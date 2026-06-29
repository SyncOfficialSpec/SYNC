-- SYNC / apps / Cursor
-- Custom cursor studio: browse presets in the Gallery, or fully customise the
-- live cursor in Customize (shape, size, colour, outline, glow, opacity,
-- rotation + rainbow / spin / pulse / trail / click-ripple effects) and save
-- your own named presets.
-- Rendered with a RenderStepped overlay so the cursor shows everywhere.

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local Theme  = SYNC.import("core/Theme")
local Util   = SYNC.import("core/Util")
local Icons  = SYNC.import("core/Icons")
local Slider = SYNC.import("ui/Slider")
local Switch = SYNC.import("ui/Switch")

local CursorApp = {}

local WHITE  = Color3.fromRGB(255, 255, 255)
local BLACK  = Color3.fromRGB(0, 0, 0)
local DIM    = Color3.fromRGB(150, 150, 158)
local PANEL  = Color3.fromRGB(44, 44, 48)
local ACCENT = Theme.accent

-- ---------------------------------------------------------------------------
-- Shapes (glyph based). Each renders as a centred text glyph.
-- ---------------------------------------------------------------------------
local SHAPES = {
    { id = "arrow",    name = "Arrow",    char = "↑" },
    { id = "pointer",  name = "Pointer",  char = "➜" },
    { id = "cross",    name = "Cross",    char = "+" },
    { id = "plus",     name = "Plus",     char = "✛" },
    { id = "dot",      name = "Dot",      char = "●" },
    { id = "ring",     name = "Ring",     char = "○" },
    { id = "diamond",  name = "Diamond",  char = "◆" },
    { id = "square",   name = "Square",   char = "■" },
    { id = "triangle", name = "Triangle", char = "▲" },
    { id = "star",     name = "Star",     char = "★" },
    { id = "heart",    name = "Heart",    char = "♥" },
    { id = "text",     name = "Text",     char = "|" },
}
local function shapeChar(id)
    for _, s in ipairs(SHAPES) do if s.id == id then return s.char end end
    return "↑"
end

-- Quick colour swatches (cursor + outline pickers share these)
local SWATCHES = {
    WHITE, BLACK, Color3.fromRGB(150,150,158),
    Color3.fromRGB(255,59,48),  Color3.fromRGB(255,149,0),  Color3.fromRGB(255,204,0),
    Color3.fromRGB(52,199,89),  Color3.fromRGB(90,200,255),  ACCENT,
    Color3.fromRGB(175,82,222), Color3.fromRGB(255,45,130),
}

-- ---------------------------------------------------------------------------
-- Built-in gallery presets (each is a full config)
-- ---------------------------------------------------------------------------
local function cfg(t)
    return {
        shape = t.shape or "arrow",
        size = t.size or 28,
        color = t.color or WHITE,
        outline = t.outline ~= false,
        outlineColor = t.outlineColor or BLACK,
        outlineThickness = t.outlineThickness or 1,
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

local GALLERY = {
    { name = "Classic",   conf = cfg{ shape="arrow", color=WHITE } },
    { name = "Blue",      conf = cfg{ shape="arrow", color=ACCENT } },
    { name = "Red Dot",   conf = cfg{ shape="dot", color=Color3.fromRGB(255,59,48), size=22 } },
    { name = "Crosshair", conf = cfg{ shape="cross", color=Color3.fromRGB(90,200,255), size=34, outline=false } },
    { name = "Gold Gem",  conf = cfg{ shape="diamond", color=Color3.fromRGB(254,188,46), glow=0.6 } },
    { name = "Neon Ring", conf = cfg{ shape="ring", color=Color3.fromRGB(90,255,200), size=26, glow=0.8, trail=4 } },
    { name = "Rainbow",   conf = cfg{ shape="star", size=30, rainbow=true, glow=0.5 } },
    { name = "Spinner",   conf = cfg{ shape="plus", color=ACCENT, size=30, spin=true } },
    { name = "Heartbeat", conf = cfg{ shape="heart", color=Color3.fromRGB(255,45,130), size=26, pulse=true } },
    { name = "Comet",     conf = cfg{ shape="dot", color=Color3.fromRGB(90,200,255), size=20, trail=8, glow=0.7 } },
    { name = "Text Bar",  conf = cfg{ shape="text", color=WHITE, size=30 } },
    { name = "Ghost",     conf = cfg{ shape="arrow", color=WHITE, opacity=0.5, trail=3 } },
}

-- ---------------------------------------------------------------------------
-- Config serialisation (Color3 <-> {r,g,b}) for save / load
-- ---------------------------------------------------------------------------
local function c2t(c) return { math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5) } end
local function t2c(t) return Color3.fromRGB(t[1] or 255, t[2] or 255, t[3] or 255) end

