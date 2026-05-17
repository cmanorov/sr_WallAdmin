local activeWallUsers = {}

local function GetPlayersData()
    local players = {}
    
    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        for _, src in ipairs(GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(tonumber(src))
            if Player then
                table.insert(players, {
                    id = src,
                    name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                    cid = Player.PlayerData.citizenid,
                    isStaff = QBCore.Functions.HasPermission(src, 'admin')
                })
            end
        end

    elseif Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        for _, src in ipairs(GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(tonumber(src))
            if xPlayer then
                table.insert(players, {
                    id = src,
                    name = xPlayer.getName(),
                    cid = xPlayer.identifier,
                    isStaff = (xPlayer.getGroup() ~= 'user')
                })
            end
        end

    elseif Config.Framework == 'vrp' then
        local vRP = Proxy.getInterface("vRP")
        for _, src in ipairs(GetPlayers()) do
            local user_id = vRP.getUserId(src)
            if user_id then
                local identity = vRP.getUserIdentity(user_id)
                table.insert(players, {
                    id = src,
                    name = identity and (identity.name .. ' ' .. identity.firstname) or "Desconhecido",
                    cid = tostring(user_id),
                    isStaff = vRP.hasPermission(user_id, "admin.permissao")
                })
            end
        end

    else
        for _, src in ipairs(GetPlayers()) do
            table.insert(players, {
                id = src,
                name = GetPlayerName(src),
                cid = "N/A",
                isStaff = false
            })
        end
    end

    return players
end

CreateThread(function()
    while true do
        Wait(Config.RefreshRate)
        local adminCount = 0
        for _ in pairs(activeWallUsers) do adminCount = adminCount + 1 end
        if adminCount > 0 then
            local playersData = GetPlayersData()
            for adminSrc, _ in pairs(activeWallUsers) do
                TriggerClientEvent('studioreborn:client:updateWallData', adminSrc, playersData, activeWallUsers)
            end
        end
    end
end)

RegisterNetEvent('studioreborn:server:toggleWallState', function(state)
    local src = source
    if state then
        activeWallUsers[src] = true
    else
        activeWallUsers[src] = nil
    end
end)