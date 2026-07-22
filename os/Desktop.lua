-- SYNC / os / Desktop
-- The desktop you land on after choosing "Desktop": a wallpaper plus the dock.
-- Menu bar and windows come next. Desktop.start() -> { destroy }.

local Util        = SYNC.import("core/Util")
local Dock        = SYNC.import("os/Dock")
local Settings    = SYNC.import("os/Settings")
local MenuBar     = SYNC.import("os/MenuBar")
local Home        = SYNC.import("apps/Home")
local Scripts     = SYNC.import("apps/Scripts")
local Joiner      = SYNC.import("apps/Joiner")
local MusicApp    = SYNC.import("apps/Music")
local DesktopMode = SYNC.import("os/DesktopMode")
local WM          = SYNC.import("os/WindowManager")

local Desktop = {}

function Desktop.start()
    -- No wallpaper: the menu bar + dock float over the actual game screen.
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Desktop"
    Util.mount(gui)
    gui.DisplayOrder = 5000000 -- dock/desktop always sits above app windows

    -- Menu bar hidden for now (module kept for later): local menubar = MenuBar.create(gui)
    local menubar = nil

    -- Bring an app window to the front (window manager handles focus + dimming).
    local function raise(appName)
        local host = gui.Parent
        local w = host and host:FindFirstChild("SYNC_" .. appName)
        if w then WM.focus(w) end
    end

    local dock
    dock = Dock.create(gui, function(appName)
        if appName == "Home" then
            Home.open()
            raise("Home")
        elseif appName == "Scripts" then
            Scripts.open()
            raise("Scripts")
        elseif appName == "Joiner" then
            Joiner.open()
            raise("Joiner")
        elseif appName == "Music" then
            MusicApp.open()
            raise("Music")
        elseif appName == "Settings" then
            Settings.open({
                position = dock.getPosition(),
                onPosition = function(p)
                    dock.setPosition(p)
                    Util.save("DockPosition", p)
                end,
                alwaysShow = Util.load("DockAlwaysShow") == "true",
                onAlwaysShow = function(v)
                    Util.save("DockAlwaysShow", v and "true" or "false")
                    dock.setAlwaysShow(v)
                end,
                mag = dock.getMagFrac(),
                onMag = function(f)
                    dock.setMagnification(f)
                    Util.save("DockMagFrac", tostring(f))
                end,
                dockSize = dock.getDockFrac(),
                onDockSize = function(f)
                    dock.setDockSize(f)
                    Util.save("DockSizeFrac", tostring(f))
                end,
                desktopMode = DesktopMode.isOn(),
                onDesktopMode = function(v)
                    DesktopMode.set(v)
                end,
            })
            raise("Settings")
        end
    end)

    -- Restore Desktop mode if it was left on
    if DesktopMode.isOn() then
        task.defer(function() DesktopMode.enable() end)
    end

    return {
        gui = gui,
        destroy = function()
            if dock then dock.destroy() end
            if menubar then menubar.destroy() end
            DesktopMode.disable()
            gui:Destroy()
        end,
    }
end

return Desktop
