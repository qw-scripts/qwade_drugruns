return {
    ['weed_usb'] = {
        hack = function(cb)
            local ans = math.random(1000, 9999)
            exports['SN-Hacking']:ShowNumber(ans, 3000)
            Wait(500)
            local success = exports['SN-Hacking']:KeyPad(ans, 5000)
            if success then
                cb(true)
            else
                cb(false)
            end
        end
    }
}
