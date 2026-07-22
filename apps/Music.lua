-- SYNC / apps / Music
-- A music app with three sources, one look. The centrepiece is a "now playing"
-- hero: a big album cover, the title, a draggable scrubber and large controls.
--   Local  - plays mp3/ogg files from SYNC/songs. Local files have no cover art,
--            so each track gets a procedural gradient cover keyed to its name.
--   Spotify- a remote for your real Spotify (paste an OAuth token). Same hero,
--            driven by the Spotify Web API with real album art.
--   YouTube- search or paste a link, download the audio into SYNC/songs.
--
-- Music.open() -> builds the window (a single instance).

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local WM    = SYNC.import("os/WindowManager")

local Music = {}

local _req = (syn and syn.request) or (http and http.request) or http_request or request

local WHITE  = Color3.fromRGB(244, 244, 248)
local SUB    = Color3.fromRGB(150, 150, 158)
local DIM    = Color3.fromRGB(105, 105, 113)
local WIN    = Color3.fromRGB(15, 15, 18)
local BAR    = Color3.fromRGB(28, 28, 32)
local FIELD  = Color3.fromRGB(20, 21, 26)
local CARD   = Color3.fromRGB(24, 25, 30)
local BLUE   = Color3.fromRGB(46, 72, 117)
local BLUEH  = Color3.fromRGB(58, 88, 140)
local LINK   = Color3.fromRGB(74, 135, 225)
local RED    = Color3.fromRGB(230, 66, 74)
local SPOT   = Color3.fromRGB(30, 215, 96)
local LOCAL_ACCENT = Color3.fromRGB(126, 110, 248)

local TOKEN_KEY = "SpotifyToken"
local API = "https://api.spotify.com/v1"
-- Our own audio backend (Railway). Public transcoders all died, so YouTube
-- audio is fetched from here: GET /audio?v=<id> streams back an mp3.
-- Override at runtime with Util.save("MusicApiUrl", "https://...") without a rebuild.
local MUSIC_API = "https://sync-music-production-0fe9.up.railway.app"

local SND_DIR = "SYNC/songs"
local AUDIO_EXT = { mp3 = true, ogg = true, wav = true }

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
local function fmtSec(s) s = math.max(0, math.floor(s or 0)); return ("%d:%02d"):format(math.floor(s / 60), s % 60) end

Music._gui = nil

-- ============================================================================
-- Procedural cover art. Local files carry no artwork, so we hash the track name
-- into a stable two-tone gradient - every song gets its own colourful cover.
-- ============================================================================
local function hashStr(s)
    local h = 0
    s = tostring(s or "song"):lower()
    for i = 1, #s do h = (h * 31 + s:byte(i)) % 1000003 end
    return h
end

local function procColors(name)
    local h = hashStr(name)
    local base = (h % 360) / 360
    local c1 = Color3.fromHSV(base, 0.55, 0.94)
    local c2 = Color3.fromHSV((base + 0.09 + (h % 17) / 120) % 1, 0.74, 0.58)
    return c1, c2
end

-- a small gradient cover tile (used in library rows). Returns frame, setColors.
local function makeCover(parent, size, radius, zbase)
    local f = Instance.new("Frame")
    f.Size = UDim2.fromOffset(size, size)
    f.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    f.BorderSizePixel = 0
    f.ZIndex = zbase
    f.Parent = parent
    Util.corner(f, radius or math.floor(size * 0.24))
    local g = Instance.new("UIGradient"); g.Rotation = 120; g.Parent = f
    local glyph = Instance.new("ImageLabel")
    glyph.AnchorPoint = Vector2.new(0.5, 0.5); glyph.Position = UDim2.fromScale(0.5, 0.5)
    glyph.Size = UDim2.fromOffset(math.floor(size * 0.5), math.floor(size * 0.5))
    glyph.BackgroundTransparency = 1; glyph.ImageColor3 = WHITE; glyph.ImageTransparency = 0.15
    glyph.ZIndex = zbase + 1; glyph.Parent = f
    loadIcon(glyph, "music", WHITE)
    local function setColors(c1, c2) g.Color = ColorSequence.new(c1, c2 or Color3.fromRGB(22, 22, 28)) end
    return f, setColors
end

-- a click+drag slider parented to `parent` at (x,y). Returns setFrac, isDragging.
local function makeSlider(parent, x, y, w, h, onSet, zbase, fillColor)
    zbase = zbase or 3
    local track = Instance.new("TextButton")
    track.Text = ""; track.AutoButtonColor = false
    track.Position = UDim2.fromOffset(x, y); track.Size = UDim2.fromOffset(w, h)
    track.BackgroundColor3 = Color3.fromRGB(58, 59, 68); track.BorderSizePixel = 0
    track.ZIndex = zbase; track.Parent = parent
    Util.corner(track, h / 2)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = fillColor or LOCAL_ACCENT; fill.BorderSizePixel = 0
    fill.ZIndex = zbase + 1; fill.Parent = track
    Util.corner(fill, h / 2)
    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Position = UDim2.fromScale(0, 0.5)
    knob.Size = UDim2.fromOffset(h + 7, h + 7); knob.BackgroundColor3 = Color3.fromRGB(246, 246, 250)
    knob.BorderSizePixel = 0; knob.ZIndex = zbase + 2; knob.Parent = track
    Util.corner(knob, (h + 7) / 2)
    local function setFrac(f)
        f = math.clamp(f, 0, 1)
        fill.Size = UDim2.new(f, 0, 1, 0); knob.Position = UDim2.new(f, 0, 0.5, 0)
    end
    local dragging = false
    local function fx(px) return math.clamp((px - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1) end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; local f = fx(inp.Position.X); setFrac(f); if onSet then onSet(f) end
            Util.tween(knob, { Size = UDim2.fromOffset(h + 12, h + 12) }, 0.1)
        end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false; Util.tween(knob, { Size = UDim2.fromOffset(h + 7, h + 7) }, 0.12)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local f = fx(inp.Position.X); setFrac(f); if onSet then onSet(f) end
        end
    end)
    return setFrac, function() return dragging end
end

-- soft fade strip over a scroll edge (content dissolves into the window bg)
local function scrollFade(parent, x, y, w, h, bottom, bg)
    local f = Instance.new("Frame")
    f.Position = UDim2.fromOffset(x, y); f.Size = UDim2.fromOffset(w, h)
    f.BackgroundColor3 = bg or Color3.fromRGB(14, 14, 17)
    f.BorderSizePixel = 0; f.Active = false; f.ZIndex = 9; f.Parent = parent
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = bottom
        and NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
    g.Parent = f
    return f
end

-- ============================================================================
-- THE HERO. A now-playing panel shared by Local and Spotify: colored ambient
-- wash, big cover (gradient or real image), title, subtitle, draggable scrubber,
-- prev / play / next. buildHero(parent, W, opts) -> handle. opts callbacks:
-- onPrev, onNext, onToggle(wantPlay), onSeek(frac).
-- ============================================================================
local HERO_H = 330

