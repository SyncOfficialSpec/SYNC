-- SYNC / os / DesktopMode
-- Turns the whole screen into a macOS-style desktop: the user's real wallpaper,
-- a menu bar up top, and the live Roblox game framed as a centered "app" window.
--
-- The trick for showing the RUNNING game inside a window: 2D GUI always draws
-- over the 3D viewport, so you can never see the game "through" a GUI. Instead we
-- cover the screen with the wallpaper in four strips arranged AROUND a central
-- rectangle, and leave that rectangle empty. The game shows through the gap, and
-- we draw macOS window chrome (title bar + traffic lights + a rounded border) on
-- top of the gap's edges. Result: the game looks like a windowed Mac app.
--
-- DesktopMode.set(true/false) toggles it; the choice persists under "DesktopMode".
-- Exit from inside via the red traffic light or the Escape key.

local Util  = SYNC.import("core/Util")
local Theme = SYNC.import("core/Theme")

local DesktopMode = {}

local HS = game:GetService("HttpService")
local RAW_WALLPAPER =
    "https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/assets/desktop_wallpaper.jpg"
local IMG_W, IMG_H = 1024, 663 -- committed asset dimensions

DesktopMode._gui = nil

local DARK = Color3.fromRGB(28, 28, 32)

-- weserv turns the jpg into a png getcustomasset can load, at the asset's size.
local function wallpaperAsset()
    local png = "https://images.weserv.nl/?url="
        .. HS:UrlEncode(RAW_WALLPAPER) .. "&output=png&w=" .. IMG_W .. "&h=" .. IMG_H
    return Util.remoteImage(png, "desktop_wallpaper.png")
end

-- lucide icons rasterise BLACK, which is what we want on the light menu bar, so
-- we skip the negate filter (invert) and let the black glyph stand. simple-icons
-- come pre-coloured. Async: fills `img` once the png is ready.
local function loadIcon(img, svgUrl, filename, tint)
    task.spawn(function()
        local pngUrl = "https://images.weserv.nl/?url="
            .. HS:UrlEncode(svgUrl) .. "&output=png&w=48&h=48"
        local id = Util.remoteImage(pngUrl, filename)
        if id and img and img.Parent then
            img.Image = id
            img.ImageColor3 = tint or DARK
        end
    end)
end

function DesktopMode.isOn()
    return Util.load("DesktopMode") == "true"
end

-- Real device-local time (macOS-style), not SYNC's deliberately-offset clock.
-- Roblox's FormatLocalTime tokens are unreliable (its "d" is day-of-week, "tt"
-- prints literally), so we build the string from the ToLocalTime() table.
local WD = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local MO = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local function weekdayIndex(y, m, d) -- Sakamoto's algorithm, 0 = Sunday
    local t = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 }
    if m < 3 then y = y - 1 end
    return (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400) + t[m] + d) % 7
end
local function localClock()
    local ok, t = pcall(function() return DateTime.now():ToLocalTime() end)
    if ok and t and t.Hour then
        local h = t.Hour % 12
        if h == 0 then h = 12 end
        local ap = t.Hour < 12 and "AM" or "PM"
        local wd = WD[weekdayIndex(t.Year, t.Month, t.Day) + 1]
        local mo = MO[t.Month]
        return string.format("%s %d %s  %d:%02d %s", wd, t.Day, mo, h, t.Minute, ap)
    end
    return Util.date("%a %d %b  %I:%M %p")
end

