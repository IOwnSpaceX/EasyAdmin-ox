------------------------------------
------------------------------------
---- DONT TOUCH ANY OF THIS IF YOU DON'T KNOW WHAT YOU ARE DOING
---- THESE ARE **NOT** CONFIG VALUES, USE THE CONVARS IF YOU WANT TO CHANGE SOMETHING
---- If you are a developer and want to change something, consider writing a plugin instead:
---- https://easyadmin.readthedocs.io/en/latest/plugins/
------------------------------------

blacklist = {} -- in-memory cache

---Handles the banning of a player
RegisterServerEvent("EasyAdmin:banPlayer", function(playerId, reason, expires)
    if playerId ~= nil and CheckAdminCooldown(source, "ban") then
        if (DoesPlayerHavePermission(source, "player.ban.temporary") or DoesPlayerHavePermission(source, "player.ban.permanent"))
            and CachedPlayers[playerId] and not CachedPlayers[playerId].immune then

            SetAdminCooldown(source, "ban")
            local bannedIdentifiers = CachedPlayers[playerId].identifiers or getAllPlayerIdentifiers(playerId)
            local username = CachedPlayers[playerId].name or getName(playerId, true)

            if expires and expires < os.time() then
                expires = os.time() + expires
            elseif not expires then
                expires = 10444633200
            end
            if expires >= 10444633200 and not DoesPlayerHavePermission(source, "player.ban.permanent") then
                return false
            end

            local function formatBanDuration(expireTime)
                local currentTime = os.time()
                local duration = expireTime - currentTime
                if duration <= 0 then return "Permanent" end
                local months = math.floor(duration / 2592000)
                local weeks = math.floor(duration / 604800)
                local days = math.floor((duration % 604800) / 86400)
                local hours = math.floor((duration % 86400) / 3600)
                local parts = {}
                if months > 0 then table.insert(parts, string.format("%d month(s)", months)) end
                if weeks > 0 then table.insert(parts, string.format("%d week(s)", weeks)) end
                if days > 0 then table.insert(parts, string.format("%d day(s)", days)) end
                if hours > 0 then table.insert(parts, string.format("%d hour(s)", hours)) end
                return table.concat(parts, ", ")
            end

            local function GetDiscordId(playerId)
                if not playerId then return nil end
                for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
                    if identifier:match("^discord:") then
                        return identifier:gsub("^discord:", "")
                    end
                end
                return nil
            end

            reason = formatShortcuts(reason)
            local banId = GetFreshBanId()
            Storage.addBan(banId, username, bannedIdentifiers, getName(source), reason, expires, formatDateString(expires), "BAN", os.time())
            local banDuration = formatBanDuration(expires)
            local formattedReason = string.format("%s \nTime: %s", reason, banDuration)
            Storage.addAction("~r~BANNED~w~~s~", GetDiscordId(playerId) or "Unknown", formattedReason, getName(source), GetDiscordId(source) or "Unknown")
            PrintDebugMessage("Player "..getName(source,true).." banned player "..CachedPlayers[playerId].name.." for "..reason, 3)
            SendWebhookMessage(moderationNotification,string.format(GetLocalisedText("adminbannedplayer"), getName(source, false, true), CachedPlayers[playerId].name, reason, formatDateString(expires), tostring(banId)), "ban", 16711680)
            DropPlayer(playerId, string.format(GetLocalisedText("banned"), reason, formatDateString(expires)))
        elseif CachedPlayers[playerId].immune then
            TriggerClientEvent("EasyAdmin:showNotification", source, GetLocalisedText("adminimmune"))
        end
    end
end)

