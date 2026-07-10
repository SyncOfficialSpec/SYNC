-- SYNC / os / Boot
-- Branded loading screen: black backdrop, a mono dithered character floating in a
-- glowing multi-color ring (Google-logo gradient), a big gradient "SYNC" headline,
-- corner frame brackets, sparkles, and a thin progress bar with a believable cadence.
-- Boot.run(onDone) plays the sequence then fades out and calls onDone().

local RunService = game:GetService("RunService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Boot = {}

local RAW      = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"
local CHAR_URL = RAW .. "boot-char.png"

-- Google brand gradient, looped (blue -> red -> yellow -> green -> blue) so an
-- animated rotation flows seamlessly with no visible seam.
local GOOGLE = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(66, 133, 244)),  -- blue
    ColorSequenceKeypoint.new(0.28, Color3.fromRGB(234, 67, 53)),   -- red
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(251, 188, 5)),   -- yellow
    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(52, 168, 83)),   -- green
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(66, 133, 244)),  -- back to blue
})

local WHITE = Color3.fromRGB(245, 245, 247)

function Boot.run(onDone)
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

    -- Track everything we tween out at the end, and a flag to stop RenderStepped loops.
    local alive = true
    local fadeOuts = {} -- { inst = {props...} }

    -- -----------------------------------------------------------------------
    -- Corner frame: hairline rounded border + four L-brackets, like the ref card.
    -- -----------------------------------------------------------------------
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -48, 1, -48)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = screen
    Util.corner(frame, 18)
    local frameStroke = Util.stroke(frame, WHITE, 1, 0.82)
    fadeOuts[frameStroke] = { Transparency = 1 }

    local function bracket(ax, ay, sx, sy)
        -- two thin bars forming an L in one corner
        local L = 26
        local h = Instance.new("Frame")
        h.Size = UDim2.fromOffset(L, 2)
        h.AnchorPoint = Vector2.new(ax, ay)
        h.Position = UDim2.new(sx, sx == 0 and 10 or -10, sy, sy == 0 and 10 or -10)
        h.BackgroundColor3 = WHITE
        h.BackgroundTransparency = 0.45
        h.BorderSizePixel = 0
        h.Parent = frame
        fadeOuts[h] = { BackgroundTransparency = 1 }
        local v = Instance.new("Frame")
        v.Size = UDim2.fromOffset(2, L)
        v.AnchorPoint = Vector2.new(ax, ay)
        v.Position = UDim2.new(sx, sx == 0 and 10 or -10, sy, sy == 0 and 10 or -10)
        v.BackgroundColor3 = WHITE
        v.BackgroundTransparency = 0.45
        v.BorderSizePixel = 0
        v.Parent = frame
        fadeOuts[v] = { BackgroundTransparency = 1 }
    end
    bracket(0, 0, 0, 0)   -- top-left
    bracket(1, 0, 1, 0)   -- top-right
    bracket(0, 1, 0, 1)   -- bottom-left
    bracket(1, 1, 1, 1)   -- bottom-right

    -- -----------------------------------------------------------------------
    -- Glow ring (asset-free): concentric circle strokes carrying the Google
    -- gradient. Outer copies are larger + fainter for a soft bloom. All strokes'
    -- gradients rotate together for the flowing-color effect.
    -- -----------------------------------------------------------------------
    local ringHolder = Instance.new("Frame")
    ringHolder.Size = UDim2.fromOffset(360, 360)
    ringHolder.Position = UDim2.fromScale(0.72, 0.5)
    ringHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    ringHolder.BackgroundTransparency = 1
    ringHolder.Parent = screen

    local gradients = {}
    local function makeRing(scale, thickness, transparency)
        local r = Instance.new("Frame")
        r.Size = UDim2.fromScale(scale, scale)
        r.Position = UDim2.fromScale(0.5, 0.5)
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.BackgroundTransparency = 1
        r.Parent = ringHolder
        Util.corner(r, 1000) -- huge radius -> perfect circle
        local s = Instance.new("UIStroke")
        s.Thickness = thickness
        s.Transparency = 1 -- fade in below
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = r
        local g = Instance.new("UIGradient")
        g.Color = GOOGLE
        g.Parent = s
        gradients[#gradients + 1] = g
        Util.tween(s, { Transparency = transparency }, 0.9, Enum.EasingStyle.Sine)
        fadeOuts[s] = { Transparency = 1 }
        return r
    end
    makeRing(1.28, 2, 0.72) -- outer bloom
    makeRing(1.12, 3, 0.5)  -- mid bloom
    makeRing(1.0, 6, 0.0)   -- crisp main ring

    -- Continuously rotate every ring gradient (flowing Google colors).
    task.spawn(function()
        local rot = 0
        while alive do
            local dt = RunService.RenderStepped:Wait()
            rot = (rot + dt * 40) % 360
            for _, g in ipairs(gradients) do g.Rotation = rot end
        end
    end)

    -- -----------------------------------------------------------------------
    -- Character (mono dithered figure). Loaded from the repo; skipped if it fails.
    -- -----------------------------------------------------------------------
    task.spawn(function()
        local id = Util.remoteImage(CHAR_URL, "sync_boot_char.png")
        if not id or not alive then return end
        local char = Instance.new("ImageLabel")
        char.Size = UDim2.fromOffset(330, 330)
        char.Position = UDim2.fromScale(0.5, 0.52)
        char.AnchorPoint = Vector2.new(0.5, 0.5)
        char.BackgroundTransparency = 1
        char.Image = id
        char.ScaleType = Enum.ScaleType.Fit
        char.ImageTransparency = 1
        char.ZIndex = 5
        char.Parent = ringHolder
        local sc = Instance.new("UIScale")
        sc.Scale = 0.9
        sc.Parent = char
        Util.tween(char, { ImageTransparency = 0 }, 0.8, Enum.EasingStyle.Sine)
        Util.tween(sc, { Scale = 1 }, 1.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        fadeOuts[char] = { ImageTransparency = 1 }
    end)

    -- -----------------------------------------------------------------------
    -- Headline (left): "WELCOME TO" / big gradient "SYNC" / gray tagline.
    -- Each slides in from the left and fades up, staggered.
    -- -----------------------------------------------------------------------
    local function slideIn(label, targetX, delay)
        label.Position = UDim2.new(targetX.Scale, targetX.Offset - 24, label.Position.Y.Scale, label.Position.Y.Offset)
        task.delay(delay, function()
            if not alive then return end
            Util.tween(label, {
                Position = UDim2.new(targetX.Scale, targetX.Offset, label.Position.Y.Scale, label.Position.Y.Offset),
                TextTransparency = 0,
            }, 0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end)
    end

    local kicker = Instance.new("TextLabel")
    kicker.Size = UDim2.fromOffset(360, 22)
    kicker.Position = UDim2.fromScale(0.1, 0.4)
    kicker.BackgroundTransparency = 1
    kicker.Font = Theme.fonts.caption
    kicker.Text = "W E L C O M E   T O"
    kicker.TextSize = 15
    kicker.TextColor3 = WHITE
    kicker.TextTransparency = 1
    kicker.TextXAlignment = Enum.TextXAlignment.Left
    kicker.Parent = screen
    fadeOuts[kicker] = { TextTransparency = 1 }

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(400, 96)
    title.Position = UDim2.fromScale(0.1, 0.47)
    title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title
    title.Text = "SYNC"
    title.TextSize = 92
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = screen
    local titleGrad = Instance.new("UIGradient")
    titleGrad.Color = GOOGLE
    titleGrad.Rotation = 12
    titleGrad.Parent = title
    gradients[#gradients + 1] = titleGrad
    fadeOuts[title] = { TextTransparency = 1 }

    local tagline = Instance.new("TextLabel")
    tagline.Size = UDim2.fromOffset(400, 22)
    tagline.Position = UDim2.fromScale(0.1, 0.58)
    tagline.BackgroundTransparency = 1
    tagline.Font = Theme.fonts.body
    tagline.Text = "your desktop, reimagined"
    tagline.TextSize = 17
    tagline.TextColor3 = Theme.c.textSecondary
    tagline.TextTransparency = 1
    tagline.TextXAlignment = Enum.TextXAlignment.Left
    tagline.Parent = screen
    fadeOuts[tagline] = { TextTransparency = 1 }

    slideIn(kicker, UDim.new(0.1, 0), 0.25)
    slideIn(title, UDim.new(0.1, 0), 0.38)
    slideIn(tagline, UDim.new(0.1, 0), 0.55)

    -- -----------------------------------------------------------------------
    -- Progress bar (under the headline), gradient fill matching the ring.
    -- -----------------------------------------------------------------------
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(300, 4)
    track.Position = UDim2.new(0.1, 0, 0.65, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.BackgroundColor3 = Color3.fromRGB(70, 70, 74)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Parent = screen
    Util.corner(track, 2)
    Util.tween(track, { BackgroundTransparency = 0.5 }, 0.5)
    fadeOuts[track] = { BackgroundTransparency = 1 }

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Util.corner(fill, 2)
    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = GOOGLE
    fillGrad.Parent = fill

    -- -----------------------------------------------------------------------
    -- Sparkles: a handful of twinkling four-point stars near the ring/headline.
    -- -----------------------------------------------------------------------
    local sparkPositions = {
        { 0.55, 0.28, 16 }, { 0.9, 0.34, 12 }, { 0.63, 0.74, 14 },
        { 0.86, 0.7, 18 }, { 0.48, 0.5, 10 }, { 0.94, 0.52, 12 },
    }
    for i, sp in ipairs(sparkPositions) do
        local star = Instance.new("TextLabel")
        star.Size = UDim2.fromOffset(sp[3] * 2, sp[3] * 2)
        star.Position = UDim2.fromScale(sp[1], sp[2])
        star.AnchorPoint = Vector2.new(0.5, 0.5)
        star.BackgroundTransparency = 1
        star.Font = Enum.Font.GothamBold
        star.Text = "\u{2726}" -- ✦
        star.TextSize = sp[3]
        star.TextColor3 = WHITE
        star.TextTransparency = 1
        star.Parent = screen
        fadeOuts[star] = { TextTransparency = 1 }
        task.delay(0.5 + i * 0.12, function()
            while alive and star.Parent do
                Util.tween(star, { TextTransparency = 0.15 }, 0.7, Enum.EasingStyle.Sine)
                task.wait(0.75)
                if not (alive and star.Parent) then break end
                Util.tween(star, { TextTransparency = 0.85 }, 0.9, Enum.EasingStyle.Sine)
                task.wait(1.0)
            end
        end)
    end

    -- -----------------------------------------------------------------------
    -- Progress cadence, then fade everything out and hand off to onDone.
    -- -----------------------------------------------------------------------
    task.spawn(function()
        local steps = {
            { p = 0.28, t = 0.55, hold = 0.20 },
            { p = 0.52, t = 0.70, hold = 0.28 },
            { p = 0.74, t = 0.55, hold = 0.34 },
            { p = 0.90, t = 0.60, hold = 0.18 },
            { p = 1.00, t = 0.45, hold = 0.00 },
        }
        for _, s in ipairs(steps) do
            Util.tween(fill, { Size = UDim2.fromScale(s.p, 1) }, s.t,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(s.t + s.hold)
        end
        task.wait(0.4)

        -- Fade every tracked element, then the backdrop.
        for inst, props in pairs(fadeOuts) do
            if inst and inst.Parent then Util.tween(inst, props, 0.45) end
        end
        Util.tween(screen, { BackgroundTransparency = 1 }, 0.6)
        task.wait(0.7)
        alive = false
        gui:Destroy()
        if onDone then onDone() end
    end)

    return gui
end

return Boot