local function buildHero(parent, W, opts)
    opts = opts or {}
    local accent = opts.accent or LOCAL_ACCENT

    -- ambient colored wash across the top, fading down into the window
    local wash = Instance.new("Frame")
    wash.Size = UDim2.fromOffset(W, HERO_H + 30)
    wash.BackgroundColor3 = accent
    wash.BackgroundTransparency = 0.8
    wash.BorderSizePixel = 0
    wash.ZIndex = 3
    wash.Parent = parent
    local washG = Instance.new("UIGradient")
    washG.Rotation = 90
    washG.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.68),
        NumberSequenceKeypoint.new(0.5, 0.9),
        NumberSequenceKeypoint.new(1, 1),
    })
    washG.Parent = wash

    -- cover
    local cover = Instance.new("Frame")
    cover.AnchorPoint = Vector2.new(0.5, 0)
    cover.Position = UDim2.fromOffset(W / 2, 14)
    cover.Size = UDim2.fromOffset(176, 176)
    cover.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    cover.BorderSizePixel = 0
    cover.ZIndex = 5
    cover.Parent = parent
    Util.corner(cover, 18)
    Util.shadow(cover, { blur = 42, spread = 0, transparency = 0.42, offset = UDim2.fromOffset(0, 14) })
    local coverGrad = Instance.new("UIGradient")
    coverGrad.Rotation = 125
    coverGrad.Color = ColorSequence.new(accent, Color3.fromRGB(20, 20, 26))
    coverGrad.Parent = cover
    local coverImg = Instance.new("ImageLabel")
    coverImg.Size = UDim2.fromScale(1, 1); coverImg.BackgroundTransparency = 1
    coverImg.ScaleType = Enum.ScaleType.Crop; coverImg.ImageTransparency = 1
    coverImg.ZIndex = 6; coverImg.Parent = cover
    Util.corner(coverImg, 18)
    local glyph = Instance.new("ImageLabel")
    glyph.AnchorPoint = Vector2.new(0.5, 0.5); glyph.Position = UDim2.fromScale(0.5, 0.5)
    glyph.Size = UDim2.fromOffset(60, 60); glyph.BackgroundTransparency = 1
    glyph.ImageColor3 = WHITE; glyph.ImageTransparency = 0.12; glyph.ZIndex = 7; glyph.Parent = cover
    loadIcon(glyph, "music", WHITE)

    -- title + subtitle
    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0); title.Position = UDim2.fromOffset(W / 2, 200)
    title.Size = UDim2.fromOffset(W - 56, 26); title.BackgroundTransparency = 1
    title.Font = Theme.fonts.title; title.Text = opts.title or "Nothing playing"
    title.TextSize = 21; title.TextColor3 = WHITE
    title.TextTruncate = Enum.TextTruncate.AtEnd; title.ZIndex = 5; title.Parent = parent

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0); sub.Position = UDim2.fromOffset(W / 2, 229)
    sub.Size = UDim2.fromOffset(W - 80, 18); sub.BackgroundTransparency = 1
    sub.Font = Theme.fonts.body; sub.Text = opts.sub or ""
    sub.TextSize = 13; sub.TextColor3 = SUB
    sub.TextTruncate = Enum.TextTruncate.AtEnd; sub.ZIndex = 5; sub.Parent = parent

    -- scrubber
    local scrubY = 262
    local tCur = Instance.new("TextLabel")
    tCur.Position = UDim2.fromOffset(44, scrubY + 9); tCur.Size = UDim2.fromOffset(50, 14)
    tCur.BackgroundTransparency = 1; tCur.Font = Theme.fonts.caption; tCur.Text = "0:00"
    tCur.TextSize = 11; tCur.TextColor3 = DIM; tCur.TextXAlignment = Enum.TextXAlignment.Left
    tCur.ZIndex = 5; tCur.Parent = parent
    local tEnd = Instance.new("TextLabel")
    tEnd.AnchorPoint = Vector2.new(1, 0); tEnd.Position = UDim2.fromOffset(W - 44, scrubY + 9); tEnd.Size = UDim2.fromOffset(50, 14)
    tEnd.BackgroundTransparency = 1; tEnd.Font = Theme.fonts.caption; tEnd.Text = "0:00"
    tEnd.TextSize = 11; tEnd.TextColor3 = DIM; tEnd.TextXAlignment = Enum.TextXAlignment.Right
    tEnd.ZIndex = 5; tEnd.Parent = parent
    local setScrub, scrubDrag = makeSlider(parent, 44, scrubY, W - 88, 5, function(f)
        if opts.onSeek then opts.onSeek(f) end
    end, 5, accent)

    -- controls
    local ctrlY = 302
    local function iconBtn(cx, size, icon)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(0.5, 0.5); b.Position = UDim2.fromOffset(cx, ctrlY)
        b.Size = UDim2.fromOffset(size + 16, size + 16); b.BackgroundTransparency = 1
        b.AutoButtonColor = false; b.Text = ""; b.ZIndex = 5; b.Parent = parent
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(0.5, 0.5); ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.Size = UDim2.fromOffset(size, size); ic.BackgroundTransparency = 1
        ic.ImageColor3 = Color3.fromRGB(228, 228, 234); ic.ZIndex = 6; ic.Parent = b
        loadIcon(ic, icon, Color3.fromRGB(228, 228, 234))
        b.MouseEnter:Connect(function() Util.tween(ic, { ImageColor3 = WHITE }, 0.1) end)
        b.MouseLeave:Connect(function() Util.tween(ic, { ImageColor3 = Color3.fromRGB(228, 228, 234) }, 0.1) end)
        return b, ic
    end
    local cx = W / 2
    local prevBtn = iconBtn(cx - 80, 26, "skip-back")
    local nextBtn = iconBtn(cx + 80, 26, "skip-forward")
    local playWrap = Instance.new("Frame")
    playWrap.AnchorPoint = Vector2.new(0.5, 0.5); playWrap.Position = UDim2.fromOffset(cx, ctrlY)
    playWrap.Size = UDim2.fromOffset(60, 60); playWrap.BackgroundColor3 = WHITE
    playWrap.BorderSizePixel = 0; playWrap.ZIndex = 5; playWrap.Parent = parent
    Util.corner(playWrap, 30)
    Util.shadow(playWrap, { blur = 26, spread = 0, transparency = 0.5, offset = UDim2.fromOffset(0, 5) })
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.fromScale(1, 1); playBtn.BackgroundTransparency = 1
    playBtn.AutoButtonColor = false; playBtn.Text = ""; playBtn.ZIndex = 6; playBtn.Parent = playWrap
    local playIc = Instance.new("ImageLabel")
    playIc.AnchorPoint = Vector2.new(0.5, 0.5); playIc.Position = UDim2.fromScale(0.53, 0.5)
    playIc.Size = UDim2.fromOffset(26, 26); playIc.BackgroundTransparency = 1
    playIc.ImageColor3 = Color3.fromRGB(16, 16, 20); playIc.ZIndex = 7; playIc.Parent = playWrap
    loadIcon(playIc, "play", Color3.fromRGB(16, 16, 20))

    local playing = false
    prevBtn.MouseButton1Click:Connect(function() if opts.onPrev then opts.onPrev() end end)
    nextBtn.MouseButton1Click:Connect(function() if opts.onNext then opts.onNext() end end)
    playBtn.MouseButton1Click:Connect(function() if opts.onToggle then opts.onToggle(not playing) end end)
    playBtn.MouseButton1Down:Connect(function() Util.tween(playWrap, { Size = UDim2.fromOffset(55, 55) }, 0.08) end)
    playBtn.MouseButton1Up:Connect(function() Util.tween(playWrap, { Size = UDim2.fromOffset(60, 60) }, 0.12) end)

    local handle = { height = HERO_H, cover = cover }
    function handle.setTitle(t) title.Text = t or "" end
    function handle.setSub(t) sub.Text = t or "" end
    function handle.setColors(c1, c2)
        coverGrad.Color = ColorSequence.new(c1, c2 or Color3.fromRGB(20, 20, 26))
        Util.tween(coverImg, { ImageTransparency = 1 }, 0.2)
        Util.tween(glyph, { ImageTransparency = 0.12 }, 0.2)
        Util.tween(wash, { BackgroundColor3 = c1 }, 0.45)
    end
    function handle.loadImage(url, key)
        task.spawn(function()
            local png = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode(url) .. "&output=png&w=300&h=300&fit=cover"
            local id = Util.remoteImage(png, key .. ".png")
            if id and coverImg.Parent then
                coverImg.Image = id
                Util.tween(coverImg, { ImageTransparency = 0 }, 0.35)
                Util.tween(glyph, { ImageTransparency = 1 }, 0.25)
            end
        end)
    end
    function handle.setProgress(frac, cur, endd)
        if not scrubDrag() then setScrub(math.clamp(frac or 0, 0, 1)) end
        if cur then tCur.Text = cur end
        if endd then tEnd.Text = endd end
    end
    function handle.setPlaying(p)
        playing = p and true or false
        loadIcon(playIc, playing and "pause" or "play", Color3.fromRGB(16, 16, 20))
    end
    return handle
