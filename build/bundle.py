#!/usr/bin/env python3
"""SYNC bundler.

Concatenates the modular Lua sources under core/ ui/ os/ apps/ plus init.lua
into a single executor-ready file (build/SYNC.lua). Each module is registered
with SYNC.define(name, fn) and pulled in lazily via SYNC.import(name), where
`name` is the path relative to the project root without the .lua extension
(e.g. "core/Theme").

The bundle exposes SYNC as both a local upvalue (so modules close over it) and
on getgenv() when available, then runs the "init" module.

Usage:  python3 build/bundle.py
Output: build/SYNC.lua   (feed this to Prometheus/Luraph/MoonSec to obfuscate)
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRS = ["core", "ui", "os", "apps"]
OUT = os.path.join(ROOT, "build", "SYNC.lua")

# Load order only matters for define() registration; import() is lazy, so any
# order works as long as init runs last. We still sort for deterministic output.

def collect():
    modules = []
    for d in DIRS:
        dpath = os.path.join(ROOT, d)
        if not os.path.isdir(dpath):
            continue
        for fn in sorted(os.listdir(dpath)):
            if fn.endswith(".lua"):
                name = f"{d}/{fn[:-4]}"
                modules.append((name, os.path.join(dpath, fn)))
    init = os.path.join(ROOT, "init.lua")
    if os.path.exists(init):
        modules.append(("init", init))
    return modules


RUNTIME = """-- ============================================================
--  SYNC  -  macOS-style desktop OS for Roblox executors
--  Generated bundle. Do not edit by hand; edit sources + rebundle.
-- ============================================================
local SYNC = {}
do
    local modules, cache = {}, {}
    function SYNC.define(name, fn) modules[name] = fn end
    function SYNC.import(name)
        local c = cache[name]
        if c ~= nil then return c end
        local fn = modules[name]
        if not fn then error("SYNC: module not found: " .. tostring(name), 2) end
        local r = fn()
        if r == nil then r = true end
        cache[name] = r
        return r
    end
end
pcall(function()
    if typeof(getgenv) == "function" then getgenv().SYNC = SYNC end
end)

"""


def main():
    modules = collect()
    if not modules:
        print("No modules found.", file=sys.stderr)
        return 1

    parts = [RUNTIME]
    for name, path in modules:
        with open(path, "r", encoding="utf-8") as f:
            src = f.read()
        parts.append(f'SYNC.define("{name}", function()\n')
        parts.append(src.rstrip("\n"))
        parts.append("\nend)\n\n")

    parts.append('SYNC.import("init")\n')

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("".join(parts))

    size = os.path.getsize(OUT)
    print(f"Bundled {len(modules)} modules -> {OUT} ({size} bytes)")
    for name, _ in modules:
        print(f"  + {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
