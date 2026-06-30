-- SYNC / os / Desktop
-- The desktop you land on after choosing "Desktop": a wallpaper plus the dock.
-- Menu bar and windows come next. Desktop.start() -> { destroy }.

local Util     = SYNC.import("core/Util")
local Dock     = SYNC.import("os/Dock")
local Settings = SYNC.import("os/Settings")
local MenuBar  = SYNC.import("os/MenuBar")
local Browser  = SYNC.import("os/Browser")
local Cursor   = SYNC.import("apps/Cursor")
local Discord  = SYNC.import("apps/Discord")

local Desktop = {}

function Desktop.start()
    -- No wallpaper: the menu bar + dock float over the actual game screen.
    local gui = Instance.new("ScreenGui")
    gui.Name = "SYNC_Desktop"
    Util.mount(gui)

    -- Menu bar hidden for now (module kept for later): local menubar = MenuBar.create(gui)
    local menubar = nil

    local dock
    dock = Dock.create(gui, function(appName)
        if appName == "Sense Browser" then
            Browser.open()
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
            })
        elseif appName == "Cursor" then
            Cursor.open()
        elseif appName == "Syncord" then
            Discord.open()
        end
    end)

    Cursor.restore()

    return {
        gui = gui,
        destroy = function()
            if dock then dock.destroy() end
            if menubar then menubar.destroy() end
            gui:Destroy()
        end,
    }
end

return Desktop
