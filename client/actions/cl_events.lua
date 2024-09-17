BlipsEnabled, NamesEnabled, BlipData = false, false, {}

-- [ Code ] --

-- [ Events ] --

RegisterNetEvent("Admin:Bennys", function(Result)
   
    TriggerServerEvent('j0-admin/server/open-bennys', Result['player'])
end)

RegisterNetEvent("Admin:Kill", function(Result)
   
    TriggerServerEvent('j0-admin/server/kill', Result['player'])
end)

RegisterNetEvent("Admin:Set:Environment", function(Result)
   
    TriggerServerEvent('j0-admin/server/set-environment', Result['weather'], Result['hour'], Result['minute'])
end)

RegisterNetEvent("Admin:Delete:Area", function(Result)
   
    TriggerServerEvent('j0-admin/server/delete-area', Result['type'], Result['radius'])
end)

RegisterNetEvent("Admin:Infinite:Ammo", function(Result)
   
    TriggerServerEvent('j0-admin/server/toggle-infinite-ammo', Result['player'])
end)

RegisterNetEvent("Admin:Infinite:Stamina", function(Result)
   
    TriggerServerEvent('j0-admin/server/toggle-infinite-stamina', Result['player'])
end)

RegisterNetEvent("Admin:Cloak", function(Result)
   
    TriggerServerEvent('j0-admin/server/toggle-cloak', Result['player'])
end)

RegisterNetEvent("Admin:Godmode", function(Result)
   
    TriggerServerEvent('j0-admin/server/toggle-godmode', Result['player'])
end)

RegisterNetEvent('Admin:Toggle:Noclip', function(Result)
   
    TriggerEvent('j0-admin/client/force-close')
    SendNUIMessage({
        Action = "SetItemEnabled",
        Name = 'noclip',
        State = not noClipEnabled
    })
    toggleFreecam(not noClipEnabled)
end)

RegisterNetEvent('Admin:Fix:Vehicle', function(Result)
   
    TriggerEvent('j0-admin/client/force-close')
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        SetVehicleFixed(GetVehiclePedIsIn(PlayerPedId(), true))
    else
        local Vehicle, Distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        SetVehicleFixed(Vehicle)
    end 
end)

RegisterNetEvent('Admin:Delete:Vehicle', function(Result)
   
    TriggerEvent('j0-admin/client/force-close')
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        DeleteVehicle(GetVehiclePedIsIn(PlayerPedId(), true))
    else
        local Vehicle, Distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        DeleteVehicle(Vehicle)
    end
end)

RegisterNetEvent('Admin:Spawn:Vehicle', function(Result)
   
    TriggerEvent('j0-admin/client/force-close')
    TriggerEvent('QBCore:Command:SpawnVehicle', Result['model'])
end)

RegisterNetEvent('Admin:Teleport:Marker', function(Result)
    
    TriggerEvent('j0-admin/client/force-close')
    TriggerEvent('QBCore:Command:GoToMarker')
end)

RegisterNetEvent('Admin:Teleport:Coords', function(Result)
   
    if Result['x-coord'] ~= '' and Result['y-coord'] ~= '' and Result['z-coord'] ~= '' then
        TriggerEvent('j0-admin/client/force-close')
        SetEntityCoords(PlayerPedId(), tonumber(Result['x-coord']), tonumber(Result['y-coord']), tonumber(Result['z-coord']))
    end
end)

RegisterNetEvent('Admin:Teleport', function(Result)
    
    TriggerEvent('j0-admin/client/force-close')
    TriggerServerEvent('j0-admin/server/teleport-player', Result['player'], Result['type'])
end)

RegisterNetEvent("Admin:Chat:Say", function(Result)
   
    TriggerServerEvent('j0-admin/server/chat-say', Result['message'])
end)

RegisterNetEvent('Admin:Open:Clothing', function(Result)
   
    TriggerEvent('j0-admin/client/force-close')
    TriggerServerEvent('j0-admin/server/open-clothing', Result['player'])
end)

