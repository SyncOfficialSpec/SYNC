-- ============================================================
--  SYNC  -  macOS-style desktop OS for Roblox executors
--  Generated bundle. Do not edit by hand; edit sources + rebundle.
-- ============================================================
local SYNC = {}
do
    local modules, cache = {}, {}
    function SYNC.define(name, fn) modules[name] = fn end
    function SYNC.import(name)
        local c = cache[name]
        if c ~= nil then return c end
        local fn = modules[name]
        if not fn then error("SYNC: module not found: " .. tostring(name), 2) end
        local r = fn()
        if r == nil then r = true end
        cache[name] = r
        return r
    end
end
pcall(function()
    if typeof(getgenv) == "function" then getgenv().SYNC = SYNC end
end)

SYNC.define("core/Theme", function()
-- SYNC / core / Theme
-- macOS-style palette, fonts and metrics. Light + dark variants.
-- Returns a module table; switch active palette with Theme.setMode("dark"|"light").

local Theme = {}

Theme.fonts = {
    title   = Enum.Font.GothamSemibold,
    body    = Enum.Font.GothamMedium,
    caption = Enum.Font.Gotham,
    light   = Enum.Font.GothamLight,
}

-- Shared accent + system colors (consistent across modes)
Theme.accent      = Color3.fromRGB(0, 122, 255)   -- macOS blue
Theme.red         = Color3.fromRGB(255, 95, 87)    -- traffic light close
Theme.yellow      = Color3.fromRGB(254, 188, 46)   -- minimize
Theme.green       = Color3.fromRGB(40, 200, 64)    -- zoom

Theme.metrics = {
    windowRadius  = 12,
    cardRadius    = 22,
    optionRadius  = 14,
    menuBarHeight = 28,
    dockHeight    = 70,
    dockIcon      = 52,
    titleBar      = 36,
    trafficLight  = 12,
    trafficGap    = 8,
}

local light = {
    name           = "light",
    wallpaper      = Color3.fromRGB(38, 42, 60),
    backdrop       = Color3.fromRGB(0, 0, 0),
    backdropAlpha  = 0.65,
    surface        = Color3.fromRGB(255, 255, 255),
    surfaceAlt     = Color3.fromRGB(242, 242, 247),
    surfaceHover   = Color3.fromRGB(235, 235, 241),
    chrome         = Color3.fromRGB(246, 246, 248),   -- menubar / titlebar
    chromeAlpha    = 0.15,                             -- translucency over content
    stroke         = Color3.fromRGB(210, 210, 215),
    strokeAlpha    = 0.3,
    textPrimary    = Color3.fromRGB(0, 0, 0),
    textSecondary  = Color3.fromRGB(142, 142, 147),
    selected       = Color3.fromRGB(230, 242, 255),
}

local dark = {
    name           = "dark",
    wallpaper      = Color3.fromRGB(28, 30, 44),
    backdrop       = Color3.fromRGB(0, 0, 0),
    backdropAlpha  = 0.7,
    surface        = Color3.fromRGB(30, 30, 32),
    surfaceAlt     = Color3.fromRGB(44, 44, 46),
    surfaceHover   = Color3.fromRGB(58, 58, 60),
    chrome         = Color3.fromRGB(38, 38, 40),
    chromeAlpha    = 0.2,
    stroke         = Color3.fromRGB(70, 70, 74),
    strokeAlpha    = 0.4,
    textPrimary    = Color3.fromRGB(245, 245, 247),
    textSecondary  = Color3.fromRGB(152, 152, 157),
    selected       = Color3.fromRGB(20, 56, 96),
}

Theme.palettes = { light = light, dark = dark }
Theme.c = dark  -- active palette (default dark; feels most "premium")

function Theme.setMode(mode)
    Theme.c = Theme.palettes[mode] or Theme.c
    return Theme.c
end

return Theme
end)

