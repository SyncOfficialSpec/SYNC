-- SYNC / os / Boot
-- Branded loading screen v3 ("system boot"): minimal black layout — tri-blade
-- SYNC mark + spaced wordmark + rainbow hairline on the left, a center divider
-- that grows out of a glowing node, and a segmented tick-bar progress with a
-- live percent + status labels on the right. Corner brackets, monospace status
-- row bottom-left, STAND BY dot-chase bottom-right.
-- Fancy visuals stay baked PNGs (logo mark, halo glow) — reliable everywhere.
-- Open/close are fully choreographed; exit ends in a crossfade handoff (the
-- next screen builds under the black veil while it lifts).
-- Boot.run(onDone) plays, fades out, calls onDone().

local RunService = game:GetService("RunService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Boot = {}

local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"
-- getcustomasset caches by file path on many executors: new art = new filename.
local ASSETS = {
    logo = { url = RAW .. "boot-logo.png", file = "sync_boot3_logo.png" },
    halo = { url = RAW .. "boot-halo.png", file = "sync_boot2_halo.png" },
}

local GOOGLE = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(66, 133, 244)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(234, 67, 53)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(251, 188, 5)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(52, 168, 83)),
})

local WHITE  = Color3.fromRGB(245, 245, 247)
local ACCENT = Color3.fromRGB(120, 140, 255) -- soft blue-violet (bullet, ">", dots)

-- "S Y N C"-style letter spacing; original spaces become wide word gaps
local function spaced(s)
    return (s:gsub("(.)", "%1 "):gsub(" $", ""))
end

