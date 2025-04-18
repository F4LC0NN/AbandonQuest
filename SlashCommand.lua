local addonName, addon = ...

SLASH_ABANDONQUEST1 = '/abandonquest'
SLASH_ABANDONQUEST2 = '/aq'

SlashCmdList['ABANDONQUEST'] = function(msg)
    -- Convert message to lowercase for case-insensitive comparison
    msg = msg:lower()  -- Fixed: proper Lua method call syntax

    -- Check if the message is "help" or "h"
    if msg == "help" or msg == "h" then
        -- Show the help message
        local helpMessage = "AbandonQuest Help:\n" ..
                            "/aq help - Show this help message\n" ..
                            "/aq status - Show the status of all quests\n" ..
                            "/aq version - Show the current version of the addon\n" ..
                            "/aq abandon <questID> - Abandon a specific quest by ID\n" ..
                            "/aq abandonall <category> - Abandon all quests in a category (zone)\n"
        print(helpMessage)
    elseif msg == "status" or msg == "s" then
        -- Show the status of all quests using WoW API
        print("AbandonQuest Status:")
        local numEntries = C_QuestLog.GetNumQuestLogEntries()
        if numEntries == 0 then
            print("You have no active quests.")
        else
            print("You have " .. numEntries .. " active quests:")
            for i = 1, numEntries do
                local questInfo = C_QuestLog.GetInfo(i)
                if questInfo and not questInfo.isHeader then
                    print("ID: " .. questInfo.questID .. " - " .. questInfo.title)
                end
            end
        end
    elseif msg == "version" or msg == "v" then
        -- Show the current version of the addon (matching TOC file)
        print("AbandonQuest Version: 0.0.1")
    elseif msg:find("abandon%s+%d+") then
        -- Extract the quest ID from the message
        local questID = tonumber(msg:match("abandon%s+(%d+)"))
        if questID then
            -- Actually abandon the specified quest using WoW API
            local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
            if questLogIndex then
                C_QuestLog.SetSelectedQuest(questID)
                C_QuestLog.SetAbandonQuest()
                C_QuestLog.AbandonQuest()
                print("Quest with ID " .. questID .. " has been abandoned.")
            else
                print("No active quest found with ID: " .. questID)
            end
        else
            print("Invalid quest ID. Use /aq help for a list of commands.")
        end
    elseif msg:find("abandonall") then
        -- Extract the category from the message
        local category = msg:match("abandonall%s+(.+)")
        if category then
            -- Abandon all quests in the specified category
            print("Attempting to abandon all quests in category: " .. category)
            local numAbandoned = 0
            local numEntries = C_QuestLog.GetNumQuestLogEntries()
            
            for i = 1, numEntries do
                local questInfo = C_QuestLog.GetInfo(i)
                if questInfo and not questInfo.isHeader then
                    -- Check if quest belongs to the specified category/zone
                    -- This is a simplified approach - you might need to adjust based on how categories are defined
                    if questInfo.questLogIndex and string.find(string.lower(questInfo.title), string.lower(category)) then
                        C_QuestLog.SetSelectedQuest(questInfo.questID)
                        C_QuestLog.SetAbandonQuest()
                        C_QuestLog.AbandonQuest()
                        numAbandoned = numAbandoned + 1
                    end
                end
            end
            
            print("Abandoned " .. numAbandoned .. " quests in category: " .. category)
        else
            print("Invalid category. Use /aq help for a list of commands.")
        end
    else
        print("Invalid command. Use /aq help for a list of commands.")
    end
end
