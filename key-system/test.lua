local HttpService = game:GetService("HttpService")

local WORKER_URL = "https://access-keys.xenopersonalbusiness.workers.dev"

local SCRIPTS = {
    [14890802310] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
    [74747090658891] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Bizzare-Lineage/refs/heads/main/Main",
    [130169555191153] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/universalpiece/refs/heads/main/main",
    [15694107053] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Jujutsu-Legacy/refs/heads/main/main",
    [17889317592] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Jujutsu-Legacy/refs/heads/main/main",
    [18795268508] = "https://raw.githubusercontent.com/xenopersonalbusiness-dot/Jujutsu-Legacy/refs/heads/main/main",
}

local AUTH_DIR = "XenoKeySystem"
local AUTH_FILE = "XenoKeySystem/auth_cache.json"
local SESSION_DURATION = 86400

local function urlEncode(str)
    return tostring(str):gsub("([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function doRequest(url, method)
    method = method or "GET"
    if syn and syn.request then
        local ok, res = pcall(syn.request, { Url = url, Method = method })
        if ok and res and res.StatusCode then return res.StatusCode, res.Body end
    end
    if http_request and type(http_request) == "function" then
        local ok, res = pcall(http_request, { Url = url, Method = method })
        if ok and res and res.StatusCode then return res.StatusCode, res.Body end
    end
    if request and type(request) == "function" then
        local ok, res = pcall(request, { Url = url, Method = method })
        if ok and res and res.StatusCode then return res.StatusCode, res.Body end
    end
    if method == "GET" then
        local ok, body = pcall(game.HttpGet, game, url)
        if ok and body then return 200, body end
    end
    if method == "POST" then
        local ok, body = pcall(game.HttpPost, game, url, "")
        if ok and body then return 200, body end
    end
    return nil, nil
end

local function saveAuth(key)
    pcall(function()
        if not isfolder(AUTH_DIR) then makefolder(AUTH_DIR) end
        writefile(AUTH_FILE, HttpService:JSONEncode({ key = key, timestamp = os.time() }))
    end)
end

local function getCachedKey()
    local ok, result = pcall(function()
        if isfile(AUTH_FILE) then
            local data = HttpService:JSONDecode(readfile(AUTH_FILE))
            if data and data.key and data.timestamp and (os.time() - data.timestamp) < SESSION_DURATION then
                return data.key
            end
        end
        return nil
    end)
    return ok and result
end

local function clearAuth()
    pcall(function()
        if isfile(AUTH_FILE) then delfile(AUTH_FILE) end
    end)
end

local function detectExecutor()
    if identifyexecutor then
        local ok, name, version = pcall(identifyexecutor)
        if ok and name then
            if version and version ~= "" then
                return tostring(name) .. " " .. tostring(version)
            end
            return tostring(name)
        end
    end
    if syn then return "Synapse X" end
    if KRNL_LOADED then return "KRNL" end
    if FluxusAndroid or Fluxus then return "Fluxus" end
    if is_sirhurt then return "SirHurt" end
    if pebc_load then return "ProtoSmasher" end
    if OXYGEN_LOADED then return "Oxygen U" end
    if Electron then return "Electron" end
    return "Unknown"
end

local function bindAccount(key)
    pcall(function()
        local player = game.Players.LocalPlayer
        if player then
            local executor = detectExecutor()
            local bindUrl = WORKER_URL .. "/bind?key=" .. urlEncode(key) .. "&username=" .. urlEncode(player.Name) .. "&executor=" .. urlEncode(executor)
            doRequest(bindUrl, "POST")
        end
    end)
end

local function checkServerBinding(key)
    local status, body = doRequest(WORKER_URL .. "/validate?key=" .. urlEncode(key))
    if status ~= 200 or not body then
        return false, "could not reach key server"
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or not data then
        return false, "invalid server response"
    end
    if not data.valid then
        return false, "key expired or invalid"
    end
    if not data.username then
        return false, "account not bound"
    end
    return true, data.username
end

local function validateKey(key)
    if not key or key == "" then
        return false, "no key provided"
    end
    local status, body = doRequest(WORKER_URL .. "/validate?key=" .. urlEncode(key))
    if status ~= 200 or not body then
        return false, "could not reach key server"
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or not data then
        return false, "invalid server response"
    end
    if not data.valid then
        return false, "key expired or invalid"
    end
    bindAccount(key)
    return true, "ok"
end

local function loadGameScript()
    local src = SCRIPTS[game.PlaceId]
    if src then
        loadstring(game:HttpGet(src))()
    else
        pcall(function()
            local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
            local W = Rayfield:CreateWindow({ Name = "Xeno's", KeySystem = false })
            local T = W:CreateTab("Info", 4483362458)
            T:CreateSection("Notice")
            T:CreateParagraph({ Title = "Unsupported Game", Content = "This game is not supported yet." })
        end)
    end
end

local function showFallbackGui(title, msg)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "XenoKeySystem"
        sg.ResetOnSpawn = false
        sg.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 360, 0, 200)
        f.Position = UDim2.new(0.5, -180, 0.5, -100)
        f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        f.BorderSizePixel = 0
        f.Parent = sg

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10)
        c.Parent = f

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -30, 0, 40)
        t.Position = UDim2.new(0, 15, 0, 20)
        t.BackgroundTransparency = 1
        t.Text = title
        t.TextColor3 = Color3.fromRGB(236, 236, 230)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 18
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = f

        local m = Instance.new("TextLabel")
        m.Size = UDim2.new(1, -30, 0, 100)
        m.Position = UDim2.new(0, 15, 0, 60)
        m.BackgroundTransparency = 1
        m.Text = msg
        m.TextColor3 = Color3.fromRGB(138, 138, 133)
        m.Font = Enum.Font.Gotham
        m.TextSize = 14
        m.TextWrapped = true
        m.TextXAlignment = Enum.TextXAlignment.Left
        m.TextYAlignment = Enum.TextYAlignment.Top
        m.Parent = f

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -30, 0, 36)
        b.Position = UDim2.new(0, 15, 1, -50)
        b.BackgroundColor3 = Color3.fromRGB(236, 236, 230)
        b.Text = "Copy Error"
        b.TextColor3 = Color3.fromRGB(20, 20, 20)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.Parent = f

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 6)
        bc.Parent = b

        b.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(msg) end)
        end)
    end)
