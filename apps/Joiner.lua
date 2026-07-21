-- SYNC / apps / Joiner
-- Two tools in one window:
--   1. Invite  - copy a link that drops someone into the EXACT server you're in.
--   2. Join    - paste anyone's game/server link and jump straight into it.
--
-- Joiner.open() -> builds the window (a single instance).

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Joiner = {}

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
-- start links, /games/<id> links, or a bare id. Returns placeId, jobId|nil.
local function parseLink(text)
    text = tostring(text or ""):gsub("%s+", "")
    if text == "" then return nil end
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

    local cardW, cardH = 480, 452
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

    local catcher = Instance.new("TextButton")
    catcher.Text = ""
    catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)
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

    -- ============ 1. INVITE ============
    section("YOUR SERVER", TB + 12)
    local c1 = card(TB + 32, 150)

    local i1 = Instance.new("ImageLabel")
    i1.Size = UDim2.fromOffset(18, 18)
    i1.Position = UDim2.fromOffset(16, 16)
    i1.BackgroundTransparency = 1
    i1.ImageColor3 = VIOLET
    i1.ZIndex = 4
    i1.Parent = c1
    loadIcon(i1, "link", VIOLET)

    local t1 = Instance.new("TextLabel")
    t1.Text = "Invite someone to your server"
    t1.Position = UDim2.fromOffset(42, 14)
    t1.Size = UDim2.fromOffset(cardW - 90, 20)
    t1.BackgroundTransparency = 1
    t1.Font = Theme.fonts.title
    t1.TextSize = 15
    t1.TextColor3 = WHITE
    t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.ZIndex = 4
    t1.Parent = c1

    local d1 = Instance.new("TextLabel")
    d1.Text = "Copy this link and send it. They'll join the exact server you're in right now."
    d1.Position = UDim2.fromOffset(16, 40)
    d1.Size = UDim2.fromOffset(cardW - 64, 32)
    d1.BackgroundTransparency = 1
    d1.Font = Theme.fonts.caption
    d1.TextSize = 12
    d1.TextColor3 = SUB
    d1.TextWrapped = true
    d1.TextXAlignment = Enum.TextXAlignment.Left
    d1.TextYAlignment = Enum.TextYAlignment.Top
    d1.ZIndex = 4
    d1.Parent = c1

    -- link preview pill (read-only, truncated)
    local prev = Instance.new("TextLabel")
    prev.Position = UDim2.fromOffset(16, 80)
    prev.Size = UDim2.fromOffset(cardW - 64, 26)
    prev.BackgroundColor3 = FIELD
    prev.BackgroundTransparency = 0.15
    prev.Font = Enum.Font.Code
    prev.Text = "  " .. inviteLink()
    prev.TextSize = 11
    prev.TextColor3 = Color3.fromRGB(170, 170, 178)
    prev.TextXAlignment = Enum.TextXAlignment.Left
    prev.TextTruncate = Enum.TextTruncate.AtEnd
    prev.ClipsDescendants = true
    prev.ZIndex = 4
    prev.Parent = c1
    Util.corner(prev, 7)

    local copyBtn = Instance.new("TextButton")
    copyBtn.Position = UDim2.fromOffset(16, 114)
    copyBtn.Size = UDim2.fromOffset(cardW - 64, 24)
    copyBtn.BackgroundColor3 = VIOLET
    copyBtn.AutoButtonColor = false
    copyBtn.Font = Theme.fonts.title
    copyBtn.Text = "Copy invite link"
    copyBtn.TextSize = 13
    copyBtn.TextColor3 = Color3.fromRGB(26, 22, 40)
    copyBtn.BorderSizePixel = 0
    copyBtn.ZIndex = 4
    copyBtn.Parent = c1
    Util.corner(copyBtn, 8)
    copyBtn.MouseEnter:Connect(function() Util.tween(copyBtn, { BackgroundColor3 = Color3.fromRGB(186, 166, 255) }, 0.12) end)
    copyBtn.MouseLeave:Connect(function() Util.tween(copyBtn, { BackgroundColor3 = VIOLET }, 0.12) end)
    copyBtn.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(inviteLink()) end)
        copyBtn.Text = ok and "Copied to clipboard" or "Clipboard not available"
        task.delay(1.4, function() if copyBtn.Parent then copyBtn.Text = "Copy invite link" end end)
    end)

    -- ============ 2. JOIN ============
    section("JOIN A FRIEND", TB + 200)
    local c2 = card(TB + 220, 150)

    local i2 = Instance.new("ImageLabel")
    i2.Size = UDim2.fromOffset(18, 18)
    i2.Position = UDim2.fromOffset(16, 16)
    i2.BackgroundTransparency = 1
    i2.ImageColor3 = GREEN
    i2.ZIndex = 4
    i2.Parent = c2
    loadIcon(i2, "log-in", GREEN)

    local t2 = Instance.new("TextLabel")
    t2.Text = "Join someone's game"
    t2.Position = UDim2.fromOffset(42, 14)
    t2.Size = UDim2.fromOffset(cardW - 90, 20)
    t2.BackgroundTransparency = 1
    t2.Font = Theme.fonts.title
    t2.TextSize = 15
    t2.TextColor3 = WHITE
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.ZIndex = 4
    t2.Parent = c2

    local d2 = Instance.new("TextLabel")
    d2.Text = "Paste their game or server link below, then hit Join to jump into it."
    d2.Position = UDim2.fromOffset(16, 40)
    d2.Size = UDim2.fromOffset(cardW - 64, 16)
    d2.BackgroundTransparency = 1
    d2.Font = Theme.fonts.caption
    d2.TextSize = 12
    d2.TextColor3 = SUB
    d2.TextXAlignment = Enum.TextXAlignment.Left
    d2.ZIndex = 4
    d2.Parent = c2

    -- paste field
    local fh = Instance.new("Frame")
    fh.Position = UDim2.fromOffset(16, 66)
    fh.Size = UDim2.fromOffset(cardW - 158, 30)
    fh.BackgroundColor3 = FIELD
    fh.BorderSizePixel = 0
    fh.ZIndex = 4
    fh.Parent = c2
    Util.corner(fh, 8)
    local fSt = Util.stroke(fh, STROKE, 1, 0.45)

    local input = Instance.new("TextBox")
    input.Position = UDim2.fromOffset(12, 0)
    input.Size = UDim2.fromOffset(cardW - 158 - 24, 30)
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

    local joinBtn = Instance.new("TextButton")
    joinBtn.Position = UDim2.fromOffset(cardW - 132, 66)
    joinBtn.Size = UDim2.fromOffset(100, 30)
    joinBtn.BackgroundColor3 = GREEN
    joinBtn.AutoButtonColor = false
    joinBtn.Font = Theme.fonts.title
    joinBtn.Text = "Join"
    joinBtn.TextSize = 13
    joinBtn.TextColor3 = Color3.fromRGB(12, 32, 22)
    joinBtn.BorderSizePixel = 0
    joinBtn.ZIndex = 4
    joinBtn.Parent = c2
    Util.corner(joinBtn, 8)
    joinBtn.MouseEnter:Connect(function() Util.tween(joinBtn, { BackgroundColor3 = Color3.fromRGB(92, 220, 165) }, 0.12) end)
    joinBtn.MouseLeave:Connect(function() Util.tween(joinBtn, { BackgroundColor3 = GREEN }, 0.12) end)

    local status = Instance.new("TextLabel")
    status.Position = UDim2.fromOffset(16, 106)
    status.Size = UDim2.fromOffset(cardW - 64, 30)
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
        local pid, jid = parseLink(input.Text)
        if not pid then
            setStatus("Couldn't find a game in that link. Paste a roblox.com game or server link.", Color3.fromRGB(255, 120, 110))
            return
        end
        joining = true
        joinBtn.Text = "Joining"
        if jid then
            setStatus("Joining their exact server...", GREEN)
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
