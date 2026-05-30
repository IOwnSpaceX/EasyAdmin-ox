------------------------------------------------------
-- EasyAdmin-ox | Death/Kill Tracker - Server
-- Stores death/kills.
-- Entries older than 30 minutes are auto-removed from the file.
        --By: Liam (IOwnSpaceX)
------------------------------------------------------

local DEATH_FILE   = "deathsnkills.json"
local PURGE_AFTER  = 30 * 60

local function LoadDeaths()
    local raw = LoadResourceFile(GetCurrentResourceName(), DEATH_FILE)
    if raw and raw ~= "" then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function SaveDeaths(data)
    SaveResourceFile(GetCurrentResourceName(), DEATH_FILE, json.encode(data), -1)
end

local function PurgeOld(data)
    local now  = os.time()
    local kept = {}
    for _, entry in ipairs(data) do
        if (now - entry.timestamp) < PURGE_AFTER then
            table.insert(kept, entry)
        end
    end
    return kept
end

local function RecordDeath(victimId, killerId, weapon, hitBone)
    local data   = LoadDeaths()
    data         = PurgeOld(data)

    local victimName = GetPlayerName(victimId) or "Unknown"
    local killerName = killerId and GetPlayerName(killerId) or "Unknown"

    local entry = {
        timestamp   = os.time(),
        victimId    = GetPlayerServerId and GetPlayerServerId(victimId) or victimId,
        victimName  = victimName,
        killerId    = killerId and (GetPlayerServerId and GetPlayerServerId(killerId) or killerId) or nil,
        killerName  = killerName,
        weapon      = weapon   or "Unknown",
        hitBone     = hitBone  or "Unknown",
    }

    table.insert(data, 1, entry)
    SaveDeaths(data)
end

RegisterNetEvent("EasyAdmin:ReportDeath")
AddEventHandler("EasyAdmin:ReportDeath", function(killerId, weapon, hitBone)
    local victimId = source
    RecordDeath(victimId, killerId, weapon, hitBone)
end)

RegisterNetEvent("EasyAdmin:RequestPlayerDeaths")
AddEventHandler("EasyAdmin:RequestPlayerDeaths", function(targetServerId)
    local src  = source
    local data = LoadDeaths()
    data       = PurgeOld(data)
    SaveDeaths(data)

    local deaths = {}
    local kills  = {}
    local now    = os.time()

    for _, entry in ipairs(data) do
        local age = now - entry.timestamp
        if entry.victimId == targetServerId then
            table.insert(deaths, { entry = entry, age = age })
        elseif entry.killerId == targetServerId then
            table.insert(kills, { entry = entry, age = age })
        end
    end

    TriggerClientEvent("EasyAdmin:ReceivePlayerDeaths", src, {
        deaths = deaths,
        kills  = kills,
    })
end)

CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)
        local data = LoadDeaths()
        data = PurgeOld(data)
        SaveDeaths(data)
    end
end)
