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
    ["orbit"] = { 16898613613, 967, 612 },
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
-- Time (intentionally offset: always 5h17m behind the real local time)
-- ---------------------------------------------------------------------------
local TIME_OFFSET = 5 * 3600 + 17 * 60 -- seconds to subtract

function Util.now()
    return os.time() - TIME_OFFSET
end

function Util.date(fmt)
    return os.date(fmt, Util.now())
end

-- ---------------------------------------------------------------------------
-- HTTP request (prefer executor request with a real UA; fall back to HttpGet)
-- ---------------------------------------------------------------------------
local _req = (syn and syn.request) or (http and http.request) or http_request or request
local UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

function Util.httpGet(url)
    if _req then
        local ok, res = pcall(_req, { Url = url, Method = "GET", Headers = { ["User-Agent"] = UA } })
        if ok and res and res.Body and res.Body ~= "" then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(res) == "string" and res ~= "" then return res end
    return nil
end

-- ---------------------------------------------------------------------------
-- Remote image: download once and expose via getcustomasset (so we can use
-- images that aren't uploaded to Roblox). Returns a content id, or nil.
-- ---------------------------------------------------------------------------
function Util.remoteImage(url, filename)
    local getasset = (typeof(getcustomasset) == "function" and getcustomasset)
        or (typeof(getsynasset) == "function" and getsynasset)
    if not getasset or typeof(writefile) ~= "function" then return nil end
    local path = "SYNC/" .. filename
    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder("SYNC") then
            makefolder("SYNC")
        end
        if not (typeof(isfile) == "function" and isfile(path)) then
            local data = game:HttpGet(url, true)
            if data and data ~= "" then writefile(path, data) end
        end
    end)
    local id
    pcall(function() id = getasset(path) end)
    return id
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

SYNC.define("ui/Select", function()
-- SYNC / ui / Select
-- macOS pop-up button: shows the current value + up/down chevrons; clicking opens
-- a small menu of options with a checkmark on the selection.
-- Select.create(parent, options, value, onChange) -> { get, set }

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Select = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local SUB   = Color3.fromRGB(225, 225, 230)

function Select.create(parent, options, value, onChange)
    local screen = parent:FindFirstAncestorWhichIsA("ScreenGui")
    local baseZ = (parent.ZIndex or 1) + 1
    local btnW = 128

    local btn = Instance.new("TextButton")
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, 0, 0.5, 0)
    btn.Size = UDim2.fromOffset(btnW, 26)
    btn.BackgroundColor3 = WHITE
    btn.BackgroundTransparency = 1
    btn.ZIndex = baseZ
    btn.Parent = parent
    Util.corner(btn, 6)

    local valLabel = Instance.new("TextLabel")
    valLabel.BackgroundTransparency = 1
    valLabel.Size = UDim2.new(1, -34, 1, 0)
    valLabel.Position = UDim2.fromOffset(2, 0)
    valLabel.Font = Theme.fonts.body
    valLabel.TextSize = 14
    valLabel.TextColor3 = SUB
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Text = tostring(value)
    valLabel.ZIndex = baseZ
    valLabel.Parent = btn

    -- Tinted chevron square (the macOS pop-up indicator)
    local chev = Instance.new("Frame")
    chev.Size = UDim2.fromOffset(20, 22)
    chev.AnchorPoint = Vector2.new(1, 0.5)
    chev.Position = UDim2.new(1, 0, 0.5, 0)
    chev.BackgroundColor3 = Color3.fromRGB(96, 96, 104)
    chev.BackgroundTransparency = 0.15
    chev.BorderSizePixel = 0
    chev.ZIndex = baseZ
    chev.Parent = btn
    Util.corner(chev, 6)
    local up = Instance.new("ImageLabel")
    up.Size = UDim2.fromOffset(11, 11)
    up.AnchorPoint = Vector2.new(0.5, 0)
    up.Position = UDim2.new(0.5, 0, 0, 1)
    up.BackgroundTransparency = 1
    up.ZIndex = baseZ + 1
    up.Parent = chev
    Icons.apply(up, "chevron-up", WHITE)
    local dn = Instance.new("ImageLabel")
    dn.Size = UDim2.fromOffset(11, 11)
    dn.AnchorPoint = Vector2.new(0.5, 1)
    dn.Position = UDim2.new(0.5, 0, 1, -1)
    dn.BackgroundTransparency = 1
    dn.ZIndex = baseZ + 1
    dn.Parent = chev
    Icons.apply(dn, "chevron-down", WHITE)

    local current = value
    local menuLayer

    local function close()
        if menuLayer then menuLayer:Destroy(); menuLayer = nil end
    end

    local function open()
        if menuLayer then close(); return end
        local ap, as = btn.AbsolutePosition, btn.AbsoluteSize
        local menuW = btnW + 8
        local rowH = 30
        local menuH = #options * rowH + 8

        menuLayer = Instance.new("Frame")
        menuLayer.Size = UDim2.fromScale(1, 1)
        menuLayer.BackgroundTransparency = 1
        menuLayer.ZIndex = 60
        menuLayer.Parent = screen

        local catcher = Instance.new("TextButton")
        catcher.Text = ""
        catcher.AutoButtonColor = false
        catcher.Size = UDim2.fromScale(1, 1)
        catcher.BackgroundTransparency = 1
        catcher.ZIndex = 60
        catcher.Parent = menuLayer
        catcher.MouseButton1Click:Connect(close)

        local menu = Instance.new("Frame")
        menu.Size = UDim2.fromOffset(menuW, menuH)
        menu.Position = UDim2.fromOffset(ap.X + as.X - menuW, ap.Y + as.Y + 4)
        menu.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
        menu.BackgroundTransparency = 0.08
        menu.BorderSizePixel = 0
        menu.ZIndex = 61
        menu.Parent = menuLayer
        Util.corner(menu, 10)
        Util.rimStroke(menu, 1, 0.5, 0.92)
        Util.shadow(menu, { blur = 40, transparency = 0.4, offset = UDim2.fromOffset(0, 10) })

        for i, opt in ipairs(options) do
            local row = Instance.new("TextButton")
            row.Text = ""
            row.AutoButtonColor = false
            row.Size = UDim2.fromOffset(menuW - 8, rowH)
            row.Position = UDim2.fromOffset(4, 4 + (i - 1) * rowH)
            row.BackgroundColor3 = WHITE
            row.BackgroundTransparency = 1
            row.ZIndex = 62
            row.Parent = menu
            Util.corner(row, 6)

            local check = Instance.new("ImageLabel")
            check.Size = UDim2.fromOffset(14, 14)
            check.AnchorPoint = Vector2.new(0, 0.5)
            check.Position = UDim2.new(0, 10, 0.5, 0)
            check.BackgroundTransparency = 1
            check.ImageTransparency = (opt == current) and 0 or 1
            check.ZIndex = 63
            check.Parent = row
            Icons.apply(check, "check", WHITE)

            local lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1, -36, 1, 0)
            lbl.Position = UDim2.fromOffset(30, 0)
            lbl.Font = Theme.fonts.body
            lbl.TextSize = 14
            lbl.TextColor3 = WHITE
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = opt
            lbl.ZIndex = 63
            lbl.Parent = row

            row.MouseEnter:Connect(function() Util.tween(row, { BackgroundTransparency = 0.82 }, 0.1) end)
            row.MouseLeave:Connect(function() Util.tween(row, { BackgroundTransparency = 1 }, 0.12) end)
            row.MouseButton1Click:Connect(function()
                current = opt
                valLabel.Text = opt
                close()
                if onChange then onChange(opt) end
            end)
        end
    end

    btn.MouseButton1Click:Connect(open)

    return {
        instance = btn,
        get = function() return current end,
        set = function(v) current = v; valLabel.Text = tostring(v) end,
    }
