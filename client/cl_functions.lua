AllPlayerBlips, Group = {}, nil

-- [ Code ] --

-- [ Essential Functions ] --

function InitAdminMenu()
    if (GetServerConvar('steam_webApiKey') == 'none') then DebugPrint('steam', Lang:t("info.steam_key")) end
    TriggerEvent('chat:addSuggestion', '/'..Config.Commands['MenuOpen'], Lang:t("info.keymapping_desc"))
    TriggerEvent('chat:addSuggestion', '/'..Config.Commands['MenuDebug'], Lang:t("info.menu_debug"))
    TriggerEvent('chat:addSuggestion', '/'..Config.Commands['MenuReset'], Lang:t("info.reset_data"))
    TriggerEvent('chat:addSuggestion', '/'..Config.Commands['MenuPerms'], Lang:t("info.menu_perms"), { { name = "action", help = Lang:t('info.perm_action') }, { name = "commandid", help = Lang:t('info.commandid') }, { name = "group", help = Lang:t('info.rankid') } })
    TriggerEvent('chat:addSuggestion', '/'..Config.Commands['ReportNew'], Lang:t("info.send_report"), { { name = "message", help = Lang:t('info.message') } })
    TriggerEvent('chat:addSuggestion', '/'..Config.Commands['ReportChat'], Lang:t("info.reply_report"), { { name = "message", help = Lang:t('info.message') } })
    TriggerEvent('chat:addSuggestion', '/'..Config.Commands['ReportClose'], Lang:t("info.close_report"))
    Citizen.Wait(100)
    RefreshMenu('all')
    Citizen.CreateThread(StartBlipsLoop)
    LoggedIn = true
end

function ToggleMenu(IsUpdate)
    local Bans = GetBans()
    local Players = GetPlayers()
    local Logs = GetLogs()
    local Commands = GetCommands()
    local Favorites = GetResourceKvpInfo('favorites')['Value']
    local Pinned = GetResourceKvpInfo('pinned_targets')['Value']
    local Options = GetResourceKvpInfo('options')['Value']
    if not IsUpdate then
        SetCursorLocation(0.87, 0.15)
        SetNuiFocus(true, true)
    end
    SendNUIMessage({
        Action = not IsUpdate and 'Open' or 'Update',
        -- Needs Refresh
        Debug = Config.Settings['Debug'],
        Bans = Bans,
        AllPlayers = Players,
        Logs = Logs,
        Favorited = next(Favorites) ~= nil and Favorites or {},
        PinnedPlayers = Pinned,
        MenuOptions = next(Options) ~= nil and Options or {},
        Commands = Commands,
        Reports = Config.Reports,
        Staffchat = Config.StaffChat,
        Name = QBCore.Functions.GetPlayerData().name,
        Pages = Config.Settings['Pages'],
        BanTypes = Config.BanTimeCategories,
    })
end

function ToggleDevMode(Bool)
    Config.Settings['DebugToggle'](Bool)
end

