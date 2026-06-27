-- SYNC / os / DeviceSelector
-- First-run Apple-style device picker (Mobile / Tablet / Desktop).
-- Adapted from the original standalone SyncDeviceSelector into a SYNC module.
-- DeviceSelector.run(onChoose) shows the card and calls onChoose(id) when picked
-- (or onChoose(savedOrNil) if dismissed). The choice is persisted via Util.

local TweenService = game:GetService("TweenService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local DeviceSelector = {}

local UI = {
    cardColor   = Color3.fromRGB(255, 255, 255),
    cardRadius  = 22,
    optionBg    = Color3.fromRGB(242, 242, 247),
    optionHover = Color3.fromRGB(235, 235, 241),
    optionRad   = 14,
    accent      = Theme.accent,
    textPrimary = Color3.fromRGB(0, 0, 0),
    textSub     = Color3.fromRGB(142, 142, 147),
    closeBg     = Color3.fromRGB(229, 229, 234),
    closeHov    = Color3.fromRGB(209, 209, 214),
    stroke      = Color3.fromRGB(210, 210, 215),
    selected    = Color3.fromRGB(230, 242, 255),
    backdropA   = 0.65,
}

function DeviceSelector.run(onChoose)
    local saved = Util.load("DevicePref")
    local vp = Util.viewport()
    local screenW, screenH = vp.X, vp.Y

    local cardW, cardH = 380, 460
    local cardX, cardY = (screenW - cardW) / 2, (screenH - cardH) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_DeviceSelector"
    Util.mount(gui)

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Parent = gui
    Util.tween(backdrop, { BackgroundTransparency = 1 - UI.backdropA }, 0.4)

    -- Card
    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.Position = UDim2.fromOffset(cardX, cardY)
    card.BackgroundColor3 = UI.cardColor
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = gui
    Util.corner(card, UI.cardRadius)
    local cardStroke = Util.stroke(card, UI.stroke, 0.5, 0.3)

    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 0
    cardScale.Parent = card
    Util.tween(cardScale, { Scale = 1 }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 38, 16)
    closeBtn.BackgroundColor3 = UI.closeBg
    closeBtn.BorderSizePixel = 0
    closeBtn.Image = "rbxassetid://7072725342"
    closeBtn.ImageColor3 = UI.textSub
    closeBtn.Parent = card
    Util.corner(closeBtn, 14)
    closeBtn.MouseEnter:Connect(function()
        Util.tween(closeBtn, { BackgroundColor3 = UI.closeHov }, 0.2)
    end)
    closeBtn.MouseLeave:Connect(function()
        Util.tween(closeBtn, { BackgroundColor3 = UI.closeBg }, 0.3)
    end)

    -- Title + subtitle
    local title = Instance.new("TextLabel")
    title.Text = "Choose Your Device"
    title.Size = UDim2.fromOffset(cardW - 60, 30)
    title.Position = UDim2.fromOffset(30, 32)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.TextSize = 22
    title.TextColor3 = UI.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Text = "Select the device you're using"
    subtitle.Size = UDim2.fromOffset(cardW - 60, 20)
    subtitle.Position = UDim2.fromOffset(30, 66)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Theme.fonts.light
    subtitle.TextSize = 14
    subtitle.TextColor3 = UI.textSub
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = card

    local devices = {
        { id = "mobile",  icon = "📱", title = "Mobile",  desc = "Phone-optimized layout" },
        { id = "tablet",  icon = "💻", title = "Tablet",  desc = "Tablet-optimized layout" },
        { id = "desktop", icon = "🖥️", title = "Desktop", desc = "Full desktop experience" },
    }

    local startY, spacing, optH = 104, 14, 86
    local optW, optX = cardW - 48, 24

    local options = {}
    local selectedId = saved
    local closing = false

    local function applySelection(id)
        selectedId = id
        for _, opt in ipairs(options) do
            local sel = opt.id == id
            Util.tween(opt.stroke, { Transparency = sel and 0 or 1 }, 0.3)
            Util.tween(opt.bg, { BackgroundColor3 = sel and UI.selected or UI.optionBg }, 0.3)
            Util.tween(opt.icon, { TextColor3 = sel and UI.accent or UI.textPrimary }, 0.3)
        end
    end

    local function closeMenu(chosen)
        if closing then return end
        closing = true
        for i, opt in ipairs(options) do
            task.delay(0.03 * (i - 1), function()
                Util.tween(opt.bg, { BackgroundTransparency = 1 }, 0.15)
                Util.tween(opt.icon, { TextTransparency = 1 }, 0.15)
                Util.tween(opt.label, { TextTransparency = 1 }, 0.15)
                Util.tween(opt.desc, { TextTransparency = 1 }, 0.15)
                Util.tween(opt.stroke, { Transparency = 1 }, 0.15)
            end)
        end
        task.delay(0.2, function()
            Util.tween(title, { TextTransparency = 1 }, 0.2)
            Util.tween(subtitle, { TextTransparency = 1 }, 0.2)
            Util.tween(closeBtn, { BackgroundTransparency = 1, ImageTransparency = 1 }, 0.2)
        end)
        task.delay(0.35, function()
            Util.tween(cardScale, { Scale = 0.92 }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            Util.tween(card, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(cardStroke, { Transparency = 1 }, 0.3)
        end)
        task.delay(0.55, function()
            Util.tween(backdrop, { BackgroundTransparency = 1 }, 0.35)
        end)
        task.delay(1, function()
            gui:Destroy()
            if onChoose then onChoose(chosen) end
        end)
    end

    for i, device in ipairs(devices) do
        local yPos = startY + (i - 1) * (optH + spacing)

        local optFrame = Instance.new("Frame")
        optFrame.Size = UDim2.fromOffset(optW, optH)
        optFrame.Position = UDim2.fromOffset(optX, yPos)
        optFrame.BackgroundColor3 = (device.id == selectedId) and UI.selected or UI.optionBg
        optFrame.BorderSizePixel = 0
        optFrame.ClipsDescendants = true
        optFrame.Parent = card
        Util.corner(optFrame, UI.optionRad)

        local optScale = Instance.new("UIScale")
        optScale.Parent = optFrame

        local optStroke = Util.stroke(optFrame, UI.accent, 1.5, (device.id == selectedId) and 0 or 1)

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Text = device.icon
        iconLabel.Size = UDim2.fromOffset(40, 40)
        iconLabel.Position = UDim2.fromOffset(16, (optH - 40) / 2)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Font = Theme.fonts.body
        iconLabel.TextSize = 26
        iconLabel.TextColor3 = (device.id == selectedId) and UI.accent or UI.textPrimary
        iconLabel.Parent = optFrame

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Text = device.title
        titleLabel.Size = UDim2.fromOffset(optW - 80, 22)
        titleLabel.Position = UDim2.fromOffset(68, 20)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Theme.fonts.body
        titleLabel.TextSize = 17
        titleLabel.TextColor3 = UI.textPrimary
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        titleLabel.Parent = optFrame

        local descLabel = Instance.new("TextLabel")
        descLabel.Text = device.desc
        descLabel.Size = UDim2.fromOffset(optW - 80, 18)
        descLabel.Position = UDim2.fromOffset(68, 46)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Theme.fonts.caption
        descLabel.TextSize = 12
        descLabel.TextColor3 = UI.textSub
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.Parent = optFrame

        local data = {
            id = device.id, bg = optFrame, icon = iconLabel,
            label = titleLabel, desc = descLabel, stroke = optStroke, scale = optScale,
        }
        table.insert(options, data)

        optFrame.MouseEnter:Connect(function()
            if data.id ~= selectedId then
                Util.tween(optFrame, { BackgroundColor3 = UI.optionHover }, 0.2)
            end
            Util.tween(optScale, { Scale = 1.025 }, 0.2)
        end)
        optFrame.MouseLeave:Connect(function()
            Util.tween(optFrame, { BackgroundColor3 = (data.id == selectedId) and UI.selected or UI.optionBg }, 0.3)
            Util.tween(optScale, { Scale = 1 }, 0.3)
        end)
        optFrame.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            applySelection(data.id)
            Util.tween(optScale, { Scale = 0.96 }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.1, function()
                Util.tween(optScale, { Scale = 1 }, 0.15)
            end)
            task.delay(0.2, function()
                Util.save("DevicePref", data.id)
                closeMenu(data.id)
            end)
        end)
    end

    if selectedId then
        task.delay(0.5, function() applySelection(selectedId) end)
    end

    closeBtn.MouseButton1Click:Connect(function() closeMenu(selectedId) end)

    return gui
end

return DeviceSelector
