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

Config.Inventory = 'ox_lib' -- Set to 'ox_lib' or 'chezza'

Config.Dustbins = {684586828, 577432224, 218085040, 666561306, 1511880420, 682791951}