local dustbinStorage = {}

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
        local createTable = MySQL.query.await("CREATE TABLE IF NOT EXISTS msk_dustbin (`binId` varchar(80) NOT NULL, `items` longtext DEFAULT NULL, PRIMARY KEY (`binId`));")

        if createTable and createTable.warningStatus < 1 then
			print('^2 Successfully ^3 created ^2 table ^3 msk_dustbin ^0')
		end

        local data = MySQL.query.await("SELECT * FROM msk_dustbin")

        for k, v in pairs(data) do
            dustbinStorage[v.binId] = {binId = v.binId, items = json.decode(v.items)}
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(dustbinStorage) do
            if v.isNew then
                MySQL.query('INSERT INTO msk_dustbin (binId, items) VALUES (@binId, @items)', {
                    ['@items'] = json.encode(v.items),
                    ['@binId'] = v.binId
                })
            else
                MySQL.query('UPDATE msk_dustbin SET items = @items WHERE binId = @binId', {
                    ['@items'] = json.encode(v.items),
                    ['@binId'] = v.binId
                })
            end
        end
    end
end)

RegisterServerEvent('msk_dustbin:throwAway')
AddEventHandler('msk_dustbin:throwAway', function(binId, data, count)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if data.type == 'money' then
        xPlayer.removeAccountMoney(data.name, count)

        if dustbinStorage[binId] then
            if dustbinStorage[binId].items[data.name] then
                dustbinStorage[binId].items[data.name].money = dustbinStorage[binId].items[data.name].money + count
            else
                dustbinStorage[binId].items[data.name] = data
                dustbinStorage[binId].items[data.name].money = count
            end
        else
            dustbinStorage[binId] = {binId = binId, items = {[data.name] = data}, isNew = true}
            dustbinStorage[binId].items[data.name].money = count
        end

        Config.Notification(src, Translation[Config.Locale]['thow_away_money']:format(comma(count), data.label), 'success')
    elseif data.type == 'item' then
        xPlayer.removeInventoryItem(data.name, count)

        if dustbinStorage[binId] then
            if dustbinStorage[binId].items[data.name] then
                dustbinStorage[binId].items[data.name].count = dustbinStorage[binId].items[data.name].count + count
            else
                dustbinStorage[binId].items[data.name] = data
                dustbinStorage[binId].items[data.name].count = count
            end
        else
            dustbinStorage[binId] = {binId = binId, items = {[data.name] = data}, isNew = true}
            dustbinStorage[binId].items[data.name].count = count
        end

        Config.Notification(src, Translation[Config.Locale]['thow_away_item']:format(count, data.label), 'success')
    elseif data.type == 'weapon' then
        xPlayer.removeWeapon(data.name)

        if dustbinStorage[binId] then
            if not dustbinStorage[binId].items[data.name] then
                dustbinStorage[binId].items[data.name] = {}
            end
            dustbinStorage[binId].items[data.name][#dustbinStorage[binId].items[data.name] + 1] = data
        else
            dustbinStorage[binId] = {binId = binId, items = {[data.name] = {}}, isNew = true}
            dustbinStorage[binId].items[data.name][#dustbinStorage[binId].items[data.name] + 1] = data
        end

        Config.Notification(src, Translation[Config.Locale]['thow_away_weapon']:format(data.label, data.ammo), 'success')
    end
end)

RegisterServerEvent('msk_dustbin:getItem')
AddEventHandler('msk_dustbin:getItem', function(binId, data, count, weaponIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if data.type == 'money' then
        xPlayer.addAccountMoney(data.name, count)
        dustbinStorage[binId].items[data.name].money = dustbinStorage[binId].items[data.name].money - count
        if dustbinStorage[binId].items[data.name].money == 0 then dustbinStorage[binId].items[data.name] = nil end
        Config.Notification(src, Translation[Config.Locale]['get_money']:format(comma(count), data.label), 'success')
    elseif data.type == 'item' then
        xPlayer.addInventoryItem(data.name, count)
        dustbinStorage[binId].items[data.name].count = dustbinStorage[binId].items[data.name].count - count
        if dustbinStorage[binId].items[data.name].count == 0 then dustbinStorage[binId].items[data.name] = nil end
        Config.Notification(src, Translation[Config.Locale]['get_item']:format(count, data.label), 'success')
    elseif data.type == 'weapon' then
        if not xPlayer.hasWeapon(data.name) then
            xPlayer.addWeapon(data.name, data.ammo)

            if #data.components > 0 then
                for k, comp in pairs(data.components) do
                    xPlayer.addWeaponComponent(data.name, comp)
                end
            end

            table.remove(dustbinStorage[binId].items[data.name], weaponIndex)
            Config.Notification(src, Translation[Config.Locale]['get_weapon']:format(data.label, data.ammo), 'success')
        else
            Config.Notification(src, Translation[Config.Locale]['already_has_weapon'], 'error')
        end
    end
end)

ESX.RegisterServerCallback('dinerov_dustbin:getInventory', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

   cb(xPlayer.inventory, xPlayer.loadout)
end)

ESX.RegisterServerCallback('dinerov_dustbin:getDustbin', function(source, cb, binId, items)
   cb(getDustbinStorage(binId, items))
end)

getDustbinStorage = function(binId, items)
    if binId and not items then return dustbinStorage[binId] or {} end
    if binId and items then return (dustbinStorage[binId] and dustbinStorage[binId].items) or {} end
    return dustbinStorage
end
exports('getDustbinStorage', getDustbinStorage)

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

GithubUpdater = function()
    GetCurrentVersion = function()
	    return GetResourceMetadata( GetCurrentResourceName(), "version" )
    end
    
    local CurrentVersion = GetCurrentVersion()
    local resourceName = "^0[^2"..GetCurrentResourceName().."^0]"

    if Config.VersionChecker then
        PerformHttpRequest('https://raw.githubusercontent.com/MSK-Scripts/msk_dustbin/main/VERSION', function(Error, NewestVersion, Header)
            print("###############################")
            if not NewestVersion then print(resourceName .. '^1 Update Check failed! ^3Please Update to the latest Version: ^9https://github.com/MSK-Scripts/msk_dustbin^0') return print("###############################") end
            if CurrentVersion == NewestVersion then
                print(resourceName .. '^2 ✓ Resource is Up to Date^0 - ^5Current Version: ^2' .. CurrentVersion .. '^0')
            elseif CurrentVersion ~= NewestVersion then
                print(resourceName .. '^1 ✗ Resource Outdated. Please Update!^0 - ^5Current Version: ^1' .. CurrentVersion .. '^0')
                print('^5Newest Version: ^2' .. NewestVersion .. '^0 - ^6Download here:^9 https://github.com/MSK-Scripts/msk_dustbin/releases/tag/v'.. NewestVersion .. '^0')
            end
            print("###############################")
        end)
    else
        print("###############################")
        print(resourceName .. '^2 ✓ Resource loaded^0')
        print("###############################")
    end
end
GithubUpdater()