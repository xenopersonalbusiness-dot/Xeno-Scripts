local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")

local Config = {
    Aimbot = false,
    AimPart = "Head",
    FOV = 120,
    Distance = 400,
    WallCheck = false,
    TeamCheck = true,
    ESP = false,
    HealthESP = false,
    NameESP = false,
    DistanceESP = false,
    ToolESP = false,
    TeamESP = false,
    TeamHealthESP = false,
    TeamNameESP = false,
    TeamDistanceESP = false,
    TeamToolESP = false,
    VisColorCheck = false,
    ESPColor = Color3.fromRGB(255, 0, 0),
    TeamESPColor = Color3.fromRGB(0, 255, 0),
    Freecam = false,
    FreecamSpeed = 2,
    Noclip = false,
    InfJump = false,
    Radar = false,
    RadarRange = 200,
    RadarX = 20,
    RadarY = 400,
    FlyMaster = false,
    Fly = false,
    FlySpeed = 50,
    FlyKey = Enum.KeyCode.F,
    FlyMode = "CFrame",
    FullBright = false
}

local Elements = {}
local FolderName = "StarmanUniversalConfig"

pcall(function()
    if not isfolder(FolderName) then
        makefolder(FolderName)
    end
end)

local function GetConfigList()
    local names = {}
    local success, files = pcall(function() return listfiles(FolderName) end)
    if success then
        for _, file in ipairs(files) do
            local name = file:gsub(FolderName .. "/", ""):gsub(FolderName .. "\\", ""):gsub(".txt", "")
            table.insert(names, name)
        end
    end
    return names
end

local RadarGui = Instance.new("ScreenGui")
RadarGui.Name = "LogicRadar_VisSync"
RadarGui.ResetOnSpawn = false
RadarGui.Enabled = false
RadarGui.Parent = game:GetService("CoreGui")

local RadarFrame = Instance.new("Frame")
RadarFrame.Name = "MainFrame"
RadarFrame.Parent = RadarGui
RadarFrame.Size = UDim2.new(0, 200, 0, 200)
RadarFrame.Position = UDim2.new(0, Config.RadarX, 0, Config.RadarY)
RadarFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
RadarFrame.BorderSizePixel = 2
RadarFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)

local RadarCorner = Instance.new("UICorner")
RadarCorner.CornerRadius = UDim.new(1, 0)
RadarCorner.Parent = RadarFrame

local VerticalLine = Instance.new("Frame", RadarFrame)
VerticalLine.Size = UDim2.new(0, 1, 1, 0)
VerticalLine.Position = UDim2.new(0.5, 0, 0, 0)
VerticalLine.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
VerticalLine.BorderSizePixel = 0

local HorizontalLine = Instance.new("Frame", RadarFrame)
HorizontalLine.Size = UDim2.new(1, 0, 0, 1)
HorizontalLine.Position = UDim2.new(0, 0, 0.5, 0)
HorizontalLine.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
HorizontalLine.BorderSizePixel = 0

local CenterBlip = Instance.new("Frame")
CenterBlip.Parent = RadarFrame
CenterBlip.Size = UDim2.new(0, 6, 0, 6)
CenterBlip.Position = UDim2.new(0.5, -3, 0.5, -3)
CenterBlip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CenterBlip.ZIndex = 5

local CenterCorner = Instance.new("UICorner")
CenterCorner.CornerRadius = UDim.new(1, 0)
CenterCorner.Parent = CenterBlip

local Blips = {}

local function IsVisible(targetPart)
    local char = LocalPlayer.Character
    if not char or not targetPart then return false end
    local Origin = Camera.CFrame.Position
    local Direction = targetPart.Position - Origin
    local rayParam = RaycastParams.new()
    rayParam.FilterType = Enum.RaycastFilterType.Exclude
    rayParam.FilterDescendantsInstances = {char, Camera}
    local rayResult = workspace:Raycast(Origin, Direction, rayParam)
    if not rayResult then return true end
    return rayResult.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetRawTeam(player)
    if player.Team then return player.Team.Name end
    local char = player.Character
    local sources = {player, char}
    for _, src in pairs(sources) do
        if not src then continue end
        if src:GetAttribute("Team") then return tostring(src:GetAttribute("Team")) end
        if src:GetAttribute("TeamID") then return tostring(src:GetAttribute("TeamID")) end
        local teamObj = src:FindFirstChild("Team") or src:FindFirstChild("TeamID") or src:FindFirstChild("Leaderstats") and src.Leaderstats:FindFirstChild("Team")
        if teamObj and (teamObj:IsA("StringValue") or teamObj:IsA("NumberValue") or teamObj:IsA("IntValue")) then
            return tostring(teamObj.Value)
        end
    end
    if player.TeamColor then return tostring(player.TeamColor) end
    return nil
