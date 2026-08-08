local HttpService = game:GetService("HttpService")

local okJunkie, Junkie = pcall(function()
    return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
end)
if not okJunkie or type(Junkie) ~= "table" then
    error("Xeno: Junkie SDK failed to load - " .. tostring(Junkie))
end
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
    local ok, key, expiresAt = pcall(function()
        if isfile(AUTH_FILE) then
            local data = HttpService:JSONDecode(readfile(AUTH_FILE))
            if data and data.key and data.timestamp and (os.time() - data.timestamp) < SESSION_DURATION then
                return data.key, data.expiresAt
            end
        end
        return nil, nil
    end)
    if not ok then return nil, nil end
    return key, expiresAt
end

local function clearAuth()
    pcall(function()
        if isfile(AUTH_FILE) then delfile(AUTH_FILE) end
    end)
end

local LAYER2 = "2d2d204c4159455220313a205365727665722d67617465642073637269707420666574636865720a2d2d2054686973206973206f62667573636174656420696e746f204c6179657220320a0a6c6f63616c2047415445203d202268747470733a2f2f6163636573732d6b6579732e78656e6f706572736f6e616c627573696e6573732e776f726b6572732e6465762f736372697074220a6c6f63616c2050415353203d2022576879417265596f754c6f6f6b696e67486572654d6172676549744c6f6f6b734c696b655765476f744153656375726974794272656163684f68536e6170486f6d657244726f7073486973444f6e7574446f61684e616842757446724966596f754d616465497454486973466172436f6e7461637458656e6f626f757468657265324f6e446973636f7264466f7241446f6e7574416e644b65794f66596f75724578656375746f7243686f6963654c6f7665594f754e4f43617046616d220a6c6f63616c2047414d4553203d207b0a202020205b31343839303830323331305d203d20226c696e65616765222c0a202020205b37343734373039303635383839315d203d20226c696e65616765222c0a202020205b3133303136393535353139313135335d203d20227069656365222c0a202020205b31353639343130373035335d203d20226c6567616379222c0a202020205b31373838393331373539325d203d20226c6567616379222c0a202020205b31383739353236383530385d203d20226c6567616379222c0a202020205b363139383232353430305d203d20226c696e65616765222c0a7d0a0a6c6f63616c2067616d654e616d65203d2047414d45535b67616d652e506c61636549645d0a6966206e6f742067616d654e616d65207468656e0a202020206572726f72282258656e6f3a20746869732067616d65206973206e6f7420737570706f727465642028506c61636549642022202e2e20746f737472696e672867616d652e506c616365496429202e2e20222922290a656e640a0a2d2d2067616d653a487474704765742043414e4e4f542073656e6420637573746f6d20686561646572732c20736f2074686520782d706173732067617465206e65656473207468650a2d2d206578656375746f7220726571756573742066756e6374696f6e20696e73746561642e0a6c6f63616c20726571203d202873796e20616e642073796e2e7265717565737429206f7220286874747020616e6420687474702e7265717565737429206f7220687474705f72657175657374206f7220726571756573740a6966206e6f7420726571207468656e0a202020206572726f72282258656e6f3a20796f7572206578656375746f7220686173206e6f207265717565737428292066756e6374696f6e202d2069742063616e6e6f742073656e642074686520617574682068656164657222290a656e640a0a6c6f63616c206f6b2c20726573203d207063616c6c287265712c207b0a2020202055726c203d2047415445202e2e20223f67616d653d22202e2e2067616d654e616d652c0a202020204d6574686f64203d2022474554222c0a2020202048656164657273203d207b0a20202020202020205b22782d70617373225d203d20504153532c0a20202020202020205b22557365722d4167656e74225d203d202258656e6f4c6f616465722f312e30222c0a202020207d2c0a7d290a0a6966206e6f74206f6b207468656e0a202020206572726f72282258656e6f3a2072657175657374206661696c6564202d2022202e2e20746f737472696e672872657329290a656e640a6966206e6f7420726573206f72206e6f74207265732e426f6479207468656e0a202020206572726f72282258656e6f3a20676174652072657475726e6564206e6f20626f647922290a656e640a0a6c6f63616c20737461747573203d207265732e537461747573436f6465206f72207265732e537461747573206f7220300a696620737461747573207e3d20323030207468656e0a202020206572726f72282258656e6f3a20676174652072656a656374656420726571756573742028485454502022202e2e20746f737472696e672873746174757329202e2e202229202d2022202e2e20746f737472696e67287265732e426f647929290a656e640a0a6c6f63616c206368756e6b2c20657272203d206c6f6164737472696e67287265732e426f6479290a6966206e6f74206368756e6b207468656e0a202020206572726f72282258656e6f3a2067616d6520736372697074206661696c656420746f20636f6d70696c65202d2022202e2e20746f737472696e672865727229290a656e640a6368756e6b28290a"
local layer1Code = LAYER2:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)

local showFallbackGui

local function loadGameScript()
    local chunk, compileErr = loadstring(layer1Code)
    if not chunk then
        warn("[Xeno] loader compile error: " .. tostring(compileErr))
        showFallbackGui("Xeno - Loader Error", tostring(compileErr))
        return
    end
    local ok, err = pcall(chunk)
    if not ok then
        warn("[Xeno] loader runtime error: " .. tostring(err))
        showFallbackGui("Xeno - Script Error", tostring(err))
    end
end

function showFallbackGui(title, msg)
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
