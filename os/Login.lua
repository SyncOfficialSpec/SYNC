-- SYNC / os / Login
-- A multi-stage "SYNC.GG" sign-in shown after the boot splash, rebuilt to match
-- the reference exactly:
--   A) login form   (Username, Password, LOG IN, SIGN UP / Forgot)
--   B) on LOG IN the button turns red and fills, then a security-check panel
--      slides in from the right (Windows / Anti-Virus / Driver Blacklist /
--      Driver Check, each spinner -> check) with a "CHECKING FOR MISSING PIECES" bar
--   C) a verify screen (avatar + name + UID, SYNC.GG, animated bars, status text)
-- then it hands off to the desktop.
--
-- Credentials are hard-coded for now: Diablo / Diablo.
-- Login.run(onDone) plays and calls onDone() once the user is through.

local Players = game:GetService("Players")
local Theme   = SYNC.import("core/Theme")
local Util    = SYNC.import("core/Util")

local Login = {}

local HS  = game:GetService("HttpService")
local RAW = "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/"

local VIOLET  = Color3.fromRGB(151, 151, 231)
local VIOLETH = Color3.fromRGB(171, 171, 243)
local RED     = Color3.fromRGB(237, 86, 100)
local WIN     = Color3.fromRGB(14, 14, 17)
local FIELD   = Color3.fromRGB(23, 24, 29)
local CARD    = Color3.fromRGB(20, 21, 26)
local WHITE   = Color3.fromRGB(244, 244, 248)
local GRAY    = Color3.fromRGB(140, 140, 150)
local DIM     = Color3.fromRGB(95, 95, 105)

local USER = "Diablo"
local PASS = "Diablo"

local QUART = Enum.EasingStyle.Quart
local BACK  = Enum.EasingStyle.Back
local SINE  = Enum.EasingStyle.Sine
local OUT   = Enum.EasingDirection.Out
local IN    = Enum.EasingDirection.In

local function loadIcon(img, name, tint)
    task.spawn(function()
        local url = "https://images.weserv.nl/?url="
            .. HS:UrlEncode("cdn.jsdelivr.net/npm/lucide-static/icons/" .. name .. ".svg")
            .. "&output=png&w=64&h=64&filt=negate"
        local id = Util.remoteImage(url, "ic_lg_" .. name .. ".png")
        if id and img and img.Parent then img.Image = id; img.ImageColor3 = tint or WHITE end
    end)
end

