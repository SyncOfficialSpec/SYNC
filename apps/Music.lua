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
local WM    = SYNC.import("os/WindowManager")

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
-- MP3 PLAYER (a tab): plays local audio dropped into SYNC/songs, via Sound +
-- getcustomasset. Has a search box, a scrollable song list, and a player bar.
-- buildMP3(parent, PW, PH, setSub) -> cleanup()
-- ============================================================================
local SND_DIR = "SYNC/songs"
local AUDIO_EXT = { mp3 = true, ogg = true, wav = true }
local BLUEP = Color3.fromRGB(58, 108, 210)

-- a click+drag slider parented to `parent` at (x,y). Returns setFrac, isDragging.
local function makeSlider(parent, x, y, w, h, onSet)
    local track = Instance.new("TextButton")
    track.Text = ""; track.AutoButtonColor = false
    track.Position = UDim2.fromOffset(x, y); track.Size = UDim2.fromOffset(w, h)
    track.BackgroundColor3 = Color3.fromRGB(52, 53, 62); track.BorderSizePixel = 0
    track.ZIndex = 3; track.Parent = parent
    Util.corner(track, h / 2)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0); fill.BackgroundColor3 = BLUEP; fill.BorderSizePixel = 0
    fill.ZIndex = 3; fill.Parent = track
    Util.corner(fill, h / 2)
    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Position = UDim2.fromScale(0, 0.5)
    knob.Size = UDim2.fromOffset(h + 8, h + 8); knob.BackgroundColor3 = Color3.fromRGB(245, 245, 248)
    knob.BorderSizePixel = 0; knob.ZIndex = 4; knob.Parent = track
    Util.corner(knob, (h + 8) / 2)
    local function setFrac(f)
        f = math.clamp(f, 0, 1)
        fill.Size = UDim2.new(f, 0, 1, 0); knob.Position = UDim2.new(f, 0, 0.5, 0)
    end
    local dragging = false
    local function fx(px) return math.clamp((px - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1) end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true; local f = fx(inp.Position.X); setFrac(f); if onSet then onSet(f) end
        end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
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
    f.BackgroundColor3 = bg or Color3.fromRGB(15, 15, 18)
    f.BorderSizePixel = 0; f.Active = false; f.ZIndex = 8; f.Parent = parent
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = bottom
        and NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
    g.Parent = f
    return f
end

local function buildMP3(parent, PW, PH, setSub)
    pcall(function()
        if type(makefolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder(SND_DIR) then makefolder(SND_DIR) end
        end
    end)
    setSub("MP3 Player")
    local alive, sound = true, nil
    local function stopSound() if sound then pcall(function() sound:Stop(); sound:Destroy() end); sound = nil end end

    -- search box
    local sh = Instance.new("Frame")
    sh.Position = UDim2.fromOffset(16, 6); sh.Size = UDim2.fromOffset(PW - 32, 34)
    sh.BackgroundColor3 = Color3.fromRGB(26, 27, 32); sh.BackgroundTransparency = 0; sh.BorderSizePixel = 0
    sh.ZIndex = 4; sh.Parent = parent
    Util.corner(sh, 9); local sst = Util.stroke(sh, Color3.fromRGB(70, 70, 80), 1, 0.5)
    local sBox = Instance.new("TextBox")
    sBox.Position = UDim2.fromOffset(14, 0); sBox.Size = UDim2.fromOffset(PW - 32 - 44, 34)
    sBox.BackgroundTransparency = 1; sBox.Font = Theme.fonts.body
    sBox.PlaceholderText = "Search your songs..."; sBox.PlaceholderColor3 = DIM
    sBox.Text = ""; sBox.TextSize = 13; sBox.TextColor3 = WHITE; sBox.TextXAlignment = Enum.TextXAlignment.Left
    sBox.ClearTextOnFocus = false; sBox.ZIndex = 5; sBox.Parent = sh
    local sIco = Instance.new("ImageLabel")
    sIco.AnchorPoint = Vector2.new(1, 0.5); sIco.Position = UDim2.new(1, -12, 0.5, 0); sIco.Size = UDim2.fromOffset(15, 15)
    sIco.BackgroundTransparency = 1; sIco.ImageColor3 = DIM; sIco.ZIndex = 5; sIco.Parent = sh
    loadIcon(sIco, "search", DIM)
    sBox.Focused:Connect(function() Util.tween(sst, { Transparency = 0.1, Color = BLUEP }, 0.15) end)
    sBox.FocusLost:Connect(function() Util.tween(sst, { Transparency = 0.6, Color = Color3.fromRGB(70, 70, 80) }, 0.15) end)

    -- song list
    local listY = 48
    local listH = PH - listY - 104
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(12, listY); scroll.Size = UDim2.fromOffset(PW - 24, listH)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.ScrollBarImageTransparency = 0.35; scroll.CanvasSize = UDim2.new(); scroll.ZIndex = 3; scroll.Parent = parent
    local lpad = Instance.new("UIPadding")
    lpad.PaddingLeft = UDim.new(0, 6); lpad.PaddingRight = UDim.new(0, 6); lpad.PaddingTop = UDim.new(0, 4); lpad.Parent = scroll
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 6); ll.SortOrder = Enum.SortOrder.LayoutOrder; ll.Parent = scroll
    Util.autoCanvas(scroll, "Y")
    scrollFade(parent, 12, listY, PW - 24, 16, false)
    scrollFade(parent, 12, listY + listH - 16, PW - 24, 16, true)
    local empty = Instance.new("TextLabel")
    empty.AnchorPoint = Vector2.new(0.5, 0); empty.Position = UDim2.fromScale(0.5, 0.22)
    empty.Size = UDim2.fromOffset(PW - 80, 40); empty.BackgroundTransparency = 1
    empty.Font = Theme.fonts.caption; empty.Text = "Drop .mp3 files into SYNC/songs, then Refresh."
    empty.TextSize = 13; empty.TextColor3 = SUB; empty.TextWrapped = true; empty.ZIndex = 3; empty.Parent = scroll

    -- player bar
    local barY = PH - 96
    local trackTxt = Instance.new("TextLabel")
    trackTxt.Position = UDim2.fromOffset(16, barY); trackTxt.Size = UDim2.fromOffset(PW - 200, 20)
    trackTxt.BackgroundTransparency = 1; trackTxt.Font = Theme.fonts.title; trackTxt.Text = "No Track"
    trackTxt.TextSize = 15; trackTxt.TextColor3 = WHITE; trackTxt.TextXAlignment = Enum.TextXAlignment.Left
    trackTxt.TextTruncate = Enum.TextTruncate.AtEnd; trackTxt.ZIndex = 3; trackTxt.Parent = parent
    -- volume (top-right of the bar)
    local volIco = Instance.new("ImageLabel")
    volIco.Position = UDim2.fromOffset(PW - 150, barY + 2); volIco.Size = UDim2.fromOffset(15, 15)
    volIco.BackgroundTransparency = 1; volIco.ImageColor3 = DIM; volIco.ZIndex = 3; volIco.Parent = parent
    loadIcon(volIco, "volume-2", DIM)
    local volSet = makeSlider(parent, PW - 128, barY + 5, 108, 4, function(f) if sound then sound.Volume = f end end)
    volSet(0.6)
    -- progress
    local tCur = Instance.new("TextLabel")
    tCur.Position = UDim2.fromOffset(16, barY + 30); tCur.Size = UDim2.fromOffset(44, 14)
    tCur.BackgroundTransparency = 1; tCur.Font = Theme.fonts.caption; tCur.Text = "0:00"
    tCur.TextSize = 11; tCur.TextColor3 = DIM; tCur.TextXAlignment = Enum.TextXAlignment.Left; tCur.ZIndex = 3; tCur.Parent = parent
    local tEnd = Instance.new("TextLabel")
    tEnd.AnchorPoint = Vector2.new(1, 0); tEnd.Position = UDim2.fromOffset(PW - 16, barY + 30); tEnd.Size = UDim2.fromOffset(44, 14)
    tEnd.BackgroundTransparency = 1; tEnd.Font = Theme.fonts.caption; tEnd.Text = "0:00"
    tEnd.TextSize = 11; tEnd.TextColor3 = DIM; tEnd.TextXAlignment = Enum.TextXAlignment.Right; tEnd.ZIndex = 3; tEnd.Parent = parent
    local progSet, progDrag = makeSlider(parent, 64, barY + 33, PW - 128, 5, function(f)
        if sound and sound.TimeLength > 0 then sound.TimePosition = f * sound.TimeLength end
    end)
    -- controls
    local playIco
    local function ctrl(cx, size, icon)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(0.5, 0.5); b.Position = UDim2.fromOffset(cx, barY + 74)
        b.Size = UDim2.fromOffset(size + 12, size + 12); b.BackgroundTransparency = 1
        b.AutoButtonColor = false; b.Text = ""; b.ZIndex = 3; b.Parent = parent
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(0.5, 0.5); ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.Size = UDim2.fromOffset(size, size); ic.BackgroundTransparency = 1
        ic.ImageColor3 = Color3.fromRGB(228, 228, 234); ic.ZIndex = 4; ic.Parent = b
        loadIcon(ic, icon, Color3.fromRGB(228, 228, 234))
        return b, ic
    end
    local cx = PW / 2
    local prevBtn = ctrl(cx - 54, 24, "skip-back")
    local playBtn, playIcoRef = ctrl(cx, 34, "play"); playIco = playIcoRef
    local nextBtn = ctrl(cx + 54, 24, "skip-forward")
    local refresh = Instance.new("TextButton")
    refresh.AnchorPoint = Vector2.new(1, 0.5); refresh.Position = UDim2.fromOffset(PW - 16, barY + 74)
    refresh.Size = UDim2.fromOffset(64, 22); refresh.BackgroundTransparency = 1; refresh.AutoButtonColor = false
    refresh.Font = Theme.fonts.caption; refresh.Text = "Refresh"; refresh.TextSize = 12
    refresh.TextColor3 = Color3.fromRGB(150, 150, 160); refresh.TextXAlignment = Enum.TextXAlignment.Right
    refresh.ZIndex = 3; refresh.Parent = parent
    refresh.MouseEnter:Connect(function() refresh.TextColor3 = WHITE end)
    refresh.MouseLeave:Connect(function() refresh.TextColor3 = Color3.fromRGB(150, 150, 160) end)

    -- ---- data ----
    local files, view, index, rows = {}, {}, 0, {}
    local function fmt(s) s = math.max(0, math.floor(s or 0)); return ("%d:%02d"):format(math.floor(s / 60), s % 60) end
    local function nameOf(p) return ((p:match("([^/\\]+)$") or p):gsub("%.%w+$", "")) end

    local function highlight()
        for _, r in ipairs(rows) do
            r.frame.BackgroundTransparency = (view[index] == r.path) and 0.05 or 0.55
        end
    end
    local function playAt(i)
        if #view == 0 then return end
        index = ((i - 1) % #view) + 1
        stopSound()
        local path = view[index]
        local ok, id = pcall(function() return getcustomasset(path) end)
        if not ok or not id then trackTxt.Text = "Could not load track"; return end
        sound = Instance.new("Sound"); sound.SoundId = id; sound.Volume = 0.6
        sound.Parent = game:GetService("SoundService"); sound:Play()
        trackTxt.Text = nameOf(path); loadIcon(playIco, "pause", Color3.fromRGB(228, 228, 234))
        highlight()
        sound.Ended:Connect(function() if sound and alive then playAt(index + 1) end end)
    end

    local function render(q)
        for _, r in ipairs(rows) do r.frame:Destroy() end
        rows, view = {}, {}
        q = (q or ""):lower()
        for _, path in ipairs(files) do
            local nm = nameOf(path)
            if q == "" or nm:lower():find(q, 1, true) then
                view[#view + 1] = path
                local n = #view
                local row = Instance.new("TextButton")
                row.Size = UDim2.new(1, -4, 0, 34); row.BackgroundColor3 = CARD; row.BackgroundTransparency = 0.55
                row.AutoButtonColor = false; row.Text = ""; row.BorderSizePixel = 0; row.LayoutOrder = n; row.ZIndex = 3; row.Parent = scroll
                Util.corner(row, 8)
                local ri = Instance.new("ImageLabel")
                ri.Position = UDim2.fromOffset(12, 9); ri.Size = UDim2.fromOffset(16, 16); ri.BackgroundTransparency = 1
                ri.ImageColor3 = SUB; ri.ZIndex = 4; ri.Parent = row
                loadIcon(ri, "music", SUB)
                local rt = Instance.new("TextLabel")
                rt.Position = UDim2.fromOffset(38, 0); rt.Size = UDim2.fromOffset(PW - 90, 34); rt.BackgroundTransparency = 1
                rt.Font = Theme.fonts.body; rt.Text = nm; rt.TextSize = 13; rt.TextColor3 = WHITE
                rt.TextXAlignment = Enum.TextXAlignment.Left; rt.TextTruncate = Enum.TextTruncate.AtEnd; rt.ZIndex = 4; rt.Parent = row
                row.MouseButton1Click:Connect(function() playAt(n) end)
                rows[#rows + 1] = { frame = row, path = path }
            end
        end
        empty.Visible = (#view == 0)
        highlight()
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
        render(sBox.Text)
    end

    sBox:GetPropertyChangedSignal("Text"):Connect(function() render(sBox.Text) end)
    prevBtn.MouseButton1Click:Connect(function() if #view > 0 then playAt(index - 1) end end)
    nextBtn.MouseButton1Click:Connect(function() if #view > 0 then playAt(index + 1) end end)
    playBtn.MouseButton1Click:Connect(function()
        if not sound then if #view > 0 then playAt(index == 0 and 1 or index) end return end
        if sound.Playing then sound:Pause(); loadIcon(playIco, "play", Color3.fromRGB(228, 228, 234))
        else sound:Resume(); loadIcon(playIco, "pause", Color3.fromRGB(228, 228, 234)) end
    end)
    refresh.MouseButton1Click:Connect(scan)

    task.spawn(function()
        while alive do
            if sound and sound.TimeLength and sound.TimeLength > 0 then
                tCur.Text = fmt(sound.TimePosition); tEnd.Text = fmt(sound.TimeLength)
                if not progDrag() then progSet(sound.TimePosition / sound.TimeLength) end
            end
            task.wait(0.3)
        end
    end)

    scan()
    return function() alive = false; stopSound() end
end

-- ============================================================================
-- YOUTUBE: search videos (or paste a link), then download the audio to
-- SYNC/songs so the MP3 player can play it. Search runs through public Piped
-- instances; the audio itself is fetched through a media-extraction service
-- (Cobalt) that transcodes to mp3 (Roblox can only play mp3/ogg).
-- ============================================================================
local RED = Color3.fromRGB(230, 66, 74)
local PIPED = {
    "https://api.piped.private.coffee",
    "https://pipedapi.adminforge.de",
    "https://pipedapi.kavin.rocks",
    "https://pipedapi.reallyaweso.me",
}
local COBALT = {
    "https://cobalt-backend.canine.tools",
    "https://cobalt-api.kwiatekmiki.com",
    "https://co.eepy.today",
    "https://cobalt.255x.ru",
}

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

-- ask a Cobalt instance for a direct mp3 url. Returns url or nil.
local function ytAudioUrl(youtubeUrl)
    for _, inst in ipairs(COBALT) do
        -- newer API shape
        local _, _, body = Util.httpPost(inst .. "/", { ["Accept"] = "application/json" },
            HttpService:JSONEncode({ url = youtubeUrl, downloadMode = "audio", audioFormat = "mp3" }))
        local ok, d = pcall(function() return HttpService:JSONDecode(body or "") end)
        if ok and d and d.url then return d.url end
        -- older API shape
        local _, _, body2 = Util.httpPost(inst .. "/api/json", { ["Accept"] = "application/json" },
            HttpService:JSONEncode({ url = youtubeUrl, isAudioOnly = true, aFormat = "mp3" }))
        local ok2, d2 = pcall(function() return HttpService:JSONDecode(body2 or "") end)
        if ok2 and d2 and d2.url then return d2.url end
    end
    return nil
end

local function safeName(s)
    return (tostring(s):gsub("[^%w%s%-_%.]", ""):gsub("%s+", " "):sub(1, 60))
end

local function buildYT(parent, PW, PH, setSub)
    pcall(function()
        if type(makefolder) == "function" then
            if not isfolder("SYNC") then makefolder("SYNC") end
            if not isfolder(SND_DIR) then makefolder(SND_DIR) end
        end
    end)
    setSub("Search or paste a link")

    -- search bar
    local sh = Instance.new("Frame")
    sh.Position = UDim2.fromOffset(16, 6); sh.Size = UDim2.fromOffset(PW - 32, 40)
    sh.BackgroundColor3 = Color3.fromRGB(26, 27, 32); sh.BorderSizePixel = 0; sh.ZIndex = 4; sh.Parent = parent
    Util.corner(sh, 10); local sst = Util.stroke(sh, Color3.fromRGB(70, 70, 80), 1, 0.5)
    local sBox = Instance.new("TextBox")
    sBox.Position = UDim2.fromOffset(16, 0); sBox.Size = UDim2.fromOffset(PW - 32 - 56, 40)
    sBox.BackgroundTransparency = 1; sBox.Font = Theme.fonts.body
    sBox.PlaceholderText = "Search YouTube or paste a link..."; sBox.PlaceholderColor3 = DIM
    sBox.Text = ""; sBox.TextSize = 14; sBox.TextColor3 = WHITE
    sBox.TextXAlignment = Enum.TextXAlignment.Left; sBox.ClearTextOnFocus = false; sBox.ZIndex = 5; sBox.Parent = sh
    sBox.Focused:Connect(function() Util.tween(sst, { Transparency = 0.1, Color = RED }, 0.15) end)
    sBox.FocusLost:Connect(function() Util.tween(sst, { Transparency = 0.5, Color = Color3.fromRGB(70, 70, 80) }, 0.15) end)
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

    -- results (padded so card strokes aren't clipped by the scroll edge)
    local listY = 54
    local listH = PH - listY - 10
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position = UDim2.fromOffset(12, listY); scroll.Size = UDim2.fromOffset(PW - 24, listH)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 90)
    scroll.ScrollBarImageTransparency = 0.35; scroll.CanvasSize = UDim2.new(); scroll.ZIndex = 3; scroll.Parent = parent
    local spad = Instance.new("UIPadding")
    spad.PaddingLeft = UDim.new(0, 6); spad.PaddingRight = UDim.new(0, 10); spad.PaddingTop = UDim.new(0, 4); spad.Parent = scroll
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
    Util.autoCanvas(scroll, "Y")
    scrollFade(parent, 12, listY, PW - 24, 16, false)
    scrollFade(parent, 12, listY + listH - 16, PW - 24, 16, true)
    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0); status.Position = UDim2.fromScale(0.5, 0.22)
    status.Size = UDim2.fromOffset(PW - 80, 40); status.BackgroundTransparency = 1
    status.Font = Theme.fonts.caption; status.Text = "Search for a song or paste a YouTube link."
    status.TextSize = 13; status.TextColor3 = SUB; status.TextWrapped = true
    status.ZIndex = 3; status.Parent = scroll

    local function clearResults()
        for _, c in ipairs(scroll:GetChildren()) do
            if c ~= layout and c ~= status and c ~= spad then c:Destroy() end
        end
    end

    local cardW = PW - 24 - 16 -- scroll width minus padding
    local function resultCard(i, id, title, channel, dur)
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, 0, 0, 64); c.BackgroundColor3 = CARD; c.BorderSizePixel = 0
        c.LayoutOrder = i; c.ZIndex = 3; c.Parent = scroll
        Util.corner(c, 10); Util.stroke(c, WHITE, 1, 0.93)
        local thumb = Instance.new("ImageLabel")
        thumb.Position = UDim2.fromOffset(8, 8); thumb.Size = UDim2.fromOffset(84, 48)
        thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36); thumb.BorderSizePixel = 0
        thumb.ScaleType = Enum.ScaleType.Crop; thumb.ZIndex = 4; thumb.Parent = c
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
        t.TextTruncate = Enum.TextTruncate.AtEnd; t.ZIndex = 4; t.Parent = c
        local sub = Instance.new("TextLabel")
        sub.Position = UDim2.fromOffset(102, 32); sub.Size = UDim2.fromOffset(cardW - 102 - 48, 16)
        sub.BackgroundTransparency = 1; sub.Font = Theme.fonts.caption
        sub.Text = channel .. (dur and dur > 0 and ("  \195\151  " .. ("%d:%02d"):format(math.floor(dur / 60), dur % 60)) or "")
        sub.TextSize = 11; sub.TextColor3 = SUB; sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd; sub.ZIndex = 4; sub.Parent = c
        local dl = Instance.new("TextButton")
        dl.AnchorPoint = Vector2.new(1, 0.5); dl.Position = UDim2.new(1, -12, 0.5, 0)
        dl.Size = UDim2.fromOffset(30, 30); dl.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
        dl.AutoButtonColor = false; dl.Text = ""; dl.BorderSizePixel = 0; dl.ZIndex = 4; dl.Parent = c
        Util.corner(dl, 8)
        local dlIc = Instance.new("ImageLabel")
        dlIc.AnchorPoint = Vector2.new(0.5, 0.5); dlIc.Position = UDim2.fromScale(0.5, 0.5)
        dlIc.Size = UDim2.fromOffset(15, 15); dlIc.BackgroundTransparency = 1
        dlIc.ImageColor3 = RED; dlIc.ZIndex = 5; dlIc.Parent = dl
        loadIcon(dlIc, "download", RED)
        dl.MouseEnter:Connect(function() Util.tween(dl, { BackgroundColor3 = Color3.fromRGB(52, 40, 42) }, 0.12) end)
        dl.MouseLeave:Connect(function() Util.tween(dl, { BackgroundColor3 = Color3.fromRGB(36, 36, 42) }, 0.12) end)

        local busy = false
        dl.MouseButton1Click:Connect(function()
            if busy then return end
            busy = true
            sub.Text = "Downloading audio..."; sub.TextColor3 = RED
            task.spawn(function()
                local yurl = "https://www.youtube.com/watch?v=" .. id
                local mp3url = ytAudioUrl(yurl)
                if not mp3url then
                    sub.Text = "Audio service unavailable, try again"; sub.TextColor3 = Color3.fromRGB(240, 160, 90)
                    busy = false; return
                end
                local ok, data = pcall(function() return game:HttpGet(mp3url, true) end)
                if ok and data and #data > 2000 then
                    pcall(function() writefile(SND_DIR .. "/" .. safeName(title) .. ".mp3", data) end)
                    sub.Text = "Downloaded - open the MP3 tab"; sub.TextColor3 = Color3.fromRGB(120, 210, 150)
                else
                    sub.Text = "Download failed, try again"; sub.TextColor3 = Color3.fromRGB(240, 160, 90)
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
                resultCard(1, direct, "Video from link", "Paste  \195\151  tap download", 0)
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

    local cardW, cardH = 588, 528
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
    local winGrad = Instance.new("UIGradient")
    winGrad.Rotation = 120
    winGrad.Color = ColorSequence.new(Color3.fromRGB(24, 26, 34), Color3.fromRGB(12, 12, 15))
    winGrad.Parent = win
    WM.register(gui, win, 16)

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
    hSub.AnchorPoint = Vector2.new(1, 0.5)
    hSub.Position = UDim2.fromOffset(cardW - 20, TB + 25)
    hSub.Size = UDim2.fromOffset(240, 18)
    hSub.BackgroundTransparency = 1
    hSub.Font = Theme.fonts.caption
    hSub.TextSize = 12.5
    hSub.TextColor3 = SUB
    hSub.TextXAlignment = Enum.TextXAlignment.Right
    hSub.TextTruncate = Enum.TextTruncate.AtEnd
    hSub.ZIndex = 3
    hSub.Parent = win

    local function setSub(t) hSub.Text = t end

    -- tab bar: Spotify / YouTube / MP3
    local switchTab -- forward declared
    local tabDefs = {
        { key = "spotify", label = "Spotify", x = 48, w = 58 },
        { key = "youtube", label = "YouTube", x = 122, w = 66 },
        { key = "mp3",     label = "MP3",     x = 204, w = 34 },
    }
    local tabBtns = {}
    local tabY = TB + 44
    for _, td in ipairs(tabDefs) do
        local tb = Instance.new("TextButton")
        tb.Position = UDim2.fromOffset(td.x, tabY)
        tb.Size = UDim2.fromOffset(td.w, 28)
        tb.BackgroundTransparency = 1
        tb.AutoButtonColor = false
        tb.Font = Theme.fonts.title
        tb.Text = td.label
        tb.TextSize = 14
        tb.TextColor3 = SUB
        tb.ZIndex = 3
        tb.Parent = win
        local ul = Instance.new("Frame")
        ul.AnchorPoint = Vector2.new(0.5, 1)
        ul.Position = UDim2.new(0.5, 0, 1, 2)
        ul.Size = UDim2.fromOffset(td.w, 2)
        ul.BackgroundColor3 = WHITE
        ul.BorderSizePixel = 0
        ul.BackgroundTransparency = 1
        ul.ZIndex = 3
        ul.Parent = tb
        Util.corner(ul, 1)
        tabBtns[td.key] = { btn = tb, ul = ul }
        tb.MouseButton1Click:Connect(function() switchTab(td.key) end)
    end
    -- hairline under the tab row
    local tabLine = Instance.new("Frame")
    tabLine.Position = UDim2.fromOffset(20, tabY + 30)
    tabLine.Size = UDim2.new(1, -40, 0, 1)
    tabLine.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tabLine.BackgroundTransparency = 0.55
    tabLine.BorderSizePixel = 0
    tabLine.ZIndex = 3
    tabLine.Parent = win

    -- body container (tab content builds in here)
    local body = Instance.new("Frame")
    body.Position = UDim2.fromOffset(0, TB + 82)
    body.Size = UDim2.fromOffset(cardW, cardH - TB - 82)
    body.BackgroundTransparency = 1
    body.ZIndex = 3
    body.Parent = win
    local BW, BH = cardW, cardH - TB - 82

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

        -- soft glow behind the mark
        local glow = Instance.new("ImageLabel")
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Position = UDim2.fromOffset(BW / 2, 30)
        glow.Size = UDim2.fromOffset(180, 180)
        glow.BackgroundTransparency = 1
        glow.ImageColor3 = LINK
        glow.ImageTransparency = 1
        glow.ZIndex = 3
        glow.Parent = body
        task.spawn(function()
            local png = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode(RAW .. "boot-halo.png") .. "&output=png&w=220&h=220"
            local id = Util.remoteImage(png, "music_glow.png")
            if id and glow.Parent then glow.Image = id; Util.tween(glow, { ImageTransparency = 0.5 }, 0.5) end
        end)

        local note = Instance.new("ImageLabel")
        note.AnchorPoint = Vector2.new(0.5, 0)
        note.Position = UDim2.fromOffset(BW / 2, 4)
        note.Size = UDim2.fromOffset(50, 50)
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
        local btnGrad = Instance.new("UIGradient")
        btnGrad.Rotation = 90
        btnGrad.Color = ColorSequence.new(Color3.fromRGB(72, 104, 165), BLUE)
        btnGrad.Parent = btn
        Util.shadow(btn, { blur = 24, transparency = 0.6, offset = UDim2.fromOffset(0, 6), color = Color3.fromRGB(30, 50, 90) })
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

        -- faint blurred album-art backdrop (premium depth)
        local backdrop = Instance.new("ImageLabel")
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
        backdrop.BackgroundTransparency = 1
        backdrop.BorderSizePixel = 0
        backdrop.ScaleType = Enum.ScaleType.Crop
        backdrop.ImageTransparency = 1
        backdrop.ZIndex = 1
        backdrop.Parent = body
        local bkc = Instance.new("UICorner")
        local okbk = pcall(function()
            bkc.BottomLeftRadius = UDim.new(0, 16); bkc.BottomRightRadius = UDim.new(0, 16)
            bkc.TopLeftRadius = UDim.new(0, 0); bkc.TopRightRadius = UDim.new(0, 0)
        end)
        if not okbk then bkc.CornerRadius = UDim.new(0, 16) end
        bkc.Parent = backdrop
        local backdropDim = Instance.new("Frame")
        backdropDim.Size = UDim2.fromScale(1, 1)
        backdropDim.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
        backdropDim.BackgroundTransparency = 0.12
        backdropDim.BorderSizePixel = 0
        backdropDim.ZIndex = 2
        backdropDim.Parent = body
        local ddg = Instance.new("UIGradient")
        ddg.Rotation = 90
        ddg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(1, 0.0),
        })
        ddg.Parent = backdropDim
        local bkc2 = bkc:Clone(); bkc2.Parent = backdropDim

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
        Util.shadow(playWrap, { blur = 26, transparency = 0.55, offset = UDim2.fromOffset(0, 5) })
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
                            task.spawn(function()
                                local burl = "https://images.weserv.nl/?url=" .. HttpService:UrlEncode(imgs[1].url)
                                    .. "&output=png&w=340&h=220&fit=cover&blur=45"
                                local bid = Util.remoteImage(burl, "sp_bg_" .. it.id .. ".png")
                                if bid and backdrop.Parent then backdrop.Image = bid; Util.tween(backdrop, { ImageTransparency = 0.62 }, 0.6) end
                            end)
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
        elseif key == "mp3" then currentCleanup = buildMP3(body, BW, BH, setSub) end
    end

    switchTab("spotify")

    return { close = close }
end

return Music
