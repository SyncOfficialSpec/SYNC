-- SYNC / core / SyncCodec
-- A tiny reversible codec for "SYNC codes": free-tier invite links that only the
-- SYNC Joiner can read. A place + server id is XOR-scrambled with a fixed key and
-- re-encoded over a shuffled 64-char alphabet, then prefixed "SYNC-". The result
-- is NOT a valid Roblox link, so it does nothing outside SYNC - which is the point.
-- Premium users skip this and share the real roblox.com link instead.
--
-- SyncCodec.encode(placeId, jobId) -> "SYNC-...."
-- SyncCodec.decode(token) -> placeId (number), jobId (string) | nil

local SyncCodec = {}

-- Shuffled, URL-safe 64-char alphabet (deterministic permutation of the standard
-- set, so encode and decode agree without shipping a literal scrambled string).
local BASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local ALPHA = ""
do
    local n = #BASE
    local idx = 0
    for _ = 1, n do
        idx = (idx + 37) % n -- 37 is coprime with 64 -> visits every index once
        ALPHA = ALPHA .. BASE:sub(idx + 1, idx + 1)
    end
end
local REV = {}
for i = 1, #ALPHA do REV[ALPHA:sub(i, i)] = i - 1 end

local KEY = { 83, 121, 110, 99, 79, 83, 42, 173, 55, 200 } -- fixed scramble key

local function xorApply(bytes)
    local out = {}
    for i, b in ipairs(bytes) do
        out[i] = bit32.bxor(b, KEY[((i - 1) % #KEY) + 1])
    end
    return out
end

-- bytes -> chars (6-bit repacking over ALPHA)
local function packBytes(bytes)
    local out, buf, bits = {}, 0, 0
    for _, b in ipairs(bytes) do
        buf = buf * 256 + b
        bits = bits + 8
        while bits >= 6 do
            bits = bits - 6
            local idx = math.floor(buf / (2 ^ bits)) % 64
            out[#out + 1] = ALPHA:sub(idx + 1, idx + 1)
            buf = buf % (2 ^ bits) -- drop the bits we just emitted (keep buf small + exact)
        end
    end
    if bits > 0 then
        local idx = (buf * (2 ^ (6 - bits))) % 64
        out[#out + 1] = ALPHA:sub(idx + 1, idx + 1)
    end
    return table.concat(out)
end

-- chars -> bytes (inverse of packBytes)
local function unpackChars(str)
    local out, buf, bits = {}, 0, 0
    for i = 1, #str do
        local v = REV[str:sub(i, i)]
        if v then
            buf = buf * 64 + v
            bits = bits + 6
            if bits >= 8 then
                bits = bits - 8
                out[#out + 1] = math.floor(buf / (2 ^ bits)) % 256
                buf = buf % (2 ^ bits)
            end
        end
    end
    return out
end

function SyncCodec.encode(placeId, jobId)
    local payload = tostring(placeId) .. "|" .. tostring(jobId)
    local bytes = {}
    for i = 1, #payload do bytes[i] = payload:byte(i) end
    return "SYNC-" .. packBytes(xorApply(bytes))
end

-- Returns placeId, jobId, or nil if this isn't a SYNC code.
function SyncCodec.decode(token)
    token = tostring(token or ""):gsub("%s+", "")
    local body = token:match("^SYNC%-(.+)$")
    if not body then return nil end
    local ok, pid, jid = pcall(function()
        local bytes = xorApply(unpackChars(body))
        local chars = {}
        for _, b in ipairs(bytes) do chars[#chars + 1] = string.char(b) end
        local payload = table.concat(chars)
        local p, j = payload:match("^(%d+)|(.+)$")
        return p and tonumber(p) or nil, j
    end)
    if ok then return pid, jid end
    return nil
end

function SyncCodec.isSyncCode(token)
    return tostring(token or ""):match("^%s*SYNC%-") ~= nil
end

return SyncCodec
