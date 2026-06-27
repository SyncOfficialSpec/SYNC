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

SYNC.define("core/Icons", function()
-- SYNC / core / Icons
-- Lucide icon set (https://lucide.dev) via the lucide-roblox spritesheet,
-- the same source Rayfield uses. Icons.get(name) -> { Image, ImageRectSize, ImageRectOffset }.
-- Icons.apply(image, name, color) sets them in one call. Curated subset.

local Icons = {}

local DATA = {
    ["smartphone"] = { 16898613777, 257, 918 },
    ["tablet"] = { 16898613777, 918, 906 },
    ["monitor"] = { 16898613613, 404, 820 },
    ["laptop"] = { 16898613509, 563, 967 },
    ["check"] = { 16898612819, 710, 869 },
    ["circle-check"] = { 16898612819, 869, 955 },
    ["x"] = { 16898613869, 869, 906 },
    ["circle-x"] = { 16898613044, 820, 306 },
    ["settings"] = { 16898613777, 771, 257 },
    ["folder"] = { 16898613353, 404, 967 },
    ["terminal"] = { 16898613869, 820, 257 },
    ["info"] = { 16898613509, 612, 869 },
    ["wifi"] = { 16898613869, 869, 808 },
    ["battery"] = { 16898612629, 967, 857 },
    ["search"] = { 16898613699, 918, 857 },
    ["bluetooth"] = { 16898612819, 771, 355 },
    ["volume-2"] = { 16898613869, 771, 808 },
    ["sun"] = { 16898613777, 967, 453 },
    ["moon"] = { 16898613613, 306, 918 },
    ["bell"] = { 16898612819, 820, 257 },
    ["trash-2"] = { 16898613869, 257, 918 },
    ["plus"] = { 16898613699, 257, 918 },
    ["minus"] = { 16898613613, 771, 196 },
    ["chevron-right"] = { 16898612819, 869, 759 },
    ["chevron-down"] = { 16898612819, 196, 918 },
    ["chevron-left"] = { 16898612819, 404, 967 },
    ["chevron-up"] = { 16898612819, 710, 918 },
    ["power"] = { 16898613699, 820, 147 },
    ["grid-3x3"] = { 16898613509, 98, 771 },
    ["command"] = { 16898613044, 563, 918 },
    ["compass"] = { 16898613044, 514, 967 },
    ["mail"] = { 16898613613, 820, 0 },
    ["message-circle"] = { 16898613613, 563, 820 },
    ["music"] = { 16898613613, 967, 563 },
    ["image"] = { 16898613509, 306, 918 },
    ["calendar"] = { 16898612819, 355, 918 },
    ["file-text"] = { 16898613353, 869, 355 },
    ["camera"] = { 16898612819, 967, 563 },
    ["map"] = { 16898613613, 306, 771 },
    ["gamepad-2"] = { 16898613353, 710, 967 },
    ["sparkles"] = { 16898613777, 918, 49 },
    ["globe"] = { 16898613509, 771, 563 },
    ["app-window"] = { 16898612629, 612, 820 },
    ["folder-open"] = { 16898613353, 820, 759 },
    ["calculator"] = { 16898612819, 563, 918 },
    ["clock"] = { 16898613044, 771, 661 },
    ["cloud"] = { 16898613044, 918, 306 },
    ["video"] = { 16898613869, 355, 967 },
    ["headphones"] = { 16898613509, 306, 869 },
    ["book-open"] = { 16898612819, 820, 355 },
    ["github"] = { 16898613509, 0, 820 },
    ["sliders-horizontal"] = { 16898613777, 820, 355 },
    ["battery-full"] = { 16898612629, 967, 808 },
    ["battery-medium"] = { 16898612629, 869, 906 },
    ["panel-top"] = { 16898613613, 869, 857 },
}

local RECT = Vector2.new(48, 48)

function Icons.get(name)
    local d = DATA[name]
    if not d then return nil end
    return { Image = "rbxassetid://" .. d[1], ImageRectSize = RECT, ImageRectOffset = Vector2.new(d[2], d[3]) }
end

function Icons.apply(img, name, color)
    local d = DATA[name]
    if not d then return false end
    img.Image = "rbxassetid://" .. d[1]
    img.ImageRectSize = RECT
    img.ImageRectOffset = Vector2.new(d[2], d[3])
    if color then img.ImageColor3 = color end
    return true
end

return Icons
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

-- Liquid Glass rim light: a hairline stroke that's bright along the top edge and
-- fades toward the bottom, giving panels that lit-glass edge. Returns the stroke.
function Util.rimStroke(parent, thickness, topAlpha, botAlpha)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = thickness or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, topAlpha or 0.35), -- top: brighter
        NumberSequenceKeypoint.new(1, botAlpha or 0.9),  -- bottom: faint
    })
    g.Parent = s
    return s
end

function Util.padding(parent, all)
    local p = Instance.new("UIPadding")
    local u = UDim.new(0, all or 0)
    p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = u, u, u, u
    p.Parent = parent
    return p
end

-- Real drop shadow using the native UIShadow modifier (released June 2026).
-- Parented to `target`, it follows the element's rounded corners automatically
-- with true gaussian blur. opts: { blur, spread, transparency, offset, color }.
-- Returns the UIShadow, or nil on older clients that lack the class.
function Util.shadow(target, opts)
    opts = opts or {}
    local ok, sh = pcall(function()
        local s = Instance.new("UIShadow")
        s.Color = opts.color or Color3.fromRGB(0, 0, 0)
        s.BlurRadius = UDim.new(0, opts.blur or 34)
        s.Spread = opts.spread or 0
        s.Offset = opts.offset or UDim2.fromOffset(0, 10)
        s.Transparency = opts.transparency ~= nil and opts.transparency or 0.5
        s.Parent = target
        return s
    end)
    return ok and sh or nil
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