end

local function IsFriendly(targetPlayer)
    if not Config.TeamCheck then return false end
    local myTeam = GetRawTeam(LocalPlayer)
    local tarTeam = GetRawTeam(targetPlayer)
    
    if myTeam and tarTeam and myTeam ~= "" and tarTeam ~= "" then
        if myTeam == tarTeam then return true end
    end
    
    local myTeamStr = tostring(myTeam)
    local tarTeamStr = tostring(tarTeam)
    
    local IAmHostile = (myTeamStr == "Class - D" or myTeamStr == "Chaos Insurgency")
    local TarIsHostile = (tarTeamStr == "Class - D" or tarTeamStr == "Chaos Insurgency")
    
    if IAmHostile then
        if TarIsHostile then return true end
    else
        if not TarIsHostile and myTeamStr ~= "Neutral" and tarTeamStr ~= "Neutral" then 
            if myTeamStr == tarTeamStr then return true end
        end
    end
    return false
end

local function GetTarget()
    local Target, MinDist = nil, Config.FOV
    local MousePos = UserInputService:GetMouseLocation()
    local AimPartName = Config.AimPart
    if AimPartName == "Chest" then AimPartName = "UpperTorso" end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local pName = AimPartName
            if pName == "Random" then
                local parts = {"Head", "UpperTorso", "LowerTorso"}
                pName = parts[math.random(1, #parts)]
            end
            local Part = v.Character:FindFirstChild(pName)
            if Part then
                local Hum = v.Character:FindFirstChildOfClass("Humanoid")
                if Hum and Hum.Health > 0 and not IsFriendly(v) then
                    local Pos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                    if OnScreen then
                        local MouseDist = (Vector2.new(Pos.X, Pos.Y) - MousePos).Magnitude
                        if MouseDist < MinDist then
                            if Config.WallCheck then
                                if IsVisible(Part) then MinDist = MouseDist; Target = v end
                            else
                                MinDist = MouseDist; Target = v
                            end
                        end
                    end
                end
            end
        end
    end
    return Target
end

local Window = Rayfield:CreateWindow({
    Name = "Xeno Universal",
    LoadingTitle = "Loading",
    LoadingSubtitle = "Nearly Done",
    ConfigurationSaving = {
        Enabled = false
    }
})

local Combat = Window:CreateTab("Combat")
local Visuals = Window:CreateTab("Visuals")
local Utility = Window:CreateTab("Utility")
local Settings = Window:CreateTab("Settings")

Elements["Aimbot"] = Combat:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v) Config.Aimbot = v end,
})

Elements["AimPart"] = Combat:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Chest", "Random"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Callback = function(Option) Config.AimPart = Option[1] end,
})

Elements["WallCheck"] = Combat:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Callback = function(v) Config.WallCheck = v end,
})

Elements["TeamCheck"] = Combat:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(v) Config.TeamCheck = v end,
})

Elements["FOV"] = Combat:CreateSlider({
    Name = "FOV Radius",
    Range = {30, 800},
    Increment = 5,
    CurrentValue = 120,
    Callback = function(v) Config.FOV = v end,
})

Visuals:CreateSection("Enemy ESP")

Elements["ESP"] = Visuals:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Callback = function(v) Config.ESP = v end,
})

Elements["HealthESP"] = Visuals:CreateToggle({
    Name = "Health ESP",
    CurrentValue = false,
    Callback = function(v) Config.HealthESP = v end,
})

