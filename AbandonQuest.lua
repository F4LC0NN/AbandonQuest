local addonName, addon = ...

addon.ShowMessage = function ()
    local message = "AbandonQuest addon loaded successfully!"
    print(message)
end

addon.ShowMessage()
