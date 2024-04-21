Config = {}
----------------------------------------------------------------
Config.Locale = 'de'
Config.VersionChecker = true
----------------------------------------------------------------
-- !!! This function is clientside AND serverside !!!
Config.Notification = function(source, message, info)
    if IsDuplicityVersion() then -- serverside
        MSK.Notification(source, 'MSK Dustbin', message, info)
    else -- clientside
        MSK.Notification('MSK Dustbin', message, info)
    end
end
----------------------------------------------------------------
Config.Hotkey = 38

Config.Inventory = 'ox_lib' -- Set to 'ox_lib', 'chezza' or 'ox_inventory'

Config.Dustbins = {684586828, 577432224, 218085040, 666561306, 1511880420, 682791951}

Config.RemoveItemsOnRestart = true -- Set false if you don't want that items will be removed after server restart