function DoPermsAction(Action, CommandId, Group)
    local Groups = GetResourceKvpInfo('command_perms')['Value']
    if Action == 'add' then
        if CommandId == 'all' then
            for k, v in pairs(Groups) do
                for l=1, #Groups[k] do -- Check if Group already exists
                    if Groups[k][l] == Group then 
                        return
                    end
                end
                table.insert(Groups[k], Group)
            end
            QBCore.Functions.Notify(Lang:t('info.perms_added_all'))
        end
    elseif Action == 'remove' then
        if CommandId == 'all' then -- Remove From Every Table
            if not Group then return QBCore.Functions.Notify(Lang:t('info.perms_group_exist')) end
            for k,_ in pairs(Groups) do
                for l=1, #Groups[k] do -- Get Group Number in Table
                    local SearchGroup = Groups[k][l]
                    if SearchGroup == Group then
                        table.remove(Groups[k], l)
                        if next(Groups[k]) == nil then
                            table.insert(Groups[k], 'all')
                        end
                    end
                end
            end
            QBCore.Functions.Notify(Lang:t('info.perms_removed_all'))
        end
    end
    for p, q in pairs(Config.CommandList) do
        local Command = q
        for j=1, #Command['Items'] do
            local Item = Command['Items'][j]
            if not Item['UseKVPGroups'] then return QBCore.Functions.Notify(Lang:t('info.perms_disabled')) end
            if Groups ~= nil then
                if Action == 'add' then
                    if CommandId ~= 'all' and Groups[CommandId] ~= nil and Item['Id'] == CommandId then 
                        for k, v in pairs(Groups[CommandId]) do -- Check if Group already exists
                            if v == Group then 
                                return QBCore.Functions.Notify(Lang:t('info.perms_exist')) 
                            end
                        end
                        table.insert(Groups[CommandId], Group)
                        QBCore.Functions.Notify(Lang:t('info.perms_added'))
                    end
                elseif Action == 'remove' then
                    if CommandId ~= 'all' and Groups[CommandId] ~= nil and Item['Id'] == CommandId then
                        for k, v in pairs(Groups[CommandId]) do
                            if k == #Groups[CommandId]+1 and v ~= Group then return QBCore.Functions.Notify(Lang:t('info.perms_not_exist')) end
                            if v == Group then  
                                table.remove(Groups[CommandId], k)
                                if next(Groups[CommandId]) == nil then
                                    DebugPrint('permissions', 'KVP Permissions for command: '..CommandId..' are empty. Adding default permissions.')
                                    table.insert(Groups[CommandId], 'all')
                                end
                                QBCore.Functions.Notify(Lang:t('info.perms_removed'))
                            end
                        end
                    end
                elseif Action == 'list' then
                    if Groups[CommandId] ~= nil then 
                        if Item['Id'] == CommandId then
                            return QBCore.Functions.Notify(Lang:t('info.perms_list', { command = CommandId, groups = json.encode(Groups[CommandId]) }))
                        end
                    else
                        return QBCore.Functions.Notify(Lang:t('info.perms_command_exist'))
                    end
                end
            end
        end
    end
    if Action == 'add' or Action == 'remove' then
        SetKvp('command_perms', CommandId ~= 'all' and CommandId or nil, CommandId ~= 'all' and Groups[CommandId] or Groups)
        SendNUIMessage({
            Action = 'Update',
            Single = {
                Name = 'Commands',
                Updates = { -- Update things
                    {
                        Name = 'Commands', -- Variable Name in JS.
                        Data = GetCommands(), -- Data for Variable.
                    }
                }
            }
        })
    end
end

