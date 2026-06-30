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