SYNC.define("core/Util", function()
-- SYNC / core / Util
-- Cross-executor helpers: safe CoreGui parenting, persisted settings,
-- and small Instance-building shortcuts (corner, stroke, tween, padding).

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local Util = {}

-- ---------------------------------------------------------------------------
-- Player / camera (wait for them on early inject)
-- ---------------------------------------------------------------------------
function Util.localPlayer()
    local lp = Players.LocalPlayer
    if not lp then
        lp = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
    end
    return lp
end

function Util.viewport()
    local cam = workspace.CurrentCamera
    if not cam then
        cam = workspace:GetPropertyChangedSignal("CurrentCamera"):Wait() and workspace.CurrentCamera
    end
    return cam.ViewportSize
end

-- ---------------------------------------------------------------------------
-- Parent a ScreenGui where it survives respawn/teleport and hides from game.
-- Prefers executor gethui(); falls back to CoreGui, then PlayerGui.
-- ---------------------------------------------------------------------------
function Util.mount(gui)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999

    local ok = pcall(function()
        if typeof(gethui) == "function" then
            gui.Parent = gethui()
            return
        end
        error("no gethui")
    end)
    if ok and gui.Parent then return gui end

    ok = pcall(function()
        local cg = game:GetService("CoreGui")
        if syn and typeof(syn.protect_gui) == "function" then syn.protect_gui(gui) end
        gui.Parent = cg
    end)
    if ok and gui.Parent then return gui end

    -- Last resort: PlayerGui
    local lp = Util.localPlayer()
    gui.Parent = lp:WaitForChild("PlayerGui")
    return gui
end

-- ---------------------------------------------------------------------------
-- Persisted settings (writefile -> syn cookie -> _G), same strategy as the
-- existing device selector. Stored as plain strings under SyncDir/.
-- ---------------------------------------------------------------------------
local SYNC_DIR = "SYNC"

local function tryMakeDir()
    pcall(function()
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" and not isfolder(SYNC_DIR) then
            makefolder(SYNC_DIR)
        end
    end)
end

function Util.save(key, value)
    value = tostring(value)
    tryMakeDir()
    local ok = pcall(function()
        if typeof(writefile) == "function" then writefile(SYNC_DIR .. "/" .. key .. ".txt", value) end
    end)
    if ok then return end
    ok = pcall(function()
        if syn and typeof(syn.SetCookie) == "function" then syn.SetCookie("Sync_" .. key, value) end
    end)
    if ok then return end
    _G["__Sync_" .. key] = value
end

function Util.load(key)
    local val
    local ok = pcall(function()
        if typeof(readfile) == "function" and typeof(isfile) == "function"
            and isfile(SYNC_DIR .. "/" .. key .. ".txt") then
            val = readfile(SYNC_DIR .. "/" .. key .. ".txt")
        end
    end)
    if ok and val and val ~= "" then return val end
    ok = pcall(function()
        if syn and typeof(syn.GetCookie) == "function" then val = syn.GetCookie("Sync_" .. key) end
    end)
    if ok and val and val ~= "" then return val end
    val = _G["__Sync_" .. key]
    return (val and val ~= "") and val or nil
end

-- ---------------------------------------------------------------------------
-- Instance shortcuts
-- ---------------------------------------------------------------------------
function Util.corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

function Util.stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.new(1, 1, 1)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Util.padding(parent, all)
    local p = Instance.new("UIPadding")
    local u = UDim.new(0, all or 0)
    p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = u, u, u, u
    p.Parent = parent
    return p
end

-- Standard SYNC tween. props is a table of properties to animate.
function Util.tween(inst, props, time, style, dir)
    local info = TweenInfo.new(
        time or 0.25,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

return Util
end)

SYNC.define("os/Boot", function()
-- SYNC / os / Boot
-- macOS-style boot screen: black backdrop, Apple logo, thin progress bar.
-- Boot.run(onDone) plays the sequence then fades out and calls onDone().

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Boot = {}

-- Apple logo glyph asset (white). Swap for a custom SYNC mark later.
local APPLE_LOGO = "rbxassetid://6031075938"

function Boot.run(onDone)
    local vp = Util.viewport()

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Boot"
    Util.mount(gui)

    local screen = Instance.new("Frame")
    screen.Size = UDim2.fromScale(1, 1)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    screen.BorderSizePixel = 0
    screen.BackgroundTransparency = 1
    screen.Parent = gui
    Util.tween(screen, { BackgroundTransparency = 0 }, 0.4)

    -- Logo
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.fromOffset(78, 96)
    logo.Position = UDim2.new(0.5, 0, 0.42, 0)
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.BackgroundTransparency = 1
    logo.Image = APPLE_LOGO
    logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    logo.ImageTransparency = 1
    logo.Parent = screen
    Util.tween(logo, { ImageTransparency = 0 }, 0.7)

    -- Progress track
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(180, 4)
    track.Position = UDim2.new(0.5, 0, 0.62, 0)
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.BackgroundColor3 = Color3.fromRGB(70, 70, 74)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Parent = screen
    Util.corner(track, 2)
    Util.tween(track, { BackgroundTransparency = 0.4 }, 0.5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Util.corner(fill, 2)

    -- Animate the fill in a few uneven steps (feels like real boot)
    task.spawn(function()
        local steps = { 0.18, 0.42, 0.55, 0.78, 1.0 }
        for _, p in ipairs(steps) do
            Util.tween(fill, { Size = UDim2.fromScale(p, 1) }, 0.45 + math.random() * 0.3)
            task.wait(0.45 + math.random() * 0.35)
        end
        task.wait(0.25)

        -- Fade everything out
        Util.tween(logo, { ImageTransparency = 1 }, 0.4)
        Util.tween(track, { BackgroundTransparency = 1 }, 0.4)
        Util.tween(fill, { BackgroundTransparency = 1 }, 0.4)
        Util.tween(screen, { BackgroundTransparency = 1 }, 0.6)
        task.wait(0.7)
        gui:Destroy()
        if onDone then onDone() end
    end)

    return gui
end

return Boot
end)

SYNC.define("os/DeviceSelector", function()
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
end)

SYNC.define("init", function()
-- SYNC / init
-- Entry module. Boot sequence -> device selector -> (desktop, coming next).

local Boot           = SYNC.import("os/Boot")
local DeviceSelector = SYNC.import("os/DeviceSelector")

Boot.run(function()
    DeviceSelector.run(function(device)
        -- device is "mobile" | "tablet" | "desktop" | nil (dismissed)
        -- TODO: launch Desktop.start(device) here once built.
    end)
end)
end)

SYNC.import("init")
