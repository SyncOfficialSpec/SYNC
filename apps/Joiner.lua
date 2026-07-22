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
