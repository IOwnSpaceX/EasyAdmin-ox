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

players = {}
banlist = {}
cachedplayers = {}
reports = {}
add_aces, add_principals = {}, {}
MessageShortcuts = {}
FrozenPlayers = {}
MutedPlayers = {}
MyBucket = 0

local cachedInfo = {
	ped = PlayerPedId(),
	veh = 0,
	player = PlayerId(),
}

local vehicleInfo = {
	netId = nil,
	seat = nil,
}

RegisterNetEvent("EasyAdmin:adminresponse", function(perms)
	permissions = perms

	for perm, val in pairs(perms) do
		if val == true then
			isAdmin = true
		end
	end
end)

RegisterNetEvent("EasyAdmin:SetSetting", function(setting,state)
	settings[setting] = state
end)

AddEventHandler('EasyAdmin:SetLanguage', function(newstrings)
	strings = newstrings
end)

RegisterNetEvent("EasyAdmin:fillBanlist", function(thebanlist)
	banlist = thebanlist
end)

RegisterNetEvent("EasyAdmin:fillCachedPlayers", function(thecached)
	if permissions["player.ban.temporary"] or permissions["player.ban.permanent"] then
		cachedplayers = thecached
	end
end)


RegisterNetEvent("EasyAdmin:GetInfinityPlayerList", function(players)
	playerlist = players
end)

RegisterNetEvent("EasyAdmin:getServerAces", function(aces,principals)
	add_aces = aces
	add_principals = principals
	PrintDebugMessage("Recieved ACE Permissions list", 4)
end)

RegisterNetEvent("EasyAdmin:SetLanguage", function()
	if permissions["server.permissions.read"] then
		TriggerServerEvent("EasyAdmin:getServerAces")
	end
end)

RegisterNetEvent("EasyAdmin:NewReport", function(reportData)
	reports[reportData.id] = reportData
end)

RegisterNetEvent("EasyAdmin:ClaimedReport", function(reportData)
	reports[reportData.id] = reportData
	if _menuPool and _menuPool:IsAnyMenuOpen() then
		for i, menu in pairs(reportMenus) do
			for o,item in pairs(menu.Items) do 
				if getMenuItemTitle(item) == GetLocalisedText("claimreport") then
					setMenuItemTitle(item, GetLocalisedText("claimedby"))
					item:RightLabel(reportData.claimedName)
				end
			end
		end
	end
end)

RegisterNetEvent("EasyAdmin:RemoveReport", function(reportData)
	reports[reportData.id] = nil 
end)


RegisterNetEvent("EasyAdmin:fillShortcuts", function (shortcuts)
	MessageShortcuts = shortcuts
end)

RegisterNetEvent('EasyAdmin:SetPlayerFrozen', function(player,state)
	FrozenPlayers[player] = state
	if _menuPool and _menuPool:IsAnyMenuOpen() then
		if playerMenus[tostring(player)].menu then
			for o,item in pairs(playerMenus[tostring(player)].menu.Items) do 
				if getMenuItemTitle(item) == GetLocalisedText("setplayerfrozen") then
					item.Checked = state
				end
			end
		end
	end
end)

RegisterNetEvent('EasyAdmin:SetPlayerMuted', function(player,state)
	MutedPlayers[player] = state
	if _menuPool and _menuPool:IsAnyMenuOpen() then
		if playerMenus[tostring(player)].menu then
			for o,item in pairs(playerMenus[tostring(player)].menu.Items) do 
				if getMenuItemTitle(item) == GetLocalisedText("mute") then
					item.Checked = state
				end
			end
		end
	end
end)

