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
