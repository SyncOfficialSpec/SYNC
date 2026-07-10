-- SYNC / os / Boot
-- Branded loading screen v2 ("baked-bloom cinematic"). All fancy visuals are
-- pre-rendered PNGs served from the repo (rainbow bloom ring with a smoked-glass
-- interior, porthole-clipped mono character, radial halo, star sparkles) because
-- baked images render reliably everywhere, unlike stroke gradients / font glyphs.
-- Layout scales with the viewport. Boot.run(onDone) plays, fades out, calls onDone().

local RunService = game:GetService("RunService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Boot = {}

local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"
-- v2 local filenames: getcustomasset caches by file path on many executors, so
-- new art needs new names or clients keep showing the old pixels.
local ASSETS = {
    char = { url = RAW .. "boot-char.png", file = "sync_boot2_char.png" },
    ring = { url = RAW .. "boot-ring.png", file = "sync_boot2_ring.png" },
    halo = { url = RAW .. "boot-halo.png", file = "sync_boot2_halo.png" },
    star = { url = RAW .. "boot-star.png", file = "sync_boot2_star.png" },
}

-- Google brand gradient, looped so offset/rotation animation is seamless.
local GOOGLE = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(66, 133, 244)),  -- blue
    ColorSequenceKeypoint.new(0.28, Color3.fromRGB(234, 67, 53)),   -- red
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(251, 188, 5)),   -- yellow
    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(52, 168, 83)),   -- green
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(66, 133, 244)),  -- back to blue
})

local WHITE = Color3.fromRGB(245, 245, 247)
local CHAR_ASPECT = 591 / 609 -- boot-char.png width/height