function FreezeMyself(state)

	if state then
		if frozen then return end -- prevents double threads
		CreateThread(function()
	
			while frozen do 
	
				FreezeEntityPosition(cachedInfo.ped, frozen)
				if cachedInfo.veh ~= 0 then
					FreezeEntityPosition(cachedInfo.veh, frozen)
				end
				DisablePlayerFiring(cachedInfo.player, true)
	
				Wait(0)
	
			end
	
		end)
	else
		-- unfreeze
		local localPlayerPedId = PlayerPedId()
		FreezeEntityPosition(localPlayerPedId, false)
		if IsPedInAnyVehicle(localPlayerPedId, true) then
			FreezeEntityPosition(GetVehiclePedIsIn(localPlayerPedId, true), false)
		end
	end

end

RegisterNetEvent("EasyAdmin:CopyDiscord", function(discord)
	copyToClipboard(discord)
end)

RegisterNetEvent("EasyAdmin:requestSpectate", function(playerServerId, playerData)
	
	local localPlayerPed = PlayerPedId()
	
	if IsPedInAnyVehicle(localPlayerPed) then
		local vehicle = GetVehiclePedIsIn(localPlayerPed, false)
		local numVehSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
		vehicleInfo.netId = VehToNet(vehicle)
		for i = -1, numVehSeats do
			if GetPedInVehicleSeat(vehicle, i) == localPlayerPed then
				vehicleInfo.seat = i
				break
			end
		end
	end

	if playerData.selfbucket then
		-- cache old bucket to restore at end of spectate
		if not IsSpectating then
			MyBucket = playerData.selfbucket
		end
	end

	local tgtCoords = playerData.coords
	
	if ((not tgtCoords) or (tgtCoords.z == 0.0)) then tgtCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(playerServerId))) end
	if playerServerId == GetPlayerServerId(PlayerId()) then 
		if oldCoords then
			RequestCollisionAtCoord(oldCoords.x, oldCoords.y, oldCoords.z)
			Wait(500)
			SetEntityCoords(playerPed, oldCoords.x, oldCoords.y, oldCoords.z, 0, 0, 0, false)
			oldCoords=nil
		end
		spectatePlayer(localPlayerPed,GetPlayerFromServerId(PlayerId()),GetPlayerName(PlayerId()))
		frozen = false
		FreezeMyself(false)
		return 
	else
		if not oldCoords then
			oldCoords = GetEntityCoords(PlayerPedId())
		end
	end
	SetEntityCoords(localPlayerPed, tgtCoords.x, tgtCoords.y, tgtCoords.z - 10.0, 0, 0, 0, false)
	frozen = true
	FreezeMyself(true)
	stopSpectateUpdate = true
	local playerId = GetPlayerFromServerId(playerServerId)
	repeat
		Wait(200)
		playerId = GetPlayerFromServerId(playerServerId)
	until ((GetPlayerPed(playerId) > 0) and (playerId ~= -1))
	spectatePlayer(GetPlayerPed(playerId),playerId,GetPlayerName(playerId))
	stopSpectateUpdate = false 
end)

Citizen.CreateThread(function()
	RegisterNetEvent("EasyAdmin:requestCleanup", function(type, radius)

		local toDelete = {}
		local deletionText = ""
		if type == "cars" then
			toDelete = GetGamePool("CVehicle")
			deletionText = GetLocalisedText("cleaningcar")
		elseif type == "peds" then
			toDelete = GetGamePool("CPed")
			deletionText = GetLocalisedText("cleaningped")
		elseif type == "props" then
			toDelete = mergeTables(GetGamePool("CObject"), GetGamePool("CPickup"))
			deletionText = GetLocalisedText("cleaningprop")
		end

		for _,entity in pairs(toDelete) do
			PrintDebugMessage("starting deletion for entity "..entity, 4)
			if DoesEntityExist(entity) then
				if (type == "cars" and not IsPedAPlayer(GetPedInVehicleSeat(entity, -1))) then
					if not NetworkHasControlOfEntity(entity) then
						local i=0
						repeat 
							NetworkRequestControlOfEntity(entity)
							i=i+1
							Wait(150)
						until (NetworkHasControlOfEntity(entity) or i==500)
					end

					-- draw text
					SetTextFont(2)
					SetTextColour(255, 255, 255, 200)
					SetTextProportional(1)
					SetTextScale(0.0, 0.6)
					SetTextDropshadow(0, 0, 0, 0, 255)
					SetTextEdge(1, 0, 0, 0, 255)
					SetTextDropShadow()
					SetTextOutline()
					SetTextEntry("STRING")
					AddTextComponentString(string.format(deletionText, entity))
					EndTextCommandDisplayText(0.45, 0.95)

					-- delete entity
					if radius == "global" then
						PrintDebugMessage("deleting entity "..entity, 3)
						SetEntityAsNoLongerNeeded(entity)
						DeleteEntity(entity)
					else
						local entityCoords = GetEntityCoords(entity)
						local playerCoords = GetEntityCoords(PlayerPedId())
						if #(playerCoords - entityCoords) < radius then
							PrintDebugMessage("deleting entity "..entity, 3)
							SetEntityAsNoLongerNeeded(entity)
							DeleteEntity(entity)
						end
					end
					Wait(1)
				end
				toDelete[i] = nil
			end
		end
	end)
end)

