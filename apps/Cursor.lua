-- SYNC / apps / Cursor
-- Custom cursor studio. Renders a real arrow-image cursor (solid or outline)
-- via a RenderStepped overlay and lets you fully customise it: colour, size,
-- outline, glow, opacity, rotation, gradient + rainbow / spin / pulse / trail /
-- click-ripple effects, plus saved named presets and a gallery of looks.
-- Cursor art is loaded from the SYNC repo via Util.remoteImage (getcustomasset).

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local GuiService       = game:GetService("GuiService")

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

-- Cursor artwork. `tintable` white masters recolour via ImageColor3; the fixed
-- full-colour `art` pieces render exactly as supplied. aspect = width / height.
local TIP = Vector2.new(0.07, 0.05)
local SHAPES = {
    { id = "solid",    name = "Solid",   url = RAW .. "arrow_solid.png",   file = "sync_cur_solid.png",   aspect = 256/254, tip = TIP, tintable = true },
    { id = "outline",  name = "Outline", url = RAW .. "arrow_outline.png", file = "sync_cur_outline.png", aspect = 229/256, tip = TIP, tintable = true },
    { id = "art_white", name = "Snow",     url = RAW .. "art_white.png", file = "sync_cur_white.png", aspect = 229/256, tip = TIP, tintable = false },
    { id = "art_navy",  name = "Graphite", url = RAW .. "art_navy.png",  file = "sync_cur_navy.png",  aspect = 256/256, tip = TIP, tintable = false },
    { id = "art_red",   name = "Crimson",  url = RAW .. "art_red.png",   file = "sync_cur_red.png",   aspect = 256/256, tip = TIP, tintable = false },
    { id = "art_grad",  name = "Aurora",   url = RAW .. "art_grad.png",  file = "sync_cur_grad.png",  aspect = 256/256, tip = TIP, tintable = false },
    { id = "art_glow",  name = "Glow",     url = RAW .. "art_glow.png",  file = "sync_cur_glow.png",  aspect = 0.828, tip = Vector2.new(0.104, 0.062), tintable = false },
    { id = "art_blue",  name = "Blue",     url = RAW .. "art_blue.png",  file = "sync_cur_blue.png",  aspect = 1.000, tip = Vector2.new(0.023, 0.062), tintable = false },
    -- Pack pieces (also valid shapes so shapeDef resolves them)
    { id = "sukuna_cursor",  name = "Sukuna",      url = RAW .. "sukuna_cursor.png",  file = "sync_cur_sukc.png", aspect = 0.707, tip = Vector2.new(0.144, 0.031), tintable = false },
    { id = "sukuna_pointer", name = "Sukuna Hand", url = RAW .. "sukuna_pointer.png", file = "sync_cur_sukp.png", aspect = 0.758, tip = Vector2.new(0.216, 0.047), tintable = false },
    -- UI icon only (not a cursor): the "no" symbol shown on the Default tile
    { id = "icon_none", name = "None", url = RAW .. "icon_none.png", file = "sync_icon_none.png", aspect = 1.0, tip = TIP, tintable = true },
}

-- Cursor packs: a matched cursor (idle) + pointer (shown while pressing)
local PACKS = {
    { id = "sukuna", name = "Sukuna", cursor = "sukuna_cursor", pointer = "sukuna_pointer" },
}
local function shapeDef(id)
    for _, s in ipairs(SHAPES) do if s.id == id then return s end end
    return SHAPES[1]
end

-- Bump CVER whenever cursor art changes so the on-disk cache filename changes
-- and executors re-download instead of serving a stale getcustomasset copy.
local CVER = "1"

-- asset id cache (resolved lazily; false = tried and failed)
local assetCache = {}
local assetFails = {}
local function assetFor(id)
    local d = shapeDef(id)
    if assetCache[id] == nil then
        local ok, res = pcall(Util.remoteImage, d.url, CVER .. "_" .. d.file)
        assetCache[id] = (ok and res) or false
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
        pointer = t.pointer or false,   -- pack pointer shape shown while pressing
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