---Handles the banning of an offline player
RegisterServerEvent("EasyAdmin:offlinebanPlayer", function(playerId, reason, expires)
    if playerId ~= nil and not CachedPlayers[playerId].immune and CheckAdminCooldown(source, "ban") then
        if (DoesPlayerHavePermission(source, "player.ban.temporary") or DoesPlayerHavePermission(source, "player.ban.permanent")) then
            SetAdminCooldown(source, "ban")
            local bannedIdentifiers = CachedPlayers[playerId].identifiers or getAllPlayerIdentifiers(playerId)
            local username = CachedPlayers[playerId].name or getName(playerId, true)

            if expires and expires < os.time() then
                expires = os.time() + expires
            elseif not expires then
                expires = 10444633200
            end
            if expires >= 10444633200 and not DoesPlayerHavePermission(source, "player.ban.permanent") then
                return false
            end

            reason = formatShortcuts(reason).. string.format(GetLocalisedText("reasonadd"), CachedPlayers[playerId].name, getName(source))
            Storage.addBan(GetFreshBanId(), username, bannedIdentifiers, getName(source), reason, expires, formatDateString(expires), "OFFLINE BAN", os.time())
            Storage.addAction("OFFLINE BAN", CachedPlayers[playerId].discordId, reason, getName(source), CachedPlayers[source].discordId)
            PrintDebugMessage("Player "..getName(source,true).." offline banned player "..CachedPlayers[playerId].name.." for "..reason, 3)
            SendWebhookMessage(moderationNotification,string.format(GetLocalisedText("adminofflinebannedplayer"), getName(source, false, true), CachedPlayers[playerId].name, reason, formatDateString(expires)), "ban", 16711680)
        end
    elseif CachedPlayers[playerId].immune then
        TriggerClientEvent("EasyAdmin:showNotification", source, GetLocalisedText("adminimmune"))
    end
end)

AddEventHandler('banCheater', function(playerId,reason)
    Citizen.Trace("^1EasyAdmin^7: the banCheater event is ^1deprecated^7 and has been removed! Please adjust your resource to use EasyAdmin:addBan instead.")
end)

---Adds a ban to the banlist
function addBanExport(playerId, reason, expires, banner)
    local bannedIdentifiers = {}
    local bannedUsername = "Unknown"
    local offline = false

    if type(playerId) == "table" then
        offline = true
        bannedIdentifiers = playerId
    elseif CachedPlayers[playerId] then
        if CachedPlayers[playerId].dropped then offline = true end
        if CachedPlayers[playerId].immune then return false end
        bannedIdentifiers = CachedPlayers[playerId].identifiers
        bannedUsername = CachedPlayers[playerId].name or getName(playerId, true)
    else
        PrintDebugMessage("Couldn't find any Infos about Player "..playerId..", no ban issued.", 1)
        return false
    end

    if expires and expires < os.time() then
        expires = os.time() + expires
    elseif not expires then
        expires = 10444633200
    end

    reason = formatShortcuts(reason).. string.format(GetLocalisedText("reasonadd"), getName(tostring(playerId) or "?"), banner or "Unknown" )
    local banId = GetFreshBanId()
    Storage.addBan(banId, bannedUsername, bannedIdentifiers, banner or "Unknown", reason, expires, formatDateString(expires), "BAN", os.time())
    Storage.addAction("BAN", bannedIdentifiers[1], reason, banner or "Unknown", source, expires, formatDateString(expires))
    
    if source then
        PrintDebugMessage("Player "..getName(source,true).." added ban "..reason, 3)
    end

    SendWebhookMessage(moderationNotification,string.format(GetLocalisedText("adminbannedplayer"), banner or "Unknown", getName(tostring(playerId) or "?", false, true), reason, formatDateString(expires), tostring(banId)), "ban", 16711680)

    if not offline then
        DropPlayer(playerId, string.format(GetLocalisedText("banned"), reason, formatDateString(expires)))
    end

    return banId
end
exports('addBan', addBanExport)
AddEventHandler("EasyAdmin:addBan", addBanExport)

---Update and fetch bans
RegisterServerEvent("EasyAdmin:updateBanlist", function(playerId)
    local src = source
    if DoesPlayerHavePermission(source, "player.ban.view") then
        -- Nothing needed; DB always up-to-date
        local banlist = Storage.getBanList()
        Citizen.Wait(300)
        TriggerLatentClientEvent("EasyAdmin:fillBanlist", src, 100000, banlist)
        PrintDebugMessage("Banlist Refreshed by "..getName(src,true), 3)
    end
end)

RegisterServerEvent("EasyAdmin:requestBanlist", function()
    local src = source
    if DoesPlayerHavePermission(source, "player.ban.view") then
        TriggerLatentClientEvent("EasyAdmin:fillBanlist", src, 100000, Storage.getBanList())
        PrintDebugMessage("Banlist Requested by "..getName(src,true), 3)
    end
end)

