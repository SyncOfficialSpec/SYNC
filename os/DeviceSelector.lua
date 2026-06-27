-- SYNC / os / DeviceSelector
-- First-run Apple-style device picker (Mobile / Tablet / Desktop).
-- macOS frosted dark panel (blur faked with translucency), colored icon tiles
-- with filled white glyphs + selected checkmark, macOS-tuned spring animations.
-- DeviceSelector.run(onChoose): onChoose(id) on pick, onChoose(saved) on dismiss.

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local DeviceSelector = {}

local ACCENT = Color3.fromRGB(10, 132, 255)
local WHITE  = Color3.fromRGB(255, 255, 255)

-- Per-device tile gradient + glyph kind
local DEVICES = {
    { id = "mobile",  title = "Mobile",  desc = "Phone-optimized layout",
      top = Color3.fromRGB(52, 199, 89),  bot = Color3.fromRGB(40, 167, 69) },
    { id = "tablet",  title = "Tablet",  desc = "Tablet-optimized layout",
      top = Color3.fromRGB(10, 132, 255), bot = Color3.fromRGB(0, 96, 223) },
    { id = "desktop", title = "Desktop", desc = "Full desktop experience",
      top = Color3.fromRGB(94, 92, 230),  bot = Color3.fromRGB(75, 63, 214) },
}

-- macOS frosted dark style (blur faked with translucency)
local S = {
    cardColor = Color3.fromRGB(40, 40, 48), cardTransp = 0.16,
    cardStroke = WHITE, cardStrokeTransp = 0.86,
    titleColor = Color3.fromRGB(245, 245, 247), subColor = Color3.fromRGB(160, 160, 168),
    descColor = Color3.fromRGB(152, 152, 159),
    rowColor = WHITE, rowTransp = 0.93,
    hoverColor = WHITE, hoverTransp = 0.88,
    selColor = ACCENT, selTransp = 0.8,
    selStroke = ACCENT,
    closeColor = WHITE, closeTransp = 0.86, closeHover = WHITE, closeHoverTransp = 0.78,
    closeIcon = Color3.fromRGB(210, 210, 217),
    backdropA = 0.6,
}

-- macOS-flavored easing presets
local SPRING = { 0.5, Enum.EasingStyle.Back,  Enum.EasingDirection.Out }
local SMOOTH = { 0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out }
local QUICK  = { 0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out }

local function tw(inst, props, preset)
    return Util.tween(inst, props, preset[1], preset[2], preset[3])
end

-- ---------------------------------------------------------------------------
-- Colored icon tile with filled white glyph
-- ---------------------------------------------------------------------------
local function buildTile(parent, device)
    local tile = Instance.new("Frame")
    tile.Size = UDim2.fromOffset(50, 50)
    tile.Position = UDim2.fromOffset(14, 12)
    tile.BackgroundColor3 = device.top
    tile.BorderSizePixel = 0
    tile.ZIndex = 5
    tile.Parent = parent
    Util.corner(tile, 13)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(device.top, device.bot)
    grad.Rotation = 90
    grad.Parent = tile

    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(28, 28)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.ZIndex = 6
    box.Parent = tile

    local function fill(w, h, radius, ax, ay, px, pxoff, py, pyoff, transp)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.AnchorPoint = Vector2.new(ax, ay)
        f.Position = UDim2.new(px, pxoff, py, pyoff)
        f.BackgroundColor3 = WHITE
        f.BackgroundTransparency = transp or 0
        f.BorderSizePixel = 0
        f.ZIndex = 6
        f.Parent = box
        if radius and radius > 0 then Util.corner(f, radius) end
        return f
    end

    if device.id == "mobile" then
        local body = fill(15, 25, 4, 0.5, 0.5, 0.5, 0, 0.5, 0)
        fill(7, 1.6, 0.8, 0.5, 1, 0.5, 0, 1, -3, 0.45)
        body.Parent = box
    elseif device.id == "tablet" then
        fill(26, 19, 4, 0.5, 0.5, 0.5, 0, 0.5, 0)
        fill(8, 1.6, 0.8, 0.5, 1, 0.5, 0, 0.5, 8, 0.45)
    else -- desktop
        fill(26, 16, 3, 0.5, 0, 0.5, 0, 0, 1)        -- screen
        fill(4, 4, 0, 0.5, 0, 0.5, 0, 0, 17)         -- neck
        fill(14, 2.6, 1.3, 0.5, 0, 0.5, 0, 0, 21)    -- base
    end

    return tile
end