end

-- ============================================================================
-- YOUTUBE download plumbing (search via Piped, audio via our backend).
-- ============================================================================
local PIPED = {
    "https://api.piped.private.coffee",
    "https://pipedapi.adminforge.de",
    "https://pipedapi.kavin.rocks",
    "https://pipedapi.reallyaweso.me",
}
local function musicApiBase()
    local saved = Util.load and Util.load("MusicApiUrl")
    if saved and #tostring(saved) > 8 then return (tostring(saved):gsub("/+$", "")) end
    return (MUSIC_API:gsub("/+$", ""))
end
local function backendReady() return not musicApiBase():find("REPLACE") end

local function ytId(url)
    url = tostring(url)
    return url:match("[?&]v=([%w%-_]+)") or url:match("youtu%.be/([%w%-_]+)")
        or url:match("/watch%?v=([%w%-_]+)") or url:match("/embed/([%w%-_]+)")
        or url:match("/shorts/([%w%-_]+)") or url:match("^([%w%-_]+)$")
end

local function ytSearch(q)
    for _, inst in ipairs(PIPED) do
        local b = Util.httpGetH(inst .. "/search?q=" .. HttpService:UrlEncode(q) .. "&filter=videos", {})
        if b then
            local ok, d = pcall(function() return HttpService:JSONDecode(b) end)
            if ok and d and d.items and #d.items > 0 then return d.items end
        end
    end
    return nil
end

-- pull mp3 bytes for a youtube id from our backend. Returns bytes or nil, err.
local function ytDownload(id)
    if not backendReady() then return nil, "backend not set up yet" end
    local url = musicApiBase() .. "/audio?v=" .. id
    local MIN = 40000 -- ~2s of audio; below this it's a stub or an error blob
    local lastErr = "no audio"
    for attempt = 1, 3 do
        if _req then
            local ok, res = pcall(_req, { Url = url, Method = "GET" })
            if ok and res then
                local code = res.StatusCode or (res.Success and 200) or 0
                if code == 200 and res.Body and #res.Body > MIN then return res.Body end
                if code ~= 0 and code ~= 200 then lastErr = "server " .. tostring(code) end
            end
        end
        local ok2, data = pcall(function() return game:HttpGet(url, true) end)
        if ok2 and data and #data > MIN then return data end
        if attempt < 3 then task.wait(1.5) end
    end
    return nil, lastErr
end

local function safeName(s)
    return (tostring(s):gsub("[^%w%s%-_%.]", ""):gsub("%s+", " "):sub(1, 60))
end

