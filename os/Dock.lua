-- SYNC / os / Dock
-- macOS-style dock with cursor-proximity magnification (fisheye). Icons grow
-- toward the cursor with a smooth cosine falloff, push their neighbours apart,
-- show their name on hover, and bounce when clicked. Slides up on first show.
--
-- Dock.create(parent) -> { destroy } ; parent is a ScreenGui/Frame to host it.

local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local Dock = {}

local WHITE = Color3.fromRGB(255, 255, 255)

-- Tunables
local BASE          = 52    -- resting icon size (px)
local MAX           = 94    -- size directly under the cursor
local GAP           = 14    -- gap between icons
local INFLUENCE     = 150   -- horizontal reach of the magnification (px)
local BOTTOM_MARGIN = 14    -- gap from screen bottom to dock
local PADX          = 12    -- dock inner horizontal padding
local PADY          = 8     -- dock inner vertical padding
local BOUNCE_AMP    = 28    -- launch bounce height
local BOUNCE_DUR    = 0.5

-- App roster: name, Lucide glyph, squircle gradient. A few real-ish macOS apps
-- plus some "Test" tiles, as requested.
local APPS = {
    { name = "Finder",    icon = "folder",         top = Color3.fromRGB(70, 170, 255),  bot = Color3.fromRGB(20, 110, 230) },
    { name = "Safari",    icon = "compass",        top = Color3.fromRGB(90, 200, 255),  bot = Color3.fromRGB(20, 120, 235) },
    { name = "Messages",  icon = "message-circle", top = Color3.fromRGB(90, 220, 110),  bot = Color3.fromRGB(40, 180, 70) },
    { name = "Mail",      icon = "mail",           top = Color3.fromRGB(80, 180, 255),  bot = Color3.fromRGB(30, 120, 240) },
    { name = "Maps",      icon = "map",            top = Color3.fromRGB(120, 215, 130), bot = Color3.fromRGB(70, 175, 90) },
    { name = "Photos",    icon = "image",          top = Color3.fromRGB(255, 120, 160), bot = Color3.fromRGB(255, 175, 70) },
    { name = "Music",     icon = "music",          top = Color3.fromRGB(255, 110, 130), bot = Color3.fromRGB(230, 40, 90) },
    { name = "Calendar",  icon = "calendar",       top = Color3.fromRGB(255, 255, 255), bot = Color3.fromRGB(235, 235, 240), dark = true },
    { name = "Notes",     icon = "file-text",      top = Color3.fromRGB(255, 225, 120), bot = Color3.fromRGB(245, 195, 60), dark = true },
    { name = "Terminal",  icon = "terminal",       top = Color3.fromRGB(70, 72, 78),    bot = Color3.fromRGB(30, 32, 36) },
    { name = "Settings",  icon = "settings",       top = Color3.fromRGB(150, 152, 158), bot = Color3.fromRGB(90, 92, 98) },
    { name = "Test",      icon = "gamepad-2",      top = Color3.fromRGB(180, 130, 255), bot = Color3.fromRGB(120, 70, 230) },
    { name = "Test 2",    icon = "sparkles",       top = Color3.fromRGB(120, 200, 255), bot = Color3.fromRGB(160, 130, 255) },
}

local function buildIcon(parent, app)
    local holder = Instance.new("ImageButton")
    holder.Size = UDim2.fromOffset(BASE, BASE)
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
    corner.CornerRadius = UDim.new(0.2237, 0) -- squircle-ish, scales with size
    corner.Parent = tile
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(app.top, app.bot)
    grad.Rotation = 90
    grad.Parent = tile
    Util.stroke(tile, WHITE, 1, 0.86) -- subtle top highlight edge

    local glyph = Instance.new("ImageLabel")
    glyph.Size = UDim2.fromScale(0.56, 0.56)
    glyph.AnchorPoint = Vector2.new(0.5, 0.5)
    glyph.Position = UDim2.fromScale(0.5, 0.5)
    glyph.BackgroundTransparency = 1
    glyph.ZIndex = 7
    glyph.Parent = tile
    Icons.apply(glyph, app.icon, app.dark and Color3.fromRGB(40, 40, 46) or WHITE)

    -- Name label (shown on hover, above the icon)
    local label = Instance.new("TextLabel")
    label.AutoLocalize = false
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Position = UDim2.new(0.5, 0, 0, -10)
    label.Size = UDim2.fromOffset(0, 22)
    label.AutomaticSize = Enum.AutomaticSize.X
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

    return { holder = holder, label = label, lstroke = lstroke, size = BASE, bounceStart = nil, restCenter = 0 }
end

