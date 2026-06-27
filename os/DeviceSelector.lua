-- SYNC / os / DeviceSelector
-- First-run Apple-style device picker (Mobile / Tablet / Desktop).
-- Vector device glyphs (built from frames, no emoji), soft modal shadow,
-- macOS-tuned spring animations. DeviceSelector.run(onChoose) shows the card and
-- calls onChoose(id) when picked, or onChoose(saved) if dismissed. Persisted via Util.

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local DeviceSelector = {}

local UI = {
    card        = Color3.fromRGB(255, 255, 255),
    cardRadius  = 24,
    optionBg    = Color3.fromRGB(244, 244, 248),
    optionHover = Color3.fromRGB(237, 237, 242),
    optionRad   = 16,
    accent      = Theme.accent,
    textPrimary = Color3.fromRGB(0, 0, 0),
    textSub     = Color3.fromRGB(142, 142, 147),
    closeBg     = Color3.fromRGB(233, 233, 238),
    closeHov    = Color3.fromRGB(214, 214, 219),
    hairline    = Color3.fromRGB(214, 214, 219),
    selectedBg  = Color3.fromRGB(233, 243, 255),
    wellBg      = Color3.fromRGB(255, 255, 255),
    backdropA   = 0.55,
}

-- macOS-flavored easing presets
local SPRING = { 0.5, Enum.EasingStyle.Back,    Enum.EasingDirection.Out }
local SMOOTH = { 0.28, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out }
local QUICK  = { 0.18, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out }

local function tw(inst, props, preset)
    return Util.tween(inst, props, preset[1], preset[2], preset[3])
end

