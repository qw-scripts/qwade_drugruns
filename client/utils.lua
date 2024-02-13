local utils = {}


---@async
---@param bagName string
---@return integer?, integer
function utils.getEntityAndNetIdFromBagName(bagName)
    local netId = tonumber(bagName:gsub('entity:', ''), 10)

    if not lib.waitFor(function() return NetworkDoesEntityExistWithNetworkId(netId) end, nil, 10000) then
        return print(('statebag timed out while awaiting entity creation! (%s)'):format(bagName)), 0
    end

    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity == 0 then
        return print(('statebag received invalid entity! (%s)'):format(bagName)), 0
    end

    return entity, netId
end

---@param keyFilter string
---@param cb fun(entity: number, netId: number, value: any, bagName: string)
---@return number
function utils.entityStateHandler(keyFilter, cb)
    return AddStateBagChangeHandler(keyFilter, '', function(bagName, key, value, reserved, replicated)
        local entity, netId = utils.getEntityAndNetIdFromBagName(bagName)

        if entity then
            cb(entity, netId, value, bagName)
        end
    end)
end

function utils.setFuel(vehicle)
    Entity(vehicle).state.fuel = 100
end

function utils.getVehicleKeys(plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
end

return utils
