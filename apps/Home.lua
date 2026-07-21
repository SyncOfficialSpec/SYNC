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

    -- Outside-click catcher
    local catcher = Instance.new("TextButton")
    catcher.Text = ""
    catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)
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

    local function renderUniversal(list)
        for _, m in ipairs(list) do
            lastUniversalId = m.id
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
        -- first fetch dumps recent history; render only the tail
        local first = fetchUniversal()
        if first and alive then
            if #first > 15 then
                local tail = {}
                for i = #first - 14, #first do tail[#tail + 1] = first[i] end
                -- keep pagination anchored to the true newest message
                for _, m in ipairs(first) do lastUniversalId = m.id end
                renderUniversal(tail)
            else
                renderUniversal(first)
            end
        end
        while alive and gui.Parent do
            -- 2.5s when the chat is open, 6s in the background (unread badge)
            local ticks = chatView.Visible and 5 or 12
            for _ = 1, ticks do
                if not alive then return end
                task.wait(0.5)
            end
            local list = fetchUniversal()
            if list and alive then renderUniversal(list) end
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

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.fromOffset(THUMB_W, THUMB_H)
            thumb.Position = UDim2.fromOffset(0, y)
            thumb.BackgroundColor3 = FIELD
            thumb.ScaleType = Enum.ScaleType.Crop
            thumb.ZIndex = 5
            thumb.Parent = faScroll
            Util.corner(thumb, 12)
            Util.stroke(thumb, WHITE, 1, 0.86)

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
    cardTitle(serverCard, "Server")

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

            -- hover shows who it is (and that green means joinable)
            av.MouseEnter:Connect(function()
                friendsTitle.Text = (fr.DisplayName or fr.UserName or "?")
                    .. (inGame and "  ·  click to join" or "")
            end)
            av.MouseLeave:Connect(function()
                friendsTitle.Text = titleDefault
            end)
            av.MouseButton1Click:Connect(function()
                if inGame then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(fr.PlaceId, fr.GameId, lp)
                    end)
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
