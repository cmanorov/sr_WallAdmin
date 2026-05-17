local ShowNames = false
local ShowLines = false
local ShowWeapons = false
local ShowVehicles = false

local playerStates = {}
local playersWithWall = {} 
local currentPlayersData = {}

local function FormatHealthBar(current, max)
    local minHealth = 100
    if current <= minHealth or IsPedDeadOrDying(PlayerPedId(), 1) then return " 0%" end
    local adjustedHealth = current - minHealth
    local adjustedMax = max - minHealth
    if adjustedMax <= 0 then adjustedMax = 100 end
    local percentage = math.floor((adjustedHealth / adjustedMax) * 100)
    if percentage > 100 then percentage = 100 end
    if percentage < 0 then percentage = 0 end
    return " " .. percentage .. "%"
end

local function FormatArmourBar(current, max)
    local percentage = math.floor((current / max) * 100)
    return " " .. percentage .. "%"
end

local function ProcessPlayerStates()
    if not ShowNames then return end
    local myPlayerId = PlayerId()
    playerStates = {} 
    for _, player in ipairs(currentPlayersData) do
        local playerId = GetPlayerFromServerId(tonumber(player.id))
        if playerId ~= -1 then
            local ped = GetPlayerPed(playerId)
            if DoesEntityExist(ped) then
                local isVisible = IsEntityVisible(ped)
                local hasWall = playersWithWall[player.id] or false
                local health = GetEntityHealth(ped)
                local maxHealth = GetEntityMaxHealth(ped)
                local armor = GetPedArmour(ped)
                local infoLine = string.format("~w~%s ~w~| ID: ~b~%s ~w~| SRC: ~w~%s", player.name, player.cid, player.id)
                local tags = {}
                if not isVisible then table.insert(tags, "~r~[Invisível]") end
                if player.isStaff then table.insert(tags, "~o~[Staff]") end
                if hasWall then table.insert(tags, "~o~[Wall]") end
                local tagsLine = #tags > 0 and ("~w~" .. table.concat(tags, " ")) or nil
                local healthBar = FormatHealthBar(health, maxHealth)
                local isLowHealth = (health - 100) <= ((maxHealth - 100) * 0.3)
                local healthLine = string.format("~w~Vida: %s%s", isLowHealth and "~r~" or "~g~", healthBar)
                if armor > 0 then
                    healthLine = healthLine .. string.format(" ~w~| ~w~Colete: ~b~%s", FormatArmourBar(armor, 100))
                end
                local lines = {}
                table.insert(lines, infoLine)
                if tagsLine then table.insert(lines, tagsLine) end 
                table.insert(lines, healthLine)
                if ShowWeapons then
                    local weaponHash = GetSelectedPedWeapon(ped)
                    if weaponHash ~= `WEAPON_UNARMED` then
                        local weaponName = Config.Weapons[weaponHash] or "Arma Desconhecida"
                        table.insert(lines, "~w~Arma: ~c~" .. weaponName)
                    end
                end
                if ShowVehicles then
                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh ~= 0 then
                        local vehModel = GetEntityModel(veh)
                        local vehName = GetDisplayNameFromVehicleModel(vehModel)
                        local plate = GetVehicleNumberPlateText(veh)
                        table.insert(lines, string.format("~w~Veículo: ~y~%s ~w~(%s)", vehName, plate))
                    end
                end
                playerStates[player.id] = { 
                    lines = lines,
                    ped = ped
                }
            end
        end
    end
end

RegisterNetEvent('studioreborn:client:updateWallData', function(playersData, wallUsers)
    currentPlayersData = playersData
    playersWithWall = wallUsers
    ProcessPlayerStates()
end)

local function NotifyStatus(moduleName, state)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(state and ("~g~" .. moduleName .. " ativado.") or ("~r~" .. moduleName .. " desativado."))
    EndTextCommandThefeedPostTicker(false, true)
end

RegisterNetEvent('studioreborn:client:toggleWall', function()
    ShowNames = not ShowNames
    NotifyStatus("Wall Base", ShowNames)
    TriggerServerEvent('studioreborn:server:toggleWallState', ShowNames)
    if not ShowNames then
        playerStates = {}
        currentPlayersData = {}
        ShowLines, ShowWeapons, ShowVehicles = false, false, false
    end
end)

local function CloseWallUI()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hideUI" })
end

RegisterCommand('wall', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showUI",
        data = {
            base = ShowNames,
            lines = ShowLines,
            weapons = ShowWeapons,
            vehicles = ShowVehicles
        }
    })
end)

RegisterNUICallback('close', function(data, cb)
    CloseWallUI()
    cb('ok')
end)

RegisterNUICallback('toggleModule', function(data, cb)
    local module = data.module
    local state = data.state
    if module == "base" then
        ShowNames = state
        TriggerServerEvent('studioreborn:server:toggleWallState', ShowNames)
        if not ShowNames then
            playerStates = {}
            currentPlayersData = {}
            SendNUIMessage({ action = "forceDisableAll" })
        else
            ProcessPlayerStates()
        end
    elseif module == "lines" then
        ShowLines = state
    elseif module == "weapons" then
        ShowWeapons = state
        ProcessPlayerStates()
    elseif module == "vehicles" then
        ShowVehicles = state
        ProcessPlayerStates()
    end

    cb('ok')
end)

local function DrawText3D(x, y, z, lines, dist)
    local maxScale = 0.38
    local minScale = 0.25
    local distForMinScale = 80.0
    local scale = maxScale
    if dist >= distForMinScale then 
        scale = minScale 
    else
        local fraction = dist / distForMinScale
        scale = maxScale - (fraction * (maxScale - minScale))
    end
    SetDrawOrigin(x, y, z, 0)
    local dynamicGap = 0.022 * (scale / maxScale)
    local totalHeight = (#lines - 1) * dynamicGap
    for i = 1, #lines do
        local offset = (i - 1) * dynamicGap - (totalHeight / 2)
        SetTextScale(0.0, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(lines[i])
        DrawText(0.0, offset)
    end
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        Wait(1000)
        if ShowNames then ProcessPlayerStates() end
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        if ShowNames then
            sleep = 0 
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            local camCoords = GetGameplayCamCoords()
            for _, data in pairs(playerStates) do
                if DoesEntityExist(data.ped) then
                    local targetCoords = GetEntityCoords(data.ped)
                    local dist = #(camCoords - targetCoords)
                    if dist <= Config.MaxDistance then
                        if IsSphereVisible(targetCoords.x, targetCoords.y, targetCoords.z, 1.0) then
                            DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.0, data.lines, dist) 
                            if ShowLines then
                                DrawLine(myCoords.x, myCoords.y, myCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, 255, 255, 255, 100)
                            end
                        end
                        
                    end
                end
            end
        end
        Wait(sleep)
    end
end)