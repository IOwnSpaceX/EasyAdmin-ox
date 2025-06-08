-- Jail event handler
RegisterNetEvent("Liam:JailPlayerServer")
AddEventHandler("Liam:JailPlayerServer", function(targetId, jailtime)
    local targetPlayer = tonumber(targetId)
    if targetPlayer and GetPlayerName(targetPlayer) then
        TriggerClientEvent("Liam:JailPlayer", targetPlayer, jailtime)
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
