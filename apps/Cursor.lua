-- SYNC / apps / Cursor
-- Custom cursor picker: browse cursor styles, click to apply.
-- Uses a RenderStepped overlay so the cursor shows everywhere.

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Theme = SYNC.import("core/Theme")
local Util  = SYNC.import("core/Util")
local Icons = SYNC.import("core/Icons")

local CursorApp = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local DIM   = Color3.fromRGB(150, 150, 158)
local ACCENT = Theme.accent

local CURSORS = {
    { id = "arrow_white",  name = "White",    cat = "Arrows",     char = "↑", color = Color3.fromRGB(255,255,255), size = 26 },
    { id = "arrow_black",  name = "Black",    cat = "Arrows",     char = "↑", color = Color3.fromRGB(0,0,0),       size = 26 },
    { id = "arrow_accent", name = "Blue",     cat = "Arrows",     char = "↑", color = ACCENT,                      size = 26 },
    { id = "arrow_green",  name = "Green",    cat = "Arrows",     char = "↑", color = Color3.fromRGB(52,199,89),   size = 26 },
    { id = "arrow_red",    name = "Red",      cat = "Arrows",     char = "↑", color = Color3.fromRGB(255,95,87),   size = 26 },
    { id = "arrow_gold",   name = "Gold",     cat = "Arrows",     char = "↑", color = Color3.fromRGB(254,188,46),  size = 26 },
    { id = "arrow_purple", name = "Purple",   cat = "Arrows",     char = "↑", color = Color3.fromRGB(175,82,222),  size = 26 },
    { id = "cross_white",  name = "White",    cat = "Crosshairs", char = "+", color = Color3.fromRGB(255,255,255), size = 32 },
    { id = "cross_red",    name = "Red",      cat = "Crosshairs", char = "+", color = Color3.fromRGB(255,59,48),   size = 32 },
    { id = "cross_cyan",   name = "Cyan",     cat = "Crosshairs", char = "+", color = Color3.fromRGB(90,200,255),  size = 32 },
    { id = "cross_gold",   name = "Gold",     cat = "Crosshairs", char = "+", color = Color3.fromRGB(254,188,46),  size = 32 },
    { id = "cross_green",  name = "Green",    cat = "Crosshairs", char = "+", color = Color3.fromRGB(52,199,89),   size = 32 },
    { id = "dot_white",    name = "White",    cat = "Dots",       char = "○", color = Color3.fromRGB(255,255,255), size = 22 },
    { id = "dot_red",      name = "Red",      cat = "Dots",       char = "○", color = Color3.fromRGB(255,59,48),   size = 22 },
    { id = "dot_cyan",     name = "Cyan",     cat = "Dots",       char = "○", color = Color3.fromRGB(90,200,255),  size = 22 },
    { id = "dot_accent",   name = "Blue",     cat = "Dots",       char = "○", color = ACCENT,                      size = 22 },
    { id = "text_white",   name = "White",    cat = "Text",       char = "|", color = Color3.fromRGB(255,255,255), size = 28 },
    { id = "text_accent",  name = "Blue",     cat = "Text",       char = "|", color = ACCENT,                      size = 28 },
    { id = "diamond_w",    name = "White",    cat = "Diamonds",   char = "◇", color = Color3.fromRGB(255,255,255), size = 26 },
    { id = "diamond_r",    name = "Red",      cat = "Diamonds",   char = "◇", color = Color3.fromRGB(255,59,48),   size = 26 },
    { id = "diamond_a",    name = "Blue",     cat = "Diamonds",   char = "◇", color = ACCENT,                      size = 26 },
}

local CATEGORIES = { "All", "Arrows", "Crosshairs", "Dots", "Text", "Diamonds" }

-- Cursor overlay engine (singleton)
local overlayGui, cursorLabel, conn
local activeId, cursorSize

local function clamp01(x) return math.clamp(x, 0, 1) end

