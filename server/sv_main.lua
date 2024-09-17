SpectateData = {}
local FrozenPlayers, GodmodeEnabled, CloakEnabled, StaminaEnabled, AmmoEnabled = {}, {}, {}, {}, {}

-- [ Callbacks ] --

QBCore.Functions.CreateCallback('j0-adminmenu/server/get-permission', function(Source, Cb)
    local Group = QBCore.Functions.GetPermission(Source)
    Cb(Group)
end)

QBCore.Functions.CreateCallback('j0-adminmenu/server/get-convar', function(source, Cb, ConvarName)
    Cb(GetConvar(ConvarName, 'none'))
end)

QBCore.Functions.CreateCallback('j0-admin/server/get-active-players-in-radius', function(Source, Cb, Coords, Radius)
	local Coords, Radius = Coords ~= nil and vector3(Coords.x, Coords.y, Coords.z) or GetEntityCoords(GetPlayerPed(Source)), Radius ~= nil and Radius or 5.0
    local ActivePlayers = {}
	for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local TargetCoords = GetEntityCoords(GetPlayerPed(v))
        local TargetDistance = #(TargetCoords - Coords)
        if TargetDistance <= Radius then
            ActivePlayers[#ActivePlayers + 1] = {
                ['ServerId'] = v,
                ['Name'] = GetPlayerName(v)
            }
        end
	end
	Cb(ActivePlayers)
end)

QBCore.Functions.CreateCallback('j0-admin/server/get-bans', function(source, Cb)
    local BanList = {}
    local BansData = MySQL.Sync.fetchAll('SELECT * FROM bans', {})
    if BansData and BansData[1] ~= nil then
        for k, v in pairs(BansData) do
            BanList[#BanList + 1] = {
                Text = v.name.." ("..v.banid..")",
                BanId = v.banid,
                Name = v.name,
                Reason = v.reason,
                Expires = os.date('*t', tonumber(v.expire)),
                BannedOn = os.date('*t', tonumber(v.bannedon)),
                BannedOnN = v.bannedon,
                BannedBy = v.bannedby,
                License = v.license ~= nil and v.license or v.steam,
                Discord = v.discord,
            }
        end
    end
    Cb(BanList)
end)

QBCore.Functions.CreateCallback('j0-admin/server/get-logs', function(source, Cb)
    local LogsList = {}
    local LogsData = MySQL.query.await('SELECT * FROM logs', {})
    if LogsData and LogsData[1] ~= nil then
        for k, v in pairs(LogsData) do
            LogsList[#LogsList + 1] = {
                Type = v.Type ~= nil and v.Type or "Unknown",
                Steam = v.Steam ~= nil and v.Steam  or "Unknown",
                Desc = v.Log ~= nil and v.Log or "Unknown",
                Date = v.Date ~= nil and v.Date or "Unknown",
                Cid = v.Cid ~= nil and v.Cid or "Unknown",
                Data = v.Data ~= nil and v.Data or "Unknown",
            }
        end
    end
    Cb(LogsList)
end)
 
QBCore.Functions.CreateCallback('j0-admin/server/get-players', function(source, Cb)
    local PlayerList = {}
    for i=1, #QBCore.Functions.GetPlayers() do
        local Player = QBCore.Functions.GetPlayers()[i]
        local Steam = QBCore.Functions.GetIdentifier(Player, "steam")
        local License = QBCore.Functions.GetIdentifier(Player, "license")
        PlayerList[#PlayerList + 1] = {
            ServerId = Player,
            Name = GetPlayerName(Player),
            Steam = Steam ~= nil and Steam or 'Not Found',
            License = License  ~= nil and License or Steam
        }
    end
    Cb(PlayerList)
end)

QBCore.Functions.CreateCallback('j0-admin/server/get-player-data', function(source, Cb, Identifier)
    local PlayerInfo = {}
    local TPlayer = nil
    if string.match(Identifier, "license:") then
        TPlayer = GetPlayerFromIdentifier('license', Identifier)
    elseif string.match(Identifier, "steam:") then
        TPlayer = GetPlayerFromIdentifier('steam', Identifier)
    end
    if TPlayer ~= nil then
        local Steam = QBCore.Functions.GetIdentifier(TPlayer.PlayerData.source, "steam")
        PlayerInfo = {
            Name = TPlayer.PlayerData.name,
            Steam = Steam ~= nil and Steam or 'Not found',
            CharName = TPlayer.PlayerData.charinfo.firstname..' '..TPlayer.PlayerData.charinfo.lastname,
            Source = TPlayer.PlayerData.source,
            CitizenId = TPlayer.PlayerData.citizenid
        }
        Cb(PlayerInfo)
    end
end)

