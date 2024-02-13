local locations = require 'server.locations'
local runs = require 'server.runs'
local utils = require 'server.utils'
local rewards = require 'server.rewards'
local discord = require 'server.discord'
local running_missions = {}

--#region Functions

local function getMissionFromMissionId(mission_id)
    for i = 1, #running_missions do
        local mission = running_missions[i]
        if mission.mission_id == mission_id then
            return mission
        end
    end

    return nil
end

local function endRunningMission(mission, source)
    if not mission then return end

    discord.send(source, 'Mission Completed')

    for i = 1, #running_missions do
        local running_mission = running_missions[i]
        if running_mission.mission_id == mission.mission_id then
            table.remove(running_missions, i)
            break
        end
    end

    if DoesEntityExist(mission.vehicle) then
        DeleteEntity(mission.vehicle)
    end

    for i = 1, #mission.peds do
        local ped = mission.peds[i]
        if DoesEntityExist(ped.ped) then
            DeleteEntity(ped.ped)
        end
    end
    TriggerClientEvent('qwade_drugruns:client:missionComplete', source)

    if not rewards[mission.mission_type] then return end
    rewards[mission.mission_type].giveReward(source)
end

local function startRun(src, item_name)
    if not runs.missionTypes[item_name] then return end -- invalid item name

    discord.send(src, 'Mission Started')

    local location = locations[math.random(1, #locations)]
    local vehicle_config = location.vehicle
    local mission_veh = CreateVehicleServerSetter(vehicle_config.model, vehicle_config.type, vehicle_config.coords.x,
        vehicle_config.coords.y, vehicle_config.coords.z, vehicle_config.coords.w)


    local mission_data = {
        mission_id = math.random(100000, 999999),
        vehicle = mission_veh,
        vehicle_net_id = NetworkGetNetworkIdFromEntity(mission_veh),
        mission_owner = src,
        peds = {},
        time_started = os.time(),
        mission_type = runs.missionTypes[item_name],
        plate = utils.generatePlate(),
        starting_coords = vehicle_config.coords,
        drop_off = location.drop_off.coords
    }

    local pedAttackData = {
        attack = src,
        health = 100,
    }

    for i = 1, #location.peds do
        local ped_config = location.peds[i]
        local createdPed = CreatePed(0, ped_config.model, ped_config.coords.x, ped_config.coords.y, ped_config.coords.z,
            ped_config.coords.w, true, true)

        while not DoesEntityExist(createdPed) do Wait(0) end

        local weapon = ped_config.weapons[math.random(1, #ped_config.weapons)]
        SetPedArmour(createdPed, 100)
        GiveWeaponToPed(createdPed, weapon, 9999999, false, true)
        Entity(createdPed).state:set('drugRunPed', pedAttackData, true)

        mission_data.peds[#mission_data.peds + 1] = {
            ped = createdPed,
            ped_net_id = NetworkGetNetworkIdFromEntity(createdPed),
            ped_attack_data = pedAttackData
        }
    end

    TriggerClientEvent('qwade_drugruns:client:setWaypoint', src, mission_data.starting_coords.x,
        mission_data.starting_coords.y)

    running_missions[#running_missions + 1] = mission_data
    Entity(mission_veh).state:set('mission', mission_data, true)
end

--#endregion

--#region Events

RegisterNetEvent('qwade_drugruns:server:startMission', function(item_name)
    local src = source
    startRun(src, item_name)
end)

--#endregion

--#region callbacks

lib.callback.register('qwade_drugruns:dropOff', function(source, missionId, plate)
    local mission = getMissionFromMissionId(missionId)
    if not mission then return false end

    if not mission.plate == plate then return false end

    discord.send(source, 'Mission Dropped Off')

    CreateThread(function()
        local ped = GetPlayerPed(source)
        while #(vector3(mission.drop_off.x, mission.drop_off.y, mission.drop_off.z) - GetEntityCoords(ped)) < 30.0 do
            Wait(1000)
        end

        endRunningMission(mission, source)
    end)

    return true
end)

--#endregion



AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, mission in ipairs(running_missions) do
            if DoesEntityExist(mission.vehicle) then
                DeleteEntity(mission.vehicle)
            end

            for _, ped in ipairs(mission.peds) do
                if DoesEntityExist(ped.ped) then
                    DeleteEntity(ped.ped)
                end
            end
        end
    end
end)
