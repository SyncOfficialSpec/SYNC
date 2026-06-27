-- SYNC / init
-- TEMPORARY A/B test harness: boot, then show a small switcher so you can flip
-- between device-picker style A (iOS light) and B (macOS frosted dark) live.
-- Once a style is chosen we'll replace this with the real desktop handoff.

local Boot           = SYNC.import("os/Boot")
local DeviceSelector = SYNC.import("os/DeviceSelector")
local Util           = SYNC.import("core/Util")

local function showSwitcher()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_StyleSwitcher"
    Util.mount(gui)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromOffset(220, 48)
    bar.Position = UDim2.new(0.5, 0, 0, 16)
    bar.AnchorPoint = Vector2.new(0.5, 0)
    bar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    bar.BackgroundTransparency = 0.1
    bar.BorderSizePixel = 0
    bar.Parent = gui
    Util.corner(bar, 14)
    Util.stroke(bar, Color3.fromRGB(255, 255, 255), 1, 0.85)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromOffset(70, 48)
    label.Position = UDim2.fromOffset(8, 0)
    label.BackgroundTransparency = 1
    label.Text = "Style:"
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(230, 230, 235)
    label.Parent = bar

    local current
    local function open(style)
        if current and current.Parent then current:Destroy() end
        current = DeviceSelector.run(function() end, style)
    end

    local function makeBtn(text, x)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(58, 34)
        b.Position = UDim2.fromOffset(x, 7)
        b.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
        b.Text = text
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 15
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.AutoButtonColor = true
        b.Parent = bar
        Util.corner(b, 10)
        return b
    end

    makeBtn("A", 78).MouseButton1Click:Connect(function() open("A") end)
    makeBtn("B", 142).MouseButton1Click:Connect(function() open("B") end)

    open("A") -- start on A
end

Boot.run(showSwitcher)