QBCore.Functions.CreateCallback('j0-admin/server/get-date-difference', function(source, Cb, Bans, Type)
    local FilteredBans, BanAmount = GetDateDifference(Type, Bans) 
    Cb(FilteredBans, BanAmount)
end)

QBCore.Functions.CreateCallback("j0-admin/server/create-log", function(source, Cb, Type, Log, Data)
    if Type == nil or Log == nil then return end
    CreateLog(source, Type, Log, Data)
end)

-- [ Events ] --

AddEventHandler('playerConnecting', onPlayerConnecting)

RegisterNetEvent("j0-admin/server/try-open-menu", function(KeyPress)
    local src = source
    
    TriggerClientEvent('j0-admin/client/try-open-menu', src, KeyPress)
end)

-- User Commands

RegisterNetEvent("j0-admin/server/unban-player", function(BanId)
    local src = source
    

    local BanData = MySQL.query.await('SELECT * FROM bans WHERE banid = ?', {BanId})
    if BanData and BanData[1] ~= nil then
        MySQL.query('DELETE FROM bans WHERE banid = ?', {BanId})
        TriggerClientEvent('QBCore:Notify', src, Lang:t('bans.unbanned'), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('bans.not_banned'), 'error')
    end
end)

RegisterNetEvent("j0-admin/server/ban-player", function(ServerId, Expires, Reason)
    local src = source
    
    local License = QBCore.Functions.GetIdentifier(ServerId, 'license')
    local Steam = QBCore.Functions.GetIdentifier(ServerId, 'steam')
    local BanData = nil
    if License ~= nil then
        BanData = MySQL.query.await('SELECT * FROM bans WHERE license = ?', {License})
    else
        BanData = MySQL.query.await('SELECT * FROM bans WHERE steam = ?', {Steam})
    end
    if BanData and BanData[1] ~= nil then
        for k, v in pairs(BanData) do
            TriggerClientEvent('QBCore:Notify', src, Lang:t('bans.already_banned', {player = GetPlayerName(ServerId), reason = v.reason}), 'error')
        end
    else
        local Expiring, ExpireDate = GetBanTime(Expires)
        local Time = os.time()
        local BanId = "BAN-"..math.random(11111, 99999)
        MySQL.insert('INSERT INTO bans (banid, name, steam, license, discord, ip, reason, bannedby, expire, bannedon) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            BanId,
            GetPlayerName(ServerId),
            Steam,
            License,
            QBCore.Functions.GetIdentifier(ServerId, 'discord'),
            QBCore.Functions.GetIdentifier(ServerId, 'ip'),
            Reason,
            GetPlayerName(src),
            ExpireDate,
            Time,
        })
        TriggerClientEvent('QBCore:Notify', src, Lang:t('bans.success_banned', {player = GetPlayerName(ServerId), reason = Reason}), 'success')
        local ExpireHours = tonumber(Expiring['hour']) < 10 and "0"..Expiring['hour'] or Expiring['hour']
        local ExpireMinutes = tonumber(Expiring['min']) < 10 and "0"..Expiring['min'] or Expiring['min']
        local ExpiringDate = Expiring['day'] .. '/' .. Expiring['month'] .. '/' .. Expiring['year'] .. ' | '..ExpireHours..':'..ExpireMinutes
        if Expires == "Permanent" then
            DropPlayer(ServerId,  Lang:t('bans.perm_banned', {reason = Reason}))
        else
            DropPlayer(ServerId, Lang:t('bans.banned', {reason = Reason, expires = ExpiringDate}))
        end
    end
end)

RegisterNetEvent("j0-admin/server/kick-all-players", function(Reason)
    local src = source
    
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            DropPlayer(Player.PlayerData.source, Reason)
        end
    end
end)

RegisterNetEvent("j0-admin/server/kick-player", function(ServerId, Reason)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    DropPlayer(Source, Reason)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.kicked'), 'success')
end)

RegisterNetEvent("j0-admin/server/set-money", function(ServerId, MoneyType, MoneyAmount)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    TPlayer.Functions.SetMoney(MoneyType, MoneyAmount, 'Admin-Menu-Set-Money')
end)


