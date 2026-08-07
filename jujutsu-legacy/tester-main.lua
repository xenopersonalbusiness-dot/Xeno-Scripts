--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Player Variables
local LocalPlayer = Players.LocalPlayer

--// Game Detection
local PlaceId = game.PlaceId
local IsMainGame = PlaceId == 15694107053
local IsRaidGame = PlaceId == 18795268508 or PlaceId == 17889317592

if not IsMainGame and not IsRaidGame then
    return
end

--// Prevent Duplicate GUI / Runaway Loops / Leaked Connections on Re-Execution
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ExistingGui = PlayerGui:FindFirstChild("AutoFarmHubGui")
if ExistingGui then
    ExistingGui:Destroy()
end
-- disconnect global-service connections (they outlive Destroy()'d GUI instances)
if getgenv().AutoFarmHubGlobalConnections then
    for _, conn in pairs(getgenv().AutoFarmHubGlobalConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
getgenv().AutoFarmHubGlobalConnections = {}
-- a bumped generation token ends every loop from previous executions, including ones
-- blocked inside a Wait at re-execution time (the old false->true toggle missed those).
-- Older script versions gate their loops on this boolean instead, so it stays false forever
-- to kill any of their loops still alive in this session
getgenv().AutoFarmHubRunning = false
getgenv().AutoFarmHubGeneration = (getgenv().AutoFarmHubGeneration or 0) + 1
local ScriptGeneration = getgenv().AutoFarmHubGeneration
local function IsScriptActive()
    return getgenv().AutoFarmHubGeneration == ScriptGeneration
end

--// Script State
local isRunning = false
local isAutoMoves = false
local isAutoUseDrops = false
local isAutoStats = false
local isDisableVFX = false
local isSelectiveFarming = false
local isRaidFarming = false
local farmLoopActive = false
local lastPickedStartLevel = 0
local selectedFarmingTool = "Combat"
local selectedMobs = {}
local currentMobOptions = {}
local vesselValue = ""
local selectedTechnique = ""
local isAutoSpinTechnique = false
local isAutoRefillSpins = false
local StartToggle = nil
local isResetOnFarmStart = false

-- how far below the player's level a quest tier may sit before the area counts as outgrown
local OutgrownAreaGap = 25

--// Stat System
local statMap = {
    ["Curse Energy"] = "Ability",
    ["Sword"] = "Sword",
    ["Defense"] = "Defensive",
    ["Melee"] = "Melee"
}
local selectedStats = {}

--// UI References
local FarmToggle = nil
local SelectiveFarmToggle = nil
local SelectiveMobsFrame = nil
local ToolsFrame = nil

-- Instances:
local ScreenGui = Instance.new("ScreenGui")
local Container = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Image = Instance.new("ImageLabel")
local UICorner_2 = Instance.new("UICorner")
local Featureslist = Instance.new("Frame")
local Tabs = Instance.new("Frame")
local FarmingTabButton = Instance.new("TextButton")
local UsefulTabButton = Instance.new("TextButton")
local SettingsTabButton = Instance.new("TextButton")
local Credits = Instance.new("TextLabel")
local UICorner_3 = Instance.new("UICorner")

-- Toggle Button Instances
local ToggleButton = Instance.new("ImageButton")
local ToggleCorner = Instance.new("UICorner")
local ToggleText = Instance.new("TextLabel")

-- Close Button Instances
local CloseButton = Instance.new("TextButton")
local CloseUICorner = Instance.new("UICorner")

--Properties:
ScreenGui.Name = "AutoFarmHubGui"
ScreenGui.Parent = PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

Container.Name = "Container"
Container.Parent = ScreenGui
Container.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
Container.BorderSizePixel = 0
Container.Position = UDim2.new(0.304771006, 0, 0.217517093, 0)
Container.Size = UDim2.new(0, 629, 0, 384)

UICorner.Parent = Container

Image.Name = "Image"
Image.Parent = Container
Image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Image.BorderColor3 = Color3.fromRGB(0, 0, 0)
Image.BorderSizePixel = 0
Image.Position = UDim2.new(0, 10, 0, 12)
Image.Size = UDim2.new(0, 608, 0, 360)
Image.ZIndex = 2
Image.Image = "rbxassetid://8508980527"

UICorner_2.Parent = Image

CloseButton.Name = "CloseButton"
CloseButton.Parent = Container
CloseButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseButton.BackgroundTransparency = 0.5
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.Font = Enum.Font.FredokaOne
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
CloseButton.TextStrokeTransparency = 0
CloseButton.TextSize = 20
CloseButton.ZIndex = 10

CloseUICorner.Parent = CloseButton

ToggleButton.Name = "Button"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.BorderSizePixel = 0
ToggleButton.Position = UDim2.new(0.597701132, 0, 0.288425058, 0)
ToggleButton.Size = UDim2.new(0, 75, 0, 75)
ToggleButton.Image = "rbxassetid://136968465397176"
ToggleButton.Visible = false

ToggleCorner.Parent = ToggleButton

ToggleText.Name = "Text"
ToggleText.Parent = ToggleButton
ToggleText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleText.BackgroundTransparency = 1.000
ToggleText.BorderColor3 = Color3.fromRGB(0, 0, 0)
ToggleText.BorderSizePixel = 0
ToggleText.Position = UDim2.new(0, 0, 0.653333306, 0)
ToggleText.Size = UDim2.new(0, 75, 0, 26)
ToggleText.Font = Enum.Font.SourceSans
ToggleText.Text = "Meow"
ToggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleText.TextSize = 14.000
ToggleText.TextStrokeTransparency = 0.000

-- touch without a keyboard is the standard mobile signal; desktop is left untouched
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if IsMobile then
    local ContainerScale = Instance.new("UIScale")
    ContainerScale.Scale = 0.65
    ContainerScale.Parent = Container

    local ToggleScale = Instance.new("UIScale")
    ToggleScale.Scale = 0.65
    ToggleScale.Parent = ToggleButton
end

-- Close Logic
CloseButton.MouseButton1Click:Connect(function()
    Container.Visible = false
    ToggleButton.Visible = true
end)

Featureslist.Name = "Featureslist"
Featureslist.Parent = Image
Featureslist.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Featureslist.BackgroundTransparency = 1.000
Featureslist.BorderColor3 = Color3.fromRGB(0, 0, 0)
Featureslist.BorderSizePixel = 0
Featureslist.Position = UDim2.new(0.296985716, 0, 0.0222222228, 0)
Featureslist.Size = UDim2.new(0, 415, 0, 330)

Tabs.Name = "Tabs"
Tabs.Parent = Container
Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Tabs.BackgroundTransparency = 0.650
Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
Tabs.BorderSizePixel = 0
Tabs.Position = UDim2.new(0.025872793, 0, 0.0327699184, 0)
Tabs.Size = UDim2.new(0, 179, 0, 359)
Tabs.ZIndex = 3

local TabLayout = Instance.new("UIListLayout")
TabLayout.Parent = Tabs
TabLayout.Padding = UDim.new(0, 5)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local TabPadding = Instance.new("UIPadding")
TabPadding.Parent = Tabs
TabPadding.PaddingTop = UDim.new(0, 5)
TabPadding.PaddingLeft = UDim.new(0, 5)
TabPadding.PaddingRight = UDim.new(0, 5)

Credits.Name = "Credits"
Credits.Parent = Tabs
Credits.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Credits.BackgroundTransparency = 1.000
Credits.Size = UDim2.new(1, -10, 0, 50)
Credits.Font = Enum.Font.FredokaOne
Credits.Text = "Made By ! Xeno\n(xenobouthere on discord)"
Credits.TextColor3 = Color3.fromRGB(255, 255, 255)
Credits.TextScaled = true
Credits.TextSize = 14.000
Credits.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Credits.TextStrokeTransparency = 0.000
Credits.TextWrapped = true
Credits.LayoutOrder = 0

FarmingTabButton.Name = "FarmingTabButton"
FarmingTabButton.Parent = Tabs
FarmingTabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FarmingTabButton.BackgroundTransparency = 1.000
FarmingTabButton.Size = UDim2.new(1, -10, 0, 40)
FarmingTabButton.Font = Enum.Font.FredokaOne
FarmingTabButton.Text = "Farming"
FarmingTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmingTabButton.TextSize = 23.000
FarmingTabButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
FarmingTabButton.TextStrokeTransparency = 0.000
FarmingTabButton.LayoutOrder = 1

UsefulTabButton.Name = "UsefulTabButton"
UsefulTabButton.Parent = Tabs
UsefulTabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
UsefulTabButton.BackgroundTransparency = 1.000
UsefulTabButton.Size = UDim2.new(1, -10, 0, 40)
UsefulTabButton.Font = Enum.Font.FredokaOne
UsefulTabButton.Text = "Useful"
UsefulTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UsefulTabButton.TextSize = 23.000
UsefulTabButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
UsefulTabButton.TextStrokeTransparency = 0.000
UsefulTabButton.LayoutOrder = 2

SettingsTabButton.Name = "SettingsTabButton"
SettingsTabButton.Parent = Tabs
SettingsTabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SettingsTabButton.BackgroundTransparency = 1.000
SettingsTabButton.Size = UDim2.new(1, -10, 0, 40)
SettingsTabButton.Font = Enum.Font.FredokaOne
SettingsTabButton.Text = "Settings"
SettingsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsTabButton.TextSize = 23.000
SettingsTabButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
SettingsTabButton.TextStrokeTransparency = 0.000
SettingsTabButton.LayoutOrder = 3

UICorner_3.Parent = Tabs

--// Custom GUI Logic Setup
local Pages = {}

local function CreatePage(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = name
    frame.Parent = Featureslist
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    frame.ScrollBarThickness = 6
    frame.Visible = false
    
    local layout = Instance.new("UIListLayout")
    layout.Parent = frame
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local padding = Instance.new("UIPadding")
    padding.Parent = frame
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    
    Pages[name] = frame
    return frame
end

local FarmingPage = CreatePage("Farming")
local UsefulPage = CreatePage("Useful")
local SettingsPage = CreatePage("Settings")

FarmingPage.Visible = true

local TabButtons = {FarmingTabButton, UsefulTabButton, SettingsTabButton}
local TabPages = {FarmingPage, UsefulPage, SettingsPage}

for i, btn in ipairs(TabButtons) do
    btn.MouseButton1Click:Connect(function()
        for _, page in ipairs(TabPages) do page.Visible = false end
        TabPages[i].Visible = true
    end)
end

--// Smooth & Bug-Free Draggable Logic
local function MakeDragable(frame, onClickCallback)
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    local isMoving = false
    local releaseConn = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            isMoving = false
            dragStart = input.Position
            startPos = frame.Position

            if releaseConn then
                releaseConn:Disconnect()
                releaseConn = nil
            end

            releaseConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if releaseConn then
                        releaseConn:Disconnect()
                        releaseConn = nil
                    end
                    if not isMoving and onClickCallback then
                        onClickCallback()
                    end
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local globalConn = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 5 then
                isMoving = true
            end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(getgenv().AutoFarmHubGlobalConnections, globalConn)
end

MakeDragable(Container)
MakeDragable(ToggleButton, function()
    Container.Visible = true
    ToggleButton.Visible = false
end)


--// UI Component Generators
local function CreateToggle(parent, text, default, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.8
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    btn.TextStrokeTransparency = 0
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 16
    btn.Text = text .. ": Off"
    btn.Parent = parent

    local state = default or false
    local function updateVisual()
        btn.Text = text .. ": " .. (state and "On" or "Off")
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    end
    updateVisual()

    local self = {Value = state}
    function self:Set(val)
        state = val
        updateVisual()
        callback(state)
    end

    btn.MouseButton1Click:Connect(function()
        self:Set(not state)
    end)
    return self
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 100)
    btn.BackgroundTransparency = 0.8
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    btn.TextStrokeTransparency = 0
    btn.Font = Enum.Font.FredokaOne
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = parent

    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateInput(parent, text, placeholder, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.FredokaOne
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.6, 0, 1, 0)
    box.Position = UDim2.new(0.4, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    box.BackgroundTransparency = 0.8
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    box.TextStrokeTransparency = 0
    box.PlaceholderText = placeholder
    box.Font = Enum.Font.FredokaOne
    box.TextSize = 14
    box.Parent = frame

    box.FocusLost:Connect(function()
        callback(box.Text)
    end)
end

local function CreateListFrame(parent, title)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = parent
    
    local cLayout = Instance.new("UIListLayout")
    cLayout.Parent = container
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local headerBtn = Instance.new("TextButton")
    headerBtn.Size = UDim2.new(1, 0, 0, 25)
    headerBtn.BackgroundTransparency = 1
    headerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    headerBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    headerBtn.TextStrokeTransparency = 0
    headerBtn.Font = Enum.Font.FredokaOne
    headerBtn.TextSize = 16
    headerBtn.TextXAlignment = Enum.TextXAlignment.Left
    headerBtn.Text = "▸ " .. title
    headerBtn.LayoutOrder = 1
    headerBtn.Parent = container

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.ClipsDescendants = true
    contentFrame.BackgroundTransparency = 1
    contentFrame.LayoutOrder = 2
    contentFrame.Parent = container

    local scrolling = Instance.new("ScrollingFrame")
    scrolling.Size = UDim2.new(1, 0, 1, 0)
    scrolling.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scrolling.BackgroundTransparency = 0.9
    scrolling.BorderSizePixel = 0
    scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrolling.ScrollBarThickness = 4
    scrolling.Parent = contentFrame
    
    local innerLayout = Instance.new("UIListLayout")
    innerLayout.Parent = scrolling
    innerLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local isExpanded = false

    headerBtn.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        if isExpanded then
            contentFrame.Size = UDim2.new(1, 0, 0, 100) 
            headerBtn.Text = "▾ " .. title
        else
            contentFrame.Size = UDim2.new(1, 0, 0, 0) 
            headerBtn.Text = "▸ " .. title
        end
    end)

    return scrolling
end

--// Helper Functions
local function EquipToolByName(toolName)
    if not toolName then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local equippedTool = Character:FindFirstChildOfClass("Tool")
    if equippedTool and equippedTool.Name == toolName then return end
    local Backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if Backpack then
        local tool = Backpack:FindFirstChild(toolName, true)
        if tool and tool:IsA("Tool") then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then Humanoid:EquipTool(tool) task.wait(0.5) end
        end
    end
end

local function EquipVessel(vesselName)
    if not vesselName or vesselName == "" then return end
    local Event = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("VesselEquip")
    if Event then pcall(function() Event:FireServer(vesselName) end) end
end

-- VFX arrives as a server->client broadcast; suppressing it means silencing the listeners the
-- game bound to that remote rather than dropping anything we send.
local vfxConnections = {}

local function GetVFXRemote()
    local container = ReplicatedStorage:FindFirstChild("RemoteEvent")
    return container and container:FindFirstChild("VFX")
end

local function SetVFXBlocked(blocked)
    local remote = GetVFXRemote()
    if not remote then return end

    if blocked then
        if typeof(getconnections) ~= "function" then return end
        local ok, connections = pcall(getconnections, remote.OnClientEvent)
        if not ok then return end
        for _, connection in pairs(connections) do
            if connection.Disable then
                pcall(function() connection:Disable() end)
                table.insert(vfxConnections, connection)
            end
        end
    else
        for _, connection in pairs(vfxConnections) do
            if connection.Enable then pcall(function() connection:Enable() end) end
        end
        table.clear(vfxConnections)
    end
end

local function GetUnequippedTools()
    local tools = {}
    local seen = {}
    local Backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if Backpack then
        for _, item in pairs(Backpack:GetChildren()) do
            if item:IsA("Tool") and not seen[item.Name] then table.insert(tools, item.Name) seen[item.Name] = true
            elseif item:IsA("Model") then
                local innerTool = item:FindFirstChildWhichIsA("Tool")
                if innerTool and not seen[innerTool.Name] then table.insert(tools, innerTool.Name) seen[innerTool.Name] = true end
            end
        end
    end
    local Character = LocalPlayer.Character
    if Character then
        for _, item in pairs(Character:GetChildren()) do
            if item:IsA("Tool") and not seen[item.Name] then table.insert(tools, item.Name) seen[item.Name] = true end
        end
    end
    return tools
end

local function GetTechniqueNames()
    local names = {}
    local StarterGui = game:GetService("StarterGui")
    local techniqueSpin = StarterGui:FindFirstChild("TechniqueSpin")
    local frame = techniqueSpin and techniqueSpin:FindFirstChild("Frame")
    local mainFrame = frame and frame:FindFirstChild("MainFrame")
    local chanceFrame = mainFrame and mainFrame:FindFirstChild("ChanceFrame")
    local scrollingFrame = chanceFrame and chanceFrame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return names end
    for _, item in pairs(scrollingFrame:GetChildren()) do
        if item:IsA("GuiObject") then
            local label = item:IsA("TextLabel") and item or item:FindFirstChildWhichIsA("TextLabel", true)
            if label and label.Text ~= "" then
                local name = label.Text:gsub("%s*[%d%.]+%%%s*$", "")
                if name ~= "" and not table.find(names, name) then table.insert(names, name) end
            end
        end
    end
    return names
end

local function TweenTo(targetCFrame)
    local Character = LocalPlayer.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end
    local startCF = HRP.CFrame
    local distance = (HRP.Position - targetCFrame.Position).Magnitude
    if distance <= 5 then HRP.CFrame = targetCFrame return true end
    local tweenTime = math.clamp(distance / 1000, 0.05, 0.3)
    local elapsed = 0
    while elapsed < tweenTime do
        local currentHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not currentHRP or (not isRunning and not isSelectiveFarming and not isRaidFarming) then return false end
        local alpha = elapsed / tweenTime
        currentHRP.CFrame = startCF:Lerp(targetCFrame, alpha)
        elapsed = elapsed + 0.05
        task.wait(0.05)
    end
    local finalHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if finalHRP then finalHRP.CFrame = targetCFrame end
    return true
end

-- forces nearby world content to stream in before a lookup runs
local function EnsureStreamedAroundPlayer()
    local Character = LocalPlayer.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    pcall(function()
        LocalPlayer:RequestStreamAroundAsync(HRP.Position, 3)
    end)
end

local function GetPivotPart(model)
    if not model then return nil end
    -- quest markers are bare Parts holding only a BillboardGui and their Level values, so the
    -- object itself has to count before looking for anything nested
    if model:IsA("BasePart") then return model end
    local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    if part and part:IsA("BasePart") then return part end
    if model:IsA("Model") and model.PrimaryPart then return model.PrimaryPart end
    return model:FindFirstChildWhichIsA("BasePart", true)
end

local function GetAllAreaTeleportNPCs()
    EnsureStreamedAroundPlayer()
    local npcs = {}
    local npc2 = Workspace:FindFirstChild("Npc2")
    if npc2 then
        for _, child in pairs(npc2:GetChildren()) do
            if child.Name:sub(1, 8) == "Teleport" then table.insert(npcs, child) end
        end
    end
    table.sort(npcs, function(a, b) return a.Name < b.Name end)
    return npcs
end

-- reads the Level/LevelMax bracket an object gates on, falling back to its prompt attributes
local function GetLevelRange(obj)
    local levelVal = obj:FindFirstChild("Level")
    local maxLevelVal = obj:FindFirstChild("LevelMax")
    local reqLevel = levelVal and tonumber(levelVal.Value)
    local maxLevel = maxLevelVal and tonumber(maxLevelVal.Value)
    if not reqLevel then
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then reqLevel = tonumber(prompt:GetAttribute("LevelReq") or prompt:GetAttribute("Level")) end
    end
    return reqLevel, maxLevel
end

-- true / false when the object states a bracket, nil when it states nothing
local function MatchesLevel(obj, playerLevel)
    local reqLevel, maxLevel = GetLevelRange(obj)
    if not reqLevel then return nil end
    if playerLevel < reqLevel then return false end
    if maxLevel and playerLevel >= maxLevel then return false end
    return true
end

-- nearest prompt-bearing transition the player's level actually qualifies for. Objects that
-- state a bracket and fail it are never eligible; unstated ones are a last resort, and quest
-- givers must match explicitly so low levels are never routed to high-level questlines.
local function GetNearestTeleportTarget(position, playerLevel)
    local matched, unknown = {}, {}
    local seen = {}
    local function consider(obj, requireExplicit)
        if not obj or seen[obj] then return end
        if not obj:FindFirstChildWhichIsA("ProximityPrompt", true) then return end
        seen[obj] = true
        local ok = MatchesLevel(obj, playerLevel)
        if ok == true then table.insert(matched, obj)
        elseif ok == nil and not requireExplicit then table.insert(unknown, obj) end
    end

    EnsureStreamedAroundPlayer()
    local npc2 = Workspace:FindFirstChild("Npc2")
    if npc2 then
        local children = npc2:GetChildren()
        consider(children[19], false)
        for _, child in pairs(children) do consider(child, false) end
    end
    local questGivers = Workspace:FindFirstChild("QuestGivers")
    if questGivers then
        for _, npc in pairs(questGivers:GetChildren()) do consider(npc, true) end
    end

    local pool = #matched > 0 and matched or unknown
    local bestObj, bestPart, bestDist
    for _, obj in pairs(pool) do
        local part = GetPivotPart(obj)
        if part then
            local dist = (position - part.Position).Magnitude
            if not bestDist or dist < bestDist then bestObj, bestPart, bestDist = obj, part, dist end
        end
    end
    return bestObj, bestPart
end

local function GetLevelMatchedAreaTeleportNPC(playerLevel, npcs)
    for _, npc in pairs(npcs) do
        local levelVal = npc:FindFirstChild("Level")
        if levelVal then
            local maxLevelVal = npc:FindFirstChild("LevelMax")
            local reqLevel = tonumber(levelVal.Value) or 0
            local maxLevel = maxLevelVal and (tonumber(maxLevelVal.Value) or math.huge) or math.huge
            if playerLevel >= reqLevel and playerLevel < maxLevel then return npc end
        end
    end
    return nil
end

-- fireproximityprompt does not satisfy a hold-to-activate prompt on its own, and every area
-- teleporter here uses HoldDuration = 1, so the hold is cleared for the call and put back
local function TriggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    local hold = prompt.HoldDuration
    pcall(function()
        if hold > 0 then prompt.HoldDuration = 0 end
        fireproximityprompt(prompt)
    end)
    if hold > 0 then pcall(function() prompt.HoldDuration = hold end) end
end

-- a tier's marker can sit on an area transition rather than on the giver itself (the level 100
-- marker is placed on the Shibuya teleporter, with its giver living inside that area), so
-- whatever prompt is standing on the marker is what actually advances progress
local function FindNearestPrompt(position, radius)
    local bestPrompt, bestDist
    local function scan(container)
        if not container then return end
        for _, obj in pairs(container:GetChildren()) do
            local part = GetPivotPart(obj)
            if part then
                local dist = (position - part.Position).Magnitude
                if dist <= radius and (not bestDist or dist < bestDist) then
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then bestPrompt, bestDist = prompt, dist end
                end
            end
        end
    end
    scan(Workspace:FindFirstChild("Npc2"))
    scan(Workspace:FindFirstChild("QuestGivers"))
    return bestPrompt
end

-- a tier's giver only carries its prompt once streamed in, so this is re-run as the player
-- closes in rather than resolved once up front
local function FindQuestGiverByLevel(startLevel)
    local questGivers = Workspace:FindFirstChild("QuestGivers")
    if not questGivers then return nil, nil end
    for _, npc in pairs(questGivers:GetChildren()) do
        if npc.Name:sub(1, 8) == "Teleport" then continue end
        for _, prompt in pairs(npc:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                local npcReqLevel = prompt:GetAttribute("LevelReq") or prompt:GetAttribute("Level")
                if tonumber(npcReqLevel) == startLevel then return npc, prompt end
            end
        end
    end
    return nil, nil
end

-- the quest markers stop at level 100 (100/Max=101 is the last one); past that the chain is
-- defined solely by the LevelReq attribute on each quest giver's prompt. Those prompts only
-- exist while their (far-away) area is streamed in, so requirements are read once via a
-- stream request around each giver and cached by name.
local questGiverLevelCache = {}
local questGiverStreamAttempts = {}

local function GetQuestGiverReq(npc)
    local cached = questGiverLevelCache[npc.Name]
    if cached then return cached end
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    local req = prompt and tonumber(prompt:GetAttribute("LevelReq") or prompt:GetAttribute("Level"))
    if not req then
        local levelVal = npc:FindFirstChild("Level")
        req = levelVal and tonumber(levelVal.Value)
    end
    if req then questGiverLevelCache[npc.Name] = req end
    return req
end

-- the serial stream requests here can take minutes on a fresh join, so this only ever runs
-- as a background task — never on the farm loop's path. The farm falls back to markers (and
-- whatever givers are already cached) until it completes.
local questGiverPopulateActive = false
local function PopulateQuestGiverLevels()
    if questGiverPopulateActive then return end
    questGiverPopulateActive = true
    local questGivers = Workspace:FindFirstChild("QuestGivers")
    if questGivers then
        local pending = {}
        for _, npc in pairs(questGivers:GetChildren()) do
            if npc.Name:sub(1, 8) ~= "Teleport" and not GetQuestGiverReq(npc) then
                local attempts = questGiverStreamAttempts[npc.Name] or 0
                if attempts < 3 then
                    questGiverStreamAttempts[npc.Name] = attempts + 1
                    table.insert(pending, npc)
                end
            end
        end
        for _, npc in ipairs(pending) do
            if not IsScriptActive() then break end
            pcall(function()
                LocalPlayer:RequestStreamAroundAsync(npc:GetPivot().Position, 2)
            end)
            GetQuestGiverReq(npc)
        end
        if #pending > 0 then
            task.wait(1)
            for _, npc in ipairs(pending) do GetQuestGiverReq(npc) end
        end
    end
    questGiverPopulateActive = false
end

local function GetBestQuestGiver(playerLevel)
    local questGivers = Workspace:FindFirstChild("QuestGivers")
    if not questGivers then return nil, 0 end
    local bestNpc, bestReq = nil, 0
    for _, npc in pairs(questGivers:GetChildren()) do
        if npc.Name:sub(1, 8) ~= "Teleport" then
            local req = GetQuestGiverReq(npc)
            if req and req >= bestReq and playerLevel >= req then
                bestNpc, bestReq = npc, req
            end
        end
    end
    return bestNpc, bestReq
end

-- returns marker, startLevel, giverNpc, authoritative. When the giver scan meets or beats
-- the marker tier it wins outright (markers stop at 100), and "authoritative" tells the
-- caller the tier gap check must not discard it — giver gaps above 500 legitimately exceed
-- OutgrownAreaGap (535 -> 700, 950 -> 1150, ...)
local function GetBestQuestInfo()
    EnsureStreamedAroundPlayer()
    local statsFolder = LocalPlayer:FindFirstChild("Stats")
    if not statsFolder or not statsFolder:FindFirstChild("Level") then return nil, 0, nil, false end
    local playerLevel = tonumber(statsFolder.Level.Value) or 0
    local bestMarker = nil
    local bestStartLevel = 0
    local markersFolder = Workspace:FindFirstChild("Quests2") and Workspace.Quests2:FindFirstChild("Markers")
    if markersFolder then
        for _, marker in pairs(markersFolder:GetChildren()) do
            local levelVal = marker:FindFirstChild("Level")
            local maxLevelVal = marker:FindFirstChild("LevelMax")
            if levelVal then
                local reqLevel = tonumber(levelVal.Value) or 0
                local maxLevel = maxLevelVal and (tonumber(maxLevelVal.Value) or math.huge) or math.huge
                if playerLevel >= reqLevel and playerLevel < maxLevel then
                    if reqLevel > bestStartLevel then bestMarker = marker bestStartLevel = reqLevel end
                end
            end
        end
    end
    local giverNpc, giverReq = GetBestQuestGiver(playerLevel)
    if giverNpc and giverReq >= bestStartLevel then
        return nil, giverReq, giverNpc, true
    end
    if not bestMarker then return nil, 0, nil, false end
    return bestMarker, bestStartLevel, (FindQuestGiverByLevel(bestStartLevel)), false
end

local MobContainerNames = {"Enemies", "Monsters", "Mobs", "Boss", "Bosses", "Npcs", "NPCs"}

local function CollectMobs(container, filterFn, out)
    for _, obj in pairs(container:GetChildren()) do
        if obj:IsA("Model") and filterFn(obj.Name) then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local part = GetPivotPart(obj)
            if humanoid and part and humanoid.Health > 0 then
                table.insert(out, {mob = obj, health = humanoid.Health})
            end
        end
    end
end

local function FindMobByFilter(filterFn)
    EnsureStreamedAroundPlayer()
    local validMobs = {}
    for _, name in ipairs(MobContainerNames) do
        local folder = Workspace:FindFirstChild(name)
        if folder then CollectMobs(folder, filterFn, validMobs) end
    end
    if #validMobs == 0 then
        CollectMobs(Workspace, filterFn, validMobs)
        for _, child in pairs(Workspace:GetChildren()) do
            if child:IsA("Folder") then CollectMobs(child, filterFn, validMobs) end
        end
    end
    if #validMobs == 0 then return nil end
    table.sort(validMobs, function(a, b) return a.health < b.health end)
    return validMobs[1].mob
end

local function FindTargetMob(targetName)
    if not targetName or targetName == "" then return nil end
    local mob = FindMobByFilter(function(name) return name == targetName end)
    if mob then return mob end
    -- only ever widen to names that CONTAIN the full target; matching the other way round lets
    -- a short mob name ("Curse") satisfy any longer quest target and drags in wrong-tier mobs
    local lowerTarget = targetName:lower()
    return FindMobByFilter(function(name) return name:lower():find(lowerTarget, 1, true) ~= nil end)
end
local function FindSelectiveTargetMob(mobNames) return FindMobByFilter(function(name) return table.find(mobNames, name) ~= nil end) end

--// Independent Background Loops
local function PowerSpamLoop()
    local statIndex = 1
    while task.wait(0.1) and IsScriptActive() do
        if isAutoStats and #selectedStats > 0 then
            pcall(function()
                local powerRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("IncrementPower")
                if powerRemote then
                    local statName = selectedStats[statIndex]
                    local remoteName = statMap[statName]
                    if remoteName then
                        local statsFolder = LocalPlayer:FindFirstChild("Stats")
                        local pointVal = statsFolder and statsFolder:FindFirstChild("Point")
                        local points = pointVal and tonumber(pointVal.Value) or 0
                        local amount = points > 1000 and 10 or 5
                        powerRemote:FireServer(remoteName, amount)
                    end
                    statIndex = statIndex + 1
                    if statIndex > #selectedStats then statIndex = 1 end
                end
            end)
        end
    end
end

local function AutoMovesLoop()
    while task.wait(0.2) and IsScriptActive() do
        if isAutoMoves then
            pcall(function()
                local moveEvent = ReplicatedStorage:FindFirstChild("RemoteEvent") and ReplicatedStorage.RemoteEvent:FindFirstChild("information")
                if moveEvent and selectedFarmingTool then
                    moveEvent:FireServer(selectedFarmingTool, "UseX") task.wait(0.2)
                    moveEvent:FireServer(selectedFarmingTool, "UseZ") task.wait(0.2)
                    moveEvent:FireServer(selectedFarmingTool, "UseC") task.wait(0.2)
                    moveEvent:FireServer(selectedFarmingTool, "UseV")
                end
            end)
        end
    end
end

local function GetDropTools()
    local drops = {}
    local Backpack = LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if Backpack then
        for _, item in pairs(Backpack:GetChildren()) do
            if item:IsA("Tool") then
                local canStore = item:FindFirstChild("CanStore")
                if canStore and canStore:IsA("BoolValue") and canStore.Value then
                    table.insert(drops, item)
                end
            end
        end
    end
    return drops
end

local function AutoUseDropsLoop()
    while task.wait(1) and IsScriptActive() do
        if isAutoUseDrops then
            pcall(function()
                local drops = GetDropTools()
                if #drops == 0 then return end
                local Character = LocalPlayer.Character
                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                if not Humanoid then return end
                local previousTool = Character:FindFirstChildOfClass("Tool")
                local previousToolName = previousTool and previousTool.Name
                for _, tool in ipairs(drops) do
                    Humanoid:EquipTool(tool)
                    task.wait(0.3)
                    pcall(function() tool:Activate() end)
                    task.wait(0.3)
                end
                -- Hand back whatever was equipped before (usually the farming weapon)
                if previousToolName then EquipToolByName(previousToolName) end
            end)
        end
    end
end

local function AutoSpinTechniqueLoop()
    while task.wait(0.1) and IsScriptActive() do
        if isAutoSpinTechnique then
            local currentTechnique = LocalPlayer:FindFirstChild("Technique")
            if currentTechnique and selectedTechnique ~= "" and currentTechnique.Value == selectedTechnique then
                isAutoSpinTechnique = false
                if StartToggle then StartToggle:Set(false) end
            else
                pcall(function()
                    local setTechniqueRemote = ReplicatedStorage:FindFirstChild("SetTechnique")
                    if setTechniqueRemote then setTechniqueRemote:FireServer() end
                end)
            end
        end
    end
end

local function AutoRefillSpinsLoop()
    while task.wait(1) and IsScriptActive() do
        if isAutoRefillSpins then
            pcall(function()
                local statsFolder = LocalPlayer:FindFirstChild("Stats")
                local spinsVal = statsFolder and statsFolder:FindFirstChild("Spins")
                if spinsVal and spinsVal.Value == 0 then
                    local buyRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("BuySpinsTechnique3")
                    if buyRemote then buyRemote:FireServer() task.wait(2) end
                end
            end)
        end
    end
end

local function GetBossNames()
    local names = {}
    local monsterFolder = ReplicatedStorage:FindFirstChild("Monster")
    local bossFolder = monsterFolder and monsterFolder:FindFirstChild("Boss")
    if bossFolder then
        for _, obj in pairs(bossFolder:GetChildren()) do
            if not table.find(names, obj.Name) then table.insert(names, obj.Name) end
        end
    end
    table.sort(names)
    return names
end

local function UpdateMobsUI(mobList)
    for _, child in pairs(SelectiveMobsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, mobName in pairs(mobList) do
        local isSelected = table.find(selectedMobs, mobName) ~= nil
        local mobBtn = Instance.new("TextButton")
        mobBtn.Size = UDim2.new(1, 0, 0, 25)
        mobBtn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        mobBtn.BackgroundTransparency = 0.8
        mobBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        mobBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        mobBtn.TextStrokeTransparency = 0
        mobBtn.Font = Enum.Font.FredokaOne
        mobBtn.TextSize = 14
        mobBtn.Text = mobName .. (isSelected and " [X]" or "")
        mobBtn.Parent = SelectiveMobsFrame
        
        mobBtn.MouseButton1Click:Connect(function()
            if table.find(selectedMobs, mobName) then
                for i, v in pairs(selectedMobs) do if v == mobName then table.remove(selectedMobs, i) break end end
            else
                table.insert(selectedMobs, mobName)
            end
            UpdateMobsUI(mobList)
        end)
    end
end

local function UpdateToolsUI(tools)
    for _, child in pairs(ToolsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, toolName in pairs(tools) do
        local isSelected = (toolName == selectedFarmingTool)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0.8
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextStrokeTransparency = 0
        btn.Font = Enum.Font.FredokaOne
        btn.TextSize = 14
        btn.Text = toolName
        btn.Parent = ToolsFrame
        
        btn.MouseButton1Click:Connect(function()
            selectedFarmingTool = toolName
            UpdateToolsUI(tools)
        end)
    end
end

local function MobScannerLoop()
    while task.wait(5) and IsScriptActive() do
        local newMobs = GetBossNames()
        local changed = false
        if #newMobs ~= #currentMobOptions then changed = true
        else
            for i = 1, #newMobs do if newMobs[i] ~= currentMobOptions[i] then changed = true break end end
        end
        if changed then
            currentMobOptions = newMobs
            UpdateMobsUI(currentMobOptions)
        end
    end
end

local function FightMobLoop(mob, runningFlag)
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
    if not mobHRP or not mobHumanoid then return end
    if mobHRP.Parent then TweenTo(mobHRP.CFrame * CFrame.new(0, 0, 8)) if not runningFlag() then return end end
    EquipToolByName(selectedFarmingTool)
    local Character = LocalPlayer.Character
    local function FindToolEvent(char) if not char then return nil end local obj = char:FindFirstChild(selectedFarmingTool, true) return obj and obj:FindFirstChild("RemoteEvent", true) end
    local Event = FindToolEvent(Character)
    if not Event then task.wait(1) Character = LocalPlayer.Character Event = FindToolEvent(Character) end
    if not Event then return end
    
    local equipCheckElapsed = 0
    while runningFlag() do
        local mobAlive = false
        pcall(function() mobAlive = mobHumanoid.Parent and mobHumanoid.Health > 0 end)
        if not mobAlive then break end
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myChar or not myHRP or not myHum or myHum.Health <= 0 then break end
        equipCheckElapsed = equipCheckElapsed + 0.15
        if equipCheckElapsed >= 1 then
            equipCheckElapsed = 0
            local equippedTool = myChar:FindFirstChildOfClass("Tool")
            if not equippedTool or equippedTool.Name ~= selectedFarmingTool then
                EquipToolByName(selectedFarmingTool)
                Character = LocalPlayer.Character
                Event = FindToolEvent(Character) or Event
            end
        end
        pcall(function() Event:FireServer("Combat", "Combo") end)
        pcall(function() if mobHRP and mobHRP.Parent then myHRP.CFrame = mobHRP.CFrame * CFrame.new(0, 0, 8) end end)
        task.wait(0.15)
    end
    task.wait(1)
end

--// Main Farm Loop
local function AutoFarmLoop()
    if farmLoopActive then return end farmLoopActive = true
    -- errors inside the farm body must not silently end farming: log and re-enter while
    -- the toggle is still on
    while (isRunning or isSelectiveFarming) and IsScriptActive() do
    local ok, farmErr = pcall(function()
        local mobMissStreak = 0

        -- used whenever the current area has nothing to do: heads for the current-tier quest
        -- giver first (the giver chain covers 1-1500), and only then falls back to teleport
        -- prompts — the area teleporters no longer carry Level/LevelMax brackets, so the
        -- level-matched teleporter lookup can't be trusted on its own anymore
        local function GoToNearestTransition(playerLevel)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1) return end

            local targetObj = (GetBestQuestGiver(playerLevel))
            local targetPart = GetPivotPart(targetObj)
            if not targetPart then
                targetObj = GetLevelMatchedAreaTeleportNPC(playerLevel, GetAllAreaTeleportNPCs())
                targetPart = GetPivotPart(targetObj)
            end
            if not targetPart then
                targetObj, targetPart = GetNearestTeleportTarget(hrp.Position, playerLevel)
            end
            if not targetPart then task.wait(3) return end

            TweenTo(targetPart.CFrame * CFrame.new(0, 0, 3))
            if not isRunning then return end
            local prompt = targetPart:FindFirstChild("ProximityPrompt") or targetObj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then TriggerPrompt(prompt) task.wait(5) else task.wait(1) end
        end

        while isRunning or isSelectiveFarming do
            task.wait(0.5)
            if not IsScriptActive() then break end
            if not isRunning and not isSelectiveFarming then break end
            local Character = LocalPlayer.Character
            local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if not Character or not HRP or not Humanoid or Humanoid.Health <= 0 then
                -- the respawn can land before this check runs; waiting on CharacterAdded then
                -- blocks until the NEXT death, freezing the farm — take the live character if
                -- it already replaced the dead one
                local liveChar = LocalPlayer.Character
                if liveChar and liveChar ~= Character and liveChar.Parent then
                    Character = liveChar
                else
                    Character = LocalPlayer.CharacterAdded:Wait()
                end
                HRP = Character:WaitForChild("HumanoidRootPart", 10)
                if not HRP then continue end
                task.wait(2) EquipToolByName(selectedFarmingTool) continue
            end
            EquipToolByName(selectedFarmingTool)
            if isSelectiveFarming and #selectedMobs > 0 then
                local mob = FindSelectiveTargetMob(selectedMobs)
                if mob then FightMobLoop(mob, function() return isSelectiveFarming end) else task.wait(1) end
                continue
            end
            if not isRunning then continue end
            local statsFolder = LocalPlayer:FindFirstChild("Stats")
            local playerLevel = statsFolder and statsFolder:FindFirstChild("Level") and statsFolder.Level.Value or 0
            local questFolder = LocalPlayer:FindFirstChild("QuestValue")
            local targetValue = questFolder and questFolder:FindFirstChild("Target")
            local targetName = targetValue and targetValue.Value
            local bestQuestMarker, bestStartLevel, bestQuestNPC, bestQuestAuthoritative = GetBestQuestInfo()
            if targetName ~= "" and targetName ~= nil then
                if bestStartLevel > lastPickedStartLevel then
                    pcall(function() local cancelRemote = ReplicatedStorage:FindFirstChild("Quest") and ReplicatedStorage.Quest:FindFirstChild("CancelQuest") if cancelRemote then cancelRemote:FireServer() end end)
                    task.wait(1) targetName = ""
                end
            end
            if targetName == "" or not targetName then
                local targetObj = bestQuestNPC or bestQuestMarker
                local targetPart = GetPivotPart(targetObj)
                -- the best quest still loaded here can be far below the player's tier when the
                -- current-tier markers haven't streamed in; move on rather than farm backwards.
                -- Never applied to giver-scan results: that scan is complete, so its pick is the
                -- true current tier even when the gap to the player's level is large
                if targetPart and not bestQuestAuthoritative and bestStartLevel > 0 and (playerLevel - bestStartLevel) >= OutgrownAreaGap then
                    targetPart = nil
                end
                if targetPart then
                    local tweenSuccess = TweenTo(targetPart.CFrame * CFrame.new(0, 0, 3))
                    if not isRunning then break end
                    if tweenSuccess then
                        local attempts = 0
                        while isRunning and attempts < 15 do
                            local currentTarget = LocalPlayer:FindFirstChild("QuestValue") and LocalPlayer.QuestValue:FindFirstChild("Target")
                            if currentTarget and currentTarget.Value ~= "" then lastPickedStartLevel = bestStartLevel break end
                            if targetPart and HRP then HRP.CFrame = targetPart.CFrame * CFrame.new(0, 0, 0) end
                            -- standing on the marker streams the giver in, so keep re-resolving
                            -- it instead of relying on the lookup from before we travelled
                            local giver, giverPrompt = bestQuestNPC, nil
                            if giver then
                                giverPrompt = giver:FindFirstChildWhichIsA("ProximityPrompt", true)
                            else
                                giver, giverPrompt = FindQuestGiverByLevel(bestStartLevel)
                            end
                            if giverPrompt and giverPrompt.Enabled then
                                local giverPart = GetPivotPart(giver)
                                if giverPart and HRP and (HRP.Position - giverPart.Position).Magnitude > 12 then
                                    HRP.CFrame = giverPart.CFrame * CFrame.new(0, 0, 3)
                                end
                                TriggerPrompt(giverPrompt)
                            else
                                -- giver isn't in this area: the marker is sitting on the
                                -- transition that leads to it, so take it
                                local transition = FindNearestPrompt(HRP.Position, 40)
                                if transition then
                                    TriggerPrompt(transition)
                                    task.wait(3)
                                end
                            end
                            task.wait(0.3) attempts = attempts + 1
                        end
                    end
                else
                    GoToNearestTransition(playerLevel)
                end
            else
                local mob = FindTargetMob(targetName)
                if mob then
                    mobMissStreak = 0
                    FightMobLoop(mob, function() return isRunning end)
                else
                    mobMissStreak = mobMissStreak + 1
                    if mobMissStreak >= 4 then
                        mobMissStreak = 0
                        GoToNearestTransition(playerLevel)
                    else
                        task.wait(1)
                    end
                end
            end
        end
    end)
    if not ok then
        warn("[AutoFarmHub] farm loop error, retrying: " .. tostring(farmErr))
        task.wait(1)
    end
    end
    farmLoopActive = false
end

--// Raid Farm Loop
local function FindAnyRaidMob() return FindMobByFilter(function(name) return true end) end

local function RaidFarmLoop()
    if farmLoopActive then return end farmLoopActive = true
    while isRaidFarming and IsScriptActive() do
    local ok, farmErr = pcall(function()
        while isRaidFarming do
            task.wait(0.5)
            if not IsScriptActive() then break end
            if not isRaidFarming then break end
            local Character = LocalPlayer.Character
            local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if not Character or not HRP or not Humanoid or Humanoid.Health <= 0 then
                local liveChar = LocalPlayer.Character
                if liveChar and liveChar ~= Character and liveChar.Parent then
                    Character = liveChar
                else
                    Character = LocalPlayer.CharacterAdded:Wait()
                end
                HRP = Character:WaitForChild("HumanoidRootPart", 10)
                if not HRP then continue end
                task.wait(2) EquipToolByName(selectedFarmingTool) continue
            end
            EquipToolByName(selectedFarmingTool)
            local mob = FindAnyRaidMob()
            if mob then FightMobLoop(mob, function() return isRaidFarming end) else task.wait(1) end
        end
    end)
    if not ok then
        warn("[AutoFarmHub] raid loop error, retrying: " .. tostring(farmErr))
        task.wait(1)
    end
    end
    farmLoopActive = false
end

--// Custom GUI Setup
if IsRaidGame then
    UsefulTabButton.Visible = false
end

-- Farming Page
do
    if IsMainGame then
        FarmToggle = CreateToggle(FarmingPage, "Auto Level Farm", false, function(val) 
            isRunning = val
            if val then
                if isResetOnFarmStart then pcall(function() local r = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ResetStats") if r then r:FireServer() end end) end
                task.spawn(PopulateQuestGiverLevels)
                isSelectiveFarming = false if SelectiveFarmToggle then SelectiveFarmToggle:Set(false) end spawn(AutoFarmLoop)
            end
        end)
        
        SelectiveMobsFrame = CreateListFrame(FarmingPage, "Selective Farming Mobs")
        currentMobOptions = GetBossNames()
        UpdateMobsUI(currentMobOptions)
        
        SelectiveFarmToggle = CreateToggle(FarmingPage, "Enable Selective Farming", false, function(val) 
            isSelectiveFarming = val 
            if val then 
                if isResetOnFarmStart then pcall(function() local r = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ResetStats") if r then r:FireServer() end end) end
                isRunning = false if FarmToggle then FarmToggle:Set(false) end spawn(AutoFarmLoop) 
            end 
        end)
    elseif IsRaidGame then
        CreateToggle(FarmingPage, "Auto Farm Raid", false, function(val) 
            isRaidFarming = val 
            if val then 
                if isResetOnFarmStart then pcall(function() local r = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ResetStats") if r then r:FireServer() end end) end
                spawn(RaidFarmLoop) 
            end 
        end)
    end

    CreateToggle(FarmingPage, "Auto Moves", false, function(val) isAutoMoves = val end)
    CreateToggle(FarmingPage, "Auto Use Drops", false, function(val) isAutoUseDrops = val end)
    CreateToggle(FarmingPage, "Auto Stats", false, function(val) isAutoStats = val end)

    local statOptions = {"Curse Energy", "Sword", "Defense", "Melee"}
    for _, statName in pairs(statOptions) do
        CreateToggle(FarmingPage, statName, table.find(selectedStats, statName) ~= nil, function(val)
            if val then
                if not table.find(selectedStats, statName) then table.insert(selectedStats, statName) end
            else
                for i, v in pairs(selectedStats) do if v == statName then table.remove(selectedStats, i) break end end
            end
        end)
    end

    CreateToggle(FarmingPage, "Reset Stats on Farm Start", false, function(val) isResetOnFarmStart = val end)

    ToolsFrame = CreateListFrame(FarmingPage, "Select Farming Tool")
    UpdateToolsUI(GetUnequippedTools())
    
    CreateButton(FarmingPage, "Refresh Tool Dropdown", function()
        UpdateToolsUI(GetUnequippedTools())
    end)
end

-- Useful Page (Main Game Only)
if IsMainGame then
    CreateInput(UsefulPage, "Target Technique:", "", function(val) selectedTechnique = val end)
    StartToggle = CreateToggle(UsefulPage, "Start Spin Technique", false, function(val) isAutoSpinTechnique = val end)
    CreateToggle(UsefulPage, "Auto Refill Spins", false, function(val) isAutoRefillSpins = val end)

    CreateInput(UsefulPage, "Vessel Name:", "", function(val) vesselValue = val end)
    CreateButton(UsefulPage, "Equip Vessel", function() EquipVessel(vesselValue) end)
end

-- Settings Page
CreateToggle(SettingsPage, "Disable VFX", false, function(val)
    isDisableVFX = val
    SetVFXBlocked(val)
end)

--// Start Background Loops
spawn(PowerSpamLoop)
spawn(AutoMovesLoop)
spawn(AutoUseDropsLoop)
if IsMainGame then
    spawn(MobScannerLoop)
    spawn(AutoSpinTechniqueLoop)
    spawn(AutoRefillSpinsLoop)
    task.spawn(PopulateQuestGiverLevels)
end
