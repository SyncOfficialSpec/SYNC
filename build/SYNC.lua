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
-- Branded loading screen v2 ("baked-bloom cinematic"). All fancy visuals are
-- pre-rendered PNGs served from the repo (rainbow bloom ring with a smoked-glass
-- interior, porthole-clipped mono character, radial halo, star sparkles) because
-- baked images render reliably everywhere, unlike stroke gradients / font glyphs.
-- Open/close are fully choreographed: staggered rises in, reverse slide-out, and
-- a crossfade handoff (next screen builds under the black veil while it lifts).
-- Layout scales with the viewport. Boot.run(onDone) plays, fades out, calls onDone().

local RunService = game:GetService("RunService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Boot = {}

local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"
-- v2 local filenames: getcustomasset caches by file path on many executors, so
-- new art needs new names or clients keep showing the old pixels.
local ASSETS = {
    char = { url = RAW .. "boot-char.png", file = "sync_boot2_char.png" },
    ring = { url = RAW .. "boot-ring.png", file = "sync_boot2_ring.png" },
    halo = { url = RAW .. "boot-halo.png", file = "sync_boot2_halo.png" },
    star = { url = RAW .. "boot-star.png", file = "sync_boot2_star.png" },
}

-- Google brand gradient, looped so offset/rotation animation is seamless.
local GOOGLE = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(66, 133, 244)),  -- blue
    ColorSequenceKeypoint.new(0.28, Color3.fromRGB(234, 67, 53)),   -- red
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(251, 188, 5)),   -- yellow
    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(52, 168, 83)),   -- green
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(66, 133, 244)),  -- back to blue
})

local WHITE = Color3.fromRGB(245, 245, 247)
local CHAR_ASPECT = 591 / 609 -- boot-char.png width/height

