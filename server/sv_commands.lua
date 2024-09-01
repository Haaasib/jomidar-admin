QBCore = exports['qb-core']:GetCoreObject()

-- [ Code ] --

-- [ Commands ] --

QBCore.Commands.Add('login', 'Login', {}, false, function(source)
    TriggerClientEvent('QBCore:Client:OnPlayerLoaded', -1)
end, 'god')

QBCore.Commands.Add(Config.Commands['MenuOpen'], Lang:t("info.keymapping_desc"), {}, false, function(source)
    TriggerClientEvent('j0-admin/client/try-open-menu', source, false)
end, 'admin')

QBCore.Commands.Add(Config.Commands['MenuDebug'], Lang:t("info.menu_debug"), {}, false, function(source)
    TriggerClientEvent('j0-admin/client/toggle-debug', source, false)
end, 'god')

QBCore.Commands.Add(Config.Commands['MenuReset'], Lang:t("info.reset_data"), {}, false, function(source)
    TriggerClientEvent('j0-admin/client/reset-menu', -1, false)
end, 'god')

QBCore.Commands.Add(Config.Commands['MenuPerms'], Lang:t("info.menu_perms"), {{name = "action", help = Lang:t('info.perm_action')}, {name = "commandid", help = Lang:t('info.commandid')}, {name = "group", help = Lang:t('info.rankid')}}, false, function(source, args)
    local Action = args[1]:lower()
    local CommandId = args[2]
    local Group = args[3] ~= nil and args[3]:lower() or false
    if Action ~= 'add' and Action ~= 'remove' and Action ~= 'list' then
        return TriggerClientEvent('QBCore:Notify', source, Lang:t('info.invalid_action'), 'error')
    end
    TriggerClientEvent('j0-admin/client/do-perms-action', source, Action, CommandId, Group)
end, 'god')

QBCore.Commands.Add(Config.Commands['ReportNew'], Lang:t("info.send_report"), {{name = "message", help = Lang:t('info.message')}}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    local Message = table.concat(args, ' ')
    if Message ~= nil then
        local ReportData = {
            ['Id'] = math.random(111111, 999999),
            ['ServerId'] = source,
            ['Chats'] = {
                {
                    ['Message'] = Message,
                    ['Time'] = CalculateTimeToDisplay(),
                    ['Sender'] = Player.PlayerData.name,
                }
            },
        }
        TriggerClientEvent('j0-admin/client/send-report', source, ReportData)
    end
end)

QBCore.Commands.Add(Config.Commands['ReportChat'], Lang:t("info.reply_report"), {{name = "message", help = Lang:t('info.message')}}, false, function(source, args)
    local Message = table.concat(args, ' ')
    if Message ~= nil then
        TriggerClientEvent('j0-admin/client/reply-report', source, Message, CalculateTimeToDisplay())
    end
end)

QBCore.Commands.Add(Config.Commands['ReportClose'], Lang:t("info.close_report"), {}, false, function(source, args)
    TriggerClientEvent('j0-admin/client/close-report', source)
end)

-- [ Console ] --

RegisterCommand(Config.Commands['APKick'], function(source, args, rawCommand)
    if source == 0 then
        local ServerId = tonumber(args[1])
        table.remove(args, 1)
        local Msg = table.concat(args, " ")
        DropPlayer(ServerId, Lang:t('info.kicked', {reason = Msg}))
    end
end, false)

RegisterCommand(Config.Commands['APAddItem'], function(source, args, rawCommand)
    if source == 0 then
        local ServerId, ItemName, ItemAmount = tonumber(args[1]), tostring(args[2]), tonumber(args[3])
        local Player = QBCore.Functions.GetPlayer(ServerId)
        if Player ~= nil then
            Player.Functions.AddItem(ItemName, ItemAmount, false, false)
            print(Lang:t('info.gaveitem', {amount = ItemAmount, name = ItemName}))
        end
    end
end, false)

RegisterCommand(Config.Commands['APAddMoney'], function(source, args, rawCommand)
    if source == 0 then
        local ServerId, Amount = tonumber(args[1]), tonumber(args[2])
        local Player = QBCore.Functions.GetPlayer(ServerId)
        if Player ~= nil then
            Player.Functions.AddMoney('cash', Amount)
            print(Lang:t('info.gavemoney', {amount = Amount, moneytype = 'Cash'}))
        end
    end
end, false)

RegisterCommand(Config.Commands['APSetJob'], function(source, args, rawCommand)
    if source == 0 then
        local ServerId, JobName, Grade = tonumber(args[1]), tostring(args[2]), tonumber(args[3])
        local Player = QBCore.Functions.GetPlayer(ServerId)
        if Player ~= nil then
            Player.Functions.SetJob(JobName, Grade)
            print(Lang:t('info.setjob', {jobname = JobName}))
        end
    end
end, false)

RegisterCommand(Config.Commands['APRevive'], function(source, args, rawCommand)
    if source == 0 then
        local ServerId = tonumber(args[1])
        TriggerClientEvent('hospital:client:Revive', ServerId, true)
        print(Lang:t('info.gave_revive'))
    end
end, false)