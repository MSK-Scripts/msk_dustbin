local currentDustbin = {}
local isDead = false

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        lib.hideContext('msk_dustbin_main')
    end
end)

AddEventHandler('esx:onPlayerDeath', function() isDead = true end)
AddEventHandler('esx:onPlayerSpawn', function() isDead = false end)

CreateThread(function()
	while true do
		local sleep = 500
        currentDustbin = {}

        if NearDustbin() and isCurrent() and not isDead then
            sleep = 0
            ESX.ShowHelpNotification(Translation[Config.Locale]['open'])
            
            if IsControlJustPressed(0, Config.Hotkey) then
                if Config.Inventory == 'chezza' then
                    TriggerEvent('inventory:openInventory', {
                        type = "msk_dustbin",
                        id = currentDustbin.model .. ' - ' .. coordsToJson(currentDustbin.coords),
                        title = Translation[Config.Locale]['dustbin_label'],
                        weight = false,
                        delay = 250,
                        save = true
                    })
                elseif Config.Inventory == 'ox_lib' then
                    registerMenus()
                end
            end
        end

		Wait(sleep)
	end
end)

registerMenus = function()
    local binOptions = {{title = Translation[Config.Locale]['menu_throw_label'], menu = 'msk_dustbin_other', icon = 'trash', arrow = true}}
    local binCallback = false

    ESX.TriggerServerCallback('msk_dustbin:getDustbin', function(data)
        for k, v in pairs(data) do
            local icon, title = 'dollar-sign', ''
            
            if v.type == 'money' or v.type == 'item' then
                if v.type == 'money' then 
                    icon = 'dollar-sign'
                    title = ('%s - $%s'):format(v.label, comma(v.money))
                elseif v.type == 'item' then 
                    icon = 'box'
                    title = ('%s - %sx'):format(v.label, v.count)
                end

                binOptions[#binOptions + 1] = {
                    title = title,
                    description = Translation[Config.Locale]['menu_get_desc'],
                    icon = icon,
                    args = v,
                    onSelect = function(data)
                        local binId = currentDustbin.model .. ' - ' .. coordsToJson(currentDustbin.coords)

                        local input = lib.inputDialog(Translation[Config.Locale]['amount'], {
                            {type = 'number', label = Translation[Config.Locale]['amount'], description = Translation[Config.Locale]['amount_desc'], required = true},
                        })
    
                        if input and input[1] then
                            local amount = data.money
                            if data.type == 'item' then amount = data.count end

                            if input[1] <= amount then
                                TriggerServerEvent('msk_dustbin:getItem', binId, data, input[1])
                                reopenMenu()
                            else
                                Config.Notification(nil, Translation[Config.Locale]['bin_not_enough'], 'error')
                            end
                        end
                    end
                }
            end
        end

        for _, i in pairs(data) do
            if not i.type then
                icon = 'gun'

                for k, v in pairs(i) do
                    title = ('%s - %s Ammo'):format(v.label, v.ammo)
                    local metadata = false

                    for a, comp in pairs(v.components) do
                        if type(metadata) ~= 'table' then metadata = {} end
                        table.insert(metadata, {label = ESX.GetWeaponComponent(v.name, comp).label})
                    end

                    binOptions[#binOptions + 1] = {
                        title = title,
                        description = Translation[Config.Locale]['menu_get_desc'],
                        icon = icon,
                        args = v,
                        metadata = metadata,
                        onSelect = function(data)
                            local binId = currentDustbin.model .. ' - ' .. coordsToJson(currentDustbin.coords)
                            TriggerServerEvent('msk_dustbin:getItem', binId, data, nil, k)
                            reopenMenu()
                        end
                    }
                end
            end
        end

        binCallback = true
    end, currentDustbin.model .. ' - ' .. coordsToJson(currentDustbin.coords), true)
    while not binCallback do Wait(0) end

    lib.registerContext({
        id = 'msk_dustbin_main',
        title = Translation[Config.Locale]['dustbin_label'],
        options = binOptions
    })

    local inventoryOptions, callback = {}, false
    for k, v in pairs(ESX.PlayerData.accounts) do
        if v.money > 0 and v.name ~= 'bank' then
            v.type = 'money'

            inventoryOptions[#inventoryOptions + 1] = {
                title = ('%s - $%s'):format(v.label, comma(v.money)),
                icon = 'dollar-sign',
                args = v,
                onSelect = function(data)
                    local input = lib.inputDialog(Translation[Config.Locale]['amount'], {
                        {type = 'number', label = Translation[Config.Locale]['amount'], description = Translation[Config.Locale]['menu_throw_desc'], required = true},
                    })

                    if input and input[1] then
                        if input[1] <= data.money then
                            local binId = currentDustbin.model .. ' - ' .. coordsToJson(currentDustbin.coords)

                            TriggerServerEvent('msk_dustbin:throwAway', binId, data, input[1])
                            reopenMenu()
                        else
                            Config.Notification(nil, Translation[Config.Locale]['player_not_enough'], 'error')
                        end
                    end
                end
            }
        end
    end

    ESX.TriggerServerCallback('msk_dustbin:getInventory', function(inventory, loadout)
        for k, v in pairs(inventory) do
            if v.count > 0 then
                v.type = 'item'

                inventoryOptions[#inventoryOptions + 1] = {
                    title = ('%s - %sx'):format(v.label, v.count),
                    icon = 'box',
                    args = v,
                    onSelect = function(data)
                        local input = lib.inputDialog(Translation[Config.Locale]['amount'], {
                            {type = 'number', label = Translation[Config.Locale]['amount'], description = Translation[Config.Locale]['menu_throw_desc'], required = true},
                        })

                        if input and input[1] then
                            if input[1] <= data.count then
                                local binId = currentDustbin.model .. ' - ' .. coordsToJson(currentDustbin.coords)

                                TriggerServerEvent('msk_dustbin:throwAway', binId, data, input[1])
                                reopenMenu()
                            else
                                Config.Notification(nil, Translation[Config.Locale]['player_not_enough'], 'error')
                            end
                        end
                    end
                }
            end
        end

        for k, v in pairs(loadout) do
            v.type = 'weapon'

            inventoryOptions[#inventoryOptions + 1] = {
                title = ('%s - %s Ammo'):format(v.label, v.ammo),
                icon = 'gun',
                args = v,
                onSelect = function(data)
                    local binId = currentDustbin.model .. ' - ' .. coordsToJson(currentDustbin.coords)

                    TriggerServerEvent('msk_dustbin:throwAway', binId, data)
                    reopenMenu()
                end
            }
        end

        callback = true
    end)
    while not callback do Wait(0) end

    lib.registerContext({
        id = 'msk_dustbin_other',
        title = Translation[Config.Locale]['menu_throw_label'],
        menu = 'msk_dustbin_main',
        options = inventoryOptions
    })

    lib.showContext('msk_dustbin_main')
