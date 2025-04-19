local addonName, addon = ...

-- Addon initialization
addon.ShowMessage = function ()
    local message = "AbandonQuest addon loaded successfully!"
    print(message)
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

-- Create and hook right-click menu for quest headers
addon.InitializeRightClickMenu = function()
    -- Hook into the QuestLogPopupDetailFrame to add our menu option
    hooksecurefunc("QuestLogPopupDetailFrame_Show", function()
        -- Check if the selected quest is a header
        local selectedQuest = C_QuestLog.GetSelectedQuest()
        if selectedQuest then
            local questInfo = C_QuestLog.GetInfo(C_QuestLog.GetLogIndexForQuestID(selectedQuest))
            if questInfo and questInfo.isHeader then
                -- Add our menu option to the quest log right-click menu
                local abandonItem = {
                    text = "Abandon Quests",
                    func = function()
                        addon.AbandonQuestsInCategory(questInfo.title)
                    end
                }
                -- Add to the context menu
                QuestLogPopupDetailFrame_AddContextMenuOption(abandonItem)
            end
        end
    end)
end

-- Hook into the right-click menu for quest headers in the quest log
addon.HookQuestLogMenu = function()
    -- Create a table to store our right-click menu options
    local AbandonQuestMenu = CreateFrame("Frame", "AbandonQuestMenu", UIParent, "UIDropDownMenuTemplate")

    -- Hook the quest log right-click menu
    hooksecurefunc("QuestMapLogTitleButton_OnClick", function(self, button)
        if button == "RightButton" then
            local questID = self.questID
            local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
            local info = C_QuestLog.GetInfo(questLogIndex)
            
            if info and info.isHeader then
                -- This is a category header, show our custom menu
                UIDropDownMenu_Initialize(AbandonQuestMenu, function(frame, level, menuList)
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = "Abandon Quests"
                    info.func = function()
                        addon.AbandonQuestsInCategory(self.questTitle)
                    end
                    UIDropDownMenu_AddButton(info, level)
                end, "MENU")
                ToggleDropDownMenu(1, nil, AbandonQuestMenu, self, 0, 0)
            end
        end
    end)
    
    -- Also hook the classic quest log if available
    if QuestLogFrameItem_OnClick then
        hooksecurefunc("QuestLogFrameItem_OnClick", function(self, button)
            if button == "RightButton" then
                local questIndex = self:GetID()
                local info = C_QuestLog.GetInfo(questIndex)
                
                if info and info.isHeader then
                    -- This is a category header, show our custom menu
                    UIDropDownMenu_Initialize(AbandonQuestMenu, function(frame, level, menuList)
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = "Abandon Quests"
                        info.func = function()
                            addon.AbandonQuestsInCategory(self.questTitle)
                        end
                        UIDropDownMenu_AddButton(info, level)
                    end, "MENU")
                    ToggleDropDownMenu(1, nil, AbandonQuestMenu, self, 0, 0)
                end
            end
        end)
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

-- Initialize the addon
addon.InitializeAddon = function()
    addon.ShowMessage()
    addon.InitializeRightClickMenu()
    addon.HookQuestLogMenu()
    addon.CreateConfirmDialog()
    
    -- Register for events if needed
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "ADDON_LOADED" and arg1 == addonName then
            -- Addon has loaded, do any needed setup
            addon.ShowMessage()
        end
    end)
end

-- Call the initialization function
addon.InitializeAddon()
