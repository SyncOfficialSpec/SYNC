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

SYNC.define("core/Executor", function()
-- SYNC / core / Executor
-- In-game script runner. SYNC runs scripts itself the same way Sirius does -
-- the executor's own loadstring - so a click executes instantly with no manual
-- paste. This wraps that with a reliable fetch (rscripts' /raw/ endpoint
-- randomly serves a Cloudflare HTML page instead of Lua, which loadstring can't
-- run), HTML detection + retries, and protected execution that surfaces errors.
--
--   Executor.run(source, name)   -> ok, err
--   Executor.fetch(url)          -> source|nil, reason
--   Executor.runUrl(url, name)   -> ok, err   (fetch + run)

local Util = SYNC.import("core/Util")

local Executor = {}

-- loadstring is provided by the host executor. SYNC only runs because an
-- executor executed it, so this always exists; grab it defensively anyway.
local _loadstring = loadstring

local function looksLikeHTML(s)
    if not s or #s == 0 then return false end
    local head = s:sub(1, 400):lower()
    return head:find("<!doctype html", 1, true) ~= nil
        or head:find("<html", 1, true) ~= nil
        or head:find("cf-browser-verification", 1, true) ~= nil
        or head:find("just a moment", 1, true) ~= nil
end

-- Signatures of a host that took the script down (Vercel/Netlify/GitHub etc.).
-- These aren't Lua, so loadstring returns nil and the wrapper dies on line 1
-- with a useless "attempt to call a nil value". We translate that up front.
local function deadHostReason(s)
    if type(s) ~= "string" then return nil end
    local h = s:sub(1, 200):lower()
    if h:find("deployment_disabled", 1, true) or h:find("payment required", 1, true) then
        return "the uploader's host is offline (deployment disabled)"
    end
    if h:find("not found", 1, true) and #s < 60 then
        return "the script link is dead (404 not found)"
    end
    if h:find("account suspended", 1, true) or h:find("service unavailable", 1, true) then
        return "the uploader's host is down"
    end
    if looksLikeHTML(s) then
        return "the link returned a web page, not a script"
    end
    return nil
end

-- Pull the first URL out of a `loadstring(game:HttpGet("url"))()` wrapper, so we
-- can validate the real target before running the wrapper blind.
local function wrapperInnerUrl(src)
    if type(src) ~= "string" or #src > 400 then return nil end
    return src:match('HttpGet%s*%(%s*["\']([^"\']+)["\']')
        or src:match('HttpGetAsync%s*%(%s*["\']([^"\']+)["\']')
end

-- Short-lived cache of successful fetches, so re-running or re-clicking a
-- script is instant instead of re-hitting the network + retry loop.
local _fetchCache = {}
local FETCH_TTL = 90

-- Fetch raw Lua for a URL. Retries a few times because the challenge page is
-- transient. Returns (source, nil) or (nil, reason).
function Executor.fetch(url, tries)
    tries = tries or 4
    local hit = _fetchCache[url]
    if hit and (os.clock() - hit.at) < FETCH_TTL then
        return hit.src, nil
    end
    local lastReason = "no response"
    for attempt = 1, tries do
        local body = Util.httpGet(url)
        if body and body ~= "" then
            if looksLikeHTML(body) then
                lastReason = "host returned a web page, not a script"
            else
                _fetchCache[url] = { src = body, at = os.clock() }
                return body, nil
            end
        else
            lastReason = "download failed"
        end
        if attempt < tries then task.wait(0.6) end
    end
    return nil, lastReason
end

-- Recent-run history (newest first), capped. `at` is os.time() so callers can
-- render a relative time. Read a copy via Executor.recent().
local _recent = {}
local RECENT_MAX = 12

local function pushRecent(name)
    local nm = tostring(name or "script")
    -- drop an existing entry with the same name so it moves to the top
    for i = #_recent, 1, -1 do
        if _recent[i].name == nm then table.remove(_recent, i) end
    end
    table.insert(_recent, 1, { name = nm, at = os.time() })
    while #_recent > RECENT_MAX do table.remove(_recent) end
end

function Executor.recent()
    local copy = {}
    for i, e in ipairs(_recent) do copy[i] = { name = e.name, at = e.at } end
    return copy
end

-- Run Lua source. loadstring compiles it; we run in a fresh thread under pcall
-- so a script that errors (dead link wrappers are common) can't take SYNC down
-- and the failure is reported. Returns (ok, err). err is a compile message when
-- ok is false before the thread starts, or a runtime message after.
function Executor.run(source, name)
    if type(source) ~= "string" or source == "" then
        return false, "empty script"
    end
    if looksLikeHTML(source) then
        return false, "that's a web page, not a script"
    end
    local fn, compileErr = _loadstring(source, "=" .. tostring(name or "SYNC"))
    if not fn then
        return false, "compile error: " .. tostring(compileErr):gsub("\n.*", "")
    end

    -- Report a runtime error back to the caller. The script runs in its own
    -- thread so long-running scripts don't block; we only forward an error if
    -- it happens synchronously on start (most dead-link wrappers fail instantly).
    local done, runOk, runErr = false, true, nil
    task.spawn(function()
        runOk, runErr = pcall(fn)
        done = true
    end)
    -- give the thread a moment to fault on start
    for _ = 1, 20 do
        if done then break end
        task.wait(0.05)
    end
    if done and not runOk then
        local msg = tostring(runErr):gsub("\n.*", "")
        -- a bare wrapper whose inner loadstring returned nil surfaces as this
        if msg:find("attempt to call a nil value") then
            return false, "the script link is dead (uploader's host is offline)"
        end
        return false, "runtime error: " .. msg
    end
    pushRecent(name)
    return true, nil
end

-- Fetch a URL and run it. Returns (ok, err). If the fetched source is a thin
-- `loadstring(game:HttpGet("inner"))()` wrapper (most rscripts uploads are),
-- the inner link is validated first so a dead host gives a clear reason instead
-- of a cryptic "attempt to call a nil value" from the wrapper.
function Executor.runUrl(url, name)
    local src, reason = Executor.fetch(url)
    if not src then return false, reason end

    local inner = wrapperInnerUrl(src)
    if inner then
        local innerBody = Util.httpGet(inner)
        if not innerBody or innerBody == "" then
            return false, "the script link is dead (host didn't respond)"
        end
        local dead = deadHostReason(innerBody)
        if dead then return false, dead end
        -- inner is real Lua: run it directly (skips the wrapper's own fetch)
        return Executor.run(innerBody, name)
    end

    return Executor.run(src, name)
end

pcall(function()
    if typeof(getgenv) == "function" then getgenv().SYNCExecutor = Executor end
end)

return Executor
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

SYNC.define("core/SyncCodec", function()
-- SYNC / core / SyncCodec
-- A tiny reversible codec for "SYNC codes": free-tier invite links that only the
-- SYNC Joiner can read. A place + server id is XOR-scrambled with a fixed key and
-- re-encoded over a shuffled 64-char alphabet, then prefixed "SYNC-". The result
-- is NOT a valid Roblox link, so it does nothing outside SYNC - which is the point.
-- Premium users skip this and share the real roblox.com link instead.
--
-- SyncCodec.encode(placeId, jobId) -> "SYNC-...."
-- SyncCodec.decode(token) -> placeId (number), jobId (string) | nil

local SyncCodec = {}

-- Shuffled, URL-safe 64-char alphabet (deterministic permutation of the standard
-- set, so encode and decode agree without shipping a literal scrambled string).
local BASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local ALPHA = ""
do
    local n = #BASE
    local idx = 0
    for _ = 1, n do
        idx = (idx + 37) % n -- 37 is coprime with 64 -> visits every index once
        ALPHA = ALPHA .. BASE:sub(idx + 1, idx + 1)
    end
end
local REV = {}
for i = 1, #ALPHA do REV[ALPHA:sub(i, i)] = i - 1 end

local KEY = { 83, 121, 110, 99, 79, 83, 42, 173, 55, 200 } -- fixed scramble key

local function xorApply(bytes)
    local out = {}
    for i, b in ipairs(bytes) do
        out[i] = bit32.bxor(b, KEY[((i - 1) % #KEY) + 1])
    end
    return out
end

-- bytes -> chars (6-bit repacking over ALPHA)
local function packBytes(bytes)
    local out, buf, bits = {}, 0, 0
    for _, b in ipairs(bytes) do
        buf = buf * 256 + b
        bits = bits + 8
        while bits >= 6 do
            bits = bits - 6
            local idx = math.floor(buf / (2 ^ bits)) % 64
            out[#out + 1] = ALPHA:sub(idx + 1, idx + 1)
            buf = buf % (2 ^ bits) -- drop the bits we just emitted (keep buf small + exact)
        end
    end
    if bits > 0 then
        local idx = (buf * (2 ^ (6 - bits))) % 64
        out[#out + 1] = ALPHA:sub(idx + 1, idx + 1)
    end
    return table.concat(out)
end

-- chars -> bytes (inverse of packBytes)
local function unpackChars(str)
    local out, buf, bits = {}, 0, 0
    for i = 1, #str do
        local v = REV[str:sub(i, i)]
        if v then
            buf = buf * 64 + v
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                out[#out + 1] = math.floor(buf / (2 ^ bits)) % 256
                buf = buf % (2 ^ bits)
            end
        end
    end
    return out
end

function SyncCodec.encode(placeId, jobId)
    local payload = tostring(placeId) .. "|" .. tostring(jobId)
    local bytes = {}
    for i = 1, #payload do bytes[i] = payload:byte(i) end
    return "SYNC-" .. packBytes(xorApply(bytes))
end

-- Returns placeId, jobId, or nil if this isn't a SYNC code.
function SyncCodec.decode(token)
    token = tostring(token or ""):gsub("%s+", "")
    local body = token:match("^SYNC%-(.+)$")
    if not body then return nil end
    local ok, pid, jid = pcall(function()
        local bytes = xorApply(unpackChars(body))
        local chars = {}
        for _, b in ipairs(bytes) do chars[#chars + 1] = string.char(b) end
        local payload = table.concat(chars)
        local p, j = payload:match("^(%d+)|(.+)$")
        return p and tonumber(p) or nil, j
    end)
    if ok then return pid, jid end
    return nil
end

function SyncCodec.isSyncCode(token)
    return tostring(token or ""):match("^%s*SYNC%-") ~= nil
end

return SyncCodec
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
-- Each property is set independently: on some client builds UIShadow.Spread is a
-- UDim2 (not a number), and a single bad assignment inside one pcall used to
-- abort the whole shadow, leaving elements with no shadow at all.
function Util.shadow(target, opts)
    opts = opts or {}
    local okNew, s = pcall(function() return Instance.new("UIShadow") end)
    if not okNew or not s then return nil end
    pcall(function() s.Color = opts.color or Color3.fromRGB(0, 0, 0) end)
    pcall(function() s.BlurRadius = UDim.new(0, opts.blur or 34) end)
    pcall(function()
        local sp = opts.spread or 0
        if typeof(sp) == "UDim2" then s.Spread = sp
        else s.Spread = UDim2.fromOffset(sp, sp) end
    end)
    pcall(function() s.Offset = opts.offset or UDim2.fromOffset(0, 10) end)
    pcall(function() s.Transparency = opts.transparency ~= nil and opts.transparency or 0.5 end)
    local okP = pcall(function() s.Parent = target end)
    return okP and s or nil
end

-- Close a window when Escape is pressed. Ignores the keystroke while a TextBox
-- is focused (so typing Escape in search/chat doesn't nuke the window), and
-- disconnects itself once the gui is gone.
function Util.closeOnEscape(gui, closeFn)
    local UIS = game:GetService("UserInputService")
    local conn
    conn = UIS.InputBegan:Connect(function(input, processed)
        if input.KeyCode == Enum.KeyCode.Escape and not UIS:GetFocusedTextBox() then
            closeFn()
        end
    end)
    gui.Destroying:Connect(function()
        if conn then conn:Disconnect() end
    end)
    return conn
end

-- Remember a centered window's dragged position. Restores the saved pixel
-- offset from center immediately (falls back to centered), then saves the
-- offset, debounced, whenever the window moves. `key` namespaces the storage.
function Util.persistPosition(win, key)
    local ox = tonumber(Util.load(key .. "OX"))
    local oy = tonumber(Util.load(key .. "OY"))
    if ox and oy then
        win.Position = UDim2.new(0.5, ox, 0.5, oy)
    else
        win.Position = UDim2.fromScale(0.5, 0.5)
    end
    local saveVer = 0
    win:GetPropertyChangedSignal("Position"):Connect(function()
        saveVer += 1
        local v = saveVer
        local p = win.Position
        task.delay(0.5, function()
            if v ~= saveVer then return end
            Util.save(key .. "OX", tostring(p.X.Offset))
            Util.save(key .. "OY", tostring(p.Y.Offset))
        end)
    end)
end

-- Make a window draggable by its title bar (mouse + touch). Cleans up its
-- global input connection when the window is destroyed.
function Util.draggable(frame, handle)
    local UIS = game:GetService("UserInputService")
    local dragging = false
    local dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local moveConn = UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    frame.Destroying:Connect(function()
        if moveConn then moveConn:Disconnect() end
    end)
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

        -- entrance: scale up + fade in
        local mScale = Instance.new("UIScale")
        mScale.Scale = 0.9
        mScale.Parent = menu
        menu.BackgroundTransparency = 1
        Util.tween(menu, { BackgroundTransparency = 0.08 }, 0.14)
        Util.tween(mScale, { Scale = 1 }, 0.16, Enum.EasingStyle.Back)

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

    -- Value bubble above the knob, shown while dragging
    local bubble = Instance.new("TextLabel")
    bubble.Text = "0%"
    bubble.Font = Enum.Font.GothamBold
    bubble.TextSize = 11
    bubble.TextColor3 = WHITE
    bubble.TextTransparency = 1
    bubble.BackgroundColor3 = Color3.fromRGB(20, 21, 24)
    bubble.BackgroundTransparency = 1
    bubble.AnchorPoint = Vector2.new(0.5, 1)
    bubble.Position = UDim2.new(value, 0, 0.5, -16)
    bubble.Size = UDim2.fromOffset(38, 18)
    bubble.ZIndex = baseZ + 3
    bubble.Parent = track
    Util.corner(bubble, 6)
    local bubbleStroke = Util.stroke(bubble, WHITE, 1, 1)

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
        bubble.Position = UDim2.new(value, 0, 0.5, -16)
        bubble.Text = math.floor(value * 100 + 0.5) .. "%"
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
    local function showBubble(on)
        Util.tween(bubble, { TextTransparency = on and 0 or 1, BackgroundTransparency = on and 0.05 or 1 }, 0.12)
        Util.tween(bubbleStroke, { Transparency = on and 0.85 or 1 }, 0.12)
    end
    hit.MouseButton1Down:Connect(function()
        dragging = true
        showBubble(true)
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
            if dragging then showBubble(false) end
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

    -- squash pulse on toggle (iOS-style tactile bounce)
    local kscale = Instance.new("UIScale")
    kscale.Parent = knob

    local function render(animate)
        local kp = { Position = UDim2.new(0, knobX(value), 0.5, 0), BackgroundColor3 = value and KNOB_ON or KNOB_OFF }
        local tp = { BackgroundColor3 = value and TRACK_ON or TRACK_OFF }
        if animate then
            Util.tween(knob, kp, 0.18, Enum.EasingStyle.Quart)
            Util.tween(track, tp, 0.18)
            kscale.Scale = 1
            Util.tween(kscale, { Scale = 1.12 }, 0.09)
            task.delay(0.1, function() Util.tween(kscale, { Scale = 1 }, 0.12, Enum.EasingStyle.Back) end)
        else
            knob.Position = kp.Position
            knob.BackgroundColor3 = kp.BackgroundColor3
            track.BackgroundColor3 = tp.BackgroundColor3
            kscale.Scale = 1
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

    -- faint version stamp, bottom-center
    local verStamp = Instance.new("TextLabel")
    verStamp.AnchorPoint = Vector2.new(0.5, 1)
    verStamp.Position = UDim2.new(0.5, 0, 1, -px(22))
    verStamp.Size = UDim2.fromOffset(px(200), px(16))
    verStamp.BackgroundTransparency = 1
    verStamp.Font = Theme.fonts.caption
    verStamp.Text = spaced("SYNC  v1.0")
    verStamp.TextSize = px(12)
    verStamp.TextColor3 = Color3.fromRGB(90, 90, 98)
    verStamp.TextTransparency = 1
    verStamp.ZIndex = 3
    verStamp.Parent = screen
    task.delay(0.8, function()
        if screen.Parent then Util.tween(verStamp, { TextTransparency = 0 }, 0.6, Enum.EasingStyle.Sine) end
    end)

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

local Util        = SYNC.import("core/Util")
local Dock        = SYNC.import("os/Dock")
local Settings    = SYNC.import("os/Settings")
local MenuBar     = SYNC.import("os/MenuBar")
local Home        = SYNC.import("apps/Home")
local Scripts     = SYNC.import("apps/Scripts")
local Joiner      = SYNC.import("apps/Joiner")
local MusicApp    = SYNC.import("apps/Music")
local DesktopMode = SYNC.import("os/DesktopMode")
local WM          = SYNC.import("os/WindowManager")

local Desktop = {}

function Desktop.start()
    -- No wallpaper: the menu bar + dock float over the actual game screen.
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Desktop"
    Util.mount(gui)
    gui.DisplayOrder = 5000000 -- dock/desktop always sits above app windows

    -- Menu bar hidden for now (module kept for later): local menubar = MenuBar.create(gui)
    local menubar = nil

    -- Bring an app window to the front (window manager handles focus + dimming).
    local function raise(appName)
        local host = gui.Parent
        local w = host and host:FindFirstChild("SYNC_" .. appName)
        if w then WM.focus(w) end
    end

    local dock
    dock = Dock.create(gui, function(appName)
        if appName == "Home" then
            Home.open()
            raise("Home")
        elseif appName == "Scripts" then
            Scripts.open()
            raise("Scripts")
        elseif appName == "Joiner" then
            Joiner.open()
            raise("Joiner")
        elseif appName == "Music" then
            MusicApp.open()
            raise("Music")
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
                desktopMode = DesktopMode.isOn(),
                onDesktopMode = function(v)
                    DesktopMode.set(v)
                end,
            })
            raise("Settings")
        end
    end)

    -- Restore Desktop mode if it was left on
    if DesktopMode.isOn() then
        task.defer(function() DesktopMode.enable() end)
    end

    return {
        gui = gui,
        destroy = function()
            if dock then dock.destroy() end
            if menubar then menubar.destroy() end
            DesktopMode.disable()
            gui:Destroy()
        end,
    }
end

return Desktop
end)

SYNC.define("os/DesktopMode", function()
-- SYNC / os / DesktopMode
-- Turns the whole screen into a macOS-style desktop: the user's real wallpaper,
-- a menu bar up top, and the live Roblox game framed as a centered "app" window.
--
-- The trick for showing the RUNNING game inside a window: 2D GUI always draws
-- over the 3D viewport, so you can never see the game "through" a GUI. Instead we
-- cover the screen with the wallpaper in four strips arranged AROUND a central
-- rectangle, and leave that rectangle empty. The game shows through the gap, and
-- we draw macOS window chrome (title bar + traffic lights + a rounded border) on
-- top of the gap's edges. Result: the game looks like a windowed Mac app.
--
-- DesktopMode.set(true/false) toggles it; the choice persists under "DesktopMode".
-- Exit from inside via the red traffic light or the Escape key.

local Util  = SYNC.import("core/Util")
local Theme = SYNC.import("core/Theme")

local DesktopMode = {}

local HS = game:GetService("HttpService")
local RAW_WALLPAPER =
    "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/desktop_wallpaper.jpg"
local IMG_W, IMG_H = 1024, 663 -- committed asset dimensions

DesktopMode._gui = nil

local DARK = Color3.fromRGB(28, 28, 32)

-- weserv turns the jpg into a png getcustomasset can load, at the asset's size.
local function wallpaperAsset()
    local png = "https://images.weserv.nl/?url="
        .. HS:UrlEncode(RAW_WALLPAPER) .. "&output=png&w=" .. IMG_W .. "&h=" .. IMG_H
    return Util.remoteImage(png, "desktop_wallpaper.png")
end

-- lucide icons rasterise BLACK, which is what we want on the light menu bar, so
-- we skip the negate filter (invert) and let the black glyph stand. simple-icons
-- come pre-coloured. Async: fills `img` once the png is ready.
local function loadIcon(img, svgUrl, filename, tint)
    task.spawn(function()
        local pngUrl = "https://images.weserv.nl/?url="
            .. HS:UrlEncode(svgUrl) .. "&output=png&w=48&h=48"
        local id = Util.remoteImage(pngUrl, filename)
        if id and img and img.Parent then
            img.Image = id
            img.ImageColor3 = tint or DARK
        end
    end)
end

function DesktopMode.isOn()
    return Util.load("DesktopMode") == "true"
end

-- Real device-local time (macOS-style), not SYNC's deliberately-offset clock.
-- Roblox's FormatLocalTime tokens are unreliable (its "d" is day-of-week, "tt"
-- prints literally), so we build the string from the ToLocalTime() table.
local WD = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local MO = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local function weekdayIndex(y, m, d) -- Sakamoto's algorithm, 0 = Sunday
    local t = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
    if m < 3 then y = y - 1 end
    return (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400) + t[m] + d) % 7
end
local function localClock()
    local ok, t = pcall(function() return DateTime.now():ToLocalTime() end)
    if ok and t and t.Hour then
        local h = t.Hour % 12
        if h == 0 then h = 12 end
        local ap = t.Hour < 12 and "AM" or "PM"
        local wd = WD[weekdayIndex(t.Year, t.Month, t.Day) + 1]
        local mo = MO[t.Month]
        return string.format("%s %d %s  %d:%02d %s", wd, t.Day, mo, h, t.Minute, ap)
    end
    return Util.date("%a %d %b  %I:%M %p")
end

function DesktopMode.enable()
    if DesktopMode._gui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_DesktopMode"
    Util.mount(gui)
    gui.DisplayOrder = 1000000000 -- sit above every SYNC window
    DesktopMode._gui = gui

    -- Fill the true screen (the IgnoreGuiInset canvas) and measure THAT, not the
    -- camera viewport. The viewport is shorter than the canvas by the top inset,
    -- so sizing to it pushes the menu bar above the visible top.
    local root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.ZIndex = 1
    root.Parent = gui
    task.wait() -- let AbsoluteSize populate
    local W, H = root.AbsoluteSize.X, root.AbsoluteSize.Y
    if W < 1 or H < 1 then local vp = Util.viewport(); W, H = vp.X, vp.Y end

    -- Cover-crop the wallpaper to the screen aspect (true macOS "Fill", no stretch)
    local ia, sa = IMG_W / IMG_H, W / H
    local cropX, cropY, cropW, cropH
    if sa > ia then
        cropW, cropH = IMG_W, IMG_W / sa
        cropX, cropY = 0, (IMG_H - cropH) / 2
    else
        cropW, cropH = IMG_H * sa, IMG_H
        cropX, cropY = (IMG_W - cropW) / 2, 0
    end

    local assetId = wallpaperAsset()

    -- One wallpaper slice covering the screen rect (sx, sy, sw, sh). ImageRect maps
    -- that region back into the source crop so the slices tile seamlessly.
    local function strip(sx, sy, sw, sh)
        if sw <= 0 or sh <= 0 then return end
        local im = Instance.new("ImageLabel")
        im.BackgroundColor3 = Color3.fromRGB(74, 108, 150) -- sky tone while it loads
        im.BorderSizePixel = 0
        im.Position = UDim2.fromOffset(math.floor(sx), math.floor(sy))
        im.Size = UDim2.fromOffset(math.ceil(sw), math.ceil(sh))
        im.ZIndex = 2
        if assetId then
            im.Image = assetId
            im.ImageRectOffset = Vector2.new(cropX + (sx / W) * cropW, cropY + (sy / H) * cropH)
            im.ImageRectSize = Vector2.new((sw / W) * cropW, (sh / H) * cropH)
        end
        im.Parent = root
        return im
    end

    -- Near-maximized window: the game fills the frame with only a thin wallpaper
    -- border and the menu bar across the top. Roblox renders the live game at full
    -- screen, so a big window is what lets you actually see the whole game; the gap
    -- below the title bar is left empty so the game shows through it.
    local MBH = 24            -- menu bar height (also used by the menu below)
    local TBH = 30            -- window title bar height
    local marginX = math.floor(W * 0.035)
    local topGap  = math.floor(H * 0.028)
    local botGap  = math.floor(H * 0.045)
    local wx = marginX
    local wy = MBH + topGap
    local ww = W - marginX * 2
    local wh = H - wy - botGap
    local bodyTop = wy + TBH

    -- Four wallpaper strips around the gap
    strip(0, 0, W, bodyTop)                            -- top band (full width)
    strip(0, wy + wh, W, H - (wy + wh))                -- bottom band (full width)
    strip(0, bodyTop, wx, wh - TBH)                    -- left of the window
    strip(wx + ww, bodyTop, W - (wx + ww), wh - TBH)   -- right of the window

    -- Rounded window border. Transparent body so the game (and its input) pass
    -- through; only the stroke and rounded corners draw.
    local border = Instance.new("Frame")
    border.Active = false
    border.BackgroundTransparency = 1
    border.Position = UDim2.fromOffset(wx, wy)
    border.Size = UDim2.fromOffset(ww, wh)
    border.ZIndex = 3
    border.Parent = root
    Util.corner(border, 10)
    Util.stroke(border, Color3.fromRGB(255, 255, 255), 1, 0.55)

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(wx, wy)
    bar.Size = UDim2.fromOffset(ww, TBH)
    bar.BackgroundColor3 = Color3.fromRGB(52, 52, 57)
    bar.BackgroundTransparency = 0.06
    bar.BorderSizePixel = 0
    bar.ZIndex = 4
    bar.Parent = root
    local bc = Instance.new("UICorner")
    local okc = pcall(function()
        bc.TopLeftRadius = UDim.new(0, 10); bc.TopRightRadius = UDim.new(0, 10)
        bc.BottomLeftRadius = UDim.new(0, 0); bc.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okc then bc.CornerRadius = UDim.new(0, 10) end
    bc.Parent = bar

    -- Traffic lights (red exits desktop mode)
    local cols = { Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }
    for i, col in ipairs(cols) do
        local clickable = (i == 1)
        local dot = Instance.new(clickable and "TextButton" or "Frame")
        if clickable then dot.Text = ""; dot.AutoButtonColor = false end
        dot.Size = UDim2.fromOffset(12, 12)
        dot.Position = UDim2.fromOffset(12 + (i - 1) * 20, (TBH - 12) / 2)
        dot.BackgroundColor3 = col
        dot.BorderSizePixel = 0
        dot.ZIndex = 5
        dot.Parent = bar
        Util.corner(dot, 6)
        if clickable then dot.MouseButton1Click:Connect(function() DesktopMode.set(false) end) end
    end

    -- Window title with the Roblox mark
    local titleWrap = Instance.new("Frame")
    titleWrap.BackgroundTransparency = 1
    titleWrap.AnchorPoint = Vector2.new(0.5, 0.5)
    titleWrap.Position = UDim2.new(0.5, 0, 0.5, 0)
    titleWrap.Size = UDim2.fromOffset(90, 18)
    titleWrap.ZIndex = 5
    titleWrap.Parent = bar
    local rbxMark = Instance.new("ImageLabel")
    rbxMark.BackgroundTransparency = 1
    rbxMark.Size = UDim2.fromOffset(13, 13)
    rbxMark.Position = UDim2.fromOffset(6, 3)
    rbxMark.ZIndex = 5
    rbxMark.Parent = titleWrap
    loadIcon(rbxMark, "cdn.simpleicons.org/roblox/e6e6e6", "ic_roblox_w.png", Color3.fromRGB(230, 230, 235))
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(24, 0)
    title.Size = UDim2.fromOffset(64, 18)
    title.Text = "Roblox"
    title.Font = Theme.fonts.title
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(228, 228, 233)
    title.ZIndex = 5
    title.Parent = titleWrap

    -- ---- Menu bar (frosted light, dark glyphs, like macOS over a bright wallpaper)
    local menu = Instance.new("Frame")
    menu.Size = UDim2.fromOffset(W, MBH)
    menu.BackgroundColor3 = Color3.fromRGB(248, 248, 250)
    menu.BackgroundTransparency = 0.42
    menu.BorderSizePixel = 0
    menu.ZIndex = 6
    menu.Parent = root
    Util.stroke(menu, Color3.fromRGB(0, 0, 0), 1, 0.9)

    -- Left cluster: apple + app menus
    local left = Instance.new("Frame")
    left.BackgroundTransparency = 1
    left.Position = UDim2.fromOffset(12, 0)
    left.Size = UDim2.new(0, 0, 1, 0)
    left.AutomaticSize = Enum.AutomaticSize.X
    left.ZIndex = 7
    left.Parent = menu
    local ll = Instance.new("UIListLayout")
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.VerticalAlignment = Enum.VerticalAlignment.Center
    ll.Padding = UDim.new(0, 15)
    ll.Parent = left

    local apple = Instance.new("ImageLabel")
    apple.BackgroundTransparency = 1
    apple.Size = UDim2.fromOffset(14, 14)
    apple.LayoutOrder = 0
    apple.ZIndex = 7
    apple.Parent = left
    loadIcon(apple, "cdn.simpleicons.org/apple/111111", "ic_apple_d.png", Color3.fromRGB(20, 20, 20))

    local menus = { { "Finder", Theme.fonts.title }, { "File" }, { "Edit" }, { "View" }, { "Go" }, { "Window" }, { "Help" } }
    for i, m in ipairs(menus) do
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Size = UDim2.new(0, 0, 1, 0)
        t.Text = m[1]
        t.Font = m[2] or Theme.fonts.body
        t.TextSize = 13
        t.TextColor3 = Color3.fromRGB(24, 24, 26)
        t.LayoutOrder = i
        t.ZIndex = 7
        t.Parent = left
    end

    -- Right cluster: status icons + clock
    local right = Instance.new("Frame")
    right.BackgroundTransparency = 1
    right.AnchorPoint = Vector2.new(1, 0)
    right.Position = UDim2.new(1, -12, 0, 0)
    right.Size = UDim2.new(0, 0, 1, 0)
    right.AutomaticSize = Enum.AutomaticSize.X
    right.ZIndex = 7
    right.Parent = menu
    local rl = Instance.new("UIListLayout")
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.VerticalAlignment = Enum.VerticalAlignment.Center
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.Padding = UDim.new(0, 14)
    rl.Parent = right

    local function statusIcon(order, svg, file)
        local ic = Instance.new("ImageLabel")
        ic.BackgroundTransparency = 1
        ic.Size = UDim2.fromOffset(15, 15)
        ic.LayoutOrder = order
        ic.ZIndex = 7
        ic.Parent = right
        loadIcon(ic, "cdn.jsdelivr.net/npm/lucide-static/icons/" .. svg .. ".svg", file, DARK)
        return ic
    end
    statusIcon(1, "sliders-horizontal", "ic_cc.png")
    statusIcon(2, "battery-medium", "ic_batt.png")
    statusIcon(3, "wifi", "ic_wifi.png")
    statusIcon(4, "search", "ic_search.png")

    local clock = Instance.new("TextLabel")
    clock.BackgroundTransparency = 1
    clock.AutomaticSize = Enum.AutomaticSize.X
    clock.Size = UDim2.new(0, 0, 1, 0)
    clock.Font = Theme.fonts.body
    clock.TextSize = 13
    clock.TextColor3 = Color3.fromRGB(24, 24, 26)
    clock.Text = localClock()
    clock.LayoutOrder = 5
    clock.ZIndex = 7
    clock.Parent = right
    task.spawn(function()
        while DesktopMode._gui == gui and clock.Parent do
            clock.Text = localClock()
            task.wait(15)
        end
    end)

    -- Exit hint, fades after a few seconds
    local hint = Instance.new("TextLabel")
    hint.AnchorPoint = Vector2.new(0.5, 1)
    hint.Position = UDim2.new(0.5, 0, 1, -18)
    hint.Size = UDim2.fromOffset(360, 22)
    hint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hint.BackgroundTransparency = 0.5
    hint.Text = "Press Esc or click the red dot to leave Desktop mode"
    hint.Font = Theme.fonts.body
    hint.TextSize = 12
    hint.TextColor3 = Color3.fromRGB(240, 240, 245)
    hint.ZIndex = 8
    hint.Parent = root
    Util.corner(hint, 11)
    task.delay(4, function()
        if hint.Parent then
            Util.tween(hint, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.6)
            task.delay(0.7, function() if hint.Parent then hint:Destroy() end end)
        end
    end)

    -- Escape leaves desktop mode
    Util.closeOnEscape(gui, function() DesktopMode.set(false) end)

    -- Entrance: quick fade in from black
    local cover = Instance.new("Frame")
    cover.Size = UDim2.fromScale(1, 1)
    cover.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    cover.BackgroundTransparency = 0
    cover.ZIndex = 50
    cover.Parent = gui
    Util.tween(cover, { BackgroundTransparency = 1 }, 0.3)
    task.delay(0.34, function() if cover.Parent then cover:Destroy() end end)
end

function DesktopMode.disable()
    local g = DesktopMode._gui
    if not g then return end
    DesktopMode._gui = nil
    g:Destroy()
end

function DesktopMode.set(v)
    Util.save("DesktopMode", v and "true" or "false")
    if v then DesktopMode.enable() else DesktopMode.disable() end
end

return DesktopMode
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
    { name = "Scripts",   icon = "file-text",      top = Color3.fromRGB(172, 122, 255), bot = Color3.fromRGB(104, 52, 212) },
    { name = "Joiner",    icon = "compass",        top = Color3.fromRGB(96, 214, 172),  bot = Color3.fromRGB(30, 156, 122) },
    { name = "Music",     icon = "music",          top = Color3.fromRGB(92, 132, 200),  bot = Color3.fromRGB(46, 72, 117) },
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

    -- running-indicator dot (macOS style): lit while the app's window is open
    local runDot = Instance.new("Frame")
    runDot.AnchorPoint = Vector2.new(0.5, 0.5)
    runDot.Size = UDim2.fromOffset(4, 4)
    runDot.BackgroundColor3 = WHITE
    runDot.BackgroundTransparency = 1
    runDot.BorderSizePixel = 0
    runDot.ZIndex = 8
    runDot.Parent = holder
    Util.corner(runDot, 2)

    return {
        holder = holder, label = label, lstroke = lstroke, app = app.name,
        size = BASE_DEFAULT, bounceStart = nil, restCenter = 0, centerMain = 0,
        pressed = false, labelShown = false, runDot = runDot, running = false,
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
                ic.runDot.Position = UDim2.new(0.5, 0, 1, 5)
            elseif pos == "left" then
                ic.holder.AnchorPoint = Vector2.new(0, 0.5)
                ic.holder.Position = UDim2.fromOffset(baseLeftX - curOff + interior, cm)
                ic.label.AnchorPoint = Vector2.new(0, 0.5)
                ic.label.Position = UDim2.new(1, 8, 0.5, 0)
                ic.runDot.Position = UDim2.new(0, -5, 0.5, 0)
            else -- right
                ic.holder.AnchorPoint = Vector2.new(1, 0.5)
                ic.holder.Position = UDim2.fromOffset(baseRightX + curOff - interior, cm)
                ic.label.AnchorPoint = Vector2.new(1, 0.5)
                ic.label.Position = UDim2.new(0, -8, 0.5, 0)
                ic.runDot.Position = UDim2.new(1, 5, 0.5, 0)
            end
            accM += ic.size + GAP
        end

        -- Running dots: lit while the app's window is open (polls CoreGui)
        for _, ic in ipairs(icons) do
            local isOpen = parent.Parent and parent.Parent:FindFirstChild("SYNC_" .. ic.app) ~= nil
            if isOpen ~= ic.running then
                ic.running = isOpen
                Util.tween(ic.runDot, { BackgroundTransparency = isOpen and 0 or 1 }, 0.18)
            end
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

SYNC.define("os/Login", function()
-- SYNC / os / Login
-- A multi-stage "SYNC.GG" sign-in shown after the boot splash, rebuilt to match
-- the reference exactly:
--   A) login form   (Username, Password, LOG IN, SIGN UP / Forgot)
--   B) on LOG IN the button turns red and fills, then a security-check panel
--      slides in from the right (Windows / Anti-Virus / Driver Blacklist /
--      Driver Check, each spinner -> check) with a "CHECKING FOR MISSING PIECES" bar
--   C) a verify screen (avatar + name + UID, SYNC.GG, animated bars, status text)
-- then it hands off to the desktop.
--
-- Credentials are hard-coded for now: Diablo / Diablo.
-- Login.run(onDone) plays and calls onDone() once the user is through.

local Players = game:GetService("Players")
local Theme   = SYNC.import("core/Theme")
local Util    = SYNC.import("core/Util")

local Login = {}

local HS  = game:GetService("HttpService")
local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"

local VIOLET  = Color3.fromRGB(151, 151, 231)
local VIOLETH = Color3.fromRGB(171, 171, 243)
local RED     = Color3.fromRGB(237, 86, 100)
local GREEN   = Color3.fromRGB(86, 202, 128)
local WIN     = Color3.fromRGB(14, 14, 17)
local FIELD   = Color3.fromRGB(23, 24, 29)
local CARD    = Color3.fromRGB(20, 21, 26)
local WHITE   = Color3.fromRGB(244, 244, 248)
local GRAY    = Color3.fromRGB(140, 140, 150)
local DIM     = Color3.fromRGB(95, 95, 105)

local USER = "Diablo"
local PASS = "Diablo"

local QUART = Enum.EasingStyle.Quart
local BACK  = Enum.EasingStyle.Back
local SINE  = Enum.EasingStyle.Sine
local OUT   = Enum.EasingDirection.Out
local IN    = Enum.EasingDirection.In

local function loadIcon(img, name, tint)
    task.spawn(function()
        local url = "https://images.weserv.nl/?url="
            .. HS:UrlEncode("cdn.jsdelivr.net/npm/lucide-static/icons/" .. name .. ".svg")
            .. "&output=png&w=64&h=64&filt=negate"
        local id = Util.remoteImage(url, "ic_lg_" .. name .. ".png")
        if id and img and img.Parent then img.Image = id; img.ImageColor3 = tint or WHITE end
    end)
end

function Login.run(onDone)
    local vp = Util.viewport()
    local S = math.clamp(vp.Y / 1080, 0.5, 1.35)
    local function px(n) return math.floor(n * S + 0.5) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Login"
    Util.mount(gui)

    local done = false
    local function finish()
        if done then return end
        done = true
        if onDone then task.spawn(onDone) end
    end

    -- darkened backdrop (the desktop wallpaper, dimmed)
    local backdrop = Instance.new("ImageLabel")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(10, 11, 16)
    backdrop.BorderSizePixel = 0
    backdrop.ScaleType = Enum.ScaleType.Crop
    backdrop.ImageTransparency = 1
    backdrop.Parent = gui
    task.spawn(function()
        local url = "https://images.weserv.nl/?url=" .. HS:UrlEncode(RAW .. "desktop_wallpaper.jpg")
            .. "&output=png&w=1280&h=720&blur=6"
        local id = Util.remoteImage(url, "login_backdrop.png")
        if id and backdrop.Parent then backdrop.Image = id; Util.tween(backdrop, { ImageTransparency = 0.5 }, 0.6) end
    end)
    local dim = Instance.new("Frame")
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.35
    dim.BorderSizePixel = 0
    dim.Parent = gui

    -- ---- window ----------------------------------------------------------
    local W, H = px(1060), px(648)
    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = WIN
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    Util.corner(win, px(28))
    Util.stroke(win, Color3.fromRGB(255, 255, 255), 1, 0.92)
    Util.shadow(win, { blur = 70, spread = 0, transparency = 0.4, offset = UDim2.fromOffset(0, px(26)) })
    local wScale = Instance.new("UIScale"); wScale.Scale = 0.95; wScale.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(win, { BackgroundTransparency = 0 }, 0.35)
    Util.tween(wScale, { Scale = 1 }, 0.45, BACK, OUT)

    -- title (SYNC.GG) + close, shown for stages A/B
    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(px(40), px(30))
    title.Size = UDim2.fromOffset(px(300), px(30))
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.RichText = true
    title.Text = 'SYNC<font color="rgb(151,151,231)">.</font>GG'
    title.TextSize = px(24)
    title.TextColor3 = WHITE
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 8
    title.Parent = win

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.fromOffset(W - px(30), px(28))
    closeBtn.Size = UDim2.fromOffset(px(28), px(28))
    closeBtn.BackgroundTransparency = 1
    closeBtn.AutoButtonColor = false
    closeBtn.Font = Theme.fonts.body
    closeBtn.Text = "\195\151"
    closeBtn.TextSize = px(24)
    closeBtn.TextColor3 = Color3.fromRGB(180, 180, 188)
    closeBtn.ZIndex = 10
    closeBtn.Parent = win
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = WHITE end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(180, 180, 188) end)

    -- ======================================================================
    -- Stage A: login form
    -- ======================================================================
    local form = Instance.new("Frame")
    form.Size = UDim2.fromScale(1, 1)
    form.BackgroundTransparency = 1
    form.ZIndex = 3
    form.Parent = win

    local FW = px(560)
    local FX = math.floor((W - FW) / 2)
    local py = px(250)

    -- Floating-label field: the label sits centered when empty, floats to the top
    -- when focused / filled, and the typed value shows below it. Passwords render
    -- as dots. Returns box, holder, getValue().
    local DOT = "\226\128\162" -- U+2022 bullet
    local function field(y, labelText, iconName, isPassword)
        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(FX, y)
        holder.Size = UDim2.fromOffset(FW, px(56))
        holder.BackgroundColor3 = FIELD
        holder.BackgroundTransparency = 0.2
        holder.BorderSizePixel = 0
        holder.ClipsDescendants = true
        holder.ZIndex = 3
        holder.Parent = form
        Util.corner(holder, px(10))
        local st = Util.stroke(holder, Color3.fromRGB(70, 70, 80), 1, 0.55)

        -- input value (lower part of the field)
        local box = Instance.new("TextBox")
        box.Position = UDim2.fromOffset(px(18), px(24))
        box.Size = UDim2.fromOffset(FW - px(60), px(26))
        box.BackgroundTransparency = 1
        box.Font = Theme.fonts.body
        box.PlaceholderText = ""
        box.Text = ""
        box.TextSize = px(15)
        box.TextColor3 = WHITE
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.TextYAlignment = Enum.TextYAlignment.Center
        box.ClearTextOnFocus = false
        box.ZIndex = 4
        box.Parent = holder

        -- floating label (starts centered, covering the field)
        local lbl = Instance.new("TextLabel")
        lbl.Position = UDim2.fromOffset(px(18), 0)
        lbl.Size = UDim2.fromOffset(FW - px(60), px(56))
        lbl.BackgroundTransparency = 1
        lbl.Font = Theme.fonts.body
        lbl.Text = labelText
        lbl.TextSize = px(15)
        lbl.TextColor3 = DIM
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        lbl.ZIndex = 4
        lbl.Parent = holder

        local icon = Instance.new("ImageLabel")
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Position = UDim2.new(1, -px(16), 0.5, 0)
        icon.Size = UDim2.fromOffset(px(20), px(20))
        icon.BackgroundTransparency = 1
        icon.ImageColor3 = DIM
        icon.ZIndex = 4
        icon.Parent = holder
        loadIcon(icon, iconName, DIM)

        -- password masking (utf8-safe, so the multibyte dot never corrupts input)
        local realPass = ""
        local getValue = function() return box.Text end
        if isPassword then
            local guard = false
            box:GetPropertyChangedSignal("Text"):Connect(function()
                if guard then return end
                local shown = box.Text
                local typed, total = {}, 0
                local ok = pcall(function()
                    for _, code in utf8.codes(shown) do
                        total = total + 1
                        local ch = utf8.char(code)
                        if ch ~= DOT then typed[#typed + 1] = ch end
                    end
                end)
                if not ok then realPass = shown; total = #shown end
                if #typed > 0 then realPass = realPass .. table.concat(typed)
                elseif total < #realPass then realPass = realPass:sub(1, total) end
                guard = true
                box.Text = string.rep(DOT, #realPass)
                guard = false
            end)
            getValue = function() return realPass end
        end

        local floated = false
        local function setFloat(f)
            if f == floated then return end
            floated = f
            if f then
                Util.tween(lbl, { Position = UDim2.fromOffset(px(18), px(9)), Size = UDim2.fromOffset(FW - px(60), px(14)), TextSize = px(11) }, 0.16, QUART, OUT)
            else
                Util.tween(lbl, { Position = UDim2.fromOffset(px(18), 0), Size = UDim2.fromOffset(FW - px(60), px(56)), TextSize = px(15) }, 0.16, QUART, OUT)
            end
        end
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if box.Text ~= "" then setFloat(true) end
        end)
        box.Focused:Connect(function()
            setFloat(true)
            Util.tween(st, { Transparency = 0.1, Color = VIOLET }, 0.15); icon.ImageColor3 = VIOLET
        end)
        box.FocusLost:Connect(function()
            if box.Text == "" then setFloat(false) end
            Util.tween(st, { Transparency = 0.55, Color = Color3.fromRGB(70, 70, 80) }, 0.15); icon.ImageColor3 = DIM
        end)

        return box, holder, getValue
    end

    local userBox, _, userGet = field(py, "Username", "user", false)
    local passBox, _, passGet = field(py + px(72), "Password", "eye", true)

    -- LOG IN button (with an inner fill for the red loading sweep)
    local loginBtn = Instance.new("TextButton")
    loginBtn.Position = UDim2.fromOffset(FX, py + px(160))
    loginBtn.Size = UDim2.fromOffset(FW, px(58))
    loginBtn.BackgroundColor3 = VIOLET
    loginBtn.AutoButtonColor = false
    loginBtn.Font = Theme.fonts.title
    loginBtn.Text = "LOG IN"
    loginBtn.TextSize = px(17)
    loginBtn.TextColor3 = Color3.fromRGB(28, 26, 44)
    loginBtn.BorderSizePixel = 0
    loginBtn.ClipsDescendants = true
    loginBtn.ZIndex = 3
    loginBtn.Parent = form
    Util.corner(loginBtn, px(10))
    local btnLocked = false
    loginBtn.MouseEnter:Connect(function() if not btnLocked then Util.tween(loginBtn, { BackgroundColor3 = VIOLETH }, 0.12) end end)
    loginBtn.MouseLeave:Connect(function() if not btnLocked then Util.tween(loginBtn, { BackgroundColor3 = VIOLET }, 0.12) end end)

    -- click ripple: a light circle that expands from the click point and fades
    local rippleX, rippleY = FW / 2, px(29)
    loginBtn.MouseButton1Down:Connect(function(x, y)
        rippleX = x - loginBtn.AbsolutePosition.X
        rippleY = y - loginBtn.AbsolutePosition.Y
    end)
    local function ripple()
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.fromOffset(rippleX, rippleY)
        r.Size = UDim2.fromOffset(0, 0)
        r.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        r.BackgroundTransparency = 0.55
        r.BorderSizePixel = 0
        r.ZIndex = 4
        r.Parent = loginBtn
        Util.corner(r, 999)
        local d = math.max(loginBtn.AbsoluteSize.X, px(300)) * 2.4
        Util.tween(r, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, 0.5, QUART, OUT)
        task.delay(0.55, function() if r.Parent then r:Destroy() end end)
    end
    -- color wipe: a coloured panel grows from the left, then becomes the bg
    local function wipeTo(color, dur, cb)
        local ov = Instance.new("Frame")
        ov.Size = UDim2.new(0, 0, 1, 0)
        ov.BackgroundColor3 = color
        ov.BorderSizePixel = 0
        ov.ZIndex = 3
        ov.Parent = loginBtn
        Util.tween(ov, { Size = UDim2.new(1, 0, 1, 0) }, dur, QUART, OUT)
        task.delay(dur, function()
            loginBtn.BackgroundColor3 = color
            if ov.Parent then ov:Destroy() end
            if cb then cb() end
        end)
    end

    -- small loading spinner inside the button (appears while it turns red)
    local spinner = Instance.new("ImageLabel")
    spinner.AnchorPoint = Vector2.new(0.5, 0.5)
    spinner.Position = UDim2.fromOffset(px(70), px(29))
    spinner.Size = UDim2.fromOffset(px(18), px(18))
    spinner.BackgroundTransparency = 1
    spinner.ImageColor3 = Color3.fromRGB(255, 255, 255)
    spinner.ImageTransparency = 1
    spinner.ZIndex = 5
    spinner.Parent = loginBtn
    loadIcon(spinner, "loader-circle", Color3.fromRGB(255, 255, 255))
    local function setSpinner(on)
        spinner.ImageTransparency = on and 0 or 1
        spinner:SetAttribute("s", on)
        if on then
            task.spawn(function()
                while spinner.Parent and spinner:GetAttribute("s") do
                    Util.tween(spinner, { Rotation = spinner.Rotation + 180 }, 0.45, Enum.EasingStyle.Linear)
                    task.wait(0.45)
                end
            end)
        end
    end

    -- bottom links
    local links = Instance.new("TextLabel")
    links.Position = UDim2.fromOffset(FX, py + px(228))
    links.Size = UDim2.fromOffset(px(300), px(18))
    links.BackgroundTransparency = 1
    links.Font = Theme.fonts.caption
    links.RichText = true
    links.Text = '<font color="rgb(120,120,130)">Don\'t have an account? </font><font color="rgb(230,230,236)">SIGN UP</font>'
    links.TextSize = px(13)
    links.TextXAlignment = Enum.TextXAlignment.Left
    links.ZIndex = 3
    links.Parent = form
    local forgot = Instance.new("TextLabel")
    forgot.AnchorPoint = Vector2.new(1, 0)
    forgot.Position = UDim2.fromOffset(FX + FW, py + px(228))
    forgot.Size = UDim2.fromOffset(px(160), px(18))
    forgot.BackgroundTransparency = 1
    forgot.Font = Theme.fonts.caption
    forgot.Text = "Forgot password?"
    forgot.TextSize = px(13)
    forgot.TextColor3 = GRAY
    forgot.TextXAlignment = Enum.TextXAlignment.Right
    forgot.ZIndex = 3
    forgot.Parent = form

    -- scrim that fades in over the form when the checks appear (reads as the
    -- background receding / blurring behind the cards)
    local formDim = Instance.new("Frame")
    formDim.Size = UDim2.fromScale(1, 1)
    formDim.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    formDim.BackgroundTransparency = 1
    formDim.BorderSizePixel = 0
    formDim.ZIndex = 5
    formDim.Parent = win
    Util.corner(formDim, px(28)) -- match window so corners stay curved

    -- ======================================================================
    -- Stage B: security checks (built hidden, fades in from the right)
    -- ======================================================================
    local checks = Instance.new("Frame")
    checks.Size = UDim2.fromScale(1, 1)
    checks.BackgroundTransparency = 1
    checks.ZIndex = 7
    checks.Visible = false
    checks.Parent = win

    local CKW = px(500)
    local CKX = W - px(40) - CKW
    local function checkCard(i, y, name, sub)
        local c = Instance.new("Frame")
        c.Position = UDim2.fromOffset(CKX, y + px(16)) -- starts a touch low, fades + rises into place
        c.Size = UDim2.fromOffset(CKW, px(76))
        c.BackgroundColor3 = CARD
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0
        c.ZIndex = 7
        c.Parent = checks
        Util.corner(c, px(14))
        Util.stroke(c, Color3.fromRGB(60, 60, 70), 1, 0.7)
        Util.shadow(c, { blur = 34, spread = 0, transparency = 0.55, offset = UDim2.fromOffset(0, px(10)) })
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(px(20), px(15))
        t.Size = UDim2.fromOffset(CKW - px(80), px(20))
        t.BackgroundTransparency = 1
        t.Font = Theme.fonts.title
        t.Text = name
        t.TextSize = px(16)
        t.TextColor3 = WHITE
        t.TextTransparency = 1
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 9
        t.Parent = c
        local d = Instance.new("TextLabel")
        d.Position = UDim2.fromOffset(px(20), px(40))
        d.Size = UDim2.fromOffset(CKW - px(80), px(18))
        d.BackgroundTransparency = 1
        d.Font = Theme.fonts.caption
        d.Text = sub
        d.TextSize = px(12)
        d.TextColor3 = DIM
        d.TextTransparency = 1
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.ZIndex = 9
        d.Parent = c
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(1, 0.5)
        ic.Position = UDim2.new(1, -px(20), 0.5, 0)
        ic.Size = UDim2.fromOffset(px(20), px(20))
        ic.BackgroundTransparency = 1
        ic.ImageColor3 = DIM
        ic.ImageTransparency = 1
        ic.ZIndex = 9
        ic.Parent = c
        loadIcon(ic, "rotate-cw", GRAY)
        return { frame = c, title = t, sub = d, icon = ic }
    end

    -- detect the real OS so the first card names the actual device
    local osName, osDetail = "Device", "System check"
    pcall(function()
        local p = game:GetService("UserInputService"):GetPlatform().Name
        local map = {
            Windows = { "Windows", "Windows 11 22h4" },
            OSX     = { "macOS", "Apple macOS" },
            Linux   = { "Linux", "Linux desktop" },
            Android = { "Android", "Android device" },
            IOS     = { "iOS", "Apple iOS" },
        }
        local m = map[p]
        if m then osName, osDetail = m[1], m[2] else osName, osDetail = p, p end
    end)
    local ckDefs = {
        { osName, osDetail },
        { "Anti-Virus", "Availability check..." },
        { "Driver Blacklist", "Availability check..." },
        { "Driver Check", "Availability check..." },
    }
    local cards = {}
    for i, cd in ipairs(ckDefs) do
        cards[i] = checkCard(i, px(90) + (i - 1) * px(90), cd[1], cd[2])
    end

    local checkBar = Instance.new("Frame")
    checkBar.AnchorPoint = Vector2.new(0, 1)
    checkBar.Position = UDim2.fromOffset(CKX, H - px(40) + px(16))
    checkBar.Size = UDim2.fromOffset(CKW, px(50))
    checkBar.BackgroundColor3 = CARD
    checkBar.BackgroundTransparency = 1
    checkBar.BorderSizePixel = 0
    checkBar.ZIndex = 7
    checkBar.Parent = checks
    Util.corner(checkBar, px(12))
    Util.stroke(checkBar, Color3.fromRGB(60, 60, 70), 1, 0.7)
    Util.shadow(checkBar, { blur = 34, spread = 0, transparency = 0.55, offset = UDim2.fromOffset(0, px(10)) })
    local checkBarTxt = Instance.new("TextLabel")
    checkBarTxt.Size = UDim2.fromScale(1, 1)
    checkBarTxt.BackgroundTransparency = 1
    checkBarTxt.Font = Theme.fonts.title
    checkBarTxt.Text = "CHECKING FOR MISSING PIECES"
    checkBarTxt.TextSize = px(13)
    checkBarTxt.TextColor3 = Color3.fromRGB(210, 210, 218)
    checkBarTxt.TextTransparency = 1
    checkBarTxt.ZIndex = 9
    checkBarTxt.Parent = checkBar

    -- ======================================================================
    -- Stage C: verify screen (built hidden)
    -- ======================================================================
    local verify = Instance.new("Frame")
    verify.Size = UDim2.fromScale(1, 1)
    verify.BackgroundColor3 = WIN
    verify.BackgroundTransparency = 1
    verify.BorderSizePixel = 0
    verify.ZIndex = 8
    verify.Visible = false
    verify.Parent = win
    Util.corner(verify, px(28)) -- match window so corners stay curved

    local av = Instance.new("ImageLabel")
    av.Position = UDim2.fromOffset(px(40), px(28))
    av.Size = UDim2.fromOffset(px(46), px(46))
    av.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    av.BorderSizePixel = 0
    av.ZIndex = 9
    av.Parent = verify
    Util.corner(av, px(23))
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and url and av.Parent then av.Image = url end
    end)
    local vName = Instance.new("TextLabel")
    vName.Position = UDim2.fromOffset(px(96), px(30))
    vName.Size = UDim2.fromOffset(px(240), px(20))
    vName.BackgroundTransparency = 1
    vName.Font = Theme.fonts.title
    vName.Text = "Past Owl"
    vName.TextSize = px(16)
    vName.TextColor3 = WHITE
    vName.TextXAlignment = Enum.TextXAlignment.Left
    vName.ZIndex = 9
    vName.Parent = verify
    local vUid = Instance.new("TextLabel")
    vUid.Position = UDim2.fromOffset(px(96), px(51))
    vUid.Size = UDim2.fromOffset(px(240), px(16))
    vUid.BackgroundTransparency = 1
    vUid.Font = Theme.fonts.caption
    vUid.Text = "UID: 1145"
    vUid.TextSize = px(12)
    vUid.TextColor3 = DIM
    vUid.TextXAlignment = Enum.TextXAlignment.Left
    vUid.ZIndex = 9
    vUid.Parent = verify
    local vTitle = Instance.new("TextLabel")
    vTitle.AnchorPoint = Vector2.new(0.5, 0)
    vTitle.Position = UDim2.fromOffset(W / 2, px(32))
    vTitle.Size = UDim2.fromOffset(px(300), px(30))
    vTitle.BackgroundTransparency = 1
    vTitle.Font = Enum.Font.GothamBlack
    vTitle.RichText = true
    vTitle.Text = 'SYNC<font color="rgb(151,151,231)">.</font>GG'
    vTitle.TextSize = px(24)
    vTitle.TextColor3 = WHITE
    vTitle.ZIndex = 9
    vTitle.Parent = verify
    local vStatus = Instance.new("TextLabel")
    vStatus.AnchorPoint = Vector2.new(0.5, 1)
    vStatus.Position = UDim2.fromOffset(W / 2, H - px(40))
    vStatus.Size = UDim2.fromOffset(px(500), px(20))
    vStatus.BackgroundTransparency = 1
    vStatus.Font = Theme.fonts.caption
    vStatus.Text = "Verify the account and your data from the server."
    vStatus.TextSize = px(14)
    vStatus.TextColor3 = GRAY
    vStatus.ZIndex = 9
    vStatus.Parent = verify

    -- equalizer bars
    local bars = {}
    local barW, barH, gap = px(30), px(96), px(10)
    local totalW = 3 * barW + 2 * gap
    for i = 1, 3 do
        local b = Instance.new("Frame")
        b.AnchorPoint = Vector2.new(0, 0.5)
        b.Position = UDim2.fromOffset(W / 2 - totalW / 2 + (i - 1) * (barW + gap), H / 2)
        b.Size = UDim2.fromOffset(barW, barH)
        b.BackgroundColor3 = Color3.fromRGB(160, 158, 214)
        b.BorderSizePixel = 0
        b.ZIndex = 9
        b.Parent = verify
        Util.corner(b, px(7))
        bars[i] = b
    end

    -- ======================================================================
    -- flow
    -- ======================================================================
    local function spin(icon)
        task.spawn(function()
            while icon.Parent and icon:GetAttribute("spinning") do
                Util.tween(icon, { Rotation = icon.Rotation + 180 }, 0.7, Enum.EasingStyle.Linear)
                task.wait(0.7)
            end
        end)
    end

    local function runChecks(afterAll)
        checks.Visible = true
        -- background recedes: scrim fades in over the form, form eases back
        Util.tween(formDim, { BackgroundTransparency = 0.42 }, 0.55, SINE)
        for _, o in ipairs(form:GetDescendants()) do
            if o:IsA("TextLabel") then Util.tween(o, { TextTransparency = 0.85 }, 0.5)
            elseif o:IsA("TextBox") then Util.tween(o, { TextTransparency = 0.85 }, 0.5) end
        end
        Util.tween(loginBtn, { BackgroundTransparency = 0.55 }, 0.5)
        -- cards fade + rise into place, gentle stagger
        for i, card in ipairs(cards) do
            task.delay((i - 1) * 0.14, function()
                Util.tween(card.frame, { Position = UDim2.fromOffset(CKX, px(90) + (i - 1) * px(90)), BackgroundTransparency = 0 }, 0.55, QUART, OUT)
                Util.tween(card.title, { TextTransparency = 0 }, 0.55)
                Util.tween(card.sub, { TextTransparency = 0 }, 0.55)
                Util.tween(card.icon, { ImageTransparency = 0 }, 0.55)
            end)
        end
        task.delay(0.14 * #cards, function()
            Util.tween(checkBar, { Position = UDim2.fromOffset(CKX, H - px(40)), BackgroundTransparency = 0 }, 0.6, QUART, OUT)
            Util.tween(checkBarTxt, { TextTransparency = 0 }, 0.6)
        end)
        -- resolve sequentially (slow, deliberate)
        task.spawn(function()
            task.wait(1.3)
            for i, card in ipairs(cards) do
                if i == 1 then
                    loadIcon(card.icon, "check", VIOLET) -- OS: verified straight away
                else
                    card.icon:SetAttribute("spinning", true); spin(card.icon)
                    task.wait(1.4)
                    card.icon:SetAttribute("spinning", false)
                    card.icon.Rotation = 0
                    loadIcon(card.icon, "check", VIOLET)
                    card.sub.Text = "Passed"
                end
                task.wait(0.7)
            end
            task.wait(0.8)
            if afterAll then afterAll() end
        end)
    end

    local function showVerify()
        vName.Text = (userBox.Text ~= "" and userBox.Text) or "Past Owl"
        vUid.Text = "UID: " .. tostring(Players.LocalPlayer.UserId)
        -- hand off cleanly: hide the checks + form, cover with an opaque verify
        -- screen, then fade its content in (no messy overlap)
        checks.Visible = false
        form.Visible = false
        formDim.Visible = false
        title.Visible = false
        verify.Visible = true
        verify.BackgroundTransparency = 0
        for _, o in ipairs(verify:GetDescendants()) do
            if o:IsA("TextLabel") then o.TextTransparency = 1; Util.tween(o, { TextTransparency = 0 }, 0.5, SINE)
            elseif o:IsA("ImageLabel") then o.ImageTransparency = 1; Util.tween(o, { ImageTransparency = 0 }, 0.5, SINE)
            elseif o:IsA("Frame") then o.BackgroundTransparency = 1; Util.tween(o, { BackgroundTransparency = 0 }, 0.5, SINE) end
        end
        -- animate the bars: a slow, smooth staggered up/down pulse (middle leads)
        task.spawn(function()
            while verify.Parent and verify.Visible do
                for i, b in ipairs(bars) do
                    task.delay((i - 1) * 0.16, function()
                        if b.Parent then Util.tween(b, { Size = UDim2.fromOffset(barW, px(56)) }, 0.55, SINE, Enum.EasingDirection.InOut) end
                    end)
                end
                task.wait(0.72)
                for i, b in ipairs(bars) do
                    task.delay((i - 1) * 0.16, function()
                        if b.Parent then Util.tween(b, { Size = UDim2.fromOffset(barW, barH) }, 0.55, SINE, Enum.EasingDirection.InOut) end
                    end)
                end
                task.wait(0.78)
            end
        end)
        task.delay(3.6, function()
            Util.tween(win, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(verify, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(dim, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(backdrop, { ImageTransparency = 1 }, 0.3)
            task.delay(0.34, function() gui:Destroy(); finish() end)
        end)
    end

    local busy = false
    local function attempt()
        if busy then return end
        if userBox.Text == USER and passGet() == PASS then
            busy = true
            btnLocked = true
            -- correct: morph violet -> GREEN (success) + loading spinner, then checks
            Util.tween(loginBtn, { BackgroundColor3 = GREEN }, 0.5, SINE)
            setSpinner(true)
            task.delay(2.1, function()
                setSpinner(false)
                runChecks(showVerify)
            end)
        else
            btnLocked = true
            Util.tween(loginBtn, { BackgroundColor3 = RED }, 0.35, SINE)
            task.delay(1.1, function()
                Util.tween(loginBtn, { BackgroundColor3 = VIOLET }, 0.4, SINE)
                task.delay(0.42, function() btnLocked = false end)
            end)
        end
    end

    loginBtn.MouseButton1Click:Connect(attempt)
    passBox.FocusLost:Connect(function(enter) if enter then attempt() end end)
    userBox.FocusLost:Connect(function(enter) if enter then passBox:CaptureFocus() end end)
    closeBtn.MouseButton1Click:Connect(function()
        Util.tween(win, { BackgroundTransparency = 1 }, 0.25)
        Util.tween(wScale, { Scale = 0.96 }, 0.25)
        Util.tween(dim, { BackgroundTransparency = 1 }, 0.3)
        Util.tween(backdrop, { ImageTransparency = 1 }, 0.3)
        task.delay(0.3, function() gui:Destroy(); finish() end)
    end)

    return gui
end

return Login
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
local WM     = SYNC.import("os/WindowManager")

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
    WM.register(gui, win, 12)

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
end)

SYNC.define("os/WindowManager", function()
-- SYNC / os / WindowManager
-- macOS-style window focus for app windows. Each app registers its window; the
-- manager raises the clicked window above the others (DisplayOrder), and fades a
-- dim overlay over every window that isn't focused, so the active one stands out.
-- Windows never close from a background click - only the red light or Escape.
--
-- WM.register(gui, win, cornerRadius) -> adds the dim overlay + click-to-focus.
-- WM.focus(gui) -> bring that window to the front.

local Util = SYNC.import("core/Util")

local WM = {}

-- App windows live in this DisplayOrder band; the desktop/dock sits well above it
-- so it is always on top.
local BASE = 400000
local top = 0
local entries = {}

function WM.focus(gui)
    if not gui or not gui.Parent then return end
    top = top + 2
    for _, e in ipairs(entries) do
        if e.gui == gui then
            pcall(function() e.gui.DisplayOrder = BASE + top end)
            Util.tween(e.dim, { BackgroundTransparency = 1 }, 0.16)
        else
            Util.tween(e.dim, { BackgroundTransparency = 0.4 }, 0.16)
        end
    end
end

function WM.register(gui, win, cornerRadius)
    -- dim overlay (covers the whole window; non-interactive so clicks pass through)
    local dim = Instance.new("Frame")
    dim.Name = "WM_Dim"
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 1
    dim.BorderSizePixel = 0
    dim.Active = false
    dim.ZIndex = 900
    dim.Parent = win
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, cornerRadius or 14)
    uic.Parent = dim

    local entry = { gui = gui, win = win, dim = dim }
    entries[#entries + 1] = entry

    -- clicking anywhere on the window focuses it
    win.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            WM.focus(gui)
        end
    end)

    -- drop the entry when the window is destroyed
    gui.AncestryChanged:Connect(function()
        if not gui.Parent then
            for i, e in ipairs(entries) do
                if e.gui == gui then table.remove(entries, i) break end
            end
        end
    end)

    WM.focus(gui)
    return dim
end

return WM
end)

SYNC.define("apps/Home", function()
-- SYNC / apps / Home
-- Orca-style home dashboard (look ported from github.com/richie0866/orca):
-- profile card (gradient avatar ring + joined/friends stats), server card
-- (players / elapsed / ping + hop & rejoin buttons), clock pill, and Friend
-- Activity with full-bleed game thumbnails and expanding join chips.
-- Chat panel has two channels: Server (game chat) and Universal — a Discord
-- channel bridged through the SYNC relay so in-game players and Discord
-- members talk in one room.

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
local WM    = SYNC.import("os/WindowManager")

local Home = {}

local WHITE   = Color3.fromRGB(255, 255, 255)
local SUB     = Color3.fromRGB(142, 142, 147)
local WIN     = Color3.fromRGB(14, 15, 17)
local CARD    = Color3.fromRGB(22, 23, 26)
local FIELD   = Color3.fromRGB(36, 37, 42)
local ACCENT  = Theme.accent
local GREEN   = Color3.fromRGB(62, 209, 148)   -- orca join green
local BLURPLE = Color3.fromRGB(88, 101, 242)   -- discord names
local RINGA   = Color3.fromRGB(168, 85, 247)   -- avatar ring gradient (purple)
local RINGB   = Color3.fromRGB(59, 130, 246)   -- avatar ring gradient (blue)

-- Universal chat bridge (same relay as the old Discord app; key is a
-- speed-bump only, the bot token stays server-side)
local RELAY_URL    = "https://relay-production-a9e3.up.railway.app"
local API_KEY      = "CdTt-Mmf25ewBa8Ak9DQujolBQ7HQ9Va76lyV4ulXDnIyc8XOPih2w"
local UNIVERSAL_ID = "1528867061428654201"

local TITLE_FONT = Enum.Font.GothamBlack
local BODY_BOLD  = Enum.Font.GothamBold

Home._gui = nil

local function headshot(userId, size)
    return ("rbxthumb://type=AvatarHeadShot&id=%d&w=%d&h=%d"):format(userId, size, size)
end

local function subHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end
local SUB_HEX = subHex(SUB)

function Home.open()
    -- Stale guard: the gui may have been destroyed externally (respawn, cleanup)
    if Home._gui and Home._gui.Parent then return end
    Home._gui = nil

    local lp = Util.localPlayer()
    local winW, winH = 890, 560
    local TB = 40
    local PAD = 20
    local COL1, COL2, COL3 = 264, 306, 250
    local GAPX = 14

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Home"
    Util.mount(gui)
    Home._gui = gui

    local alive = true
    local conns = {}
    local winRef, scaleRef -- filled in below; close() animates them out

    local closing = false
    local function close()
        if not Home._gui or closing then return end
        closing = true
        Home._gui = nil
        alive = false
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        if winRef and scaleRef then
            Util.tween(scaleRef, { Scale = 0.94 }, 0.15)
            Util.tween(winRef, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.17, function() gui:Destroy() end)
        else
            gui:Destroy()
        end
    end

    Util.closeOnEscape(gui, close)

    -- Window
    local win = Instance.new("TextButton")
    win.Text = ""
    win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5) -- persistPosition overrides below
    win.Size = UDim2.fromOffset(winW, winH)
    win.BackgroundColor3 = WIN
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 16)
    Util.stroke(win, WHITE, 1, 0.88)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })
    WM.register(gui, win, 16)

    -- Entrance: quick scale + fade in
    local scaleFx = Instance.new("UIScale")
    scaleFx.Scale = 0.94
    scaleFx.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleFx, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0 }, 0.18)
    winRef, scaleRef = win, scaleFx

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = CARD
    bar.BackgroundTransparency = 0.35
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local barCorner = Instance.new("UICorner")
    local okCorner = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 16)
        barCorner.TopRightRadius = UDim.new(0, 16)
        barCorner.BottomLeftRadius = UDim.new(0, 0)
        barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okCorner then barCorner.CornerRadius = UDim.new(0, 16) end
    barCorner.Parent = bar

    local lights = { Theme.red, Theme.yellow, Theme.green }
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
    Util.persistPosition(win, "HomeWin")

    local barTitle = Instance.new("TextLabel")
    barTitle.Size = UDim2.new(1, 0, 1, 0)
    barTitle.BackgroundTransparency = 1
    barTitle.Text = "Home"
    barTitle.Font = Theme.fonts.title
    barTitle.TextSize = 14
    barTitle.TextColor3 = Color3.fromRGB(200, 200, 206)
    barTitle.ZIndex = 3
    barTitle.Parent = bar

    local contentY = TB + PAD
    local contentH = winH - contentY - PAD

    local function makeCard(x, y, w, h, parent)
        local c = Instance.new("Frame")
        c.Position = UDim2.fromOffset(x, y)
        c.Size = UDim2.fromOffset(w, h)
        c.BackgroundColor3 = CARD
        c.BorderSizePixel = 0
        c.ClipsDescendants = true
        c.ZIndex = 3
        c.Parent = parent or win
        Util.corner(c, 18)
        Util.rimStroke(c, 1, 0.82, 0.96)
        return c
    end

    local function cardTitle(parent, text)
        local t = Instance.new("TextLabel")
        t.Text = text
        t.Font = TITLE_FONT
        t.TextSize = 19
        t.TextColor3 = WHITE
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.BackgroundTransparency = 1
        t.Position = UDim2.fromOffset(20, 18)
        t.Size = UDim2.new(1, -40, 0, 22)
        t.ZIndex = 4
        t.Parent = parent
        return t
    end

    -- -----------------------------------------------------------------------
    -- Profile card (col 1)
    -- -----------------------------------------------------------------------
    local profileCard = makeCard(PAD, contentY, COL1, contentH)

    local profileView = Instance.new("Frame")
    profileView.Size = UDim2.fromScale(1, 1)
    profileView.BackgroundTransparency = 1
    profileView.ZIndex = 3
    profileView.Parent = profileCard

    local avatarHolder = Instance.new("Frame")
    avatarHolder.Size = UDim2.fromOffset(124, 124)
    avatarHolder.AnchorPoint = Vector2.new(0.5, 0)
    avatarHolder.Position = UDim2.new(0.5, 0, 0, 36)
    avatarHolder.BackgroundColor3 = FIELD
    avatarHolder.ZIndex = 3
    avatarHolder.Parent = profileView
    Util.corner(avatarHolder, 62)
    local ring = Util.stroke(avatarHolder, WHITE, 4, 0)
    local ringGrad = Instance.new("UIGradient")
    ringGrad.Color = ColorSequence.new(RINGA, RINGB)
    ringGrad.Rotation = 45
    ringGrad.Parent = ring
    -- slow continuous spin on the ring gradient
    local TweenService = game:GetService("TweenService")
    TweenService:Create(ringGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 405 }):Play()

    local avatar = Instance.new("ImageLabel")
    avatar.Image = headshot(lp.UserId, 150)
    avatar.Size = UDim2.new(1, -8, 1, -8)
    avatar.AnchorPoint = Vector2.new(0.5, 0.5)
    avatar.Position = UDim2.fromScale(0.5, 0.5)
    avatar.BackgroundTransparency = 1
    avatar.ZIndex = 4
    avatar.Parent = avatarHolder
    Util.corner(avatar, 58)

    local dispName = Instance.new("TextLabel")
    dispName.Text = lp.DisplayName or lp.Name
    dispName.Font = TITLE_FONT
    dispName.TextSize = 22
    dispName.TextColor3 = WHITE
    dispName.BackgroundTransparency = 1
    dispName.Position = UDim2.new(0, 0, 0, 176)
    dispName.Size = UDim2.new(1, 0, 0, 26)
    dispName.ZIndex = 3
    dispName.Parent = profileView

    local userName = Instance.new("TextLabel")
    userName.Text = lp.Name
    userName.Font = BODY_BOLD
    userName.TextSize = 15
    userName.TextColor3 = SUB
    userName.BackgroundTransparency = 1
    userName.Position = UDim2.new(0, 0, 0, 204)
    userName.Size = UDim2.new(1, 0, 0, 18)
    userName.ZIndex = 3
    userName.Parent = profileView

    -- Click the avatar to copy your profile link (brief confirmation on @name)
    local avatarBtn = Instance.new("TextButton")
    avatarBtn.Text = ""
    avatarBtn.AutoButtonColor = false
    avatarBtn.BackgroundTransparency = 1
    avatarBtn.Size = UDim2.fromScale(1, 1)
    avatarBtn.ZIndex = 5
    avatarBtn.Parent = avatarHolder
    Util.corner(avatarBtn, 62)

    -- hover affordance: scale the avatar up + a copy-hint overlay
    local avatarScale = Instance.new("UIScale")
    avatarScale.Parent = avatarHolder
    local copyHint = Instance.new("Frame")
    copyHint.Size = UDim2.fromScale(1, 1)
    copyHint.BackgroundColor3 = Color3.new(0, 0, 0)
    copyHint.BackgroundTransparency = 1
    copyHint.ZIndex = 5
    copyHint.Parent = avatarHolder
    Util.corner(copyHint, 62)
    local copyHintIcon = Instance.new("ImageLabel")
    copyHintIcon.Size = UDim2.fromOffset(24, 24)
    copyHintIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    copyHintIcon.Position = UDim2.fromScale(0.5, 0.5)
    copyHintIcon.BackgroundTransparency = 1
    copyHintIcon.ImageTransparency = 1
    copyHintIcon.ZIndex = 6
    copyHintIcon.Parent = copyHint
    Icons.apply(copyHintIcon, "file-text", WHITE)
    avatarBtn.MouseEnter:Connect(function()
        Util.tween(avatarScale, { Scale = 1.05 }, 0.14, Enum.EasingStyle.Back)
        Util.tween(copyHint, { BackgroundTransparency = 0.45 }, 0.14)
        Util.tween(copyHintIcon, { ImageTransparency = 0 }, 0.14)
    end)
    avatarBtn.MouseLeave:Connect(function()
        Util.tween(avatarScale, { Scale = 1 }, 0.14)
        Util.tween(copyHint, { BackgroundTransparency = 1 }, 0.14)
        Util.tween(copyHintIcon, { ImageTransparency = 1 }, 0.14)
    end)

    local copyResetAt = 0
    avatarBtn.MouseButton1Click:Connect(function()
        local ok = pcall(function()
            setclipboard(("https://www.roblox.com/users/%d/profile"):format(lp.UserId))
        end)
        if ok then
            userName.Text = "Profile link copied"
            userName.TextColor3 = GREEN
            local myStamp = os.clock()
            copyResetAt = myStamp
            task.delay(1.4, function()
                if userName.Parent and copyResetAt == myStamp then
                    userName.Text = lp.Name
                    userName.TextColor3 = SUB
                end
            end)
        end
    end)

    -- Bottom stats row: joined / friends joined / friends online
    local statsRowY = contentH - 150
    local statCells = {}
    for i = 1, 3 do
        local cell = Instance.new("TextLabel")
        cell.RichText = true
        cell.Text = ""
        cell.Font = BODY_BOLD
        cell.TextSize = 13
        cell.TextColor3 = WHITE
        cell.TextWrapped = true
        cell.BackgroundTransparency = 1
        cell.Position = UDim2.new((i - 1) / 3, 4, 0, statsRowY)
        cell.Size = UDim2.new(1 / 3, -8, 0, 44)
        cell.ZIndex = 3
        cell.Parent = profileView
        statCells[i] = cell
        if i > 1 then
            local div = Instance.new("Frame")
            div.Size = UDim2.fromOffset(1, 34)
            div.Position = UDim2.new((i - 1) / 3, 0, 0, statsRowY + 5)
            div.BackgroundColor3 = Color3.fromRGB(70, 70, 76)
            div.BackgroundTransparency = 0.4
            div.BorderSizePixel = 0
            div.ZIndex = 3
            div.Parent = profileView
        end
    end

    local joinDate = os.date("%m/%d/%Y", os.time() - lp.AccountAge * 86400)
    statCells[1].Text = ('Joined<br /><font color="%s">%s</font>'):format(SUB_HEX, joinDate)
    statCells[2].Text = ('--<br /><font color="%s">friends joined</font>'):format(SUB_HEX)
    statCells[3].Text = ('--<br /><font color="%s">friends online</font>'):format(SUB_HEX)

    -- Chat pill (opens the chat view)
    local chatPill = Instance.new("TextButton")
    chatPill.Text = ""
    chatPill.AutoButtonColor = false
    chatPill.AnchorPoint = Vector2.new(0.5, 1)
    chatPill.Position = UDim2.new(0.5, 0, 1, -18)
    chatPill.Size = UDim2.new(1, -36, 0, 50)
    chatPill.BackgroundColor3 = FIELD
    chatPill.BackgroundTransparency = 0.25
    chatPill.ZIndex = 4
    chatPill.Parent = profileView
    Util.corner(chatPill, 16)
    Util.stroke(chatPill, WHITE, 1, 0.9)

    local pillIcon = Instance.new("ImageLabel")
    pillIcon.Size = UDim2.fromOffset(18, 18)
    pillIcon.Position = UDim2.new(0, 16, 0.5, 0)
    pillIcon.AnchorPoint = Vector2.new(0, 0.5)
    pillIcon.BackgroundTransparency = 1
    pillIcon.ZIndex = 5
    pillIcon.Parent = chatPill
    Icons.apply(pillIcon, "message-circle", SUB)

    local pillText = Instance.new("TextLabel")
    pillText.Text = "Chat..."
    pillText.Font = BODY_BOLD
    pillText.TextSize = 15
    pillText.TextColor3 = SUB
    pillText.TextXAlignment = Enum.TextXAlignment.Left
    pillText.TextTruncate = Enum.TextTruncate.AtEnd
    pillText.BackgroundTransparency = 1
    pillText.Position = UDim2.fromOffset(44, 0)
    pillText.Size = UDim2.new(1, -76, 1, 0)
    pillText.ZIndex = 5
    pillText.Parent = chatPill

    -- unread badge (messages that arrive while the chat view is closed)
    local unread = 0
    local badge = Instance.new("TextLabel")
    badge.Text = ""
    badge.Font = BODY_BOLD
    badge.TextSize = 11
    badge.TextColor3 = WHITE
    badge.BackgroundColor3 = Theme.red
    badge.AnchorPoint = Vector2.new(1, 0.5)
    badge.Position = UDim2.new(1, -12, 0.5, 0)
    badge.Size = UDim2.fromOffset(22, 22)
    badge.Visible = false
    badge.ZIndex = 5
    badge.Parent = chatPill
    Util.corner(badge, 11)

    local badgeScale = Instance.new("UIScale")
    badgeScale.Parent = badge

    local function bumpUnread()
        unread += 1
        badge.Text = unread > 9 and "9+" or tostring(unread)
        badge.Visible = true
        badgeScale.Scale = 1.35
        Util.tween(badgeScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
    end
    local function clearUnread()
        unread = 0
        badge.Visible = false
    end

    -- -----------------------------------------------------------------------
    -- Chat view (swaps over the profile card)
    -- -----------------------------------------------------------------------
    local chatView = Instance.new("Frame")
    chatView.Size = UDim2.fromScale(1, 1)
    chatView.BackgroundTransparency = 1
    chatView.Visible = false
    chatView.ZIndex = 3
    chatView.Parent = profileCard

    local chatTitle = Instance.new("TextLabel")
    chatTitle.Text = "Chat"
    chatTitle.Font = TITLE_FONT
    chatTitle.TextSize = 19
    chatTitle.TextColor3 = WHITE
    chatTitle.TextXAlignment = Enum.TextXAlignment.Left
    chatTitle.BackgroundTransparency = 1
    chatTitle.Position = UDim2.fromOffset(20, 18)
    chatTitle.Size = UDim2.fromOffset(80, 22)
    chatTitle.ZIndex = 4
    chatTitle.Parent = chatView

    local chatClose = Instance.new("TextButton")
    chatClose.Text = ""
    chatClose.AutoButtonColor = false
    chatClose.Size = UDim2.fromOffset(28, 28)
    chatClose.AnchorPoint = Vector2.new(1, 0)
    chatClose.Position = UDim2.new(1, -14, 0, 15)
    chatClose.BackgroundColor3 = FIELD
    chatClose.BackgroundTransparency = 0.3
    chatClose.ZIndex = 4
    chatClose.Parent = chatView
    Util.corner(chatClose, 9)
    local chatCloseGlyph = Instance.new("ImageLabel")
    chatCloseGlyph.Size = UDim2.fromOffset(13, 13)
    chatCloseGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    chatCloseGlyph.Position = UDim2.fromScale(0.5, 0.5)
    chatCloseGlyph.BackgroundTransparency = 1
    chatCloseGlyph.ZIndex = 5
    chatCloseGlyph.Parent = chatClose
    Icons.apply(chatCloseGlyph, "x", SUB)

    -- Channel tabs: Server | Universal
    local activeTab = "server"
    local tabs = {}
    local function makeTab(x, w, key, label)
        local t = Instance.new("TextButton")
        t.Text = label
        t.AutoButtonColor = false
        t.Font = BODY_BOLD
        t.TextSize = 12
        t.TextColor3 = SUB
        t.Position = UDim2.fromOffset(x, 48)
        t.Size = UDim2.fromOffset(w, 26)
        t.BackgroundColor3 = FIELD
        t.BackgroundTransparency = 1
        t.ZIndex = 4
        t.Parent = chatView
        Util.corner(t, 13)
        tabs[key] = t
        return t
    end
    makeTab(20, 70, "server", "Server")
    makeTab(96, 96, "universal", "Universal")

    -- Live dot on the Universal tab: green when the Discord bridge answered,
    -- gray until the first successful poll / after a failure.
    local liveDot = Instance.new("Frame")
    liveDot.Size = UDim2.fromOffset(6, 6)
    liveDot.AnchorPoint = Vector2.new(1, 0.5)
    liveDot.Position = UDim2.new(1, -8, 0.5, 0)
    liveDot.BackgroundColor3 = Color3.fromRGB(90, 90, 96)
    liveDot.BorderSizePixel = 0
    liveDot.ZIndex = 5
    liveDot.Parent = tabs.universal
    Util.corner(liveDot, 3)
    local function setUniversalLive(on)
        Util.tween(liveDot, { BackgroundColor3 = on and GREEN or Color3.fromRGB(120, 90, 90) }, 0.2)
    end

    local function setTab(key)
        activeTab = key
        for k, t in pairs(tabs) do
            local on = (k == key)
            t.TextColor3 = on and WHITE or SUB
            t.BackgroundTransparency = on and 0.25 or 1
        end
    end

    local chatScroll = Instance.new("ScrollingFrame")
    chatScroll.Position = UDim2.fromOffset(12, 84)
    chatScroll.Size = UDim2.new(1, -24, 1, -152)
    chatScroll.BackgroundTransparency = 1
    chatScroll.BorderSizePixel = 0
    chatScroll.ScrollBarThickness = 0
    chatScroll.ScrollBarImageTransparency = 1
    chatScroll.CanvasSize = UDim2.new()
    chatScroll.ZIndex = 4
    chatScroll.Parent = chatView
    local chatLayout = Instance.new("UIListLayout")
    chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
    chatLayout.Padding = UDim.new(0, 10)
    chatLayout.Parent = chatScroll

    -- top fade so messages dissolve under the channel tabs as they scroll up
    local chatFade = Instance.new("Frame")
    chatFade.Position = UDim2.fromOffset(12, 82)
    chatFade.Size = UDim2.new(1, -24, 0, 22)
    chatFade.BackgroundColor3 = CARD
    chatFade.BorderSizePixel = 0
    chatFade.Active = false
    chatFade.ZIndex = 6
    chatFade.Parent = chatView
    local chatFadeGrad = Instance.new("UIGradient")
    chatFadeGrad.Rotation = 90
    chatFadeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    chatFadeGrad.Parent = chatFade
    Util.autoCanvas(chatScroll, "Y")

    local chatEmpty = Instance.new("TextLabel")
    chatEmpty.Text = "Messages show up here."
    chatEmpty.Font = Theme.fonts.caption
    chatEmpty.TextSize = 13
    chatEmpty.TextColor3 = SUB
    chatEmpty.TextWrapped = true
    chatEmpty.BackgroundTransparency = 1
    chatEmpty.AnchorPoint = Vector2.new(0.5, 0.5)
    chatEmpty.Position = UDim2.fromScale(0.5, 0.45)
    chatEmpty.Size = UDim2.new(1, -60, 0, 40)
    chatEmpty.ZIndex = 4
    chatEmpty.Parent = chatView

    local chatInputHolder = Instance.new("Frame")
    chatInputHolder.AnchorPoint = Vector2.new(0.5, 1)
    chatInputHolder.Position = UDim2.new(0.5, 0, 1, -14)
    chatInputHolder.Size = UDim2.new(1, -28, 0, 46)
    chatInputHolder.BackgroundColor3 = FIELD
    chatInputHolder.BackgroundTransparency = 0.25
    chatInputHolder.ZIndex = 4
    chatInputHolder.Parent = chatView
    Util.corner(chatInputHolder, 14)
    Util.stroke(chatInputHolder, WHITE, 1, 0.9)

    local chatBox = Instance.new("TextBox")
    chatBox.PlaceholderText = "Message..."
    chatBox.PlaceholderColor3 = SUB
    chatBox.Text = ""
    chatBox.ClearTextOnFocus = false
    chatBox.Font = Theme.fonts.body
    chatBox.TextSize = 14
    chatBox.TextColor3 = WHITE
    chatBox.TextXAlignment = Enum.TextXAlignment.Left
    chatBox.BackgroundTransparency = 1
    chatBox.Position = UDim2.fromOffset(16, 0)
    chatBox.Size = UDim2.new(1, -58, 1, 0)
    chatBox.ZIndex = 5
    chatBox.Parent = chatInputHolder

    -- Send button (tap to send, same as pressing enter)
    local sendBtn = Instance.new("TextButton")
    sendBtn.Text = ""
    sendBtn.AutoButtonColor = false
    sendBtn.Size = UDim2.fromOffset(32, 32)
    sendBtn.AnchorPoint = Vector2.new(1, 0.5)
    sendBtn.Position = UDim2.new(1, -7, 0.5, 0)
    sendBtn.BackgroundColor3 = ACCENT
    sendBtn.BackgroundTransparency = 0.5
    sendBtn.ZIndex = 6
    sendBtn.Parent = chatInputHolder
    Util.corner(sendBtn, 10)
    local sendGlyph = Instance.new("ImageLabel")
    sendGlyph.Size = UDim2.fromOffset(16, 16)
    sendGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    sendGlyph.Position = UDim2.fromScale(0.5, 0.5)
    sendGlyph.BackgroundTransparency = 1
    sendGlyph.ZIndex = 7
    sendGlyph.Parent = sendBtn
    Icons.apply(sendGlyph, "chevron-right", WHITE)

    -- dim the send button until there's something to send
    local function updateSendState()
        local has = chatBox.Text:gsub("%s", "") ~= ""
        Util.tween(sendBtn, { BackgroundTransparency = has and 0.1 or 0.65 }, 0.12)
        sendGlyph.ImageTransparency = has and 0 or 0.45
    end
    chatBox:GetPropertyChangedSignal("Text"):Connect(updateSendState)
    updateSendState()

    chatPill.MouseButton1Click:Connect(function()
        profileView.Visible = false
        chatView.Visible = true
        chatView.Position = UDim2.fromOffset(0, 22)
        Util.tween(chatView, { Position = UDim2.fromOffset(0, 0) }, 0.24, Enum.EasingStyle.Quint)
        clearUnread()
    end)
    chatClose.MouseButton1Click:Connect(function()
        chatView.Visible = false
        profileView.Visible = true
        profileView.Position = UDim2.fromOffset(0, 22)
        Util.tween(profileView, { Position = UDim2.fromOffset(0, 0) }, 0.24, Enum.EasingStyle.Quint)
    end)

    -- Message rows, one store per tab -------------------------------------
    local msgOrder = 0
    local rowsByTab = { server = {}, universal = {} }

    local function refilterRows()
        for tabKey, rows in pairs(rowsByTab) do
            local show = (tabKey == activeTab)
            for _, r in ipairs(rows) do r.Visible = show end
        end
        local any = #rowsByTab[activeTab] > 0
        chatEmpty.Visible = not any
        task.defer(function()
            pcall(function()
                chatScroll.CanvasPosition = Vector2.new(0, math.max(0, chatLayout.AbsoluteContentSize.Y - chatScroll.AbsoluteWindowSize.Y + 8))
            end)
        end)
    end

    -- addMessage: avatarSpec = {userId=n} | {url=s, key=s} | {initial=s}
    local function addMessage(tabKey, name, text, nameColor, avatarSpec)
        if not alive then return end
        msgOrder += 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundTransparency = 1
        row.LayoutOrder = msgOrder
        row.Visible = (tabKey == activeTab)
        row.ZIndex = 4
        row.Parent = chatScroll

        local av = Instance.new("ImageLabel")
        av.Size = UDim2.fromOffset(30, 30)
        av.BackgroundColor3 = FIELD
        av.ZIndex = 4
        av.Parent = row
        Util.corner(av, 15)
        if avatarSpec.userId then
            av.Image = headshot(avatarSpec.userId, 48)
        elseif avatarSpec.url then
            local ini = Instance.new("TextLabel")
            ini.Text = (name:sub(1, 1) or "?"):upper()
            ini.Font = BODY_BOLD
            ini.TextSize = 13
            ini.TextColor3 = WHITE
            ini.BackgroundTransparency = 1
            ini.Size = UDim2.fromScale(1, 1)
            ini.ZIndex = 5
            ini.Parent = av
            task.spawn(function()
                local id = Util.remoteImage(avatarSpec.url, avatarSpec.key)
                if id and av.Parent then
                    av.Image = id
                    ini:Destroy()
                end
            end)
        else
            local ini = Instance.new("TextLabel")
            ini.Text = (avatarSpec.initial or "?"):upper()
            ini.Font = BODY_BOLD
            ini.TextSize = 13
            ini.TextColor3 = WHITE
            ini.BackgroundTransparency = 1
            ini.Size = UDim2.fromScale(1, 1)
            ini.ZIndex = 5
            ini.Parent = av
        end

        local nm = Instance.new("TextLabel")
        nm.Text = name
        nm.Font = BODY_BOLD
        nm.TextSize = 13
        nm.TextColor3 = nameColor or ACCENT
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.TextTruncate = Enum.TextTruncate.AtEnd
        nm.BackgroundTransparency = 1
        nm.Position = UDim2.fromOffset(40, 0)
        nm.Size = UDim2.new(1, -102, 0, 15)
        nm.ZIndex = 4
        nm.Parent = row

        local ts = Instance.new("TextLabel")
        ts.Text = Util.date("%I:%M %p"):gsub("^0", "")
        ts.Font = Theme.fonts.caption
        ts.TextSize = 10
        ts.TextColor3 = SUB
        ts.TextXAlignment = Enum.TextXAlignment.Right
        ts.BackgroundTransparency = 1
        ts.AnchorPoint = Vector2.new(1, 0)
        ts.Position = UDim2.new(1, -2, 0, 2)
        ts.Size = UDim2.fromOffset(56, 12)
        ts.ZIndex = 4
        ts.Parent = row

        local tx = Instance.new("TextLabel")
        tx.Text = text
        tx.Font = Theme.fonts.body
        tx.TextSize = 13
        tx.TextColor3 = Color3.fromRGB(222, 222, 228)
        tx.TextXAlignment = Enum.TextXAlignment.Left
        tx.TextYAlignment = Enum.TextYAlignment.Top
        tx.TextWrapped = true
        tx.BackgroundTransparency = 1
        tx.AutomaticSize = Enum.AutomaticSize.Y
        tx.Position = UDim2.fromOffset(40, 17)
        tx.Size = UDim2.new(1, -44, 0, 15)
        tx.ZIndex = 4
        tx.Parent = row

        -- new rows fade in
        av.ImageTransparency = 1
        nm.TextTransparency = 1
        tx.TextTransparency = 1
        Util.tween(av, { ImageTransparency = 0 }, 0.25)
        Util.tween(nm, { TextTransparency = 0 }, 0.25)
        Util.tween(tx, { TextTransparency = 0 }, 0.25)

        local rows = rowsByTab[tabKey]
        rows[#rows + 1] = row
        if #rows > 60 then
            local old = table.remove(rows, 1)
            old:Destroy()
        end

        -- keep the closed pill informative
        pillText.Text = (name == "You" and "You: " or name .. ": ") .. text
        pillText.TextColor3 = Color3.fromRGB(200, 200, 206)
        if not chatView.Visible and name ~= "You" then
            bumpUnread()
        end

        if tabKey == activeTab then
            chatEmpty.Visible = false
            task.defer(function()
                pcall(function()
                    chatScroll.CanvasPosition = Vector2.new(0, math.max(0, chatLayout.AbsoluteContentSize.Y - chatScroll.AbsoluteWindowSize.Y + 8))
                end)
            end)
        end
    end

    for key, t in pairs(tabs) do
        t.MouseButton1Click:Connect(function()
            setTab(key)
            refilterRows()
        end)
    end
    setTab("server")

    -- Server chat wiring: pick by what the game actually exposes ------------
    local sendServer
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
            local you = src.UserId == lp.UserId
            addMessage("server", you and "You" or src.Name, msg.Text, ACCENT, { userId = src.UserId })
        end)
        sendServer = function(text)
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
                addMessage("server", pl == lp and "You" or speaker, data.Message or "",
                    ACCENT, pl and { userId = pl.UserId } or { initial = speaker:sub(1, 1) })
            end)
        else
            local function hook(pl)
                conns[#conns + 1] = pl.Chatted:Connect(function(msg)
                    addMessage("server", pl == lp and "You" or pl.Name, msg, ACCENT, { userId = pl.UserId })
                end)
            end
            for _, pl in ipairs(Players:GetPlayers()) do hook(pl) end
            conns[#conns + 1] = Players.PlayerAdded:Connect(hook)
        end
        sendServer = function(text)
            pcall(function()
                local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                local say = ev and ev:FindFirstChild("SayMessageRequest")
                if say then say:FireServer(text, "All") end
            end)
        end
    end

    -- Universal chat: poll the relay --------------------------------------
    local lastUniversalId = nil
    -- Persistent local log so messages stay in SYNC even after they're deleted
    -- in Discord or the relay restarts (relay re-seeds from live history only).
    local UNI_LOG = "SYNC/universal_log.json"
    local seenUni = {}
    local function loadUniLog()
        local ok, data = pcall(function()
            if typeof(isfile) == "function" and isfile(UNI_LOG) then
                return HttpService:JSONDecode(readfile(UNI_LOG))
            end
        end)
        return (ok and type(data) == "table") and data or {}
    end
    local uniLog = loadUniLog()
    local uniSaveVer = 0
    local function persistUniLog()
        uniSaveVer += 1
        local v = uniSaveVer
        task.delay(0.6, function()
            if v ~= uniSaveVer or typeof(writefile) ~= "function" then return end
            pcall(function()
                while #uniLog > 150 do table.remove(uniLog, 1) end
                if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder("SYNC") then
                    makefolder("SYNC")
                end
                writefile(UNI_LOG, HttpService:JSONEncode(uniLog))
            end)
        end)
    end

    -- render a list of relay-format messages; dedupes by id, so a message shown
    -- from the local log won't double up when the relay returns it again.
    -- persist=true also records new messages into the local log.
    local function renderUniversal(list, persist, force)
        for _, m in ipairs(list) do
            if m.id then lastUniversalId = m.id end
            if force or not (m.id and seenUni[m.id]) then
                if m.id then seenUni[m.id] = true end
                local name = m.author or "?"
                local isRoblox = m.roblox == true
                if isRoblox then name = name:gsub("%s*%(Roblox%)%s*$", "") end
                local isYou = isRoblox and name == lp.Name
                local text = m.content or ""
                if m.images and #m.images > 0 then
                    text = (text ~= "" and text .. " " or "") .. "[image]"
                end
                if text ~= "" then
                    local color = isYou and ACCENT or (isRoblox and ACCENT or BLURPLE)
                    local avatarSpec
                    if isRoblox and isYou then
                        avatarSpec = { userId = lp.UserId }
                    elseif m.avatar then
                        avatarSpec = { url = m.avatar, key = "dcav_" .. tostring(m.authorId or name) .. ".png" }
                    else
                        avatarSpec = { initial = name:sub(1, 1) }
                    end
                    addMessage("universal", isYou and "You" or name, text, color, avatarSpec)
                    if persist then
                        uniLog[#uniLog + 1] = { id = m.id, author = m.author, content = m.content,
                            roblox = m.roblox, avatar = m.avatar, authorId = m.authorId, images = m.images }
                        persistUniLog()
                    end
                end
            end
        end
    end

    local function fetchUniversal()
        local url = RELAY_URL .. "/messages?channel=" .. UNIVERSAL_ID .. "&key=" .. API_KEY
        if lastUniversalId then url = url .. "&after=" .. lastUniversalId end
        local body = Util.httpGetH(url, { ["X-API-Key"] = API_KEY })
        if not body then setUniversalLive(false); return nil end
        local ok, list = pcall(function() return HttpService:JSONDecode(body) end)
        if not ok or type(list) ~= "table" then setUniversalLive(false); return nil end
        setUniversalLive(true)
        return list
    end

    task.spawn(function()
        -- 1) paint the saved local log first (survives Discord deletes / relay
        -- restarts). Mark the whole log seen so the relay can't re-render older
        -- entries, but force-render the visible tail.
        for _, m in ipairs(uniLog) do if m.id then seenUni[m.id] = true end end
        if #uniLog > 0 and alive then
            local tail = {}
            for i = math.max(1, #uniLog - 24), #uniLog do tail[#tail + 1] = uniLog[i] end
            renderUniversal(tail, false, true)
        end
        -- 2) first relay fetch: dedupe against the log, persist anything new
        local first = fetchUniversal()
        if first and alive then renderUniversal(first, true) end
        while alive and gui.Parent do
            -- 2.5s when the chat is open, 6s in the background (unread badge)
            local ticks = chatView.Visible and 5 or 12
            for _ = 1, ticks do
                if not alive then return end
                task.wait(0.5)
            end
            local list = fetchUniversal()
            if list and alive then renderUniversal(list, true) end
        end
    end)

    local function sendUniversal(text)
        if not Util.hasRequest() then
            addMessage("universal", "SYNC", "This executor can't POST (no request API) — sending is disabled, reading still works.", SUB, { initial = "!" })
            return
        end
        task.spawn(function()
            local ok = Util.httpPost(RELAY_URL .. "/send?key=" .. API_KEY, { ["X-API-Key"] = API_KEY },
                HttpService:JSONEncode({
                    channel = UNIVERSAL_ID,
                    robloxUserId = lp.UserId,
                    username = lp.Name,
                    text = text,
                }))
            if not ok and alive then
                addMessage("universal", "SYNC", "Message didn't send (relay rejected it).", SUB, { initial = "!" })
            end
        end)
    end

    local function submitChat()
        local text = chatBox.Text
        if text:gsub("%s", "") == "" then return end
        chatBox.Text = ""
        if activeTab == "universal" then sendUniversal(text) else sendServer(text) end
    end

    chatBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then submitChat() end
    end)

    sendBtn.MouseEnter:Connect(function()
        Util.tween(sendBtn, { BackgroundTransparency = 0 }, 0.12)
    end)
    sendBtn.MouseLeave:Connect(function()
        Util.tween(sendBtn, { BackgroundTransparency = 0.5 }, 0.12)
    end)
    sendBtn.MouseButton1Click:Connect(submitChat)

    -- -----------------------------------------------------------------------
    -- Friend Activity card (col 2) — orca look: full-bleed thumbnails with
    -- overlapping friend chips that expand green on hover
    -- -----------------------------------------------------------------------
    local faCard = makeCard(PAD + COL1 + GAPX, contentY, COL2, contentH)
    local faTitle = cardTitle(faCard, "Friend Activity")

    -- Manual refresh button (top-right of the card): breaks the poll wait
    local faRefreshRequested = false
    local faRefreshBtn = Instance.new("TextButton")
    faRefreshBtn.Text = ""
    faRefreshBtn.AutoButtonColor = false
    faRefreshBtn.Size = UDim2.fromOffset(26, 26)
    faRefreshBtn.AnchorPoint = Vector2.new(1, 0)
    faRefreshBtn.Position = UDim2.new(1, -16, 0, 16)
    faRefreshBtn.BackgroundColor3 = FIELD
    faRefreshBtn.BackgroundTransparency = 0.3
    faRefreshBtn.ZIndex = 5
    faRefreshBtn.Parent = faCard
    Util.corner(faRefreshBtn, 9)
    local faRefreshGlyph = Instance.new("ImageLabel")
    faRefreshGlyph.Size = UDim2.fromOffset(14, 14)
    faRefreshGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    faRefreshGlyph.Position = UDim2.fromScale(0.5, 0.5)
    faRefreshGlyph.BackgroundTransparency = 1
    faRefreshGlyph.ZIndex = 6
    faRefreshGlyph.Parent = faRefreshBtn
    Icons.apply(faRefreshGlyph, "orbit", SUB)
    faRefreshBtn.MouseEnter:Connect(function()
        Util.tween(faRefreshBtn, { BackgroundTransparency = 0 }, 0.12)
        faRefreshGlyph.ImageColor3 = WHITE
    end)
    faRefreshBtn.MouseLeave:Connect(function()
        Util.tween(faRefreshBtn, { BackgroundTransparency = 0.3 }, 0.12)
        faRefreshGlyph.ImageColor3 = SUB
    end)
    faRefreshBtn.MouseButton1Click:Connect(function()
        faRefreshRequested = true
        Util.tween(faRefreshGlyph, { Rotation = faRefreshGlyph.Rotation + 360 }, 0.5)
    end)

    local faEmpty = Instance.new("TextLabel")
    faEmpty.Text = "Your friends will appear here when they're in-game."
    faEmpty.Font = Theme.fonts.caption
    faEmpty.TextSize = 14
    faEmpty.TextColor3 = SUB
    faEmpty.TextWrapped = true
    faEmpty.BackgroundTransparency = 1
    faEmpty.AnchorPoint = Vector2.new(0.5, 0.5)
    faEmpty.Position = UDim2.fromScale(0.5, 0.52)
    faEmpty.Size = UDim2.new(1, -60, 0, 40)
    faEmpty.ZIndex = 4
    faEmpty.Parent = faCard

    local faEmptyIcon = Instance.new("ImageLabel")
    faEmptyIcon.Size = UDim2.fromOffset(30, 30)
    faEmptyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    faEmptyIcon.Position = UDim2.fromScale(0.5, 0.4)
    faEmptyIcon.BackgroundTransparency = 1
    faEmptyIcon.ImageTransparency = 0.4
    faEmptyIcon.ZIndex = 4
    faEmptyIcon.Parent = faCard
    Icons.apply(faEmptyIcon, "gamepad-2", SUB)

    local faScroll = Instance.new("ScrollingFrame")
    faScroll.Position = UDim2.fromOffset(20, 52)
    faScroll.Size = UDim2.new(1, -34, 1, -66)
    faScroll.BackgroundTransparency = 1
    faScroll.BorderSizePixel = 0
    faScroll.ScrollBarThickness = 3
    faScroll.ScrollBarImageColor3 = SUB
    faScroll.ScrollBarImageTransparency = 0.6
    faScroll.CanvasSize = UDim2.new()
    faScroll.ZIndex = 4
    faScroll.Parent = faCard

    -- bottom fade so game cards dissolve into the card edge as they scroll off
    local faFade = Instance.new("Frame")
    faFade.AnchorPoint = Vector2.new(0.5, 1)
    faFade.Position = UDim2.new(0.5, 0, 1, -6)
    faFade.Size = UDim2.new(1, -8, 0, 34)
    faFade.BackgroundColor3 = CARD
    faFade.BorderSizePixel = 0
    faFade.Active = false
    faFade.ZIndex = 6
    faFade.Parent = faCard
    local faFadeGrad = Instance.new("UIGradient")
    faFadeGrad.Rotation = 90
    faFadeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.1),
    })
    faFadeGrad.Parent = faFade

    local THUMB_W = COL2 - 40
    local THUMB_H = math.floor(THUMB_W * 9 / 16 + 0.5)
    local ENTRY_H = THUMB_H + 24 + 22   -- thumbnail + chip overhang + gap

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
        if not ok or type(friends) ~= "table" then return nil, nil end
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
        return order, friends
    end

    -- orca FriendItem: 44px avatar circle; hover -> green pill with play icon
    local function buildFriendChip(parent, fr, index)
        local chip = Instance.new("TextButton")
        chip.Text = ""
        chip.AutoButtonColor = false
        chip.Size = UDim2.fromOffset(44, 44)
        chip.Position = UDim2.fromOffset((index - 1) * 52, 0)
        chip.BackgroundColor3 = CARD
        chip.ClipsDescendants = true
        chip.ZIndex = 6
        chip.Parent = parent
        Util.corner(chip, 22)
        local chipStroke = Util.stroke(chip, WHITE, 1, 0.85)
        local glow = Util.shadow(chip, { blur = 26, spread = 0, transparency = 1, offset = UDim2.fromOffset(0, 4), color = GREEN })

        local av = Instance.new("ImageLabel")
        av.Image = headshot(fr.VisitorId, 100)
        av.Size = UDim2.fromOffset(44, 44)
        av.BackgroundTransparency = 1
        av.ZIndex = 7
        av.Parent = chip
        Util.corner(av, 22)

        local play = Instance.new("ImageLabel")
        play.Size = UDim2.fromOffset(20, 20)
        play.Position = UDim2.fromOffset(52, 12)
        play.BackgroundTransparency = 1
        play.ImageTransparency = 1
        play.ZIndex = 7
        play.Parent = chip
        Icons.apply(play, "chevron-right", WHITE)

        chip.MouseEnter:Connect(function()
            Util.tween(chip, { Size = UDim2.fromOffset(82, 44), BackgroundColor3 = GREEN }, 0.16)
            Util.tween(play, { ImageTransparency = 0 }, 0.16)
            Util.tween(chipStroke, { Transparency = 1 }, 0.16)
            if glow then Util.tween(glow, { Transparency = 0.45 }, 0.16) end
        end)
        chip.MouseLeave:Connect(function()
            Util.tween(chip, { Size = UDim2.fromOffset(44, 44), BackgroundColor3 = CARD }, 0.16)
            Util.tween(play, { ImageTransparency = 1 }, 0.16)
            Util.tween(chipStroke, { Transparency = 0.85 }, 0.16)
            if glow then Util.tween(glow, { Transparency = 1 }, 0.16) end
        end)
        chip.MouseButton1Click:Connect(function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(fr.PlaceId, fr.GameId, lp)
            end)
        end)

        -- pop in, staggered along the row
        local chipScale = Instance.new("UIScale")
        chipScale.Scale = 0
        chipScale.Parent = chip
        task.delay((index - 1) * 0.05, function()
            if chip.Parent then
                Util.tween(chipScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
            end
        end)
    end

    local function renderGames(games)
        if not alive then return end
        for _, child in ipairs(faScroll:GetChildren()) do child:Destroy() end
        faEmpty.Visible = #games == 0
        faEmptyIcon.Visible = #games == 0
        faScroll.CanvasSize = UDim2.fromOffset(0, #games * ENTRY_H + 8)

        -- title count: total friends across the games shown
        local playing = 0
        for _, g in ipairs(games) do playing += #g.friends end
        faTitle.Text = playing > 0 and ("Friend Activity · " .. playing) or "Friend Activity"

        for gi, g in ipairs(games) do
            local y = (gi - 1) * ENTRY_H

            local thumb = Instance.new("ImageButton")
            thumb.AutoButtonColor = false
            thumb.Size = UDim2.fromOffset(THUMB_W, THUMB_H)
            thumb.Position = UDim2.fromOffset(0, y)
            thumb.BackgroundColor3 = FIELD
            thumb.ScaleType = Enum.ScaleType.Crop
            thumb.ZIndex = 5
            thumb.Parent = faScroll
            Util.corner(thumb, 12)
            Util.stroke(thumb, WHITE, 1, 0.86)
            -- click the game art (behind the friend chips) to copy its link
            local gpid = g.placeId
            thumb.MouseButton1Click:Connect(function()
                local ok = pcall(function()
                    setclipboard(("https://www.roblox.com/games/%d"):format(gpid))
                end)
                if ok then
                    faTitle.Text = "Game link copied"
                    task.delay(1.2, function()
                        if faTitle.Parent then faTitle.Text = "Friend Activity" end
                    end)
                end
            end)

            -- Fallback name shows until (unless) the thumbnail loads
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text = "..."
            nameLabel.Font = BODY_BOLD
            nameLabel.TextSize = 14
            nameLabel.TextColor3 = WHITE
            nameLabel.TextWrapped = true
            nameLabel.BackgroundTransparency = 1
            nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            nameLabel.Position = UDim2.fromScale(0.5, 0.45)
            nameLabel.Size = UDim2.new(1, -24, 0, 40)
            nameLabel.ZIndex = 6
            nameLabel.Parent = thumb

            -- game name pill fades in when hovering the art
            local namePill = Instance.new("TextLabel")
            namePill.Text = ""
            namePill.Font = BODY_BOLD
            namePill.TextSize = 12
            namePill.TextColor3 = WHITE
            namePill.TextTransparency = 1
            namePill.TextTruncate = Enum.TextTruncate.AtEnd
            namePill.BackgroundColor3 = Color3.new(0, 0, 0)
            namePill.BackgroundTransparency = 1
            namePill.Position = UDim2.fromOffset(10, 10)
            namePill.Size = UDim2.new(1, -20, 0, 24)
            namePill.ZIndex = 7
            namePill.Parent = thumb
            Util.corner(namePill, 8)
            thumb.MouseEnter:Connect(function()
                if namePill.Text ~= "" and not nameLabel.Visible then
                    Util.tween(namePill, { TextTransparency = 0, BackgroundTransparency = 0.35 }, 0.15)
                end
            end)
            thumb.MouseLeave:Connect(function()
                Util.tween(namePill, { TextTransparency = 1, BackgroundTransparency = 1 }, 0.15)
            end)

            local chipRow = Instance.new("Frame")
            chipRow.Size = UDim2.new(1, 0, 0, 44)
            chipRow.Position = UDim2.fromOffset(10, y + THUMB_H - 22)
            chipRow.BackgroundTransparency = 1
            chipRow.ZIndex = 6
            chipRow.Parent = faScroll

            for fi, fr in ipairs(g.friends) do
                buildFriendChip(chipRow, fr, fi)
            end

            task.spawn(function()
                local nm = gameNameFor(g.placeId)
                if nameLabel.Parent then nameLabel.Text = nm end
                if namePill.Parent then namePill.Text = " " .. nm .. " " end
                -- 768x432 game thumbnail: universe id -> thumbnails API -> CDN png
                -- (the old www.roblox.com/asset-thumbnail endpoint now returns HTML)
                local uid = universeIdFor(g.placeId)
                local cdn
                if uid then
                    local body = Util.httpGet("https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds="
                        .. uid .. "&size=768x432&format=Png&countPerUniverse=1")
                    if body then
                        pcall(function()
                            local d = HttpService:JSONDecode(body)
                            cdn = d.data[1].thumbnails[1].imageUrl
                        end)
                    end
                end
                local id = cdn and Util.remoteImage(cdn, "gthumb2_" .. g.placeId .. ".png")
                if id and thumb.Parent then
                    thumb.ImageTransparency = 1
                    thumb.Image = id
                    nameLabel.Visible = false
                    Util.tween(thumb, { ImageTransparency = 0 }, 0.35)
                elseif uid and thumb.Parent then
                    thumb.ImageTransparency = 1
                    thumb.Image = ("rbxthumb://type=GameIcon&id=%d&w=150&h=150"):format(uid)
                    Util.tween(thumb, { ImageTransparency = 0.35 }, 0.35)
                end
            end)
        end
    end

    -- -----------------------------------------------------------------------
    -- Server card + clock pill (col 3)
    -- -----------------------------------------------------------------------
    local col3X = PAD + COL1 + GAPX + COL2 + GAPX
    local serverCard = makeCard(col3X, contentY, COL3, 190)
    local serverTitle = cardTitle(serverCard, "Server")

    -- small copy-link button by the title: copies a deep link to this server
    local srvCopy = Instance.new("TextButton")
    srvCopy.Text = ""
    srvCopy.AutoButtonColor = false
    srvCopy.Size = UDim2.fromOffset(26, 26)
    srvCopy.AnchorPoint = Vector2.new(1, 0)
    srvCopy.Position = UDim2.new(1, -16, 0, 16)
    srvCopy.BackgroundColor3 = FIELD
    srvCopy.BackgroundTransparency = 0.35
    srvCopy.ZIndex = 5
    srvCopy.Parent = serverCard
    Util.corner(srvCopy, 8)
    local srvCopyIc = Instance.new("ImageLabel")
    srvCopyIc.Size = UDim2.fromOffset(13, 13)
    srvCopyIc.AnchorPoint = Vector2.new(0.5, 0.5)
    srvCopyIc.Position = UDim2.fromScale(0.5, 0.5)
    srvCopyIc.BackgroundTransparency = 1
    srvCopyIc.ZIndex = 6
    srvCopyIc.Parent = srvCopy
    Icons.apply(srvCopyIc, "file-text", SUB)
    srvCopy.MouseEnter:Connect(function()
        Util.tween(srvCopy, { BackgroundTransparency = 0 }, 0.12); srvCopyIc.ImageColor3 = WHITE
    end)
    srvCopy.MouseLeave:Connect(function()
        Util.tween(srvCopy, { BackgroundTransparency = 0.35 }, 0.12); srvCopyIc.ImageColor3 = SUB
    end)
    srvCopy.MouseButton1Click:Connect(function()
        local link = ("https://www.roblox.com/games/start?placeId=%d&launchData=%s"):format(game.PlaceId, game.JobId)
        local ok = pcall(function() setclipboard(link) end)
        if ok then
            serverTitle.Text = "Link copied"
            task.delay(1.2, function() if serverTitle.Parent then serverTitle.Text = "Server" end end)
        end
    end)

    local serverRows = {}
    for i = 1, 3 do
        local r = Instance.new("TextLabel")
        r.RichText = true
        r.Text = ""
        r.Font = BODY_BOLD
        r.TextSize = 16
        r.TextColor3 = WHITE
        r.TextXAlignment = Enum.TextXAlignment.Left
        r.BackgroundTransparency = 1
        r.Position = UDim2.fromOffset(20, 24 + i * 34)
        r.Size = UDim2.new(1, -90, 0, 22)
        r.ZIndex = 4
        r.Parent = serverCard
        serverRows[i] = r
    end

    -- Hop (random server) + rejoin buttons, orca's shuffle/retry pair
    local function serverButton(y, iconName, tip, cb)
        local b = Instance.new("TextButton")
        b.Text = ""
        b.AutoButtonColor = false
        b.Size = UDim2.fromOffset(50, 50)
        b.AnchorPoint = Vector2.new(1, 0)
        b.Position = UDim2.new(1, -16, 0, y)
        b.BackgroundColor3 = FIELD
        b.BackgroundTransparency = 0.25
        b.ZIndex = 4
        b.Parent = serverCard
        Util.corner(b, 14)
        Util.stroke(b, WHITE, 1, 0.9)
        local g = Instance.new("ImageLabel")
        g.Size = UDim2.fromOffset(22, 22)
        g.AnchorPoint = Vector2.new(0.5, 0.5)
        g.Position = UDim2.fromScale(0.5, 0.5)
        g.BackgroundTransparency = 1
        g.ZIndex = 5
        g.Parent = b
        Icons.apply(g, iconName, SUB)

        -- tooltip: floats to the left of the button on hover
        local tipLabel = Instance.new("TextLabel")
        tipLabel.Text = "  " .. tip .. "  "
        tipLabel.Font = BODY_BOLD
        tipLabel.TextSize = 12
        tipLabel.TextColor3 = WHITE
        tipLabel.TextTransparency = 1
        tipLabel.BackgroundColor3 = Color3.fromRGB(10, 11, 13)
        tipLabel.BackgroundTransparency = 1
        tipLabel.AutomaticSize = Enum.AutomaticSize.X
        tipLabel.AnchorPoint = Vector2.new(1, 0.5)
        tipLabel.Position = UDim2.new(1, -60, 0, y + 25)
        tipLabel.Size = UDim2.fromOffset(0, 24)
        tipLabel.ZIndex = 8
        tipLabel.Parent = serverCard
        Util.corner(tipLabel, 7)
        local tipStroke = Util.stroke(tipLabel, WHITE, 1, 1)

        local bScale = Instance.new("UIScale")
        bScale.Parent = b
        b.MouseEnter:Connect(function()
            Util.tween(b, { BackgroundTransparency = 0 }, 0.12)
            Util.tween(bScale, { Scale = 1.06 }, 0.12)
            g.ImageColor3 = WHITE
            Util.tween(tipLabel, { TextTransparency = 0, BackgroundTransparency = 0.05 }, 0.14)
            Util.tween(tipStroke, { Transparency = 0.85 }, 0.14)
        end)
        b.MouseLeave:Connect(function()
            Util.tween(b, { BackgroundTransparency = 0.25 }, 0.12)
            Util.tween(bScale, { Scale = 1 }, 0.12)
            g.ImageColor3 = SUB
            Util.tween(tipLabel, { TextTransparency = 1, BackgroundTransparency = 1 }, 0.14)
            Util.tween(tipStroke, { Transparency = 1 }, 0.14)
        end)
        b.MouseButton1Down:Connect(function()
            Util.tween(bScale, { Scale = 0.92 }, 0.08)
        end)
        b.MouseButton1Up:Connect(function()
            Util.tween(bScale, { Scale = 1.06 }, 0.12)
        end)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    serverButton(58, "orbit", "Server hop", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
    end)
    serverButton(120, "power", "Rejoin", function()
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end)
    end)

    local clockCard = makeCard(col3X, contentY + 190 + GAPX, COL3, 62)
    local clockIcon = Instance.new("ImageLabel")
    clockIcon.Size = UDim2.fromOffset(20, 20)
    clockIcon.AnchorPoint = Vector2.new(0, 0.5)
    clockIcon.Position = UDim2.new(0, 20, 0.5, 0)
    clockIcon.BackgroundTransparency = 1
    clockIcon.ZIndex = 4
    clockIcon.Parent = clockCard
    Icons.apply(clockIcon, "clock", WHITE)

    local clockLabel = Instance.new("TextLabel")
    clockLabel.Font = TITLE_FONT
    clockLabel.TextSize = 19
    clockLabel.TextColor3 = WHITE
    clockLabel.TextXAlignment = Enum.TextXAlignment.Left
    clockLabel.BackgroundTransparency = 1
    clockLabel.Position = UDim2.fromOffset(52, 9)
    clockLabel.Size = UDim2.new(1, -60, 0, 24)
    clockLabel.ZIndex = 4
    clockLabel.Parent = clockCard

    local dateLabel = Instance.new("TextLabel")
    dateLabel.Font = Theme.fonts.caption
    dateLabel.TextSize = 11
    dateLabel.TextColor3 = SUB
    dateLabel.TextXAlignment = Enum.TextXAlignment.Left
    dateLabel.BackgroundTransparency = 1
    dateLabel.Position = UDim2.fromOffset(52, 35)
    dateLabel.Size = UDim2.new(1, -60, 0, 14)
    dateLabel.ZIndex = 4
    dateLabel.Parent = clockCard

    -- Friends card: online friends at a glance, green ring = in a game
    local friendsY = contentY + 190 + GAPX + 62 + GAPX
    local friendsCard = makeCard(col3X, friendsY, COL3, contentH - (friendsY - contentY))
    local friendsTitle = cardTitle(friendsCard, "Friends")
    friendsTitle.TextTruncate = Enum.TextTruncate.AtEnd -- long hover names show … not a hard crop

    local friendsGrid = Instance.new("Frame")
    friendsGrid.Position = UDim2.fromOffset(20, 50)
    friendsGrid.Size = UDim2.new(1, -40, 1, -64)
    friendsGrid.BackgroundTransparency = 1
    friendsGrid.ZIndex = 4
    friendsGrid.Parent = friendsCard
    local friendsLayout = Instance.new("UIGridLayout")
    friendsLayout.CellSize = UDim2.fromOffset(38, 38)
    friendsLayout.CellPadding = UDim2.fromOffset(10, 10)
    friendsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    friendsLayout.Parent = friendsGrid

    local friendsEmpty = Instance.new("TextLabel")
    friendsEmpty.Text = "No friends online right now."
    friendsEmpty.Font = Theme.fonts.caption
    friendsEmpty.TextSize = 13
    friendsEmpty.TextColor3 = SUB
    friendsEmpty.TextWrapped = true
    friendsEmpty.BackgroundTransparency = 1
    friendsEmpty.AnchorPoint = Vector2.new(0.5, 0.5)
    friendsEmpty.Position = UDim2.fromScale(0.5, 0.55)
    friendsEmpty.Size = UDim2.new(1, -40, 0, 36)
    friendsEmpty.ZIndex = 4
    friendsEmpty.Parent = friendsCard

    local function renderFriendsOnline(friends)
        if not alive then return end
        for _, ch in ipairs(friendsGrid:GetChildren()) do
            if ch:IsA("GuiObject") then ch:Destroy() end
        end
        local titleDefault = #friends > 0 and ("Friends · %d"):format(#friends) or "Friends"
        friendsTitle.Text = titleDefault
        friendsEmpty.Visible = #friends == 0
        for i, fr in ipairs(friends) do
            if i > 15 then break end
            -- last slot becomes a "+N more" chip when the list overflows
            if i == 15 and #friends > 15 then
                local more = Instance.new("TextLabel")
                more.Text = "+" .. (#friends - 14)
                more.Font = BODY_BOLD
                more.TextSize = 12
                more.TextColor3 = Color3.fromRGB(210, 210, 216)
                more.BackgroundColor3 = FIELD
                more.LayoutOrder = 15
                more.ZIndex = 5
                more.Parent = friendsGrid
                Util.corner(more, 19)
                Util.stroke(more, Color3.fromRGB(90, 90, 96), 2, 0.55)
                break
            end
            local av = Instance.new("ImageButton")
            av.Image = headshot(fr.VisitorId, 100)
            av.AutoButtonColor = false
            av.BackgroundColor3 = FIELD
            av.LayoutOrder = i
            av.ZIndex = 5
            av.Parent = friendsGrid
            Util.corner(av, 19)
            local inGame = fr.PlaceId and fr.GameId
            Util.stroke(av, inGame and GREEN or Color3.fromRGB(90, 90, 96), 2, inGame and 0.1 or 0.55)

            -- hover shows who it is; green = joinable, otherwise copy profile
            av.MouseEnter:Connect(function()
                -- short hint so the name + action fits the card (no crop)
                friendsTitle.Text = (fr.DisplayName or fr.UserName or "?")
                    .. (inGame and "  ·  join" or "  ·  copy")
            end)
            av.MouseLeave:Connect(function()
                friendsTitle.Text = titleDefault
            end)
            av.MouseButton1Click:Connect(function()
                if inGame then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(fr.PlaceId, fr.GameId, lp)
                    end)
                else
                    local ok = pcall(function()
                        setclipboard(("https://www.roblox.com/users/%d/profile"):format(fr.VisitorId))
                    end)
                    if ok then
                        friendsTitle.Text = "Profile link copied"
                        task.delay(1.2, function()
                            if friendsTitle.Parent then friendsTitle.Text = titleDefault end
                        end)
                    end
                end
            end)

            local avScale = Instance.new("UIScale")
            avScale.Scale = 0
            avScale.Parent = av
            task.delay((i - 1) * 0.04, function()
                if av.Parent then
                    Util.tween(avScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
                end
            end)
        end
    end

    -- Entrance: cards settle in one after another
    for i, cardFrame in ipairs({ profileCard, faCard, serverCard, clockCard, friendsCard }) do
        local cover = Instance.new("Frame")
        cover.Size = UDim2.fromScale(1, 1)
        cover.BackgroundColor3 = WIN
        cover.BorderSizePixel = 0
        cover.ZIndex = 10
        cover.Parent = cardFrame
        Util.corner(cover, 18)
        local cs = Instance.new("UIScale")
        cs.Scale = 0.95
        cs.Parent = cardFrame
        task.delay(0.05 + (i - 1) * 0.06, function()
            if not cover.Parent then return end
            Util.tween(cover, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(cs, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
            task.delay(0.35, function()
                if cover.Parent then cover:Destroy() end
            end)
        end)
    end

    -- -----------------------------------------------------------------------
    -- Live loops
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
            clockLabel.Text = Util.date("%I:%M %p"):gsub("^0", "")
            dateLabel.Text = Util.date("%a, %b %d")

            local white = "#FFFFFF"
            serverRows[1].Text = ('<font color="%s">%d / %d</font> <font color="%s">players</font>')
                :format(white, #Players:GetPlayers(), Players.MaxPlayers, SUB_HEX)
            local mins = math.floor(time() / 60)
            local elapsedStr
            if mins < 60 then
                elapsedStr = mins .. (mins == 1 and " minute" or " minutes")
            else
                local h, m = mins // 60, mins % 60
                elapsedStr = ("%dh %02dm"):format(h, m)
            end
            serverRows[2].Text = ('<font color="%s">%s</font> <font color="%s">elapsed</font>')
                :format(white, elapsedStr, SUB_HEX)
            local ms = ping()
            -- ping value color-coded: green under 80, amber under 150, red above
            local pingHex = white
            if ms then
                pingHex = ms < 80 and "#3ED194" or ms < 150 and "#FEBC2E" or "#FF5F57"
            end
            serverRows[3].Text = ('<font color="%s">%s</font> <font color="%s">ping</font>')
                :format(pingHex, ms and (ms .. " ms") or "--", SUB_HEX)
            task.wait(1)
        end
    end)

    -- Friend activity + profile counters: 30s when populated, 5s retry
    task.spawn(function()
        while alive and gui.Parent do
            local games, onlineFriends = fetchGames()
            if not alive then return end
            if games then
                renderGames(games)
                renderFriendsOnline(onlineFriends or {})
                statCells[3].Text = ('%d friends<br /><font color="%s">online</font>')
                    :format(onlineFriends and #onlineFriends or 0, SUB_HEX)
            end
            local delaySec = (games and #games > 0) and 30 or 5
            for _ = 1, delaySec * 2 do
                if not alive then return end
                if faRefreshRequested then faRefreshRequested = false; break end
                task.wait(0.5)
            end
        end
    end)

    -- Friends in this server (yields per player; refresh sparsely)
    task.spawn(function()
        while alive and gui.Parent do
            local n = 0
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= lp then
                    local ok, isFriend = pcall(function() return lp:IsFriendsWith(pl.UserId) end)
                    if ok and isFriend then n += 1 end
                end
            end
            if not alive then return end
            statCells[2].Text = ('%d friends<br /><font color="%s">joined</font>'):format(n, SUB_HEX)
            for _ = 1, 60 do
                if not alive then return end
                task.wait(0.5)
            end
        end
    end)

    return { close = close }
end

return Home
end)

SYNC.define("apps/Joiner", function()
-- SYNC / apps / Joiner
-- Two tools in one window:
--   1. Invite  - copy a link that drops someone into the EXACT server you're in.
--   2. Join    - paste anyone's game/server link and jump straight into it.
--
-- Joiner.open() -> builds the window (a single instance).

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local Theme     = SYNC.import("core/Theme")
local Util      = SYNC.import("core/Util")
local SyncCodec = SYNC.import("core/SyncCodec")
local WM        = SYNC.import("os/WindowManager")

local Joiner = {}

-- Premium status. Free users create SYNC codes; premium users get real links.
-- Flip it for a paying user with Util.save("SyncPremium", "true") (a real gamepass
-- check can replace this later) or getgenv().SYNCPremium = true.
local function isPremium()
    if getgenv and getgenv().SYNCPremium == true then return true end
    return Util.load("SyncPremium") == "true"
end

local WHITE  = Color3.fromRGB(245, 245, 247)
local SUB    = Color3.fromRGB(150, 150, 158)
local WIN    = Color3.fromRGB(32, 32, 35)
local BAR    = Color3.fromRGB(44, 44, 48)
local GROUP  = Color3.fromRGB(46, 46, 50)
local FIELD  = Color3.fromRGB(24, 24, 28)
local STROKE = Color3.fromRGB(70, 70, 80)
local HAIR   = Color3.fromRGB(0, 0, 0)
local VIOLET = Color3.fromRGB(171, 148, 251)
local GREEN  = Color3.fromRGB(70, 205, 145)

local lp = Players.LocalPlayer

-- lucide icon -> white PNG through weserv (lucide renders black, negate whitens)
local function loadIcon(img, name, tint)
    task.spawn(function()
        local url = "https://images.weserv.nl/?url="
            .. HttpService:UrlEncode("cdn.jsdelivr.net/npm/lucide-static/icons/" .. name .. ".svg")
            .. "&output=png&w=64&h=64&filt=negate"
        local id = Util.remoteImage(url, "ic_join_" .. name .. ".png")
        if id and img and img.Parent then
            img.Image = id
            img.ImageColor3 = tint or WHITE
        end
    end)
end

-- Build the invite link for the server we're in right now.
local function inviteLink()
    return ("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s")
        :format(game.PlaceId, game.JobId)
end

-- Pull a placeId (+ optional server instance) out of whatever the user pasted:
-- a SYNC code, start links, /games/<id> links, or a bare id. Returns placeId,
-- jobId|nil, plus whether it was a SYNC code.
local function parseLink(text)
    text = tostring(text or ""):gsub("%s+", "")
    if text == "" then return nil end
    if SyncCodec.isSyncCode(text) then
        local pid, jid = SyncCodec.decode(text)
        return pid, jid, true
    end
    local pid = text:match("placeId=(%d+)")
        or text:match("/games/(%d+)")
        or text:match("/games/start.-(%d%d%d%d+)")
        or text:match("^(%d+)$")
    local jid = text:match("gameInstanceId=([%w%-]+)")
        or text:match("instanceId=([%w%-]+)")
        or text:match("launchData=([%w%-]+)")
    return pid and tonumber(pid) or nil, jid
end

function Joiner.open()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    if host:FindFirstChild("SYNC_Joiner") then return end

    local cardW, cardH = 480, 462
    local TB = 40

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Joiner"
    Util.mount(gui)

    local winRef, scaleRef
    local closing = false
    local function close()
        if closing then return end
        closing = true
        if winRef and scaleRef then
            Util.tween(scaleRef, { Scale = 0.94 }, 0.15)
            Util.tween(winRef, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.17, function() gui:Destroy() end)
        else
            gui:Destroy()
        end
    end

    Util.closeOnEscape(gui, close)

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
    WM.register(gui, win, 12)

    local scaleFx = Instance.new("UIScale")
    scaleFx.Scale = 0.94
    scaleFx.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleFx, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0.04 }, 0.18)
    winRef, scaleRef = win, scaleFx

    -- title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = BAR
    bar.BackgroundTransparency = 0.12
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local barCorner = Instance.new("UICorner")
    local okC = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 12); barCorner.TopRightRadius = UDim.new(0, 12)
        barCorner.BottomLeftRadius = UDim.new(0, 0); barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okC then barCorner.CornerRadius = UDim.new(0, 12) end
    barCorner.Parent = bar

    for i, col in ipairs({ Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }) do
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
        if i == 3 then dot.MouseButton1Click:Connect(function()
            Util.tween(win, { Position = UDim2.fromScale(0.5, 0.5) }, 0.3, Enum.EasingStyle.Quint)
        end) end
    end

    Util.draggable(win, bar)
    Util.persistPosition(win, "JoinerWin")

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Joiner"
    title.Font = Theme.fonts.title
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(210, 210, 216)
    title.ZIndex = 3
    title.Parent = bar

    -- section header helper
    local function section(text, y)
        local s = Instance.new("TextLabel")
        s.Text = text
        s.Size = UDim2.fromOffset(cardW - 40, 14)
        s.Position = UDim2.fromOffset(20, y)
        s.BackgroundTransparency = 1
        s.Font = Theme.fonts.body
        s.TextSize = 11
        s.TextColor3 = SUB
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.ZIndex = 3
        s.Parent = win
        return s
    end

    -- card helper
    local function card(y, h)
        local c = Instance.new("Frame")
        c.Size = UDim2.fromOffset(cardW - 32, h)
        c.Position = UDim2.fromOffset(16, y)
        c.BackgroundColor3 = GROUP
        c.BorderSizePixel = 0
        c.ZIndex = 3
        c.Parent = win
        Util.corner(c, 10)
        Util.stroke(c, WHITE, 1, 0.9)
        return c
    end

    -- rounded gradient app-icon tile with a lucide glyph centered
    local function iconTile(parent, top, bot, iconName)
        local tile = Instance.new("Frame")
        tile.Size = UDim2.fromOffset(42, 42)
        tile.Position = UDim2.fromOffset(16, 16)
        tile.BackgroundColor3 = top
        tile.BorderSizePixel = 0
        tile.ZIndex = 4
        tile.Parent = parent
        Util.corner(tile, 12)
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new(top, bot)
        g.Parent = tile
        Util.stroke(tile, Color3.fromRGB(255, 255, 255), 1, 0.7)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(22, 22)
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.BackgroundTransparency = 1
        ic.ZIndex = 5
        ic.Parent = tile
        loadIcon(ic, iconName, WHITE)
        return tile
    end

    -- gradient pill button with a subtle grow on hover
    local function gradBtn(parent, x, y, w, h, top, bot, txt, txtCol)
        local b = Instance.new("TextButton")
        b.Position = UDim2.fromOffset(x, y)
        b.Size = UDim2.fromOffset(w, h)
        b.AnchorPoint = Vector2.new(0, 0)
        b.BackgroundColor3 = top
        b.AutoButtonColor = false
        b.Font = Theme.fonts.title
        b.Text = txt
        b.TextSize = 13
        b.TextColor3 = txtCol
        b.BorderSizePixel = 0
        b.ZIndex = 4
        b.Parent = parent
        Util.corner(b, 10)
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        g.Color = ColorSequence.new(top, bot)
        g.Parent = b
        local sc = Instance.new("UIScale")
        sc.Parent = b
        b.MouseEnter:Connect(function() Util.tween(sc, { Scale = 1.02 }, 0.12) end)
        b.MouseLeave:Connect(function() Util.tween(sc, { Scale = 1.0 }, 0.12) end)
        return b
    end

    local IN = 16 -- inner card padding
    local CW = cardW - 32 - IN * 2 -- content width inside a card

    local premium = isPremium()
    local function currentToken()
        if isPremium() then return inviteLink() end
        return SyncCodec.encode(game.PlaceId, game.JobId)
    end

    -- ============ 1. INVITE ============
    section("YOUR SERVER", TB + 12)
    local c1 = card(TB + 32, 186)
    iconTile(c1, Color3.fromRGB(188, 168, 255), Color3.fromRGB(150, 118, 242), "link")

    local t1 = Instance.new("TextLabel")
    t1.Text = "Invite to your server"
    t1.Position = UDim2.fromOffset(70, 16)
    t1.Size = UDim2.fromOffset(cardW - 200, 20)
    t1.BackgroundTransparency = 1
    t1.Font = Theme.fonts.title
    t1.TextSize = 15
    t1.TextColor3 = WHITE
    t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.ZIndex = 4
    t1.Parent = c1

    local gameLabel = Instance.new("TextLabel")
    gameLabel.Text = "Reading this server..."
    gameLabel.Position = UDim2.fromOffset(70, 39)
    gameLabel.Size = UDim2.fromOffset(cardW - 130, 16)
    gameLabel.BackgroundTransparency = 1
    gameLabel.Font = Theme.fonts.caption
    gameLabel.TextSize = 12
    gameLabel.TextColor3 = SUB
    gameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    gameLabel.ZIndex = 4
    gameLabel.Parent = c1
    task.spawn(function()
        local name = "this experience"
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info and info.Name then name = info.Name end
        end)
        local n, mx = #Players:GetPlayers(), Players.MaxPlayers
        if gameLabel.Parent then
            gameLabel.Text = ("%s   ·   %d/%d players"):format(name, n, mx > 0 and mx or n)
        end
    end)

    -- tier badge (top-right): PRO for premium, tappable Upgrade for free
    local badge = Instance.new("TextButton")
    badge.AnchorPoint = Vector2.new(1, 0)
    badge.Position = UDim2.fromOffset(cardW - 32 - 14, 16)
    badge.Size = UDim2.fromOffset(premium and 52 or 74, 22)
    badge.AutoButtonColor = false
    badge.BackgroundColor3 = premium and Color3.fromRGB(240, 196, 92) or Color3.fromRGB(40, 40, 46)
    badge.Font = Theme.fonts.title
    badge.Text = premium and "PRO" or "Upgrade"
    badge.TextSize = 11
    badge.TextColor3 = premium and Color3.fromRGB(40, 30, 6) or VIOLET
    badge.BorderSizePixel = 0
    badge.ZIndex = 5
    badge.Parent = c1
    Util.corner(badge, 11)
    if not premium then Util.stroke(badge, VIOLET, 1, 0.4) end

    -- link / code preview pill (read-only, truncated)
    local prev = Instance.new("TextLabel")
    prev.Position = UDim2.fromOffset(IN, 70)
    prev.Size = UDim2.fromOffset(CW, 32)
    prev.BackgroundColor3 = FIELD
    prev.BackgroundTransparency = 0.1
    prev.Font = Enum.Font.Code
    prev.Text = "   " .. currentToken()
    prev.TextSize = 11
    prev.TextColor3 = Color3.fromRGB(165, 165, 175)
    prev.TextXAlignment = Enum.TextXAlignment.Left
    prev.TextTruncate = Enum.TextTruncate.AtEnd
    prev.ClipsDescendants = true
    prev.ZIndex = 4
    prev.Parent = c1
    Util.corner(prev, 8)
    Util.stroke(prev, STROKE, 1, 0.6)

    -- mode note
    local note = Instance.new("TextLabel")
    note.Position = UDim2.fromOffset(IN, 108)
    note.Size = UDim2.fromOffset(CW, 28)
    note.BackgroundTransparency = 1
    note.Font = Theme.fonts.caption
    note.Text = premium
        and "A normal Roblox link. Works in the app and anywhere you send it."
        or "A SYNC code. Only people using SYNC Joiner can open it. Go PRO for a link that works anywhere."
    note.TextSize = 11
    note.TextColor3 = premium and Color3.fromRGB(120, 210, 150) or SUB
    note.TextWrapped = true
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.TextYAlignment = Enum.TextYAlignment.Top
    note.ZIndex = 4
    note.Parent = c1

    local copyBtn = gradBtn(c1, IN, 140, CW, 38,
        Color3.fromRGB(186, 166, 255), Color3.fromRGB(150, 120, 240),
        premium and "Copy invite link" or "Copy SYNC code", Color3.fromRGB(26, 22, 40))
    copyBtn.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(currentToken()) end)
        copyBtn.Text = ok and "Copied to clipboard" or "Clipboard not available"
        task.delay(1.4, function()
            if copyBtn.Parent then copyBtn.Text = isPremium() and "Copy invite link" or "Copy SYNC code" end
        end)
    end)

    if not premium then
        badge.MouseButton1Click:Connect(function()
            note.Text = "Premium unlocks a universal link anyone can open. Subscription coming soon."
            note.TextColor3 = VIOLET
            task.delay(2.6, function()
                if note.Parent then
                    note.Text = "A SYNC code. Only people using SYNC Joiner can open it. Go PRO for a link that works anywhere."
                    note.TextColor3 = SUB
                end
            end)
        end)
    end

    -- ============ 2. JOIN ============
    section("JOIN A FRIEND", TB + 32 + 186 + 14)
    local c2 = card(TB + 32 + 186 + 34, 150)
    iconTile(c2, Color3.fromRGB(110, 222, 168), Color3.fromRGB(52, 182, 132), "log-in")

    local t2 = Instance.new("TextLabel")
    t2.Text = "Join a friend's game"
    t2.Position = UDim2.fromOffset(70, 18)
    t2.Size = UDim2.fromOffset(cardW - 120, 20)
    t2.BackgroundTransparency = 1
    t2.Font = Theme.fonts.title
    t2.TextSize = 15
    t2.TextColor3 = WHITE
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.ZIndex = 4
    t2.Parent = c2

    local d2 = Instance.new("TextLabel")
    d2.Text = "Paste their link and hop straight into their server."
    d2.Position = UDim2.fromOffset(70, 41)
    d2.Size = UDim2.fromOffset(cardW - 120, 16)
    d2.BackgroundTransparency = 1
    d2.Font = Theme.fonts.caption
    d2.TextSize = 12
    d2.TextColor3 = SUB
    d2.TextXAlignment = Enum.TextXAlignment.Left
    d2.ZIndex = 4
    d2.Parent = c2

    -- paste field + join button on one row
    local btnW = 96
    local fh = Instance.new("Frame")
    fh.Position = UDim2.fromOffset(IN, 74)
    fh.Size = UDim2.fromOffset(CW - btnW - 10, 38)
    fh.BackgroundColor3 = FIELD
    fh.BorderSizePixel = 0
    fh.ZIndex = 4
    fh.Parent = c2
    Util.corner(fh, 10)
    local fSt = Util.stroke(fh, STROKE, 1, 0.45)

    local input = Instance.new("TextBox")
    input.Position = UDim2.fromOffset(12, 0)
    input.Size = UDim2.fromOffset(CW - btnW - 10 - 24, 38)
    input.BackgroundTransparency = 1
    input.Font = Theme.fonts.body
    input.PlaceholderText = "Paste a game or server link"
    input.PlaceholderColor3 = Color3.fromRGB(110, 110, 118)
    input.Text = ""
    input.TextSize = 12
    input.TextColor3 = WHITE
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.ClipsDescendants = true
    input.ZIndex = 5
    input.Parent = fh
    input.Focused:Connect(function() Util.tween(fSt, { Transparency = 0, Color = GREEN }, 0.15) end)
    input.FocusLost:Connect(function() Util.tween(fSt, { Transparency = 0.45, Color = STROKE }, 0.15) end)

    local joinBtn = gradBtn(c2, IN + CW - btnW, 74, btnW, 38,
        Color3.fromRGB(104, 216, 162), Color3.fromRGB(54, 184, 134),
        "Join", Color3.fromRGB(10, 34, 24))

    local status = Instance.new("TextLabel")
    status.Position = UDim2.fromOffset(IN, 120)
    status.Size = UDim2.fromOffset(CW, 24)
    status.BackgroundTransparency = 1
    status.Font = Theme.fonts.caption
    status.Text = ""
    status.TextSize = 12
    status.TextColor3 = SUB
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.ZIndex = 4
    status.Parent = c2

    local function setStatus(msg, color)
        status.Text = msg
        status.TextColor3 = color or SUB
    end

    local joining = false
    local function doJoin()
        if joining then return end
        local pid, jid, isCode = parseLink(input.Text)
        if not pid then
            local msg = SyncCodec.isSyncCode(input.Text)
                and "That SYNC code looks broken. Ask them to copy it again."
                or "Couldn't find a game in that link. Paste a roblox.com link or a SYNC code."
            setStatus(msg, Color3.fromRGB(255, 120, 110))
            return
        end
        joining = true
        joinBtn.Text = "Joining"
        if jid then
            setStatus(isCode and "Decoded a SYNC code, joining their server..." or "Joining their exact server...", GREEN)
            local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(pid, jid, lp) end)
            if not ok then
                setStatus("That server may be full or closed. Trying a normal join...", Color3.fromRGB(240, 190, 90))
                pcall(function() TeleportService:Teleport(pid, lp) end)
            end
        else
            setStatus("No specific server in the link, joining a public server...", GREEN)
            pcall(function() TeleportService:Teleport(pid, lp) end)
        end
        task.delay(2.5, function()
            if joinBtn.Parent then joinBtn.Text = "Join"; joining = false end
        end)
    end
    joinBtn.MouseButton1Click:Connect(doJoin)
    input.FocusLost:Connect(function(enter) if enter then doJoin() end end)

    return { close = close }
