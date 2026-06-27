-- SYNC / ui / Switch
-- Apple-accurate toggle switch (50x30 track, 26 knob, systemGreen on / gray off).
-- Switch.create(parent, initial, onChange) -> { instance, get, set }

local Util = SYNC.import("core/Util")

local Switch = {}

local W, H    = 50, 30
local KNOB    = 26
local INSET   = 2
local KRADIUS = 9                              -- squircle knob (not a full circle)
local GREEN   = Color3.fromRGB(52, 199, 89)    -- systemGreen (on)
local OFF     = Color3.fromRGB(58, 58, 62)     -- recessed dark off-track
local KNOB_ON  = Color3.fromRGB(255, 255, 255) -- white knob when on
local KNOB_OFF = Color3.fromRGB(222, 222, 226) -- light-gray knob when off
local WHITE   = Color3.fromRGB(255, 255, 255)

local function knobX(on) return on and (W - KNOB - INSET) or INSET end

function Switch.create(parent, initial, onChange)
    local value = initial and true or false

    local track = Instance.new("TextButton")
    track.Text = ""
    track.AutoButtonColor = false
    track.Size = UDim2.fromOffset(W, H)
    track.BackgroundColor3 = value and GREEN or OFF
    track.BorderSizePixel = 0
    track.Parent = parent
    Util.corner(track, H / 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(KNOB, KNOB)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, knobX(value), 0.5, 0)
    knob.BackgroundColor3 = value and KNOB_ON or KNOB_OFF
    knob.BorderSizePixel = 0
    knob.Parent = track
    Util.corner(knob, KRADIUS)
    Util.shadow(knob, { blur = 6, transparency = 0.65, offset = UDim2.fromOffset(0, 1) })

    local function render(animate)
        local kp = { Position = UDim2.new(0, knobX(value), 0.5, 0), BackgroundColor3 = value and KNOB_ON or KNOB_OFF }
        local tp = { BackgroundColor3 = value and GREEN or OFF }
        if animate then
            Util.tween(knob, kp, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            Util.tween(track, tp, 0.2)
        else
            knob.Position = kp.Position
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