-- ---------------------------------------------------------------------------
-- Vector device glyphs. Each returns { setColor = function(Color3) }.
-- Built from frames + strokes so they stay crisp and recolor on selection.
-- ---------------------------------------------------------------------------
local function buildIcon(parent, kind, color)
    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(44, 44)
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.fromScale(0.5, 0.5)
    box.BackgroundTransparency = 1
    box.Parent = parent

    local parts = {} -- { inst, prop }
    local function reg(inst, prop) parts[#parts + 1] = { inst = inst, prop = prop } end

    local function outline(w, h, radius, anchor, posScaleY, posOffY, thick)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.AnchorPoint = anchor
        f.Position = UDim2.new(0.5, 0, posScaleY, posOffY)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.Parent = box
        Util.corner(f, radius)
        local s = Util.stroke(f, color, thick or 2.4, 0)
        reg(s, "Color")
        return f
    end

    local function bar(w, h, radius, anchorY, parentFrame, offY)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.AnchorPoint = Vector2.new(0.5, anchorY)
        f.Position = UDim2.new(0.5, 0, anchorY, offY)
        f.BackgroundColor3 = color
        f.BorderSizePixel = 0
        f.Parent = parentFrame
        Util.corner(f, radius)
        reg(f, "BackgroundColor3")
        return f
    end

    if kind == "mobile" then
        local body = outline(24, 40, 7, Vector2.new(0.5, 0.5), 0.5, 0, 2.4)
        bar(8, 2, 1, 0, body, 5)        -- earpiece
        bar(10, 2.5, 1.25, 1, body, -5) -- home indicator
    elseif kind == "tablet" then
        local body = outline(40, 30, 6, Vector2.new(0.5, 0.5), 0.5, 0, 2.4)
        bar(14, 2.5, 1.25, 1, body, -5) -- home indicator
    else -- desktop
        outline(42, 27, 4, Vector2.new(0.5, 0), 0, 2, 2.4) -- screen
        local neck = Instance.new("Frame")
        neck.Size = UDim2.fromOffset(5, 5)
        neck.AnchorPoint = Vector2.new(0.5, 0)
        neck.Position = UDim2.new(0.5, 0, 0, 29)
        neck.BackgroundColor3 = color
        neck.BorderSizePixel = 0
        neck.Parent = box
        reg(neck, "BackgroundColor3")
        local base = Instance.new("Frame")
        base.Size = UDim2.fromOffset(22, 3)
        base.AnchorPoint = Vector2.new(0.5, 0)
        base.Position = UDim2.new(0.5, 0, 0, 34)
        base.BackgroundColor3 = color
        base.BorderSizePixel = 0
        base.Parent = box
        Util.corner(base, 1.5)
        reg(base, "BackgroundColor3")
    end

    return {
        setColor = function(c)
            for _, p in ipairs(parts) do
                Util.tween(p.inst, { [p.prop] = c }, 0.3)
            end
        end,
    }
end

function DeviceSelector.run(onChoose)
    local saved = Util.load("DevicePref")
    local vp = Util.viewport()
    local cardW, cardH = 384, 468
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
    Util.tween(backdrop, { BackgroundTransparency = 1 - UI.backdropA }, 0.45)

    -- Card
    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.Position = UDim2.fromOffset(cardX, cardY)
    card.BackgroundColor3 = UI.card
    card.BorderSizePixel = 0
    card.ZIndex = 2
    card.Parent = gui
    Util.corner(card, UI.cardRadius)
    local cardStroke = Util.stroke(card, UI.hairline, 1, 0.35)

    -- Soft shadow behind the card (sibling, fades in)
    local shadow = Util.shadow(card, 46, 1)
    Util.tween(shadow, { ImageTransparency = 0.5 }, 0.5)

    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 0.92
    cardScale.Parent = card
    tw(cardScale, { Scale = 1 }, SPRING)

    -- Close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 40, 18)
    closeBtn.BackgroundColor3 = UI.closeBg
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.Image = "rbxassetid://7072725342"
    closeBtn.ImageColor3 = UI.textSub
    closeBtn.ImageRectOffset = Vector2.new(0, 0)
    closeBtn.ZIndex = 3
    closeBtn.Parent = card
    Util.corner(closeBtn, 14)
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, { BackgroundColor3 = UI.closeHov }, QUICK) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, { BackgroundColor3 = UI.closeBg }, SMOOTH) end)

    -- Title + subtitle
    local title = Instance.new("TextLabel")
    title.Text = "Choose Your Device"
    title.Size = UDim2.fromOffset(cardW - 64, 30)
    title.Position = UDim2.fromOffset(28, 32)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.TextSize = 23
    title.TextColor3 = UI.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 3
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "How are you running SYNC?"
    subtitle.Size = UDim2.fromOffset(cardW - 64, 20)
    subtitle.Position = UDim2.fromOffset(28, 66)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Theme.fonts.caption
    subtitle.TextSize = 14
    subtitle.TextColor3 = UI.textSub
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 3
    subtitle.Parent = card

    local devices = {
        { id = "mobile",  title = "Mobile",  desc = "Phone-optimized layout" },
        { id = "tablet",  title = "Tablet",  desc = "Tablet-optimized layout" },
        { id = "desktop", title = "Desktop", desc = "Full desktop experience" },
    }

    local startY, spacing, optH = 110, 14, 88
    local optW, optX = cardW - 48, 24

    local options = {}
    local selectedId = saved
    local closing = false

    local function paint(opt, sel, animate)
        local set = animate and tw or function(i, p) for k, v in pairs(p) do i[k] = v end end
        set(opt.bg,        { BackgroundColor3 = sel and UI.selectedBg or UI.optionBg }, SMOOTH)
        set(opt.stroke,    { Transparency = sel and 0 or 1 }, SMOOTH)
        set(opt.well,      { BackgroundColor3 = sel and UI.accent or UI.wellBg }, SMOOTH)
        set(opt.wellStroke,{ Transparency = sel and 1 or 0.5 }, SMOOTH)
        opt.icon.setColor(sel and Color3.fromRGB(255, 255, 255) or UI.accent)
    end

    local function applySelection(id, animate)
        selectedId = id
        for _, opt in ipairs(options) do
            paint(opt, opt.id == id, animate)
        end
    end

    local function closeMenu(chosen)
        if closing then return end
        closing = true
        for i, opt in ipairs(options) do
            task.delay(0.035 * (i - 1), function()
                tw(opt.bg, { BackgroundTransparency = 1 }, QUICK)
                tw(opt.label, { TextTransparency = 1 }, QUICK)
                tw(opt.desc, { TextTransparency = 1 }, QUICK)
                tw(opt.stroke, { Transparency = 1 }, QUICK)
                tw(opt.well, { BackgroundTransparency = 1 }, QUICK)
                tw(opt.wellStroke, { Transparency = 1 }, QUICK)
                opt.icon.setColor(opt.id == selectedId and Color3.fromRGB(255,255,255) or UI.accent)
            end)
        end
        task.delay(0.18, function()
            tw(title, { TextTransparency = 1 }, QUICK)
            tw(subtitle, { TextTransparency = 1 }, QUICK)
            tw(closeBtn, { BackgroundTransparency = 1, ImageTransparency = 1 }, QUICK)
        end)
        task.delay(0.32, function()
            Util.tween(cardScale, { Scale = 0.94 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            tw(card, { BackgroundTransparency = 1 }, SMOOTH)
            tw(cardStroke, { Transparency = 1 }, SMOOTH)
            tw(shadow, { ImageTransparency = 1 }, SMOOTH)
        end)
        task.delay(0.5, function() Util.tween(backdrop, { BackgroundTransparency = 1 }, 0.35) end)
        task.delay(0.95, function()
            gui:Destroy()
            if onChoose then onChoose(chosen) end
        end)
    end

    for i, device in ipairs(devices) do
        local yPos = startY + (i - 1) * (optH + spacing)

        local opt = Instance.new("TextButton")
        opt.Text = ""
        opt.AutoButtonColor = false
        opt.Size = UDim2.fromOffset(optW, optH)
        opt.Position = UDim2.fromOffset(optX, yPos)
        opt.BackgroundColor3 = UI.optionBg
        opt.BorderSizePixel = 0
        opt.ZIndex = 3
        opt.Parent = card
        Util.corner(opt, UI.optionRad)
        local optStroke = Util.stroke(opt, UI.accent, 2, 1)

        -- Icon well
        local well = Instance.new("Frame")
        well.Size = UDim2.fromOffset(56, 56)
        well.Position = UDim2.fromOffset(14, (optH - 56) / 2)
        well.BackgroundColor3 = UI.wellBg
        well.BorderSizePixel = 0
        well.ZIndex = 4
        well.Parent = opt
        Util.corner(well, 15)
        local wellStroke = Util.stroke(well, UI.hairline, 1, 0.5)

        local icon = buildIcon(well, device.id, UI.accent)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = device.title
        titleLabel.Size = UDim2.fromOffset(optW - 100, 22)
        titleLabel.Position = UDim2.fromOffset(86, 22)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Theme.fonts.title
        titleLabel.TextSize = 17
        titleLabel.TextColor3 = UI.textPrimary
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        titleLabel.ZIndex = 4
        titleLabel.Parent = opt

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = device.desc
        descLabel.Size = UDim2.fromOffset(optW - 100, 18)
        descLabel.Position = UDim2.fromOffset(86, 47)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Theme.fonts.caption
        descLabel.TextSize = 13
        descLabel.TextColor3 = UI.textSub
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.ZIndex = 4
        descLabel.Parent = opt

        local optScale = Instance.new("UIScale")
        optScale.Parent = opt

        local data = {
            id = device.id, bg = opt, stroke = optStroke, well = well,
            wellStroke = wellStroke, icon = icon, label = titleLabel,
            desc = descLabel, scale = optScale,
        }
        options[#options + 1] = data

        opt.MouseEnter:Connect(function()
            if data.id ~= selectedId then tw(opt, { BackgroundColor3 = UI.optionHover }, QUICK) end
            tw(optScale, { Scale = 1.02 }, QUICK)
        end)
        opt.MouseLeave:Connect(function()
            tw(opt, { BackgroundColor3 = (data.id == selectedId) and UI.selectedBg or UI.optionBg }, SMOOTH)
            tw(optScale, { Scale = 1 }, SMOOTH)
        end)
        opt.MouseButton1Down:Connect(function()
            tw(optScale, { Scale = 0.97 }, QUICK)
        end)
        opt.MouseButton1Click:Connect(function()
            applySelection(data.id, true)
            tw(optScale, { Scale = 1 }, SPRING)
            task.delay(0.22, function()
                Util.save("DevicePref", data.id)
                closeMenu(data.id)
            end)
        end)
    end

    if selectedId then
        applySelection(selectedId, false)
    end

    closeBtn.MouseButton1Click:Connect(function() closeMenu(selectedId) end)

    return gui
end

return DeviceSelector
