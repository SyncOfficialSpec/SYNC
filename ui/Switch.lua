-- SYNC / ui / Switch
-- macOS-style toggle switch. Switch.create(parent, initial, onChange) -> { set, get }
-- Animates the knob slide + track color (gray -> system green).

local Util = SYNC.import("core/Util")

local Switch = {}

local W, H = 46, 28
local KNOB = 24
local GREEN = Color3.fromRGB(48, 209, 88)
local OFF = Color3.fromRGB(90, 90, 98)
local WHITE = Color3.fromRGB(255, 255, 255)

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
    knob.AnchorPoint = Vector2.new(value and 1 or 0, 0.5)
    knob.Position = UDim2.new(value and 1 or 0, value and -2 or 2, 0.5, 0)
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    knob.Parent = track
    Util.corner(knob, KNOB / 2)
    Util.shadow(knob, { blur = 8, transparency = 0.7, offset = UDim2.fromOffset(0, 1) })

    local function render(animate)
        local props = {
            [knob] = {
                AnchorPoint = Vector2.new(value and 1 or 0, 0.5),
                Position = UDim2.new(value and 1 or 0, value and -2 or 2, 0.5, 0),
            },
            [track] = { BackgroundColor3 = value and GREEN or OFF },
        }
        if animate then
            Util.tween(knob, props[knob], 0.18, Enum.EasingStyle.Quart)
            Util.tween(track, props[track], 0.18)
        else
            for inst, p in pairs(props) do for k, v in pairs(p) do inst[k] = v end end
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
        set = function(v, animate)
            value = v and true or false
            render(animate ~= false)
        end,
    }
end

return Switch