function Login.run(onDone)
    local vp = Util.viewport()
    local S = math.clamp(vp.Y / 1080, 0.5, 1.35)
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

    -- darkened backdrop (the desktop wallpaper, dimmed)
    local backdrop = Instance.new("ImageLabel")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(10, 11, 16)
    backdrop.BorderSizePixel = 0
    backdrop.ScaleType = Enum.ScaleType.Crop
    backdrop.ImageTransparency = 1
    backdrop.Parent = gui
    task.spawn(function()
        local url = "https://images.weserv.nl/?url=" .. HS:UrlEncode(RAW .. "desktop_wallpaper.jpg")
            .. "&output=png&w=1280&h=720&blur=6"
        local id = Util.remoteImage(url, "login_backdrop.png")
        if id and backdrop.Parent then backdrop.Image = id; Util.tween(backdrop, { ImageTransparency = 0.5 }, 0.6) end
    end)
    local dim = Instance.new("Frame")
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.35
    dim.BorderSizePixel = 0
    dim.Parent = gui

    -- ---- window ----------------------------------------------------------
    local W, H = px(1180), px(700)
    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = WIN
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    Util.corner(win, px(22))
    Util.stroke(win, Color3.fromRGB(255, 255, 255), 1, 0.92)
    Util.shadow(win, { blur = 70, spread = 0, transparency = 0.4, offset = UDim2.fromOffset(0, px(26)) })
    local wScale = Instance.new("UIScale"); wScale.Scale = 0.95; wScale.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(win, { BackgroundTransparency = 0 }, 0.35)
    Util.tween(wScale, { Scale = 1 }, 0.45, BACK, OUT)

    -- title (SYNC.GG) + close, shown for stages A/B
    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(px(40), px(30))
    title.Size = UDim2.fromOffset(px(300), px(30))
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.RichText = true
    title.Text = 'SYNC<font color="rgb(151,151,231)">.</font>GG'
    title.TextSize = px(24)
    title.TextColor3 = WHITE
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 6
    title.Parent = win

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.fromOffset(W - px(30), px(28))
    closeBtn.Size = UDim2.fromOffset(px(28), px(28))
    closeBtn.BackgroundTransparency = 1
    closeBtn.AutoButtonColor = false
    closeBtn.Font = Theme.fonts.body
    closeBtn.Text = "\195\151"
    closeBtn.TextSize = px(24)
    closeBtn.TextColor3 = Color3.fromRGB(180, 180, 188)
    closeBtn.ZIndex = 6
    closeBtn.Parent = win
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = WHITE end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(180, 180, 188) end)

    -- ======================================================================
    -- Stage A: login form
    -- ======================================================================
    local form = Instance.new("Frame")
    form.Size = UDim2.fromScale(1, 1)
    form.BackgroundTransparency = 1
    form.ZIndex = 3
    form.Parent = win

    local FW = px(560)
    local FX = math.floor((W - FW) / 2)
    local py = px(250)

    local function field(y, placeholder, iconName)
        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(FX, y)
        holder.Size = UDim2.fromOffset(FW, px(56))
        holder.BackgroundColor3 = FIELD
        holder.BackgroundTransparency = 0.2
        holder.BorderSizePixel = 0
        holder.ClipsDescendants = true
        holder.ZIndex = 3
        holder.Parent = form
        Util.corner(holder, px(10))
        local st = Util.stroke(holder, Color3.fromRGB(70, 70, 80), 1, 0.55)
        local box = Instance.new("TextBox")
        box.Position = UDim2.fromOffset(px(18), 0)
        box.Size = UDim2.fromOffset(FW - px(60), px(56))
        box.BackgroundTransparency = 1
        box.Font = Theme.fonts.body
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = DIM
        box.Text = ""
        box.TextSize = px(15)
        box.TextColor3 = WHITE
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.ZIndex = 4
        box.Parent = holder
        local icon = Instance.new("ImageLabel")
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Position = UDim2.new(1, -px(16), 0.5, 0)
        icon.Size = UDim2.fromOffset(px(20), px(20))
        icon.BackgroundTransparency = 1
        icon.ImageColor3 = DIM
        icon.ZIndex = 4
        icon.Parent = holder
        loadIcon(icon, iconName, DIM)
        box.Focused:Connect(function() Util.tween(st, { Transparency = 0.1, Color = VIOLET }, 0.15); icon.ImageColor3 = VIOLET end)
        box.FocusLost:Connect(function() Util.tween(st, { Transparency = 0.55, Color = Color3.fromRGB(70, 70, 80) }, 0.15); icon.ImageColor3 = DIM end)
        return box, holder
    end

    local userBox = field(py, "Username", "user")
    local passBox = field(py + px(72), "Password", "eye")

    local realPass = ""
    passBox:GetPropertyChangedSignal("Text"):Connect(function()
        local t = passBox.Text
        if t == string.rep("*", #realPass) then return end
        if #t > #realPass then realPass = realPass .. t:sub(#realPass + 1)
        else realPass = realPass:sub(1, #t) end
        passBox.Text = string.rep("*", #realPass)
    end)

    -- LOG IN button (with an inner fill for the red loading sweep)
    local loginBtn = Instance.new("TextButton")
    loginBtn.Position = UDim2.fromOffset(FX, py + px(160))
    loginBtn.Size = UDim2.fromOffset(FW, px(58))
    loginBtn.BackgroundColor3 = VIOLET
    loginBtn.AutoButtonColor = false
    loginBtn.Font = Theme.fonts.title
    loginBtn.Text = "LOG IN"
    loginBtn.TextSize = px(17)
    loginBtn.TextColor3 = Color3.fromRGB(28, 26, 44)
    loginBtn.BorderSizePixel = 0
    loginBtn.ClipsDescendants = true
    loginBtn.ZIndex = 3
    loginBtn.Parent = form
    Util.corner(loginBtn, px(10))
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 130, 140)
    fill.BackgroundTransparency = 0.35
    fill.BorderSizePixel = 0
    fill.ZIndex = 3
    fill.Visible = false
    fill.Parent = loginBtn
    loginBtn.MouseEnter:Connect(function() if loginBtn.BackgroundColor3 == VIOLET then Util.tween(loginBtn, { BackgroundColor3 = VIOLETH }, 0.12) end end)
    loginBtn.MouseLeave:Connect(function() if loginBtn.BackgroundColor3 == VIOLETH then Util.tween(loginBtn, { BackgroundColor3 = VIOLET }, 0.12) end end)

    -- bottom links
    local links = Instance.new("TextLabel")
    links.Position = UDim2.fromOffset(FX, py + px(228))
    links.Size = UDim2.fromOffset(px(300), px(18))
    links.BackgroundTransparency = 1
    links.Font = Theme.fonts.caption
    links.RichText = true
    links.Text = '<font color="rgb(120,120,130)">Don\'t have an account? </font><font color="rgb(230,230,236)">SIGN UP</font>'
    links.TextSize = px(13)
    links.TextXAlignment = Enum.TextXAlignment.Left
    links.ZIndex = 3
    links.Parent = form
    local forgot = Instance.new("TextLabel")
    forgot.AnchorPoint = Vector2.new(1, 0)
    forgot.Position = UDim2.fromOffset(FX + FW, py + px(228))
    forgot.Size = UDim2.fromOffset(px(160), px(18))
    forgot.BackgroundTransparency = 1
    forgot.Font = Theme.fonts.caption
    forgot.Text = "Forgot password?"
    forgot.TextSize = px(13)
    forgot.TextColor3 = GRAY
    forgot.TextXAlignment = Enum.TextXAlignment.Right
    forgot.ZIndex = 3
    forgot.Parent = form

    -- ======================================================================
    -- Stage B: security checks (built hidden, slides in from the right)
    -- ======================================================================
    local checks = Instance.new("Frame")
    checks.Size = UDim2.fromScale(1, 1)
    checks.BackgroundTransparency = 1
    checks.ZIndex = 4
    checks.Visible = false
    checks.Parent = win

    local CKW = px(500)
    local CKX = W - px(40) - CKW
    local function checkCard(i, y, name, sub)
        local c = Instance.new("Frame")
        c.Position = UDim2.fromOffset(CKX + px(60), y) -- starts offset right, slides to CKX
        c.Size = UDim2.fromOffset(CKW, px(76))
        c.BackgroundColor3 = CARD
        c.BackgroundTransparency = 1
        c.BorderSizePixel = 0
        c.ZIndex = 5
        c.Parent = checks
        Util.corner(c, px(12))
        Util.stroke(c, Color3.fromRGB(60, 60, 70), 1, 0.7)
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(px(20), px(15))
        t.Size = UDim2.fromOffset(CKW - px(80), px(20))
        t.BackgroundTransparency = 1
        t.Font = Theme.fonts.title
        t.Text = name
        t.TextSize = px(16)
        t.TextColor3 = WHITE
        t.TextTransparency = 1
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 6
        t.Parent = c
        local d = Instance.new("TextLabel")
        d.Position = UDim2.fromOffset(px(20), px(40))
        d.Size = UDim2.fromOffset(CKW - px(80), px(18))
        d.BackgroundTransparency = 1
        d.Font = Theme.fonts.caption
        d.Text = sub
        d.TextSize = px(12)
        d.TextColor3 = DIM
        d.TextTransparency = 1
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.ZIndex = 6
        d.Parent = c
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(1, 0.5)
        ic.Position = UDim2.new(1, -px(20), 0.5, 0)
        ic.Size = UDim2.fromOffset(px(20), px(20))
        ic.BackgroundTransparency = 1
        ic.ImageColor3 = DIM
        ic.ImageTransparency = 1
        ic.ZIndex = 6
        ic.Parent = c
        loadIcon(ic, "rotate-cw", GRAY)
        return { frame = c, title = t, sub = d, icon = ic }
    end

    local ckDefs = {
        { "Windows", "Windows 11 22h4" },
        { "Anti-Virus", "Availability check..." },
        { "Driver Blacklist", "Availability check..." },
        { "Driver Check", "Availability check..." },
    }
    local cards = {}
    for i, cd in ipairs(ckDefs) do
        cards[i] = checkCard(i, px(90) + (i - 1) * px(90), cd[1], cd[2])
    end

    local checkBar = Instance.new("Frame")
    checkBar.AnchorPoint = Vector2.new(0, 1)
    checkBar.Position = UDim2.fromOffset(CKX + px(60), H - px(40))
    checkBar.Size = UDim2.fromOffset(CKW, px(50))
    checkBar.BackgroundColor3 = CARD
    checkBar.BackgroundTransparency = 1
    checkBar.BorderSizePixel = 0
    checkBar.ZIndex = 5
    checkBar.Parent = checks
    Util.corner(checkBar, px(12))
    Util.stroke(checkBar, Color3.fromRGB(60, 60, 70), 1, 0.7)
    local checkBarTxt = Instance.new("TextLabel")
    checkBarTxt.Size = UDim2.fromScale(1, 1)
    checkBarTxt.BackgroundTransparency = 1
    checkBarTxt.Font = Theme.fonts.title
    checkBarTxt.Text = "CHECKING FOR MISSING PIECES"
    checkBarTxt.TextSize = px(13)
    checkBarTxt.TextColor3 = Color3.fromRGB(210, 210, 218)
    checkBarTxt.TextTransparency = 1
    checkBarTxt.ZIndex = 6
    checkBarTxt.Parent = checkBar

    -- ======================================================================
    -- Stage C: verify screen (built hidden)
    -- ======================================================================
    local verify = Instance.new("Frame")
    verify.Size = UDim2.fromScale(1, 1)
    verify.BackgroundColor3 = WIN
    verify.BackgroundTransparency = 1
    verify.BorderSizePixel = 0
    verify.ZIndex = 8
    verify.Visible = false
    verify.Parent = win

    local av = Instance.new("ImageLabel")
    av.Position = UDim2.fromOffset(px(40), px(28))
    av.Size = UDim2.fromOffset(px(46), px(46))
    av.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    av.BorderSizePixel = 0
    av.ZIndex = 9
    av.Parent = verify
    Util.corner(av, px(23))
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and url and av.Parent then av.Image = url end
    end)
    local vName = Instance.new("TextLabel")
    vName.Position = UDim2.fromOffset(px(96), px(30))
    vName.Size = UDim2.fromOffset(px(240), px(20))
    vName.BackgroundTransparency = 1
    vName.Font = Theme.fonts.title
    vName.Text = "Past Owl"
    vName.TextSize = px(16)
    vName.TextColor3 = WHITE
    vName.TextXAlignment = Enum.TextXAlignment.Left
    vName.ZIndex = 9
    vName.Parent = verify
    local vUid = Instance.new("TextLabel")
    vUid.Position = UDim2.fromOffset(px(96), px(51))
    vUid.Size = UDim2.fromOffset(px(240), px(16))
    vUid.BackgroundTransparency = 1
    vUid.Font = Theme.fonts.caption
    vUid.Text = "UID: 1145"
    vUid.TextSize = px(12)
    vUid.TextColor3 = DIM
    vUid.TextXAlignment = Enum.TextXAlignment.Left
    vUid.ZIndex = 9
    vUid.Parent = verify
    local vTitle = Instance.new("TextLabel")
    vTitle.AnchorPoint = Vector2.new(0.5, 0)
    vTitle.Position = UDim2.fromOffset(W / 2, px(32))
    vTitle.Size = UDim2.fromOffset(px(300), px(30))
    vTitle.BackgroundTransparency = 1
    vTitle.Font = Enum.Font.GothamBlack
    vTitle.RichText = true
    vTitle.Text = 'SYNC<font color="rgb(151,151,231)">.</font>GG'
    vTitle.TextSize = px(24)
    vTitle.TextColor3 = WHITE
    vTitle.ZIndex = 9
    vTitle.Parent = verify
    local vStatus = Instance.new("TextLabel")
    vStatus.AnchorPoint = Vector2.new(0.5, 1)
    vStatus.Position = UDim2.fromOffset(W / 2, H - px(40))
    vStatus.Size = UDim2.fromOffset(px(500), px(20))
    vStatus.BackgroundTransparency = 1
    vStatus.Font = Theme.fonts.caption
    vStatus.Text = "Verify the account and your data from the server."
    vStatus.TextSize = px(14)
    vStatus.TextColor3 = GRAY
    vStatus.ZIndex = 9
    vStatus.Parent = verify

    -- equalizer bars
    local bars = {}
    local barW, barH, gap = px(30), px(96), px(10)
    local totalW = 3 * barW + 2 * gap
    for i = 1, 3 do
        local b = Instance.new("Frame")
        b.AnchorPoint = Vector2.new(0, 0.5)
        b.Position = UDim2.fromOffset(W / 2 - totalW / 2 + (i - 1) * (barW + gap), H / 2)
        b.Size = UDim2.fromOffset(barW, barH)
        b.BackgroundColor3 = Color3.fromRGB(160, 158, 214)
        b.BorderSizePixel = 0
        b.ZIndex = 9
        b.Parent = verify
        Util.corner(b, px(7))
        bars[i] = b
    end

    -- ======================================================================
    -- flow
    -- ======================================================================
    local function spin(icon)
        task.spawn(function()
            while icon.Parent and icon:GetAttribute("spinning") do
                Util.tween(icon, { Rotation = icon.Rotation + 180 }, 0.5, Enum.EasingStyle.Linear)
                task.wait(0.5)
            end
        end)
    end

    local function runChecks(afterAll)
        checks.Visible = true
        -- fade the form back
        for _, o in ipairs(form:GetDescendants()) do
            if o:IsA("TextLabel") then Util.tween(o, { TextTransparency = 0.75 }, 0.3)
            elseif o:IsA("TextBox") then Util.tween(o, { TextTransparency = 0.75 }, 0.3)
            elseif o:IsA("Frame") then Util.tween(o, { BackgroundTransparency = 0.85 }, 0.3) end
        end
        Util.tween(loginBtn, { BackgroundTransparency = 0.7 }, 0.3)
        -- slide cards in, staggered
        for i, card in ipairs(cards) do
            task.delay((i - 1) * 0.12, function()
                Util.tween(card.frame, { Position = UDim2.fromOffset(CKX, px(90) + (i - 1) * px(90)), BackgroundTransparency = 0 }, 0.4, QUART, OUT)
                Util.tween(card.title, { TextTransparency = 0 }, 0.4)
                Util.tween(card.sub, { TextTransparency = 0 }, 0.4)
                Util.tween(card.icon, { ImageTransparency = 0 }, 0.4)
            end)
        end
        Util.tween(checkBar, { Position = UDim2.fromOffset(CKX, H - px(40)), BackgroundTransparency = 0 }, 0.5, QUART, OUT)
        Util.tween(checkBarTxt, { TextTransparency = 0 }, 0.5)
        -- resolve sequentially
        task.spawn(function()
            task.wait(0.7)
            for i, card in ipairs(cards) do
                if i == 1 then
                    loadIcon(card.icon, "check", VIOLET) -- Windows: instant done
                else
                    card.icon:SetAttribute("spinning", true); spin(card.icon)
                    task.wait(0.75)
                    card.icon:SetAttribute("spinning", false)
                    card.icon.Rotation = 0
                    loadIcon(card.icon, "check", VIOLET)
                    card.sub.Text = "Passed"
                end
                task.wait(0.35)
            end
            task.wait(0.4)
            if afterAll then afterAll() end
        end)
    end

    local function showVerify()
        verify.Visible = true
        vName.Text = (userBox.Text ~= "" and userBox.Text) or "Past Owl"
        vUid.Text = "UID: " .. tostring(Players.LocalPlayer.UserId)
        title.Visible = false
        Util.tween(verify, { BackgroundTransparency = 0 }, 0.35)
        -- animate the bars: a staggered up/down pulse (middle leads)
        task.spawn(function()
            while verify.Parent and verify.Visible do
                for i, b in ipairs(bars) do
                    task.delay((i - 1) * 0.12, function()
                        if b.Parent then Util.tween(b, { Size = UDim2.fromOffset(barW, px(58)) }, 0.35, SINE, Enum.EasingDirection.InOut) end
                    end)
                end
                task.wait(0.5)
                for i, b in ipairs(bars) do
                    task.delay((i - 1) * 0.12, function()
                        if b.Parent then Util.tween(b, { Size = UDim2.fromOffset(barW, barH) }, 0.35, SINE, Enum.EasingDirection.InOut) end
                    end)
                end
                task.wait(0.55)
            end
        end)
        task.delay(2.6, function()
            Util.tween(win, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(verify, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(dim, { BackgroundTransparency = 1 }, 0.3)
            Util.tween(backdrop, { ImageTransparency = 1 }, 0.3)
            task.delay(0.34, function() gui:Destroy(); finish() end)
        end)
    end

    local busy = false
    local function attempt()
        if busy then return end
        if userBox.Text == USER and realPass == PASS then
            busy = true
            -- red loading fill
            Util.tween(loginBtn, { BackgroundColor3 = RED }, 0.15)
            loginBtn.Text = ""
            fill.Visible = true
            fill.Size = UDim2.new(0, 0, 1, 0)
            Util.tween(fill, { Size = UDim2.new(1, 0, 1, 0) }, 1.4, SINE)
            task.delay(1.5, function()
                runChecks(showVerify)
            end)
        else
            Util.tween(loginBtn, { BackgroundColor3 = RED }, 0.12)
            loginBtn.Text = "WRONG LOGIN"
            local base = win.Position
            for i, dx in ipairs({ -12, 10, -8, 6, -3, 0 }) do
                task.delay((i - 1) * 0.05, function()
                    if win.Parent then Util.tween(win, { Position = base + UDim2.fromOffset(px(dx), 0) }, 0.05) end
                end)
            end
            task.delay(1.2, function()
                Util.tween(loginBtn, { BackgroundColor3 = VIOLET }, 0.2)
                loginBtn.Text = "LOG IN"
            end)
        end
    end

    loginBtn.MouseButton1Click:Connect(attempt)
    passBox.FocusLost:Connect(function(enter) if enter then attempt() end end)
    userBox.FocusLost:Connect(function(enter) if enter then passBox:CaptureFocus() end end)
    closeBtn.MouseButton1Click:Connect(function()
        Util.tween(win, { BackgroundTransparency = 1 }, 0.25)
        Util.tween(wScale, { Scale = 0.96 }, 0.25)
        Util.tween(dim, { BackgroundTransparency = 1 }, 0.3)
        Util.tween(backdrop, { ImageTransparency = 1 }, 0.3)
        task.delay(0.3, function() gui:Destroy(); finish() end)
    end)

    return gui
end

return Login
