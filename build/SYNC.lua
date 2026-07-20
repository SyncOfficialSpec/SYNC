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

-- Whether a real request() API (headers/POST capable) is available.
function Util.hasRequest() return _req ~= nil end

-- Drive a ScrollingFrame's CanvasSize from its layout's content size. Replaces
-- AutomaticCanvasSize, which some executors' Roblox builds lack (it throws as
-- "not a valid member of Enum"). axis = "Y" (default) or "X". Order-independent:
-- it waits for the layout to exist, so call it any time.
function Util.autoCanvas(scroll, axis)
    axis = axis or "Y"
    task.spawn(function()
        local layout
        for _ = 1, 120 do
            layout = scroll:FindFirstChildOfClass("UIListLayout") or scroll:FindFirstChildOfClass("UIGridLayout")
            if layout then break end
            task.wait()
        end
        if not layout then return end
        local function upd()
            local cs = layout.AbsoluteContentSize
            scroll.CanvasSize = (axis == "X") and UDim2.fromOffset(cs.X + 8, 0)
                or UDim2.fromOffset(0, cs.Y + 8)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
        upd()
    end)
end

-- GET with custom headers (e.g. an API key). Returns (body, statusCode).
function Util.httpGetH(url, headers)
    if not _req then
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        return (ok and res) or nil, ok and 200 or 0
    end
    local h = { ["User-Agent"] = UA }
    if headers then for k, v in pairs(headers) do h[k] = v end end
    local ok, res = pcall(_req, { Url = url, Method = "GET", Headers = h })
    if ok and res and res.Body then return res.Body, res.StatusCode or 0 end
    return nil, 0
end

-- POST JSON via the executor request API. Returns (ok, statusCode, body).
-- Needs an executor that exposes request/syn.request (no game:HttpPost fallback
-- since that requires HttpService:RequestAsync which executors usually block).
function Util.httpPost(url, headers, body)
    if not _req then return false, 0, nil end
    local h = { ["Content-Type"] = "application/json", ["User-Agent"] = UA }
    if headers then for k, v in pairs(headers) do h[k] = v end end
    local ok, res = pcall(_req, { Url = url, Method = "POST", Headers = h, Body = body or "" })
    if not ok or not res then return false, 0, nil end
    return (res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300) or false,
        res.StatusCode or 0, res.Body
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
-- Branded loading screen v3 ("system boot"): minimal black layout — tri-blade
-- SYNC mark + spaced wordmark + rainbow hairline on the left, a center divider
-- that grows out of a glowing node, and a segmented tick-bar progress with a
-- live percent + status labels on the right. Corner brackets, monospace status
-- row bottom-left, STAND BY dot-chase bottom-right.
-- Fancy visuals stay baked PNGs (logo mark, halo glow) — reliable everywhere.
-- Open/close are fully choreographed; exit ends in a crossfade handoff (the
-- next screen builds under the black veil while it lifts).
-- Boot.run(onDone) plays, fades out, calls onDone().

local RunService = game:GetService("RunService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Boot = {}

local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"
-- getcustomasset caches by file path on many executors: new art = new filename.
local ASSETS = {
    logo = { url = RAW .. "boot-logo.png", file = "sync_boot3_logo.png" },
    halo = { url = RAW .. "boot-halo.png", file = "sync_boot2_halo.png" },
}

local GOOGLE = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(66, 133, 244)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(234, 67, 53)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(251, 188, 5)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(52, 168, 83)),
})

local WHITE  = Color3.fromRGB(245, 245, 247)
local ACCENT = Color3.fromRGB(120, 140, 255) -- soft blue-violet (bullet, ">", dots)

-- "S Y N C"-style letter spacing; original spaces become wide word gaps
local function spaced(s)
    return (s:gsub("(.)", "%1 "):gsub(" $", ""))
end