local function encodeConfig(c)
    local copy = {}
    for k, v in pairs(c) do copy[k] = v end
    copy.color = c2t(c.color)
    copy.outlineColor = c2t(c.outlineColor)
    local ok, s = pcall(function() return HttpService:JSONEncode(copy) end)
    return ok and s or ""
end

local function decodeConfig(s)
    local ok, t = pcall(function() return HttpService:JSONDecode(s) end)
    if not ok or type(t) ~= "table" then return nil end
    if type(t.color) == "table" then t.color = t2c(t.color) end
    if type(t.outlineColor) == "table" then t.outlineColor = t2c(t.outlineColor) end
    return cfg(t)
end

-- ===========================================================================
-- Overlay engine (singleton) — config driven
-- ===========================================================================
local overlayGui, root, conn, inputConn
local mainLabel, glowLabel
local outlineLabels = {}
local trailLabels   = {}
local rippleLayer
local history = {}            -- recent mouse positions for the trail
local config                  -- active config (nil = disabled)
local onChangeCB              -- UI listener so previews refresh

local function setLabel(lbl)
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = false
    lbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lbl.Position = UDim2.fromScale(0.5, 0.5)
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.Parent = root
end

-- (Re)build the structural pieces (glyph text, outline copies, glow, trail).
-- Per-frame colour / size / rotation / opacity is applied in the render loop.
local function rebuild()
    if not root then return end
    local ch = shapeChar(config.shape)

    -- glow glyph follows the active shape (created/sized live in applyVisuals)
    if glowLabel then glowLabel.Text = ch end

    -- outline (directional offset copies)
    for _, l in ipairs(outlineLabels) do l:Destroy() end
    outlineLabels = {}
    if config.outline then
        local th = math.clamp(config.outlineThickness or 1, 1, 4)
        local dirs = { {1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1} }
        for _, d in ipairs(dirs) do
            local o = Instance.new("TextLabel")
            o.ZIndex = 997
            setLabel(o)
            o.Text = ch
            o.TextStrokeTransparency = 1
            o.Position = UDim2.new(0.5, d[1]*th, 0.5, d[2]*th)
            o:SetAttribute("dx", d[1]*th)
            o:SetAttribute("dy", d[2]*th)
            table.insert(outlineLabels, o)
        end
    end

    -- main glyph
    if not mainLabel then
        mainLabel = Instance.new("TextLabel")
        mainLabel.ZIndex = 999
        setLabel(mainLabel)
    end
    mainLabel.Text = ch
    mainLabel.TextStrokeTransparency = 1

    -- trail ghosts
    for _, l in ipairs(trailLabels) do l:Destroy() end
    trailLabels = {}
    local n = math.clamp(math.floor(config.trail or 0), 0, 10)
    for i = 1, n do
        local g = Instance.new("TextLabel")
        g.BackgroundTransparency = 1
        g.BorderSizePixel = 0
        g.Font = Enum.Font.GothamBold
        g.AnchorPoint = Vector2.new(0.5, 0.5)
        g.Text = ch
        g.ZIndex = 995
        g.Parent = overlayGui
        table.insert(trailLabels, g)
    end
end

