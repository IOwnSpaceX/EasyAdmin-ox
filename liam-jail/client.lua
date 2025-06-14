local IsJailed = false
local EarlyRelease = false
local JailCoords = vector3(1677.233, 2658.618, 45.216)
local MaxDistance = 50.0 -- Maximum distance the player can wander from the jail center
local TimeAddedForEscape = 60 -- Seconds added for escape attempts
local JailReason = "No reason provided"

RegisterNetEvent("Liam:JailPlayer")
AddEventHandler("Liam:JailPlayer", function(jailtime, reason)
    if IsJailed then return end
    
    local playerPed = PlayerPedId()
    if DoesEntityExist(playerPed) then
        Citizen.CreateThread(function()
            SetEntityCoords(playerPed, JailCoords)
            IsJailed = true
            EarlyRelease = false
            JailReason = reason or "No reason provided"
            
            while jailtime > 0 and not EarlyRelease do
                playerPed = PlayerPedId()
                RemoveAllPedWeapons(playerPed, true)
                SetEntityInvincible(playerPed, true)
                
                if IsPedInAnyVehicle(playerPed, false) then
                    ClearPedTasksImmediately(playerPed)
                end

                lib.showTextUI(string.format("You have %s seconds remaining in jail for: %s", math.floor(jailtime), JailReason), {
                    position = "bottom-center",
                    icon = 'clock',
                    style = {
                        borderRadius = 8,
                        backgroundColor = '#ba1420',
                        color = 'white'
                    }
                })
                
                Citizen.Wait(500)
                local playerLoc = GetEntityCoords(playerPed, true)
                local distance = #(JailCoords - playerLoc)
                
                if distance > MaxDistance then
                    SetEntityCoords(playerPed, JailCoords)
                    -- jailtime = jailtime + TimeAddedForEscape
                    -- if jailtime > 1500 then
                    --     jailtime = 1500
                    -- end
                    lib.notify({
                        title = 'Escape Attempt',
                        -- description = "Your jail time was extended by " .. TimeAddedForEscape .. " seconds because you tried to escape.",
                        description = "Your escape attempt failed miserably.",
                        type = 'error'
                    })
                end
                  jailtime = jailtime - 0.5
                -- Update server with remaining time
                TriggerServerEvent("Liam:UpdateJailTime", jailtime)
            end
            
            lib.hideTextUI()
            SetEntityCoords(playerPed, 1849.0, 2585.0, 45.0)
            SetEntityHeading(playerPed, 265.0)
            IsJailed = false
            SetEntityInvincible(playerPed, false)
            lib.notify({
                title = 'Released',
                description = "You have been released from jail.",
                type = 'success'
            })
        end)
    end
end)

RegisterNetEvent("Liam:UnjailPlayer")
AddEventHandler("Liam:UnjailPlayer", function()
    EarlyRelease = true
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, 1849.0, 2585.0, 45.0)
    SetEntityHeading(playerPed, 265.0)
    IsJailed = false
    SetEntityInvincible(playerPed, false)
    lib.hideTextUI()
    lib.notify({
        title = 'Early Release',
        description = "You have been released from jail early.",
        type = 'success'
    })
end)