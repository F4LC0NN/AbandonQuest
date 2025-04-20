local addonName, addon = ...

QUEST_LOG_ABANDON_QUESTS = "Abandon Quests"

function QuestLogHeaderCodeMixin:OnClick(button)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    if button == "LeftButton" then
        local info = C_QuestLog.GetInfo(self.questLogIndex);
        if info then
            if info.isCollapsed then
                ExpandQuestHeader(self.questLogIndex);
            else
                CollapseQuestHeader(self.questLogIndex);
            end
        end
    elseif button == "RightButton" then
        MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
            rootDescription:SetTag("MENU_QUEST_MAP_FRAME");

            rootDescription:CreateButton(QUEST_LOG_TRACK_ALL, function()
                QuestMapFrame:SetHeaderQuestsTracked(self.questLogIndex, true);
            end);

            rootDescription:CreateButton(QUEST_LOG_UNTRACK_ALL, function()
                QuestMapFrame:SetHeaderQuestsTracked(self.questLogIndex, false);
            end);

            rootDescription:CreateButton(QUEST_LOG_ABANDON_QUESTS, function()
                local questInfo = C_QuestLog.GetInfo(self.questLogIndex);
                if questInfo and questInfo.isHeader then
                    local categoryName = questInfo.title;
                    print("Abandoning quests in category: " .. categoryName);

                    -- Find quests under this header
                    local questsToAbandon = {};
                    local i = self.questLogIndex + 1;
                    local nextQuestInfo = C_QuestLog.GetInfo(i);

                    -- Keep going until we hit another header or end of list
                    while nextQuestInfo and not nextQuestInfo.isHeader do
                        table.insert(questsToAbandon, {
                            id = nextQuestInfo.questID,
                            title = nextQuestInfo.title
                        });
                        i = i + 1;
                        nextQuestInfo = C_QuestLog.GetInfo(i);
                    end

                    -- Abandon all the quests we found
                    for _, quest in ipairs(questsToAbandon) do
                        C_QuestLog.SetSelectedQuest(quest.id);
                        C_QuestLog.SetAbandonQuest();
                        C_QuestLog.AbandonQuest();
                        print("  - Abandoned: " .. quest.title);
                    end
                end
            end);
        end);
    end
end
