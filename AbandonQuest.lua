local addonName, addon = ...

-- Function to hook into the quest header right-click menu
local function InitializeQuestHeaderRightClick()
    -- Create a frame to listen for events
    local frame = CreateFrame("Frame")
    
    -- This function will run when we detect the dropdown menu is being shown
    local function AddAbandonOption()
        -- Check if this is a quest header dropdown menu
        local dropdownMenu = UIDROPDOWNMENU_INIT_MENU
        if not dropdownMenu or not dropdownMenu.questID then return end
        
        -- Get the quest info to check if it's a header
        local questInfo = C_QuestLog.GetInfo(GetQuestLogIndexByID(dropdownMenu.questID))
        if not questInfo or not questInfo.isHeader then return end
        
        local categoryName = questInfo.title
        
        -- If we've reached this point, it's a header dropdown, add our option
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Abandon Quests"
        info.notCheckable = true
        info.func = function()
            SlashCmdList["ABANDONQUEST"]("abandonall " .. categoryName)
        end
        UIDropDownMenu_AddButton(info)
    end
    
    -- Hook into the UIDropDownMenu_Initialize function to detect when menus are being created
    hooksecurefunc("UIDropDownMenu_Initialize", AddAbandonOption)
    
    print("|cFF00FF00AbandonQuest:|r Dropdown menu hook initialized.")
end

-- Initialize when addon is loaded
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then return end
    
    -- Initialize our right-click menu hook
    InitializeQuestHeaderRightClick()
    
    -- Don't need to listen for this event anymore
    self:UnregisterEvent("ADDON_LOADED")
end)