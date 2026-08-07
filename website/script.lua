--[[
  key_check.lua
  Validates a temporary access key against your Cloudflare Worker before
  letting the rest of your script run.

  USAGE:
    local KeyCheck = loadstring(game:HttpGet("https://yourhost/key_check.lua"))()
    -- or just paste this at the top of your product script

    local ok, info = KeyCheck.validate("THEIR-KEY-HERE")
    if not ok then
      print("Access denied: " .. info)
      return
    end
    print("Key valid, expires in " .. info .. "s")

    -- ... rest of your product code below this line ...
]]

local KeyCheck = {}

-- 1. SET THIS to the Worker URL from the discord-worker README
local WORKER_URL = "https://access-keys.yourname.workers.dev"

-- 2. Point this at whatever HTTP function your executor exposes.
--    Uncomment the one that matches your environment, or wire up your own.
local function http_get(url)
  -- Synapse X / most modern executors:
  if syn and syn.request then
    local res = syn.request({ Url = url, Method = "GET" })
    return res.StatusCode, res.Body
  end
  -- Generic `request` global (KRNL, Fluxus, etc.):
  if request then
    local res = request({ Url = url, Method = "GET" })
    return res.StatusCode, res.Body
  end
  -- Fallback for plain Lua with a socket-based http library (e.g. luasocket):
  local http_ok, http = pcall(require, "socket.http")
  if http_ok then
    local body, code = http.request(url)
    return code, body
  end
  error("No HTTP function available — wire up your executor's request function in http_get()")
end

-- Minimal JSON decode (only handles the flat objects this API returns —
-- swap in a full JSON library if you already use one in your project).
local function decode_json(str)
  local result = {}
  for k, v in str:gmatch('"(%w+)"%s*:%s*("?[%w%.%-]*"?)') do
    v = v:gsub('^"(.*)"$', "%1")
    if v == "true" then v = true
    elseif v == "false" then v = false
    elseif tonumber(v) then v = tonumber(v)
    end
    result[k] = v
  end
  return result
end

-- Returns: ok (boolean), and either seconds-remaining (number) or an error message (string)
function KeyCheck.validate(key)
  if not key or key == "" then
    return false, "no key provided"
  end

  local status, body = http_get(WORKER_URL .. "/validate?key=" .. key)

  if status ~= 200 or not body then
    return false, "could not reach key server"
  end

  local data = decode_json(body)

  if not data.valid then
    return false, "key expired or invalid"
  end

  local remaining = math.floor((tonumber(data.expiresAt) - (os.time() * 1000)) / 1000)
  return true, remaining
end

return KeyCheck