end

return Joiner
end)

SYNC.define("apps/Music", function()
-- SYNC / apps / Music
-- A Spotify companion. You paste a Spotify OAuth token, SYNC talks to the Spotify
-- Web API (api.spotify.com) with it, and then shows what you're playing with
-- play / pause / skip controls that drive your real Spotify. No audio streams
-- through Roblox (Spotify doesn't allow that); this is a remote for your account.
--
-- Music.open() -> builds the window (a single instance).

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local WM    = SYNC.import("os/WindowManager")

local Music = {}

local _req = (syn and syn.request) or (http and http.request) or http_request or request

local WHITE  = Color3.fromRGB(244, 244, 248)
local SUB    = Color3.fromRGB(150, 150, 158)
local DIM    = Color3.fromRGB(105, 105, 113)
local WIN    = Color3.fromRGB(15, 15, 18)
local BAR    = Color3.fromRGB(28, 28, 32)
local FIELD  = Color3.fromRGB(12, 12, 15)
local CARD   = Color3.fromRGB(22, 22, 27)
local BLUE   = Color3.fromRGB(46, 72, 117)
local BLUEH  = Color3.fromRGB(58, 88, 140)
local LINK   = Color3.fromRGB(74, 135, 225)

local TOKEN_KEY = "SpotifyToken"
local API = "https://api.spotify.com/v1"

-- lucide icon -> white png (renders black, negate whitens), then tint
local function loadIcon(img, name, tint)
    task.spawn(function()
        local url = "https://images.weserv.nl/?url="
            .. HttpService:UrlEncode("cdn.jsdelivr.net/npm/lucide-static/icons/" .. name .. ".svg")
            .. "&output=png&w=96&h=96&filt=negate"
        local id = Util.remoteImage(url, "ic_music_" .. name .. ".png")
        if id and img and img.Parent then img.Image = id; img.ImageColor3 = tint or WHITE end
    end)
end

-- album art (https i.scdn.co) -> png via weserv, cached per track id
local function loadArt(img, url, key)
    task.spawn(function()
        local png = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode(url) .. "&output=png&w=300&h=300&fit=cover"
        local id = Util.remoteImage(png, "sp_art_" .. key .. ".png")
        if id and img and img.Parent then img.Image = id end
    end)
end

-- one Spotify API call. Returns (body, statusCode).
local function spotify(method, path, token, body)
    if not _req then return nil, 0 end
    local ok, res = pcall(_req, {
        Url = API .. path,
        Method = method,
        Headers = {
            ["Authorization"] = "Bearer " .. token,
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "SYNC",
        },
        Body = body,
    })
    if ok and res then return res.Body, res.StatusCode or 0 end
    return nil, 0
end

local function mmss(ms)
    ms = math.max(0, math.floor((ms or 0) / 1000))
    return ("%d:%02d"):format(math.floor(ms / 60), ms % 60)
end

Music._gui = nil

-- ============================================================================
-- MP3 PLAYER: a separate compact window that plays local audio files dropped
-- into SYNC/songs. Roblox plays them via getcustomasset (custom audio assets).
-- ============================================================================
local SND_DIR = "SYNC/songs"
local AUDIO_EXT = { mp3 = true, ogg = true, wav = true }

function Music.openMP3()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    if host:FindFirstChild("SYNC_MP3") then return end
    pcall(function()
        if type(makefolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder(SND_DIR) then makefolder(SND_DIR) end
        end
    end)

    local W, H = 440, 474
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_MP3"
    Util.mount(gui)

    local closing = false
    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.44)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    Util.corner(win, 18)
    Util.stroke(win, WHITE, 1, 0.9)
    Util.shadow(win, { blur = 55, spread = 0, transparency = 0.35, offset = UDim2.fromOffset(0, 22) })
    local wg = Instance.new("UIGradient")
    wg.Rotation = 118
    wg.Color = ColorSequence.new(Color3.fromRGB(26, 30, 44), Color3.fromRGB(11, 11, 15))
    wg.Parent = win
    local sc = Instance.new("UIScale"); sc.Scale = 0.94; sc.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(sc, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0 }, 0.18)

    local function close()
        if closing then return end
        closing = true
        Util.tween(sc, { Scale = 0.94 }, 0.14)
        Util.tween(win, { BackgroundTransparency = 1 }, 0.14)
        task.delay(0.16, function() gui:Destroy() end)
    end
    Util.closeOnEscape(gui, close)

    local titleTxt = Instance.new("TextLabel")
    titleTxt.Text = "MP3 PLAYER"
    titleTxt.Position = UDim2.fromOffset(20, 16)
    titleTxt.Size = UDim2.fromOffset(200, 18)
    titleTxt.BackgroundTransparency = 1
    titleTxt.Font = Theme.fonts.title
    titleTxt.TextSize = 12
    titleTxt.TextColor3 = Color3.fromRGB(175, 175, 186)
    titleTxt.TextXAlignment = Enum.TextXAlignment.Left
    titleTxt.Parent = win
    local dragBar = Instance.new("Frame")
    dragBar.Size = UDim2.new(1, 0, 0, 40)
    dragBar.BackgroundTransparency = 1
    dragBar.Parent = win
    Util.draggable(win, dragBar)

    local xBtn = Instance.new("TextButton")
    xBtn.AnchorPoint = Vector2.new(1, 0)
    xBtn.Position = UDim2.fromOffset(W - 16, 13)
    xBtn.Size = UDim2.fromOffset(22, 22)
    xBtn.BackgroundTransparency = 1
    xBtn.AutoButtonColor = false
    xBtn.Font = Theme.fonts.body
    xBtn.Text = "\195\151"
    xBtn.TextSize = 20
    xBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
    xBtn.Parent = win
    xBtn.MouseEnter:Connect(function() xBtn.TextColor3 = WHITE end)
    xBtn.MouseLeave:Connect(function() xBtn.TextColor3 = Color3.fromRGB(160, 160, 170) end)
    xBtn.MouseButton1Click:Connect(close)

    -- large album / empty-state area (top)
    local artArea = Instance.new("Frame")
    artArea.Position = UDim2.fromOffset(16, 44)
    artArea.Size = UDim2.fromOffset(W - 32, 246)
    artArea.BackgroundColor3 = Color3.fromRGB(9, 10, 14)
    artArea.BackgroundTransparency = 0.15
    artArea.BorderSizePixel = 0
    artArea.Parent = win
    Util.corner(artArea, 14)
    local ag = Instance.new("UIGradient")
    ag.Rotation = 125
    ag.Color = ColorSequence.new(Color3.fromRGB(20, 23, 34), Color3.fromRGB(8, 8, 11))
    ag.Parent = artArea
    local emptyTxt = Instance.new("TextLabel")
    emptyTxt.AnchorPoint = Vector2.new(0.5, 0.5)
    emptyTxt.Position = UDim2.fromScale(0.5, 0.5)
    emptyTxt.Size = UDim2.fromOffset(W - 80, 44)
    emptyTxt.BackgroundTransparency = 1
    emptyTxt.Font = Theme.fonts.caption
    emptyTxt.Text = "Drop .mp3 files into\nSYNC/songs folder"
    emptyTxt.TextSize = 14
    emptyTxt.TextColor3 = Color3.fromRGB(118, 118, 130)
    emptyTxt.ZIndex = 3
    emptyTxt.Parent = artArea

    -- control panel (bottom, a distinct card)
    local panel = Instance.new("Frame")
    panel.Position = UDim2.fromOffset(16, 300)
    panel.Size = UDim2.fromOffset(W - 32, H - 300 - 16)
    panel.BackgroundColor3 = Color3.fromRGB(17, 18, 23)
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Parent = win
    Util.corner(panel, 14)
    Util.stroke(panel, WHITE, 1, 0.92)
    local PW = W - 32

    local trackTxt = Instance.new("TextLabel")
    trackTxt.Position = UDim2.fromOffset(20, 12)
    trackTxt.Size = UDim2.fromOffset(PW - 40, 24)
    trackTxt.BackgroundTransparency = 1
    trackTxt.Font = Theme.fonts.title
    trackTxt.Text = "No Track"
    trackTxt.TextSize = 16
    trackTxt.TextColor3 = WHITE
    trackTxt.TextTruncate = Enum.TextTruncate.AtEnd
    trackTxt.ZIndex = 3
    trackTxt.Parent = panel

    -- slider builder (parented to the panel)
    local BLUEP = Color3.fromRGB(58, 108, 210)
    local function makeSlider(parent, x, y, w, h, onSet)
        local track = Instance.new("TextButton")
        track.Text = ""; track.AutoButtonColor = false
        track.Position = UDim2.fromOffset(x, y)
        track.Size = UDim2.fromOffset(w, h)
        track.BackgroundColor3 = Color3.fromRGB(52, 53, 62)
        track.BorderSizePixel = 0
        track.ZIndex = 3
        track.Parent = parent
        Util.corner(track, h / 2)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = BLUEP
        fill.BorderSizePixel = 0
        fill.ZIndex = 3
        fill.Parent = track
        Util.corner(fill, h / 2)
        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.fromScale(0, 0.5)
        knob.Size = UDim2.fromOffset(h + 8, h + 8)
        knob.BackgroundColor3 = WHITE
        knob.BorderSizePixel = 0
        knob.ZIndex = 4
        knob.Parent = track
        Util.corner(knob, (h + 8) / 2)
        local function setFrac(f)
            f = math.clamp(f, 0, 1)
            fill.Size = UDim2.new(f, 0, 1, 0)
            knob.Position = UDim2.new(f, 0, 0.5, 0)
        end
        local dragging = false
        local function fracFromX(pxX)
            return math.clamp((pxX - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        end
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local f = fracFromX(inp.Position.X); setFrac(f); if onSet then onSet(f) end
            end
        end)
        track.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local f = fracFromX(inp.Position.X); setFrac(f); if onSet then onSet(f) end
            end
        end)
        return setFrac, function() return dragging end
    end

    -- ---- audio state ----
    local sound
    local files, index = {}, 0
    local function stopSound()
        if sound then pcall(function() sound:Stop(); sound:Destroy() end); sound = nil end
    end

    local timeCur = Instance.new("TextLabel")
    timeCur.Position = UDim2.fromOffset(20, 60)
    timeCur.Size = UDim2.fromOffset(50, 14)
    timeCur.BackgroundTransparency = 1
    timeCur.Font = Theme.fonts.caption
    timeCur.Text = "0:00"; timeCur.TextSize = 11; timeCur.TextColor3 = DIM
    timeCur.TextXAlignment = Enum.TextXAlignment.Left
    timeCur.ZIndex = 3
    timeCur.Parent = panel
    local timeEnd = Instance.new("TextLabel")
    timeEnd.AnchorPoint = Vector2.new(1, 0)
    timeEnd.Position = UDim2.fromOffset(PW - 20, 60)
    timeEnd.Size = UDim2.fromOffset(50, 14)
    timeEnd.BackgroundTransparency = 1
    timeEnd.Font = Theme.fonts.caption
    timeEnd.Text = "0:00"; timeEnd.TextSize = 11; timeEnd.TextColor3 = DIM
    timeEnd.TextXAlignment = Enum.TextXAlignment.Right
    timeEnd.ZIndex = 3
    timeEnd.Parent = panel

    local progSet, progDragging = makeSlider(panel, 20, 48, PW - 40, 6, function(f)
        if sound and sound.TimeLength > 0 then sound.TimePosition = f * sound.TimeLength end
    end)

    -- controls (plain icons, play larger, no circle)
    local playIco
    local function ctrl(cx, size, icon)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(0.5, 0.5)
        b.Position = UDim2.fromOffset(cx, 104)
        b.Size = UDim2.fromOffset(size + 12, size + 12)
        b.BackgroundTransparency = 1
        b.AutoButtonColor = false
        b.Text = ""
        b.ZIndex = 3
        b.Parent = panel
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.Size = UDim2.fromOffset(size, size)
        ic.BackgroundTransparency = 1
        ic.ImageColor3 = Color3.fromRGB(225, 225, 232)
        ic.ZIndex = 4
        ic.Parent = b
        loadIcon(ic, icon, Color3.fromRGB(225, 225, 232))
        return b, ic
    end
    local cx = PW / 2
    local prevBtn = ctrl(cx - 62, 26, "skip-back")
    local playBtn, playIcoRef = ctrl(cx, 38, "play")
    playIco = playIcoRef
    local nextBtn = ctrl(cx + 62, 26, "skip-forward")

    local function fmt(s) s = math.max(0, math.floor(s or 0)); return ("%d:%02d"):format(math.floor(s / 60), s % 60) end

    local function playIndex(i)
        if #files == 0 then return end
        index = ((i - 1) % #files) + 1
        stopSound()
        local path = files[index]
        local ok, id = pcall(function() return getcustomasset(path) end)
        if not ok or not id then trackTxt.Text = "Could not load track"; return end
        sound = Instance.new("Sound")
        sound.SoundId = id
        sound.Volume = 0.6
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        -- filename -> nice title
        local name = path:match("([^/\\]+)$") or path
        name = name:gsub("%.%w+$", "")
        trackTxt.Text = name
        loadIcon(playIco, "pause", WHITE)
        sound.Ended:Connect(function() if sound and not closing then playIndex(index + 1) end end)
    end

    local function scan()
        files = {}
        local ok, list = pcall(function() return listfiles(SND_DIR) end)
        if ok and list then
            for _, f in ipairs(list) do
                local ext = tostring(f):match("%.(%w+)$")
                if ext and AUDIO_EXT[ext:lower()] then files[#files + 1] = f end
            end
        end
        if #files > 0 then
            emptyTxt.Text = (#files == 1 and "1 track loaded") or (#files .. " tracks loaded")
        else
            emptyTxt.Text = "Drop .mp3 files into\nSYNC/songs folder"
            trackTxt.Text = "No Track"
        end
    end

    prevBtn.MouseButton1Click:Connect(function() if #files > 0 then playIndex(index - 1) end end)
    nextBtn.MouseButton1Click:Connect(function() if #files > 0 then playIndex(index + 1) end end)
    playBtn.MouseButton1Click:Connect(function()
        if not sound then if #files > 0 then playIndex(index == 0 and 1 or index) end return end
        if sound.Playing then sound:Pause(); loadIcon(playIco, "play", WHITE)
        else sound:Resume(); loadIcon(playIco, "pause", WHITE) end
    end)

    -- volume slider + refresh (bottom of the panel)
    local PH = H - 300 - 16
    local volSet = makeSlider(panel, 20, PH - 26, 96, 5, function(f) if sound then sound.Volume = f end end)
    volSet(0.6)
    local refresh = Instance.new("TextButton")
    refresh.AnchorPoint = Vector2.new(1, 0.5)
    refresh.Position = UDim2.fromOffset(PW - 18, PH - 24)
    refresh.Size = UDim2.fromOffset(70, 20)
    refresh.BackgroundTransparency = 1
    refresh.AutoButtonColor = false
    refresh.Font = Theme.fonts.caption
    refresh.Text = "Refresh"
    refresh.TextSize = 12
    refresh.TextColor3 = Color3.fromRGB(150, 150, 160)
    refresh.TextXAlignment = Enum.TextXAlignment.Right
    refresh.ZIndex = 3
    refresh.Parent = panel
    refresh.MouseEnter:Connect(function() refresh.TextColor3 = WHITE end)
    refresh.MouseLeave:Connect(function() refresh.TextColor3 = Color3.fromRGB(150, 150, 160) end)
    refresh.MouseButton1Click:Connect(scan)

    -- progress update loop
    task.spawn(function()
        while gui.Parent do
            if sound and sound.TimeLength and sound.TimeLength > 0 then
                timeCur.Text = fmt(sound.TimePosition)
                timeEnd.Text = fmt(sound.TimeLength)
                if not progDragging() then progSet(sound.TimePosition / sound.TimeLength) end
            end
            task.wait(0.3)
        end
        stopSound()
    end)

    scan()
    return { close = close }
end

-- ============================================================================
-- YOUTUBE: search videos (or paste a link), then download the audio to
-- SYNC/songs so the MP3 player can play it. Search runs through public Piped
-- instances; the audio itself is fetched through a media-extraction service
-- (Cobalt) that transcodes to mp3 (Roblox can only play mp3/ogg).
-- ============================================================================
local RED = Color3.fromRGB(230, 66, 74)
local PIPED = {
    "https://api.piped.private.coffee",
    "https://pipedapi.adminforge.de",
    "https://pipedapi.kavin.rocks",
    "https://pipedapi.reallyaweso.me",
}
local COBALT = {
    "https://cobalt-backend.canine.tools",
    "https://cobalt-api.kwiatekmiki.com",
    "https://co.eepy.today",
    "https://cobalt.255x.ru",
}

local function ytId(url)
    url = tostring(url)
    return url:match("[?&]v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
        or url:match("/watch%?v=([%w%-_]+)") or url:match("/embed/([%w%-_]+)")
        or url:match("/shorts/([%w%-_]+)") or url:match("^([%w%-_]+)$")
end

local function ytSearch(q)
    for _, inst in ipairs(PIPED) do
        local b = Util.httpGetH(inst .. "/search?q=" .. HttpService:UrlEncode(q) .. "&filter=videos", {})
        if b then
            local ok, d = pcall(function() return HttpService:JSONDecode(b) end)
            if ok and d and d.items and #d.items > 0 then return d.items end
        end
    end
    return nil
end

-- ask a Cobalt instance for a direct mp3 url. Returns url or nil.
local function ytAudioUrl(youtubeUrl)
    for _, inst in ipairs(COBALT) do
        -- newer API shape
        local _, _, body = Util.httpPost(inst .. "/", { ["Accept"] = "application/json" },
            HttpService:JSONEncode({ url = youtubeUrl, downloadMode = "audio", audioFormat = "mp3" }))
        local ok, d = pcall(function() return HttpService:JSONDecode(body or "") end)
        if ok and d and d.url then return d.url end
        -- older API shape
        local _, _, body2 = Util.httpPost(inst .. "/api/json", { ["Accept"] = "application/json" },
            HttpService:JSONEncode({ url = youtubeUrl, isAudioOnly = true, aFormat = "mp3" }))
        local ok2, d2 = pcall(function() return HttpService:JSONDecode(body2 or "") end)
        if ok2 and d2 and d2.url then return d2.url end
    end
    return nil
end

local function safeName(s)
    return (tostring(s):gsub("[^%w%s%-_%.]", ""):gsub("%s+", " "):sub(1, 60))
end

function Music.openYT()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    if host:FindFirstChild("SYNC_YouTube") then return end
    pcall(function()
        if type(makefolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder(SND_DIR) then makefolder(SND_DIR) end
        end
    end)

    local W, H = 470, 524
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_YouTube"
    Util.mount(gui)

    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.46)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(14, 14, 17)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    Util.corner(win, 18)
    Util.stroke(win, WHITE, 1, 0.9)
    Util.shadow(win, { blur = 55, transparency = 0.35, offset = UDim2.fromOffset(0, 22) })
    local sc = Instance.new("UIScale"); sc.Scale = 0.94; sc.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(sc, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0 }, 0.18)

    local closing = false
    local function close()
        if closing then return end
        closing = true
        Util.tween(sc, { Scale = 0.94 }, 0.14)
        Util.tween(win, { BackgroundTransparency = 1 }, 0.14)
        task.delay(0.16, function() gui:Destroy() end)
    end
    Util.closeOnEscape(gui, close)

    local ytIco = Instance.new("ImageLabel")
    ytIco.Size = UDim2.fromOffset(20, 20); ytIco.Position = UDim2.fromOffset(20, 18)
    ytIco.BackgroundTransparency = 1; ytIco.ImageColor3 = RED; ytIco.Parent = win
    loadIcon(ytIco, "youtube", RED)
    local hTitle = Instance.new("TextLabel")
    hTitle.Text = "YouTube"; hTitle.Position = UDim2.fromOffset(48, 14)
    hTitle.Size = UDim2.fromOffset(200, 22); hTitle.BackgroundTransparency = 1
    hTitle.Font = Theme.fonts.title; hTitle.TextSize = 18; hTitle.TextColor3 = WHITE
    hTitle.TextXAlignment = Enum.TextXAlignment.Left; hTitle.Parent = win
    local hSub = Instance.new("TextLabel")
    hSub.Text = "Search a song or paste a link"; hSub.Position = UDim2.fromOffset(48, 37)
    hSub.Size = UDim2.fromOffset(300, 16); hSub.BackgroundTransparency = 1
    hSub.Font = Theme.fonts.caption; hSub.TextSize = 12; hSub.TextColor3 = SUB
    hSub.TextXAlignment = Enum.TextXAlignment.Left; hSub.Parent = win
    local dragBar = Instance.new("Frame"); dragBar.Size = UDim2.new(1, 0, 0, 44)
    dragBar.BackgroundTransparency = 1; dragBar.Parent = win
    Util.draggable(win, dragBar)
    local xBtn = Instance.new("TextButton")
    xBtn.AnchorPoint = Vector2.new(1, 0); xBtn.Position = UDim2.fromOffset(W - 16, 14)
    xBtn.Size = UDim2.fromOffset(22, 22); xBtn.BackgroundTransparency = 1; xBtn.AutoButtonColor = false
    xBtn.Font = Theme.fonts.body; xBtn.Text = "\195\151"; xBtn.TextSize = 20
    xBtn.TextColor3 = Color3.fromRGB(160, 160, 170); xBtn.Parent = win
    xBtn.MouseEnter:Connect(function() xBtn.TextColor3 = WHITE end)
    xBtn.MouseLeave:Connect(function() xBtn.TextColor3 = Color3.fromRGB(160, 160, 170) end)
    xBtn.MouseButton1Click:Connect(close)

    -- search bar
    local sh = Instance.new("Frame")
    sh.Position = UDim2.fromOffset(16, 60); sh.Size = UDim2.fromOffset(W - 32, 42)
    sh.BackgroundColor3 = Color3.fromRGB(24, 24, 28); sh.BorderSizePixel = 0; sh.Parent = win
    Util.corner(sh, 10); local sst = Util.stroke(sh, Color3.fromRGB(70, 70, 80), 1, 0.55)
    local sBox = Instance.new("TextBox")
    sBox.Position = UDim2.fromOffset(16, 0); sBox.Size = UDim2.fromOffset(W - 32 - 60, 42)
    sBox.BackgroundTransparency = 1; sBox.Font = Theme.fonts.body
    sBox.PlaceholderText = "Search YouTube or paste a link..."; sBox.PlaceholderColor3 = DIM
    sBox.Text = ""; sBox.TextSize = 14; sBox.TextColor3 = WHITE
    sBox.TextXAlignment = Enum.TextXAlignment.Left; sBox.ClearTextOnFocus = false; sBox.Parent = sh
    sBox.Focused:Connect(function() Util.tween(sst, { Transparency = 0.1, Color = RED }, 0.15) end)
    sBox.FocusLost:Connect(function() Util.tween(sst, { Transparency = 0.55, Color = Color3.fromRGB(70, 70, 80) }, 0.15) end)
    local sBtn = Instance.new("TextButton")
    sBtn.AnchorPoint = Vector2.new(1, 0.5); sBtn.Position = UDim2.new(1, -8, 0.5, 0)
    sBtn.Size = UDim2.fromOffset(40, 30); sBtn.BackgroundColor3 = RED; sBtn.AutoButtonColor = false
    sBtn.Text = ""; sBtn.BorderSizePixel = 0; sBtn.Parent = sh
    Util.corner(sBtn, 8)
    local sBtnIc = Instance.new("ImageLabel")
    sBtnIc.AnchorPoint = Vector2.new(0.5, 0.5); sBtnIc.Position = UDim2.fromScale(0.5, 0.5)
    sBtnIc.Size = UDim2.fromOffset(16, 16); sBtnIc.BackgroundTransparency = 1
    sBtnIc.ImageColor3 = WHITE; sBtnIc.Parent = sBtn
    loadIcon(sBtnIc, "search", WHITE)

    -- results
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(12, 114); scroll.Size = UDim2.fromOffset(W - 24, H - 114 - 14)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.CanvasSize = UDim2.new(); scroll.Parent = win
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
    Util.autoCanvas(scroll, "Y")
    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0); status.Position = UDim2.fromScale(0.5, 0.25)
    status.Size = UDim2.fromOffset(W - 60, 40); status.BackgroundTransparency = 1
    status.Font = Theme.fonts.caption; status.Text = "Search for a song or paste a YouTube link."
    status.TextSize = 13; status.TextColor3 = SUB; status.TextWrapped = true
    status.ZIndex = 2; status.Parent = scroll

    local function clearResults()
        for _, c in ipairs(scroll:GetChildren()) do
            if c ~= layout and c ~= status then c:Destroy() end
        end
    end

    local function resultCard(i, id, title, channel, dur)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, -6, 0, 64); c.BackgroundColor3 = CARD; c.BorderSizePixel = 0
        c.LayoutOrder = i; c.Parent = scroll
        Util.corner(c, 10); Util.stroke(c, WHITE, 1, 0.93)
        local thumb = Instance.new("ImageLabel")
        thumb.Position = UDim2.fromOffset(8, 8); thumb.Size = UDim2.fromOffset(84, 48)
        thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36); thumb.BorderSizePixel = 0
        thumb.ScaleType = Enum.ScaleType.Crop; thumb.ZIndex = 2; thumb.Parent = c
        Util.corner(thumb, 7)
        task.spawn(function()
            local url = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode("i.ytimg.com/vi/" .. id .. "/mqdefault.jpg")
                .. "&output=png&w=168&h=94&fit=cover"
            local aid = Util.remoteImage(url, "yt_thumb_" .. id .. ".png")
            if aid and thumb.Parent then thumb.Image = aid end
        end)
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(102, 10); t.Size = UDim2.fromOffset(W - 24 - 102 - 44, 20)
        t.BackgroundTransparency = 1; t.Font = Theme.fonts.body; t.Text = title
        t.TextSize = 13; t.TextColor3 = WHITE; t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd; t.ZIndex = 2; t.Parent = c
        local sub = Instance.new("TextLabel")
        sub.Position = UDim2.fromOffset(102, 32); sub.Size = UDim2.fromOffset(W - 24 - 102 - 44, 16)
        sub.BackgroundTransparency = 1; sub.Font = Theme.fonts.caption
        sub.Text = channel .. (dur and dur > 0 and ("  \195\151  " .. ("%d:%02d"):format(math.floor(dur / 60), dur % 60)) or "")
        sub.TextSize = 11; sub.TextColor3 = SUB; sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd; sub.ZIndex = 2; sub.Parent = c
        local dl = Instance.new("TextButton")
        dl.AnchorPoint = Vector2.new(1, 0.5); dl.Position = UDim2.new(1, -12, 0.5, 0)
        dl.Size = UDim2.fromOffset(30, 30); dl.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
        dl.AutoButtonColor = false; dl.Text = ""; dl.BorderSizePixel = 0; dl.ZIndex = 2; dl.Parent = c
        Util.corner(dl, 8)
        local dlIc = Instance.new("ImageLabel")
        dlIc.AnchorPoint = Vector2.new(0.5, 0.5); dlIc.Position = UDim2.fromScale(0.5, 0.5)
        dlIc.Size = UDim2.fromOffset(15, 15); dlIc.BackgroundTransparency = 1
        dlIc.ImageColor3 = RED; dlIc.ZIndex = 3; dlIc.Parent = dl
        loadIcon(dlIc, "download", RED)

        local busy = false
        dl.MouseButton1Click:Connect(function()
            if busy then return end
            busy = true
            sub.Text = "Downloading audio..."; sub.TextColor3 = RED
            task.spawn(function()
                local yurl = "https://www.youtube.com/watch?v=" .. id
                local mp3url = ytAudioUrl(yurl)
                if not mp3url then
                    sub.Text = "Audio service unavailable, try again"; sub.TextColor3 = Color3.fromRGB(240, 160, 90)
                    busy = false; return
                end
                local ok, data = pcall(function() return game:HttpGet(mp3url, true) end)
                if ok and data and #data > 2000 then
                    pcall(function() writefile(SND_DIR .. "/" .. safeName(title) .. ".mp3", data) end)
                    sub.Text = "Downloaded to library"; sub.TextColor3 = Color3.fromRGB(120, 210, 150)
                else
                    sub.Text = "Download failed, try again"; sub.TextColor3 = Color3.fromRGB(240, 160, 90)
                end
                busy = false
            end)
        end)
    end

    local searching = false
    local function doSearch()
        local q = sBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if q == "" or searching then return end
        searching = true
        clearResults()
        status.Text = "Searching..."
        status.Visible = true
        task.spawn(function()
            -- a pasted link -> single result for that id
            local direct = ytId(q)
            if q:find("youtu") and direct then
                status.Visible = false
                resultCard(1, direct, "Video from link", "Paste  \195\151  tap download", 0)
                searching = false
                return
            end
            local items = ytSearch(q)
            if not items then
                status.Text = "Couldn't reach search. Try again in a moment."
                searching = false
                return
            end
            status.Visible = false
            local n = 0
            for _, it in ipairs(items) do
                local id = ytId(it.url or "")
                if id then
                    n = n + 1
                    resultCard(n, id, it.title or "Untitled", it.uploaderName or "Unknown", it.duration or 0)
                    if n >= 20 then break end
                end
            end
            if n == 0 then status.Text = "No results."; status.Visible = true end
            searching = false
        end)
    end
    sBtn.MouseButton1Click:Connect(doSearch)
    sBox.FocusLost:Connect(function(enter) if enter then doSearch() end end)

    return { close = close }
end

function Music.open()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    if host:FindFirstChild("SYNC_Music") then return end

    local cardW, cardH = 560, 440
    local TB = 38

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Music"
    Util.mount(gui)
    Music._gui = gui

    local winRef, scaleRef, closing = nil, nil, false
    local function close()
        if closing then return end
        closing = true
        Music._gui = nil
        if winRef and scaleRef then
            Util.tween(scaleRef, { Scale = 0.94 }, 0.15)
            Util.tween(winRef, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.17, function() gui:Destroy() end)
        else
            gui:Destroy()
        end
    end

    Util.closeOnEscape(gui, close)

    local win = Instance.new("TextButton")
    win.Text = ""; win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(cardW, cardH)
    win.BackgroundColor3 = WIN
    win.BackgroundTransparency = 0.03
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 16)
    Util.stroke(win, WHITE, 1, 0.9)
    Util.shadow(win, { blur = 55, spread = 0, transparency = 0.4, offset = UDim2.fromOffset(0, 22) })
    local winGrad = Instance.new("UIGradient")
    winGrad.Rotation = 120
    winGrad.Color = ColorSequence.new(Color3.fromRGB(24, 26, 34), Color3.fromRGB(12, 12, 15))
    winGrad.Parent = win
    WM.register(gui, win, 16)

    scaleRef = Instance.new("UIScale"); scaleRef.Scale = 0.94; scaleRef.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleRef, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0.03 }, 0.18)
    winRef = win

    -- title bar (traffic lights only, draggable, red closes)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = BAR
    bar.BackgroundTransparency = 0.15
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local bc = Instance.new("UICorner")
    local okc = pcall(function()
        bc.TopLeftRadius = UDim.new(0, 16); bc.TopRightRadius = UDim.new(0, 16)
        bc.BottomLeftRadius = UDim.new(0, 0); bc.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okc then bc.CornerRadius = UDim.new(0, 16) end
    bc.Parent = bar
    for i, col in ipairs({ Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }) do
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
    Util.draggable(win, bar)
    Util.persistPosition(win, "MusicWin")

    -- app header: music mark + "Music" + subtitle + "+"
    local hIcon = Instance.new("ImageLabel")
    hIcon.Size = UDim2.fromOffset(20, 20)
    hIcon.Position = UDim2.fromOffset(20, TB + 16)
    hIcon.BackgroundTransparency = 1
    hIcon.ImageColor3 = WHITE
    hIcon.ZIndex = 3
    hIcon.Parent = win
    loadIcon(hIcon, "music", WHITE)

    local hTitle = Instance.new("TextLabel")
    hTitle.Text = "Music"
    hTitle.Position = UDim2.fromOffset(48, TB + 12)
    hTitle.Size = UDim2.fromOffset(240, 22)
    hTitle.BackgroundTransparency = 1
    hTitle.Font = Theme.fonts.title
    hTitle.TextSize = 18
    hTitle.TextColor3 = WHITE
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.ZIndex = 3
    hTitle.Parent = win

    local hSub = Instance.new("TextLabel")
    hSub.Text = "Connect Spotify"
    hSub.Position = UDim2.fromOffset(48, TB + 35)
    hSub.Size = UDim2.fromOffset(300, 18)
    hSub.BackgroundTransparency = 1
    hSub.Font = Theme.fonts.caption
    hSub.TextSize = 13
    hSub.TextColor3 = SUB
    hSub.TextXAlignment = Enum.TextXAlignment.Left
    hSub.TextTruncate = Enum.TextTruncate.AtEnd
    hSub.ZIndex = 3
    hSub.Parent = win

    local plus = Instance.new("TextButton")
    plus.AnchorPoint = Vector2.new(1, 0)
    plus.Position = UDim2.fromOffset(cardW - 20, TB + 14)
    plus.Size = UDim2.fromOffset(32, 32)
    plus.BackgroundColor3 = CARD
    plus.BackgroundTransparency = 0.2
    plus.AutoButtonColor = false
    plus.Font = Theme.fonts.body
    plus.Text = "+"
    plus.TextSize = 22
    plus.TextColor3 = Color3.fromRGB(180, 180, 188)
    plus.BorderSizePixel = 0
    plus.ZIndex = 3
    plus.Parent = win
    Util.corner(plus, 16)
    Util.stroke(plus, WHITE, 1, 0.85)
    plus.MouseEnter:Connect(function() plus.TextColor3 = WHITE end)
    plus.MouseLeave:Connect(function() plus.TextColor3 = Color3.fromRGB(180, 180, 188) end)

    -- body container (state screens build in here)
    local body = Instance.new("Frame")
    body.Position = UDim2.fromOffset(0, TB + 60)
    body.Size = UDim2.fromOffset(cardW, cardH - TB - 60)
    body.BackgroundTransparency = 1
    body.ZIndex = 3
    body.Parent = win
    local BW, BH = cardW, cardH - TB - 60

    local function clearBody()
        for _, c in ipairs(body:GetChildren()) do c:Destroy() end
    end

    local pollAlive = false
    local showConnect, showPlayer

    -- ================= CONNECT SCREEN =================
    showConnect = function(errMsg)
        pollAlive = false
        clearBody()
        hSub.Text = "Connect Spotify"

        -- soft glow behind the mark
        local glow = Instance.new("ImageLabel")
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Position = UDim2.fromOffset(BW / 2, 30)
        glow.Size = UDim2.fromOffset(180, 180)
        glow.BackgroundTransparency = 1
        glow.ImageColor3 = LINK
        glow.ImageTransparency = 1
        glow.ZIndex = 3
        glow.Parent = body
        task.spawn(function()
            local png = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode(RAW .. "boot-halo.png") .. "&output=png&w=220&h=220"
            local id = Util.remoteImage(png, "music_glow.png")
            if id and glow.Parent then glow.Image = id; Util.tween(glow, { ImageTransparency = 0.5 }, 0.5) end
        end)

        local note = Instance.new("ImageLabel")
        note.AnchorPoint = Vector2.new(0.5, 0)
        note.Position = UDim2.fromOffset(BW / 2, 4)
        note.Size = UDim2.fromOffset(50, 50)
        note.BackgroundTransparency = 1
        note.ImageColor3 = WHITE
        note.ZIndex = 4
        note.Parent = body
        loadIcon(note, "music", WHITE)

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 0)
        title.Position = UDim2.fromOffset(BW / 2, 62)
        title.Size = UDim2.fromOffset(BW, 26)
        title.BackgroundTransparency = 1
        title.Font = Theme.fonts.title
        title.Text = "Connect Spotify"
        title.TextSize = 20
        title.TextColor3 = WHITE
        title.ZIndex = 4
        title.Parent = body

        local desc = Instance.new("TextLabel")
        desc.AnchorPoint = Vector2.new(0.5, 0)
        desc.Position = UDim2.fromOffset(BW / 2, 92)
        desc.Size = UDim2.fromOffset(BW, 18)
        desc.BackgroundTransparency = 1
        desc.Font = Theme.fonts.caption
        desc.Text = "Paste your Spotify OAuth token to get started."
        desc.TextSize = 13
        desc.TextColor3 = SUB
        desc.ZIndex = 4
        desc.Parent = body

        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(30, 130)
        holder.Size = UDim2.fromOffset(BW - 60, 46)
        holder.BackgroundColor3 = FIELD
        holder.BackgroundTransparency = 0.1
        holder.BorderSizePixel = 0
        holder.ClipsDescendants = true
        holder.ZIndex = 4
        holder.Parent = body
        Util.corner(holder, 10)
        local st = Util.stroke(holder, Color3.fromRGB(70, 70, 80), 1, 0.55)
        local box = Instance.new("TextBox")
        box.Position = UDim2.fromOffset(18, 0)
        box.Size = UDim2.fromOffset(BW - 60 - 36, 46)
        box.BackgroundTransparency = 1
        box.Font = Theme.fonts.body
        box.PlaceholderText = "Paste your Spotify token..."
        box.PlaceholderColor3 = DIM
        box.Text = ""
        box.TextSize = 14
        box.TextColor3 = WHITE
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.ZIndex = 5
        box.Parent = holder
        box.Focused:Connect(function() Util.tween(st, { Transparency = 0.1, Color = LINK }, 0.15) end)
        box.FocusLost:Connect(function() Util.tween(st, { Transparency = 0.55, Color = Color3.fromRGB(70, 70, 80) }, 0.15) end)

        local btn = Instance.new("TextButton")
        btn.Position = UDim2.fromOffset(30, 188)
        btn.Size = UDim2.fromOffset(BW - 60, 46)
        btn.BackgroundColor3 = BLUE
        btn.AutoButtonColor = false
        btn.Font = Theme.fonts.title
        btn.Text = "Connect"
        btn.TextSize = 16
        btn.TextColor3 = WHITE
        btn.BorderSizePixel = 0
        btn.ZIndex = 4
        btn.Parent = body
        Util.corner(btn, 10)
        local btnGrad = Instance.new("UIGradient")
        btnGrad.Rotation = 90
        btnGrad.Color = ColorSequence.new(Color3.fromRGB(72, 104, 165), BLUE)
        btnGrad.Parent = btn
        Util.shadow(btn, { blur = 24, transparency = 0.6, offset = UDim2.fromOffset(0, 6), color = Color3.fromRGB(30, 50, 90) })
        btn.MouseEnter:Connect(function() Util.tween(btn, { BackgroundColor3 = BLUEH }, 0.12) end)
        btn.MouseLeave:Connect(function() Util.tween(btn, { BackgroundColor3 = BLUE }, 0.12) end)

        local link = Instance.new("TextButton")
        link.AnchorPoint = Vector2.new(0.5, 0)
        link.Position = UDim2.fromOffset(BW / 2, 246)
        link.Size = UDim2.fromOffset(BW, 20)
        link.BackgroundTransparency = 1
        link.AutoButtonColor = false
        link.Font = Theme.fonts.body
        link.Text = "How to get a token"
        link.TextSize = 13
        link.TextColor3 = LINK
        link.ZIndex = 4
        link.Parent = body

        if errMsg then
            desc.Text = errMsg
            desc.TextColor3 = Color3.fromRGB(255, 110, 120)
        end

        local connecting = false
        local function doConnect()
            local token = box.Text:gsub("%s+", "")
            token = token:gsub("^Bearer ", "")
            if token == "" then return end
            if connecting then return end
            connecting = true
            btn.Text = "Connecting..."
            task.spawn(function()
                local bodyStr, status = spotify("GET", "/me", token)
                if status == 200 then
                    Util.save(TOKEN_KEY, token)
                    showPlayer(token)
                else
                    btn.Text = "Connect"
                    connecting = false
                    desc.Text = (status == 401 and "That token is invalid or expired.")
                        or (status == 0 and "Couldn't reach Spotify. Check your connection.")
                        or ("Spotify returned an error (" .. tostring(status) .. ").")
                    desc.TextColor3 = Color3.fromRGB(255, 110, 120)
                end
            end)
        end
        btn.MouseButton1Click:Connect(doConnect)
        box.FocusLost:Connect(function(enter) if enter then doConnect() end end)

        link.MouseButton1Click:Connect(function()
            desc.TextColor3 = SUB
            desc.Text = "Open the Spotify web player, then copy your Bearer access token from the network requests to api.spotify.com."
        end)
    end

    -- ================= PLAYER SCREEN =================
    showPlayer = function(token)
        clearBody()
        hSub.Text = "Loading..."

        -- faint blurred album-art backdrop (premium depth)
        local backdrop = Instance.new("ImageLabel")
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
        backdrop.BackgroundTransparency = 1
        backdrop.BorderSizePixel = 0
        backdrop.ScaleType = Enum.ScaleType.Crop
        backdrop.ImageTransparency = 1
        backdrop.ZIndex = 1
        backdrop.Parent = body
        local bkc = Instance.new("UICorner")
        local okbk = pcall(function()
            bkc.BottomLeftRadius = UDim.new(0, 16); bkc.BottomRightRadius = UDim.new(0, 16)
            bkc.TopLeftRadius = UDim.new(0, 0); bkc.TopRightRadius = UDim.new(0, 0)
        end)
        if not okbk then bkc.CornerRadius = UDim.new(0, 16) end
        bkc.Parent = backdrop
        local backdropDim = Instance.new("Frame")
        backdropDim.Size = UDim2.fromScale(1, 1)
        backdropDim.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
        backdropDim.BackgroundTransparency = 0.12
        backdropDim.BorderSizePixel = 0
        backdropDim.ZIndex = 2
        backdropDim.Parent = body
        local ddg = Instance.new("UIGradient")
        ddg.Rotation = 90
        ddg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(1, 0.0),
        })
        ddg.Parent = backdropDim
        local bkc2 = bkc:Clone(); bkc2.Parent = backdropDim

        -- album art
        local art = Instance.new("ImageLabel")
        art.Position = UDim2.fromOffset(30, 10)
        art.Size = UDim2.fromOffset(130, 130)
        art.BackgroundColor3 = CARD
        art.BorderSizePixel = 0
        art.ScaleType = Enum.ScaleType.Crop
        art.ZIndex = 4
        art.Parent = body
        Util.corner(art, 12)
        Util.shadow(art, { blur = 30, transparency = 0.5, offset = UDim2.fromOffset(0, 8) })

        local track = Instance.new("TextLabel")
        track.Position = UDim2.fromOffset(180, 22)
        track.Size = UDim2.fromOffset(BW - 210, 26)
        track.BackgroundTransparency = 1
        track.Font = Theme.fonts.title
        track.Text = "Nothing playing"
        track.TextSize = 19
        track.TextColor3 = WHITE
        track.TextXAlignment = Enum.TextXAlignment.Left
        track.TextTruncate = Enum.TextTruncate.AtEnd
        track.ZIndex = 4
        track.Parent = body

        local artist = Instance.new("TextLabel")
        artist.Position = UDim2.fromOffset(180, 50)
        artist.Size = UDim2.fromOffset(BW - 210, 20)
        artist.BackgroundTransparency = 1
        artist.Font = Theme.fonts.body
        artist.Text = "Open Spotify and press play"
        artist.TextSize = 14
        artist.TextColor3 = SUB
        artist.TextXAlignment = Enum.TextXAlignment.Left
        artist.TextTruncate = Enum.TextTruncate.AtEnd
        artist.ZIndex = 4
        artist.Parent = body

        -- progress bar
        local barBg = Instance.new("Frame")
        barBg.Position = UDim2.fromOffset(180, 90)
        barBg.Size = UDim2.fromOffset(BW - 210, 4)
        barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
        barBg.BorderSizePixel = 0
        barBg.ZIndex = 4
        barBg.Parent = body
        Util.corner(barBg, 2)
        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = LINK
        barFill.BorderSizePixel = 0
        barFill.ZIndex = 5
        barFill.Parent = barBg
        Util.corner(barFill, 2)
        local tCur = Instance.new("TextLabel")
        tCur.Position = UDim2.fromOffset(180, 100)
        tCur.Size = UDim2.fromOffset(60, 16)
        tCur.BackgroundTransparency = 1
        tCur.Font = Theme.fonts.caption
        tCur.Text = "0:00"
        tCur.TextSize = 11
        tCur.TextColor3 = DIM
        tCur.TextXAlignment = Enum.TextXAlignment.Left
        tCur.ZIndex = 4
        tCur.Parent = body
        local tEnd = Instance.new("TextLabel")
        tEnd.AnchorPoint = Vector2.new(1, 0)
        tEnd.Position = UDim2.fromOffset(BW - 30, 100)
        tEnd.Size = UDim2.fromOffset(60, 16)
        tEnd.BackgroundTransparency = 1
        tEnd.Font = Theme.fonts.caption
        tEnd.Text = "0:00"
        tEnd.TextSize = 11
        tEnd.TextColor3 = DIM
        tEnd.TextXAlignment = Enum.TextXAlignment.Right
        tEnd.ZIndex = 4
        tEnd.Parent = body

        -- controls
        local ctrlY = 175
        local function ctrlBtn(cx, size, icon)
            local b = Instance.new("TextButton")
            b.AnchorPoint = Vector2.new(0.5, 0.5)
            b.Position = UDim2.fromOffset(cx, ctrlY)
            b.Size = UDim2.fromOffset(size, size)
            b.BackgroundTransparency = 1
            b.AutoButtonColor = false
            b.Text = ""
            b.ZIndex = 4
            b.Parent = body
            local ic = Instance.new("ImageLabel")
            ic.AnchorPoint = Vector2.new(0.5, 0.5)
            ic.Position = UDim2.fromScale(0.5, 0.5)
            ic.Size = UDim2.fromOffset(math.floor(size * 0.55), math.floor(size * 0.55))
            ic.BackgroundTransparency = 1
            ic.ImageColor3 = WHITE
            ic.ZIndex = 5
            ic.Parent = b
            loadIcon(ic, icon, WHITE)
            return b, ic
        end
        local cx = BW / 2
        local prevBtn = ctrlBtn(cx - 78, 40, "skip-back")
        local playWrap = Instance.new("Frame")
        playWrap.AnchorPoint = Vector2.new(0.5, 0.5)
        playWrap.Position = UDim2.fromOffset(cx, ctrlY)
        playWrap.Size = UDim2.fromOffset(58, 58)
        playWrap.BackgroundColor3 = WHITE
        playWrap.BorderSizePixel = 0
        playWrap.ZIndex = 4
        playWrap.Parent = body
        Util.corner(playWrap, 29)
        Util.shadow(playWrap, { blur = 26, transparency = 0.55, offset = UDim2.fromOffset(0, 5) })
        local playBtn = Instance.new("TextButton")
        playBtn.Size = UDim2.fromScale(1, 1)
        playBtn.BackgroundTransparency = 1
        playBtn.AutoButtonColor = false
        playBtn.Text = ""
        playBtn.ZIndex = 5
        playBtn.Parent = playWrap
        local playIc = Instance.new("ImageLabel")
        playIc.AnchorPoint = Vector2.new(0.5, 0.5)
        playIc.Position = UDim2.fromScale(0.5, 0.5)
        playIc.Size = UDim2.fromOffset(26, 26)
        playIc.BackgroundTransparency = 1
        playIc.ImageColor3 = Color3.fromRGB(16, 16, 20)
        playIc.ZIndex = 6
        playIc.Parent = playWrap
        loadIcon(playIc, "play", Color3.fromRGB(16, 16, 20))
        local nextBtn = ctrlBtn(cx + 78, 40, "skip-forward")

        local isPlaying, curKey = false, ""

        local function control(method, path)
            task.spawn(function() spotify(method, path, token) end)
        end
        prevBtn.MouseButton1Click:Connect(function()
            control("POST", "/me/player/previous"); task.wait(0.4)
        end)
        nextBtn.MouseButton1Click:Connect(function()
            control("POST", "/me/player/next"); task.wait(0.4)
        end)
        playBtn.MouseButton1Click:Connect(function()
            if isPlaying then control("PUT", "/me/player/pause"); isPlaying = false; loadIcon(playIc, "play", Color3.fromRGB(16, 16, 20))
            else control("PUT", "/me/player/play"); isPlaying = true; loadIcon(playIc, "pause", Color3.fromRGB(16, 16, 20)) end
        end)

        -- poll now-playing
        pollAlive = true
        task.spawn(function()
            -- name in the header from /me
            local meBody = spotify("GET", "/me", token)
            if meBody and gui.Parent then
                local ok, me = pcall(function() return HttpService:JSONDecode(meBody) end)
                if ok and me and me.display_name then hSub.Text = me.display_name end
            end
            while pollAlive and gui.Parent do
                local b, status = spotify("GET", "/me/player/currently-playing", token)
                if status == 200 and b and b ~= "" then
                    local ok, data = pcall(function() return HttpService:JSONDecode(b) end)
                    if ok and data and data.item then
                        local it = data.item
                        track.Text = it.name or "Unknown"
                        local names = {}
                        for _, a in ipairs(it.artists or {}) do names[#names + 1] = a.name end
                        artist.Text = table.concat(names, ", ")
                        tCur.Text = mmss(data.progress_ms)
                        tEnd.Text = mmss(it.duration_ms)
                        local frac = (it.duration_ms and it.duration_ms > 0) and (data.progress_ms / it.duration_ms) or 0
                        Util.tween(barFill, { Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0) }, 0.4)
                        isPlaying = data.is_playing and true or false
                        loadIcon(playIc, isPlaying and "pause" or "play", Color3.fromRGB(16, 16, 20))
                        local imgs = it.album and it.album.images
                        if imgs and imgs[1] and it.id ~= curKey then
                            curKey = it.id
                            loadArt(art, imgs[1].url, it.id)
                            task.spawn(function()
                                local burl = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode(imgs[1].url)
                                    .. "&output=png&w=340&h=220&fit=cover&blur=45"
                                local bid = Util.remoteImage(burl, "sp_bg_" .. it.id .. ".png")
                                if bid and backdrop.Parent then backdrop.Image = bid; Util.tween(backdrop, { ImageTransparency = 0.62 }, 0.6) end
                            end)
                        end
                    end
                elseif status == 204 then
                    track.Text = "Nothing playing"
                    artist.Text = "Open Spotify and press play"
                    Util.tween(barFill, { Size = UDim2.new(0, 0, 1, 0) }, 0.3)
                elseif status == 401 then
                    Util.save(TOKEN_KEY, "")
                    showConnect("Your Spotify session expired. Paste a new token.")
                    return
                end
                task.wait(3)
            end
        end)
    end

    -- + button: pick a music source (Spotify is the main screen)
    local menu = Instance.new("Frame")
    menu.AnchorPoint = Vector2.new(1, 0)
    menu.Position = UDim2.fromOffset(cardW - 20, TB + 50)
    menu.Size = UDim2.fromOffset(196, 128)
    menu.BackgroundColor3 = CARD
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.ZIndex = 20
    menu.Parent = win
    Util.corner(menu, 10)
    Util.stroke(menu, WHITE, 1, 0.85)
    Util.shadow(menu, { blur = 30, transparency = 0.4, offset = UDim2.fromOffset(0, 8) })
    local function menuItem(y, label, icon, cb)
        local it = Instance.new("TextButton")
        it.Position = UDim2.fromOffset(6, y)
        it.Size = UDim2.fromOffset(184, 36)
        it.BackgroundColor3 = Color3.fromRGB(44, 44, 52)
        it.BackgroundTransparency = 1
        it.AutoButtonColor = false
        it.Text = ""
        it.ZIndex = 21
        it.Parent = menu
        Util.corner(it, 7)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(16, 16); ic.Position = UDim2.fromOffset(12, 10)
        ic.BackgroundTransparency = 1; ic.ImageColor3 = WHITE; ic.ZIndex = 22; ic.Parent = it
        loadIcon(ic, icon, WHITE)
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(38, 0); t.Size = UDim2.fromOffset(140, 36)
        t.BackgroundTransparency = 1; t.Font = Theme.fonts.body; t.Text = label
        t.TextSize = 14; t.TextColor3 = WHITE; t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 22; t.Parent = it
        it.MouseEnter:Connect(function() Util.tween(it, { BackgroundTransparency = 0.4 }, 0.1) end)
        it.MouseLeave:Connect(function() Util.tween(it, { BackgroundTransparency = 1 }, 0.1) end)
        it.MouseButton1Click:Connect(function() menu.Visible = false; cb() end)
    end
    menuItem(6, "Spotify", "music", function() end)
    menuItem(44, "MP3 Player", "disc-3", function() Music.openMP3() end)
    menuItem(84, "YouTube", "youtube", function() Music.openYT() end)

    plus.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
    win.MouseButton1Click:Connect(function() if menu.Visible then menu.Visible = false end end)

    -- open: reconnect with a saved token, else show connect
    local saved = Util.load(TOKEN_KEY)
    if saved and saved ~= "" then
        showConnect() -- render immediately, then verify + swap to player
        task.spawn(function()
            local _, status = spotify("GET", "/me", saved)
            if status == 200 and gui.Parent then showPlayer(saved) end
        end)
    else
        showConnect()
    end

    return { close = close }
