local lastSpectateLocation = {}
local StoredTargetPlayerId = -1
local storedGameTag = ""
SpectateEnabled = false
StoredTargetPed = nil

-- [ Code ] --

-- [ Threads ] --

CreateThread(function()
    while true do
        if SpectateEnabled then
            createGamerTagInfo()
        else
            clearGamerTagInfo()
        end
        Wait(50)
    end
end)

-- [ Functions ] --

function InstructionalButton(controlButton, text)
    ScaleformMovieMethodAddParamPlayerNameString(controlButton)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function calculateSpectatorCoords(coords)
    return vec3(coords[1], coords[2], coords[3] - 15.0)
end

function createGamerTagInfo()
    if storedGameTag and IsMpGamerTagActive(storedGameTag) then return end
    local nameTag = ('[%d] %s'):format(GetPlayerServerId(StoredTargetPlayerId), GetPlayerName(StoredTargetPlayerId))
    storedGameTag = CreateFakeMpGamerTag(StoredTargetPed, nameTag, false, false, '', 0, 0, 0, 0)
    SetMpGamerTagVisibility(storedGameTag, 2, 1)  --set the visibility of component 2(healthArmour) to true
    SetMpGamerTagAlpha(storedGameTag, 2, 255) --set the alpha of component 2(healthArmour) to 255
    SetMpGamerTagHealthBarColor(storedGameTag, 129) --set component 2(healthArmour) color to 129(HUD_COLOUR_YOGA)
    SetMpGamerTagVisibility(storedGameTag, 4, NetworkIsPlayerTalking(i))
end

function clearGamerTagInfo()
    if not storedGameTag then return end
    RemoveMpGamerTag(storedGameTag)
    storedGameTag = nil
end

function preparePlayerForSpec(bool)
    local PlayerPed = PlayerPedId()
    FreezeEntityPosition(PlayerPed, bool)
    SetEntityVisible(PlayerPed, not bool, 0)
end

function createSpectatorTeleportThread()
    CreateThread(function()
        while SpectateEnabled do
            Wait(500)
            if not DoesEntityExist(StoredTargetPed) then
                local _ped = GetPlayerPed(StoredTargetPlayerId)
                if _ped > 0 then
                    if _ped ~= StoredTargetPed then
                        StoredTargetPed = _ped
                    end
                    StoredTargetPed = _ped
                else
                    ToggleSpectate(StoredTargetPed, StoredTargetPlayerId)
                    break
                end
            end
            local newSpectateCoords = calculateSpectatorCoords(GetEntityCoords(StoredTargetPed))
            SetEntityCoords(PlayerPedId(), newSpectateCoords.x, newSpectateCoords.y, newSpectateCoords.z, 0, 0, 0, false)
        end
    end)
end

function ToggleSpectate(targetPed, targetPlayerId)
    local PlayerPed = PlayerPedId()
    if SpectateEnabled then
        SpectateEnabled = false
        if not lastSpectateLocation then error('Last location previous to spectate was not stored properly') end
        if not StoredTargetPed then error('Target ped was not stored to unspectate') end

        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        RequestCollisionAtCoord(lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z)
        SetEntityCoords(PlayerPed, lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z - 1.0)
        while not HasCollisionLoadedAroundEntity(PlayerPed) do Wait(5) end

        preparePlayerForSpec(false)
        NetworkSetInSpectatorMode(false, StoredTargetPed)
        clearGamerTagInfo()
        DoScreenFadeIn(500)
        QBCore.Functions.Notify(Lang:t('spectate.toggled', {toggled_spectate = Lang:t('commands.stopped'), player = GetPlayerName(StoredTargetPlayerId)..' ('..GetPlayerServerId(StoredTargetPlayerId)..')'}))
        StoredTargetPed = nil
    else
        -- Store Ped and Coords
        StoredTargetPed = targetPed
        StoredTargetPlayerId = targetPlayerId
        local targetCoords = GetEntityCoords(targetPed)
        RequestCollisionAtCoord(targetCoords.x, targetCoords.y, targetCoords.z)
        while not HasCollisionLoadedAroundEntity(targetPed) do Wait(5) end
        NetworkSetInSpectatorMode(true, targetPed)
        DoScreenFadeIn(500)
        QBCore.Functions.Notify(Lang:t('spectate.toggled', {toggled_spectate = Lang:t('commands.started'), player = GetPlayerName(StoredTargetPlayerId)..' ('..GetPlayerServerId(StoredTargetPlayerId)..')'}))
        SpectateEnabled = true
        createSpectatorTeleportThread()
    end
end

function cleanupFailedResolve()
    local PlayerPed = PlayerPedId()

    RequestCollisionAtCoord(lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z)
    SetEntityCoords(PlayerPed, lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z)
    while not HasCollisionLoadedAroundEntity(PlayerPed) do Wait(5) end
    preparePlayerForSpec(false)
    DoScreenFadeIn(500)

    QBCore.Functions.Notify(Lang:t('spectate.stopped_not_found'), 'error')
end

-- [ Events ] --

RegisterNetEvent('QBCore/client/specPlayer', function(targetServerId, coords)
    
    local spectatorPed = PlayerPedId()
    lastSpectateLocation = GetEntityCoords(spectatorPed)

    local targetPlayerId = GetPlayerFromServerId(targetServerId)
    if targetPlayerId == PlayerId() then
        return QBCore.Functions.Notify(Lang:t('spectate.self'), 'error')
    end
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local tpCoords = calculateSpectatorCoords(coords)
    SetEntityCoords(spectatorPed, tpCoords.x, tpCoords.y, tpCoords.z, 0, 0, 0, false)
    preparePlayerForSpec(true)
    local resolvePlayerAttempts = 0
    local resolvePlayerFailed
    repeat
        if resolvePlayerAttempts > 100 then
            resolvePlayerFailed = true
            break;
        end
        Wait(50)
        targetPlayerId = GetPlayerFromServerId(targetServerId)
        resolvePlayerAttempts = resolvePlayerAttempts + 1
    until (GetPlayerPed(targetPlayerId) > 0) and targetPlayerId ~= -1

    if resolvePlayerFailed then
        return cleanupFailedResolve()
    end
    ToggleSpectate(GetPlayerPed(targetPlayerId), targetPlayerId)
end)