RegisterCommand("unban", function(source, args, rawCommand)
    if args[1] and DoesPlayerHavePermission(source, "player.ban.remove") and CheckAdminCooldown(source, "unban") then
        SetAdminCooldown(source, "unban")
        PrintDebugMessage("Player "..getName(source,true).." Unbanned "..args[1], 3)
        if tonumber(args[1]) then
            UnbanId(tonumber(args[1]))
        else
            UnbanIdentifier(args[1])
        end
        if (source ~= 0) then
            TriggerClientEvent("EasyAdmin:showNotification", source, GetLocalisedText("done"))
        else
            Citizen.Trace(GetLocalisedText("done"))
        end
        SendWebhookMessage(moderationNotification,string.format(GetLocalisedText("adminunbannedplayer"), getName(source, false, true), args[1], "Unbanned via Command"), "ban", 16711680)
    end
end, false)

RegisterServerEvent("EasyAdmin:editBan", function(ban)
    if DoesPlayerHavePermission(source, "player.ban.edit") then
        Storage.updateBan(ban.banid, ban)
    end
end)

function unbanPlayer(banId)
    return Storage.removeBan(banId)
end
exports('unbanPlayer', unbanPlayer)

function fetchBan(banId)
    return Storage.getBan(banId)
end
exports('fetchBan', fetchBan)

RegisterServerEvent("EasyAdmin:unbanPlayer", function(banId)
    if DoesPlayerHavePermission(source, "player.ban.remove") and CheckAdminCooldown(source, "unban") then
        SetAdminCooldown(source, "unban")
        local thisBan = fetchBan(banId)
        local ret = unbanPlayer(banId)
        if ret then
            PrintDebugMessage("Player "..getName(source,true).." unbanned "..banId, 3)
            SendWebhookMessage(moderationNotification,string.format(GetLocalisedText("adminunbannedplayer"), getName(source, false, true), banId, thisBan.reason), "ban", 16711680)
        end
    end
end)

---Generates a new unique ban ID
function GetFreshBanId()
    local startId = 100
    local freshId = startId
    local banList = Storage.getBanList()
    if #banList > 0 then
        local lastBan = banList[#banList]
        local lastNum = tonumber(lastBan.banid:match("%d+"))
        freshId = lastNum + 1
    end
    return "NET-"..freshId
end
exports('GetFreshBanId', GetFreshBanId)

---Database-based identifier bans
function BanIdentifier(identifier, reason)
    Storage.addBan(GetFreshBanId(), "Unknown", {identifier}, "Unknown", reason, 10444633200, formatDateString(10444633200), "BAN", os.time())
end

function BanIdentifiers(identifier, reason)
    Storage.addBan(GetFreshBanId(), "Unknown", identifier, "Unknown", reason, 10444633200, formatDateString(10444633200), "BAN", os.time())
end

function UnbanIdentifier(identifier)
    Storage.removeBanIdentifier(identifier)
end

function performBanlistUpgrades()
    local upgraded = false
    local banlist = Storage.getBanList()
    local takenIds = {}
    for i,b in pairs(banlist) do
        if takenIds[b.banid] then
            local freshId = GetFreshBanId()
            PrintDebugMessage("ID "..b.banid.." was assigned twice, reassigned to "..freshId, 4)
            banlist[i].banid = freshId
            upgraded = true
        end
        takenIds[b.banid] = true
    end

    for i,ban in ipairs(banlist) do
        if ban.identifiers then
            for k, identifier in pairs(ban.identifiers) do
                if identifier == "" then
                    PrintDebugMessage("Ban "..ban.banid.." had an empty identifier, removed it.", 4)
                    ban.identifiers[k] = nil
                    upgraded = true
                end
            end
        end
        if not ban.expireString then
            upgraded = true
            ban.expireString = formatDateString(ban.expire)
        end
    end

    Storage.updateBanlist(banlist)
    return upgraded
end

function IsIdentifierBanned(theIdentifier)
    return Storage.getBanIdentifier(theIdentifier)
end
exports('IsIdentifierBanned', IsIdentifierBanned)
