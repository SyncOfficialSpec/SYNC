-- SYNC / os / Dock
-- macOS-style dock with cursor-proximity magnification, auto-hide, launch bounce,
-- and three screen positions (Bottom / Left / Right). The dock relayouts to the
-- chosen edge: bottom = horizontal, left/right = vertical. Size + magnification
-- are adjustable and persisted. Dock.create(parent, onAppClick) -> { ... }.

local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Dock = {}

local WHITE = Color3.fromRGB(255, 255, 255)

local BASE_DEFAULT = 52
local GAP          = 14
local INFLUENCE    = 150
local MARGIN       = 14   -- gap from the screen edge
local PADX         = 12   -- dock inner padding along its length
local PADY         = 8    -- dock inner padding across its thickness
local BOUNCE_AMP   = 28
local BOUNCE_DUR   = 0.5
local REVEAL_PX    = 4
local TOP_INSET    = 30   -- leave room for the menu bar (vertical docks)

local APPS = {
    { name = "Home",      icon = "app-window",     top = Color3.fromRGB(96, 170, 255),  bot = Color3.fromRGB(28, 110, 230) },
    { name = "Scripts",   icon = "file-text",      top = Color3.fromRGB(172, 122, 255), bot = Color3.fromRGB(104, 52, 212) },
    { name = "Joiner",    icon = "compass",        top = Color3.fromRGB(96, 214, 172),  bot = Color3.fromRGB(30, 156, 122) },
    { name = "Music",     icon = "music",          top = Color3.fromRGB(92, 132, 200),  bot = Color3.fromRGB(46, 72, 117) },
    { name = "Settings",  icon = "settings",       top = Color3.fromRGB(150, 152, 158), bot = Color3.fromRGB(90, 92, 98) },
}

local function buildIcon(parent, app)
    local holder = Instance.new("ImageButton")
    holder.Size = UDim2.fromOffset(BASE_DEFAULT, BASE_DEFAULT)
    holder.AnchorPoint = Vector2.new(0.5, 1)
    holder.BackgroundTransparency = 1
    holder.AutoButtonColor = false
    holder.ZIndex = 6
    holder.Parent = parent

    local tile = Instance.new("Frame")
    tile.Size = UDim2.fromScale(1, 1)
    tile.BackgroundColor3 = app.top
    tile.BorderSizePixel = 0
    tile.ZIndex = 6
    tile.Parent = holder
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2237, 0)
    corner.Parent = tile
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(app.top, app.bot)
    grad.Rotation = 90
    grad.Parent = tile
    Util.stroke(tile, WHITE, 1, 0.86)

    local glyph = Instance.new("ImageLabel")
    glyph.Size = UDim2.fromScale(0.56, 0.56)
    glyph.AnchorPoint = Vector2.new(0.5, 0.5)
    glyph.Position = UDim2.fromScale(0.5, 0.5)
    glyph.BackgroundTransparency = 1
    glyph.ZIndex = 7
    glyph.Parent = tile
    Icons.apply(glyph, app.icon, app.dark and Color3.fromRGB(40, 40, 46) or WHITE)

    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.new(0.5, 0, 0, -10)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Size = UDim2.fromOffset(0, 22)
    label.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    label.BackgroundTransparency = 1
    label.Text = "  " .. app.name .. "  "
    label.Font = Theme.fonts.body
    label.TextSize = 13
    label.TextColor3 = WHITE
    label.TextTransparency = 1
    label.ZIndex = 9
    label.Parent = holder
    Util.corner(label, 7)
    local lstroke = Util.stroke(label, WHITE, 1, 1)

    -- running-indicator dot (macOS style): lit while the app's window is open
    local runDot = Instance.new("Frame")
    runDot.AnchorPoint = Vector2.new(0.5, 0.5)
    runDot.Size = UDim2.fromOffset(4, 4)
    runDot.BackgroundColor3 = WHITE
    runDot.BackgroundTransparency = 1
    runDot.BorderSizePixel = 0
    runDot.ZIndex = 8
    runDot.Parent = holder
    Util.corner(runDot, 2)

    return {
        holder = holder, label = label, lstroke = lstroke, app = app.name,
        size = BASE_DEFAULT, bounceStart = nil, restCenter = 0, centerMain = 0,
        pressed = false, labelShown = false, runDot = runDot, running = false,
    }
end

