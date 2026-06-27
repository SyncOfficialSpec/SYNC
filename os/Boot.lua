-- SYNC / os / Boot
-- macOS-style boot screen: black backdrop, Apple logo, thin progress bar.
-- Boot.run(onDone) plays the sequence then fades out and calls onDone().

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Boot = {}

-- Apple logo glyph asset (white). Swap for a custom SYNC mark later.
local APPLE_LOGO = "rbxassetid://6031075938"

function Boot.run(onDone)
    local vp = Util.viewport()

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Boot"
    Util.mount(gui)

    local screen = Instance.new("Frame")
    screen.Size = UDim2.fromScale(1, 1)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    screen.BorderSizePixel = 0
    screen.BackgroundTransparency = 1
    screen.Parent = gui
    Util.tween(screen, { BackgroundTransparency = 0 }, 0.4)

    -- Logo
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.fromOffset(78, 96)
    logo.Position = UDim2.new(0.5, 0, 0.42, 0)
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.BackgroundTransparency = 1
    logo.Image = APPLE_LOGO
    logo.ImageColor3 = Color3.fromRGB(245, 245, 247)
    logo.ImageTransparency = 1
    logo.Parent = screen

    -- Gentle scale-up entrance so the logo breathes in rather than just appearing.
    local logoScale = Instance.new("UIScale")
    logoScale.Scale = 0.86
    logoScale.Parent = logo
    Util.tween(logo, { ImageTransparency = 0 }, 0.8, Enum.EasingStyle.Sine)
    Util.tween(logoScale, { Scale = 1 }, 1.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    -- Progress track
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(180, 4)
    track.Position = UDim2.new(0.5, 0, 0.62, 0)
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.BackgroundColor3 = Color3.fromRGB(70, 70, 74)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Parent = screen
    Util.corner(track, 2)
    Util.tween(track, { BackgroundTransparency = 0.4 }, 0.5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Util.corner(fill, 2)

    -- Animate the fill with a believable boot cadence: quick start, a couple of
    -- deliberate pauses, then a confident finish. Sine easing keeps it smooth.
    task.spawn(function()
        local steps = {
            { p = 0.28, t = 0.55, hold = 0.20 },
            { p = 0.52, t = 0.70, hold = 0.28 },
            { p = 0.74, t = 0.55, hold = 0.34 },
            { p = 0.90, t = 0.60, hold = 0.18 },
            { p = 1.00, t = 0.45, hold = 0.00 },
        }
        for _, s in ipairs(steps) do
            Util.tween(fill, { Size = UDim2.fromScale(s.p, 1) }, s.t,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(s.t + s.hold)
        end
        task.wait(0.35)

        -- Fade everything out
        Util.tween(logo, { ImageTransparency = 1 }, 0.4)
        Util.tween(track, { BackgroundTransparency = 1 }, 0.4)
        Util.tween(fill, { BackgroundTransparency = 1 }, 0.4)
        Util.tween(screen, { BackgroundTransparency = 1 }, 0.6)
        task.wait(0.7)
        gui:Destroy()
        if onDone then onDone() end
    end)

    return gui
end

return Boot