-- Overall tab: the two cursors the user supplied (each works as cursor + pointer)
local GALLERY = {
    { name = "Glow", conf = cfg{ shape="art_glow", outline=false } },
    { name = "Blue", conf = cfg{ shape="art_blue", outline=false } },
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
local overlayGui, root, conn, inputConn, endConn, mouseIconConn, focusConn
local mainImg, borderImg, glowImg, gradient
local trailImgs = {}
local rippleLayer
local history = {}
local config
local pressed = false
local watching = false
local onChangeCB

-- the shape shown right now: pack pointer while pressing, else the base shape
local function activeShapeId()
    if pressed and config and config.pointer then return config.pointer end
    return config and config.shape or "solid"
end

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

    -- gradient overlay on the main image (tintable masters only)
    if config.gradient and def.tintable then
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
    local def = shapeDef(activeShapeId())
    local h = size
    local w = size * def.aspect
    if root then
        root.AnchorPoint = def.tip
        root.Size = UDim2.fromOffset(w, h)
        root.Rotation = rotation
    end
    if mainImg then
        mainImg.Image = assetFor(activeShapeId()) or mainImg.Image
        -- fixed art keeps its own colours; masters take the live tint/gradient
        if not def.tintable then
            mainImg.ImageColor3 = WHITE
        else
            mainImg.ImageColor3 = config.gradient and WHITE or color
            if gradient then gradient.Color = ColorSequence.new(color, config.colorB) end
        end
        mainImg.ImageTransparency = opacity
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

-- Unique token for this execution. If the script is re-run, a new module load
-- replaces _G.__SYNC_CURSOR_GEN, and any loops from the old run see the mismatch
-- and stop themselves -- so re-executing never stacks ghost cursors.
local GEN = {}
pcall(function() _G.__SYNC_CURSOR_GEN = GEN end)
local function isCurrentGen() return _G.__SYNC_CURSOR_GEN == GEN end

-- Remove overlays left behind by a previous execution.
local function destroyOldOverlays()
    local parents = {}
    pcall(function() if typeof(gethui) == "function" then parents[#parents + 1] = gethui() end end)
    pcall(function() parents[#parents + 1] = game:GetService("CoreGui") end)
    pcall(function() parents[#parents + 1] = Util.localPlayer():FindFirstChild("PlayerGui") end)
    for _, p in ipairs(parents) do
        if p then
            for _, ch in ipairs(p:GetChildren()) do
                if ch.Name == "SYNC_CursorOverlay" then pcall(function() ch:Destroy() end) end
            end
        end
    end
end

-- Tear down connections + instance refs WITHOUT restoring the system cursor
-- (used by the watchdog when rebuilding after a wipe). Safe to call any time.
local function resetRefs()
    for _, c in ipairs({ conn, inputConn, endConn, mouseIconConn, focusConn }) do
        if c then pcall(function() c:Disconnect() end) end
    end
    conn, inputConn, endConn, mouseIconConn, focusConn = nil, nil, nil, nil, nil
    if overlayGui then pcall(function() overlayGui:Destroy() end) end
    overlayGui, root, mainImg, borderImg, glowImg, gradient, rippleLayer =
        nil, nil, nil, nil, nil, nil, nil
    trailImgs, history = {}, {}
end

local startOverlay  -- fwd decl (watchdog rebuilds via it)

-- Watchdog: some games periodically wipe CoreGui to kill exploit UIs. If our
-- overlay vanishes while a cursor is active, silently rebuild it.
local function startWatchdog()
    if watching then return end
    watching = true
    task.spawn(function()
        while config and isCurrentGen() do
            task.wait(1)
            if config and isCurrentGen() and (overlayGui == nil or overlayGui.Parent == nil) then
                resetRefs()
                startOverlay()
            end
        end
        watching = false
    end)
end

function startOverlay()
    if overlayGui and overlayGui.Parent then return end
    if overlayGui then resetRefs() end
    destroyOldOverlays()
    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "SYNC_CursorOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.DisplayOrder = 999999
    overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Util.mount(overlayGui)
    -- Util.mount sets DisplayOrder 999999 for every SYNC gui, so app windows
    -- opened later would tie and draw over the cursor. Force this above all.
    pcall(function() overlayGui.DisplayOrder = 2147483647 end)
    -- IgnoreGuiInset = false is the pairing that matches GetMouseLocation 1:1, so
    -- the cursor sits exactly on the OS pointer and clicks land where you see it.
    overlayGui.IgnoreGuiInset = false

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
    local refreshAcc = 0
    conn = RunService.RenderStepped:Connect(function(dt)
        if not isCurrentGen() then if conn then conn:Disconnect(); conn = nil end return end
        if not config then return end
        if not (root and root.Parent) then return end  -- wiped; watchdog will rebuild
        clock = clock + dt
        local m = UserInputService:GetMouseLocation()

        -- Every frame: if the system cursor is showing while ours is active, hide
        -- it. Alt-tabbing away and back re-enables it; this kills it within a
        -- frame so users never see both cursors at once.
        if mainImg and mainImg.Image ~= "" and UserInputService.MouseIconEnabled then
            pcall(function() UserInputService.MouseIconEnabled = false end)
        end

        -- once a second, re-assert state so nothing drifts: if the art failed to
        -- load fall back to the normal cursor (instead of an invisible "none"),
        -- otherwise keep the system cursor hidden and show ours.
        refreshAcc = refreshAcc + dt
        if refreshAcc >= 1 then
            refreshAcc = 0
            local id = activeShapeId()
            local a = assetFor(id)
            if not a then
                assetFails[id] = (assetFails[id] or 0) + 1
                if assetFails[id] <= 5 then assetCache[id] = nil end  -- retry, capped
            else
                assetFails[id] = nil
            end
            pcall(function() UserInputService.MouseIconEnabled = (a == nil) end)
            -- resync press state in case an InputEnded was missed over sinking UI
            pcall(function()
                pressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            end)
        end

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

    endConn = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then pressed = false end
    end)

    inputConn = UserInputService.InputBegan:Connect(function(inp)
        if not config then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        pressed = true
        if not config.ripple then return end
        local ml = UserInputService:GetMouseLocation()
        local ring = Instance.new("Frame")
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromOffset(ml.X, ml.Y)
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

    -- Re-hide the system cursor if a game tries to turn it back on (the classic
    -- reason custom cursors flicker / double up for other people).
    mouseIconConn = UserInputService:GetPropertyChangedSignal("MouseIconEnabled"):Connect(function()
        if config and UserInputService.MouseIconEnabled and assetFor(activeShapeId()) then
            pcall(function() UserInputService.MouseIconEnabled = false end)
        end
    end)

    -- Alt-tabbing back into Roblox re-shows the system cursor; re-hide on focus.
    focusConn = UserInputService.WindowFocused:Connect(function()
        if config and assetFor(activeShapeId()) then
            pcall(function() UserInputService.MouseIconEnabled = false end)
        end
    end)

    -- hide the system cursor only if our art is ready; the 1s loop keeps this true
    pcall(function() UserInputService.MouseIconEnabled = (assetFor(activeShapeId()) == nil) end)

    startWatchdog()
end

local function stopOverlay()
    if conn then conn:Disconnect(); conn = nil end
    if inputConn then inputConn:Disconnect(); inputConn = nil end
    if endConn then endConn:Disconnect(); endConn = nil end
    if mouseIconConn then mouseIconConn:Disconnect(); mouseIconConn = nil end
    if focusConn then focusConn:Disconnect(); focusConn = nil end
    pressed = false
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

    local winConns = {}
    local function close()
        if not CursorApp._gui then return end
        CursorApp._gui = nil
        onChangeCB = nil
        for _, c in ipairs(winConns) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end
    -- No full-screen click-catcher: the window closes only via the red button,
    -- so tapping tabs / the panel / elsewhere never dismisses it.

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

    -- Drag the window by its title bar
    bar.Active = true
    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            win.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

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

    local galleryPage, customPage, packsPage
    local tabButtons = {}
    local function selectTab(name)
        galleryPage.Visible = (name == "Overall")
        customPage.Visible  = (name == "Customize")
        if packsPage then packsPage.Visible = (name == "Packs") end
        for _, t in ipairs(tabButtons) do
            local on = t.name == name
            Util.tween(t.under, { BackgroundTransparency = on and 0 or 1 }, 0.15)
            t.label.TextColor3 = on and WHITE or DIM
        end
    end

    for i, name in ipairs({ "Overall", "Customize", "Packs" }) do
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
        -- "Default" tile first (restores the normal system cursor), then the two
        local items = { { name = "Default", default = true } }
        for _, g in ipairs(GALLERY) do items[#items + 1] = g end
        for _, g in ipairs(items) do
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

            if g.default then
                local noimg = Instance.new("ImageLabel")
                noimg.Size = UDim2.fromOffset(42, 42)
                noimg.Position = UDim2.fromScale(0.5, 0.42)
                noimg.AnchorPoint = Vector2.new(0.5, 0.5)
                noimg.BackgroundTransparency = 1
                noimg.ScaleType = Enum.ScaleType.Fit
                noimg.Image = assetFor("icon_none") or ""
                noimg.ImageColor3 = Color3.fromRGB(170, 170, 178)
                noimg.ZIndex = 5
                noimg.Parent = frame
            else
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
                if g.default then
                    stopOverlay()
                    config = nil
                    Util.save("CursorConfig", "")
                    return
                end
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
    -- PACKS  (matched cursor + pointer; pointer shows while the mouse is held)
    -- =======================================================================
    packsPage = Instance.new("ScrollingFrame")
    packsPage.Size = UDim2.fromOffset(W, contentH)
    packsPage.Position = UDim2.fromOffset(0, contentY)
    packsPage.Visible = false
    packsPage.BackgroundTransparency = 1
    packsPage.BorderSizePixel = 0
    packsPage.ScrollBarThickness = 4
    packsPage.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128)
    packsPage.ScrollBarImageTransparency = 0.4
    packsPage.CanvasSize = UDim2.fromOffset(0, 0)
    Util.autoCanvas(packsPage, "Y")
    packsPage.ZIndex = 3
    packsPage.Parent = win
    do
        local play = Instance.new("UIListLayout")
        play.Padding = UDim.new(0, 12)
        play.SortOrder = Enum.SortOrder.LayoutOrder
        play.Parent = packsPage
        local ppad = Instance.new("UIPadding")
        ppad.PaddingTop = UDim.new(0, 14); ppad.PaddingLeft = UDim.new(0, 14)
        ppad.PaddingRight = UDim.new(0, 14); ppad.PaddingBottom = UDim.new(0, 14)
        ppad.Parent = packsPage

        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(1, 0, 0, 16)
        hint.BackgroundTransparency = 1
        hint.Text = "A pack pairs a cursor with a pointer shown while you hold click."
        hint.Font = Theme.fonts.caption
        hint.TextSize = 11
        hint.TextColor3 = DIM
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.LayoutOrder = 0
        hint.ZIndex = 3
        hint.Parent = packsPage

        for pi, pack in ipairs(PACKS) do
            local card = Instance.new("TextButton")
            card.Text = ""; card.AutoButtonColor = false
            card.Size = UDim2.new(1, 0, 0, 92)
            card.BackgroundColor3 = PANEL
            card.BackgroundTransparency = 0.12
            card.BorderSizePixel = 0
            card.LayoutOrder = pi
            card.ZIndex = 3
            card.Parent = packsPage
            Util.corner(card, 12)
            Util.stroke(card, WHITE, 1, 0.9)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(0, 200, 0, 22)
            nm.Position = UDim2.fromOffset(16, 14)
            nm.BackgroundTransparency = 1
            nm.Text = pack.name
            nm.Font = Theme.fonts.title
            nm.TextSize = 16
            nm.TextColor3 = WHITE
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.ZIndex = 4
            nm.Parent = card

            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(0, 220, 0, 16)
            sub.Position = UDim2.fromOffset(16, 40)
            sub.BackgroundTransparency = 1
            sub.Text = "Cursor + Pointer"
            sub.Font = Theme.fonts.caption
            sub.TextSize = 11
            sub.TextColor3 = DIM
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.ZIndex = 4
            sub.Parent = card

            -- two preview tiles on the right
            local function tile(xoff, shapeId, label)
                local t = Instance.new("Frame")
                t.Size = UDim2.fromOffset(64, 64)
                t.Position = UDim2.new(1, xoff, 0.5, -32)
                t.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
                t.BackgroundTransparency = 0.2
                t.BorderSizePixel = 0
                t.ZIndex = 4
                t.Parent = card
                Util.corner(t, 8)
                local im = Instance.new("ImageLabel")
                im.Size = UDim2.fromOffset(40, 40)
                im.Position = UDim2.fromScale(0.5, 0.46)
                im.AnchorPoint = Vector2.new(0.5, 0.5)
                im.BackgroundTransparency = 1
                im.ScaleType = Enum.ScaleType.Fit
                im.Image = assetFor(shapeId) or ""
                im.ZIndex = 5
                im.Parent = t
                local lb = Instance.new("TextLabel")
                lb.Size = UDim2.new(1, 0, 0, 12)
                lb.Position = UDim2.new(0, 0, 1, -13)
                lb.BackgroundTransparency = 1
                lb.Text = label
                lb.Font = Theme.fonts.caption
                lb.TextSize = 9
                lb.TextColor3 = DIM
                lb.ZIndex = 5
                lb.Parent = t
            end
            tile(-152, pack.cursor, "Cursor")
            tile(-80, pack.pointer, "Pointer")

            card.MouseButton1Click:Connect(function()
                setConfig(cfg{ shape = pack.cursor, pointer = pack.pointer, outline = false })
            end)
        end
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
    Util.autoCanvas(customPage, "Y")
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
      if s.tintable then
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
    Util.autoCanvas(presetScroll, "X")
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
