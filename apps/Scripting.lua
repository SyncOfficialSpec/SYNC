-- SYNC / apps / Scripting
-- Hub for 20+ Roblox scripting websites (thumbnail, title, description, link).
-- Shell + menu layout only for now; the site grid is intentionally left blank.

local UserInputService = game:GetService("UserInputService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")

local ScriptingApp = {}

local C = {
    bg     = Color3.fromRGB(24, 25, 28),
    side   = Color3.fromRGB(30, 31, 34),
    header = Color3.fromRGB(30, 31, 34),
    card   = Color3.fromRGB(38, 40, 45),
    input  = Color3.fromRGB(44, 46, 51),
    text   = Color3.fromRGB(228, 230, 234),
    muted  = Color3.fromRGB(150, 155, 164),
    accent = Theme.accent,
}
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)

-- Left-rail categories (menu). Content blank for now.
local CATEGORIES = { "All", "Executors", "Script Hubs", "Marketplaces", "Communities", "Tools" }

ScriptingApp._gui = nil

function ScriptingApp.open()
    if ScriptingApp._gui then return end

    local vp = Util.viewport()
    local W = math.floor(math.min(980, math.max(700, vp.X - 80)))
    local H = math.floor(math.min(640, math.max(460, vp.Y - 100)))
    local cardX, cardY = (vp.X - W) / 2, (vp.Y - H) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Scripting"
    Util.mount(gui)
    ScriptingApp._gui = gui

    local winConns = {}
    local function close()
        if not ScriptingApp._gui then return end
        ScriptingApp._gui = nil
        for _, c in ipairs(winConns) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end

    -- window
    local TB = 38
    local win = Instance.new("Frame")
    win.Position = UDim2.fromOffset(cardX, cardY)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = C.bg
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 12)
    Util.stroke(win, WHITE, 1, 0.86)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })

    -- title bar (draggable + traffic lights)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = C.header
    bar.BorderSizePixel = 0
    bar.ZIndex = 6
    bar.Active = true
    bar.Parent = win
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 12); bc.Parent = bar
    local barFix = Instance.new("Frame")
    barFix.Size = UDim2.new(1, 0, 0, 12); barFix.Position = UDim2.new(0, 0, 1, -12)
    barFix.BackgroundColor3 = C.header; barFix.BorderSizePixel = 0; barFix.ZIndex = 6; barFix.Parent = bar

    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = win.Position
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            win.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
        end
    end)
    winConns[#winConns + 1] = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    local lights = { Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }
    for i, col in ipairs(lights) do
        local dot = Instance.new(i == 1 and "TextButton" or "Frame")
        if i == 1 then dot.Text = ""; dot.AutoButtonColor = false end
        dot.Size = UDim2.fromOffset(12, 12)
        dot.Position = UDim2.fromOffset(14 + (i - 1) * 20, (TB - 12) / 2)
        dot.BackgroundColor3 = col; dot.BorderSizePixel = 0; dot.ZIndex = 7; dot.Parent = bar
        Util.corner(dot, 6)
        if i == 1 then dot.MouseButton1Click:Connect(close) end
    end
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, 0, 1, 0); titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Scripting"; titleLbl.Font = Theme.fonts.title; titleLbl.TextSize = 14
    titleLbl.TextColor3 = Color3.fromRGB(210, 210, 216); titleLbl.ZIndex = 6; titleLbl.Parent = bar

    -- ---- left rail (categories menu) ----
    local SIDE_W = 196
    local side = Instance.new("Frame")
    side.Position = UDim2.fromOffset(0, TB); side.Size = UDim2.new(0, SIDE_W, 1, -TB)
    side.BackgroundColor3 = C.side; side.BorderSizePixel = 0; side.ZIndex = 3; side.Parent = win

    local railTitle = Instance.new("TextLabel")
    railTitle.Position = UDim2.fromOffset(16, 14); railTitle.Size = UDim2.new(1, -24, 0, 18)
    railTitle.BackgroundTransparency = 1; railTitle.Text = "BROWSE"
    railTitle.Font = Theme.fonts.caption; railTitle.TextSize = 11; railTitle.TextColor3 = C.muted
    railTitle.TextXAlignment = Enum.TextXAlignment.Left; railTitle.ZIndex = 4; railTitle.Parent = side

    local activeCat = "All"
    local catButtons = {}
    local function selectCat(name)
        activeCat = name
        for _, cb in ipairs(catButtons) do
            local on = cb.name == name
            cb.btn.BackgroundTransparency = on and 0 or 1
            cb.btn.BackgroundColor3 = C.card
            cb.lbl.TextColor3 = on and C.text or C.muted
        end
        -- content stays blank for now
    end
    for i, name in ipairs(CATEGORIES) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -16, 0, 34); btn.Position = UDim2.fromOffset(8, 40 + (i - 1) * 38)
        btn.BackgroundColor3 = C.card; btn.BackgroundTransparency = 1; btn.BorderSizePixel = 0
        btn.AutoButtonColor = false; btn.Text = ""; btn.ZIndex = 4; btn.Parent = side
        Util.corner(btn, 8)
        local lbl = Instance.new("TextLabel")
        lbl.Position = UDim2.fromOffset(12, 0); lbl.Size = UDim2.new(1, -20, 1, 0)
        lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.Font = Theme.fonts.body
        lbl.TextSize = 14; lbl.TextColor3 = (name == activeCat) and C.text or C.muted
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 5; lbl.Parent = btn
        btn.MouseButton1Click:Connect(function() selectCat(name) end)
        catButtons[#catButtons + 1] = { name = name, btn = btn, lbl = lbl }
    end
    selectCat("All")

    -- ---- right side (header + search + content grid placeholder) ----
    local main = Instance.new("Frame")
    main.Position = UDim2.fromOffset(SIDE_W, TB); main.Size = UDim2.new(1, -SIDE_W, 1, -TB)
    main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0; main.ZIndex = 3; main.Parent = win

    local heading = Instance.new("TextLabel")
    heading.Position = UDim2.fromOffset(22, 16); heading.Size = UDim2.new(1, -44, 0, 26)
    heading.BackgroundTransparency = 1; heading.Text = "Scripting Sites"
    heading.Font = Theme.fonts.title; heading.TextSize = 19; heading.TextColor3 = C.text
    heading.TextXAlignment = Enum.TextXAlignment.Left; heading.ZIndex = 4; heading.Parent = main

    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.fromOffset(22, 44); sub.Size = UDim2.new(1, -44, 0, 16)
    sub.BackgroundTransparency = 1; sub.Text = "20+ Roblox scripting websites, all in one place"
    sub.Font = Theme.fonts.caption; sub.TextSize = 12; sub.TextColor3 = C.muted
    sub.TextXAlignment = Enum.TextXAlignment.Left; sub.ZIndex = 4; sub.Parent = main

    -- search bar
    local searchWrap = Instance.new("Frame")
    searchWrap.Position = UDim2.fromOffset(22, 74); searchWrap.Size = UDim2.new(1, -44, 0, 36)
    searchWrap.BackgroundColor3 = C.input; searchWrap.BorderSizePixel = 0; searchWrap.ZIndex = 4; searchWrap.Parent = main
    Util.corner(searchWrap, 9)
    local search = Instance.new("TextBox")
    search.Position = UDim2.fromOffset(14, 0); search.Size = UDim2.new(1, -24, 1, 0)
    search.BackgroundTransparency = 1; search.Text = ""; search.PlaceholderText = "Search sites..."
    search.PlaceholderColor3 = C.muted; search.TextColor3 = C.text; search.Font = Theme.fonts.body
    search.TextSize = 14; search.TextXAlignment = Enum.TextXAlignment.Left; search.ClearTextOnFocus = false
    search.ClipsDescendants = true; search.ZIndex = 5; search.Parent = searchWrap

    -- content grid (scroll). Left blank for now -- sites get added later.
    local grid = Instance.new("ScrollingFrame")
    grid.Position = UDim2.fromOffset(14, 122); grid.Size = UDim2.new(1, -28, 1, -134)
    grid.BackgroundTransparency = 1; grid.BorderSizePixel = 0; grid.ScrollBarThickness = 4
    grid.ScrollBarImageColor3 = Color3.fromRGB(90, 92, 98); grid.ScrollBarImageTransparency = 0.3
    grid.CanvasSize = UDim2.fromOffset(0, 0); grid.ZIndex = 4; grid.Parent = main

    local placeholder = Instance.new("TextLabel")
    placeholder.AnchorPoint = Vector2.new(0.5, 0.5); placeholder.Position = UDim2.fromScale(0.5, 0.45)
    placeholder.Size = UDim2.fromOffset(360, 40); placeholder.BackgroundTransparency = 1
    placeholder.Text = "Sites coming soon"; placeholder.Font = Theme.fonts.body
    placeholder.TextSize = 15; placeholder.TextColor3 = C.muted; placeholder.ZIndex = 5; placeholder.Parent = grid

    return { close = close }
end

return ScriptingApp