Elements["NameESP"] = Visuals:CreateToggle({
    Name = "Name ESP",
    CurrentValue = false,
    Callback = function(v) Config.NameESP = v end,
})

Elements["DistanceESP"] = Visuals:CreateToggle({
    Name = "Distance ESP",
    CurrentValue = false,
    Callback = function(v) Config.DistanceESP = v end,
})

Elements["ToolESP"] = Visuals:CreateToggle({
    Name = "Held Item ESP",
    CurrentValue = false,
    Callback = function(v) Config.ToolESP = v end,
})

Elements["ESPColor"] = Visuals:CreateColorPicker({
    Name = "Enemy ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value) Config.ESPColor = Value end
})

Visuals:CreateSection("Teammate ESP")

Elements["TeamESP"] = Visuals:CreateToggle({
    Name = "Team Box ESP",
    CurrentValue = false,
    Callback = function(v) Config.TeamESP = v end,
})

Elements["TeamHealthESP"] = Visuals:CreateToggle({
    Name = "Team Health ESP",
    CurrentValue = false,
    Callback = function(v) Config.TeamHealthESP = v end,
})

Elements["TeamNameESP"] = Visuals:CreateToggle({
    Name = "Team Name ESP",
    CurrentValue = false,
    Callback = function(v) Config.TeamNameESP = v end,
})

Elements["TeamDistanceESP"] = Visuals:CreateToggle({
    Name = "Team Distance ESP",
    CurrentValue = false,
    Callback = function(v) Config.TeamDistanceESP = v end,
})

Elements["TeamToolESP"] = Visuals:CreateToggle({
    Name = "Team Held Item ESP",
    CurrentValue = false,
    Callback = function(v) Config.TeamToolESP = v end,
})

Elements["TeamESPColor"] = Visuals:CreateColorPicker({
    Name = "Team ESP Color",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(Value) Config.TeamESPColor = Value end
})

Visuals:CreateSection("Global ESP Settings")

Elements["VisColorCheck"] = Visuals:CreateToggle({
    Name = "Visibility Color Check",
    CurrentValue = false,
    Callback = function(v) Config.VisColorCheck = v end,
})

Visuals:CreateSection("Radar")

Elements["Radar"] = Visuals:CreateToggle({
    Name = "Radar",
    CurrentValue = false,
    Callback = function(v) 
        Config.Radar = v 
        RadarGui.Enabled = v
    end,
})

Elements["RadarRange"] = Visuals:CreateSlider({
    Name = "Radar Range",
    Range = {50, 1000},
    Increment = 10,
    CurrentValue = 200,
    Callback = function(v) Config.RadarRange = v end,
})

Utility:CreateSection("Lighting")

Elements["FullBright"] = Utility:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Callback = function(v) Config.FullBright = v end,
})

Utility:CreateSection("Movement")

Elements["Noclip"] = Utility:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Config.Noclip = v end,
})

Elements["InfJump"] = Utility:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v) 
        Config.InfJump = v 
    end,
})

Utility:CreateSection("Fly")

local function UpdateFly(v)
    if not Config.FlyMaster then 
        Config.Fly = false 
        return 
    end
    Config.Fly = v
    local Character = LocalPlayer.Character
    local Hum = Character and Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not v and Hum and HRP then
        HRP.Velocity = Vector3.new(0,0,0)
    end
end

Elements["FlyMaster"] = Utility:CreateToggle({
    Name = "Fly Toggle",
    CurrentValue = false,
    Callback = function(v) 
        Config.FlyMaster = v 
        if not v then UpdateFly(false) end
    end,
})

Utility:CreateKeybind({
    Name = "Fly Keybind",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Callback = function() 
        if Config.FlyMaster then
            UpdateFly(not Config.Fly) 
        end
    end,
})

Elements["FlySpeed"] = Utility:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v) Config.FlySpeed = v end,
})

Elements["FlyMode"] = Utility:CreateDropdown({
    Name = "Fly Mode",
    Options = {"CFrame", "Velocity"},
    CurrentOption = {"CFrame"},
    MultipleOptions = false,
    Callback = function(Option) Config.FlyMode = Option[1] end,
})

Utility:CreateSection("Freecam")