RegisterNetEvent('Admin:Revive:Radius', function(Result)
   
    TriggerServerEvent('j0-admin/server/revive-in-distance', Result['radius'])
end)

RegisterNetEvent('Admin:Revive', function(Result)
   
    TriggerServerEvent('j0-admin/server/revive-target', Result['player'])
end)

RegisterNetEvent('Admin:Remove:Stress', function(Result)
   
    TriggerServerEvent('j0-admin/server/remove-stress', Result['player'])
end)

RegisterNetEvent('Admin:Change:Model', function(Result)
   
    if Result['model'] ~= '' then
        local Model = GetHashKey(Result['model'])
        if IsModelValid(Model) then
            TriggerServerEvent('j0-admin/server/set-model', Result['player'], Model)
        end
    end
end)

RegisterNetEvent('Admin:Reset:Model', function(Result)
   
    TriggerServerEvent('j0-admin/server/reset-skin', Result['player'])
end)

RegisterNetEvent('Admin:Armor', function(Result)
   
    TriggerServerEvent('j0-admin/server/set-armor', Result['player'])
end)

RegisterNetEvent('Admin:Food:Drink', function(Result)
   
    TriggerServerEvent('j0-admin/server/set-food-drink', Result['player'])
end)

RegisterNetEvent('Admin:Request:Gang', function(Result)
   
    TriggerServerEvent('j0-admin/server/request-gang', Result['player'], Result['gang'] ~= '' and Result['gang'] or 'none')
end)

RegisterNetEvent('Admin:Request:Job', function(Result)
   
    TriggerServerEvent('j0-admin/server/request-job', Result['player'], Result['job'] ~= '' and Result['job'] or 'unemployed')
end)

RegisterNetEvent("Admin:Drunk", function(Result)
   
    TriggerServerEvent('j0-admin/server/drunk', Result['player'])
end)

RegisterNetEvent("Admin:Animal:Attack", function(Result)
   
    TriggerServerEvent('j0-admin/server/animal-attack', Result['player'])
end)

RegisterNetEvent('Admin:Set:Fire', function(Result)
   
    TriggerServerEvent('j0-admin/server/set-fire', Result['player'])
end)

RegisterNetEvent('Admin:Fling:Player', function(Result)
   
    TriggerServerEvent('j0-admin/server/fling-player', Result['player'])
end)

RegisterNetEvent("Admin:Freeze:Player", function(Result)
   
    TriggerServerEvent('j0-admin/server/freeze-player', Result['player'])
end)

RegisterNetEvent('Admin:SetMoney', function(Result)
   
    TriggerServerEvent('j0-admin/server/set-money', Result['player'], Result['moneytype'], Result['amount'])
end)

RegisterNetEvent('Admin:GiveMoney', function(Result)
   

    TriggerServerEvent('j0-admin/server/give-money', Result['player'], Result['moneytype'], Result['amount'])
end)

RegisterNetEvent('Admin:GiveItem', function(Result)
   

    TriggerServerEvent('j0-admin/server/give-item', Result['player'], Result['item'], Result['amount'])
end)

RegisterNetEvent('Admin:Ban', function(Result)
   
    TriggerServerEvent('j0-admin/server/ban-player', Result['player'], Result['expire'], Result['reason'])
end)

RegisterNetEvent('Admin:Unban', function(Result)
    
    TriggerServerEvent("j0-admin/server/unban-player", Result['player'])
end)

RegisterNetEvent('Admin:Kick', function(Result)
    
    TriggerServerEvent('j0-admin/server/kick-player', Result['player'], Result['reason'])
end)

RegisterNetEvent('Admin:Kick:All', function(Result)
   
   TriggerServerEvent('j0-admin/server/kick-all-players', Result['reason'])
end)

