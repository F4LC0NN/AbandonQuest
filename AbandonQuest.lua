local addonName, addon = ...

-- Debug utilities
addon.Debug = {}
addon.Debug.enabled = true

addon.Debug.Log = function(...)
    if addon.Debug.enabled then
        print("|cFF00FFFF[AbandonQuest Debug]|r", ...)
    end
end

-- Addon initialization
addon.ShowMessage = function()
    local message = "AbandonQuest addon loaded successfully! Use '/aq help' for commands."
    print("|cFF00FF00" .. message .. "|r")
end

-- Function to abandon all quests in a specific category
addon.AbandonQuestsInCategory = function(category)
    if not category then return end
    
    print("Abandoning all quests in category: " .. category)
    
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    local currentHeader = nil
    local questsToAbandon = {}
    
    -- First pass: find all quests in the specified category
    for i = 1, numEntries do
        local questInfo = C_QuestLog.GetInfo(i)
        
        if questInfo then
            if questInfo.isHeader then
                -- This is a category header
                currentHeader = questInfo.title
            elseif not questInfo.isHeader and currentHeader and 
                   currentHeader == category then
                -- This is a quest under our target category
                table.insert(questsToAbandon, {
                    id = questInfo.questID,
                    title = questInfo.title
                })
            end
        end
    end
    
    -- Second pass: abandon all identified quests
    local numAbandoned = 0
    for _, quest in ipairs(questsToAbandon) do
        C_QuestLog.SetSelectedQuest(quest.id)
        C_QuestLog.SetAbandonQuest()
        C_QuestLog.AbandonQuest()
        numAbandoned = numAbandoned + 1
        print("  - Abandoned: " .. quest.title)
    end
    
    if numAbandoned > 0 then
        print("Successfully abandoned " .. numAbandoned .. " quests in category: " .. category)
    else
        print("No quests found in category: " .. category)
    end
end

