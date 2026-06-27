-- SYNC / os / Desktop
-- The desktop you land on after choosing "Desktop": a wallpaper plus the dock.
-- Menu bar and windows come next. Desktop.start() -> { destroy }.

local Util = SYNC.import("core/Util")
local Dock = SYNC.import("os/Dock")

local Desktop = {}

function Desktop.start()
    -- No wallpaper: the dock floats over the actual game screen.
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Desktop"
    Util.mount(gui)

    local dock = Dock.create(gui)

    return {
        gui = gui,
        destroy = function()
            if dock then dock.destroy() end
            gui:Destroy()
        end,
    }
end

return Desktop
