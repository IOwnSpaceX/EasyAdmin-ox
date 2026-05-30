------------------------------------------------------
-- EasyAdmin-ox | Death/Kill Tracker - Client
-- Detects player deaths/kills natively.
        -- By: Liam (IOwnSpaceX)
------------------------------------------------------

local boneNames = {
    -- Head / Neck
    [31086] = "Head",
    [20178] = "Head",
    [39317] = "Neck",
    [38539] = "Neck",
    -- Spine / Torso
    [23553] = "Upper Chest",
    [24816] = "Chest",
    [11816] = "Stomach",
    [14201] = "Lower Torso",
    [57597] = "Spine",
    -- Left Arm
    [61163] = "Left Shoulder",
    [36029] = "Left Upper Arm",
    [2992]  = "Left Elbow",
    [40269] = "Left Forearm",
    [18905] = "Left Hand",
    [64729] = "Left Finger",
    -- Right Arm
    [40269+1] = "Right Shoulder",
    [45509] = "Right Shoulder",
    [28252] = "Right Upper Arm",
    [22711] = "Right Forearm",
    [49286] = "Right Hand",
    [60309] = "Right Finger",
    -- Left Leg
    [46078] = "Left Thigh",
    [16335] = "Left Knee",
    [51826] = "Left Shin",
    [20781] = "Left Foot",
    [14201+1] = "Left Toe",
    [2108]  = "Left Toe",
    -- Right Leg
    [8086]  = "Right Thigh",
    [51826+1] = "Right Knee",
    [63931] = "Right Knee",
    [35502] = "Right Shin",
    [52301] = "Right Foot",
    [20393] = "Right Toe",
    -- Fallback
    [0]     = "Body",
}

local function GetBoneName(boneId)
    if boneNames[boneId] then
        return boneNames[boneId]
    end
    if boneId and boneId ~= 0 then
        print("[EasyAdmin Deaths] Unknown bone ID: " .. tostring(boneId) .. " - please report this!")
    end
    return "Body"
end

local weaponLabels = {
    ["WEAPON_PISTOL"]           = "Pistol",
    ["WEAPON_PISTOL_MK2"]       = "Pistol Mk II",
    ["WEAPON_COMBATPISTOL"]     = "Combat Pistol",
    ["WEAPON_APPISTOL"]         = "AP Pistol",
    ["WEAPON_MICROSMG"]         = "Micro SMG",
    ["WEAPON_SMG"]              = "SMG",
    ["WEAPON_SMG_MK2"]          = "SMG Mk II",
    ["WEAPON_ASSAULTRIFLE"]     = "Assault Rifle",
    ["WEAPON_ASSAULTRIFLE_MK2"] = "Assault Rifle Mk II",
    ["WEAPON_CARBINERIFLE"]     = "Carbine Rifle",
    ["WEAPON_SNIPERRIFLE"]      = "Sniper Rifle",
    ["WEAPON_HEAVYSNIPER"]      = "Heavy Sniper",
    ["WEAPON_SHOTGUN"]          = "Pump Shotgun",
    ["WEAPON_SAWNOFFSHOTGUN"]   = "Sawn-Off Shotgun",
    ["WEAPON_ASSAULTSHOTGUN"]   = "Assault Shotgun",
    ["WEAPON_UNARMED"]          = "Fists",
    ["WEAPON_KNIFE"]            = "Knife",
    ["WEAPON_BAT"]              = "Baseball Bat",
    ["WEAPON_VEHICLE"]          = "Vehicle",
    ["WEAPON_FALL"]             = "Fall",
    ["WEAPON_DROWNING"]         = "Drowning",
    ["WEAPON_EXPLOSION"]        = "Explosion",
    ["WEAPON_FIRE"]             = "Fire",
}

local function GetWeaponLabel(weaponHash)
    for k, v in pairs(weaponLabels) do
        if GetHashKey(k) == weaponHash then
            return v
        end
    end
    local labelKey = string.format("WT_%s", tostring(weaponHash))
    local label = GetLabelText(labelKey)
    if label and label ~= "NULL" and label ~= "" then
        return label
    end
    return "Unknown Weapon"
end

local isDead    = false
local reported  = false

CreateThread(function()
    while true do
        Wait(500)

        local ped = PlayerPedId()

        if IsEntityDead(ped) and not isDead then
            isDead   = true
            reported = false

            Wait(100)

            local weaponHash = GetPedCauseOfDeath(ped)
            local weaponName = GetWeaponLabel(weaponHash)
            local damBone    = GetPedLastDamageBone(ped)
            local boneName   = GetBoneName(damBone)

            local killerServerId = nil
            local killerEntity   = GetPedSourceOfDeath(ped)

            if killerEntity and killerEntity ~= 0 then
                local resolvedPed = nil

                if IsEntityAPed(killerEntity) then
                    resolvedPed = killerEntity
                elseif IsEntityAVehicle(killerEntity) then
                    local driver = GetPedInVehicleSeat(killerEntity, -1)
                    if driver and driver ~= 0 and DoesEntityExist(driver) then
                        resolvedPed = driver
                        if weaponName == "Unknown Weapon" then
                            weaponName = "Vehicle"
                        end
                    end
                end

                if resolvedPed then
                    local killerPlayer = NetworkGetPlayerIndexFromPed(resolvedPed)
                    if killerPlayer ~= -1 then
                        killerServerId = GetPlayerServerId(killerPlayer)
                    end
                end
            end

            if not reported then
                reported = true
                TriggerServerEvent("EasyAdmin:ReportDeath", killerServerId, weaponName, boneName)
            end

        elseif not IsEntityDead(ped) and isDead then
            isDead   = false
            reported = false
        end
    end
end)

EADeathData = nil

RegisterNetEvent("EasyAdmin:ReceivePlayerDeaths")
AddEventHandler("EasyAdmin:ReceivePlayerDeaths", function(data)
    EADeathData = data
end)