function Boot.run(onDone)
    local vp = Util.viewport()
    local S = math.clamp(vp.Y / 1080, 0.45, 1.7)
    local function px(n) return math.floor(n * S + 0.5) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Boot"
    Util.mount(gui)

    local screen = Instance.new("Frame")
    screen.Size = UDim2.fromScale(1, 1)
    screen.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
    screen.BorderSizePixel = 0
    screen.BackgroundTransparency = 1
    screen.Parent = gui
    Util.tween(screen, { BackgroundTransparency = 0 }, 0.55, Enum.EasingStyle.Sine)

    local alive   = true
    local closing = false
    local QUINT, QUAD, SINE = Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Sine
    local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In

    -- -----------------------------------------------------------------------
    -- Corner brackets: slide out of the corners on open, retract on close.
    -- -----------------------------------------------------------------------
    local bracketBars = {}
    for ci, c in ipairs({ {0,0}, {1,0}, {0,1}, {1,1} }) do
        local ax, ay = c[1], c[2]
        local inset, blen = px(30), px(26)
        local ox = ax == 0 and inset or -inset
        local oy = ay == 0 and inset or -inset
        local rx = ax == 0 and inset - px(14) or -(inset - px(14))
        local ry = ay == 0 and inset - px(14) or -(inset - px(14))
        for _, bar in ipairs({ { blen, 2 }, { 2, blen } }) do
            local f = Instance.new("Frame")
            f.Size = UDim2.fromOffset(bar[1], bar[2])
            f.AnchorPoint = Vector2.new(ax, ay)
            f.Position = UDim2.new(ax, rx, ay, ry)
            f.BackgroundColor3 = WHITE
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Parent = screen
            bracketBars[#bracketBars + 1] = {
                inst = f,
                finalPos = UDim2.new(ax, ox, ay, oy),
                retractPos = UDim2.new(ax, rx, ay, ry),
            }
            task.delay(0.12 + ci * 0.05, function()
                if alive and not closing then
                    Util.tween(f, { Position = UDim2.new(ax, ox, ay, oy), BackgroundTransparency = 0.5 },
                        0.6, QUINT, OUT)
                end
            end)
        end
    end

    -- -----------------------------------------------------------------------
    -- Left block: logo mark, spaced wordmark, rainbow hairline, tagline.
    -- Each rises ~14px while fading in, staggered.
    -- -----------------------------------------------------------------------
    local left = Instance.new("Frame")
    left.Size = UDim2.fromOffset(px(560), px(230))
    left.Position = UDim2.new(0.10, 0, 0.483, 0)
    left.AnchorPoint = Vector2.new(0, 0.5)
    left.BackgroundTransparency = 1
    left.Parent = screen

    local logo -- ImageLabel, created when the asset arrives
    task.spawn(function()
        local id = Util.remoteImage(ASSETS.logo.url, ASSETS.logo.file)
        if not (id and alive) or closing then return end
        logo = Instance.new("ImageLabel")
        logo.Size = UDim2.fromOffset(px(74), px(74))
        logo.Position = UDim2.fromOffset(0, px(14))
        logo.BackgroundTransparency = 1
        logo.Image = id
        logo.ScaleType = Enum.ScaleType.Fit
        logo.ImageTransparency = 1
        logo.Rotation = -25
        logo.Parent = left
        Util.tween(logo, { ImageTransparency = 0, Rotation = 0, Position = UDim2.fromOffset(0, 0) },
            0.9, QUINT, OUT)
        -- subtle idle breathing
        local sc = Instance.new("UIScale")
        sc.Parent = logo
        task.spawn(function()
            while alive and not closing and logo.Parent do
                Util.tween(sc, { Scale = 1.04 }, 1.9, SINE, Enum.EasingDirection.InOut)
                task.wait(1.95)
                if not alive or closing then break end
                Util.tween(sc, { Scale = 1.0 }, 1.9, SINE, Enum.EasingDirection.InOut)
                task.wait(1.95)
            end
        end)
    end)

    local function riser(parent, finalY, delay, build)
        local inst = build()
        inst.Position = UDim2.fromOffset(0, finalY + px(14))
        inst.Parent = parent
        task.delay(delay, function()
            if alive and not closing then
                local props = { Position = UDim2.fromOffset(0, finalY) }
                if inst:IsA("TextLabel") then props.TextTransparency = 0
                else props.BackgroundTransparency = 0 end
                Util.tween(inst, props, 0.65, QUINT, OUT)
            end
        end)
        return inst
    end

    local wordmark = riser(left, px(91), 0.38, function()
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, px(52))
        l.BackgroundTransparency = 1
        l.Font = Theme.fonts.title
        l.Text = spaced("SYNC")
        l.TextSize = px(46)
        l.TextColor3 = Color3.fromRGB(240, 240, 244)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTransparency = 1
        return l
    end)

    -- rainbow hairline: sweeps its width open after the wordmark lands
    local underline = Instance.new("Frame")
    underline.Size = UDim2.fromOffset(0, math.max(px(2), 2))
    underline.Position = UDim2.fromOffset(0, px(176))
    underline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    underline.BorderSizePixel = 0
    underline.Parent = left
    local ug = Instance.new("UIGradient")
    ug.Color = GOOGLE
    ug.Parent = underline
    task.delay(0.62, function()
        if alive and not closing then
            Util.tween(underline, { Size = UDim2.fromOffset(px(96), math.max(px(2), 2)) }, 0.6, QUINT, OUT)
        end
    end)

    local tagline = riser(left, px(200), 0.7, function()
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, px(22))
        l.BackgroundTransparency = 1
        l.Font = Theme.fonts.caption
        l.Text = spaced("your desktop, reimagined")
        l.TextSize = px(17)
        l.TextColor3 = Color3.fromRGB(140, 140, 146)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTransparency = 1
        return l
    end)

    -- -----------------------------------------------------------------------
    -- Center divider: grows out of the glowing node, faded at both ends.
    -- -----------------------------------------------------------------------
    local NODE_Y = 0.497
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, math.max(px(2), 1), 0, 0)
    line.Position = UDim2.fromScale(0.5, NODE_Y)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = Color3.fromRGB(200, 200, 208)
    line.BackgroundTransparency = 0.55
    line.BorderSizePixel = 0
    line.Parent = screen
    local lg = Instance.new("UIGradient")
    lg.Rotation = 90
    lg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 1),
        NumberSequenceKeypoint.new(0.14, 0.25),
        NumberSequenceKeypoint.new(0.86, 0.25),
        NumberSequenceKeypoint.new(1.00, 1),
    })
    lg.Parent = line
    task.delay(0.3, function()
        if alive and not closing then
            Util.tween(line, { Size = UDim2.new(0, math.max(px(2), 1), 0.67, 0) }, 1.0, QUINT, OUT)
        end
    end)

    local nodeGlow, nodeDot
    task.spawn(function()
        local haloId = Util.remoteImage(ASSETS.halo.url, ASSETS.halo.file)
        if not alive or closing then return end
        if haloId then
            nodeGlow = Instance.new("ImageLabel")
            nodeGlow.Size = UDim2.fromOffset(px(52), px(52))
            nodeGlow.Position = UDim2.fromScale(0.5, NODE_Y)
            nodeGlow.AnchorPoint = Vector2.new(0.5, 0.5)
            nodeGlow.BackgroundTransparency = 1
            nodeGlow.Image = haloId
            nodeGlow.ImageTransparency = 1
            nodeGlow.Parent = screen
            Util.tween(nodeGlow, { ImageTransparency = 0.25 }, 0.8, SINE)
        end
        nodeDot = Instance.new("Frame")
        nodeDot.Size = UDim2.fromOffset(px(8), px(8))
        nodeDot.Position = UDim2.fromScale(0.5, NODE_Y)
        nodeDot.AnchorPoint = Vector2.new(0.5, 0.5)
        nodeDot.BackgroundColor3 = Color3.fromRGB(250, 250, 255)
        nodeDot.BackgroundTransparency = 1
        nodeDot.BorderSizePixel = 0
        nodeDot.Parent = screen
        Util.corner(nodeDot, px(8))
        Util.tween(nodeDot, { BackgroundTransparency = 0 }, 0.6, SINE)
        -- gentle glow pulse
        while alive and not closing and nodeGlow and nodeGlow.Parent do
            Util.tween(nodeGlow, { ImageTransparency = 0.55 }, 1.6, SINE, Enum.EasingDirection.InOut)
            task.wait(1.65)
            if not alive or closing then break end
            Util.tween(nodeGlow, { ImageTransparency = 0.25 }, 1.6, SINE, Enum.EasingDirection.InOut)
            task.wait(1.65)
        end
    end)

    -- -----------------------------------------------------------------------
    -- Right block: status label + segmented tick bar + percent.
    -- -----------------------------------------------------------------------
    local right = Instance.new("Frame")
    right.Size = UDim2.fromOffset(px(640), px(96))
    right.Position = UDim2.new(0.5625, 0, NODE_Y, 0)
    right.AnchorPoint = Vector2.new(0, 0.5)
    right.BackgroundTransparency = 1
    right.Parent = screen

    local bullet = Instance.new("Frame")
    bullet.Size = UDim2.fromOffset(px(7), px(7))
    bullet.Position = UDim2.fromOffset(0, px(21))
    bullet.BackgroundColor3 = ACCENT
    bullet.BackgroundTransparency = 1
    bullet.BorderSizePixel = 0
    bullet.Parent = right
    Util.corner(bullet, px(7))

    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(px(500), px(20))
    status.Position = UDim2.fromOffset(px(18), px(14))
    status.BackgroundTransparency = 1
    status.Font = Theme.fonts.caption
    status.Text = spaced("LOADING SYSTEM FILES")
    status.TextSize = px(15)
    status.TextColor3 = Color3.fromRGB(225, 225, 232)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTransparency = 1
    status.Parent = right
    task.delay(0.55, function()
        if alive and not closing then
            Util.tween(bullet, { BackgroundTransparency = 0 }, 0.5, SINE)
            Util.tween(status, { TextTransparency = 0 }, 0.5, SINE)
        end
    end)

    -- tick bar: 46 segments, cascade in left-to-right
    local N, TW, TH, GAP = 46, math.max(px(4), 2), px(15), px(6)
    local PITCH = TW + GAP
    local BARY = px(48)
    local ticks, tickColors = {}, {}
    local UNLIT = Color3.fromRGB(52, 52, 58)
    for i = 1, N do
        local v = 0.72 + 0.28 * math.abs(math.sin(i * 1.7))
        tickColors[i] = Color3.fromRGB(
            math.floor(170 + 60 * v), math.floor(180 + 55 * v), math.floor(240 + 15 * v))
        local t = Instance.new("Frame")
        t.Size = UDim2.fromOffset(TW, TH)
        t.Position = UDim2.fromOffset((i - 1) * PITCH, BARY)
        t.BackgroundColor3 = UNLIT
        t.BackgroundTransparency = 1
        t.BorderSizePixel = 0
        t.Parent = right
        ticks[i] = t
        task.delay(0.62 + i * 0.014, function()
            if alive and not closing then Util.tween(t, { BackgroundTransparency = 0 }, 0.3, SINE) end
        end)
    end

    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.fromOffset(px(90), px(20))
    pct.Position = UDim2.fromOffset(N * PITCH + px(18), BARY - px(2))
    pct.BackgroundTransparency = 1
    pct.Font = Enum.Font.Code
    pct.Text = spaced("0%")
    pct.TextSize = px(15)
    pct.TextColor3 = Color3.fromRGB(210, 210, 216)
    pct.TextXAlignment = Enum.TextXAlignment.Left
    pct.TextTransparency = 1
    pct.Parent = right
    task.delay(1.0, function()
        if alive and not closing then Util.tween(pct, { TextTransparency = 0 }, 0.5, SINE) end
    end)

    -- -----------------------------------------------------------------------
    -- Bottom rows: "> status" left, "STAND BY · · ·" right.
    -- -----------------------------------------------------------------------
    local chevron = Instance.new("TextLabel")
    chevron.Size = UDim2.fromOffset(px(16), px(18))
    chevron.Position = UDim2.new(0, px(56), 1, -px(66))
    chevron.BackgroundTransparency = 1
    chevron.Font = Enum.Font.Code
    chevron.Text = ">"
    chevron.TextSize = px(15)
    chevron.TextColor3 = ACCENT
    chevron.TextXAlignment = Enum.TextXAlignment.Left
    chevron.TextTransparency = 1
    chevron.Parent = screen

    local bootlog = Instance.new("TextLabel")
    bootlog.Size = UDim2.fromOffset(px(520), px(18))
    bootlog.Position = UDim2.new(0, px(76), 1, -px(66))
    bootlog.BackgroundTransparency = 1
    bootlog.Font = Enum.Font.Code
    bootlog.Text = spaced("initializing")
    bootlog.TextSize = px(14)
    bootlog.TextColor3 = Color3.fromRGB(130, 130, 138)
    bootlog.TextXAlignment = Enum.TextXAlignment.Left
    bootlog.TextTransparency = 1
    bootlog.Parent = screen

    local standby = Instance.new("TextLabel")
    standby.Size = UDim2.fromOffset(px(160), px(18))
    standby.Position = UDim2.new(1, -px(150), 1, -px(66))
    standby.AnchorPoint = Vector2.new(1, 0)
    standby.BackgroundTransparency = 1
    standby.Font = Theme.fonts.caption
    standby.Text = spaced("STAND BY")
    standby.TextSize = px(14)
    standby.TextColor3 = Color3.fromRGB(170, 170, 178)
    standby.TextXAlignment = Enum.TextXAlignment.Right
    standby.TextTransparency = 1
    standby.Parent = screen

    local sbDots = {}
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(px(7), px(7))
        dot.Position = UDim2.new(1, -px(134) + i * px(22), 1, -px(61))
        dot.BackgroundColor3 = ACCENT
        dot.BackgroundTransparency = 1
        dot.BorderSizePixel = 0
        dot.Parent = screen
        Util.corner(dot, px(7))
        sbDots[i] = dot
    end
    task.delay(0.9, function()
        if not alive or closing then return end
        Util.tween(chevron, { TextTransparency = 0 }, 0.5, SINE)
        Util.tween(bootlog, { TextTransparency = 0 }, 0.5, SINE)
        Util.tween(standby, { TextTransparency = 0 }, 0.5, SINE)
        -- dot chase
        task.spawn(function()
            local i = 0
            while alive and not closing do
                i = i % 3 + 1
                for j, dot in ipairs(sbDots) do
                    if dot.Parent then
                        Util.tween(dot, { BackgroundTransparency = j == i and 0.1 or 0.72 }, 0.35, SINE)
                    end
                end
                task.wait(0.45)
            end
        end)
    end)

    -- -----------------------------------------------------------------------
    -- Progress engine: exponential smoothing toward per-step targets, ticks
    -- light up as it moves, head tick burns white, percent counts live.
    -- -----------------------------------------------------------------------
    local target, current = 0, 0
    task.spawn(function()
        local lastLit, lastPct = -1, -1
        while alive and right.Parent do
            local dt = RunService.RenderStepped:Wait()
            current = current + (target - current) * (1 - math.exp(-dt * 3.0))
            if target >= 1 and current > 0.996 then current = 1 end
            local lit = math.floor(current * N + 0.5)
            if lit ~= lastLit then
                for i = 1, N do
                    ticks[i].BackgroundColor3 = i <= lit and tickColors[i] or UNLIT
                end
                lastLit = lit
            end
            if lit > 0 and lit <= N then
                ticks[lit].BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- burning head
            end
            local p = math.floor(current * 100 + 0.5)
            if p ~= lastPct then
                pct.Text = spaced(p .. "%")
                lastPct = p
            end
        end
    end)

    -- -----------------------------------------------------------------------
    -- Boot cadence -> choreographed exit -> crossfade handoff.
    -- -----------------------------------------------------------------------
    task.spawn(function()
        task.wait(1.15) -- let the stage assemble first
        local steps = {
            { p = 0.22, wait = 1.00, status = "LOADING SYSTEM FILES", log = "initializing" },
            { p = 0.45, wait = 1.05, status = "MOUNTING DOCK",        log = "mounting dock" },
            { p = 0.68, wait = 1.00, status = "SYNCING APPS",         log = "syncing apps" },
            { p = 0.88, wait = 0.95, status = "CALIBRATING CURSOR",   log = "calibrating cursor" },
            { p = 1.00, wait = 1.05, status = "READY",                log = "ready." },
        }
        for _, s in ipairs(steps) do
            status.Text = spaced(s.status)
            bootlog.Text = spaced(s.log)
            target = s.p
            task.wait(s.wait)
        end
        task.wait(0.3)

        -- ---- exit choreography ----
        closing = true

        -- 1. ticks cascade out right-to-left, label/pct slide right
        for i = N, 1, -1 do
            task.delay((N - i) * 0.008, function()
                if ticks[i].Parent then Util.tween(ticks[i], { BackgroundTransparency = 1 }, 0.25, SINE) end
            end)
        end
        Util.tween(status, { Position = UDim2.fromOffset(px(34), px(14)), TextTransparency = 1 }, 0.4, QUAD, IN)
        Util.tween(bullet, { BackgroundTransparency = 1 }, 0.3, SINE)
        Util.tween(pct, { TextTransparency = 1 }, 0.35, QUAD, IN)
        task.wait(0.12)

        -- 2. left block slides out left, bottom-up
        Util.tween(tagline, { Position = tagline.Position - UDim2.fromOffset(px(18), 0), TextTransparency = 1 },
            0.35, QUAD, IN)
        task.wait(0.06)
        Util.tween(underline, { Size = UDim2.fromOffset(0, math.max(px(2), 2)) }, 0.4, QUINT, OUT)
        task.wait(0.06)
        Util.tween(wordmark, { Position = wordmark.Position - UDim2.fromOffset(px(22), 0), TextTransparency = 1 },
            0.4, QUAD, IN)
        task.wait(0.06)
        if logo then
            Util.tween(logo, { Position = logo.Position - UDim2.fromOffset(px(18), 0), ImageTransparency = 1, Rotation = 12 },
                0.45, QUAD, IN)
        end

        -- 3. bottom rows fade
        for _, l in ipairs({ chevron, bootlog, standby }) do
            Util.tween(l, { TextTransparency = 1 }, 0.35, QUAD, IN)
        end
        for _, dot in ipairs(sbDots) do
            Util.tween(dot, { BackgroundTransparency = 1 }, 0.3, SINE)
        end

        -- 4. the line collapses back into the node, the node flares then dies
        Util.tween(line, { Size = UDim2.new(0, math.max(px(2), 1), 0, 0) }, 0.6, QUINT, IN)
        if nodeGlow then Util.tween(nodeGlow, { ImageTransparency = 0.05 }, 0.3, SINE) end
        task.delay(0.35, function()
            if nodeGlow then Util.tween(nodeGlow, { ImageTransparency = 1 }, 0.45, SINE) end
            if nodeDot then Util.tween(nodeDot, { BackgroundTransparency = 1 }, 0.4, SINE) end
        end)

        -- 5. brackets retract
        for _, b in ipairs(bracketBars) do
            Util.tween(b.inst, { Position = b.retractPos, BackgroundTransparency = 1 }, 0.4, QUAD, IN)
        end

        -- 6. crossfade handoff: raise the veil, start the next screen under it
        task.wait(0.45)
        gui.DisplayOrder = 1000000
        if onDone then task.spawn(onDone) end
        Util.tween(screen, { BackgroundTransparency = 1 }, 0.85, SINE, Enum.EasingDirection.InOut)
        task.wait(0.95)
        alive = false
        gui:Destroy()
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
local Home     = SYNC.import("apps/Home")

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
        if appName == "Home" then
            Home.open()
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
    { name = "Home",      icon = "app-window",     top = Color3.fromRGB(96, 170, 255),  bot = Color3.fromRGB(28, 110, 230) },
    { name = "Settings",  icon = "settings",       top = Color3.fromRGB(150, 152, 158), bot = Color3.fromRGB(90, 92, 98) },
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
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.78 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
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
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.78 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
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

SYNC.define("apps/Home", function()
-- SYNC / apps / Home
-- Home hub window: welcome header with live clock, session stats
-- (players / ping / uptime), profile card with in-game chat, and Friend
-- Activity ported from orca (github.com/richie0866/orca): online friends
-- grouped by the game they're playing, click a friend to join their server.

local Players            = game:GetService("Players")
local StatsService       = game:GetService("Stats")
local TeleportService    = game:GetService("TeleportService")
local TextChatService    = game:GetService("TextChatService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService        = game:GetService("HttpService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Home = {}

local WHITE  = Color3.fromRGB(255, 255, 255)
local SUB    = Color3.fromRGB(150, 150, 158)
local WIN    = Color3.fromRGB(24, 25, 29)
local BAR    = Color3.fromRGB(38, 38, 44)
local CARD   = Color3.fromRGB(34, 35, 40)
local FIELD  = Color3.fromRGB(46, 47, 53)
local ACCENT = Theme.accent
local GREEN  = Color3.fromRGB(52, 199, 89)

Home._gui = nil

local function headshot(userId, size)
    return ("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d"):format(userId, size, size)
end

function Home.open()
    -- Stale guard: the gui may have been destroyed externally (respawn, cleanup)
    if Home._gui and Home._gui.Parent then return end
    Home._gui = nil

    local lp = Util.localPlayer()
    local winW, winH = 780, 560
    local TB = 40

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Home"
    Util.mount(gui)
    Home._gui = gui

    local alive = true
    local conns = {}

    local function close()
        if not Home._gui then return end
        Home._gui = nil
        alive = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
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

    -- Window
    local win = Instance.new("TextButton")
    win.Text = ""
    win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(winW, winH)
    win.BackgroundColor3 = WIN
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 14)
    Util.stroke(win, WHITE, 1, 0.85)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })

    -- Entrance: quick scale + fade in
    local scaleFx = Instance.new("UIScale")
    scaleFx.Scale = 0.94
    scaleFx.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleFx, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0.02 }, 0.18)

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = BAR
    bar.BackgroundTransparency = 0.25
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local barCorner = Instance.new("UICorner")
    local okCorner = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 14)
        barCorner.TopRightRadius = UDim.new(0, 14)
        barCorner.BottomLeftRadius = UDim.new(0, 0)
        barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okCorner then barCorner.CornerRadius = UDim.new(0, 14) end
    barCorner.Parent = bar
    local hair = Instance.new("Frame")
    hair.Size = UDim2.new(1, 0, 0, 1)
    hair.Position = UDim2.new(0, 0, 1, 0)
    hair.AnchorPoint = Vector2.new(0, 1)
    hair.BackgroundColor3 = Color3.new(0, 0, 0)
    hair.BackgroundTransparency = 0.7
    hair.BorderSizePixel = 0
    hair.ZIndex = 3
    hair.Parent = bar

    local lights = { Theme.red, Theme.yellow, Theme.green }
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

    local barTitle = Instance.new("TextLabel")
    barTitle.Size = UDim2.new(1, 0, 1, 0)
    barTitle.BackgroundTransparency = 1
    barTitle.Text = "Home"
    barTitle.Font = Theme.fonts.title
    barTitle.TextSize = 14
    barTitle.TextColor3 = Color3.fromRGB(210, 210, 216)
    barTitle.ZIndex = 3
    barTitle.Parent = bar

    -- -----------------------------------------------------------------------
    -- Header: welcome + clock
    -- -----------------------------------------------------------------------
    local PAD = 24

    local welcome = Instance.new("TextLabel")
    welcome.Text = "Welcome home, " .. (lp.DisplayName or lp.Name)
    welcome.Font = Enum.Font.GothamBold
    welcome.TextSize = 24
    welcome.TextColor3 = WHITE
    welcome.TextXAlignment = Enum.TextXAlignment.Left
    welcome.BackgroundTransparency = 1
    welcome.Position = UDim2.fromOffset(PAD, TB + 18)
    welcome.Size = UDim2.fromOffset(winW - 200, 26)
    welcome.ZIndex = 3
    welcome.Parent = win

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "SYNC"
    subtitle.Font = Theme.fonts.caption
    subtitle.TextSize = 13
    subtitle.TextColor3 = SUB
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(PAD, TB + 46)
    subtitle.Size = UDim2.fromOffset(300, 16)
    subtitle.ZIndex = 3
    subtitle.Parent = win

    local clockLabel = Instance.new("TextLabel")
    clockLabel.Font = Theme.fonts.title
    clockLabel.TextSize = 17
    clockLabel.TextColor3 = WHITE
    clockLabel.TextXAlignment = Enum.TextXAlignment.Right
    clockLabel.BackgroundTransparency = 1
    clockLabel.AnchorPoint = Vector2.new(1, 0)
    clockLabel.Position = UDim2.new(1, -PAD, 0, TB + 22)
    clockLabel.Size = UDim2.fromOffset(110, 20)
    clockLabel.ZIndex = 3
    clockLabel.Parent = win

    local clockIcon = Instance.new("ImageLabel")
    clockIcon.Size = UDim2.fromOffset(16, 16)
    clockIcon.AnchorPoint = Vector2.new(1, 0)
    clockIcon.BackgroundTransparency = 1
    clockIcon.ZIndex = 3
    clockIcon.Parent = win
    Icons.apply(clockIcon, "clock", WHITE)

    -- -----------------------------------------------------------------------
    -- Stats strip: players / ping / uptime
    -- -----------------------------------------------------------------------
    local stats = Instance.new("Frame")
    stats.Position = UDim2.fromOffset(PAD, TB + 76)
    stats.Size = UDim2.fromOffset(winW - PAD * 2, 64)
    stats.BackgroundColor3 = CARD
    stats.BackgroundTransparency = 0.25
    stats.BorderSizePixel = 0
    stats.ZIndex = 3
    stats.Parent = win
    Util.corner(stats, 14)
    Util.rimStroke(stats, 1, 0.75, 0.95)

    local statValues = {}
    local statDefs = { { "Players" }, { "Ping" }, { "Uptime" } }
    for i, def in ipairs(statDefs) do
        local col = Instance.new("Frame")
        col.Size = UDim2.new(1 / 3, 0, 1, 0)
        col.Position = UDim2.new((i - 1) / 3, 0, 0, 0)
        col.BackgroundTransparency = 1
        col.ZIndex = 3
        col.Parent = stats

        local v = Instance.new("TextLabel")
        v.Text = "--"
        v.Font = Theme.fonts.title
        v.TextSize = 20
        v.TextColor3 = WHITE
        v.BackgroundTransparency = 1
        v.Position = UDim2.new(0, 0, 0, 11)
        v.Size = UDim2.new(1, 0, 0, 22)
        v.ZIndex = 3
        v.Parent = col
        statValues[def[1]] = v

        local l = Instance.new("TextLabel")
        l.Text = def[1]
        l.Font = Theme.fonts.caption
        l.TextSize = 12
        l.TextColor3 = SUB
        l.BackgroundTransparency = 1
        l.Position = UDim2.new(0, 0, 0, 34)
        l.Size = UDim2.new(1, 0, 0, 14)
        l.ZIndex = 3
        l.Parent = col
    end

    -- -----------------------------------------------------------------------
    -- Cards row
    -- -----------------------------------------------------------------------
    local cardsY = TB + 154
    local cardH = winH - cardsY - PAD
    local cardW = (winW - PAD * 2 - 14) / 2

    local function makeCard(x)
        local c = Instance.new("Frame")
        c.Position = UDim2.fromOffset(x, cardsY)
        c.Size = UDim2.fromOffset(cardW, cardH)
        c.BackgroundColor3 = CARD
        c.BackgroundTransparency = 0.25
        c.BorderSizePixel = 0
        c.ClipsDescendants = true
        c.ZIndex = 3
        c.Parent = win
        Util.corner(c, 16)
        Util.rimStroke(c, 1, 0.75, 0.95)
        return c
    end

    local leftCard  = makeCard(PAD)
    local rightCard = makeCard(PAD + cardW + 14)

    -- -----------------------------------------------------------------------
    -- Left card: profile view
    -- -----------------------------------------------------------------------
    local profileView = Instance.new("Frame")
    profileView.Size = UDim2.fromScale(1, 1)
    profileView.BackgroundTransparency = 1
    profileView.ZIndex = 3
    profileView.Parent = leftCard

    local avatarHolder = Instance.new("Frame")
    avatarHolder.Size = UDim2.fromOffset(116, 116)
    avatarHolder.AnchorPoint = Vector2.new(0.5, 0)
    avatarHolder.Position = UDim2.new(0.5, 0, 0, 34)
    avatarHolder.BackgroundColor3 = FIELD
    avatarHolder.ZIndex = 3
    avatarHolder.Parent = profileView
    Util.corner(avatarHolder, 58)
    local ring = Util.stroke(avatarHolder, ACCENT, 3, 0.1)
    ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local avatar = Instance.new("ImageLabel")
    avatar.Image = headshot(lp.UserId, 150)
    avatar.Size = UDim2.fromScale(1, 1)
    avatar.BackgroundTransparency = 1
    avatar.ZIndex = 4
    avatar.Parent = avatarHolder
    Util.corner(avatar, 58)

    local onlineDot = Instance.new("Frame")
    onlineDot.Size = UDim2.fromOffset(22, 22)
    onlineDot.AnchorPoint = Vector2.new(1, 1)
    onlineDot.Position = UDim2.new(1, 2, 1, 2)
    onlineDot.BackgroundColor3 = GREEN
    onlineDot.ZIndex = 5
    onlineDot.Parent = avatarHolder
    Util.corner(onlineDot, 11)
    Util.stroke(onlineDot, WIN, 3, 0)

    local dispName = Instance.new("TextLabel")
    dispName.Text = lp.DisplayName or lp.Name
    dispName.Font = Theme.fonts.title
    dispName.TextSize = 20
    dispName.TextColor3 = WHITE
    dispName.BackgroundTransparency = 1
    dispName.Position = UDim2.new(0, 0, 0, 166)
    dispName.Size = UDim2.new(1, 0, 0, 24)
    dispName.ZIndex = 3
    dispName.Parent = profileView

    local userName = Instance.new("TextLabel")
    userName.Text = lp.Name
    userName.Font = Theme.fonts.caption
    userName.TextSize = 14
    userName.TextColor3 = SUB
    userName.BackgroundTransparency = 1
    userName.Position = UDim2.new(0, 0, 0, 192)
    userName.Size = UDim2.new(1, 0, 0, 16)
    userName.ZIndex = 3
    userName.Parent = profileView

    -- Chat pill (opens the chat view)
    local chatPill = Instance.new("TextButton")
    chatPill.Text = ""
    chatPill.AutoButtonColor = false
    chatPill.AnchorPoint = Vector2.new(0.5, 1)
    chatPill.Position = UDim2.new(0.5, 0, 1, -18)
    chatPill.Size = UDim2.new(1, -36, 0, 50)
    chatPill.BackgroundColor3 = FIELD
    chatPill.BackgroundTransparency = 0.35
    chatPill.ZIndex = 4
    chatPill.Parent = profileView
    Util.corner(chatPill, 15)
    Util.stroke(chatPill, WHITE, 1, 0.9)

    local pillIcon = Instance.new("Frame")
    pillIcon.Size = UDim2.fromOffset(30, 30)
    pillIcon.Position = UDim2.new(0, 12, 0.5, 0)
    pillIcon.AnchorPoint = Vector2.new(0, 0.5)
    pillIcon.BackgroundColor3 = Color3.fromRGB(120, 120, 128)
    pillIcon.ZIndex = 5
    pillIcon.Parent = chatPill
    Util.corner(pillIcon, 15)
    local pillGlyph = Instance.new("ImageLabel")
    pillGlyph.Size = UDim2.fromOffset(16, 16)
    pillGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    pillGlyph.Position = UDim2.fromScale(0.5, 0.5)
    pillGlyph.BackgroundTransparency = 1
    pillGlyph.ZIndex = 6
    pillGlyph.Parent = pillIcon
    Icons.apply(pillGlyph, "message-circle", WHITE)

    local pillText = Instance.new("TextLabel")
    pillText.Text = "Chat..."
    pillText.Font = Theme.fonts.body
    pillText.TextSize = 15
    pillText.TextColor3 = SUB
    pillText.TextXAlignment = Enum.TextXAlignment.Left
    pillText.BackgroundTransparency = 1
    pillText.Position = UDim2.fromOffset(52, 0)
    pillText.Size = UDim2.new(1, -60, 1, 0)
    pillText.ZIndex = 5
    pillText.Parent = chatPill

    -- -----------------------------------------------------------------------
    -- Left card: chat view
    -- -----------------------------------------------------------------------
    local chatView = Instance.new("Frame")
    chatView.Size = UDim2.fromScale(1, 1)
    chatView.BackgroundTransparency = 1
    chatView.Visible = false
    chatView.ZIndex = 3
    chatView.Parent = leftCard

    local chatTitle = Instance.new("TextLabel")
    chatTitle.Text = "Chat"
    chatTitle.Font = Enum.Font.GothamBold
    chatTitle.TextSize = 18
    chatTitle.TextColor3 = WHITE
    chatTitle.TextXAlignment = Enum.TextXAlignment.Left
    chatTitle.BackgroundTransparency = 1
    chatTitle.Position = UDim2.fromOffset(20, 16)
    chatTitle.Size = UDim2.fromOffset(120, 22)
    chatTitle.ZIndex = 4
    chatTitle.Parent = chatView

    local chatClose = Instance.new("TextButton")
    chatClose.Text = ""
    chatClose.AutoButtonColor = false
    chatClose.Size = UDim2.fromOffset(30, 30)
    chatClose.AnchorPoint = Vector2.new(1, 0)
    chatClose.Position = UDim2.new(1, -14, 0, 12)
    chatClose.BackgroundColor3 = FIELD
    chatClose.BackgroundTransparency = 0.4
    chatClose.ZIndex = 4
    chatClose.Parent = chatView
    Util.corner(chatClose, 10)
    Util.stroke(chatClose, WHITE, 1, 0.9)
    local chatCloseGlyph = Instance.new("ImageLabel")
    chatCloseGlyph.Size = UDim2.fromOffset(14, 14)
    chatCloseGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    chatCloseGlyph.Position = UDim2.fromScale(0.5, 0.5)
    chatCloseGlyph.BackgroundTransparency = 1
    chatCloseGlyph.ZIndex = 5
    chatCloseGlyph.Parent = chatClose
    Icons.apply(chatCloseGlyph, "x", SUB)

    local chatScroll = Instance.new("ScrollingFrame")
    chatScroll.Position = UDim2.fromOffset(12, 52)
    chatScroll.Size = UDim2.new(1, -24, 1, -122)
    chatScroll.BackgroundTransparency = 1
    chatScroll.BorderSizePixel = 0
    chatScroll.ScrollBarThickness = 3
    chatScroll.ScrollBarImageColor3 = SUB
    chatScroll.ScrollBarImageTransparency = 0.6
    chatScroll.CanvasSize = UDim2.new()
    chatScroll.ZIndex = 4
    chatScroll.Parent = chatView
    local chatLayout = Instance.new("UIListLayout")
    chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
    chatLayout.Padding = UDim.new(0, 10)
    chatLayout.Parent = chatScroll
    Util.autoCanvas(chatScroll, "Y")

    local chatEmpty = Instance.new("TextLabel")
    chatEmpty.Text = "Server chat shows up here."
    chatEmpty.Font = Theme.fonts.caption
    chatEmpty.TextSize = 14
    chatEmpty.TextColor3 = SUB
    chatEmpty.TextWrapped = true
    chatEmpty.BackgroundTransparency = 1
    chatEmpty.AnchorPoint = Vector2.new(0.5, 0.5)
    chatEmpty.Position = UDim2.fromScale(0.5, 0.42)
    chatEmpty.Size = UDim2.new(1, -60, 0, 40)
    chatEmpty.ZIndex = 4
    chatEmpty.Parent = chatView

    local chatInputHolder = Instance.new("Frame")
    chatInputHolder.AnchorPoint = Vector2.new(0.5, 1)
    chatInputHolder.Position = UDim2.new(0.5, 0, 1, -14)
    chatInputHolder.Size = UDim2.new(1, -28, 0, 46)
    chatInputHolder.BackgroundColor3 = FIELD
    chatInputHolder.BackgroundTransparency = 0.35
    chatInputHolder.ZIndex = 4
    chatInputHolder.Parent = chatView
    Util.corner(chatInputHolder, 14)
    Util.stroke(chatInputHolder, WHITE, 1, 0.9)

    local inputIcon = Instance.new("Frame")
    inputIcon.Size = UDim2.fromOffset(26, 26)
    inputIcon.Position = UDim2.new(0, 10, 0.5, 0)
    inputIcon.AnchorPoint = Vector2.new(0, 0.5)
    inputIcon.BackgroundColor3 = Color3.fromRGB(120, 120, 128)
    inputIcon.ZIndex = 5
    inputIcon.Parent = chatInputHolder
    Util.corner(inputIcon, 13)
    local inputGlyph = Instance.new("ImageLabel")
    inputGlyph.Size = UDim2.fromOffset(14, 14)
    inputGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    inputGlyph.Position = UDim2.fromScale(0.5, 0.5)
    inputGlyph.BackgroundTransparency = 1
    inputGlyph.ZIndex = 6
    inputGlyph.Parent = inputIcon
    Icons.apply(inputGlyph, "message-circle", WHITE)

    local chatBox = Instance.new("TextBox")
    chatBox.PlaceholderText = "Message..."
    chatBox.PlaceholderColor3 = SUB
    chatBox.Text = ""
    chatBox.ClearTextOnFocus = false
    chatBox.Font = Theme.fonts.body
    chatBox.TextSize = 15
    chatBox.TextColor3 = WHITE
    chatBox.TextXAlignment = Enum.TextXAlignment.Left
    chatBox.BackgroundTransparency = 1
    chatBox.Position = UDim2.fromOffset(46, 0)
    chatBox.Size = UDim2.new(1, -56, 1, 0)
    chatBox.ZIndex = 5
    chatBox.Parent = chatInputHolder

    chatPill.MouseButton1Click:Connect(function()
        profileView.Visible = false
        chatView.Visible = true
    end)
    chatClose.MouseButton1Click:Connect(function()
        chatView.Visible = false
        profileView.Visible = true
    end)

    -- Chat message rows -----------------------------------------------------
    local msgOrder = 0
    local msgRows = {}

    local function addMessage(name, text, userId, isYou)
        if not alive then return end
        chatEmpty.Visible = false
        msgOrder += 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundTransparency = 1
        row.LayoutOrder = msgOrder
        row.ZIndex = 4
        row.Parent = chatScroll

        local av = Instance.new("ImageLabel")
        av.Size = UDim2.fromOffset(32, 32)
        av.BackgroundColor3 = FIELD
        av.ZIndex = 4
        av.Parent = row
        Util.corner(av, 16)
        if userId then
            av.Image = headshot(userId, 48)
        else
            av.Image = ""
        end

        local nm = Instance.new("TextLabel")
        nm.Text = isYou and "You" or name
        nm.Font = Theme.fonts.title
        nm.TextSize = 14
        nm.TextColor3 = ACCENT
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.BackgroundTransparency = 1
        nm.Position = UDim2.fromOffset(42, 0)
        nm.Size = UDim2.new(1, -46, 0, 16)
        nm.ZIndex = 4
        nm.Parent = row

        local tx = Instance.new("TextLabel")
        tx.Text = text
        tx.Font = Theme.fonts.body
        tx.TextSize = 14
        tx.TextColor3 = Color3.fromRGB(225, 225, 230)
        tx.TextXAlignment = Enum.TextXAlignment.Left
        tx.TextYAlignment = Enum.TextYAlignment.Top
        tx.TextWrapped = true
        tx.BackgroundTransparency = 1
        tx.AutomaticSize = Enum.AutomaticSize.Y
        tx.Position = UDim2.fromOffset(42, 18)
        tx.Size = UDim2.new(1, -46, 0, 16)
        tx.ZIndex = 4
        tx.Parent = row

        msgRows[#msgRows + 1] = row
        if #msgRows > 60 then
            local old = table.remove(msgRows, 1)
            old:Destroy()
        end

        task.defer(function()
            pcall(function()
                chatScroll.CanvasPosition = Vector2.new(0, math.max(0, chatLayout.AbsoluteContentSize.Y - chatScroll.AbsoluteWindowSize.Y + 8))
            end)
        end)
    end

    -- Chat wiring: pick by what the game actually exposes (some games report
    -- LegacyChatService but only have TextChannels, and vice versa) ----------
    local sendMessage
    local generalChannel
    pcall(function()
        local channels = TextChatService:FindFirstChild("TextChannels")
        generalChannel = channels and channels:FindFirstChild("RBXGeneral")
    end)

    if generalChannel then
        conns[#conns + 1] = TextChatService.MessageReceived:Connect(function(msg)
            local st
            pcall(function() st = msg.Status end)
            if st ~= nil and st ~= Enum.TextChatMessageStatus.Success then return end
            local src = msg.TextSource
            if not src then return end
            addMessage(src.Name, msg.Text, src.UserId, src.UserId == lp.UserId)
        end)
        sendMessage = function(text)
            pcall(function() generalChannel:SendAsync(text) end)
        end
    else
        local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        local filtered = events and events:FindFirstChild("OnMessageDoneFiltering")
        if filtered then
            conns[#conns + 1] = filtered.OnClientEvent:Connect(function(data)
                if type(data) ~= "table" then return end
                if data.MessageType and data.MessageType ~= "Message" then return end
                local speaker = data.FromSpeaker or "?"
                local pl = Players:FindFirstChild(speaker)
                addMessage(speaker, data.Message or "", pl and pl.UserId or nil, pl == lp)
            end)
        else
            local function hook(pl)
                conns[#conns + 1] = pl.Chatted:Connect(function(msg)
                    addMessage(pl.Name, msg, pl.UserId, pl == lp)
                end)
            end
            for _, pl in ipairs(Players:GetPlayers()) do hook(pl) end
            conns[#conns + 1] = Players.PlayerAdded:Connect(hook)
        end
        sendMessage = function(text)
            pcall(function()
                local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local say = ev and ev:FindFirstChild("SayMessageRequest")
                if say then say:FireServer(text, "All") end
            end)
        end
    end

    chatBox.FocusLost:Connect(function(enterPressed)
        if not enterPressed then return end
        local text = chatBox.Text
        if text:gsub("%s", "") == "" then return end
        chatBox.Text = ""
        sendMessage(text)
    end)

    -- -----------------------------------------------------------------------
    -- Right card: Friend Activity (orca port)
    -- -----------------------------------------------------------------------
    local faTitle = Instance.new("TextLabel")
    faTitle.Text = "Friend Activity"
    faTitle.Font = Enum.Font.GothamBold
    faTitle.TextSize = 18
    faTitle.TextColor3 = WHITE
    faTitle.TextXAlignment = Enum.TextXAlignment.Left
    faTitle.BackgroundTransparency = 1
    faTitle.Position = UDim2.fromOffset(20, 16)
    faTitle.Size = UDim2.new(1, -40, 0, 22)
    faTitle.ZIndex = 4
    faTitle.Parent = rightCard

    local faEmpty = Instance.new("TextLabel")
    faEmpty.Text = "Your friends will appear here when they're in-game."
    faEmpty.Font = Theme.fonts.caption
    faEmpty.TextSize = 14
    faEmpty.TextColor3 = SUB
    faEmpty.TextWrapped = true
    faEmpty.BackgroundTransparency = 1
    faEmpty.AnchorPoint = Vector2.new(0.5, 0.5)
    faEmpty.Position = UDim2.fromScale(0.5, 0.5)
    faEmpty.Size = UDim2.new(1, -60, 0, 40)
    faEmpty.ZIndex = 4
    faEmpty.Parent = rightCard

    local faScroll = Instance.new("ScrollingFrame")
    faScroll.Position = UDim2.fromOffset(14, 48)
    faScroll.Size = UDim2.new(1, -28, 1, -62)
    faScroll.BackgroundTransparency = 1
    faScroll.BorderSizePixel = 0
    faScroll.ScrollBarThickness = 3
    faScroll.ScrollBarImageColor3 = SUB
    faScroll.ScrollBarImageTransparency = 0.6
    faScroll.CanvasSize = UDim2.new()
    faScroll.ZIndex = 4
    faScroll.Parent = rightCard
    local faLayout = Instance.new("UIListLayout")
    faLayout.SortOrder = Enum.SortOrder.LayoutOrder
    faLayout.Padding = UDim.new(0, 10)
    faLayout.Parent = faScroll
    Util.autoCanvas(faScroll, "Y")

    local universeCache = {}
    local nameCache = {}

    local function universeIdFor(placeId)
        local cached = universeCache[placeId]
        if cached ~= nil then return cached or nil end
        local body = Util.httpGet("https://apis.roblox.com/universes/v1/places/" .. placeId .. "/universe")
        local id
        if body then
            pcall(function() id = HttpService:JSONDecode(body).universeId end)
        end
        universeCache[placeId] = id or false
        return id
    end

    local function gameNameFor(placeId)
        local cached = nameCache[placeId]
        if cached then return cached end
        local name
        pcall(function() name = MarketplaceService:GetProductInfo(placeId).Name end)
        name = name or ("Place " .. placeId)
        nameCache[placeId] = name
        return name
    end

    -- Same grouping as orca's useFriendActivity: online friends that expose
    -- PlaceId + GameId, bucketed per place, most friends first.
    local function fetchGames()
        local ok, friends = pcall(function() return lp:GetFriendsOnline(200) end)
        if not ok or type(friends) ~= "table" then return nil end
        local byPlace, order = {}, {}
        for _, fr in ipairs(friends) do
            if fr.PlaceId and fr.GameId then
                local g = byPlace[fr.PlaceId]
                if not g then
                    g = { placeId = fr.PlaceId, gameId = fr.GameId, friends = {} }
                    byPlace[fr.PlaceId] = g
                    order[#order + 1] = g
                end
                g.friends[#g.friends + 1] = fr
            end
        end
        table.sort(order, function(a, b) return #a.friends > #b.friends end)
        return order
    end

    local function buildFriendChip(parent, fr, index)
        local chip = Instance.new("TextButton")
        chip.Text = ""
        chip.AutoButtonColor = false
        chip.Size = UDim2.fromOffset(44, 44)
        chip.BackgroundColor3 = FIELD
        chip.BackgroundTransparency = 0.2
        chip.ClipsDescendants = true
        chip.LayoutOrder = index
        chip.ZIndex = 5
        chip.Parent = parent
        Util.corner(chip, 22)
        local chipStroke = Util.stroke(chip, WHITE, 1, 0.88)

        local av = Instance.new("ImageLabel")
        av.Image = headshot(fr.VisitorId, 100)
        av.Size = UDim2.fromOffset(44, 44)
        av.BackgroundTransparency = 1
        av.ZIndex = 6
        av.Parent = chip
        Util.corner(av, 22)

        local play = Instance.new("ImageLabel")
        play.Size = UDim2.fromOffset(18, 18)
        play.Position = UDim2.fromOffset(52, 13)
        play.BackgroundTransparency = 1
        play.ImageTransparency = 1
        play.ZIndex = 6
        play.Parent = chip
        Icons.apply(play, "chevron-right", WHITE)

        chip.MouseEnter:Connect(function()
            Util.tween(chip, { Size = UDim2.fromOffset(78, 44), BackgroundColor3 = ACCENT, BackgroundTransparency = 0 }, 0.16)
            Util.tween(play, { ImageTransparency = 0 }, 0.16)
            Util.tween(chipStroke, { Transparency = 0.55 }, 0.16)
        end)
        chip.MouseLeave:Connect(function()
            Util.tween(chip, { Size = UDim2.fromOffset(44, 44), BackgroundColor3 = FIELD, BackgroundTransparency = 0.2 }, 0.16)
            Util.tween(play, { ImageTransparency = 1 }, 0.16)
            Util.tween(chipStroke, { Transparency = 0.88 }, 0.16)
        end)
        chip.MouseButton1Click:Connect(function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(fr.PlaceId, fr.GameId, lp)
            end)
        end)
    end

    local function render(games)
        if not alive then return end
        for _, child in ipairs(faScroll:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
        faEmpty.Visible = #games == 0

        for gi, g in ipairs(games) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -4, 0, 122)
            card.BackgroundColor3 = FIELD
            card.BackgroundTransparency = 0.45
            card.BorderSizePixel = 0
            card.LayoutOrder = gi
            card.ZIndex = 4
            card.Parent = faScroll
            Util.corner(card, 14)
            Util.stroke(card, WHITE, 1, 0.9)

            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.fromOffset(48, 48)
            icon.Position = UDim2.fromOffset(14, 12)
            icon.BackgroundColor3 = CARD
            icon.ZIndex = 5
            icon.Parent = card
            Util.corner(icon, 12)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text = "..."
            nameLabel.Font = Theme.fonts.title
            nameLabel.TextSize = 15
            nameLabel.TextColor3 = WHITE
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.BackgroundTransparency = 1
            nameLabel.Position = UDim2.fromOffset(72, 16)
            nameLabel.Size = UDim2.new(1, -86, 0, 18)
            nameLabel.ZIndex = 5
            nameLabel.Parent = card

            local countLabel = Instance.new("TextLabel")
            countLabel.Text = #g.friends .. (#g.friends == 1 and " friend here" or " friends here")
            countLabel.Font = Theme.fonts.caption
            countLabel.TextSize = 12
            countLabel.TextColor3 = SUB
            countLabel.TextXAlignment = Enum.TextXAlignment.Left
            countLabel.BackgroundTransparency = 1
            countLabel.Position = UDim2.fromOffset(72, 36)
            countLabel.Size = UDim2.new(1, -86, 0, 14)
            countLabel.ZIndex = 5
            countLabel.Parent = card

            local chips = Instance.new("ScrollingFrame")
            chips.Position = UDim2.fromOffset(14, 68)
            chips.Size = UDim2.new(1, -28, 0, 44)
            chips.BackgroundTransparency = 1
            chips.BorderSizePixel = 0
            chips.ScrollBarThickness = 0
            chips.ScrollingDirection = Enum.ScrollingDirection.X
            chips.CanvasSize = UDim2.fromOffset(#g.friends * 54 + 40, 0)
            chips.ZIndex = 5
            chips.Parent = card
            local chipsLayout = Instance.new("UIListLayout")
            chipsLayout.FillDirection = Enum.FillDirection.Horizontal
            chipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            chipsLayout.Padding = UDim.new(0, 10)
            chipsLayout.Parent = chips

            for fi, fr in ipairs(g.friends) do
                buildFriendChip(chips, fr, fi)
            end

            -- Slow lookups (name + universe icon) resolved after the card shows
            task.spawn(function()
                local nm = gameNameFor(g.placeId)
                if nameLabel.Parent then nameLabel.Text = nm end
                local uid = universeIdFor(g.placeId)
                if uid and icon.Parent then
                    icon.Image = ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(uid)
                end
            end)
        end
    end

    -- Refresh loop: 30s when populated, 5s retry when empty (orca's cadence)
    task.spawn(function()
        while alive and gui.Parent do
            local games = fetchGames()
            if not alive then return end
            if games then render(games) end
            local delaySec = (games and #games > 0) and 30 or 5
            for _ = 1, delaySec * 2 do
                if not alive then return end
                task.wait(0.5)
            end
        end
    end)

    -- -----------------------------------------------------------------------
    -- Live header/stats loop
    -- -----------------------------------------------------------------------
    local function ping()
        local ms
        pcall(function()
            ms = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if not ms then
            pcall(function() ms = lp:GetNetworkPing() * 2000 end)
        end
        return ms and math.floor(ms + 0.5) or nil
    end

    task.spawn(function()
        while alive and gui.Parent do
            local t = Util.date("%I:%M %p"):gsub("^0", "")
            clockLabel.Text = t
            clockIcon.Position = UDim2.new(1, -PAD - clockLabel.TextBounds.X - 10, 0, TB + 24)

            statValues.Players.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
            local ms = ping()
            statValues.Ping.Text = ms and (ms .. "ms") or "--"
            local up = math.floor(time())
            statValues.Uptime.Text = string.format("%02d:%02d:%02d", up // 3600, (up // 60) % 60, up % 60)
            task.wait(1)
        end
    end)

    return { close = close }
end

return Home
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