local CamPart = nil
local function ToggleFreecam()
    Config.Freecam = not Config.Freecam
    local Character = LocalPlayer.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if Config.Freecam then
        if HRP then HRP.Anchored = true end
        CamPart = Instance.new("Part", workspace)
        CamPart.Anchored = true
        CamPart.CanCollide = false
        CamPart.Transparency = 1
        CamPart.CFrame = Camera.CFrame
        Camera.CameraSubject = CamPart
    else
        if HRP then HRP.Anchored = false end
        if CamPart then CamPart:Destroy() end
        if Character and Character:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = Character.Humanoid
        end
    end
end

Elements["Freecam"] = Utility:CreateToggle({
    Name = "Freecam",
    CurrentValue = false,
    Callback = function(v) if Config.Freecam ~= v then ToggleFreecam() end end,
})

Elements["FreecamSpeed"] = Utility:CreateSlider({
    Name = "Freecam Speed",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(v) Config.FreecamSpeed = v end,
})

Settings:CreateSection("Configs")

local ConfigNameInput = "main"
local SelectedConfig = ""

local ConfigDropdown = Settings:CreateDropdown({
    Name = "Select Config",
    Options = GetConfigList(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Option)
        SelectedConfig = Option[1]
    end,
})

Settings:CreateInput({
    Name = "Config Name",
    PlaceholderText = "main",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        ConfigNameInput = Text
    end,
})

Settings:CreateButton({
    Name = "Save Config",
    Callback = function()
        local saveTable = {}
        for i,v in pairs(Config) do
            if typeof(v) == "Color3" then
                saveTable[i] = {v.R, v.G, v.B}
            else
                saveTable[i] = v
            end
        end
        local json = HttpService:JSONEncode(saveTable)
        local success, err = pcall(function()
            writefile(FolderName .. "/" .. ConfigNameInput .. ".txt", json)
        end)
        if success then
            ConfigDropdown:Set(GetConfigList())
            Rayfield:Notify({Title = "Success", Content = "Saved " .. ConfigNameInput, Duration = 2})
        else
            Rayfield:Notify({Title = "Error", Content = "Failed to save: " .. tostring(err), Duration = 2})
        end
    end,
})

Settings:CreateButton({
    Name = "Load Config",
    Callback = function()
        if SelectedConfig ~= "" then
            local path = FolderName .. "/" .. SelectedConfig .. ".txt"
            local success, json = pcall(function() return readfile(path) end)
            if success then
                local data = HttpService:JSONDecode(json)
                for i,v in pairs(data) do
                    if Config[i] ~= nil then
                        if typeof(Config[i]) == "Color3" then
                            Config[i] = Color3.new(v[1], v[2], v[3])
                        else
                            Config[i] = v
                        end
                        
                        local element = Elements[i]
                        if element then
                            pcall(function()
                                if element.Set then
                                    if typeof(Config[i]) == "string" then
                                        element:Set({Config[i]})
                                    else
                                        element:Set(Config[i])
                                    end
                                end
                            end)
                        end
                    end
                end
                Rayfield:Notify({Title = "Success", Content = "Loaded " .. SelectedConfig, Duration = 2})
            else
                Rayfield:Notify({Title = "Error", Content = "Failed to load", Duration = 2})
            end
        end
    end,
})

Settings:CreateButton({
    Name = "Refresh",
    Callback = function()
        ConfigDropdown:Set(GetConfigList())
    end,
})

-- ============================================================
-- FOV CIRCLE using UICorner Method
-- ============================================================
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "FOVCircleGui"
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
FOVGui.Parent = game:GetService("CoreGui")

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOVCircle"
FOVFrame.Parent = FOVGui
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Size = UDim2.new(0, Config.FOV * 2, 0, Config.FOV * 2)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Visible = false

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1
FOVStroke.Transparency = 0
FOVStroke.Parent = FOVFrame
-- ============================================================