function SetKvp(Name, Data, SetData)
    local KvpInfo, KvpId = GetResourceKvpInfo(Name)
    if Data ~= nil and SetData ~= nil then
        Config.ResourceKVPs[KvpId]['Value'][Data] = SetData
    elseif Data == nil and SetData ~= nil then
        Config.ResourceKVPs[KvpId]['Value'] = SetData
    else
        Config.ResourceKVPs[KvpId]['Value'][#Config.ResourceKVPs[KvpId]['Value'] + 1] = Data
    end
    SetResourceKvp('j0-adminmenu-'..Name, json.encode(Config.ResourceKVPs[KvpId]['Value']))
    Wait(100)
    RefreshMenu(Name)
end

function GenerateKVP(KVPName)
    Wait(50)
    if KVPName == nil then Prom:resolve({}) DebugPrint('kvp', 'KVP creation failed: name not found, options will not save!') return end
    local ReturnData = {}
    local Prom = promise:new()
    if KVPName == 'favorites' then
        for u = 1, #Config.CommandList do
            local Command = Config.CommandList[u]
            for i = 1, #Command['Items'] do
                local Item = Command['Items'][i]
                ReturnData[Item.Id] = false
            end
        end
        Prom:resolve(ReturnData)
    elseif KVPName == 'pinned_targets' then
        local Players = GetPlayers()
        for i = 1, #Players do
            local Player = Players[i]
            ReturnData[Player.License ~= nil and Player.License or Player.Steam] = false
        end
        Prom:resolve(ReturnData)
    elseif KVPName == 'options' then
        ReturnData['LargeDefault'] = false
        ReturnData['BindOpen'] = true
        ReturnData['Tooltips'] = true
        ReturnData['Resizer'] = true
        Prom:resolve(ReturnData)
    elseif KVPName == 'command_perms' then
        for k, v in pairs(Config.CommandList) do
            for j = 1, #v['Items'] do
                local Item = v['Items'][j]
                if Item['UseKVPGroups'] then
                    ReturnData[Item.Id] = {'all'}
                end
            end
        end
        Prom:resolve(ReturnData)
    end
    return Citizen.Await(Prom)
end

function GetResourceKvpInfo(Name)
    for i = 1, #Config.ResourceKVPs do
        if Config.ResourceKVPs[i]['Name']:lower() == Name:lower() then
            return Config.ResourceKVPs[i], i
        end
    end
    return false
end

function ResetMenuKvp()
    for i = 1, #Config.ResourceKVPs do
        SetResourceKvp("j0-adminmenu-" .. Config.ResourceKVPs[i]['Name'], "[]")
        Config.ResourceKVPs[i]['Value'] = {}
    end
    RefreshMenu('all')
end

function RefreshMenu(Type)
    if Type == nil then return end
    Type = Type:lower()
    if Type == 'all' then -- Generate All
        for i=1, #Config.ResourceKVPs do
            local KVP = Config.ResourceKVPs[i]
            if GetResourceKvpString("j0-adminmenu-"..KVP['Name']) == nil or GetResourceKvpString("j0-adminmenu-"..KVP['Name']) == "[]" then
                KVP['Value'] = GenerateKVP(KVP['Name'])
                SetResourceKvp("j0-adminmenu-"..KVP['Name'], json.encode(KVP['Value']))
            else
                KVP['Value'] = json.decode(GetResourceKvpString("j0-adminmenu-"..KVP['Name']))
            end
        end
    elseif Type == 'favorites' or Type == 'targets' or Type == 'options' or Type == 'command_perms' then
        local KVP = Config.ResourceKVPs[Type == 'favorites' and 1 or Type == 'targets' and 2 or Type == 'options' and 3 or Type == 'command_perms' and 4]
        if GetResourceKvpString("j0-adminmenu-"..KVP['Name']) == nil or GetResourceKvpString("j0-adminmenu-"..KVP['Name']) == "[]" then
            KVP['Value'] = GenerateKVP(Type)
            SetResourceKvp("j0-adminmenu-"..KVP['Name'], json.encode(KVP['Value']))
        else
            KVP['Value'] = json.decode(GetResourceKvpString("j0-adminmenu-" .. KVP['Name']))
        end
    end
    if Type == 'favorites' then -- Update Favorites
        local Favorites = GetResourceKvpInfo('favorites')['Value']
        SendNUIMessage({
            Action = 'Update',
            Single = {
                Name = 'Commands',
                Updates = { -- Update things
                    {
                        Name = 'FavoritedItems', -- Variable Name in JS.
                        Data = next(Favorites) ~= nil and Favorites or {}, -- Data for Variable.
                    }
                }
            }
        })
    end
    ToggleMenu(true)
end

function CanBind()
    local Prom = promise:new()
    local BindInfo = GetResourceKvpInfo('options')
    if BindInfo then
        if BindInfo['Value']['BindOpen'] ~= nil and BindInfo['Value']['BindOpen'] then
            Prom:resolve(true)
        else
            Prom:resolve(false)
        end
    else
        Prom:resolve(true)
    end
    return Citizen.Await(Prom)
end

function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
        local iter, id = initFunc()
        if not id or id == 0 then
            disposeFunc(iter)
            return
        end
        local enum = { handle = iter, destructor = disposeFunc }
        setmetatable(enum, entityEnumerator)
        local next = true
        repeat
            coroutine.yield(id)
            next, id = moveFunc(iter)
        until not next
        enum.destructor, enum.handle = nil, nil
        disposeFunc(iter)
    end)
