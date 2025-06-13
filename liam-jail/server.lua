-- Jail event handler
RegisterNetEvent("Liam:JailPlayerServer")
AddEventHandler("Liam:JailPlayerServer", function(targetId, jailtime, jailReason)
    local targetPlayer = tonumber(targetId)
    if targetPlayer and GetPlayerName(targetPlayer) then
        local playerName = GetPlayerName(targetPlayer)
        local playerIdentifiers = GetPlayerIdentifiers(targetPlayer)
        local discordId = nil
        
        for _, identifier in ipairs(playerIdentifiers) do
            if string.find(identifier, "discord:") then
                discordId = string.sub(identifier, 9)
                break
            end
        end

        if discordId then
            local reason = string.format("%s. \nTime: %s seconds.", jailReason or "No reason provided", jailtime)
            local moderatorName = GetPlayerName(source)
            local moderatorDiscordId = nil

            local moderatorIdentifiers = GetPlayerIdentifiers(source)
            for _, identifier in ipairs(moderatorIdentifiers) do
                if string.find(identifier, "discord:") then
                    moderatorDiscordId = string.sub(identifier, 9)
                    break
                end
            end
            
            Storage.addAction("~y~JAILED~w~~s~", discordId, reason, moderatorName, moderatorDiscordId)
        end
        TriggerClientEvent("Liam:JailPlayer", targetPlayer, jailtime, jailReason)
    end
end)

-- Unjail event handler
RegisterNetEvent("Liam:UnjailPlayerServer")
AddEventHandler("Liam:UnjailPlayerServer", function(targetId)
    local targetPlayer = tonumber(targetId)
    if targetPlayer and GetPlayerName(targetPlayer) then
        TriggerClientEvent("Liam:UnjailPlayer", targetPlayer)
    end
end)
