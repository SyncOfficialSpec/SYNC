-- SYNC / os / Login
-- A "RETINA"-style login gate shown right after the boot splash: a wide dark
-- card, a big violet panel on the left with the SYNC mark, and a form on the
-- right (username, password, Continue, an OR divider, and a subscription
-- button). The entrance matches the reference: the dark card fades in first,
-- then the violet panel fades in a beat later.
--
-- Credentials are hard-coded for now: Diablo / Diablo.
-- Login.run(onDone) plays, and calls onDone() once the user is through.

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Login = {}

local HS  = game:GetService("HttpService")
local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"

local VIOLET   = Color3.fromRGB(171, 148, 251)
local CARD     = Color3.fromRGB(15, 15, 17)
local INPUT_BG = Color3.fromRGB(23, 23, 27)
local STROKE   = Color3.fromRGB(70, 70, 80)
local WHITE    = Color3.fromRGB(244, 244, 247)
local GRAY     = Color3.fromRGB(150, 150, 156)
local DARKTX   = Color3.fromRGB(26, 22, 40) -- text on the violet button

local USER = "Diablo"
local PASS = "Diablo"

local QUART = Enum.EasingStyle.Quart
local BACK  = Enum.EasingStyle.Back
local SINE  = Enum.EasingStyle.Sine
local OUT   = Enum.EasingDirection.Out

-- Load the SYNC mark (white logo, transparent background) through weserv so
-- getcustomasset can read it; weserv keeps the PNG alpha.
local function loadLogo(img)
    task.spawn(function()
        local png = "https://images.weserv.nl/?url="
            .. HS:UrlEncode(RAW .. "sync_mark.png") .. "&output=png&w=256&h=256"
        local id = Util.remoteImage(png, "sync_mark_w.png")
        if id and img and img.Parent then img.Image = id end
    end)
end