end

function DebugPrint(Comp, Message)
    if Config.Settings['Debug'] then
        print('[' .. GetCurrentResourceName() .. ':' .. Comp .. ']: ' .. Message)
    end
end

function DrawText3D(Coords, Text)
    local OnScreen, _X, _Y = World3dToScreen2d(Coords.x, Coords.y, Coords.z)
    SetTextScale(0.3, 0.3)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 0, 0, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(Text)
    DrawText(_X, _Y)
end

function roundDecimals(num, decimals)
    local mult = math.pow(10, decimals or 0)
    return math.floor(num * mult + 0.5) / 100
end

-- [ Menu Functions ] --

function ToggleDev(Bool)
    Bool = Bool ~= nil and Bool or not Bool
    Config.Settings['DebugToggle'](Bool)
end

function CreateLog(Type, Log, Data)
    if Type == nil or Log == nil then return end
    QBCore.Functions.TriggerCallback('j0-admin/server/create-log', function(result)
    end, Type, Log, Data)
end

function HasReport()
    if next(Config.Reports) ~= nil then
        for i = 1, #Config.Reports do
            local Report = Config.Reports[i]
            if Report['ServerId'] == GetPlayerServerId(PlayerId()) then
                return true
            end
        end
    end
    return false
end

function DeleteReport(ReportId)
    if next(Config.Reports) ~= nil then
        for i = 1, #Config.Reports do
            local Report = Config.Reports[i]
            if Report['Id'] == ReportId then
                SetTimeout(500, function()
                    table.remove(Config.Reports, i)
                    TriggerServerEvent('j0-admin/server/sync-chat-data', 'Reports', Config.Reports, 1500)
                end)
                return true, Report['ServerId']
            end
        end
    end
    return false
end

