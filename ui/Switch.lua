-- SYNC / ui / Switch
-- macOS-style toggle: neutral grey track, light/white rounded-rectangle knob
-- (no green). Switch.create(parent, initial, onChange) -> { instance, get, set }

local Util = SYNC.import("core/Util")

local W, H     = 54, 26       -- slim, elongated track
local KW, KH   = 26, 20       -- rounded-rectangle knob
local KRADIUS  = 8            -- rounded corner (not a circle)
local INSET_X  = 3
local TRACK_OFF = Color3.fromRGB(78, 78, 84)    -- grey off-track
local TRACK_ON  = Color3.fromRGB(128, 128, 134) -- lighter grey when on
local KNOB_OFF  = Color3.fromRGB(245, 245, 248) -- near-white knob
local KNOB_ON   = Color3.fromRGB(255, 255, 255) -- white knob

local Switch = {}

local function knobX(on) return on and (W - KW - INSET_X) or INSET_X end

function Switch.create(parent, initial, onChange)
    local value = initial and true or false

    local baseZ = (parent.ZIndex or 1) + 1

    local track = Instance.new("TextButton")
    track.Text = ""
    track.AutoButtonColor = false
    track.Size = UDim2.fromOffset(W, H)
    track.BackgroundColor3 = value and TRACK_ON or TRACK_OFF
    track.BorderSizePixel = 0
    track.ZIndex = baseZ
    track.Parent = parent
    Util.corner(track, H / 2)
    -- Recessed depth: darken the top of the track (multiplied over its colour),
    -- plus a faint inner edge.
    local tgrad = Instance.new("UIGradient")
    tgrad.Color = ColorSequence.new(Color3.fromRGB(196, 196, 196), Color3.fromRGB(255, 255, 255))
    tgrad.Rotation = 90
    tgrad.Parent = track
    Util.stroke(track, Color3.fromRGB(0, 0, 0), 1, 0.72)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(KW, KH)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, knobX(value), 0.5, 0)
    knob.BackgroundColor3 = value and KNOB_ON or KNOB_OFF
    knob.BorderSizePixel = 0
    knob.ZIndex = baseZ + 1
    knob.Parent = track
    Util.corner(knob, KRADIUS) -- rounded rectangle, not a circle
    -- Convex shading (lighter top, slightly darker bottom)
    local kgrad = Instance.new("UIGradient")
    kgrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(234, 234, 238))
    kgrad.Rotation = 90
    kgrad.Parent = knob
    Util.shadow(knob, { blur = 7, transparency = 0.55, offset = UDim2.fromOffset(0, 1) }) -- drop shadow
    Util.shadow(knob, { blur = 12, transparency = 0.6, offset = UDim2.fromOffset(0, 0), color = Color3.fromRGB(255, 255, 255) }) -- soft glow

    -- squash pulse on toggle (iOS-style tactile bounce)
    local kscale = Instance.new("UIScale")
    kscale.Parent = knob

    local function render(animate)
        local kp = { Position = UDim2.new(0, knobX(value), 0.5, 0), BackgroundColor3 = value and KNOB_ON or KNOB_OFF }
        local tp = { BackgroundColor3 = value and TRACK_ON or TRACK_OFF }
        if animate then
            Util.tween(knob, kp, 0.18, Enum.EasingStyle.Quart)
            Util.tween(track, tp, 0.18)
            kscale.Scale = 1
            Util.tween(kscale, { Scale = 1.12 }, 0.09)
            task.delay(0.1, function() Util.tween(kscale, { Scale = 1 }, 0.12, Enum.EasingStyle.Back) end)
        else
            knob.Position = kp.Position
            knob.BackgroundColor3 = kp.BackgroundColor3
            track.BackgroundColor3 = tp.BackgroundColor3
            kscale.Scale = 1
        end
    end

    track.MouseButton1Click:Connect(function()
        value = not value
        render(true)
        if onChange then onChange(value) end
    end)

    return {
        instance = track,
        get = function() return value end,
        set = function(v, animate) value = v and true or false; render(animate ~= false) end,
    }
end

return Switch