RegisterNetEvent("Admin:Copy:Coords", function(Result)
   
    local Coords, Heading = GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId())
    local X, Y, Z, H = roundDecimals(Coords.x, 2), roundDecimals(Coords.y, 2), roundDecimals(Coords.z, 2), roundDecimals(Heading, 2)
    SendNUIMessage({
        Action = 'Copy',
        String = Result['type'] == 'vector3(0.0, 0.0, 0.0)' and 'vector3('..X..', '..Y..', '..Z..')' or
                 Result['type'] == 'vector4(0.0, 0.0, 0.0, 0.0)' and 'vector4('..X..', '..Y..', '..Z..', '..H..')' or
                 Result['type'] == '0.0, 0.0, 0.0' and ''..X..', '..Y..', '..Z..'' or
                 Result['type'] == '0.0, 0.0, 0.0, 0.0' and ''..X..', '..Y..', '..Z..', '..H..'' or
                 Result['type'] == 'X = 0.0, Y = 0.0, Z = 0.0' and 'X = '..X..', Y = '..Y..', Z = '..Z..'' or
                 Result['type'] == 'x = 0.0, y = 0.0, z = 0.0' and 'x = '..X..', y = '..Y..', z = '..Z..'' or
                 Result['type'] == 'X = 0.0, Y = 0.0, Z = 0.0, H = 0.0' and 'X = '..X..', Y = '..Y..', Z = '..Z..', H = '..H or
                 Result['type'] == 'x = 0.0, y = 0.0, z = 0.0, h = 0.0' and 'x = '..X..', y = '..Y..', z = '..Z..', h = '..H or
                 Result['type'] == '["X"] = 0.0, ["Y"] = 0.0, ["Z"] = 0.0' and '["X"] = '..X..', ["Y"] = '..Y..', ["Z"] = '..Z or
                 Result['type'] == '["x"] = 0.0, ["y"] = 0.0, ["z"] = 0.0' and '["x"] = '..X..', ["y"] = '..Y..', ["z"] = '..Z or
                 Result['type'] == '["X"] = 0.0, ["Y"] = 0.0, ["Z"] = 0.0, ["H"] = 0.0' and '["X"] = '..X..', ["Y"] = '..Y..', ["Z"] = '..Z..', ["H"] = '..H or
                 Result['type'] == '["x"] = 0.0, ["y"] = 0.0, ["z"] = 0.0, ["h"] = 0.0' and '["x"] = '..X..', ["y"] = '..Y..', ["z"] = '..Z..', ["h"] = '..H
    })
end)

RegisterNetEvent("Admin:Fart:Player", function(Result)
   
    TriggerServerEvent('j0-admin/server/play-sound', Result['player'], Result['fart'])
end)

RegisterNetEvent('Admin:Toggle:PlayerBlips', function()
   
    BlipsEnabled = not BlipsEnabled
    TriggerServerEvent('j0-admin/server/toggle-blips')
    SendNUIMessage({
        Action = "SetItemEnabled",
        Name = 'playerblips',
        State = BlipsEnabled
    })
    if not BlipsEnabled then
        DeletePlayerBlips()
    end
end)

RegisterNetEvent('Admin:Toggle:PlayerNames', function()
   
    NamesEnabled = not NamesEnabled
    SendNUIMessage({
        Action = "SetItemEnabled",
        Name = 'playernames',
        State = NamesEnabled
    })
    if NamesEnabled then
        local Players = GetPlayersInArea(nil, 15.0)
        CreateThread(function()
            while NamesEnabled do
                Citizen.Wait(2000)
                Players = GetPlayersInArea(nil, 15.0)
            end
        end)
        CreateThread(function()
            while NamesEnabled do
                for i=1, #Players do
                    local Ped = GetPlayerPed(GetPlayerFromServerId(tonumber(Players[i]['ServerId'])))
                    local PedCoords = GetPedBoneCoords(Ped, 0x796e)
                    local PedHealth = GetEntityHealth(Ped) / GetEntityMaxHealth(Ped) * 100
                    local PedArmor = GetPedArmour(Ped)
                    DrawText3D(vector3(PedCoords.x, PedCoords.y, PedCoords.z + 0.5), ('[%s] - %s ~n~'..Lang:t("commands.health")..': %s - '..Lang:t("commands.armor")..': %s'):format(Players[i]['ServerId'], Players[i]['Name'], math.floor(PedHealth), math.floor(PedArmor)))
                end
                Wait(1)
            end
        end)
    end
end)

