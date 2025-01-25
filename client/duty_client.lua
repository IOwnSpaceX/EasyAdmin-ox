local unit = {}

RegisterNetEvent("chimera-staff", function(table)
    unit = table
end)

AddEventHandler("EasyAdmin:BuildSettingsOptions", function(source)
    if unit == nil then
        onduty = false
    else
        if unit['staff'] then
            onduty = true
        else
            onduty = false
        end
    end
    if not onduty then
        repeat
            Wait(1)
        until _menuPool:IsAnyMenuOpen()
        _menuPool:CloseAllMenus()
        TriggerEvent('ox_lib:notify', {
            title = 'EasyAdmin',
            description = 'You are not on duty.',
            type = 'error',
            position = 'center-right',
            duration = 3000
        })
    end
end)