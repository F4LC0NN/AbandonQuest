local addonName, addon = ...

-- File Initialization
addon.ShowMessage = function ()
    local message = "AbandonQuest ObjectiveTracker loaded successfully!"
    print(message)
end

-- Create a mixin for our extended Adventure Objective Tracker
AbandonQuestAdventureTrackerMixin = {}

-- Hook into the Adventure Objective Tracker's OnBlockHeaderClick function
function AbandonQuestAdventureTrackerMixin:Init()
    -- Store the original OnBlockHeaderClick function
    self.originalOnBlockHeaderClick = AdventureObjectiveTrackerMixin.OnBlockHeaderClick
    
    -- Replace it with our extended version
    AdventureObjectiveTrackerMixin.OnBlockHeaderClick = function(self, block, mouseButton)
        -- If right-clicked, show our custom menu
        if mouseButton == "RightButton" then
            -- Create a context menu for the block
            MenuUtil.CreateContextMenu(self:GetContextMenuParent(), function(owner, rootDescription)
                rootDescription:SetTag("MENU_OBJECTIVE_TRACKER", block)
                
                rootDescription:CreateTitle(block.name)
                
                -- Add our custom option to abandon related quests
                if block.trackableType and block.trackableID then
                    -- Check if this is related to a quest category
                    local targetType, targetID = C_ContentTracking.GetCurrentTrackingTarget(block.trackableType, block.trackableID)
                    if targetType then
                        local questCategory = nil
                        
                        -- Determine if this is related to a quest category
                        if targetType == Enum.ContentTrackingTargetType.Quest then
                            -- Get the quest category
                            local questLogIndex = C_QuestLog.GetLogIndexForQuestID(targetID)
                            if questLogIndex then
                                -- Find the header for this quest
                                for i = questLogIndex, 1, -1 do
                                    local info = C_QuestLog.GetInfo(i)
                                    if info and info.isHeader then
                                        questCategory = info.title
                                        break
                                    end
                                end
                            end
                        end
                        
                        -- If we found a quest category, add an option to abandon all quests in it
                        if questCategory then
                            rootDescription:CreateButton("Abandon All Quests in Category", function()
                                -- Show confirmation dialog
                                StaticPopup_Show("ABANDON_QUEST_CATEGORY", nil, nil, questCategory)
                            end)
                        end
                    end
                end
                
                -- Add other default options
                if block.trackableType == Enum.ContentTrackingType.Appearance then
                    rootDescription:CreateButton(CONTENT_TRACKING_OPEN_JOURNAL_OPTION, function()
                        self:OpenToAppearance(block.trackableID)
                    end)
                end
                rootDescription:CreateButton(OBJECTIVES_STOP_TRACKING, function()
                    self:Untrack(block.trackableType, block.trackableID)
                end)
            end)
            return true
        end
        
        -- Otherwise, call the original function
        return self.originalOnBlockHeaderClick(self, block, mouseButton)
    end
end

-- Initialize our extension
local tracker = CreateFrame("Frame")
tracker:RegisterEvent("ADDON_LOADED")
tracker:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_ObjectiveTracker" then
        -- Apply our mixin to the Adventure Objective Tracker
        if AdventureObjectiveTracker then
            Mixin(AdventureObjectiveTrackerMixin, AbandonQuestAdventureTrackerMixin)
            
            -- Initialize the mixin
            if AdventureObjectiveTrackerMixin.Init then
                AdventureObjectiveTrackerMixin:Init()
            end
        end
    end
end)

-- Register the frame in the XML file you provided
-- <Frame name="AdventureObjectiveTracker" mixin="AdventureObjectiveTrackerMixin" inherits="ObjectiveTrackerModuleTemplate, POIButtonOwnerTemplate"/>