end

local function safeLoadRayfield()
    local ok, Rayfield = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)
    if ok and Rayfield then return Rayfield end
    return nil
end

if not SCRIPTS[game.PlaceId] then
    local Rayfield = safeLoadRayfield()
    if Rayfield then
        local W = Rayfield:CreateWindow({ Name = "Xeno's", KeySystem = false })
        local T = W:CreateTab("Info", 4483362458)
        T:CreateSection("Notice")
        T:CreateParagraph({ Title = "Unsupported Game", Content = "This game is not supported. Join the Discord for updates." })
    else
        showFallbackGui("Unsupported Game", "This game is not supported. Join the Discord for updates.")
    end
    return
end

local cachedKey = getCachedKey()
if cachedKey then
    local bound, username = checkServerBinding(cachedKey)
    if bound then
        loadGameScript()
        return
    else
        clearAuth()
    end
end

local Rayfield = safeLoadRayfield()
if not Rayfield then
    showFallbackGui("Xeno's Key System", "Rayfield UI failed to load. Your executor may not support HttpGet.\n\nTry a different executor or check the Discord for supported executors.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Xeno's - Key System",
    LoadingTitle = "Loading",
    LoadingSubtitle = "Almost there...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local AuthTab = Window:CreateTab("Verification", 4483362458)
local sessionKey = ""

AuthTab:CreateSection("License Key")

AuthTab:CreateInput({
    Name = "Enter Key",
    PlaceholderText = "Paste your key here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        sessionKey = value:gsub("%s+", "")
    end,
})

AuthTab:CreateButton({
    Name = "Verify Key",
    Callback = function()
        if sessionKey == "" then
            return Rayfield:Notify({ Title = "Error", Content = "Please enter a key!", Duration = 3, Image = 4483362458 })
        end

        Rayfield:Notify({ Title = "Verifying", Content = "Checking key...", Duration = 2, Image = 4483362458 })

        task.delay(1.6, function()
            local ok, msg = validateKey(sessionKey)

            if ok then
                local bound, username = checkServerBinding(sessionKey)
                if not bound then
                    Rayfield:Notify({ Title = "Error", Content = "Key valid but account not bound. Please wait and try again.", Duration = 4, Image = 4483362458 })
                    return
                end
                Rayfield:Notify({ Title = "Success", Content = "Key valid! Loading...", Duration = 3, Image = 4483362458 })
                task.wait(1)
                saveAuth(sessionKey)
                Rayfield:Destroy()
                loadGameScript()
            else
                Rayfield:Notify({ Title = "Failed", Content = msg, Duration = 4, Image = 4483362458 })
            end
        end)
    end,
})
