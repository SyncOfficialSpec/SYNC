-- ============================================================
--  SYNC  -  macOS-style desktop OS for Roblox executors
--  Generated bundle. Do not edit by hand; edit sources + rebundle.
-- ============================================================
local SYNC = {}
do
    local modules, cache = {}, {}
    function SYNC.define(name, fn) modules[name] = fn end
    function SYNC.import(name)
        local c = cache[name]
        if c ~= nil then return c end
        local fn = modules[name]
        if not fn then error("SYNC: module not found: " .. tostring(name), 2) end
        local r = fn()
        if r == nil then r = true end
        cache[name] = r
        return r
    end
end
pcall(function()
    if typeof(getgenv) == "function" then getgenv().SYNC = SYNC end
end)

SYNC.define("core/Theme", function()
-- SYNC / core / Theme
-- macOS-style palette, fonts and metrics. Light + dark variants.
-- Returns a module table; switch active palette with Theme.setMode("dark"|"light").

local Theme = {}

Theme.fonts = {
    title   = Enum.Font.GothamSemibold,
    body    = Enum.Font.GothamMedium,
    caption = Enum.Font.Gotham,
    light   = Enum.Font.Gotham,
}

-- Shared accent + system colors (consistent across modes)
Theme.accent      = Color3.fromRGB(0, 122, 255)   -- macOS blue
Theme.red         = Color3.fromRGB(255, 95, 87)    -- traffic light close
Theme.yellow      = Color3.fromRGB(254, 188, 46)   -- minimize
Theme.green       = Color3.fromRGB(40, 200, 64)    -- zoom

Theme.metrics = {
    windowRadius  = 12,
    cardRadius    = 22,
    optionRadius  = 14,
    menuBarHeight = 28,
    dockHeight    = 70,
    dockIcon      = 52,
    titleBar      = 36,
    trafficLight  = 12,
    trafficGap    = 8,
}

local light = {
    name           = "light",
    wallpaper      = Color3.fromRGB(38, 42, 60),
    backdrop       = Color3.fromRGB(0, 0, 0),
    backdropAlpha  = 0.65,
    surface        = Color3.fromRGB(255, 255, 255),
    surfaceAlt     = Color3.fromRGB(242, 242, 247),
    surfaceHover   = Color3.fromRGB(235, 235, 241),
    chrome         = Color3.fromRGB(246, 246, 248),   -- menubar / titlebar
    chromeAlpha    = 0.15,                             -- translucency over content
    stroke         = Color3.fromRGB(210, 210, 215),
    strokeAlpha    = 0.3,
    textPrimary    = Color3.fromRGB(0, 0, 0),
    textSecondary  = Color3.fromRGB(142, 142, 147),
    selected       = Color3.fromRGB(230, 242, 255),
}

local dark = {
    name           = "dark",
    wallpaper      = Color3.fromRGB(28, 30, 44),
    backdrop       = Color3.fromRGB(0, 0, 0),
    backdropAlpha  = 0.7,
    surface        = Color3.fromRGB(30, 30, 32),
    surfaceAlt     = Color3.fromRGB(44, 44, 46),
    surfaceHover   = Color3.fromRGB(58, 58, 60),
    chrome         = Color3.fromRGB(38, 38, 40),
    chromeAlpha    = 0.2,
    stroke         = Color3.fromRGB(70, 70, 74),
    strokeAlpha    = 0.4,
    textPrimary    = Color3.fromRGB(245, 245, 247),
    textSecondary  = Color3.fromRGB(152, 152, 157),
    selected       = Color3.fromRGB(20, 56, 96),
}

Theme.palettes = { light = light, dark = dark }
Theme.c = dark  -- active palette (default dark; feels most "premium")

function Theme.setMode(mode)
    Theme.c = Theme.palettes[mode] or Theme.c
    return Theme.c
end

return Theme
end)