local function applyVisuals(color, size, rotation, opacity)
    if root then
        root.Size = UDim2.fromOffset(size * 3, size * 3)
        root.Rotation = rotation
    end
    if mainLabel then
        mainLabel.TextColor3 = color
        mainLabel.TextSize = size
        mainLabel.TextTransparency = opacity
    end
    for _, o in ipairs(outlineLabels) do
        o.TextColor3 = config.outlineColor
        o.TextSize = size
        o.TextTransparency = opacity
    end
    -- glow is managed live (create/destroy on the 0 boundary) so the glow
    -- slider doesn't need a structural rebuild every frame
    if config.glow and config.glow > 0 then
        if not glowLabel then
            glowLabel = Instance.new("TextLabel")
            glowLabel.ZIndex = 996
            setLabel(glowLabel)
            glowLabel.Text = shapeChar(config.shape)
            glowLabel.TextStrokeTransparency = 1
        end
        glowLabel.TextColor3 = color
        glowLabel.TextSize = size * (1.5 + config.glow * 0.8)
        glowLabel.TextTransparency = math.clamp(1 - config.glow * 0.7, 0, 1)
    elseif glowLabel then
        glowLabel:Destroy(); glowLabel = nil
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
    root.AnchorPoint = Vector2.new(0.5, 0.5)
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

        -- live colour (rainbow overrides)
        local color = config.color
        if config.rainbow then color = Color3.fromHSV((clock * 0.3) % 1, 0.85, 1) end
        -- live size (pulse)
        local size = config.size
        if config.pulse then size = size * (1 + 0.18 * math.sin(clock * 4)) end
        -- live rotation (spin adds to base)
        local rot = config.rotation
        if config.spin then rot = (rot + clock * 220) % 360 end

        root.Position = UDim2.fromOffset(m.X, m.Y)
        applyVisuals(color, size, rot, config.opacity)

        -- trail
        if #trailLabels > 0 then
            table.insert(history, 1, Vector2.new(m.X, m.Y))
            local maxHist = #trailLabels * 3 + 2
            while #history > maxHist do table.remove(history) end
            for i, g in ipairs(trailLabels) do
                local samp = history[math.min(i * 3 + 1, #history)]
                if samp then
                    g.Position = UDim2.fromOffset(samp.X, samp.Y)
                    g.Size = UDim2.fromOffset(size, size)
                    g.TextSize = size
                    g.TextColor3 = color
                    g.TextTransparency = math.clamp(0.25 + (i / (#trailLabels + 1)) * 0.7, 0, 0.95)
                end
            end
        end
    end)

    -- click ripple
    inputConn = UserInputService.InputBegan:Connect(function(inp, gpe)
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
    root, mainLabel, glowLabel, rippleLayer = nil, nil, nil, nil
    outlineLabels, trailLabels, history = {}, {}, {}
    pcall(function() UserInputService.MouseIconEnabled = true end)
end

-- Debounced persistence so dragging a slider doesn't write a file every frame
local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.4, function()
        saveQueued = false
        if config then Util.save("CursorConfig", encodeConfig(config)) end
    end)
end

-- Public: set the whole config, rebuild + persist
local function setConfig(newCfg, skipSave)
    config = newCfg
    if not overlayGui then startOverlay() end
    rebuild()
    if not skipSave then queueSave() end
    if onChangeCB then onChangeCB() end
end

-- Keys that change the cursor's structure (need a rebuild). Everything else
-- (size, colour, glow, opacity, rotation, effect toggles) is applied live in
-- the render loop, so dragging those sliders stays smooth.
local STRUCTURAL = { shape = true, outline = true, outlineThickness = true, trail = true }

-- Mutate one field and re-apply
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

-- Saved user presets (named) ------------------------------------------------
local function loadPresets()
    local raw = Util.load("CursorPresets")
    if not raw or raw == "" then return {} end
    local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and type(t) == "table" then return t end
    return {}
end

local function savePresets(list)
    Util.save("CursorPresets", HttpService:JSONEncode(list))
end

-- ===========================================================================
-- UI
-- ===========================================================================
CursorApp._gui = nil

function CursorApp.open()
    if CursorApp._gui then return end

    if not config then
        setConfig(cfg{ shape = "arrow", color = WHITE }, true)
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
    catcher.Text = ""
    catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)

    -- Window
    local TB = 38
    local win = Instance.new("TextButton")
    win.Text = ""
    win.AutoButtonColor = false
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

    -- Tab strip
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 38)
    tabBar.Position = UDim2.fromOffset(0, TB)
    tabBar.BackgroundTransparency = 1
    tabBar.ZIndex = 3
    tabBar.Parent = win

    local contentY = TB + 38
    local contentH = H - contentY

    -- Two pages
    local galleryPage, customPage
    local tabButtons = {}
    local activeTab = "Gallery"

    local function selectTab(name)
        activeTab = name
        galleryPage.Visible = (name == "Gallery")
        customPage.Visible  = (name == "Customize")
        for _, t in ipairs(tabButtons) do
            local on = t.name == name
            Util.tween(t.under, { BackgroundTransparency = on and 0 or 1 }, 0.15)
            t.label.TextColor3 = on and WHITE or DIM
        end
    end

    local tabNames = { "Gallery", "Customize" }
    for i, name in ipairs(tabNames) do
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
        lbl.TextColor3 = name == activeTab and WHITE or DIM
        lbl.ZIndex = 3
        lbl.Parent = holder

        local under = Instance.new("Frame")
        under.Size = UDim2.new(1, -20, 0, 2)
        under.Position = UDim2.new(0, 10, 1, -4)
        under.BackgroundColor3 = ACCENT
        under.BackgroundTransparency = name == activeTab and 0 or 1
        under.BorderSizePixel = 0
        under.ZIndex = 3
        under.Parent = holder
        Util.corner(under, 1)

        local btn = Instance.new("TextButton")
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.ZIndex = 4
        btn.Parent = holder
        btn.MouseButton1Click:Connect(function() selectTab(name) end)

        table.insert(tabButtons, { name = name, label = lbl, under = under })
    end

    -- =======================================================================
    -- GALLERY PAGE
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
        local CELL_W, CELL_H, PAD = 110, 96, 12
        local GRID_W = W - 24
        local COLS = math.max(1, math.floor((GRID_W + PAD) / (CELL_W + PAD)))
        local col, row = 0, 0
        for _, g in ipairs(GALLERY) do
            local x = col * (CELL_W + PAD) + PAD
            local y = row * (CELL_H + PAD) + PAD

            local frame = Instance.new("TextButton")
            frame.Text = ""
            frame.AutoButtonColor = false
            frame.Size = UDim2.fromOffset(CELL_W, CELL_H)
            frame.Position = UDim2.fromOffset(x, y)
            frame.BackgroundColor3 = PANEL
            frame.BackgroundTransparency = 0.12
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = galleryPage
            Util.corner(frame, 10)
            Util.stroke(frame, WHITE, 1, 0.9)

            local preview = Instance.new("TextLabel")
            preview.Size = UDim2.fromOffset(40, 40)
            preview.Position = UDim2.fromScale(0.5, 0.42)
            preview.AnchorPoint = Vector2.new(0.5, 0.5)
            preview.BackgroundTransparency = 1
            preview.Font = Enum.Font.GothamBold
            preview.Text = shapeChar(g.conf.shape)
            preview.TextColor3 = g.conf.rainbow and Color3.fromRGB(120,220,255) or g.conf.color
            preview.TextSize = math.min(g.conf.size + 4, 38)
            preview.ZIndex = 5
            preview.Parent = frame

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -8, 0, 16)
            nameLbl.Position = UDim2.new(0, 4, 1, -20)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.fonts.caption
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = DIM
            nameLbl.Text = g.name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Center
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 5
            nameLbl.Parent = frame

            frame.MouseButton1Click:Connect(function()
                local c = {} ; for k, v in pairs(g.conf) do c[k] = v end
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
    -- CUSTOMIZE PAGE
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
    customPage.ZIndex = 3
    customPage.Parent = win

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = customPage
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = customPage

    local order = 0
    local function nextOrder() order = order + 1; return order end

    -- Live preview card -----------------------------------------------------
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

    local previewGlyph = Instance.new("TextLabel")
    previewGlyph.Size = UDim2.fromOffset(60, 60)
    previewGlyph.Position = UDim2.fromScale(0.5, 0.5)
    previewGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    previewGlyph.BackgroundTransparency = 1
    previewGlyph.Font = Enum.Font.GothamBold
    previewGlyph.Text = "↑"
    previewGlyph.TextColor3 = WHITE
    previewGlyph.TextSize = 30
    previewGlyph.ZIndex = 5
    previewGlyph.Parent = previewBox

    local previewHint = Instance.new("TextLabel")
    previewHint.Size = UDim2.new(1, -16, 0, 14)
    previewHint.Position = UDim2.new(0, 8, 1, -18)
    previewHint.BackgroundTransparency = 1
    previewHint.Font = Theme.fonts.caption
    previewHint.TextSize = 10
    previewHint.TextColor3 = DIM
    previewHint.Text = "Live preview"
    previewHint.TextXAlignment = Enum.TextXAlignment.Left
    previewHint.ZIndex = 5
    previewHint.Parent = previewBox

    -- Section helpers -------------------------------------------------------
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

    -- a labelled row holding an arbitrary control on the right
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

    -- a swatch picker row; onPick(Color3); returns refresh fn
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
            for _, sw in ipairs(rings) do
                local on = sw.col == cur
                sw.ring.Transparency = on and 0 or 1
            end
        end
        for _, colr in ipairs(SWATCHES) do
            local cell = Instance.new("TextButton")
            cell.Text = ""
            cell.AutoButtonColor = false
            cell.Size = UDim2.fromOffset(24, 24)
            cell.BackgroundColor3 = colr
            cell.BorderSizePixel = 0
            cell.ZIndex = 4
            cell.Parent = r
            Util.corner(cell, 12)
            local ring = Util.stroke(cell, ACCENT, 2, 1)
            cell.MouseButton1Click:Connect(function()
                onPick(colr)
                refresh()
            end)
            table.insert(rings, { col = colr, ring = ring })
        end
        return refresh
    end

    -- ---- SHAPE ----
    sectionLabel("Shape")
    local shapeRow = Instance.new("ScrollingFrame")
    shapeRow.Size = UDim2.new(1, 0, 0, 48)
    shapeRow.BackgroundTransparency = 1
    shapeRow.BorderSizePixel = 0
    shapeRow.ScrollBarThickness = 0
    shapeRow.ScrollingDirection = Enum.ScrollingDirection.X
    shapeRow.AutomaticCanvasSize = Enum.AutomaticCanvasSize.X
    shapeRow.CanvasSize = UDim2.fromOffset(0, 0)
    shapeRow.LayoutOrder = nextOrder()
    shapeRow.ZIndex = 3
    shapeRow.Parent = customPage
    local shapeLay = Instance.new("UIListLayout")
    shapeLay.FillDirection = Enum.FillDirection.Horizontal
    shapeLay.Padding = UDim.new(0, 8)
    shapeLay.VerticalAlignment = Enum.VerticalAlignment.Center
    shapeLay.Parent = shapeRow
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
        cell.Text = s.char
        cell.AutoButtonColor = false
        cell.Font = Enum.Font.GothamBold
        cell.TextSize = 22
        cell.TextColor3 = WHITE
        cell.Size = UDim2.fromOffset(44, 44)
        cell.BackgroundColor3 = PANEL
        cell.BackgroundTransparency = 0.12
        cell.BorderSizePixel = 0
        cell.ZIndex = 4
        cell.Parent = shapeRow
        Util.corner(cell, 10)
        cell.MouseButton1Click:Connect(function()
            setField("shape", s.id)
            refreshShapes()
        end)
        table.insert(shapeCells, { id = s.id, cell = cell })
    end

    -- ---- SIZE ----
    local sizeRow = row("Size")
    local sizeHolder = Instance.new("Frame")
    sizeHolder.Size = UDim2.new(1, -120, 0, 20)
    sizeHolder.Position = UDim2.fromOffset(110, 5)
    sizeHolder.BackgroundTransparency = 1
    sizeHolder.ZIndex = 3
    sizeHolder.Parent = sizeRow
    local SIZE_MIN, SIZE_MAX = 12, 64
    local sizeSlider = Slider.create(sizeHolder, (config.size - SIZE_MIN) / (SIZE_MAX - SIZE_MIN), function(v)
        setField("size", math.floor(SIZE_MIN + v * (SIZE_MAX - SIZE_MIN) + 0.5))
    end)

    -- ---- COLOUR ----
    sectionLabel("Colour")
    local hueRow = row("Hue", 24)
    local hueHolder = Instance.new("Frame")
    hueHolder.Size = UDim2.new(1, -120, 0, 20)
    hueHolder.Position = UDim2.fromOffset(110, 2)
    hueHolder.BackgroundTransparency = 1
    hueHolder.ZIndex = 3
    hueHolder.Parent = hueRow
    local hueSlider = Slider.create(hueHolder, 0, function(v)
        setField("color", Color3.fromHSV(v, 0.85, 1))
    end)
    local refreshColorSwatch = swatchRow(function() return config.color end, function(c)
        setField("color", c)
    end)

    -- ---- OUTLINE ----
    sectionLabel("Outline")
    local outRow = row("Enabled")
    local outSwitchHolder = Instance.new("Frame")
    outSwitchHolder.Size = UDim2.fromOffset(54, 26)
    outSwitchHolder.Position = UDim2.new(1, -54, 0.5, -13)
    outSwitchHolder.BackgroundTransparency = 1
    outSwitchHolder.ZIndex = 3
    outSwitchHolder.Parent = outRow
    Switch.create(outSwitchHolder, config.outline, function(on) setField("outline", on) end)

    local thickRow = row("Thickness")
    local thickHolder = Instance.new("Frame")
    thickHolder.Size = UDim2.new(1, -120, 0, 20)
    thickHolder.Position = UDim2.fromOffset(110, 5)
    thickHolder.BackgroundTransparency = 1
    thickHolder.ZIndex = 3
    thickHolder.Parent = thickRow
    local thickSlider = Slider.create(thickHolder, (config.outlineThickness - 1) / 3, function(v)
        setField("outlineThickness", 1 + math.floor(v * 3 + 0.5))
    end)
    local refreshOutlineSwatch = swatchRow(function() return config.outlineColor end, function(c)
        setField("outlineColor", c)
    end)

    -- ---- GLOW / OPACITY / ROTATION ----
    sectionLabel("Style")
    local function sliderRow(labelText, initial, onChange)
        local r = row(labelText)
        local hold = Instance.new("Frame")
        hold.Size = UDim2.new(1, -120, 0, 20)
        hold.Position = UDim2.fromOffset(110, 5)
        hold.BackgroundTransparency = 1
        hold.ZIndex = 3
        hold.Parent = r
        return Slider.create(hold, initial, onChange)
    end
    local glowSlider = sliderRow("Glow", config.glow, function(v) setField("glow", v) end)
    local opacitySlider = sliderRow("Opacity", config.opacity, function(v) setField("opacity", v) end)
    local rotSlider = sliderRow("Rotation", config.rotation / 360, function(v) setField("rotation", math.floor(v * 360 + 0.5)) end)

    -- ---- EFFECTS ----
    sectionLabel("Effects")
    local function switchRow(labelText, getv, onChange)
        local r = row(labelText)
        local hold = Instance.new("Frame")
        hold.Size = UDim2.fromOffset(54, 26)
        hold.Position = UDim2.new(1, -54, 0.5, -13)
        hold.BackgroundTransparency = 1
        hold.ZIndex = 3
        hold.Parent = r
        Switch.create(hold, getv, onChange)
    end
    switchRow("Rainbow", config.rainbow, function(on) setField("rainbow", on) end)
    switchRow("Spin", config.spin, function(on) setField("spin", on) end)
    switchRow("Pulse", config.pulse, function(on) setField("pulse", on) end)
    switchRow("Click ripple", config.ripple, function(on) setField("ripple", on) end)
    local trailR = sliderRow("Trail", config.trail / 10, function(v) setField("trail", math.floor(v * 10 + 0.5)) end)

    -- ---- PRESETS ----
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
            if ch:IsA("TextButton") or ch:IsA("Frame") then ch:Destroy() end
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
            chip.Text = "  " .. (p.name or "Preset") .. "   ✕"
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
                -- click name area loads; click is simplest: load it
                local c = p.config
                if type(c.color) == "table" then c.color = t2c(c.color) end
                if type(c.outlineColor) == "table" then c.outlineColor = t2c(c.outlineColor) end
                setConfig(cfg(c))
            end)
            chip.MouseButton2Click:Connect(function()
                table.remove(list, idx)
                savePresets(list)
                renderPresets()
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
        local conf = {}
        for k, v in pairs(config) do conf[k] = v end
        conf.color = c2t(config.color)
        conf.outlineColor = c2t(config.outlineColor)
        table.insert(list, { name = "Preset " .. (#list + 1), config = conf })
        savePresets(list)
        renderPresets()
    end)
    renderPresets()

    -- Disable button --------------------------------------------------------
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
        stopOverlay()
        config = nil
        Util.save("CursorConfig", "")
    end)

    -- Sync all controls to the current config -------------------------------
    local function syncControls()
        if not config then return end
        previewGlyph.Text = shapeChar(config.shape)
        previewGlyph.TextColor3 = config.rainbow and Color3.fromRGB(120,220,255) or config.color
        previewGlyph.TextSize = math.clamp(config.size, 12, 50)
        previewGlyph.TextTransparency = config.opacity
        previewGlyph.Rotation = config.rotation
        refreshShapes()
        sizeSlider.set((config.size - SIZE_MIN) / (SIZE_MAX - SIZE_MIN))
        refreshColorSwatch()
        refreshOutlineSwatch()
        if thickSlider and thickSlider.set then thickSlider.set((config.outlineThickness - 1) / 3) end
        if glowSlider and glowSlider.set then glowSlider.set(config.glow) end
        if opacitySlider and opacitySlider.set then opacitySlider.set(config.opacity) end
        if rotSlider and rotSlider.set then rotSlider.set(config.rotation / 360) end
        if trailR and trailR.set then trailR.set(config.trail / 10) end
    end
    onChangeCB = syncControls
    syncControls()

    return { close = close }
end

-- Auto-restore on startup (called from init)
function CursorApp.restore()
    restoreSaved()
end

return CursorApp
