-- Sync Device Selector
-- Apple-style device selection for Roblox executors
-- Choose Mobile, Tablet, or Desktop with smooth animations

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- ========================================
-- SETTINGS (Universal Executor Storage)
-- ========================================
local SETTINGS_KEY = "SyncDevicePref"

local function saveSetting(value)
    local ok
    ok = pcall(function()
        if type(writefile) == "function" then writefile(SETTINGS_KEY .. ".txt", value) end
    end)
    if ok then return end
    ok = pcall(function()
        if syn and type(syn.SetCookie) == "function" then syn.SetCookie(SETTINGS_KEY, value) end
    end)
    if ok then return end
    _G["__" .. SETTINGS_KEY] = value
end

local function loadSetting()
    local val
    local ok = pcall(function()
        if type(readfile) == "function" then val = readfile(SETTINGS_KEY .. ".txt") end
    end)
    if ok and val and val ~= "" then return val end
    ok = pcall(function()
        if syn and type(syn.GetCookie) == "function" then val = syn.GetCookie(SETTINGS_KEY) end
    end)
    if ok and val and val ~= "" then return val end
    val = _G["__" .. SETTINGS_KEY]
    return (val and val ~= "") and val or nil
end

local savedChoice = loadSetting()

-- ========================================
-- THEME
-- ========================================
local Theme = {
    backdropColor   = Color3.fromRGB(0, 0, 0),
    backdropOpacity = 0.65,
    cardColor       = Color3.fromRGB(255, 255, 255),
    cardRadius      = 22,
    optionBg        = Color3.fromRGB(242, 242, 247),
    optionBgHover   = Color3.fromRGB(235, 235, 241),
    optionRadius    = 14,
    accent          = Color3.fromRGB(0, 122, 255),
    titleFont       = Enum.Font.GothamSemibold,
    bodyFont        = Enum.Font.GothamMedium,
    captionFont     = Enum.Font.GothamLight,
    titleSize       = 22,
    subtitleSize    = 14,
    optionTitleSize = 17,
    optionDescSize  = 12,
    textPrimary     = Color3.fromRGB(0, 0, 0),
    textSecondary   = Color3.fromRGB(142, 142, 147),
    closeBg         = Color3.fromRGB(229, 229, 234),
    closeHov        = Color3.fromRGB(209, 209, 214),
    strokeColor     = Color3.fromRGB(210, 210, 215),
    selectedBg      = Color3.fromRGB(230, 242, 255),
}