SYNC.define("core/Util", function()
-- SYNC / core / Util
-- Cross-executor helpers: safe CoreGui parenting, persisted settings,
-- and small Instance-building shortcuts (corner, stroke, tween, padding).

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local Util = {}

-- ---------------------------------------------------------------------------
-- Player / camera (wait for them on early inject)
-- ---------------------------------------------------------------------------
function Util.localPlayer()
    local lp = Players.LocalPlayer
    if not lp then
        lp = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
    end
    return lp
end

function Util.viewport()
    local cam = workspace.CurrentCamera
    if not cam then
        cam = workspace:GetPropertyChangedSignal("CurrentCamera"):Wait() and workspace.CurrentCamera
    end
    return cam.ViewportSize
end

-- ---------------------------------------------------------------------------
-- Parent a ScreenGui where it survives respawn/teleport and hides from game.
-- Prefers executor gethui(); falls back to CoreGui, then PlayerGui.
-- ---------------------------------------------------------------------------
function Util.mount(gui)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999

    local ok = pcall(function()
        if typeof(gethui) == "function" then
            gui.Parent = gethui()
            return
        end
        error("no gethui")
    end)
    if ok and gui.Parent then return gui end

    ok = pcall(function()
        local cg = game:GetService("CoreGui")
        if syn and typeof(syn.protect_gui) == "function" then syn.protect_gui(gui) end
        gui.Parent = cg
    end)
    if ok and gui.Parent then return gui end

    -- Last resort: PlayerGui
    local lp = Util.localPlayer()
    gui.Parent = lp:WaitForChild("PlayerGui")
    return gui
end

-- ---------------------------------------------------------------------------
-- Persisted settings (writefile -> syn cookie -> _G), same strategy as the
-- existing device selector. Stored as plain strings under SyncDir/.
-- ---------------------------------------------------------------------------
local SYNC_DIR = "SYNC"

local function tryMakeDir()
    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(SYNC_DIR) then
            makefolder(SYNC_DIR)
        end
    end)
end

function Util.save(key, value)
    value = tostring(value)
    tryMakeDir()
    local ok = pcall(function()
        if typeof(writefile) == "function" then writefile(SYNC_DIR .. "/" .. key .. ".txt", value) end
    end)
    if ok then return end
    ok = pcall(function()
        if syn and typeof(syn.SetCookie) == "function" then syn.SetCookie("Sync_" .. key, value) end
    end)
    if ok then return end
    _G["__Sync_" .. key] = value
end

function Util.load(key)
    local val
    local ok = pcall(function()
        if typeof(readfile) == "function" and typeof(isfile) == "function"
            and isfile(SYNC_DIR .. "/" .. key .. ".txt") then
            val = readfile(SYNC_DIR .. "/" .. key .. ".txt")
        end
    end)
    if ok and val and val ~= "" then return val end
    ok = pcall(function()
        if syn and typeof(syn.GetCookie) == "function" then val = syn.GetCookie("Sync_" .. key) end
    end)
    if ok and val and val ~= "" then return val end
    val = _G["__Sync_" .. key]
    return (val and val ~= "") and val or nil
end

-- ---------------------------------------------------------------------------
-- Instance shortcuts
-- ---------------------------------------------------------------------------
function Util.corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

function Util.stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1, 1, 1)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Util.padding(parent, all)
    local p = Instance.new("UIPadding")
    local u = UDim.new(0, all or 0)
    p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = u, u, u, u
    p.Parent = parent
    return p
end