Citizen.CreateThread( function()
	while true do
		Citizen.Wait(500)
		local localPlayerPed = PlayerPedId()
		if drawInfo and not stopSpectateUpdate then
			local targetPed = GetPlayerPed(drawTarget)
			local targetGod = GetPlayerInvincible(drawTarget)
			
			local tgtCoords = GetEntityCoords(targetPed)
			if tgtCoords and tgtCoords.x ~= 0 then
				SetEntityCoords(localPlayerPed, tgtCoords.x, tgtCoords.y, tgtCoords.z - 10.0, 0, 0, 0, false)
			end
		else
			Citizen.Wait(1000)
		end
		cachedInfo = {
			ped = localPlayerPed,
			veh = GetVehiclePedIsIn(localPlayerPed, false),
			player = PlayerId(),
		}
	end
end)


RegisterNetEvent("EasyAdmin:TeleportPlayerBack", function(id, tgtCoords)
	if lastLocation then
		SetEntityCoords(PlayerPedId(), lastLocation,0,0,0, false)
		lastLocation=nil
	end
end)

RegisterNetEvent("EasyAdmin:TeleportRequest", function(id, tgtCoords)
	if id then
		if (tgtCoords.x == 0.0 and tgtCoords.y == 0.0 and tgtCoords.z == 0.0) then
			local tgtPed = GetPlayerPed(GetPlayerFromServerId(id))
			tgtCoords = GetEntityCoords(tgtPed)
		end
		lastLocation = tgtCoords
		SetEntityCoords(PlayerPedId(), tgtCoords,0,0,0, false)
	else
		lastLocation = tgtCoords
		SetEntityCoords(PlayerPedId(), tgtCoords,0,0,0, false)
	end
end)

RegisterNetEvent("EasyAdmin:SlapPlayer", function(slapAmount)
	local ped = PlayerPedId()
	if slapAmount > GetEntityHealth(ped) then
		ApplyDamageToPed(ped, 5000, false, true,true)
	else
		ApplyDamageToPed(ped, slapAmount, false, true,true)
	end
end)


RegisterCommand("kick", function(source, args, rawCommand)
    if LocalPlayer.state["chimerastaff:clockedIn"] == 'yes' then
        local source=source
        local reason = ""
        for i,theArg in pairs(args) do
            if i ~= 1 then -- make sure we are not adding the kicked player as a reason
                reason = reason.." "..theArg
            end
        end
        if args[1] and tonumber(args[1]) then
            TriggerServerEvent("EasyAdmin:kickPlayer", tonumber(args[1]), reason)
        end
    else
        TriggerEvent("ox_lib:notify", {
            title = "Error",
            description = "You must be clocked in to use this command.",
            type = "error"
        })
    end
end, false)

