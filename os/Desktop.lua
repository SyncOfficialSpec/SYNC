-- SYNC / os / Desktop
-- The desktop you land on after choosing "Desktop": a wallpaper plus the dock.
-- Menu bar and windows come next. Desktop.start() -> { destroy }.

local Util = SYNC.import("core/Util")
local Dock = SYNC.import("os/Dock")

local Desktop = {}

function Desktop.start()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Desktop"
    Util.mount(gui)

    -- Wallpaper: a soft blue/purple gradient (macOS-ish), fades in.
    local wall = Instance.new("Frame")
    wall.Size = UDim2.fromScale(1, 1)
    wall.BackgroundColor3 = Color3.fromRGB(40, 46, 78)
    wall.BorderSizePixel = 0
    wall.BackgroundTransparency = 1
    wall.ZIndex = 0
    wall.Parent = gui
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 74, 120)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(46, 50, 92)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 48, 96)),
    })
    grad.Rotation = 120
    grad.Parent = wall
    Util.tween(wall, { BackgroundTransparency = 0 }, 0.5)

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
