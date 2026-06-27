-- SYNC / ui / Slider
-- macOS-style slider: thin track, filled portion, round draggable knob.
-- Slider.create(parent, initial, onChange) -> { set, get }. Fills parent's width.

local UserInputService = game:GetService("UserInputService")

local Util = SYNC.import("core/Util")

local Slider = {}

local WHITE = Color3.fromRGB(255, 255, 255)

local function clamp01(x) return math.clamp(x, 0, 1) end

function Slider.create(parent, initial, onChange)
    local value = clamp01(initial or 0)
    local baseZ = (parent.ZIndex or 1) + 1

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.Size = UDim2.new(1, 0, 0, 4)
    track.BackgroundColor3 = Color3.fromRGB(74, 74, 80)
    track.BorderSizePixel = 0
    track.ZIndex = baseZ
    track.Parent = parent
    Util.corner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(value, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(236, 236, 240)
    fill.BorderSizePixel = 0
    fill.ZIndex = baseZ
    fill.Parent = track
    Util.corner(fill, 2)

    -- Round knob with a touch of depth (convex shading + drop shadow), Apple style
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(value, 0, 0.5, 0)
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    knob.ZIndex = baseZ + 1
    knob.Parent = track
    Util.corner(knob, 9)
    local kg = Instance.new("UIGradient")
    kg.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(232, 232, 238))
    kg.Rotation = 90
    kg.Parent = knob
    Util.stroke(knob, Color3.fromRGB(0, 0, 0), 1, 0.86)
    Util.shadow(knob, { blur = 8, transparency = 0.55, offset = UDim2.fromOffset(0, 1) })

    -- Transparent hit area for press + drag
    local hit = Instance.new("TextButton")
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.BackgroundTransparency = 1
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.Position = UDim2.fromScale(0.5, 0.5)
    hit.AnchorPoint = Vector2.new(0.5, 0.5)
    hit.ZIndex = baseZ + 2
    hit.Parent = parent

    local function apply()
        fill.Size = UDim2.new(value, 0, 1, 0)
        knob.Position = UDim2.new(value, 0, 0.5, 0)
    end

    local function setFromX(px)
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        value = clamp01((px - track.AbsolutePosition.X) / w)
        apply()
        if onChange then onChange(value) end
    end

    local dragging = false
    local conns = {}
    hit.MouseButton1Down:Connect(function()
        dragging = true
        setFromX(UserInputService:GetMouseLocation().X)
    end)
    conns[#conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    conns[#conns + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    -- Clean up global input connections when the slider is removed
    track.AncestryChanged:Connect(function(_, p)
        if not p then for _, c in ipairs(conns) do c:Disconnect() end end
    end)

    return {
        get = function() return value end,
        set = function(v) value = clamp01(v); apply() end,
    }
end

return Slider