RegisterCommand("ban", function(source, args, rawCommand)
    if LocalPlayer.state["chimerastaff:clockedIn"] == 'yes' then
        if args[1] and tonumber(args[1]) then
            local reason = ""
            for i,theArg in pairs(args) do
                if i ~= 1 then
                    reason = reason.." "..theArg
                end
            end
            if args[1] and tonumber(args[1]) then
                TriggerServerEvent("EasyAdmin:banPlayer", tonumber(args[1]), reason, false, GetPlayerName(args[1]))
            end
        end
    else
        TriggerEvent("ox_lib:notify", {
            title = "Error",
            description = "You must be clocked in to use this command.",
            type = "error"
        })
    end
end, false)

RegisterNetEvent("EasyAdmin:FreezePlayer", function(toggle)
	frozen = toggle
	FreezeMyself(frozen)
end)


RegisterNetEvent("EasyAdmin:CaptureScreenshot", function(toggle, url, field)
	exports['screenshot-basic']:requestScreenshotUpload(GetConvar("ea_screenshoturl", 'https://wew.wtf/upload.php'), GetConvar("ea_screenshotfield", 'files[]'), function(data)
		TriggerLatentServerEvent("EasyAdmin:TookScreenshot", 100000, data)
	end)
end)

function spectatePlayer(targetPed,target,name)
	local playerPed = PlayerPedId() -- yourself
	enable = true
	if (target == PlayerId() or target == -1) then 
		enable = false
	end

	if(enable)then
		SetEntityVisible(playerPed, false, 0)
		SetEntityCollision(playerPed, false, false)
		SetEntityInvincible(playerPed, true)
		NetworkSetEntityInvisibleToNetwork(playerPed, true)
		Citizen.Wait(200) -- to prevent target player seeing you
		if targetPed == playerPed then
			Wait(500)
			targetPed = GetPlayerPed(target)
		end
		local targetx,targety,targetz = table.unpack(GetEntityCoords(targetPed, false))
		RequestCollisionAtCoord(targetx,targety,targetz)
		NetworkSetInSpectatorMode(true, targetPed)
		
		DrawPlayerInfo(target)
		TriggerEvent("EasyAdmin:showNotification", string.format(GetLocalisedText("spectatingUser"), name))
	else
		if oldCoords then
			RequestCollisionAtCoord(oldCoords.x, oldCoords.y, oldCoords.z)
			Wait(500)
			SetEntityCoords(playerPed, oldCoords.x, oldCoords.y, oldCoords.z, 0, 0, 0, false)
			oldCoords=nil
		end
		NetworkSetInSpectatorMode(false, targetPed)
		StopDrawPlayerInfo()
		TriggerEvent("ox_lib:notify", {
			title = "Spectating Stopped",  -- You can change the title
			description = GetLocalisedText("stoppedSpectating"),
			type = "info"  -- Adjust the type as needed, e.g., "success", "error", "info"
		})
		
		frozen = false
		FreezeMyself(false)
		Citizen.Wait(200) -- to prevent staying invisible
		SetEntityVisible(playerPed, true, 0)
		SetEntityCollision(playerPed, true, true)
		SetEntityInvincible(playerPed, false)
		NetworkSetEntityInvisibleToNetwork(playerPed, false)
		if vehicleInfo.netId and vehicleInfo.seat then
			local vehicle = NetToVeh(vehicleInfo.netId)
			if DoesEntityExist(vehicle) then
				if IsVehicleSeatFree(vehicle, vehicleInfo.seat) then
					SetPedIntoVehicle(playerPed, vehicle, vehicleInfo.seat)
				else
					TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("spectatevehicleseatoccupied"))
				end
			else
				TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("spectatenovehiclefound"))
			end

			vehicleInfo.netId = nil
			vehicleInfo.seat = nil
		end
	end
end