function Dock.create(parent)
    local vp = Util.viewport()
    local cx = vp.X / 2
    local stripH = MAX + 60
    local baselineY = stripH - BOTTOM_MARGIN - PADY -- in strip-local coords
    local barLocalY = stripH - BOTTOM_MARGIN

    -- Hover strip across the bottom. The bar + icons live INSIDE it so hovering
    -- an icon doesn't fire the strip's MouseLeave (which would kill magnify).
    local strip = Instance.new("Frame")
    strip.AnchorPoint = Vector2.new(0.5, 1)
    strip.Position = UDim2.fromOffset(cx, vp.Y)
    strip.Size = UDim2.fromOffset(vp.X, stripH)
    strip.BackgroundTransparency = 1
    strip.ZIndex = 4
    strip.Parent = parent

    -- Dock bar (frosted, rounded, soft shadow)
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0.5, 1)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    bar.BackgroundTransparency = 0.22
    bar.BorderSizePixel = 0
    bar.ZIndex = 5
    bar.Parent = strip
    Util.corner(bar, 22)
    Util.stroke(bar, WHITE, 1, 0.86)
    Util.shadow(bar, { blur = 36, spread = 0, transparency = 0.55, offset = UDim2.fromOffset(0, 10) })

    local icons = {}
    for _, app in ipairs(APPS) do
        local ic = buildIcon(strip, app)
        icons[#icons + 1] = ic
    end

    -- Resting centers (for stable distance math, independent of live magnify)
    local restingW = #icons * BASE + (#icons - 1) * GAP
    local restLeft = cx - restingW / 2
    for i, ic in ipairs(icons) do
        ic.restCenter = restLeft + (i - 1) * (BASE + GAP) + BASE / 2
    end

    -- Auto-hide: the dock stays hidden off the bottom edge and only reveals when
    -- the cursor presses against the very bottom of the screen (like macOS).
    local REVEAL_PX = 4                       -- must touch within this of the bottom
    local hideOffset = stripH                 -- how far down to tuck it away
    local shown = false
    local curOff = hideOffset                 -- current slide offset (starts hidden)

    -- Hover labels + click bounce
    for _, ic in ipairs(icons) do
        ic.holder.MouseEnter:Connect(function()
            Util.tween(ic.label, { TextTransparency = 0, BackgroundTransparency = 0.1 }, 0.15)
            Util.tween(ic.lstroke, { Transparency = 0.7 }, 0.15)
        end)
        ic.holder.MouseLeave:Connect(function()
            Util.tween(ic.label, { TextTransparency = 1, BackgroundTransparency = 1 }, 0.15)
            Util.tween(ic.lstroke, { Transparency = 1 }, 0.15)
        end)
        ic.holder.MouseButton1Click:Connect(function() ic.bounceStart = tick() end)
    end

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        local m = UserInputService:GetMouseLocation()
        local mouseX, mouseY = m.X, m.Y
        local alpha = 1 - math.exp(-dt * 16) -- frame-rate independent smoothing

        -- Reveal/hide state (hysteresis: reveal only at the very bottom edge,
        -- hide once the cursor moves well above the dock).
        if not shown then
            if mouseY >= vp.Y - REVEAL_PX then shown = true end
        else
            if mouseY < vp.Y - (MAX + 40) then shown = false end
        end
        local targetOff = shown and 0 or hideOffset
        curOff = curOff + (targetOff - curOff) * (1 - math.exp(-dt * 12))

        -- Target sizes from cursor proximity (only while shown)
        for _, ic in ipairs(icons) do
            local target = BASE
            if shown then
                local d = math.abs(mouseX - ic.restCenter)
                if d < INFLUENCE then
                    local f = math.cos((d / INFLUENCE) * (math.pi / 2)) -- 1 at cursor -> 0 at edge
                    target = BASE + (MAX - BASE) * f
                end
            end
            ic.size = ic.size + (target - ic.size) * alpha
        end

        -- Lay out centered, summing live sizes (neighbours pushed apart)
        local W = GAP * (#icons - 1)
        for _, ic in ipairs(icons) do W += ic.size end
        local accX = cx - W / 2
        local off = curOff
        for _, ic in ipairs(icons) do
            local center = accX + ic.size / 2
            local bounce = 0
            if ic.bounceStart then
                local t = tick() - ic.bounceStart
                if t < BOUNCE_DUR then
                    bounce = -BOUNCE_AMP * math.sin((t / BOUNCE_DUR) * math.pi)
                else
                    ic.bounceStart = nil
                end
            end
            ic.holder.Size = UDim2.fromOffset(ic.size, ic.size)
            ic.holder.Position = UDim2.fromOffset(center, baselineY + off + bounce)
            accX += ic.size + GAP
        end

        -- Bar wraps the icons and rides the intro offset
        bar.Size = UDim2.fromOffset(W + PADX * 2, BASE + PADY * 2)
        bar.Position = UDim2.fromOffset(cx, barLocalY + off)
    end)

    return {
        destroy = function()
            if conn then conn:Disconnect() end
            strip:Destroy() -- bar + icons are children, go with it
        end,
    }
end

return Dock