function Boot.run(onDone)
    local vp = Util.viewport()
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
    Util.tween(screen, { BackgroundTransparency = 0 }, 0.55, Enum.EasingStyle.Sine)

    -- faint version stamp, bottom-center
    local verStamp = Instance.new("TextLabel")
    verStamp.AnchorPoint = Vector2.new(0.5, 1)
    verStamp.Position = UDim2.new(0.5, 0, 1, -px(22))
    verStamp.Size = UDim2.fromOffset(px(200), px(16))
    verStamp.BackgroundTransparency = 1
    verStamp.Font = Theme.fonts.caption
    verStamp.Text = spaced("SYNC  v1.0")
    verStamp.TextSize = px(12)
    verStamp.TextColor3 = Color3.fromRGB(90, 90, 98)
    verStamp.TextTransparency = 1
    verStamp.ZIndex = 3
    verStamp.Parent = screen
    task.delay(0.8, function()
        if screen.Parent then Util.tween(verStamp, { TextTransparency = 0 }, 0.6, Enum.EasingStyle.Sine) end
    end)

    local alive   = true
    local closing = false
    local QUINT, QUAD, SINE = Enum.EasingStyle.Quint, Enum.EasingStyle.Quad, Enum.EasingStyle.Sine
    local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In

    -- -----------------------------------------------------------------------
    -- Corner brackets: slide out of the corners on open, retract on close.
    -- -----------------------------------------------------------------------
    local bracketBars = {}
    for ci, c in ipairs({ {0,0}, {1,0}, {0,1}, {1,1} }) do
        local ax, ay = c[1], c[2]
        local inset, blen = px(30), px(26)
        local ox = ax == 0 and inset or -inset
        local oy = ay == 0 and inset or -inset
        local rx = ax == 0 and inset - px(14) or -(inset - px(14))
        local ry = ay == 0 and inset - px(14) or -(inset - px(14))
        for _, bar in ipairs({ { blen, 2 }, { 2, blen } }) do
            local f = Instance.new("Frame")
            f.Size = UDim2.fromOffset(bar[1], bar[2])
            f.AnchorPoint = Vector2.new(ax, ay)
            f.Position = UDim2.new(ax, rx, ay, ry)
            f.BackgroundColor3 = WHITE
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.Parent = screen
            bracketBars[#bracketBars + 1] = {
                inst = f,
                finalPos = UDim2.new(ax, ox, ay, oy),
                retractPos = UDim2.new(ax, rx, ay, ry),
            }
            task.delay(0.12 + ci * 0.05, function()
                if alive and not closing then
                    Util.tween(f, { Position = UDim2.new(ax, ox, ay, oy), BackgroundTransparency = 0.5 },
                        0.6, QUINT, OUT)
                end
            end)
        end
    end

    -- -----------------------------------------------------------------------
    -- Left block: logo mark, spaced wordmark, rainbow hairline, tagline.
    -- Each rises ~14px while fading in, staggered.
    -- -----------------------------------------------------------------------
    local left = Instance.new("Frame")
    left.Size = UDim2.fromOffset(px(560), px(230))
    left.Position = UDim2.new(0.10, 0, 0.483, 0)
    left.AnchorPoint = Vector2.new(0, 0.5)
    left.BackgroundTransparency = 1
    left.Parent = screen

    local logo -- ImageLabel, created when the asset arrives
    task.spawn(function()
        local id = Util.remoteImage(ASSETS.logo.url, ASSETS.logo.file)
        if not (id and alive) or closing then return end
        logo = Instance.new("ImageLabel")
        logo.Size = UDim2.fromOffset(px(74), px(74))
        logo.Position = UDim2.fromOffset(0, px(14))
        logo.BackgroundTransparency = 1
        logo.Image = id
        logo.ScaleType = Enum.ScaleType.Fit
        logo.ImageTransparency = 1
        logo.Rotation = -25
        logo.Parent = left
        Util.tween(logo, { ImageTransparency = 0, Rotation = 0, Position = UDim2.fromOffset(0, 0) },
            0.9, QUINT, OUT)
        -- subtle idle breathing
        local sc = Instance.new("UIScale")
        sc.Parent = logo
        task.spawn(function()
            while alive and not closing and logo.Parent do
                Util.tween(sc, { Scale = 1.04 }, 1.9, SINE, Enum.EasingDirection.InOut)
                task.wait(1.95)
                if not alive or closing then break end
                Util.tween(sc, { Scale = 1.0 }, 1.9, SINE, Enum.EasingDirection.InOut)
                task.wait(1.95)
            end
        end)
    end)

    local function riser(parent, finalY, delay, build)
        local inst = build()
        inst.Position = UDim2.fromOffset(0, finalY + px(14))
        inst.Parent = parent
        task.delay(delay, function()
            if alive and not closing then
                local props = { Position = UDim2.fromOffset(0, finalY) }
                if inst:IsA("TextLabel") then props.TextTransparency = 0
                else props.BackgroundTransparency = 0 end
                Util.tween(inst, props, 0.65, QUINT, OUT)
            end
        end)
        return inst
    end

    local wordmark = riser(left, px(91), 0.38, function()
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, px(52))
        l.BackgroundTransparency = 1
        l.Font = Theme.fonts.title
        l.Text = spaced("SYNC")
        l.TextSize = px(46)
        l.TextColor3 = Color3.fromRGB(240, 240, 244)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTransparency = 1
        return l
    end)

    -- rainbow hairline: sweeps its width open after the wordmark lands
    local underline = Instance.new("Frame")
    underline.Size = UDim2.fromOffset(0, math.max(px(2), 2))
    underline.Position = UDim2.fromOffset(0, px(176))
    underline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    underline.BorderSizePixel = 0
    underline.Parent = left
    local ug = Instance.new("UIGradient")
    ug.Color = GOOGLE
    ug.Parent = underline
    task.delay(0.62, function()
        if alive and not closing then
            Util.tween(underline, { Size = UDim2.fromOffset(px(96), math.max(px(2), 2)) }, 0.6, QUINT, OUT)
        end
    end)

    local tagline = riser(left, px(200), 0.7, function()
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, px(22))
        l.BackgroundTransparency = 1
        l.Font = Theme.fonts.caption
        l.Text = spaced("your desktop, reimagined")
        l.TextSize = px(17)
        l.TextColor3 = Color3.fromRGB(140, 140, 146)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTransparency = 1
        return l
    end)

    -- -----------------------------------------------------------------------
    -- Center divider: grows out of the glowing node, faded at both ends.
    -- -----------------------------------------------------------------------
    local NODE_Y = 0.497
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, math.max(px(2), 1), 0, 0)
    line.Position = UDim2.fromScale(0.5, NODE_Y)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = Color3.fromRGB(200, 200, 208)
    line.BackgroundTransparency = 0.55
    line.BorderSizePixel = 0
    line.Parent = screen
    local lg = Instance.new("UIGradient")
    lg.Rotation = 90
    lg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 1),
        NumberSequenceKeypoint.new(0.14, 0.25),
        NumberSequenceKeypoint.new(0.86, 0.25),
        NumberSequenceKeypoint.new(1.00, 1),
    })
    lg.Parent = line
    task.delay(0.3, function()
        if alive and not closing then
            Util.tween(line, { Size = UDim2.new(0, math.max(px(2), 1), 0.67, 0) }, 1.0, QUINT, OUT)
        end
    end)

    local nodeGlow, nodeDot
    task.spawn(function()
        local haloId = Util.remoteImage(ASSETS.halo.url, ASSETS.halo.file)
        if not alive or closing then return end
        if haloId then
            nodeGlow = Instance.new("ImageLabel")
            nodeGlow.Size = UDim2.fromOffset(px(52), px(52))
            nodeGlow.Position = UDim2.fromScale(0.5, NODE_Y)
            nodeGlow.AnchorPoint = Vector2.new(0.5, 0.5)
            nodeGlow.BackgroundTransparency = 1
            nodeGlow.Image = haloId
            nodeGlow.ImageTransparency = 1
            nodeGlow.Parent = screen
            Util.tween(nodeGlow, { ImageTransparency = 0.25 }, 0.8, SINE)
        end
        nodeDot = Instance.new("Frame")
        nodeDot.Size = UDim2.fromOffset(px(8), px(8))
        nodeDot.Position = UDim2.fromScale(0.5, NODE_Y)
        nodeDot.AnchorPoint = Vector2.new(0.5, 0.5)
        nodeDot.BackgroundColor3 = Color3.fromRGB(250, 250, 255)
        nodeDot.BackgroundTransparency = 1
        nodeDot.BorderSizePixel = 0
        nodeDot.Parent = screen
        Util.corner(nodeDot, px(8))
        Util.tween(nodeDot, { BackgroundTransparency = 0 }, 0.6, SINE)
        -- gentle glow pulse
        while alive and not closing and nodeGlow and nodeGlow.Parent do
            Util.tween(nodeGlow, { ImageTransparency = 0.55 }, 1.6, SINE, Enum.EasingDirection.InOut)
            task.wait(1.65)
            if not alive or closing then break end
            Util.tween(nodeGlow, { ImageTransparency = 0.25 }, 1.6, SINE, Enum.EasingDirection.InOut)
            task.wait(1.65)
        end
    end)

    -- -----------------------------------------------------------------------
    -- Right block: status label + segmented tick bar + percent.
    -- -----------------------------------------------------------------------
    local right = Instance.new("Frame")
    right.Size = UDim2.fromOffset(px(640), px(96))
    right.Position = UDim2.new(0.5625, 0, NODE_Y, 0)
    right.AnchorPoint = Vector2.new(0, 0.5)
    right.BackgroundTransparency = 1
    right.Parent = screen

    local bullet = Instance.new("Frame")
    bullet.Size = UDim2.fromOffset(px(7), px(7))
    bullet.Position = UDim2.fromOffset(0, px(21))
    bullet.BackgroundColor3 = ACCENT
    bullet.BackgroundTransparency = 1
    bullet.BorderSizePixel = 0
    bullet.Parent = right
    Util.corner(bullet, px(7))

    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(px(500), px(20))
    status.Position = UDim2.fromOffset(px(18), px(14))
    status.BackgroundTransparency = 1
    status.Font = Theme.fonts.caption
    status.Text = spaced("LOADING SYSTEM FILES")
    status.TextSize = px(15)
    status.TextColor3 = Color3.fromRGB(225, 225, 232)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTransparency = 1
    status.Parent = right
    task.delay(0.55, function()
        if alive and not closing then
            Util.tween(bullet, { BackgroundTransparency = 0 }, 0.5, SINE)
            Util.tween(status, { TextTransparency = 0 }, 0.5, SINE)
        end
    end)

    -- tick bar: 46 segments, cascade in left-to-right
    local N, TW, TH, GAP = 46, math.max(px(4), 2), px(15), px(6)
    local PITCH = TW + GAP
    local BARY = px(48)
    local ticks, tickColors = {}, {}
    local UNLIT = Color3.fromRGB(52, 52, 58)
    for i = 1, N do
        local v = 0.72 + 0.28 * math.abs(math.sin(i * 1.7))
        tickColors[i] = Color3.fromRGB(
            math.floor(170 + 60 * v), math.floor(180 + 55 * v), math.floor(240 + 15 * v))
        local t = Instance.new("Frame")
        t.Size = UDim2.fromOffset(TW, TH)
        t.Position = UDim2.fromOffset((i - 1) * PITCH, BARY)
        t.BackgroundColor3 = UNLIT
        t.BackgroundTransparency = 1
        t.BorderSizePixel = 0
        t.Parent = right
        ticks[i] = t
        task.delay(0.62 + i * 0.014, function()
            if alive and not closing then Util.tween(t, { BackgroundTransparency = 0 }, 0.3, SINE) end
        end)
    end

    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.fromOffset(px(90), px(20))
    pct.Position = UDim2.fromOffset(N * PITCH + px(18), BARY - px(2))
    pct.BackgroundTransparency = 1
    pct.Font = Enum.Font.Code
    pct.Text = spaced("0%")
    pct.TextSize = px(15)
    pct.TextColor3 = Color3.fromRGB(210, 210, 216)
    pct.TextXAlignment = Enum.TextXAlignment.Left
    pct.TextTransparency = 1
    pct.Parent = right
    task.delay(1.0, function()
        if alive and not closing then Util.tween(pct, { TextTransparency = 0 }, 0.5, SINE) end
    end)

    -- -----------------------------------------------------------------------
    -- Bottom rows: "> status" left, "STAND BY · · ·" right.
    -- -----------------------------------------------------------------------
    local chevron = Instance.new("TextLabel")
    chevron.Size = UDim2.fromOffset(px(16), px(18))
    chevron.Position = UDim2.new(0, px(56), 1, -px(66))
    chevron.BackgroundTransparency = 1
    chevron.Font = Enum.Font.Code
    chevron.Text = ">"
    chevron.TextSize = px(15)
    chevron.TextColor3 = ACCENT
    chevron.TextXAlignment = Enum.TextXAlignment.Left
    chevron.TextTransparency = 1
    chevron.Parent = screen

    local bootlog = Instance.new("TextLabel")
    bootlog.Size = UDim2.fromOffset(px(520), px(18))
    bootlog.Position = UDim2.new(0, px(76), 1, -px(66))
    bootlog.BackgroundTransparency = 1
    bootlog.Font = Enum.Font.Code
    bootlog.Text = spaced("initializing")
    bootlog.TextSize = px(14)
    bootlog.TextColor3 = Color3.fromRGB(130, 130, 138)
    bootlog.TextXAlignment = Enum.TextXAlignment.Left
    bootlog.TextTransparency = 1
    bootlog.Parent = screen

    local standby = Instance.new("TextLabel")
    standby.Size = UDim2.fromOffset(px(160), px(18))
    standby.Position = UDim2.new(1, -px(150), 1, -px(66))
    standby.AnchorPoint = Vector2.new(1, 0)
    standby.BackgroundTransparency = 1
    standby.Font = Theme.fonts.caption
    standby.Text = spaced("STAND BY")
    standby.TextSize = px(14)
    standby.TextColor3 = Color3.fromRGB(170, 170, 178)
    standby.TextXAlignment = Enum.TextXAlignment.Right
    standby.TextTransparency = 1
    standby.Parent = screen

    local sbDots = {}
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(px(7), px(7))
        dot.Position = UDim2.new(1, -px(134) + i * px(22), 1, -px(61))
        dot.BackgroundColor3 = ACCENT
        dot.BackgroundTransparency = 1
        dot.BorderSizePixel = 0
        dot.Parent = screen
        Util.corner(dot, px(7))
        sbDots[i] = dot
    end
    task.delay(0.9, function()
        if not alive or closing then return end
        Util.tween(chevron, { TextTransparency = 0 }, 0.5, SINE)
        Util.tween(bootlog, { TextTransparency = 0 }, 0.5, SINE)
        Util.tween(standby, { TextTransparency = 0 }, 0.5, SINE)
        -- dot chase
        task.spawn(function()
            local i = 0
            while alive and not closing do
                i = i % 3 + 1
                for j, dot in ipairs(sbDots) do
                    if dot.Parent then
                        Util.tween(dot, { BackgroundTransparency = j == i and 0.1 or 0.72 }, 0.35, SINE)
                    end
                end
                task.wait(0.45)
            end
        end)
    end)

    -- -----------------------------------------------------------------------
    -- Progress engine: exponential smoothing toward per-step targets, ticks
    -- light up as it moves, head tick burns white, percent counts live.
    -- -----------------------------------------------------------------------
    local target, current = 0, 0
    task.spawn(function()
        local lastLit, lastPct = -1, -1
        while alive and right.Parent do
            local dt = RunService.RenderStepped:Wait()
            current = current + (target - current) * (1 - math.exp(-dt * 3.0))
            if target >= 1 and current > 0.996 then current = 1 end
            local lit = math.floor(current * N + 0.5)
            if lit ~= lastLit then
                for i = 1, N do
                    ticks[i].BackgroundColor3 = i <= lit and tickColors[i] or UNLIT
                end
                lastLit = lit
            end
            if lit > 0 and lit <= N then
                ticks[lit].BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- burning head
            end
            local p = math.floor(current * 100 + 0.5)
            if p ~= lastPct then
                pct.Text = spaced(p .. "%")
                lastPct = p
            end
        end
    end)

    -- -----------------------------------------------------------------------
    -- Boot cadence -> choreographed exit -> crossfade handoff.
    -- -----------------------------------------------------------------------
    task.spawn(function()
        task.wait(1.15) -- let the stage assemble first
        local steps = {
            { p = 0.22, wait = 1.00, status = "LOADING SYSTEM FILES", log = "initializing" },
            { p = 0.45, wait = 1.05, status = "MOUNTING DOCK",        log = "mounting dock" },
            { p = 0.68, wait = 1.00, status = "SYNCING APPS",         log = "syncing apps" },
            { p = 0.88, wait = 0.95, status = "CALIBRATING CURSOR",   log = "calibrating cursor" },
            { p = 1.00, wait = 1.05, status = "READY",                log = "ready." },
        }
        for _, s in ipairs(steps) do
            status.Text = spaced(s.status)
            bootlog.Text = spaced(s.log)
            target = s.p
            task.wait(s.wait)
        end
        task.wait(0.3)

        -- ---- exit choreography ----
        closing = true

        -- 1. ticks cascade out right-to-left, label/pct slide right
        for i = N, 1, -1 do
            task.delay((N - i) * 0.008, function()
                if ticks[i].Parent then Util.tween(ticks[i], { BackgroundTransparency = 1 }, 0.25, SINE) end
            end)
        end
        Util.tween(status, { Position = UDim2.fromOffset(px(34), px(14)), TextTransparency = 1 }, 0.4, QUAD, IN)
        Util.tween(bullet, { BackgroundTransparency = 1 }, 0.3, SINE)
        Util.tween(pct, { TextTransparency = 1 }, 0.35, QUAD, IN)
        task.wait(0.12)

        -- 2. left block slides out left, bottom-up
        Util.tween(tagline, { Position = tagline.Position - UDim2.fromOffset(px(18), 0), TextTransparency = 1 },
            0.35, QUAD, IN)
        task.wait(0.06)
        Util.tween(underline, { Size = UDim2.fromOffset(0, math.max(px(2), 2)) }, 0.4, QUINT, OUT)
        task.wait(0.06)
        Util.tween(wordmark, { Position = wordmark.Position - UDim2.fromOffset(px(22), 0), TextTransparency = 1 },
            0.4, QUAD, IN)
        task.wait(0.06)
        if logo then
            Util.tween(logo, { Position = logo.Position - UDim2.fromOffset(px(18), 0), ImageTransparency = 1, Rotation = 12 },
                0.45, QUAD, IN)
        end

        -- 3. bottom rows fade
        for _, l in ipairs({ chevron, bootlog, standby }) do
            Util.tween(l, { TextTransparency = 1 }, 0.35, QUAD, IN)
        end
        for _, dot in ipairs(sbDots) do
            Util.tween(dot, { BackgroundTransparency = 1 }, 0.3, SINE)
        end

        -- 4. the line collapses back into the node, the node flares then dies
        Util.tween(line, { Size = UDim2.new(0, math.max(px(2), 1), 0, 0) }, 0.6, QUINT, IN)
        if nodeGlow then Util.tween(nodeGlow, { ImageTransparency = 0.05 }, 0.3, SINE) end
        task.delay(0.35, function()
            if nodeGlow then Util.tween(nodeGlow, { ImageTransparency = 1 }, 0.45, SINE) end
            if nodeDot then Util.tween(nodeDot, { BackgroundTransparency = 1 }, 0.4, SINE) end
        end)

        -- 5. brackets retract
        for _, b in ipairs(bracketBars) do
            Util.tween(b.inst, { Position = b.retractPos, BackgroundTransparency = 1 }, 0.4, QUAD, IN)
        end

        -- 6. crossfade handoff: raise the veil, start the next screen under it
        task.wait(0.45)
        gui.DisplayOrder = 1000000
        if onDone then task.spawn(onDone) end
        Util.tween(screen, { BackgroundTransparency = 1 }, 0.85, SINE, Enum.EasingDirection.InOut)
        task.wait(0.95)
        alive = false
        gui:Destroy()
    end)

    return gui
end

return Boot
