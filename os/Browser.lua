-- SYNC / os / Browser  ("Sense Browser")
-- A workable text browser inside SYNC: homepage (drawn Saturn logo, offset clock,
-- search field, quick links) + real search via DuckDuckGo (HttpGet) that lists
-- results and opens a page's readable text. Roblox can't render real web pages,
-- so pages are shown as extracted text. Browser.open() -> window.

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Browser = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local DIM   = Color3.fromRGB(150, 150, 158)
local ACCENT = Color3.fromRGB(90, 150, 255)

Browser._gui = nil

-- ---------- helpers ----------
local function urlencode(s)
    return (tostring(s):gsub("[^%w%-_%.~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
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
    html = html:gsub("<script.->.-</script>", " ")
    html = html:gsub("<style.->.-</style>", " ")
    html = html:gsub("<!%-%-.-%-%->", " ")
    html = html:gsub("<br%s*/?>", "\n")
    html = html:gsub("</p>", "\n")
    html = html:gsub("<.->", "")
    html = decodeEntities(html)
    html = html:gsub("[ \t]+", " ")
    html = html:gsub("\n%s*\n%s*\n+", "\n\n")
    return (html:gsub("^%s+", ""))
end

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(res) == "string" then return res end
    return nil
end

-- Parse DuckDuckGo HTML results into { {title, url, snippet}, ... }
local function parseDDG(html)
    local results = {}
    for href, title in html:gmatch('class="result__a"%s+href="(.-)"[^>]*>(.-)</a>') do
        local real = href
        local uddg = href:match("uddg=([^&]+)")
        if uddg then real = urldecode(uddg) end
        real = real:gsub("^//", "https://")
        local cleanTitle = stripTags(title):gsub("%s+", " ")
        if cleanTitle ~= "" then
            results[#results + 1] = { title = cleanTitle, url = real, snippet = "" }
        end
        if #results >= 8 then break end
    end
    -- attach snippets in order
    local i = 0
    for snip in html:gmatch('class="result__snippet"[^>]*>(.-)</a>') do
        i = i + 1
        if results[i] then results[i].snippet = stripTags(snip):gsub("%s+", " ") end
    end
    return results
end

-- Saturn logo drawn from a tilted ring + a planet circle outline
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
    ring.BorderSizePixel = 0
    ring.ZIndex = 4
    ring.Parent = box
    Util.corner(ring, size * 0.21)
    Util.stroke(ring, color, thick, 0)

    local planet = Instance.new("Frame")
    planet.Size = UDim2.fromOffset(size * 0.6, size * 0.6)
    planet.AnchorPoint = Vector2.new(0.5, 0.5)
    planet.Position = UDim2.fromScale(0.5, 0.5)
    planet.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    planet.BorderSizePixel = 0
    planet.ZIndex = 5
    planet.Parent = box
    Util.corner(planet, size)
    Util.stroke(planet, color, thick, 0)
    return box
end

function Browser.open()
    if Browser._gui then return end

    local vp = Util.viewport()
    local W, H = 760, 520
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Browser"
    Util.mount(gui)
    Browser._gui = gui

    local function close()
        if not Browser._gui then return end
        Browser._gui = nil
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

    -- ===== Title bar (draggable) with traffic lights + tab =====
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

    local tab = Instance.new("Frame")
    tab.Size = UDim2.fromOffset(170, 26)
    tab.Position = UDim2.fromOffset(86, (TB - 26) / 2)
    tab.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
    tab.BorderSizePixel = 0
    tab.ZIndex = 4
    tab.Parent = bar
    Util.corner(tab, 8)
    local tabLabel = Instance.new("TextLabel")
    tabLabel.BackgroundTransparency = 1
    tabLabel.Size = UDim2.new(1, -16, 1, 0)
    tabLabel.Position = UDim2.fromOffset(12, 0)
    tabLabel.Font = Theme.fonts.body
    tabLabel.TextSize = 13
    tabLabel.TextColor3 = Color3.fromRGB(220, 220, 226)
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.Text = "New Tab"
    tabLabel.ZIndex = 5
    tabLabel.Parent = tab

    -- ===== Address bar =====
    local AB = 44
    local addr = Instance.new("Frame")
    addr.Size = UDim2.new(1, 0, 0, AB)
    addr.Position = UDim2.fromOffset(0, TB)
    addr.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
    addr.BorderSizePixel = 0
    addr.ZIndex = 3
    addr.Parent = win

    local urlField = Instance.new("TextBox")
    urlField.Size = UDim2.new(1, -100, 0, 30)
    urlField.Position = UDim2.fromOffset(16, (AB - 30) / 2)
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

    -- ===== Content area =====
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -(TB + AB))
    content.Position = UDim2.fromOffset(0, TB + AB)
    content.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.ZIndex = 3
    content.Parent = win

    local function clearContent()
        for _, ch in ipairs(content:GetChildren()) do ch:Destroy() end
    end

    -- forward declares
    local showHomepage, doSearch, openPage

    -- ----- Homepage -----
    local clockConn
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
        logoWrap.Size = UDim2.fromOffset(70, 70)
        logoWrap.AnchorPoint = Vector2.new(0.5, 0.5)
        logoWrap.Position = UDim2.fromScale(0.5, 0.32)
        logoWrap.BackgroundTransparency = 1
        logoWrap.ZIndex = 4
        logoWrap.Parent = content
        drawSaturn(logoWrap, 64, WHITE)

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
        mag.Size = UDim2.fromOffset(18, 18)
        mag.AnchorPoint = Vector2.new(0, 0.5)
        mag.Position = UDim2.new(0, 22, 0.5, 0)
        mag.BackgroundTransparency = 1
        mag.ZIndex = 5
        mag.Parent = searchWrap
        Icons.apply(mag, "search", DIM)
        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -64, 1, 0)
        searchBox.Position = UDim2.fromOffset(52, 0)
        searchBox.BackgroundTransparency = 1
        searchBox.Font = Theme.fonts.body
        searchBox.TextSize = 15
        searchBox.TextColor3 = WHITE
        searchBox.PlaceholderText = "Search or enter URL"
        searchBox.PlaceholderColor3 = DIM
        searchBox.Text = ""
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        searchBox.ZIndex = 5
        searchBox.Parent = searchWrap
        searchBox.FocusLost:Connect(function(enter)
            if enter and searchBox.Text ~= "" then doSearch(searchBox.Text) end
        end)

        -- Quick links
        local links = {
            { name = "Google",    icon = "search",         url = "https://www.google.com",     col = Color3.fromRGB(66, 133, 244) },
            { name = "YouTube",   icon = "video",          url = "https://www.youtube.com",    col = Color3.fromRGB(255, 0, 0) },
            { name = "GitHub",    icon = "github",         url = "https://github.com",         col = Color3.fromRGB(60, 60, 66) },
            { name = "Wikipedia", icon = "book-open",      url = "https://www.wikipedia.org",  col = Color3.fromRGB(120, 120, 128) },
            { name = "Reddit",    icon = "message-circle", url = "https://www.reddit.com",     col = Color3.fromRGB(255, 69, 0) },
        }
        local tileW, gap = 78, 14
        local total = #links * tileW + (#links - 1) * gap
        local startX = (content.AbsoluteSize.X > 0 and content.AbsoluteSize.X or W) / 2 - total / 2
        for i, lk in ipairs(links) do
            local t = Instance.new("TextButton")
            t.Text = ""
            t.AutoButtonColor = false
            t.Size = UDim2.fromOffset(tileW, 76)
            t.AnchorPoint = Vector2.new(0, 1)
            t.Position = UDim2.new(0, startX + (i - 1) * (tileW + gap), 1, -28)
            t.BackgroundTransparency = 1
            t.ZIndex = 4
            t.Parent = content
            local circ = Instance.new("Frame")
            circ.Size = UDim2.fromOffset(48, 48)
            circ.AnchorPoint = Vector2.new(0.5, 0)
            circ.Position = UDim2.fromScale(0.5, 0)
            circ.BackgroundColor3 = lk.col
            circ.BorderSizePixel = 0
            circ.ZIndex = 4
            circ.Parent = t
            Util.corner(circ, 12)
            local g = Instance.new("ImageLabel")
            g.Size = UDim2.fromOffset(24, 24)
            g.AnchorPoint = Vector2.new(0.5, 0.5)
            g.Position = UDim2.fromScale(0.5, 0.5)
            g.BackgroundTransparency = 1
            g.ZIndex = 5
            g.Parent = circ
            Icons.apply(g, lk.icon, WHITE)
            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.fromOffset(tileW, 16)
            nm.AnchorPoint = Vector2.new(0.5, 1)
            nm.Position = UDim2.fromScale(0.5, 1)
            nm.BackgroundTransparency = 1
            nm.Font = Theme.fonts.caption
            nm.TextSize = 12
            nm.TextColor3 = DIM
            nm.Text = lk.name
            nm.ZIndex = 5
            nm.Parent = t
            t.MouseButton1Click:Connect(function() openPage(lk.url) end)
        end
    end

    -- ----- Results / page text views -----
    local function makeScroll()
        clearContent()
        local sc = Instance.new("ScrollingFrame")
        sc.Size = UDim2.new(1, 0, 1, 0)
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
        local ll = Instance.new("UIListLayout")
        ll.Padding = UDim.new(0, 10); ll.Parent = sc
        return sc
    end

    local function statusText(msg)
        clearContent()
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -48, 0, 40)
        t.Position = UDim2.fromOffset(24, 20)
        t.BackgroundTransparency = 1
        t.Font = Theme.fonts.body
        t.TextSize = 14
        t.TextColor3 = DIM
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Text = msg
        t.ZIndex = 4
        t.Parent = content
    end

    function openPage(url)
        if clockConn then clockConn:Disconnect(); clockConn = nil end
        urlField.Text = url
        statusText("Loading " .. url .. " ...")
        task.spawn(function()
            local html = httpGet(url)
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
            body.Text = text ~= "" and text or "(no readable text on this page)"
            body.ZIndex = 4
            body.Parent = sc
        end)
    end

    function doSearch(query)
        if clockConn then clockConn:Disconnect(); clockConn = nil end
        -- treat as URL if it looks like a domain
        if query:match("^https?://") or query:match("^[%w%-]+%.[%w%-%.]+$") then
            local u = query:match("^https?://") and query or ("https://" .. query)
            openPage(u)
            return
        end
        urlField.Text = "sense://search?q=" .. query
        statusText('Searching "' .. query .. '" ...')
        task.spawn(function()
            local html = httpGet("https://html.duckduckgo.com/html/?q=" .. urlencode(query))
            if Browser._gui ~= gui then return end
            if not html then statusText("Search failed (network blocked).") return end
            local results = parseDDG(html)
            if #results == 0 then statusText('No results for "' .. query .. '".') return end
            local sc = makeScroll()
            for _, r in ipairs(results) do
                local row = Instance.new("TextButton")
                row.Text = ""
                row.AutoButtonColor = false
                row.Size = UDim2.new(1, 0, 0, 0)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
                row.BackgroundTransparency = 1
                row.ZIndex = 4
                row.Parent = sc
                Util.corner(row, 8)
                local rp = Instance.new("UIPadding")
                rp.PaddingTop = UDim.new(0, 6); rp.PaddingBottom = UDim.new(0, 8)
                rp.PaddingLeft = UDim.new(0, 8); rp.PaddingRight = UDim.new(0, 8)
                rp.Parent = row
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
                if r.snippet ~= "" then
                    local sn = Instance.new("TextLabel")
                    sn.Size = UDim2.new(1, 0, 0, 0); sn.AutomaticSize = Enum.AutomaticSize.Y
                    sn.BackgroundTransparency = 1; sn.Font = Theme.fonts.caption; sn.TextSize = 13
                    sn.TextColor3 = DIM; sn.TextXAlignment = Enum.TextXAlignment.Left
                    sn.TextYAlignment = Enum.TextYAlignment.Top; sn.TextWrapped = true
                    sn.Text = r.snippet; sn.ZIndex = 5; sn.LayoutOrder = 3; sn.Parent = row
                end
                row.MouseEnter:Connect(function() row.BackgroundTransparency = 0.85 end)
                row.MouseLeave:Connect(function() row.BackgroundTransparency = 1 end)
                row.MouseButton1Click:Connect(function() openPage(r.url) end)
            end
        end)
    end

    urlField.FocusLost:Connect(function(enter)
        if enter and urlField.Text ~= "" then
            local q = urlField.Text
            if q == "sense://homepage" then showHomepage() else doSearch(q) end
        end
    end)

    -- ===== Drag the window by its title bar =====
    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = win.Position
        end
    end)
    local dragConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    gui.AncestryChanged:Connect(function(_, p)
        if not p then dragConn:Disconnect(); endConn:Disconnect(); if clockConn then clockConn:Disconnect() end end
    end)

    showHomepage()
    return { close = close }
end

return Browser
