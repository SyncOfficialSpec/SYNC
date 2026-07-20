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