end

return Select
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
    track.BackgroundColor3 = Color3.fromRGB(74, 74, 80)
    track.BorderSizePixel = 0
    track.ZIndex = baseZ
    track.Parent = parent
    Util.corner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(value, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(236, 236, 240)
    fill.BorderSizePixel = 0
    fill.ZIndex = baseZ
    fill.Parent = track
    Util.corner(fill, 2)

    -- Round knob with a touch of depth (convex shading + drop shadow), Apple style
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(value, 0, 0.5, 0)
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    knob.ZIndex = baseZ + 1
    knob.Parent = track
    Util.corner(knob, 9)
    local kg = Instance.new("UIGradient")
    kg.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(232, 232, 238))
    kg.Rotation = 90
    kg.Parent = knob
    Util.stroke(knob, Color3.fromRGB(0, 0, 0), 1, 0.86)
    Util.shadow(knob, { blur = 8, transparency = 0.55, offset = UDim2.fromOffset(0, 1) })

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
    -- Recessed depth: darken the top of the track (multiplied over its colour),
    -- plus a faint inner edge.
    local tgrad = Instance.new("UIGradient")
    tgrad.Color = ColorSequence.new(Color3.fromRGB(196, 196, 196), Color3.fromRGB(255, 255, 255))
    tgrad.Rotation = 90
    tgrad.Parent = track
    Util.stroke(track, Color3.fromRGB(0, 0, 0), 1, 0.72)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(KW, KH)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, knobX(value), 0.5, 0)
    knob.BackgroundColor3 = value and KNOB_ON or KNOB_OFF
    knob.BorderSizePixel = 0
    knob.ZIndex = baseZ + 1
    knob.Parent = track
    Util.corner(knob, KRADIUS) -- rounded rectangle, not a circle
    -- Convex shading (lighter top, slightly darker bottom)
    local kgrad = Instance.new("UIGradient")
    kgrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(234, 234, 238))
    kgrad.Rotation = 90
    kgrad.Parent = knob
    Util.shadow(knob, { blur = 7, transparency = 0.55, offset = UDim2.fromOffset(0, 1) }) -- drop shadow
    Util.shadow(knob, { blur = 12, transparency = 0.6, offset = UDim2.fromOffset(0, 0), color = Color3.fromRGB(255, 255, 255) }) -- soft glow

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

SYNC.define("os/Browser", function()
-- SYNC / os / Browser  ("Sense Browser")
-- Two modes:
--  * Bridge mode (best): connects to the Sense Browser desktop app over
--    127.0.0.1, which renders real pages in Chromium and streams screenshots.
--    SYNC shows the live page and forwards clicks/scroll/typing. Downloads are
--    blocked by the app. Needs the desktop app running on the same machine.
--  * Reader fallback: if the app isn't running, search via DuckDuckGo and show
--    page text (no images / JS). Always available.
-- Browser.open() -> window.

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Browser = {}

local WHITE  = Color3.fromRGB(255, 255, 255)
local DIM    = Color3.fromRGB(150, 150, 158)
local ACCENT = Color3.fromRGB(90, 150, 255)
local OK_GREEN = Color3.fromRGB(52, 199, 89)

local LOGO_URL = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/sense-logo.png"
local BRIDGE   = "http://127.0.0.1:31573"
local VW, VH   = 1280, 800 -- desktop render viewport (for click mapping)

local _req = (syn and syn.request) or (http and http.request) or http_request or request
local _getasset = (typeof(getcustomasset) == "function" and getcustomasset)
    or (typeof(getsynasset) == "function" and getsynasset)

Browser._gui = nil

-- ---------- text helpers (reader fallback) ----------
local function urlencode(s)
    return (tostring(s):gsub("[^%w%-_%.~]", function(c) return string.format("%%%02X", string.byte(c)) end))
end
local function urldecode(s)
    s = tostring(s):gsub("+", " ")
    return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end
local function decodeEntities(s)
    return (s:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">")
        :gsub("&quot;", '"'):gsub("&#39;", "'"):gsub("&#x27;", "'"):gsub("&nbsp;", " "))