function Boot.run(onDone)
    local vp = Util.viewport()
    -- design space is 1080p; scale every offset by S so the screen fills any window
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

    local alive   = true  -- kills RenderStepped loops on destroy
    local closing = false -- stops decorative loops from fighting the exit tweens

    -- -----------------------------------------------------------------------
    -- Corner brackets: slide out of the corners on open, retract on close.
    -- -----------------------------------------------------------------------
    local bracketBars = {} -- { inst, finalPos, retractPos }
    for ci, c in ipairs({ {0,0}, {1,0}, {0,1}, {1,1} }) do
        local ax, ay = c[1], c[2]
        local inset, blen = px(34), px(30)
        local ox = ax == 0 and inset or -inset
        local oy = ay == 0 and inset or -inset
        -- retracted = pushed 16px deeper into the corner
        local rx = ax == 0 and inset - px(16) or -(inset - px(16))
        local ry = ay == 0 and inset - px(16) or -(inset - px(16))
        for _, bar in ipairs({ { blen, 2 }, { 2, blen } }) do
            local f = Instance.new("Frame")
            f.Size = UDim2.fromOffset(bar[1], bar[2])
            f.AnchorPoint = Vector2.new(ax, ay)
            f.Position = UDim2.new(ax, rx, ay, ry) -- start retracted
            f.BackgroundColor3 = WHITE
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Parent = screen
            bracketBars[#bracketBars + 1] = {
                inst = f,
                finalPos = UDim2.new(ax, ox, ay, oy),
                retractPos = UDim2.new(ax, rx, ay, ry),
            }
            task.delay(0.15 + ci * 0.05, function()
                if alive and not closing then
                    Util.tween(f, { Position = UDim2.new(ax, ox, ay, oy), BackgroundTransparency = 0.45 },
                        0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                end
            end)
        end
    end

    -- -----------------------------------------------------------------------
    -- Right stage: halo -> rainbow ring (rotating) -> porthole character.
    -- The stage frame carries the idle float bob, an entrance settle and the
    -- exit zoom.
    -- -----------------------------------------------------------------------
    local stage = Instance.new("Frame")
    stage.Size = UDim2.fromOffset(px(760), px(760))
    stage.Position = UDim2.fromScale(0.66, 0.5)
    stage.AnchorPoint = Vector2.new(0.5, 0.5)
    stage.BackgroundTransparency = 1
    stage.Parent = screen
    local stageScale = Instance.new("UIScale")
    stageScale.Scale = 0.94
    stageScale.Parent = stage
    Util.tween(stageScale, { Scale = 1 }, 1.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local ringLabel, haloLabel, charLabel -- filled in as assets load
    local stars = {}

    local function addImage(id, size, z, yOff)
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromOffset(size, size)
        img.Position = UDim2.new(0.5, 0, 0.5, yOff or 0)
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.BackgroundTransparency = 1
        img.Image = id
        img.ScaleType = Enum.ScaleType.Fit
        img.ImageTransparency = 1
        img.ZIndex = z
        img.Parent = stage
        return img
    end

    task.spawn(function()
        local haloId = Util.remoteImage(ASSETS.halo.url, ASSETS.halo.file)
        if haloId and alive and not closing then
            haloLabel = addImage(haloId, px(760), 1)
            Util.tween(haloLabel, { ImageTransparency = 0 }, 1.2, Enum.EasingStyle.Sine)
        end
    end)

    task.spawn(function()
        local ringId = Util.remoteImage(ASSETS.ring.url, ASSETS.ring.file)
        if ringId and alive and not closing then
            ringLabel = addImage(ringId, px(640), 2)
            local sc = Instance.new("UIScale")
            sc.Scale = 0.92
            sc.Parent = ringLabel
            Util.tween(ringLabel, { ImageTransparency = 0 }, 0.9, Enum.EasingStyle.Sine)
            Util.tween(sc, { Scale = 1 }, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end
    end)

    task.spawn(function()
        local charId = Util.remoteImage(ASSETS.char.url, ASSETS.char.file)
        if not (charId and alive) or closing then return end
        local ch = px(520)
        local cw = math.floor(ch * CHAR_ASPECT + 0.5)

        -- chromatic-aberration entrance: blue/red ghosts jitter, then converge
        local ghosts = {}
        for _, g in ipairs({
            { color = Color3.fromRGB(66, 133, 244), dir = -1 },
            { color = Color3.fromRGB(234, 67, 53),  dir = 1 },
        }) do
            local gh = Instance.new("ImageLabel")
            gh.Size = UDim2.fromOffset(cw, ch)
            gh.Position = UDim2.new(0.5, g.dir * px(8), 0.5, -px(10))
            gh.AnchorPoint = Vector2.new(0.5, 0.5)
            gh.BackgroundTransparency = 1
            gh.Image = charId
            gh.ScaleType = Enum.ScaleType.Fit
            gh.ImageColor3 = g.color
            gh.ImageTransparency = 0.62
            gh.ZIndex = 3
            gh.Parent = stage
            ghosts[#ghosts + 1] = { inst = gh, dir = g.dir }
        end

        charLabel = Instance.new("ImageLabel")
        charLabel.Size = UDim2.fromOffset(cw, ch)
        charLabel.Position = UDim2.new(0.5, 0, 0.5, -px(10))
        charLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        charLabel.BackgroundTransparency = 1
        charLabel.Image = charId
        charLabel.ScaleType = Enum.ScaleType.Fit
        charLabel.ImageTransparency = 1
        charLabel.ZIndex = 4
        charLabel.Parent = stage
        Util.tween(charLabel, { ImageTransparency = 0 }, 0.55, Enum.EasingStyle.Sine)

        -- jitter ~0.5s, then snap together and vanish
        for _ = 1, 9 do
            if not alive or closing then break end
            for _, g in ipairs(ghosts) do
                g.inst.Position = UDim2.new(
                    0.5, g.dir * math.random(px(3), px(10)),
                    0.5, -px(10) + math.random(-px(3), px(3)))
            end
            task.wait(0.055)
        end
        for _, g in ipairs(ghosts) do
            Util.tween(g.inst, {
                Position = UDim2.new(0.5, 0, 0.5, -px(10)),
                ImageTransparency = 1,
            }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.3, function() g.inst:Destroy() end)
        end
    end)

    -- ring rotation + stage float bob (runs through the exit too; the bob makes
    -- the fade-out feel alive rather than frozen)
    task.spawn(function()
        local t = 0
        while alive do
            local dt = RunService.RenderStepped:Wait()
            t += dt
            if ringLabel then ringLabel.Rotation = (t * 14) % 360 end
            stage.Position = UDim2.new(0.66, 0, 0.5, math.sin(t * 2.1) * px(8))
        end
    end)

    -- -----------------------------------------------------------------------
    -- Left block: kicker (typed on), gradient SYNC, tagline, progress row.
    -- Each element rises ~16px while fading in, staggered top to bottom.
    -- -----------------------------------------------------------------------
    local block = Instance.new("Frame")
    block.Size = UDim2.fromOffset(px(700), px(300))
    block.Position = UDim2.new(0.10, 0, 0.5, 0)
    block.AnchorPoint = Vector2.new(0, 0.5)
    block.BackgroundTransparency = 1
    block.Parent = screen

    local function textLabel(y, h, size, font, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, px(h))
        l.Position = UDim2.fromOffset(0, px(y) + px(16)) -- start low, rise in
        l.BackgroundTransparency = 1
        l.Font = font
        l.TextSize = px(size)
        l.TextColor3 = color
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTransparency = 1
        l.Parent = block
        return l, UDim2.fromOffset(0, px(y))
    end

    local function riseIn(label, finalPos, delay, dur)
        task.delay(delay, function()
            if alive and not closing then
                Util.tween(label, { Position = finalPos, TextTransparency = 0 },
                    dur or 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            end
        end)
    end

    local kicker, kickerPos = textLabel(0, 24, 20, Theme.fonts.caption, WHITE)
    kicker.Text = ""

    local title, titlePos = textLabel(26, 160, 150, Theme.fonts.title, Color3.fromRGB(255, 255, 255))
    title.Text = "SYNC"
    local titleGrad = Instance.new("UIGradient")
    titleGrad.Color = GOOGLE
    titleGrad.Parent = title

    local tagline, taglinePos = textLabel(196, 26, 24, Theme.fonts.body, Theme.c.textSecondary)
    tagline.Text = "your desktop, reimagined"

    riseIn(kicker, kickerPos, 0.25, 0.5)
    task.delay(0.3, function()
        -- type the kicker on, letter by letter, while it rises
        local spaced = "W E L C O M E   T O"
        for i = 1, #spaced do
            if not alive or closing then return end
            kicker.Text = string.sub(spaced, 1, i)
            task.wait(0.022)
        end
    end)

    riseIn(title, titlePos, 0.45, 0.7)
    task.delay(0.5, function()
        -- shine sweep on the wordmark
        while alive and not closing and title.Parent do
            Util.tween(titleGrad, { Offset = Vector2.new(0.25, 0) }, 1.6,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.65)
            if not alive or closing or not title.Parent then break end
            Util.tween(titleGrad, { Offset = Vector2.new(-0.25, 0) }, 1.6,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.65)
        end
    end)

    riseIn(tagline, taglinePos, 0.62, 0.6)

    -- progress row: reveal-style fill so the gradient is unveiled, not squished
    local trackW, trackH = px(420), math.max(px(5), 3)
    local trackY = px(256)
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(trackW, trackH)
    track.Position = UDim2.fromOffset(0, trackY + px(14)) -- rises in with the row
    track.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Parent = block
    Util.corner(track, trackH)

    local reveal = Instance.new("Frame")
    reveal.Size = UDim2.new(0, 0, 1, 0)
    reveal.BackgroundTransparency = 1
    reveal.BorderSizePixel = 0
    reveal.ClipsDescendants = true
    reveal.Parent = track
    Util.corner(reveal, trackH)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromOffset(trackW, trackH) -- full track width, gets revealed
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bar.BorderSizePixel = 0
    bar.Parent = reveal
    Util.corner(bar, trackH)
    local barGrad = Instance.new("UIGradient")
    barGrad.Color = GOOGLE
    barGrad.Parent = bar

    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.fromOffset(px(70), px(20))
    pct.Position = UDim2.fromOffset(trackW + px(16), trackY - px(8) + px(14))
    pct.BackgroundTransparency = 1
    pct.Font = Enum.Font.Code
    pct.TextSize = px(15)
    pct.TextColor3 = Color3.fromRGB(200, 200, 205)
    pct.TextXAlignment = Enum.TextXAlignment.Left
    pct.Text = "0%"
    pct.TextTransparency = 1
    pct.Parent = block

    local bootlog = Instance.new("TextLabel")
    bootlog.Size = UDim2.new(1, 0, 0, px(18))
    bootlog.Position = UDim2.fromOffset(0, px(276) + px(14))
    bootlog.BackgroundTransparency = 1
    bootlog.Font = Enum.Font.Code
    bootlog.TextSize = px(14)
    bootlog.TextColor3 = Color3.fromRGB(112, 112, 118)
    bootlog.TextXAlignment = Enum.TextXAlignment.Left
    bootlog.Text = ""
    bootlog.TextTransparency = 1
    bootlog.Parent = block

    -- the whole progress row rises in together, after the tagline
    task.delay(0.8, function()
        if not alive or closing then return end
        Util.tween(track, { Position = UDim2.fromOffset(0, trackY), BackgroundTransparency = 0.35 },
            0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        Util.tween(pct, { Position = UDim2.fromOffset(trackW + px(16), trackY - px(8)), TextTransparency = 0 },
            0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        Util.tween(bootlog, { Position = UDim2.fromOffset(0, px(276)), TextTransparency = 0 },
            0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    end)

    -- live percent readout from the reveal width
    task.spawn(function()
        while alive and track.Parent do
            RunService.RenderStepped:Wait()
            local p = reveal.AbsoluteSize.X / math.max(track.AbsoluteSize.X, 1)
            pct.Text = string.format("%d%%", math.floor(p * 100 + 0.5))
        end
    end)

    -- -----------------------------------------------------------------------
    -- Sparkles (baked star PNG; created once the asset arrives)
    -- -----------------------------------------------------------------------
    task.spawn(function()
        local starId = Util.remoteImage(ASSETS.star.url, ASSETS.star.file)
        if not (starId and alive) or closing then return end
        local spots = {
            { 0.545, 0.27, 34 }, { 0.80, 0.22, 24 }, { 0.585, 0.72, 26 },
            { 0.79, 0.76, 40 }, { 0.51, 0.50, 18 }, { 0.735, 0.135, 20 },
        }
        for i, sp in ipairs(spots) do
            local star = Instance.new("ImageLabel")
            star.Size = UDim2.fromOffset(px(sp[3]), px(sp[3]))
            star.Position = UDim2.fromScale(sp[1], sp[2])
            star.AnchorPoint = Vector2.new(0.5, 0.5)
            star.BackgroundTransparency = 1
            star.Image = starId
            star.ImageTransparency = 1
            star.Parent = screen
            stars[#stars + 1] = star
            task.delay(0.3 + i * 0.14, function()
                while alive and not closing and star.Parent do
                    Util.tween(star, { ImageTransparency = 0.1, Rotation = 12 }, 0.7, Enum.EasingStyle.Sine)
                    task.wait(0.75)
                    if not alive or closing or not star.Parent then break end
                    Util.tween(star, { ImageTransparency = 0.85, Rotation = -12 }, 0.95, Enum.EasingStyle.Sine)
                    task.wait(1.0)
                end
            end)
        end
    end)

    -- -----------------------------------------------------------------------
    -- Boot cadence -> choreographed exit (reverse of the entrance) -> crossfade
    -- -----------------------------------------------------------------------
    task.spawn(function()
        task.wait(0.85) -- let the progress row land before it starts filling
        local steps = {
            { p = 0.24, t = 0.60, hold = 0.22, log = "> mounting dock…" },
            { p = 0.47, t = 0.70, hold = 0.30, log = "> loading apps…" },
            { p = 0.68, t = 0.60, hold = 0.34, log = "> syncing cursor…" },
            { p = 0.88, t = 0.65, hold = 0.22, log = "> warming up liquid glass…" },
            { p = 1.00, t = 0.50, hold = 0.00, log = "> ready." },
        }
        for _, s in ipairs(steps) do
            bootlog.Text = s.log
            Util.tween(reveal, { Size = UDim2.new(0, math.floor(trackW * s.p + 0.5), 1, 0) }, s.t,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(s.t + s.hold)
        end
        task.wait(0.5)

        -- ---- exit choreography ----
        closing = true
        local IN = Enum.EasingDirection.In

        -- 1. progress row drops away
        Util.tween(track, { Position = UDim2.fromOffset(0, trackY + px(10)), BackgroundTransparency = 1 },
            0.35, Enum.EasingStyle.Quad, IN)
        Util.tween(pct, { Position = UDim2.fromOffset(trackW + px(16), trackY + px(2)), TextTransparency = 1 },
            0.35, Enum.EasingStyle.Quad, IN)
        Util.tween(bootlog, { Position = UDim2.fromOffset(0, px(286)), TextTransparency = 1 },
            0.35, Enum.EasingStyle.Quad, IN)
        task.wait(0.07)

        -- 2. texts slide out left, bottom-up (reverse of the entrance)
        Util.tween(tagline, { Position = taglinePos - UDim2.fromOffset(px(20), 0), TextTransparency = 1 },
            0.35, Enum.EasingStyle.Quad, IN)
        task.wait(0.07)
        Util.tween(title, { Position = titlePos - UDim2.fromOffset(px(24), 0), TextTransparency = 1 },
            0.4, Enum.EasingStyle.Quad, IN)
        task.wait(0.07)
        Util.tween(kicker, { Position = kickerPos - UDim2.fromOffset(px(16), 0), TextTransparency = 1 },
            0.35, Enum.EasingStyle.Quad, IN)

        -- 3. stage release: char drifts down and out first, ring follows, halo
        --    lingers longest so the glow is the last thing to leave
        Util.tween(stageScale, { Scale = 1.07 }, 0.9, Enum.EasingStyle.Sine)
        if charLabel then
            Util.tween(charLabel, {
                Position = UDim2.new(0.5, 0, 0.5, px(4)),
                ImageTransparency = 1,
            }, 0.55, Enum.EasingStyle.Quad, IN)
        end
        if ringLabel then Util.tween(ringLabel, { ImageTransparency = 1 }, 0.65, Enum.EasingStyle.Sine) end
        if haloLabel then Util.tween(haloLabel, { ImageTransparency = 1 }, 0.9, Enum.EasingStyle.Sine) end
        for _, star in ipairs(stars) do
            if star.Parent then Util.tween(star, { ImageTransparency = 1 }, 0.3) end
        end

        -- 4. brackets retract into the corners
        for _, b in ipairs(bracketBars) do
            Util.tween(b.inst, { Position = b.retractPos, BackgroundTransparency = 1 },
                0.4, Enum.EasingStyle.Quad, IN)
        end

        -- 5. crossfade handoff: raise the veil above everything, start the next
        --    screen beneath it, then lift the black
        task.wait(0.3)
        gui.DisplayOrder = 1000000
        if onDone then task.spawn(onDone) end
        Util.tween(screen, { BackgroundTransparency = 1 }, 0.85,
            Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(0.95)
        alive = false
        gui:Destroy()
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

local function validateKey(key)
    if not _req or not key then return false end
    local ok, res = pcall(_req, { Url = BRIDGE .. "/validate?key=" .. urlencode(key), Method = "GET" })
    if not ok or type(res) ~= "table" then return false end
    local body = tostring(res.Body or "")
    return body:find('"ok"%s*:%s*true') ~= nil
end

local function bridgeConnectWithKey(key)
    if not validateKey(key) then return false end
    bridgeKey = key
    return true
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

    local refreshBtn = Instance.new("ImageButton")
    refreshBtn.Size = UDim2.fromOffset(30, 30)
    refreshBtn.Position = UDim2.new(1, -44, 0, (AB - 30) / 2)
    refreshBtn.BackgroundTransparency = 1
    refreshBtn.AutoButtonColor = false
    refreshBtn.ZIndex = 4
    refreshBtn.Parent = addr
    Icons.apply(refreshBtn, "globe", DIM)
    refreshBtn.MouseButton1Click:Connect(function()
        if urlField.Text == "sense://homepage" then showHomepage()
        elseif connected and liveImg then refreshFrame()
        else navigate(urlField.Text) end
    end)

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -(TB + AB))
    content.Position = UDim2.fromOffset(0, TB + AB)
    content.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.ZIndex = 3
    content.Parent = win

    local function clearContent()
        liveToken = liveToken + 1
        liveImg = nil
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
    local liveImg = nil

    local function refreshFrame()
        if not liveImg then return end
        task.spawn(function()
            local id = fetchFrame()
            if liveImg and id then
                liveImg.Image = id
                for _, ch in ipairs(content:GetChildren()) do
                    if ch:IsA("TextLabel") then ch.Visible = false end
                end
            end
        end)
    end

    local function showLive(url)
        if clockConn then clockConn:Disconnect(); clockConn = nil end
        clearContent()
        liveImg = nil
        urlField.Text = url

        local img = Instance.new("ImageButton")
        img.Size = UDim2.fromScale(1, 1)
        img.BackgroundTransparency = 1
        img.BorderSizePixel = 0
        img.AutoButtonColor = false
        img.ScaleType = Enum.ScaleType.Crop
        img.Image = ""
        img.ZIndex = 4
        img.Parent = content
        liveImg = img

        -- click -> normalized coords -> bridge (via global InputBegan for reliability)
        local aSize = 28
        local scrollHold = false
        local function scrollLoop(dy)
            scrollHold = true
            task.spawn(function()
                while scrollHold and liveImg == img do
                    reqRaw("/scroll?dy=" .. tostring(dy))
                    task.wait(0.12)
                    if liveImg == img then refreshFrame() end
                    task.wait(0.12)
                end
            end)
        end

        local clickConn
        clickConn = UserInputService.InputBegan:Connect(function(input, _g)
            local isRight = input.UserInputType == Enum.UserInputType.MouseButton2
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and not isRight then return end
            if not liveImg or liveImg ~= img then return end
            local ap, asz = img.AbsolutePosition, img.AbsoluteSize
            local pos = input.Position
            local lx, ly = pos.X - ap.X, pos.Y - ap.Y
            if lx < 0 or lx > asz.X or ly < 0 or ly > asz.Y then return end
            if asz.X <= 0 or asz.Y <= 0 then return end

            local margin = aSize + 20
            if lx > asz.X - margin and (ly < margin or ly > asz.Y - margin) then return end

            local nx = math.clamp(lx / asz.X, 0, 1)
            local ny = math.clamp(ly / asz.Y, 0, 1)

            if isRight then
                -- right-click: no dot, just send event
                task.spawn(function()
                    reqRaw("/click?x=" .. string.format("%.4f", nx) .. "&y=" .. string.format("%.4f", ny) .. "&button=right")
                    for _ = 1, 6 do
                        task.wait(0.4)
                        if liveImg ~= img then return end
                        local id = fetchFrame()
                        if id then liveImg.Image = id; return end
                    end
                end)
                return
            end

            local dot = Instance.new("Frame")
            local ds = 20
            dot.Size = UDim2.fromOffset(ds, ds)
            dot.Position = UDim2.fromOffset(lx - ds / 2, ly - ds / 2)
            dot.BackgroundColor3 = WHITE
            dot.BackgroundTransparency = 0.4
            dot.BorderSizePixel = 0
            dot.ZIndex = 10
            dot.Parent = content
            Util.corner(dot, ds)
            Util.tween(dot, { BackgroundTransparency = 1 }, 0.4)
            task.delay(0.5, function() pcall(function() dot:Destroy() end) end)

            task.spawn(function()
                reqRaw("/click?x=" .. string.format("%.4f", nx) .. "&y=" .. string.format("%.4f", ny))
                for _ = 1, 6 do
                    task.wait(0.4)
                    if liveImg ~= img then return end
                    local id = fetchFrame()
                    if id then liveImg.Image = id; return end
                end
            end)
        end)

        -- clean up click connection when content is cleared
        table.insert(conns, clickConn)

        -- no frame fetch here — wait for navigation to finish first (handled in navigate())

        local aUp = Instance.new("TextButton")
        aUp.Text = "▲"; aUp.Size = UDim2.fromOffset(aSize, aSize)
        aUp.Position = UDim2.new(1, -(aSize + 8), 0, 8)
        aUp.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
        aUp.BorderSizePixel = 0; aUp.AutoButtonColor = false
        aUp.Font = Theme.fonts.caption; aUp.TextSize = 13
        aUp.TextColor3 = DIM; aUp.ZIndex = 5; aUp.Parent = content
        Util.corner(aUp, 6)
        aUp.MouseButton1Down:Connect(function() scrollLoop(80) end)
        aUp.MouseButton1Up:Connect(function() scrollHold = false end)
        aUp.MouseLeave:Connect(function() scrollHold = false end)

        local aDown = Instance.new("TextButton")
        aDown.Text = "▼"; aDown.Size = UDim2.fromOffset(aSize, aSize)
        aDown.Position = UDim2.new(1, -(aSize + 8), 1, -(aSize + 8))
        aDown.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
        aDown.BorderSizePixel = 0; aDown.AutoButtonColor = false
        aDown.Font = Theme.fonts.caption; aDown.TextSize = 13
        aDown.TextColor3 = DIM; aDown.ZIndex = 5; aDown.Parent = content
        Util.corner(aDown, 6)
        aDown.MouseButton1Down:Connect(function() scrollLoop(-80) end)
        aDown.MouseButton1Up:Connect(function() scrollHold = false end)
        aDown.MouseLeave:Connect(function() scrollHold = false end)
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
        Util.autoCanvas(sc, "Y")
        sc.ZIndex = 4
        sc.Parent = content
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 16); pad.PaddingBottom = UDim.new(0, 16)
        pad.PaddingLeft = UDim.new(0, 24); pad.PaddingRight = UDim.new(0, 24)
        pad.Parent = sc
        local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 10); ll.Parent = sc

        local aSize = 28
        local aUp = Instance.new("TextButton")
        aUp.Text = "▲"; aUp.Size = UDim2.fromOffset(aSize, aSize)
        aUp.Position = UDim2.new(1, -(aSize + 8), 0, 8)
        aUp.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
        aUp.BorderSizePixel = 0; aUp.AutoButtonColor = false
        aUp.Font = Theme.fonts.caption; aUp.TextSize = 13
        aUp.TextColor3 = DIM; aUp.ZIndex = 5
        aUp.Parent = content; Util.corner(aUp, 6)

        local aDown = Instance.new("TextButton")
        aDown.Text = "▼"; aDown.Size = UDim2.fromOffset(aSize, aSize)
        aDown.Position = UDim2.new(1, -(aSize + 8), 1, -(aSize + 8))
        aDown.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
        aDown.BorderSizePixel = 0; aDown.AutoButtonColor = false
        aDown.Font = Theme.fonts.caption; aDown.TextSize = 13
        aDown.TextColor3 = DIM; aDown.ZIndex = 5
        aDown.Parent = content; Util.corner(aDown, 6)

        local step = 200
        aUp.MouseButton1Click:Connect(function()
            sc.CanvasPosition = Vector2.new(0, math.max(0, sc.CanvasPosition.Y - step))
        end)
        aDown.MouseButton1Click:Connect(function()
            sc.CanvasPosition = Vector2.new(0, math.min(sc.CanvasSize.Y.Offset - sc.AbsoluteSize.Y, sc.CanvasPosition.Y + step))
        end)

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
            task.spawn(function()
                reqRaw("/nav?url=" .. urlencode(url))
                for _ = 1, 12 do
                    task.wait(0.5)
                    if not liveImg then return end
                    local id = fetchFrame()
                    if id then liveImg.Image = id; return end
                end
            end)
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
        searchWrap.Size = UDim2.fromOffset(420, 48)
        searchWrap.Position = UDim2.fromScale(0.5, 0.6)
        searchWrap.AnchorPoint = Vector2.new(0.5, 0.5)
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

    -- ===== Key entry screen =====
    local function showKeyEntry(msg)
        if clockConn then clockConn:Disconnect(); clockConn = nil end
        clearContent()
        urlField.Text = "sense://unlock"
        status.Text = "○ Enter key to connect"
        status.TextColor3 = DIM

        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, 0, 1, 0)
        wrap.BackgroundTransparency = 1
        wrap.ZIndex = 4
        wrap.Parent = content

        local logoWrap = Instance.new("Frame")
        logoWrap.Size = UDim2.fromOffset(72, 72)
        logoWrap.AnchorPoint = Vector2.new(0.5, 0.5)
        logoWrap.Position = UDim2.fromScale(0.5, 0.25)
        logoWrap.BackgroundTransparency = 1
        logoWrap.ZIndex = 4
        logoWrap.Parent = wrap
        local logoId = Util.remoteImage(LOGO_URL, "sense-logo.png")
        if logoId then
            local im = Instance.new("ImageLabel")
            im.Size = UDim2.fromScale(1, 1); im.BackgroundTransparency = 1; im.Image = logoId; im.ZIndex = 4; im.Parent = logoWrap
        else
            drawSaturn(logoWrap, 56, WHITE)
        end

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 0)
        title.Position = UDim2.fromScale(0.5, 0.36)
        title.Size = UDim2.fromOffset(300, 24)
        title.BackgroundTransparency = 1
        title.Font = Theme.fonts.title
        title.TextSize = 16
        title.TextColor3 = WHITE
        title.Text = "Enter Sense Key"
        title.ZIndex = 4
        title.Parent = wrap

        local keyBox = Instance.new("TextBox")
        keyBox.AnchorPoint = Vector2.new(0.5, 0)
        keyBox.Position = UDim2.fromScale(0.5, 0.42)
        keyBox.Size = UDim2.fromOffset(400, 38)
        keyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
        keyBox.BorderSizePixel = 0
        keyBox.Font = Theme.fonts.body
        keyBox.TextSize = 14
        keyBox.TextColor3 = WHITE
        keyBox.PlaceholderText = "Paste your key here"
        keyBox.PlaceholderColor3 = DIM
        keyBox.Text = ""
        keyBox.TextXAlignment = Enum.TextXAlignment.Center
        keyBox.ClearTextOnFocus = false
        keyBox.ZIndex = 4
        keyBox.Parent = wrap
        Util.corner(keyBox, 19)

        local errorMsg = Instance.new("TextLabel")
        errorMsg.AnchorPoint = Vector2.new(0.5, 0)
        errorMsg.Position = UDim2.fromScale(0.5, 0.50)
        errorMsg.Size = UDim2.fromOffset(400, 18)
        errorMsg.BackgroundTransparency = 1
        errorMsg.Font = Theme.fonts.caption
        errorMsg.TextSize = 12
        errorMsg.TextColor3 = Color3.fromRGB(255, 80, 80)
        errorMsg.Text = msg or ""
        errorMsg.ZIndex = 4
        errorMsg.Parent = wrap

        local connectBtn = Instance.new("TextButton")
        connectBtn.AnchorPoint = Vector2.new(0.5, 0)
        connectBtn.Position = UDim2.fromScale(0.5, 0.55)
        connectBtn.Size = UDim2.fromOffset(160, 38)
        connectBtn.BackgroundColor3 = ACCENT
        connectBtn.BorderSizePixel = 0
        connectBtn.AutoButtonColor = false
        connectBtn.Font = Theme.fonts.title
        connectBtn.TextSize = 14
        connectBtn.TextColor3 = WHITE
        connectBtn.Text = "Connect"
        connectBtn.ZIndex = 4
        connectBtn.Parent = wrap
        Util.corner(connectBtn, 19)

        connectBtn.MouseButton1Click:Connect(function()
            local k = keyBox.Text:match("^%s*(.-)%s*$")
            if k == "" then return end
            errorMsg.Text = "Validating..."
            errorMsg.TextColor3 = DIM
            task.spawn(function()
                local ok = bridgeConnectWithKey(k)
                if Browser._gui ~= gui then return end
                if ok then
                    connected = true
                    status.Text = "● Connected to Sense Browser app"
                    status.TextColor3 = OK_GREEN
                    showHomepage()
                else
                    errorMsg.TextColor3 = Color3.fromRGB(255, 80, 80)
                    errorMsg.Text = "Invalid key. Check the app and try again."
                end
            end)
        end)

        keyBox.FocusLost:Connect(function(enter)
            if enter and keyBox.Text ~= "" then
                connectBtn.MouseButton1Click:Fire()
            end
        end)
    end

    showKeyEntry()

    -- Status polling: detect key changes / disconnection
    task.spawn(function()
        while Browser._gui == gui do
            task.wait(5)
            if connected then
                local body
                pcall(function() body = tostring(reqRaw("/validate?key=" .. urlencode(bridgeKey))) end)
                if Browser._gui ~= gui then break end
                if body and body:find('"ok"%s*:%s*true') then
                    -- key still valid
                else
                    connected = false
                    bridgeKey = nil
                    status.Text = "○ Key changed — re-enter key"
                    status.TextColor3 = DIM
                    showKeyEntry("Key changed or expired. Enter the new key from the app.")
                end
            end
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
local Cursor   = SYNC.import("apps/Cursor")
local Discord  = SYNC.import("apps/Discord")
local Scripting = SYNC.import("apps/Scripting")

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
        elseif appName == "Cursor" then
            Cursor.open()
        elseif appName == "Syncord" then
            Discord.open()
        elseif appName == "Scripting" then
            Scripting.open()
        end
    end)

    Cursor.restore()

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
    { name = "Cursor",    icon = "compass",         top = Color3.fromRGB(200, 140, 255), bot = Color3.fromRGB(130, 70, 210) },
    { name = "Syncord",   icon = "message-circle",  top = Color3.fromRGB(120, 134, 255), bot = Color3.fromRGB(76, 90, 235) },
    { name = "Scripting", icon = "terminal",            top = Color3.fromRGB(120, 200, 140), bot = Color3.fromRGB(50, 160, 110) },
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

SYNC.define("apps/Cursor", function()
-- SYNC / apps / Cursor
-- Custom cursor studio. Renders a real arrow-image cursor (solid or outline)
-- via a RenderStepped overlay and lets you fully customise it: colour, size,
-- outline, glow, opacity, rotation, gradient + rainbow / spin / pulse / trail /
-- click-ripple effects, plus saved named presets and a gallery of looks.
-- Cursor art is loaded from the SYNC repo via Util.remoteImage (getcustomasset).

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local GuiService       = game:GetService("GuiService")

local Theme  = SYNC.import("core/Theme")
local Util   = SYNC.import("core/Util")
local Slider = SYNC.import("ui/Slider")
local Switch = SYNC.import("ui/Switch")

local CursorApp = {}

local WHITE  = Color3.fromRGB(255, 255, 255)
local BLACK  = Color3.fromRGB(0, 0, 0)
local DIM    = Color3.fromRGB(150, 150, 158)
local PANEL  = Color3.fromRGB(44, 44, 48)
local ACCENT = Theme.accent

local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/cursors/"

-- Cursor artwork. `tintable` white masters recolour via ImageColor3; the fixed
-- full-colour `art` pieces render exactly as supplied. aspect = width / height.
local TIP = Vector2.new(0.07, 0.05)
local SHAPES = {
    { id = "solid",    name = "Solid",   url = RAW .. "arrow_solid.png",   file = "sync_cur_solid.png",   aspect = 256/254, tip = TIP, tintable = true },
    { id = "outline",  name = "Outline", url = RAW .. "arrow_outline.png", file = "sync_cur_outline.png", aspect = 229/256, tip = TIP, tintable = true },
    { id = "art_white", name = "Snow",     url = RAW .. "art_white.png", file = "sync_cur_white.png", aspect = 229/256, tip = TIP, tintable = false },
    { id = "art_navy",  name = "Graphite", url = RAW .. "art_navy.png",  file = "sync_cur_navy.png",  aspect = 256/256, tip = TIP, tintable = false },
    { id = "art_red",   name = "Crimson",  url = RAW .. "art_red.png",   file = "sync_cur_red.png",   aspect = 256/256, tip = TIP, tintable = false },
    { id = "art_grad",  name = "Aurora",   url = RAW .. "art_grad.png",  file = "sync_cur_grad.png",  aspect = 256/256, tip = TIP, tintable = false },
    { id = "art_glow",  name = "Glow",     url = RAW .. "art_glow.png",  file = "sync_cur_glow.png",  aspect = 0.828, tip = Vector2.new(0.104, 0.062), tintable = false },
    { id = "art_blue",  name = "Blue",     url = RAW .. "art_blue.png",  file = "sync_cur_blue.png",  aspect = 1.000, tip = Vector2.new(0.023, 0.062), tintable = false },
    -- Pack pieces (also valid shapes so shapeDef resolves them)
    { id = "sukuna_cursor",  name = "Sukuna",      url = RAW .. "sukuna_cursor.png",  file = "sync_cur_sukc.png", aspect = 0.707, tip = Vector2.new(0.144, 0.031), tintable = false },
    { id = "sukuna_pointer", name = "Sukuna Hand", url = RAW .. "sukuna_pointer.png", file = "sync_cur_sukp.png", aspect = 0.758, tip = Vector2.new(0.216, 0.047), tintable = false },
    -- UI icon only (not a cursor): the "no" symbol shown on the Default tile
    { id = "icon_none", name = "None", url = RAW .. "icon_none.png", file = "sync_icon_none.png", aspect = 1.0, tip = TIP, tintable = true },
}

-- Cursor packs: a matched cursor (idle) + pointer (shown while pressing)
local PACKS = {
    { id = "sukuna", name = "Sukuna", cursor = "sukuna_cursor", pointer = "sukuna_pointer" },
}
local function shapeDef(id)
    for _, s in ipairs(SHAPES) do if s.id == id then return s end end
    return SHAPES[1]
end

-- Bump CVER whenever cursor art changes so the on-disk cache filename changes
-- and executors re-download instead of serving a stale getcustomasset copy.
local CVER = "1"

-- asset id cache (resolved lazily; false = tried and failed)
local assetCache = {}
local assetFails = {}
local function assetFor(id)
    local d = shapeDef(id)
    if assetCache[id] == nil then
        local ok, res = pcall(Util.remoteImage, d.url, CVER .. "_" .. d.file)
        assetCache[id] = (ok and res) or false
    end
    return assetCache[id] or nil
end

local SWATCHES = {
    WHITE, BLACK, Color3.fromRGB(150,150,158),
    Color3.fromRGB(255,59,48),  Color3.fromRGB(255,149,0),  Color3.fromRGB(255,204,0),
    Color3.fromRGB(52,199,89),  Color3.fromRGB(90,200,255),  ACCENT,
    Color3.fromRGB(175,82,222), Color3.fromRGB(255,45,130),
}

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------
local function cfg(t)
    return {
        shape = t.shape or "solid",
        size = t.size or 30,
        color = t.color or WHITE,
        gradient = t.gradient or false,
        colorB = t.colorB or Color3.fromRGB(255, 45, 130),
        pointer = t.pointer or false,   -- pack pointer shape shown while pressing
        outline = t.outline ~= false,
        outlineColor = t.outlineColor or BLACK,
        outlineThickness = t.outlineThickness or 2,
        glow = t.glow or 0,
        opacity = t.opacity or 0,
        rotation = t.rotation or 0,
        rainbow = t.rainbow or false,
        spin = t.spin or false,
        pulse = t.pulse or false,
        trail = t.trail or 0,
        ripple = t.ripple ~= false,
    }
end

-- Overall tab: the two cursors the user supplied (each works as cursor + pointer)
local GALLERY = {
    { name = "Glow", conf = cfg{ shape="art_glow", outline=false } },
    { name = "Blue", conf = cfg{ shape="art_blue", outline=false } },
}

-- Serialisation (Color3 <-> {r,g,b})
local function c2t(c) return { math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5) } end
local function t2c(t) return Color3.fromRGB(t[1] or 255, t[2] or 255, t[3] or 255) end
local function encodeConfig(c)
    local copy = {}; for k, v in pairs(c) do copy[k] = v end
    copy.color = c2t(c.color); copy.colorB = c2t(c.colorB); copy.outlineColor = c2t(c.outlineColor)
    local ok, s = pcall(function() return HttpService:JSONEncode(copy) end)
    return ok and s or ""
end
local function decodeConfig(s)
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    if not ok or type(t) ~= "table" then return nil end
    if type(t.color) == "table" then t.color = t2c(t.color) end
    if type(t.colorB) == "table" then t.colorB = t2c(t.colorB) end
    if type(t.outlineColor) == "table" then t.outlineColor = t2c(t.outlineColor) end
    return cfg(t)
end

-- ===========================================================================
-- Overlay engine (singleton) — image-based, config driven
-- ===========================================================================
local overlayGui, root, conn, inputConn, endConn, mouseIconConn, focusConn
local mainImg, borderImg, glowImg, gradient
local trailImgs = {}
local rippleLayer
local history = {}
local config
local pressed = false
local watching = false
local onChangeCB

-- the shape shown right now: pack pointer while pressing, else the base shape
local function activeShapeId()
    if pressed and config and config.pointer then return config.pointer end
    return config and config.shape or "solid"
end

local function newImg(parent, z)
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.BorderSizePixel = 0
    img.ScaleType = Enum.ScaleType.Fit
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Position = UDim2.fromScale(0.5, 0.5)
    img.Size = UDim2.fromScale(1, 1)
    img.ZIndex = z
    img.Parent = parent
    return img
end

-- structural (re)build: image asset, border, glow existence, trail ghosts, gradient
local function rebuild()
    if not root then return end
    local def = shapeDef(config.shape)
    local asset = assetFor(config.shape)

    if not mainImg then mainImg = newImg(root, 999) end
    mainImg.Image = asset or ""

    -- border (a larger dark copy sitting behind the main image)
    if config.outline then
        if not borderImg then borderImg = newImg(root, 997) end
        borderImg.Image = asset or ""
    elseif borderImg then
        borderImg:Destroy(); borderImg = nil
    end

    -- gradient overlay on the main image (tintable masters only)
    if config.gradient and def.tintable then
        if not gradient then
            gradient = Instance.new("UIGradient")
            gradient.Rotation = 35
            gradient.Parent = mainImg
        end
        gradient.Color = ColorSequence.new(config.color, config.colorB)
    elseif gradient then
        gradient:Destroy(); gradient = nil
    end

    -- trail ghosts
    for _, g in ipairs(trailImgs) do g:Destroy() end
    trailImgs = {}
    local n = math.clamp(math.floor(config.trail or 0), 0, 10)
    for _ = 1, n do
        local g = Instance.new("ImageLabel")
        g.BackgroundTransparency = 1
        g.BorderSizePixel = 0
        g.ScaleType = Enum.ScaleType.Fit
        g.AnchorPoint = def.tip
        g.Image = asset or ""
        g.ZIndex = 995
        g.Parent = overlayGui
        table.insert(trailImgs, g)
    end
end

local function applyVisuals(color, size, rotation, opacity)
    local def = shapeDef(activeShapeId())
    local h = size
    local w = size * def.aspect
    if root then
        root.AnchorPoint = def.tip
        root.Size = UDim2.fromOffset(w, h)
        root.Rotation = rotation
    end
    if mainImg then
        mainImg.Image = assetFor(activeShapeId()) or mainImg.Image
        -- fixed art keeps its own colours; masters take the live tint/gradient
        if not def.tintable then
            mainImg.ImageColor3 = WHITE
        else
            mainImg.ImageColor3 = config.gradient and WHITE or color
            if gradient then gradient.Color = ColorSequence.new(color, config.colorB) end
        end
        mainImg.ImageTransparency = opacity
    end
    if borderImg then
        local th = math.clamp(config.outlineThickness or 2, 1, 6)
        borderImg.ImageColor3 = config.outlineColor
        borderImg.ImageTransparency = opacity
        borderImg.Size = UDim2.new(1, th * 2, 1, th * 2)
        borderImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
    -- glow: enlarged faded tinted copy behind everything (live managed)
    if config.glow and config.glow > 0 then
        if not glowImg then glowImg = newImg(root, 996); glowImg.Image = mainImg and mainImg.Image or "" end
        glowImg.Image = mainImg and mainImg.Image or ""
        local gf = 1 + config.glow * 0.9
        glowImg.Size = UDim2.fromScale(gf, gf)
        glowImg.ImageColor3 = color
        glowImg.ImageTransparency = math.clamp(1 - config.glow * 0.65, 0, 1)
    elseif glowImg then
        glowImg:Destroy(); glowImg = nil
    end
end

-- Unique token for this execution. If the script is re-run, a new module load
-- replaces _G.__SYNC_CURSOR_GEN, and any loops from the old run see the mismatch
-- and stop themselves -- so re-executing never stacks ghost cursors.
local GEN = {}
pcall(function() _G.__SYNC_CURSOR_GEN = GEN end)
local function isCurrentGen() return _G.__SYNC_CURSOR_GEN == GEN end

-- Remove overlays left behind by a previous execution.
local function destroyOldOverlays()
    local parents = {}
    pcall(function() if typeof(gethui) == "function" then parents[#parents + 1] = gethui() end end)
    pcall(function() parents[#parents + 1] = game:GetService("CoreGui") end)
    pcall(function() parents[#parents + 1] = Util.localPlayer():FindFirstChild("PlayerGui") end)
    for _, p in ipairs(parents) do
        if p then
            for _, ch in ipairs(p:GetChildren()) do
                if ch.Name == "SYNC_CursorOverlay" then pcall(function() ch:Destroy() end) end
            end
        end
    end
end

-- Tear down connections + instance refs WITHOUT restoring the system cursor
-- (used by the watchdog when rebuilding after a wipe). Safe to call any time.
local function resetRefs()
    for _, c in ipairs({ conn, inputConn, endConn, mouseIconConn, focusConn }) do
        if c then pcall(function() c:Disconnect() end) end
    end
    conn, inputConn, endConn, mouseIconConn, focusConn = nil, nil, nil, nil, nil
    if overlayGui then pcall(function() overlayGui:Destroy() end) end
    overlayGui, root, mainImg, borderImg, glowImg, gradient, rippleLayer =
        nil, nil, nil, nil, nil, nil, nil
    trailImgs, history = {}, {}
end

local startOverlay  -- fwd decl (watchdog rebuilds via it)

-- Watchdog: some games periodically wipe CoreGui to kill exploit UIs. If our
-- overlay vanishes while a cursor is active, silently rebuild it.
local function startWatchdog()
    if watching then return end
    watching = true
    task.spawn(function()
        while config and isCurrentGen() do
            task.wait(1)
            if config and isCurrentGen() and (overlayGui == nil or overlayGui.Parent == nil) then
                resetRefs()
                startOverlay()
            end
        end
        watching = false
    end)
end

function startOverlay()
    if overlayGui and overlayGui.Parent then return end
    if overlayGui then resetRefs() end
    destroyOldOverlays()
    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "SYNC_CursorOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.DisplayOrder = 999999
    overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Util.mount(overlayGui)
    -- Util.mount sets DisplayOrder 999999 for every SYNC gui, so app windows
    -- opened later would tie and draw over the cursor. Force this above all.
    pcall(function() overlayGui.DisplayOrder = 2147483647 end)
    -- IgnoreGuiInset = false is the pairing that matches GetMouseLocation 1:1, so
    -- the cursor sits exactly on the OS pointer and clicks land where you see it.
    overlayGui.IgnoreGuiInset = false

    rippleLayer = Instance.new("Frame")
    rippleLayer.Size = UDim2.fromScale(1, 1)
    rippleLayer.BackgroundTransparency = 1
    rippleLayer.BorderSizePixel = 0
    rippleLayer.ZIndex = 994
    rippleLayer.Parent = overlayGui

    root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ZIndex = 995
    root.Parent = overlayGui

    rebuild()

    local clock = 0
    local refreshAcc = 0
    conn = RunService.RenderStepped:Connect(function(dt)
        if not isCurrentGen() then if conn then conn:Disconnect(); conn = nil end return end
        if not config then return end
        if not (root and root.Parent) then return end  -- wiped; watchdog will rebuild
        clock = clock + dt
        local m = UserInputService:GetMouseLocation()

        -- Every frame: if the system cursor is showing while ours is active, hide
        -- it. Alt-tabbing away and back re-enables it; this kills it within a
        -- frame so users never see both cursors at once.
        if mainImg and mainImg.Image ~= "" and UserInputService.MouseIconEnabled then
            pcall(function() UserInputService.MouseIconEnabled = false end)
        end

        -- once a second, re-assert state so nothing drifts: if the art failed to
        -- load fall back to the normal cursor (instead of an invisible "none"),
        -- otherwise keep the system cursor hidden and show ours.
        refreshAcc = refreshAcc + dt
        if refreshAcc >= 1 then
            refreshAcc = 0
            local id = activeShapeId()
            local a = assetFor(id)
            if not a then
                assetFails[id] = (assetFails[id] or 0) + 1
                if assetFails[id] <= 5 then assetCache[id] = nil end  -- retry, capped
            else
                assetFails[id] = nil
            end
            pcall(function() UserInputService.MouseIconEnabled = (a == nil) end)
            -- resync press state in case an InputEnded was missed over sinking UI
            pcall(function()
                pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            end)
        end

        local color = config.color
        if config.rainbow then color = Color3.fromHSV((clock * 0.3) % 1, 0.85, 1) end
        local size = config.size
        if config.pulse then size = size * (1 + 0.16 * math.sin(clock * 4)) end
        local rot = config.rotation
        if config.spin then rot = (rot + clock * 200) % 360 end

        root.Position = UDim2.fromOffset(m.X, m.Y)
        applyVisuals(color, size, rot, config.opacity)

        if #trailImgs > 0 then
            local def = shapeDef(config.shape)
            local w = size * def.aspect
            table.insert(history, 1, Vector2.new(m.X, m.Y))
            local maxHist = #trailImgs * 3 + 2
            while #history > maxHist do table.remove(history) end
            for i, g in ipairs(trailImgs) do
                local samp = history[math.min(i * 3 + 1, #history)]
                if samp then
                    g.Position = UDim2.fromOffset(samp.X, samp.Y)
                    g.Size = UDim2.fromOffset(w, size)
                    g.ImageColor3 = color
                    g.ImageTransparency = math.clamp(0.25 + (i / (#trailImgs + 1)) * 0.7, 0, 0.95)
                end
            end
        end
    end)

    endConn = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then pressed = false end
    end)

    inputConn = UserInputService.InputBegan:Connect(function(inp)
        if not config then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        pressed = true
        if not config.ripple then return end
        local ml = UserInputService:GetMouseLocation()
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromOffset(ml.X, ml.Y)
        ring.Size = UDim2.fromOffset(8, 8)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel = 0
        ring.ZIndex = 998
        ring.Parent = rippleLayer
        Util.corner(ring, 999)
        local col = config.rainbow and Color3.fromHSV((clock*0.3)%1, 0.85, 1) or config.color
        Util.stroke(ring, col, 2, 0.1)
        Util.tween(ring, { Size = UDim2.fromOffset(46, 46) }, 0.45)
        local s = ring:FindFirstChildOfClass("UIStroke")
        if s then Util.tween(s, { Transparency = 1 }, 0.45) end
        task.delay(0.5, function() ring:Destroy() end)
    end)

    -- Re-hide the system cursor if a game tries to turn it back on (the classic
    -- reason custom cursors flicker / double up for other people).
    mouseIconConn = UserInputService:GetPropertyChangedSignal("MouseIconEnabled"):Connect(function()
        if config and UserInputService.MouseIconEnabled and assetFor(activeShapeId()) then
            pcall(function() UserInputService.MouseIconEnabled = false end)
        end
    end)

    -- Alt-tabbing back into Roblox re-shows the system cursor; re-hide on focus.
    focusConn = UserInputService.WindowFocused:Connect(function()
        if config and assetFor(activeShapeId()) then
            pcall(function() UserInputService.MouseIconEnabled = false end)
        end
    end)

    -- hide the system cursor only if our art is ready; the 1s loop keeps this true
    pcall(function() UserInputService.MouseIconEnabled = (assetFor(activeShapeId()) == nil) end)

    startWatchdog()
end

local function stopOverlay()
    if conn then conn:Disconnect(); conn = nil end
    if inputConn then inputConn:Disconnect(); inputConn = nil end
    if endConn then endConn:Disconnect(); endConn = nil end
    if mouseIconConn then mouseIconConn:Disconnect(); mouseIconConn = nil end
    if focusConn then focusConn:Disconnect(); focusConn = nil end
    pressed = false
    if overlayGui then overlayGui:Destroy(); overlayGui = nil end
    root, mainImg, borderImg, glowImg, gradient, rippleLayer = nil, nil, nil, nil, nil, nil
    trailImgs, history = {}, {}
    pcall(function() UserInputService.MouseIconEnabled = true end)
end

-- debounced save
local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.4, function()
        saveQueued = false
        if config then Util.save("CursorConfig", encodeConfig(config)) end
    end)
end

local function setConfig(newCfg, skipSave)
    config = newCfg
    if not overlayGui then startOverlay() end
    rebuild()
    if not skipSave then queueSave() end
    if onChangeCB then onChangeCB() end
end

local STRUCTURAL = { shape = true, outline = true, trail = true, gradient = true }
local function setField(key, value)
    if not config then return end
    if config[key] == value then return end
    config[key] = value
    if STRUCTURAL[key] then rebuild() end
    queueSave()
    if onChangeCB then onChangeCB() end
end

local function restoreSaved()
    local saved = Util.load("CursorConfig")
    if not saved or saved == "" then return end
    local c = decodeConfig(saved)
    if c then setConfig(c, true) end
end

local function loadPresets()
    local raw = Util.load("CursorPresets")
    if not raw or raw == "" then return {} end
    local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and type(t) == "table" then return t end
    return {}
end
local function savePresets(list) Util.save("CursorPresets", HttpService:JSONEncode(list)) end

-- ===========================================================================
-- UI
-- ===========================================================================
CursorApp._gui = nil

function CursorApp.open()
    if CursorApp._gui then return end

    if not config then
        setConfig(cfg{ shape = "solid", color = WHITE }, true)
    elseif not overlayGui then
        startOverlay()
    end

    local W, H = 520, 470
    local vp = Util.viewport()
    local cardX, cardY = (vp.X - W) / 2, (vp.Y - H) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Cursor"
    Util.mount(gui)
    CursorApp._gui = gui

    local winConns = {}
    local function close()
        if not CursorApp._gui then return end
        CursorApp._gui = nil
        onChangeCB = nil
        for _, c in ipairs(winConns) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end
    -- No full-screen click-catcher: the window closes only via the red button,
    -- so tapping tabs / the panel / elsewhere never dismisses it.

    -- Window
    local TB = 38
    local win = Instance.new("TextButton")
    win.Text = ""; win.AutoButtonColor = false
    win.Position = UDim2.fromOffset(cardX, cardY)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(32, 32, 35)
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
    bar.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
    bar.BackgroundTransparency = 0.12
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local barCorner = Instance.new("UICorner")
    local okBar = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 12)
        barCorner.TopRightRadius = UDim.new(0, 12)
        barCorner.BottomLeftRadius = UDim.new(0, 0)
        barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okBar then barCorner.CornerRadius = UDim.new(0, 12) end
    barCorner.Parent = bar

    -- Drag the window by its title bar
    bar.Active = true
    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            win.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local hair = Instance.new("Frame")
    hair.Size = UDim2.new(1, 0, 0, 1)
    hair.Position = UDim2.new(0, 0, 1, 0)
    hair.BackgroundColor3 = BLACK
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
    title.Text = "Custom Cursor"
    title.Font = Theme.fonts.title
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(210, 210, 216)
    title.ZIndex = 3
    title.Parent = bar

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 38)
    tabBar.Position = UDim2.fromOffset(0, TB)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 3
    tabBar.Parent = win

    local contentY = TB + 38
    local contentH = H - contentY

    local galleryPage, customPage, packsPage
    local tabButtons = {}
    local function selectTab(name)
        galleryPage.Visible = (name == "Overall")
        customPage.Visible  = (name == "Customize")
        if packsPage then packsPage.Visible = (name == "Packs") end
        for _, t in ipairs(tabButtons) do
            local on = t.name == name
            Util.tween(t.under, { BackgroundTransparency = on and 0 or 1 }, 0.15)
            t.label.TextColor3 = on and WHITE or DIM
        end
    end

    for i, name in ipairs({ "Overall", "Customize", "Packs" }) do
        local holder = Instance.new("Frame")
        holder.Size = UDim2.fromOffset(110, 38)
        holder.Position = UDim2.fromOffset(14 + (i - 1) * 112, 0)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 3
        holder.Parent = tabBar
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = Theme.fonts.body
        lbl.TextSize = 13
        lbl.TextColor3 = i == 1 and WHITE or DIM
        lbl.ZIndex = 3
        lbl.Parent = holder
        local under = Instance.new("Frame")
        under.Size = UDim2.new(1, -20, 0, 2)
        under.Position = UDim2.new(0, 10, 1, -4)
        under.BackgroundColor3 = ACCENT
        under.BackgroundTransparency = i == 1 and 0 or 1
        under.BorderSizePixel = 0
        under.ZIndex = 3
        under.Parent = holder
        Util.corner(under, 1)
        local btn = Instance.new("TextButton")
        btn.Text = ""; btn.AutoButtonColor = false
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.ZIndex = 4
        btn.Parent = holder
        btn.MouseButton1Click:Connect(function() selectTab(name) end)
        table.insert(tabButtons, { name = name, label = lbl, under = under })
    end

    -- =======================================================================
    -- GALLERY
    -- =======================================================================
    galleryPage = Instance.new("ScrollingFrame")
    galleryPage.Size = UDim2.fromOffset(W, contentH)
    galleryPage.Position = UDim2.fromOffset(0, contentY)
    galleryPage.BackgroundTransparency = 1
    galleryPage.BorderSizePixel = 0
    galleryPage.ScrollBarThickness = 4
    galleryPage.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128)
    galleryPage.ScrollBarImageTransparency = 0.4
    galleryPage.CanvasSize = UDim2.fromOffset(0, 0)
    galleryPage.ZIndex = 3
    galleryPage.Parent = win

    do
        local CELL_W, CELL_H, PAD = 110, 100, 12
        local COLS = math.max(1, math.floor((W - 24 + PAD) / (CELL_W + PAD)))
        local col, row = 0, 0
        -- "Default" tile first (restores the normal system cursor), then the two
        local items = { { name = "Default", default = true } }
        for _, g in ipairs(GALLERY) do items[#items + 1] = g end
        for _, g in ipairs(items) do
            local x = col * (CELL_W + PAD) + PAD
            local y = row * (CELL_H + PAD) + PAD
            local frame = Instance.new("TextButton")
            frame.Text = ""; frame.AutoButtonColor = false
            frame.Size = UDim2.fromOffset(CELL_W, CELL_H)
            frame.Position = UDim2.fromOffset(x, y)
            frame.BackgroundColor3 = PANEL
            frame.BackgroundTransparency = 0.12
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = galleryPage
            Util.corner(frame, 10)
            Util.stroke(frame, WHITE, 1, 0.9)

            if g.default then
                local noimg = Instance.new("ImageLabel")
                noimg.Size = UDim2.fromOffset(42, 42)
                noimg.Position = UDim2.fromScale(0.5, 0.42)
                noimg.AnchorPoint = Vector2.new(0.5, 0.5)
                noimg.BackgroundTransparency = 1
                noimg.ScaleType = Enum.ScaleType.Fit
                noimg.Image = assetFor("icon_none") or ""
                noimg.ImageColor3 = Color3.fromRGB(170, 170, 178)
                noimg.ZIndex = 5
                noimg.Parent = frame
            else
                local prev = Instance.new("ImageLabel")
                prev.Size = UDim2.fromOffset(46, 46)
                prev.Position = UDim2.fromScale(0.5, 0.42)
                prev.AnchorPoint = Vector2.new(0.5, 0.5)
                prev.BackgroundTransparency = 1
                prev.ScaleType = Enum.ScaleType.Fit
                prev.Image = assetFor(g.conf.shape) or ""
                prev.ImageColor3 = g.conf.gradient and WHITE or g.conf.color
                prev.ZIndex = 5
                prev.Parent = frame
                if g.conf.gradient then
                    local gr = Instance.new("UIGradient")
                    gr.Rotation = 35
                    gr.Color = ColorSequence.new(g.conf.color, g.conf.colorB)
                    gr.Parent = prev
                end
            end

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -8, 0, 16)
            nameLbl.Position = UDim2.new(0, 4, 1, -20)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.fonts.caption
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = DIM
            nameLbl.Text = g.name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Center
            nameLbl.ZIndex = 5
            nameLbl.Parent = frame

            frame.MouseButton1Click:Connect(function()
                if g.default then
                    stopOverlay()
                    config = nil
                    Util.save("CursorConfig", "")
                    return
                end
                local c = {}; for k, v in pairs(g.conf) do c[k] = v end
                setConfig(cfg(c))
                selectTab("Customize")
            end)

            col = col + 1
            if col >= COLS then col = 0; row = row + 1 end
        end
        local totalRows = row + (col > 0 and 1 or 0)
        galleryPage.CanvasSize = UDim2.fromOffset(0, totalRows * (CELL_H + PAD) + PAD)
    end

    -- =======================================================================
    -- PACKS  (matched cursor + pointer; pointer shows while the mouse is held)
    -- =======================================================================
    packsPage = Instance.new("ScrollingFrame")
    packsPage.Size = UDim2.fromOffset(W, contentH)
    packsPage.Position = UDim2.fromOffset(0, contentY)
    packsPage.Visible = false
    packsPage.BackgroundTransparency = 1
    packsPage.BorderSizePixel = 0
    packsPage.ScrollBarThickness = 4
    packsPage.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128)
    packsPage.ScrollBarImageTransparency = 0.4
    packsPage.CanvasSize = UDim2.fromOffset(0, 0)
    Util.autoCanvas(packsPage, "Y")
    packsPage.ZIndex = 3
    packsPage.Parent = win
    do
        local play = Instance.new("UIListLayout")
        play.Padding = UDim.new(0, 12)
        play.SortOrder = Enum.SortOrder.LayoutOrder
        play.Parent = packsPage
        local ppad = Instance.new("UIPadding")
        ppad.PaddingTop = UDim.new(0, 14); ppad.PaddingLeft = UDim.new(0, 14)
        ppad.PaddingRight = UDim.new(0, 14); ppad.PaddingBottom = UDim.new(0, 14)
        ppad.Parent = packsPage

        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(1, 0, 0, 16)
        hint.BackgroundTransparency = 1
        hint.Text = "A pack pairs a cursor with a pointer shown while you hold click."
        hint.Font = Theme.fonts.caption
        hint.TextSize = 11
        hint.TextColor3 = DIM
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.LayoutOrder = 0
        hint.ZIndex = 3
        hint.Parent = packsPage

        for pi, pack in ipairs(PACKS) do
            local card = Instance.new("TextButton")
            card.Text = ""; card.AutoButtonColor = false
            card.Size = UDim2.new(1, 0, 0, 92)
            card.BackgroundColor3 = PANEL
            card.BackgroundTransparency = 0.12
            card.BorderSizePixel = 0
            card.LayoutOrder = pi
            card.ZIndex = 3
            card.Parent = packsPage
            Util.corner(card, 12)
            Util.stroke(card, WHITE, 1, 0.9)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(0, 200, 0, 22)
            nm.Position = UDim2.fromOffset(16, 14)
            nm.BackgroundTransparency = 1
            nm.Text = pack.name
            nm.Font = Theme.fonts.title
            nm.TextSize = 16
            nm.TextColor3 = WHITE
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.ZIndex = 4
            nm.Parent = card

            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(0, 220, 0, 16)
            sub.Position = UDim2.fromOffset(16, 40)
            sub.BackgroundTransparency = 1
            sub.Text = "Cursor + Pointer"
            sub.Font = Theme.fonts.caption
            sub.TextSize = 11
            sub.TextColor3 = DIM
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.ZIndex = 4
            sub.Parent = card

            -- two preview tiles on the right
            local function tile(xoff, shapeId, label)
                local t = Instance.new("Frame")
                t.Size = UDim2.fromOffset(64, 64)
                t.Position = UDim2.new(1, xoff, 0.5, -32)
                t.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
                t.BackgroundTransparency = 0.2
                t.BorderSizePixel = 0
                t.ZIndex = 4
                t.Parent = card
                Util.corner(t, 8)
                local im = Instance.new("ImageLabel")
                im.Size = UDim2.fromOffset(40, 40)
                im.Position = UDim2.fromScale(0.5, 0.46)
                im.AnchorPoint = Vector2.new(0.5, 0.5)
                im.BackgroundTransparency = 1
                im.ScaleType = Enum.ScaleType.Fit
                im.Image = assetFor(shapeId) or ""
                im.ZIndex = 5
                im.Parent = t
                local lb = Instance.new("TextLabel")
                lb.Size = UDim2.new(1, 0, 0, 12)
                lb.Position = UDim2.new(0, 0, 1, -13)
                lb.BackgroundTransparency = 1
                lb.Text = label
                lb.Font = Theme.fonts.caption
                lb.TextSize = 9
                lb.TextColor3 = DIM
                lb.ZIndex = 5
                lb.Parent = t
            end
            tile(-152, pack.cursor, "Cursor")
            tile(-80, pack.pointer, "Pointer")

            card.MouseButton1Click:Connect(function()
                setConfig(cfg{ shape = pack.cursor, pointer = pack.pointer, outline = false })
            end)
        end
    end

    -- =======================================================================
    -- CUSTOMIZE
    -- =======================================================================
    customPage = Instance.new("ScrollingFrame")
    customPage.Size = UDim2.fromOffset(W, contentH)
    customPage.Position = UDim2.fromOffset(0, contentY)
    customPage.Visible = false
    customPage.BackgroundTransparency = 1
    customPage.BorderSizePixel = 0
    customPage.ScrollBarThickness = 4
    customPage.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128)
    customPage.ScrollBarImageTransparency = 0.4
    customPage.CanvasSize = UDim2.fromOffset(0, 0)
    Util.autoCanvas(customPage, "Y")
    customPage.ZIndex = 3
    customPage.Parent = win

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = customPage
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = customPage

    local order = 0
    local function nextOrder() order = order + 1; return order end

    -- Live preview
    local previewBox = Instance.new("Frame")
    previewBox.Size = UDim2.new(1, 0, 0, 96)
    previewBox.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
    previewBox.BackgroundTransparency = 0.1
    previewBox.BorderSizePixel = 0
    previewBox.LayoutOrder = nextOrder()
    previewBox.ZIndex = 3
    previewBox.Parent = customPage
    Util.corner(previewBox, 10)
    Util.stroke(previewBox, WHITE, 1, 0.92)
    local previewImg = Instance.new("ImageLabel")
    previewImg.Size = UDim2.fromOffset(56, 56)
    previewImg.Position = UDim2.fromScale(0.5, 0.5)
    previewImg.AnchorPoint = Vector2.new(0.5, 0.5)
    previewImg.BackgroundTransparency = 1
    previewImg.ScaleType = Enum.ScaleType.Fit
    previewImg.ZIndex = 5
    previewImg.Parent = previewBox
    local previewGrad = Instance.new("UIGradient"); previewGrad.Rotation = 35; previewGrad.Parent = previewImg
    previewGrad.Enabled = false

    local function sectionLabel(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 16)
        l.BackgroundTransparency = 1
        l.Text = string.upper(text)
        l.Font = Theme.fonts.caption
        l.TextSize = 11
        l.TextColor3 = Color3.fromRGB(120, 120, 128)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = nextOrder()
        l.ZIndex = 3
        l.Parent = customPage
        return l
    end

    local function row(labelText, height)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, 0, 0, height or 30)
        r.BackgroundTransparency = 1
        r.LayoutOrder = nextOrder()
        r.ZIndex = 3
        r.Parent = customPage
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0, 110, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = labelText
        l.Font = Theme.fonts.body
        l.TextSize = 13
        l.TextColor3 = Color3.fromRGB(220, 220, 226)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 3
        l.Parent = r
        return r
    end

    local function swatchRow(getCurrent, onPick)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, 0, 0, 28)
        r.BackgroundTransparency = 1
        r.LayoutOrder = nextOrder()
        r.ZIndex = 3
        r.Parent = customPage
        local lay = Instance.new("UIListLayout")
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.Padding = UDim.new(0, 6)
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.Parent = r
        local rings = {}
        local function refresh()
            local cur = getCurrent()
            for _, sw in ipairs(rings) do sw.ring.Transparency = (sw.col == cur) and 0 or 1 end
        end
        for _, colr in ipairs(SWATCHES) do
            local cell = Instance.new("TextButton")
            cell.Text = ""; cell.AutoButtonColor = false
            cell.Size = UDim2.fromOffset(24, 24)
            cell.BackgroundColor3 = colr
            cell.BorderSizePixel = 0
            cell.ZIndex = 4
            cell.Parent = r
            Util.corner(cell, 12)
            local ring = Util.stroke(cell, ACCENT, 2, 1)
            cell.MouseButton1Click:Connect(function() onPick(colr); refresh() end)
            table.insert(rings, { col = colr, ring = ring })
        end
        return refresh
    end

    -- SHAPE (image thumbnails)
    sectionLabel("Shape")
    local shapeRowF = Instance.new("Frame")
    shapeRowF.Size = UDim2.new(1, 0, 0, 56)
    shapeRowF.BackgroundTransparency = 1
    shapeRowF.LayoutOrder = nextOrder()
    shapeRowF.ZIndex = 3
    shapeRowF.Parent = customPage
    local shapeLay = Instance.new("UIListLayout")
    shapeLay.FillDirection = Enum.FillDirection.Horizontal
    shapeLay.Padding = UDim.new(0, 10)
    shapeLay.VerticalAlignment = Enum.VerticalAlignment.Center
    shapeLay.Parent = shapeRowF
    local shapeCells = {}
    local function refreshShapes()
        for _, sc in ipairs(shapeCells) do
            local on = sc.id == config.shape
            Util.tween(sc.cell, { BackgroundTransparency = on and 0 or 0.12 }, 0.12)
            sc.cell.BackgroundColor3 = on and ACCENT or PANEL
        end
    end
    for _, s in ipairs(SHAPES) do
      if s.tintable then
        local cell = Instance.new("TextButton")
        cell.Text = ""; cell.AutoButtonColor = false
        cell.Size = UDim2.fromOffset(56, 56)
        cell.BackgroundColor3 = PANEL
        cell.BackgroundTransparency = 0.12
        cell.BorderSizePixel = 0
        cell.ZIndex = 4
        cell.Parent = shapeRowF
        Util.corner(cell, 10)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(34, 34)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.BackgroundTransparency = 1
        ic.ScaleType = Enum.ScaleType.Fit
        ic.Image = assetFor(s.id) or ""
        ic.ZIndex = 5
        ic.Parent = cell
        cell.MouseButton1Click:Connect(function() setField("shape", s.id); refreshShapes() end)
        table.insert(shapeCells, { id = s.id, cell = cell })
      end
    end

    -- SIZE
    local SIZE_MIN, SIZE_MAX = 14, 70
    local sizeRow = row("Size")
    local sizeHolder = Instance.new("Frame")
    sizeHolder.Size = UDim2.new(1, -120, 0, 20); sizeHolder.Position = UDim2.fromOffset(110, 5)
    sizeHolder.BackgroundTransparency = 1; sizeHolder.ZIndex = 3; sizeHolder.Parent = sizeRow
    local sizeSlider = Slider.create(sizeHolder, (config.size - SIZE_MIN) / (SIZE_MAX - SIZE_MIN), function(v)
        setField("size", math.floor(SIZE_MIN + v * (SIZE_MAX - SIZE_MIN) + 0.5))
    end)

    -- COLOUR
    sectionLabel("Colour")
    local hueRow = row("Hue", 24)
    local hueHolder = Instance.new("Frame")
    hueHolder.Size = UDim2.new(1, -120, 0, 20); hueHolder.Position = UDim2.fromOffset(110, 2)
    hueHolder.BackgroundTransparency = 1; hueHolder.ZIndex = 3; hueHolder.Parent = hueRow
    Slider.create(hueHolder, 0, function(v) setField("color", Color3.fromHSV(v, 0.85, 1)) end)
    local refreshColorSwatch = swatchRow(function() return config.color end, function(c) setField("color", c) end)

    -- GRADIENT
    local gradRow = row("Gradient")
    local gradSwH = Instance.new("Frame")
    gradSwH.Size = UDim2.fromOffset(54, 26); gradSwH.Position = UDim2.new(1, -54, 0.5, -13)
    gradSwH.BackgroundTransparency = 1; gradSwH.ZIndex = 3; gradSwH.Parent = gradRow
    Switch.create(gradSwH, config.gradient, function(on) setField("gradient", on) end)
    local gradEndLbl = sectionLabel("Gradient end")
    local refreshGradSwatch = swatchRow(function() return config.colorB end, function(c) setField("colorB", c) end)

    -- OUTLINE
    sectionLabel("Outline")
    local outRow = row("Enabled")
    local outSwH = Instance.new("Frame")
    outSwH.Size = UDim2.fromOffset(54, 26); outSwH.Position = UDim2.new(1, -54, 0.5, -13)
    outSwH.BackgroundTransparency = 1; outSwH.ZIndex = 3; outSwH.Parent = outRow
    Switch.create(outSwH, config.outline, function(on) setField("outline", on) end)
    local thickRow = row("Thickness")
    local thickHolder = Instance.new("Frame")
    thickHolder.Size = UDim2.new(1, -120, 0, 20); thickHolder.Position = UDim2.fromOffset(110, 5)
    thickHolder.BackgroundTransparency = 1; thickHolder.ZIndex = 3; thickHolder.Parent = thickRow
    local thickSlider = Slider.create(thickHolder, (config.outlineThickness - 1) / 5, function(v)
        setField("outlineThickness", 1 + math.floor(v * 5 + 0.5))
    end)
    local refreshOutlineSwatch = swatchRow(function() return config.outlineColor end, function(c) setField("outlineColor", c) end)

    -- STYLE
    sectionLabel("Style")
    local function sliderRow(labelText, initial, onChange)
        local r = row(labelText)
        local hold = Instance.new("Frame")
        hold.Size = UDim2.new(1, -120, 0, 20); hold.Position = UDim2.fromOffset(110, 5)
        hold.BackgroundTransparency = 1; hold.ZIndex = 3; hold.Parent = r
        return Slider.create(hold, initial, onChange)
    end
    local glowSlider = sliderRow("Glow", config.glow, function(v) setField("glow", v) end)
    local opacitySlider = sliderRow("Opacity", config.opacity, function(v) setField("opacity", v) end)
    local rotSlider = sliderRow("Rotation", config.rotation / 360, function(v) setField("rotation", math.floor(v * 360 + 0.5)) end)

    -- EFFECTS
    sectionLabel("Effects")
    local function switchRow(labelText, getv, onChange)
        local r = row(labelText)
        local hold = Instance.new("Frame")
        hold.Size = UDim2.fromOffset(54, 26); hold.Position = UDim2.new(1, -54, 0.5, -13)
        hold.BackgroundTransparency = 1; hold.ZIndex = 3; hold.Parent = r
        Switch.create(hold, getv, onChange)
    end
    switchRow("Rainbow", config.rainbow, function(on) setField("rainbow", on) end)
    switchRow("Spin", config.spin, function(on) setField("spin", on) end)
    switchRow("Pulse", config.pulse, function(on) setField("pulse", on) end)
    switchRow("Click ripple", config.ripple, function(on) setField("ripple", on) end)
    local trailR = sliderRow("Trail", config.trail / 10, function(v) setField("trail", math.floor(v * 10 + 0.5)) end)

    -- PRESETS
    sectionLabel("My Presets")
    local presetWrap = Instance.new("Frame")
    presetWrap.Size = UDim2.new(1, 0, 0, 34)
    presetWrap.BackgroundTransparency = 1
    presetWrap.LayoutOrder = nextOrder()
    presetWrap.ZIndex = 3
    presetWrap.Parent = customPage
    local presetScroll = Instance.new("ScrollingFrame")
    presetScroll.Size = UDim2.new(1, -90, 1, 0)
    presetScroll.BackgroundTransparency = 1
    presetScroll.BorderSizePixel = 0
    presetScroll.ScrollBarThickness = 0
    presetScroll.ScrollingDirection = Enum.ScrollingDirection.X
    Util.autoCanvas(presetScroll, "X")
    presetScroll.CanvasSize = UDim2.fromOffset(0, 0)
    presetScroll.ZIndex = 4
    presetScroll.Parent = presetWrap
    local presetLay = Instance.new("UIListLayout")
    presetLay.FillDirection = Enum.FillDirection.Horizontal
    presetLay.Padding = UDim.new(0, 6)
    presetLay.VerticalAlignment = Enum.VerticalAlignment.Center
    presetLay.Parent = presetScroll

    local function renderPresets()
        for _, ch in ipairs(presetScroll:GetChildren()) do
            if ch:IsA("GuiObject") then ch:Destroy() end
        end
        local list = loadPresets()
        if #list == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.fromOffset(200, 30)
            empty.BackgroundTransparency = 1
            empty.Text = "No saved presets yet"
            empty.Font = Theme.fonts.caption
            empty.TextSize = 12
            empty.TextColor3 = DIM
            empty.TextXAlignment = Enum.TextXAlignment.Left
            empty.ZIndex = 4
            empty.Parent = presetScroll
            return
        end
        for idx, p in ipairs(list) do
            local chip = Instance.new("TextButton")
            chip.Text = "  " .. (p.name or "Preset") .. "   X"
            chip.AutoButtonColor = false
            chip.Font = Theme.fonts.body
            chip.TextSize = 12
            chip.TextColor3 = WHITE
            chip.AutomaticSize = Enum.AutomaticSize.X
            chip.Size = UDim2.fromOffset(0, 28)
            chip.BackgroundColor3 = PANEL
            chip.BackgroundTransparency = 0.1
            chip.BorderSizePixel = 0
            chip.ZIndex = 5
            chip.Parent = presetScroll
            Util.corner(chip, 14)
            Util.padding(chip, 8)
            chip.MouseButton1Click:Connect(function()
                local c = {}; for k, v in pairs(p.config) do c[k] = v end
                if type(c.color) == "table" then c.color = t2c(c.color) end
                if type(c.colorB) == "table" then c.colorB = t2c(c.colorB) end
                if type(c.outlineColor) == "table" then c.outlineColor = t2c(c.outlineColor) end
                setConfig(cfg(c))
            end)
            chip.MouseButton2Click:Connect(function()
                table.remove(list, idx); savePresets(list); renderPresets()
            end)
        end
    end
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.fromOffset(80, 30)
    saveBtn.Position = UDim2.new(1, -80, 0, 2)
    saveBtn.BackgroundColor3 = ACCENT
    saveBtn.BorderSizePixel = 0
    saveBtn.AutoButtonColor = false
    saveBtn.Text = "Save"
    saveBtn.Font = Theme.fonts.body
    saveBtn.TextSize = 13
    saveBtn.TextColor3 = WHITE
    saveBtn.ZIndex = 5
    saveBtn.Parent = presetWrap
    Util.corner(saveBtn, 8)
    saveBtn.MouseButton1Click:Connect(function()
        local list = loadPresets()
        local conf = {}; for k, v in pairs(config) do conf[k] = v end
        conf.color = c2t(config.color); conf.colorB = c2t(config.colorB); conf.outlineColor = c2t(config.outlineColor)
        table.insert(list, { name = "Preset " .. (#list + 1), config = conf })
        savePresets(list); renderPresets()
    end)
    renderPresets()

    -- Disable
    local disableRow = Instance.new("Frame")
    disableRow.Size = UDim2.new(1, 0, 0, 34)
    disableRow.BackgroundTransparency = 1
    disableRow.LayoutOrder = nextOrder()
    disableRow.ZIndex = 3
    disableRow.Parent = customPage
    local disableBtn = Instance.new("TextButton")
    disableBtn.Size = UDim2.fromOffset(140, 30)
    disableBtn.BackgroundColor3 = WHITE
    disableBtn.BackgroundTransparency = 0.88
    disableBtn.BorderSizePixel = 0
    disableBtn.AutoButtonColor = false
    disableBtn.Text = "Disable cursor"
    disableBtn.Font = Theme.fonts.body
    disableBtn.TextSize = 13
    disableBtn.TextColor3 = Color3.fromRGB(255, 95, 87)
    disableBtn.ZIndex = 4
    disableBtn.Parent = disableRow
    Util.corner(disableBtn, 8)
    disableBtn.MouseButton1Click:Connect(function()
        stopOverlay(); config = nil; Util.save("CursorConfig", "")
    end)

    -- Sync controls to config
    local function syncControls()
        if not config then return end
        local def = shapeDef(config.shape)
        previewImg.Image = assetFor(config.shape) or ""
        previewImg.ImageColor3 = config.gradient and WHITE or (config.rainbow and Color3.fromRGB(120,220,255) or config.color)
        previewImg.ImageTransparency = config.opacity
        previewImg.Rotation = config.rotation
        previewImg.Size = UDim2.fromOffset(56 * def.aspect, 56)
        previewGrad.Enabled = config.gradient
        if config.gradient then previewGrad.Color = ColorSequence.new(config.color, config.colorB) end
        gradEndLbl.Visible = config.gradient
        refreshShapes()
        sizeSlider.set((config.size - SIZE_MIN) / (SIZE_MAX - SIZE_MIN))
        refreshColorSwatch(); refreshGradSwatch(); refreshOutlineSwatch()
        thickSlider.set((config.outlineThickness - 1) / 5)
        glowSlider.set(config.glow); opacitySlider.set(config.opacity); rotSlider.set(config.rotation / 360)
        trailR.set(config.trail / 10)
    end
    onChangeCB = syncControls
    syncControls()

    return { close = close }
end

function CursorApp.restore()
    restoreSaved()
end

return CursorApp
end)

SYNC.define("apps/Discord", function()
-- SYNC / apps / Discord
-- A Discord-looking client that bridges the game to a real Discord server via
-- the SYNC relay (see ~/sync-discord-relay). Roblox players read channels and
-- "send" messages; the relay posts them through a webhook as "<name> (Roblox)".

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local TextService      = game:GetService("TextService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

-- markdown -> Roblox RichText (bold / italic / inline code)
local function escapeRich(s)
    return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end
local function mdToRich(s)
    s = tostring(s)
    s = s:gsub("<a?:(%w+):%d+>", ":%1:")             -- custom emoji -> :name:
    s = s:gsub("<@!?%d+>", "@user"):gsub("<@&%d+>", "@role"):gsub("<#%d+>", "#channel")
    s = escapeRich(s)
    s = s:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    s = s:gsub("__(.-)__", "<b>%1</b>")
    s = s:gsub("%*(.-)%*", "<i>%1</i>")
    s = s:gsub("`(.-)`", '<font color="rgb(170,180,195)">%1</font>')
    return s
end
-- ms timestamp -> "h:mm AM/PM" (best effort)
local function fmtTime(ts)
    local ok, s = pcall(function() return os.date("%I:%M %p", math.floor((ts or 0) / 1000)) end)
    if ok and s then return (s:gsub("^0", "")) end
    return ""
end
-- Roblox ImageLabels can't load external URLs directly, so download via the
-- executor (Util.remoteImage -> getcustomasset) and set the resulting asset id.
-- Cached by a hash of the URL so repeats are instant.
local function urlKey(url)
    local h = 5381
    for i = 1, #url do h = (h * 33 + string.byte(url, i)) % 2147483647 end
    return tostring(h)
end
local function loadImg(label, url, prefix)
    if not url or url == "" or not label then return end
    task.spawn(function()
        local fn = (prefix or "dc") .. "_" .. urlKey(url) .. ".png"
        local ok, id = pcall(Util.remoteImage, url, fn)
        if ok and id and label and label.Parent then label.Image = id end
    end)
end

-- draw an X icon from two rotated bars (executor fonts often lack ✕ glyphs)
local function drawX(parent, len, thick, color)
    for _, rot in ipairs({ 45, -45 }) do
        local bar = Instance.new("Frame")
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Position = UDim2.fromScale(0.5, 0.5)
        bar.Size = UDim2.fromOffset(len, thick)
        bar.Rotation = rot
        bar.BackgroundColor3 = color
        bar.BorderSizePixel = 0
        bar.ZIndex = (parent.ZIndex or 1) + 1
        bar.Parent = parent
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = bar
    end
end

local function isImageUrl(s)
    return type(s) == "string" and s:match("^https?://%S+%.[Pp][Nn][Gg]")
        or (type(s) == "string" and s:match("^https?://%S+%.[Jj][Pp][Ee]?[Gg]"))
        or (type(s) == "string" and s:match("^https?://%S+%.[Gg][Ii][Ff]"))
        or (type(s) == "string" and s:match("^https?://%S+%.[Ww][Ee][Bb][Pp]"))
end

local DiscordApp = {}

-- ---------------------------------------------------------------------------
-- Config -- RELAY_URL is filled in once the relay is deployed. Both can be
-- overridden at runtime via Util.save("DiscordRelay"/"DiscordKey", ...).
-- ---------------------------------------------------------------------------
local RELAY_URL = "https://relay-production-a9e3.up.railway.app"
local API_KEY   = "CdTt-Mmf25ewBa8Ak9DQujolBQ7HQ9Va76lyV4ulXDnIyc8XOPih2w"

local function relayURL() local v = Util.load("DiscordRelay"); return (v and v ~= "") and v or RELAY_URL end
local function apiKey()   local v = Util.load("DiscordKey");   return (v and v ~= "") and v or API_KEY end
local function configured() return relayURL():sub(1, 8) == "https://" and not relayURL():find("REPLACE") end

-- prewarm the relay at startup so the first open is instant (no cold start)
task.spawn(function() pcall(function() Util.httpGetH(RELAY_URL .. "/health") end) end)

-- Discord palette
local C = {
    bg      = Color3.fromRGB(49, 51, 56),
    side    = Color3.fromRGB(43, 45, 49),
    rail    = Color3.fromRGB(30, 31, 34),
    header  = Color3.fromRGB(30, 31, 34),
    input   = Color3.fromRGB(64, 68, 77),
    active  = Color3.fromRGB(64, 66, 73),
    hover   = Color3.fromRGB(53, 55, 60),
    text    = Color3.fromRGB(219, 222, 225),
    muted   = Color3.fromRGB(148, 155, 164),
    bright  = Color3.fromRGB(242, 243, 245),
    blurple = Color3.fromRGB(88, 101, 242),
    green   = Color3.fromRGB(35, 165, 90),
}
local WHITE = Color3.fromRGB(255, 255, 255)

local function jdecode(s) local ok, t = pcall(function() return HttpService:JSONDecode(s) end); return ok and t or nil end
local function jencode(t) local ok, s = pcall(function() return HttpService:JSONEncode(t) end); return ok and s or "" end

local function me()
    local lp = Players.LocalPlayer
    return {
        id = lp and lp.UserId or 0,
        name = lp and lp.Name or "Player",
        display = lp and lp.DisplayName or (lp and lp.Name) or "Player",
    }
end

-- ---------------------------------------------------------------------------
-- Relay API
-- ---------------------------------------------------------------------------
-- key is passed both as a header and a ?key= query param: executors that fall
-- back to game:HttpGet can't send headers, so the query param is what works.
local function getChannels()
    local body = Util.httpGetH(relayURL() .. "/channels?key=" .. apiKey(), { ["X-API-Key"] = apiKey() })
    local t = body and jdecode(body)
    if type(t) ~= "table" or t.error then return nil end
    return t
end
local function getMessages(channelId, afterId)
    local url = relayURL() .. "/messages?key=" .. apiKey() .. "&channel=" .. channelId
    if afterId then url = url .. "&after=" .. afterId end
    local body = Util.httpGetH(url, { ["X-API-Key"] = apiKey() })
    local t = body and jdecode(body)
    if type(t) ~= "table" or t.error then return nil end
    return t
end
local function sendMessage(channelId, text, replyTo, imageUrl)
    local m = me()
    local payload = jencode({
        channel = channelId, robloxUserId = m.id, username = m.name, text = text,
        replyTo = replyTo, imageUrl = imageUrl,
    })
    local ok = Util.httpPost(relayURL() .. "/send?key=" .. apiKey(), { ["X-API-Key"] = apiKey() }, payload)
    return ok
end

-- avatar headshot url for a roblox id (used for our own sent messages preview)
local function robloxHeadshot(userId)
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=48&height=48&format=png"
end

-- ===========================================================================
-- UI
-- ===========================================================================
DiscordApp._gui = nil

function DiscordApp.open()
    if DiscordApp._gui then return end

    local vp = Util.viewport()
    local W = math.floor(math.min(960, math.max(680, vp.X - 80)))
    local H = math.floor(math.min(640, math.max(460, vp.Y - 100)))
    local cardX, cardY = (vp.X - W) / 2, (vp.Y - H) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Discord"
    Util.mount(gui)
    DiscordApp._gui = gui

    local alive = true
    local winConns = {}
    local function close()
        if not DiscordApp._gui then return end
        DiscordApp._gui = nil
        alive = false
        for _, c in ipairs(winConns) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end

    -- window
    local TB = 36
    local win = Instance.new("Frame")
    win.Position = UDim2.fromOffset(cardX, cardY)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = C.bg
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 12)
    Util.stroke(win, Color3.fromRGB(0, 0, 0), 1, 0.4)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })

    -- title bar (drag handle + traffic lights)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = C.header
    bar.BorderSizePixel = 0
    bar.ZIndex = 6
    bar.Parent = win
    bar.Active = true
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 12); bc.Parent = bar
    local barFix = Instance.new("Frame")
    barFix.Size = UDim2.new(1, 0, 0, 12); barFix.Position = UDim2.new(0, 0, 1, -12)
    barFix.BackgroundColor3 = C.header; barFix.BorderSizePixel = 0; barFix.ZIndex = 6; barFix.Parent = bar

    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = win.Position
        end
    end)
    winConns[#winConns+1] = game:GetService("UserInputService").InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            win.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
        end
    end)
    winConns[#winConns+1] = game:GetService("UserInputService").InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    local lights = { Color3.fromRGB(255,95,87), Color3.fromRGB(254,188,46), Color3.fromRGB(40,200,64) }
    for idx, col in ipairs(lights) do
        local dot = Instance.new(idx == 1 and "TextButton" or "Frame")
        if idx == 1 then dot.Text = ""; dot.AutoButtonColor = false end
        dot.Size = UDim2.fromOffset(12,12); dot.Position = UDim2.fromOffset(12 + (idx-1)*20, (TB-12)/2)
        dot.BackgroundColor3 = col; dot.BorderSizePixel = 0; dot.ZIndex = 7; dot.Parent = bar
        Util.corner(dot, 6)
        if idx == 1 then dot.MouseButton1Click:Connect(close) end
    end
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,0,1,0); titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Syncord"; titleLbl.Font = Theme.fonts.title; titleLbl.TextSize = 13
    titleLbl.TextColor3 = C.muted; titleLbl.ZIndex = 6; titleLbl.Parent = bar

    -- diagnostic label parented straight to the window (renders independently of
    -- the right panel), so failures are always visible.
    local dbg = Instance.new("TextLabel")
    dbg.Position = UDim2.fromOffset(216, 56)
    dbg.Size = UDim2.new(0, 460, 0, 320)
    dbg.BackgroundTransparency = 1
    dbg.Text = ""
    dbg.TextColor3 = Color3.fromRGB(130, 220, 170)
    dbg.Font = Theme.fonts.body; dbg.TextSize = 13
    dbg.TextWrapped = true
    dbg.TextXAlignment = Enum.TextXAlignment.Left
    dbg.TextYAlignment = Enum.TextYAlignment.Top
    dbg.ZIndex = 9; dbg.Parent = win
    local function setDbg(t) pcall(function() dbg.Text = t end) end

  local okAll, errAll = pcall(function()
    -- ---- left: channel rail ----
    local SIDE_W = 200
    local side = Instance.new("Frame")
    side.Position = UDim2.fromOffset(0, TB)
    side.Size = UDim2.new(0, SIDE_W, 1, -TB)
    side.BackgroundColor3 = C.side; side.BorderSizePixel = 0; side.ZIndex = 3; side.Parent = win
    -- round the outer bottom-left corner to match the window
    do
        local c = Instance.new("UICorner")
        local ok = pcall(function()
            c.TopLeftRadius = UDim.new(0, 0); c.TopRightRadius = UDim.new(0, 0)
            c.BottomLeftRadius = UDim.new(0, 12); c.BottomRightRadius = UDim.new(0, 0)
        end)
        if not ok then c.CornerRadius = UDim.new(0, 0) end
        c.Parent = side
    end

    local serverName = Instance.new("TextLabel")
    serverName.Size = UDim2.new(1, -24, 0, 48); serverName.Position = UDim2.fromOffset(16, 0)
    serverName.BackgroundTransparency = 1; serverName.Text = "SYNC Server"
    serverName.Font = Theme.fonts.title; serverName.TextSize = 15; serverName.TextColor3 = C.bright
    serverName.TextXAlignment = Enum.TextXAlignment.Left; serverName.ZIndex = 4; serverName.Parent = side
    local snHair = Instance.new("Frame")
    snHair.Size = UDim2.new(1,0,0,1); snHair.Position = UDim2.fromOffset(0,48)
    snHair.BackgroundColor3 = Color3.fromRGB(0,0,0); snHair.BackgroundTransparency = 0.8
    snHair.BorderSizePixel = 0; snHair.ZIndex = 4; snHair.Parent = side

    local chList = Instance.new("ScrollingFrame")
    chList.Position = UDim2.fromOffset(8, 56); chList.Size = UDim2.new(1, -12, 1, -64)
    chList.BackgroundTransparency = 1; chList.BorderSizePixel = 0; chList.ScrollBarThickness = 3
    chList.ScrollBarImageColor3 = Color3.fromRGB(24,25,28); chList.CanvasSize = UDim2.fromOffset(0,0)
    chList.ZIndex = 4; chList.Parent = side
    local chLayout = Instance.new("UIListLayout"); chLayout.Padding = UDim.new(0,2)
    chLayout.SortOrder = Enum.SortOrder.LayoutOrder; chLayout.Parent = chList
    chLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        chList.CanvasSize = UDim2.fromOffset(0, chLayout.AbsoluteContentSize.Y + 4)
    end)

    -- ---- right: messages + input ----
    local main = Instance.new("Frame")
    main.Position = UDim2.fromOffset(SIDE_W, TB); main.Size = UDim2.new(1, -SIDE_W, 1, -TB)
    main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0; main.ZIndex = 3; main.Parent = win
    do
        local c = Instance.new("UICorner")
        local ok = pcall(function()
            c.TopLeftRadius = UDim.new(0, 0); c.TopRightRadius = UDim.new(0, 0)
            c.BottomLeftRadius = UDim.new(0, 0); c.BottomRightRadius = UDim.new(0, 12)
        end)
        if not ok then c.CornerRadius = UDim.new(0, 0) end
        c.Parent = main
    end

    local chHeader = Instance.new("TextLabel")
    chHeader.Size = UDim2.new(1, -24, 0, 48); chHeader.Position = UDim2.fromOffset(16, 0)
    chHeader.BackgroundTransparency = 1; chHeader.Text = "# select a channel"
    chHeader.Font = Theme.fonts.title; chHeader.TextSize = 15; chHeader.TextColor3 = C.bright
    chHeader.TextXAlignment = Enum.TextXAlignment.Left; chHeader.ZIndex = 4; chHeader.Parent = main
    local chHair = Instance.new("Frame")
    chHair.Size = UDim2.new(1,0,0,1); chHair.Position = UDim2.fromOffset(0,48)
    chHair.BackgroundColor3 = Color3.fromRGB(0,0,0); chHair.BackgroundTransparency = 0.8
    chHair.BorderSizePixel = 0; chHair.ZIndex = 4; chHair.Parent = main

    local feed = Instance.new("ScrollingFrame")
    feed.Position = UDim2.fromOffset(8, 52); feed.Size = UDim2.new(1, -12, 1, -52-56)
    feed.BackgroundTransparency = 1; feed.BorderSizePixel = 0; feed.ScrollBarThickness = 4
    feed.ScrollBarImageColor3 = Color3.fromRGB(26,27,30); feed.CanvasSize = UDim2.fromOffset(0,0)
    feed.ZIndex = 4; feed.Parent = main
    local feedLayout = Instance.new("UIListLayout"); feedLayout.Padding = UDim.new(0,3)
    feedLayout.SortOrder = Enum.SortOrder.LayoutOrder; feedLayout.Parent = feed
    feedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        feed.CanvasSize = UDim2.fromOffset(0, feedLayout.AbsoluteContentSize.Y + 16)
        feed.CanvasPosition = Vector2.new(0, feed.CanvasSize.Y.Offset)
    end)
    local feedPad = Instance.new("UIPadding"); feedPad.PaddingTop = UDim.new(0,8); feedPad.PaddingBottom = UDim.new(0,8)
    feedPad.PaddingRight = UDim.new(0,8); feedPad.Parent = feed

    -- input bar
    local inputWrap = Instance.new("Frame")
    inputWrap.Size = UDim2.new(1, -32, 0, 44); inputWrap.Position = UDim2.new(0, 16, 1, -54)
    inputWrap.BackgroundColor3 = C.input; inputWrap.BorderSizePixel = 0; inputWrap.ZIndex = 4; inputWrap.Parent = main
    Util.corner(inputWrap, 10)
    -- attach (+) button, Discord style
    local attachBtn = Instance.new("TextButton")
    attachBtn.Size = UDim2.fromOffset(26, 26); attachBtn.Position = UDim2.fromOffset(10, 9)
    attachBtn.BackgroundColor3 = C.muted; attachBtn.AutoButtonColor = false; attachBtn.Text = ""
    attachBtn.ZIndex = 5; attachBtn.Parent = inputWrap
    Util.corner(attachBtn, 13)
    local plusV = Instance.new("Frame")
    plusV.AnchorPoint = Vector2.new(0.5,0.5); plusV.Position = UDim2.fromScale(0.5,0.5)
    plusV.Size = UDim2.fromOffset(2, 12); plusV.BackgroundColor3 = C.input; plusV.BorderSizePixel = 0
    plusV.ZIndex = 6; plusV.Parent = attachBtn
    local plusH = plusV:Clone(); plusH.Size = UDim2.fromOffset(12, 2); plusH.Parent = attachBtn
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -56, 1, 0); box.Position = UDim2.fromOffset(46, 0)
    box.BackgroundTransparency = 1; box.Text = ""; box.PlaceholderText = "Message #general"
    box.PlaceholderColor3 = C.muted; box.TextColor3 = C.text; box.Font = Theme.fonts.body
    box.TextSize = 14; box.TextXAlignment = Enum.TextXAlignment.Left; box.ClearTextOnFocus = false
    box.ClipsDescendants = true; box.ZIndex = 5; box.Parent = inputWrap

    -- reply bar (shown above the input when replying)
    local replyBar = Instance.new("Frame")
    replyBar.Size = UDim2.new(1, -32, 0, 24); replyBar.Position = UDim2.new(0, 16, 1, -76)
    replyBar.BackgroundColor3 = Color3.fromRGB(38, 40, 45); replyBar.BorderSizePixel = 0
    replyBar.Visible = false; replyBar.ZIndex = 4; replyBar.Parent = main
    Util.corner(replyBar, 6)
    local replyLbl = Instance.new("TextLabel")
    replyLbl.Position = UDim2.fromOffset(10, 0); replyLbl.Size = UDim2.new(1, -44, 1, 0)
    replyLbl.BackgroundTransparency = 1; replyLbl.Font = Theme.fonts.caption; replyLbl.TextSize = 12
    replyLbl.TextColor3 = C.muted; replyLbl.TextXAlignment = Enum.TextXAlignment.Left
    replyLbl.TextTruncate = Enum.TextTruncate.AtEnd; replyLbl.ZIndex = 5; replyLbl.Parent = replyBar
    local replyX = Instance.new("TextButton")
    replyX.Position = UDim2.new(1, -28, 0.5, -10); replyX.Size = UDim2.fromOffset(20, 20)
    replyX.BackgroundTransparency = 1; replyX.AutoButtonColor = false; replyX.Text = ""
    replyX.ZIndex = 5; replyX.Parent = replyBar
    drawX(replyX, 11, 2, C.muted)

    -- ---- loading screen (shown until the first channel loads) ----
    local loadingOverlay = Instance.new("Frame")
    loadingOverlay.Position = UDim2.fromOffset(0, TB); loadingOverlay.Size = UDim2.new(1, 0, 1, -TB)
    loadingOverlay.BackgroundColor3 = C.bg; loadingOverlay.BorderSizePixel = 0
    loadingOverlay.ZIndex = 15; loadingOverlay.Parent = win
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.5, 0.44)
    ring.Size = UDim2.fromOffset(40, 40); ring.BackgroundTransparency = 1; ring.ZIndex = 16; ring.Parent = loadingOverlay
    Util.corner(ring, 20)
    local rs = Instance.new("UIStroke"); rs.Thickness = 3; rs.Color = C.blurple; rs.Parent = ring
    local rg = Instance.new("UIGradient")
    rg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.2),
        NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1),
    })
    rg.Parent = rs
    local loadTxt = Instance.new("TextLabel")
    loadTxt.AnchorPoint = Vector2.new(0.5, 0.5); loadTxt.Position = UDim2.fromScale(0.5, 0.56)
    loadTxt.Size = UDim2.fromOffset(320, 24); loadTxt.BackgroundTransparency = 1
    loadTxt.Text = "Loading"; loadTxt.Font = Theme.fonts.title; loadTxt.TextSize = 15
    loadTxt.TextColor3 = C.muted; loadTxt.ZIndex = 16; loadTxt.Parent = loadingOverlay
    local spinning = true
    task.spawn(function()
        local a, dots = 0, 0
        while spinning and loadingOverlay and loadingOverlay.Parent do
            a = (a + 9) % 360; rg.Rotation = a
            dots = (dots + 1) % 40
            loadTxt.Text = "Loading" .. string.rep(".", math.floor(dots / 10))
            task.wait(0.03)
        end
    end)
    local function hideLoading()
        if not (loadingOverlay and loadingOverlay.Parent) then return end
        spinning = false
        Util.tween(loadingOverlay, { BackgroundTransparency = 1 }, 0.25)
        Util.tween(loadTxt, { TextTransparency = 1 }, 0.2)
        pcall(function() Util.tween(rs, { Transparency = 1 }, 0.2) end)
        local lo = loadingOverlay; loadingOverlay = nil
        task.delay(0.3, function() if lo then lo:Destroy() end end)
    end

    -- ---- state ----
    local activeChannel, activeName
    local lastId
    local renderedIds = {}
    local replyTarget = nil
    local prevAuthor, prevTs      -- for grouping consecutive messages
    local showProfile, setReply   -- forward declarations

    local CONTENT_W = (W - SIDE_W) - 96
    local function measureH(text)
        if not text or text == "" then return 0 end
        local ok, v = pcall(function()
            return TextService:GetTextSize(text, 14, Theme.fonts.body, Vector2.new(CONTENT_W, 100000))
        end)
        return (ok and v and v.Y) or 18
    end
    local function measureW(text, size, font)
        local ok, v = pcall(function()
            return TextService:GetTextSize(text, size, font, Vector2.new(240, size + 6))
        end)
        return (ok and v and v.X) or (#tostring(text) * size * 0.5)
    end

    local AV_X, AV_SZ, TX = 16, 40, 72
    local function addMessage(m)
        if renderedIds[m.id] then return end
        renderedIds[m.id] = true

        -- reply preview: native replyTo, or a leading "> " quote from a Roblox reply
        local replyPreview, bodyText = nil, (m.content or "")
        if m.replyTo and m.replyTo.author then
            replyPreview = (m.replyTo.author or "") ..
                ((m.replyTo.content and m.replyTo.content ~= "") and ("  " .. m.replyTo.content) or "")
        elseif bodyText:sub(1, 2) == "> " then
            local first = bodyText:match("^(.-)\n")
            replyPreview = ((first or bodyText):gsub("^>%s*", ""):gsub("%*%*", ""))
            bodyText = first and (bodyText:gsub("^.-\n", "", 1)) or ""
        end

        local grouped = (not replyPreview) and prevAuthor ~= nil
            and prevAuthor == (m.authorId or m.author)
            and prevTs and m.ts and (m.ts - prevTs) < 420000
        prevAuthor = m.authorId or m.author
        if m.ts then prevTs = m.ts end

        local replyH = replyPreview and 16 or 0
        local headerH = grouped and 0 or (replyH + 22)
        local contentH = measureH(bodyText)
        local imgCount = m.images and #m.images or 0
        local imgH = imgCount * 188
        local total = math.max(grouped and 24 or 52, headerH + contentH + imgH + (grouped and 3 or 8))

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, total)
        row.BackgroundColor3 = C.hover; row.BackgroundTransparency = 1
        row.BorderSizePixel = 0; row.ZIndex = 4; row.Parent = feed

        local rb = Instance.new("TextButton")
        rb.Position = UDim2.new(1, -54, 0, 6); rb.Size = UDim2.fromOffset(44, 18)
        rb.BackgroundTransparency = 1; rb.AutoButtonColor = false
        rb.Text = "reply"; rb.Font = Theme.fonts.caption; rb.TextSize = 11; rb.TextColor3 = C.muted
        rb.Visible = false; rb.ZIndex = 7; rb.Parent = row
        rb.MouseButton1Click:Connect(function() if setReply then setReply(m) end end)
        local hov = Instance.new("TextButton")
        hov.Size = UDim2.fromScale(1, 1); hov.BackgroundTransparency = 1; hov.Text = ""
        hov.AutoButtonColor = false; hov.ZIndex = 4; hov.Parent = row
        hov.MouseEnter:Connect(function() row.BackgroundTransparency = 0.96; rb.Visible = true end)
        hov.MouseLeave:Connect(function() row.BackgroundTransparency = 1; rb.Visible = false end)

        if not grouped then
            local av = Instance.new("ImageLabel")
            av.Size = UDim2.fromOffset(AV_SZ, AV_SZ); av.Position = UDim2.fromOffset(AV_X, replyH + 2)
            av.BackgroundColor3 = C.rail; av.BorderSizePixel = 0; av.ZIndex = 5; av.Parent = row
            Util.corner(av, AV_SZ / 2)
            loadImg(av, m.avatar, "dcav")
            local avBtn = Instance.new("TextButton")
            avBtn.Size = UDim2.fromScale(1, 1); avBtn.BackgroundTransparency = 1
            avBtn.Text = ""; avBtn.AutoButtonColor = false; avBtn.ZIndex = 6; avBtn.Parent = av
            avBtn.MouseButton1Click:Connect(function() if showProfile then showProfile(m) end end)

            local nameBtn = Instance.new("TextButton")
            nameBtn.Position = UDim2.fromOffset(TX, replyH + 1); nameBtn.Size = UDim2.fromOffset(280, 18)
            nameBtn.BackgroundTransparency = 1; nameBtn.AutoButtonColor = false
            nameBtn.Text = m.author or "Unknown"; nameBtn.Font = Theme.fonts.title; nameBtn.TextSize = 15
            nameBtn.TextColor3 = m.roblox and Color3.fromRGB(120, 200, 255) or C.bright
            nameBtn.TextXAlignment = Enum.TextXAlignment.Left; nameBtn.ZIndex = 5; nameBtn.Parent = row
            nameBtn.MouseButton1Click:Connect(function() if showProfile then showProfile(m) end end)

            local nameW = measureW(m.author or "", 15, Theme.fonts.title)
            local timeLbl = Instance.new("TextLabel")
            timeLbl.Position = UDim2.fromOffset(TX + nameW + 8, replyH + 5); timeLbl.Size = UDim2.fromOffset(90, 13)
            timeLbl.BackgroundTransparency = 1; timeLbl.Text = fmtTime(m.ts)
            timeLbl.Font = Theme.fonts.caption; timeLbl.TextSize = 11; timeLbl.TextColor3 = C.muted
            timeLbl.TextXAlignment = Enum.TextXAlignment.Left; timeLbl.ZIndex = 5; timeLbl.Parent = row
        end

        if replyPreview then
            local bar = Instance.new("Frame")
            bar.Position = UDim2.fromOffset(TX, 4); bar.Size = UDim2.fromOffset(3, 11)
            bar.BackgroundColor3 = C.blurple; bar.BorderSizePixel = 0; bar.ZIndex = 5; bar.Parent = row
            Util.corner(bar, 2)
            local rl = Instance.new("TextLabel")
            rl.Position = UDim2.fromOffset(TX + 10, 1); rl.Size = UDim2.new(1, -(TX + 70), 0, 14)
            rl.BackgroundTransparency = 1; rl.Text = replyPreview
            rl.Font = Theme.fonts.caption; rl.TextSize = 12; rl.TextColor3 = C.muted
            rl.TextXAlignment = Enum.TextXAlignment.Left; rl.TextTruncate = Enum.TextTruncate.AtEnd
            rl.ZIndex = 5; rl.Parent = row
        end

        if bodyText and bodyText ~= "" then
            local content = Instance.new("TextLabel")
            content.Position = UDim2.fromOffset(TX, headerH); content.Size = UDim2.fromOffset(CONTENT_W, contentH)
            content.BackgroundTransparency = 1; content.RichText = true; content.Text = mdToRich(bodyText)
            content.Font = Theme.fonts.body; content.TextSize = 15; content.TextColor3 = C.text
            content.TextWrapped = true; content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextYAlignment = Enum.TextYAlignment.Top; content.ZIndex = 5; content.Parent = row
        end

        if m.images then
            for i, url in ipairs(m.images) do
                local img = Instance.new("ImageLabel")
                img.Position = UDim2.fromOffset(TX, headerH + contentH + (i - 1) * 188 + 6)
                img.Size = UDim2.fromOffset(360, 180)
                img.BackgroundColor3 = C.rail; img.BorderSizePixel = 0
                img.ScaleType = Enum.ScaleType.Fit; img.ZIndex = 5; img.Parent = row
                Util.corner(img, 8)
                loadImg(img, url, "dcimg")
            end
        end
    end

    local function clearFeed()
        renderedIds = {}; lastId = nil; prevAuthor = nil; prevTs = nil
        for _, ch in ipairs(feed:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
    end

    local function notice(text)
        clearFeed()
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -16, 0, 60); l.BackgroundTransparency = 1
        l.Text = text; l.Font = Theme.fonts.body; l.TextSize = 13; l.TextColor3 = C.muted
        l.TextWrapped = true; l.ZIndex = 4; l.Parent = feed
    end

    local function selectChannel(id, name, btnHighlight)
        activeChannel, activeName = id, name
        chHeader.Text = "# " .. name
        clearFeed()
        notice("Loading #" .. name .. "...")
        if btnHighlight then btnHighlight() end
        task.spawn(function()
            local msgs = getMessages(id)
            if not alive or activeChannel ~= id then return end
            clearFeed()
            hideLoading()
            if not msgs then notice("Couldn't load #" .. name .. " from the relay.") return end
            if #msgs == 0 then notice("No messages in #" .. name .. " yet. Say hi.") return end
            for _, m in ipairs(msgs) do addMessage(m); lastId = m.id end
        end)
    end

    -- build channel buttons
    local chButtons = {}
    local function highlightChannel(id)
        for cid, b in pairs(chButtons) do
            b.BackgroundColor3 = (cid == id) and C.active or C.side
            b.BackgroundTransparency = (cid == id) and 0 or 1
        end
    end

    local function buildChannelButton(ch)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 32); b.AutoButtonColor = false
            b.BackgroundColor3 = C.side; b.BackgroundTransparency = 1; b.BorderSizePixel = 0
            b.Text = ""; b.ZIndex = 5; b.Parent = chList
            Util.corner(b, 6)
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -16, 1, 0); t.Position = UDim2.fromOffset(10, 0)
            t.BackgroundTransparency = 1; t.Text = "#  " .. ch.name; t.Font = Theme.fonts.body
            t.TextSize = 14; t.TextColor3 = C.muted; t.TextXAlignment = Enum.TextXAlignment.Left
            t.ZIndex = 6; t.Parent = b
            b.MouseEnter:Connect(function() if activeChannel ~= ch.id then b.BackgroundTransparency = 0; b.BackgroundColor3 = C.hover end end)
            b.MouseLeave:Connect(function() if activeChannel ~= ch.id then b.BackgroundTransparency = 1 end end)
            b.MouseButton1Click:Connect(function()
                selectChannel(ch.id, ch.name, function() highlightChannel(ch.id); t.TextColor3 = C.bright end)
            end)
            chButtons[ch.id] = b
    end

    -- Non-blocking: build the window first, fetch channels in the background,
    -- and show a clear diagnostic on screen if anything fails.
    local function loadChannels()
        if not configured() then
            hideLoading(); setDbg("Relay URL not configured.")
            return
        end
        setDbg("Connecting...\nHTTP: " .. (Util.hasRequest() and "request() available" or "game:HttpGet only") ..
            "\nConnecting to relay…")
        task.spawn(function()
            local url = relayURL() .. "/channels?key=" .. apiKey()
            local ok, body, status = pcall(function() return Util.httpGetH(url, { ["X-API-Key"] = apiKey() }) end)
            if not alive then return end
            if not ok then
                hideLoading(); setDbg("Request error:\n" .. tostring(body) .. "\n\n" .. url)
                return
            end
            if not body then
                hideLoading(); setDbg("No response.\nHTTP: " ..
                    (Util.hasRequest() and "request()" or "game:HttpGet only") ..
                    "\nstatus = " .. tostring(status) .. "\n\n" .. url)
                return
            end
            local chans = jdecode(body)
            if type(chans) ~= "table" or chans.error then
                hideLoading(); setDbg("Relay replied (status " .. tostring(status) .. "):\n\n" .. tostring(body):sub(1, 220))
                return
            end
            setDbg("")  -- success: clear the diagnostic
            clearFeed()
            for _, ch in ipairs(chans) do buildChannelButton(ch) end
            if chans[1] then
                selectChannel(chans[1].id, chans[1].name, function() highlightChannel(chans[1].id) end)
            else
                hideLoading(); setDbg("Connected, but the relay has no channels configured.")
            end
        end)
    end

    -- reply: assign the forward-declared local
    setReply = function(m)
        replyTarget = { id = m.id, author = m.author, content = (m.content or ""):sub(1, 80) }
        replyLbl.Text = "Replying to " .. (m.author or "")
        replyBar.Visible = true
        pcall(function() box:CaptureFocus() end)
    end
    local function clearReply()
        replyTarget = nil; replyBar.Visible = false
    end
    replyX.MouseButton1Click:Connect(clearReply)

    -- profile popup: assign the forward-declared local
    showProfile = function(m)
        local pop = Instance.new("TextButton")  -- full-window dismiss catcher
        pop.Size = UDim2.fromScale(1, 1); pop.BackgroundColor3 = Color3.fromRGB(0,0,0)
        pop.BackgroundTransparency = 0.5; pop.AutoButtonColor = false; pop.Text = ""
        pop.ZIndex = 20; pop.Parent = win
        local card = Instance.new("Frame")
        card.Size = UDim2.fromOffset(260, 160); card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.5); card.BackgroundColor3 = Color3.fromRGB(30, 31, 34)
        card.BorderSizePixel = 0; card.ClipsDescendants = true; card.ZIndex = 21; card.Parent = pop
        Util.corner(card, 12)
        Util.stroke(card, Color3.fromRGB(0,0,0), 1, 0.4)
        local banner = Instance.new("Frame")
        banner.Size = UDim2.new(1, 0, 0, 52); banner.BackgroundColor3 = m.roblox and Color3.fromRGB(70,110,200) or C.blurple
        banner.BorderSizePixel = 0; banner.ZIndex = 21; banner.Parent = card
        local pav = Instance.new("ImageLabel")
        pav.Size = UDim2.fromOffset(68, 68); pav.Position = UDim2.fromOffset(16, 22)
        pav.BackgroundColor3 = Color3.fromRGB(20,20,22); pav.BorderSizePixel = 0; pav.ZIndex = 22; pav.Parent = card
        Util.corner(pav, 34); Util.stroke(pav, Color3.fromRGB(30,31,34), 5, 0)
        loadImg(pav, m.avatar, "dcav")
        local pname = Instance.new("TextLabel")
        pname.Position = UDim2.fromOffset(16, 92); pname.Size = UDim2.new(1, -32, 0, 22)
        pname.BackgroundTransparency = 1; pname.Text = m.author or "Unknown"
        pname.Font = Theme.fonts.title; pname.TextSize = 17; pname.TextColor3 = C.bright
        pname.TextXAlignment = Enum.TextXAlignment.Left; pname.ZIndex = 22; pname.Parent = card
        local ptag = Instance.new("TextLabel")
        ptag.Position = UDim2.fromOffset(16, 116); ptag.Size = UDim2.new(1, -32, 0, 18)
        ptag.BackgroundTransparency = 1
        ptag.Text = m.roblox and "Roblox player (via SYNC)" or "Discord member"
        ptag.Font = Theme.fonts.caption; ptag.TextSize = 12; ptag.TextColor3 = C.muted
        ptag.TextXAlignment = Enum.TextXAlignment.Left; ptag.ZIndex = 22; ptag.Parent = card
        pop.MouseButton1Click:Connect(function() pop:Destroy() end)
    end

    -- attach: paste an image/file URL to send (Roblox can't open a file picker)
    attachBtn.MouseButton1Click:Connect(function()
        if not activeChannel then return end
        local pop = Instance.new("TextButton")
        pop.Size = UDim2.fromScale(1, 1); pop.BackgroundColor3 = Color3.fromRGB(0,0,0)
        pop.BackgroundTransparency = 0.5; pop.AutoButtonColor = false; pop.Text = ""; pop.ZIndex = 20; pop.Parent = win
        local card = Instance.new("TextButton")
        card.Size = UDim2.fromOffset(380, 150); card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.5); card.BackgroundColor3 = Color3.fromRGB(30, 31, 34)
        card.AutoButtonColor = false; card.Text = ""; card.BorderSizePixel = 0; card.ClipsDescendants = true
        card.ZIndex = 21; card.Parent = pop
        Util.corner(card, 12); Util.stroke(card, Color3.fromRGB(0,0,0), 1, 0.4)
        local title = Instance.new("TextLabel")
        title.Position = UDim2.fromOffset(18, 16); title.Size = UDim2.new(1, -36, 0, 22)
        title.BackgroundTransparency = 1; title.Text = "Send an image"; title.Font = Theme.fonts.title
        title.TextSize = 16; title.TextColor3 = C.bright; title.TextXAlignment = Enum.TextXAlignment.Left
        title.ZIndex = 22; title.Parent = card
        local fieldWrap = Instance.new("Frame")
        fieldWrap.Position = UDim2.fromOffset(18, 50); fieldWrap.Size = UDim2.new(1, -36, 0, 40)
        fieldWrap.BackgroundColor3 = C.rail; fieldWrap.BorderSizePixel = 0; fieldWrap.ZIndex = 22; fieldWrap.Parent = card
        Util.corner(fieldWrap, 8)
        local field = Instance.new("TextBox")
        field.Position = UDim2.fromOffset(12, 0); field.Size = UDim2.new(1, -24, 1, 0)
        field.BackgroundTransparency = 1; field.Text = ""; field.PlaceholderText = "Paste image URL (png / jpg / gif / webp)"
        field.PlaceholderColor3 = C.muted; field.TextColor3 = C.text; field.Font = Theme.fonts.body
        field.TextSize = 14; field.TextXAlignment = Enum.TextXAlignment.Left; field.ClearTextOnFocus = false
        field.ClipsDescendants = true; field.ZIndex = 23; field.Parent = fieldWrap
        local sendB = Instance.new("TextButton")
        sendB.Position = UDim2.new(1, -98, 1, -46); sendB.Size = UDim2.fromOffset(80, 32)
        sendB.BackgroundColor3 = C.blurple; sendB.AutoButtonColor = false; sendB.Text = "Send"
        sendB.Font = Theme.fonts.title; sendB.TextSize = 14; sendB.TextColor3 = WHITE; sendB.ZIndex = 22; sendB.Parent = card
        Util.corner(sendB, 8)
        local function submit()
            local u = (field.Text or ""):gsub("%s+$", ""):gsub("^%s+", "")
            if isImageUrl(u) and activeChannel then
                local rt = replyTarget; clearReply()
                task.spawn(function() sendMessage(activeChannel, "", rt, u) end)
                pop:Destroy()
            else
                field.PlaceholderText = "That doesn't look like an image URL"
                field.Text = ""
            end
        end
        sendB.MouseButton1Click:Connect(submit)
        field.FocusLost:Connect(function(enter) if enter then submit() end end)
        pop.MouseButton1Click:Connect(function() pop:Destroy() end)
        pcall(function() field:CaptureFocus() end)
    end)

    -- send
    local function doSend()
        local text = box.Text or ""
        local trimmed = text:gsub("%s", "")
        if trimmed == "" then return end
        if not activeChannel then return end
        box.Text = ""
        local rt = replyTarget
        clearReply()
        -- if the whole message is an image URL, send it as an image
        local img = isImageUrl(text:gsub("%s+$", ""):gsub("^%s+", ""))
        local body = img and "" or text
        task.spawn(function()
            local ok = sendMessage(activeChannel, body, rt, img and (text:gsub("%s+$", ""):gsub("^%s+", "")) or nil)
            if not ok then notice("Message didn't send (rate limited or filtered).") end
        end)
    end
    box.FocusLost:Connect(function(enter) if enter then doSend() end end)

    local lok, lerr = pcall(loadChannels)
    if not lok then hideLoading(); setDbg("Load error:\n" .. tostring(lerr)) end

    -- poll active channel for new messages
    task.spawn(function()
        while alive do
            task.wait(2)
            if alive and activeChannel and configured() then
                local msgs = getMessages(activeChannel, lastId)
                if msgs then
                    for _, m in ipairs(msgs) do addMessage(m); lastId = m.id end
                end
            end
        end
    end)
  end)
  if not okAll then setDbg("Error:\n" .. tostring(errAll)) end

    return { close = close }
