-- webhook configuration
local Config = {
    Webhook = {
        enabled = true, -- do you want the bots to send logs?
        url = "https://discord.com/api/webhooks/xxxxxxx", -- webhook url
        botName = "Chimera Duty Bot", -- webhook name
        avatarUrl = "https://imgur.com/xxxxxx" -- replace with an avatar url
    }
}

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
                ["text"] = "Chimera Duty System 🦉"
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

RegisterCommand("clockin", function(source, args, rawCommand)
    if exports['EasyAdmin']:IsPlayerAdmin(source) then
        if Player(source).state['chimerastaff:clockedIn'] == 'no' or Player(source).state['chimerastaff:clockedIn'] == nil then
            Player(source).state['chimerastaff:clockedIn'] = 'yes'
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock In',
                description = 'You have clocked on as staff!',
                type = 'success'
            })
            SendWebhook(source, "Clock In")
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Staff Clock In',
                description = 'You are already clocked on as staff!',
                type = 'error'
            })
        end
    end
end, false)

RegisterCommand("clockout", function(source, args, rawCommand)
    if exports['EasyAdmin']:IsPlayerAdmin(source) then
        if Player(source).state['chimerastaff:clockedIn'] == 'yes' then
            Player(source).state['chimerastaff:clockedIn'] = 'no'
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
