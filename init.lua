-- SYNC / init
-- Entry module. Boot sequence -> login -> device selector -> desktop.

local Boot           = SYNC.import("os/Boot")
local Login          = SYNC.import("os/Login")
local DeviceSelector = SYNC.import("os/DeviceSelector")
local Desktop        = SYNC.import("os/Desktop")

Boot.run(function()
    Login.run(function()
        DeviceSelector.run(function(device)
            if device == "desktop" then
                Desktop.start()
            end
            -- mobile / tablet layouts come later; desktop is the current focus.
        end)
    end)
end)