function AddReportMessage(ReportId, Message, Time)
    if next(Config.Reports) ~= nil then
        for i = 1, #Config.Reports do
            local Report = Config.Reports[i]
            if Report['Id'] == ReportId then
                SetTimeout(500, function()
                    local NewMessage = {
                        ['Message'] = Message,
                        ['Time'] = Time,
                        ['Sender'] = QBCore.Functions.GetPlayerData().name,
                    }
                    Report['Chats'][#Report['Chats'] + 1] = NewMessage
                    TriggerServerEvent('j0-admin/server/sync-chat-data', 'Reports', Config.Reports, 1500)
                end)
                return true
            end
        end
    end
    return false
end

function DeletePlayerBlips()
    if AllPlayerBlips ~= nil then
        for i = 1, #AllPlayerBlips do
            local Blip = AllPlayerBlips[i]
            RemoveBlip(Blip)
        end
        AllPlayerBlips = {}
    end
end

function SetInfiniteAmmo(Bool)
    if next(Config.Weapons) ~= nil then
        for i = 1, #Config.Weapons do
            local Weapon = GetHashKey(Config.Weapons[i])
            SetPedInfiniteAmmo(PlayerPedId(), Bool, Weapon)
        end
    else
        DebugPrint('ammo', 'No weapons found to enable infinite ammo, check config for typos.')
    end
end

function DeletePeds(Radius)
    local Peds = GetPedsInArea(nil, Radius)
    for _, entity in pairs(Peds) do
        SetEntityAsMissionEntity(entity)
        DeletePed(entity)
        SetEntityAsNoLongerNeeded(entity)
        DebugPrint('peds', 'Deleted Ped: ' .. entity .. ' Radius: ' .. Radius)
    end
end

function DeleteVehs(Radius)
    local Vehicles = GetVehiclesInArea(nil, Radius)
    for _, entity in pairs(Vehicles) do
        SetEntityAsMissionEntity(entity)
        DeleteVehicle(entity)
        SetEntityAsNoLongerNeeded(entity)
        DebugPrint('vehicles', 'Deleted Vehicle: ' .. entity .. ' Radius: ' .. Radius)
    end
end

function DeleteObjs(Radius)
    local Objects = GetGamePool('CObject')
    for _, entity in pairs(Objects) do
        local ObjectCoords = GetEntityCoords(entity)
        local Coords = GetEntityCoords(PlayerPedId())
        local Dist = GetDistanceBetweenCoords(ObjectCoords, Coords.x, Coords.y, Coords.z, true)
        if Dist <= Radius then
            SetEntityAsMissionEntity(entity)
            DeleteObject(entity)
            SetEntityAsNoLongerNeeded(entity)
            DebugPrint('object', 'Deleted Object: ' .. entity .. ' Radius: ' .. Radius)
        end
    end
end

function StartBlipsLoop()
    while true do
        Citizen.Wait(4)
        if LoggedIn then
            if BlipsEnabled then
                if BlipData ~= nil then
                    DeletePlayerBlips()
                    local ServerId = GetPlayerServerId(PlayerId())
                    for i=1, #BlipData do
                        local Blip = BlipData[i]
                        if tonumber(Blip.ServerId) ~= tonumber(ServerId) then
                            local PlayerPed = GetPlayerPed(GetPlayerFromServerId(Blip.ServerId))
                            local PlayerBlip = AddBlipForEntity(PlayerPed) 
                            SetBlipSprite(PlayerBlip, 1)
                            SetBlipColour(PlayerBlip, 0)
                            SetBlipScale(PlayerBlip, 0.75)
                            SetBlipAsShortRange(PlayerBlip, true)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentString('['..Blip.ServerId..'] '..Blip.Name)
                            EndTextCommandSetBlipName(PlayerBlip)
                            AllPlayerBlips[#AllPlayerBlips + 1] = PlayerBlip
                        end
                    end    
                end
                Citizen.Wait(5000)
            else
                if next(AllPlayerBlips) ~= nil then
                    DeletePlayerBlips()
                    Citizen.Wait(450)
                end
            end
        else
            Citizen.Wait(450)
        end
    end
end

-- [ Get Functions ] --

function GetServerConvar(Convar)
    local Prom = promise:new()
    QBCore.Functions.TriggerCallback('j0-adminmenu/server/get-convar', function(ReturnData)
        Prom:resolve(ReturnData)
    end, Convar)
    return Citizen.Await(Prom)
end

function GetReportIdFromId(Id)
    if next(Config.Reports) ~= nil then
        for i = 1, #Config.Reports do
            local Report = Config.Reports[i]
            if Report['Id'] == Id then
                return i
            end
        end
    end
    return false
end

function GetPlayerReportFromName()
    local Player = QBCore.Functions.GetPlayerData()
    if Player ~= nil then
        local Name = Player.name
        for i = 1, #Config.Reports do
            local Report = Config.Reports[i]
            if Report['Chats'][1]['Sender'] == Name then
                return i
            end
        end
    end
    return false
end

function DoesItemExistInTable(FilteredCommands, Category, CommandItem)
    for i=1, #FilteredCommands do
        local Item = FilteredCommands[i]
        if Item['Id'] == CommandItem['Id'] then
            return true
        end
    end
    return false
end

function GetCommands()
    local Prom = promise:new()
    local FilteredCommands = {}
    if next(Config.CommandList) ~= nil then
        for i = 1, #Config.CommandList do -- Categories
            local Category = Config.CommandList[i]
            FilteredCommands[Category['Id']] = {
                ['Id'] = Category['Id'],
                ['Name'] = Category['Name'],
                ['Items'] = {},
            }
            for u = 1, #Category['Items'] do -- Category Items
                local CommandItem = Category['Items'][u]
                local Command = Category['Id']
                if (CommandItem['Id'] == 'banPlayer' or CommandItem['Id'] == 'unbanPlayer') and not Config.Settings['Bans']['BanSystem'] then
                else
                    if CommandItem['UseKVPGroups'] then -- Use KVP Groups
                        local Groups = GetResourceKvpInfo('command_perms')['Value']
                        if Groups and Groups ~= nil then
                            for k,_ in pairs(Groups) do
                                if k == CommandItem['Id'] then
                                    for v = 1, #Groups[k] do
                                        local CommandGroup = Groups[k][v]:lower()
                                        local Group, Bool = GetPlayerRank()
                                        if Group and (Bool ~= nil and CommandGroup == Group and Bool) or (Bool == nil and CommandGroup == Group) or CommandGroup == 'all' then -- CommandGroup is user group or 'all' then 
                                            -- Check if already exists
                                            if not DoesItemExistInTable(FilteredCommands[Command]['Items'], Category, CommandItem) then
                                                FilteredCommands[Command]['Items'][#FilteredCommands[Command]['Items'] + 1] = CommandItem
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            if not DoesItemExistInTable(FilteredCommands[Command]['Items'], Category, CommandItem) then
                                FilteredCommands[Command]['Items'][#FilteredCommands[Command]['Items'] + 1] = CommandItem
                            end
                        end
                    else -- Use Config Groups
                        if CommandItem['Groups'] ~= nil then
                            for j = 1, #CommandItem['Groups'] do
                                local Group, Bool = GetPlayerRank()
                                local CommandGroup = CommandItem['Groups'][j]:lower()
                                if Group and (Bool ~= nil and CommandGroup == Group and Bool) or (Bool == nil and CommandGroup == Group) or CommandGroup == 'all' then -- CommandGroup is user group or 'all' then 
                                    if not DoesItemExistInTable(FilteredCommands[Command]['Items'], Category, CommandItem) then
                                        FilteredCommands[Command]['Items'][#FilteredCommands[Command]['Items'] + 1] = CommandItem
                                    end
                                end
                            end
                        else
                            if not DoesItemExistInTable(FilteredCommands[Command]['Items'], Category, CommandItem) then
                                FilteredCommands[Command]['Items'][#FilteredCommands[Command]['Items'] + 1] = CommandItem
                            end
                        end
                    end
                end
            end
        end
    else
        DebugPrint('commands', 'No commands found to filter, check the Config.CommandList for typos.')
    end
    Prom:resolve(FilteredCommands)
    return Citizen.Await(Prom)
end

function GetPlayerRank()
    local Prom = promise:new()
    if Group ~= nil then -- Old QB
        if type(Group) ~= 'table' then
            Prom:resolve(Group, nil)
        else -- New QB
            for Rank, Bool in pairs(Group) do
                Prom:resolve(Rank, Bool)
            end
        end
    else
        Prom:resolve(false, nil)
        DebugPrint('permissions', 'Player group not found, not able to execute permission check.')
    end
    return Citizen.Await(Prom)
end

function GetPlayersInArea(Coords, Radius)
    local Prom = promise:new()
    QBCore.Functions.TriggerCallback('j0-admin/server/get-active-players-in-radius', function(Players)
        Prom:resolve(Players)
    end, Coords, Radius)
    return Citizen.Await(Prom)
end

function GetBans()
    local Prom = promise:new()
    QBCore.Functions.TriggerCallback("j0-admin/server/get-bans", function(Bans)
        Prom:resolve(Bans)
    end)
    return Citizen.Await(Prom)
end

function GetPlayers()
    local Prom = promise:new()
    QBCore.Functions.TriggerCallback("j0-admin/server/get-players", function(Players)
        Prom:resolve(Players)
    end)
    return Citizen.Await(Prom)
end

function GetLogs()
    local Prom = promise:new()
    QBCore.Functions.TriggerCallback("j0-admin/server/get-logs", function(Logs)
        Prom:resolve(Logs)
    end)
    return Citizen.Await(Prom)
end

function GetDeletionTypes()
    local DeletionTypes = {}
    local Types = { 'Objects', 'Peds', 'Vehicles', 'All' }
    for i = 1, #Types do
        DeletionTypes[#DeletionTypes + 1] = {
            Text = Types[i],
        }
        table.sort(DeletionTypes, function(a, b)
            return a.Text < b.Text
        end)
    end
    return DeletionTypes
end

function GetModels()
    local Models = {}
    local ModelList = Config.Models
    if ModelList ~= nil then
        for k, v in pairs(ModelList) do
            Models[#Models + 1] = {
                Text = v,
            }
            table.sort(Models, function(a, b)
                return a.Text < b.Text
            end)
        end
    else
        DebugPrint('models', 'Could not access Config.Models, please check if you have any typo\'s in the config.')
    end
    return Models
end

function GetInventoryItems()
    local Prom = promise:new()
    local Inventory = {}
    local ItemList = QBShared.Items
    if ItemList ~= nil then
        for k, v in pairs(ItemList) do
            Inventory[#Inventory + 1] = {
                Text = v['name'] ~= nil and v['name'] or 'Not found'
            }
            table.sort(Inventory, function(a, b)
                return a.Text < b.Text
            end)
        end
        Prom:resolve(Inventory)
    else
        DebugPrint('inventory', 'Could not access QBShared.Items, please check if you have the latest version of QBCore or the right name for the items shared.')
    end
    return Citizen.Await(Prom)
end

function GetMoneyTypes()
    local Prom = promise:new()
    local MoneyTypes = {}
    local Types = QBCore.Config.Money.MoneyTypes
    if Types ~= nil then
        for k, v in pairs(Types) do
            MoneyTypes[#MoneyTypes + 1] = {
                Text = k,
            }
            table.sort(MoneyTypes, function(a, b)
                return a.Text < b.Text
            end)
        end
        Prom:resolve(MoneyTypes)
    else
        DebugPrint('money', 'Could not access Config.Money.MoneyTypes, please check if you have the latest version of QBCore or the right name for the qb-core config.')
    end
    return Citizen.Await(Prom)
end

function GetFarts()
    local Prom = promise:new()
    local FartList = {}
    local Farts = Config.FartNoises
    if Farts ~= nil then
        for k, v in pairs(Farts) do
            FartList[#FartList + 1] = {
                Text = v['SoundName'],
                Label = ' [' .. v['Name'] .. ']'
            }
            table.sort(FartList, function(a, b)
                return a.Text < b.Text
            end)
        end
        Prom:resolve(FartList)
    else
        DebugPrint('farts', 'Could not access Config.FartNoises, please check that you don\'t have any typos.')
    end
    return Citizen.Await(Prom)
end

function GetGangs()
    local Prom = promise:new()
    local GangsList = {}
    local Gangs = QBShared.Gangs
    if Gangs ~= nil then
        for k, v in pairs(Gangs) do
            GangsList[#GangsList + 1] = {
                Text = k,
                Label = ' [' .. v['label'] .. ']'
            }
            table.sort(GangsList, function(a, b)
                return a.Text < b.Text
            end)
        end
        Prom:resolve(GangsList)
    else
        DebugPrint('gangs', 'Could not access QBShared.Gangs, please check if you have the latest version of QBCore or the right name for the gangs shared.')
    end
    return Citizen.Await(Prom)
end

function GetJobs()
    local Prom = promise.new()
    local JobList = {}
    local Jobs = QBCore.Shared.Jobs  -- Updated reference to the latest QBCore
    if Jobs ~= nil then
        for k, v in pairs(Jobs) do
            JobList[#JobList + 1] = {
                Text = k,
                Label = ' [' .. v.label .. ']'  -- Access fields directly without ['']
            }
        end
        -- Sorting outside the loop for efficiency
        table.sort(JobList, function(a, b)
            return a.Text < b.Text
        end)
        Prom:resolve(JobList)
    else
        print('Could not access QBCore.Shared.Jobs, please check if you have the latest version of QBCore or the right name for the jobs shared.')
    end
    return Citizen.Await(Prom)
end


function GetAddonVehicles()
    local Prom = promise.new()
    local Vehicles = QBCore.Shared.Vehicles  -- Updated reference to the latest QBCore
    local AddonVehicles = {}
    if Vehicles ~= nil then
        for k, v in pairs(Vehicles) do
            local VehName = v.name or 'Unknown Name'
            local VehBrand = v.brand or 'Unknown Brand'
            local VehModel = v.model or 'Unknown Model'

            -- Handling custom category logic
            if Config.Settings.Cars.Custom then
                if v.category and v.category == Config.Settings.Cars.CustomCat then
                    AddonVehicles[#AddonVehicles + 1] = {
                        Text = VehModel,
                        Label = ' [' .. VehBrand .. ' ' .. VehName .. ']'
                    }
                end
            else
                AddonVehicles[#AddonVehicles + 1] = {
                    Text = VehModel,
                    Label = ' [' .. VehBrand .. ' ' .. VehName .. ']'
                }
            end
        end
        -- Sorting outside the loop for efficiency
        table.sort(AddonVehicles, function(a, b)
            return a.Text < b.Text
        end)
        Prom:resolve(AddonVehicles)
    else
        print('Could not access QBCore.Shared.Vehicles, please check if you have the latest version of QBCore or the right name for the vehicles shared.')
    end
    return Citizen.Await(Prom)
end


function GetWeatherTypes()
    local WeatherTypes = {}
    local Types = Config.WeatherTypes
    if Types ~= nil then
        for i = 1, #Types do
            WeatherTypes[#WeatherTypes + 1] = {
                Text = Types[i]
            }
            table.sort(WeatherTypes, function(a, b)
                return a.Text < b.Text
            end)
        end
    else
        DebugPrint('weather', 'Could not access Config.WeatherTypes, please check if you have any typo\'s in the config.')
    end
    return WeatherTypes
end

function GetVehicles()
    local Vehicles = {}
    for veh in EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle) do
        Vehicles[#Vehicles + 1] = veh
    end
    return Vehicles
end

function GetPeds()
    local Peds = {}
    for ped in EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed) do
        local FoundPed = false
        if not FoundPed then
            Peds[#Peds + 1] = ped
        end
    end
    return Peds
end

function GetPedsInArea(Coords, Radius)
    if Coords == nil then Coords = GetEntityCoords(PlayerPedId()) end
    local Peds = GetPeds()
    local PedsInArea = {}
    for i = 1, #Peds, 1 do
        local PedCoords = GetEntityCoords(Peds[i])
        local Dist = GetDistanceBetweenCoords(PedCoords, Coords.x, Coords.y, Coords.z, true)
        if Dist <= Radius then
            PedsInArea[#PedsInArea + 1] = Peds[i]
        end
    end
    return PedsInArea
end

function GetVehiclesInArea(Coords, Radius)
    if Coords == nil then Coords = GetEntityCoords(PlayerPedId()) end
    local Vehs = GetVehicles()
    local VehiclesInArea = {}
    for i = 1, #Vehs, 1 do
        local VehicleCoords = GetEntityCoords(Vehs[i])
        local Dist = GetDistanceBetweenCoords(VehicleCoords, Coords.x, Coords.y, Coords.z, true)
        if Dist <= Radius then
            VehiclesInArea[#VehiclesInArea + 1] = Vehs[i]
        end
    end
    return VehiclesInArea
end