SYNC.define("ui/Slider", function()
-- SYNC / ui / Slider
-- macOS-style slider: thin track, filled portion, round draggable knob.
-- Slider.create(parent, initial, onChange) -> { set, get }. Fills parent's width.

local UserInputService = game:GetService("UserInputService")

local Util = SYNC.import("core/Util")

local Slider = {}

local WHITE = Color3.fromRGB(255, 255, 255)

local function clamp01(x) return math.clamp(x, 0, 1) end

function Slider.create(parent, initial, onChange)
    local value = clamp01(initial or 0)
    local baseZ = (parent.ZIndex or 1) + 1

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.Size = UDim2.new(1, 0, 0, 4)
    track.BackgroundColor3 = Color3.fromRGB(86, 86, 92)
    track.BorderSizePixel = 0
    track.ZIndex = baseZ
    track.Parent = parent
    Util.corner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(value, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(225, 225, 230)
    fill.BorderSizePixel = 0
    fill.ZIndex = baseZ
    fill.Parent = track
    Util.corner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(value, 0, 0.5, 0)
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    knob.ZIndex = baseZ + 1
    knob.Parent = track
    Util.corner(knob, 8)
    Util.shadow(knob, { blur = 6, transparency = 0.6, offset = UDim2.fromOffset(0, 1) })

    -- Transparent hit area for press + drag
    local hit = Instance.new("TextButton")
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.BackgroundTransparency = 1
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.Position = UDim2.fromScale(0.5, 0.5)
    hit.AnchorPoint = Vector2.new(0.5, 0.5)
    hit.ZIndex = baseZ + 2
    hit.Parent = parent

    local function apply()
        fill.Size = UDim2.new(value, 0, 1, 0)
        knob.Position = UDim2.new(value, 0, 0.5, 0)
    end

    local function setFromX(px)
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        value = clamp01((px - track.AbsolutePosition.X) / w)
        apply()
        if onChange then onChange(value) end
    end

    local dragging = false
    local conns = {}
    hit.MouseButton1Down:Connect(function()
        dragging = true
        setFromX(UserInputService:GetMouseLocation().X)
    end)
    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    conns[#conns + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    -- Clean up global input connections when the slider is removed
    track.AncestryChanged:Connect(function(_, p)
        if not p then for _, c in ipairs(conns) do c:Disconnect() end end
    end)

    return {
        get = function() return value end,
        set = function(v) value = clamp01(v); apply() end,
    }
end

return Slider
end)

SYNC.define("ui/Switch", function()
-- SYNC / ui / Switch
-- macOS-style toggle: neutral grey track, light/white rounded-rectangle knob
-- (no green). Switch.create(parent, initial, onChange) -> { instance, get, set }

local Util = SYNC.import("core/Util")

local W, H     = 54, 26       -- slim, elongated track
local KW, KH   = 26, 20       -- rounded-rectangle knob
local KRADIUS  = 8            -- rounded corner (not a circle)
local INSET_X  = 3
local TRACK_OFF = Color3.fromRGB(78, 78, 84)    -- grey off-track
local TRACK_ON  = Color3.fromRGB(128, 128, 134) -- lighter grey when on
local KNOB_OFF  = Color3.fromRGB(245, 245, 248) -- near-white knob
local KNOB_ON   = Color3.fromRGB(255, 255, 255) -- white knob

local Switch = {}

local function knobX(on) return on and (W - KW - INSET_X) or INSET_X end

function Switch.create(parent, initial, onChange)
    local value = initial and true or false

    local baseZ = (parent.ZIndex or 1) + 1

    local track = Instance.new("TextButton")
    track.Text = ""
    track.AutoButtonColor = false
    track.Size = UDim2.fromOffset(W, H)
    track.BackgroundColor3 = value and TRACK_ON or TRACK_OFF
    track.BorderSizePixel = 0
    track.ZIndex = baseZ
    track.Parent = parent
    Util.corner(track, H / 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(KW, KH)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, knobX(value), 0.5, 0)
    knob.BackgroundColor3 = value and KNOB_ON or KNOB_OFF
    knob.BorderSizePixel = 0
    knob.ZIndex = baseZ + 1
    knob.Parent = track
    Util.corner(knob, KRADIUS) -- rounded rectangle, not a circle
    Util.shadow(knob, { blur = 6, transparency = 0.6, offset = UDim2.fromOffset(0, 1) })

    local function render(animate)
        local kp = { Position = UDim2.new(0, knobX(value), 0.5, 0), BackgroundColor3 = value and KNOB_ON or KNOB_OFF }
        local tp = { BackgroundColor3 = value and TRACK_ON or TRACK_OFF }
        if animate then
            Util.tween(knob, kp, 0.18, Enum.EasingStyle.Quart)
            Util.tween(track, tp, 0.18)
        else
            knob.Position = kp.Position
            knob.BackgroundColor3 = kp.BackgroundColor3
            track.BackgroundColor3 = tp.BackgroundColor3
        end
    end

    track.MouseButton1Click:Connect(function()
        value = not value
        render(true)
        if onChange then onChange(value) end
    end)

    return {
        instance = track,
        get = function() return value end,
        set = function(v, animate) value = v and true or false; render(animate ~= false) end,
    }
end

return Switch
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

SYNC.define("os/Desktop", function()
-- SYNC / os / Desktop
-- The desktop you land on after choosing "Desktop": a wallpaper plus the dock.
-- Menu bar and windows come next. Desktop.start() -> { destroy }.

local Util     = SYNC.import("core/Util")
local Dock     = SYNC.import("os/Dock")
local Settings = SYNC.import("os/Settings")
local MenuBar  = SYNC.import("os/MenuBar")

local Desktop = {}

function Desktop.start()
    -- No wallpaper: the menu bar + dock float over the actual game screen.
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Desktop"
    Util.mount(gui)

    local menubar = MenuBar.create(gui)

    local dock
    dock = Dock.create(gui, function(appName)
        if appName == "Settings" then
            Settings.open({
                alwaysShow = Util.load("DockAlwaysShow") == "true",
                onAlwaysShow = function(v)
                    Util.save("DockAlwaysShow", v and "true" or "false")
                    dock.setAlwaysShow(v)
                end,
                mag = dock.getMagFrac(),
                onMag = function(f)
                    dock.setMagnification(f)
                    Util.save("DockMagFrac", tostring(f))
                end,
                dockSize = dock.getDockFrac(),
                onDockSize = function(f)
                    dock.setDockSize(f)
                    Util.save("DockSizeFrac", tostring(f))
                end,
            })
        end
    end)

    return {
        gui = gui,
        destroy = function()
            if dock then dock.destroy() end
            if menubar then menubar.destroy() end
            gui:Destroy()
        end,
    }
end

return Desktop
end)

SYNC.define("os/DeviceSelector", function()
-- SYNC / os / DeviceSelector
-- macOS frosted dark panel (blur faked with translucency), Lucide icon tiles,
-- selected checkmark, a Continue button to confirm, macOS-tuned spring animations.
-- DeviceSelector.run(onChoose): onChoose(id) on Continue, onChoose(nil) on dismiss.

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local DeviceSelector = {}

local ACCENT = Color3.fromRGB(10, 132, 255)
local WHITE  = Color3.fromRGB(255, 255, 255)

-- Per-device tile gradient + Lucide glyph
local DEVICES = {
    { id = "mobile",  title = "Mobile",  desc = "Phone optimized layout",  icon = "smartphone",
      top = Color3.fromRGB(52, 199, 89),  bot = Color3.fromRGB(40, 167, 69) },
    { id = "tablet",  title = "Tablet",  desc = "Tablet optimized layout", icon = "tablet",
      top = Color3.fromRGB(10, 132, 255), bot = Color3.fromRGB(0, 96, 223) },
    { id = "desktop", title = "Desktop", desc = "Full desktop experience", icon = "monitor",
      top = Color3.fromRGB(94, 92, 230),  bot = Color3.fromRGB(75, 63, 214) },
}

-- macOS frosted dark style (blur faked with translucency)
local S = {
    cardColor = Color3.fromRGB(40, 40, 48), cardTransp = 0.16,
    cardStroke = WHITE, cardStrokeTransp = 0.86,
    titleColor = Color3.fromRGB(245, 245, 247), subColor = Color3.fromRGB(160, 160, 168),
    descColor = Color3.fromRGB(152, 152, 159),
    rowColor = WHITE, rowTransp = 0.93,
    hoverColor = WHITE, hoverTransp = 0.88,
    selColor = ACCENT, selTransp = 0.8,
    closeColor = WHITE, closeTransp = 0.86, closeHover = WHITE, closeHoverTransp = 0.78,
    closeIcon = Color3.fromRGB(210, 210, 217),
    backdropA = 0.6,
}

-- macOS-flavored easing presets
local SPRING = { 0.5, Enum.EasingStyle.Back,  Enum.EasingDirection.Out }
local SMOOTH = { 0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out }
local QUICK  = { 0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out }

local function tw(inst, props, preset)
    return Util.tween(inst, props, preset[1], preset[2], preset[3])
end

-- Colored icon tile with a white Lucide glyph. Anchored at center so its hover
-- pop scales evenly. Returns the tile frame and its UIScale.
local function buildTile(parent, device)
    local tile = Instance.new("Frame")
    tile.Size = UDim2.fromOffset(50, 50)
    tile.AnchorPoint = Vector2.new(0.5, 0.5)
    tile.Position = UDim2.fromOffset(14 + 25, 12 + 25)
    tile.BackgroundColor3 = device.top
    tile.BorderSizePixel = 0
    tile.ZIndex = 5
    tile.Parent = parent
    Util.corner(tile, 13)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(device.top, device.bot)
    grad.Rotation = 90
    grad.Parent = tile

    local scale = Instance.new("UIScale")
    scale.Parent = tile

    local glyph = Instance.new("ImageLabel")
    glyph.Size = UDim2.fromOffset(28, 28)
    glyph.AnchorPoint = Vector2.new(0.5, 0.5)
    glyph.Position = UDim2.fromScale(0.5, 0.5)
    glyph.BackgroundTransparency = 1
    glyph.ZIndex = 6
    glyph.Parent = tile
    Icons.apply(glyph, device.icon, WHITE)

    return tile, scale
end

-- Selected checkmark: accent circle + white Lucide check. Returns { show, hide }
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

    local tick = Instance.new("ImageLabel")
    tick.Size = UDim2.fromOffset(15, 15)
    tick.AnchorPoint = Vector2.new(0.5, 0.5)
    tick.Position = UDim2.fromScale(0.5, 0.5)
    tick.BackgroundTransparency = 1
    tick.ImageTransparency = 1
    tick.ZIndex = 7
    tick.Parent = c
    Icons.apply(tick, "check", WHITE)

    return {
        show = function(animate)
            if animate then
                tw(c, { BackgroundTransparency = 0 }, QUICK)
                tw(tick, { ImageTransparency = 0 }, QUICK)
                tw(scale, { Scale = 1 }, SPRING)
            else
                c.BackgroundTransparency = 0
                tick.ImageTransparency = 0
                scale.Scale = 1
            end
        end,
        hide = function()
            tw(c, { BackgroundTransparency = 1 }, QUICK)
            tw(tick, { ImageTransparency = 1 }, QUICK)
            scale.Scale = 0.4
        end,
    }
end

function DeviceSelector.run(onChoose)
    local saved = Util.load("DevicePref")
    local vp = Util.viewport()

    local cardW = 384
    local optH, spacing, optX = 74, 12, 20
    local optW = cardW - 40
    local startY = 110
    local rowsEnd = startY + (#DEVICES * optH) + ((#DEVICES - 1) * spacing)
    local btnY = rowsEnd + 18
    local btnH = 46
    local cardH = btnY + btnH + 22
    local cardX, cardY = (vp.X - cardW) / 2, (vp.Y - cardH) / 2
    local fromY = vp.Y + 20 -- starts just below the screen, glides up to center

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_DeviceSelector"
    Util.mount(gui)

    -- Invisible backdrop (no screen dimming, just keeps layering consistent)
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = gui

    -- Card: a plain Frame so the native UIShadow renders fully (a CanvasGroup
    -- would clip the shadow). The content lives in an inner CanvasGroup so the
    -- whole panel can still fade uniformly on close.
    -- Card: center-anchored so it expands open from height 0 (Rayfield-style).
    -- Plain Frame so the native UIShadow renders fully; content in an inner
    -- CanvasGroup that clips + fades as one unit.
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

    -- Native shadow, follows the rounded corners, soft and minimal
    local shadow = Util.shadow(card, { blur = 40, spread = -2, transparency = 0.5, offset = UDim2.fromOffset(0, 12) })

    local content = Instance.new("CanvasGroup")
    content.Size = UDim2.fromScale(1, 1)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.GroupTransparency = 0
    content.ZIndex = 2
    content.Parent = card

    -- Close (thin Lucide X)
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 40, 18)
    closeBtn.BackgroundColor3 = S.closeColor
    closeBtn.BackgroundTransparency = S.closeTransp
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 4
    closeBtn.Parent = content
    Util.corner(closeBtn, 14)

    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Size = UDim2.fromOffset(15, 15)
    closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    closeIcon.Position = UDim2.fromScale(0.5, 0.5)
    closeIcon.BackgroundTransparency = 1
    closeIcon.ZIndex = 5
    closeIcon.Parent = closeBtn
    Icons.apply(closeIcon, "x", S.closeIcon)

    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, { BackgroundColor3 = S.closeHover, BackgroundTransparency = S.closeHoverTransp }, QUICK)
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
    title.Parent = content

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
    subtitle.Parent = content

    local options = {}
    local selectedId = saved
    local closing = false

    -- Continue button (confirms the selection)
    local continueBtn = Instance.new("TextButton")
    continueBtn.Size = UDim2.fromOffset(optW, btnH)
    continueBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    continueBtn.Position = UDim2.fromOffset(cardW / 2, btnY + btnH / 2) -- center anchor
    continueBtn.BackgroundColor3 = ACCENT
    continueBtn.AutoButtonColor = false
    continueBtn.Text = "Continue"
    continueBtn.Font = Theme.fonts.title
    continueBtn.TextSize = 16
    continueBtn.TextColor3 = WHITE
    continueBtn.BorderSizePixel = 0
    continueBtn.ZIndex = 3
    continueBtn.Parent = content
    Util.corner(continueBtn, 14)

    local function setContinueEnabled(on)
        continueBtn.Active = on
        continueBtn.AutoButtonColor = false
        tw(continueBtn, { BackgroundTransparency = on and 0 or 0.55, TextTransparency = on and 0 or 0.45 }, SMOOTH)
    end

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
        setContinueEnabled(true)
    end

    local function closeMenu(chosen)
        if closing then return end
        closing = true
        -- macOS-style exit: reverse of the entrance. Slides down, scales, fades out
        -- as one unit (content CanvasGroup + card bg/stroke/shadow).
        -- No animation: just close.
        gui:Destroy()
        if onChoose then onChoose(chosen) end
    end

    for i, device in ipairs(DEVICES) do
        local yPos = startY + (i - 1) * (optH + spacing)

        local opt = Instance.new("TextButton")
        opt.Text = ""
        opt.AutoButtonColor = false
        opt.Size = UDim2.fromOffset(optW, optH)
        opt.AnchorPoint = Vector2.new(0.5, 0.5)
        opt.Position = UDim2.fromOffset(cardW / 2, yPos + optH / 2) -- center anchor: hover grows evenly
        opt.BackgroundColor3 = S.rowColor
        opt.BackgroundTransparency = S.rowTransp
        opt.BorderSizePixel = 0
        opt.ZIndex = 3
        opt.Parent = content
        Util.corner(opt, 16)
        local optStroke = Util.stroke(opt, ACCENT, 2, 1)

        local tile, tileScale = buildTile(opt, device)

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

        local data = {
            id = device.id, bg = opt, stroke = optStroke, tile = tile, tileScale = tileScale,
            label = titleLabel, desc = descLabel, check = check,
        }
        options[#options + 1] = data

        -- Hover/select life comes from the tile pop + row highlight only (no text
        -- scaling: UIScale on text re-rasterizes at fractional sizes and shimmers).
        opt.MouseEnter:Connect(function()
            if data.id ~= selectedId then setRow(data, "hover") end
            tw(tileScale, { Scale = 1.1 }, SPRING)
        end)
        opt.MouseLeave:Connect(function()
            setRow(data, data.id == selectedId and "selected" or "normal")
            tw(tileScale, { Scale = 1 }, SMOOTH)
        end)
        opt.MouseButton1Down:Connect(function() tw(tileScale, { Scale = 1.04 }, QUICK) end)
        opt.MouseButton1Click:Connect(function()
            applySelection(data.id, true)
            tw(tileScale, { Scale = 1.1 }, SPRING)
        end)
    end

    -- Initial state: pre-select saved choice, else disable Continue until a pick
    if selectedId then
        applySelection(selectedId, false)
    else
        setContinueEnabled(false)
    end

    continueBtn.MouseEnter:Connect(function()
        if continueBtn.Active then tw(continueBtn, { BackgroundColor3 = Color3.fromRGB(40, 150, 255) }, QUICK) end
    end)
    continueBtn.MouseLeave:Connect(function()
        tw(continueBtn, { BackgroundColor3 = ACCENT }, SMOOTH)
    end)
    continueBtn.MouseButton1Down:Connect(function()
        if continueBtn.Active then tw(continueBtn, { BackgroundColor3 = Color3.fromRGB(0, 102, 214) }, QUICK) end
    end)
    continueBtn.MouseButton1Click:Connect(function()
        if not continueBtn.Active or not selectedId then return end
        Util.save("DevicePref", selectedId)
        closeMenu(selectedId)
    end)

    closeBtn.MouseButton1Click:Connect(function() closeMenu(nil) end)

    return gui
end

return DeviceSelector
end)

SYNC.define("os/Dock", function()
-- SYNC / os / Dock
-- macOS-style dock with cursor-proximity magnification (fisheye). Icons grow
-- toward the cursor with a smooth cosine falloff, push their neighbours apart,
-- show their name on hover, and bounce when clicked. Slides up on first show.
--
-- Dock.create(parent) -> { destroy } ; parent is a ScreenGui/Frame to host it.

local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Dock = {}

local WHITE = Color3.fromRGB(255, 255, 255)

-- Tunables
local BASE          = 52    -- resting icon size (px)
local MAX           = 94    -- size directly under the cursor
local GAP           = 14    -- gap between icons
local INFLUENCE     = 150   -- horizontal reach of the magnification (px)
local BOTTOM_MARGIN = 14    -- gap from screen bottom to dock
local PADX          = 12    -- dock inner horizontal padding
local PADY          = 8     -- dock inner vertical padding
local BOUNCE_AMP    = 28    -- launch bounce height
local BOUNCE_DUR    = 0.5

-- App roster: name, Lucide glyph, squircle gradient. A few real-ish macOS apps
-- plus some "Test" tiles, as requested.
local APPS = {
    { name = "Finder",    icon = "folder",         top = Color3.fromRGB(70, 170, 255),  bot = Color3.fromRGB(20, 110, 230) },
    { name = "Safari",    icon = "compass",        top = Color3.fromRGB(90, 200, 255),  bot = Color3.fromRGB(20, 120, 235) },
    { name = "Messages",  icon = "message-circle", top = Color3.fromRGB(90, 220, 110),  bot = Color3.fromRGB(40, 180, 70) },
    { name = "Mail",      icon = "mail",           top = Color3.fromRGB(80, 180, 255),  bot = Color3.fromRGB(30, 120, 240) },
    { name = "Maps",      icon = "map",            top = Color3.fromRGB(120, 215, 130), bot = Color3.fromRGB(70, 175, 90) },
    { name = "Photos",    icon = "image",          top = Color3.fromRGB(255, 120, 160), bot = Color3.fromRGB(255, 175, 70) },
    { name = "Music",     icon = "music",          top = Color3.fromRGB(255, 110, 130), bot = Color3.fromRGB(230, 40, 90) },
    { name = "Calendar",  icon = "calendar",       top = Color3.fromRGB(255, 255, 255), bot = Color3.fromRGB(235, 235, 240), dark = true },
    { name = "Notes",     icon = "file-text",      top = Color3.fromRGB(255, 225, 120), bot = Color3.fromRGB(245, 195, 60), dark = true },
    { name = "Terminal",  icon = "terminal",       top = Color3.fromRGB(70, 72, 78),    bot = Color3.fromRGB(30, 32, 36) },
    { name = "Settings",  icon = "settings",       top = Color3.fromRGB(150, 152, 158), bot = Color3.fromRGB(90, 92, 98) },
    { name = "Test",      icon = "gamepad-2",      top = Color3.fromRGB(180, 130, 255), bot = Color3.fromRGB(120, 70, 230) },
    { name = "Test 2",    icon = "sparkles",       top = Color3.fromRGB(120, 200, 255), bot = Color3.fromRGB(160, 130, 255) },
}

local function buildIcon(parent, app)
    local holder = Instance.new("ImageButton")
    holder.Size = UDim2.fromOffset(BASE, BASE)
    holder.AnchorPoint = Vector2.new(0.5, 1)
    holder.BackgroundTransparency = 1
    holder.AutoButtonColor = false
    holder.ZIndex = 6
    holder.Parent = parent

    local tile = Instance.new("Frame")
    tile.Size = UDim2.fromScale(1, 1)
    tile.BackgroundColor3 = app.top
    tile.BorderSizePixel = 0
    tile.ZIndex = 6
    tile.Parent = holder
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2237, 0) -- squircle-ish, scales with size
    corner.Parent = tile
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(app.top, app.bot)
    grad.Rotation = 90
    grad.Parent = tile
    Util.stroke(tile, WHITE, 1, 0.86) -- subtle top highlight edge

    local glyph = Instance.new("ImageLabel")
    glyph.Size = UDim2.fromScale(0.56, 0.56)
    glyph.AnchorPoint = Vector2.new(0.5, 0.5)
    glyph.Position = UDim2.fromScale(0.5, 0.5)
    glyph.BackgroundTransparency = 1
    glyph.ZIndex = 7
    glyph.Parent = tile
    Icons.apply(glyph, app.icon, app.dark and Color3.fromRGB(40, 40, 46) or WHITE)

    -- Name label (shown on hover, above the icon)
    local label = Instance.new("TextLabel")
    label.AutoLocalize = false
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.new(0.5, 0, 0, -10)
    label.Size = UDim2.fromOffset(0, 22)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    label.BackgroundTransparency = 1
    label.Text = "  " .. app.name .. "  "
    label.Font = Theme.fonts.body
    label.TextSize = 13
    label.TextColor3 = WHITE
    label.TextTransparency = 1
    label.ZIndex = 9
    label.Parent = holder
    Util.corner(label, 7)
    local lstroke = Util.stroke(label, WHITE, 1, 1)

    -- Running indicator dot (sits just under the icon, inside the bar padding)
    if app.running then
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(4, 4)
        dot.AnchorPoint = Vector2.new(0.5, 0)
        dot.Position = UDim2.new(0.5, 0, 1, 5)
        dot.BackgroundColor3 = WHITE
        dot.BackgroundTransparency = 0.25
        dot.BorderSizePixel = 0
        dot.ZIndex = 6
        dot.Parent = holder
        Util.corner(dot, 2)
    end

    return { holder = holder, label = label, lstroke = lstroke, size = BASE, bounceStart = nil, restCenter = 0, pressed = false, app = app.name }
end

function Dock.create(parent, onAppClick)
    local vp = Util.viewport()
    local cx = vp.X / 2
    local stripH = MAX + 60
    local baselineY = stripH - BOTTOM_MARGIN - PADY -- in strip-local coords
    local barLocalY = stripH - BOTTOM_MARGIN

    -- Hover strip across the bottom. The bar + icons live INSIDE it so hovering
    -- an icon doesn't fire the strip's MouseLeave (which would kill magnify).
    local strip = Instance.new("Frame")
    strip.AnchorPoint = Vector2.new(0.5, 1)
    strip.Position = UDim2.fromOffset(cx, vp.Y)
    strip.Size = UDim2.fromOffset(vp.X, stripH)
    strip.BackgroundTransparency = 1
    strip.ZIndex = 4
    strip.Parent = parent

    -- Dock bar (frosted, rounded, soft shadow)
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0.5, 1)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    bar.BackgroundTransparency = 0.22
    bar.BorderSizePixel = 0
    bar.ZIndex = 5
    bar.Parent = strip
    Util.corner(bar, 22)
    Util.stroke(bar, WHITE, 1, 0.86)
    Util.shadow(bar, { blur = 36, spread = 0, transparency = 0.55, offset = UDim2.fromOffset(0, 10) })

    local icons = {}
    for _, app in ipairs(APPS) do
        local ic = buildIcon(strip, app)
        icons[#icons + 1] = ic
    end

    -- Resting centers (for stable distance math, independent of live magnify)
    local restingW = #icons * BASE + (#icons - 1) * GAP
    local restLeft = cx - restingW / 2
    for i, ic in ipairs(icons) do
        ic.restCenter = restLeft + (i - 1) * (BASE + GAP) + BASE / 2
    end

    -- Auto-hide: the dock stays hidden off the bottom edge and only reveals when
    -- the cursor presses against the very bottom of the screen (like macOS).
    local REVEAL_PX = 4                       -- must touch within this of the bottom
    local hideOffset = stripH                 -- how far down to tuck it away
    local alwaysShow = Util.load("DockAlwaysShow") == "true"
    local shown = false
    local curOff = hideOffset                 -- current slide offset (starts hidden)
    local offVel = 0                          -- spring velocity for the slide

    -- Press feedback + click (bounce + app action). Labels are handled in the
    -- render loop (poll-based) so a missed MouseLeave can't leave one stuck.
    for _, ic in ipairs(icons) do
        ic.labelShown = false
        ic.center = ic.restCenter
        ic.holder.MouseButton1Down:Connect(function() ic.pressed = true end)
        ic.holder.MouseButton1Up:Connect(function() ic.pressed = false end)
        ic.holder.MouseLeave:Connect(function() ic.pressed = false end)
        ic.holder.MouseButton1Click:Connect(function()
            ic.bounceStart = tick()
            if onAppClick then onAppClick(ic.app) end
        end)
    end

    -- Adjustable dock size + magnification (persisted, live-editable via Settings)
    local function clamp01(x) return math.clamp(x, 0, 1) end
    local baseSize = math.floor(40 + clamp01(tonumber(Util.load("DockSizeFrac")) or 0.4) * 32 + 0.5)
    local magScale = 1.0 + clamp01(tonumber(Util.load("DockMagFrac")) or 0.55) * 1.4

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        local m = UserInputService:GetMouseLocation()
        local mouseX, mouseY = m.X, m.Y
        local alpha = 1 - math.exp(-dt * 16) -- frame-rate independent smoothing

        -- Derived sizing (recomputed each frame so size/magnification update live)
        local BASE = baseSize
        local MAX = baseSize * magScale
        local stripHeight = MAX + 60
        local baselineY = stripHeight - BOTTOM_MARGIN - PADY
        local barLocalY = stripHeight - BOTTOM_MARGIN
        hideOffset = stripHeight
        strip.Size = UDim2.fromOffset(vp.X, stripHeight)
        local restingW = #icons * BASE + (#icons - 1) * GAP
        local restLeft = cx - restingW / 2
        for i, ic in ipairs(icons) do
            ic.restCenter = restLeft + (i - 1) * (BASE + GAP) + BASE / 2
        end

        -- Reveal/hide state. If "always show" is on, the dock is always out.
        -- Otherwise: reveal only at the very bottom edge, hide once the cursor
        -- moves well above the dock (hysteresis).
        if alwaysShow then
            shown = true
        elseif not shown then
            if mouseY >= vp.Y - REVEAL_PX then shown = true end
        else
            if mouseY < vp.Y - (MAX + 40) then shown = false end
        end

        -- Spring the slide offset so the dock eases out with a little life.
        local sdt = math.min(dt, 1 / 30)
        local targetOff = shown and 0 or hideOffset
        offVel = offVel + (-220 * (curOff - targetOff) - 26 * offVel) * sdt
        curOff = curOff + offVel * sdt

        -- Magnify only when the cursor is actually near the dock vertically (so an
        -- always-shown dock stays flat until you approach it).
        local restTop = vp.Y - (BASE + PADY * 2) - BOTTOM_MARGIN
        local magnifyActive = shown and (mouseY >= restTop - 30)

        -- Target sizes from cursor proximity
        for _, ic in ipairs(icons) do
            local target = BASE
            if magnifyActive then
                local d = math.abs(mouseX - ic.restCenter)
                if d < INFLUENCE then
                    local f = math.cos((d / INFLUENCE) * (math.pi / 2)) -- 1 at cursor -> 0 at edge
                    f = f * f * (3 - 2 * f)                              -- smoothstep, softer shoulders
                    target = BASE + (MAX - BASE) * f
                end
            end
            if ic.pressed then target = target * 0.9 end
            ic.size = ic.size + (target - ic.size) * alpha
        end

        -- Lay out centered, summing live sizes (neighbours pushed apart)
        local W = GAP * (#icons - 1)
        for _, ic in ipairs(icons) do W += ic.size end
        local accX = cx - W / 2
        local off = curOff
        for _, ic in ipairs(icons) do
            local center = accX + ic.size / 2
            local bounce = 0
            if ic.bounceStart then
                local t = tick() - ic.bounceStart
                if t < BOUNCE_DUR then
                    bounce = -BOUNCE_AMP * math.sin((t / BOUNCE_DUR) * math.pi)
                else
                    ic.bounceStart = nil
                end
            end
            local lift = (ic.size - BASE) * 0.16 -- magnified icons rise a touch more
            ic.center = center
            ic.holder.Size = UDim2.fromOffset(ic.size, ic.size)
            ic.holder.Position = UDim2.fromOffset(center, baselineY + off + bounce - lift)
            accX += ic.size + GAP
        end

        -- Labels: show the one under the cursor, hide the rest. Poll-based so it
        -- can never get stuck (e.g. when a panel opens over the dock).
        local hovered = nil
        if magnifyActive then
            for _, ic in ipairs(icons) do
                if mouseX >= ic.center - ic.size / 2 and mouseX <= ic.center + ic.size / 2 then
                    hovered = ic
                    break
                end
            end
        end
        for _, ic in ipairs(icons) do
            local want = (ic == hovered)
            if want ~= ic.labelShown then
                ic.labelShown = want
                Util.tween(ic.label, { TextTransparency = want and 0 or 1, BackgroundTransparency = want and 0.1 or 1 }, 0.12)
                Util.tween(ic.lstroke, { Transparency = want and 0.7 or 1 }, 0.12)
            end
        end

        -- Bar wraps the icons and rides the intro offset
        bar.Size = UDim2.fromOffset(W + PADX * 2, BASE + PADY * 2)
        bar.Position = UDim2.fromOffset(cx, barLocalY + off)
    end)

    return {
        setAlwaysShow = function(v) alwaysShow = v and true or false end,
        setDockSize = function(f) baseSize = math.floor(40 + clamp01(f) * 32 + 0.5) end,
        setMagnification = function(f) magScale = 1.0 + clamp01(f) * 1.4 end,
        getDockFrac = function() return (baseSize - 40) / 32 end,
        getMagFrac = function() return (magScale - 1.0) / 1.4 end,
        destroy = function()
            if conn then conn:Disconnect() end
            strip:Destroy() -- bar + icons are children, go with it
        end,
    }
end

return Dock
end)

SYNC.define("os/MenuBar", function()
-- SYNC / os / MenuBar
-- macOS-style top menu bar: Apple logo, bold app name, menu titles on the left;
-- control-center / wifi / battery / search / live clock on the right. Translucent
-- bar with a hairline bottom edge. MenuBar.create(parent) -> { destroy }.

local RunService = game:GetService("RunService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local MenuBar = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local DIM   = Color3.fromRGB(232, 232, 236)
local HEIGHT = 26
local APPLE_LOGO = "rbxassetid://6031075938"

-- A left-side text menu (Apple menu, app name, File/Edit/...) as a hover button.
local function menuButton(parent, text, bold, order)
    local b = Instance.new("TextButton")
    b.AutomaticSize = Enum.AutomaticSize.X
    b.Size = UDim2.fromOffset(0, HEIGHT)
    b.BackgroundColor3 = WHITE
    b.BackgroundTransparency = 1
    b.AutoButtonColor = false
    b.Text = text
    b.Font = bold and Theme.fonts.title or Theme.fonts.body
    b.TextSize = 13
    b.TextColor3 = DIM
    b.LayoutOrder = order
    b.ZIndex = 3
    b.Parent = parent
    Util.corner(b, 5)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = b
    b.MouseEnter:Connect(function() Util.tween(b, { BackgroundTransparency = 0.78 }, 0.1) end)
    b.MouseLeave:Connect(function() Util.tween(b, { BackgroundTransparency = 1 }, 0.12) end)
    return b
end

-- A right-side status item (icon or text) wrapped in a hover button.
local function statusItem(parent, order, width)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(width, 22)
    b.BackgroundColor3 = WHITE
    b.BackgroundTransparency = 1
    b.AutoButtonColor = false
    b.Text = ""
    b.LayoutOrder = order
    b.ZIndex = 3
    b.Parent = parent
    Util.corner(b, 5)
    b.MouseEnter:Connect(function() Util.tween(b, { BackgroundTransparency = 0.78 }, 0.1) end)
    b.MouseLeave:Connect(function() Util.tween(b, { BackgroundTransparency = 1 }, 0.12) end)
    return b
end

local function statusIcon(parent, order, name)
    local b = statusItem(parent, order, 26)
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.fromOffset(16, 16)
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Position = UDim2.fromScale(0.5, 0.5)
    img.BackgroundTransparency = 1
    img.ZIndex = 4
    img.Parent = b
    Icons.apply(img, name, DIM)
    return b
end

function MenuBar.create(parent)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, HEIGHT)
    bar.Position = UDim2.fromOffset(0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    bar.BackgroundTransparency = 0.25
    bar.BorderSizePixel = 0
    bar.ZIndex = 2
    bar.Parent = parent

    local hair = Instance.new("Frame")
    hair.Size = UDim2.new(1, 0, 0, 1)
    hair.Position = UDim2.new(0, 0, 1, 0)
    hair.AnchorPoint = Vector2.new(0, 1)
    hair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hair.BackgroundTransparency = 0.88
    hair.BorderSizePixel = 0
    hair.ZIndex = 2
    hair.Parent = bar

    -- Left cluster
    local left = Instance.new("Frame")
    left.Size = UDim2.new(0, 0, 1, 0)
    left.Position = UDim2.fromOffset(8, 0)
    left.BackgroundTransparency = 1
    left.AutomaticSize = Enum.AutomaticSize.X
    left.ZIndex = 3
    left.Parent = bar
    local ll = Instance.new("UIListLayout")
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.VerticalAlignment = Enum.VerticalAlignment.Center
    ll.Padding = UDim.new(0, 2)
    ll.Parent = left

    local apple = menuButton(left, "", true, 0)
    apple.Size = UDim2.fromOffset(24, HEIGHT)
    apple.AutomaticSize = Enum.AutomaticSize.None
    local alogo = Instance.new("ImageLabel")
    alogo.Size = UDim2.fromOffset(13, 15)
    alogo.AnchorPoint = Vector2.new(0.5, 0.5)
    alogo.Position = UDim2.fromScale(0.5, 0.5)
    alogo.BackgroundTransparency = 1
    alogo.Image = APPLE_LOGO
    alogo.ImageColor3 = WHITE
    alogo.ZIndex = 4
    alogo.Parent = apple

    menuButton(left, "SYNC", true, 1)
    menuButton(left, "File", false, 2)
    menuButton(left, "Edit", false, 3)
    menuButton(left, "View", false, 4)
    menuButton(left, "Window", false, 5)
    menuButton(left, "Help", false, 6)

    -- Right cluster
    local right = Instance.new("Frame")
    right.Size = UDim2.new(0, 0, 1, 0)
    right.AnchorPoint = Vector2.new(1, 0)
    right.Position = UDim2.new(1, -8, 0, 0)
    right.BackgroundTransparency = 1
    right.AutomaticSize = Enum.AutomaticSize.X
    right.ZIndex = 3
    right.Parent = bar
    local rl = Instance.new("UIListLayout")
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.VerticalAlignment = Enum.VerticalAlignment.Center
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.Padding = UDim.new(0, 2)
    rl.Parent = right

    statusIcon(right, 1, "sliders-horizontal") -- control center
    statusIcon(right, 2, "battery-full")
    statusIcon(right, 3, "wifi")
    statusIcon(right, 4, "search")

    local clockBtn = statusItem(right, 5, 132)
    local clock = Instance.new("TextLabel")
    clock.Size = UDim2.fromScale(1, 1)
    clock.BackgroundTransparency = 1
    clock.Font = Theme.fonts.body
    clock.TextSize = 13
    clock.TextColor3 = DIM
    clock.TextXAlignment = Enum.TextXAlignment.Right
    clock.ZIndex = 4
    clock.Parent = clockBtn
    local cpad = Instance.new("UIPadding")
    cpad.PaddingRight = UDim.new(0, 6)
    cpad.Parent = clockBtn

    local function tickClock()
        -- e.g. "Sat 28 Jun  17:42"
        clock.Text = os.date("%a %d %b  %H:%M")
    end
    tickClock()

    local acc = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        acc += dt
        if acc >= 5 then acc = 0; tickClock() end
    end)

    return {
        destroy = function()
            if conn then conn:Disconnect() end
            bar:Destroy()
        end,
    }
end

return MenuBar
end)

SYNC.define("os/Settings", function()
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

    local cardW, cardH = 440, 232
    local TB = 40 -- title bar height

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Settings"
    Util.mount(gui)
    Settings._gui = gui

    local function close()
        if not Settings._gui then return end
        Settings._gui = nil
        gui:Destroy()
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

    -- Window (TextButton so clicks inside are absorbed)
    local win = Instance.new("TextButton")
    win.Text = ""
    win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
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
        local dot = Instance.new(i == 1 and "TextButton" or "Frame")
        if i == 1 then dot.Text = ""; dot.AutoButtonColor = false end
        dot.Size = UDim2.fromOffset(12, 12)
        dot.Position = UDim2.fromOffset(14 + (i - 1) * 20, (TB - 12) / 2)
        dot.BackgroundColor3 = col
        dot.BorderSizePixel = 0
        dot.ZIndex = 4
        dot.Parent = bar
        Util.corner(dot, 6)
        if i == 1 then dot.MouseButton1Click:Connect(close) end
    end

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

    -- Grouped list (three rows with hairline separators)
    local rowH = 46
    local group = Instance.new("Frame")
    group.Size = UDim2.fromOffset(cardW - 32, rowH * 3)
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

    -- Row 1: Always show Dock (toggle)
    local r1 = row(0, "Always show Dock")
    local switchHolder = Instance.new("Frame")
    switchHolder.Size = UDim2.fromOffset(54, 26)
    switchHolder.AnchorPoint = Vector2.new(1, 0.5)
    switchHolder.Position = UDim2.new(1, -14, 0.5, 0)
    switchHolder.BackgroundTransparency = 1
    switchHolder.ZIndex = 4
    switchHolder.Parent = r1
    Switch.create(switchHolder, opts.alwaysShow, function(v)
        if opts.onAlwaysShow then opts.onAlwaysShow(v) end
    end)

    divider(rowH)

    -- Row 2: Magnification (slider)
    local r2 = row(rowH, "Magnification")
    local magHolder = Instance.new("Frame")
    magHolder.Size = UDim2.fromOffset(170, rowH)
    magHolder.AnchorPoint = Vector2.new(1, 0.5)
    magHolder.Position = UDim2.new(1, -16, 0.5, 0)
    magHolder.BackgroundTransparency = 1
    magHolder.ZIndex = 4
    magHolder.Parent = r2
    Slider.create(magHolder, opts.mag or 0.55, function(f)
        if opts.onMag then opts.onMag(f) end
    end)

    divider(rowH * 2)

    -- Row 3: Dock Size (slider)
    local r3 = row(rowH * 2, "Dock Size")
    local sizeHolder = Instance.new("Frame")
    sizeHolder.Size = UDim2.fromOffset(170, rowH)
    sizeHolder.AnchorPoint = Vector2.new(1, 0.5)
    sizeHolder.Position = UDim2.new(1, -16, 0.5, 0)
    sizeHolder.BackgroundTransparency = 1
    sizeHolder.ZIndex = 4
    sizeHolder.Parent = r3
    Slider.create(sizeHolder, opts.dockSize or 0.4, function(f)
        if opts.onDockSize then opts.onDockSize(f) end
    end)

    return { close = close }
end

return Settings
end)

SYNC.define("init", function()
-- SYNC / init
-- Entry module. Boot sequence -> device selector -> desktop (desktop mode for now).

local Boot           = SYNC.import("os/Boot")
local DeviceSelector = SYNC.import("os/DeviceSelector")
local Desktop        = SYNC.import("os/Desktop")

Boot.run(function()
    DeviceSelector.run(function(device)
        if device == "desktop" then
            Desktop.start()
        end
        -- mobile / tablet layouts come later; desktop is the current focus.
    end)
end)
end)

SYNC.import("init")
