------------------------------------
------------------------------------
---- DONT TOUCH ANY OF THIS IF YOU DON'T KNOW WHAT YOU ARE DOING
---- THESE ARE **NOT** CONFIG VALUES, USE THE CONVARS IF YOU WANT TO CHANGE SOMETHING
----
----
---- If you are a developer and want to change something, consider writing a plugin instead:
---- https://easyadmin.readthedocs.io/en/latest/plugins/
----
------------------------------------
------------------------------------

CachedPlayers = {} -- DO NOT TOUCH THIS

Citizen.CreateThread(function()
	while true do 
		Wait(20000)
		local osTime = os.time()
		local playerCacheExpiry = GetConvarInt("ea_playerCacheExpiryTime", 1800)
		for i, player in pairs(CachedPlayers) do 
			if player.droppedTime and (osTime > player.droppedTime+playerCacheExpiry) then
				PrintDebugMessage("Cache for "..player.id.." expired, removing from cache.", 3)
				for i, report in pairs(reports) do
					if report.reported == player.id then 
						reports[i] = nil
					end
				end
				CachedPlayers[i]=nil
			end
		end
	end
end)

function cachePlayer(playerId)
	if not CachedPlayers[playerId] then
		CachedPlayers[playerId] = { 
			id = playerId, 
			name = getName(playerId, true), 
			identifiers = getAllPlayerIdentifiers(playerId), 
			immune = DoesPlayerHavePermission(playerId, "immune"), 
			discord = GetPlayerIdentifierByType(playerId, 'discord') and GetPlayerIdentifierByType(playerId, 'discord'):gsub("discord:", "") or false 
		}
		
		-- Rank System
		CachedPlayers[playerId].rank = GetPlayerStaffRank(playerId)
		if CachedPlayers[playerId].hideRank == nil then
			CachedPlayers[playerId].hideRank = false
		end
		
		PrintDebugMessage(getName(playerId).." has been added to cache.", 4)
		return CachedPlayers[playerId]
	end
	return CachedPlayers[playerId]
end

RegisterServerEvent("EasyAdmin:requestCachedPlayers", function()
	PrintDebugMessage(getName(source, true).." requested Cache.", 4)
	local src = source
	if (DoesPlayerHavePermission(source, "player.ban.temporary") or DoesPlayerHavePermission(source, "player.ban.permanent")) then
		TriggerLatentClientEvent("EasyAdmin:fillCachedPlayers", src, 200000, CachedPlayers)
	end
end)

function getCachedPlayers() -- this is server-only for security reasons.
    return CachedPlayers
end
exports('getCachedPlayers', getCachedPlayers)

function getCachedPlayer(id)
	cachePlayer(tonumber(id))
    return CachedPlayers[tonumber(id)]
end
exports('getCachedPlayer', getCachedPlayer)

AddEventHandler('playerDropped', function (reason)
	if CachedPlayers[source] then
		CachedPlayers[source].droppedTime = os.time()
		CachedPlayers[source].dropped = true
	end
end)

function GetPlayerStaffRank(src)
    if not Config or not Config.StaffRanks then
        local configFile = LoadResourceFile(GetCurrentResourceName(), "plugins/rank_config.lua")
        if configFile then
            load(configFile)()
            print("^2[EasyAdmin] Rank config loaded successfully.^7")
        else
            print("^1[EasyAdmin] WARNING: Could not load plugins/rank_config.lua^7")
            return GetDefaultPlayerStaffRank(src)
        end
    end

    for _, perm in ipairs(Config.RankOrder or {}) do
        if DoesPlayerHavePermission(src, perm) then
            return Config.StaffRanks[perm] or "Staff"
        end
    end

    return "Staff"
end

function GetDefaultPlayerStaffRank(src)
    if DoesPlayerHavePermission(src, "easyadmin.stafftag.owner") then return "Owner" end
    if DoesPlayerHavePermission(src, "easyadmin.stafftag.admin") then return "Admin" end
    if DoesPlayerHavePermission(src, "easyadmin.stafftag.mod") then return "Moderator" end
    if DoesPlayerHavePermission(src, "easyadmin") then return "Staff" end
    return "Player"
end