-- Create a confirm dialog for abandoning multiple quests
addon.CreateConfirmDialog = function()
    StaticPopupDialogs["ABANDON_QUEST_CATEGORY"] = {
        text = "Are you sure you want to abandon all quests in this category?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(self, data)
            addon.AbandonQuestsInCategory(data)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

-- Store our added buttons to avoid duplicates
addon.addedButtons = {}

-- Create and add our custom buttons to quest headers
addon.AddButtonsToQuestHeaders = function()
    -- Function to process headers from the QuestMap frame
    local function processQuestMapHeaders()
        -- Find headers in QuestMapFrame
        if QuestMapFrame and QuestMapFrame.QuestsFrame then
            -- Get all children of the QuestsFrame
            local children = {QuestMapFrame.QuestsFrame:GetChildren()}
            for _, child in ipairs(children) do
                -- Look for the Contents frame
                if child:GetName() == "QuestMapQuestsFrame" or child:GetName() == "QuestMapFrameQuestsFrame" then
                    local contents = child
                    -- Get all children of the Contents frame
                    local contentChildren = {contents:GetChildren()}
                    for _, contentChild in ipairs(contentChildren) do
                        -- Check if this is a header frame
                        if contentChild.category and not addon.addedButtons[contentChild] then
                            addon.Debug.Log("Found quest header: " .. contentChild.category)
                            addon.AddButtonToHeader(contentChild)
                        end
                    end
                end
            end
        end
    end
    
    -- Function to process headers from the classic quest log
    local function processClassicQuestLogHeaders()
        -- Try to find headers in the classic quest log if it exists
        if QuestLogFrame then
            for i = 1, 30 do -- Try a reasonable number of possible headers
                local header = _G["QuestLogTitle" .. i]
                if header and header.isHeader and not addon.addedButtons[header] then
                    addon.Debug.Log("Found classic quest header: " .. header:GetText())
                    addon.AddButtonToHeader(header)
                end
            end
        end
    end
    
    -- Try both methods
    processQuestMapHeaders()
    processClassicQuestLogHeaders()
    
    -- As a last resort, scan all frames with names matching likely quest header patterns
    for _, pattern in ipairs({"QuestLogTitle%d+", "QuestHeader%d+", "QuestMapHeader%d+"}) do
        for i = 1, 100 do -- Try a reasonable number
            local frameName = pattern:gsub("%%d%+", tostring(i))
            local frame = _G[frameName]
            if frame and not addon.addedButtons[frame] then
                addon.Debug.Log("Found potential quest header by name: " .. frameName)
                addon.AddButtonToHeader(frame)
            end
        end
    end
end

-- Add our custom button to a header frame
addon.AddButtonToHeader = function(header)
    if not header or addon.addedButtons[header] then return end
    
    -- Create the button
    local button = CreateFrame("Button", nil, header)
    button:SetSize(20, 20)
    
    -- Create a texture for the button
    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
    button.texture = texture
    
    -- Set the button's position relative to the header
    button:SetPoint("RIGHT", header, "RIGHT", -5, 0)
    
    -- Set the button's tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Abandon all quests in this category")
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Set the button's click handler
    button:SetScript("OnClick", function(self)
        local categoryName = nil
        
        -- Try to get the category name
        if header.category then
            categoryName = header.category
        elseif header.GetText and header:GetText() then
            categoryName = header:GetText()
        elseif header.title then
            categoryName = header.title
        end
        
        if categoryName then
            addon.Debug.Log("Abandon button clicked for: " .. categoryName)
            StaticPopup_Show("ABANDON_QUEST_CATEGORY", nil, nil, categoryName)
        else
            addon.Debug.Log("Could not determine category name for header")
        end
    end)
    
    -- Mark this header as having our button
    addon.addedButtons[header] = button
    
    addon.Debug.Log("Added abandon button to header")
end

-- Function to scan all frames for potential quest headers
addon.ScanAllFrames = function()
    local scanFrame = CreateFrame("Frame")
    local scanTime = 0
    local scanInterval = 0.1
    
    scanFrame:SetScript("OnUpdate", function(self, elapsed)
        scanTime = scanTime + elapsed
        if scanTime >= scanInterval then
            scanTime = 0
            
            -- Check if the quest log is visible
            if QuestMapFrame and QuestMapFrame:IsVisible() then
                addon.AddButtonsToQuestHeaders()
            end
        end
    end)
    
    addon.Debug.Log("Started frame scanning for quest headers")
end

-- Initialize slash commands
addon.InitSlashCommands = function()
    SLASH_ABANDONQUEST1 = "/abandonquest"
    SLASH_ABANDONQUEST2 = "/aq"
    
    SlashCmdList["ABANDONQUEST"] = function(msg)
        local command, rest = msg:match("^(%S*)%s*(.-)$")
        command = command:lower()
        
        if command == "debug" then
            addon.Debug.enabled = not addon.Debug.enabled
            print("AbandonQuest Debug mode: " .. (addon.Debug.enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
        elseif command == "scan" then
            print("AbandonQuest: Scanning for quest headers...")
            addon.AddButtonsToQuestHeaders()
        elseif command == "abandon" and rest ~= "" then
            addon.AbandonQuestsInCategory(rest)
        elseif command == "help" or command == "" then
            print("|cFF00FFFF=== AbandonQuest Help ===|r")
            print("|cFFFFFFFF/aq debug|r - Toggle debug mode")
            print("|cFFFFFFFF/aq scan|r - Manually scan for quest headers")
            print("|cFFFFFFFF/aq abandon [category]|r - Abandon all quests in a category")
        else
            print("Unknown command. Type |cFFFFFFFF/aq help|r for a list of commands.")
        end
    end
end

-- Initialize the addon
addon.InitializeAddon = function()
    addon.ShowMessage()
    addon.CreateConfirmDialog()
    addon.InitSlashCommands()
    
    -- Register for events to ensure we catch when UI elements are created
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    
    frame:SetScript("OnEvent", function(self, event, arg1)
        if (event == "ADDON_LOADED" and arg1 == addonName) or 
           event == "PLAYER_ENTERING_WORLD" then
            -- Start scanning for frames
            addon.ScanAllFrames()
        elseif event == "QUEST_LOG_UPDATE" then
            -- Scan for quest headers when the quest log updates
            C_Timer.After(0.2, function()
                addon.AddButtonsToQuestHeaders()
            end)
        end
    end)
end

-- Call the initialization function
addon.InitializeAddon()