local function startOverlay()
    if overlayGui then return end
    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = "SYNC_CursorOverlay"
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.DisplayOrder = 999999
    overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Util.mount(overlayGui)

    cursorLabel = Instance.new("TextLabel")
    cursorLabel.Size = UDim2.fromOffset(32, 32)
    cursorLabel.BackgroundTransparency = 1
    cursorLabel.BorderSizePixel = 0
    cursorLabel.Font = Enum.Font.Gotham
    cursorLabel.Text = ""
    cursorLabel.ZIndex = 999
    cursorLabel.Parent = overlayGui

    local lp = Util.localPlayer()
    local iconImg = Instance.new("ImageLabel")
    iconImg.Size = UDim2.fromOffset(32, 32)
    iconImg.BackgroundTransparency = 1
    iconImg.ZIndex = 999
    iconImg.Parent = cursorLabel

    local function updatePos()
        local m = UserInputService:GetMouseLocation()
        cursorLabel.Position = UDim2.fromOffset(m.X - cursorSize / 2, m.Y - cursorSize / 2)
    end
    updatePos()

    conn = RunService.RenderStepped:Connect(updatePos)

    pcall(function()
        local playerGui = lp:FindFirstChild("PlayerGui")
        if playerGui and playerGui:FindFirstChild("RobloxGui") then
            -- if Roblox GUI exists, hide cursor there too
        end
    end)

    local ok = pcall(function()
        UserInputService.MouseIconEnabled = false
    end)
end

local function stopOverlay()
    if conn then conn:Disconnect(); conn = nil end
    if overlayGui then overlayGui:Destroy(); overlayGui = nil end
    cursorLabel = nil
    pcall(function()
        UserInputService.MouseIconEnabled = true
    end)
end

local function applyCursor(id)
    for _, c in ipairs(CURSORS) do
        if c.id == id then
            activeId = id
            cursorSize = c.size
            cursorLabel.Text = c.char
            cursorLabel.TextColor3 = c.color
            cursorLabel.TextSize = c.size
            cursorLabel.Size = UDim2.fromOffset(c.size + 8, c.size + 8)
            Util.save("CursorPref", id)
            -- stroke for contrast against any background
            if c.color.R + c.color.G + c.color.B < 1.5 then
                cursorLabel.TextStrokeTransparency = 0
                cursorLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
            else
                cursorLabel.TextStrokeTransparency = 0.7
                cursorLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            end
            return
        end
    end
end

local function restoreSaved()
    local saved = Util.load("CursorPref")
    if saved then
        for _, c in ipairs(CURSORS) do
            if c.id == saved then
                startOverlay()
                applyCursor(saved)
                return
            end
        end
    end
end

-- Clean up if the app is reopened
CursorApp._gui = nil

