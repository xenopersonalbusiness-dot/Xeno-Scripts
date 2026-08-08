local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local WEBSITE_URL = "https://xenos-intestine.pages.dev"
local CASCADE_URL = "https://github.com/cascadeui/Cascade/releases/latest/download/dist.luau"

local okJunkie, Junkie = pcall(function()
    return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
end)
if not okJunkie or type(Junkie) ~= "table" then
    error("Xeno: Junkie SDK failed to load - " .. tostring(Junkie))
end
Junkie.service = "Keysystem"
Junkie.identifier = "1007847"
Junkie.provider = "Key System"

local okUI, cascade = pcall(function()
    return loadstring(game:HttpGet(CASCADE_URL), "Cascade")()
end)
if not okUI or type(cascade) ~= "table" then
    error("Xeno: UI failed to load - " .. tostring(cascade))
end

local LAYER2 = "2d2d204c4159455220313a205365727665722d67617465642073637269707420666574636865720a2d2d2054686973206973206f62667573636174656420696e746f204c6179657220320a2d2d2052657475726e7320612066756e6374696f6e20746861742070756c6c7320616e642072756e73206f6e652067616d652773207363726970742e0a0a6c6f63616c2047415445203d202268747470733a2f2f6163636573732d6b6579732e78656e6f706572736f6e616c627573696e6573732e776f726b6572732e6465762f736372697074220a6c6f63616c2050415353203d2022576879417265596f754c6f6f6b696e67486572654d6172676549744c6f6f6b734c696b655765476f744153656375726974794272656163684f68536e6170486f6d657244726f7073486973444f6e7574446f61684e616842757446724966596f754d616465497454486973466172436f6e7461637458656e6f626f757468657265324f6e446973636f7264466f7241446f6e7574416e644b65794f66596f75724578656375746f7243686f6963654c6f7665594f754e4f43617046616d220a0a72657475726e2066756e6374696f6e2867616d654b6579290a202020202d2d2067616d653a487474704765742063616e27742073656e6420637573746f6d20686561646572732c20736f207468652067617465206e65656473207265717565737428292e0a202020206c6f63616c20726571203d202873796e20616e642073796e2e7265717565737429206f7220286874747020616e6420687474702e7265717565737429206f7220687474705f72657175657374206f7220726571756573740a202020206966206e6f7420726571207468656e0a20202020202020206572726f722822796f7572206578656375746f7220686173206e6f207265717565737428292066756e6374696f6e2c2069742063616e27742073656e642074686520617574682068656164657222290a20202020656e640a0a202020206c6f63616c206f6b2c20726573203d207063616c6c287265712c207b0a202020202020202055726c203d2047415445202e2e20223f67616d653d22202e2e2067616d654b65792c0a20202020202020204d6574686f64203d2022474554222c0a202020202020202048656164657273203d207b0a2020202020202020202020205b22782d70617373225d203d20504153532c0a2020202020202020202020205b22557365722d4167656e74225d203d202258656e6f4c6f616465722f312e30222c0a20202020202020207d2c0a202020207d290a0a202020206966206e6f74206f6b207468656e0a20202020202020206572726f72282272657175657374206661696c65643a2022202e2e20746f737472696e672872657329290a20202020656e640a202020206966206e6f7420726573206f72206e6f74207265732e426f6479207468656e0a20202020202020206572726f722822676174652072657475726e6564206e6f7468696e6722290a20202020656e640a0a202020206c6f63616c20737461747573203d207265732e537461747573436f6465206f72207265732e537461747573206f7220300a20202020696620737461747573207e3d20323030207468656e0a20202020202020206572726f722822676174652073616964206e6f2028485454502022202e2e20746f737472696e672873746174757329202e2e20222922290a20202020656e640a0a202020206c6f63616c206368756e6b2c20657272203d206c6f6164737472696e67287265732e426f6479290a202020206966206e6f74206368756e6b207468656e0a20202020202020206572726f72282273637269707420776f6e277420636f6d70696c653a2022202e2e20746f737472696e672865727229290a20202020656e640a2020202072657475726e206368756e6b28290a656e640a"
local layer1Code = LAYER2:gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)

local GAMES = {
    {
        key = "lineage",
        name = "Bizarre Lineage",
        icon = cascade.Symbols.flame,
        places = { 14890802310, 74747090658891, 6198225400 },
    },
    {
        key = "piece",
        name = "Universal Piece",
        icon = cascade.Symbols.shield,
        places = { 130169555191153 },
    },
    {
        key = "legacy",
        name = "Jujutsu Legacy",
        icon = cascade.Symbols.bolt,
        places = { 15694107053, 17889317592, 18795268508 },
    },
}

