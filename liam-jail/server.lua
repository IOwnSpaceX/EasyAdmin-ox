-- File operations for jail data
local jailDataPath = GetResourcePath(GetCurrentResourceName())..'/jail_data.json'

local function LoadJailData()
    local file = io.open(jailDataPath, 'r')
    if file then
        local content = file:read('*all')
        file:close()
        return json.decode(content) or {}
    end
    return {}
end

local function SaveJailData(data)
    local file = io.open(jailDataPath, 'w')
    if file then
        file:write(json.encode(data))
        file:close()
    end
end

local function GetFivemIdentifier(player)
    local identifiers = GetPlayerIdentifiers(player)
    for _, v in pairs(identifiers) do
        if string.find(v, "fivem") then
            return v
        end
    end
    return nil
end


local jailData = LoadJailData()

-- Event for player connecting
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    local identifier = GetFivemIdentifier(source)
    if identifier and jailData[identifier] then
        local jailInfo = jailData[identifier]
        if jailInfo.remainingTime > 0 then
            -- Player still has time to serve, resume their jail time
            Citizen.CreateThread(function()
                Citizen.Wait(2000) -- Wait for player to fully connect
                TriggerClientEvent("Liam:JailPlayer", source, jailInfo.remainingTime, jailInfo.reason)
            end)
        else
            -- Remove from jail data if time served
            jailData[identifier] = nil
            SaveJailData(jailData)
        end
    end
end)

-- Event for player disconnecting
AddEventHandler('playerDropped', function(reason)
    local source = source    
    local identifier = GetFivemIdentifier(source)
    
    if identifier and jailData[identifier] and jailData[identifier].remainingTime > 0 then
        SaveJailData(jailData)
    end
end)

-- Original Jail event handler with persistence
RegisterNetEvent("Liam:JailPlayerServer")
AddEventHandler("Liam:JailPlayerServer", function(targetId, jailtime, jailReason)
    local targetPlayer = tonumber(targetId)
    if targetPlayer and GetPlayerName(targetPlayer) then
        local identifier = GetFivemIdentifier(targetPlayer)
        if identifier then
            jailData[identifier] = {
                remainingTime = jailtime,
                reason = jailReason
            }
            SaveJailData(jailData)
        end
        
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

-- Updated Unjail event handler
RegisterNetEvent("Liam:UnjailPlayerServer")
AddEventHandler("Liam:UnjailPlayerServer", function(targetId)
    local targetPlayer = tonumber(targetId)
    if targetPlayer and GetPlayerName(targetPlayer) then
        local identifier = GetFivemIdentifier(targetPlayer)
        if identifier and jailData[identifier] then
            jailData[identifier] = nil
            SaveJailData(jailData)
        end
        TriggerClientEvent("Liam:UnjailPlayer", targetPlayer)
    end
end)

-- New event to update remaining time
RegisterNetEvent("Liam:UpdateJailTime")
AddEventHandler("Liam:UpdateJailTime", function(remainingTime)
    local source = source
    local identifier = GetFivemIdentifier(source)
    if identifier and jailData[identifier] then
        jailData[identifier].remainingTime = remainingTime
        SaveJailData(jailData)
    end
end)