function DesktopMode.enable()
    if DesktopMode._gui then return end
    local vp = Util.viewport()
    local W, H = vp.X, vp.Y

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_DesktopMode"
    Util.mount(gui)
    gui.DisplayOrder = 1000000000 -- sit above every SYNC window
    DesktopMode._gui = gui

    -- Cover-crop the wallpaper to the screen aspect (true macOS "Fill", no stretch)
    local ia, sa = IMG_W / IMG_H, W / H
    local cropX, cropY, cropW, cropH
    if sa > ia then
        cropW, cropH = IMG_W, IMG_W / sa
        cropX, cropY = 0, (IMG_H - cropH) / 2
    else
        cropW, cropH = IMG_H * sa, IMG_H
        cropX, cropY = (IMG_W - cropW) / 2, 0
    end

    local assetId = wallpaperAsset()

    -- One wallpaper slice covering the screen rect (sx, sy, sw, sh). ImageRect maps
    -- that region back into the source crop so the slices tile seamlessly.
    local function strip(sx, sy, sw, sh)
        if sw <= 0 or sh <= 0 then return end
        local im = Instance.new("ImageLabel")
        im.BackgroundColor3 = Color3.fromRGB(74, 108, 150) -- sky tone while it loads
        im.BorderSizePixel = 0
        im.Position = UDim2.fromOffset(math.floor(sx), math.floor(sy))
        im.Size = UDim2.fromOffset(math.ceil(sw), math.ceil(sh))
        im.ZIndex = 2
        if assetId then
            im.Image = assetId
            im.ImageRectOffset = Vector2.new(cropX + (sx / W) * cropW, cropY + (sy / H) * cropH)
            im.ImageRectSize = Vector2.new((sw / W) * cropW, (sh / H) * cropH)
        end
        im.Parent = gui
        return im
    end

    -- Centered window geometry. Body (below the title bar) is the see-through gap.
    local ww = math.floor(W * 0.56)
    local wh = math.floor(H * 0.62)
    local wx = math.floor((W - ww) / 2)
    local wy = math.floor((H - wh) / 2) - 6
    local TBH = 30
    local bodyTop = wy + TBH

    -- Four wallpaper strips around the gap
    strip(0, 0, W, bodyTop)                            -- top band (full width)
    strip(0, wy + wh, W, H - (wy + wh))                -- bottom band (full width)
    strip(0, bodyTop, wx, wh - TBH)                    -- left of the window
    strip(wx + ww, bodyTop, W - (wx + ww), wh - TBH)   -- right of the window

    -- Rounded window border. Transparent body so the game (and its input) pass
    -- through; only the stroke and rounded corners draw.
    local border = Instance.new("Frame")
    border.Active = false
    border.BackgroundTransparency = 1
    border.Position = UDim2.fromOffset(wx, wy)
    border.Size = UDim2.fromOffset(ww, wh)
    border.ZIndex = 3
    border.Parent = gui
    Util.corner(border, 10)
    Util.stroke(border, Color3.fromRGB(255, 255, 255), 1, 0.55)

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Position = UDim2.fromOffset(wx, wy)
    bar.Size = UDim2.fromOffset(ww, TBH)
    bar.BackgroundColor3 = Color3.fromRGB(52, 52, 57)
    bar.BackgroundTransparency = 0.06
    bar.BorderSizePixel = 0
    bar.ZIndex = 4
    bar.Parent = gui
    local bc = Instance.new("UICorner")
    local okc = pcall(function()
        bc.TopLeftRadius = UDim.new(0, 10); bc.TopRightRadius = UDim.new(0, 10)
        bc.BottomLeftRadius = UDim.new(0, 0); bc.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okc then bc.CornerRadius = UDim.new(0, 10) end
    bc.Parent = bar

    -- Traffic lights (red exits desktop mode)
    local cols = { Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }
    for i, col in ipairs(cols) do
        local clickable = (i == 1)
        local dot = Instance.new(clickable and "TextButton" or "Frame")
        if clickable then dot.Text = ""; dot.AutoButtonColor = false end
        dot.Size = UDim2.fromOffset(12, 12)
        dot.Position = UDim2.fromOffset(12 + (i - 1) * 20, (TBH - 12) / 2)
        dot.BackgroundColor3 = col
        dot.BorderSizePixel = 0
        dot.ZIndex = 5
        dot.Parent = bar
        Util.corner(dot, 6)
        if clickable then dot.MouseButton1Click:Connect(function() DesktopMode.set(false) end) end
    end

    -- Window title with the Roblox mark
    local titleWrap = Instance.new("Frame")
    titleWrap.BackgroundTransparency = 1
    titleWrap.AnchorPoint = Vector2.new(0.5, 0.5)
    titleWrap.Position = UDim2.new(0.5, 0, 0.5, 0)
    titleWrap.Size = UDim2.fromOffset(90, 18)
    titleWrap.ZIndex = 5
    titleWrap.Parent = bar
    local rbxMark = Instance.new("ImageLabel")
    rbxMark.BackgroundTransparency = 1
    rbxMark.Size = UDim2.fromOffset(13, 13)
    rbxMark.Position = UDim2.fromOffset(6, 3)
    rbxMark.ZIndex = 5
    rbxMark.Parent = titleWrap
    loadIcon(rbxMark, "cdn.simpleicons.org/roblox/e6e6e6", "ic_roblox_w.png", Color3.fromRGB(230, 230, 235))
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(24, 0)
    title.Size = UDim2.fromOffset(64, 18)
    title.Text = "Roblox"
    title.Font = Theme.fonts.title
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(228, 228, 233)
    title.ZIndex = 5
    title.Parent = titleWrap

    -- ---- Menu bar (frosted light, dark glyphs, like macOS over a bright wallpaper)
    local MBH = 24
    local menu = Instance.new("Frame")
    menu.Size = UDim2.fromOffset(W, MBH)
    menu.BackgroundColor3 = Color3.fromRGB(248, 248, 250)
    menu.BackgroundTransparency = 0.42
    menu.BorderSizePixel = 0
    menu.ZIndex = 6
    menu.Parent = gui
    Util.stroke(menu, Color3.fromRGB(0, 0, 0), 1, 0.9)

    -- Left cluster: apple + app menus
    local left = Instance.new("Frame")
    left.BackgroundTransparency = 1
    left.Position = UDim2.fromOffset(12, 0)
    left.Size = UDim2.new(0, 0, 1, 0)
    left.AutomaticSize = Enum.AutomaticSize.X
    left.ZIndex = 7
    left.Parent = menu
    local ll = Instance.new("UIListLayout")
    ll.FillDirection = Enum.FillDirection.Horizontal
    ll.VerticalAlignment = Enum.VerticalAlignment.Center
    ll.Padding = UDim.new(0, 15)
    ll.Parent = left

    local apple = Instance.new("ImageLabel")
    apple.BackgroundTransparency = 1
    apple.Size = UDim2.fromOffset(14, 14)
    apple.LayoutOrder = 0
    apple.ZIndex = 7
    apple.Parent = left
    loadIcon(apple, "cdn.simpleicons.org/apple/111111", "ic_apple_d.png", Color3.fromRGB(20, 20, 20))

    local menus = { { "Finder", Theme.fonts.title }, { "File" }, { "Edit" }, { "View" }, { "Go" }, { "Window" }, { "Help" } }
    for i, m in ipairs(menus) do
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.AutomaticSize = Enum.AutomaticSize.X
        t.Size = UDim2.new(0, 0, 1, 0)
        t.Text = m[1]
        t.Font = m[2] or Theme.fonts.body
        t.TextSize = 13
        t.TextColor3 = Color3.fromRGB(24, 24, 26)
        t.LayoutOrder = i
        t.ZIndex = 7
        t.Parent = left
    end

    -- Right cluster: status icons + clock
    local right = Instance.new("Frame")
    right.BackgroundTransparency = 1
    right.AnchorPoint = Vector2.new(1, 0)
    right.Position = UDim2.new(1, -12, 0, 0)
    right.Size = UDim2.new(0, 0, 1, 0)
    right.AutomaticSize = Enum.AutomaticSize.X
    right.ZIndex = 7
    right.Parent = menu
    local rl = Instance.new("UIListLayout")
    rl.FillDirection = Enum.FillDirection.Horizontal
    rl.VerticalAlignment = Enum.VerticalAlignment.Center
    rl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    rl.Padding = UDim.new(0, 14)
    rl.Parent = right

    local function statusIcon(order, svg, file)
        local ic = Instance.new("ImageLabel")
        ic.BackgroundTransparency = 1
        ic.Size = UDim2.fromOffset(15, 15)
        ic.LayoutOrder = order
        ic.ZIndex = 7
        ic.Parent = right
        loadIcon(ic, "cdn.jsdelivr.net/npm/lucide-static/icons/" .. svg .. ".svg", file, DARK)
        return ic
    end
    statusIcon(1, "sliders-horizontal", "ic_cc.png")
    statusIcon(2, "battery-medium", "ic_batt.png")
    statusIcon(3, "wifi", "ic_wifi.png")
    statusIcon(4, "search", "ic_search.png")

    local clock = Instance.new("TextLabel")
    clock.BackgroundTransparency = 1
    clock.AutomaticSize = Enum.AutomaticSize.X
    clock.Size = UDim2.new(0, 0, 1, 0)
    clock.Font = Theme.fonts.body
    clock.TextSize = 13
    clock.TextColor3 = Color3.fromRGB(24, 24, 26)
    clock.Text = localClock()
    clock.LayoutOrder = 5
    clock.ZIndex = 7
    clock.Parent = right
    task.spawn(function()
        while DesktopMode._gui == gui and clock.Parent do
            clock.Text = localClock()
            task.wait(15)
        end
    end)

    -- Exit hint, fades after a few seconds
    local hint = Instance.new("TextLabel")
    hint.AnchorPoint = Vector2.new(0.5, 1)
    hint.Position = UDim2.new(0.5, 0, 1, -18)
    hint.Size = UDim2.fromOffset(360, 22)
    hint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hint.BackgroundTransparency = 0.5
    hint.Text = "Press Esc or click the red dot to leave Desktop mode"
    hint.Font = Theme.fonts.body
    hint.TextSize = 12
    hint.TextColor3 = Color3.fromRGB(240, 240, 245)
    hint.ZIndex = 8
    hint.Parent = gui
    Util.corner(hint, 11)
    task.delay(4, function()
        if hint.Parent then
            Util.tween(hint, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.6)
            task.delay(0.7, function() if hint.Parent then hint:Destroy() end end)
        end
    end)

    -- Escape leaves desktop mode
    Util.closeOnEscape(gui, function() DesktopMode.set(false) end)

    -- Entrance: quick fade in from black
    local cover = Instance.new("Frame")
    cover.Size = UDim2.fromScale(1, 1)
    cover.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    cover.BackgroundTransparency = 0
    cover.ZIndex = 50
    cover.Parent = gui
    Util.tween(cover, { BackgroundTransparency = 1 }, 0.3)
    task.delay(0.34, function() if cover.Parent then cover:Destroy() end end)
end

function DesktopMode.disable()
    local g = DesktopMode._gui
    if not g then return end
    DesktopMode._gui = nil
    g:Destroy()
end

function DesktopMode.set(v)
    Util.save("DesktopMode", v and "true" or "false")
    if v then DesktopMode.enable() else DesktopMode.disable() end
end

return DesktopMode
