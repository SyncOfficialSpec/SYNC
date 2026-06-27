-- SYNC / init
-- Entry module. Runs the boot sequence, then hands off to the desktop.
-- (Desktop/menubar/dock land in the next milestone.)

local Boot = SYNC.import("os/Boot")

Boot.run(function()
    -- TODO: launch Desktop here once built.
    -- Desktop.start()
end)
