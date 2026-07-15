local function openCallAdminDialog()
	local input = lib.inputDialog(GetLocalisedText("calladmintitle"), {
		{
			type = 'input',
			label = GetLocalisedText("calladminreasonlabel"),
			description = GetLocalisedText("calladminreasondesc"),
			required = true,
			min = 3,
			max = 500,
		},
		{
			type = 'input',
			label = GetLocalisedText("calladmincliplabel"),
			description = GetLocalisedText("calladminclipdesc"),
			required = false,
			max = 300,
		},
		{
			type = 'number',
			label = GetLocalisedText("calladmintargetlabel"),
			description = GetLocalisedText("calladmintargetdesc"),
			required = false,
			min = 0,
			max = 9999,
		},
	})

	if not input then return end

	local reason = input[1] and string.gsub(input[1], "^%s*(.-)%s*$", "%1") or ""
	local clipLink = input[2] and string.gsub(input[2], "^%s*(.-)%s*$", "%1") or nil
	local targetId = input[3]

	if reason == "" then
		TriggerEvent("EasyAdmin:showNotification", GetLocalisedText("invalidreport"))
		return
	end

	if clipLink == "" then
		clipLink = nil
	end

	if clipLink and not IsAllowedClipDomain(clipLink) then
		lib.notify({
			title = "EasyAdmin",
			description = GetLocalisedText("calladminbadclip"),
			type = "error"
		})
		clipLink = nil
	end

	if targetId == 0 then
		targetId = nil
	end

	TriggerServerEvent("EasyAdmin:SubmitCallAdmin", reason, clipLink, targetId)
end

CreateThread(function()

	Wait(500)

	if GetConvar("ea_enableCallAdminCommand", "true") == "true" then
		local commandName = GetConvar("ea_callAdminCommandName", "calladmin")
		RegisterCommand(commandName, function()
			openCallAdminDialog()
		end, false)
	end
end)
