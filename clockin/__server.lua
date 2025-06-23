-- webhook configuration
local Config = {
    Webhook = {
        enabled = true, -- do you want the bots to send logs?
        url = "https://discord.com/api/webhooks/xxxxxxx", -- webhook url
        botName = "Easyadmin-ox Duty Bot", -- webhook name
        avatarUrl = "https://imgur.com/xxxxxx" -- replace with an avatar url
    }
}
Config.BypassSystem = {
    enabled = true,
    bypassPermission = "clockin.bypass"  -- ACE permission for duty bypass
}
Config.Cooldown = {
    enabled = true,
    duration = 300 -- 5 minutes in seconds
}
----------------------------------------------------------------------------------------------------



-- Function to check if duty system is enabled via convar
local function IsDutySystemEnabled()
    local dutyEnabled = GetConvar("ea_DutySystemEnabled", "false")
    return dutyEnabled == "true"
end

-- Function to check if player is on duty
local function IsPlayerOnDuty(source)
    -- If duty system is disabled via convar, always return true (considered on duty)
    if not IsDutySystemEnabled() then
        return true
    end
    -- Otherwise, check the player state
    return Player(source).state['easyadmin-ox:clockedIn'] == 'yes'
end

local playerCooldowns = {}

local function HasDutyBypass(source)
    if not Config.BypassSystem.enabled then return false end
    local hasBypass = IsPlayerAceAllowed(source, Config.BypassSystem.bypassPermission)
    if hasBypass and IsDutySystemEnabled() then
        Player(source).state['easyadmin-ox:clockedIn'] = 'yes'
    end
    return hasBypass
end

local function SendWebhook(player, action, clockInTime)
    if not Config.Webhook.enabled then return end

    local playerName = GetPlayerName(player)
    local playerIdentifiers = GetPlayerIdentifiers(player)
    local discordId = nil
    
    for _, v in pairs(playerIdentifiers) do
        if string.find(v, "discord:") then
            discordId = string.gsub(v, "discord:", "")
            break
        end
    end

    local color = (action == "Clock In") and 3780455 or 16724032
    local description = string.format("%s has %s.", playerName, action == "Clock In" and "clocked in" or "clocked out")
    if discordId then
        description = string.format("<@%s> has %s.", discordId, action == "Clock In" and "clocked in" or "clocked out")
    end

    local embed = {
        {
            ["color"] = color,
            ["title"] = "Staff " .. action,
            ["description"] = description,
            ["footer"] = {
                ["text"] = "Easyadmin-ox Duty System 🤖"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(Config.Webhook.url, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Webhook.botName,
        avatar_url = Config.Webhook.avatarUrl,
        content = pingMessage,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

local function CheckCooldown(source)
    if not Config.Cooldown.enabled or HasDutyBypass(source) then return true end
    
    local currentTime = os.time()
    if playerCooldowns[source] and currentTime - playerCooldowns[source] < Config.Cooldown.duration then
        local remainingTime = math.ceil(Config.Cooldown.duration - (currentTime - playerCooldowns[source]))
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Cooldown Active',
            description = string.format('You must wait %d seconds before clocking in again.', remainingTime),
            type = 'error'
        })
        return false
    end
    return true
end

RegisterCommand("clockin", function(source, args, rawCommand)
    if exports['EasyAdmin-ox']:IsPlayerAdmin(source) then
        if not IsDutySystemEnabled() then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock In',
                description = 'Duty system is disabled via convar!',
                type = 'info'
            })
            return
        end
    
        if HasDutyBypass(source) then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock In',
                description = 'You have clocked on as staff!',
                type = 'success'
            })
            return
        elseif CheckCooldown(source) then
            if Player(source).state['easyadmin-ox:clockedIn'] == 'no' or Player(source).state['easyadmin-ox:clockedIn'] == nil then
                Player(source).state['easyadmin-ox:clockedIn'] = 'yes'
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Staff Clock In',
                    description = 'You have clocked on as staff!',
                    type = 'success'
                })
                SendWebhook(source, "Clock In")
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Staff Clock In',
                    description = 'You are already clocked in!',
                    type = 'error'
                })
            end
        end
    end
end, false)

RegisterCommand("clockout", function(source, args, rawCommand)
    if exports['EasyAdmin-ox']:IsPlayerAdmin(source) then
        if not IsDutySystemEnabled() then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock Out',
                description = 'Duty system is disabled via convar!',
                type = 'info'
            })
            return
        end
    
        if HasDutyBypass(source) then
            Player(source).state['easyadmin-ox:clockedIn'] = 'no'
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock Out',
                description = 'You may clockin freely due to bypass.',
                type = 'success'
            })
            SendWebhook(source, "Clock Out (Bypass)")
        elseif Player(source).state['easyadmin-ox:clockedIn'] == 'yes' then
            Player(source).state['easyadmin-ox:clockedIn'] = 'no'
            playerCooldowns[source] = os.time()
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock Out',
                description = 'You have clocked out as staff!',
                type = 'success'
            })
            SendWebhook(source, "Clock Out")
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock Out',
                description = 'You are not clocked in as staff!',
                type = 'error'
            })
        end
    end
end, false)

AddEventHandler('playerDropped', function(reason)
    playerCooldowns[source] = nil
end)

-- Export the duty check function
exports('IsPlayerOnDuty', IsPlayerOnDuty)