end

return Music
end)

SYNC.define("apps/Scripts", function()
-- SYNC / apps / Scripts
-- Novoline-style script browser fed by rscripts.net (fixed source, no site
-- switcher): header + big search field, "Recent uploads" status line, and a
-- two-column grid of banner cards. Card art is the orca wallpaper set
-- (rbxassetid, hashed per title) with a dark fade behind the script title,
-- game name and a VERIFIED pill. Clicking a card fetches rawScript and runs it.

local HttpService = game:GetService("HttpService")

local Theme    = SYNC.import("core/Theme")
local Util     = SYNC.import("core/Util")
local Icons    = SYNC.import("core/Icons")
local Executor = SYNC.import("core/Executor")
local WM       = SYNC.import("os/WindowManager")

local Scripts = {}

local WHITE   = Color3.fromRGB(255, 255, 255)
local SUB     = Color3.fromRGB(142, 142, 147)
local WIN     = Color3.fromRGB(14, 15, 17)
local CARD    = Color3.fromRGB(22, 23, 26)
local FIELD   = Color3.fromRGB(30, 31, 35)
local BLURPLE = Color3.fromRGB(88, 101, 242)
local GREEN   = Color3.fromRGB(62, 209, 148)
local RED     = Color3.fromRGB(255, 95, 87)

local TITLE_FONT = Enum.Font.GothamBlack
local BODY_BOLD  = Enum.Font.GothamBold

local API = "https://rscripts.net/api/v2"

-- orca's Scripts-page wallpaper set (the same art Novoline reuses)
local BANNERS = {
    "rbxassetid://8992292705",
    "rbxassetid://8992292381",
    "rbxassetid://8992291779",
    "rbxassetid://8992291444",
    "rbxassetid://8992290931",
    "rbxassetid://8992290714",
    "rbxassetid://8992290314",
}

local function hashStr(s)
    local h = 0
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 2^31 end
    return h
end

-- 716426 -> "716K", 1240000 -> "1.2M"
local function formatCount(n)
    n = tonumber(n) or 0
    if n >= 1e6 then
        return string.format("%.1fM", n / 1e6):gsub("%.0M", "M")
    elseif n >= 1e3 then
        return string.format("%.0fK", n / 1e3)
    end
    return tostring(math.floor(n))
end

-- ISO date string -> "3d ago" / "1mo ago" / "2y ago"
local function relativeAge(iso)
    if type(iso) ~= "string" then return "" end
    local y, mo, d = iso:match("(%d+)-(%d+)-(%d+)")
    if not y then return "" end
    local t = os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = 12 })
    local secs = os.time() - t
    if secs < 0 then secs = 0 end
    local day = 86400
    if secs < day then return "today" end
    if secs < 30 * day then return math.floor(secs / day) .. "d ago" end
    if secs < 365 * day then return math.floor(secs / (30 * day)) .. "mo ago" end
    return math.floor(secs / (365 * day)) .. "y ago"
