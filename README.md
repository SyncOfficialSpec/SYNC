<div align="center">

# SYNC

### A macOS / iPadOS-style desktop OS, running inside Roblox.

Boot screen, wallpaper, menubar, a magnifying dock, draggable windows and real
built-in apps — rendered with native Roblox UI for authentic rounded corners,
hairline borders and smooth spring animations.

</div>

---

## What is SYNC?

SYNC turns your Roblox executor into a tiny desktop computer. Run one line and
you get the full Apple-style experience: it boots with the logo and progress bar,
fades into a desktop with a wallpaper, a top menubar with a live clock, and a
dock at the bottom that magnifies as you hover. Open apps in draggable windows
with the classic red/yellow/green traffic-light buttons.

It's built to *look and feel* like the real thing — light and dark modes, the
exact system blue accent, Gotham/SF-style fonts, and animations tuned to match
macOS timing.

## Use it

Paste this into your executor and run:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/SyncOfficialSpec/SYNC/main/build/SYNC.lua"))()
```

That's it. SYNC mounts itself (surviving respawns and teleports) and boots.

> **Status:** early. Right now this boots and runs the device selector. The
> desktop, menubar, dock and apps are landing next — re-run the loadstring any
> time to get the latest build.

## Features

- macOS-style **boot sequence** (logo + progress bar)
- **Light & dark** system themes with the real accent colors
- First-run **device selector** (Mobile / Tablet / Desktop) with saved preference
- Survives respawn / teleport (mounts to CoreGui via `gethui`)
- *Coming:* desktop + wallpaper, menubar + clock, magnifying dock, draggable
  windows, and built-in apps (Settings, Notes, Terminal, About This Mac)

## For developers

SYNC is written as small, readable Lua modules and bundled into one
executor-ready file.

```
core/     Theme (light/dark palette), Util (mount, settings, UI helpers)
ui/       reusable widgets + Window
os/       Boot, Desktop, MenuBar, Dock, WindowManager
apps/     Settings, Notes, Terminal, About
init.lua  entry module
build/    bundle.py -> build/SYNC.lua  (the hosted file the loadstring fetches)
```

Build the single file from sources:

```bash
python3 build/bundle.py        # -> build/SYNC.lua
```

Each module registers with `SYNC.define(name, fn)` and is pulled lazily via
`SYNC.import("core/Theme")`; `init` runs last.

---

<div align="center">
<sub>SYNC · made by SyncOfficialSpec</sub>
</div>
