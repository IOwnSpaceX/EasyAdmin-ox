local resourceName = GetCurrentResourceName()

local function isBanLogEnabled()
    local ch = GetConvar("ea_banLogChannel", "")
    return ch ~= "" and ch ~= "false" and ch ~= "none"
end

local function buildDurationLabel(expireTimestamp)
    if not expireTimestamp or expireTimestamp >= 10444633200 then
        return "Permanent"
    end
    local seconds = expireTimestamp - os.time()
    if seconds <= 0 then return "Expired" end
    local days    = math.floor(seconds / 86400)
    local hours   = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local parts = {}
    if days    > 0 then parts[#parts+1] = days    .. " Day(s)"    end
    if hours   > 0 then parts[#parts+1] = hours   .. " Hour(s)"   end
    if minutes > 0 then parts[#parts+1] = minutes .. " Minute(s)" end
    return (#parts > 0) and table.concat(parts, " ") or "< 1 Minute"
end

local function extractDiscordId(identifiers)
    if not identifiers then return nil end
    for _, id in ipairs(identifiers) do
        if type(id) == "string" and id:find("^discord:") then
            return id:sub(9)
        end
    end
    return nil
end

local _recentlyDispatched = {}

local function dispatchBanLog(bannerSrc)
    if not isBanLogEnabled() then return end

    local bannerDiscord = nil
    if bannerSrc and CachedPlayers and CachedPlayers[bannerSrc] then
        bannerDiscord = extractDiscordId(CachedPlayers[bannerSrc].identifiers)
    end

    Citizen.SetTimeout(800, function()
        local ban = exports[resourceName]:getLastBan()
        if not ban or not ban.banid then return end

        local banId = tostring(ban.banid)
        if _recentlyDispatched[banId] then return end
        _recentlyDispatched[banId] = true
        Citizen.SetTimeout(5000, function()
            _recentlyDispatched[banId] = nil
        end)

        local payload = {
            banid         = ban.banid,
            name          = ban.name         or "Unknown",
            banner        = ban.banner        or "Unknown",
            bannerDiscord = bannerDiscord,
            reason        = ban.reason        or "No reason provided",
            expire        = ban.expire,
            expireString  = ban.expireString  or formatDateString(ban.expire or 0),
            durationLabel = buildDurationLabel(ban.expire),
            identifiers   = ban.identifiers   or {},
        }

        local ok, err = pcall(function()
            exports[resourceName]:sendBanLog(payload)
        end)

        if not ok then
            PrintDebugMessage("^1[BanMgmt]^7 Failed to dispatch ban log: " .. tostring(err), 1)
        end
    end)
end

RegisterServerEvent("EasyAdmin:banPlayer")
AddEventHandler("EasyAdmin:banPlayer", function()
    dispatchBanLog(source)
end)

RegisterServerEvent("EasyAdmin:offlinebanPlayer")
AddEventHandler("EasyAdmin:offlinebanPlayer", function()
    dispatchBanLog(source)
end)

AddEventHandler("EasyAdmin:addBan", function()
    dispatchBanLog(source)
end)