function CursorApp.open()
    if CursorApp._gui then return end

    -- Ensure overlay is running
    startOverlay()
    if not activeId then
        applyCursor("arrow_white")
    end

    local W, H = 480, 420
    local vp = Util.viewport()
    local cardX, cardY = (vp.X - W) / 2, (vp.Y - H) / 2

    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Cursor"
    Util.mount(gui)
    CursorApp._gui = gui

    local function close()
        if not CursorApp._gui then return end
        CursorApp._gui = nil
        gui:Destroy()
    end

    local catcher = Instance.new("TextButton")
    catcher.Text = ""
    catcher.AutoButtonColor = false
    catcher.Size = UDim2.fromScale(1, 1)
    catcher.BackgroundTransparency = 1
    catcher.ZIndex = 1
    catcher.Parent = gui
    catcher.MouseButton1Click:Connect(close)

    -- Window
    local TB = 38
    local win = Instance.new("TextButton")
    win.Text = ""
    win.AutoButtonColor = false
    win.Position = UDim2.fromOffset(cardX, cardY)
    win.Size = UDim2.fromOffset(W, H)
    win.BackgroundColor3 = Color3.fromRGB(32, 32, 35)
    win.BackgroundTransparency = 0.04
    win.BorderSizePixel = 0
    win.ClipsDescendants = true
    win.ZIndex = 2
    win.Parent = gui
    Util.corner(win, 12)
    Util.stroke(win, WHITE, 1, 0.85)
    Util.shadow(win, { blur = 50, spread = -2, transparency = 0.4, offset = UDim2.fromOffset(0, 20) })

    -- Title bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, TB)
    bar.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
    bar.BackgroundTransparency = 0.12
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = win
    local barCorner = Instance.new("UICorner")
    local okBar = pcall(function()
        barCorner.TopLeftRadius = UDim.new(0, 12)
        barCorner.TopRightRadius = UDim.new(0, 12)
        barCorner.BottomLeftRadius = UDim.new(0, 0)
        barCorner.BottomRightRadius = UDim.new(0, 0)
    end)
    if not okBar then barCorner.CornerRadius = UDim.new(0, 12) end
    barCorner.Parent = bar

    local hair = Instance.new("Frame")
    hair.Size = UDim2.new(1, 0, 0, 1)
    hair.Position = UDim2.new(0, 0, 1, 0)
    hair.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hair.BackgroundTransparency = 0.7
    hair.BorderSizePixel = 0
    hair.ZIndex = 3
    hair.Parent = bar

    local lights = { Color3.fromRGB(255, 95, 87), Color3.fromRGB(254, 188, 46), Color3.fromRGB(40, 200, 64) }
    for i, col in ipairs(lights) do
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

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Custom Cursor"
    title.Font = Theme.fonts.title
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(210, 210, 216)
    title.ZIndex = 3
    title.Parent = bar

    -- Category bar
    local catBar = Instance.new("Frame")
    catBar.Size = UDim2.new(1, 0, 0, 36)
    catBar.Position = UDim2.fromOffset(0, TB)
    catBar.BackgroundTransparency = 1
    catBar.ZIndex = 3
    catBar.Parent = win

    local catScroll = Instance.new("ScrollingFrame")
    catScroll.Size = UDim2.new(1, -24, 0, 36)
    catScroll.Position = UDim2.fromOffset(12, 0)
    catScroll.BackgroundTransparency = 1
    catScroll.BorderSizePixel = 0
    catScroll.ScrollBarThickness = 0
    catScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    catScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.X
    catScroll.ScrollingDirection = Enum.ScrollingDirection.X
    catScroll.ScrollBarImageTransparency = 1
    catScroll.ZIndex = 3
    catScroll.Parent = catBar

    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    catLayout.Padding = UDim.new(0, 6)
    catLayout.Parent = catScroll

    local activeCat = "All"
    local catButtons = {}

    local function selectCat(cat)
        activeCat = cat
        for _, btn in ipairs(catButtons) do
            if btn.cat == cat then
                Util.tween(btn.bg, { BackgroundColor3 = ACCENT, BackgroundTransparency = 0 }, 0.15)
                btn.label.TextColor3 = WHITE
            else
                Util.tween(btn.bg, { BackgroundColor3 = WHITE, BackgroundTransparency = 0.92 }, 0.15)
                btn.label.TextColor3 = DIM
            end
        end
        renderGrid()
    end

    for _, cat in ipairs(CATEGORIES) do
        local bg = Instance.new("Frame")
        bg.Size = UDim2.fromOffset(0, 28)
        bg.AutomaticSize = Enum.AutomaticSize.X
        bg.BackgroundColor3 = cat == activeCat and ACCENT or WHITE
        bg.BackgroundTransparency = cat == activeCat and 0 or 0.92
        bg.BorderSizePixel = 0
        bg.ZIndex = 4
        bg.Parent = catScroll
        Util.corner(bg, 14)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromOffset(0, 28)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Padding = UDim.new(0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. cat .. "  "
        lbl.Font = Theme.fonts.body
        lbl.TextSize = 13
        lbl.TextColor3 = cat == activeCat and WHITE or DIM
        lbl.ZIndex = 5
        lbl.Parent = bg

        local btn = Instance.new("TextButton")
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Size = UDim2.fromScale(1, 1)
        btn.BackgroundTransparency = 1
        btn.ZIndex = 6
        btn.Parent = bg
        btn.MouseButton1Click:Connect(function() selectCat(cat) end)

        table.insert(catButtons, { cat = cat, bg = bg, label = lbl, btn = btn })
    end

    -- Grid area
    local gridY = TB + 36 + 4
    local gridH = H - gridY - 8
    local grid = Instance.new("ScrollingFrame")
    grid.Size = UDim2.fromOffset(W - 24, gridH)
    grid.Position = UDim2.fromOffset(12, gridY)
    grid.BackgroundTransparency = 1
    grid.BorderSizePixel = 0
    grid.ScrollBarThickness = 4
    grid.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 128)
    grid.ScrollBarImageTransparency = 0.4
    grid.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
    grid.ZIndex = 3
    grid.Parent = win

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.fromOffset(84, 96)
    gridLayout.CellPadding = UDim2.fromOffset(10, 10)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.StartCorner = Enum.StartCorner.TopLeft
    gridLayout.Parent = grid

    local gridPad = Instance.new("UIPadding")
    gridPad.PaddingTop = UDim.new(0, 4)
    gridPad.Parent = grid

    local gridCards = {}
    local function renderGrid()
        for _, card in ipairs(gridCards) do card.frame:Destroy() end
        gridCards = {}
        gridLayout.Parent = nil
        gridLayout.Parent = grid

        for _, c in ipairs(CURSORS) do
            if activeCat ~= "All" and c.cat ~= activeCat then continue end

            local frame = Instance.new("TextButton")
            frame.Text = ""
            frame.AutoButtonColor = false
            frame.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
            frame.BackgroundTransparency = 0.12
            frame.BorderSizePixel = 0
            frame.ZIndex = 3
            frame.Parent = grid
            Util.corner(frame, 10)

            -- Current selection indicator
            local sel = Instance.new("Frame")
            sel.Size = UDim2.fromScale(1, 1)
            sel.BackgroundTransparency = (c.id == activeId) and 0.7 or 1
            sel.BackgroundColor3 = ACCENT
            sel.BorderSizePixel = 0
            sel.ZIndex = 4
            sel.Parent = frame
            Util.corner(sel, 10)
            Util.stroke(frame, ACCENT, 2, (c.id == activeId) and 0.3 or 1)

            -- Cursor preview
            local preview = Instance.new("TextLabel")
            preview.Size = UDim2.fromOffset(38, 38)
            preview.Position = UDim2.fromScale(0.5, 0.5)
            preview.AnchorPoint = Vector2.new(0.5, 0.5)
            preview.BackgroundTransparency = 1
            preview.Font = Enum.Font.Gotham
            preview.Text = c.char
            preview.TextColor3 = c.color
            preview.TextSize = c.size
            preview.ZIndex = 5
            preview.Parent = frame

            -- Name label
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -4, 0, 16)
            nameLbl.Position = UDim2.new(0, 2, 1, -18)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.fonts.caption
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = DIM
            nameLbl.Text = c.name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Center
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex = 5
            nameLbl.Parent = frame

            frame.MouseButton1Click:Connect(function()
                applyCursor(c.id)
                renderGrid()
            end)

            table.insert(gridCards, { frame = frame, id = c.id })
        end

        -- If no items, show a message
        if #gridCards == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.fromOffset(W - 40, 40)
            empty.BackgroundTransparency = 1
            empty.Font = Theme.fonts.caption
            empty.TextSize = 14
            empty.TextColor3 = DIM
            empty.Text = "No cursors in this category yet."
            empty.ZIndex = 4
            empty.Parent = grid
            table.insert(gridCards, { frame = empty })
        end
    end
    renderGrid()

    -- Disable toggle button at bottom
    local disableBtn = Instance.new("TextButton")
    disableBtn.Size = UDim2.fromOffset(100, 26)
    disableBtn.Position = UDim2.new(1, -104, 1, -34)
    disableBtn.BackgroundColor3 = WHITE
    disableBtn.BackgroundTransparency = 0.88
    disableBtn.BorderSizePixel = 0
    disableBtn.AutoButtonColor = false
    disableBtn.Text = "Disable"
    disableBtn.Font = Theme.fonts.body
    disableBtn.TextSize = 12
    disableBtn.TextColor3 = Color3.fromRGB(255, 95, 87)
    disableBtn.ZIndex = 4
    disableBtn.Parent = win
    Util.corner(disableBtn, 13)

    disableBtn.MouseButton1Click:Connect(function()
        stopOverlay()
        activeId = nil
        Util.save("CursorPref", "")
        renderGrid()
    end)

    return { close = close }
end

-- Auto-restore on startup (called from init)
function CursorApp.restore()
    restoreSaved()
end

return CursorApp
