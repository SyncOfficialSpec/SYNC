# SYNC

A macOS / iPadOS-style desktop OS experience for Roblox executors. Boot screen,
wallpaper, menubar, dock, draggable windows and built-in apps, rendered with real
Roblox UI instances for authentic rounded corners, hairline strokes and smooth
spring animations.

## Project layout

```
core/    Theme (light/dark palette), Util (mount, settings, UI helpers)
ui/      reusable widgets + Window (coming)
os/      Boot, Desktop, MenuBar, Dock, WindowManager (Boot done)
apps/    Settings, Notes, Terminal, About (coming)
init.lua entry module
build/   bundle.py -> build/SYNC.lua (single executor-ready file)
```

## Build

Sources are modular for maintainability. The executor target is a single file:

```
python3 build/bundle.py        # -> build/SYNC.lua
```

Each module registers via `SYNC.define(name, fn)` and is pulled lazily with
`SYNC.import("core/Theme")`. `init` runs last.

## Source protection

Develop in clean source; obfuscate only the built `build/SYNC.lua` for release
(Prometheus for local builds; Luraph / MoonSec for strongest release builds).
Distribute via `loadstring(game:HttpGet("<raw url to obfuscated build>"))()`.

## Status

Foundation: Theme, Util, Boot screen, bundler. Next: Desktop + MenuBar + Dock.