RegisterNetEvent("j0-admin/server/give-money", function(ServerId, MoneyType, MoneyAmount)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    TPlayer.Functions.AddMoney(MoneyType, MoneyAmount, 'Admin-Menu-Give-Money')
end)

RegisterNetEvent("j0-admin/server/give-item", function(ServerId, ItemName, ItemAmount)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    TPlayer.Functions.AddItem(ItemName, ItemAmount)
    print(ItemName)
    TriggerClientEvent("hasib:additem", ItemName, ItemAmount)
end)

RegisterNetEvent('jomidar:additem', function(ItemName, ItemAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddItem(item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add")
end)
RegisterNetEvent("j0-admin/server/request-gang", function(ServerId, GangName)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    TPlayer.Functions.SetGang(GangName, 1, 'Admin-Menu-Give-Gang')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.setgang', {gangname = GangName}), 'success')
end)

RegisterNetEvent("j0-admin/server/request-job", function(ServerId, JobName)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    TPlayer.Functions.SetJob(JobName, 1, 'Admin-Menu-Give-Job')
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.setjob', {jobname = JobName}), 'success')
end)

RegisterNetEvent('j0-admin/server/start-spectate', function(ServerId)
    local src = source
    

    -- Check if Person exists
    local Target = GetPlayerPed(ServerId)
    if not Target then
        return TriggerClientEvent('QBCore:Notify', src, Lang:t('spectate.not_found'), 'error')
    end

    -- Make Check for Spectating
    local SteamIdentifier = QBCore.Functions.GetIdentifier(src, "steam")
    if SpectateData[SteamIdentifier] ~= nil then
        SpectateData[SteamIdentifier]['Spectating'] = true
    else
        SpectateData[SteamIdentifier] = {}
        SpectateData[SteamIdentifier]['Spectating'] = true
    end

    local tgtCoords = GetEntityCoords(Target)
    TriggerClientEvent('QBCore/client/specPlayer', src, ServerId, tgtCoords)
end)

RegisterNetEvent('j0-admin/server/stop-spectate', function()
    local src = source
    

    local SteamIdentifier = QBCore.Functions.GetIdentifier(src, "steam")
    if SpectateData[SteamIdentifier] ~= nil and SpectateData[SteamIdentifier]['Spectating'] then
        SpectateData[SteamIdentifier]['Spectating'] = false
    end
end)

RegisterNetEvent("j0-admin/server/drunk", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('j0-admin/client/drunk', Source)
end)

RegisterNetEvent("j0-admin/server/animal-attack", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('j0-admin/client/animal-attack', Source)
end)

RegisterNetEvent("j0-admin/server/set-fire", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('j0-admin/client/set-fire', Source)
end)

RegisterNetEvent("j0-admin/server/fling-player", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('j0-admin/client/fling-player', Source)
end)

RegisterNetEvent("j0-admin/server/play-sound", function(ServerId, SoundId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('j0-admin/client/play-sound', Source, SoundId)
end)

-- Utility Commands

RegisterNetEvent("j0-admin/server/toggle-blips", function()
    local src = source
    
    local BlipData = {}
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        BlipData[#BlipData + 1] = {
            ServerId = v,
            Name = GetPlayerName(v),
            Coords = GetEntityCoords(GetPlayerPed(v)),
        }
    end
    TriggerClientEvent('j0-admin/client/UpdatePlayerBlips', src, BlipData)
end)


RegisterNetEvent("j0-admin/server/teleport-all", function()
    local src = source
    
    
    local SourcePlayer = QBCore.Functions.GetPlayer(src)
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local TPlayer = QBCore.Functions.GetPlayer(v)
        if SourcePlayer ~= nil and TPlayer ~= nil then 
            if SourcePlayer.PlayerData.citizenid ~= TPlayer.PlayerData.citizenid then
                local SourceCoords = GetEntityCoords(GetPlayerPed(src))
                TriggerClientEvent('j0-admin/client/teleport-player', v, SourceCoords)
            end
        end
    end
end)

RegisterNetEvent("j0-admin/server/teleport-player", function(ServerId, Type)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local Msg = ""
    if Type == 'Goto' then
        Msg = Lang:t('info.teleported_to') 
        local TCoords = GetEntityCoords(GetPlayerPed(Source))
        TriggerClientEvent('j0-admin/client/teleport-player', src, TCoords)
    elseif Type == 'Bring' then
        Msg = Lang:t('info.teleported_brought')
        local Coords = GetEntityCoords(GetPlayerPed(src))
        TriggerClientEvent('j0-admin/client/teleport-player', Source, Coords)
    end
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.teleported', {tpmsg = Msg}), 'success')
end)

RegisterNetEvent("j0-admin/server/chat-say", function(Message)
    TriggerClientEvent('chat:addMessage', -1, {
        template = "<div class=chat-message server'><strong>"..Lang:t('info.announcement').." | </strong> {0}</div>",
        args = {Message}
    })
end)

-- Player Commands

-- Change this if needed changes
RegisterNetEvent("j0-admin/server/set-environment", function(Weather, Hour, Minute)
    local src = source
    
    Hour, Minute = tonumber(Hour), tonumber(Minute)

    if Weather ~= nil then
        local UpdatedWeather = exports['qb-weathersync']:setWeather(Weather)
        if UpdatedWeather ~= nil and UpdatedWeather then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('info.set_weather', {weather = Weather}), 'success')
        else
            DebugLog('Could not set weather, is the export valid? server/sv_main.lua line 380')
        end
    end
    if Hour ~= nil and Minute ~= nil then
        local UpdatedTime = exports['qb-weathersync']:setTime(Hour, Minute)
        if UpdatedTime ~= nil and UpdatedTime then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('info.set_time', {time = Hour..":"..Minute}), 'success')
        else
            DebugLog('Could not set time, is the export valid? server/sv_main.lua line 388')
        end
    end
end)

RegisterNetEvent("j0-admin/server/open-bennys", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('qb-customs:client:EnterCustomsOverride', Source) -- Custom Event for Bennys (Change to work with yours.)
end)

RegisterNetEvent("j0-admin/server/kill", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('hospital:client:KillPlayer', Source)
end)

RegisterNetEvent("j0-admin/server/delete-area", function(Type, Radius)
    local src = source
    

    TriggerClientEvent('j0-admin/client/delete-area', src, Type, Radius)
end)

RegisterNetEvent("j0-admin/server/freeze-player", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        local PData = TPlayer.PlayerData
        FrozenPlayers[PData.citizenid] = not FrozenPlayers[PData.citizenid]
        local Msg = FrozenPlayers[PData.citizenid] and Lang:t("info.gave_freeze", {frozenmsg =  Lang:t('commands.frozen')}) or Lang:t("info.gave_freeze", {frozenmsg =  Lang:t('commands.unfrozen')})
        local MsgType = FrozenPlayers[PData.citizenid] and 'success' or 'error'
        TriggerClientEvent('QBCore:Notify', src, Msg, MsgType)
        TriggerClientEvent('j0-admin/client/freeze-player', Source, FrozenPlayers[PData.citizenid])
    end
end)

RegisterNetEvent("j0-admin/server/toggle-infinite-ammo", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        local PData = TPlayer.PlayerData
        AmmoEnabled[PData.citizenid] = not AmmoEnabled[PData.citizenid]
        local Msg = AmmoEnabled[PData.citizenid] and Lang:t("commands.enabled") or Lang:t("commands.disabled")
        local MsgType = AmmoEnabled[PData.citizenid] and 'success' or 'error'
        TriggerClientEvent('QBCore:Notify', src, 'Infinite Ammo '..Msg, MsgType)
        TriggerClientEvent('j0-admin/client/toggle-infinite-ammo', Source, AmmoEnabled[PData.citizenid])
    end
end)

RegisterNetEvent("j0-admin/server/toggle-infinite-stamina", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        local PData = TPlayer.PlayerData
        StaminaEnabled[PData.citizenid] = not StaminaEnabled[PData.citizenid]
        local Msg = StaminaEnabled[PData.citizenid] and Lang:t("commands.enabled") or Lang:t("commands.disabled")
        local MsgType = StaminaEnabled[PData.citizenid] and 'success' or 'error'
        TriggerClientEvent('QBCore:Notify', src, 'Infinite Stamina '..Msg, MsgType)
        TriggerClientEvent('j0-admin/client/toggle-infinite-stamina', Source, StaminaEnabled[PData.citizenid])
    end
end)

RegisterNetEvent("j0-admin/server/toggle-cloak", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        local PData = TPlayer.PlayerData
        CloakEnabled[PData.citizenid] = not CloakEnabled[PData.citizenid]
        local Msg = CloakEnabled[PData.citizenid] and Lang:t("commands.enabled") or Lang:t("commands.disabled")
        local MsgType = CloakEnabled[PData.citizenid] and 'success' or 'error'
        TriggerClientEvent('QBCore:Notify', src, 'Cloak '..Msg, MsgType)
        TriggerClientEvent('j0-admin/client/toggle-cloak', Source, CloakEnabled[PData.citizenid])
    end
end)

RegisterNetEvent("j0-admin/server/toggle-godmode", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        local PData = TPlayer.PlayerData
        GodmodeEnabled[PData.citizenid] = not GodmodeEnabled[PData.citizenid]
        local Msg = GodmodeEnabled[PData.citizenid] and Lang:t('commands.enabled') or Lang:t('commands.disabled')
        local MsgType = GodmodeEnabled[PData.citizenid] and 'success' or 'error'
        TriggerClientEvent('QBCore:Notify', src, 'Godmode '..Msg, MsgType)
        TriggerClientEvent('j0-admin/client/toggle-godmode', Source, GodmodeEnabled[PData.citizenid])
    end
end)

RegisterNetEvent("j0-admin/server/set-food-drink", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        TPlayer.Functions.SetMetaData('thirst', 100)
        TPlayer.Functions.SetMetaData('hunger', 100)
        TriggerClientEvent('hud:client:UpdateNeeds', Source, 100, 100)
        TPlayer.Functions.Save()
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.gave_needs'), 'success')
    end
end)

RegisterNetEvent("j0-admin/server/remove-stress", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        TPlayer.Functions.SetMetaData('stress', 0)
        TriggerClientEvent('hud:client:UpdateStress', Source, 0)
        TPlayer.Functions.Save()
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.removed_stress'), 'success')
    end
end)

RegisterNetEvent("j0-admin/server/set-armor", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    if TPlayer ~= nil then
        SetPedArmour(GetPlayerPed(Source), 100)
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.gave_armor'), 'success')
    end
end)

RegisterNetEvent("j0-admin/server/reset-skin", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    local TPlayer = QBCore.Functions.GetPlayer(Source)
    local ClothingData = MySQL.Sync.fetchAll('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', { TPlayer.PlayerData.citizenid, 1 })
    if ClothingData[1] ~= nil then
        TriggerClientEvent("qb-clothes:loadSkin", Source, false, ClothingData[1].model, ClothingData[1].skin)
    else
        TriggerClientEvent("qb-clothes:loadSkin", Source, true)
    end
end)

RegisterNetEvent("j0-admin/server/set-model", function(ServerId, Model)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('j0-admin/client/set-model', Source, Model)
end)

RegisterNetEvent("j0-admin/server/revive-all", function()
    local src = source
    

    for k, v in pairs(QBCore.Functions.GetPlayers()) do
		local Player = QBCore.Functions.GetPlayer(v)
		if Player ~= nil then
            TriggerClientEvent('hospital:client:Revive', v, true)
		end
	end
end)

RegisterNetEvent("j0-admin/server/revive-in-distance", function(Radius)
    local src = source
    

    local Coords, Radius = GetEntityCoords(GetPlayerPed(src)), Radius ~= nil and tonumber(Radius) or 5.0
	for k, v in pairs(QBCore.Functions.GetPlayers()) do
		local Player = QBCore.Functions.GetPlayer(v)
		if Player ~= nil then
			local TargetCoords = GetEntityCoords(GetPlayerPed(v))
			local TargetDistance = #(TargetCoords - Coords)
			if TargetDistance <= Radius then
                TriggerClientEvent('hospital:client:Revive', v, true)
			end
		end
	end
end)

RegisterNetEvent("j0-admin/server/revive-target", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('hospital:client:Revive', Source, true)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.gave_revive'), 'success')
end)

RegisterNetEvent("j0-admin/server/open-clothing", function(ServerId)
    local src = source
    
    local Source = ServerId ~= nil and ServerId or src
    TriggerClientEvent('qb-clothing:client:openMenu', Source)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('info.gave_clothing'), 'success')
end)


RegisterNetEvent('j0-admin/server/sync-chat-data', function(Type, Data, UpdateDelay)
    UpdateDelay = UpdateDelay == nil and false or UpdateDelay
    if Type == 'Staffchat' then 
        Config.StaffChat = Data 
    else 
        Config.Reports = Data 
    end
    TriggerClientEvent('j0-admin/client/sync-chat-data', -1, Type, Type == 'Staffchat' and Config.StaffChat or Config.Reports, UpdateDelay)
end)

RegisterNetEvent("j0-admin/server/send-chat-report", function(ServerId, Message)
    TriggerClientEvent('chatMessage', ServerId, '', { 255, 255, 255 }, Message)
end)