function Boot.run(onDone)
    local vp = Util.viewport()
    -- design space is 1080p; scale every offset by S so the screen fills any window
    local S = math.clamp(vp.Y / 1080, 0.45, 1.7)
    local function px(n) return math.floor(n * S + 0.5) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Boot"
    Util.mount(gui)

    local screen = Instance.new("Frame")
    screen.Size = UDim2.fromScale(1, 1)
    screen.BackgroundColor3 = Color3.fromRGB(4, 4, 6)
    screen.BorderSizePixel = 0
    screen.BackgroundTransparency = 1
    screen.Parent = gui
    Util.tween(screen, { BackgroundTransparency = 0 }, 0.4)

    local alive = true
    local fadeOuts = {} -- inst -> tween props for the exit

    -- -----------------------------------------------------------------------
    -- Corner brackets
    -- -----------------------------------------------------------------------
    local inset, blen = px(34), px(30)
    for _, c in ipairs({ {0,0}, {1,0}, {0,1}, {1,1} }) do
        local ax, ay = c[1], c[2]
        for _, bar in ipairs({ { blen, 2 }, { 2, blen } }) do
            local f = Instance.new("Frame")
            f.Size = UDim2.fromOffset(bar[1], bar[2])
            f.AnchorPoint = Vector2.new(ax, ay)
            f.Position = UDim2.new(ax, ax == 0 and inset or -inset, ay, ay == 0 and inset or -inset)
            f.BackgroundColor3 = WHITE
            f.BackgroundTransparency = 0.45
            f.BorderSizePixel = 0
            f.Parent = screen
            fadeOuts[f] = { BackgroundTransparency = 1 }
        end
    end

    -- -----------------------------------------------------------------------
    -- Right stage: halo -> rainbow ring (rotating) -> porthole character.
    -- The stage frame carries the idle float bob and the exit zoom.
    -- -----------------------------------------------------------------------
    local stage = Instance.new("Frame")
    stage.Size = UDim2.fromOffset(px(760), px(760))
    stage.Position = UDim2.fromScale(0.66, 0.5)
    stage.AnchorPoint = Vector2.new(0.5, 0.5)
    stage.BackgroundTransparency = 1
    stage.Parent = screen
    local stageScale = Instance.new("UIScale")
    stageScale.Parent = stage

    local ringLabel -- set when loaded; rotated every frame

    local function addImage(id, size, z, yOff)
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromOffset(size, size)
        img.Position = UDim2.new(0.5, 0, 0.5, yOff or 0)
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.BackgroundTransparency = 1
        img.Image = id
        img.ScaleType = Enum.ScaleType.Fit
        img.ImageTransparency = 1
        img.ZIndex = z
        img.Parent = stage
        fadeOuts[img] = { ImageTransparency = 1 }
        return img
    end

    task.spawn(function()
        local haloId = Util.remoteImage(ASSETS.halo.url, ASSETS.halo.file)
        if haloId and alive then
            local halo = addImage(haloId, px(760), 1)
            Util.tween(halo, { ImageTransparency = 0 }, 1.2, Enum.EasingStyle.Sine)
        end
    end)

    task.spawn(function()
        local ringId = Util.remoteImage(ASSETS.ring.url, ASSETS.ring.file)
        if ringId and alive then
            ringLabel = addImage(ringId, px(640), 2)
            local sc = Instance.new("UIScale")
            sc.Scale = 0.92
            sc.Parent = ringLabel
            Util.tween(ringLabel, { ImageTransparency = 0 }, 0.9, Enum.EasingStyle.Sine)
            Util.tween(sc, { Scale = 1 }, 1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end
    end)

    task.spawn(function()
        local charId = Util.remoteImage(ASSETS.char.url, ASSETS.char.file)
        if not (charId and alive) then return end
        local ch = px(520)
        local cw = math.floor(ch * CHAR_ASPECT + 0.5)

        -- chromatic-aberration entrance: blue/red ghosts jitter, then converge
        local ghosts = {}
        for _, g in ipairs({
            { color = Color3.fromRGB(66, 133, 244), dir = -1 },
            { color = Color3.fromRGB(234, 67, 53),  dir = 1 },
        }) do
            local gh = Instance.new("ImageLabel")
            gh.Size = UDim2.fromOffset(cw, ch)
            gh.Position = UDim2.new(0.5, g.dir * px(8), 0.5, -px(10))
            gh.AnchorPoint = Vector2.new(0.5, 0.5)
            gh.BackgroundTransparency = 1
            gh.Image = charId
            gh.ScaleType = Enum.ScaleType.Fit
            gh.ImageColor3 = g.color
            gh.ImageTransparency = 0.62
            gh.ZIndex = 3
            gh.Parent = stage
            ghosts[#ghosts + 1] = { inst = gh, dir = g.dir }
        end

        local char = Instance.new("ImageLabel")
        char.Size = UDim2.fromOffset(cw, ch)
        char.Position = UDim2.new(0.5, 0, 0.5, -px(10))
        char.AnchorPoint = Vector2.new(0.5, 0.5)
        char.BackgroundTransparency = 1
        char.Image = charId
        char.ScaleType = Enum.ScaleType.Fit
        char.ImageTransparency = 1
        char.ZIndex = 4
        char.Parent = stage
        fadeOuts[char] = { ImageTransparency = 1 }
        Util.tween(char, { ImageTransparency = 0 }, 0.55, Enum.EasingStyle.Sine)

        -- jitter ~0.5s, then snap together and vanish
        for _ = 1, 9 do
            if not alive then break end
            for _, g in ipairs(ghosts) do
                g.inst.Position = UDim2.new(
                    0.5, g.dir * math.random(px(3), px(10)),
                    0.5, -px(10) + math.random(-px(3), px(3)))
            end
            task.wait(0.055)
        end
        for _, g in ipairs(ghosts) do
            Util.tween(g.inst, {
                Position = UDim2.new(0.5, 0, 0.5, -px(10)),
                ImageTransparency = 1,
            }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.delay(0.3, function() g.inst:Destroy() end)
        end
    end)

    -- ring rotation + stage float bob
    task.spawn(function()
        local t = 0
        while alive do
            local dt = RunService.RenderStepped:Wait()
            t += dt
            if ringLabel then ringLabel.Rotation = (t * 14) % 360 end
            stage.Position = UDim2.new(0.66, 0, 0.5, math.sin(t * 2.1) * px(8))
        end
    end)

    -- -----------------------------------------------------------------------
    -- Left block: kicker (typed on), gradient SYNC, tagline, progress row.
    -- -----------------------------------------------------------------------
    local block = Instance.new("Frame")
    block.Size = UDim2.fromOffset(px(700), px(300))
    block.Position = UDim2.new(0.10, 0, 0.5, 0)
    block.AnchorPoint = Vector2.new(0, 0.5)
    block.BackgroundTransparency = 1
    block.Parent = screen

    local function textLabel(y, h, size, font, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, px(h))
        l.Position = UDim2.fromOffset(0, px(y))
        l.BackgroundTransparency = 1
        l.Font = font
        l.TextSize = px(size)
        l.TextColor3 = color
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTransparency = 1
        l.Parent = block
        fadeOuts[l] = { TextTransparency = 1 }
        return l
    end

    local kicker = textLabel(0, 24, 20, Theme.fonts.caption, WHITE)
    kicker.Text = ""

    local title = textLabel(26, 160, 150, Theme.fonts.title, Color3.fromRGB(255, 255, 255))
    title.Text = "SYNC"
    local titleGrad = Instance.new("UIGradient")
    titleGrad.Color = GOOGLE
    titleGrad.Parent = title

    local tagline = textLabel(196, 26, 24, Theme.fonts.body, Theme.c.textSecondary)
    tagline.Text = "your desktop, reimagined"

    -- staggered entrances
    task.delay(0.25, function()
        if not alive then return end
        -- type the kicker on, letter by letter
        Util.tween(kicker, { TextTransparency = 0 }, 0.2)
        local spaced = "W E L C O M E   T O"
        for i = 1, #spaced do
            if not alive then return end
            kicker.Text = string.sub(spaced, 1, i)
            task.wait(0.022)
        end
    end)
    task.delay(0.45, function()
        if not alive then return end
        Util.tween(title, { TextTransparency = 0 }, 0.7, Enum.EasingStyle.Sine)
        -- shine sweep on the wordmark
        task.spawn(function()
            while alive and title.Parent do
                Util.tween(titleGrad, { Offset = Vector2.new(0.25, 0) }, 1.6,
                    Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(1.65)
                if not (alive and title.Parent) then break end
                Util.tween(titleGrad, { Offset = Vector2.new(-0.25, 0) }, 1.6,
                    Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(1.65)
            end
        end)
    end)
    task.delay(0.65, function()
        if alive then Util.tween(tagline, { TextTransparency = 0 }, 0.6, Enum.EasingStyle.Sine) end
    end)

    -- progress row: reveal-style fill so the gradient is unveiled, not squished
    local trackW, trackH = px(420), math.max(px(5), 3)
    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(trackW, trackH)
    track.Position = UDim2.fromOffset(0, px(256))
    track.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Parent = block
    Util.corner(track, trackH)
    Util.tween(track, { BackgroundTransparency = 0.35 }, 0.5)
    fadeOuts[track] = { BackgroundTransparency = 1 }

    local reveal = Instance.new("Frame")
    reveal.Size = UDim2.new(0, 0, 1, 0)
    reveal.BackgroundTransparency = 1
    reveal.BorderSizePixel = 0
    reveal.ClipsDescendants = true
    reveal.Parent = track
    Util.corner(reveal, trackH)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.fromOffset(trackW, trackH) -- full track width, gets revealed
    bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bar.BorderSizePixel = 0
    bar.Parent = reveal
    Util.corner(bar, trackH)
    local barGrad = Instance.new("UIGradient")
    barGrad.Color = GOOGLE
    barGrad.Parent = bar

    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.fromOffset(px(70), px(20))
    pct.Position = UDim2.fromOffset(trackW + px(16), px(256) - px(8))
    pct.BackgroundTransparency = 1
    pct.Font = Enum.Font.Code
    pct.TextSize = px(15)
    pct.TextColor3 = Color3.fromRGB(200, 200, 205)
    pct.TextXAlignment = Enum.TextXAlignment.Left
    pct.Text = "0%"
    pct.TextTransparency = 1
    pct.Parent = block
    Util.tween(pct, { TextTransparency = 0 }, 0.5)
    fadeOuts[pct] = { TextTransparency = 1 }

    local bootlog = Instance.new("TextLabel")
    bootlog.Size = UDim2.new(1, 0, 0, px(18))
    bootlog.Position = UDim2.fromOffset(0, px(276))
    bootlog.BackgroundTransparency = 1
    bootlog.Font = Enum.Font.Code
    bootlog.TextSize = px(14)
    bootlog.TextColor3 = Color3.fromRGB(112, 112, 118)
    bootlog.TextXAlignment = Enum.TextXAlignment.Left
    bootlog.Text = ""
    bootlog.TextTransparency = 1
    bootlog.Parent = block
    Util.tween(bootlog, { TextTransparency = 0 }, 0.5)
    fadeOuts[bootlog] = { TextTransparency = 1 }

    -- live percent readout from the reveal width
    task.spawn(function()
        while alive and track.Parent do
            RunService.RenderStepped:Wait()
            local p = reveal.AbsoluteSize.X / math.max(track.AbsoluteSize.X, 1)
            pct.Text = string.format("%d%%", math.floor(p * 100 + 0.5))
        end
    end)

    -- -----------------------------------------------------------------------
    -- Sparkles (baked star PNG; created once the asset arrives)
    -- -----------------------------------------------------------------------
    task.spawn(function()
        local starId = Util.remoteImage(ASSETS.star.url, ASSETS.star.file)
        if not (starId and alive) then return end
        local spots = {
            { 0.545, 0.27, 34 }, { 0.80, 0.22, 24 }, { 0.585, 0.72, 26 },
            { 0.79, 0.76, 40 }, { 0.51, 0.50, 18 }, { 0.735, 0.135, 20 },
        }
        for i, sp in ipairs(spots) do
            local star = Instance.new("ImageLabel")
            star.Size = UDim2.fromOffset(px(sp[3]), px(sp[3]))
            star.Position = UDim2.fromScale(sp[1], sp[2])
            star.AnchorPoint = Vector2.new(0.5, 0.5)
            star.BackgroundTransparency = 1
            star.Image = starId
            star.ImageTransparency = 1
            star.Parent = screen
            fadeOuts[star] = { ImageTransparency = 1 }
            task.delay(0.3 + i * 0.14, function()
                while alive and star.Parent do
                    Util.tween(star, { ImageTransparency = 0.1, Rotation = 12 }, 0.7, Enum.EasingStyle.Sine)
                    task.wait(0.75)
                    if not (alive and star.Parent) then break end
                    Util.tween(star, { ImageTransparency = 0.85, Rotation = -12 }, 0.95, Enum.EasingStyle.Sine)
                    task.wait(1.0)
                end
            end)
        end
    end)

    -- -----------------------------------------------------------------------
    -- Boot cadence -> exit
    -- -----------------------------------------------------------------------
    task.spawn(function()
        local steps = {
            { p = 0.24, t = 0.60, hold = 0.22, log = "> mounting dock…" },
            { p = 0.47, t = 0.70, hold = 0.30, log = "> loading apps…" },
            { p = 0.68, t = 0.60, hold = 0.34, log = "> syncing cursor…" },
            { p = 0.88, t = 0.65, hold = 0.22, log = "> warming up liquid glass…" },
            { p = 1.00, t = 0.50, hold = 0.00, log = "> ready." },
        }
        for _, s in ipairs(steps) do
            bootlog.Text = s.log
            Util.tween(reveal, { Size = UDim2.new(0, math.floor(trackW * s.p + 0.5), 1, 0) }, s.t,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(s.t + s.hold)
        end
        task.wait(0.45)

        -- cinematic release: slight zoom on the stage while everything fades
        Util.tween(stageScale, { Scale = 1.06 }, 0.7, Enum.EasingStyle.Sine)
        for inst, props in pairs(fadeOuts) do
            if inst and inst.Parent then Util.tween(inst, props, 0.5) end
        end
        Util.tween(screen, { BackgroundTransparency = 1 }, 0.65)
        task.wait(0.75)
        alive = false
        gui:Destroy()
        if onDone then onDone() end
    end)

    return gui
end

return Boot
