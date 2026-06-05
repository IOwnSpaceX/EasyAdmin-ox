CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        {
            name = 'ea_kick',
            icon = 'fa-solid fa-right-from-bracket',
            label = '[Staff] Kick',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Kick Player', {
                    { type = 'input', label = 'Reason for Kick', description = 'Provide a reason for kicking the player.', required = true, min = 3, max = 128 }
                })

                if input then
                    TriggerServerEvent('ea:target:kick', id, input[1])
                end
            end
        },

        {
            name = 'ea_ban',
            icon = 'fa-solid fa-ban',
            label = '[Staff] Ban',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Ban Details', {
                    { type = 'input', label = 'Reason for Ban', description = 'Provide a reason for banning the player.', required = true, min = 3, max = 128 },
                    {
                        type = 'select',
                        label = 'Ban Duration',
                        description = 'Select the duration of the ban.',
                        options = {
                            { label = 'Hour(s)',   value = 'hours' },
                            { label = 'Day(s)',    value = 'days' },
                            { label = 'Week(s)',   value = 'weeks' },
                            { label = 'Month(s)',  value = 'months' },
                            { label = 'Permanent', value = 'permanent' }
                        },
                        required = true,
                        searchable = true,
                        clearable = true
                    },
                    { type = 'number', label = 'Ban Duration', description = 'Specify the length of the ban time. If Permanent IGNORE Box Below!', min = 1, max = 300, step = 10, default = 0, required = true }
                })

                if input then
                    local BanReason = input[1] or "No reason provided"
                    local BanDuration = input[2] or 'hours'
                    local AmountOfTime = input[3] or 0
                    local BanLength = 0

                    if BanDuration == 'permanent' then
                        BanLength = -1
                    elseif AmountOfTime > 0 then
                        if BanDuration == 'hours' then
                            BanLength = AmountOfTime * 3600
                        elseif BanDuration == 'days' then
                            BanLength = AmountOfTime * 86400
                        elseif BanDuration == 'weeks' then
                            BanLength = AmountOfTime * 604800
                        elseif BanDuration == 'months' then
                            BanLength = AmountOfTime * 2592000
                        end
                    end

                    if BanLength > 0 or BanLength == -1 then
                        TriggerServerEvent('ea:target:ban', id, BanReason, BanLength)
                    else
                        lib.notify({
                            title = 'Error',
                            description = 'Invalid ban length! Please enter a valid number.',
                            type = 'error'
                        })
                    end
                end
            end
        },

        {
            name = 'ea_warn',
            icon = 'fa-solid fa-triangle-exclamation',
            label = '[Staff] Warn',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Warn Player', {
                    { type = 'input', label = 'Reason for Warning', description = 'Provide a reason for warning the player.', required = true, min = 3, max = 128 }
                })

                if input then
                    TriggerServerEvent('ea:target:warn', id, input[1])
                end
            end
        },

        {
            name = 'ea_jail',
            icon = 'fa-solid fa-lock',
            label = '[Staff] Jail',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Jail Details', {
                    { type = 'input',  label = 'Reason for Jail',         description = 'Provide a reason for jailing the player.',        required = true, min = 3,    max = 128 },
                    { type = 'number', label = 'Jail Duration (seconds)', description = 'Specify the length of the jail time in seconds.', min = 1,         max = 1200, default = 30, required = true }
                })

                if input then
                    local JailReason = input[1] or "No reason provided"
                    local JailLengthSeconds = tonumber(input[2]) or 60

                    if JailLengthSeconds >= 1 and JailLengthSeconds <= 1200 then
                        TriggerServerEvent('ea:target:jail', id, JailLengthSeconds, JailReason)
                    else
                        lib.notify({
                            title = 'Invalid Jail Duration',
                            description = 'Please enter a valid number between 1 and 1200 seconds.',
                            type = 'error'
                        })
                    end
                end
            end
        },

        {
            name = 'ea_unjail',
            icon = 'fa-solid fa-lock-open',
            label = '[Staff] Unjail',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Confirm Unjail', {
                    { type = 'checkbox', label = 'Are you sure you want to unjail this player?', required = true }
                })

                if input and input[1] then
                    TriggerServerEvent('ea:target:unjail', id)
                end
            end
        },

        {
            name = 'ea_freeze',
            icon = 'fa-solid fa-snowflake',
            label = '[Staff] Freeze',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Freeze Player', {
                    { type = 'checkbox', label = 'Confirm Freeze', description = 'Check this box to confirm you want to freeze this player in place.', required = true }
                })

                if input and input[1] then
                    TriggerServerEvent('EasyAdmin:FreezePlayer', id, true)
                end
            end
        },

        {
            name = 'ea_unfreeze',
            icon = 'fa-solid fa-fire',
            label = '[Staff] Unfreeze',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Unfreeze Player', {
                    { type = 'checkbox', label = 'Confirm Unfreeze', description = 'Check this box to confirm you want to unfreeze this player.', required = true }
                })

                if input and input[1] then
                    TriggerServerEvent('EasyAdmin:FreezePlayer', id, false)
                end
            end
        },

        {
            name = 'ea_remove_weapons',
            icon = 'fa-solid fa-gun',
            label = '[Staff] Remove Weapons',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Remove Weapons', {
                    { type = 'checkbox', label = 'Confirm Remove Weapons', description = 'Check this box to confirm you want to remove all weapons from this player.', required = true }
                })

                if input and input[1] then
                    TriggerServerEvent('ea:target:removeweapons', id)
                end
            end
        },

        {
            name = 'ea_respawn',
            icon = 'fa-solid fa-rotate-right',
            label = '[Staff] Respawn',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Respawn Player', {
                    { type = 'checkbox', label = 'Confirm Respawn', description = 'Check this box to confirm you want to respawn this player.', required = true }
                })

                if input and input[1] then
                    TriggerServerEvent('ea:target:respawn', id)
                end
            end
        },

        {
            name = 'ea_revive',
            icon = 'fa-solid fa-kit-medical',
            label = '[Staff] Revive',

            canInteract = function(entity)
                return LocalPlayer.state['easyadmin-ox:clockedIn'] == 'yes'
            end,

            onSelect = function(data)
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))

                local input = lib.inputDialog('Revive Player', {
                    { type = 'checkbox', label = 'Confirm Revive', description = 'Check this box to confirm you want to revive this player.', required = true }
                })

                if input and input[1] then
                    TriggerServerEvent('ea:target:revive', id)
                end
            end
        },
    })
end)
