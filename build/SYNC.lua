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

-- Soft drop shadow for macOS-style modal depth. Created as a SIBLING behind
-- `target` (children always render above their parent, so a child can't sit
-- behind it). Call AFTER target.Position/Size are set. Returns the ImageLabel.
function Util.shadow(target, spread, transparency)
    spread = spread or 40
    local sh = Instance.new("ImageLabel")
    sh.Name = "Shadow"
    sh.BackgroundTransparency = 1
    sh.Image = "rbxassetid://6015897843"            -- soft 9-slice glow
    sh.ImageColor3 = Color3.fromRGB(0, 0, 0)
    sh.ImageTransparency = transparency or 0.5
    sh.ScaleType = Enum.ScaleType.Slice
    sh.SliceCenter = Rect.new(49, 49, 450, 450)
    sh.AnchorPoint = target.AnchorPoint
    sh.Size = UDim2.new(
        target.Size.X.Scale, target.Size.X.Offset + spread * 2,
        target.Size.Y.Scale, target.Size.Y.Offset + spread * 2
    )
    sh.Position = UDim2.new(
        target.Position.X.Scale, target.Position.X.Offset - spread,
        target.Position.Y.Scale, target.Position.Y.Offset - spread + 8  -- cast downward
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
-- Vector device glyphs (built from frames, no emoji), soft modal shadow,
-- macOS-tuned spring animations. DeviceSelector.run(onChoose) shows the card and
-- calls onChoose(id) when picked, or onChoose(saved) if dismissed. Persisted via Util.

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local DeviceSelector = {}

local UI = {
    card        = Color3.fromRGB(255, 255, 255),
    cardRadius  = 24,
    optionBg    = Color3.fromRGB(244, 244, 248),
    optionHover = Color3.fromRGB(237, 237, 242),
    optionRad   = 16,
    accent      = Theme.accent,
    textPrimary = Color3.fromRGB(0, 0, 0),
    textSub     = Color3.fromRGB(142, 142, 147),
    closeBg     = Color3.fromRGB(233, 233, 238),
    closeHov    = Color3.fromRGB(214, 214, 219),
    hairline    = Color3.fromRGB(214, 214, 219),
    selectedBg  = Color3.fromRGB(233, 243, 255),
    wellBg      = Color3.fromRGB(255, 255, 255),
    backdropA   = 0.55,
}

-- macOS-flavored easing presets
local SPRING = { 0.5, Enum.EasingStyle.Back,    Enum.EasingDirection.Out }
local SMOOTH = { 0.28, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out }
local QUICK  = { 0.18, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out }

local function tw(inst, props, preset)
    return Util.tween(inst, props, preset[1], preset[2], preset[3])
end

-- ---------------------------------------------------------------------------
-- Vector device glyphs. Each returns { setColor = function(Color3) }.
-- Built from frames + strokes so they stay crisp and recolor on selection.
-- ---------------------------------------------------------------------------
local function buildIcon(parent, kind, color)
    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(44, 44)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.Parent = parent

    local parts = {} -- { inst, prop }
    local function reg(inst, prop) parts[#parts + 1] = { inst = inst, prop = prop } end

    local function outline(w, h, radius, anchor, posScaleY, posOffY, thick)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.AnchorPoint = anchor
        f.Position = UDim2.new(0.5, 0, posScaleY, posOffY)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Parent = box
        Util.corner(f, radius)
        local s = Util.stroke(f, color, thick or 2.4, 0)
        reg(s, "Color")
        return f
    end

    local function bar(w, h, radius, anchorY, parentFrame, offY)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.AnchorPoint = Vector2.new(0.5, anchorY)
        f.Position = UDim2.new(0.5, 0, anchorY, offY)
        f.BackgroundColor3 = color
        f.BorderSizePixel = 0
        f.Parent = parentFrame
        Util.corner(f, radius)
        reg(f, "BackgroundColor3")
        return f
    end

    if kind == "mobile" then
        local body = outline(24, 40, 7, Vector2.new(0.5, 0.5), 0.5, 0, 2.4)
        bar(8, 2, 1, 0, body, 5)        -- earpiece
        bar(10, 2.5, 1.25, 1, body, -5) -- home indicator
    elseif kind == "tablet" then
        local body = outline(40, 30, 6, Vector2.new(0.5, 0.5), 0.5, 0, 2.4)
        bar(14, 2.5, 1.25, 1, body, -5) -- home indicator
    else -- desktop
        outline(42, 27, 4, Vector2.new(0.5, 0), 0, 2, 2.4) -- screen
        local neck = Instance.new("Frame")
        neck.Size = UDim2.fromOffset(5, 5)
        neck.AnchorPoint = Vector2.new(0.5, 0)
        neck.Position = UDim2.new(0.5, 0, 0, 29)
        neck.BackgroundColor3 = color
        neck.BorderSizePixel = 0
        neck.Parent = box
        reg(neck, "BackgroundColor3")
        local base = Instance.new("Frame")
        base.Size = UDim2.fromOffset(22, 3)
        base.AnchorPoint = Vector2.new(0.5, 0)
        base.Position = UDim2.new(0.5, 0, 0, 34)
        base.BackgroundColor3 = color
        base.BorderSizePixel = 0
        base.Parent = box
        Util.corner(base, 1.5)
        reg(base, "BackgroundColor3")
    end

    return {
        setColor = function(c)
            for _, p in ipairs(parts) do
                Util.tween(p.inst, { [p.prop] = c }, 0.3)
            end
        end,
    }
end

function DeviceSelector.run(onChoose)
    local saved = Util.load("DevicePref")
    local vp = Util.viewport()
    local cardW, cardH = 384, 468
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
    Util.tween(backdrop, { BackgroundTransparency = 1 - UI.backdropA }, 0.45)

    -- Card
    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.Position = UDim2.fromOffset(cardX, cardY)
    card.BackgroundColor3 = UI.card
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = gui
    Util.corner(card, UI.cardRadius)
    local cardStroke = Util.stroke(card, UI.hairline, 1, 0.35)

    -- Soft shadow behind the card (sibling, fades in)
    local shadow = Util.shadow(card, 46, 1)
    Util.tween(shadow, { ImageTransparency = 0.5 }, 0.5)

    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 0.92
    cardScale.Parent = card
    tw(cardScale, { Scale = 1 }, SPRING)

    -- Close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 40, 18)
    closeBtn.BackgroundColor3 = UI.closeBg
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Image = "rbxassetid://7072725342"
    closeBtn.ImageColor3 = UI.textSub
    closeBtn.ImageRectOffset = Vector2.new(0, 0)
    closeBtn.ZIndex = 3
    closeBtn.Parent = card
    Util.corner(closeBtn, 14)
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, { BackgroundColor3 = UI.closeHov }, QUICK) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, { BackgroundColor3 = UI.closeBg }, SMOOTH) end)

    -- Title + subtitle
    local title = Instance.new("TextLabel")
    title.Text = "Choose Your Device"
    title.Size = UDim2.fromOffset(cardW - 64, 30)
    title.Position = UDim2.fromOffset(28, 32)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.TextSize = 23
    title.TextColor3 = UI.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "How are you running SYNC?"
    subtitle.Size = UDim2.fromOffset(cardW - 64, 20)
    subtitle.Position = UDim2.fromOffset(28, 66)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Theme.fonts.caption
    subtitle.TextSize = 14
    subtitle.TextColor3 = UI.textSub
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 3
    subtitle.Parent = card

    local devices = {
        { id = "mobile",  title = "Mobile",  desc = "Phone-optimized layout" },
        { id = "tablet",  title = "Tablet",  desc = "Tablet-optimized layout" },
        { id = "desktop", title = "Desktop", desc = "Full desktop experience" },
    }

    local startY, spacing, optH = 110, 14, 88
    local optW, optX = cardW - 48, 24

    local options = {}
    local selectedId = saved
    local closing = false

    local function paint(opt, sel, animate)
        local set = animate and tw or function(i, p) for k, v in pairs(p) do i[k] = v end end
        set(opt.bg,        { BackgroundColor3 = sel and UI.selectedBg or UI.optionBg }, SMOOTH)
        set(opt.stroke,    { Transparency = sel and 0 or 1 }, SMOOTH)
        set(opt.well,      { BackgroundColor3 = sel and UI.accent or UI.wellBg }, SMOOTH)
        set(opt.wellStroke,{ Transparency = sel and 1 or 0.5 }, SMOOTH)
        opt.icon.setColor(sel and Color3.fromRGB(255, 255, 255) or UI.accent)
    end

    local function applySelection(id, animate)
        selectedId = id
        for _, opt in ipairs(options) do
            paint(opt, opt.id == id, animate)
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
                tw(opt.well, { BackgroundTransparency = 1 }, QUICK)
                tw(opt.wellStroke, { Transparency = 1 }, QUICK)
                opt.icon.setColor(opt.id == selectedId and Color3.fromRGB(255,255,255) or UI.accent)
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

    for i, device in ipairs(devices) do
        local yPos = startY + (i - 1) * (optH + spacing)

        local opt = Instance.new("TextButton")
        opt.Text = ""
        opt.AutoButtonColor = false
        opt.Size = UDim2.fromOffset(optW, optH)
        opt.Position = UDim2.fromOffset(optX, yPos)
        opt.BackgroundColor3 = UI.optionBg
        opt.BorderSizePixel = 0
        opt.ZIndex = 3
        opt.Parent = card
        Util.corner(opt, UI.optionRad)
        local optStroke = Util.stroke(opt, UI.accent, 2, 1)

        -- Icon well
        local well = Instance.new("Frame")
        well.Size = UDim2.fromOffset(56, 56)
        well.Position = UDim2.fromOffset(14, (optH - 56) / 2)
        well.BackgroundColor3 = UI.wellBg
        well.BorderSizePixel = 0
        well.ZIndex = 4
        well.Parent = opt
        Util.corner(well, 15)
        local wellStroke = Util.stroke(well, UI.hairline, 1, 0.5)

        local icon = buildIcon(well, device.id, UI.accent)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = device.title
        titleLabel.Size = UDim2.fromOffset(optW - 100, 22)
        titleLabel.Position = UDim2.fromOffset(86, 22)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Theme.fonts.title
        titleLabel.TextSize = 17
        titleLabel.TextColor3 = UI.textPrimary
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        titleLabel.ZIndex = 4
        titleLabel.Parent = opt

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = device.desc
        descLabel.Size = UDim2.fromOffset(optW - 100, 18)
        descLabel.Position = UDim2.fromOffset(86, 47)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Theme.fonts.caption
        descLabel.TextSize = 13
        descLabel.TextColor3 = UI.textSub
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.ZIndex = 4
        descLabel.Parent = opt

        local optScale = Instance.new("UIScale")
        optScale.Parent = opt

        local data = {
            id = device.id, bg = opt, stroke = optStroke, well = well,
            wellStroke = wellStroke, icon = icon, label = titleLabel,
            desc = descLabel, scale = optScale,
        }
        options[#options + 1] = data

        opt.MouseEnter:Connect(function()
            if data.id ~= selectedId then tw(opt, { BackgroundColor3 = UI.optionHover }, QUICK) end
            tw(optScale, { Scale = 1.02 }, QUICK)
        end)
        opt.MouseLeave:Connect(function()
            tw(opt, { BackgroundColor3 = (data.id == selectedId) and UI.selectedBg or UI.optionBg }, SMOOTH)
            tw(optScale, { Scale = 1 }, SMOOTH)
        end)
        opt.MouseButton1Down:Connect(function()
            tw(optScale, { Scale = 0.97 }, QUICK)
        end)
        opt.MouseButton1Click:Connect(function()
            applySelection(data.id, true)
            tw(optScale, { Scale = 1 }, SPRING)
            task.delay(0.22, function()
                Util.save("DevicePref", data.id)
                closeMenu(data.id)
            end)
        end)
    end

    if selectedId then
        applySelection(selectedId, false)
    end

    closeBtn.MouseButton1Click:Connect(function() closeMenu(selectedId) end)

    return gui
end

return DeviceSelector
end)

SYNC.define("init", function()
-- SYNC / init
-- Entry module. Boot sequence -> device selector -> (desktop, coming next).

local Boot           = SYNC.import("os/Boot")
local DeviceSelector = SYNC.import("os/DeviceSelector")

Boot.run(function()
    DeviceSelector.run(function(device)
        -- device is "mobile" | "tablet" | "desktop" | nil (dismissed)
        -- TODO: launch Desktop.start(device) here once built.
    end)
end)
end)

SYNC.import("init")
