local discord = {}

local webhook = 'changeme'
local avatar = 'changeme'
local username = 'qwade_dev logs'

function discord.send(source, message)
    if webhook == 'changeme' then return end
    local steamid = GetPlayerIdentifiers(source)[1]
    local color = 16711680

    local embeds = {
        {
            ["title"] = "Qwade Drug Runs",
            ["description"] = message .. '\n\n' .. 'SteamID: ' .. steamid,
            ["type"] = "rich",
            ["color"] = color,
            ["footer"] = {
                ["text"] = "Qwade Drug Runs | " .. os.date("%c"),
                ["icon_url"] = avatar,
            },
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST',
        json.encode({ username = username, embeds = embeds, avatar_url = avatar }),
        { ['Content-Type'] = 'application/json' })
end

return discord