-- Subtle Rayfield-style drop shadow for minimal Apple-like depth. Created as a
-- SIBLING behind `target` (children always render above their parent, so a child
-- can't sit behind it). Call AFTER target.Position/Size are set. Returns the ImageLabel.
function Util.shadow(target, spread, transparency)
    spread = spread or 18
    local sh = Instance.new("ImageLabel")
    sh.Name = "Shadow"
    sh.BackgroundTransparency = 1
    sh.Image = "rbxassetid://5028857084"            -- Rayfield soft shadow
    sh.ImageColor3 = Color3.fromRGB(0, 0, 0)
    sh.ImageTransparency = transparency or 0.6
    sh.ScaleType = Enum.ScaleType.Slice
    sh.SliceCenter = Rect.new(24, 24, 276, 276)
    sh.AnchorPoint = target.AnchorPoint
    sh.Size = UDim2.new(
        target.Size.X.Scale, target.Size.X.Offset + spread * 2,
        target.Size.Y.Scale, target.Size.Y.Offset + spread * 2
    )
    sh.Position = UDim2.new(
        target.Position.X.Scale, target.Position.X.Offset - spread,
        target.Position.Y.Scale, target.Position.Y.Offset - spread + 4  -- slight downward cast
    )
    sh.ZIndex = math.max((target.ZIndex or 1) - 1, 1)
    sh.Parent = target.Parent
    return sh
end

-- Standard SYNC tween. props is a table of properties to animate.
function Util.tween(inst, props, time, style, dir)
    local info = TweenInfo.new(
        time or 0.25,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

return Util
end)

SYNC.define("os/Boot", function()
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
end)

SYNC.define("os/DeviceSelector", function()
-- SYNC / os / DeviceSelector
-- First-run Apple-style device picker (Mobile / Tablet / Desktop).
-- Two visual styles, switchable for A/B testing:
--   "A" = iOS Settings light card
--   "B" = macOS frosted dark panel (blur faked with translucency)
-- Colored icon tiles with filled white glyphs + selected checkmark, macOS-tuned springs.
-- DeviceSelector.run(onChoose, style) ; onChoose(id) on pick, onChoose(saved) on dismiss.

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local DeviceSelector = {}

local ACCENT = Color3.fromRGB(10, 132, 255)
local WHITE  = Color3.fromRGB(255, 255, 255)

-- Per-device tile gradient + glyph kind
local DEVICES = {
    { id = "mobile",  title = "Mobile",  desc = "Phone-optimized layout",
      top = Color3.fromRGB(52, 199, 89),  bot = Color3.fromRGB(40, 167, 69) },
    { id = "tablet",  title = "Tablet",  desc = "Tablet-optimized layout",
      top = Color3.fromRGB(10, 132, 255), bot = Color3.fromRGB(0, 96, 223) },
    { id = "desktop", title = "Desktop", desc = "Full desktop experience",
      top = Color3.fromRGB(94, 92, 230),  bot = Color3.fromRGB(75, 63, 214) },
}

local STYLES = {
    A = {
        cardColor = WHITE, cardTransp = 0,
        cardStroke = Color3.fromRGB(214, 214, 219), cardStrokeTransp = 0.4,
        titleColor = Color3.fromRGB(0, 0, 0), subColor = Color3.fromRGB(142, 142, 147),
        descColor = Color3.fromRGB(142, 142, 147),
        rowColor = Color3.fromRGB(245, 245, 247), rowTransp = 0,
        hoverColor = Color3.fromRGB(237, 237, 242), hoverTransp = 0,
        selColor = Color3.fromRGB(234, 243, 255), selTransp = 0,
        selStroke = ACCENT,
        closeColor = Color3.fromRGB(233, 233, 238), closeTransp = 0,
        closeHover = Color3.fromRGB(214, 214, 219), closeIcon = Color3.fromRGB(142, 142, 147),
        backdropA = 0.45, fake = false,
    },
    B = {
        cardColor = Color3.fromRGB(40, 40, 48), cardTransp = 0.16,
        cardStroke = WHITE, cardStrokeTransp = 0.86,
        titleColor = Color3.fromRGB(245, 245, 247), subColor = Color3.fromRGB(160, 160, 168),
        descColor = Color3.fromRGB(152, 152, 159),
        rowColor = WHITE, rowTransp = 0.93,
        hoverColor = WHITE, hoverTransp = 0.88,
        selColor = ACCENT, selTransp = 0.8,
        selStroke = ACCENT,
        closeColor = WHITE, closeTransp = 0.86, closeHover = WHITE, closeHoverTransp = 0.78,
        closeIcon = Color3.fromRGB(210, 210, 217),
        backdropA = 0.6, fake = true,
    },
}

-- macOS-flavored easing presets
local SPRING = { 0.5, Enum.EasingStyle.Back,  Enum.EasingDirection.Out }
local SMOOTH = { 0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out }
local QUICK  = { 0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out }

local function tw(inst, props, preset)
    return Util.tween(inst, props, preset[1], preset[2], preset[3])
end

-- ---------------------------------------------------------------------------
-- Colored icon tile with filled white glyph
-- ---------------------------------------------------------------------------
local function buildTile(parent, device)
    local tile = Instance.new("Frame")
    tile.Size = UDim2.fromOffset(50, 50)
    tile.Position = UDim2.fromOffset(14, 12)
    tile.BackgroundColor3 = device.top
    tile.BorderSizePixel = 0
    tile.ZIndex = 5
    tile.Parent = parent
    Util.corner(tile, 13)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(device.top, device.bot)
    grad.Rotation = 90
    grad.Parent = tile

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(28, 28)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.ZIndex = 6
    box.Parent = tile

    local function fill(w, h, radius, ax, ay, px, pxoff, py, pyoff, transp)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.AnchorPoint = Vector2.new(ax, ay)
        f.Position = UDim2.new(px, pxoff, py, pyoff)
        f.BackgroundColor3 = WHITE
        f.BackgroundTransparency = transp or 0
        f.BorderSizePixel = 0
        f.ZIndex = 6
        f.Parent = box
        if radius and radius > 0 then Util.corner(f, radius) end
        return f
    end

    if device.id == "mobile" then
        local body = fill(15, 25, 4, 0.5, 0.5, 0.5, 0, 0.5, 0)
        fill(7, 1.6, 0.8, 0.5, 1, 0.5, 0, 1, -3, 0.45)
        body.Parent = box
    elseif device.id == "tablet" then
        fill(26, 19, 4, 0.5, 0.5, 0.5, 0, 0.5, 0)
        fill(8, 1.6, 0.8, 0.5, 1, 0.5, 0, 0.5, 8, 0.45)
    else -- desktop
        fill(26, 16, 3, 0.5, 0, 0.5, 0, 0, 1)        -- screen
        fill(4, 4, 0, 0.5, 0, 0.5, 0, 0, 17)         -- neck
        fill(14, 2.6, 1.3, 0.5, 0, 0.5, 0, 0, 21)    -- base
    end

    return tile
end

-- ---------------------------------------------------------------------------
-- Selected checkmark: accent circle + white tick (built from two frames)
-- Returns { show(animate), hide() }
-- ---------------------------------------------------------------------------
local function buildCheck(parent)
    local c = Instance.new("Frame")
    c.Size = UDim2.fromOffset(22, 22)
    c.AnchorPoint = Vector2.new(1, 0.5)
    c.Position = UDim2.new(1, -16, 0.5, 0)
    c.BackgroundColor3 = ACCENT
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.ZIndex = 6
    c.Parent = parent
    Util.corner(c, 11)

    local scale = Instance.new("UIScale")
    scale.Scale = 0.4
    scale.Parent = c

    local long = Instance.new("Frame")
    long.Size = UDim2.fromOffset(11, 2.6)
    long.AnchorPoint = Vector2.new(0.5, 0.5)
    long.Position = UDim2.new(0.5, 1.5, 0.5, -1)
    long.Rotation = -45
    long.BackgroundColor3 = WHITE
    long.BackgroundTransparency = 1
    long.BorderSizePixel = 0
    long.ZIndex = 7
    long.Parent = c
    Util.corner(long, 1.3)

    local short = Instance.new("Frame")
    short.Size = UDim2.fromOffset(6, 2.6)
    short.AnchorPoint = Vector2.new(0.5, 0.5)
    short.Position = UDim2.new(0.5, -4, 0.5, 2)
    short.Rotation = 45
    short.BackgroundColor3 = WHITE
    short.BackgroundTransparency = 1
    short.BorderSizePixel = 0
    short.ZIndex = 7
    short.Parent = c
    Util.corner(short, 1.3)

    return {
        show = function(animate)
            if animate then
                tw(c, { BackgroundTransparency = 0 }, QUICK)
                tw(long, { BackgroundTransparency = 0 }, QUICK)
                tw(short, { BackgroundTransparency = 0 }, QUICK)
                tw(scale, { Scale = 1 }, SPRING)
            else
                c.BackgroundTransparency = 0
                long.BackgroundTransparency = 0
                short.BackgroundTransparency = 0
                scale.Scale = 1
            end
        end,
        hide = function()
            tw(c, { BackgroundTransparency = 1 }, QUICK)
            tw(long, { BackgroundTransparency = 1 }, QUICK)
            tw(short, { BackgroundTransparency = 1 }, QUICK)
            scale.Scale = 0.4
        end,
    }
end

function DeviceSelector.run(onChoose, style)
    local S = STYLES[style] or STYLES.A
    local saved = Util.load("DevicePref")
    local vp = Util.viewport()

    local cardW = 384
    local optH, spacing, optX = 74, 12, 20
    local optW = cardW - 40
    local startY = 104
    local cardH = startY + (#DEVICES * optH) + ((#DEVICES - 1) * spacing) + 22
    local cardX, cardY = (vp.X - cardW) / 2, (vp.Y - cardH) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_DeviceSelector"
    Util.mount(gui)

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = gui
    Util.tween(backdrop, { BackgroundTransparency = 1 - S.backdropA }, 0.45)

    -- Card
    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.Position = UDim2.fromOffset(cardX, cardY)
    card.BackgroundColor3 = S.cardColor
    card.BackgroundTransparency = S.cardTransp
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = gui
    Util.corner(card, 26)
    local cardStroke = Util.stroke(card, S.cardStroke, 1, S.cardStrokeTransp)

    local shadow = Util.shadow(card, 20, 1)
    Util.tween(shadow, { ImageTransparency = 0.55 }, 0.5)

    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 0.92
    cardScale.Parent = card
    tw(cardScale, { Scale = 1 }, SPRING)

    -- Close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 40, 18)
    closeBtn.BackgroundColor3 = S.closeColor
    closeBtn.BackgroundTransparency = S.closeTransp
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Image = "rbxassetid://7072725342"
    closeBtn.ImageColor3 = S.closeIcon
    closeBtn.ZIndex = 4
    closeBtn.Parent = card
    Util.corner(closeBtn, 14)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, { BackgroundColor3 = S.closeHover, BackgroundTransparency = S.closeHoverTransp or S.closeTransp }, QUICK)
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, { BackgroundColor3 = S.closeColor, BackgroundTransparency = S.closeTransp }, SMOOTH)
    end)

    -- Title + subtitle
    local title = Instance.new("TextLabel")
    title.Text = "Choose Your Device"
    title.Size = UDim2.fromOffset(cardW - 80, 30)
    title.Position = UDim2.fromOffset(26, 30)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.TextSize = 23
    title.TextColor3 = S.titleColor
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "How are you running SYNC?"
    subtitle.Size = UDim2.fromOffset(cardW - 80, 20)
    subtitle.Position = UDim2.fromOffset(26, 64)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Theme.fonts.caption
    subtitle.TextSize = 14
    subtitle.TextColor3 = S.subColor
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 3
    subtitle.Parent = card

    local options = {}
    local selectedId = saved
    local closing = false

    local function setRow(opt, state)
        if state == "selected" then
            tw(opt.bg, { BackgroundColor3 = S.selColor, BackgroundTransparency = S.selTransp }, SMOOTH)
            tw(opt.stroke, { Transparency = 0 }, SMOOTH)
        elseif state == "hover" then
            tw(opt.bg, { BackgroundColor3 = S.hoverColor, BackgroundTransparency = S.hoverTransp }, QUICK)
            tw(opt.stroke, { Transparency = 1 }, QUICK)
        else
            tw(opt.bg, { BackgroundColor3 = S.rowColor, BackgroundTransparency = S.rowTransp }, SMOOTH)
            tw(opt.stroke, { Transparency = 1 }, SMOOTH)
        end
    end

    local function applySelection(id, animate)
        selectedId = id
        for _, opt in ipairs(options) do
            if opt.id == id then
                if animate then setRow(opt, "selected") else
                    opt.bg.BackgroundColor3 = S.selColor
                    opt.bg.BackgroundTransparency = S.selTransp
                    opt.stroke.Transparency = 0
                end
                opt.check.show(animate)
            else
                if animate then setRow(opt, "normal") else
                    opt.bg.BackgroundColor3 = S.rowColor
                    opt.bg.BackgroundTransparency = S.rowTransp
                    opt.stroke.Transparency = 1
                end
                opt.check.hide()
            end
        end
    end

    local function closeMenu(chosen)
        if closing then return end
        closing = true
        for i, opt in ipairs(options) do
            task.delay(0.035 * (i - 1), function()
                tw(opt.bg, { BackgroundTransparency = 1 }, QUICK)
                tw(opt.label, { TextTransparency = 1 }, QUICK)
                tw(opt.desc, { TextTransparency = 1 }, QUICK)
                tw(opt.stroke, { Transparency = 1 }, QUICK)
                tw(opt.tile, { BackgroundTransparency = 1 }, QUICK)
            end)
        end
        task.delay(0.18, function()
            tw(title, { TextTransparency = 1 }, QUICK)
            tw(subtitle, { TextTransparency = 1 }, QUICK)
            tw(closeBtn, { BackgroundTransparency = 1, ImageTransparency = 1 }, QUICK)
        end)
        task.delay(0.32, function()
            Util.tween(cardScale, { Scale = 0.94 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            tw(card, { BackgroundTransparency = 1 }, SMOOTH)
            tw(cardStroke, { Transparency = 1 }, SMOOTH)
            tw(shadow, { ImageTransparency = 1 }, SMOOTH)
        end)
        task.delay(0.5, function() Util.tween(backdrop, { BackgroundTransparency = 1 }, 0.35) end)
        task.delay(0.95, function()
            gui:Destroy()
            if onChoose then onChoose(chosen) end
        end)
    end

    for i, device in ipairs(DEVICES) do
        local yPos = startY + (i - 1) * (optH + spacing)

        local opt = Instance.new("TextButton")
        opt.Text = ""
        opt.AutoButtonColor = false
        opt.Size = UDim2.fromOffset(optW, optH)
        opt.Position = UDim2.fromOffset(optX, yPos)
        opt.BackgroundColor3 = S.rowColor
        opt.BackgroundTransparency = S.rowTransp
        opt.BorderSizePixel = 0
        opt.ZIndex = 3
        opt.Parent = card
        Util.corner(opt, 16)
        local optStroke = Util.stroke(opt, S.selStroke, 2, 1)

        local tile = buildTile(opt, device)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = device.title
        titleLabel.Size = UDim2.fromOffset(optW - 120, 20)
        titleLabel.Position = UDim2.fromOffset(78, 17)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Theme.fonts.title
        titleLabel.TextSize = 16
        titleLabel.TextColor3 = S.titleColor
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        titleLabel.ZIndex = 5
        titleLabel.Parent = opt

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = device.desc
        descLabel.Size = UDim2.fromOffset(optW - 120, 18)
        descLabel.Position = UDim2.fromOffset(78, 39)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Theme.fonts.caption
        descLabel.TextSize = 13
        descLabel.TextColor3 = S.descColor
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.ZIndex = 5
        descLabel.Parent = opt

        local check = buildCheck(opt)

        local optScale = Instance.new("UIScale")
        optScale.Parent = opt

        local data = {
            id = device.id, bg = opt, stroke = optStroke, tile = tile,
            label = titleLabel, desc = descLabel, check = check, scale = optScale,
        }
        options[#options + 1] = data

        opt.MouseEnter:Connect(function()
            if data.id ~= selectedId then setRow(data, "hover") end
            tw(optScale, { Scale = 1.02 }, QUICK)
        end)
        opt.MouseLeave:Connect(function()
            setRow(data, data.id == selectedId and "selected" or "normal")
            tw(optScale, { Scale = 1 }, SMOOTH)
        end)
        opt.MouseButton1Down:Connect(function() tw(optScale, { Scale = 0.97 }, QUICK) end)
        opt.MouseButton1Click:Connect(function()
            applySelection(data.id, true)
            tw(optScale, { Scale = 1 }, SPRING)
            task.delay(0.24, function()
                Util.save("DevicePref", data.id)
                closeMenu(data.id)
            end)
        end)
    end

    if selectedId then applySelection(selectedId, false) end

    closeBtn.MouseButton1Click:Connect(function() closeMenu(selectedId) end)

    return gui
end

return DeviceSelector
end)

SYNC.define("init", function()
-- SYNC / init
-- Entry module. Boot sequence -> device selector (style B) -> (desktop, coming next).

local Boot           = SYNC.import("os/Boot")
local DeviceSelector = SYNC.import("os/DeviceSelector")

Boot.run(function()
    DeviceSelector.run(function(device)
        -- device is "mobile" | "tablet" | "desktop" | nil (dismissed)
        -- TODO: launch Desktop.start(device) here once built.
    end, "B")
end)
end)

SYNC.import("init")
