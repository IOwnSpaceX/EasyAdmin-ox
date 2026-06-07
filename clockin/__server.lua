-- ============================================================
--  EasyAdmin-ox Clock In/Out System
--  By: Liam (IOwnSpaceX)
-- ============================================================

local Config = {
    Webhook = {
        enabled    = GetConvar("ea_clockin_webhook_enabled", "true") == "true",
        url        = GetConvar("ea_clockin_webhook_url", ""),
        botName    = GetConvar("ea_clockin_webhook_name", "Easyadmin-ox Duty Bot"),
        avatarUrl  = GetConvar("ea_clockin_webhook_avatar", ""),
        botToken   = GetConvar("ea_botToken", ""),
    },
    DM = {
        enabled = true, --Should the bot send DMs to the user letting them known when they clockin/out?
    },
    AbuseDetection = {
        enabled    = true, --Bot sends a log if it sees clockin abuse
        minSeconds = 180, --what in seconds is considered clockin abuse? (3 mins)
        webhookUrl = GetConvar("ea_clockin_abuse_webhook_url", ""), --(optional) should the bot send clockin abuse logs to a seperate channel then the main clockin channel? (use convar in server.cfg)
    },
    BypassSystem = {
        enabled          = true, --Bypass Clockin
        bypassPermission = "clockin.bypass",
    },
    Cooldown = {
        enabled  = true,--Time between clocking out and then back in again
        duration = 300, --Amount of time in seconds that duration is
    },
    Permissions = {
        suspend  = "clockin.suspend", --ACE perm to suspend people from clocking in
        forceout = "clockin.forceout", --ACE perm to kick people off duty
    },
}

-- ============================================================

local playerCooldowns   = {}
local playerClockInTime = {}
local playerLastClockIn = {}

local function LoadJSON(filename)
    local raw = LoadResourceFile(GetCurrentResourceName(), "clockin/" .. filename)
    if not raw or raw == "" then return {} end
    return json.decode(raw) or {}
end

local function SaveJSON(filename, data)
    SaveResourceFile(GetCurrentResourceName(), "clockin/" .. filename, json.encode(data, { indent = true }), -1)
end

local function EnsureFile(filename, default)
    local raw = LoadResourceFile(GetCurrentResourceName(), "clockin/" .. filename)
    if not raw or raw == "" then
        SaveResourceFile(GetCurrentResourceName(), "clockin/" .. filename, json.encode(default), -1)
    end
end
EnsureFile("suspensions.json", {})
EnsureFile("hours.json", {})

local suspensions = LoadJSON("suspensions.json")
local hours       = LoadJSON("hours.json")
local clockConfig = LoadJSON("config.json")

-- ============================================================
--  Helpers
-- ============================================================

local function IsDutySystemEnabled()
    return GetConvar("ea_DutySystemEnabled", "false") == "true"
end

local function HasDutyBypass(source)
    if not Config.BypassSystem.enabled then return false end
    local hasBypass = IsPlayerAceAllowed(source, Config.BypassSystem.bypassPermission)
    if hasBypass and IsDutySystemEnabled() then
        Player(source).state:set('easyadmin-ox:clockedIn', 'yes', true)
    end
    return hasBypass
end

local function CheckCooldown(source)
    if not Config.Cooldown.enabled or HasDutyBypass(source) then return true end
    local currentTime = os.time()
    if playerCooldowns[source] and currentTime - playerCooldowns[source] < Config.Cooldown.duration then
        local remaining = math.ceil(Config.Cooldown.duration - (currentTime - playerCooldowns[source]))
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Cooldown Active',
            description = string.format('You must wait %d seconds before clocking in again.', remaining),
            type = 'error'
        })
        return false
    end
    return true
end

local function GetPlayerInfo(player)
    local name        = GetPlayerName(player)
    local identifiers = GetPlayerIdentifiers(player)
    local discordId   = nil
    for _, v in pairs(identifiers) do
        if string.find(v, "discord:") then
            discordId = string.gsub(v, "discord:", "")
            break
        end
    end
    return name, discordId
end

