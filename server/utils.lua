local utils = {}

function utils.generatePlate()
    local plate = ''
    for i = 1, 8 do
        plate = plate .. string.char(math.random(65, 90))
    end
    return plate
end

return utils