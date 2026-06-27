-- SYNC / ui / Switch
-- macOS-style toggle: neutral grey track, light/white rounded-rectangle knob
-- (no green). Switch.create(parent, initial, onChange) -> { instance, get, set }

local Util = SYNC.import("core/Util")

local W, H     = 56, 32
local KW, KH   = 30, 26       -- big rounded-rectangle knob, fills most of the track
local KRADIUS  = 11           -- generous corner (rounded rect, not a circle)
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

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(KW, KH)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, knobX(value), 0.5, 0)
    knob.BackgroundColor3 = value and KNOB_ON or KNOB_OFF
    knob.BorderSizePixel = 0
    knob.ZIndex = baseZ + 1
    knob.Parent = track
    Util.corner(knob, KRADIUS) -- rounded rectangle, not a circle
    Util.shadow(knob, { blur = 6, transparency = 0.6, offset = UDim2.fromOffset(0, 1) })

    local function render(animate)
        local kp = { Position = UDim2.new(0, knobX(value), 0.5, 0), BackgroundColor3 = value and KNOB_ON or KNOB_OFF }
        local tp = { BackgroundColor3 = value and TRACK_ON or TRACK_OFF }
        if animate then
            Util.tween(knob, kp, 0.18, Enum.EasingStyle.Quart)
            Util.tween(track, tp, 0.18)
        else
            knob.Position = kp.Position
            knob.BackgroundColor3 = kp.BackgroundColor3
            track.BackgroundColor3 = tp.BackgroundColor3
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