end

-- Roblox can't decode rscripts' .webp, so route it through images.weserv.nl
-- which returns a PNG that getcustomasset can load.
local function weservPng(imgUrl, w)
    return "https://images.weserv.nl/?url="
        .. game:GetService("HttpService"):UrlEncode(tostring(imgUrl))
        .. "&output=png&w=" .. (w or 768)
end

-- Load an SVG icon as a PNG the client can render: weserv rasterises the SVG,
-- getcustomasset loads it. lucide icons render BLACK, and ImageColor3 can't
-- lighten black (multiply), so invert=true runs weserv's negate filter to make
-- them white first; then the tint applies. Async: fills `img` once ready.
local function loadSvgIcon(img, svgUrl, filename, tint, invert)
    task.spawn(function()
        local pngUrl = "https://images.weserv.nl/?url="
            .. game:GetService("HttpService"):UrlEncode(svgUrl) .. "&output=png&w=64&h=64"
        if invert then pngUrl = pngUrl .. "&filt=negate" end
        local id = SYNC.import("core/Util").remoteImage(pngUrl, filename)
        if id and img and img.Parent then
            img.Image = id
            img.ImageRectOffset = Vector2.new(0, 0)
            img.ImageRectSize = Vector2.new(0, 0)
            img.ImageColor3 = tint or Color3.fromRGB(255, 255, 255)
        end
    end)