end
local function stripTags(html)
    html = html:gsub("<script.->.-</script>", " "):gsub("<style.->.-</style>", " ")
    html = html:gsub("<!%-%-.-%-%->", " "):gsub("<br%s*/?>", "\n"):gsub("</p>", "\n"):gsub("<.->", "")
    html = decodeEntities(html):gsub("[ \t]+", " "):gsub("\n%s*\n%s*\n+", "\n\n")
    return (html:gsub("^%s+", ""))
end
local function parseDDG(html)
    local results = {}
    for href, title in html:gmatch('class="result__a"%s+href="(.-)"[^>]*>(.-)</a>') do
        local real = href
        local uddg = href:match("uddg=([^&]+)")
        if uddg then real = urldecode(uddg) end
        real = real:gsub("^//", "https://")
        local t = stripTags(title):gsub("%s+", " ")
        if t ~= "" then results[#results + 1] = { title = t, url = real, snippet = "" } end
        if #results >= 8 then break end
    end
    return results
end

-- ---------- bridge ----------
local bridgeKey = nil

local function reqRaw(path)
    if not _req then return nil end
    local headers = bridgeKey and { ["x-key"] = bridgeKey } or {}
    local ok, res = pcall(_req, { Url = BRIDGE .. path, Method = "GET", Headers = headers })
    if not ok or type(res) ~= "table" then return nil end
    local good = res.Success or (res.StatusCode and res.StatusCode < 400) or (res.Body ~= nil)
    if good then return res.Body end
    return nil
end

local function bridgePing()
    local b = reqRaw("/ping")
    return b ~= nil and tostring(b):find('"ok"') ~= nil
end
local function bridgePair()
    local b = reqRaw("/pair")
    if not b then return false end
    local k = tostring(b):match('"key"%s*:%s*"(.-)"')
    if k and k ~= "" then bridgeKey = k; return true end
    return false
end
local function bridgeConnect()
    if not _req then return false end
    if not bridgePing() then return false end
    return bridgePair()
end

-- getcustomasset caches by file PATH (permanently) on many executors, so reusing
-- the same filename shows a stale frame. Use a unique filename every frame and
-- delete old ones to avoid filling the disk.
local frameCounter = 0
local oldFramePaths = {}
local _delfile = (typeof(delfile) == "function" and delfile) or nil
local function fetchFrame()
    if not (_getasset and typeof(writefile) == "function") then return nil end
    local body = reqRaw("/shot")
    if not body or #body < 100 then return nil end
    frameCounter = frameCounter + 1
    local path = "SYNC/frames/f" .. frameCounter .. ".png"
    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder("SYNC/frames") then makefolder("SYNC/frames") end
        end
        writefile(path, body)
    end)
    local id
    pcall(function() id = _getasset(path) end)
    -- keep only the last few files
    table.insert(oldFramePaths, path)
    if #oldFramePaths > 4 then
        local old = table.remove(oldFramePaths, 1)
        if _delfile then pcall(function() _delfile(old) end) end
    end
    return id
end

-- ---------- Saturn fallback logo ----------
local function drawSaturn(parent, size, color)
    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(size, size)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.ZIndex = 4
    box.Parent = parent
    local thick = math.max(2, size * 0.05)
    local ring = Instance.new("Frame")
    ring.Size = UDim2.fromOffset(size * 0.98, size * 0.42)
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Rotation = -20
    ring.BackgroundTransparency = 1
    ring.ZIndex = 4
    ring.Parent = box
    Util.corner(ring, size * 0.21)
    Util.stroke(ring, color, thick, 0)
    local planet = Instance.new("Frame")
    planet.Size = UDim2.fromOffset(size * 0.6, size * 0.6)
    planet.AnchorPoint = Vector2.new(0.5, 0.5)
    planet.Position = UDim2.fromScale(0.5, 0.5)
    planet.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    planet.ZIndex = 5
    planet.Parent = box
    Util.corner(planet, size)
    Util.stroke(planet, color, thick, 0)
    return box
end

