-- SYNC / os / WindowManager
-- macOS-style window focus for app windows. Each app registers its window; the
-- manager raises the clicked window above the others (DisplayOrder), and fades a
-- dim overlay over every window that isn't focused, so the active one stands out.
-- Windows never close from a background click - only the red light or Escape.
--
-- WM.register(gui, win, cornerRadius) -> adds the dim overlay + click-to-focus.
-- WM.focus(gui) -> bring that window to the front.

local Util = SYNC.import("core/Util")

local WM = {}

-- App windows live in this DisplayOrder band; the desktop/dock sits well above it
-- so it is always on top.
local BASE = 400000
local top = 0
local entries = {}

function WM.focus(gui)
    if not gui or not gui.Parent then return end
    top = top + 2
    for _, e in ipairs(entries) do
        if e.gui == gui then
            pcall(function() e.gui.DisplayOrder = BASE + top end)
            Util.tween(e.dim, { BackgroundTransparency = 1 }, 0.16)
        else
            Util.tween(e.dim, { BackgroundTransparency = 0.4 }, 0.16)
        end
    end
end

function WM.register(gui, win, cornerRadius)
    -- dim overlay (covers the whole window; non-interactive so clicks pass through)
    local dim = Instance.new("Frame")
    dim.Name = "WM_Dim"
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 1
    dim.BorderSizePixel = 0
    dim.Active = false
    dim.ZIndex = 900
    dim.Parent = win
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0, cornerRadius or 14)
    uic.Parent = dim

    local entry = { gui = gui, win = win, dim = dim }
    entries[#entries + 1] = entry

    -- clicking anywhere on the window focuses it
    win.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            WM.focus(gui)
        end
    end)

    -- drop the entry when the window is destroyed
    gui.AncestryChanged:Connect(function()
        if not gui.Parent then
            for i, e in ipairs(entries) do
                if e.gui == gui then table.remove(entries, i) break end
            end
        end
    end)

    WM.focus(gui)
    return dim
end

return WM