UserInputService.JumpRequest:Connect(function()
    if Config.InfJump and LocalPlayer.Character then
        local HRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if HRP and Hum then
            local MoveDir = Hum.MoveDirection
            if MoveDir.Magnitude > 0 then
                HRP.Velocity = Vector3.new(MoveDir.X * 60, 42, MoveDir.Z * 60)
            else
                HRP.Velocity = Vector3.new(HRP.Velocity.X, 42, HRP.Velocity.Z)
            end
            local Platform = Instance.new("Part", workspace)
            Platform.Size = Vector3.new(10, 1, 10)
            Platform.CFrame = HRP.CFrame * CFrame.new(0, -3.1, 0)
            Platform.Anchored = true
            Platform.Transparency = 1
            Hum:ChangeState(Enum.HumanoidStateType.Jumping)
            task.delay(0.1, function() Platform:Destroy() end)
        end
    end
end)

RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end
end)

RunService:BindToRenderStep("LogicUpdate", 201, function()
    if Config.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
    
    -- ============================================================
    -- FOV Circle update (UICorner method)
    -- ============================================================
    FOVFrame.Visible = Config.Aimbot
    if Config.Aimbot then
        local mousePos = UserInputService:GetMouseLocation()
        local diameter = Config.FOV * 2
        FOVFrame.Size = UDim2.new(0, diameter, 0, diameter)
        FOVFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
    end
    -- ============================================================
    
    if Config.Freecam and CamPart then
        local MoveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then MoveDir = MoveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then MoveDir = MoveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then MoveDir = MoveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then MoveDir = MoveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then MoveDir = MoveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then MoveDir = MoveDir - Vector3.new(0,1,0) end
        CamPart.CFrame = CamPart.CFrame + (MoveDir * Config.FreecamSpeed)
    end
    
    if Config.Fly and Config.FlyMaster then
        local Character = LocalPlayer.Character
        local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
        local Hum = Character and Character:FindFirstChildOfClass("Humanoid")
        if HRP and Hum then
            local MoveDir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then MoveDir = MoveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then MoveDir = MoveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then MoveDir = MoveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then MoveDir = MoveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then MoveDir = MoveDir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then MoveDir = MoveDir - Vector3.new(0,1,0) end
            if Config.FlyMode == "CFrame" then
                Hum.PlatformStand = true
                HRP.Velocity = Vector3.new(0,0,0)
                HRP.CFrame = HRP.CFrame + (MoveDir * (Config.FlySpeed / 50))
            elseif Config.FlyMode == "Velocity" then
                Hum.PlatformStand = false
                HRP.Velocity = MoveDir * Config.FlySpeed
            end
        end
    elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
    
    if Config.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local T = GetTarget()
        if T and T.Character then
            local tName = Config.AimPart == "Chest" and "UpperTorso" or Config.AimPart
            if tName == "Random" then
                local p = {"Head", "UpperTorso", "LowerTorso"}
                tName = p[math.random(1, #p)]
            end
            local p = T.Character:FindFirstChild(tName)
            if p then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, p.Position) end
        end
    end
end)

local function HandleESP(p)
    local Box = Drawing.new("Square")
    local HealthBarOutline = Drawing.new("Square")
    local HealthBar = Drawing.new("Square")
    local NameTag = Drawing.new("Text")
    local DistanceTag = Drawing.new("Text")
    local ToolTag = Drawing.new("Text")
    
    Box.Thickness = 1
    HealthBarOutline.Thickness = 1
    HealthBarOutline.Filled = true
    HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    HealthBar.Thickness = 1
    HealthBar.Filled = true
    NameTag.Size = 14; NameTag.Center = true; NameTag.Outline = true; NameTag.Font = 2
    DistanceTag.Size = 13; DistanceTag.Center = true; DistanceTag.Outline = true; DistanceTag.Font = 2
    ToolTag.Size = 13; ToolTag.Center = true; ToolTag.Outline = true; ToolTag.Font = 2
    
    local function SetVisible(bool)
        Box.Visible = bool
        HealthBarOutline.Visible = bool
        HealthBar.Visible = bool
        NameTag.Visible = bool
        DistanceTag.Visible = bool
        ToolTag.Visible = bool
    end

    local connection; connection = RunService.RenderStepped:Connect(function()
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") and p ~= LocalPlayer then
            local Hum = p.Character:FindFirstChildOfClass("Humanoid")
            local HRP = p.Character.HumanoidRootPart
            
            if Hum.Health <= 0 or not HRP:IsDescendantOf(workspace) then
                SetVisible(false)
                return
            end

            local friendly = IsFriendly(p)
            local Enabled = friendly and Config.TeamESP or (not friendly and Config.ESP)
            
            if not Enabled then
                SetVisible(false)
                return
            end

            local ShowHealth = friendly and Config.TeamHealthESP or Config.HealthESP
            local ShowName = friendly and Config.TeamNameESP or Config.NameESP
            local ShowDist = friendly and Config.TeamDistanceESP or Config.DistanceESP
            local ShowTool = friendly and Config.TeamToolESP or Config.ToolESP
            local BaseColor = friendly and Config.TeamESPColor or Config.ESPColor
            
            local cf = p.Character:GetPivot()
            local size = Vector3.new(4, 6, 0)
            local corners = {
                cf * CFrame.new(-size.X/2, size.Y/2, 0),
                cf * CFrame.new(size.X/2, size.Y/2, 0),
                cf * CFrame.new(-size.X/2, -size.Y/2, 0),
                cf * CFrame.new(size.X/2, -size.Y/2, 0)
            }
            
            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local onScreen = false
            
            for _, corner in pairs(corners) do
                local pos, visible = Camera:WorldToViewportPoint(corner.Position)
                if visible then onScreen = true end
                minX = math.min(minX, pos.X)
                minY = math.min(minY, pos.Y)
                maxX = math.max(maxX, pos.X)
                maxY = math.max(maxY, pos.Y)
            end

            if onScreen then
                local boxSize = Vector2.new(maxX - minX, maxY - minY)
                local boxPos = Vector2.new(minX, minY)
                local ActiveColor = BaseColor
                
                if not friendly and Config.VisColorCheck and Config.WallCheck then
                    ActiveColor = IsVisible(HRP) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                end
                
                Box.Visible = true
                Box.Size = boxSize
                Box.Position = boxPos
                Box.Color = ActiveColor
                
                NameTag.Visible = ShowName
                NameTag.Text = p.Name
                NameTag.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y - 15)
                NameTag.Color = ActiveColor
                
                DistanceTag.Visible = ShowDist
                local dist = (Camera.CFrame.Position - HRP.Position).Magnitude
                DistanceTag.Text = math.floor(dist) .. " studs"
                DistanceTag.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y + boxSize.Y + 5)
                DistanceTag.Color = Color3.new(1, 1, 1)

                local EquippedTool = p.Character:FindFirstChildOfClass("Tool")
                if ShowTool and EquippedTool then
                    ToolTag.Visible = true
                    ToolTag.Text = EquippedTool.Name
                    ToolTag.Position = Vector2.new(boxPos.X + boxSize.X/2, boxPos.Y + boxSize.Y + (ShowDist and 18 or 5))
                    ToolTag.Color = Color3.new(1, 0.8, 0.4)
                else
                    ToolTag.Visible = false
                end
                
                if ShowHealth then
                    local HealthPercent = math.clamp(Hum.Health / Hum.MaxHealth, 0, 1)
                    HealthBarOutline.Visible = true
                    HealthBarOutline.Size = Vector2.new(4, boxSize.Y + 2)
                    HealthBarOutline.Position = Vector2.new(boxPos.X - 6, boxPos.Y - 1)
                    HealthBar.Visible = true
                    HealthBar.Size = Vector2.new(2, boxSize.Y * HealthPercent)
                    HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (boxSize.Y * (1 - HealthPercent)))
                    HealthBar.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), HealthPercent)
                else
                    HealthBar.Visible = false
                    HealthBarOutline.Visible = false
                end
            else
                SetVisible(false)
            end
        else
            SetVisible(false)
        end
        
        if not p.Parent then 
            Box:Remove(); HealthBar:Remove(); HealthBarOutline:Remove(); NameTag:Remove(); DistanceTag:Remove(); ToolTag:Remove(); connection:Disconnect() 
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do HandleESP(p) end
Players.PlayerAdded:Connect(HandleESP)

UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.X then ToggleFreecam() end
end)

Rayfield:Notify({Title = "Starman Universal", Content = "Ready", Duration = 3})
