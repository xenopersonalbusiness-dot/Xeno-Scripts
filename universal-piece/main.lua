local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer

-- // REMOTE SERVICES // --
local QuestRemote = game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("QuestMain")
local StatRemote = game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("Upstats")
local BlackMarketRemote = game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("BlackMarket")
local FruitRemote = game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("FruitShop")
local RandomFruitRemote = game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("RandomFruit")
local MainFruitRemote = game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("MainFruit")
local MainNpcRemote = game:GetService("ReplicatedStorage"):WaitForChild("Event"):WaitForChild("MainNpc")

-- // DATA FOLDERS // --
local BlackMarketFolder = game:GetService("ReplicatedStorage"):WaitForChild("BlackMarkets")
local FruitFolder = game:GetService("ReplicatedStorage"):WaitForChild("FruitStocks")

-- // LEVEL SCALING DATA // --
local LevelScaling = {
    {Level = 35500, Name = "Cursed Student", Quest = "CursedStudent Lv.35000", Pos = CFrame.new(9169.14, 43.00, -12694.04)},
    {Level = 30000, Name = "Hollow Knight", Quest = "HollowKnight Lv.30000", Pos = CFrame.new(-49981.22, 37.95, 486.85)},
    {Level = 25000, Name = "Reza", Quest = "Reza Lv.25000", Pos = CFrame.new(-6425.03, 31.24, 2692.93)},
    {Level = 20000, Name = "Vowd", Quest = "Vowd Lv.20000", Pos = CFrame.new(-6607.41, 31.25, 2654.96)},
    {Level = 15500, Name = "Strongest Man", Quest = "StrongestMan Lv.15000", Pos = CFrame.new(2038.52, 77.60, 10131.11)},
    {Level = 10500, Name = "Strongman", Quest = "StrongMan Lv.10000", Pos = CFrame.new(1869.52, 77.60, 10323.29)},
    {Level = 8500,  Name = "Alien", Quest = "Alien Lv.8000", Pos = CFrame.new(-777.45, 37.42, 4934.02)},
    {Level = 6800,  Name = "Jago", Quest = "Jago Lv.6400", Pos = CFrame.new(-7608.50, 29.82, 1393.16)},
    {Level = 6000,  Name = "Blizzard Queen", Quest = "BlizzardQueen Lv.5600", Pos = CFrame.new(7676.63, 58.51, 142.18)},
    {Level = 5200,  Name = "Gassy", Quest = "Gassy Lv.4800", Pos = CFrame.new(7881.54, 55.77, 687.91)},
    {Level = 3600,  Name = "Giant Zombie", Quest = "GiantZombie Lv.3200", Pos = CFrame.new(1887.21, 59.31, -10155.78)},
    {Level = 2700,  Name = "Zombie", Quest = "Zombie Lv.2400", Pos = CFrame.new(2288.42, 39.45, -10151.57)},
    {Level = 2000,  Name = "Burger Spinner", Quest = "BurgerSpinner Lv.1800", Pos = CFrame.new(-2036.73, 44.55, -8849.96)},
    {Level = 1500,  Name = "Smile Pirate", Quest = "SmilePirate Lv.1300", Pos = CFrame.new(-2422.15, 44.69, -8994.54)},
    {Level = 1000,  Name = "Clown Pirate", Quest = "ClownPirate Lv.800", Pos = CFrame.new(-2392.20, 43.66, -8793.29)},
    {Level = 400,   Name = "Bomber", Quest = "Bomber Lv.400", Pos = CFrame.new(-5691.69, 72.14, -6170.37)},
    {Level = 100,   Name = "Sigma Bandits", Quest = "SigmaBandit Lv.100", Pos = CFrame.new(-5693.32, 74.15, -6165.67)},
    {Level = 0,     Name = "Bandit", Quest = "Bandit Lv.1", Pos = CFrame.new(-6001.41, 73.43, -5891.75)}
}

getgenv().StarmanConfig = {
    AutoFarm = false,
    AutoHunterHeart = false,
    AutoTheHunterBoss = false,
    AutoDecay = false,
    AutoNinth = false,
    AutoChest = false,
    AutoStats = false,
    AutoStore = false,
    QuestWaitTimer = 30, -- Default Slider Value
    SelectedStats = {},
    SelectedAbilities = {"Z", "X", "C", "V"},
    ESPEnabled = false,
    SessionID = 0,
    LastQuestTime = 0,
    LastSpecialistQuestTime = 0,
    SelectedBlackMarketItems = {},
    SelectedFruits = {}
}

