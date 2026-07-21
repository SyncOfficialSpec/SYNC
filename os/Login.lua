-- SYNC / os / Login
-- A "sign in" gate shown right after the boot splash: a portrait window with a
-- blurred backdrop, a pink SYNC mark next to "SIGN IN", a username + password
-- field with pink icons, a "forgot" line and a big pink Sign IN button. Styled
-- after the reference the user provided (Laber.tech-style), rebranded to sync.gg.
--
-- Credentials are hard-coded for now: Diablo / Diablo.
-- Login.run(onDone) plays, and calls onDone() once the user is through.

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Login = {}

local HS  = game:GetService("HttpService")
local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"

local PINK    = Color3.fromRGB(234, 76, 137)
local PINK_HI = Color3.fromRGB(249, 150, 190)
local PINK_LO = Color3.fromRGB(196, 56, 112)
local WHITE   = Color3.fromRGB(245, 245, 248)
local GRAY    = Color3.fromRGB(150, 150, 158)
local FIELD   = Color3.fromRGB(24, 24, 28)
local BARBG   = Color3.fromRGB(16, 16, 20)

local USER = "Diablo"
local PASS = "Diablo"

local QUART = Enum.EasingStyle.Quart
local BACK  = Enum.EasingStyle.Back
local SINE  = Enum.EasingStyle.Sine
local OUT   = Enum.EasingDirection.Out

-- weserv turns a repo image into a png getcustomasset can read (keeps alpha).
local function remotePng(file, w, h, extra)
    local url = "https://images.weserv.nl/?url=" .. HS:UrlEncode(RAW .. file)
        .. "&output=png&w=" .. w .. "&h=" .. (h or w) .. (extra or "")
    return Util.remoteImage(url, "login_" .. file:gsub("%.", "_") .. "_" .. w .. ".png")
end

-- lucide icon (renders black) -> whiten via negate, then tint. Fills img async.
local function loadIcon(img, name, tint)
    task.spawn(function()
        local url = "https://images.weserv.nl/?url="
            .. HS:UrlEncode("cdn.jsdelivr.net/npm/lucide-static/icons/" .. name .. ".svg")
            .. "&output=png&w=64&h=64&filt=negate"
        local id = Util.remoteImage(url, "ic_login_" .. name .. ".png")
        if id and img and img.Parent then
            img.Image = id
            img.ImageColor3 = tint or WHITE
        end
    end)
end

