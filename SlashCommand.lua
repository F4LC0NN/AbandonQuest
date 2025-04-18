local addonName, addon = ...

-- Ensure SlashCmdList exists
if not SlashCmdList then
    SlashCmdList = {}
end

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
                            "/aq status - Show the status of all quests by category\n" ..
                            "/aq version - Show the current version of the addon\n" ..
                            "/aq categories - List all quest categories in your quest log\n" ..
                            "/aq abandon <questID> - Abandon a specific quest by ID\n" ..
                            "/aq abandonall <category> - Abandon all quests in a category\n"
        print(helpMessage)
    elseif msg == "status" or msg == "s" then
        -- Show the status of all quests organized by category
        print("AbandonQuest Status:")
        
        local numEntries = C_QuestLog.GetNumQuestLogEntries()
        local currentHeader = nil
        
        if numEntries == 0 then
            print("You have no active quests.")
        else
            for i = 1, numEntries do
                local questInfo = C_QuestLog.GetInfo(i)
                if questInfo then
                    if questInfo.isHeader then
                        currentHeader = questInfo.title
                        print("\n|cFF00FFFF" .. currentHeader .. "|r") -- Color the header cyan
                    elseif currentHeader then
                        print("  - " .. questInfo.title .. " (ID: " .. questInfo.questID .. ")")
                    end
                end
            end
        end
    elseif msg == "categories" or msg == "cats" then
        -- Show all quest categories
        print("Quest Categories:")
        local numEntries = C_QuestLog.GetNumQuestLogEntries()
        for i = 1, numEntries do
            local questInfo = C_QuestLog.GetInfo(i)
            if questInfo and questInfo.isHeader then
                print("- " .. questInfo.title)
            end
        end
    elseif msg == "version" or msg == "v" then
        -- Show the current version of the addon (matching TOC file)
        print("AbandonQuest Version: 0.0.1")
    elseif msg:find("abandon%s+%d+") then
        -- Extract the quest ID from the message
        local questID = tonumber(msg:match("abandon%s+(%d+)"))
        if questID then
            -- Abandon the specified quest using WoW API
            local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
            if questLogIndex then
                -- Get the quest title before abandoning it
                local questInfo = C_QuestLog.GetInfo(questLogIndex)
                local questTitle = questInfo and questInfo.title or "Unknown Quest"
                
                -- Abandon the quest
                C_QuestLog.SetSelectedQuest(questID)
                C_QuestLog.SetAbandonQuest()
                C_QuestLog.AbandonQuest()
                print("Quest '" .. questTitle .. "' (ID: " .. questID .. ") has been abandoned.")
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
            print("Attempting to abandon all quests in category: " .. category)
            
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
                print("No quests found in category: " .. category .. ". Use '/aq categories' to see available categories.")
            end
        else
            print("Please specify a category. Example: /aq abandonall Northshire")
        end
    else
        print("Invalid command. Use /aq help for a list of commands.")
    end
end
