-- SYNC / apps / Cursor
-- Custom cursor studio. Renders a real arrow-image cursor (solid or outline)
-- via a RenderStepped overlay and lets you fully customise it: colour, size,
-- outline, glow, opacity, rotation, gradient + rainbow / spin / pulse / trail /
-- click-ripple effects, plus saved named presets and a gallery of looks.
-- Cursor art is loaded from the SYNC repo via Util.remoteImage (getcustomasset).

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local Theme  = SYNC.import("core/Theme")
local Util   = SYNC.import("core/Util")
local Slider = SYNC.import("ui/Slider")
local Switch = SYNC.import("ui/Switch")

local CursorApp = {}

local WHITE  = Color3.fromRGB(255, 255, 255)
local BLACK  = Color3.fromRGB(0, 0, 0)
local DIM    = Color3.fromRGB(150, 150, 158)
local PANEL  = Color3.fromRGB(44, 44, 48)
local ACCENT = Theme.accent

local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/cursors/"

-- Cursor artwork (white masters; tinted at runtime). aspect = width / height.
local SHAPES = {
    { id = "solid",   name = "Solid",   url = RAW .. "arrow_solid.png",   file = "sync_cursor_solid.png",   aspect = 256/254, tip = Vector2.new(0.14, 0.06) },
    { id = "outline", name = "Outline", url = RAW .. "arrow_outline.png", file = "sync_cursor_outline.png", aspect = 229/256, tip = Vector2.new(0.14, 0.06) },
}
local function shapeDef(id)
    for _, s in ipairs(SHAPES) do if s.id == id then return s end end
    return SHAPES[1]
end

-- asset id cache (resolved lazily; false = tried and failed)
local assetCache = {}
local function assetFor(id)
    local d = shapeDef(id)
    if assetCache[id] == nil then
        assetCache[id] = Util.remoteImage(d.url, d.file) or false
    end
    return assetCache[id] or nil
end

local SWATCHES = {
    WHITE, BLACK, Color3.fromRGB(150,150,158),
    Color3.fromRGB(255,59,48),  Color3.fromRGB(255,149,0),  Color3.fromRGB(255,204,0),
    Color3.fromRGB(52,199,89),  Color3.fromRGB(90,200,255),  ACCENT,
    Color3.fromRGB(175,82,222), Color3.fromRGB(255,45,130),
}

-- ---------------------------------------------------------------------------
-- Config
-- ---------------------------------------------------------------------------
local function cfg(t)
    return {
        shape = t.shape or "solid",
        size = t.size or 30,
        color = t.color or WHITE,
        gradient = t.gradient or false,
        colorB = t.colorB or Color3.fromRGB(255, 45, 130),
        outline = t.outline ~= false,
        outlineColor = t.outlineColor or BLACK,
        outlineThickness = t.outlineThickness or 2,
        glow = t.glow or 0,
        opacity = t.opacity or 0,
        rotation = t.rotation or 0,
        rainbow = t.rainbow or false,
        spin = t.spin or false,
        pulse = t.pulse or false,
        trail = t.trail or 0,
        ripple = t.ripple ~= false,
    }
end

-- The four designs the user supplied, as ready presets
local GALLERY = {
    { name = "Snow",     conf = cfg{ shape="outline", color=WHITE, outline=false } },
    { name = "Graphite", conf = cfg{ shape="solid", color=Color3.fromRGB(86,86,120), outline=true, outlineColor=Color3.fromRGB(20,20,28) } },
    { name = "Crimson",  conf = cfg{ shape="solid", color=Color3.fromRGB(235,85,95), outline=false } },
    { name = "Aurora",   conf = cfg{ shape="outline", color=Color3.fromRGB(90,120,255), gradient=true, colorB=Color3.fromRGB(255,90,200), outline=false, glow=0.4 } },
    { name = "Mint",     conf = cfg{ shape="solid", color=Color3.fromRGB(90,255,200), glow=0.5 } },
    { name = "Gold",     conf = cfg{ shape="solid", color=Color3.fromRGB(254,200,70), outline=true, outlineColor=Color3.fromRGB(120,80,0) } },
    { name = "Rainbow",  conf = cfg{ shape="solid", rainbow=true, glow=0.4 } },
    { name = "Comet",    conf = cfg{ shape="solid", color=Color3.fromRGB(90,200,255), trail=8, glow=0.6 } },
}