-- ---------------------------------------------------------------------------
-- Selected checkmark: accent circle + white tick (built from two frames)
-- Returns { show(animate), hide() }
-- ---------------------------------------------------------------------------
local function buildCheck(parent)
    local c = Instance.new("Frame")
    c.Size = UDim2.fromOffset(22, 22)
    c.AnchorPoint = Vector2.new(1, 0.5)
    c.Position = UDim2.new(1, -16, 0.5, 0)
    c.BackgroundColor3 = ACCENT
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.ZIndex = 6
    c.Parent = parent
    Util.corner(c, 11)

    local scale = Instance.new("UIScale")
    scale.Scale = 0.4
    scale.Parent = c

    local long = Instance.new("Frame")
    long.Size = UDim2.fromOffset(11, 2.6)
    long.AnchorPoint = Vector2.new(0.5, 0.5)
    long.Position = UDim2.new(0.5, 1.5, 0.5, -1)
    long.Rotation = -45
    long.BackgroundColor3 = WHITE
    long.BackgroundTransparency = 1
    long.BorderSizePixel = 0
    long.ZIndex = 7
    long.Parent = c
    Util.corner(long, 1.3)

    local short = Instance.new("Frame")
    short.Size = UDim2.fromOffset(6, 2.6)
    short.AnchorPoint = Vector2.new(0.5, 0.5)
    short.Position = UDim2.new(0.5, -4, 0.5, 2)
    short.Rotation = 45
    short.BackgroundColor3 = WHITE
    short.BackgroundTransparency = 1
    short.BorderSizePixel = 0
    short.ZIndex = 7
    short.Parent = c
    Util.corner(short, 1.3)

    return {
        show = function(animate)
            if animate then
                tw(c, { BackgroundTransparency = 0 }, QUICK)
                tw(long, { BackgroundTransparency = 0 }, QUICK)
                tw(short, { BackgroundTransparency = 0 }, QUICK)
                tw(scale, { Scale = 1 }, SPRING)
            else
                c.BackgroundTransparency = 0
                long.BackgroundTransparency = 0
                short.BackgroundTransparency = 0
                scale.Scale = 1
            end
        end,
        hide = function()
            tw(c, { BackgroundTransparency = 1 }, QUICK)
            tw(long, { BackgroundTransparency = 1 }, QUICK)
            tw(short, { BackgroundTransparency = 1 }, QUICK)
            scale.Scale = 0.4
        end,
    }
end

