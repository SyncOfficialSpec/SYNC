-- SYNC / os / Settings
-- Apple-style settings panel opened from the dock's Settings icon. For now it
-- holds the Dock section with an "Always show Dock" toggle (off by default = the
-- dock auto-hides and only appears when the cursor touches the bottom edge).
--
-- Settings.open({ alwaysShow = bool, onAlwaysShow = function(v) }) -- one at a time

local Theme  = SYNC.import("core/Theme")
local Util   = SYNC.import("core/Util")
local Icons  = SYNC.import("core/Icons")
local Switch = SYNC.import("ui/Switch")

local Settings = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local CARD  = Color3.fromRGB(40, 40, 48)

Settings._gui = nil

function Settings.open(opts)
    opts = opts or {}
    if Settings._gui then return end -- already open

    local vp = Util.viewport()
    local cardW, cardH = 380, 188

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Settings"
    Util.mount(gui)
    Settings._gui = gui

    -- Outside-click catcher (no dimming)
    local catcher = Instance.new("TextButton")
    catcher.Text = ""
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.AutoButtonColor = false
    catcher.ZIndex = 1
    catcher.Parent = gui

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.BackgroundColor3 = CARD
    card.BackgroundTransparency = 0.14
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = gui
    Util.corner(card, 20)
    local stroke = Util.stroke(card, WHITE, 1, 0.86)
    Util.shadow(card, { blur = 40, spread = -2, transparency = 0.5, offset = UDim2.fromOffset(0, 12) })

    local scale = Instance.new("UIScale")
    scale.Scale = 0.94
    scale.Parent = card

    -- Header
    local title = Instance.new("TextLabel")
    title.Text = "Settings"
    title.Size = UDim2.fromOffset(cardW - 70, 28)
    title.Position = UDim2.fromOffset(24, 20)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.TextSize = 22
    title.TextColor3 = WHITE
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = card

    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(26, 26)
    closeBtn.Position = UDim2.fromOffset(cardW - 38, 20)
    closeBtn.BackgroundColor3 = WHITE
    closeBtn.BackgroundTransparency = 0.86
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 3
    closeBtn.Parent = card
    Util.corner(closeBtn, 13)
    local cicon = Instance.new("ImageLabel")
    cicon.Size = UDim2.fromOffset(14, 14)
    cicon.AnchorPoint = Vector2.new(0.5, 0.5)
    cicon.Position = UDim2.fromScale(0.5, 0.5)
    cicon.BackgroundTransparency = 1
    cicon.ZIndex = 4
    cicon.Parent = closeBtn
    Icons.apply(cicon, "x", Color3.fromRGB(210, 210, 217))

    -- Section label
    local section = Instance.new("TextLabel")
    section.Text = "DOCK"
    section.Size = UDim2.fromOffset(cardW - 48, 16)
    section.Position = UDim2.fromOffset(24, 64)
    section.BackgroundTransparency = 1
    section.Font = Theme.fonts.body
    section.TextSize = 11
    section.TextColor3 = Color3.fromRGB(150, 150, 158)
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.ZIndex = 3
    section.Parent = card

    -- Row: Always show Dock
    local row = Instance.new("Frame")
    row.Size = UDim2.fromOffset(cardW - 48, 64)
    row.Position = UDim2.fromOffset(24, 86)
    row.BackgroundColor3 = WHITE
    row.BackgroundTransparency = 0.93
    row.BorderSizePixel = 0
    row.ZIndex = 3
    row.Parent = card
    Util.corner(row, 14)

    local rowTitle = Instance.new("TextLabel")
    rowTitle.Text = "Always show Dock"
    rowTitle.Size = UDim2.fromOffset(220, 20)
    rowTitle.Position = UDim2.fromOffset(16, 13)
    rowTitle.BackgroundTransparency = 1
    rowTitle.Font = Theme.fonts.body
    rowTitle.TextSize = 15
    rowTitle.TextColor3 = WHITE
    rowTitle.TextXAlignment = Enum.TextXAlignment.Left
    rowTitle.ZIndex = 4
    rowTitle.Parent = row

    local rowDesc = Instance.new("TextLabel")
    rowDesc.Text = "Off: shows only when you touch the bottom edge"
    rowDesc.Size = UDim2.fromOffset(250, 16)
    rowDesc.Position = UDim2.fromOffset(16, 34)
    rowDesc.BackgroundTransparency = 1
    rowDesc.Font = Theme.fonts.caption
    rowDesc.TextSize = 12
    rowDesc.TextColor3 = Color3.fromRGB(150, 150, 158)
    rowDesc.TextXAlignment = Enum.TextXAlignment.Left
    rowDesc.ZIndex = 4
    rowDesc.Parent = row

    local switchHolder = Instance.new("Frame")
    switchHolder.Size = UDim2.fromOffset(46, 28)
    switchHolder.AnchorPoint = Vector2.new(1, 0.5)
    switchHolder.Position = UDim2.new(1, -16, 0.5, 0)
    switchHolder.BackgroundTransparency = 1
    switchHolder.ZIndex = 4
    switchHolder.Parent = row
    Switch.create(switchHolder, opts.alwaysShow, function(v)
        if opts.onAlwaysShow then opts.onAlwaysShow(v) end
    end)

    -- entrance / close
    Util.tween(scale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local closing = false
    local function close()
        if closing then return end
        closing = true
        Util.tween(scale, { Scale = 0.96 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Util.tween(card, { BackgroundTransparency = 1 }, 0.16)
        Util.tween(stroke, { Transparency = 1 }, 0.16)
        task.delay(0.18, function()
            gui:Destroy()
            Settings._gui = nil
        end)
    end

    catcher.MouseButton1Click:Connect(close)
    closeBtn.MouseButton1Click:Connect(close)

    return { close = close }
end

return Settings