function Dock.create(parent, onAppClick)
    local vp = Util.viewport()

    -- Dock bar
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    bar.BackgroundTransparency = 0.22
    bar.BorderSizePixel = 0
    bar.ZIndex = 5
    bar.Parent = parent
    Util.corner(bar, 22)
    Util.stroke(bar, WHITE, 1, 0.86)
    Util.shadow(bar, { blur = 36, spread = 0, transparency = 0.55, offset = UDim2.fromOffset(0, 10) })

    local icons = {}
    for _, app in ipairs(APPS) do
        icons[#icons + 1] = buildIcon(parent, app)
    end

    -- Persisted, live-editable state
    local function clamp01(x) return math.clamp(x, 0, 1) end
    local baseSize = math.floor(40 + clamp01(tonumber(Util.load("DockSizeFrac")) or 0.4) * 32 + 0.5)
    local magScale = 1.0 + clamp01(tonumber(Util.load("DockMagFrac")) or 0.55) * 1.4
    local pos = Util.load("DockPosition") or "bottom"
    local alwaysShow = Util.load("DockAlwaysShow") == "true"

    local shown = false
    local curOff = 200
    local offVel = 0

    -- Press feedback + click (labels handled in the loop)
    for _, ic in ipairs(icons) do
        ic.holder.MouseButton1Down:Connect(function() ic.pressed = true end)
        ic.holder.MouseButton1Up:Connect(function() ic.pressed = false end)
        ic.holder.MouseLeave:Connect(function() ic.pressed = false end)
        ic.holder.MouseButton1Click:Connect(function()
            ic.bounceStart = tick()
            if onAppClick then onAppClick(ic.app) end
        end)
    end

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        local m = UserInputService:GetMouseLocation()
        local mouseX, mouseY = m.X, m.Y
        local alpha = 1 - math.exp(-dt * 16)

        local BASE = baseSize
        local MAX = baseSize * magScale
        local thickness = BASE + PADY * 2
        local isV = (pos ~= "bottom")
        local mainCenter = isV and (TOP_INSET + (vp.Y - TOP_INSET) / 2) or (vp.X / 2)
        local cursorMain = isV and mouseY or mouseX

        -- Reveal / hide / near-dock checks per edge
        local revealHit, hideAway, nearDock
        if pos == "bottom" then
            revealHit = mouseY >= vp.Y - REVEAL_PX
            hideAway  = mouseY < vp.Y - (MAX + 40)
            nearDock  = mouseY >= (vp.Y - thickness - MARGIN) - 30
        elseif pos == "left" then
            revealHit = mouseX <= REVEAL_PX
            hideAway  = mouseX > (MAX + 40)
            nearDock  = mouseX <= (MARGIN + thickness) + 30
        else -- right
            revealHit = mouseX >= vp.X - REVEAL_PX
            hideAway  = mouseX < vp.X - (MAX + 40)
            nearDock  = mouseX >= (vp.X - MARGIN - thickness) - 30
        end

        if alwaysShow then shown = true
        elseif not shown then if revealHit then shown = true end
        else if hideAway then shown = false end end

        local hideOffset = thickness + 40
        local sdt = math.min(dt, 1 / 30)
        local targetOff = shown and 0 or hideOffset
        offVel = offVel + (-220 * (curOff - targetOff) - 26 * offVel) * sdt
        curOff = curOff + offVel * sdt

        local magnifyActive = shown and nearDock

        -- Resting centers along the main axis
        local restingLen = #icons * BASE + (#icons - 1) * GAP
        local restStart = mainCenter - restingLen / 2
        for i, ic in ipairs(icons) do
            ic.restCenter = restStart + (i - 1) * (BASE + GAP) + BASE / 2
        end

        -- Magnified sizes
        for _, ic in ipairs(icons) do
            local target = BASE
            if magnifyActive then
                local d = math.abs(cursorMain - ic.restCenter)
                if d < INFLUENCE then
                    local f = math.cos((d / INFLUENCE) * (math.pi / 2))
                    f = f * f * (3 - 2 * f)
                    target = BASE + (MAX - BASE) * f
                end
            end
            if ic.pressed then target = target * 0.9 end
            ic.size = ic.size + (target - ic.size) * alpha
        end

        -- Lay out along the main axis
        local W = GAP * (#icons - 1)
        for _, ic in ipairs(icons) do W += ic.size end
        local accM = mainCenter - W / 2

        local baseBottomY = vp.Y - MARGIN - PADY
        local baseLeftX   = MARGIN + PADY
        local baseRightX  = vp.X - MARGIN - PADY

        for _, ic in ipairs(icons) do
            local cm = accM + ic.size / 2
            ic.centerMain = cm
            local bounce = 0
            if ic.bounceStart then
                local t = tick() - ic.bounceStart
                if t < BOUNCE_DUR then bounce = BOUNCE_AMP * math.sin((t / BOUNCE_DUR) * math.pi)
                else ic.bounceStart = nil end
            end
            local interior = (ic.size - BASE) * 0.16 + bounce
            ic.holder.Size = UDim2.fromOffset(ic.size, ic.size)

            if pos == "bottom" then
                ic.holder.AnchorPoint = Vector2.new(0.5, 1)
                ic.holder.Position = UDim2.fromOffset(cm, baseBottomY + curOff - interior)
                ic.label.AnchorPoint = Vector2.new(0.5, 1)
                ic.label.Position = UDim2.new(0.5, 0, 0, -8)
                ic.runDot.Position = UDim2.new(0.5, 0, 1, 5)
            elseif pos == "left" then
                ic.holder.AnchorPoint = Vector2.new(0, 0.5)
                ic.holder.Position = UDim2.fromOffset(baseLeftX - curOff + interior, cm)
                ic.label.AnchorPoint = Vector2.new(0, 0.5)
                ic.label.Position = UDim2.new(1, 8, 0.5, 0)
                ic.runDot.Position = UDim2.new(0, -5, 0.5, 0)
            else -- right
                ic.holder.AnchorPoint = Vector2.new(1, 0.5)
                ic.holder.Position = UDim2.fromOffset(baseRightX + curOff - interior, cm)
                ic.label.AnchorPoint = Vector2.new(1, 0.5)
                ic.label.Position = UDim2.new(0, -8, 0.5, 0)
                ic.runDot.Position = UDim2.new(1, 5, 0.5, 0)
            end
            accM += ic.size + GAP
        end

        -- Running dots: lit while the app's window is open (polls CoreGui)
        for _, ic in ipairs(icons) do
            local isOpen = parent.Parent and parent.Parent:FindFirstChild("SYNC_" .. ic.app) ~= nil
            if isOpen ~= ic.running then
                ic.running = isOpen
                Util.tween(ic.runDot, { BackgroundTransparency = isOpen and 0 or 1 }, 0.18)
            end
        end

        -- Labels (poll-based)
        local hovered = nil
        if magnifyActive then
            for _, ic in ipairs(icons) do
                if cursorMain >= ic.centerMain - ic.size / 2 and cursorMain <= ic.centerMain + ic.size / 2 then
                    hovered = ic
                    break
                end
            end
        end
        for _, ic in ipairs(icons) do
            local want = (ic == hovered)
            if want ~= ic.labelShown then
                ic.labelShown = want
                Util.tween(ic.label, { TextTransparency = want and 0 or 1, BackgroundTransparency = want and 0.1 or 1 }, 0.12)
                Util.tween(ic.lstroke, { Transparency = want and 0.7 or 1 }, 0.12)
            end
        end

        -- Bar wraps the icons on the chosen edge
        local lengthPx = W + PADX * 2
        if pos == "bottom" then
            bar.AnchorPoint = Vector2.new(0.5, 1)
            bar.Size = UDim2.fromOffset(lengthPx, thickness)
            bar.Position = UDim2.fromOffset(mainCenter, (vp.Y - MARGIN) + curOff)
        elseif pos == "left" then
            bar.AnchorPoint = Vector2.new(0, 0.5)
            bar.Size = UDim2.fromOffset(thickness, lengthPx)
            bar.Position = UDim2.fromOffset(MARGIN - curOff, mainCenter)
        else -- right
            bar.AnchorPoint = Vector2.new(1, 0.5)
            bar.Size = UDim2.fromOffset(thickness, lengthPx)
            bar.Position = UDim2.fromOffset((vp.X - MARGIN) + curOff, mainCenter)
        end
    end)

    return {
        setAlwaysShow = function(v) alwaysShow = v and true or false end,
        setDockSize = function(f) baseSize = math.floor(40 + clamp01(f) * 32 + 0.5) end,
        setMagnification = function(f) magScale = 1.0 + clamp01(f) * 1.4 end,
        setPosition = function(p)
            pos = p
            shown = false
            curOff = baseSize + PADY * 2 + 40
            offVel = 0
        end,
        getDockFrac = function() return (baseSize - 40) / 32 end,
        getMagFrac = function() return (magScale - 1.0) / 1.4 end,
        getPosition = function() return pos end,
        destroy = function()
            if conn then conn:Disconnect() end
            bar:Destroy()
            for _, ic in ipairs(icons) do ic.holder:Destroy() end
        end,
    }
end

return Dock