-- // CONSOLE LOGGING SYSTEM // --
local ConsoleGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ConsoleGui)
local ScrollingFrame = Instance.new("ScrollingFrame", MainFrame)
local UIListLayout = Instance.new("UIListLayout", ScrollingFrame)
MainFrame.Size = UDim2.new(0, 220, 0, 35)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -17)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)
ScrollingFrame.Size = UDim2.new(1, -15, 1, -15)
ScrollingFrame.Position = UDim2.new(0, 7, 0, 7)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.Visible = false
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function Log(text)
    if not text then return end
    if not ScrollingFrame.Visible and MainFrame.Visible then
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 250), "Out", "Quad", 0.3, true)
        ScrollingFrame.Visible = true
    end
    local LogLabel = Instance.new("TextLabel", ScrollingFrame)
    LogLabel.Size = UDim2.new(1, 0, 0, 18)
    LogLabel.BackgroundTransparency = 1
    LogLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    LogLabel.Font = Enum.Font.Code
    LogLabel.TextSize = 13
    LogLabel.Text = "[" .. os.date("%X") .. "] " .. tostring(text)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    ScrollingFrame.CanvasPosition = Vector2.new(0, UIListLayout.AbsoluteContentSize.Y)
end

-- // ESP SYSTEM // --
local function createESP(player)
    if player == lp then return end
    local function setupCharacter(char)
        if char:FindFirstChild("ESP_UI") then char.ESP_UI:Destroy() end
        local head = char:WaitForChild("Head", 10)
        if not head then return end
        local bill = Instance.new("BillboardGui", char)
        bill.Name = "ESP_UI"
        bill.Size = UDim2.new(0, 100, 0, 50)
        bill.AlwaysOnTop = true
        bill.StudsOffset = Vector3.new(0, 3, 0)
        bill.Adornee = head
        local label = Instance.new("TextLabel", bill)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if getgenv().StarmanConfig.ESPEnabled and char.Parent and lp.Character:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((lp.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
                label.Text = player.Name .. "\n[" .. dist .. "m]"
            else
                bill:Destroy()
                conn:Disconnect()
            end
        end)
    end
    player.CharacterAdded:Connect(setupCharacter)
    if player.Character then setupCharacter(player.Character) end
end

-- // HELPERS // --
local function canGetSpecialistQuest()
    local currentTime = tick()
    if (currentTime - getgenv().StarmanConfig.LastSpecialistQuestTime) >= getgenv().StarmanConfig.QuestWaitTimer then 
        return true 
    end
    return false
end

local function canGetNormalQuest()
    local currentTime = tick()
    if (currentTime - getgenv().StarmanConfig.LastQuestTime) >= 30 then 
        return true 
    end
    return false
end

local function spamAbilities()
    for _, keyStr in ipairs(getgenv().StarmanConfig.SelectedAbilities) do
        local key = Enum.KeyCode[keyStr]
        if key then
            VIM:SendKeyEvent(true, key, false, game)
            task.wait(0.01)
            VIM:SendKeyEvent(false, key, false, game)
        end
    end
end

local function applyMagnet(centerPos, characterRoot)
    for _, Mob in ipairs(workspace.Alive:GetChildren()) do
        if Mob:IsA("Model") and Mob:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(Mob) then
            local distance = (Mob.HumanoidRootPart.Position - centerPos.Position).Magnitude
            if distance < 450 then
                Mob.HumanoidRootPart.CFrame = characterRoot.CFrame * CFrame.new(0, -9, -3)
                Mob.HumanoidRootPart.Anchored = true
                Mob.HumanoidRootPart.Velocity = Vector3.new(0,0,0)
            end
        end
    end
end

-- // UI WINDOW // --
local Window = Rayfield:CreateWindow({Name = "Starman Release", LoadingTitle = "Starman Services"})
local MainTab = Window:CreateTab("Combat", 4483362458)
local StatsTab = Window:CreateTab("Stats", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- // COMBAT SECTION: CORE FARMS // --
MainTab:CreateDropdown({
    Name = "Select Abilities to Spam",
    Options = {"Z", "X", "C", "V", "B", "F"},
    CurrentOption = {"Z", "X", "C", "V"},
    MultipleOptions = true,
    Callback = function(v) getgenv().StarmanConfig.SelectedAbilities = v end,
})

MainTab:CreateToggle({
   Name = "Auto farm",
   CurrentValue = false,
   Callback = function(v)
      getgenv().StarmanConfig.AutoFarm = v
      if v then
          Log("Standard AutoFarm Started")
          getgenv().StarmanConfig.SessionID += 1
          task.spawn(function()
              local SID = getgenv().StarmanConfig.SessionID
              while getgenv().StarmanConfig.AutoFarm and getgenv().StarmanConfig.SessionID == SID do
                  local Root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                  if Root then
                      local CurrentLvl = lp:GetAttribute("Levels") or 0
                      local Data
                      for _, d in ipairs(LevelScaling) do if CurrentLvl >= d.Level then Data = d break end end
                      if canGetNormalQuest() then
                          QuestRemote:InvokeServer(tostring(Data.Quest))
                          getgenv().StarmanConfig.LastQuestTime = tick()
                      end
                      Root.CFrame = Data.Pos * CFrame.new(0, 12, 0)
                      Root.Anchored = true
                      applyMagnet(Data.Pos, Root)
                      spamAbilities()
                  end
                  task.wait(0.05)
              end
              if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = false end
          end)
      end
   end,
})

MainTab:CreateSection("--- Specialist Farm Settings ---")

MainTab:CreateSlider({
   Name = "Specialist Quest Wait (Seconds)",
   Info = "Timer for Decay, Ninth, TheHunter, and Cursed Student quests",
   Range = {1, 60},
   Increment = 1,
   Suffix = "s",
   CurrentValue = 30,
   Callback = function(Value)
      getgenv().StarmanConfig.QuestWaitTimer = Value
   end,
})

-- // COMBAT SECTION: SPECIALIST FARMS // --

MainTab:CreateToggle({
   Name = "Auto Summon & Farm Decay",
   CurrentValue = false,
   Callback = function(v)
      getgenv().StarmanConfig.AutoDecay = v
      if v then
          Log("Decay Specialist Farm Active")
          task.spawn(function()
              local TargetPos = CFrame.new(-1602.280, 43.270, 9644.279)
              while getgenv().StarmanConfig.AutoDecay do
                  local Root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                  if Root then
                      MainNpcRemote:InvokeServer("SpawnBoss", "Spawn55")
                      Root.CFrame = TargetPos * CFrame.new(0, 12, 0)
                      Root.Anchored = true
                      applyMagnet(TargetPos, Root)
                      spamAbilities()
                  end
                  task.wait(0.1)
              end
              if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = false end
          end)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Summon & Farm Ninth",
   CurrentValue = false,
   Callback = function(v)
      getgenv().StarmanConfig.AutoNinth = v
      if v then
          Log("Ninth Specialist Farm Active")
          task.spawn(function()
              local TargetPos = CFrame.new(-1602.280, 43.270, 9644.279)
              while getgenv().StarmanConfig.AutoNinth do
                  local Root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                  if Root then
                      MainNpcRemote:InvokeServer("SpawnBoss", "Spawn5")
                      Root.CFrame = TargetPos * CFrame.new(0, 12, 0)
                      Root.Anchored = true
                      applyMagnet(TargetPos, Root)
                      spamAbilities()
                  end
                  task.wait(0.1)
              end
              if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = false end
          end)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Summon & Farm TheHunter",
   CurrentValue = false,
   Callback = function(v)
      getgenv().StarmanConfig.AutoTheHunterBoss = v
      if v then
          Log("TheHunter Specialist Farm Active")
          task.spawn(function()
              local TargetPos = CFrame.new(7699.629, 45.151, -12960.123)
              while getgenv().StarmanConfig.AutoTheHunterBoss do
                  local Root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                  if Root then
                      MainFruitRemote:InvokeServer("UnStore", "HeartOfHunter")
                      task.wait(0.1)
                      MainNpcRemote:InvokeServer("SpawnBoss", "SpawnCity")
                      if canGetSpecialistQuest() then
                          QuestRemote:InvokeServer("TheHunter")
                          getgenv().StarmanConfig.LastSpecialistQuestTime = tick()
                      end
                      Root.CFrame = TargetPos * CFrame.new(0, 12, 0)
                      Root.Anchored = true
                      applyMagnet(TargetPos, Root)
                      spamAbilities()
                  end
                  task.wait(0.1)
              end
              if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = false end
          end)
      end
   end,
})

MainTab:CreateToggle({
   Name = "Auto Hunter Heart (Cursed Student)",
   CurrentValue = false,
   Callback = function(v)
      getgenv().StarmanConfig.AutoHunterHeart = v
      if v then
          Log("Cursed Student Farm Active")
          task.spawn(function()
              local TargetPos = CFrame.new(9169.14, 43.00, -12694.04)
              while getgenv().StarmanConfig.AutoHunterHeart do
                  local Root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                  if Root then
                      if canGetSpecialistQuest() then
                          QuestRemote:InvokeServer("CursedStudent Lv.35000")
                          getgenv().StarmanConfig.LastSpecialistQuestTime = tick()
                      end
                      Root.CFrame = TargetPos * CFrame.new(0, 12, 0)
                      Root.Anchored = true
                      applyMagnet(TargetPos, Root)
                      spamAbilities()
                  end
                  task.wait(0.05)
              end
              if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = false end
          end)
      end
   end,
})

-- // MISC SECTION // --
MiscTab:CreateSection("Fruit Management")
MiscTab:CreateToggle({
    Name = "Auto Store/Drop Fruit",
    CurrentValue = false,
    Callback = function(v)
        getgenv().StarmanConfig.AutoStore = v
        if v then
            task.spawn(function()
                while getgenv().StarmanConfig.AutoStore do
                    local bp = lp:FindFirstChild("Backpack")
                    if bp then
                        for _, item in ipairs(bp:GetChildren()) do
                            if item:IsA("Tool") and item:FindFirstChild("Handle") then
                                lp.Character.Humanoid:EquipTool(item)
                                task.wait(0.3)
                                MainFruitRemote:InvokeServer("Store", item.Name)
                                task.wait(0.5)
                                if item.Parent == lp.Backpack or item.Parent == lp.Character then
                                    MainFruitRemote:InvokeServer("Drop", item.Name)
                                end
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Chest",
    CurrentValue = false,
    Callback = function(v)
        getgenv().StarmanConfig.AutoChest = v
        if v then
            task.spawn(function()
                while getgenv().StarmanConfig.AutoChest do
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then
                            local pos = obj.Parent:IsA("BasePart") and obj.Parent.Position or obj.Parent:GetPivot().Position
                            if (lp.Character.HumanoidRootPart.Position - pos).Magnitude < 15 then
                                fireproximityprompt(obj)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

MiscTab:CreateSection("Black Market & Stock")
local BM_Label = MiscTab:CreateLabel("BM: Scanning...")
local Stock_Label = MiscTab:CreateLabel("Stock: Scanning...")
local StockDropdown = MiscTab:CreateDropdown({
    Name = "Select Fruits to Buy",
    Options = {},
    MultipleOptions = true,
    Callback = function(v) getgenv().StarmanConfig.SelectedFruits = v end,
})
MiscTab:CreateButton({
    Name = "Buy Selected Fruits",
    Callback = function() 
        for _, name in ipairs(getgenv().StarmanConfig.SelectedFruits) do 
            FruitRemote:FireServer("BuyFruitByPrice", name) 
        end 
    end
})
local BM_Dropdown = MiscTab:CreateDropdown({
    Name = "Select BM Items",
    Options = {},
    MultipleOptions = true,
    Callback = function(v) getgenv().StarmanConfig.SelectedBlackMarketItems = v end,
})
MiscTab:CreateButton({
    Name = "Buy Selected BM Items",
    Callback = function() 
        for _, name in ipairs(getgenv().StarmanConfig.SelectedBlackMarketItems) do 
            BlackMarketRemote:FireServer("Buy", name:gsub("%s+", ""), 1) 
        end 
    end
})

task.spawn(function()
    while true do
        local b_str, s_str, b_tab, s_tab = "", "", {}, {}
        for _, i in ipairs(BlackMarketFolder:GetChildren()) do 
            b_str = b_str .. i.Name .. ", " 
            table.insert(b_tab, i.Name) 
        end
        for _, i in ipairs(FruitFolder:GetChildren()) do 
            s_str = s_str .. i.Name .. ", " 
            table.insert(s_tab, i.Name) 
        end
        BM_Label:Set(b_str == "" and "BM: Empty" or "BM: " .. b_str:sub(1,-3))
        Stock_Label:Set(s_str == "" and "Stock: Empty" or "Stock: " .. s_str:sub(1,-3))
        StockDropdown:Refresh(s_tab) 
        BM_Dropdown:Refresh(b_tab) 
        task.wait(5)
    end
end)

-- // STATS & SETTINGS // --
StatsTab:CreateDropdown({
    Name = "Select Stats", 
    Options = {"Melee", "Defense", "Weapons", "Power"}, 
    MultipleOptions = true, 
    Callback = function(v) getgenv().StarmanConfig.SelectedStats = v end
})
StatsTab:CreateToggle({
    Name = "Auto Update Stats", 
    CurrentValue = false, 
    Callback = function(v)
        getgenv().StarmanConfig.AutoStats = v
        if v then 
            task.spawn(function() 
                while getgenv().StarmanConfig.AutoStats do 
                    for _, s in ipairs(getgenv().StarmanConfig.SelectedStats) do 
                        StatRemote:FireServer(s, 9999) 
                    end 
                    task.wait(2) 
                end 
            end) 
        end
    end
})

SettingsTab:CreateToggle({
    Name = "Player ESP", 
    CurrentValue = false, 
    Callback = function(v) 
        getgenv().StarmanConfig.ESPEnabled = v 
        if v then for _, p in pairs(Players:GetPlayers()) do createESP(p) end end 
    end
})
SettingsTab:CreateButton({
    Name = "Toggle Console Window", 
    Callback = function() MainFrame.Visible = not MainFrame.Visible end
})