function ShowNotification(text)
	if not RedM then
		local notificationTxd = CreateRuntimeTxd("easyadmin_notification")
		CreateRuntimeTextureFromImage(notificationTxd, 'small_logo', 'dependencies/images/small-logo-bg.png')
		BeginTextCommandThefeedPost("STRING")
		AddTextComponentSubstringPlayerName(text)

		local title = "~bold~EasyAdmin"
		local subtitle = GetLocalisedText("notification")
		local iconType = 0
		local flash = false

		EndTextCommandThefeedPostMessagetext("easyadmin_notification", "small_logo", flash, iconType, title, subtitle)
		local showInBrief = false
		local blink = false
		EndTextCommandThefeedPostTicker(blink, showInBrief)

	else
		-- someone who has RedM installed please write some code for this
		
	end
end

RegisterNetEvent("EasyAdmin:showNotification", function(text, important)
	TriggerEvent("EasyAdmin:receivedNotification")
	if not WasEventCanceled() then
		ShowNotification(text)
	end
end)

-- NOCLIP BY: LIAM & SAXON :)

config = {
	controls = {
		openKey = 289,
		goUp = 85,
		goDown = 48,
		turnLeft = 34,
		turnRight = 35,
		goForward = 32,
		goBackward = 33,
		changeSpeed = 21,
	},

	speeds = {
		{ label = "12.5%", speed = 0 },
		{ label = "25%", speed = 0.5 },
		{ label = "37.5%", speed = 2 },
		{ label = "50%", speed = 4 },
		{ label = "62.5%", speed = 6 },
		{ label = "75%", speed = 10 },
		{ label = "87.5%", speed = 20 },
		{ label = "100%", speed = 25 }
	},

	offsets = {
		y = 0.5,
		z = 0.2,
		h = 3,
	},
}

noclipActive = false
index = 1

local function IsPlayerOnDuty()
    return LocalPlayer.state["chimerastaff:clockedIn"] == 'yes'
end

Citizen.CreateThread(function()
    buttons = setupScaleform("instructional_buttons")

    currentSpeed = config.speeds[index].speed
    while true do
        Citizen.Wait(1)
        if permissions["player.noclip"] then
            if IsControlJustPressed(1, config.controls.openKey) then
                if IsPlayerOnDuty() then
                    noclipActive = not noclipActive

                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                        noclipEntity = GetVehiclePedIsIn(PlayerPedId(), false)
                    else
                        noclipEntity = PlayerPedId()
                    end

                    SetEntityCollision(noclipEntity, not noclipActive, not noclipActive)
                    FreezeEntityPosition(noclipEntity, noclipActive)
                    SetEntityInvincible(noclipEntity, noclipActive)
                    SetVehicleRadioEnabled(noclipEntity, not noclipActive)
                else
                    lib.notify({
                        title = 'Error',
                        description = 'You are not clocked in!',
                        type = 'error',
                    })
                end
            end

            if noclipActive then
                if not IsPlayerOnDuty() then -- Checks to see if player clocks out in noclip state. If yes then the player will be removed from noclip state.
                    noclipActive = false
                    SetEntityCollision(noclipEntity, true, true)
                    FreezeEntityPosition(noclipEntity, false)
                    SetEntityInvincible(noclipEntity, false)
                    SetVehicleRadioEnabled(noclipEntity, true)
                    SetEntityAlpha(noclipEntity, 255, false)
                    SetEntityVisible(noclipEntity, true)
                    lib.notify({
                        title = 'Noclip Disabled',
                        description = 'You have been removed from noclip as you are no longer on duty.',
                        type = 'info',
                    })
                else
                    DrawScaleformMovieFullscreen(buttons)

                    local xoff = 0.0
                    local yoff = 0.0
                    local zoff = 0.0

                    if IsControlJustPressed(1, config.controls.changeSpeed) then
                        if index ~= 8 then
                            index = index + 1
                            currentSpeed = config.speeds[index].speed
                        else
                            currentSpeed = config.speeds[1].speed
                            index = 1
                        end
                    end
                    setupScaleform("instructional_buttons")

                    DisableControls()

                    if IsDisabledControlPressed(0, config.controls.goForward) then
                        yoff = config.offsets.y
                    end

                    if IsDisabledControlPressed(0, config.controls.goBackward) then
                        yoff = -config.offsets.y
                    end

                    if IsDisabledControlPressed(0, config.controls.turnLeft) then
                        xoff = -config.offsets.y
                    end

                    if IsDisabledControlPressed(0, config.controls.turnRight) then
                        xoff = config.offsets.y
                    end

                    if IsDisabledControlPressed(0, config.controls.goUp) then
                        zoff = config.offsets.z
                    end

                    if IsDisabledControlPressed(0, config.controls.goDown) then
                        zoff = -config.offsets.z
                    end

                    local newPos = GetOffsetFromEntityInWorldCoords(noclipEntity, xoff * (currentSpeed + 0.3),
                        yoff * (currentSpeed + 0.3), zoff * (currentSpeed + 0.3))
                    local camRot = GetGameplayCamRot(2)
                    local heading = camRot.z
                    SetEntityVelocity(noclipEntity, 0.0, 0.0, 0.0)
                    SetEntityRotation(noclipEntity, 0.0, 0.0, 0.0, 0, false)
                    SetEntityHeading(noclipEntity, heading)
                    SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, noclipActive, noclipActive,
                        noclipActive)

                    SetEntityAlpha(noclipEntity, 52, false)
                    SetEntityVisible(noclipEntity, not noclipActive)
                    SetEntityLocallyVisible(noclipEntity)
                end
            else
                SetEntityAlpha(noclipEntity, 255, false)
                SetEntityVisible(noclipEntity, true)
            end
        end
    end
