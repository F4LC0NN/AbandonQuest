local addonName, addon = ...

-- Ensure SlashCmdList exists
if not SlashCmdList then
    SlashCmdList = {}
end

SLASH_ABANDONQUEST1 = '/abandonquest'
SLASH_ABANDONQUEST2 = '/aq'

SlashCmdList['ABANDONQUEST'] = function(msg)
    -- Convert message to lowercase for case-insensitive comparison
    msg = msg.lower()

    -- Check if the message is "help" or "h"
    if msg == "help" or msg == "h" then
        -- Show the help message, use shortand /aq for the command
        local helpMessage = "AbandonQuest Help:\n" ..
                            "/aq help - Show this help message\n" ..
                            "/aq status - Show the status of all quests\n" ..
                            "/aq version - Show the current version of the addon\n" ..
                            "/aq abandon <questID> - Abandon a specific quest by ID\n"
        print(helpMessage)
    elseif msg == "status" or msg == "s" then
        -- Show the status of all quests
        local statusMessage = "AbandonQuest Status:\n" ..
                              "All quests are currently active.\n"
        print(statusMessage)
    elseif msg == "version" or msg == "v" then
        -- Show the current version of the addon
        local versionMessage = "AbandonQuest Version: 1.0.0\n"
        print(versionMessage)
    elseif msg:find("abandon") then
        -- Extract the quest ID from the message
        local questID = msg:match("abandon%s+(%d+)")
        if questID then
            -- Abandon the specified quest (this is a placeholder, actual implementation needed)
            local abandonMessage = "Abandoning quest with ID: " .. questID .. "\n"
            print(abandonMessage)
        else
            print("Invalid command. Use /aq help for a list of commands.")
        end
    else
        print("Invalid command. Use /aq help for a list of commands.")
    end
end