function Browser.open()
    if Browser._gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Browser"
    Util.mount(gui)
    Browser._gui = gui

    local W, H = 760, 520
    local connected = false
    local liveToken = 0
    local conns = {}

    local function close()
        if not Browser._gui then return end
        Browser._gui = nil
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end

    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 12)
    Util.stroke(win, WHITE, 1, 0.85)
    Util.shadow(win, { blur = 55, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 22) })

    -- Title bar (drag)
    local TB = 38
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    do
        local c = Instance.new("UICorner")
        local ok = pcall(function()
            c.TopLeftRadius = UDim.new(0, 12); c.TopRightRadius = UDim.new(0, 12)
            c.BottomLeftRadius = UDim.new(0, 0); c.BottomRightRadius = UDim.new(0, 0)
        end)
        if not ok then c.CornerRadius = UDim.new(0, 12) end
        c.Parent = bar
    end
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
    -- connection status pill
    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(1, 0.5)
    status.Position = UDim2.new(1, -14, 0.5, 0)
    status.Size = UDim2.fromOffset(220, 18)
    status.BackgroundTransparency = 1
    status.Font = Theme.fonts.caption
    status.TextSize = 12
    status.TextColor3 = DIM
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Text = "Connecting to desktop app…"
    status.ZIndex = 4
    status.Parent = bar

    -- Address bar
    local AB = 44
    local addr = Instance.new("Frame")
    addr.Size = UDim2.new(1, 0, 0, AB)
    addr.Position = UDim2.fromOffset(0, TB)
    addr.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
    addr.BorderSizePixel = 0
    addr.ZIndex = 3
    addr.Parent = win

    local homeBtn = Instance.new("ImageButton")
    homeBtn.Size = UDim2.fromOffset(26, 26)
    homeBtn.Position = UDim2.fromOffset(12, (AB - 26) / 2)
    homeBtn.BackgroundTransparency = 1
    homeBtn.AutoButtonColor = false
    homeBtn.ZIndex = 4
    homeBtn.Parent = addr
    Icons.apply(homeBtn, "chevron-left", DIM)

    local urlField = Instance.new("TextBox")
    urlField.Size = UDim2.new(1, -130, 0, 30)
    urlField.Position = UDim2.fromOffset(46, (AB - 30) / 2)
    urlField.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
    urlField.BorderSizePixel = 0
    urlField.Font = Theme.fonts.body
    urlField.TextSize = 13
    urlField.TextColor3 = WHITE
    urlField.PlaceholderText = "Search or enter URL"
    urlField.PlaceholderColor3 = DIM
    urlField.Text = "sense://homepage"
    urlField.TextXAlignment = Enum.TextXAlignment.Left
    urlField.ClearTextOnFocus = false
    urlField.ZIndex = 4
    urlField.Parent = addr
    Util.corner(urlField, 15)
    local up = Instance.new("UIPadding"); up.PaddingLeft = UDim.new(0, 14); up.Parent = urlField

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -(TB + AB))
    content.Position = UDim2.fromOffset(0, TB + AB)
    content.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.ZIndex = 3
    content.Parent = win
    do
        local c = Instance.new("UICorner")
        local ok = pcall(function()
            c.TopLeftRadius = UDim.new(0, 0); c.TopRightRadius = UDim.new(0, 0)
            c.BottomLeftRadius = UDim.new(0, 12); c.BottomRightRadius = UDim.new(0, 12)
        end)
        if not ok then c.CornerRadius = UDim.new(0, 12) end
        c.Parent = content
    end

    local function clearContent()
        liveToken = liveToken + 1 -- stop any running frame loop
        for _, ch in ipairs(content:GetChildren()) do
            if not ch:IsA("UICorner") then ch:Destroy() end
        end
    end

    local clockConn
    local showHomepage, navigate

    local function statusText(msg)
        clearContent()
        if clockConn then clockConn:Disconnect(); clockConn = nil end
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -48, 0, 60)
        t.Position = UDim2.fromOffset(24, 20)
        t.BackgroundTransparency = 1
        t.Font = Theme.fonts.body
        t.TextSize = 14
        t.TextColor3 = DIM
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Top
        t.TextWrapped = true
        t.Text = msg
        t.ZIndex = 4
        t.Parent = content
    end

    -- ===== LIVE (bridge) view =====
    local function showLive(url)
        if clockConn then clockConn:Disconnect(); clockConn = nil end
        clearContent()
        local myToken = liveToken
        urlField.Text = url

        local img = Instance.new("ImageButton")
        img.Size = UDim2.fromScale(1, 1)
        img.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        img.BorderSizePixel = 0
        img.AutoButtonColor = false
        img.ScaleType = Enum.ScaleType.Fit
        img.Image = ""
        img.ZIndex = 4
        img.Parent = content

        local loading = Instance.new("TextLabel")
        loading.AnchorPoint = Vector2.new(0.5, 0.5)
        loading.Position = UDim2.fromScale(0.5, 0.5)
        loading.Size = UDim2.fromOffset(200, 24)
        loading.BackgroundTransparency = 1
        loading.Font = Theme.fonts.body
        loading.TextSize = 14
        loading.TextColor3 = DIM
        loading.Text = "Loading…"
        loading.ZIndex = 5
        loading.Parent = content

        -- click -> normalized coords -> bridge
        img.MouseButton1Click:Connect(function()
            local mp = UserInputService:GetMouseLocation()
            local ap, asz = img.AbsolutePosition, img.AbsoluteSize
            if asz.X <= 0 or asz.Y <= 0 then return end
            local nx = math.clamp((mp.X - ap.X) / asz.X, 0, 1)
            local ny = math.clamp((mp.Y - ap.Y) / asz.Y, 0, 1)
            task.spawn(function() reqRaw("/click?x=" .. string.format("%.4f", nx) .. "&y=" .. string.format("%.4f", ny)) end)
        end)

        -- frame polling loop
        task.spawn(function()
            while Browser._gui == gui and liveToken == myToken do
                local id = fetchFrame()
                if liveToken ~= myToken then break end
                if id then img.Image = id; loading.Visible = false end
                task.wait(0.5)
            end
        end)
    end

    -- ===== Reader fallback (no app) =====
    local function makeScroll()
        clearContent()
        local sc = Instance.new("ScrollingFrame")
        sc.Size = UDim2.fromScale(1, 1)
        sc.BackgroundTransparency = 1
        sc.BorderSizePixel = 0
        sc.ScrollBarThickness = 5
        sc.CanvasSize = UDim2.new(0, 0, 0, 0)
        sc.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        sc.ZIndex = 4
        sc.Parent = content
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 16); pad.PaddingBottom = UDim.new(0, 16)
        pad.PaddingLeft = UDim.new(0, 24); pad.PaddingRight = UDim.new(0, 24)
        pad.Parent = sc
        local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 10); ll.Parent = sc
        return sc
    end

    local function readerOpenPage(url)
        urlField.Text = url
        statusText("Loading " .. url .. " … (reader mode)")
        task.spawn(function()
            local html = Util.httpGet(url)
            if Browser._gui ~= gui then return end
            if not html then statusText("Couldn't load this page (blocked or offline).") return end
            local text = stripTags(html)
            if #text > 12000 then text = text:sub(1, 12000) .. "\n\n…(truncated)" end
            local sc = makeScroll()
            local body = Instance.new("TextLabel")
            body.Size = UDim2.new(1, 0, 0, 0)
            body.AutomaticSize = Enum.AutomaticSize.Y
            body.BackgroundTransparency = 1
            body.Font = Theme.fonts.caption
            body.TextSize = 14
            body.TextColor3 = Color3.fromRGB(220, 220, 226)
            body.TextXAlignment = Enum.TextXAlignment.Left
            body.TextYAlignment = Enum.TextYAlignment.Top
            body.TextWrapped = true
            body.Text = text ~= "" and text or "(no readable text)"
            body.ZIndex = 4
            body.Parent = sc
        end)
    end

    local function readerSearch(query)
        urlField.Text = "sense://search?q=" .. query
        statusText('Searching "' .. query .. '" … (reader mode)')
        task.spawn(function()
            local html = Util.httpGet("https://html.duckduckgo.com/html/?q=" .. urlencode(query))
            if Browser._gui ~= gui then return end
            if not html then statusText("Search failed (network blocked).") return end
            local results = parseDDG(html)
            if #results == 0 then statusText('No results for "' .. query .. '".') return end
            local sc = makeScroll()
            for _, r in ipairs(results) do
                local row = Instance.new("TextButton")
                row.Text = ""; row.AutoButtonColor = false
                row.Size = UDim2.new(1, 0, 0, 0); row.AutomaticSize = Enum.AutomaticSize.Y
                row.BackgroundTransparency = 1; row.ZIndex = 4; row.Parent = sc
                local rp = Instance.new("UIPadding")
                rp.PaddingTop = UDim.new(0, 4); rp.PaddingBottom = UDim.new(0, 6); rp.Parent = row
                local rl = Instance.new("UIListLayout"); rl.Padding = UDim.new(0, 2); rl.Parent = row
                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, 0, 0, 20); title.BackgroundTransparency = 1
                title.Font = Theme.fonts.title; title.TextSize = 15; title.TextColor3 = ACCENT
                title.TextXAlignment = Enum.TextXAlignment.Left; title.TextTruncate = Enum.TextTruncate.AtEnd
                title.Text = r.title; title.ZIndex = 5; title.LayoutOrder = 1; title.Parent = row
                local urll = Instance.new("TextLabel")
                urll.Size = UDim2.new(1, 0, 0, 14); urll.BackgroundTransparency = 1
                urll.Font = Theme.fonts.caption; urll.TextSize = 11; urll.TextColor3 = Color3.fromRGB(110, 170, 120)
                urll.TextXAlignment = Enum.TextXAlignment.Left; urll.TextTruncate = Enum.TextTruncate.AtEnd
                urll.Text = r.url; urll.ZIndex = 5; urll.LayoutOrder = 2; urll.Parent = row
                row.MouseButton1Click:Connect(function() readerOpenPage(r.url) end)
            end
        end)
    end

    -- ===== Dispatcher =====
    function navigate(q)
        if q == nil or q == "" then return end
        local url
        if q:match("^https?://") then url = q
        elseif q:match("^[%w%-]+%.[%w%-%.]+") and not q:find("%s") then url = "https://" .. q
        else url = "https://www.google.com/search?q=" .. urlencode(q) end

        if connected then
            urlField.Text = url
            showLive(url)
            task.spawn(function() reqRaw("/nav?url=" .. urlencode(url)) end)
        else
            if q:match("^https?://") or (q:match("^[%w%-]+%.[%w%-%.]+") and not q:find("%s")) then
                readerOpenPage(url)
            else
                readerSearch(q)
            end
        end
    end

    -- ===== Homepage =====
    function showHomepage()
        if clockConn then clockConn:Disconnect(); clockConn = nil end
        clearContent()
        urlField.Text = "sense://homepage"

        local clock = Instance.new("TextLabel")
        clock.AnchorPoint = Vector2.new(1, 0)
        clock.Position = UDim2.new(1, -28, 0, 18)
        clock.Size = UDim2.fromOffset(140, 26)
        clock.BackgroundTransparency = 1
        clock.Font = Theme.fonts.title
        clock.TextSize = 20
        clock.TextColor3 = WHITE
        clock.TextXAlignment = Enum.TextXAlignment.Right
        clock.ZIndex = 4
        clock.Parent = content
        local function tick() clock.Text = (Util.date("%I:%M %p"):gsub("^0", "")) end
        tick()
        local acc = 0
        clockConn = RunService.Heartbeat:Connect(function(dt) acc += dt; if acc >= 5 then acc = 0; tick() end end)

        local logoWrap = Instance.new("Frame")
        logoWrap.Size = UDim2.fromOffset(96, 96)
        logoWrap.AnchorPoint = Vector2.new(0.5, 0.5)
        logoWrap.Position = UDim2.fromScale(0.5, 0.32)
        logoWrap.BackgroundTransparency = 1
        logoWrap.ZIndex = 4
        logoWrap.Parent = content
        local logoId = Util.remoteImage(LOGO_URL, "sense-logo.png")
        if logoId then
            local im = Instance.new("ImageLabel")
            im.Size = UDim2.fromScale(1, 1); im.BackgroundTransparency = 1; im.Image = logoId; im.ZIndex = 4; im.Parent = logoWrap
        else
            drawSaturn(logoWrap, 64, WHITE)
        end

        local searchWrap = Instance.new("Frame")
        searchWrap.Size = UDim2.fromOffset(460, 52)
        searchWrap.AnchorPoint = Vector2.new(0.5, 0.5)
        searchWrap.Position = UDim2.fromScale(0.5, 0.6)
        searchWrap.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
        searchWrap.BorderSizePixel = 0
        searchWrap.ZIndex = 4
        searchWrap.Parent = content
        Util.corner(searchWrap, 26)
        Util.stroke(searchWrap, WHITE, 1, 0.9)
        local mag = Instance.new("ImageLabel")
        mag.Size = UDim2.fromOffset(18, 18); mag.AnchorPoint = Vector2.new(0, 0.5)
        mag.Position = UDim2.new(0, 22, 0.5, 0); mag.BackgroundTransparency = 1; mag.ZIndex = 5; mag.Parent = searchWrap
        Icons.apply(mag, "search", DIM)
        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -64, 1, 0); searchBox.Position = UDim2.fromOffset(52, 0)
        searchBox.BackgroundTransparency = 1; searchBox.Font = Theme.fonts.body; searchBox.TextSize = 15
        searchBox.TextColor3 = WHITE; searchBox.PlaceholderText = "Search or enter URL"; searchBox.PlaceholderColor3 = DIM
        searchBox.Text = ""; searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus = false
        searchBox.ZIndex = 5; searchBox.Parent = searchWrap
        searchBox.FocusLost:Connect(function(enter) if enter and searchBox.Text ~= "" then navigate(searchBox.Text) end end)

        local links = {
            { name = "Google",    icon = "search",         url = "https://www.google.com",    col = Color3.fromRGB(66, 133, 244) },
            { name = "YouTube",   icon = "video",          url = "https://www.youtube.com",   col = Color3.fromRGB(255, 0, 0) },
            { name = "GitHub",    icon = "github",         url = "https://github.com",        col = Color3.fromRGB(60, 60, 66) },
            { name = "Wikipedia", icon = "book-open",      url = "https://www.wikipedia.org", col = Color3.fromRGB(120, 120, 128) },
            { name = "Reddit",    icon = "message-circle", url = "https://www.reddit.com",    col = Color3.fromRGB(255, 69, 0) },
        }
        local tileW, gap = 78, 14
        local total = #links * tileW + (#links - 1) * gap
        local startX = (content.AbsoluteSize.X > 0 and content.AbsoluteSize.X or W) / 2 - total / 2
        for i, lk in ipairs(links) do
            local t = Instance.new("TextButton")
            t.Text = ""; t.AutoButtonColor = false
            t.Size = UDim2.fromOffset(tileW, 76); t.AnchorPoint = Vector2.new(0, 1)
            t.Position = UDim2.new(0, startX + (i - 1) * (tileW + gap), 1, -28)
            t.BackgroundTransparency = 1; t.ZIndex = 4; t.Parent = content
            local circ = Instance.new("Frame")
            circ.Size = UDim2.fromOffset(48, 48); circ.AnchorPoint = Vector2.new(0.5, 0)
            circ.Position = UDim2.fromScale(0.5, 0); circ.BackgroundColor3 = lk.col; circ.BorderSizePixel = 0
            circ.ZIndex = 4; circ.Parent = t
            Util.corner(circ, 12)
            local g = Instance.new("ImageLabel")
            g.Size = UDim2.fromOffset(24, 24); g.AnchorPoint = Vector2.new(0.5, 0.5); g.Position = UDim2.fromScale(0.5, 0.5)
            g.BackgroundTransparency = 1; g.ZIndex = 5; g.Parent = circ
            Icons.apply(g, lk.icon, WHITE)
            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.fromOffset(tileW, 16); nm.AnchorPoint = Vector2.new(0.5, 1); nm.Position = UDim2.fromScale(0.5, 1)
            nm.BackgroundTransparency = 1; nm.Font = Theme.fonts.caption; nm.TextSize = 12; nm.TextColor3 = DIM
            nm.Text = lk.name; nm.ZIndex = 5; nm.Parent = t
            t.MouseButton1Click:Connect(function() navigate(lk.url) end)
        end
    end

    -- url bar + home
    urlField.FocusLost:Connect(function(enter)
        if enter and urlField.Text ~= "" then
            if urlField.Text == "sense://homepage" then showHomepage() else navigate(urlField.Text) end
        end
    end)
    homeBtn.MouseButton1Click:Connect(function()
        if connected then task.spawn(function() reqRaw("/back") end) end
        showHomepage()
    end)

    -- scroll forwarding while hovering the page (bridge mode)
    local hoveringContent = false
    content.MouseEnter:Connect(function() hoveringContent = true end)
    content.MouseLeave:Connect(function() hoveringContent = false end)
    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if connected and hoveringContent and input.UserInputType == Enum.UserInputType.MouseWheel then
            local dy = -input.Position.Z * 120
            task.spawn(function() reqRaw("/scroll?dy=" .. tostring(dy)) end)
        end
    end)

    -- drag window
    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = win.Position
        end
    end)
    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    conns[#conns + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    showHomepage()

    -- connect to the desktop app in the background
    task.spawn(function()
        connected = bridgeConnect()
        if Browser._gui ~= gui then return end
        if connected then
            status.Text = "● Connected to Sense Browser app"
            status.TextColor3 = OK_GREEN
        else
            status.Text = "○ Reader mode (open the app for full browsing)"
            status.TextColor3 = DIM
        end
    end)

    return { close = close }
end

return Browser
end)