local app = cascade.New({
    Theme = cascade.Themes.Dark,
    Accent = cascade.Accents.Blue,
    WindowPill = true,
})

local function notify(title, subtitle)
    pcall(function()
        app:Notification({
            App = "XENO",
            Title = title,
            Subtitle = subtitle,
            Duration = 5,
        })
    end)
end

local window = app:Window({
    Title = "Xeno's",
    Subtitle = "Key System",
    Size = UserInputService.TouchEnabled and UDim2.fromOffset(560, 340) or UDim2.fromOffset(780, 480),
})

local section = window:Section({ Title = "Xeno's" })

local verifyTab = section:Tab({
    Title = "Verify",
    Icon = cascade.Symbols.key,
    Selected = true,
})

local sessionKey = ""
local unlocked = false

local function inThisGame(places)
    for _, id in ipairs(places) do
        if game.PlaceId == id then
            return true
        end
    end
    return false
end

local function runGameScript(entry)
    if not inThisGame(entry.places) then
        notify("Wrong game", "You're not in " .. entry.name .. " right now.")
        return
    end

    local build, buildErr = loadstring(layer1Code)
    if not build then
        notify("Loader broke", tostring(buildErr))
        return
    end

    local okBuild, fetch = pcall(build)
    if not okBuild or type(fetch) ~= "function" then
        notify("Loader broke", tostring(fetch))
        return
    end

    notify(entry.name, "Loading the script...")

    local okRun, err = pcall(fetch, entry.key)
    if okRun then
        window.Minimized = true
    else
        notify("Didn't load", tostring(err))
    end
end

local function addGameTabs()
    if unlocked then return end
    unlocked = true

    local first = nil
    for _, entry in ipairs(GAMES) do
        local tab = section:Tab({
            Title = entry.name,
            Icon = entry.icon,
        })
        first = first or tab

        local form = tab:PageSection({ Title = entry.name }):Form()

        local row = form:Row()
        row:Left():TitleStack({
            Title = "Script",
            Subtitle = inThisGame(entry.places) and "You're in this game." or "Join the game first, then hit load.",
        })
        row:Right():Button({
            Label = "Load Script",
            State = "Primary",
            Pushed = function()
                runGameScript(entry)
            end,
        })
    end

    if first then
        first.Selected = true
    end
end

local function getKeyLink()
    local ok, link = pcall(function()
        local body = Junkie.get_key_link(Junkie.provider)
        if type(body) ~= "string" or body == "" then return nil end

        local okJson, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if okJson and type(data) == "table" then
            return data.url or data.link or data.key_link or data.keyLink
        end
        if body:sub(1, 4) == "http" then return body end
        return nil
    end)
    return ok and link or nil
end

do
    local form = verifyTab:PageSection({ Title = "Key" }):Form()

    do
        local row = form:Row()
        row:Left():TitleStack({
            Title = "Key",
            Subtitle = "Paste it in and hit verify.",
        })
        row:Right():TextField({
            Placeholder = "Your key",
            TextChanged = function(self, text)
                sessionKey = tostring(text or ""):gsub("%s+", "")
            end,
            ValueChanged = function(self, value)
                sessionKey = tostring(value or ""):gsub("%s+", "")
            end,
        })
    end

    do
        local row = form:Row()
        row:Left():TitleStack({
            Title = "Verify",
            Subtitle = "Unlocks the game tabs.",
        })
        row:Right():Button({
            Label = "Verify",
            State = "Primary",
            Pushed = function()
                if sessionKey == "" then
                    notify("No key", "Type or paste a key first.")
                    return
                end

                notify("Checking", "Give it a second.")

                task.spawn(function()
                    local ok, result = pcall(Junkie.check_key, sessionKey)

                    if ok and result and result.valid then
                        notify("You're in", "Pick a game on the left.")
                        addGameTabs()
                    else
                        local msg = "That key isn't valid."
                        if ok and result and result.error then
                            msg = tostring(result.error)
                        elseif not ok then
                            msg = tostring(result)
                        end
                        notify("Nope", msg)
                    end
                end)
            end,
        })
    end

    do
        local row = form:Row()
        row:Left():TitleStack({
            Title = "No key yet?",
            Subtitle = "Copies the link, open it in your browser.",
        })
        row:Right():Button({
            Label = "Get Key",
            State = "Secondary",
            Pushed = function()
                local link = getKeyLink() or WEBSITE_URL
                if setclipboard then
                    setclipboard(link)
                    notify("Copied", "Paste it in your browser.")
                else
                    notify("Link", link)
                end
            end,
        })
    end
end