local function FormatDuration(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then return string.format("%dm %ds", m, s)
    else return string.format("%ds", s) end
end

local function FormatTime(t)
    return os.date("%A, %B %d, %Y %H:%M", t)
end

-- ============================================================
--  Cycle & Hours
-- ============================================================

local function GetCycleNumber()
    local startDate = clockConfig.cycle and clockConfig.cycle.startDate or "2026-01-01"
    local y, mo, d  = startDate:match("(%d+)-(%d+)-(%d+)")
    local startTs   = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = 0, min = 0, sec = 0 })
    local cycleLen  = ((clockConfig.cycle and clockConfig.cycle.lengthDays) or 14) * 86400
    return math.floor((os.time() - startTs) / cycleLen) + 1
end

local function GetHoursKey(discordId)
    return discordId .. "_cycle" .. GetCycleNumber()
end

local function AddHours(discordId, seconds)
    if not discordId then return end
    local key = GetHoursKey(discordId)
    hours[key] = (hours[key] or 0) + seconds
    SaveJSON("hours.json", hours)
end

local function GetHours(discordId)
    if not discordId then return 0 end
    return hours[GetHoursKey(discordId)] or 0
end

-- ============================================================
--  Suspension
-- ============================================================

local function IsSuspended(discordId)
    if not discordId then return false end
    local s = suspensions[discordId]
    if not s then return false end
    if s.until_time and os.time() > s.until_time then
        suspensions[discordId] = nil
        SaveJSON("suspensions.json", suspensions)
        return false
    end
    return true
end

local function GetSuspension(discordId)
    return suspensions[discordId]
end

local function SuspendPlayer(discordId, duration, reason, moderator)
    suspensions[discordId] = {
        reason       = reason,
        moderator    = moderator,
        suspended_at = os.time(),
        until_time   = duration > 0 and (os.time() + duration) or nil,
    }
    SaveJSON("suspensions.json", suspensions)
end

local function UnsuspendPlayer(discordId)
    suspensions[discordId] = nil
    SaveJSON("suspensions.json", suspensions)
end

exports('getSuspensions',  function() return suspensions end)
exports('unsuspendPlayer', function(discordId) UnsuspendPlayer(discordId) end)
exports('suspendPlayer',   function(discordId, duration, reason, moderator) SuspendPlayer(discordId, duration, reason, moderator) end)
exports('getHours',        function(discordId) return GetHours(discordId) end)
exports('getCycleNumber',  function() return GetCycleNumber() end)
exports('getClockConfig',  function() return clockConfig end)

-- ============================================================
--  Webhook / DM
-- ============================================================

local function SendDM(discordId, embeds)
    if not Config.DM.enabled or not Config.Webhook.botToken or Config.Webhook.botToken == "" then return end
    if not discordId then return end

    PerformHttpRequest("https://discord.com/api/v10/users/@me/channels", function(err, channelText, headers)
        if err ~= 200 then
            print("^1[ClockIn] Failed to create DM channel: " .. tostring(err) .. " | " .. tostring(channelText))
            return
        end
        local channelData = json.decode(channelText)
        if not channelData or not channelData.id then return end

        PerformHttpRequest("https://discord.com/api/v10/channels/" .. channelData.id .. "/messages", function(msgErr, msgText)
            if msgErr ~= 200 then
                print("^1[ClockIn] Failed to send DM: " .. tostring(msgErr) .. " | " .. tostring(msgText))
            end
        end, 'POST', json.encode({ embeds = embeds }), {
            ['Content-Type']  = 'application/json',
            ['Authorization'] = 'Bot ' .. Config.Webhook.botToken
        })
    end, 'POST', json.encode({ recipient_id = discordId }), {
        ['Content-Type']  = 'application/json',
        ['Authorization'] = 'Bot ' .. Config.Webhook.botToken
    })
end

