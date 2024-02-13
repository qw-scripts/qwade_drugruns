local hacking = require 'client.hacking'
local utils = require 'client.utils'
local ox_inventory = exports.ox_inventory

local current_run_data = nil
local dropOffPoint = nil

RegisterCommand('dev:run', function()
    TriggerServerEvent('qwade_drugruns:server:startMission', 'green_usb')
end)

local function startMission(data)
    local hacking_data = hacking[data.name]
    if not hacking_data then return end
    hacking_data.hack(function(success)
        if success then
            ox_inventory:useItem(data, function(item_data)
                if item_data then
                    TriggerServerEvent('qwade_drugruns:server:startMission', item_data.name)
                end
            end)
        else
            lib.notify({
                title = 'Drug Run',
                description = 'You failed the hack.',
                icon = 'fas fa-car',
            })
        end
    end)
end

exports('startMission', startMission)

local function playSearchAnim()
    lib.requestAnimDict('amb@medic@standing@kneel@base')
    lib.requestAnimDict('anim@gangops@facility@servers@bodysearch@')
    TaskPlayAnim(cache.ped, 'amb@medic@standing@kneel@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(cache.ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, -8.0, -1, 48, 0, false,
        false, false)
end

local function createDropOffPoint()
    if not current_run_data then return end

    dropOffPoint = lib.points.new({
        coords = current_run_data.drop_off,
        distance = 10.0,
    })

    function dropOffPoint:onEnter()
        if not current_run_data then return end

        local droppedOff = lib.callback.await('qwade_drugruns:dropOff', false, current_run_data.mission_id)

        if not droppedOff then return end

        lib.notify({
            title = 'Drug Run',
            description = 'The van is now in the drop off zone. You can now leave the area.',
            icon = 'fas fa-car',
        })

        local vehicle = NetToVeh(current_run_data.vehicle_net_id)
        FreezeEntityPosition(vehicle, true)
    end
end

local function searchForKeys()
    playSearchAnim()
    Wait(5000)
    ClearPedTasks(cache.ped)
    if not current_run_data?.plate or not current_run_data then return end
    utils.getVehicleKeys(current_run_data.plate)

    for i = 1, #current_run_data.peds, 1 do
        local ped = current_run_data.peds[i]
        exports.ox_target:removeEntity(ped.ped_net_id, { 'drugrun_search_keys' })
    end

    SetNewWaypoint(current_run_data.drop_off.x, current_run_data.drop_off.y)
    createDropOffPoint()
end

exports('searchForKeys', searchForKeys)


RegisterNetEvent('qwade_drugruns:client:setWaypoint', function(x, y)
    SetNewWaypoint(x, y)
end)

RegisterNetEvent("qwade_drugruns:client:missionComplete", function()
    lib.notify({
        title = 'Drug Run',
        description = 'You delivered the van successfully.',
        icon = 'fas fa-car',
    })
    if dropOffPoint then
        dropOffPoint:remove()
        dropOffPoint = nil
    end
    current_run_data = nil
end)

utils.entityStateHandler('mission', function(entity, _, value)
    if not value then return end

    if NetworkGetEntityOwner(entity) ~= cache.playerId then return end

    SetVehicleColours(entity, 0, 0)
    SetVehicleExtraColours(entity, 0, 0)
    SetVehicleNumberPlateText(entity, value.plate)
    SetVehicleDoorsLocked(entity, 2)
    utils.setFuel(entity)

    current_run_data = value
end)

utils.entityStateHandler('drugRunPed', function(entity, _, value)
    if not value then return end

    if NetworkGetEntityOwner(entity) ~= cache.playerId then return end

    local ped = value.attack == cache.serverId and cache.ped or GetPlayerPed(GetPlayerFromServerId(value.attack))

    -- health and armor --
    SetEntityMaxHealth(entity, value.health)
    SetEntityHealth(entity, value.health)

    -- Relationship --
    SetPedAsCop(entity, true)
    SetPedRelationshipGroupHash(entity, `HATES_PLAYER`)

    -- combat stuff --
    SetCanAttackFriendly(entity, false, true)
    SetPedCombatMovement(entity, 3)
    SetPedCombatRange(entity, 2)
    SetPedCombatAttributes(entity, 46, true)
    SetPedCombatAttributes(entity, 0, false)
    SetPedAccuracy(entity, 60)
    SetPedCombatAbility(entity, 100)
    TaskCombatPed(entity, ped, 0, 16)
    SetPedKeepTask(entity, true)
    SetPedSeeingRange(entity, 150.0)
    SetPedHearingRange(entity, 150.0)
    SetPedAlertness(entity, 3)


    -- other shit --
    SetPedDropsWeaponsWhenDead(entity, false)
    SetPedFleeAttributes(entity, 0, false)

    -- targeting stuff ==
    local net_id = NetworkGetNetworkIdFromEntity(entity)
    exports.ox_target:addEntity(net_id, {
        {
            label = 'Search For Van Keys',
            icon = 'fa-solid fa-magnifying-glass',
            name = 'drugrun_search_keys',
            distance = 2.0,
            canInteract = function(ent, distance, coords, name, bone)
                if IsPedDeadOrDying(ent, true) then return true end
            end,
            resource = 'qwade_drugruns',
            export = 'searchForKeys'
        }
    })
end)
