-- SYNC / os / Settings
-- macOS Tahoe "Liquid Glass" style settings panel, opened from the dock's
-- Settings icon. Translucent panel, bright rim-light edge, grouped rounded rows.
-- No open/close animation (appears and closes instantly). Clicking inside does
-- NOT close it; only the close button or clicking outside does.
--
-- Settings.open({ alwaysShow = bool, onAlwaysShow = function(v) })

local Theme  = SYNC.import("core/Theme")
local Util   = SYNC.import("core/Util")
local Icons  = SYNC.import("core/Icons")
local Switch = SYNC.import("ui/Switch")

local Settings = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local SUB   = Color3.fromRGB(152, 152, 162)

Settings._gui = nil

function Settings.open(opts)
    opts = opts or {}
    if Settings._gui then return end

    local cardW, cardH = 404, 188

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Settings"
    Util.mount(gui)
    Settings._gui = gui

    local function close()
        if not Settings._gui then return end
        Settings._gui = nil
        gui:Destroy()
    end

    -- Outside-click catcher (no dimming). A Frame won't absorb clicks, so use a
    -- transparent button. Clicking it (i.e. outside the card) closes.
    local catcher = Instance.new("TextButton")
    catcher.Text = ""
    catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)

    -- Card is a TextButton so clicks inside are absorbed (don't reach the catcher).
    local card = Instance.new("TextButton")
    card.Text = ""
    card.AutoButtonColor = false
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    card.BackgroundTransparency = 0.12 -- liquid glass: quite translucent
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = gui
    Util.corner(card, 26)
    Util.rimStroke(card, 1.5, 0.3, 0.9)
    Util.shadow(card, { blur = 50, spread = -2, transparency = 0.45, offset = UDim2.fromOffset(0, 18) })

    -- Header
    local title = Instance.new("TextLabel")
    title.Text = "Settings"
    title.Size = UDim2.fromOffset(cardW - 80, 30)
    title.Position = UDim2.fromOffset(26, 22)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.TextSize = 24
    title.TextColor3 = WHITE
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = card

    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 42, 24)
    closeBtn.BackgroundColor3 = WHITE
    closeBtn.BackgroundTransparency = 0.84
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 3
    closeBtn.Parent = card
    Util.corner(closeBtn, 14)
    local cicon = Instance.new("ImageLabel")
    cicon.Size = UDim2.fromOffset(13, 13)
    cicon.AnchorPoint = Vector2.new(0.5, 0.5)
    cicon.Position = UDim2.fromScale(0.5, 0.5)
    cicon.BackgroundTransparency = 1
    cicon.ZIndex = 4
    cicon.Parent = closeBtn
    Icons.apply(cicon, "x", Color3.fromRGB(220, 220, 228))
    closeBtn.MouseEnter:Connect(function() Util.tween(closeBtn, { BackgroundTransparency = 0.74 }, 0.12) end)
    closeBtn.MouseLeave:Connect(function() Util.tween(closeBtn, { BackgroundTransparency = 0.84 }, 0.15) end)
    closeBtn.MouseButton1Click:Connect(close)

    -- Section header
    local section = Instance.new("TextLabel")
    section.Text = "DOCK"
    section.Size = UDim2.fromOffset(cardW - 52, 14)
    section.Position = UDim2.fromOffset(28, 66)
    section.BackgroundTransparency = 1
    section.Font = Theme.fonts.body
    section.TextSize = 11
    section.TextColor3 = SUB
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.ZIndex = 3
    section.Parent = card

    -- Grouped row card (lighter translucent surface, like iOS/macOS grouped lists)
    local group = Instance.new("Frame")
    group.Size = UDim2.fromOffset(cardW - 48, 64)
    group.Position = UDim2.fromOffset(24, 86)
    group.BackgroundColor3 = WHITE
    group.BackgroundTransparency = 0.92
    group.BorderSizePixel = 0
    group.ZIndex = 3
    group.Parent = card
    Util.corner(group, 14)
    Util.rimStroke(group, 1, 0.7, 0.95)

    -- Icon tile (colored, like a settings row glyph)
    local tile = Instance.new("Frame")
    tile.Size = UDim2.fromOffset(30, 30)
    tile.Position = UDim2.fromOffset(14, 17)
    tile.BackgroundColor3 = Color3.fromRGB(40, 130, 240)
    tile.BorderSizePixel = 0
    tile.ZIndex = 4
    tile.Parent = group
    Util.corner(tile, 8)
    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new(Color3.fromRGB(70, 160, 255), Color3.fromRGB(20, 110, 230))
    tg.Rotation = 90
    tg.Parent = tile
    local tglyph = Instance.new("ImageLabel")
    tglyph.Size = UDim2.fromOffset(18, 18)
    tglyph.AnchorPoint = Vector2.new(0.5, 0.5)
    tglyph.Position = UDim2.fromScale(0.5, 0.5)
    tglyph.BackgroundTransparency = 1
    tglyph.ZIndex = 5
    tglyph.Parent = tile
    Icons.apply(tglyph, "monitor", WHITE)

    local rowTitle = Instance.new("TextLabel")
    rowTitle.Text = "Always show Dock"
    rowTitle.Size = UDim2.fromOffset(240, 20)
    rowTitle.Position = UDim2.fromOffset(56, 13)
    rowTitle.BackgroundTransparency = 1
    rowTitle.Font = Theme.fonts.body
    rowTitle.TextSize = 15
    rowTitle.TextColor3 = WHITE
    rowTitle.TextXAlignment = Enum.TextXAlignment.Left
    rowTitle.ZIndex = 4
    rowTitle.Parent = group

    local rowDesc = Instance.new("TextLabel")
    rowDesc.Text = "Hidden until you touch the bottom edge"
    rowDesc.Size = UDim2.fromOffset(300, 16)
    rowDesc.Position = UDim2.fromOffset(56, 33)
    rowDesc.BackgroundTransparency = 1
    rowDesc.Font = Theme.fonts.caption
    rowDesc.TextSize = 12
    rowDesc.TextColor3 = SUB
    rowDesc.TextXAlignment = Enum.TextXAlignment.Left
    rowDesc.ZIndex = 4
    rowDesc.Parent = group

    local switchHolder = Instance.new("Frame")
    switchHolder.Size = UDim2.fromOffset(50, 30)
    switchHolder.AnchorPoint = Vector2.new(1, 0.5)
    switchHolder.Position = UDim2.new(1, -14, 0.5, 0)
    switchHolder.BackgroundTransparency = 1
    switchHolder.ZIndex = 4
    switchHolder.Parent = group
    Switch.create(switchHolder, opts.alwaysShow, function(v)
        if opts.onAlwaysShow then opts.onAlwaysShow(v) end
    end)

    return { close = close }
end

return Settings
