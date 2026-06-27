-- SYNC / init
-- Entry module. Boot sequence -> device selector (style B) -> (desktop, coming next).

local Boot           = SYNC.import("os/Boot")
local DeviceSelector = SYNC.import("os/DeviceSelector")

Boot.run(function()
    DeviceSelector.run(function(device)
        -- device is "mobile" | "tablet" | "desktop" | nil (dismissed)
        -- TODO: launch Desktop.start(device) here once built.
    end)
end)