-- ========================================
-- BUILD MENU
-- ========================================
local function buildMenu()
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        LocalPlayer = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end

    local cam = workspace.CurrentCamera
    if not cam then
        cam = workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
    end

    local viewport = cam.ViewportSize
    local screenW, screenH = viewport.X, viewport.Y

    local cardW, cardH = 380, 460
    local cardX = (screenW - cardW) / 2
    local cardY = (screenH - cardH) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SyncDeviceSelector"
    gui.DisplayOrder = 9999
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- === BACKDROP ===
    local backdrop = Instance.new("Frame")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Theme.backdropColor
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Parent = gui

    TweenService:Create(
        backdrop,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1 - Theme.backdropOpacity}
    ):Play()

    -- === CARD ===
    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.fromOffset(cardW, cardH)
    card.Position = UDim2.fromOffset(cardX, cardY)
    card.BackgroundColor3 = Theme.cardColor
    card.BackgroundTransparency = 0
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = gui

    Instance.new("UICorner", card).CornerRadius = UDim.new(0, Theme.cardRadius)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Theme.strokeColor
    cardStroke.Thickness = 0.5
    cardStroke.Transparency = 0.3
    cardStroke.Parent = card

    -- UIScale for card entrance animation
    local cardScaleObj = Instance.new("UIScale")
    cardScaleObj.Parent = card
    cardScaleObj.Scale = 0

    TweenService:Create(
        cardScaleObj,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    -- === CLOSE BUTTON ===
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.fromOffset(cardW - 38, 16)
    closeBtn.BackgroundColor3 = Theme.closeBg
    closeBtn.BorderSizePixel = 0
    closeBtn.Image = "rbxassetid://7072725342"
    closeBtn.ImageColor3 = Theme.textSecondary
    closeBtn.Parent = card

    local closeRadius = Instance.new("UICorner")
    closeRadius.CornerRadius = UDim.new(0.5, 0)
    closeRadius.Parent = closeBtn

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.closeHov}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.closeBg}):Play()
    end)

    -- === TITLE ===
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "Choose Your Device"
    title.Size = UDim2.fromOffset(cardW - 60, 30)
    title.Position = UDim2.fromOffset(30, 32)
    title.BackgroundTransparency = 1
    title.Font = Theme.titleFont
    title.TextSize = Theme.titleSize
    title.TextColor3 = Theme.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BorderSizePixel = 0
    title.Parent = card

    -- === SUBTITLE ===
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Text = "Select the device you're using"
    subtitle.Size = UDim2.fromOffset(cardW - 60, 20)
    subtitle.Position = UDim2.fromOffset(30, 66)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Theme.captionFont
    subtitle.TextSize = Theme.subtitleSize
    subtitle.TextColor3 = Theme.textSecondary
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.BorderSizePixel = 0
    subtitle.Parent = card

    -- === OPTIONS ===
    local devices = {
        {id = "mobile",  icon = "📱", title = "Mobile",  desc = "Phone-optimized layout"},
        {id = "tablet",  icon = "💻", title = "Tablet",  desc = "Tablet-optimized layout"},
        {id = "desktop", icon = "🖥️", title = "Desktop", desc = "Full desktop experience"},
    }

    local optionStartY = 104
    local optionSpacing = 14
    local optionH = 86
    local optionW = cardW - 48
    local optionX = 24

    local options = {}
    local selectedId = savedChoice

    local function selectDevice(id)
        selectedId = id
        for _, opt in ipairs(options) do
            local sel = opt.id == id
            TweenService:Create(opt.stroke, TweenInfo.new(0.3), {Transparency = sel and 0 or 1}):Play()
            TweenService:Create(opt.bg, TweenInfo.new(0.3), {
                BackgroundColor3 = sel and Theme.selectedBg or Theme.optionBg,
            }):Play()
            TweenService:Create(opt.icon, TweenInfo.new(0.3), {
                TextColor3 = sel and Theme.accent or Theme.textPrimary,
            }):Play()
        end
    end

    local function closeMenu()
        for i, opt in ipairs(options) do
            task.delay(0.03 * (i - 1), function()
                TweenService:Create(opt.bg, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
                TweenService:Create(opt.icon, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
                TweenService:Create(opt.label, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
                TweenService:Create(opt.desc, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
                TweenService:Create(opt.stroke, TweenInfo.new(0.15), {Transparency = 1}):Play()
            end)
        end

        task.delay(0.2, function()
            TweenService:Create(title, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            TweenService:Create(subtitle, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
            TweenService:Create(closeBtn, TweenInfo.new(0.2), {
                BackgroundTransparency = 1,
                ImageTransparency = 1,
            }):Play()
        end)

        task.delay(0.35, function()
            TweenService:Create(cardScaleObj, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Scale = 0.92,
            }):Play()
            TweenService:Create(card, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(cardStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
        end)

        task.delay(0.55, function()
            TweenService:Create(backdrop, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
        end)

        task.delay(1, function()
            gui:Destroy()
        end)
    end

    local function completeSelection(id)
        saveSetting(id)
        savedChoice = id
        closeMenu()
    end

    for i, device in ipairs(devices) do
        local yPos = optionStartY + (i - 1) * (optionH + optionSpacing)

        local optFrame = Instance.new("Frame")
        optFrame.Name = device.id
        optFrame.Size = UDim2.fromOffset(optionW, optionH)
        optFrame.Position = UDim2.fromOffset(optionX, yPos)
        optFrame.BackgroundColor3 = (device.id == selectedId) and Theme.selectedBg or Theme.optionBg
        optFrame.BackgroundTransparency = 0
        optFrame.BorderSizePixel = 0
        optFrame.Parent = card
        optFrame.ClipsDescendants = true

        Instance.new("UICorner", optFrame).CornerRadius = UDim.new(0, Theme.optionRadius)

        local optScale = Instance.new("UIScale")
        optScale.Parent = optFrame
        optScale.Scale = 1

        local optStroke = Instance.new("UIStroke")
        optStroke.Color = Theme.accent
        optStroke.Thickness = 1.5
        optStroke.Transparency = (device.id == selectedId) and 0 or 1
        optStroke.Parent = optFrame

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Name = "Icon"
        iconLabel.Text = device.icon
        iconLabel.Size = UDim2.fromOffset(40, 40)
        iconLabel.Position = UDim2.fromOffset(16, (optionH - 40) / 2)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Font = Enum.Font.GothamMedium
        iconLabel.TextSize = 26
        iconLabel.TextColor3 = (device.id == selectedId) and Theme.accent or Theme.textPrimary
        iconLabel.TextXAlignment = Enum.TextXAlignment.Center
        iconLabel.TextYAlignment = Enum.TextYAlignment.Center
        iconLabel.BorderSizePixel = 0
        iconLabel.Parent = optFrame

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Text = device.title
        titleLabel.Size = UDim2.fromOffset(optionW - 80, 22)
        titleLabel.Position = UDim2.fromOffset(68, 20)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Font = Theme.bodyFont
        titleLabel.TextSize = Theme.optionTitleSize
        titleLabel.TextColor3 = Theme.textPrimary
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextYAlignment = Enum.TextYAlignment.Bottom
        titleLabel.BorderSizePixel = 0
        titleLabel.Parent = optFrame

        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "Description"
        descLabel.Text = device.desc
        descLabel.Size = UDim2.fromOffset(optionW - 80, 18)
        descLabel.Position = UDim2.fromOffset(68, 46)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Theme.captionFont
        descLabel.TextSize = Theme.optionDescSize
        descLabel.TextColor3 = Theme.textSecondary
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.BorderSizePixel = 0
        descLabel.Parent = optFrame

        local optData = {
            id = device.id,
            frame = optFrame,
            bg = optFrame,
            icon = iconLabel,
            label = titleLabel,
            desc = descLabel,
            stroke = optStroke,
            scale = optScale,
        }
        table.insert(options, optData)

        optFrame.MouseEnter:Connect(function()
            if optData.id ~= selectedId then
                TweenService:Create(optFrame, TweenInfo.new(0.2), {BackgroundColor3 = Theme.optionBgHover}):Play()
            end
            TweenService:Create(optScale, TweenInfo.new(0.2), {Scale = 1.025}):Play()
        end)

        optFrame.MouseLeave:Connect(function()
            local bg = (optData.id == selectedId) and Theme.selectedBg or Theme.optionBg
            TweenService:Create(optFrame, TweenInfo.new(0.3), {BackgroundColor3 = bg}):Play()
            TweenService:Create(optScale, TweenInfo.new(0.3), {Scale = 1}):Play()
        end)

        optFrame.MouseButton1Click:Connect(function()
            selectDevice(optData.id)
            TweenService:Create(optScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.96}):Play()
            task.delay(0.1, function()
                TweenService:Create(optScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
            end)
            task.delay(0.2, function()
                completeSelection(optData.id)
            end)
        end)
    end

    -- Pre-select saved choice
    if selectedId then
        local function doSelect()
            for _, opt in ipairs(options) do
                if opt.id == selectedId then
                    TweenService:Create(opt.stroke, TweenInfo.new(0.4), {Transparency = 0}):Play()
                    TweenService:Create(opt.bg, TweenInfo.new(0.4), {BackgroundColor3 = Theme.selectedBg}):Play()
                    TweenService:Create(opt.icon, TweenInfo.new(0.4), {TextColor3 = Theme.accent}):Play()
                end
            end
        end
        task.delay(0.5, doSelect)
    end

    -- Close button
    closeBtn.MouseButton1Click:Connect(closeMenu)

    return gui
end

-- ========================================
-- ENTRY
-- ========================================
local ok, err = pcall(buildMenu)
if not ok then
    warn("[Sync] Device Selector error:", err)
end