-- ============================================================================
-- LOCAL tab: the hero + a searchable library of files in SYNC/songs. Playback
-- lives in `audio` (passed from Music.open) so it keeps going across tab
-- switches. buildLocal(parent, W, H, setSub, audio) -> cleanup().
-- ============================================================================
local function buildLocal(parent, W, H, setSub, audio)
    pcall(function()
        if type(makefolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder(SND_DIR) then makefolder(SND_DIR) end
        end
    end)
    setSub("Local library")
    local alive = true
    local rows = {}
    local function nameOf(p) return ((p:match("([^/\\]+)$") or p):gsub("%.%w+$", "")) end

    local playAt -- forward

    local hero = buildHero(parent, W, {
        accent = LOCAL_ACCENT,
        title = "Nothing playing",
        sub = "Pick a song below",
        onPrev = function() if #audio.view > 0 then playAt(audio.index - 1) end end,
        onNext = function() if #audio.view > 0 then playAt(audio.index + 1) end end,
        onToggle = function(wantPlay)
            if not audio.sound then if #audio.view > 0 then playAt(audio.index == 0 and 1 or audio.index) end return end
            if wantPlay then audio.sound:Resume(); audio.playing = true; hero.setPlaying(true)
            else audio.sound:Pause(); audio.playing = false; hero.setPlaying(false) end
        end,
        onSeek = function(f) if audio.sound and audio.sound.TimeLength > 0 then audio.sound.TimePosition = f * audio.sound.TimeLength end end,
    })

    -- ---- library section ----
    local libY = hero.height + 8

    local search = Instance.new("Frame")
    search.Position = UDim2.fromOffset(16, libY); search.Size = UDim2.fromOffset(W - 32 - 40, 32)
    search.BackgroundColor3 = FIELD; search.BorderSizePixel = 0; search.ZIndex = 5; search.Parent = parent
    Util.corner(search, 9); local sst = Util.stroke(search, Color3.fromRGB(70, 70, 82), 1, 0.55)
    local sIco = Instance.new("ImageLabel")
    sIco.Position = UDim2.fromOffset(11, 8); sIco.Size = UDim2.fromOffset(15, 15); sIco.BackgroundTransparency = 1
    sIco.ImageColor3 = DIM; sIco.ZIndex = 6; sIco.Parent = search
    loadIcon(sIco, "search", DIM)
    local sBox = Instance.new("TextBox")
    sBox.Position = UDim2.fromOffset(34, 0); sBox.Size = UDim2.fromOffset(W - 32 - 40 - 44, 32)
    sBox.BackgroundTransparency = 1; sBox.Font = Theme.fonts.body
    sBox.PlaceholderText = "Search your library"; sBox.PlaceholderColor3 = DIM
    sBox.Text = ""; sBox.TextSize = 13; sBox.TextColor3 = WHITE; sBox.TextXAlignment = Enum.TextXAlignment.Left
    sBox.ClearTextOnFocus = false; sBox.ZIndex = 6; sBox.Parent = search
    sBox.Focused:Connect(function() Util.tween(sst, { Transparency = 0.1, Color = LOCAL_ACCENT }, 0.15) end)
    sBox.FocusLost:Connect(function() Util.tween(sst, { Transparency = 0.55, Color = Color3.fromRGB(70, 70, 82) }, 0.15) end)

    local refresh = Instance.new("TextButton")
    refresh.Position = UDim2.fromOffset(W - 48, libY); refresh.Size = UDim2.fromOffset(32, 32)
    refresh.BackgroundColor3 = FIELD; refresh.AutoButtonColor = false; refresh.Text = ""
    refresh.BorderSizePixel = 0; refresh.ZIndex = 5; refresh.Parent = parent
    Util.corner(refresh, 9); Util.stroke(refresh, Color3.fromRGB(70, 70, 82), 1, 0.55)
    local rIco = Instance.new("ImageLabel")
    rIco.AnchorPoint = Vector2.new(0.5, 0.5); rIco.Position = UDim2.fromScale(0.5, 0.5); rIco.Size = UDim2.fromOffset(15, 15)
    rIco.BackgroundTransparency = 1; rIco.ImageColor3 = SUB; rIco.ZIndex = 6; rIco.Parent = refresh
    loadIcon(rIco, "refresh-cw", SUB)

    local listY = libY + 40
    local listH = H - listY - 6
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(12, listY); scroll.Size = UDim2.fromOffset(W - 24, listH)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 92)
    scroll.ScrollBarImageTransparency = 0.4; scroll.CanvasSize = UDim2.new(); scroll.ZIndex = 4; scroll.Parent = parent
    local lpad = Instance.new("UIPadding")
    lpad.PaddingLeft = UDim.new(0, 6); lpad.PaddingRight = UDim.new(0, 6); lpad.PaddingTop = UDim.new(0, 2); lpad.Parent = scroll
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 6); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = scroll
    Util.autoCanvas(scroll, "Y")
    scrollFade(parent, 12, listY, W - 24, 14, false)
    scrollFade(parent, 12, listY + listH - 14, W - 24, 14, true)
    local empty = Instance.new("TextLabel")
    empty.AnchorPoint = Vector2.new(0.5, 0); empty.Position = UDim2.fromScale(0.5, 0.3)
    empty.Size = UDim2.fromOffset(W - 90, 40); empty.BackgroundTransparency = 1
    empty.Font = Theme.fonts.caption; empty.Text = "No songs yet. Download from the YouTube tab, or drop .mp3 files into SYNC/songs and hit refresh."
    empty.TextSize = 12.5; empty.TextColor3 = SUB; empty.TextWrapped = true; empty.ZIndex = 4; empty.Parent = scroll

    -- shared equalizer, reparented onto the active row while playing
    local eq = Instance.new("Frame")
    eq.AnchorPoint = Vector2.new(1, 0.5); eq.Position = UDim2.new(1, -14, 0.5, 0)
    eq.Size = UDim2.fromOffset(18, 16); eq.BackgroundTransparency = 1; eq.ZIndex = 6; eq.Visible = false
    local eqBars = {}
    for i = 1, 3 do
        local b = Instance.new("Frame")
        b.AnchorPoint = Vector2.new(0.5, 1); b.Position = UDim2.new((i - 0.5) / 3, 0, 1, 0)
        b.Size = UDim2.fromOffset(3, 6); b.BackgroundColor3 = LOCAL_ACCENT; b.BorderSizePixel = 0
        b.ZIndex = 6; b.Parent = eq; Util.corner(b, 1); eqBars[i] = b
    end
    task.spawn(function()
        while alive do
            if eq.Visible and audio.playing then
                for _, b in ipairs(eqBars) do Util.tween(b, { Size = UDim2.fromOffset(3, math.random(4, 15)) }, 0.22) end
            end
            task.wait(0.24)
        end
    end)

    local function highlight()
        local active
        for _, r in ipairs(rows) do
            local on = (audio.view[audio.index] == r.path)
            Util.tween(r.frame, { BackgroundTransparency = on and 0.0 or 0.6 }, 0.12)
            r.accent.Visible = on
            r.dur.Visible = not on
            if on then active = r end
        end
        if active then
            local c1 = procColors(nameOf(active.path))
            for _, b in ipairs(eqBars) do b.BackgroundColor3 = c1 end
            eq.Parent = active.frame; eq.Visible = true
        else
            eq.Visible = false
        end
    end

    local function reflect()
        if audio.name ~= "" then hero.setTitle(audio.name); hero.setSub("Local file")
            hero.setColors(procColors(audio.name)) end
        hero.setPlaying(audio.playing)
        highlight()
    end

    function playAt(i)
        if #audio.view == 0 then return end
        audio.index = ((i - 1) % #audio.view) + 1
        if audio.sound then pcall(function() audio.sound:Stop(); audio.sound:Destroy() end); audio.sound = nil end
        local path = audio.view[audio.index]
        local ok, id = pcall(function() return getcustomasset(path) end)
        if not ok or not id then hero.setTitle("Could not load track"); return end
        local snd = Instance.new("Sound"); snd.SoundId = id; snd.Volume = 0.65
        snd.Parent = game:GetService("SoundService"); snd:Play()
        audio.sound = snd; audio.playing = true; audio.name = nameOf(path)
        hero.setTitle(audio.name); hero.setSub("Local file"); hero.setColors(procColors(audio.name))
        hero.setPlaying(true); highlight()
        snd.Ended:Connect(function() if audio.sound == snd then playAt(audio.index + 1) end end)
    end

    local function render(q)
        for _, r in ipairs(rows) do r.frame:Destroy() end
        rows = {}
        audio.view = {}
        q = (q or ""):lower()
        for _, path in ipairs(audio.files) do
            local nm = nameOf(path)
            if q == "" or nm:lower():find(q, 1, true) then
                audio.view[#audio.view + 1] = path
                local n = #audio.view
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -4, 0, 44); row.BackgroundColor3 = CARD; row.BackgroundTransparency = 0.6
                row.AutoButtonColor = false; row.Text = ""; row.BorderSizePixel = 0; row.LayoutOrder = n; row.ZIndex = 4; row.Parent = scroll
                Util.corner(row, 10)
                local accent = Instance.new("Frame")
                accent.AnchorPoint = Vector2.new(0, 0.5); accent.Position = UDim2.new(0, 0, 0.5, 0)
                accent.Size = UDim2.fromOffset(3, 24); accent.BackgroundColor3 = LOCAL_ACCENT
                accent.BorderSizePixel = 0; accent.Visible = false; accent.ZIndex = 6; accent.Parent = row
                Util.corner(accent, 2)
                local cv, setCv = makeCover(row, 30, 8, 5)
                cv.Position = UDim2.fromOffset(12, 7); setCv(procColors(nm))
                local rt = Instance.new("TextLabel")
                rt.Position = UDim2.fromOffset(52, 0); rt.Size = UDim2.fromOffset(W - 120, 44); rt.BackgroundTransparency = 1
                rt.Font = Theme.fonts.body; rt.Text = nm; rt.TextSize = 13.5; rt.TextColor3 = WHITE
                rt.TextXAlignment = Enum.TextXAlignment.Left; rt.TextTruncate = Enum.TextTruncate.AtEnd; rt.ZIndex = 5; rt.Parent = row
                local rd = Instance.new("TextLabel")
                rd.AnchorPoint = Vector2.new(1, 0.5); rd.Position = UDim2.new(1, -14, 0.5, 0); rd.Size = UDim2.fromOffset(44, 16)
                rd.BackgroundTransparency = 1; rd.Font = Theme.fonts.caption; rd.Text = ""
                rd.TextSize = 11; rd.TextColor3 = DIM; rd.TextXAlignment = Enum.TextXAlignment.Right; rd.ZIndex = 5; rd.Parent = row
                row.MouseEnter:Connect(function() if audio.view[audio.index] ~= path then Util.tween(row, { BackgroundTransparency = 0.4 }, 0.1) end end)
                row.MouseLeave:Connect(function() if audio.view[audio.index] ~= path then Util.tween(row, { BackgroundTransparency = 0.6 }, 0.1) end end)
                row.MouseButton1Click:Connect(function() playAt(n) end)
                rows[#rows + 1] = { frame = row, path = path, accent = accent, dur = rd }
            end
        end
        empty.Visible = (#audio.view == 0)
        highlight()
    end

    local function scan()
        audio.files = {}
        local ok, list = pcall(function() return listfiles(SND_DIR) end)
        if ok and list then
            for _, f in ipairs(list) do
                local ext = tostring(f):match("%.(%w+)$")
                if ext and AUDIO_EXT[ext:lower()] then audio.files[#audio.files + 1] = f end
            end
        end
        render(sBox.Text)
    end

    sBox:GetPropertyChangedSignal("Text"):Connect(function() render(sBox.Text) end)
    refresh.MouseButton1Click:Connect(function() Util.tween(rIco, { Rotation = rIco.Rotation + 360 }, 0.5); scan() end)

    -- progress loop for the hero
    task.spawn(function()
        while alive do
            if audio.sound and audio.sound.TimeLength and audio.sound.TimeLength > 0 then
                hero.setProgress(audio.sound.TimePosition / audio.sound.TimeLength, fmtSec(audio.sound.TimePosition), fmtSec(audio.sound.TimeLength))
            end
            task.wait(0.3)
        end
    end)

    scan()
    -- if something was already playing (came back to this tab), reflect it
    if audio.sound then reflect() end

    return function() alive = false end -- note: audio keeps playing across tab switches
end

-- ============================================================================
-- YOUTUBE tab: search / paste link -> results with a download button.
-- buildYT(parent, W, H, setSub) -> cleanup().
-- ============================================================================
local function buildYT(parent, W, H, setSub)
    pcall(function()
        if type(makefolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder(SND_DIR) then makefolder(SND_DIR) end
        end
    end)
    setSub("Search or paste a link")

    local sh = Instance.new("Frame")
    sh.Position = UDim2.fromOffset(16, 8); sh.Size = UDim2.fromOffset(W - 32, 40)
    sh.BackgroundColor3 = FIELD; sh.BorderSizePixel = 0; sh.ZIndex = 4; sh.Parent = parent
    Util.corner(sh, 11); local sst = Util.stroke(sh, Color3.fromRGB(70, 70, 82), 1, 0.5)
    local sBox = Instance.new("TextBox")
    sBox.Position = UDim2.fromOffset(16, 0); sBox.Size = UDim2.fromOffset(W - 32 - 56, 40)
    sBox.BackgroundTransparency = 1; sBox.Font = Theme.fonts.body
    sBox.PlaceholderText = "Search YouTube or paste a link..."; sBox.PlaceholderColor3 = DIM
    sBox.Text = ""; sBox.TextSize = 14; sBox.TextColor3 = WHITE
    sBox.TextXAlignment = Enum.TextXAlignment.Left; sBox.ClearTextOnFocus = false; sBox.ZIndex = 5; sBox.Parent = sh
    sBox.Focused:Connect(function() Util.tween(sst, { Transparency = 0.1, Color = RED }, 0.15) end)
    sBox.FocusLost:Connect(function() Util.tween(sst, { Transparency = 0.5, Color = Color3.fromRGB(70, 70, 82) }, 0.15) end)
    local sBtn = Instance.new("TextButton")
    sBtn.AnchorPoint = Vector2.new(1, 0.5); sBtn.Position = UDim2.new(1, -6, 0.5, 0)
    sBtn.Size = UDim2.fromOffset(38, 30); sBtn.BackgroundColor3 = RED; sBtn.AutoButtonColor = false
    sBtn.Text = ""; sBtn.BorderSizePixel = 0; sBtn.ZIndex = 5; sBtn.Parent = sh
    Util.corner(sBtn, 8)
    local sBtnIc = Instance.new("ImageLabel")
    sBtnIc.AnchorPoint = Vector2.new(0.5, 0.5); sBtnIc.Position = UDim2.fromScale(0.5, 0.5)
    sBtnIc.Size = UDim2.fromOffset(16, 16); sBtnIc.BackgroundTransparency = 1
    sBtnIc.ImageColor3 = WHITE; sBtnIc.ZIndex = 6; sBtnIc.Parent = sBtn
    loadIcon(sBtnIc, "search", WHITE)

    local listY = 56
    local listH = H - listY - 8
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(12, listY); scroll.Size = UDim2.fromOffset(W - 24, listH)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 92)
    scroll.ScrollBarImageTransparency = 0.4; scroll.CanvasSize = UDim2.new(); scroll.ZIndex = 4; scroll.Parent = parent
    local spad = Instance.new("UIPadding")
    spad.PaddingLeft = UDim.new(0, 6); spad.PaddingRight = UDim.new(0, 10); spad.PaddingTop = UDim.new(0, 4); spad.Parent = scroll
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
    Util.autoCanvas(scroll, "Y")
    scrollFade(parent, 12, listY, W - 24, 14, false)
    scrollFade(parent, 12, listY + listH - 14, W - 24, 14, true)
    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0); status.Position = UDim2.fromScale(0.5, 0.24)
    status.Size = UDim2.fromOffset(W - 80, 40); status.BackgroundTransparency = 1
    status.Font = Theme.fonts.caption; status.Text = "Search for a song or paste a YouTube link."
    status.TextSize = 13; status.TextColor3 = SUB; status.TextWrapped = true
    status.ZIndex = 4; status.Parent = scroll

    local function clearResults()
        for _, c in ipairs(scroll:GetChildren()) do
            if c ~= layout and c ~= status and c ~= spad then c:Destroy() end
        end
    end

    local cardW = W - 24 - 16
    local function resultCard(i, id, title, channel, dur)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, 0, 0, 64); c.BackgroundColor3 = CARD; c.BorderSizePixel = 0
        c.LayoutOrder = i; c.ZIndex = 4; c.Parent = scroll
        Util.corner(c, 11); Util.stroke(c, WHITE, 1, 0.92)
        local thumb = Instance.new("ImageLabel")
        thumb.Position = UDim2.fromOffset(8, 8); thumb.Size = UDim2.fromOffset(84, 48)
        thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36); thumb.BorderSizePixel = 0
        thumb.ScaleType = Enum.ScaleType.Crop; thumb.ZIndex = 5; thumb.Parent = c
        Util.corner(thumb, 7)
        task.spawn(function()
            local url = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode("i.ytimg.com/vi/" .. id .. "/mqdefault.jpg")
                .. "&output=png&w=168&h=94&fit=cover"
            local aid = Util.remoteImage(url, "yt_thumb_" .. id .. ".png")
            if aid and thumb.Parent then thumb.Image = aid end
        end)
        local t = Instance.new("TextLabel")
        t.Position = UDim2.fromOffset(102, 10); t.Size = UDim2.fromOffset(cardW - 102 - 48, 20)
        t.BackgroundTransparency = 1; t.Font = Theme.fonts.body; t.Text = title
        t.TextSize = 13; t.TextColor3 = WHITE; t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd; t.ZIndex = 5; t.Parent = c
        local sub = Instance.new("TextLabel")
        sub.Position = UDim2.fromOffset(102, 32); sub.Size = UDim2.fromOffset(cardW - 102 - 48, 16)
        sub.BackgroundTransparency = 1; sub.Font = Theme.fonts.caption
        sub.Text = channel .. (dur and dur > 0 and ("  \195\151  " .. ("%d:%02d"):format(math.floor(dur / 60), dur % 60)) or "")
        sub.TextSize = 11; sub.TextColor3 = SUB; sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd; sub.ZIndex = 5; sub.Parent = c
        local dl = Instance.new("TextButton")
        dl.AnchorPoint = Vector2.new(1, 0.5); dl.Position = UDim2.new(1, -12, 0.5, 0)
        dl.Size = UDim2.fromOffset(30, 30); dl.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
        dl.AutoButtonColor = false; dl.Text = ""; dl.BorderSizePixel = 0; dl.ZIndex = 5; dl.Parent = c
        Util.corner(dl, 8)
        local dlIc = Instance.new("ImageLabel")
        dlIc.AnchorPoint = Vector2.new(0.5, 0.5); dlIc.Position = UDim2.fromScale(0.5, 0.5)
        dlIc.Size = UDim2.fromOffset(15, 15); dlIc.BackgroundTransparency = 1
        dlIc.ImageColor3 = RED; dlIc.ZIndex = 6; dlIc.Parent = dl
        loadIcon(dlIc, "download", RED)
        dl.MouseEnter:Connect(function() Util.tween(dl, { BackgroundColor3 = Color3.fromRGB(54, 40, 42) }, 0.12) end)
        dl.MouseLeave:Connect(function() Util.tween(dl, { BackgroundColor3 = Color3.fromRGB(38, 38, 44) }, 0.12) end)

        local busy = false
        dl.MouseButton1Click:Connect(function()
            if busy then return end
            busy = true
            sub.Text = "Downloading audio..."; sub.TextColor3 = RED
            task.spawn(function()
                local data, err = ytDownload(id)
                if data then
                    pcall(function() writefile(SND_DIR .. "/" .. safeName(title) .. ".mp3", data) end)
                    sub.Text = "Downloaded - open the Local tab"; sub.TextColor3 = Color3.fromRGB(120, 210, 150)
                else
                    sub.Text = (err == "backend not set up yet") and "Audio download not set up yet"
                        or "Download failed, try again"
                    sub.TextColor3 = Color3.fromRGB(240, 160, 90)
                end
                busy = false
            end)
        end)
    end

    local searching = false
    local function doSearch()
        local q = sBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if q == "" or searching then return end
        searching = true
        clearResults()
        status.Text = "Searching..."; status.Visible = true
        task.spawn(function()
            local direct = ytId(q)
            if q:find("youtu") and direct then
                status.Visible = false
                resultCard(1, direct, "Video from link", "Tap download to save", 0)
                searching = false; return
            end
            local items = ytSearch(q)
            if not items then
                status.Text = "Couldn't reach search. Try again in a moment."
                searching = false; return
            end
            status.Visible = false
            local n = 0
            for _, it in ipairs(items) do
                local id = ytId(it.url or "")
                if id then
                    n = n + 1
                    resultCard(n, id, it.title or "Untitled", it.uploaderName or "Unknown", it.duration or 0)
                    if n >= 20 then break end
                end
            end
            if n == 0 then status.Text = "No results."; status.Visible = true end
            searching = false
        end)
    end
    sBtn.MouseButton1Click:Connect(doSearch)
    sBox.FocusLost:Connect(function(enter) if enter then doSearch() end end)

    return function() end
end

function Music.open()
    local host = (gethui and gethui()) or game:GetService("CoreGui")
    if host:FindFirstChild("SYNC_Music") then return end

    local cardW, cardH = 540, 620
    local TB = 38
    local HEADER = 78

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Music"
    Util.mount(gui)
    Music._gui = gui

    -- playback state that survives tab switches (only the window close stops it)
    local audio = { sound = nil, files = {}, view = {}, index = 0, playing = false, name = "" }

    local winRef, scaleRef, closing = nil, nil, false
    local function close()
        if closing then return end
        closing = true
        Music._gui = nil
        if audio.sound then pcall(function() audio.sound:Stop(); audio.sound:Destroy() end); audio.sound = nil end
        if winRef and scaleRef then
            Util.tween(scaleRef, { Scale = 0.94 }, 0.15)
            Util.tween(winRef, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.17, function() gui:Destroy() end)
        else
            gui:Destroy()
        end
    end

    Util.closeOnEscape(gui, close)

    local win = Instance.new("TextButton")
    win.Text = ""; win.AutoButtonColor = false
    win.AnchorPoint = Vector2.new(0.5, 0.5)
    win.Position = UDim2.fromScale(0.5, 0.5)
    win.Size = UDim2.fromOffset(cardW, cardH)
    win.BackgroundColor3 = WIN
    win.BackgroundTransparency = 0.02
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 16)
    Util.stroke(win, WHITE, 1, 0.9)
    Util.shadow(win, { blur = 55, spread = 0, transparency = 0.4, offset = UDim2.fromOffset(0, 22) })
    local winGrad = Instance.new("UIGradient")
    winGrad.Rotation = 120
    winGrad.Color = ColorSequence.new(Color3.fromRGB(22, 24, 32), Color3.fromRGB(12, 12, 15))
    winGrad.Parent = win
    WM.register(gui, win, 16)

    scaleRef = Instance.new("UIScale"); scaleRef.Scale = 0.94; scaleRef.Parent = win
    win.BackgroundTransparency = 1
    Util.tween(scaleRef, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    Util.tween(win, { BackgroundTransparency = 0.02 }, 0.18)
    winRef = win

    -- title bar (traffic lights only, draggable, red closes)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = BAR
    bar.BackgroundTransparency = 0.2
    bar.BorderSizePixel = 0
    bar.ZIndex = 8
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
        dot.ZIndex = 9
        dot.Parent = bar
        Util.corner(dot, 6)
        if i == 1 then dot.MouseButton1Click:Connect(close) end
    end
    Util.draggable(win, bar)
    Util.persistPosition(win, "MusicWin")

    -- header: wordmark (left) + status (right)
    local hIcon = Instance.new("ImageLabel")
    hIcon.Size = UDim2.fromOffset(19, 19); hIcon.Position = UDim2.fromOffset(20, TB + 11)
    hIcon.BackgroundTransparency = 1; hIcon.ImageColor3 = WHITE; hIcon.ZIndex = 5; hIcon.Parent = win
    loadIcon(hIcon, "music", WHITE)
    local hTitle = Instance.new("TextLabel")
    hTitle.Text = "Music"; hTitle.Position = UDim2.fromOffset(46, TB + 8); hTitle.Size = UDim2.fromOffset(160, 22)
    hTitle.BackgroundTransparency = 1; hTitle.Font = Theme.fonts.title; hTitle.TextSize = 17
    hTitle.TextColor3 = WHITE; hTitle.TextXAlignment = Enum.TextXAlignment.Left; hTitle.ZIndex = 5; hTitle.Parent = win
    local hSub = Instance.new("TextLabel")
    hSub.Text = ""; hSub.AnchorPoint = Vector2.new(1, 0.5); hSub.Position = UDim2.fromOffset(cardW - 20, TB + 18)
    hSub.Size = UDim2.fromOffset(230, 18); hSub.BackgroundTransparency = 1; hSub.Font = Theme.fonts.caption
    hSub.TextSize = 12; hSub.TextColor3 = SUB; hSub.TextXAlignment = Enum.TextXAlignment.Right
    hSub.TextTruncate = Enum.TextTruncate.AtEnd; hSub.ZIndex = 5; hSub.Parent = win
    local function setSub(t) hSub.Text = t end

    -- centered source tabs: Spotify / YouTube / Local
    local switchTab -- forward
    local tabDefs = {
        { key = "spotify", label = "Spotify", w = 58 },
        { key = "youtube", label = "YouTube", w = 66 },
        { key = "local",   label = "Local",   w = 46 },
    }
    local gap = 30
    local total = 0
    for _, td in ipairs(tabDefs) do total = total + td.w end
    total = total + gap * (#tabDefs - 1)
    local x = math.floor((cardW - total) / 2)
    local tabBtns = {}
    local tabY = TB + 40
    for _, td in ipairs(tabDefs) do
        local tb = Instance.new("TextButton")
        tb.Position = UDim2.fromOffset(x, tabY); tb.Size = UDim2.fromOffset(td.w, 26)
        tb.BackgroundTransparency = 1; tb.AutoButtonColor = false; tb.Font = Theme.fonts.title
        tb.Text = td.label; tb.TextSize = 14; tb.TextColor3 = SUB; tb.ZIndex = 5; tb.Parent = win
        local ul = Instance.new("Frame")
        ul.AnchorPoint = Vector2.new(0.5, 1); ul.Position = UDim2.new(0.5, 0, 1, 3)
        ul.Size = UDim2.fromOffset(td.w - 8, 2); ul.BackgroundColor3 = WHITE
        ul.BorderSizePixel = 0; ul.BackgroundTransparency = 1; ul.ZIndex = 5; ul.Parent = tb
        Util.corner(ul, 1)
        tabBtns[td.key] = { btn = tb, ul = ul }
        tb.MouseButton1Click:Connect(function() switchTab(td.key) end)
        x = x + td.w + gap
    end
    local tabLine = Instance.new("Frame")
    tabLine.Position = UDim2.fromOffset(0, TB + HEADER - 1); tabLine.Size = UDim2.new(1, 0, 0, 1)
    tabLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0); tabLine.BackgroundTransparency = 0.5
    tabLine.BorderSizePixel = 0; tabLine.ZIndex = 5; tabLine.Parent = win

    -- body container
    local body = Instance.new("Frame")
    body.Position = UDim2.fromOffset(0, TB + HEADER); body.Size = UDim2.fromOffset(cardW, cardH - TB - HEADER)
    body.BackgroundTransparency = 1; body.ClipsDescendants = true; body.ZIndex = 3; body.Parent = win
    local BW, BH = cardW, cardH - TB - HEADER

    local function clearBody() for _, c in ipairs(body:GetChildren()) do c:Destroy() end end

    local pollAlive = false
    local showConnect, showPlayer

    -- ================= SPOTIFY: CONNECT SCREEN =================
    showConnect = function(errMsg)
        pollAlive = false
        clearBody()
        setSub("")

        local disc = Instance.new("Frame")
        disc.AnchorPoint = Vector2.new(0.5, 0); disc.Position = UDim2.fromOffset(BW / 2, 40)
        disc.Size = UDim2.fromOffset(78, 78); disc.BackgroundColor3 = SPOT; disc.BorderSizePixel = 0
        disc.ZIndex = 5; disc.Parent = body
        Util.corner(disc, 39)
        local dg = Instance.new("UIGradient"); dg.Rotation = 120
        dg.Color = ColorSequence.new(Color3.fromRGB(52, 235, 120), Color3.fromRGB(24, 160, 74)); dg.Parent = disc
        Util.shadow(disc, { blur = 40, spread = 0, transparency = 0.5, offset = UDim2.fromOffset(0, 8), color = Color3.fromRGB(20, 120, 60) })
        local note = Instance.new("ImageLabel")
        note.AnchorPoint = Vector2.new(0.5, 0.5); note.Position = UDim2.fromScale(0.5, 0.5); note.Size = UDim2.fromOffset(38, 38)
        note.BackgroundTransparency = 1; note.ImageColor3 = Color3.fromRGB(12, 30, 18); note.ZIndex = 6; note.Parent = disc
        loadIcon(note, "music", Color3.fromRGB(12, 30, 18))

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 0); title.Position = UDim2.fromOffset(BW / 2, 132); title.Size = UDim2.fromOffset(BW, 26)
        title.BackgroundTransparency = 1; title.Font = Theme.fonts.title; title.Text = "Connect Spotify"
        title.TextSize = 21; title.TextColor3 = WHITE; title.ZIndex = 5; title.Parent = body
        local desc = Instance.new("TextLabel")
        desc.AnchorPoint = Vector2.new(0.5, 0); desc.Position = UDim2.fromOffset(BW / 2, 162); desc.Size = UDim2.fromOffset(BW - 60, 18)
        desc.BackgroundTransparency = 1; desc.Font = Theme.fonts.caption; desc.Text = "Paste your Spotify OAuth token to get started."
        desc.TextSize = 13; desc.TextColor3 = SUB; desc.TextWrapped = true; desc.ZIndex = 5; desc.Parent = body

        local holder = Instance.new("Frame")
        holder.Position = UDim2.fromOffset(34, 202); holder.Size = UDim2.fromOffset(BW - 68, 46)
        holder.BackgroundColor3 = FIELD; holder.BorderSizePixel = 0; holder.ClipsDescendants = true
        holder.ZIndex = 5; holder.Parent = body
        Util.corner(holder, 11)
        local st = Util.stroke(holder, Color3.fromRGB(70, 70, 82), 1, 0.55)
        local box = Instance.new("TextBox")
        box.Position = UDim2.fromOffset(18, 0); box.Size = UDim2.fromOffset(BW - 68 - 36, 46); box.BackgroundTransparency = 1
        box.Font = Theme.fonts.body; box.PlaceholderText = "Paste your Spotify token..."; box.PlaceholderColor3 = DIM
        box.Text = ""; box.TextSize = 14; box.TextColor3 = WHITE; box.TextXAlignment = Enum.TextXAlignment.Left
        box.ClearTextOnFocus = false; box.ZIndex = 6; box.Parent = holder
        box.Focused:Connect(function() Util.tween(st, { Transparency = 0.1, Color = SPOT }, 0.15) end)
        box.FocusLost:Connect(function() Util.tween(st, { Transparency = 0.55, Color = Color3.fromRGB(70, 70, 82) }, 0.15) end)

        local btn = Instance.new("TextButton")
        btn.Position = UDim2.fromOffset(34, 262); btn.Size = UDim2.fromOffset(BW - 68, 46); btn.BackgroundColor3 = Color3.fromRGB(30, 180, 84)
        btn.AutoButtonColor = false; btn.Font = Theme.fonts.title; btn.Text = "Connect"; btn.TextSize = 16
        btn.TextColor3 = Color3.fromRGB(9, 24, 15); btn.BorderSizePixel = 0; btn.ZIndex = 5; btn.Parent = body
        Util.corner(btn, 11)
        local bg = Instance.new("UIGradient"); bg.Rotation = 90
        bg.Color = ColorSequence.new(Color3.fromRGB(48, 220, 108), Color3.fromRGB(28, 176, 82)); bg.Parent = btn
        Util.shadow(btn, { blur = 24, spread = 0, transparency = 0.6, offset = UDim2.fromOffset(0, 6), color = Color3.fromRGB(20, 120, 60) })
        btn.MouseEnter:Connect(function() Util.tween(btn, { BackgroundColor3 = Color3.fromRGB(42, 208, 100) }, 0.12) end)
        btn.MouseLeave:Connect(function() Util.tween(btn, { BackgroundColor3 = Color3.fromRGB(30, 180, 84) }, 0.12) end)

        local link = Instance.new("TextButton")
        link.AnchorPoint = Vector2.new(0.5, 0); link.Position = UDim2.fromOffset(BW / 2, 320); link.Size = UDim2.fromOffset(BW, 20)
        link.BackgroundTransparency = 1; link.AutoButtonColor = false; link.Font = Theme.fonts.body
        link.Text = "How to get a token"; link.TextSize = 13; link.TextColor3 = SPOT; link.ZIndex = 5; link.Parent = body

        if errMsg then desc.Text = errMsg; desc.TextColor3 = Color3.fromRGB(255, 110, 120) end

        local connecting = false
        local function doConnect()
            local token = box.Text:gsub("%s+", ""):gsub("^Bearer ", "")
            if token == "" or connecting then return end
            connecting = true; btn.Text = "Connecting..."
            task.spawn(function()
                local _, status = spotify("GET", "/me", token)
                if status == 200 then
                    Util.save(TOKEN_KEY, token); showPlayer(token)
                else
                    btn.Text = "Connect"; connecting = false
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
            desc.Text = "Open the Spotify web player, then copy your Bearer access token from a request to api.spotify.com."
        end)
    end

    -- ================= SPOTIFY: PLAYER (hero) =================
    showPlayer = function(token)
        clearBody()
        setSub("Loading...")
        local lastDur = 0
        local hero = buildHero(body, BW, {
            accent = SPOT,
            title = "Nothing playing",
            sub = "Open Spotify and press play",
            onPrev = function() task.spawn(function() spotify("POST", "/me/player/previous", token) end) end,
            onNext = function() task.spawn(function() spotify("POST", "/me/player/next", token) end) end,
            onToggle = function(wantPlay)
                hero.setPlaying(wantPlay)
                task.spawn(function() spotify("PUT", wantPlay and "/me/player/play" or "/me/player/pause", token) end)
            end,
            onSeek = function(f)
                if lastDur > 0 then task.spawn(function() spotify("PUT", "/me/player/seek?position_ms=" .. math.floor(f * lastDur), token) end) end
            end,
        })
        hero.setColors(Color3.fromRGB(40, 180, 96), Color3.fromRGB(18, 90, 52))

        -- a small "playing from spotify" chip under the hero
        local chip = Instance.new("TextLabel")
        chip.AnchorPoint = Vector2.new(0.5, 0); chip.Position = UDim2.fromOffset(BW / 2, hero.height + 18)
        chip.Size = UDim2.fromOffset(BW, 18); chip.BackgroundTransparency = 1; chip.Font = Theme.fonts.caption
        chip.Text = "PLAYING FROM SPOTIFY"; chip.TextSize = 11; chip.TextColor3 = Color3.fromRGB(90, 180, 120)
        chip.ZIndex = 5; chip.Parent = body

        pollAlive = true
        task.spawn(function()
            local meBody = spotify("GET", "/me", token)
            if meBody and gui.Parent then
                local ok, me = pcall(function() return HttpService:JSONDecode(meBody) end)
                if ok and me and me.display_name then setSub(me.display_name) end
            end
            local curKey = ""
            while pollAlive and gui.Parent do
                local b, status = spotify("GET", "/me/player/currently-playing", token)
                if status == 200 and b and b ~= "" then
                    local ok, data = pcall(function() return HttpService:JSONDecode(b) end)
                    if ok and data and data.item then
                        local it = data.item
                        hero.setTitle(it.name or "Unknown")
                        local names = {}
                        for _, a in ipairs(it.artists or {}) do names[#names + 1] = a.name end
                        hero.setSub(table.concat(names, ", "))
                        lastDur = it.duration_ms or 0
                        local frac = (lastDur > 0) and (data.progress_ms / lastDur) or 0
                        hero.setProgress(frac, mmss(data.progress_ms), mmss(lastDur))
                        hero.setPlaying(data.is_playing and true or false)
                        local imgs = it.album and it.album.images
                        if imgs and imgs[1] and it.id ~= curKey then
                            curKey = it.id
                            hero.loadImage(imgs[1].url, "sp_art_" .. it.id)
                        end
                    end
                elseif status == 204 then
                    hero.setTitle("Nothing playing"); hero.setSub("Open Spotify and press play")
                    hero.setProgress(0, "0:00", "0:00")
                elseif status == 401 then
                    Util.save(TOKEN_KEY, ""); showConnect("Your Spotify session expired. Paste a new token."); return
                end
                task.wait(3)
            end
        end)
    end

    -- ===== tab switching =====
    local currentTab, currentCleanup = nil, nil
    local function setActiveTab(key)
        for k, t in pairs(tabBtns) do
            local active = (k == key)
            Util.tween(t.btn, { TextColor3 = active and WHITE or SUB }, 0.15)
            Util.tween(t.ul, { BackgroundTransparency = active and 0 or 1 }, 0.15)
        end
    end
    local function showSpotify()
        showConnect()
        local saved = Util.load(TOKEN_KEY)
        if saved and saved ~= "" then
            task.spawn(function()
                local _, status = spotify("GET", "/me", saved)
                if status == 200 and gui.Parent and currentTab == "spotify" then showPlayer(saved) end
            end)
        end
    end
    switchTab = function(key)
        if currentTab == key then return end
        if currentCleanup then pcall(currentCleanup); currentCleanup = nil end
        pollAlive = false
        currentTab = key
        clearBody()
        setActiveTab(key)
        if key == "spotify" then showSpotify()
        elseif key == "youtube" then currentCleanup = buildYT(body, BW, BH, setSub)
        elseif key == "local" then currentCleanup = buildLocal(body, BW, BH, setSub, audio) end
    end

    switchTab("local")

    return { close = close }
end

return Music
