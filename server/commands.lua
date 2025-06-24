------------------------------------
------------------------------------
---- DONT TOUCH ANY OF THIS IF YOU DON'T KNOW WHAT YOU ARE DOING
---- THESE ARE **NOT** CONFIG VALUES, USE THE CONVARS IF YOU WANT TO CHANGE SOMETHING
----
----
---- If you are a developer and want to change something, consider writing a plugin instead:
---- https://easyadmin.readthedocs.io/en/latest/plugins/
----
------------------------------------
------------------------------------

-- Function to check if player is on duty
local function IsPlayerOnDuty(source)
    -- Check if duty system is enabled via convar
    local isDutySystemEnabled = GetConvar('ea_DutySystemEnabled', 'false') == true
    
    -- If duty system is disabled, always return true
    if isDutySystemEnabled then
        return true
    end
    
    -- Otherwise check player state
    return Player(source).state["easyadmin-ox:clockedIn"] == 'yes'
end

RegisterCommand("ea_addShortcut", function(source, args, rawCommand)
	if args[2] and DoesPlayerHavePermission(source, "server.shortcut.add") then
		local shortcut = args[1]
		local text = table.concat(args, " ", 2)
		
		PrintDebugMessage("added '"..shortcut.." -> "..text.."' as a shortcut", 3)
		MessageShortcuts[shortcut] = text
		
		for i,_ in pairs(OnlineAdmins) do 
			TriggerLatentClientEvent("EasyAdmin:fillShortcuts", i, 10000, MessageShortcuts)
		end
	end
end)

RegisterCommand("ea_addReminder", function(source, args, rawCommand)
	if args[1] and DoesPlayerHavePermission(source, "server.reminder.add") then
		local text = string.gsub(rawCommand, "ea_addReminder ", "")
		local text = string.gsub(text, '"', '')
		
		PrintDebugMessage("added '"..text.."' as a Chat Reminder", 3)
		table.insert(ChatReminders, text)
	end
end, false)

RegisterCommand("ea_printIdentifiers", function(source,args,rawCommand)
	if source == 0 and args[1] then -- only let Console run this command
		local id = tonumber(args[1])
		print(json.encode(CachedPlayers[id].identifiers)) -- puke all identifiers into console
	end
end,false)

Citizen.CreateThread(function()
	RegisterCommand("ea_generateSupportFile", function(source, args, rawCommand)
		if DoesPlayerHavePermission(source, "server") then
			print("SupportFile is no longer supported, please use eaDiag instead.")
		end
	end, false)
	
end)

RegisterCommand("spectate", function(source, args, rawCommand)
    if(source == 0) then
        Citizen.Trace(GetLocalisedText("badidea")) -- Maybe should be it's own string saying something like "only players can do this" or something
    end
    
    PrintDebugMessage("Player "..getName(source,true).." Requested Spectate on "..getName(args[1],true), 3)
    
    if args[1] and tonumber(args[1]) and DoesPlayerHavePermission(source, "player.spectate") then
        if getName(args[1]) then
            TriggerClientEvent("EasyAdmin:requestSpectate", source, args[1])
        else
            TriggerClientEvent("EasyAdmin:showNotification", source, GetLocalisedText("playernotfound"))
        end
    end
end, false)


RegisterCommand("setgametype", function(source, args, rawCommand)
    if args[1] and DoesPlayerHavePermission(source, "server.convars") then
        PrintDebugMessage("Player "..getName(source,true).." set Gametype to "..args[1], 3)
        SetGameType(args[1])
    end
end, false)

RegisterCommand("setmapname", function(source, args, rawCommand)
    if args[1] and DoesPlayerHavePermission(source, "server.convars") then
        PrintDebugMessage("Player "..getName(source,true).." set Map Name to "..args[1], 3)
        SetMapName(args[1])
    end
end, false)

RegisterCommand("slap", function(source, args, rawCommand)
    if args[1] and args[2] and DoesPlayerHavePermission(source, "player.slap") then
        local preferredWebhook = detailNotification ~= "false" and detailNotification or moderationNotification
        SendWebhookMessage(preferredWebhook,string.format(GetLocalisedText("adminslappedplayer"), getName(source, false, true), getName(args[1], true, true), args[2]), "slap", 16711680)
        PrintDebugMessage("Player "..getName(source,true).." slapped "..getName(args[1],true).." for "..args[2].." HP", 3)
        TriggerClientEvent("EasyAdmin:SlapPlayer", args[1], args[2])
    end
end, false)	

RegisterCommand("adres", function(source, args, rawCommand)    if DoesPlayerHavePermission(source, "player.adres") then
        if IsPlayerOnDuty(source) then
            local target = args[1] or source
            if target then
                if GetPlayerName(target) ~= nil then
                    TriggerClientEvent('DeathScript:Admin:Respawn', target, 0, true)
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Success',
                        description = 'Player has been respawned!',
                        type = 'success'
                    })
                else
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Error',
                        description = 'Invalid ID!',
                        type = 'error'
                    })
                end
            end
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'You are not clocked in!',
                type = 'error'
            })
        end
    end
end, false)

RegisterCommand("adrev", function(source, args, rawCommand)    
    if DoesPlayerHavePermission(source, "player.adrev") then
        if IsPlayerOnDuty(source) then
            local target = args[1] or source
            if target then
                if GetPlayerName(target) ~= nil then
                    TriggerClientEvent('DeathScript:Admin:Revive', target, 0, true)
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Success',
                        description = 'Player has been revived!',
                        type = 'success'
                    })
                else
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Error',
                        description = 'Invalid ID!',
                        type = 'error'
                    })
                end
            end
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'You are not clocked in!',
                type = 'error'
            })
        end
    end
end, false)

RegisterCommand("adrevall", function(source, args, rawCommand)    
    if DoesPlayerHavePermission(source, "player.adrevall") then
        if IsPlayerOnDuty(source) then
            TriggerClientEvent('DeathScript:Admin:Revive', -1, source, true)
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Success',
                description = 'Players have been revived!',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'You are not clocked in!',
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Unexpected error.',
            type = 'error'
        })
    end
end, false)

RegisterCommand("adresall", function(source, args, rawCommand)    
    if DoesPlayerHavePermission(source, "player.adresall") then
        if IsPlayerOnDuty(source) then
            TriggerClientEvent('DeathScript:Admin:Respawn', -1, source, true)
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Success',
                description = 'Players have been respawned!',
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                description = 'You are not clocked in!',
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Error',
            description = 'Unexpected error.',
            type = 'error'
        })
    end
end, false)

