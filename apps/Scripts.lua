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
    status.Position = UDim2.fromOffset(PAD + 6, TB + 140)
    status.Size = UDim2.new(1, -PAD * 2 - 110, 0, 16)
    status.ZIndex = 3
    status.Parent = win

    -- Sort chip (cycles Recent / Popular / Top rated), right of the status row
    local sortChip = Instance.new("TextButton")
    sortChip.AutoButtonColor = false
    sortChip.Text = ""
    sortChip.AnchorPoint = Vector2.new(1, 0.5)
    sortChip.Position = UDim2.new(1, -PAD, 0, TB + 148)
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
    local gridY = TB + 164
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
            return "Results for \"" .. curQuery .. "\"" .. count .. " · Powered by RScripts.io"
        end
        return curSort().heading .. count .. " · Powered by RScripts.io"
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
            local pill = Instance.new("TextLabel")
            pill.Text = "VERIFIED"
            pill.Font = BODY_BOLD
            pill.TextSize = 10
            pill.TextColor3 = WHITE
            pill.BackgroundColor3 = BLURPLE
            pill.AnchorPoint = Vector2.new(1, 0)
            pill.Position = UDim2.new(1, -10, 0, 10)
            pill.Size = UDim2.fromOffset(64, 20)
            pill.ZIndex = 6
            pill.Parent = body
            Util.corner(pill, 6)
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
            local kp = Instance.new("TextLabel")
            kp.Text = "KEY"
            kp.Font = BODY_BOLD
            kp.TextSize = 10
            kp.TextColor3 = WHITE
            kp.BackgroundColor3 = Color3.fromRGB(176, 108, 34)
            kp.Position = UDim2.fromOffset(10, 10)
            kp.Size = UDim2.fromOffset(38, 20)
            kp.ZIndex = 6
            kp.Parent = body
            Util.corner(kp, 6)
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
        -- per-card busy overlay (dim + spinner) while this card is executing
        local busy = Instance.new("Frame")
        busy.Size = UDim2.fromScale(1, 1)
        busy.BackgroundColor3 = Color3.new(0, 0, 0)
        busy.BackgroundTransparency = 1
        busy.Visible = false
        busy.ZIndex = 8
        busy.Parent = body
        Util.corner(busy, 12)
        local busySpin = Instance.new("ImageLabel")
        busySpin.Size = UDim2.fromOffset(28, 28)
        busySpin.AnchorPoint = Vector2.new(0.5, 0.5)
        busySpin.Position = UDim2.fromScale(0.5, 0.5)
        busySpin.BackgroundTransparency = 1
        busySpin.ZIndex = 9
        busySpin.Parent = busy
        Icons.apply(busySpin, "orbit", WHITE)
        local busyTween = game:GetService("TweenService"):Create(
            busySpin, TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })

        local running = false
        c.MouseButton1Click:Connect(function()
            if running then return end
            if not s.rawScript then
                status.Text = "No raw script for \"" .. (s.title or "?") .. "\""
                status.TextColor3 = RED
                return
            end
            running = true
            busy.Visible = true
            busyTween:Play()
            Util.tween(busy, { BackgroundTransparency = 0.45 }, 0.15)
            status.Text = "Running " .. (s.title or "script") .. "..."
            status.TextColor3 = SUB
            task.spawn(function()
                -- SYNC runs it in-game itself (no paste): fetch with retries,
                -- then loadstring + protected run via the shared executor.
                local ok, err = Executor.runUrl(s.rawScript, s.title)
                running = false
                busyTween:Pause()
                busy.Visible = false
                busy.BackgroundTransparency = 1
                if not alive then return end
                if ok then
                    status.Text = "Executed " .. (s.title or "script")
                    status.TextColor3 = GREEN
                    flash(GREEN)
                    if s.rawScript then ranSet[s.rawScript] = true end
                    markRan()
                else
                    status.Text = (s.title or "script") .. ": " .. tostring(err):sub(1, 90)
                    status.TextColor3 = RED
                    flash(RED)
                end
            end)
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