local function SendWebhook(url, payload)
    if not url or url == "" then return end
    PerformHttpRequest(url, function(err, text)
        if err ~= 204 and err ~= 200 then
            print("^1[ClockIn] Webhook error: " .. tostring(err) .. " | " .. tostring(text))
        end
    end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- ============================================================
--  Clock In / Out Logic
-- ============================================================

local function OnClockIn(source)
    local name, discordId = GetPlayerInfo(source)
    local now    = os.time()
    local lastIn = playerLastClockIn[source]

    playerClockInTime[source] = now
    playerLastClockIn[source] = now

    local lastInStr  = lastIn and FormatTime(lastIn) or "N/A"
    local discordStr = discordId and ("<@" .. discordId .. ">") or name

    SendWebhook(Config.Webhook.url, {
        username = Config.Webhook.botName, avatar_url = Config.Webhook.avatarUrl,
        embeds = {{
            ["color"]       = 4437377,
            ["title"]       = "Staff Clocked In",
            ["description"] = discordStr .. " has clocked in.",
            ["fields"]      = {
                { ["name"] = "👤 In-Game Name", ["value"] = "`" .. name .. "`", ["inline"] = true },
                { ["name"] = "🎮 Discord",       ["value"] = discordStr,         ["inline"] = true },
                { ["name"] = "🕐 Clock In Time", ["value"] = FormatTime(now),    ["inline"] = false },
                { ["name"] = "🕐 Last Clock In", ["value"] = lastInStr,          ["inline"] = false },
            },
            ["footer"]    = { ["text"] = "Easyadmin Duty System" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    })

    SendDM(discordId, {{
        ["color"]       = 4437377,
        ["title"]       = "Successfully Clocked In",
        ["description"] = string.format("Time to start your shift, **%s**!", name),
        ["fields"]      = {
            { ["name"] = "📅 Date & Time", ["value"] = FormatTime(now),       ["inline"] = true },
            { ["name"] = "⏰ Quick Time",  ["value"] = os.date("%H:%M", now), ["inline"] = true },
            { ["name"] = "🎯 Status",      ["value"] = "✅ ON DUTY",          ["inline"] = false },
        },
        ["footer"]    = { ["text"] = "EasyAdmin Duty System" },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }})
end

local function OnClockOut(source, isBypass, forcedBy)
    local name, discordId = GetPlayerInfo(source)
    local now         = os.time()
    local clockInTime = playerClockInTime[source]
    local duration    = clockInTime and (now - clockInTime) or nil
    local durationStr = duration and ("`" .. FormatDuration(duration) .. "`") or "`Unknown`"
    local discordStr  = discordId and ("<@" .. discordId .. ">") or name

    if duration and discordId then AddHours(discordId, duration) end

    local title = forcedBy and "Staff Forced Off Duty" or ("Staff Clocked Out" .. (isBypass and " (Bypass)" or ""))
    local fields = {
        { ["name"] = "👤 In-Game Name",    ["value"] = "`" .. name .. "`", ["inline"] = true },
        { ["name"] = "🎮 Discord",          ["value"] = discordStr,         ["inline"] = true },
        { ["name"] = "🕐 Clock Out Time",   ["value"] = FormatTime(now),    ["inline"] = false },
        { ["name"] = "⏱ Duration on Duty", ["value"] = durationStr,        ["inline"] = false },
    }
    if forcedBy then fields[#fields + 1] = { ["name"] = "👮 Forced By", ["value"] = "`" .. forcedBy .. "`", ["inline"] = false } end

    SendWebhook(Config.Webhook.url, {
        username = Config.Webhook.botName, avatar_url = Config.Webhook.avatarUrl,
        embeds = {{
            ["color"]       = forcedBy and 16744272 or 16724032,
            ["title"]       = title,
            ["description"] = discordStr .. " has clocked out.",
            ["fields"]      = fields,
            ["footer"]      = { ["text"] = "Easyadmin Duty System" },
            ["timestamp"]   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    })

    if Config.AbuseDetection.enabled and duration and duration < Config.AbuseDetection.minSeconds and not forcedBy then
        local abuseUrl = (Config.AbuseDetection.webhookUrl ~= "") and Config.AbuseDetection.webhookUrl or Config.Webhook.url
        SendWebhook(abuseUrl, {
            username = Config.Webhook.botName, avatar_url = Config.Webhook.avatarUrl,
            embeds = {{
                ["color"]       = 16744272,
                ["title"]       = "⚠️ Clock In Abuse Detected",
                ["description"] = discordStr .. " clocked out after only **" .. FormatDuration(duration) .. "**.",
                ["fields"]      = {
                    { ["name"] = "👤 In-Game Name",    ["value"] = "`" .. name .. "`",                                          ["inline"] = true },
                    { ["name"] = "🎮 Discord",          ["value"] = discordStr,                                                  ["inline"] = true },
                    { ["name"] = "⏱ Time on Duty",     ["value"] = durationStr,                                                 ["inline"] = false },
                },
                ["footer"]    = { ["text"] = "Easyadmin Duty System" },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}
        })
    end

    SendDM(discordId, {{
        ["color"]       = 16724032,
        ["title"]       = forcedBy and "⚠️ You Were Forced Off Duty" or "Successfully Clocked Out",
        ["description"] = forcedBy
            and string.format("You were forced off duty by **%s**.", forcedBy)
            or string.format("Great work during your shift, **%s**!", name),
        ["fields"]      = {
            { ["name"] = "📅 Clock Out Time",  ["value"] = FormatTime(now), ["inline"] = true },
            { ["name"] = "⏱ Session Duration", ["value"] = durationStr,     ["inline"] = true },
        },
        ["footer"]    = { ["text"] = "EasyAdmin Duty System" },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }})

    playerClockInTime[source] = nil
end

-- ============================================================
--  Commands
-- ============================================================

RegisterCommand("clockin", function(source, args, rawCommand)
    if not exports['EasyAdmin-ox']:IsPlayerAdmin(source) then return end
    if not IsDutySystemEnabled() then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock In', description = 'Duty system is disabled!', type = 'info' })
        return
    end

    local _, discordId = GetPlayerInfo(source)
    if IsSuspended(discordId) then
        local s = GetSuspension(discordId)
        local untilStr = s.until_time and FormatTime(s.until_time) or "Permanent"
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Staff Clock In',
            description = string.format('You are suspended from duty.\nReason: %s\nExpires: %s', s.reason or "N/A", untilStr),
            type = 'error'
        })
        return
    end

    if HasDutyBypass(source) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock In', description = 'You have clocked on as staff!', type = 'success' })
        OnClockIn(source)
        return
    end

    if CheckCooldown(source) then
        if Player(source).state['easyadmin-ox:clockedIn'] == 'no' or Player(source).state['easyadmin-ox:clockedIn'] == nil then
            Player(source).state:set('easyadmin-ox:clockedIn', 'yes', true)
            TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock In', description = 'You have clocked on as staff!', type = 'success' })
            OnClockIn(source)
        else
            TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock In', description = 'You are already clocked in!', type = 'error' })
        end
    end
end, false)

RegisterCommand("clockout", function(source, args, rawCommand)
    if not exports['EasyAdmin-ox']:IsPlayerAdmin(source) then return end
    if not IsDutySystemEnabled() then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock Out', description = 'Duty system is disabled!', type = 'info' })
        return
    end

    if HasDutyBypass(source) then
        Player(source).state:set('easyadmin-ox:clockedIn', 'no', true)
        TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock Out', description = 'You may clockin freely due to bypass.', type = 'success' })
        OnClockOut(source, true)
    elseif Player(source).state['easyadmin-ox:clockedIn'] == 'yes' then
        Player(source).state:set('easyadmin-ox:clockedIn', 'no', true)
        playerCooldowns[source] = os.time()
        TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock Out', description = 'You have clocked out as staff!', type = 'success' })
        OnClockOut(source, false)
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'Staff Clock Out', description = 'You are not clocked in!', type = 'error' })
    end
end, false)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if Player(src).state['easyadmin-ox:clockedIn'] == 'yes' then
        Player(src).state:set('easyadmin-ox:clockedIn', 'no', true)
        OnClockOut(src, false, nil)
    end
    playerCooldowns[src]   = nil
    playerClockInTime[src] = nil
end)

-- ============================================================
--  Server Events
-- ============================================================

local function ParseDurationString(str)
    if not str then return 0 end
    str = tostring(str):lower():gsub("%s+", "")
    if str == "0" or str == "permanent" then return 0 end
    local units = { s = 1, sec = 1, second = 1, seconds = 1, m = 60, min = 60, minute = 60, minutes = 60, h = 3600, hr = 3600, hour = 3600, hours = 3600, d = 86400, day = 86400, days = 86400, w = 604800, week = 604800, weeks = 604800 }
    local total = 0
    for val, unit in str:gmatch("(%d+)([a-z]+)") do
        total = total + (tonumber(val) * (units[unit] or 0))
    end
    if total == 0 then total = tonumber(str) or 0 end
    return math.floor(total)
end

RegisterServerEvent("EasyAdmin:StaffSuspend")
AddEventHandler("EasyAdmin:StaffSuspend", function(targetId, durationStr, reason)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Permissions.suspend) then return end
    local _, discordId = GetPlayerInfo(targetId)
    if not discordId then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Staff Suspend', description = 'Target has no Discord linked.', type = 'error' })
        return
    end
    local duration      = ParseDurationString(durationStr)
    local moderatorName = GetPlayerName(src)
    SuspendPlayer(discordId, duration, reason, moderatorName)

    if Player(targetId).state['easyadmin-ox:clockedIn'] == 'yes' then
        Player(targetId).state:set('easyadmin-ox:clockedIn', 'no', true)
        OnClockOut(targetId, false, moderatorName .. " (Suspension)")
    end

    local untilStr = duration > 0 and FormatTime(os.time() + duration) or "Permanent"
    TriggerClientEvent('ox_lib:notify', src, { title = 'Staff Suspend', description = 'Player suspended until: ' .. untilStr, type = 'success' })
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'Duty Suspended',
        description = 'You have been suspended from duty.\nReason: ' .. reason .. '\nExpires: ' .. untilStr,
        type = 'error'
    })
    SendWebhook(Config.Webhook.url, {
        username = Config.Webhook.botName, avatar_url = Config.Webhook.avatarUrl,
        embeds = {{
            ["color"]       = 16711680,
            ["title"]       = "🚫 Staff Suspended from Duty",
            ["fields"]      = {
                { ["name"] = "👤 Player",    ["value"] = "`" .. GetPlayerName(targetId) .. "`", ["inline"] = true },
                { ["name"] = "👮 Moderator", ["value"] = "`" .. moderatorName .. "`",           ["inline"] = true },
                { ["name"] = "📋 Reason",    ["value"] = reason,                                ["inline"] = false },
                { ["name"] = "⏰ Expires",   ["value"] = untilStr,                              ["inline"] = false },
            },
            ["footer"]    = { ["text"] = "Easyadmin Duty System" },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    })
end)

RegisterServerEvent("EasyAdmin:StaffUnsuspend")
AddEventHandler("EasyAdmin:StaffUnsuspend", function(targetId)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Permissions.suspend) then return end
    local _, discordId = GetPlayerInfo(targetId)
    if not discordId then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Staff Unsuspend', description = 'Target has no Discord linked.', type = 'error' })
        return
    end
    UnsuspendPlayer(discordId)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Staff Unsuspend', description = 'Player unsuspended.', type = 'success' })
    TriggerClientEvent('ox_lib:notify', targetId, { title = 'Duty Suspension Lifted', description = 'Your duty suspension has been lifted.', type = 'success' })
end)

RegisterServerEvent("EasyAdmin:ForceOut")
AddEventHandler("EasyAdmin:ForceOut", function(targetId)
    local src = source
    if not IsPlayerAceAllowed(src, Config.Permissions.forceout) then return end
    if Player(targetId).state['easyadmin-ox:clockedIn'] ~= 'yes' then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Force Out', description = 'That player is not clocked in.', type = 'error' })
        return
    end
    local moderatorName = GetPlayerName(src)
    Player(targetId).state:set('easyadmin-ox:clockedIn', 'no', true)
    OnClockOut(targetId, false, moderatorName)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Force Out', description = 'Player forced off duty.', type = 'success' })
    TriggerClientEvent('ox_lib:notify', targetId, { title = 'Forced Off Duty', description = 'You were forced off duty by ' .. moderatorName, type = 'error' })
end)