end

return DiscordApp
end)

SYNC.define("apps/Scripting", function()
-- SYNC / apps / Scripting
-- Hub for Roblox scripting sites. Home shows the latest scripts across sources;
-- search queries them; a settings popup (top-right) toggles each site on/off.
-- Data comes from the SYNC relay's /scripts aggregator.

local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local ScriptingApp = {}

local RELAY_URL = "https://relay-production-a9e3.up.railway.app"
local API_KEY   = "CdTt-Mmf25ewBa8Ak9DQujolBQ7HQ9Va76lyV4ulXDnIyc8XOPih2w"

local C = {
    bg     = Color3.fromRGB(24, 25, 28),
    header = Color3.fromRGB(30, 31, 34),
    card   = Color3.fromRGB(37, 39, 44),
    card2  = Color3.fromRGB(44, 46, 52),
    input  = Color3.fromRGB(40, 42, 47),
    text   = Color3.fromRGB(230, 232, 236),
    muted  = Color3.fromRGB(150, 155, 164),
    accent = Theme.accent,
    green  = Color3.fromRGB(60, 190, 120),
}
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

local function jdecode(s) local ok, t = pcall(function() return HttpService:JSONDecode(s) end); return ok and t or nil end
local function setClip(t)
    local f = setclipboard or toclipboard or (syn and syn.write_clipboard) or writeclipboard
    if f then pcall(f, t) end
end
-- run a script string with the executor (loadstring). Returns ok, err.
local function execute(src)
    if not src or src == "" then return false, "no script" end
    local ls = loadstring or (getgenv and getgenv().loadstring)
    if not ls then return false, "loadstring unavailable" end
    local fn, cerr = ls(src)
    if not fn then return false, tostring(cerr) end
    local ok, rerr = pcall(fn)
    return ok, rerr
end

-- external images -> getcustomasset (Roblox can't load URLs directly)
local function urlKey(u) local h = 5381; for i = 1, #u do h = (h * 33 + string.byte(u, i)) % 2147483647 end return tostring(h) end
local function loadImg(label, url)
    if not url or url == "" then return end
    task.spawn(function()
        local ok, id = pcall(Util.remoteImage, url, "scr_" .. urlKey(url) .. ".png")
        if ok and id and label and label.Parent then label.Image = id end
    end)
end

local function enabledCsv()
    local raw = Util.load("ScriptSites")
    if not raw or raw == "" then return "" end       -- empty = all sites
    return raw
end
local function isEnabled(id)
    local raw = enabledCsv()
    if raw == "" then return true end
    return (("," .. raw .. ","):find("," .. id .. ",", 1, true)) ~= nil
end

local function getSites()
    local b = Util.httpGetH(RELAY_URL .. "/scripts/sites?key=" .. API_KEY, { ["X-API-Key"] = API_KEY })
    local t = b and jdecode(b)
    return (type(t) == "table") and t or nil
end
-- fetch the raw executable script for a result (rscripts/roscripts/scriptblox)
local function getRaw(s)
    if s.script and s.script ~= "" then return s.script end
    local url = RELAY_URL .. "/scripts/raw?key=" .. API_KEY .. "&site=" .. (s.siteId or "")
    if s.slug and s.slug ~= "" then url = url .. "&slug=" .. HttpService:UrlEncode(s.slug) end
    if s.rawUrl and s.rawUrl ~= "" then url = url .. "&rawurl=" .. HttpService:UrlEncode(s.rawUrl) end
    if s.detailUrl and s.detailUrl ~= "" then url = url .. "&detailurl=" .. HttpService:UrlEncode(s.detailUrl) end
    local b = Util.httpGetH(url, { ["X-API-Key"] = API_KEY })
    local t = b and jdecode(b)
    return (t and t.script) or ""
end

local function getScripts(q, siteId, page)
    local url = RELAY_URL .. "/scripts?key=" .. API_KEY
    if siteId and siteId ~= "" then
        url = url .. "&sites=" .. siteId          -- a specific site tab
    else
        local csv = enabledCsv()
        if csv ~= "" then url = url .. "&sites=" .. csv end   -- All (enabled)
    end
    if q and q ~= "" then url = url .. "&q=" .. HttpService:UrlEncode(q) end
    if page and page > 1 then url = url .. "&page=" .. page end
    local b = Util.httpGetH(url, { ["X-API-Key"] = API_KEY })
    local t = b and jdecode(b)
    return (type(t) == "table" and not t.error) and t or nil
end

ScriptingApp._gui = nil

function ScriptingApp.open()
    if ScriptingApp._gui then return end

    local vp = Util.viewport()
    local W = math.floor(math.min(1000, math.max(720, vp.X - 80)))
    local H = math.floor(math.min(650, math.max(470, vp.Y - 100)))
    local cardX, cardY = (vp.X - W) / 2, (vp.Y - H) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Scripting"
    Util.mount(gui)
    ScriptingApp._gui = gui

    local alive = true
    local winConns = {}
    local function close()
        if not ScriptingApp._gui then return end
        ScriptingApp._gui = nil; alive = false
        for _, c in ipairs(winConns) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end

    -- window
    local TB = 40
    local win = Instance.new("Frame")
    win.Position = UDim2.fromOffset(cardX, cardY); win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = C.bg; win.BorderSizePixel = 0; win.ClipsDescendants = true
    win.ZIndex = 2; win.Parent = gui
    Util.corner(win, 12); Util.stroke(win, WHITE, 1, 0.86)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })

    -- title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB); bar.BackgroundColor3 = C.header; bar.BorderSizePixel = 0
    bar.Active = true; bar.ZIndex = 6; bar.Parent = win
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 12); bc.Parent = bar
    local barFix = Instance.new("Frame")
    barFix.Size = UDim2.new(1, 0, 0, 12); barFix.Position = UDim2.new(0, 0, 1, -12)
    barFix.BackgroundColor3 = C.header; barFix.BorderSizePixel = 0; barFix.ZIndex = 6; barFix.Parent = bar

    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = win.Position
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            win.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    local lights = { Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }
    for i, col in ipairs(lights) do
        local dot = Instance.new(i == 1 and "TextButton" or "Frame")
        if i == 1 then dot.Text = ""; dot.AutoButtonColor = false end
        dot.Size = UDim2.fromOffset(12, 12); dot.Position = UDim2.fromOffset(14 + (i - 1) * 20, (TB - 12) / 2)
        dot.BackgroundColor3 = col; dot.BorderSizePixel = 0; dot.ZIndex = 7; dot.Parent = bar
        Util.corner(dot, 6)
        if i == 1 then dot.MouseButton1Click:Connect(close) end
    end
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 1, 0); titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Scripting"; titleLbl.Font = Theme.fonts.title; titleLbl.TextSize = 14
    titleLbl.TextColor3 = Color3.fromRGB(210, 210, 216); titleLbl.ZIndex = 6; titleLbl.Parent = bar

    -- settings gear (top-right)
    local gear = Instance.new("TextButton")
    gear.Size = UDim2.fromOffset(28, 28); gear.Position = UDim2.new(1, -38, 0, (TB - 28) / 2)
    gear.BackgroundColor3 = C.card2; gear.AutoButtonColor = false; gear.Text = ""
    gear.ZIndex = 7; gear.Parent = bar
    Util.corner(gear, 8)
    local gearIco = Instance.new("ImageLabel")
    gearIco.Size = UDim2.fromOffset(16, 16); gearIco.Position = UDim2.fromScale(0.5, 0.5)
    gearIco.AnchorPoint = Vector2.new(0.5, 0.5); gearIco.BackgroundTransparency = 1; gearIco.ZIndex = 8; gearIco.Parent = gear
    pcall(function() (SYNC.import("core/Icons")).apply(gearIco, "settings", C.muted) end)

    -- header + search
    local heading = Instance.new("TextLabel")
    heading.Position = UDim2.fromOffset(24, TB + 14); heading.Size = UDim2.new(1, -48, 0, 24)
    heading.BackgroundTransparency = 1; heading.Text = "Scripting Sites"; heading.Font = Theme.fonts.title
    heading.TextSize = 19; heading.TextColor3 = C.text; heading.TextXAlignment = Enum.TextXAlignment.Left
    heading.ZIndex = 4; heading.Parent = win

    local searchWrap = Instance.new("Frame")
    searchWrap.Position = UDim2.fromOffset(24, TB + 46); searchWrap.Size = UDim2.new(1, -48, 0, 36)
    searchWrap.BackgroundColor3 = C.input; searchWrap.BorderSizePixel = 0; searchWrap.ZIndex = 4; searchWrap.Parent = win
    Util.corner(searchWrap, 9); Util.stroke(searchWrap, BLACK, 1, 0.7)
    local search = Instance.new("TextBox")
    search.Position = UDim2.fromOffset(14, 0); search.Size = UDim2.new(1, -110, 1, 0)
    search.BackgroundTransparency = 1; search.Text = ""; search.PlaceholderText = "Search scripts (e.g. blox fruits)..."
    search.PlaceholderColor3 = C.muted; search.TextColor3 = C.text; search.Font = Theme.fonts.body
    search.TextSize = 14; search.TextXAlignment = Enum.TextXAlignment.Left; search.ClearTextOnFocus = false
    search.ClipsDescendants = true; search.ZIndex = 5; search.Parent = searchWrap
    local searchBtn = Instance.new("TextButton")
    searchBtn.Position = UDim2.new(1, -92, 0.5, -13); searchBtn.Size = UDim2.fromOffset(84, 26)
    searchBtn.BackgroundColor3 = C.accent; searchBtn.AutoButtonColor = false; searchBtn.Text = "Search"
    searchBtn.Font = Theme.fonts.title; searchBtn.TextSize = 13; searchBtn.TextColor3 = WHITE
    searchBtn.ZIndex = 6; searchBtn.Parent = searchWrap
    Util.corner(searchBtn, 7)

    -- site tabs (scriptblox.com, rscripts.net, ...)
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Position = UDim2.fromOffset(24, TB + 90); tabBar.Size = UDim2.new(1, -48, 0, 34)
    tabBar.BackgroundTransparency = 1; tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 0; tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.CanvasSize = UDim2.fromOffset(0, 0); tabBar.ZIndex = 4; tabBar.Parent = win
    local tabLay = Instance.new("UIListLayout")
    tabLay.FillDirection = Enum.FillDirection.Horizontal; tabLay.Padding = UDim.new(0, 8)
    tabLay.VerticalAlignment = Enum.VerticalAlignment.Center; tabLay.Parent = tabBar

    -- filter chips
    local filterRow = Instance.new("Frame")
    filterRow.Position = UDim2.fromOffset(24, TB + 128); filterRow.Size = UDim2.new(1, -48, 0, 26)
    filterRow.BackgroundTransparency = 1; filterRow.ZIndex = 4; filterRow.Parent = win
    local filterLay = Instance.new("UIListLayout")
    filterLay.FillDirection = Enum.FillDirection.Horizontal; filterLay.Padding = UDim.new(0, 8)
    filterLay.VerticalAlignment = Enum.VerticalAlignment.Center; filterLay.Parent = filterRow

    -- grid
    local grid = Instance.new("ScrollingFrame")
    grid.Position = UDim2.fromOffset(20, TB + 162); grid.Size = UDim2.new(1, -40, 1, -(TB + 172))
    grid.BackgroundTransparency = 1; grid.BorderSizePixel = 0; grid.ScrollBarThickness = 5
    grid.ScrollBarImageColor3 = Color3.fromRGB(90, 92, 98); grid.ScrollBarImageTransparency = 0.35
    grid.CanvasSize = UDim2.fromOffset(0, 0); grid.ZIndex = 4; grid.Parent = win

    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0.5); status.Position = UDim2.fromScale(0.5, 0.4)
    status.Size = UDim2.fromOffset(400, 30); status.BackgroundTransparency = 1
    status.Text = "Loading..."; status.Font = Theme.fonts.body; status.TextSize = 15
    status.TextColor3 = C.muted; status.ZIndex = 5; status.Parent = grid

    -- ----- detail popup (script + copy) -----
    local function showDetail(s)
        local pop = Instance.new("TextButton")
        pop.Size = UDim2.fromScale(1, 1); pop.BackgroundColor3 = BLACK; pop.BackgroundTransparency = 0.55
        pop.AutoButtonColor = false; pop.Text = ""; pop.ZIndex = 30; pop.Parent = win
        local CW = math.min(600, W - 60)
        local CH = math.min(500, H - 50)
        local card = Instance.new("TextButton")
        card.Size = UDim2.fromOffset(CW, CH); card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.5); card.BackgroundColor3 = C.header
        card.AutoButtonColor = false; card.Text = ""; card.BorderSizePixel = 0; card.ClipsDescendants = true
        card.ZIndex = 31; card.Parent = pop
        Util.corner(card, 14); Util.stroke(card, BLACK, 1, 0.4)

        -- banner image + dark gradient
        local banner = Instance.new("ImageLabel")
        banner.Size = UDim2.new(1, 0, 0, 150); banner.BackgroundColor3 = Color3.fromRGB(18, 19, 22)
        banner.BorderSizePixel = 0; banner.ScaleType = Enum.ScaleType.Crop; banner.ZIndex = 31; banner.Parent = card
        loadImg(banner, s.thumbnail)
        local shade = Instance.new("Frame")
        shade.Size = UDim2.new(1, 0, 0, 90); shade.Position = UDim2.new(0, 0, 0, 60)
        shade.BackgroundColor3 = BLACK; shade.BorderSizePixel = 0; shade.ZIndex = 32; shade.Parent = banner
        local sg = Instance.new("UIGradient")
        sg.Rotation = 90
        sg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
        sg.Parent = shade
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(18, 116); t.Size = UDim2.new(1, -36, 0, 28)
        t.BackgroundTransparency = 1; t.Text = s.title or "Script"; t.Font = Theme.fonts.title
        t.TextSize = 18; t.TextColor3 = WHITE; t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd; t.ZIndex = 33; t.Parent = banner
        local siteTag = Instance.new("TextLabel")
        siteTag.Position = UDim2.fromOffset(12, 10); siteTag.Size = UDim2.fromOffset(#(s.site or "") * 7 + 18, 20)
        siteTag.BackgroundColor3 = BLACK; siteTag.BackgroundTransparency = 0.3; siteTag.Text = s.site or ""
        siteTag.Font = Theme.fonts.caption; siteTag.TextSize = 11; siteTag.TextColor3 = WHITE
        siteTag.ZIndex = 33; siteTag.Parent = banner; Util.corner(siteTag, 5)
        -- close X
        local xb = Instance.new("TextButton")
        xb.Position = UDim2.new(1, -34, 0, 10); xb.Size = UDim2.fromOffset(24, 24)
        xb.BackgroundColor3 = BLACK; xb.BackgroundTransparency = 0.3; xb.AutoButtonColor = false; xb.Text = ""
        xb.ZIndex = 33; xb.Parent = banner; Util.corner(xb, 12)
        for _, rot in ipairs({ 45, -45 }) do
            local ln = Instance.new("Frame"); ln.AnchorPoint = Vector2.new(0.5, 0.5)
            ln.Position = UDim2.fromScale(0.5, 0.5); ln.Size = UDim2.fromOffset(11, 2); ln.Rotation = rot
            ln.BackgroundColor3 = WHITE; ln.BorderSizePixel = 0; ln.ZIndex = 34; ln.Parent = xb
            local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = ln
        end
        xb.MouseButton1Click:Connect(function() pop:Destroy() end)

        -- badges row
        local bx = 18
        local function pill(text, col)
            local p = Instance.new("TextLabel")
            p.Position = UDim2.fromOffset(bx, 160); p.Size = UDim2.fromOffset(#text * 7 + 18, 20)
            p.BackgroundColor3 = col; p.BackgroundTransparency = 0.82; p.Text = text
            p.Font = Theme.fonts.caption; p.TextSize = 11; p.TextColor3 = col; p.ZIndex = 32; p.Parent = card
            Util.corner(p, 5); Util.stroke(p, col, 1, 0.5)
            bx = bx + p.Size.X.Offset + 6
        end
        if s.verified then pill("Verified", C.green) end
        if s.keySystem then pill("Key System", Color3.fromRGB(240, 190, 70)) end
        if s.patched then pill("Patched", Color3.fromRGB(240, 90, 90)) end
        if s.universal then pill("Universal", Color3.fromRGB(110, 160, 255)) end

        -- meta
        local meta = Instance.new("TextLabel")
        meta.Position = UDim2.fromOffset(18, 186); meta.Size = UDim2.new(1, -36, 0, 16)
        meta.BackgroundTransparency = 1
        meta.Text = (s.game ~= "" and (s.game .. "   ") or "") .. tostring(s.views or 0) .. " views" ..
            ((s.likes and s.likes > 0) and ("   " .. s.likes .. " likes") or "")
        meta.Font = Theme.fonts.caption; meta.TextSize = 12; meta.TextColor3 = C.muted
        meta.TextXAlignment = Enum.TextXAlignment.Left; meta.ZIndex = 32; meta.Parent = card

        -- description (if present and not just the game name)
        local hasDesc = s.desc and s.desc ~= "" and s.desc ~= s.game
        if hasDesc then
            local d = Instance.new("TextLabel")
            d.Position = UDim2.fromOffset(18, 208); d.Size = UDim2.new(1, -36, 0, 34)
            d.BackgroundTransparency = 1; d.Text = s.desc; d.Font = Theme.fonts.body; d.TextSize = 13
            d.TextColor3 = C.text; d.TextWrapped = true; d.TextXAlignment = Enum.TextXAlignment.Left
            d.TextYAlignment = Enum.TextYAlignment.Top; d.TextTruncate = Enum.TextTruncate.AtEnd
            d.ZIndex = 32; d.Parent = card
        end

        local hasScript = s.script and s.script ~= ""
        local canRaw = hasScript or (s.slug and s.slug ~= "") or (s.rawUrl and s.rawUrl ~= "") or (s.detailUrl and s.detailUrl ~= "")
        local codeTop = hasDesc and 248 or 210
        local box = Instance.new("Frame")
        box.Position = UDim2.fromOffset(18, codeTop); box.Size = UDim2.new(1, -36, 0, CH - codeTop - 56)
        box.BackgroundColor3 = C.bg; box.BorderSizePixel = 0; box.ZIndex = 32; box.Parent = card
        Util.corner(box, 8)
        local codeScroll = Instance.new("ScrollingFrame")
        codeScroll.Size = UDim2.new(1, -8, 1, -8); codeScroll.Position = UDim2.fromOffset(8, 4)
        codeScroll.BackgroundTransparency = 1; codeScroll.BorderSizePixel = 0; codeScroll.ScrollBarThickness = 4
        codeScroll.CanvasSize = UDim2.fromOffset(0, 3000); codeScroll.ZIndex = 33; codeScroll.Parent = box
        local code = Instance.new("TextLabel")
        code.Size = UDim2.new(1, -6, 0, 3000); code.BackgroundTransparency = 1
        code.Text = hasScript and s.script or (canRaw and "Loading script..." or ("This source has no raw script.\nCopy Link and open on " .. (s.site or "the site") .. ":\n\n" .. (s.url or "")))
        code.Font = Enum.Font.Code; code.TextSize = 12; code.TextColor3 = hasScript and C.text or C.muted
        code.TextXAlignment = Enum.TextXAlignment.Left; code.TextYAlignment = Enum.TextYAlignment.Top
        code.TextWrapped = true; code.ZIndex = 33; code.Parent = codeScroll

        -- action buttons
        local function actionBtn(rightOffset, w, label, col)
            local b = Instance.new("TextButton")
            b.Position = UDim2.new(1, rightOffset, 1, -44); b.Size = UDim2.fromOffset(w, 32)
            b.BackgroundColor3 = col; b.AutoButtonColor = false; b.Text = label
            b.Font = Theme.fonts.title; b.TextSize = 13; b.TextColor3 = WHITE; b.ZIndex = 32; b.Parent = card
            Util.corner(b, 8)
            return b
        end
        local copyBtn = actionBtn(-118, 106, "Copy Script", C.card2)
        copyBtn.TextColor3 = C.text
        local execBtn = actionBtn(-232, 108, "Execute", C.green)
        if not canRaw then execBtn.Visible = false; copyBtn.Text = "Copy Link" end

        -- fetch raw on-demand so Execute/Copy work for every source
        local scriptText = hasScript and s.script or nil
        if canRaw and not scriptText then
            task.spawn(function()
                local raw = getRaw(s)
                if raw and raw ~= "" then
                    scriptText = raw; s.script = raw
                    pcall(function() code.Text = raw; code.TextColor3 = C.text end)
                else
                    pcall(function() code.Text = "Couldn't load the raw script.\nCopy Link:\n\n" .. (s.url or "") end)
                    execBtn.Visible = false; copyBtn.Text = "Copy Link"
                end
            end)
        end

        copyBtn.MouseButton1Click:Connect(function()
            setClip(scriptText or s.url or "")
            copyBtn.Text = "Copied!"; copyBtn.BackgroundColor3 = C.green; copyBtn.TextColor3 = WHITE
        end)
        execBtn.MouseButton1Click:Connect(function()
            execBtn.Text = "Running..."
            task.spawn(function()
                local src = scriptText or getRaw(s)
                if not src or src == "" then execBtn.Text = "No script"; return end
                scriptText = src
                local ok, err = execute(src)
                execBtn.Text = ok and "Executed" or "Failed"
                execBtn.BackgroundColor3 = ok and C.green or Color3.fromRGB(210, 80, 80)
                if not ok then pcall(function() code.Text = "Execution error:\n" .. tostring(err) end) end
            end)
        end)
        pop.MouseButton1Click:Connect(function() pop:Destroy() end)
    end

    -- ----- render cards -----
    local CARD_W, CARD_H, PAD = 210, 182, 14
    local allResults = {}
    local filterMode = "all"
    local currentSite = nil       -- nil = All
    local curQuery = nil
    local curPage = 1
    local loadingMore = false
    local loadMoreBtn
    local loadMore                 -- forward decl

    local function passFilter(s)
        if filterMode == "verified" then return s.verified == true end
        if filterMode == "key" then return s.keySystem == true end
        if filterMode == "nokey" then return not s.keySystem end
        return true
    end

    local function makeCard(s, x, y)
        local cardBtn = Instance.new("TextButton")
        cardBtn.Size = UDim2.fromOffset(CARD_W, CARD_H); cardBtn.Position = UDim2.fromOffset(x, y)
        cardBtn.BackgroundColor3 = C.card; cardBtn.AutoButtonColor = false; cardBtn.Text = ""
        cardBtn.BorderSizePixel = 0; cardBtn.ClipsDescendants = true; cardBtn.ZIndex = 5; cardBtn.Parent = grid
        Util.corner(cardBtn, 10)
        cardBtn.MouseEnter:Connect(function() cardBtn.BackgroundColor3 = C.card2 end)
        cardBtn.MouseLeave:Connect(function() cardBtn.BackgroundColor3 = C.card end)

        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(1, 0, 0, 100); thumb.BackgroundColor3 = Color3.fromRGB(20, 21, 24)
        thumb.BorderSizePixel = 0; thumb.ScaleType = Enum.ScaleType.Crop; thumb.ZIndex = 5; thumb.Parent = cardBtn
        loadImg(thumb, s.thumbnail)

        local badge = Instance.new("TextLabel")
        badge.Position = UDim2.fromOffset(8, 8); badge.Size = UDim2.fromOffset(#(s.site or "") * 7 + 16, 18)
        badge.BackgroundColor3 = BLACK; badge.BackgroundTransparency = 0.35; badge.Text = s.site or ""
        badge.Font = Theme.fonts.caption; badge.TextSize = 11; badge.TextColor3 = WHITE
        badge.ZIndex = 6; badge.Parent = thumb
        Util.corner(badge, 5)

        -- corner tags (key system / verified)
        local tx = 8
        local function tag(text, col)
            local p = Instance.new("TextLabel")
            p.AnchorPoint = Vector2.new(1, 1); p.Position = UDim2.new(1, -tx, 1, -8)
            p.Size = UDim2.fromOffset(#text * 7 + 12, 17); p.BackgroundColor3 = col
            p.BackgroundTransparency = 0.15; p.Text = text; p.Font = Theme.fonts.caption
            p.TextSize = 10; p.TextColor3 = WHITE; p.ZIndex = 6; p.Parent = thumb
            Util.corner(p, 4); tx = tx + p.Size.X.Offset + 5
        end
        if s.keySystem then tag("KEY", Color3.fromRGB(200, 150, 40)) end
        if s.verified then tag("VERIFIED", C.green) end

        local ttl = Instance.new("TextLabel")
        ttl.Position = UDim2.fromOffset(10, 106); ttl.Size = UDim2.new(1, -20, 0, 36)
        ttl.BackgroundTransparency = 1; ttl.Text = s.title or "Untitled"; ttl.Font = Theme.fonts.title
        ttl.TextSize = 13; ttl.TextColor3 = C.text; ttl.TextWrapped = true
        ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.TextYAlignment = Enum.TextYAlignment.Top
        ttl.ZIndex = 5; ttl.Parent = cardBtn

        local sub = Instance.new("TextLabel")
        sub.Position = UDim2.fromOffset(10, 156); sub.Size = UDim2.new(1, -20, 0, 16)
        sub.BackgroundTransparency = 1
        sub.Text = (s.game ~= "" and s.game or s.desc or "") .. "   " .. tostring(s.views or 0) .. " views"
        sub.Font = Theme.fonts.caption; sub.TextSize = 11; sub.TextColor3 = C.muted
        sub.TextXAlignment = Enum.TextXAlignment.Left; sub.TextTruncate = Enum.TextTruncate.AtEnd
        sub.ZIndex = 5; sub.Parent = cardBtn

        cardBtn.MouseButton1Click:Connect(function() showDetail(s) end)
    end

    local function renderCards(errored)
        for _, ch in ipairs(grid:GetChildren()) do if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end end
        loadMoreBtn = nil
        status.Parent = grid
        if errored then status.Text = "Couldn't reach the relay."; return end
        if #allResults == 0 then status.Text = "No scripts found."; return end

        local list = {}
        for _, s in ipairs(allResults) do if passFilter(s) then list[#list + 1] = s end end
        if #list == 0 then status.Text = "Nothing matches this filter."; return end
        status.Parent = nil

        local gridW = grid.AbsoluteSize.X
        if gridW < 50 then gridW = W - 60 end
        local cols = math.max(1, math.floor((gridW + PAD) / (CARD_W + PAD)))
        local col, row = 0, 0
        for _, s in ipairs(list) do
            makeCard(s, col * (CARD_W + PAD), row * (CARD_H + PAD))
            col = col + 1
            if col >= cols then col = 0; row = row + 1 end
        end
        local rows = row + (col > 0 and 1 or 0)
        local moreY = rows * (CARD_H + PAD)
        loadMoreBtn = Instance.new("TextButton")
        loadMoreBtn.Position = UDim2.fromOffset(0, moreY); loadMoreBtn.Size = UDim2.new(1, -8, 0, 40)
        loadMoreBtn.BackgroundColor3 = C.card; loadMoreBtn.AutoButtonColor = false; loadMoreBtn.Text = "Load more"
        loadMoreBtn.Font = Theme.fonts.title; loadMoreBtn.TextSize = 14; loadMoreBtn.TextColor3 = C.text
        loadMoreBtn.ZIndex = 5; loadMoreBtn.Parent = grid
        Util.corner(loadMoreBtn, 8)
        loadMoreBtn.MouseButton1Click:Connect(function() if loadMore then loadMore() end end)
        grid.CanvasSize = UDim2.fromOffset(0, moreY + 52)
    end

    local function load(q)
        curQuery = q; curPage = 1; allResults = {}
        for _, ch in ipairs(grid:GetChildren()) do if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end end
        status.Parent = grid; status.Text = "Loading..."
        task.spawn(function()
            local list = getScripts(q, currentSite, 1)
            if not alive then return end
            allResults = list or {}
            renderCards(list == nil)
        end)
    end

    loadMore = function()
        if loadingMore then return end
        loadingMore = true
        if loadMoreBtn then loadMoreBtn.Text = "Loading..." end
        curPage = curPage + 1
        task.spawn(function()
            local more = getScripts(curQuery, currentSite, curPage)
            loadingMore = false
            if not alive then return end
            if more and #more > 0 then
                local seen = {}
                for _, s in ipairs(allResults) do seen[s.url or s.title] = true end
                local added = 0
                for _, s in ipairs(more) do
                    if not seen[s.url or s.title] then allResults[#allResults + 1] = s; added = added + 1 end
                end
                if added > 0 then renderCards() elseif loadMoreBtn then loadMoreBtn.Text = "No more results" end
            elseif loadMoreBtn then loadMoreBtn.Text = "No more results" end
        end)
    end

    searchBtn.MouseButton1Click:Connect(function() load(search.Text) end)
    search.FocusLost:Connect(function(enter) if enter then load(search.Text) end end)

    -- filter chips
    local filterChips = {}
    local function setFilter(mode)
        filterMode = mode
        for _, fc in ipairs(filterChips) do
            local on = fc.mode == mode
            fc.bg.BackgroundColor3 = on and C.accent or C.card
            fc.lbl.TextColor3 = on and WHITE or C.muted
        end
        renderCards()
    end
    for _, f in ipairs({ { "all", "All" }, { "verified", "Verified" }, { "key", "Key System" }, { "nokey", "No Key" } }) do
        local w = #f[2] * 7 + 22
        local bg = Instance.new("TextButton")
        bg.Size = UDim2.fromOffset(w, 24); bg.BackgroundColor3 = C.card; bg.AutoButtonColor = false
        bg.Text = ""; bg.BorderSizePixel = 0; bg.ZIndex = 5; bg.Parent = filterRow
        Util.corner(bg, 12)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 1; lbl.Text = f[2]
        lbl.Font = Theme.fonts.caption; lbl.TextSize = 12; lbl.TextColor3 = C.muted; lbl.ZIndex = 6; lbl.Parent = bg
        bg.MouseButton1Click:Connect(function() setFilter(f[1]) end)
        filterChips[#filterChips + 1] = { mode = f[1], bg = bg, lbl = lbl }
    end
    setFilter("all")

    -- build the tab bar (All + each enabled site's domain)
    local tabButtons = {}
    local function highlightTab(id)
        for _, tb in ipairs(tabButtons) do
            local on = tb.id == id
            tb.bg.BackgroundColor3 = on and C.accent or C.card
            tb.lbl.TextColor3 = on and WHITE or C.muted
        end
    end
    local function addTab(id, label)
        local w = #label * 8 + 26
        local bg = Instance.new("TextButton")
        bg.Size = UDim2.fromOffset(w, 28); bg.BackgroundColor3 = C.card; bg.AutoButtonColor = false
        bg.Text = ""; bg.BorderSizePixel = 0; bg.ZIndex = 5; bg.Parent = tabBar
        Util.corner(bg, 8)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1, 1); lbl.BackgroundTransparency = 1; lbl.Text = label
        lbl.Font = Theme.fonts.body; lbl.TextSize = 13; lbl.TextColor3 = C.muted; lbl.ZIndex = 6; lbl.Parent = bg
        bg.MouseButton1Click:Connect(function()
            currentSite = id; highlightTab(id); search.Text = ""; load(nil)
        end)
        tabButtons[#tabButtons + 1] = { id = id, bg = bg, lbl = lbl }
        return w
    end
    local function buildTabs(sites)
        for _, tb in ipairs(tabButtons) do tb.bg:Destroy() end
        tabButtons = {}
        local total = addTab(nil, "All") + 8
        for _, s in ipairs(sites) do
            if isEnabled(s.id) then total = total + addTab(s.id, s.host or s.name) + 8 end
        end
        tabBar.CanvasSize = UDim2.fromOffset(total + 10, 0)
        highlightTab(currentSite)
    end

    -- ----- settings popup (per-site toggles) -----
    gear.MouseButton1Click:Connect(function()
        local pop = Instance.new("TextButton")
        pop.Size = UDim2.fromScale(1, 1); pop.BackgroundColor3 = BLACK; pop.BackgroundTransparency = 0.5
        pop.AutoButtonColor = false; pop.Text = ""; pop.ZIndex = 30; pop.Parent = win
        local card = Instance.new("TextButton")
        card.Size = UDim2.fromOffset(360, math.min(460, H - 80)); card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.5); card.BackgroundColor3 = C.header
        card.AutoButtonColor = false; card.Text = ""; card.BorderSizePixel = 0; card.ClipsDescendants = true
        card.ZIndex = 31; card.Parent = pop
        Util.corner(card, 12); Util.stroke(card, BLACK, 1, 0.4)
        local h = Instance.new("TextLabel")
        h.Position = UDim2.fromOffset(18, 14); h.Size = UDim2.new(1, -36, 0, 22)
        h.BackgroundTransparency = 1; h.Text = "Sites"; h.Font = Theme.fonts.title; h.TextSize = 16
        h.TextColor3 = C.text; h.TextXAlignment = Enum.TextXAlignment.Left; h.ZIndex = 32; h.Parent = card
        local hint = Instance.new("TextLabel")
        hint.Position = UDim2.fromOffset(18, 38); hint.Size = UDim2.new(1, -36, 0, 16)
        hint.BackgroundTransparency = 1; hint.Text = "Toggle which sites show in home & search"
        hint.Font = Theme.fonts.caption; hint.TextSize = 11; hint.TextColor3 = C.muted
        hint.TextXAlignment = Enum.TextXAlignment.Left; hint.ZIndex = 32; hint.Parent = card

        local listScroll = Instance.new("ScrollingFrame")
        listScroll.Position = UDim2.fromOffset(12, 62); listScroll.Size = UDim2.new(1, -24, 1, -74)
        listScroll.BackgroundTransparency = 1; listScroll.BorderSizePixel = 0; listScroll.ScrollBarThickness = 4
        listScroll.CanvasSize = UDim2.fromOffset(0, 0); listScroll.ZIndex = 32; listScroll.Parent = card
        local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 6); ll.Parent = listScroll

        pop.MouseButton1Click:Connect(function() pop:Destroy() end)

        task.spawn(function()
            local sites = getSites() or {}
            -- build current enabled set (empty csv = all on)
            local set = {}
            local csv = enabledCsv()
            local allOn = (csv == "")
            if not allOn then for id in csv:gmatch("[^,]+") do set[id] = true end end
            if allOn then for _, s in ipairs(sites) do set[s.id] = true end end

            local function saveSet()
                local ids = {}
                for _, s in ipairs(sites) do if set[s.id] then ids[#ids + 1] = s.id end end
                -- if all enabled, store "" (means all); else the csv
                Util.save("ScriptSites", (#ids == #sites) and "" or table.concat(ids, ","))
                -- reflect changes in the tab bar + results
                if currentSite and not isEnabled(currentSite) then currentSite = nil end
                buildTabs(sites); load(nil)
            end

            for _, s in ipairs(sites) do
                local rowf = Instance.new("Frame")
                rowf.Size = UDim2.new(1, -4, 0, 34); rowf.BackgroundColor3 = C.card
                rowf.BorderSizePixel = 0; rowf.ZIndex = 33; rowf.Parent = listScroll
                Util.corner(rowf, 8)
                local nm = Instance.new("TextLabel")
                nm.Position = UDim2.fromOffset(12, 0); nm.Size = UDim2.new(1, -70, 1, 0)
                nm.BackgroundTransparency = 1; nm.Text = s.name; nm.Font = Theme.fonts.body
                nm.TextSize = 14; nm.TextColor3 = C.text; nm.TextXAlignment = Enum.TextXAlignment.Left
                nm.ZIndex = 34; nm.Parent = rowf
                local sw = Instance.new("TextButton")
                sw.Position = UDim2.new(1, -52, 0.5, -11); sw.Size = UDim2.fromOffset(40, 22)
                sw.AutoButtonColor = false; sw.Text = ""; sw.BorderSizePixel = 0; sw.ZIndex = 34; sw.Parent = rowf
                Util.corner(sw, 11)
                local knob = Instance.new("Frame")
                knob.Size = UDim2.fromOffset(16, 16); knob.BackgroundColor3 = WHITE
                knob.BorderSizePixel = 0; knob.ZIndex = 35; knob.Parent = sw
                Util.corner(knob, 8)
                local function paint()
                    sw.BackgroundColor3 = set[s.id] and C.green or Color3.fromRGB(70, 72, 78)
                    knob.Position = set[s.id] and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                end
                paint()
                sw.MouseButton1Click:Connect(function()
                    set[s.id] = not set[s.id]; paint(); saveSet()
                end)
            end
            listScroll.CanvasSize = UDim2.fromOffset(0, #sites * 40 + 8)
        end)
    end)

    -- initial: fetch sites, build tabs, load home (latest across enabled sites)
    task.spawn(function()
        local sites = getSites() or {}
        if not alive then return end
        buildTabs(sites)
        load(nil)
    end)

    return { close = close }
end

return ScriptingApp
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
