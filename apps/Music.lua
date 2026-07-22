-- SYNC / apps / Music
-- A Spotify companion. You paste a Spotify OAuth token, SYNC talks to the Spotify
-- Web API (api.spotify.com) with it, and then shows what you're playing with
-- play / pause / skip controls that drive your real Spotify. No audio streams
-- through Roblox (Spotify doesn't allow that); this is a remote for your account.
--
-- Music.open() -> builds the window (a single instance).

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local Music = {}

local _req = (syn and syn.request) or (http and http.request) or http_request or request

local WHITE  = Color3.fromRGB(244, 244, 248)
local SUB    = Color3.fromRGB(150, 150, 158)
local DIM    = Color3.fromRGB(105, 105, 113)
local WIN    = Color3.fromRGB(15, 15, 18)
local BAR    = Color3.fromRGB(28, 28, 32)
local FIELD  = Color3.fromRGB(12, 12, 15)
local CARD   = Color3.fromRGB(22, 22, 27)
local BLUE   = Color3.fromRGB(46, 72, 117)
local BLUEH  = Color3.fromRGB(58, 88, 140)
local LINK   = Color3.fromRGB(74, 135, 225)

local TOKEN_KEY = "SpotifyToken"
local API = "https://api.spotify.com/v1"

-- lucide icon -> white png (renders black, negate whitens), then tint
local function loadIcon(img, name, tint)
    task.spawn(function()
        local url = "https://images.weserv.nl/?url="
            .. HttpService:UrlEncode("cdn.jsdelivr.net/npm/lucide-static/icons/" .. name .. ".svg")
            .. "&output=png&w=96&h=96&filt=negate"
        local id = Util.remoteImage(url, "ic_music_" .. name .. ".png")
        if id and img and img.Parent then img.Image = id; img.ImageColor3 = tint or WHITE end
    end)
end

-- album art (https i.scdn.co) -> png via weserv, cached per track id
local function loadArt(img, url, key)
    task.spawn(function()
        local png = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode(url) .. "&output=png&w=300&h=300&fit=cover"
        local id = Util.remoteImage(png, "sp_art_" .. key .. ".png")
        if id and img and img.Parent then img.Image = id end
    end)
end

-- one Spotify API call. Returns (body, statusCode).
local function spotify(method, path, token, body)
    if not _req then return nil, 0 end
    local ok, res = pcall(_req, {
        Url = API .. path,
        Method = method,
        Headers = {
            ["Authorization"] = "Bearer " .. token,
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "SYNC",
        },
        Body = body,
    })
    if ok and res then return res.Body, res.StatusCode or 0 end
    return nil, 0
end

local function mmss(ms)
    ms = math.max(0, math.floor((ms or 0) / 1000))
    return ("%d:%02d"):format(math.floor(ms / 60), ms % 60)
end

Music._gui = nil

-- ============================================================================
-- MP3 PLAYER: a separate compact window that plays local audio files dropped
-- into SYNC/songs. Roblox plays them via getcustomasset (custom audio assets).
-- ============================================================================
local SND_DIR = "SYNC/songs"
local AUDIO_EXT = { mp3 = true, ogg = true, wav = true }

function Music.openMP3()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    if host:FindFirstChild("SYNC_MP3") then return end
    pcall(function()
        if type(makefolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder(SND_DIR) then makefolder(SND_DIR) end
        end
    end)

    local W, H = 364, 452
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_MP3"
    Util.mount(gui)

    local closing = false
    local win = Instance.new("Frame")
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.44)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.Parent = gui
    Util.corner(win, 16)
    Util.stroke(win, WHITE, 1, 0.9)
    Util.shadow(win, { blur = 55, spread = 0, transparency = 0.35, offset = UDim2.fromOffset(0, 22) })
    -- subtle top-to-bottom gradient on the whole window
    local wg = Instance.new("UIGradient")
    wg.Rotation = 90
    wg.Color = ColorSequence.new(Color3.fromRGB(24, 28, 40), Color3.fromRGB(12, 12, 16))
    wg.Parent = win
    local sc = Instance.new("UIScale"); sc.Scale = 0.94; sc.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(sc, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0 }, 0.18)

    local function close()
        if closing then return end
        closing = true
        Util.tween(sc, { Scale = 0.94 }, 0.14)
        Util.tween(win, { BackgroundTransparency = 1 }, 0.14)
        task.delay(0.16, function() gui:Destroy() end)
    end
    Util.closeOnEscape(gui, close)

    local titleTxt = Instance.new("TextLabel")
    titleTxt.Text = "MP3 PLAYER"
    titleTxt.Position = UDim2.fromOffset(18, 14)
    titleTxt.Size = UDim2.fromOffset(200, 18)
    titleTxt.BackgroundTransparency = 1
    titleTxt.Font = Theme.fonts.title
    titleTxt.TextSize = 12
    titleTxt.TextColor3 = Color3.fromRGB(180, 180, 190)
    titleTxt.TextXAlignment = Enum.TextXAlignment.Left
    titleTxt.Parent = win
    local dragBar = Instance.new("Frame")
    dragBar.Size = UDim2.new(1, 0, 0, 40)
    dragBar.BackgroundTransparency = 1
    dragBar.Parent = win
    Util.draggable(win, dragBar)

    local xBtn = Instance.new("TextButton")
    xBtn.AnchorPoint = Vector2.new(1, 0)
    xBtn.Position = UDim2.fromOffset(W - 14, 12)
    xBtn.Size = UDim2.fromOffset(22, 22)
    xBtn.BackgroundTransparency = 1
    xBtn.AutoButtonColor = false
    xBtn.Font = Theme.fonts.body
    xBtn.Text = "\195\151"
    xBtn.TextSize = 20
    xBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
    xBtn.Parent = win
    xBtn.MouseEnter:Connect(function() xBtn.TextColor3 = WHITE end)
    xBtn.MouseLeave:Connect(function() xBtn.TextColor3 = Color3.fromRGB(160, 160, 170) end)
    xBtn.MouseButton1Click:Connect(close)

    -- art / empty-state area
    local artArea = Instance.new("Frame")
    artArea.Position = UDim2.fromOffset(16, 46)
    artArea.Size = UDim2.fromOffset(W - 32, 176)
    artArea.BackgroundColor3 = Color3.fromRGB(10, 11, 15)
    artArea.BackgroundTransparency = 0.2
    artArea.BorderSizePixel = 0
    artArea.Parent = win
    Util.corner(artArea, 12)
    local emptyTxt = Instance.new("TextLabel")
    emptyTxt.AnchorPoint = Vector2.new(0.5, 0.5)
    emptyTxt.Position = UDim2.fromScale(0.5, 0.5)
    emptyTxt.Size = UDim2.fromOffset(W - 60, 44)
    emptyTxt.BackgroundTransparency = 1
    emptyTxt.Font = Theme.fonts.caption
    emptyTxt.Text = "Drop .mp3 files into\nSYNC/songs folder"
    emptyTxt.TextSize = 13
    emptyTxt.TextColor3 = Color3.fromRGB(120, 120, 130)
    emptyTxt.Parent = artArea

    local trackTxt = Instance.new("TextLabel")
    trackTxt.Position = UDim2.fromOffset(20, 236)
    trackTxt.Size = UDim2.fromOffset(W - 40, 24)
    trackTxt.BackgroundTransparency = 1
    trackTxt.Font = Theme.fonts.title
    trackTxt.Text = "No Track"
    trackTxt.TextSize = 16
    trackTxt.TextColor3 = WHITE
    trackTxt.TextTruncate = Enum.TextTruncate.AtEnd
    trackTxt.Parent = win

    -- progress slider
    local BLUEP = Color3.fromRGB(58, 108, 210)
    local function makeSlider(y, w, h, onSet)
        local track = Instance.new("TextButton")
        track.Text = ""; track.AutoButtonColor = false
        track.Position = UDim2.fromOffset(20, y)
        track.Size = UDim2.fromOffset(w, h)
        track.BackgroundColor3 = Color3.fromRGB(55, 56, 64)
        track.BorderSizePixel = 0
        track.Parent = win
        Util.corner(track, h / 2)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = BLUEP
        fill.BorderSizePixel = 0
        fill.Parent = track
        Util.corner(fill, h / 2)
        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.fromScale(0, 0.5)
        knob.Size = UDim2.fromOffset(h + 6, h + 6)
        knob.BackgroundColor3 = WHITE
        knob.BorderSizePixel = 0
        knob.ZIndex = 3
        knob.Parent = track
        Util.corner(knob, (h + 6) / 2)
        local function setFrac(f)
            f = math.clamp(f, 0, 1)
            fill.Size = UDim2.new(f, 0, 1, 0)
            knob.Position = UDim2.new(f, 0, 0.5, 0)
        end
        local dragging = false
        local function fracFromX(px)
            local rel = (px - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X)
            return math.clamp(rel, 0, 1)
        end
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local f = fracFromX(inp.Position.X); setFrac(f); if onSet then onSet(f) end
            end
        end)
        track.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        game:GetService("UserInputService").InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local f = fracFromX(inp.Position.X); setFrac(f); if onSet then onSet(f) end
            end
        end)
        return setFrac, function() return dragging end
    end

    -- ---- audio state ----
    local sound
    local files, index = {}, 0
    local seeking = false

    local function stopSound()
        if sound then pcall(function() sound:Stop(); sound:Destroy() end); sound = nil end
    end

    local progSet, progDragging
    local timeCur = Instance.new("TextLabel")
    timeCur.Position = UDim2.fromOffset(20, 292)
    timeCur.Size = UDim2.fromOffset(50, 14)
    timeCur.BackgroundTransparency = 1
    timeCur.Font = Theme.fonts.caption
    timeCur.Text = "0:00"; timeCur.TextSize = 11; timeCur.TextColor3 = DIM
    timeCur.TextXAlignment = Enum.TextXAlignment.Left
    timeCur.Parent = win
    local timeEnd = Instance.new("TextLabel")
    timeEnd.AnchorPoint = Vector2.new(1, 0)
    timeEnd.Position = UDim2.fromOffset(W - 20, 292)
    timeEnd.Size = UDim2.fromOffset(50, 14)
    timeEnd.BackgroundTransparency = 1
    timeEnd.Font = Theme.fonts.caption
    timeEnd.Text = "0:00"; timeEnd.TextSize = 11; timeEnd.TextColor3 = DIM
    timeEnd.TextXAlignment = Enum.TextXAlignment.Right
    timeEnd.Parent = win

    progSet, progDragging = makeSlider(276, W - 40, 6, function(f)
        if sound and sound.TimeLength > 0 then sound.TimePosition = f * sound.TimeLength end
    end)

    -- controls
    local playIc
    local function ctrl(cx, size, icon)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(0.5, 0.5)
        b.Position = UDim2.fromOffset(cx, 340)
        b.Size = UDim2.fromOffset(size, size)
        b.BackgroundTransparency = 1
        b.AutoButtonColor = false
        b.Text = ""
        b.Parent = win
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.Size = UDim2.fromOffset(math.floor(size * 0.6), math.floor(size * 0.6))
        ic.BackgroundTransparency = 1
        ic.ImageColor3 = WHITE
        ic.Parent = b
        loadIcon(ic, icon, WHITE)
        return b, ic
    end
    local prevBtn = ctrl(W / 2 - 66, 34, "skip-back")
    local playBtn, playIco = ctrl(W / 2, 46, "play")
    local nextBtn = ctrl(W / 2 + 66, 34, "skip-forward")

    local function fmt(s) s = math.max(0, math.floor(s or 0)); return ("%d:%02d"):format(math.floor(s / 60), s % 60) end

    local function playIndex(i)
        if #files == 0 then return end
        index = ((i - 1) % #files) + 1
        stopSound()
        local path = files[index]
        local ok, id = pcall(function() return getcustomasset(path) end)
        if not ok or not id then trackTxt.Text = "Could not load track"; return end
        sound = Instance.new("Sound")
        sound.SoundId = id
        sound.Volume = 0.6
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        -- filename -> nice title
        local name = path:match("([^/\\]+)$") or path
        name = name:gsub("%.%w+$", "")
        trackTxt.Text = name
        loadIcon(playIco, "pause", WHITE)
        sound.Ended:Connect(function() if sound and not closing then playIndex(index + 1) end end)
    end

    local function scan()
        files = {}
        local ok, list = pcall(function() return listfiles(SND_DIR) end)
        if ok and list then
            for _, f in ipairs(list) do
                local ext = tostring(f):match("%.(%w+)$")
                if ext and AUDIO_EXT[ext:lower()] then files[#files + 1] = f end
            end
        end
        if #files > 0 then
            emptyTxt.Text = (#files == 1 and "1 track loaded") or (#files .. " tracks loaded")
        else
            emptyTxt.Text = "Drop .mp3 files into\nSYNC/songs folder"
            trackTxt.Text = "No Track"
        end
    end

    prevBtn.MouseButton1Click:Connect(function() if #files > 0 then playIndex(index - 1) end end)
    nextBtn.MouseButton1Click:Connect(function() if #files > 0 then playIndex(index + 1) end end)
    playBtn.MouseButton1Click:Connect(function()
        if not sound then if #files > 0 then playIndex(index == 0 and 1 or index) end return end
        if sound.Playing then sound:Pause(); loadIcon(playIco, "play", WHITE)
        else sound:Resume(); loadIcon(playIco, "pause", WHITE) end
    end)

    -- volume slider + refresh
    local volSet = makeSlider(H - 40, 96, 5, function(f) if sound then sound.Volume = f end end)
    volSet(0.6)
    local refresh = Instance.new("TextButton")
    refresh.AnchorPoint = Vector2.new(1, 0.5)
    refresh.Position = UDim2.fromOffset(W - 20, H - 37)
    refresh.Size = UDim2.fromOffset(70, 20)
    refresh.BackgroundTransparency = 1
    refresh.AutoButtonColor = false
    refresh.Font = Theme.fonts.caption
    refresh.Text = "Refresh"
    refresh.TextSize = 12
    refresh.TextColor3 = Color3.fromRGB(150, 150, 160)
    refresh.TextXAlignment = Enum.TextXAlignment.Right
    refresh.Parent = win
    refresh.MouseEnter:Connect(function() refresh.TextColor3 = WHITE end)
    refresh.MouseLeave:Connect(function() refresh.TextColor3 = Color3.fromRGB(150, 150, 160) end)
    refresh.MouseButton1Click:Connect(scan)

    -- progress update loop
    task.spawn(function()
        while gui.Parent do
            if sound and sound.TimeLength and sound.TimeLength > 0 then
                timeCur.Text = fmt(sound.TimePosition)
                timeEnd.Text = fmt(sound.TimeLength)
                if not progDragging() then progSet(sound.TimePosition / sound.TimeLength) end
            end
            task.wait(0.3)
        end
        stopSound()
    end)

    scan()
    return { close = close }
end

function Music.open()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    if host:FindFirstChild("SYNC_Music") then return end

    local cardW, cardH = 560, 440
    local TB = 38

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Music"
    Util.mount(gui)
    Music._gui = gui

    local winRef, scaleRef, closing = nil, nil, false
    local function close()
        if closing then return end
        closing = true
        Music._gui = nil
        if winRef and scaleRef then
            Util.tween(scaleRef, { Scale = 0.94 }, 0.15)
            Util.tween(winRef, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.17, function() gui:Destroy() end)
        else
            gui:Destroy()
        end
    end

    local catcher = Instance.new("TextButton")
    catcher.Text = ""; catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)
    Util.closeOnEscape(gui, close)

    local win = Instance.new("TextButton")
    win.Text = ""; win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(cardW, cardH)
    win.BackgroundColor3 = WIN
    win.BackgroundTransparency = 0.03
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 16)
    Util.stroke(win, WHITE, 1, 0.9)
    Util.shadow(win, { blur = 55, spread = 0, transparency = 0.4, offset = UDim2.fromOffset(0, 22) })

    scaleRef = Instance.new("UIScale"); scaleRef.Scale = 0.94; scaleRef.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleRef, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0.03 }, 0.18)
    winRef = win

    -- title bar (traffic lights only, draggable, red closes)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = BAR
    bar.BackgroundTransparency = 0.15
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local bc = Instance.new("UICorner")
    local okc = pcall(function()
        bc.TopLeftRadius = UDim.new(0, 16); bc.TopRightRadius = UDim.new(0, 16)
        bc.BottomLeftRadius = UDim.new(0, 0); bc.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okc then bc.CornerRadius = UDim.new(0, 16) end
    bc.Parent = bar
    for i, col in ipairs({ Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }) do
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
    Util.draggable(win, bar)
    Util.persistPosition(win, "MusicWin")

    -- app header: music mark + "Music" + subtitle + "+"
    local hIcon = Instance.new("ImageLabel")
    hIcon.Size = UDim2.fromOffset(20, 20)
    hIcon.Position = UDim2.fromOffset(20, TB + 16)
    hIcon.BackgroundTransparency = 1
    hIcon.ImageColor3 = WHITE
    hIcon.ZIndex = 3
    hIcon.Parent = win
    loadIcon(hIcon, "music", WHITE)

    local hTitle = Instance.new("TextLabel")
    hTitle.Text = "Music"
    hTitle.Position = UDim2.fromOffset(48, TB + 12)
    hTitle.Size = UDim2.fromOffset(240, 22)
    hTitle.BackgroundTransparency = 1
    hTitle.Font = Theme.fonts.title
    hTitle.TextSize = 18
    hTitle.TextColor3 = WHITE
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.ZIndex = 3
    hTitle.Parent = win

    local hSub = Instance.new("TextLabel")
    hSub.Text = "Connect Spotify"
    hSub.Position = UDim2.fromOffset(48, TB + 35)
    hSub.Size = UDim2.fromOffset(300, 18)
    hSub.BackgroundTransparency = 1
    hSub.Font = Theme.fonts.caption
    hSub.TextSize = 13
    hSub.TextColor3 = SUB
    hSub.TextXAlignment = Enum.TextXAlignment.Left
    hSub.TextTruncate = Enum.TextTruncate.AtEnd
    hSub.ZIndex = 3
    hSub.Parent = win

    local plus = Instance.new("TextButton")
    plus.AnchorPoint = Vector2.new(1, 0)
    plus.Position = UDim2.fromOffset(cardW - 20, TB + 14)
    plus.Size = UDim2.fromOffset(32, 32)
    plus.BackgroundColor3 = CARD
    plus.BackgroundTransparency = 0.2
    plus.AutoButtonColor = false
    plus.Font = Theme.fonts.body
    plus.Text = "+"
    plus.TextSize = 22
    plus.TextColor3 = Color3.fromRGB(180, 180, 188)
    plus.BorderSizePixel = 0
    plus.ZIndex = 3
    plus.Parent = win
    Util.corner(plus, 16)
    Util.stroke(plus, WHITE, 1, 0.85)
    plus.MouseEnter:Connect(function() plus.TextColor3 = WHITE end)
    plus.MouseLeave:Connect(function() plus.TextColor3 = Color3.fromRGB(180, 180, 188) end)

    -- body container (state screens build in here)
    local body = Instance.new("Frame")
    body.Position = UDim2.fromOffset(0, TB + 60)
    body.Size = UDim2.fromOffset(cardW, cardH - TB - 60)
    body.BackgroundTransparency = 1
    body.ZIndex = 3
    body.Parent = win
    local BW, BH = cardW, cardH - TB - 60

    local function clearBody()
        for _, c in ipairs(body:GetChildren()) do c:Destroy() end
    end

    local pollAlive = false
    local showConnect, showPlayer

    -- ================= CONNECT SCREEN =================
    showConnect = function(errMsg)
        pollAlive = false
        clearBody()
        hSub.Text = "Connect Spotify"

        local note = Instance.new("ImageLabel")
        note.AnchorPoint = Vector2.new(0.5, 0)
        note.Position = UDim2.fromOffset(BW / 2, 6)
        note.Size = UDim2.fromOffset(46, 46)
        note.BackgroundTransparency = 1
        note.ImageColor3 = WHITE
        note.ZIndex = 4
        note.Parent = body
        loadIcon(note, "music", WHITE)

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 0)
        title.Position = UDim2.fromOffset(BW / 2, 62)
        title.Size = UDim2.fromOffset(BW, 26)
        title.BackgroundTransparency = 1
        title.Font = Theme.fonts.title
        title.Text = "Connect Spotify"
        title.TextSize = 20
        title.TextColor3 = WHITE
        title.ZIndex = 4
        title.Parent = body

        local desc = Instance.new("TextLabel")
        desc.AnchorPoint = Vector2.new(0.5, 0)
        desc.Position = UDim2.fromOffset(BW / 2, 92)
        desc.Size = UDim2.fromOffset(BW, 18)
        desc.BackgroundTransparency = 1
        desc.Font = Theme.fonts.caption
        desc.Text = "Paste your Spotify OAuth token to get started."
        desc.TextSize = 13
        desc.TextColor3 = SUB
        desc.ZIndex = 4
        desc.Parent = body

        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(30, 130)
        holder.Size = UDim2.fromOffset(BW - 60, 46)
        holder.BackgroundColor3 = FIELD
        holder.BackgroundTransparency = 0.1
        holder.BorderSizePixel = 0
        holder.ClipsDescendants = true
        holder.ZIndex = 4
        holder.Parent = body
        Util.corner(holder, 10)
        local st = Util.stroke(holder, Color3.fromRGB(70, 70, 80), 1, 0.55)
        local box = Instance.new("TextBox")
        box.Position = UDim2.fromOffset(18, 0)
        box.Size = UDim2.fromOffset(BW - 60 - 36, 46)
        box.BackgroundTransparency = 1
        box.Font = Theme.fonts.body
        box.PlaceholderText = "Paste your Spotify token..."
        box.PlaceholderColor3 = DIM
        box.Text = ""
        box.TextSize = 14
        box.TextColor3 = WHITE
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false
        box.ZIndex = 5
        box.Parent = holder
        box.Focused:Connect(function() Util.tween(st, { Transparency = 0.1, Color = LINK }, 0.15) end)
        box.FocusLost:Connect(function() Util.tween(st, { Transparency = 0.55, Color = Color3.fromRGB(70, 70, 80) }, 0.15) end)

        local btn = Instance.new("TextButton")
        btn.Position = UDim2.fromOffset(30, 188)
        btn.Size = UDim2.fromOffset(BW - 60, 46)
        btn.BackgroundColor3 = BLUE
        btn.AutoButtonColor = false
        btn.Font = Theme.fonts.title
        btn.Text = "Connect"
        btn.TextSize = 16
        btn.TextColor3 = WHITE
        btn.BorderSizePixel = 0
        btn.ZIndex = 4
        btn.Parent = body
        Util.corner(btn, 10)
        btn.MouseEnter:Connect(function() Util.tween(btn, { BackgroundColor3 = BLUEH }, 0.12) end)
        btn.MouseLeave:Connect(function() Util.tween(btn, { BackgroundColor3 = BLUE }, 0.12) end)

        local link = Instance.new("TextButton")
        link.AnchorPoint = Vector2.new(0.5, 0)
        link.Position = UDim2.fromOffset(BW / 2, 246)
        link.Size = UDim2.fromOffset(BW, 20)
        link.BackgroundTransparency = 1
        link.AutoButtonColor = false
        link.Font = Theme.fonts.body
        link.Text = "How to get a token"
        link.TextSize = 13
        link.TextColor3 = LINK
        link.ZIndex = 4
        link.Parent = body

        if errMsg then
            desc.Text = errMsg
            desc.TextColor3 = Color3.fromRGB(255, 110, 120)
        end

        local connecting = false
        local function doConnect()
            local token = box.Text:gsub("%s+", "")
            token = token:gsub("^Bearer ", "")
            if token == "" then return end
            if connecting then return end
            connecting = true
            btn.Text = "Connecting..."
            task.spawn(function()
                local bodyStr, status = spotify("GET", "/me", token)
                if status == 200 then
                    Util.save(TOKEN_KEY, token)
                    showPlayer(token)
                else
                    btn.Text = "Connect"
                    connecting = false
                    desc.Text = (status == 401 and "That token is invalid or expired.")
                        or (status == 0 and "Couldn't reach Spotify. Check your connection.")
                        or ("Spotify returned an error (" .. tostring(status) .. ").")
                    desc.TextColor3 = Color3.fromRGB(255, 110, 120)
                end
            end)
        end
        btn.MouseButton1Click:Connect(doConnect)
        box.FocusLost:Connect(function(enter) if enter then doConnect() end end)

        link.MouseButton1Click:Connect(function()
            desc.TextColor3 = SUB
            desc.Text = "Open the Spotify web player, then copy your Bearer access token from the network requests to api.spotify.com."
        end)
    end

    -- ================= PLAYER SCREEN =================
    showPlayer = function(token)
        clearBody()
        hSub.Text = "Loading..."

        -- album art
        local art = Instance.new("ImageLabel")
        art.Position = UDim2.fromOffset(30, 10)
        art.Size = UDim2.fromOffset(130, 130)
        art.BackgroundColor3 = CARD
        art.BorderSizePixel = 0
        art.ScaleType = Enum.ScaleType.Crop
        art.ZIndex = 4
        art.Parent = body
        Util.corner(art, 12)
        Util.shadow(art, { blur = 30, transparency = 0.5, offset = UDim2.fromOffset(0, 8) })

        local track = Instance.new("TextLabel")
        track.Position = UDim2.fromOffset(180, 22)
        track.Size = UDim2.fromOffset(BW - 210, 26)
        track.BackgroundTransparency = 1
        track.Font = Theme.fonts.title
        track.Text = "Nothing playing"
        track.TextSize = 19
        track.TextColor3 = WHITE
        track.TextXAlignment = Enum.TextXAlignment.Left
        track.TextTruncate = Enum.TextTruncate.AtEnd
        track.ZIndex = 4
        track.Parent = body

        local artist = Instance.new("TextLabel")
        artist.Position = UDim2.fromOffset(180, 50)
        artist.Size = UDim2.fromOffset(BW - 210, 20)
        artist.BackgroundTransparency = 1
        artist.Font = Theme.fonts.body
        artist.Text = "Open Spotify and press play"
        artist.TextSize = 14
        artist.TextColor3 = SUB
        artist.TextXAlignment = Enum.TextXAlignment.Left
        artist.TextTruncate = Enum.TextTruncate.AtEnd
        artist.ZIndex = 4
        artist.Parent = body

        -- progress bar
        local barBg = Instance.new("Frame")
        barBg.Position = UDim2.fromOffset(180, 90)
        barBg.Size = UDim2.fromOffset(BW - 210, 4)
        barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
        barBg.BorderSizePixel = 0
        barBg.ZIndex = 4
        barBg.Parent = body
        Util.corner(barBg, 2)
        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barFill.BackgroundColor3 = LINK
        barFill.BorderSizePixel = 0
        barFill.ZIndex = 5
        barFill.Parent = barBg
        Util.corner(barFill, 2)
        local tCur = Instance.new("TextLabel")
        tCur.Position = UDim2.fromOffset(180, 100)
        tCur.Size = UDim2.fromOffset(60, 16)
        tCur.BackgroundTransparency = 1
        tCur.Font = Theme.fonts.caption
        tCur.Text = "0:00"
        tCur.TextSize = 11
        tCur.TextColor3 = DIM
        tCur.TextXAlignment = Enum.TextXAlignment.Left
        tCur.ZIndex = 4
        tCur.Parent = body
        local tEnd = Instance.new("TextLabel")
        tEnd.AnchorPoint = Vector2.new(1, 0)
        tEnd.Position = UDim2.fromOffset(BW - 30, 100)
        tEnd.Size = UDim2.fromOffset(60, 16)
        tEnd.BackgroundTransparency = 1
        tEnd.Font = Theme.fonts.caption
        tEnd.Text = "0:00"
        tEnd.TextSize = 11
        tEnd.TextColor3 = DIM
        tEnd.TextXAlignment = Enum.TextXAlignment.Right
        tEnd.ZIndex = 4
        tEnd.Parent = body

        -- controls
        local ctrlY = 175
        local function ctrlBtn(cx, size, icon)
            local b = Instance.new("TextButton")
            b.AnchorPoint = Vector2.new(0.5, 0.5)
            b.Position = UDim2.fromOffset(cx, ctrlY)
            b.Size = UDim2.fromOffset(size, size)
            b.BackgroundTransparency = 1
            b.AutoButtonColor = false
            b.Text = ""
            b.ZIndex = 4
            b.Parent = body
            local ic = Instance.new("ImageLabel")
            ic.AnchorPoint = Vector2.new(0.5, 0.5)
            ic.Position = UDim2.fromScale(0.5, 0.5)
            ic.Size = UDim2.fromOffset(math.floor(size * 0.55), math.floor(size * 0.55))
            ic.BackgroundTransparency = 1
            ic.ImageColor3 = WHITE
            ic.ZIndex = 5
            ic.Parent = b
            loadIcon(ic, icon, WHITE)
            return b, ic
        end
        local cx = BW / 2
        local prevBtn = ctrlBtn(cx - 78, 40, "skip-back")
        local playWrap = Instance.new("Frame")
        playWrap.AnchorPoint = Vector2.new(0.5, 0.5)
        playWrap.Position = UDim2.fromOffset(cx, ctrlY)
        playWrap.Size = UDim2.fromOffset(58, 58)
        playWrap.BackgroundColor3 = WHITE
        playWrap.BorderSizePixel = 0
        playWrap.ZIndex = 4
        playWrap.Parent = body
        Util.corner(playWrap, 29)
        local playBtn = Instance.new("TextButton")
        playBtn.Size = UDim2.fromScale(1, 1)
        playBtn.BackgroundTransparency = 1
        playBtn.AutoButtonColor = false
        playBtn.Text = ""
        playBtn.ZIndex = 5
        playBtn.Parent = playWrap
        local playIc = Instance.new("ImageLabel")
        playIc.AnchorPoint = Vector2.new(0.5, 0.5)
        playIc.Position = UDim2.fromScale(0.5, 0.5)
        playIc.Size = UDim2.fromOffset(26, 26)
        playIc.BackgroundTransparency = 1
        playIc.ImageColor3 = Color3.fromRGB(16, 16, 20)
        playIc.ZIndex = 6
        playIc.Parent = playWrap
        loadIcon(playIc, "play", Color3.fromRGB(16, 16, 20))
        local nextBtn = ctrlBtn(cx + 78, 40, "skip-forward")

        local isPlaying, curKey = false, ""

        local function control(method, path)
            task.spawn(function() spotify(method, path, token) end)
        end
        prevBtn.MouseButton1Click:Connect(function()
            control("POST", "/me/player/previous"); task.wait(0.4)
        end)
        nextBtn.MouseButton1Click:Connect(function()
            control("POST", "/me/player/next"); task.wait(0.4)
        end)
        playBtn.MouseButton1Click:Connect(function()
            if isPlaying then control("PUT", "/me/player/pause"); isPlaying = false; loadIcon(playIc, "play", Color3.fromRGB(16, 16, 20))
            else control("PUT", "/me/player/play"); isPlaying = true; loadIcon(playIc, "pause", Color3.fromRGB(16, 16, 20)) end
        end)

        -- poll now-playing
        pollAlive = true
        task.spawn(function()
            -- name in the header from /me
            local meBody = spotify("GET", "/me", token)
            if meBody and gui.Parent then
                local ok, me = pcall(function() return HttpService:JSONDecode(meBody) end)
                if ok and me and me.display_name then hSub.Text = me.display_name end
            end
            while pollAlive and gui.Parent do
                local b, status = spotify("GET", "/me/player/currently-playing", token)
                if status == 200 and b and b ~= "" then
                    local ok, data = pcall(function() return HttpService:JSONDecode(b) end)
                    if ok and data and data.item then
                        local it = data.item
                        track.Text = it.name or "Unknown"
                        local names = {}
                        for _, a in ipairs(it.artists or {}) do names[#names + 1] = a.name end
                        artist.Text = table.concat(names, ", ")
                        tCur.Text = mmss(data.progress_ms)
                        tEnd.Text = mmss(it.duration_ms)
                        local frac = (it.duration_ms and it.duration_ms > 0) and (data.progress_ms / it.duration_ms) or 0
                        Util.tween(barFill, { Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0) }, 0.4)
                        isPlaying = data.is_playing and true or false
                        loadIcon(playIc, isPlaying and "pause" or "play", Color3.fromRGB(16, 16, 20))
                        local imgs = it.album and it.album.images
                        if imgs and imgs[1] and it.id ~= curKey then
                            curKey = it.id
                            loadArt(art, imgs[1].url, it.id)
                        end
                    end
                elseif status == 204 then
                    track.Text = "Nothing playing"
                    artist.Text = "Open Spotify and press play"
                    Util.tween(barFill, { Size = UDim2.new(0, 0, 1, 0) }, 0.3)
                elseif status == 401 then
                    Util.save(TOKEN_KEY, "")
                    showConnect("Your Spotify session expired. Paste a new token.")
                    return
                end
                task.wait(3)
            end
        end)
    end

    -- + button: pick a music source (Spotify is the main screen)
    local menu = Instance.new("Frame")
    menu.AnchorPoint = Vector2.new(1, 0)
    menu.Position = UDim2.fromOffset(cardW - 20, TB + 50)
    menu.Size = UDim2.fromOffset(196, 128)
    menu.BackgroundColor3 = CARD
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.ZIndex = 20
    menu.Parent = win
    Util.corner(menu, 10)
    Util.stroke(menu, WHITE, 1, 0.85)
    Util.shadow(menu, { blur = 30, transparency = 0.4, offset = UDim2.fromOffset(0, 8) })
    local function menuItem(y, label, icon, cb)
        local it = Instance.new("TextButton")
        it.Position = UDim2.fromOffset(6, y)
        it.Size = UDim2.fromOffset(184, 36)
        it.BackgroundColor3 = Color3.fromRGB(44, 44, 52)
        it.BackgroundTransparency = 1
        it.AutoButtonColor = false
        it.Text = ""
        it.ZIndex = 21
        it.Parent = menu
        Util.corner(it, 7)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(16, 16); ic.Position = UDim2.fromOffset(12, 10)
        ic.BackgroundTransparency = 1; ic.ImageColor3 = WHITE; ic.ZIndex = 22; ic.Parent = it
        loadIcon(ic, icon, WHITE)
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(38, 0); t.Size = UDim2.fromOffset(140, 36)
        t.BackgroundTransparency = 1; t.Font = Theme.fonts.body; t.Text = label
        t.TextSize = 14; t.TextColor3 = WHITE; t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 22; t.Parent = it
        it.MouseEnter:Connect(function() Util.tween(it, { BackgroundTransparency = 0.4 }, 0.1) end)
        it.MouseLeave:Connect(function() Util.tween(it, { BackgroundTransparency = 1 }, 0.1) end)
        it.MouseButton1Click:Connect(function() menu.Visible = false; cb() end)
    end
    menuItem(6, "Spotify", "music", function() end)
    menuItem(44, "MP3 Player", "disc-3", function() Music.openMP3() end)
    menuItem(84, "YouTube", "youtube", function() hSub.Text = "YouTube coming soon" end)

    plus.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
    win.MouseButton1Click:Connect(function() if menu.Visible then menu.Visible = false end end)

    -- open: reconnect with a saved token, else show connect
    local saved = Util.load(TOKEN_KEY)
    if saved and saved ~= "" then
        showConnect() -- render immediately, then verify + swap to player
        task.spawn(function()
            local _, status = spotify("GET", "/me", saved)
            if status == 200 and gui.Parent then showPlayer(saved) end
        end)
    else
        showConnect()
    end

    return { close = close }
end

return Music