-- Serialisation (Color3 <-> {r,g,b})
local function c2t(c) return { math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5) } end
local function t2c(t) return Color3.fromRGB(t[1] or 255, t[2] or 255, t[3] or 255) end
local function encodeConfig(c)
    local copy = {}; for k, v in pairs(c) do copy[k] = v end
    copy.color = c2t(c.color); copy.colorB = c2t(c.colorB); copy.outlineColor = c2t(c.outlineColor)
    local ok, s = pcall(function() return HttpService:JSONEncode(copy) end)
    return ok and s or ""
end
local function decodeConfig(s)
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    if not ok or type(t) ~= "table" then return nil end
    if type(t.color) == "table" then t.color = t2c(t.color) end
    if type(t.colorB) == "table" then t.colorB = t2c(t.colorB) end
    if type(t.outlineColor) == "table" then t.outlineColor = t2c(t.outlineColor) end
    return cfg(t)
end

-- ===========================================================================
-- Overlay engine (singleton) — image-based, config driven
-- ===========================================================================
local overlayGui, root, conn, inputConn
local mainImg, borderImg, glowImg, gradient
local trailImgs = {}
local rippleLayer
local history = {}
local config
local onChangeCB

local function newImg(parent, z)
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.BorderSizePixel = 0
    img.ScaleType = Enum.ScaleType.Fit
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Position = UDim2.fromScale(0.5, 0.5)
    img.Size = UDim2.fromScale(1, 1)
    img.ZIndex = z
    img.Parent = parent
    return img
end

-- structural (re)build: image asset, border, glow existence, trail ghosts, gradient
local function rebuild()
    if not root then return end
    local def = shapeDef(config.shape)
    local asset = assetFor(config.shape)

    if not mainImg then mainImg = newImg(root, 999) end
    mainImg.Image = asset or ""

    -- border (a larger dark copy sitting behind the main image)
    if config.outline then
        if not borderImg then borderImg = newImg(root, 997) end
        borderImg.Image = asset or ""
    elseif borderImg then
        borderImg:Destroy(); borderImg = nil
    end

    -- gradient overlay on the main image
    if config.gradient then
        if not gradient then
            gradient = Instance.new("UIGradient")
            gradient.Rotation = 35
            gradient.Parent = mainImg
        end
        gradient.Color = ColorSequence.new(config.color, config.colorB)
    elseif gradient then
        gradient:Destroy(); gradient = nil
    end

    -- trail ghosts
    for _, g in ipairs(trailImgs) do g:Destroy() end
    trailImgs = {}
    local n = math.clamp(math.floor(config.trail or 0), 0, 10)
    for _ = 1, n do
        local g = Instance.new("ImageLabel")
        g.BackgroundTransparency = 1
        g.BorderSizePixel = 0
        g.ScaleType = Enum.ScaleType.Fit
        g.AnchorPoint = def.tip
        g.Image = asset or ""
        g.ZIndex = 995
        g.Parent = overlayGui
        table.insert(trailImgs, g)
    end
end

local function applyVisuals(color, size, rotation, opacity)
    local def = shapeDef(config.shape)
    local h = size
    local w = size * def.aspect
    if root then
        root.AnchorPoint = def.tip
        root.Size = UDim2.fromOffset(w, h)
        root.Rotation = rotation
    end
    if mainImg then
        mainImg.ImageColor3 = config.gradient and WHITE or color
        mainImg.ImageTransparency = opacity
        if gradient then gradient.Color = ColorSequence.new(color, config.colorB) end
    end
    if borderImg then
        local th = math.clamp(config.outlineThickness or 2, 1, 6)
        borderImg.ImageColor3 = config.outlineColor
        borderImg.ImageTransparency = opacity
        borderImg.Size = UDim2.new(1, th * 2, 1, th * 2)
        borderImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
    -- glow: enlarged faded tinted copy behind everything (live managed)
    if config.glow and config.glow > 0 then
        if not glowImg then glowImg = newImg(root, 996); glowImg.Image = mainImg and mainImg.Image or "" end
        glowImg.Image = mainImg and mainImg.Image or ""
        local gf = 1 + config.glow * 0.9
        glowImg.Size = UDim2.fromScale(gf, gf)
        glowImg.ImageColor3 = color
        glowImg.ImageTransparency = math.clamp(1 - config.glow * 0.65, 0, 1)
    elseif glowImg then
        glowImg:Destroy(); glowImg = nil
    end
end