end

NearDustbin = function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for k, prop in pairs(Config.Dustbins) do
        local entity = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 1.5, prop, false, false, false)

        if DoesEntityExist(entity) then
            local entityCoords = GetEntityCoords(entity)
            local x, y, z = table.unpack(entityCoords)
            local tCoords = {[1] = round(x, 2), [2] = round(y, 2), [3] = round(z, 2)}

            currentDustbin = {model = prop, coords = tCoords, entity = entity}
	        return true
	    end
    end

    return false
end

reopenMenu = function()
    if isDead then return end
    Wait(500)
    registerMenus()
end

isCurrent = function()
    return currentDustbin and currentDustbin.model and currentDustbin.coords
end

coordsToJson = function(coords)
    local sorted = {}

    for k, v in ESX.Table.Sort(coords, function(t, a, b) return t[b] < t[a] end) do
        sorted[k] = v
    end

    return json.encode(sorted)
end

comma = function(int, tag)
    if not tag then tag = '.' end
    local newInt = int

    while true do  
        newInt, k = string.gsub(newInt, "^(-?%d+)(%d%d%d)", '%1'..tag..'%2')

        if (k == 0) then
            break
        end
    end

    return newInt
end

round = function(num, decimal) 
    return tonumber(string.format("%." .. (decimal or 0) .. "f", num))
end