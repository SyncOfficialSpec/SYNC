-- SYNC / os / Settings
-- An actual macOS-style window: title bar with traffic-light buttons, a grouped
-- settings list below. No open/close animation. Clicking inside doesn't close it;
-- the red traffic light, or clicking outside, does.
--
-- Settings.open({ alwaysShow = bool, onAlwaysShow = function(v) })

local Theme  = SYNC.import("core/Theme")
local Util   = SYNC.import("core/Util")
local Icons  = SYNC.import("core/Icons")
local Switch = SYNC.import("ui/Switch")
local Slider = SYNC.import("ui/Slider")
local Select = SYNC.import("ui/Select")

local Settings = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local SUB   = Color3.fromRGB(150, 150, 158)
local WIN   = Color3.fromRGB(32, 32, 35)
local BAR   = Color3.fromRGB(44, 44, 48)
local GROUP = Color3.fromRGB(46, 46, 50)
local HAIR  = Color3.fromRGB(0, 0, 0)

Settings._gui = nil

function Settings.open(opts)
    opts = opts or {}
    if Settings._gui then return end

    local cardW, cardH = 440, 396
    local TB = 40 -- title bar height
    local VERSION = "SYNC 1.0"

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Settings"
    Util.mount(gui)
    Settings._gui = gui

    local winRef, scaleRef -- assigned once the window exists
    local closing = false
    local function close()
        if not Settings._gui or closing then return end
        closing = true
        Settings._gui = nil
        if winRef and scaleRef then
            Util.tween(scaleRef, { Scale = 0.94 }, 0.15)
            Util.tween(winRef, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.17, function() gui:Destroy() end)
        else
            gui:Destroy()
        end
    end

    -- Outside-click catcher
    local catcher = Instance.new("TextButton")
    catcher.Text = ""
    catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)
    Util.closeOnEscape(gui, close)

    -- Window (TextButton so clicks inside are absorbed)
    local win = Instance.new("TextButton")
    win.Text = ""
    win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5) -- persistPosition (below) overrides
    win.Size = UDim2.fromOffset(cardW, cardH)
    win.BackgroundColor3 = WIN
    win.BackgroundTransparency = 0.04
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 12)
    Util.stroke(win, WHITE, 1, 0.85)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })

    -- Entrance: scale + fade in (matches Home / Scripts)
    local scaleFx = Instance.new("UIScale")
    scaleFx.Scale = 0.94
    scaleFx.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleFx, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0.04 }, 0.18)
    winRef, scaleRef = win, scaleFx

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = BAR
    bar.BackgroundTransparency = 0.12
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    -- Round only the top corners so the bar follows the window's rounded corners
    local barCorner = Instance.new("UICorner")
    local okCorner = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 12)
        barCorner.TopRightRadius = UDim.new(0, 12)
        barCorner.BottomLeftRadius = UDim.new(0, 0)
        barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okCorner then barCorner.CornerRadius = UDim.new(0, 12) end
    barCorner.Parent = bar
    local hair = Instance.new("Frame")
    hair.Size = UDim2.new(1, 0, 0, 1)
    hair.Position = UDim2.new(0, 0, 1, 0)
    hair.AnchorPoint = Vector2.new(0, 1)
    hair.BackgroundColor3 = HAIR
    hair.BackgroundTransparency = 0.7
    hair.BorderSizePixel = 0
    hair.ZIndex = 3
    hair.Parent = bar

    local lights = { Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }
    for i, col in ipairs(lights) do
        -- red closes, green re-centers a window dragged off-screen
        local clickable = (i == 1 or i == 3)
        local dot = Instance.new(clickable and "TextButton" or "Frame")
        if clickable then dot.Text = ""; dot.AutoButtonColor = false end
        dot.Size = UDim2.fromOffset(12, 12)
        dot.Position = UDim2.fromOffset(14 + (i - 1) * 20, (TB - 12) / 2)
        dot.BackgroundColor3 = col
        dot.BorderSizePixel = 0
        dot.ZIndex = 4
        dot.Parent = bar
        Util.corner(dot, 6)
        if i == 1 then dot.MouseButton1Click:Connect(close) end
        if i == 3 then
            dot.MouseButton1Click:Connect(function()
                Util.tween(win, { Position = UDim2.fromScale(0.5, 0.5) }, 0.3, Enum.EasingStyle.Quint)
            end)
        end
    end

    Util.draggable(win, bar)
    Util.persistPosition(win, "SettingsWin")

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Settings"
    title.Font = Theme.fonts.title
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(210, 210, 216)
    title.ZIndex = 3
    title.Parent = bar

    -- Section header
    local section = Instance.new("TextLabel")
    section.Text = "DOCK"
    section.Size = UDim2.fromOffset(cardW - 40, 14)
    section.Position = UDim2.fromOffset(20, TB + 14)
    section.BackgroundTransparency = 1
    section.Font = Theme.fonts.body
    section.TextSize = 11
    section.TextColor3 = SUB
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.ZIndex = 3
    section.Parent = win

    -- Grouped list (rows with hairline separators)
    local rowH = 46
    local group = Instance.new("Frame")
    group.Size = UDim2.fromOffset(cardW - 32, rowH * 4)
    group.Position = UDim2.fromOffset(16, TB + 34)
    group.BackgroundColor3 = GROUP
    group.BorderSizePixel = 0
    group.ZIndex = 3
    group.Parent = win
    Util.corner(group, 10)
    Util.stroke(group, WHITE, 1, 0.9)

    local function divider(y)
        local d = Instance.new("Frame")
        d.Size = UDim2.new(1, -16, 0, 1)
        d.Position = UDim2.fromOffset(16, y)
        d.BackgroundColor3 = HAIR
        d.BackgroundTransparency = 0.78
        d.BorderSizePixel = 0
        d.ZIndex = 4
        d.Parent = group
    end

    local function row(y, titleText)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, 0, 0, rowH)
        r.Position = UDim2.fromOffset(0, y)
        r.BackgroundTransparency = 1
        r.ZIndex = 3
        r.Parent = group
        local t = Instance.new("TextLabel")
        t.Text = titleText
        t.Size = UDim2.fromOffset(180, 20)
        t.Position = UDim2.fromOffset(16, (rowH - 20) / 2)
        t.BackgroundTransparency = 1
        t.Font = Theme.fonts.body
        t.TextSize = 15
        t.TextColor3 = WHITE
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 4
        t.Parent = r
        return r
    end

    -- Row 1: Dock position on screen (pop-up select)
    local r1 = row(0, "Dock position on screen")
    local posHolder = Instance.new("Frame")
    posHolder.Size = UDim2.fromOffset(140, 26)
    posHolder.AnchorPoint = Vector2.new(1, 0.5)
    posHolder.Position = UDim2.new(1, -12, 0.5, 0)
    posHolder.BackgroundTransparency = 1
    posHolder.ZIndex = 4
    posHolder.Parent = r1
    local posLabels = { left = "Left", bottom = "Bottom", right = "Right" }
    local cur = posLabels[opts.position or "bottom"] or "Bottom"
    Select.create(posHolder, { "Left", "Bottom", "Right" }, cur, function(choice)
        if opts.onPosition then opts.onPosition(string.lower(choice)) end
    end)

    divider(rowH)

    -- Row 2: Always show Dock (toggle)
    local r2 = row(rowH, "Always show Dock")
    local switchHolder = Instance.new("Frame")
    switchHolder.Size = UDim2.fromOffset(54, 26)
    switchHolder.AnchorPoint = Vector2.new(1, 0.5)
    switchHolder.Position = UDim2.new(1, -14, 0.5, 0)
    switchHolder.BackgroundTransparency = 1
    switchHolder.ZIndex = 4
    switchHolder.Parent = r2
    Switch.create(switchHolder, opts.alwaysShow, function(v)
        if opts.onAlwaysShow then opts.onAlwaysShow(v) end
    end)

    divider(rowH * 2)

    -- Row 3: Magnification (slider)
    local r3 = row(rowH * 2, "Magnification")
    local magHolder = Instance.new("Frame")
    magHolder.Size = UDim2.fromOffset(170, rowH)
    magHolder.AnchorPoint = Vector2.new(1, 0.5)
    magHolder.Position = UDim2.new(1, -16, 0.5, 0)
    magHolder.BackgroundTransparency = 1
    magHolder.ZIndex = 4
    magHolder.Parent = r3
    Slider.create(magHolder, opts.mag or 0.55, function(f)
        if opts.onMag then opts.onMag(f) end
    end)

    divider(rowH * 3)

    -- Row 4: Dock Size (slider)
    local r4 = row(rowH * 3, "Dock Size")
    local sizeHolder = Instance.new("Frame")
    sizeHolder.Size = UDim2.fromOffset(170, rowH)
    sizeHolder.AnchorPoint = Vector2.new(1, 0.5)
    sizeHolder.Position = UDim2.new(1, -16, 0.5, 0)
    sizeHolder.BackgroundTransparency = 1
    sizeHolder.ZIndex = 4
    sizeHolder.Parent = r4
    Slider.create(sizeHolder, opts.dockSize or 0.4, function(f)
        if opts.onDockSize then opts.onDockSize(f) end
    end)

    -- EXPERIMENTAL section: a shelf for in-progress ideas
    local expSectionY = TB + 34 + rowH * 4 + 16
    local expSection = Instance.new("TextLabel")
    expSection.Text = "EXPERIMENTAL"
    expSection.Size = UDim2.fromOffset(cardW - 40, 14)
    expSection.Position = UDim2.fromOffset(20, expSectionY)
    expSection.BackgroundTransparency = 1
    expSection.Font = Theme.fonts.body
    expSection.TextSize = 11
    expSection.TextColor3 = SUB
    expSection.TextXAlignment = Enum.TextXAlignment.Left
    expSection.ZIndex = 3
    expSection.Parent = win

    local expGroupY = expSectionY + 20
    local expGroup = Instance.new("Frame")
    expGroup.Size = UDim2.fromOffset(cardW - 32, rowH)
    expGroup.Position = UDim2.fromOffset(16, expGroupY)
    expGroup.BackgroundColor3 = GROUP
    expGroup.BorderSizePixel = 0
    expGroup.ZIndex = 3
    expGroup.Parent = win
    Util.corner(expGroup, 10)
    Util.stroke(expGroup, WHITE, 1, 0.9)

    -- Desktop mode toggle. Placeholder for now: flipping it just remembers the
    -- choice, nothing is wired to it yet.
    local dmLabel = Instance.new("TextLabel")
    dmLabel.Text = "Desktop mode"
    dmLabel.Size = UDim2.fromOffset(200, 20)
    dmLabel.Position = UDim2.fromOffset(16, (rowH - 20) / 2)
    dmLabel.BackgroundTransparency = 1
    dmLabel.Font = Theme.fonts.body
    dmLabel.TextSize = 15
    dmLabel.TextColor3 = WHITE
    dmLabel.TextXAlignment = Enum.TextXAlignment.Left
    dmLabel.ZIndex = 4
    dmLabel.Parent = expGroup

    local dmHolder = Instance.new("Frame")
    dmHolder.Size = UDim2.fromOffset(54, 26)
    dmHolder.AnchorPoint = Vector2.new(1, 0.5)
    dmHolder.Position = UDim2.new(1, -14, 0.5, 0)
    dmHolder.BackgroundTransparency = 1
    dmHolder.ZIndex = 4
    dmHolder.Parent = expGroup
    Switch.create(dmHolder, opts.desktopMode, function(v)
        if opts.onDesktopMode then opts.onDesktopMode(v) end
    end)

    -- About footer: version left, tagline right
    local aboutY = expGroupY + rowH + 16
    local hairline = Instance.new("Frame")
    hairline.Size = UDim2.new(1, -32, 0, 1)
    hairline.Position = UDim2.fromOffset(16, aboutY)
    hairline.BackgroundColor3 = HAIR
    hairline.BackgroundTransparency = 0.85
    hairline.BorderSizePixel = 0
    hairline.ZIndex = 3
    hairline.Parent = win

    local verLabel = Instance.new("TextLabel")
    verLabel.Text = VERSION
    verLabel.Font = Theme.fonts.title
    verLabel.TextSize = 13
    verLabel.TextColor3 = WHITE
    verLabel.TextXAlignment = Enum.TextXAlignment.Left
    verLabel.BackgroundTransparency = 1
    verLabel.Position = UDim2.fromOffset(20, aboutY + 10)
    verLabel.Size = UDim2.fromOffset(200, 16)
    verLabel.ZIndex = 3
    verLabel.Parent = win

    -- Reset window positions button: recenters Home/Scripts/Settings next open
    local resetBtn = Instance.new("TextButton")
    resetBtn.Text = "Reset window positions"
    resetBtn.Font = Theme.fonts.body
    resetBtn.TextSize = 12
    resetBtn.TextColor3 = SUB
    resetBtn.AutoButtonColor = false
    resetBtn.BackgroundColor3 = GROUP
    resetBtn.BackgroundTransparency = 0.2
    resetBtn.AnchorPoint = Vector2.new(1, 0.5)
    resetBtn.Position = UDim2.new(1, -20, 0, aboutY + 17)
    resetBtn.Size = UDim2.fromOffset(180, 26)
    resetBtn.ZIndex = 3
    resetBtn.Parent = win
    Util.corner(resetBtn, 8)
    Util.stroke(resetBtn, WHITE, 1, 0.9)
    resetBtn.MouseEnter:Connect(function()
        Util.tween(resetBtn, { BackgroundTransparency = 0 }, 0.12)
        resetBtn.TextColor3 = WHITE
    end)
    resetBtn.MouseLeave:Connect(function()
        Util.tween(resetBtn, { BackgroundTransparency = 0.2 }, 0.12)
        resetBtn.TextColor3 = SUB
    end)
    resetBtn.MouseButton1Click:Connect(function()
        for _, k in ipairs({ "HomeWinOX", "HomeWinOY", "ScriptsWinOX", "ScriptsWinOY", "SettingsWinOX", "SettingsWinOY" }) do
            Util.save(k, "")
        end
        resetBtn.Text = "Positions reset"
        task.delay(1.2, function() if resetBtn.Parent then resetBtn.Text = "Reset window positions" end end)
    end)

    return { close = close }
end

return Settings