end

Scripts._gui = nil

function Scripts.open()
    if Scripts._gui and Scripts._gui.Parent then return end
    Scripts._gui = nil

    local winW, winH = 880, 600
    local TB = 40
    local PAD = 24

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Scripts"
    Util.mount(gui)
    Scripts._gui = gui

    local alive = true
    local winRef, scaleRef

    local closing = false
    local function close()
        if not Scripts._gui or closing then return end
        closing = true
        Scripts._gui = nil
        alive = false
        if winRef and scaleRef then
            Util.tween(scaleRef, { Scale = 0.94 }, 0.15)
            Util.tween(winRef, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.17, function() gui:Destroy() end)
        else
            gui:Destroy()
        end
    end

    -- forward-declared so Escape can close the detail view first (assigned below)
    local detailLayer, closeDetail
    Util.closeOnEscape(gui, function()
        if detailLayer then closeDetail() else close() end
    end)

    local win = Instance.new("TextButton")
    win.Text = ""
    win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5) -- persistPosition (below) overrides
    win.Size = UDim2.fromOffset(winW, winH)
    win.BackgroundColor3 = WIN
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 16)
    Util.stroke(win, WHITE, 1, 0.88)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })
    WM.register(gui, win, 16)

    local scaleFx = Instance.new("UIScale")
    scaleFx.Scale = 0.94
    scaleFx.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleFx, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0 }, 0.18)
    winRef, scaleRef = win, scaleFx

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = CARD
    bar.BackgroundTransparency = 0.35
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local barCorner = Instance.new("UICorner")
    local okCorner = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 16)
        barCorner.TopRightRadius = UDim.new(0, 16)
        barCorner.BottomLeftRadius = UDim.new(0, 0)
        barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okCorner then barCorner.CornerRadius = UDim.new(0, 16) end
    barCorner.Parent = bar

    local lights = { Theme.red, Theme.yellow, Theme.green }
    local lightGlyphs = { "x", "minus", "plus" }
    local trafficGlyphs = {}
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
        -- symbol revealed on hover over the cluster (macOS style)
        local gl = Instance.new("ImageLabel")
        gl.Size = UDim2.fromOffset(8, 8)
        gl.AnchorPoint = Vector2.new(0.5, 0.5)
        gl.Position = UDim2.fromScale(0.5, 0.5)
        gl.BackgroundTransparency = 1
        gl.ImageTransparency = 1
        gl.ZIndex = 5
        gl.Parent = dot
        Icons.apply(gl, lightGlyphs[i], Color3.fromRGB(60, 40, 10))
        trafficGlyphs[i] = gl
        if i == 1 then dot.MouseButton1Click:Connect(close) end
        if i == 3 then
            dot.MouseButton1Click:Connect(function()
                Util.tween(win, { Position = UDim2.fromScale(0.5, 0.5) }, 0.3, Enum.EasingStyle.Quint)
            end)
        end
    end
    bar.MouseEnter:Connect(function()
        for _, gl in ipairs(trafficGlyphs) do Util.tween(gl, { ImageTransparency = 0.15 }, 0.12) end
    end)
    bar.MouseLeave:Connect(function()
        for _, gl in ipairs(trafficGlyphs) do Util.tween(gl, { ImageTransparency = 1 }, 0.12) end
    end)

    Util.draggable(win, bar)
    Util.persistPosition(win, "ScriptsWin")

    local barTitle = Instance.new("TextLabel")
    barTitle.Size = UDim2.new(1, 0, 1, 0)
    barTitle.BackgroundTransparency = 1
    barTitle.Text = "Scripts"
    barTitle.Font = Theme.fonts.title
    barTitle.TextSize = 14
    barTitle.TextColor3 = Color3.fromRGB(200, 200, 206)
    barTitle.ZIndex = 3
    barTitle.Parent = bar

    -- Header: icon + "Scripts" + sub
    local headIcon = Instance.new("ImageLabel")
    headIcon.Size = UDim2.fromOffset(26, 26)
    headIcon.Position = UDim2.fromOffset(PAD, TB + 20)
    headIcon.BackgroundTransparency = 1
    headIcon.ZIndex = 3
    headIcon.Parent = win
    Icons.apply(headIcon, "file-text", WHITE)

    local head = Instance.new("TextLabel")
    head.Text = "Scripts"
    head.Font = TITLE_FONT
    head.TextSize = 24
    head.TextColor3 = WHITE
    head.TextXAlignment = Enum.TextXAlignment.Left
    head.BackgroundTransparency = 1
    head.Position = UDim2.fromOffset(PAD + 36, TB + 18)
    head.Size = UDim2.fromOffset(300, 30)
    head.ZIndex = 3
    head.Parent = win

    local headSub = Instance.new("TextLabel")
    headSub.Text = "Search scripts"
    headSub.Font = Theme.fonts.caption
    headSub.TextSize = 13
    headSub.TextColor3 = SUB
    headSub.TextXAlignment = Enum.TextXAlignment.Left
    headSub.BackgroundTransparency = 1
    headSub.Position = UDim2.fromOffset(PAD, TB + 52)
    headSub.Size = UDim2.fromOffset(300, 16)
    headSub.ZIndex = 3
    headSub.Parent = win

    -- Search field
    local search = Instance.new("Frame")
    search.Position = UDim2.fromOffset(PAD, TB + 80)
    search.Size = UDim2.new(1, -PAD * 2, 0, 52)
    search.BackgroundColor3 = FIELD
    search.BackgroundTransparency = 0.2
    search.BorderSizePixel = 0
    search.ZIndex = 3
    search.Parent = win
    Util.corner(search, 14)
    local searchStroke = Util.stroke(search, WHITE, 1, 0.9)

    local searchBox = Instance.new("TextBox")
    searchBox.PlaceholderText = "Search scripts..."
    searchBox.PlaceholderColor3 = SUB
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.Font = Theme.fonts.body
    searchBox.TextSize = 16
    searchBox.TextColor3 = WHITE
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.BackgroundTransparency = 1
    searchBox.Position = UDim2.fromOffset(20, 0)
    searchBox.Size = UDim2.new(1, -60, 1, 0)
    searchBox.ZIndex = 4
    searchBox.Parent = search

    local searchGlyph = Instance.new("ImageLabel")
    searchGlyph.Size = UDim2.fromOffset(18, 18)
    searchGlyph.AnchorPoint = Vector2.new(1, 0.5)
    searchGlyph.Position = UDim2.new(1, -18, 0.5, 0)
    searchGlyph.BackgroundTransparency = 1
    searchGlyph.ZIndex = 4
    searchGlyph.Parent = search
    Icons.apply(searchGlyph, "search", BLURPLE)

    -- Clear (X) button: appears once there's text, resets back to recent
    local clearBtn = Instance.new("TextButton")
    clearBtn.Text = ""
    clearBtn.AutoButtonColor = false
    clearBtn.Size = UDim2.fromOffset(26, 26)
    clearBtn.AnchorPoint = Vector2.new(1, 0.5)
    clearBtn.Position = UDim2.new(1, -14, 0.5, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(70, 71, 78)
    clearBtn.BackgroundTransparency = 1
    clearBtn.Visible = false
    clearBtn.ZIndex = 5
    clearBtn.Parent = search
    Util.corner(clearBtn, 13)
    local clearGlyph = Instance.new("ImageLabel")
    clearGlyph.Size = UDim2.fromOffset(13, 13)
    clearGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    clearGlyph.Position = UDim2.fromScale(0.5, 0.5)
    clearGlyph.BackgroundTransparency = 1
    clearGlyph.ImageTransparency = 1
    clearGlyph.ZIndex = 6
    clearGlyph.Parent = clearBtn
    Icons.apply(clearGlyph, "x", WHITE)

    -- Status line
    local status = Instance.new("TextLabel")
    status.Text = "Loading recent scripts..."
    status.Font = Theme.fonts.caption
    status.TextSize = 13
    status.TextColor3 = SUB
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(PAD + 6, TB + 156)
    status.Size = UDim2.new(1, -PAD * 2 - 110, 0, 16)
    status.ZIndex = 3
    status.Parent = win

    -- Sort chip (cycles Recent / Popular / Top rated), right of the status row
    local sortChip = Instance.new("TextButton")
    sortChip.AutoButtonColor = false
    sortChip.Text = ""
    sortChip.AnchorPoint = Vector2.new(1, 0.5)
    sortChip.Position = UDim2.new(1, -PAD, 0, TB + 164)
    sortChip.Size = UDim2.fromOffset(104, 24)
    sortChip.BackgroundColor3 = FIELD
    sortChip.BackgroundTransparency = 0.15
    sortChip.ZIndex = 4
    sortChip.Parent = win
    Util.corner(sortChip, 8)
    Util.stroke(sortChip, WHITE, 1, 0.9)
    local sortIconImg = Instance.new("ImageLabel")
    sortIconImg.Size = UDim2.fromOffset(13, 13)
    sortIconImg.AnchorPoint = Vector2.new(0, 0.5)
    sortIconImg.Position = UDim2.new(0, 9, 0.5, 0)
    sortIconImg.BackgroundTransparency = 1
    sortIconImg.ZIndex = 5
    sortIconImg.Parent = sortChip
    Icons.apply(sortIconImg, "sliders-horizontal", SUB)
    local sortChipLabel = Instance.new("TextLabel")
    sortChipLabel.Text = "Recent"
    sortChipLabel.Font = BODY_BOLD
    sortChipLabel.TextSize = 12
    sortChipLabel.TextColor3 = Color3.fromRGB(210, 210, 216)
    sortChipLabel.TextXAlignment = Enum.TextXAlignment.Left
    sortChipLabel.BackgroundTransparency = 1
    sortChipLabel.Position = UDim2.fromOffset(28, 0)
    sortChipLabel.Size = UDim2.new(1, -32, 1, 0)
    sortChipLabel.ZIndex = 5
    sortChipLabel.Parent = sortChip
    sortChip.MouseEnter:Connect(function()
        Util.tween(sortChip, { BackgroundTransparency = 0 }, 0.12)
    end)
    sortChip.MouseLeave:Connect(function()
        Util.tween(sortChip, { BackgroundTransparency = 0.15 }, 0.12)
    end)

    -- Grid
    local gridY = TB + 182
    local grid = Instance.new("ScrollingFrame")
    grid.Position = UDim2.fromOffset(PAD, gridY)
    grid.Size = UDim2.new(1, -PAD * 2 + 8, 1, -gridY - 16)
    grid.BackgroundTransparency = 1
    grid.BorderSizePixel = 0
    grid.ScrollBarThickness = 0
    grid.ScrollBarImageTransparency = 1
    grid.CanvasSize = UDim2.new()
    grid.ZIndex = 3
    grid.Parent = win

    -- Bottom scroll fade: cards dissolve into the window edge as they scroll off
    local gridFade = Instance.new("Frame")
    gridFade.AnchorPoint = Vector2.new(0.5, 1)
    gridFade.Position = UDim2.new(0.5, 0, 1, 0)
    gridFade.Size = UDim2.new(1, 0, 0, 40)
    gridFade.BackgroundColor3 = WIN
    gridFade.BorderSizePixel = 0
    gridFade.Active = false
    gridFade.ZIndex = 6
    gridFade.Parent = win
    local gridFadeGrad = Instance.new("UIGradient")
    gridFadeGrad.Rotation = 90
    gridFadeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    gridFadeGrad.Parent = gridFade

    -- Top scroll fade: cards dissolve in under the sort row as they scroll up
    local gridFadeTop = Instance.new("Frame")
    gridFadeTop.Position = UDim2.fromOffset(0, gridY - 2)
    gridFadeTop.Size = UDim2.new(1, 0, 0, 26)
    gridFadeTop.BackgroundColor3 = WIN
    gridFadeTop.BorderSizePixel = 0
    gridFadeTop.Active = false
    gridFadeTop.ZIndex = 6
    gridFadeTop.Parent = win
    local gridFadeTopGrad = Instance.new("UIGradient")
    gridFadeTopGrad.Rotation = 90
    gridFadeTopGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(1, 1),
    })
    gridFadeTopGrad.Parent = gridFadeTop

    -- Scroll-to-top button (floats bottom-right, appears once scrolled down)
    local toTop = Instance.new("TextButton")
    toTop.Text = ""
    toTop.AutoButtonColor = false
    toTop.Size = UDim2.fromOffset(36, 36)
    toTop.AnchorPoint = Vector2.new(1, 1)
    toTop.Position = UDim2.new(1, -PAD - 4, 1, -PAD)
    toTop.BackgroundColor3 = FIELD
    toTop.BackgroundTransparency = 1
    toTop.Visible = false
    toTop.ZIndex = 30
    toTop.Parent = win
    Util.corner(toTop, 18)
    Util.stroke(toTop, WHITE, 1, 1)
    local toTopGlyph = Instance.new("ImageLabel")
    toTopGlyph.Size = UDim2.fromOffset(18, 18)
    toTopGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    toTopGlyph.Position = UDim2.fromScale(0.5, 0.5)
    toTopGlyph.BackgroundTransparency = 1
    toTopGlyph.ImageTransparency = 1
    toTopGlyph.ZIndex = 31
    toTopGlyph.Parent = toTop
    Icons.apply(toTopGlyph, "chevron-up", WHITE)
    local toTopShown = false
    local function setToTop(show)
        if show == toTopShown then return end
        toTopShown = show
        toTop.Visible = true
        Util.tween(toTop, { BackgroundTransparency = show and 0.05 or 1 }, 0.15)
        Util.tween(toTopGlyph, { ImageTransparency = show and 0 or 1 }, 0.15)
        if not show then task.delay(0.16, function() if not toTopShown then toTop.Visible = false end end) end
    end
    toTop.MouseButton1Click:Connect(function()
        Util.tween(grid, { CanvasPosition = Vector2.new(0, 0) }, 0.35, Enum.EasingStyle.Quint)
    end)

    -- Empty state (shown when a search returns nothing)
    local emptyState = Instance.new("Frame")
    emptyState.Size = UDim2.fromScale(1, 1)
    emptyState.BackgroundTransparency = 1
    emptyState.Visible = false
    emptyState.ZIndex = 3
    emptyState.Parent = grid
    local emptyIcon = Instance.new("ImageLabel")
    emptyIcon.Size = UDim2.fromOffset(34, 34)
    emptyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    emptyIcon.Position = UDim2.fromScale(0.5, 0.4)
    emptyIcon.BackgroundTransparency = 1
    emptyIcon.ImageTransparency = 0.4
    emptyIcon.ZIndex = 4
    emptyIcon.Parent = emptyState
    Icons.apply(emptyIcon, "search", SUB)
    local emptyText = Instance.new("TextLabel")
    emptyText.Text = "No scripts found"
    emptyText.Font = BODY_BOLD
    emptyText.TextSize = 15
    emptyText.TextColor3 = SUB
    emptyText.BackgroundTransparency = 1
    emptyText.AnchorPoint = Vector2.new(0.5, 0.5)
    emptyText.Position = UDim2.fromScale(0.5, 0.5)
    emptyText.Size = UDim2.new(1, -60, 0, 20)
    emptyText.ZIndex = 4
    emptyText.Parent = emptyState

    -- Loading spinner (shown during the very first fetch, before any cards)
    local loader = Instance.new("ImageLabel")
    loader.Size = UDim2.fromOffset(34, 34)
    loader.AnchorPoint = Vector2.new(0.5, 0.5)
    loader.Position = UDim2.fromScale(0.5, 0.42)
    loader.BackgroundTransparency = 1
    loader.ImageTransparency = 0.3
    loader.Visible = false
    loader.ZIndex = 4
    loader.Parent = grid
    Icons.apply(loader, "orbit", BLURPLE)
    do
        local TweenService = game:GetService("TweenService")
        local spin = TweenService:Create(loader, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
        spin:Play()
    end
    local function setLoading(on)
        loader.Visible = on
    end

    -- 12px inset all around gives the orca hover-grow room inside the scroll clip.
    -- GROW stays under the 14px card gap so a hovered card never covers neighbors.
    local INSET = 12
    local GROW = 12
    local CARD_W = math.floor((winW - PAD * 2 - 14 - INSET * 2) / 2)
    local CARD_H = 150
    local reqToken = 0
    local curQuery = nil
    local curPage = 1
    local maxPages = 1
    local loadingMore = false
    local itemCount = 0
    local ranSet = {} -- rawScript -> true for scripts run this session (badge)

    -- Sort modes cycled by the sort chip
    local SORTS = {
        { key = "date",  label = "Recent",    heading = "Recent uploads" },
        { key = "views", label = "Popular",   heading = "Most viewed" },
        { key = "likes", label = "Top rated", heading = "Top rated" },
    }
    -- restore the last chosen sort (persisted across reopens)
    local sortIdx = 1
    do
        local saved = Util.load("ScriptsSort")
        for i, s in ipairs(SORTS) do
            if s.key == saved then sortIdx = i break end
        end
    end
    local function curSort() return SORTS[sortIdx] end
    sortChipLabel.Text = SORTS[sortIdx].label

    local function statusDefault()
        local count = itemCount > 0 and (" · " .. itemCount .. " shown") or ""
        if curQuery and curQuery ~= "" then
            return "Results for \"" .. curQuery .. "\"" .. count .. " · Powered by RScripts.net"
        end
        return curSort().heading .. count .. " · Powered by RScripts.net"
    end

    -- ------------------------------------------------------------------
    -- Script detail view (opens over the grid on card click)
    -- ------------------------------------------------------------------
    -- detailLayer + closeDetail forward-declared near the top (for Escape)
    closeDetail = function()
        if detailLayer then
            local d = detailLayer
            detailLayer = nil
            Util.tween(d, { BackgroundTransparency = 1 }, 0.15)
            for _, ch in ipairs(d:GetDescendants()) do
                pcall(function()
                    if ch:IsA("GuiObject") then Util.tween(ch, { BackgroundTransparency = 1 }, 0.12) end
                end)
            end
            task.delay(0.16, function() if d and d.Parent then d:Destroy() end end)
        end
    end

    local function pill(parent, w, iconName, text, x)
        local p = Instance.new("Frame")
        p.Size = UDim2.fromOffset(w, 30)
        p.Position = UDim2.fromOffset(x, 0)
        p.BackgroundColor3 = FIELD
        p.BackgroundTransparency = 0.3
        p.ZIndex = 62
        p.Parent = parent
        Util.corner(p, 10)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(14, 14)
        ic.Position = UDim2.fromOffset(12, 8)
        ic.BackgroundTransparency = 1
        ic.ImageColor3 = SUB
        ic.ZIndex = 63
        ic.Parent = p
        if iconName then Icons.apply(ic, iconName, SUB) end
        local t = Instance.new("TextLabel")
        t.Text = text
        t.Font = BODY_BOLD
        t.TextSize = 12
        t.TextColor3 = Color3.fromRGB(215, 215, 220)
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.BackgroundTransparency = 1
        t.Position = UDim2.fromOffset(32, 0)
        t.Size = UDim2.new(1, -38, 1, 0)
        t.ZIndex = 63
        t.Parent = p
        return p, ic
    end

    local function openShare(s)
        local TEAL   = Color3.fromRGB(20, 184, 166)
        local TEALBG = Color3.fromRGB(18, 32, 30)
        local BLACK  = Color3.fromRGB(20, 20, 24)
        local TILE   = Color3.fromRGB(38, 39, 45)
        local MW, pad = 448, 24
        local shareUrl = "https://rscripts.net/script/" .. (s.slug or "")

        local layer = Instance.new("Frame")
        layer.Size = UDim2.fromScale(1, 1)
        layer.BackgroundColor3 = Color3.new(0, 0, 0)
        layer.BackgroundTransparency = 1
        layer.ZIndex = 80
        layer.Parent = win
        Util.tween(layer, { BackgroundTransparency = 0.5 }, 0.15)
        local catch = Instance.new("TextButton")
        catch.Text = ""; catch.AutoButtonColor = false
        catch.Size = UDim2.fromScale(1, 1)
        catch.BackgroundTransparency = 1
        catch.ZIndex = 80
        catch.Parent = layer

        local modal = Instance.new("Frame")
        modal.AnchorPoint = Vector2.new(0.5, 0.5)
        modal.Position = UDim2.fromScale(0.5, 0.5)
        modal.Size = UDim2.fromOffset(MW, 360)
        modal.BackgroundColor3 = Color3.fromRGB(24, 25, 29)
        modal.ZIndex = 81
        modal.Parent = layer
        Util.corner(modal, 20)
        Util.rimStroke(modal, 1, 0.6, 0.95)
        local msc = Instance.new("UIScale"); msc.Scale = 0.9; msc.Parent = modal
        Util.tween(msc, { Scale = 1 }, 0.18, Enum.EasingStyle.Back)

        local function closeShare()
            Util.tween(msc, { Scale = 0.9 }, 0.12)
            Util.tween(layer, { BackgroundTransparency = 1 }, 0.14)
            task.delay(0.15, function() if layer.Parent then layer:Destroy() end end)
        end
        catch.MouseButton1Click:Connect(closeShare)

        -- Header: leading share-icon tile + title + subtitle
        local hicon = Instance.new("Frame")
        hicon.Size = UDim2.fromOffset(48, 48)
        hicon.Position = UDim2.fromOffset(pad, 22)
        hicon.BackgroundColor3 = TILE
        hicon.BackgroundTransparency = 0.15
        hicon.ZIndex = 82
        hicon.Parent = modal
        Util.corner(hicon, 12)
        local hiconG = Instance.new("ImageLabel")
        hiconG.Size = UDim2.fromOffset(22, 22)
        hiconG.AnchorPoint = Vector2.new(0.5, 0.5)
        hiconG.Position = UDim2.fromScale(0.5, 0.5)
        hiconG.BackgroundTransparency = 1
        hiconG.ZIndex = 83
        hiconG.Parent = hicon
        loadSvgIcon(hiconG, "cdn.jsdelivr.net/npm/lucide-static/icons/share-2.svg", "ic_share2w.png", WHITE, true)

        local sh = Instance.new("TextLabel")
        sh.Text = "Share script"
        sh.Font = TITLE_FONT
        sh.TextSize = 22
        sh.TextColor3 = WHITE
        sh.TextXAlignment = Enum.TextXAlignment.Left
        sh.BackgroundTransparency = 1
        sh.Position = UDim2.fromOffset(84, 24)
        sh.Size = UDim2.fromOffset(280, 26)
        sh.ZIndex = 82
        sh.Parent = modal
        local shSub = Instance.new("TextLabel")
        shSub.Text = "Check out " .. (s.title or "this script") .. " on Rscripts"
        shSub.Font = Theme.fonts.caption
        shSub.TextSize = 13
        shSub.TextColor3 = SUB
        shSub.TextXAlignment = Enum.TextXAlignment.Left
        shSub.TextTruncate = Enum.TextTruncate.AtEnd
        shSub.BackgroundTransparency = 1
        shSub.Position = UDim2.fromOffset(84, 50)
        shSub.Size = UDim2.fromOffset(MW - 84 - 56, 18)
        shSub.ZIndex = 82
        shSub.Parent = modal

        local xBtn = Instance.new("TextButton")
        xBtn.Text = ""; xBtn.AutoButtonColor = false
        xBtn.Size = UDim2.fromOffset(34, 34)
        xBtn.AnchorPoint = Vector2.new(1, 0)
        xBtn.Position = UDim2.new(1, -16, 0, 20)
        xBtn.BackgroundColor3 = TILE
        xBtn.BackgroundTransparency = 0.25
        xBtn.ZIndex = 82
        xBtn.Parent = modal
        Util.corner(xBtn, 11)
        local xg = Instance.new("ImageLabel")
        xg.Size = UDim2.fromOffset(14, 14); xg.AnchorPoint = Vector2.new(0.5, 0.5)
        xg.Position = UDim2.fromScale(0.5, 0.5); xg.BackgroundTransparency = 1
        xg.ZIndex = 83; xg.Parent = xBtn
        Icons.apply(xg, "x", SUB)
        xBtn.MouseEnter:Connect(function() Util.tween(xBtn, { BackgroundTransparency = 0 }, 0.12); xg.ImageColor3 = WHITE end)
        xBtn.MouseLeave:Connect(function() Util.tween(xBtn, { BackgroundTransparency = 0.25 }, 0.12); xg.ImageColor3 = SUB end)
        xBtn.MouseButton1Click:Connect(closeShare)

        local via = Instance.new("TextLabel")
        via.Text = "SHARE VIA"
        via.Font = BODY_BOLD
        via.TextSize = 11
        via.TextColor3 = SUB
        via.TextXAlignment = Enum.TextXAlignment.Left
        via.BackgroundTransparency = 1
        via.Position = UDim2.fromOffset(pad, 92)
        via.Size = UDim2.fromOffset(200, 14)
        via.ZIndex = 82
        via.Parent = modal

        -- Social buttons: brand logo on top, label below (all four, incl. X)
        local socials = {
            { name = "X",        slug = "x" },
            { name = "Facebook", slug = "facebook" },
            { name = "Reddit",   slug = "reddit" },
            { name = "Telegram", slug = "telegram" },
        }
        local socY, socH = 114, 66
        local socW = math.floor((MW - pad * 2 - 30) / 4)   -- 3 gaps of 10
        for i, soc in ipairs(socials) do
            local b = Instance.new("TextButton")
            b.Text = ""
            b.AutoButtonColor = false
            b.Size = UDim2.fromOffset(socW, socH)
            b.Position = UDim2.fromOffset(pad + (i - 1) * (socW + 10), socY)
            b.BackgroundColor3 = TILE
            b.BackgroundTransparency = 0.4
            b.ZIndex = 82
            b.Parent = modal
            Util.corner(b, 12)
            local logo = Instance.new("ImageLabel")
            logo.Size = UDim2.fromOffset(22, 22)
            logo.AnchorPoint = Vector2.new(0.5, 0)
            logo.Position = UDim2.new(0.5, 0, 0, 13)
            logo.BackgroundTransparency = 1
            logo.ZIndex = 83
            logo.Parent = b
            loadSvgIcon(logo, "cdn.simpleicons.org/" .. soc.slug .. "/ffffff", "ic_soc_" .. soc.slug .. ".png", WHITE)
            local lbl = Instance.new("TextLabel")
            lbl.Text = soc.name
            lbl.Font = BODY_BOLD
            lbl.TextSize = 12
            lbl.TextColor3 = Color3.fromRGB(200, 200, 208)
            lbl.BackgroundTransparency = 1
            lbl.AnchorPoint = Vector2.new(0.5, 1)
            lbl.Position = UDim2.new(0.5, 0, 1, -9)
            lbl.Size = UDim2.fromOffset(socW - 6, 16)
            lbl.ZIndex = 83
            lbl.Parent = b
            local bScale = Instance.new("UIScale"); bScale.Parent = b
            b.MouseEnter:Connect(function()
                Util.tween(b, { BackgroundTransparency = 0.15 }, 0.12)
                Util.tween(bScale, { Scale = 1.04 }, 0.12, Enum.EasingStyle.Back)
            end)
            b.MouseLeave:Connect(function()
                Util.tween(b, { BackgroundTransparency = 0.4 }, 0.12)
                Util.tween(bScale, { Scale = 1 }, 0.12)
            end)
            b.MouseButton1Click:Connect(function()
                pcall(function() setclipboard(shareUrl) end)
                lbl.Text = "Copied"
                task.delay(1, function() if lbl.Parent then lbl.Text = soc.name end end)
            end)
        end

        -- System share
        local sysY = socY + socH + 14
        local sys = Instance.new("TextButton")
        sys.Text = ""
        sys.AutoButtonColor = false
        sys.Size = UDim2.fromOffset(MW - pad * 2, 56)
        sys.Position = UDim2.fromOffset(pad, sysY)
        sys.BackgroundColor3 = TILE
        sys.BackgroundTransparency = 0.4
        sys.ZIndex = 82
        sys.Parent = modal
        Util.corner(sys, 12)
        local sysTile = Instance.new("Frame")
        sysTile.Size = UDim2.fromOffset(38, 38)
        sysTile.AnchorPoint = Vector2.new(0, 0.5)
        sysTile.Position = UDim2.new(0, 10, 0.5, 0)
        sysTile.BackgroundColor3 = Color3.fromRGB(30, 31, 36)
        sysTile.BackgroundTransparency = 0.2
        sysTile.ZIndex = 83
        sysTile.Parent = sys
        Util.corner(sysTile, 10)
        local sysIcon = Instance.new("ImageLabel")
        sysIcon.Size = UDim2.fromOffset(19, 19)
        sysIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        sysIcon.Position = UDim2.fromScale(0.5, 0.5)
        sysIcon.BackgroundTransparency = 1
        sysIcon.ZIndex = 84
        sysIcon.Parent = sysTile
        loadSvgIcon(sysIcon, "cdn.jsdelivr.net/npm/lucide-static/icons/share-2.svg", "ic_share2w.png", WHITE, true)
        sys.MouseEnter:Connect(function() Util.tween(sys, { BackgroundTransparency = 0.2 }, 0.12) end)
        sys.MouseLeave:Connect(function() Util.tween(sys, { BackgroundTransparency = 0.4 }, 0.12) end)
        local sysT = Instance.new("TextLabel")
        sysT.Text = "System share"
        sysT.Font = BODY_BOLD
        sysT.TextSize = 15
        sysT.TextColor3 = WHITE
        sysT.TextXAlignment = Enum.TextXAlignment.Left
        sysT.BackgroundTransparency = 1
        sysT.Position = UDim2.fromOffset(60, 9)
        sysT.Size = UDim2.fromOffset(320, 18)
        sysT.ZIndex = 83
        sysT.Parent = sys
        local sysS = Instance.new("TextLabel")
        sysS.Text = "Use your device's share sheet"
        sysS.Font = Theme.fonts.caption
        sysS.TextSize = 12
        sysS.TextColor3 = SUB
        sysS.TextXAlignment = Enum.TextXAlignment.Left
        sysS.BackgroundTransparency = 1
        sysS.Position = UDim2.fromOffset(60, 29)
        sysS.Size = UDim2.fromOffset(320, 16)
        sysS.ZIndex = 83
        sysS.Parent = sys
        sys.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(shareUrl) end)
            sysS.Text = "Link copied to clipboard"
            sysS.TextColor3 = TEAL
        end)

        -- OR COPY LINK label
        local orY = sysY + 56 + 16
        local orLbl = Instance.new("TextLabel")
        orLbl.Text = "OR COPY LINK"
        orLbl.Font = BODY_BOLD
        orLbl.TextSize = 11
        orLbl.TextColor3 = SUB
        orLbl.TextXAlignment = Enum.TextXAlignment.Left
        orLbl.BackgroundTransparency = 1
        orLbl.Position = UDim2.fromOffset(pad, orY)
        orLbl.Size = UDim2.fromOffset(200, 14)
        orLbl.ZIndex = 82
        orLbl.Parent = modal

        -- Copy link: plain white pill; click -> teal "Copied!" morph (no hover)
        local clY = orY + 22
        local copyLink = Instance.new("TextButton")
        copyLink.Text = ""
        copyLink.Size = UDim2.fromOffset(MW - pad * 2, 46)
        copyLink.Position = UDim2.fromOffset(pad, clY)
        copyLink.BackgroundColor3 = WHITE
        copyLink.AutoButtonColor = false
        copyLink.ZIndex = 82
        copyLink.Parent = modal
        Util.corner(copyLink, 15)
        local clStroke = Util.stroke(copyLink, TEAL, 1.5, 1) -- hidden until copied
        local clRow = Instance.new("Frame")
        clRow.Size = UDim2.fromScale(1, 1)
        clRow.BackgroundTransparency = 1
        clRow.ZIndex = 83
        clRow.Parent = copyLink
        local clLayout = Instance.new("UIListLayout")
        clLayout.FillDirection = Enum.FillDirection.Horizontal
        clLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        clLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        clLayout.Padding = UDim.new(0, 9)
        clLayout.Parent = clRow
        local clIc = Instance.new("ImageLabel")
        clIc.Size = UDim2.fromOffset(17, 17)
        clIc.BackgroundTransparency = 1
        clIc.ImageColor3 = BLACK
        clIc.LayoutOrder = 1
        clIc.ZIndex = 83
        clIc.Parent = clRow
        loadSvgIcon(clIc, "cdn.jsdelivr.net/npm/lucide-static/icons/link.svg", "ic_linkw.png", BLACK, true)
        local clTxt = Instance.new("TextLabel")
        clTxt.Text = "Copy link"
        clTxt.Font = TITLE_FONT
        clTxt.TextSize = 15
        clTxt.TextColor3 = BLACK
        clTxt.BackgroundTransparency = 1
        clTxt.AutomaticSize = Enum.AutomaticSize.X
        clTxt.Size = UDim2.fromOffset(0, 20)
        clTxt.LayoutOrder = 2
        clTxt.ZIndex = 83
        clTxt.Parent = clRow

        local clScale = Instance.new("UIScale"); clScale.Parent = copyLink
        local clCopied = false
        copyLink.MouseButton1Click:Connect(function()
            if clCopied then return end
            clCopied = true
            pcall(function() setclipboard(shareUrl) end)
            -- morph: white -> dark teal-tinted with a teal ring, link -> check,
            -- text -> teal "Copied!" (matches the reference recording)
            Util.tween(copyLink, { BackgroundColor3 = TEALBG, BackgroundTransparency = 0.08 }, 0.2)
            Util.tween(clStroke, { Transparency = 0.35 }, 0.2)
            Util.tween(clIc, { ImageTransparency = 1 }, 0.09)
            Util.tween(clTxt, { TextTransparency = 1 }, 0.09)
            clScale.Scale = 1.04
            Util.tween(clScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
            task.delay(0.11, function()
                if not copyLink.Parent then return end
                loadSvgIcon(clIc, "cdn.jsdelivr.net/npm/lucide-static/icons/check.svg", "ic_checkw.png", TEAL, true)
                clIc.ImageColor3 = TEAL
                clTxt.Text = "Copied!"
                clTxt.TextColor3 = TEAL
                Util.tween(clIc, { ImageTransparency = 0 }, 0.12)
                Util.tween(clTxt, { TextTransparency = 0 }, 0.12)
            end)
            task.delay(1.35, function()
                if not copyLink.Parent then return end
                Util.tween(copyLink, { BackgroundColor3 = WHITE, BackgroundTransparency = 0 }, 0.2)
                Util.tween(clStroke, { Transparency = 1 }, 0.2)
                Util.tween(clIc, { ImageTransparency = 1 }, 0.09)
                Util.tween(clTxt, { TextTransparency = 1 }, 0.09)
                task.delay(0.11, function()
                    if not copyLink.Parent then return end
                    loadSvgIcon(clIc, "cdn.jsdelivr.net/npm/lucide-static/icons/link.svg", "ic_linkw.png", BLACK, true)
                    clIc.ImageColor3 = BLACK
                    clTxt.Text = "Copy link"
                    clTxt.TextColor3 = BLACK
                    Util.tween(clIc, { ImageTransparency = 0 }, 0.12)
                    Util.tween(clTxt, { TextTransparency = 0 }, 0.12)
                    clCopied = false
                end)
            end)
        end)
    end

    local function showDetail(s, onRan)
        closeDetail()
        local layer = Instance.new("Frame")
        layer.Size = UDim2.new(1, 0, 1, -TB)
        layer.Position = UDim2.fromOffset(0, TB)
        layer.BackgroundColor3 = WIN
        layer.BackgroundTransparency = 1
        layer.ZIndex = 40
        layer.ClipsDescendants = true
        layer.Parent = win
        detailLayer = layer
        Util.tween(layer, { BackgroundTransparency = 0 }, 0.15)

        -- input blocker: without this, clicks on empty detail areas fall through
        -- to the grid cards behind and reopen the detail ("refreshes the menu")
        local blocker = Instance.new("TextButton")
        blocker.Text = ""
        blocker.AutoButtonColor = false
        blocker.Size = UDim2.fromScale(1, 1)
        blocker.BackgroundTransparency = 1
        blocker.ZIndex = 40
        blocker.Parent = layer

        -- bottom fade: content dissolves into the window edge as it scrolls
        local fade = Instance.new("Frame")
        fade.AnchorPoint = Vector2.new(0, 1)
        fade.Position = UDim2.fromScale(0, 1)
        fade.Size = UDim2.new(1, 0, 0, 46)
        fade.BackgroundColor3 = WIN
        fade.BorderSizePixel = 0
        fade.ZIndex = 50
        fade.Active = false
        fade.Parent = layer
        local fadeGrad = Instance.new("UIGradient")
        fadeGrad.Rotation = 90
        fadeGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        fadeGrad.Parent = fade

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.fromScale(1, 1)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 0
        scroll.CanvasSize = UDim2.new()
        scroll.ZIndex = 41
        scroll.Parent = layer
        -- slide-up entrance for the content
        scroll.Position = UDim2.fromOffset(0, 26)
        Util.tween(scroll, { Position = UDim2.fromOffset(0, 0) }, 0.28, Enum.EasingStyle.Quint)
        local pad = 24

        -- Back button
        local back = Instance.new("TextButton")
        back.Text = ""
        back.Size = UDim2.fromOffset(80, 30)
        back.Position = UDim2.fromOffset(pad, 14)
        back.BackgroundColor3 = FIELD
        back.BackgroundTransparency = 0.25
        back.AutoButtonColor = false
        back.ZIndex = 44
        back.Parent = scroll
        Util.corner(back, 10)
        local backIc = Instance.new("ImageLabel")
        backIc.Size = UDim2.fromOffset(13, 13); backIc.Position = UDim2.fromOffset(12, 8)
        backIc.BackgroundTransparency = 1; backIc.ZIndex = 45; backIc.Parent = back
        Icons.apply(backIc, "chevron-left", WHITE)
        local backTxt = Instance.new("TextLabel")
        backTxt.Text = "Back"
        backTxt.Font = BODY_BOLD
        backTxt.TextSize = 13
        backTxt.TextColor3 = WHITE
        backTxt.TextXAlignment = Enum.TextXAlignment.Left
        backTxt.BackgroundTransparency = 1
        backTxt.Position = UDim2.fromOffset(32, 0)
        backTxt.Size = UDim2.new(1, -36, 1, 0)
        backTxt.ZIndex = 45
        backTxt.Parent = back
        back.MouseEnter:Connect(function() Util.tween(back, { BackgroundTransparency = 0.05 }, 0.12) end)
        back.MouseLeave:Connect(function() Util.tween(back, { BackgroundTransparency = 0.25 }, 0.12) end)
        back.MouseButton1Click:Connect(closeDetail)

        -- Banner
        local bannerH = 210
        local banner = Instance.new("ImageLabel")
        banner.Size = UDim2.new(1, -pad * 2, 0, bannerH)
        banner.Position = UDim2.fromOffset(pad, 54)
        banner.BackgroundColor3 = FIELD
        banner.ScaleType = Enum.ScaleType.Crop
        banner.Image = BANNERS[hashStr(s.title or "?") % #BANNERS + 1]
        banner.ZIndex = 41
        banner.Parent = scroll
        -- round only the TOP corners; the bottom is a straight edge the fade
        -- dissolves into the window, so there's no visible boundary down there
        local bCorner = Instance.new("UICorner")
        local okBC = pcall(function()
            bCorner.TopLeftRadius = UDim.new(0, 14)
            bCorner.TopRightRadius = UDim.new(0, 14)
            bCorner.BottomLeftRadius = UDim.new(0, 0)
            bCorner.BottomRightRadius = UDim.new(0, 0)
        end)
        if not okBC then bCorner.CornerRadius = UDim.new(0, 14) end
        bCorner.Parent = banner
        -- bottom fade: the image dissolves fully into the window (transparency 0
        -- = solid window colour at the very bottom, no edge)
        local bannerFade = Instance.new("Frame")
        bannerFade.Size = UDim2.fromScale(1, 1)
        bannerFade.BackgroundColor3 = WIN
        bannerFade.BorderSizePixel = 0
        bannerFade.ZIndex = 42
        bannerFade.Parent = banner
        local bannerFadeGrad = Instance.new("UIGradient")
        bannerFadeGrad.Rotation = 90
        bannerFadeGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.4, 1),
            NumberSequenceKeypoint.new(0.8, 0.35),
            NumberSequenceKeypoint.new(1, 0),
        })
        bannerFadeGrad.Parent = bannerFade
        -- real script art (webp -> weserv PNG), replaces the wallpaper if it loads
        if s.image and tostring(s.image):find("%.webp") then
            task.spawn(function()
                local key = "scrb_" .. (s._id or tostring(hashStr(s.image))) .. ".png"
                local id = Util.remoteImage(weservPng(s.image, 768), key)
                if id and banner.Parent then
                    banner.ImageTransparency = 1
                    banner.Image = id
                    Util.tween(banner, { ImageTransparency = 0 }, 0.3)
                end
            end)
        end

        -- Title + creator
        local title = Instance.new("TextLabel")
        title.Text = s.title or "Untitled"
        title.Font = TITLE_FONT
        title.TextSize = 24
        title.TextColor3 = WHITE
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(pad, 54 + bannerH + 12)
        title.Size = UDim2.new(1, -pad * 2, 0, 28)
        title.ZIndex = 41
        title.Parent = scroll

        local creator = Instance.new("TextLabel")
        creator.Text = "by " .. ((s.user and s.user.username) or "Unknown")
        creator.Font = BODY_BOLD
        creator.TextSize = 13
        creator.TextColor3 = SUB
        creator.TextXAlignment = Enum.TextXAlignment.Left
        creator.BackgroundTransparency = 1
        creator.Position = UDim2.fromOffset(pad, 54 + bannerH + 44)
        creator.Size = UDim2.new(1, -pad * 2, 0, 16)
        creator.ZIndex = 41
        creator.Parent = scroll

        -- Actions: Execute (big) + Copy + Share
        local actY = 54 + bannerH + 74
        local shareW, gap = 50, 10
        local execW = (winW - pad * 2) - shareW - gap

        local exec = Instance.new("TextButton")
        exec.Text = "  Execute"
        exec.Font = TITLE_FONT
        exec.TextSize = 16
        exec.TextColor3 = Color3.fromRGB(10, 24, 16)
        exec.Size = UDim2.fromOffset(execW, 50)
        exec.Position = UDim2.fromOffset(pad, actY)
        exec.BackgroundColor3 = GREEN
        exec.AutoButtonColor = false
        exec.ZIndex = 42
        exec.Parent = scroll
        Util.corner(exec, 15)
        local execIc = Instance.new("ImageLabel")
        execIc.Size = UDim2.fromOffset(18, 18); execIc.AnchorPoint = Vector2.new(1, 0.5)
        execIc.Position = UDim2.new(0.5, -46, 0.5, 0); execIc.BackgroundTransparency = 1
        execIc.ZIndex = 43; execIc.Parent = exec
        Icons.apply(execIc, "chevron-right", Color3.fromRGB(10, 24, 16))

        local execSpin = game:GetService("TweenService"):Create(
            execIc, TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
        local execRunning = false
        local function runScript()
            if execRunning or not s.rawScript then return end
            execRunning = true
            exec.Text = "  Running..."
            Util.tween(exec, { BackgroundColor3 = Color3.fromRGB(46, 150, 108) }, 0.15)
            Icons.apply(execIc, "orbit", Color3.fromRGB(10, 24, 16))
            execSpin:Play()
            status.Text = "Running " .. (s.title or "script") .. "..."
            status.TextColor3 = SUB
            task.spawn(function()
                local ok, err = Executor.runUrl(s.rawScript, s.title)
                execRunning = false
                execSpin:Pause(); execIc.Rotation = 0
                Icons.apply(execIc, "chevron-right", Color3.fromRGB(10, 24, 16))
                exec.Text = "  Execute"
                if ok then
                    Util.tween(exec, { BackgroundColor3 = GREEN }, 0.15)
                    status.Text = "Executed " .. (s.title or "script"); status.TextColor3 = GREEN
                    if s.rawScript then ranSet[s.rawScript] = true end
                    if onRan then pcall(onRan) end
                else
                    Util.tween(exec, { BackgroundColor3 = RED }, 0.15)
                    task.delay(0.7, function() if exec.Parent then Util.tween(exec, { BackgroundColor3 = GREEN }, 0.3) end end)
                    status.Text = (s.title or "script") .. ": " .. tostring(err):sub(1, 90); status.TextColor3 = RED
                end
            end)
        end
        exec.MouseButton1Click:Connect(runScript)
        -- idle hover brighten + press feedback
        local execScale = Instance.new("UIScale"); execScale.Parent = exec
        exec.MouseEnter:Connect(function()
            if not execRunning then Util.tween(exec, { BackgroundColor3 = Color3.fromRGB(86, 224, 160) }, 0.12) end
        end)
        exec.MouseLeave:Connect(function()
            if not execRunning then Util.tween(exec, { BackgroundColor3 = GREEN }, 0.12) end
            Util.tween(execScale, { Scale = 1 }, 0.1)
        end)
        exec.MouseButton1Down:Connect(function() Util.tween(execScale, { Scale = 0.98 }, 0.08) end)
        exec.MouseButton1Up:Connect(function() Util.tween(execScale, { Scale = 1 }, 0.1) end)

        local function sideBtn(x, iconName, cb)
            local b = Instance.new("TextButton")
            b.Text = ""; b.AutoButtonColor = false
            b.Size = UDim2.fromOffset(50, 50)
            b.Position = UDim2.fromOffset(x, actY)
            b.BackgroundColor3 = FIELD
            b.BackgroundTransparency = 0.25
            b.ZIndex = 42
            b.Parent = scroll
            Util.corner(b, 15)
            Util.stroke(b, WHITE, 1, 0.9)
            local g = Instance.new("ImageLabel")
            g.Size = UDim2.fromOffset(20, 20); g.AnchorPoint = Vector2.new(0.5, 0.5)
            g.Position = UDim2.fromScale(0.5, 0.5); g.BackgroundTransparency = 1
            g.ZIndex = 43; g.Parent = b
            Icons.apply(g, iconName, SUB)
            b.MouseEnter:Connect(function() Util.tween(b, { BackgroundTransparency = 0 }, 0.12); g.ImageColor3 = WHITE end)
            b.MouseLeave:Connect(function() Util.tween(b, { BackgroundTransparency = 0.25 }, 0.12); g.ImageColor3 = SUB end)
            b.MouseButton1Click:Connect(cb)
            return b
        end
        local shareBtn = sideBtn(pad + execW + gap, nil, function() openShare(s) end)
        loadSvgIcon(shareBtn:FindFirstChildWhichIsA("ImageLabel"),
            "cdn.jsdelivr.net/npm/lucide-static/icons/share-2.svg", "ic_share2w.png", SUB, true)

        -- Stats chips (real thumbs / eye icons via SVG)
        local statY = actY + 62
        local stats = Instance.new("Frame")
        stats.Size = UDim2.new(1, -pad * 2, 0, 30)
        stats.Position = UDim2.fromOffset(pad, statY)
        stats.BackgroundTransparency = 1
        stats.ZIndex = 41
        stats.Parent = scroll
        local _, likeIc = pill(stats, 60, nil, tostring(s.likes or 0), 0)
        loadSvgIcon(likeIc, "cdn.jsdelivr.net/npm/lucide-static/icons/thumbs-up.svg", "ic_thumbupw.png", SUB, true)
        local _, disIc = pill(stats, 60, nil, tostring(s.dislikes or 0), 68)
        loadSvgIcon(disIc, "cdn.jsdelivr.net/npm/lucide-static/icons/thumbs-down.svg", "ic_thumbdownw.png", SUB, true)
        local _, viewIc = pill(stats, 96, nil, formatCount(s.views or 0), 136)
        loadSvgIcon(viewIc, "cdn.jsdelivr.net/npm/lucide-static/icons/eye.svg", "ic_eyew.png", SUB, true)
        pill(stats, 96, "clock", relativeAge(s.createdAt), 240)

        -- Script Preview
        local prevY = statY + 44
        local prevCard = Instance.new("Frame")
        prevCard.Size = UDim2.new(1, -pad * 2, 0, 190)
        prevCard.Position = UDim2.fromOffset(pad, prevY)
        prevCard.BackgroundColor3 = Color3.fromRGB(18, 19, 22)
        prevCard.ZIndex = 41
        prevCard.Parent = scroll
        Util.corner(prevCard, 14)
        Util.stroke(prevCard, WHITE, 1, 0.92)

        local prevTitle = Instance.new("TextLabel")
        prevTitle.Text = "Script Preview"
        prevTitle.Font = TITLE_FONT
        prevTitle.TextSize = 15
        prevTitle.TextColor3 = WHITE
        prevTitle.TextXAlignment = Enum.TextXAlignment.Left
        prevTitle.BackgroundTransparency = 1
        prevTitle.Position = UDim2.fromOffset(16, 12)
        prevTitle.Size = UDim2.fromOffset(200, 18)
        prevTitle.ZIndex = 42
        prevTitle.Parent = prevCard
        local prevMeta = Instance.new("TextLabel")
        prevMeta.Text = "loading..."
        prevMeta.Font = Theme.fonts.caption
        prevMeta.TextSize = 11
        prevMeta.TextColor3 = SUB
        prevMeta.TextXAlignment = Enum.TextXAlignment.Left
        prevMeta.BackgroundTransparency = 1
        prevMeta.Position = UDim2.fromOffset(16, 30)
        prevMeta.Size = UDim2.fromOffset(200, 14)
        prevMeta.ZIndex = 42
        prevMeta.Parent = prevCard

        -- Copy button in the preview header (copies the raw source)
        local previewSrc
        local prevCopy = Instance.new("TextButton")
        prevCopy.Text = ""
        prevCopy.AutoButtonColor = false
        prevCopy.AnchorPoint = Vector2.new(1, 0)
        prevCopy.Position = UDim2.new(1, -14, 0, 12)
        prevCopy.Size = UDim2.fromOffset(78, 28)
        prevCopy.BackgroundColor3 = FIELD
        prevCopy.BackgroundTransparency = 0.3
        prevCopy.ZIndex = 43
        prevCopy.Parent = prevCard
        Util.corner(prevCopy, 8)
        local prevCopyIc = Instance.new("ImageLabel")
        prevCopyIc.Size = UDim2.fromOffset(13, 13); prevCopyIc.Position = UDim2.fromOffset(14, 8)
        prevCopyIc.BackgroundTransparency = 1; prevCopyIc.ZIndex = 44; prevCopyIc.Parent = prevCopy
        local prevCopyTxt = Instance.new("TextLabel")
        prevCopyTxt.Text = "Copy"
        prevCopyTxt.Font = BODY_BOLD
        prevCopyTxt.TextSize = 12
        prevCopyTxt.TextColor3 = Color3.fromRGB(210, 210, 216)
        prevCopyTxt.TextXAlignment = Enum.TextXAlignment.Left
        prevCopyTxt.BackgroundTransparency = 1
        prevCopyTxt.Position = UDim2.fromOffset(35, 0)
        prevCopyTxt.Size = UDim2.new(1, -38, 1, 0)
        prevCopyTxt.ZIndex = 44
        prevCopyTxt.Parent = prevCopy
        loadSvgIcon(prevCopyIc, "cdn.jsdelivr.net/npm/lucide-static/icons/copy.svg", "ic_copyw.png", SUB, true)
        prevCopy.MouseEnter:Connect(function() Util.tween(prevCopy, { BackgroundTransparency = 0 }, 0.12) end)
        prevCopy.MouseLeave:Connect(function() Util.tween(prevCopy, { BackgroundTransparency = 0.3 }, 0.12) end)
        prevCopy.MouseButton1Click:Connect(function()
            if not previewSrc then return end
            pcall(function() setclipboard(previewSrc) end)
            prevCopyTxt.Text = "Copied"
            -- stretch so the longer label reads properly, then settle back
            Util.tween(prevCopy, { Size = UDim2.fromOffset(92, 28) }, 0.18, Enum.EasingStyle.Back)
            task.delay(1, function()
                if prevCopy.Parent then
                    prevCopyTxt.Text = "Copy"
                    Util.tween(prevCopy, { Size = UDim2.fromOffset(78, 28) }, 0.18)
                end
            end)
        end)

        local codeBox = Instance.new("TextLabel")
        codeBox.Text = ""
        codeBox.Font = Enum.Font.Code
        codeBox.TextSize = 13
        codeBox.TextColor3 = Color3.fromRGB(220, 220, 226)
        codeBox.TextXAlignment = Enum.TextXAlignment.Left
        codeBox.TextYAlignment = Enum.TextYAlignment.Top
        codeBox.TextWrapped = true
        codeBox.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
        codeBox.Position = UDim2.fromOffset(14, 52)
        codeBox.Size = UDim2.new(1, -28, 1, -66)
        codeBox.ZIndex = 42
        codeBox.Parent = prevCard
        Util.corner(codeBox, 10)
        Util.padding(codeBox, 12)

        task.spawn(function()
            local src = s.rawScript and Util.httpGet(s.rawScript)
            if not detailLayer then return end
            if src and src ~= "" then
                previewSrc = src
                local lines = select(2, src:gsub("\n", "\n")) + 1
                prevMeta.Text = lines .. (lines == 1 and " line · " or " lines · ") .. #src .. " B"
                codeBox.Text = #src > 1200 and (src:sub(1, 1200) .. "\n...") or src
            else
                prevMeta.Text = "unavailable"
                codeBox.Text = "-- couldn't load the script source"
            end
        end)

        scroll.CanvasSize = UDim2.fromOffset(0, prevY + 190 + pad)
    end

    local function buildCard(s, index)
        local col = (index - 1) % 2
        local row = math.floor((index - 1) / 2)

        -- Input cell stays fixed in the grid; the body inside grows on hover
        -- (orca ScriptCard: +48px centered spring, shine sweep, press cancels)
        local c = Instance.new("TextButton")
        c.Text = ""
        c.AutoButtonColor = false
        c.Size = UDim2.fromOffset(CARD_W, CARD_H)
        c.Position = UDim2.fromOffset(INSET + col * (CARD_W + 14), INSET + row * (CARD_H + 14))
        c.BackgroundTransparency = 1
        c.ZIndex = 4
        c.Parent = grid

        -- Plain Frame: CanvasGroup escapes ScrollingFrame/window clipping on
        -- executor builds. Nothing inside overflows, so square clip is fine.
        local body = Instance.new("Frame")
        body.AnchorPoint = Vector2.new(0.5, 0.5)
        body.Position = UDim2.fromScale(0.5, 0.5)
        body.Size = UDim2.fromOffset(CARD_W, CARD_H)
        body.BackgroundColor3 = CARD
        body.BorderSizePixel = 0
        body.ClipsDescendants = true
        body.ZIndex = 4
        body.Parent = c
        Util.corner(body, 12)
        local cStroke = Util.stroke(body, WHITE, 1, 0.85)

        -- "ran this session" check badge, left-middle edge (clear of the KEY /
        -- VERIFIED / views badges), shown after a run
        local ranBadge = Instance.new("Frame")
        ranBadge.Size = UDim2.fromOffset(22, 22)
        ranBadge.AnchorPoint = Vector2.new(0, 0.5)
        ranBadge.Position = UDim2.new(0, 10, 0.5, 0)
        ranBadge.BackgroundColor3 = GREEN
        ranBadge.BorderSizePixel = 0
        ranBadge.Visible = ranSet[s.rawScript] == true
        ranBadge.ZIndex = 7
        ranBadge.Parent = body
        Util.corner(ranBadge, 11)
        local ranCheck = Instance.new("ImageLabel")
        ranCheck.Size = UDim2.fromOffset(13, 13)
        ranCheck.AnchorPoint = Vector2.new(0.5, 0.5)
        ranCheck.Position = UDim2.fromScale(0.5, 0.5)
        ranCheck.BackgroundTransparency = 1
        ranCheck.ZIndex = 8
        ranCheck.Parent = ranBadge
        Icons.apply(ranCheck, "check", WHITE)
        local function markRan()
            if ranBadge.Visible then return end
            ranBadge.Visible = true
            local sc = Instance.new("UIScale")
            sc.Scale = 0
            sc.Parent = ranBadge
            Util.tween(sc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
        end

        local art = Instance.new("ImageLabel")
        art.Image = BANNERS[hashStr(s.title or tostring(index)) % #BANNERS + 1]
        art.ScaleType = Enum.ScaleType.Crop
        art.AnchorPoint = Vector2.new(0.5, 0.5)
        art.Position = UDim2.fromScale(0.5, 0.5)
        art.Size = UDim2.fromScale(1, 1)
        art.BackgroundTransparency = 1
        art.ZIndex = 4
        art.Parent = body
        Util.corner(art, 12)

        -- dark fade so the text reads over the art
        local fade = Instance.new("Frame")
        fade.Size = UDim2.fromScale(1, 1)
        fade.BackgroundColor3 = Color3.new(0, 0, 0)
        fade.BorderSizePixel = 0
        fade.ZIndex = 5
        fade.Parent = body
        Util.corner(fade, 12)
        local fg = Instance.new("UIGradient")
        fg.Rotation = 90
        fg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(0.5, 0.55),
            NumberSequenceKeypoint.new(1, 0.1),
        })
        fg.Parent = fade

        local gameName = s.game and s.game.title
        local title = Instance.new("TextLabel")
        title.Text = s.title or "Untitled"
        title.Font = BODY_BOLD
        title.TextSize = 16
        title.TextColor3 = WHITE
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 18, 1, gameName and -52 or -34)
        title.Size = UDim2.new(1, -36, 0, 20)
        title.ZIndex = 6
        title.Parent = body

        if gameName then
            local sub = Instance.new("TextLabel")
            sub.Text = gameName
            sub.Font = Theme.fonts.body
            sub.TextSize = 13
            sub.TextColor3 = Color3.fromRGB(190, 190, 196)
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.TextTruncate = Enum.TextTruncate.AtEnd
            sub.BackgroundTransparency = 1
            sub.Position = UDim2.new(0, 18, 1, -30)
            sub.Size = UDim2.new(1, -36, 0, 16)
            sub.ZIndex = 6
            sub.Parent = body
        end

        if s.user and s.user.verified then
            local pill = Instance.new("Frame")
            pill.BackgroundColor3 = BLURPLE
            pill.AnchorPoint = Vector2.new(1, 0)
            pill.Position = UDim2.new(1, -10, 0, 10)
            pill.Size = UDim2.fromOffset(80, 20)
            pill.ZIndex = 6
            pill.Parent = body
            Util.corner(pill, 6)
            local vchk = Instance.new("ImageLabel")
            vchk.Size = UDim2.fromOffset(11, 11)
            vchk.Position = UDim2.fromOffset(9, 4)
            vchk.BackgroundTransparency = 1
            vchk.ZIndex = 7
            vchk.Parent = pill
            loadSvgIcon(vchk, "cdn.jsdelivr.net/npm/lucide-static/icons/badge-check.svg", "ic_badgecheckw.png", WHITE, true)
            local vtxt = Instance.new("TextLabel")
            vtxt.Text = "VERIFIED"
            vtxt.Font = BODY_BOLD
            vtxt.TextSize = 10
            vtxt.TextColor3 = WHITE
            vtxt.TextXAlignment = Enum.TextXAlignment.Left
            vtxt.BackgroundTransparency = 1
            vtxt.Position = UDim2.fromOffset(24, 0)
            vtxt.Size = UDim2.new(1, -26, 1, 0)
            vtxt.ZIndex = 7
            vtxt.Parent = pill
        end

        -- view count badge, bottom-right over the fade
        if s.views and tonumber(s.views) and tonumber(s.views) > 0 then
            local vb = Instance.new("TextLabel")
            vb.Text = formatCount(s.views) .. " views"
            vb.Font = BODY_BOLD
            vb.TextSize = 11
            vb.TextColor3 = Color3.fromRGB(210, 210, 216)
            vb.TextXAlignment = Enum.TextXAlignment.Right
            vb.BackgroundColor3 = Color3.fromRGB(10, 11, 13)
            vb.BackgroundTransparency = 0.35
            vb.AutomaticSize = Enum.AutomaticSize.X
            vb.AnchorPoint = Vector2.new(1, 1)
            vb.Position = UDim2.new(1, -10, 1, -10)
            vb.Size = UDim2.fromOffset(0, 18)
            vb.ZIndex = 6
            vb.Parent = body
            Util.corner(vb, 6)
            Util.padding(vb, 5)
        end

        if s.keySystem then
            local kp = Instance.new("Frame")
            kp.BackgroundColor3 = Color3.fromRGB(176, 108, 34)
            kp.Position = UDim2.fromOffset(10, 10)
            kp.Size = UDim2.fromOffset(54, 20)
            kp.ZIndex = 6
            kp.Parent = body
            Util.corner(kp, 6)
            local klock = Instance.new("ImageLabel")
            klock.Size = UDim2.fromOffset(11, 11)
            klock.Position = UDim2.fromOffset(8, 4)
            klock.BackgroundTransparency = 1
            klock.ZIndex = 7
            klock.Parent = kp
            loadSvgIcon(klock, "cdn.jsdelivr.net/npm/lucide-static/icons/lock.svg", "ic_lockw.png", WHITE, true)
            local ktxt = Instance.new("TextLabel")
            ktxt.Text = "KEY"
            ktxt.Font = BODY_BOLD
            ktxt.TextSize = 10
            ktxt.TextColor3 = WHITE
            ktxt.TextXAlignment = Enum.TextXAlignment.Left
            ktxt.BackgroundTransparency = 1
            ktxt.Position = UDim2.fromOffset(23, 0)
            ktxt.Size = UDim2.new(1, -25, 1, 0)
            ktxt.ZIndex = 7
            ktxt.Parent = kp
        end

        -- Entrance: staggered fade + settle (orca-style intro)
        local cover = Instance.new("Frame")
        cover.Size = UDim2.fromScale(1, 1)
        cover.BackgroundColor3 = WIN
        cover.BorderSizePixel = 0
        cover.ZIndex = 9
        cover.Parent = body
        Util.corner(cover, 12)
        local bScale = Instance.new("UIScale")
        bScale.Scale = 0.93
        bScale.Parent = body
        task.delay(((index - 1) % 16) * 0.04, function()
            if not cover.Parent then return end
            Util.tween(cover, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(bScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
            task.delay(0.35, function()
                if cover.Parent then cover:Destroy() end
            end)
        end)

        -- Shine sweep (orca: white diagonal gradient sliding in on hover)
        local shine = Instance.new("Frame")
        shine.Size = UDim2.fromScale(1, 1)
        shine.BackgroundColor3 = WHITE
        shine.BackgroundTransparency = 1
        shine.BorderSizePixel = 0
        shine.ZIndex = 7
        shine.Parent = body
        Util.corner(shine, 12)
        local shineGrad = Instance.new("UIGradient")
        shineGrad.Rotation = 45
        shineGrad.Transparency = NumberSequence.new(0.75, 1)
        shineGrad.Offset = Vector2.new(-1, -1)
        shineGrad.Parent = shine

        -- quick color pulse over the card (execute / copy feedback)
        local function flash(color)
            shine.BackgroundColor3 = color
            shine.BackgroundTransparency = 0.5
            shineGrad.Offset = Vector2.new(0, 0)
            Util.tween(shine, { BackgroundTransparency = 1 }, 0.6)
            task.delay(0.6, function()
                if shine.Parent then shine.BackgroundColor3 = WHITE end
            end)
        end

        local hovered, pressed = false, false
        local function updateBody()
            local grow = hovered and not pressed
            -- growing the body alone re-crops the art (free zoom feel) and
            -- nothing overflows the rounded clip, so corners stay round
            Util.tween(body, { Size = grow and UDim2.fromOffset(CARD_W + GROW, CARD_H + GROW)
                or UDim2.fromOffset(CARD_W, CARD_H) }, 0.22, Enum.EasingStyle.Quad)
        end

        c.MouseEnter:Connect(function()
            hovered = true
            c.ZIndex = 20
            updateBody()
            Util.tween(shine, { BackgroundTransparency = 0 }, 0.25)
            Util.tween(shineGrad, { Offset = Vector2.new(0, 0) }, 0.25)
            Util.tween(cStroke, { Transparency = 1 }, 0.25)
        end)
        c.MouseLeave:Connect(function()
            hovered = false
            pressed = false
            c.ZIndex = 4
            updateBody()
            Util.tween(shine, { BackgroundTransparency = 1 }, 0.25)
            Util.tween(shineGrad, { Offset = Vector2.new(-1, -1) }, 0.25)
            Util.tween(cStroke, { Transparency = 0.85 }, 0.25)
        end)
        c.MouseButton1Down:Connect(function()
            pressed = true
            updateBody()
        end)
        c.MouseButton1Up:Connect(function()
            pressed = false
            updateBody()
        end)
        -- left click opens the script's detail view (banner, stats, preview,
        -- execute / copy / share). Executing from there marks this card ran.
        c.MouseButton1Click:Connect(function()
            showDetail(s, markRan)
        end)

        -- right click: copy a ready loadstring
        c.MouseButton2Click:Connect(function()
            if not s.rawScript then return end
            local ok = pcall(function()
                setclipboard('loadstring(game:HttpGet("' .. s.rawScript .. '"))()')
            end)
            if ok then
                status.Text = "Copied loadstring for " .. (s.title or "script")
                status.TextColor3 = GREEN
                flash(GREEN)
                -- floating "Copied!" bubble that rises off the card and fades
                local toast = Instance.new("TextLabel")
                toast.Text = "Copied!"
                toast.Font = BODY_BOLD
                toast.TextSize = 13
                toast.TextColor3 = WHITE
                toast.BackgroundColor3 = GREEN
                toast.AnchorPoint = Vector2.new(0.5, 0.5)
                toast.Position = UDim2.fromScale(0.5, 0.5)
                toast.Size = UDim2.fromOffset(78, 26)
                toast.ZIndex = 12
                toast.Parent = body
                Util.corner(toast, 8)
                Util.tween(toast, { Position = UDim2.new(0.5, 0, 0.5, -30), TextTransparency = 1, BackgroundTransparency = 1 }, 0.7, Enum.EasingStyle.Quad)
                task.delay(0.72, function() if toast.Parent then toast:Destroy() end end)
            end
        end)
    end

    local function renderList(list, append)
        if not append then
            for _, child in ipairs(grid:GetChildren()) do
                if child ~= emptyState and child ~= loader then child:Destroy() end
            end
            itemCount = 0
            grid.CanvasPosition = Vector2.new(0, 0)
        end
        for _, s in ipairs(list) do
            itemCount += 1
            buildCard(s, itemCount)
        end
        emptyState.Visible = itemCount == 0
        local rows = math.ceil(itemCount / 2)
        grid.CanvasSize = UDim2.fromOffset(0, rows * (CARD_H + 14) + INSET * 2)
    end

    local function requestPage(q, page)
        local url = API .. "/scripts?page=" .. page .. "&orderBy=" .. curSort().key .. "&sort=desc"
        if q and q ~= "" then url = url .. "&q=" .. HttpService:UrlEncode(q) end
        local body = Util.httpGet(url)
        if not body then return nil end
        local data
        pcall(function() data = HttpService:JSONDecode(body) end)
        if type(data) ~= "table" or type(data.scripts) ~= "table" then return nil end
        return data
    end

    local function fetchScripts(q)
        reqToken += 1
        local token = reqToken
        curQuery = (q and q ~= "") and q or nil
        curPage = 1
        loadingMore = false
        status.TextColor3 = SUB
        status.Text = curQuery and "Searching..." or "Loading recent scripts..."
        -- spinner only when there are no cards to look at yet
        setLoading(itemCount == 0)
        task.spawn(function()
            local data = requestPage(curQuery, 1)
            if not alive or token ~= reqToken then return end
            setLoading(false)
            if not data then
                status.Text = "Couldn't reach RScripts. Try again."
                status.TextColor3 = RED
                return
            end
            maxPages = (data.info and tonumber(data.info.maxPages)) or 1
            renderList(data.scripts, false)
            status.Text = statusDefault()
            -- only the default view (recent, no query) seeds the reopen cache
            if not curQuery and curSort().key == "date" then
                Scripts._cache = data.scripts
            end
        end)
    end

    -- Infinite scroll: pull the next page when close to the bottom
    grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        setToTop(grid.CanvasPosition.Y > 260)
        if loadingMore or curPage >= maxPages or itemCount == 0 then return end
        local bottom = grid.CanvasPosition.Y + grid.AbsoluteWindowSize.Y
        if bottom < grid.AbsoluteCanvasSize.Y - 220 then return end
        loadingMore = true
        local token = reqToken
        local page = curPage + 1
        status.Text = "Loading more..."
        status.TextColor3 = SUB
        task.spawn(function()
            local data = requestPage(curQuery, page)
            if not alive or token ~= reqToken then return end
            if data then
                curPage = page
                maxPages = (data.info and tonumber(data.info.maxPages)) or maxPages
                renderList(data.scripts, true)
            end
            status.Text = statusDefault()
            loadingMore = false
        end)
    end)

    -- Search as you type (debounced) + instant on Enter
    local searchVersion = 0
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local has = searchBox.Text ~= ""
        clearBtn.Visible = has
        Util.tween(clearBtn, { BackgroundTransparency = has and 0.15 or 1 }, 0.12)
        Util.tween(clearGlyph, { ImageTransparency = has and 0 or 1 }, 0.12)
        searchVersion += 1
        local v = searchVersion
        task.delay(0.6, function()
            if alive and v == searchVersion then
                fetchScripts(searchBox.Text)
            end
        end)
    end)
    searchBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            searchVersion += 1
            fetchScripts(searchBox.Text)
        end
        -- release the focus ring
        Util.tween(searchStroke, { Color = WHITE, Transparency = 0.9 }, 0.15)
    end)
    searchBox.Focused:Connect(function()
        -- accent focus ring
        Util.tween(searchStroke, { Color = BLURPLE, Transparency = 0.35 }, 0.15)
    end)
    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        searchVersion += 1
        fetchScripts(nil)
    end)

    -- Sort chip cycles the order and refetches the current query
    sortChip.MouseButton1Click:Connect(function()
        sortIdx = sortIdx % #SORTS + 1
        sortChipLabel.Text = curSort().label
        Util.save("ScriptsSort", curSort().key)
        searchVersion += 1
        fetchScripts(curQuery)
    end)

    -- Cached list paints instantly on reopen (only for the default sort, which
    -- is what the cache holds), then refreshes in the background
    if curSort().key == "date" and type(Scripts._cache) == "table" and #Scripts._cache > 0 then
        renderList(Scripts._cache, false)
        status.Text = statusDefault()
    end
    fetchScripts(nil)

    return { close = close }
end

return Scripts
end)

SYNC.define("init", function()
-- SYNC / init
-- Entry module. Boot sequence -> login -> device selector -> desktop.

local Boot           = SYNC.import("os/Boot")
local Login          = SYNC.import("os/Login")
local DeviceSelector = SYNC.import("os/DeviceSelector")
local Desktop        = SYNC.import("os/Desktop")

Boot.run(function()
    Login.run(function()
        DeviceSelector.run(function(device)
            if device == "desktop" then
                Desktop.start()
            end
            -- mobile / tablet layouts come later; desktop is the current focus.
        end)
    end)
end)
end)

SYNC.import("init")