local function startOverlay()
    if overlayGui then return end
    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "SYNC_CursorOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.DisplayOrder = 999999
    overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Util.mount(overlayGui)

    rippleLayer = Instance.new("Frame")
    rippleLayer.Size = UDim2.fromScale(1, 1)
    rippleLayer.BackgroundTransparency = 1
    rippleLayer.BorderSizePixel = 0
    rippleLayer.ZIndex = 994
    rippleLayer.Parent = overlayGui

    root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.ZIndex = 995
    root.Parent = overlayGui

    rebuild()

    local clock = 0
    conn = RunService.RenderStepped:Connect(function(dt)
        if not config then return end
        clock = clock + dt
        local m = UserInputService:GetMouseLocation()

        local color = config.color
        if config.rainbow then color = Color3.fromHSV((clock * 0.3) % 1, 0.85, 1) end
        local size = config.size
        if config.pulse then size = size * (1 + 0.16 * math.sin(clock * 4)) end
        local rot = config.rotation
        if config.spin then rot = (rot + clock * 200) % 360 end

        root.Position = UDim2.fromOffset(m.X, m.Y)
        applyVisuals(color, size, rot, config.opacity)

        if #trailImgs > 0 then
            local def = shapeDef(config.shape)
            local w = size * def.aspect
            table.insert(history, 1, Vector2.new(m.X, m.Y))
            local maxHist = #trailImgs * 3 + 2
            while #history > maxHist do table.remove(history) end
            for i, g in ipairs(trailImgs) do
                local samp = history[math.min(i * 3 + 1, #history)]
                if samp then
                    g.Position = UDim2.fromOffset(samp.X, samp.Y)
                    g.Size = UDim2.fromOffset(w, size)
                    g.ImageColor3 = color
                    g.ImageTransparency = math.clamp(0.25 + (i / (#trailImgs + 1)) * 0.7, 0, 0.95)
                end
            end
        end
    end)

    inputConn = UserInputService.InputBegan:Connect(function(inp)
        if not config or not config.ripple then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local m = UserInputService:GetMouseLocation()
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromOffset(m.X, m.Y)
        ring.Size = UDim2.fromOffset(8, 8)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel = 0
        ring.ZIndex = 998
        ring.Parent = rippleLayer
        Util.corner(ring, 999)
        local col = config.rainbow and Color3.fromHSV((clock*0.3)%1, 0.85, 1) or config.color
        Util.stroke(ring, col, 2, 0.1)
        Util.tween(ring, { Size = UDim2.fromOffset(46, 46) }, 0.45)
        local s = ring:FindFirstChildOfClass("UIStroke")
        if s then Util.tween(s, { Transparency = 1 }, 0.45) end
        task.delay(0.5, function() ring:Destroy() end)
    end)

    pcall(function() UserInputService.MouseIconEnabled = false end)
end

local function stopOverlay()
    if conn then conn:Disconnect(); conn = nil end
    if inputConn then inputConn:Disconnect(); inputConn = nil end
    if overlayGui then overlayGui:Destroy(); overlayGui = nil end
    root, mainImg, borderImg, glowImg, gradient, rippleLayer = nil, nil, nil, nil, nil, nil
    trailImgs, history = {}, {}
    pcall(function() UserInputService.MouseIconEnabled = true end)
end

-- debounced save
local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.4, function()
        saveQueued = false
        if config then Util.save("CursorConfig", encodeConfig(config)) end
    end)
end

local function setConfig(newCfg, skipSave)
    config = newCfg
    if not overlayGui then startOverlay() end
    rebuild()
    if not skipSave then queueSave() end
    if onChangeCB then onChangeCB() end
end

local STRUCTURAL = { shape = true, outline = true, trail = true, gradient = true }
local function setField(key, value)
    if not config then return end
    if config[key] == value then return end
    config[key] = value
    if STRUCTURAL[key] then rebuild() end
    queueSave()
    if onChangeCB then onChangeCB() end
end

local function restoreSaved()
    local saved = Util.load("CursorConfig")
    if not saved or saved == "" then return end
    local c = decodeConfig(saved)
    if c then setConfig(c, true) end
end

local function loadPresets()
    local raw = Util.load("CursorPresets")
    if not raw or raw == "" then return {} end
    local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and type(t) == "table" then return t end
    return {}
end
local function savePresets(list) Util.save("CursorPresets", HttpService:JSONEncode(list)) end

-- ===========================================================================
-- UI
-- ===========================================================================
CursorApp._gui = nil

function CursorApp.open()
    if CursorApp._gui then return end

    if not config then
        setConfig(cfg{ shape = "solid", color = WHITE }, true)
    elseif not overlayGui then
        startOverlay()
    end

    local W, H = 520, 470
    local vp = Util.viewport()
    local cardX, cardY = (vp.X - W) / 2, (vp.Y - H) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Cursor"
    Util.mount(gui)
    CursorApp._gui = gui

    local function close()
        if not CursorApp._gui then return end
        CursorApp._gui = nil
        onChangeCB = nil
        gui:Destroy()
    end

    local catcher = Instance.new("TextButton")
    catcher.Text = ""; catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)

    -- Window
    local TB = 38
    local win = Instance.new("TextButton")
    win.Text = ""; win.AutoButtonColor = false
    win.Position = UDim2.fromOffset(cardX, cardY)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(32, 32, 35)
    win.BackgroundTransparency = 0.04
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 12)
    Util.stroke(win, WHITE, 1, 0.85)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
    bar.BackgroundTransparency = 0.12
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local barCorner = Instance.new("UICorner")
    local okBar = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 12)
        barCorner.TopRightRadius = UDim.new(0, 12)
        barCorner.BottomLeftRadius = UDim.new(0, 0)
        barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okBar then barCorner.CornerRadius = UDim.new(0, 12) end
    barCorner.Parent = bar

    local hair = Instance.new("Frame")
    hair.Size = UDim2.new(1, 0, 0, 1)
    hair.Position = UDim2.new(0, 0, 1, 0)
    hair.BackgroundColor3 = BLACK
    hair.BackgroundTransparency = 0.7
    hair.BorderSizePixel = 0
    hair.ZIndex = 3
    hair.Parent = bar

    local lights = { Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }
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

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Custom Cursor"
    title.Font = Theme.fonts.title
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(210, 210, 216)
    title.ZIndex = 3
    title.Parent = bar

    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 38)
    tabBar.Position = UDim2.fromOffset(0, TB)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 3
    tabBar.Parent = win

    local contentY = TB + 38
    local contentH = H - contentY

    local galleryPage, customPage
    local tabButtons = {}
    local function selectTab(name)
        galleryPage.Visible = (name == "Gallery")
        customPage.Visible  = (name == "Customize")
        for _, t in ipairs(tabButtons) do
            local on = t.name == name
            Util.tween(t.under, { BackgroundTransparency = on and 0 or 1 }, 0.15)
            t.label.TextColor3 = on and WHITE or DIM
        end
    end

    for i, name in ipairs({ "Gallery", "Customize" }) do
        local holder = Instance.new("Frame")
        holder.Size = UDim2.fromOffset(110, 38)
        holder.Position = UDim2.fromOffset(14 + (i - 1) * 112, 0)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 3
        holder.Parent = tabBar
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = Theme.fonts.body
        lbl.TextSize = 13
        lbl.TextColor3 = i == 1 and WHITE or DIM
        lbl.ZIndex = 3
        lbl.Parent = holder
        local under = Instance.new("Frame")
        under.Size = UDim2.new(1, -20, 0, 2)
        under.Position = UDim2.new(0, 10, 1, -4)
        under.BackgroundColor3 = ACCENT
        under.BackgroundTransparency = i == 1 and 0 or 1
        under.BorderSizePixel = 0
        under.ZIndex = 3
        under.Parent = holder
        Util.corner(under, 1)
        local btn = Instance.new("TextButton")
        btn.Text = ""; btn.AutoButtonColor = false
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.ZIndex = 4
        btn.Parent = holder
        btn.MouseButton1Click:Connect(function() selectTab(name) end)
        table.insert(tabButtons, { name = name, label = lbl, under = under })
    end

    -- =======================================================================
    -- GALLERY
    -- =======================================================================
    galleryPage = Instance.new("ScrollingFrame")
    galleryPage.Size = UDim2.fromOffset(W, contentH)
    galleryPage.Position = UDim2.fromOffset(0, contentY)
    galleryPage.BackgroundTransparency = 1
    galleryPage.BorderSizePixel = 0
    galleryPage.ScrollBarThickness = 4
    galleryPage.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128)
    galleryPage.ScrollBarImageTransparency = 0.4
    galleryPage.CanvasSize = UDim2.fromOffset(0, 0)
    galleryPage.ZIndex = 3
    galleryPage.Parent = win

    do
        local CELL_W, CELL_H, PAD = 110, 100, 12
        local COLS = math.max(1, math.floor((W - 24 + PAD) / (CELL_W + PAD)))
        local col, row = 0, 0
        for _, g in ipairs(GALLERY) do
            local x = col * (CELL_W + PAD) + PAD
            local y = row * (CELL_H + PAD) + PAD
            local frame = Instance.new("TextButton")
            frame.Text = ""; frame.AutoButtonColor = false
            frame.Size = UDim2.fromOffset(CELL_W, CELL_H)
            frame.Position = UDim2.fromOffset(x, y)
            frame.BackgroundColor3 = PANEL
            frame.BackgroundTransparency = 0.12
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = galleryPage
            Util.corner(frame, 10)
            Util.stroke(frame, WHITE, 1, 0.9)

            local prev = Instance.new("ImageLabel")
            prev.Size = UDim2.fromOffset(46, 46)
            prev.Position = UDim2.fromScale(0.5, 0.42)
            prev.AnchorPoint = Vector2.new(0.5, 0.5)
            prev.BackgroundTransparency = 1
            prev.ScaleType = Enum.ScaleType.Fit
            prev.Image = assetFor(g.conf.shape) or ""
            prev.ImageColor3 = g.conf.gradient and WHITE or g.conf.color
            prev.ZIndex = 5
            prev.Parent = frame
            if g.conf.gradient then
                local gr = Instance.new("UIGradient")
                gr.Rotation = 35
                gr.Color = ColorSequence.new(g.conf.color, g.conf.colorB)
                gr.Parent = prev
            end

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -8, 0, 16)
            nameLbl.Position = UDim2.new(0, 4, 1, -20)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.fonts.caption
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = DIM
            nameLbl.Text = g.name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Center
            nameLbl.ZIndex = 5
            nameLbl.Parent = frame

            frame.MouseButton1Click:Connect(function()
                local c = {}; for k, v in pairs(g.conf) do c[k] = v end
                setConfig(cfg(c))
                selectTab("Customize")
            end)

            col = col + 1
            if col >= COLS then col = 0; row = row + 1 end
        end
        local totalRows = row + (col > 0 and 1 or 0)
        galleryPage.CanvasSize = UDim2.fromOffset(0, totalRows * (CELL_H + PAD) + PAD)
    end

    -- =======================================================================
    -- CUSTOMIZE
    -- =======================================================================
    customPage = Instance.new("ScrollingFrame")
    customPage.Size = UDim2.fromOffset(W, contentH)
    customPage.Position = UDim2.fromOffset(0, contentY)
    customPage.Visible = false
    customPage.BackgroundTransparency = 1
    customPage.BorderSizePixel = 0
    customPage.ScrollBarThickness = 4
    customPage.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128)
    customPage.ScrollBarImageTransparency = 0.4
    customPage.CanvasSize = UDim2.fromOffset(0, 0)
    customPage.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y  -- make controls scrollable
    customPage.ZIndex = 3
    customPage.Parent = win

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = customPage
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = customPage

    local order = 0
    local function nextOrder() order = order + 1; return order end

    -- Live preview
    local previewBox = Instance.new("Frame")
    previewBox.Size = UDim2.new(1, 0, 0, 96)
    previewBox.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
    previewBox.BackgroundTransparency = 0.1
    previewBox.BorderSizePixel = 0
    previewBox.LayoutOrder = nextOrder()
    previewBox.ZIndex = 3
    previewBox.Parent = customPage
    Util.corner(previewBox, 10)
    Util.stroke(previewBox, WHITE, 1, 0.92)
    local previewImg = Instance.new("ImageLabel")
    previewImg.Size = UDim2.fromOffset(56, 56)
    previewImg.Position = UDim2.fromScale(0.5, 0.5)
    previewImg.AnchorPoint = Vector2.new(0.5, 0.5)
    previewImg.BackgroundTransparency = 1
    previewImg.ScaleType = Enum.ScaleType.Fit
    previewImg.ZIndex = 5
    previewImg.Parent = previewBox
    local previewGrad = Instance.new("UIGradient"); previewGrad.Rotation = 35; previewGrad.Parent = previewImg
    previewGrad.Enabled = false

    local function sectionLabel(text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 16)
        l.BackgroundTransparency = 1
        l.Text = string.upper(text)
        l.Font = Theme.fonts.caption
        l.TextSize = 11
        l.TextColor3 = Color3.fromRGB(120, 120, 128)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = nextOrder()
        l.ZIndex = 3
        l.Parent = customPage
        return l
    end

    local function row(labelText, height)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, 0, 0, height or 30)
        r.BackgroundTransparency = 1
        r.LayoutOrder = nextOrder()
        r.ZIndex = 3
        r.Parent = customPage
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0, 110, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = labelText
        l.Font = Theme.fonts.body
        l.TextSize = 13
        l.TextColor3 = Color3.fromRGB(220, 220, 226)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 3
        l.Parent = r
        return r
    end

    local function swatchRow(getCurrent, onPick)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, 0, 0, 28)
        r.BackgroundTransparency = 1
        r.LayoutOrder = nextOrder()
        r.ZIndex = 3
        r.Parent = customPage
        local lay = Instance.new("UIListLayout")
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.Padding = UDim.new(0, 6)
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.Parent = r
        local rings = {}
        local function refresh()
            local cur = getCurrent()
            for _, sw in ipairs(rings) do sw.ring.Transparency = (sw.col == cur) and 0 or 1 end
        end
        for _, colr in ipairs(SWATCHES) do
            local cell = Instance.new("TextButton")
            cell.Text = ""; cell.AutoButtonColor = false
            cell.Size = UDim2.fromOffset(24, 24)
            cell.BackgroundColor3 = colr
            cell.BorderSizePixel = 0
            cell.ZIndex = 4
            cell.Parent = r
            Util.corner(cell, 12)
            local ring = Util.stroke(cell, ACCENT, 2, 1)
            cell.MouseButton1Click:Connect(function() onPick(colr); refresh() end)
            table.insert(rings, { col = colr, ring = ring })
        end
        return refresh
    end

    -- SHAPE (image thumbnails)
    sectionLabel("Shape")
    local shapeRowF = Instance.new("Frame")
    shapeRowF.Size = UDim2.new(1, 0, 0, 56)
    shapeRowF.BackgroundTransparency = 1
    shapeRowF.LayoutOrder = nextOrder()
    shapeRowF.ZIndex = 3
    shapeRowF.Parent = customPage
    local shapeLay = Instance.new("UIListLayout")
    shapeLay.FillDirection = Enum.FillDirection.Horizontal
    shapeLay.Padding = UDim.new(0, 10)
    shapeLay.VerticalAlignment = Enum.VerticalAlignment.Center
    shapeLay.Parent = shapeRowF
    local shapeCells = {}
    local function refreshShapes()
        for _, sc in ipairs(shapeCells) do
            local on = sc.id == config.shape
            Util.tween(sc.cell, { BackgroundTransparency = on and 0 or 0.12 }, 0.12)
            sc.cell.BackgroundColor3 = on and ACCENT or PANEL
        end
    end
    for _, s in ipairs(SHAPES) do
        local cell = Instance.new("TextButton")
        cell.Text = ""; cell.AutoButtonColor = false
        cell.Size = UDim2.fromOffset(56, 56)
        cell.BackgroundColor3 = PANEL
        cell.BackgroundTransparency = 0.12
        cell.BorderSizePixel = 0
        cell.ZIndex = 4
        cell.Parent = shapeRowF
        Util.corner(cell, 10)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(34, 34)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.BackgroundTransparency = 1
        ic.ScaleType = Enum.ScaleType.Fit
        ic.Image = assetFor(s.id) or ""
        ic.ZIndex = 5
        ic.Parent = cell
        cell.MouseButton1Click:Connect(function() setField("shape", s.id); refreshShapes() end)
        table.insert(shapeCells, { id = s.id, cell = cell })
    end

    -- SIZE
    local SIZE_MIN, SIZE_MAX = 14, 70
    local sizeRow = row("Size")
    local sizeHolder = Instance.new("Frame")
    sizeHolder.Size = UDim2.new(1, -120, 0, 20); sizeHolder.Position = UDim2.fromOffset(110, 5)
    sizeHolder.BackgroundTransparency = 1; sizeHolder.ZIndex = 3; sizeHolder.Parent = sizeRow
    local sizeSlider = Slider.create(sizeHolder, (config.size - SIZE_MIN) / (SIZE_MAX - SIZE_MIN), function(v)
        setField("size", math.floor(SIZE_MIN + v * (SIZE_MAX - SIZE_MIN) + 0.5))
    end)

    -- COLOUR
    sectionLabel("Colour")
    local hueRow = row("Hue", 24)
    local hueHolder = Instance.new("Frame")
    hueHolder.Size = UDim2.new(1, -120, 0, 20); hueHolder.Position = UDim2.fromOffset(110, 2)
    hueHolder.BackgroundTransparency = 1; hueHolder.ZIndex = 3; hueHolder.Parent = hueRow
    Slider.create(hueHolder, 0, function(v) setField("color", Color3.fromHSV(v, 0.85, 1)) end)
    local refreshColorSwatch = swatchRow(function() return config.color end, function(c) setField("color", c) end)

    -- GRADIENT
    local gradRow = row("Gradient")
    local gradSwH = Instance.new("Frame")
    gradSwH.Size = UDim2.fromOffset(54, 26); gradSwH.Position = UDim2.new(1, -54, 0.5, -13)
    gradSwH.BackgroundTransparency = 1; gradSwH.ZIndex = 3; gradSwH.Parent = gradRow
    Switch.create(gradSwH, config.gradient, function(on) setField("gradient", on) end)
    local gradEndLbl = sectionLabel("Gradient end")
    local refreshGradSwatch = swatchRow(function() return config.colorB end, function(c) setField("colorB", c) end)

    -- OUTLINE
    sectionLabel("Outline")
    local outRow = row("Enabled")
    local outSwH = Instance.new("Frame")
    outSwH.Size = UDim2.fromOffset(54, 26); outSwH.Position = UDim2.new(1, -54, 0.5, -13)
    outSwH.BackgroundTransparency = 1; outSwH.ZIndex = 3; outSwH.Parent = outRow
    Switch.create(outSwH, config.outline, function(on) setField("outline", on) end)
    local thickRow = row("Thickness")
    local thickHolder = Instance.new("Frame")
    thickHolder.Size = UDim2.new(1, -120, 0, 20); thickHolder.Position = UDim2.fromOffset(110, 5)
    thickHolder.BackgroundTransparency = 1; thickHolder.ZIndex = 3; thickHolder.Parent = thickRow
    local thickSlider = Slider.create(thickHolder, (config.outlineThickness - 1) / 5, function(v)
        setField("outlineThickness", 1 + math.floor(v * 5 + 0.5))
    end)
    local refreshOutlineSwatch = swatchRow(function() return config.outlineColor end, function(c) setField("outlineColor", c) end)

    -- STYLE
    sectionLabel("Style")
    local function sliderRow(labelText, initial, onChange)
        local r = row(labelText)
        local hold = Instance.new("Frame")
        hold.Size = UDim2.new(1, -120, 0, 20); hold.Position = UDim2.fromOffset(110, 5)
        hold.BackgroundTransparency = 1; hold.ZIndex = 3; hold.Parent = r
        return Slider.create(hold, initial, onChange)
    end
    local glowSlider = sliderRow("Glow", config.glow, function(v) setField("glow", v) end)
    local opacitySlider = sliderRow("Opacity", config.opacity, function(v) setField("opacity", v) end)
    local rotSlider = sliderRow("Rotation", config.rotation / 360, function(v) setField("rotation", math.floor(v * 360 + 0.5)) end)

    -- EFFECTS
    sectionLabel("Effects")
    local function switchRow(labelText, getv, onChange)
        local r = row(labelText)
        local hold = Instance.new("Frame")
        hold.Size = UDim2.fromOffset(54, 26); hold.Position = UDim2.new(1, -54, 0.5, -13)
        hold.BackgroundTransparency = 1; hold.ZIndex = 3; hold.Parent = r
        Switch.create(hold, getv, onChange)
    end
    switchRow("Rainbow", config.rainbow, function(on) setField("rainbow", on) end)
    switchRow("Spin", config.spin, function(on) setField("spin", on) end)
    switchRow("Pulse", config.pulse, function(on) setField("pulse", on) end)
    switchRow("Click ripple", config.ripple, function(on) setField("ripple", on) end)
    local trailR = sliderRow("Trail", config.trail / 10, function(v) setField("trail", math.floor(v * 10 + 0.5)) end)

    -- PRESETS
    sectionLabel("My Presets")
    local presetWrap = Instance.new("Frame")
    presetWrap.Size = UDim2.new(1, 0, 0, 34)
    presetWrap.BackgroundTransparency = 1
    presetWrap.LayoutOrder = nextOrder()
    presetWrap.ZIndex = 3
    presetWrap.Parent = customPage
    local presetScroll = Instance.new("ScrollingFrame")
    presetScroll.Size = UDim2.new(1, -90, 1, 0)
    presetScroll.BackgroundTransparency = 1
    presetScroll.BorderSizePixel = 0
    presetScroll.ScrollBarThickness = 0
    presetScroll.ScrollingDirection = Enum.ScrollingDirection.X
    presetScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.X
    presetScroll.CanvasSize = UDim2.fromOffset(0, 0)
    presetScroll.ZIndex = 4
    presetScroll.Parent = presetWrap
    local presetLay = Instance.new("UIListLayout")
    presetLay.FillDirection = Enum.FillDirection.Horizontal
    presetLay.Padding = UDim.new(0, 6)
    presetLay.VerticalAlignment = Enum.VerticalAlignment.Center
    presetLay.Parent = presetScroll

    local function renderPresets()
        for _, ch in ipairs(presetScroll:GetChildren()) do
            if ch:IsA("GuiObject") then ch:Destroy() end
        end
        local list = loadPresets()
        if #list == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.fromOffset(200, 30)
            empty.BackgroundTransparency = 1
            empty.Text = "No saved presets yet"
            empty.Font = Theme.fonts.caption
            empty.TextSize = 12
            empty.TextColor3 = DIM
            empty.TextXAlignment = Enum.TextXAlignment.Left
            empty.ZIndex = 4
            empty.Parent = presetScroll
            return
        end
        for idx, p in ipairs(list) do
            local chip = Instance.new("TextButton")
            chip.Text = "  " .. (p.name or "Preset") .. "   X"
            chip.AutoButtonColor = false
            chip.Font = Theme.fonts.body
            chip.TextSize = 12
            chip.TextColor3 = WHITE
            chip.AutomaticSize = Enum.AutomaticSize.X
            chip.Size = UDim2.fromOffset(0, 28)
            chip.BackgroundColor3 = PANEL
            chip.BackgroundTransparency = 0.1
            chip.BorderSizePixel = 0
            chip.ZIndex = 5
            chip.Parent = presetScroll
            Util.corner(chip, 14)
            Util.padding(chip, 8)
            chip.MouseButton1Click:Connect(function()
                local c = {}; for k, v in pairs(p.config) do c[k] = v end
                if type(c.color) == "table" then c.color = t2c(c.color) end
                if type(c.colorB) == "table" then c.colorB = t2c(c.colorB) end
                if type(c.outlineColor) == "table" then c.outlineColor = t2c(c.outlineColor) end
                setConfig(cfg(c))
            end)
            chip.MouseButton2Click:Connect(function()
                table.remove(list, idx); savePresets(list); renderPresets()
            end)
        end
    end
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.fromOffset(80, 30)
    saveBtn.Position = UDim2.new(1, -80, 0, 2)
    saveBtn.BackgroundColor3 = ACCENT
    saveBtn.BorderSizePixel = 0
    saveBtn.AutoButtonColor = false
    saveBtn.Text = "Save"
    saveBtn.Font = Theme.fonts.body
    saveBtn.TextSize = 13
    saveBtn.TextColor3 = WHITE
    saveBtn.ZIndex = 5
    saveBtn.Parent = presetWrap
    Util.corner(saveBtn, 8)
    saveBtn.MouseButton1Click:Connect(function()
        local list = loadPresets()
        local conf = {}; for k, v in pairs(config) do conf[k] = v end
        conf.color = c2t(config.color); conf.colorB = c2t(config.colorB); conf.outlineColor = c2t(config.outlineColor)
        table.insert(list, { name = "Preset " .. (#list + 1), config = conf })
        savePresets(list); renderPresets()
    end)
    renderPresets()

    -- Disable
    local disableRow = Instance.new("Frame")
    disableRow.Size = UDim2.new(1, 0, 0, 34)
    disableRow.BackgroundTransparency = 1
    disableRow.LayoutOrder = nextOrder()
    disableRow.ZIndex = 3
    disableRow.Parent = customPage
    local disableBtn = Instance.new("TextButton")
    disableBtn.Size = UDim2.fromOffset(140, 30)
    disableBtn.BackgroundColor3 = WHITE
    disableBtn.BackgroundTransparency = 0.88
    disableBtn.BorderSizePixel = 0
    disableBtn.AutoButtonColor = false
    disableBtn.Text = "Disable cursor"
    disableBtn.Font = Theme.fonts.body
    disableBtn.TextSize = 13
    disableBtn.TextColor3 = Color3.fromRGB(255, 95, 87)
    disableBtn.ZIndex = 4
    disableBtn.Parent = disableRow
    Util.corner(disableBtn, 8)
    disableBtn.MouseButton1Click:Connect(function()
        stopOverlay(); config = nil; Util.save("CursorConfig", "")
    end)

    -- Sync controls to config
    local function syncControls()
        if not config then return end
        local def = shapeDef(config.shape)
        previewImg.Image = assetFor(config.shape) or ""
        previewImg.ImageColor3 = config.gradient and WHITE or (config.rainbow and Color3.fromRGB(120,220,255) or config.color)
        previewImg.ImageTransparency = config.opacity
        previewImg.Rotation = config.rotation
        previewImg.Size = UDim2.fromOffset(56 * def.aspect, 56)
        previewGrad.Enabled = config.gradient
        if config.gradient then previewGrad.Color = ColorSequence.new(config.color, config.colorB) end
        gradEndLbl.Visible = config.gradient
        refreshShapes()
        sizeSlider.set((config.size - SIZE_MIN) / (SIZE_MAX - SIZE_MIN))
        refreshColorSwatch(); refreshGradSwatch(); refreshOutlineSwatch()
        thickSlider.set((config.outlineThickness - 1) / 5)
        glowSlider.set(config.glow); opacitySlider.set(config.opacity); rotSlider.set(config.rotation / 360)
        trailR.set(config.trail / 10)
    end
    onChangeCB = syncControls
    syncControls()

    return { close = close }
end

function CursorApp.restore()
    restoreSaved()
end

return CursorApp
