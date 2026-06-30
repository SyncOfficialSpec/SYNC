-- SYNC / apps / Discord
-- A Discord-looking client that bridges the game to a real Discord server via
-- the SYNC relay (see ~/sync-discord-relay). Roblox players read channels and
-- "send" messages; the relay posts them through a webhook as "<name> (Roblox)".

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local DiscordApp = {}

-- ---------------------------------------------------------------------------
-- Config -- RELAY_URL is filled in once the relay is deployed. Both can be
-- overridden at runtime via Util.save("DiscordRelay"/"DiscordKey", ...).
-- ---------------------------------------------------------------------------
local RELAY_URL = "https://REPLACE-WITH-RELAY-URL"
local API_KEY   = "CdTt-Mmf25ewBa8Ak9DQujolBQ7HQ9Va76lyV4ulXDnIyc8XOPih2w"

local function relayURL() local v = Util.load("DiscordRelay"); return (v and v ~= "") and v or RELAY_URL end
local function apiKey()   local v = Util.load("DiscordKey");   return (v and v ~= "") and v or API_KEY end
local function configured() return relayURL():sub(1, 8) == "https://" and not relayURL():find("REPLACE") end

-- Discord palette
local C = {
    bg      = Color3.fromRGB(49, 51, 56),
    side    = Color3.fromRGB(43, 45, 49),
    rail    = Color3.fromRGB(30, 31, 34),
    header  = Color3.fromRGB(30, 31, 34),
    input   = Color3.fromRGB(56, 58, 64),
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
local function getChannels()
    local body = Util.httpGetH(relayURL() .. "/channels", { ["X-API-Key"] = apiKey() })
    return body and jdecode(body) or nil
end
local function getMessages(channelId, afterId)
    local url = relayURL() .. "/messages?channel=" .. channelId
    if afterId then url = url .. "&after=" .. afterId end
    local body = Util.httpGetH(url, { ["X-API-Key"] = apiKey() })
    return body and jdecode(body) or nil
end
local function sendMessage(channelId, text)
    local m = me()
    local payload = jencode({ channel = channelId, robloxUserId = m.id, username = m.name, text = text })
    local ok = Util.httpPost(relayURL() .. "/send", { ["X-API-Key"] = apiKey() }, payload)
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

    -- ---- left: channel rail ----
    local SIDE_W = 200
    local side = Instance.new("Frame")
    side.Position = UDim2.fromOffset(0, TB)
    side.Size = UDim2.new(0, SIDE_W, 1, -TB)
    side.BackgroundColor3 = C.side; side.BorderSizePixel = 0; side.ZIndex = 3; side.Parent = win

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
    chList.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y; chList.ZIndex = 4; chList.Parent = side
    local chLayout = Instance.new("UIListLayout"); chLayout.Padding = UDim.new(0,2)
    chLayout.SortOrder = Enum.SortOrder.LayoutOrder; chLayout.Parent = chList

    -- ---- right: messages + input ----
    local main = Instance.new("Frame")
    main.Position = UDim2.fromOffset(SIDE_W, TB); main.Size = UDim2.new(1, -SIDE_W, 1, -TB)
    main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0; main.ZIndex = 3; main.Parent = win

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
    feed.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y; feed.ZIndex = 4; feed.Parent = main
    local feedLayout = Instance.new("UIListLayout"); feedLayout.Padding = UDim.new(0,10)
    feedLayout.SortOrder = Enum.SortOrder.LayoutOrder; feedLayout.Parent = feed
    local feedPad = Instance.new("UIPadding"); feedPad.PaddingTop = UDim.new(0,8); feedPad.PaddingBottom = UDim.new(0,8)
    feedPad.PaddingRight = UDim.new(0,8); feedPad.Parent = feed

    -- input bar
    local inputWrap = Instance.new("Frame")
    inputWrap.Size = UDim2.new(1, -32, 0, 42); inputWrap.Position = UDim2.new(0, 16, 1, -50)
    inputWrap.BackgroundColor3 = C.input; inputWrap.BorderSizePixel = 0; inputWrap.ZIndex = 4; inputWrap.Parent = main
    Util.corner(inputWrap, 8)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -24, 1, 0); box.Position = UDim2.fromOffset(14, 0)
    box.BackgroundTransparency = 1; box.Text = ""; box.PlaceholderText = "Message"
    box.PlaceholderColor3 = C.muted; box.TextColor3 = C.text; box.Font = Theme.fonts.body
    box.TextSize = 14; box.TextXAlignment = Enum.TextXAlignment.Left; box.ClearTextOnFocus = false
    box.ClipsDescendants = true; box.ZIndex = 5; box.Parent = inputWrap

    -- ---- state ----
    local activeChannel, activeName
    local lastId
    local renderedIds = {}

    local function addMessage(m)
        if renderedIds[m.id] then return end
        renderedIds[m.id] = true
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 0); row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundTransparency = 1; row.ZIndex = 4; row.Parent = feed

        local av = Instance.new("ImageLabel")
        av.Size = UDim2.fromOffset(36, 36); av.Position = UDim2.fromOffset(4, 2)
        av.BackgroundColor3 = C.rail; av.BorderSizePixel = 0; av.ZIndex = 5; av.Parent = row
        Util.corner(av, 18)
        if m.avatar and m.avatar ~= "" then av.Image = m.avatar end

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Position = UDim2.fromOffset(50, 0); nameLbl.Size = UDim2.new(1, -58, 0, 18)
        nameLbl.BackgroundTransparency = 1; nameLbl.Text = m.author or "Unknown"
        nameLbl.Font = Theme.fonts.title; nameLbl.TextSize = 14
        nameLbl.TextColor3 = m.roblox and Color3.fromRGB(120, 200, 255) or C.bright
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.ZIndex = 5; nameLbl.Parent = row

        local content = Instance.new("TextLabel")
        content.Position = UDim2.fromOffset(50, 18); content.Size = UDim2.new(1, -58, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y; content.BackgroundTransparency = 1
        content.Text = m.content or ""; content.Font = Theme.fonts.body; content.TextSize = 14
        content.TextColor3 = C.text; content.TextWrapped = true
        content.TextXAlignment = Enum.TextXAlignment.Left; content.TextYAlignment = Enum.TextYAlignment.Top
        content.ZIndex = 5; content.Parent = row

        feed.CanvasPosition = Vector2.new(0, math.max(0, feed.AbsoluteCanvasSize.Y))
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
        local msgs = getMessages(id)
        clearFeed()
        if not msgs then notice("Couldn't reach the relay. Is it deployed and configured?") return end
        for _, m in ipairs(msgs) do addMessage(m); lastId = m.id end
        if btnHighlight then btnHighlight() end
    end

    -- build channel buttons
    local chButtons = {}
    local function highlightChannel(id)
        for cid, b in pairs(chButtons) do
            b.BackgroundColor3 = (cid == id) and C.active or C.side
            b.BackgroundTransparency = (cid == id) and 0 or 1
        end
    end

    local function loadChannels()
        if not configured() then
            serverName.Text = "Not configured"
            notice("The Discord relay URL isn't set yet. Deploy the relay and it'll connect automatically.")
            return
        end
        local chans = getChannels()
        if not chans then
            serverName.Text = "SYNC Server"
            notice("Couldn't reach the relay (" .. relayURL() .. "). Check it's running.")
            return
        end
        for _, ch in ipairs(chans) do
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
        -- auto-open first channel
        if chans[1] then selectChannel(chans[1].id, chans[1].name, function() highlightChannel(chans[1].id) end) end
    end

    -- send
    local function doSend()
        local text = box.Text
        if not text or text:gsub("%s", "") == "" then return end
        if not activeChannel then return end
        box.Text = ""
        task.spawn(function()
            local ok = sendMessage(activeChannel, text)
            if not ok then
                -- transient: show a local hint
                notice("Message didn't send (rate limited or filtered).")
            end
        end)
    end
    box.FocusLost:Connect(function(enter) if enter then doSend() end end)

    loadChannels()

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

    return { close = close }
end

return DiscordApp
