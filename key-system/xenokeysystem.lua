local HttpService = game:GetService("HttpService")

local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service = "Keysystem"
Junkie.identifier = "1007847"
Junkie.provider = "Key System"

local WEBSITE_URL = "https://xenos-intestine.pages.dev"

local AUTH_DIR = "XenoKeySystem"
local AUTH_FILE = "XenoKeySystem/auth_cache.json"
local SESSION_DURATION = 86400

local function saveAuth(key, expiresAt)
    pcall(function()
        if not isfolder(AUTH_DIR) then makefolder(AUTH_DIR) end
        writefile(AUTH_FILE, HttpService:JSONEncode({ key = key, timestamp = os.time(), expiresAt = expiresAt }))
    end)
end

local function getCachedKey()
    local ok, result = pcall(function()
        if isfile(AUTH_FILE) then
            local data = HttpService:JSONDecode(readfile(AUTH_FILE))
            if data and data.key and data.timestamp and (os.time() - data.timestamp) < SESSION_DURATION then
                return data.key, data.expiresAt
            end
        end
        return nil, nil
    end)
    return ok and result
end

local function clearAuth()
    pcall(function()
        if isfile(AUTH_FILE) then delfile(AUTH_FILE) end
    end)
end

local LAYER2 = "2d2d204c4159455220313a20536372697074206665746368657220776974682068696464656e20776562736974652055524c730a2d2d2054686973206973206f62667573636174656420696e746f204c6179657220320a0a6c6f63616c2042415345203d202268747470733a2f2f78656e6f732d696e74657374696e652e70616765732e6465762f6173736574732f646174612f736372697074732f220a6c6f63616c2053435249505453203d207b0a202020205b31343839303830323331305d203d2042415345202e2e2022612e62696e222c0a202020205b37343734373039303635383839315d203d2042415345202e2e2022612e62696e222c0a202020205b3133303136393535353139313135335d203d2042415345202e2e2022622e62696e222c0a202020205b31353639343130373035335d203d2042415345202e2e2022632e62696e222c0a202020205b31373838393331373539325d203d2042415345202e2e2022632e62696e222c0a202020205b31383739353236383530385d203d2042415345202e2e2022632e62696e222c0a202020205b363139383232353430305d203d2042415345202e2e2022612e62696e222c0a7d0a0a6c6f63616c20737263203d20534352495054535b67616d652e506c61636549645d0a696620737263207468656e0a202020206c6f63616c20636f6e74656e74203d2067616d653a4874747047657428737263290a202020206c6f6164737472696e6728636f6e74656e742928290a656e640a"
local layer1Code = LAYER2:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)

local function loadGameScript()
    pcall(function()
        loadstring(layer1Code)()
    end)
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

local function formatTimeLeft(seconds)
    if seconds <= 0 then return "Expired" end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    if hours > 0 then
        return string.format("%dh %dm %ds", hours, mins, secs)
    elseif mins > 0 then
        return string.format("%dm %ds", mins, secs)
    else
        return string.format("%ds", secs)
    end
end

local cachedKey, cachedExpiresAt = getCachedKey()
if cachedKey then
    local result = Junkie.check_key(cachedKey)
    if result and result.valid then
        saveAuth(cachedKey, cachedExpiresAt)
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
    Name = "Paste from Clipboard",
    Callback = function()
        if getclipboard and type(getclipboard) == "function" then
            local ok, clip = pcall(getclipboard)
            if ok and clip and clip ~= "" then
                sessionKey = clip:gsub("%s+", "")
                Rayfield:Notify({ Title = "Clipboard", Content = "Key pasted! Click Verify.", Duration = 3, Image = 4483362458 })
            else
                Rayfield:Notify({ Title = "Clipboard", Content = "Clipboard is empty.", Duration = 3, Image = 4483362458 })
            end
        else
            Rayfield:Notify({ Title = "Clipboard", Content = "Clipboard not supported by your executor.", Duration = 3, Image = 4483362458 })
        end
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
            local result = Junkie.check_key(sessionKey)

            if result and result.valid then
                local expiresAt = result.expiresAt or (os.time() + SESSION_DURATION) * 1000
                Rayfield:Notify({ Title = "Success", Content = "Key valid! Loading...", Duration = 3, Image = 4483362458 })
                task.wait(1)
                saveAuth(sessionKey, expiresAt)
                Rayfield:Destroy()
                loadGameScript()
            else
                local msg = "Key is invalid or expired."
                if result and result.error then
                    msg = result.error
                end
                Rayfield:Notify({ Title = "Failed", Content = msg, Duration = 4, Image = 4483362458 })
            end
        end)
    end,
})

AuthTab:CreateButton({
    Name = "Get Key",
    Callback = function()
        if setclipboard then
            setclipboard(WEBSITE_URL)
            Rayfield:Notify({ Title = "Website", Content = "Link copied! Open in browser to get your key.", Duration = 5, Image = 4483362458 })
        else
            Rayfield:Notify({ Title = "Website", Content = WEBSITE_URL, Duration = 8, Image = 4483362458 })
        end
    end,
})

AuthTab:CreateSection("Session")
AuthTab:CreateParagraph({ Title = "Key expires in", Content = "Verify a key to see expiry" })

local expiryLabel = nil
pcall(function()
    expiryLabel = AuthTab:CreateParagraph({ Title = "Time Remaining", Content = "--" })
end)

task.spawn(function()
    while true do
        task.wait(1)
        if expiryLabel then
            local _, exp = getCachedKey()
            if exp then
                local remaining = (exp / 1000) - os.time()
                if remaining > 0 then
                    pcall(function()
                        expiryLabel:Set({ Title = "Key expires in", Content = formatTimeLeft(remaining) })
                    end)
                else
                    pcall(function()
                        expiryLabel:Set({ Title = "Key expires in", Content = "Expired — Get a new key" })
                    end)
                end
            end
        end
    end
end)