function DeviceSelector.run(onChoose)
    local saved = Util.load("DevicePref")
    local vp = Util.viewport()

    local cardW = 384
    local optH, spacing, optX = 74, 12, 20
    local optW = cardW - 40
    local startY = 104
    local cardH = startY + (#DEVICES * optH) + ((#DEVICES - 1) * spacing) + 22
    local cardX, cardY = (vp.X - cardW) / 2, (vp.Y - cardH) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_DeviceSelector"
    Util.mount(gui)

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = gui
    Util.tween(backdrop, { BackgroundTransparency = 1 - S.backdropA }, 0.45)

    -- Card (CanvasGroup so the whole panel can fade uniformly on close)
    local card = Instance.new("CanvasGroup")
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.Position = UDim2.fromOffset(cardX, cardY)
    card.BackgroundColor3 = S.cardColor
    card.BackgroundTransparency = S.cardTransp
    card.BorderSizePixel = 0
    card.GroupTransparency = 0
    card.ZIndex = 2
    card.Parent = gui
    Util.corner(card, 26)
    local cardStroke = Util.stroke(card, S.cardStroke, 1, S.cardStrokeTransp)

    local shadow = Util.shadow(card, 26, 1)
    Util.tween(shadow, { ImageTransparency = 0.65 }, 0.5)

    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 0.92
    cardScale.Parent = card
    tw(cardScale, { Scale = 1 }, SPRING)

    -- Close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 40, 18)
    closeBtn.BackgroundColor3 = S.closeColor
    closeBtn.BackgroundTransparency = S.closeTransp
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Image = "rbxassetid://7072725342"
    closeBtn.ImageColor3 = S.closeIcon
    closeBtn.ZIndex = 4
    closeBtn.Parent = card
    Util.corner(closeBtn, 14)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, { BackgroundColor3 = S.closeHover, BackgroundTransparency = S.closeHoverTransp or S.closeTransp }, QUICK)
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, { BackgroundColor3 = S.closeColor, BackgroundTransparency = S.closeTransp }, SMOOTH)
    end)

    -- Title + subtitle
    local title = Instance.new("TextLabel")
    title.Text = "Choose Your Device"
    title.Size = UDim2.fromOffset(cardW - 80, 30)
    title.Position = UDim2.fromOffset(26, 30)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.TextSize = 23
    title.TextColor3 = S.titleColor
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "How are you running SYNC?"
    subtitle.Size = UDim2.fromOffset(cardW - 80, 20)
    subtitle.Position = UDim2.fromOffset(26, 64)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Theme.fonts.caption
    subtitle.TextSize = 14
    subtitle.TextColor3 = S.subColor
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 3
    subtitle.Parent = card

    local options = {}
    local selectedId = saved
    local closing = false

    local function setRow(opt, state)
        if state == "selected" then
            tw(opt.bg, { BackgroundColor3 = S.selColor, BackgroundTransparency = S.selTransp }, SMOOTH)
            tw(opt.stroke, { Transparency = 0 }, SMOOTH)
        elseif state == "hover" then
            tw(opt.bg, { BackgroundColor3 = S.hoverColor, BackgroundTransparency = S.hoverTransp }, QUICK)
            tw(opt.stroke, { Transparency = 1 }, QUICK)
        else
            tw(opt.bg, { BackgroundColor3 = S.rowColor, BackgroundTransparency = S.rowTransp }, SMOOTH)
            tw(opt.stroke, { Transparency = 1 }, SMOOTH)
        end
    end

    local function applySelection(id, animate)
        selectedId = id
        for _, opt in ipairs(options) do
            if opt.id == id then
                if animate then setRow(opt, "selected") else
                    opt.bg.BackgroundColor3 = S.selColor
                    opt.bg.BackgroundTransparency = S.selTransp
                    opt.stroke.Transparency = 0
                end
                opt.check.show(animate)
            else
                if animate then setRow(opt, "normal") else
                    opt.bg.BackgroundColor3 = S.rowColor
                    opt.bg.BackgroundTransparency = S.rowTransp
                    opt.stroke.Transparency = 1
                end
                opt.check.hide()
            end
        end
    end

    local function closeMenu(chosen)
        if closing then return end
        closing = true
        -- The whole card fades and shrinks as one unit (CanvasGroup), so nothing
        -- lingers. Backdrop and shadow fade alongside it. Fast and clean.
        Util.tween(card, { GroupTransparency = 1 }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        Util.tween(cardScale, { Scale = 0.95 }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Util.tween(shadow, { ImageTransparency = 1 }, 0.2)
        Util.tween(backdrop, { BackgroundTransparency = 1 }, 0.24)
        task.delay(0.26, function()
            gui:Destroy()
            if onChoose then onChoose(chosen) end
        end)
    end

    for i, device in ipairs(DEVICES) do
        local yPos = startY + (i - 1) * (optH + spacing)

        local opt = Instance.new("TextButton")
        opt.Text = ""
        opt.AutoButtonColor = false
        opt.Size = UDim2.fromOffset(optW, optH)
        opt.Position = UDim2.fromOffset(optX, yPos)
        opt.BackgroundColor3 = S.rowColor
        opt.BackgroundTransparency = S.rowTransp
        opt.BorderSizePixel = 0
        opt.ZIndex = 3
        opt.Parent = card
        Util.corner(opt, 16)
        local optStroke = Util.stroke(opt, S.selStroke, 2, 1)

        local tile = buildTile(opt, device)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = device.title
        titleLabel.Size = UDim2.fromOffset(optW - 120, 20)
        titleLabel.Position = UDim2.fromOffset(78, 17)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Theme.fonts.title
        titleLabel.TextSize = 16
        titleLabel.TextColor3 = S.titleColor
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        titleLabel.ZIndex = 5
        titleLabel.Parent = opt

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = device.desc
        descLabel.Size = UDim2.fromOffset(optW - 120, 18)
        descLabel.Position = UDim2.fromOffset(78, 39)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Theme.fonts.caption
        descLabel.TextSize = 13
        descLabel.TextColor3 = S.descColor
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.ZIndex = 5
        descLabel.Parent = opt

        local check = buildCheck(opt)

        local optScale = Instance.new("UIScale")
        optScale.Parent = opt

        local data = {
            id = device.id, bg = opt, stroke = optStroke, tile = tile,
            label = titleLabel, desc = descLabel, check = check, scale = optScale,
        }
        options[#options + 1] = data

        opt.MouseEnter:Connect(function()
            if data.id ~= selectedId then setRow(data, "hover") end
            tw(optScale, { Scale = 1.02 }, QUICK)
        end)
        opt.MouseLeave:Connect(function()
            setRow(data, data.id == selectedId and "selected" or "normal")
            tw(optScale, { Scale = 1 }, SMOOTH)
        end)
        opt.MouseButton1Down:Connect(function() tw(optScale, { Scale = 0.97 }, QUICK) end)
        opt.MouseButton1Click:Connect(function()
            applySelection(data.id, true)
            tw(optScale, { Scale = 1 }, SPRING)
            task.delay(0.24, function()
                Util.save("DevicePref", data.id)
                closeMenu(data.id)
            end)
        end)
    end

    if selectedId then applySelection(selectedId, false) end

    closeBtn.MouseButton1Click:Connect(function() closeMenu(selectedId) end)

    return gui
end

return DeviceSelector
