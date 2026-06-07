-- ============================================================
--  EasyAdmin-ox Clock In/Out
--  By: Liam (IOwnSpaceX)
-- ============================================================

RegisterCommand("staffsuspend", function(source, args, rawCommand)
    local input = lib.inputDialog("Suspend from Duty", {
        { type = "number",   label = "Player Server ID",                                              required = true, min = 1 },
        { type = "input",    label = "Reason",                                                        required = true, min = 3, max = 128 },
        { type = "input",    label = "Duration", description = "e.g. 1 hour, 7 days, 0 = permanent", required = true },
        { type = "checkbox", label = "I confirm I want to suspend this player from duty",              required = true },
    })

    if not input then return end

    if not input[4] then
        lib.notify({ title = "Cancelled", description = "You must check the confirmation box.", type = "error" })
        return
    end

    local targetId = tonumber(input[1])
    local reason   = input[2] or "No reason provided"
    local duration = input[3] or "0"

    if not targetId then
        lib.notify({ title = "Invalid ID", description = "Please enter a valid player server ID.", type = "error" })
        return
    end

    TriggerServerEvent("EasyAdmin:StaffSuspend", targetId, duration, reason)
end, false)

RegisterCommand("staffunsuspend", function(source, args, rawCommand)
    local input = lib.inputDialog("Unsuspend from Duty", {
        { type = "number",   label = "Player Server ID",                                  required = true, min = 1 },
        { type = "checkbox", label = "I confirm I want to lift this player's suspension", required = true },
    })

    if not input then return end

    if not input[2] then
        lib.notify({ title = "Cancelled", description = "You must check the confirmation box.", type = "error" })
        return
    end

    local targetId = tonumber(input[1])
    if not targetId then
        lib.notify({ title = "Invalid ID", description = "Please enter a valid player server ID.", type = "error" })
        return
    end

    TriggerServerEvent("EasyAdmin:StaffUnsuspend", targetId)
end, false)

RegisterCommand("forceout", function(source, args, rawCommand)
    local input = lib.inputDialog("Force Off Duty", {
        { type = "number",   label = "Player Server ID",                               required = true, min = 1 },
        { type = "checkbox", label = "I confirm I want to force this player off duty", required = true },
    })

    if not input then return end

    if not input[2] then
        lib.notify({ title = "Cancelled", description = "You must check the confirmation box.", type = "error" })
        return
    end

    local targetId = tonumber(input[1])
    if not targetId then
        lib.notify({ title = "Invalid ID", description = "Please enter a valid player server ID.", type = "error" })
        return
    end

    TriggerServerEvent("EasyAdmin:ForceOut", targetId)
end, false)