function Login.run(onDone)
    local vp = Util.viewport()
    local S = math.clamp(vp.Y / 1080, 0.55, 1.5)
    local function px(n) return math.floor(n * S + 0.5) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Login"
    Util.mount(gui)

    local done = false
    local function finish()
        if done then return end
        done = true
        if onDone then task.spawn(onDone) end
    end

    -- dim the game behind the window
    local scrim = Instance.new("TextButton")
    scrim.Text = ""
    scrim.AutoButtonColor = false
    scrim.Size = UDim2.fromScale(1, 1)
    scrim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scrim.BackgroundTransparency = 1
    scrim.BorderSizePixel = 0
    scrim.Parent = gui
    Util.tween(scrim, { BackgroundTransparency = 0.35 }, 0.4, SINE)

    -- ---- portrait window --------------------------------------------------
    local W, H = px(462), px(602)
    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    Util.corner(win, px(16))
    Util.stroke(win, Color3.fromRGB(255, 255, 255), 1, 0.9)
    Util.shadow(win, { blur = 60, spread = 0, transparency = 0.4, offset = UDim2.fromOffset(0, px(24)) })

    local scaleFx = Instance.new("UIScale")
    scaleFx.Scale = 0.95
    scaleFx.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(win, { BackgroundTransparency = 0 }, 0.3)
    Util.tween(scaleFx, { Scale = 1 }, 0.4, BACK, OUT)

    -- blurred backdrop image + dark gradient overlay
    local bg = Instance.new("ImageLabel")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    bg.BorderSizePixel = 0
    bg.ScaleType = Enum.ScaleType.Crop
    bg.ImageTransparency = 1
    bg.ZIndex = 1
    bg.Parent = win
    task.spawn(function()
        local id = remotePng("login_bg.jpg", 512, 660)
        if id and bg.Parent then bg.Image = id; Util.tween(bg, { ImageTransparency = 0 }, 0.5, SINE) end
    end)
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 1
    overlay.Parent = win
    local og = Instance.new("UIGradient")
    og.Rotation = 90
    og.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.55, 0.35),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    og.Parent = overlay

    -- ---- title bar --------------------------------------------------------
    local TB = px(42)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = BARBG
    bar.BackgroundTransparency = 0.15
    bar.BorderSizePixel = 0
    bar.ZIndex = 4
    bar.Parent = win

    local barLogo = Instance.new("ImageLabel")
    barLogo.Size = UDim2.fromOffset(px(18), px(18))
    barLogo.Position = UDim2.fromOffset(px(14), (TB - px(18)) / 2)
    barLogo.BackgroundTransparency = 1
    barLogo.ScaleType = Enum.ScaleType.Fit
    barLogo.ImageColor3 = PINK
    barLogo.ZIndex = 5
    barLogo.Parent = bar
    task.spawn(function()
        local id = remotePng("sync_mark.png", 64, 64)
        if id and barLogo.Parent then barLogo.Image = id end
    end)

    local barName = Instance.new("TextLabel")
    barName.Position = UDim2.fromOffset(px(40), 0)
    barName.Size = UDim2.fromOffset(px(160), TB)
    barName.BackgroundTransparency = 1
    barName.Font = Theme.fonts.title
    barName.Text = "sync.gg"
    barName.TextSize = px(15)
    barName.TextColor3 = WHITE
    barName.TextXAlignment = Enum.TextXAlignment.Left
    barName.ZIndex = 5
    barName.Parent = bar

    local function barBtn(x, txt, size)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(1, 0.5)
        b.Position = UDim2.new(1, x, 0.5, 0)
        b.Size = UDim2.fromOffset(px(26), px(26))
        b.BackgroundTransparency = 1
        b.AutoButtonColor = false
        b.Font = Theme.fonts.body
        b.Text = txt
        b.TextSize = size
        b.TextColor3 = Color3.fromRGB(170, 170, 178)
        b.ZIndex = 5
        b.Parent = bar
        b.MouseEnter:Connect(function() b.TextColor3 = WHITE end)
        b.MouseLeave:Connect(function() b.TextColor3 = Color3.fromRGB(170, 170, 178) end)
        return b
    end
    local minBtn = barBtn(-px(40), "\226\128\148", px(16)) -- em dash
    local closeBtn = barBtn(-px(12), "\195\151", px(20))    -- multiplication sign

    -- ---- centered logo + SIGN IN -----------------------------------------
    local head = Instance.new("Frame")
    head.AnchorPoint = Vector2.new(0.5, 0.5)
    head.Position = UDim2.fromOffset(W / 2, px(190))
    head.Size = UDim2.fromOffset(px(300), px(90))
    head.BackgroundTransparency = 1
    head.ZIndex = 4
    head.Parent = win

    local logo = Instance.new("ImageLabel")
    logo.AnchorPoint = Vector2.new(0, 0.5)
    logo.Position = UDim2.fromOffset(px(20), px(45))
    logo.Size = UDim2.fromOffset(px(84), px(84))
    logo.BackgroundTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    logo.ZIndex = 5
    logo.Parent = head
    local lg = Instance.new("UIGradient") -- glossy pink
    lg.Rotation = 90
    lg.Color = ColorSequence.new(PINK_HI, PINK_LO)
    lg.Parent = logo
    task.spawn(function()
        local id = remotePng("sync_mark.png", 128, 128)
        if id and logo.Parent then logo.Image = id end
    end)

    local signin = Instance.new("TextLabel")
    signin.AnchorPoint = Vector2.new(0, 0.5)
    signin.Position = UDim2.fromOffset(px(116), px(45))
    signin.Size = UDim2.fromOffset(px(180), px(50))
    signin.BackgroundTransparency = 1
    signin.Font = Enum.Font.GothamBlack
    signin.Text = "SIGN IN"
    signin.TextSize = px(38)
    signin.TextColor3 = WHITE
    signin.TextXAlignment = Enum.TextXAlignment.Left
    signin.ZIndex = 5
    signin.Parent = head

    -- ---- fields -----------------------------------------------------------
    local fieldW = W - px(80)
    local function field(y, placeholder, iconName)
        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(px(40), y)
        holder.Size = UDim2.fromOffset(fieldW, px(48))
        holder.BackgroundColor3 = FIELD
        holder.BackgroundTransparency = 0.15
        holder.BorderSizePixel = 0
        holder.ClipsDescendants = true
        holder.ZIndex = 4
        holder.Parent = win
        Util.corner(holder, px(10))
        local st = Util.stroke(holder, Color3.fromRGB(80, 80, 88), 1, 0.5)

        local box = Instance.new("TextBox")
        box.Position = UDim2.fromOffset(px(16), 0)
        box.Size = UDim2.fromOffset(fieldW - px(56), px(48))
        box.BackgroundTransparency = 1
        box.Font = Theme.fonts.body
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = Color3.fromRGB(120, 120, 128)
        box.Text = ""
        box.TextSize = px(15)
        box.TextColor3 = WHITE
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.ZIndex = 5
        box.Parent = holder

        local icon = Instance.new("ImageLabel")
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Position = UDim2.new(1, -px(14), 0.5, 0)
        icon.Size = UDim2.fromOffset(px(20), px(20))
        icon.BackgroundTransparency = 1
        icon.ImageColor3 = PINK
        icon.ZIndex = 5
        icon.Parent = holder
        loadIcon(icon, iconName, PINK)

        box.Focused:Connect(function() Util.tween(st, { Transparency = 0, Color = PINK }, 0.15) end)
        box.FocusLost:Connect(function() Util.tween(st, { Transparency = 0.5, Color = Color3.fromRGB(80, 80, 88) }, 0.15) end)
        return box, st
    end

    local userBox, userStroke = field(px(300), "Username", "user-pen")
    local passBox, passStroke = field(px(360), "Password", "lock")

    -- password mask (single-byte '*', safe for normal typing)
    local realPass = ""
    passBox:GetPropertyChangedSignal("Text"):Connect(function()
        local t = passBox.Text
        if t == string.rep("*", #realPass) then return end
        if #t > #realPass then
            realPass = realPass .. t:sub(#realPass + 1)
        else
            realPass = realPass:sub(1, #t)
        end
        passBox.Text = string.rep("*", #realPass)
    end)

    -- forgot line
    local forgot = Instance.new("TextLabel")
    forgot.Position = UDim2.fromOffset(px(40), px(418))
    forgot.Size = UDim2.fromOffset(fieldW, px(18))
    forgot.BackgroundTransparency = 1
    forgot.Font = Theme.fonts.title
    forgot.RichText = true
    forgot.Text = '<font color="rgb(234,76,137)">Forgot your account</font> <font color="rgb(150,150,158)">password?</font>'
    forgot.TextSize = px(13)
    forgot.TextXAlignment = Enum.TextXAlignment.Left
    forgot.ZIndex = 4
    forgot.Parent = win

    -- Sign IN button
    local signBtn = Instance.new("TextButton")
    signBtn.Position = UDim2.fromOffset(px(40), px(446))
    signBtn.Size = UDim2.fromOffset(fieldW, px(50))
    signBtn.BackgroundColor3 = PINK
    signBtn.AutoButtonColor = false
    signBtn.Font = Theme.fonts.title
    signBtn.Text = "Sign IN"
    signBtn.TextSize = px(17)
    signBtn.TextColor3 = WHITE
    signBtn.BorderSizePixel = 0
    signBtn.ZIndex = 4
    signBtn.Parent = win
    Util.corner(signBtn, px(10))
    signBtn.MouseEnter:Connect(function() Util.tween(signBtn, { BackgroundColor3 = Color3.fromRGB(244, 96, 156) }, 0.12) end)
    signBtn.MouseLeave:Connect(function() Util.tween(signBtn, { BackgroundColor3 = PINK }, 0.12) end)

    -- error line
    local err = Instance.new("TextLabel")
    err.Position = UDim2.fromOffset(px(40), px(500))
    err.Size = UDim2.fromOffset(fieldW, px(16))
    err.BackgroundTransparency = 1
    err.Font = Theme.fonts.caption
    err.Text = ""
    err.TextSize = px(12)
    err.TextColor3 = Color3.fromRGB(120, 220, 150)
    err.TextXAlignment = Enum.TextXAlignment.Center
    err.ZIndex = 4
    err.Parent = win

    -- ---- behaviour --------------------------------------------------------
    local function exitThen(cb)
        Util.tween(win, { BackgroundTransparency = 1 }, 0.24, QUART, Enum.EasingDirection.In)
        Util.tween(scaleFx, { Scale = 0.96 }, 0.24, QUART, Enum.EasingDirection.In)
        Util.tween(scrim, { BackgroundTransparency = 1 }, 0.3, SINE)
        task.delay(0.28, function()
            gui:Destroy()
            if cb then cb() end
        end)
    end

    local function shake()
        local base = win.Position
        for i, dx in ipairs({ -12, 10, -8, 6, -3, 0 }) do
            task.delay((i - 1) * 0.05, function()
                if win.Parent then Util.tween(win, { Position = base + UDim2.fromOffset(px(dx), 0) }, 0.05) end
            end)
        end
    end

    local function attempt()
        if userBox.Text == USER and realPass == PASS then
            err.TextColor3 = Color3.fromRGB(120, 220, 150)
            err.Text = "Welcome back"
            exitThen(finish)
        else
            err.TextColor3 = Color3.fromRGB(255, 110, 120)
            err.Text = "Wrong username or password"
            Util.tween(userStroke, { Transparency = 0, Color = Color3.fromRGB(255, 110, 120) }, 0.15)
            Util.tween(passStroke, { Transparency = 0, Color = Color3.fromRGB(255, 110, 120) }, 0.15)
            shake()
            task.delay(1.6, function()
                if err.Parent then err.Text = "" end
                Util.tween(userStroke, { Transparency = 0.5, Color = Color3.fromRGB(80, 80, 88) }, 0.2)
                Util.tween(passStroke, { Transparency = 0.5, Color = Color3.fromRGB(80, 80, 88) }, 0.2)
            end)
        end
    end

    signBtn.MouseButton1Click:Connect(attempt)
    passBox.FocusLost:Connect(function(enter) if enter then attempt() end end)
    userBox.FocusLost:Connect(function(enter) if enter then passBox:CaptureFocus() end end)
    closeBtn.MouseButton1Click:Connect(function() exitThen(finish) end)
    forgot.Parent = win

    return gui
end

return Login
