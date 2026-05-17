local activeWallUsers = {}

local function ExtractIdentifiers(src)
    local ids = { steam = "N/A", license = "N/A", discord = "N/A" }
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "steam:") then ids.steam = id end
        if string.find(id, "license:") then ids.license = id end
        if string.find(id, "discord:") then 
            ids.discord = string.gsub(id, "discord:", "<@") .. ">" 
        end
    end
    return ids
end

local function GetAdminDetails(src)
    local steamName = GetPlayerName(src) or "Desconhecido"
    local charName = "N/A"
    local cid = "N/A"

    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(tonumber(src))
        if Player then
            charName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            cid = Player.PlayerData.citizenid
        end
    elseif Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(tonumber(src))
        if xPlayer then
            charName = xPlayer.getName()
            cid = xPlayer.identifier
        end
    elseif Config.Framework == 'vrp' then
        local vRP = Proxy.getInterface("vRP")
        local user_id = vRP.getUserId(src)
        if user_id then
            local identity = vRP.getUserIdentity(user_id)
            charName = identity and (identity.name .. ' ' .. identity.firstname) or "Desconhecido"
            cid = tostring(user_id)
        end
    end

    return steamName, charName, cid
end

local function HasAdminPermission(src)
    if Config.Framework == 'qbox' or Config.Framework == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.HasPermission(src, 'admin')
    elseif Config.Framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(tonumber(src))
        return (xPlayer and xPlayer.getGroup() ~= 'user')
    elseif Config.Framework == 'vrp' then
        local vRP = Proxy.getInterface("vRP")
        local user_id = vRP.getUserId(src)
        return vRP.hasPermission(user_id, "admin.permissao")
    else
        return IsPlayerAceAllowed(src, "command.wall")
    end
end

local function SendWallLog(src, state)
    if not Config.WebhookURL or Config.WebhookURL == "" then return end

    local steamName, charName, cid = GetAdminDetails(src)
    local ids = ExtractIdentifiers(src)
    
    local statusText = state and "🟢 **ATIVOU**" or "🔴 **DESATIVOU**"
    local embedColor = state and 5763719 or 15548997

    local embed = {
        {
            ["title"] = "🛡️ Logs de Moderação - Wall Admin",
            ["description"] = string.format("O administrador %s o painel de Wall.", statusText),
            ["color"] = embedColor,
            ["fields"] = {
                { ["name"] = "👤 Personagem", ["value"] = charName, ["inline"] = true },
                { ["name"] = "🆔 Passaporte", ["value"] = cid, ["inline"] = true },
                { ["name"] = "🎮 Player ID", ["value"] = tostring(src), ["inline"] = true },
                { ["name"] = "🌐 Steam Name", ["value"] = steamName, ["inline"] = true },
                { ["name"] = "💬 Discord", ["value"] = ids.discord ~= "N/A" and ids.discord or "Não vinculado", ["inline"] = true },
                { ["name"] = "🔑 License", ["value"] = "```" .. ids.license .. "```", ["inline"] = false },
                { ["name"] = "⚙️ Steam Hex", ["value"] = "```" .. ids.steam .. "```", ["inline"] = false }
            },
            ["footer"] = {
                ["text"] = "Studio Reborn System • " .. os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(Config.WebhookURL, function(err, text, headers) end, 'POST', json.encode({ username = "Studio Reborn Logs", embeds = embed }), { ['Content-Type'] = 'application/json' })
end

RegisterCommand('wall', function(source)
    if source == 0 then return end
    if HasAdminPermission(source) then
        TriggerClientEvent('studioreborn:client:openWallUI', source)
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '^1[SISTEMA]', 'Você não tem permissão para acessar o painel de wall.' } })
    end
end, false)

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
    if not HasAdminPermission(src) then
        print(string.format("^1[Studio Reborn] ALERTA DE SEGURANÇA: O ID %s tentou ativar o Wall via injection sem ter permissão!^0", src))
        return
    end
    if state then
        activeWallUsers[src] = true
    else
        activeWallUsers[src] = nil
    end
    SendWallLog(src, state)
end)