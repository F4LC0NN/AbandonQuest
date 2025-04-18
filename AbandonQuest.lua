local addonName, addon = ...

-- Function to initialize our hook for the quest header
function addon:InitializeQuestHeaderRightClick()
    -- Hook into the QuestMapQuestOptions_BuildMenu function to add our option
    hooksecurefunc("QuestMapQuestOptions_BuildMenu", function(_, questLogIndex)
        local info = C_QuestLog.GetInfo(questLogIndex)
        
        -- Only add our menu option if this is a header
        if info and info.isHeader then
            local categoryName = info.title
            
            -- Add the "Abandon Quests" option to the dropdown menu
            local abandonOption = {
                text = "Abandon Quests",
                func = function()
                    -- Execute the same logic as /aq abandonall
                    addon:AbandonAllQuestsInCategory(categoryName)
                end
            }
            
            -- Add our option to the dropdown menu
            UIDropDownMenu_AddButton(abandonOption)
        end
    end)
end

-- Function to abandon all quests in a category (same logic as in SlashCommand.lua)
function addon:AbandonAllQuestsInCategory(category)
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
                   string.lower(currentHeader) == string.lower(category) then
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

-- Initialize our addon when ADDON_LOADED event fires
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        addon:InitializeQuestHeaderRightClick()
    end
end)
