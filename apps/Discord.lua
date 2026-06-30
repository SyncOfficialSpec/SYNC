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

    local W, H = 720, 480
    local vp = Util.viewport()
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
    titleLbl.Text = "Discord"; titleLbl.Font = Theme.fonts.title; titleLbl.TextSize = 13
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
    local feedLayout = Instance.new("UIListLayout"); feedLayout.Padding = UDim.new(0,10)
    feedLayout.SortOrder = Enum.SortOrder.LayoutOrder; feedLayout.Parent = feed
    feedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        feed.CanvasSize = UDim2.fromOffset(0, feedLayout.AbsoluteContentSize.Y + 16)
        feed.CanvasPosition = Vector2.new(0, feed.CanvasSize.Y.Offset)
    end)
    local feedPad = Instance.new("UIPadding"); feedPad.PaddingTop = UDim.new(0,8); feedPad.PaddingBottom = UDim.new(0,8)
    feedPad.PaddingRight = UDim.new(0,8); feedPad.Parent = feed

    -- input bar
    local inputWrap = Instance.new("Frame")
    inputWrap.Size = UDim2.new(1, -32, 0, 42); inputWrap.Position = UDim2.new(0, 16, 1, -50)
    inputWrap.BackgroundColor3 = C.input; inputWrap.BorderSizePixel = 0; inputWrap.ZIndex = 4; inputWrap.Parent = main
    Util.corner(inputWrap, 8)
    Util.stroke(inputWrap, Color3.fromRGB(0, 0, 0), 1, 0.6)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -24, 1, 0); box.Position = UDim2.fromOffset(14, 0)
    box.BackgroundTransparency = 1; box.Text = ""; box.PlaceholderText = "Message  (paste an image URL to send a pic)"
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
    replyX.BackgroundTransparency = 1; replyX.AutoButtonColor = false; replyX.Text = "✕"
    replyX.Font = Theme.fonts.body; replyX.TextSize = 13; replyX.TextColor3 = C.muted
    replyX.ZIndex = 5; replyX.Parent = replyBar

    -- ---- state ----
    local activeChannel, activeName
    local lastId
    local renderedIds = {}
    local replyTarget = nil
    local showProfile, setReply   -- forward declarations

    local CONTENT_W = (W - SIDE_W) - 78
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

    local function addMessage(m)
        if renderedIds[m.id] then return end
        renderedIds[m.id] = true

        local replyH = m.replyTo and 16 or 0
        local headerH = replyH + 18
        local contentH = measureH(m.content)
        local imgCount = m.images and #m.images or 0
        local imgH = imgCount * 168
        local total = math.max(42, headerH + contentH + imgH + 6)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, total)
        row.BackgroundTransparency = 1; row.ZIndex = 4; row.Parent = feed

        -- avatar (clickable -> profile)
        local av = Instance.new("ImageLabel")
        av.Size = UDim2.fromOffset(36, 36); av.Position = UDim2.fromOffset(4, replyH + 2)
        av.BackgroundColor3 = C.rail; av.BorderSizePixel = 0; av.ZIndex = 5; av.Parent = row
        Util.corner(av, 18)
        loadImg(av, m.avatar, "dcav")
        local avBtn = Instance.new("TextButton")
        avBtn.Size = UDim2.fromScale(1, 1); avBtn.BackgroundTransparency = 1
        avBtn.Text = ""; avBtn.AutoButtonColor = false; avBtn.ZIndex = 6; avBtn.Parent = av
        avBtn.MouseButton1Click:Connect(function() if showProfile then showProfile(m) end end)

        -- reply context line
        if m.replyTo then
            local rl = Instance.new("TextLabel")
            rl.Position = UDim2.fromOffset(50, 0); rl.Size = UDim2.new(1, -110, 0, 14)
            rl.BackgroundTransparency = 1
            rl.Text = "↪ " .. (m.replyTo.author or "") ..
                ((m.replyTo.content and m.replyTo.content ~= "") and (": " .. m.replyTo.content) or "")
            rl.Font = Theme.fonts.caption; rl.TextSize = 12; rl.TextColor3 = C.muted
            rl.TextXAlignment = Enum.TextXAlignment.Left; rl.TextTruncate = Enum.TextTruncate.AtEnd
            rl.ZIndex = 5; rl.Parent = row
        end

        -- name (clickable) + timestamp
        local nameBtn = Instance.new("TextButton")
        nameBtn.Position = UDim2.fromOffset(50, replyH); nameBtn.Size = UDim2.fromOffset(240, 18)
        nameBtn.BackgroundTransparency = 1; nameBtn.AutoButtonColor = false
        nameBtn.Text = m.author or "Unknown"; nameBtn.Font = Theme.fonts.title; nameBtn.TextSize = 14
        nameBtn.TextColor3 = m.roblox and Color3.fromRGB(120, 200, 255) or C.bright
        nameBtn.TextXAlignment = Enum.TextXAlignment.Left; nameBtn.ZIndex = 5; nameBtn.Parent = row
        nameBtn.MouseButton1Click:Connect(function() if showProfile then showProfile(m) end end)

        local nameW = measureW(m.author or "", 14, Theme.fonts.title)
        local timeLbl = Instance.new("TextLabel")
        timeLbl.Position = UDim2.fromOffset(56 + nameW, replyH + 3); timeLbl.Size = UDim2.fromOffset(90, 13)
        timeLbl.BackgroundTransparency = 1; timeLbl.Text = fmtTime(m.ts)
        timeLbl.Font = Theme.fonts.caption; timeLbl.TextSize = 11; timeLbl.TextColor3 = C.muted
        timeLbl.TextXAlignment = Enum.TextXAlignment.Left; timeLbl.ZIndex = 5; timeLbl.Parent = row

        -- content (markdown -> rich text)
        if m.content and m.content ~= "" then
            local content = Instance.new("TextLabel")
            content.Position = UDim2.fromOffset(50, headerH); content.Size = UDim2.fromOffset(CONTENT_W, contentH)
            content.BackgroundTransparency = 1; content.RichText = true; content.Text = mdToRich(m.content)
            content.Font = Theme.fonts.body; content.TextSize = 14; content.TextColor3 = C.text
            content.TextWrapped = true; content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextYAlignment = Enum.TextYAlignment.Top; content.ZIndex = 5; content.Parent = row
        end

        -- inline images
        if m.images then
            for i, url in ipairs(m.images) do
                local img = Instance.new("ImageLabel")
                img.Position = UDim2.fromOffset(50, headerH + contentH + (i - 1) * 168 + 4)
                img.Size = UDim2.fromOffset(280, 158)
                img.BackgroundColor3 = C.rail; img.BorderSizePixel = 0
                img.ScaleType = Enum.ScaleType.Fit
                img.ZIndex = 5; img.Parent = row
                Util.corner(img, 8)
                loadImg(img, url, "dcimg")
            end
        end

        -- reply button
        local rb = Instance.new("TextButton")
        rb.Position = UDim2.new(1, -54, 0, replyH); rb.Size = UDim2.fromOffset(46, 18)
        rb.BackgroundTransparency = 1; rb.AutoButtonColor = false
        rb.Text = "reply"; rb.Font = Theme.fonts.caption; rb.TextSize = 11; rb.TextColor3 = C.muted
        rb.ZIndex = 6; rb.Parent = row
        rb.MouseButton1Click:Connect(function() if setReply then setReply(m) end end)
    end

    local function clearFeed()
        renderedIds = {}; lastId = nil
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
            if not msgs then notice("Couldn't load #" .. name .. " from the relay.") return end
            if #msgs == 0 then notice("No messages in #" .. name .. " yet. Say hi 👋") return end
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
            setDbg("Relay URL not configured.")
            return
        end
        setDbg("Connecting...\nHTTP: " .. (Util.hasRequest() and "request() available" or "game:HttpGet only") ..
            "\nConnecting to relay…")
        task.spawn(function()
            local url = relayURL() .. "/channels?key=" .. apiKey()
            local ok, body, status = pcall(function() return Util.httpGetH(url, { ["X-API-Key"] = apiKey() }) end)
            if not alive then return end
            if not ok then
                setDbg("Request error:\n" .. tostring(body) .. "\n\n" .. url)
                return
            end
            if not body then
                setDbg("No response.\nHTTP: " ..
                    (Util.hasRequest() and "request()" or "game:HttpGet only") ..
                    "\nstatus = " .. tostring(status) .. "\n\n" .. url)
                return
            end
            local chans = jdecode(body)
            if type(chans) ~= "table" or chans.error then
                setDbg("Relay replied (status " .. tostring(status) .. "):\n\n" .. tostring(body):sub(1, 220))
                return
            end
            setDbg("")  -- success: clear the diagnostic
            clearFeed()
            for _, ch in ipairs(chans) do buildChannelButton(ch) end
            if chans[1] then
                selectChannel(chans[1].id, chans[1].name, function() highlightChannel(chans[1].id) end)
            else
                setDbg("Connected, but the relay has no channels configured.")
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
    if not lok then setDbg("Load error:\n" .. tostring(lerr)) end

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