function Login.run(onDone)
    local vp = Util.viewport()
    local S = math.clamp(vp.Y / 1080, 0.5, 1.7)
    local function px(n) return math.floor(n * S + 0.5) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Login"
    Util.mount(gui)

    local done = false
    local function finish(bypass)
        if done then return end
        done = true
        if onDone then task.spawn(onDone) end
    end

    -- Dim scrim over the game
    local scrim = Instance.new("TextButton") -- TextButton so clicks don't fall through
    scrim.Text = ""
    scrim.AutoButtonColor = false
    scrim.Size = UDim2.fromScale(1, 1)
    scrim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scrim.BackgroundTransparency = 1
    scrim.BorderSizePixel = 0
    scrim.Parent = gui
    Util.tween(scrim, { BackgroundTransparency = 0.35 }, 0.45, SINE)

    -- ---- Card ------------------------------------------------------------
    local MW, MH = px(1080), px(604)
    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(MW, MH)
    card.BackgroundColor3 = CARD
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.Parent = gui
    Util.corner(card, px(24))
    Util.stroke(card, Color3.fromRGB(255, 255, 255), 1, 0.92)
    Util.shadow(card, { blur = 60, spread = 0, transparency = 0.45, offset = UDim2.fromOffset(0, px(26)) })
    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 0.96
    cardScale.Parent = card

    -- entrance: card fades + settles
    Util.tween(card, { BackgroundTransparency = 0.02 }, 0.32, QUART, OUT)
    Util.tween(cardScale, { Scale = 1 }, 0.42, BACK, OUT)

    local inset = px(20)

    -- ---- Violet panel (left) --------------------------------------------
    local violetW = px(560)
    local panel = Instance.new("Frame")
    panel.Position = UDim2.fromOffset(inset, inset)
    panel.Size = UDim2.fromOffset(violetW, MH - inset * 2)
    panel.BackgroundColor3 = VIOLET
    panel.BackgroundTransparency = 1
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = card
    Util.corner(panel, px(18))
    local panelScale = Instance.new("UIScale")
    panelScale.Scale = 0.92
    panelScale.Parent = panel

    local logo = Instance.new("ImageLabel")
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.fromScale(0.5, 0.5)
    logo.Size = UDim2.fromOffset(px(168), px(168))
    logo.BackgroundTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ImageTransparency = 1
    logo.Parent = panel
    loadLogo(logo)

    local handle = Instance.new("TextLabel")
    handle.Position = UDim2.fromOffset(px(22), MH - inset * 2 - px(38))
    handle.Size = UDim2.fromOffset(px(200), px(20))
    handle.BackgroundTransparency = 1
    handle.Font = Theme.fonts.caption
    handle.Text = "@SYNC"
    handle.TextSize = px(15)
    handle.TextColor3 = Color3.fromRGB(255, 255, 255)
    handle.TextTransparency = 1
    handle.TextXAlignment = Enum.TextXAlignment.Left
    handle.Parent = panel

    -- violet fades in a beat after the card
    task.delay(0.1, function()
        Util.tween(panel, { BackgroundTransparency = 0 }, 0.3, QUART, OUT)
        Util.tween(panelScale, { Scale = 1 }, 0.4, BACK, OUT)
        task.delay(0.08, function()
            Util.tween(logo, { ImageTransparency = 0 }, 0.4, SINE)
            Util.tween(handle, { TextTransparency = 0.1 }, 0.4, SINE)
        end)
    end)

    -- ---- Right form ------------------------------------------------------
    local rightX = inset + violetW + px(46)
    local rightW = MW - rightX - px(46)
    local function fadeIn(inst, prop, to, delay)
        task.delay(delay, function()
            if inst.Parent then Util.tween(inst, { [prop] = to }, 0.4, SINE) end
        end)
    end

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(rightX, px(68))
    title.Size = UDim2.fromOffset(rightW, px(46))
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack -- heavy wordmark, like the reference
    title.Text = "S Y N C"
    title.TextSize = px(40)
    title.TextColor3 = WHITE
    title.TextTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = card
    fadeIn(title, "TextTransparency", 0, 0.12)

    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.fromOffset(rightX, px(120))
    sub.Size = UDim2.fromOffset(rightW, px(22))
    sub.BackgroundTransparency = 1
    sub.Font = Theme.fonts.caption
    sub.Text = "Welcome again, please log in to continue."
    sub.TextSize = px(16)
    sub.TextColor3 = GRAY
    sub.TextTransparency = 1
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.Parent = card
    fadeIn(sub, "TextTransparency", 0, 0.16)

    -- input field builder (returns the TextBox + its stroke for focus/error).
    -- The placeholder is a custom label (not the built-in one) so it can animate:
    -- on focus it slides right and fades out, on blur (when empty) it slides back.
    local function field(y, placeholder, isPassword, delay)
        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(rightX, y)
        holder.Size = UDim2.fromOffset(rightW, px(50))
        holder.BackgroundColor3 = INPUT_BG
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.ClipsDescendants = true
        holder.Parent = card
        Util.corner(holder, px(14))
        local st = Util.stroke(holder, STROKE, 1, 1)

        local box = Instance.new("TextBox")
        box.Position = UDim2.fromOffset(px(20), 0)
        box.Size = UDim2.fromOffset(rightW - px(40), px(50))
        box.BackgroundTransparency = 1
        box.Font = Theme.fonts.body
        box.PlaceholderText = "" -- custom label below does the work
        box.Text = ""
        box.TextSize = px(16)
        box.TextColor3 = WHITE
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.TextTransparency = 1
        box.ZIndex = 2
        box.Parent = holder

        local phLeft = UDim2.fromOffset(px(20), 0)
        local phRight = UDim2.fromOffset(px(20) + math.floor((rightW - px(40)) * 0.55), 0)
        local ph = Instance.new("TextLabel")
        ph.BackgroundTransparency = 1
        ph.Position = phLeft
        ph.Size = UDim2.fromOffset(rightW - px(40), px(50))
        ph.Font = Theme.fonts.body
        ph.Text = placeholder
        ph.TextSize = px(16)
        ph.TextColor3 = Color3.fromRGB(105, 105, 112)
        ph.TextXAlignment = Enum.TextXAlignment.Left
        ph.TextTransparency = 1
        ph.ZIndex = 1
        ph.Parent = holder

        -- fade in
        task.delay(delay, function()
            if holder.Parent then
                Util.tween(holder, { BackgroundTransparency = 0 }, 0.4, SINE)
                Util.tween(st, { Transparency = 0.35 }, 0.4, SINE)
                Util.tween(box, { TextTransparency = 0 }, 0.4, SINE)
                Util.tween(ph, { TextTransparency = 0 }, 0.4, SINE)
            end
        end)

        box.Focused:Connect(function()
            Util.tween(st, { Transparency = 0, Color = VIOLET }, 0.18)
            Util.tween(ph, { Position = phRight, TextTransparency = 1 }, 0.24, QUART, OUT)
        end)
        box.FocusLost:Connect(function()
            Util.tween(st, { Transparency = 0.35, Color = STROKE }, 0.18)
            if box.Text == "" then -- empty (bullets string is "" when no chars either)
                Util.tween(ph, { Position = phLeft, TextTransparency = 0 }, 0.24, QUART, OUT)
            end
        end)

        return box, st
    end

    local userBox, userStroke = field(px(232), "Enter username", false, 0.2)
    local passBox, passStroke = field(px(300), "Enter password", true, 0.24)

    -- Continue button
    local cont = Instance.new("TextButton")
    cont.Position = UDim2.fromOffset(rightX, px(378))
    cont.Size = UDim2.fromOffset(rightW, px(52))
    cont.BackgroundColor3 = VIOLET
    cont.BackgroundTransparency = 1
    cont.AutoButtonColor = false
    cont.Font = Theme.fonts.title
    cont.Text = "Continue"
    cont.TextSize = px(16)
    cont.TextColor3 = DARKTX
    cont.TextTransparency = 1
    cont.BorderSizePixel = 0
    cont.Parent = card
    Util.corner(cont, px(26))
    task.delay(0.28, function()
        if cont.Parent then
            Util.tween(cont, { BackgroundTransparency = 0 }, 0.4, SINE)
            Util.tween(cont, { TextTransparency = 0 }, 0.4, SINE)
        end
    end)
    cont.MouseEnter:Connect(function() Util.tween(cont, { BackgroundColor3 = Color3.fromRGB(185, 165, 255) }, 0.15) end)
    cont.MouseLeave:Connect(function() Util.tween(cont, { BackgroundColor3 = VIOLET }, 0.15) end)

    -- OR divider
    local orWrap = Instance.new("Frame")
    orWrap.Position = UDim2.fromOffset(rightX, px(452))
    orWrap.Size = UDim2.fromOffset(rightW, px(16))
    orWrap.BackgroundTransparency = 1
    orWrap.Parent = card
    local function orLine(xoff, w)
        local l = Instance.new("Frame")
        l.Position = UDim2.fromOffset(xoff, px(8))
        l.Size = UDim2.fromOffset(w, 1)
        l.BackgroundColor3 = STROKE
        l.BackgroundTransparency = 0.5
        l.BorderSizePixel = 0
        l.Parent = orWrap
    end
    orLine(0, rightW / 2 - px(24))
    orLine(rightW / 2 + px(24), rightW / 2 - px(24))
    local orText = Instance.new("TextLabel")
    orText.AnchorPoint = Vector2.new(0.5, 0.5)
    orText.Position = UDim2.fromScale(0.5, 0.5)
    orText.Size = UDim2.fromOffset(px(40), px(16))
    orText.BackgroundTransparency = 1
    orText.Font = Theme.fonts.caption
    orText.Text = "OR"
    orText.TextSize = px(12)
    orText.TextColor3 = GRAY
    orText.Parent = orWrap
    fadeIn(orText, "TextTransparency", 0, 0.32)

    -- Purchasing button (dark, bordered)
    local sub2 = Instance.new("TextButton")
    sub2.Position = UDim2.fromOffset(rightX, px(486))
    sub2.Size = UDim2.fromOffset(rightW, px(50))
    sub2.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    sub2.BackgroundTransparency = 1
    sub2.AutoButtonColor = false
    sub2.Font = Theme.fonts.body
    sub2.Text = "Purchasing a subscription"
    sub2.TextSize = px(15)
    sub2.TextColor3 = WHITE
    sub2.TextTransparency = 1
    sub2.BorderSizePixel = 0
    sub2.Parent = card
    Util.corner(sub2, px(26))
    local sub2St = Util.stroke(sub2, STROKE, 1, 1)
    task.delay(0.34, function()
        if sub2.Parent then
            Util.tween(sub2, { BackgroundTransparency = 0 }, 0.4, SINE)
            Util.tween(sub2, { TextTransparency = 0 }, 0.4, SINE)
            Util.tween(sub2St, { Transparency = 0.5 }, 0.4, SINE)
        end
    end)
    sub2.MouseEnter:Connect(function() Util.tween(sub2, { BackgroundColor3 = Color3.fromRGB(34, 34, 40) }, 0.15) end)
    sub2.MouseLeave:Connect(function() Util.tween(sub2, { BackgroundColor3 = Color3.fromRGB(24, 24, 28) }, 0.15) end)

    -- error line under the form
    local err = Instance.new("TextLabel")
    err.Position = UDim2.fromOffset(rightX, px(432))
    err.Size = UDim2.fromOffset(rightW, px(18))
    err.BackgroundTransparency = 1
    err.Font = Theme.fonts.caption
    err.Text = ""
    err.TextSize = px(13)
    err.TextColor3 = Theme.red
    err.TextTransparency = 0
    err.TextXAlignment = Enum.TextXAlignment.Center
    err.ZIndex = 3
    err.Parent = card

    -- X close (bypasses the gate for now)
    local x = Instance.new("TextButton")
    x.AnchorPoint = Vector2.new(1, 0)
    x.Position = UDim2.fromOffset(MW - px(20), px(20))
    x.Size = UDim2.fromOffset(px(26), px(26))
    x.BackgroundTransparency = 1
    x.AutoButtonColor = false
    x.Font = Theme.fonts.body
    x.Text = "\195\151" -- multiplication sign (clean X)
    x.TextSize = px(22)
    x.TextColor3 = Color3.fromRGB(180, 180, 186)
    x.TextTransparency = 1
    x.Parent = card
    fadeIn(x, "TextTransparency", 0, 0.3)
    x.MouseEnter:Connect(function() x.TextColor3 = WHITE end)
    x.MouseLeave:Connect(function() x.TextColor3 = Color3.fromRGB(180, 180, 186) end)

    -- ---- behaviour -------------------------------------------------------
    local function exitThen(cb)
        Util.tween(panel, { BackgroundTransparency = 1 }, 0.2, QUART, Enum.EasingDirection.In)
        Util.tween(logo, { ImageTransparency = 1 }, 0.18)
        Util.tween(card, { BackgroundTransparency = 1 }, 0.26, QUART, Enum.EasingDirection.In)
        Util.tween(cardScale, { Scale = 0.96 }, 0.26, QUART, Enum.EasingDirection.In)
        Util.tween(scrim, { BackgroundTransparency = 1 }, 0.3, SINE)
        task.delay(0.32, function()
            gui:Destroy()
            if cb then cb() end
        end)
    end

    local function shake()
        local base = card.Position
        for i, dx in ipairs({ -12, 10, -8, 6, -3, 0 }) do
            task.delay((i - 1) * 0.05, function()
                if card.Parent then
                    Util.tween(card, { Position = base + UDim2.fromOffset(px(dx), 0) }, 0.05)
                end
            end)
        end
    end

    local function fail()
        err.Text = "Incorrect username or password"
        Util.tween(userStroke, { Transparency = 0, Color = Theme.red }, 0.15)
        Util.tween(passStroke, { Transparency = 0, Color = Theme.red }, 0.15)
        shake()
        task.delay(1.6, function()
            if err.Parent then err.Text = "" end
            Util.tween(userStroke, { Transparency = 0.35, Color = STROKE }, 0.2)
            Util.tween(passStroke, { Transparency = 0.35, Color = STROKE }, 0.2)
        end)
    end

    local function attempt()
        if userBox.Text == USER and passBox.Text == PASS then
            err.TextColor3 = Color3.fromRGB(120, 220, 150)
            err.Text = "Welcome back"
            exitThen(function() finish(false) end)
        else
            fail()
        end
    end

    cont.MouseButton1Click:Connect(attempt)
    passBox.FocusLost:Connect(function(enter) if enter then attempt() end end)
    userBox.FocusLost:Connect(function(enter) if enter then passBox:CaptureFocus() end end)
    x.MouseButton1Click:Connect(function() exitThen(function() finish(true) end) end)

    return gui
end

return Login
