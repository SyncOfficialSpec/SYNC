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
local function getScripts(q, siteId)
    local url = RELAY_URL .. "/scripts?key=" .. API_KEY
    if siteId and siteId ~= "" then
        url = url .. "&sites=" .. siteId          -- a specific site tab
    else
        local csv = enabledCsv()
        if csv ~= "" then url = url .. "&sites=" .. csv end   -- All (enabled)
    end
    if q and q ~= "" then url = url .. "&q=" .. HttpService:UrlEncode(q) end
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

    -- grid
    local grid = Instance.new("ScrollingFrame")
    grid.Position = UDim2.fromOffset(20, TB + 132); grid.Size = UDim2.new(1, -40, 1, -(TB + 142))
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
        pop.Size = UDim2.fromScale(1, 1); pop.BackgroundColor3 = BLACK; pop.BackgroundTransparency = 0.5
        pop.AutoButtonColor = false; pop.Text = ""; pop.ZIndex = 30; pop.Parent = win
        local card = Instance.new("TextButton")
        card.Size = UDim2.fromOffset(math.min(560, W - 80), math.min(420, H - 80))
        card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5)
        card.BackgroundColor3 = C.header; card.AutoButtonColor = false; card.Text = ""
        card.BorderSizePixel = 0; card.ClipsDescendants = true; card.ZIndex = 31; card.Parent = pop
        Util.corner(card, 12); Util.stroke(card, BLACK, 1, 0.4)
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(18, 14); t.Size = UDim2.new(1, -36, 0, 24)
        t.BackgroundTransparency = 1; t.Text = s.title or "Script"; t.Font = Theme.fonts.title
        t.TextSize = 16; t.TextColor3 = C.text; t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd; t.ZIndex = 32; t.Parent = card
        local meta = Instance.new("TextLabel")
        meta.Position = UDim2.fromOffset(18, 40); meta.Size = UDim2.new(1, -36, 0, 16)
        meta.BackgroundTransparency = 1
        meta.Text = (s.site or "") .. (s.game ~= "" and ("  -  " .. s.game) or "") .. "   " .. tostring(s.views or 0) .. " views"
        meta.Font = Theme.fonts.caption; meta.TextSize = 12; meta.TextColor3 = C.muted
        meta.TextXAlignment = Enum.TextXAlignment.Left; meta.ZIndex = 32; meta.Parent = card

        local hasScript = s.script and s.script ~= ""
        local box = Instance.new("Frame")
        box.Position = UDim2.fromOffset(18, 66); box.Size = UDim2.new(1, -36, 1, -122)
        box.BackgroundColor3 = C.bg; box.BorderSizePixel = 0; box.ZIndex = 32; box.Parent = card
        Util.corner(box, 8)
        local codeScroll = Instance.new("ScrollingFrame")
        codeScroll.Size = UDim2.new(1, -8, 1, -8); codeScroll.Position = UDim2.fromOffset(8, 4)
        codeScroll.BackgroundTransparency = 1; codeScroll.BorderSizePixel = 0; codeScroll.ScrollBarThickness = 4
        codeScroll.CanvasSize = UDim2.fromOffset(0, 0); codeScroll.ZIndex = 33; codeScroll.Parent = box
        local code = Instance.new("TextLabel")
        code.Size = UDim2.new(1, -8, 0, 2000); code.BackgroundTransparency = 1
        code.Text = hasScript and s.script or ("No inline script.\n\nOpen on the site:\n" .. (s.url or ""))
        code.Font = Enum.Font.Code; code.TextSize = 12; code.TextColor3 = C.text
        code.TextXAlignment = Enum.TextXAlignment.Left; code.TextYAlignment = Enum.TextYAlignment.Top
        code.TextWrapped = true; code.ZIndex = 33; code.Parent = codeScroll

        local copyBtn = Instance.new("TextButton")
        copyBtn.Position = UDim2.new(1, -128, 1, -44); copyBtn.Size = UDim2.fromOffset(112, 32)
        copyBtn.BackgroundColor3 = C.accent; copyBtn.AutoButtonColor = false
        copyBtn.Text = hasScript and "Copy Script" or "Copy Link"; copyBtn.Font = Theme.fonts.title
        copyBtn.TextSize = 13; copyBtn.TextColor3 = WHITE; copyBtn.ZIndex = 32; copyBtn.Parent = card
        Util.corner(copyBtn, 8)
        copyBtn.MouseButton1Click:Connect(function()
            setClip(hasScript and s.script or (s.url or ""))
            copyBtn.Text = "Copied!"; copyBtn.BackgroundColor3 = C.green
        end)
        pop.MouseButton1Click:Connect(function() pop:Destroy() end)
    end

    -- ----- render cards -----
    local CARD_W, CARD_H, PAD = 210, 176, 14
    local function renderCards(list)
        for _, ch in ipairs(grid:GetChildren()) do if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end end
        status.Parent = grid
        if not list then status.Text = "Couldn't reach the relay."; return end
        if #list == 0 then status.Text = "No scripts found."; return end
        status.Parent = nil

        local gridW = grid.AbsoluteSize.X
        if gridW < 50 then gridW = W - 60 end
        local cols = math.max(1, math.floor((gridW + PAD) / (CARD_W + PAD)))
        local col, row = 0, 0
        for _, s in ipairs(list) do
            local x = col * (CARD_W + PAD)
            local y = row * (CARD_H + PAD)
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
            badge.BackgroundColor3 = BLACK
            badge.BackgroundTransparency = 0.35; badge.Text = s.site or ""
            badge.Font = Theme.fonts.caption; badge.TextSize = 11; badge.TextColor3 = WHITE
            badge.ZIndex = 6; badge.Parent = thumb
            Util.corner(badge, 5)

            local ttl = Instance.new("TextLabel")
            ttl.Position = UDim2.fromOffset(10, 106); ttl.Size = UDim2.new(1, -20, 0, 36)
            ttl.BackgroundTransparency = 1; ttl.Text = s.title or "Untitled"; ttl.Font = Theme.fonts.body
            ttl.TextSize = 13; ttl.TextColor3 = C.text; ttl.TextWrapped = true
            ttl.TextXAlignment = Enum.TextXAlignment.Left; ttl.TextYAlignment = Enum.TextYAlignment.Top
            ttl.ZIndex = 5; ttl.Parent = cardBtn

            local sub = Instance.new("TextLabel")
            sub.Position = UDim2.fromOffset(10, 150); sub.Size = UDim2.new(1, -20, 0, 16)
            sub.BackgroundTransparency = 1
            sub.Text = (s.game ~= "" and s.game or s.desc or "") .. "   " .. tostring(s.views or 0) .. " views"
            sub.Font = Theme.fonts.caption; sub.TextSize = 11; sub.TextColor3 = C.muted
            sub.TextXAlignment = Enum.TextXAlignment.Left; sub.TextTruncate = Enum.TextTruncate.AtEnd
            sub.ZIndex = 5; sub.Parent = cardBtn

            cardBtn.MouseButton1Click:Connect(function() showDetail(s) end)

            col = col + 1
            if col >= cols then col = 0; row = row + 1 end
        end
        local rows = row + (col > 0 and 1 or 0)
        grid.CanvasSize = UDim2.fromOffset(0, rows * (CARD_H + PAD) + PAD)
    end

    local currentSite = nil   -- nil = All
    local function load(q)
        status.Parent = grid; status.Text = "Loading..."
        for _, ch in ipairs(grid:GetChildren()) do if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end end
        status.Parent = grid
        task.spawn(function()
            local list = getScripts(q, currentSite)
            if alive then renderCards(list) end
        end)
    end

    searchBtn.MouseButton1Click:Connect(function() load(search.Text) end)
    search.FocusLost:Connect(function(enter) if enter then load(search.Text) end end)

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