RegisterNetEvent('Admin:Toggle:Spectate', function(Result)
   
    if not SpectateEnabled then
        TriggerServerEvent('j0-admin/server/start-spectate', Result['player'])
    else
        ToggleSpectate(StoredTargetPed)
        TriggerServerEvent('j0-admin/server/stop-spectate')
    end
end)

RegisterNetEvent("Admin:OpenInv", function(Result)
   
    TriggerEvent('j0-admin/client/force-close')
    TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", Result['player'])
end)

-- [ Triggered Events ] --

RegisterNetEvent("j0-admin/client/delete-area", function(Type, Radius)
    Type = Type:lower()
    Radius = tonumber(Radius)
    if Type == 'peds' then
        DeletePeds(Radius)
    elseif Type == 'vehicles' then
        DeleteVehs(Radius)
    elseif Type == 'objects' then
        DeleteObjs(Radius)
    elseif Type == 'all' then
        DeletePeds(Radius)
        DeleteVehs(Radius)
        DeleteObjs(Radius)
    end
end)

RegisterNetEvent("j0-admin/client/freeze-player", function(Bool)
    FreezeEntityPosition(GetPlayerPed(PlayerId()), Bool)
end)

RegisterNetEvent("j0-admin/client/toggle-infinite-ammo", function(Bool)
    while Bool do
        Wait(1)
        SetInfiniteAmmo(true)
    end
    SetTimeout(250, function()
        SetInfiniteAmmo(false)
    end)
end)

RegisterNetEvent("j0-admin/client/toggle-infinite-stamina", function(Bool)
    while Bool do
        Wait(1)
        RestorePlayerStamina(PlayerId(), 1.0)
    end
end)

RegisterNetEvent("j0-admin/client/toggle-cloak", function(Bool)
    if Bool then
        SetEntityVisible(PlayerPedId(), false)
    else
        SetEntityVisible(PlayerPedId(), true)
    end
end)

RegisterNetEvent("j0-admin/client/toggle-godmode", function(Bool)
    while Bool do
        Wait(1)
        SetPlayerInvincible(PlayerId(), true)
    end
    SetTimeout(250, function()
        SetPlayerInvincible(PlayerId(), false)
    end)
end)

RegisterNetEvent('j0-admin/client/teleport-player', function(Coords)
    local Entity = PlayerPedId()    
    SetPedCoordsKeepVehicle(Entity, Coords.x, Coords.y, Coords.z)
end)

RegisterNetEvent('j0-admin/client/set-model', function(Model)
    QBCore.Functions.LoadModel(Model)
    SetPlayerModel(PlayerId(), Model)
    SetPedComponentVariation(PlayerPedId(), 0, 0, 0, 0)
end)

RegisterNetEvent('j0-admin/client/armor-up', function()
    SetPedArmour(PlayerPedId(), 100.0)
end)

RegisterNetEvent("j0-admin/client/play-sound", function(Sound)
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, Sound, 0.3)
end)

RegisterNetEvent('j0-admin/client/DeletePlayerBlips', function()
   
    DeletePlayerBlips()
end)

RegisterNetEvent('j0-admin/client/UpdatePlayerBlips', function(Data)
   
    BlipData = Data
end)

AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
        local victim, attacker, victimDied = data[1], data[2], data[4]
        if not IsEntityAPed(victim) then return end
        if victimDied and NetworkGetPlayerIndexFromPed(victim) == PlayerId() and IsEntityDead(PlayerPedId()) then
            if SpectateEnabled then
                ToggleSpectate(storedTargetPed)
                TriggerServerEvent('j0-admin/server/stop-spectate')
            end
        end
    end
end)
