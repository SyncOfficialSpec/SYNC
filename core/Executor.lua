-- SYNC / core / Executor
-- In-game script runner. SYNC runs scripts itself the same way Sirius does -
-- the executor's own loadstring - so a click executes instantly with no manual
-- paste. This wraps that with a reliable fetch (rscripts' /raw/ endpoint
-- randomly serves a Cloudflare HTML page instead of Lua, which loadstring can't
-- run), HTML detection + retries, and protected execution that surfaces errors.
--
--   Executor.run(source, name)   -> ok, err
--   Executor.fetch(url)          -> source|nil, reason
--   Executor.runUrl(url, name)   -> ok, err   (fetch + run)

local Util = SYNC.import("core/Util")

local Executor = {}

-- loadstring is provided by the host executor. SYNC only runs because an
-- executor executed it, so this always exists; grab it defensively anyway.
local _loadstring = loadstring

local function looksLikeHTML(s)
    if not s or #s == 0 then return false end
    local head = s:sub(1, 400):lower()
    return head:find("<!doctype html", 1, true) ~= nil
        or head:find("<html", 1, true) ~= nil
        or head:find("cf-browser-verification", 1, true) ~= nil
        or head:find("just a moment", 1, true) ~= nil
end

-- Fetch raw Lua for a URL. Retries a few times because the challenge page is
-- transient. Returns (source, nil) or (nil, reason).
function Executor.fetch(url, tries)
    tries = tries or 4
    local lastReason = "no response"
    for attempt = 1, tries do
        local body = Util.httpGet(url)
        if body and body ~= "" then
            if looksLikeHTML(body) then
                lastReason = "host returned a web page, not a script"
            else
                return body, nil
            end
        else
            lastReason = "download failed"
        end
        if attempt < tries then task.wait(0.6) end
    end
    return nil, lastReason
end

-- Run Lua source. loadstring compiles it; we run in a fresh thread under pcall
-- so a script that errors (dead link wrappers are common) can't take SYNC down
-- and the failure is reported. Returns (ok, err). err is a compile message when
-- ok is false before the thread starts, or a runtime message after.
function Executor.run(source, name)
    if type(source) ~= "string" or source == "" then
        return false, "empty script"
    end
    if looksLikeHTML(source) then
        return false, "that's a web page, not a script"
    end
    local fn, compileErr = _loadstring(source, "=" .. tostring(name or "SYNC"))
    if not fn then
        return false, "compile error: " .. tostring(compileErr):gsub("\n.*", "")
    end

    -- Report a runtime error back to the caller. The script runs in its own
    -- thread so long-running scripts don't block; we only forward an error if
    -- it happens synchronously on start (most dead-link wrappers fail instantly).
    local done, runOk, runErr = false, true, nil
    task.spawn(function()
        runOk, runErr = pcall(fn)
        done = true
    end)
    -- give the thread a moment to fault on start
    for _ = 1, 20 do
        if done then break end
        task.wait(0.05)
    end
    if done and not runOk then
        return false, "runtime error: " .. tostring(runErr):gsub("\n.*", "")
    end
    return true, nil
end

-- Fetch a URL and run it. Returns (ok, err).
function Executor.runUrl(url, name)
    local src, reason = Executor.fetch(url)
    if not src then return false, reason end
    return Executor.run(src, name)
end

pcall(function()
    if typeof(getgenv) == "function" then getgenv().SYNCExecutor = Executor end
end)

return Executor