end)

function ButtonMessage(text)
	BeginTextCommandScaleformString("STRING")
	AddTextComponentScaleform(text)
	EndTextCommandScaleformString()
end

function Button(ControlButton)
	N_0xe83a3e3557a56640(ControlButton)
end

function setupScaleform(scaleform)
	local scaleform = RequestScaleformMovie(scaleform)

	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(1)
	end

	PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
	PushScaleformMovieFunctionParameterInt(200)
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
	PushScaleformMovieFunctionParameterInt(5)
	Button(GetControlInstructionalButton(2, config.controls.openKey, true))
	ButtonMessage("Disable Noclip")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
	PushScaleformMovieFunctionParameterInt(4)
	Button(GetControlInstructionalButton(2, config.controls.goUp, true))
	ButtonMessage("Go Up")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
	PushScaleformMovieFunctionParameterInt(3)
	Button(GetControlInstructionalButton(2, config.controls.goDown, true))
	ButtonMessage("Go Down")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
	PushScaleformMovieFunctionParameterInt(2)
	Button(GetControlInstructionalButton(1, config.controls.turnRight, true))
	Button(GetControlInstructionalButton(1, config.controls.turnLeft, true))
	ButtonMessage("Turn Left/Right")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
	PushScaleformMovieFunctionParameterInt(1)
	Button(GetControlInstructionalButton(1, config.controls.goBackward, true))
	Button(GetControlInstructionalButton(1, config.controls.goForward, true))
	ButtonMessage("Go Forwards/Backwards")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
	PushScaleformMovieFunctionParameterInt(0)
	Button(GetControlInstructionalButton(2, config.controls.changeSpeed, true))
	ButtonMessage("Change Speed: " .. config.speeds[index].label .. " (" .. index .. "/" .. #config.speeds .. ")")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
	PopScaleformMovieFunctionVoid()

	return scaleform
end

function DisableControls()
	DisableControlAction(0, 30, true)
	DisableControlAction(0, 31, true)
	DisableControlAction(0, 32, true)
	DisableControlAction(0, 33, true)
	DisableControlAction(0, 34, true)
	DisableControlAction(0, 35, true)
	DisableControlAction(0, 266, true)
	DisableControlAction(0, 267, true)
	DisableControlAction(0, 268, true)
	DisableControlAction(0, 269, true)
	DisableControlAction(0, 44, true)
	DisableControlAction(0, 20, true)
	DisableControlAction(0, 74, true)
end