SYNC.define("os/Desktop", function()
-- SYNC / os / Desktop
-- The desktop you land on after choosing "Desktop": a wallpaper plus the dock.
-- Menu bar and windows come next. Desktop.start() -> { destroy }.

local Util     = SYNC.import("core/Util")
local Dock     = SYNC.import("os/Dock")
local Settings = SYNC.import("os/Settings")
local MenuBar  = SYNC.import("os/MenuBar")
local Browser  = SYNC.import("os/Browser")

local Desktop = {}

function Desktop.start()
    -- No wallpaper: the menu bar + dock float over the actual game screen.
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Desktop"
    Util.mount(gui)

    -- Menu bar hidden for now (module kept for later): local menubar = MenuBar.create(gui)
    local menubar = nil

    local dock
    dock = Dock.create(gui, function(appName)
        if appName == "Sense Browser" then
            Browser.open()
        elseif appName == "Settings" then
            Settings.open({
                position = dock.getPosition(),
                onPosition = function(p)
                    dock.setPosition(p)
                    Util.save("DockPosition", p)
                end,
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
-- macOS-style dock with cursor-proximity magnification, auto-hide, launch bounce,
-- and three screen positions (Bottom / Left / Right). The dock relayouts to the
-- chosen edge: bottom = horizontal, left/right = vertical. Size + magnification
-- are adjustable and persisted. Dock.create(parent, onAppClick) -> { ... }.

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Dock = {}

local WHITE = Color3.fromRGB(255, 255, 255)

local BASE_DEFAULT = 52
local GAP          = 14
local INFLUENCE    = 150
local MARGIN       = 14   -- gap from the screen edge
local PADX         = 12   -- dock inner padding along its length
local PADY         = 8    -- dock inner padding across its thickness
local BOUNCE_AMP   = 28
local BOUNCE_DUR   = 0.5
local REVEAL_PX    = 4
local TOP_INSET    = 30   -- leave room for the menu bar (vertical docks)

local APPS = {
    { name = "Finder",    icon = "folder",         top = Color3.fromRGB(70, 170, 255),  bot = Color3.fromRGB(20, 110, 230) },
    { name = "Sense Browser", icon = "orbit",      top = Color3.fromRGB(90, 200, 255),  bot = Color3.fromRGB(20, 120, 235) },
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
    holder.Size = UDim2.fromOffset(BASE_DEFAULT, BASE_DEFAULT)
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
    corner.CornerRadius = UDim.new(0.2237, 0)
    corner.Parent = tile
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(app.top, app.bot)
    grad.Rotation = 90
    grad.Parent = tile
    Util.stroke(tile, WHITE, 1, 0.86)

    local glyph = Instance.new("ImageLabel")
    glyph.Size = UDim2.fromScale(0.56, 0.56)
    glyph.AnchorPoint = Vector2.new(0.5, 0.5)
    glyph.Position = UDim2.fromScale(0.5, 0.5)
    glyph.BackgroundTransparency = 1
    glyph.ZIndex = 7
    glyph.Parent = tile
    Icons.apply(glyph, app.icon, app.dark and Color3.fromRGB(40, 40, 46) or WHITE)

    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.new(0.5, 0, 0, -10)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Size = UDim2.fromOffset(0, 22)
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

    return {
        holder = holder, label = label, lstroke = lstroke, app = app.name,
        size = BASE_DEFAULT, bounceStart = nil, restCenter = 0, centerMain = 0,
        pressed = false, labelShown = false,
    }
end

function Dock.create(parent, onAppClick)
    local vp = Util.viewport()

    -- Dock bar
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    bar.BackgroundTransparency = 0.22
    bar.BorderSizePixel = 0
    bar.ZIndex = 5
    bar.Parent = parent
    Util.corner(bar, 22)
    Util.stroke(bar, WHITE, 1, 0.86)
    Util.shadow(bar, { blur = 36, spread = 0, transparency = 0.55, offset = UDim2.fromOffset(0, 10) })

    local icons = {}
    for _, app in ipairs(APPS) do
        icons[#icons + 1] = buildIcon(parent, app)
    end

    -- Persisted, live-editable state
    local function clamp01(x) return math.clamp(x, 0, 1) end
    local baseSize = math.floor(40 + clamp01(tonumber(Util.load("DockSizeFrac")) or 0.4) * 32 + 0.5)
    local magScale = 1.0 + clamp01(tonumber(Util.load("DockMagFrac")) or 0.55) * 1.4
    local pos = Util.load("DockPosition") or "bottom"
    local alwaysShow = Util.load("DockAlwaysShow") == "true"

    local shown = false
    local curOff = 200
    local offVel = 0

    -- Press feedback + click (labels handled in the loop)
    for _, ic in ipairs(icons) do
        ic.holder.MouseButton1Down:Connect(function() ic.pressed = true end)
        ic.holder.MouseButton1Up:Connect(function() ic.pressed = false end)
        ic.holder.MouseLeave:Connect(function() ic.pressed = false end)
        ic.holder.MouseButton1Click:Connect(function()
            ic.bounceStart = tick()
            if onAppClick then onAppClick(ic.app) end
        end)
    end

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        local m = UserInputService:GetMouseLocation()
        local mouseX, mouseY = m.X, m.Y
        local alpha = 1 - math.exp(-dt * 16)

        local BASE = baseSize
        local MAX = baseSize * magScale
        local thickness = BASE + PADY * 2
        local isV = (pos ~= "bottom")
        local mainCenter = isV and (TOP_INSET + (vp.Y - TOP_INSET) / 2) or (vp.X / 2)
        local cursorMain = isV and mouseY or mouseX

        -- Reveal / hide / near-dock checks per edge
        local revealHit, hideAway, nearDock
        if pos == "bottom" then
            revealHit = mouseY >= vp.Y - REVEAL_PX
            hideAway  = mouseY < vp.Y - (MAX + 40)
            nearDock  = mouseY >= (vp.Y - thickness - MARGIN) - 30
        elseif pos == "left" then
            revealHit = mouseX <= REVEAL_PX
            hideAway  = mouseX > (MAX + 40)
            nearDock  = mouseX <= (MARGIN + thickness) + 30
        else -- right
            revealHit = mouseX >= vp.X - REVEAL_PX
            hideAway  = mouseX < vp.X - (MAX + 40)
            nearDock  = mouseX >= (vp.X - MARGIN - thickness) - 30
        end

        if alwaysShow then shown = true
        elseif not shown then if revealHit then shown = true end
        else if hideAway then shown = false end end

        local hideOffset = thickness + 40
        local sdt = math.min(dt, 1 / 30)
        local targetOff = shown and 0 or hideOffset
        offVel = offVel + (-220 * (curOff - targetOff) - 26 * offVel) * sdt
        curOff = curOff + offVel * sdt

        local magnifyActive = shown and nearDock

        -- Resting centers along the main axis
        local restingLen = #icons * BASE + (#icons - 1) * GAP
        local restStart = mainCenter - restingLen / 2
        for i, ic in ipairs(icons) do
            ic.restCenter = restStart + (i - 1) * (BASE + GAP) + BASE / 2
        end

        -- Magnified sizes
        for _, ic in ipairs(icons) do
            local target = BASE
            if magnifyActive then
                local d = math.abs(cursorMain - ic.restCenter)
                if d < INFLUENCE then
                    local f = math.cos((d / INFLUENCE) * (math.pi / 2))
                    f = f * f * (3 - 2 * f)
                    target = BASE + (MAX - BASE) * f
                end
            end
            if ic.pressed then target = target * 0.9 end
            ic.size = ic.size + (target - ic.size) * alpha
        end

        -- Lay out along the main axis
        local W = GAP * (#icons - 1)
        for _, ic in ipairs(icons) do W += ic.size end
        local accM = mainCenter - W / 2

        local baseBottomY = vp.Y - MARGIN - PADY
        local baseLeftX   = MARGIN + PADY
        local baseRightX  = vp.X - MARGIN - PADY

        for _, ic in ipairs(icons) do
            local cm = accM + ic.size / 2
            ic.centerMain = cm
            local bounce = 0
            if ic.bounceStart then
                local t = tick() - ic.bounceStart
                if t < BOUNCE_DUR then bounce = BOUNCE_AMP * math.sin((t / BOUNCE_DUR) * math.pi)
                else ic.bounceStart = nil end
            end
            local interior = (ic.size - BASE) * 0.16 + bounce
            ic.holder.Size = UDim2.fromOffset(ic.size, ic.size)

            if pos == "bottom" then
                ic.holder.AnchorPoint = Vector2.new(0.5, 1)
                ic.holder.Position = UDim2.fromOffset(cm, baseBottomY + curOff - interior)
                ic.label.AnchorPoint = Vector2.new(0.5, 1)
                ic.label.Position = UDim2.new(0.5, 0, 0, -8)
            elseif pos == "left" then
                ic.holder.AnchorPoint = Vector2.new(0, 0.5)
                ic.holder.Position = UDim2.fromOffset(baseLeftX - curOff + interior, cm)
                ic.label.AnchorPoint = Vector2.new(0, 0.5)
                ic.label.Position = UDim2.new(1, 8, 0.5, 0)
            else -- right
                ic.holder.AnchorPoint = Vector2.new(1, 0.5)
                ic.holder.Position = UDim2.fromOffset(baseRightX + curOff - interior, cm)
                ic.label.AnchorPoint = Vector2.new(1, 0.5)
                ic.label.Position = UDim2.new(0, -8, 0.5, 0)
            end
            accM += ic.size + GAP
        end

        -- Labels (poll-based)
        local hovered = nil
        if magnifyActive then
            for _, ic in ipairs(icons) do
                if cursorMain >= ic.centerMain - ic.size / 2 and cursorMain <= ic.centerMain + ic.size / 2 then
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

        -- Bar wraps the icons on the chosen edge
        local lengthPx = W + PADX * 2
        if pos == "bottom" then
            bar.AnchorPoint = Vector2.new(0.5, 1)
            bar.Size = UDim2.fromOffset(lengthPx, thickness)
            bar.Position = UDim2.fromOffset(mainCenter, (vp.Y - MARGIN) + curOff)
        elseif pos == "left" then
            bar.AnchorPoint = Vector2.new(0, 0.5)
            bar.Size = UDim2.fromOffset(thickness, lengthPx)
            bar.Position = UDim2.fromOffset(MARGIN - curOff, mainCenter)
        else -- right
            bar.AnchorPoint = Vector2.new(1, 0.5)
            bar.Size = UDim2.fromOffset(thickness, lengthPx)
            bar.Position = UDim2.fromOffset((vp.X - MARGIN) + curOff, mainCenter)
        end
    end)

    return {
        setAlwaysShow = function(v) alwaysShow = v and true or false end,
        setDockSize = function(f) baseSize = math.floor(40 + clamp01(f) * 32 + 0.5) end,
        setMagnification = function(f) magScale = 1.0 + clamp01(f) * 1.4 end,
        setPosition = function(p)
            pos = p
            shown = false
            curOff = baseSize + PADY * 2 + 40
            offVel = 0
        end,
        getDockFrac = function() return (baseSize - 40) / 32 end,
        getMagFrac = function() return (magScale - 1.0) / 1.4 end,
        getPosition = function() return pos end,
        destroy = function()
            if conn then conn:Disconnect() end
            bar:Destroy()
            for _, ic in ipairs(icons) do ic.holder:Destroy() end
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
local DIM   = Color3.fromRGB(236, 236, 240)
local HEIGHT = 24
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
    bar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    bar.BackgroundTransparency = 0.3 -- liquid glass: fairly translucent
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

    -- Order matches macOS (left to right): search, wifi, battery, control center, clock
    statusIcon(right, 1, "search")
    statusIcon(right, 2, "wifi")
    statusIcon(right, 3, "battery-full")
    statusIcon(right, 4, "sliders-horizontal") -- control center

    local clockBtn = statusItem(right, 5, 150)
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
        -- macOS US default: 12-hour with AM/PM, e.g. "Sat Jun 28  9:41 AM"
        local s = Util.date("%a %b %d  %I:%M %p")
        clock.Text = (s:gsub("  0(%d)", "  %1")) -- trim leading zero on the hour
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

    local cardW, cardH = 440, 278
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
