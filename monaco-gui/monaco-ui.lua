--[[
	MonacoUI.lua — VS Code / Monaco Editor styled GUI library for Roblox
	Works in LocalScripts. Load & use in any executor/script.

	API:
		local Monaco = require(path.to.MonacoUI)
		-- or via loadstring

		local ws = Monaco:CreateWorkspace({
			Name = "My Project",
			Theme = "Dark",          -- "Dark" | "Light"
			Width = 800,
			Height = 600,
		})

		-- File system
		ws:AddFile("main.lua", "print('hello world')")
		ws:AddFile("config.json", '{\n  "key": "value"\n}')
		ws:RemoveFile("config.json")
		ws:OpenFile("main.lua")
		ws:CloseFile("main.lua")
		ws:GetContent("main.lua")    -> string
		ws:SetContent("main.lua", "new code here")

		-- UI control
		ws:SetSidebarVisible(true/false)
		ws:Destroy()
		ws:Minimize()
		ws:Restore()
--]]

local MonacoUI = {}
MonacoUI.__index = MonacoUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player and player:WaitForChild("PlayerGui")

--=====================================================================
-- THEME
--=====================================================================
local THEMES = {
	Dark = {
		TitleBar        = Color3.fromRGB(60, 60, 60),
		TitleBarText    = Color3.fromRGB(204, 204, 204),
		ActivityBar     = Color3.fromRGB(51, 51, 51),
		Sidebar         = Color3.fromRGB(37, 37, 38),
		SidebarText     = Color3.fromRGB(204, 204, 204),
		SidebarSelected = Color3.fromRGB(55, 55, 60),
		SidebarHover    = Color3.fromRGB(42, 42, 44),
		TabBar          = Color3.fromRGB(37, 37, 38),
		TabActive       = Color3.fromRGB(30, 30, 30),
		TabInactive     = Color3.fromRGB(45, 45, 48),
		TabText         = Color3.fromRGB(153, 153, 153),
		TabTextActive   = Color3.fromRGB(204, 204, 204),
		EditorBg        = Color3.fromRGB(30, 30, 30),
		EditorText      = Color3.fromRGB(204, 204, 204),
		LineNumber      = Color3.fromRGB(80, 80, 80),
		LineNumberBg    = Color3.fromRGB(30, 30, 30),
		StatusBar       = Color3.fromRGB(0, 122, 204),
		StatusBarText   = Color3.fromRGB(255, 255, 255),
		ScrollBar       = Color3.fromRGB(65, 65, 65),
		ScrollBarBg     = Color3.fromRGB(30, 30, 30),
		Border          = Color3.fromRGB(20, 20, 20),
		Accent          = Color3.fromRGB(0, 122, 204),
		ButtonHover     = Color3.fromRGB(80, 80, 85),
		InputBg         = Color3.fromRGB(60, 60, 65),
		InputText       = Color3.fromRGB(204, 204, 204),
		TabBorder       = Color3.fromRGB(20, 20, 20),
		PopupBg         = Color3.fromRGB(37, 37, 38),
		PopupBorder     = Color3.fromRGB(69, 69, 74),
		CloseBtn        = Color3.fromRGB(204, 204, 204),
		CloseBtnHover   = Color3.fromRGB(255, 80, 80),
		-- syntax colors
		SynKeyword      = Color3.fromRGB(86, 156, 214),
		SynString       = Color3.fromRGB(206, 145, 120),
		SynComment      = Color3.fromRGB(106, 153, 85),
		SynNumber       = Color3.fromRGB(181, 206, 168),
		SynBuiltin      = Color3.fromRGB(78, 201, 176),
		SynFunction     = Color3.fromRGB(220, 220, 170),
		SynOperator     = Color3.fromRGB(212, 212, 212),
	},
}

--=====================================================================
-- HELPERS
--=====================================================================
local function make(name, props, children)
	local inst = Instance.new(name)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function tween(obj, props, dur, style)
	local ti = TweenInfo.new(dur or 0.15, Enum.EasingStyle[style or "Quad"], Enum.EasingDirection.Out)
	local tw = TweenService:Create(obj, ti, props)
	tw:Play()
	return tw
end

local SYN_KEYWORDS = {
	["and"]=true, ["break"]=true, ["do"]=true, ["else"]=true, ["elseif"]=true,
	["end"]=true, ["false"]=true, ["for"]=true, ["function"]=true, ["if"]=true,
	["in"]=true, ["local"]=true, ["nil"]=true, ["not"]=true, ["or"]=true,
	["repeat"]=true, ["return"]=true, ["then"]=true, ["true"]=true,
	["until"]=true, ["while"]=true, ["goto"]=true,
}

local SYN_BUILTINS = {
	["print"]=true, ["warn"]=true, ["error"]=true, ["pcall"]=true,
	["xpcall"]=true, ["require"]=true, ["loadstring"]=true, ["load"]=true,
	["type"]=true, ["typeof"]=true, ["tostring"]=true, ["tonumber"]=true,
	["ipairs"]=true, ["pairs"]=true, ["next"]=true, ["select"]=true,
	["unpack"]=true, ["rawequal"]=true, ["rawget"]=true, ["rawset"]=true,
	["setmetatable"]=true, ["getmetatable"]=true, ["Instance"]=true,
	["Color3"]=true, ["UDim2"]=true, ["Vector2"]=true, ["Vector3"]=true,
	["CFrame"]=true, ["Ray"]=true, ["Region3"]=true, ["NumberRange"]=true,
	["NumberSequence"]=true, ["ColorSequence"]=true, ["BrickColor"]=true,
	["Enum"]=true, ["Axes"]=true, ["Faces"]=true, ["RaycastParams"]=true,
	["TweenInfo"]=true, ["task"]=true, ["delay"]=true, ["spawn"]=true,
	["wait"]=true, ["tick"]=true, ["time"]=true, ["game"]=true,
	["workspace"]=true, ["script"]=true, ["shared"]=true, ["_G"]=true,
}



local function escapeHTML(s)
	return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end

local function tokenizeLua(source, theme)
	local lines = {}
	local lineNum = 1
	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local tokens = {}
		local i = 1
		while i <= #line do
			local char = line:sub(i, i)

			if char == "-" and line:sub(i+1, i+1) == "-" then
				if line:sub(i+2, i+3) == "[[" then
					local close = line:find("%]%]", i+4)
					if close then
						table.insert(tokens, {"comment", line:sub(i, close+1)})
						i = close + 2
					else
						table.insert(tokens, {"comment", line:sub(i)})
						break
					end
				else
					table.insert(tokens, {"comment", line:sub(i)})
					break
				end
			elseif char == '"' or char == "'" then
				local close = line:find(char, i+1)
				while close and line:sub(close-1, close-1) == "\\" do
					close = line:find(char, close+1)
				end
				if close then
					table.insert(tokens, {"string", line:sub(i, close)})
					i = close + 1
				else
					table.insert(tokens, {"string", line:sub(i)})
					break
				end
			elseif char:match("[%d]") and (i == 1 or not line:sub(i-1, i-1):match("[%w_]")) then
				local num = line:match("^[%d%.]+", i)
				if num then
					table.insert(tokens, {"number", num})
					i = i + #num
				else
					table.insert(tokens, {"normal", char})
					i = i + 1
				end
			elseif char:match("[%w_]") then
				local word = line:match("^[%w_]+", i)
				if SYN_KEYWORDS[word] then
					table.insert(tokens, {"keyword", word})
				elseif SYN_BUILTINS[word] then
					table.insert(tokens, {"builtin", word})
				else
					table.insert(tokens, {"normal", word})
				end
				i = i + #word
			elseif char:match("[%+%-%*%/%%%^%#%=%~%<%>%:%?%.]") then
				local op = line:match("^[%+%-%*%/%%%^%#%=%~%<%>%:%?%.]+", i)
				table.insert(tokens, {"operator", op})
				i = i + #op
			else
				table.insert(tokens, {"normal", char})
				i = i + 1
			end
		end
		lines[lineNum] = tokens
		lineNum = lineNum + 1
	end
	return lines
end

local function buildRichText(lineTokens, theme)
	local parts = {}
	for _, tok in ipairs(lineTokens) do
		local color
		if tok[1] == "keyword" then color = theme.SynKeyword
		elseif tok[1] == "string" then color = theme.SynString
		elseif tok[1] == "comment" then color = theme.SynComment
		elseif tok[1] == "number" then color = theme.SynNumber
		elseif tok[1] == "builtin" then color = theme.SynBuiltin
		elseif tok[1] == "function" then color = theme.SynFunction
		elseif tok[1] == "operator" then color = theme.SynOperator
		else color = theme.EditorText end
		local hex = "#" .. string.format("%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
		table.insert(parts, string.format('<font color="%s">%s</font>', hex, escapeHTML(tok[2])))
	end
	return table.concat(parts)
end

--=====================================================================
-- FILE SYSTEM
--=====================================================================
local FileSystem = {}
FileSystem.__index = FileSystem

function FileSystem.new()
	return setmetatable({
		_files = {},
		_openFiles = {},
		_activeFile = nil,
	}, FileSystem)
end

function FileSystem:AddFile(name, content)
	if not self._files[name] then
		self._files[name] = {
			name = name,
			content = content or "",
			savedContent = content or "",
			dirty = false,
		}
		return true
	end
	return false
end

function FileSystem:RemoveFile(name)
	self._files[name] = nil
	if self._openFiles[name] then
		self._openFiles[name] = nil
	end
	if self._activeFile == name then
		local keys = {}
		for k in pairs(self._openFiles) do
			table.insert(keys, k)
		end
		self._activeFile = keys[#keys] or nil
	end
end

function FileSystem:GetFile(name)
	return self._files[name]
end

function FileSystem:GetContent(name)
	local f = self._files[name]
	return f and f.content or nil
end

function FileSystem:SetContent(name, content)
	local f = self._files[name]
	if f then
		f.content = content or ""
		f.dirty = f.content ~= f.savedContent
		return true
	end
	return false
end

function FileSystem:OpenFile(name)
	if self._files[name] then
		self._openFiles[name] = true
		self._activeFile = name
		return true
	end
	return false
end

function FileSystem:CloseFile(name)
	self._openFiles[name] = nil
	if self._activeFile == name then
		local keys = {}
		for k in pairs(self._openFiles) do
			table.insert(keys, k)
		end
		self._activeFile = keys[#keys] or nil
	end
end

function FileSystem:GetFiles()
	local list = {}
	for _, f in pairs(self._files) do
		table.insert(list, f)
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

function FileSystem:GetOpenFiles()
	local list = {}
	for name in pairs(self._openFiles) do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

function FileSystem:GetActiveFile()
	return self._activeFile
end

--=====================================================================
-- WORKSPACE
--=====================================================================
local Workspace = {}
Workspace.__index = Workspace

function Workspace.new(opts)
	opts = opts or {}
	local self = setmetatable({
		_name = opts.Name or "Untitled",
		_theme = THEMES[opts.Theme] or THEMES.Dark,
		_size = {
			Width = opts.Width or 900,
			Height = opts.Height or 600,
		},
		_fs = FileSystem.new(),
		_destroyed = false,
		_minimized = false,
		_sidebarVisible = true,
		_sidebarWidth = 220,
		_dragging = false,
		_dragOffset = nil,
	}, Workspace)

	self:_buildGUI()
	self:_connectEvents()
	return self
end

function Workspace:_buildGUI()
	local th = self._theme
	local s = self._size

	-- Main ScreenGui
	self._screenGui = make("ScreenGui", {
		Name = "MonacoUI",
		DisplayOrder = 100,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	if playerGui then
		self._screenGui.Parent = playerGui
	end

	-- Main Frame
	self._main = make("Frame", {
		Name = "MainWindow",
		Size = UDim2.fromOffset(s.Width, s.Height),
		Position = UDim2.new(0.5, -s.Width / 2, 0.5, -s.Height / 2),
		BackgroundColor3 = th.EditorBg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 4) }),
		make("Frame", {
			Name = "DropShadow",
			Size = UDim2.new(1, 10, 1, 10),
			Position = UDim2.new(0, -5, 0, -5),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = -1,
		}),
	})
	self._main.Parent = self._screenGui

	-- Title Bar
	self:_buildTitleBar()
	-- Activity Bar + Sidebar
	self:_buildSidebar()
	-- Tab Bar
	self:_buildTabBar()
	-- Editor Area
	self:_buildEditor()
	-- Status Bar
	self:_buildStatusBar()

	-- Make window draggable
	self:_makeDraggable(self._titleBar)
end

function Workspace:_buildTitleBar()
	local th = self._theme
	self._titleBar = make("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = th.TitleBar,
		BorderSizePixel = 0,
	}, {
		make("UIStroke", {
			Color = Color3.fromRGB(40, 40, 40),
			Thickness = 1,
		}),
		make("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, -80, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1,
			Text = "  " .. self._name,
			TextColor3 = th.TitleBarText,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
	-- Window controls (minimize, close)
	local btnSize = 12
	local btnY = (30 - btnSize) / 2
	
	-- Minimize
	self._minBtn = make("ImageButton", {
		Name = "MinimizeBtn",
		Size = UDim2.fromOffset(btnSize, btnSize),
		Position = UDim2.new(1, -btnSize * 3 - 12, 0, btnY),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031094669",
		ImageColor3 = th.CloseBtn,
		ImageRectSize = Vector2.new(12, 12),
	})
	
	-- Close
	self._closeBtn = make("ImageButton", {
		Name = "CloseBtn",
		Size = UDim2.fromOffset(btnSize, btnSize),
		Position = UDim2.new(1, -btnSize - 8, 0, btnY),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031094678",
		ImageColor3 = th.CloseBtn,
		ImageRectSize = Vector2.new(12, 12),
	})

	self._titleBar.Parent = self._main
	self._minBtn.Parent = self._titleBar
	self._closeBtn.Parent = self._titleBar
end

function Workspace:_buildSidebar()
	local th = self._theme

	-- Activity bar (thin strip on far left, always visible)
	self._activityBar = make("Frame", {
		Name = "ActivityBar",
		Size = UDim2.new(0, 35, 1, -65),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundColor3 = th.ActivityBar,
		BorderSizePixel = 0,
	})
	self._activityBar.Parent = self._main

	-- Explorer icon in activity bar
	self._explorerBtn = make("ImageButton", {
		Name = "ExplorerBtn",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(0.5, -14, 0, 8),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6031094734",
		ImageColor3 = th.Accent,
		ImageRectSize = Vector2.new(20, 20),
	})
	self._explorerBtn.Parent = self._activityBar

	-- Sidebar (file explorer, sits next to activity bar, toggleable)
	self._sidebarFrame = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, self._sidebarWidth, 1, -65),
		Position = UDim2.new(0, 35, 0, 30),
		BackgroundColor3 = th.Sidebar,
		BorderSizePixel = 0,
	})

	self._sidebarHeader = make("TextLabel", {
		Name = "SidebarHeader",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = th.Sidebar,
		BorderSizePixel = 0,
		Text = "  EXPLORER",
		TextColor3 = th.SidebarText,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	self._sidebarHeader.Parent = self._sidebarFrame

	self._fileList = make("ScrollingFrame", {
		Name = "FileList",
		Size = UDim2.new(1, 0, 1, -28),
		Position = UDim2.new(0, 0, 0, 28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = th.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	self._fileList.Parent = self._sidebarFrame

	self._sidebarFrame.Parent = self._main
end

function Workspace:_buildTabBar()
	local th = self._theme
	self._tabBar = make("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, -(self._sidebarWidth + 35), 0, 35),
		Position = UDim2.new(0, self._sidebarWidth + 35, 0, 30),
		BackgroundColor3 = th.TabBar,
		BorderSizePixel = 0,
	}, {
		make("Frame", {
			Name = "TabContainer",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}),
	})
	self._tabBar.Parent = self._main
	self._tabContainer = self._tabBar:FindFirstChild("TabContainer")
end

function Workspace:_buildEditor()
	local th = self._theme
	self._editorFrame = make("ScrollingFrame", {
		Name = "EditorFrame",
		Size = UDim2.new(1, -(self._sidebarWidth + 35), 1, -100),
		Position = UDim2.new(0, self._sidebarWidth + 35, 0, 65),
		BackgroundColor3 = th.EditorBg,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = th.ScrollBar,
		ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})
	
	self._editorContent = make("Frame", {
		Name = "EditorContent",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = false,
	})
	self._editorContent.Parent = self._editorFrame

	-- TextBox for editing
	self._editorBox = make("TextBox", {
		Name = "EditorBox",
		Size = UDim2.new(1, -50, 0, 0),
		Position = UDim2.new(0, 45, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.new(0, 0, 0), -- invisible (RichText overlay handles display)
		TextSize = 13,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ClearTextOnFocus = false,
		MultiLine = true,
		RichText = false,
		AutomaticSize = Enum.AutomaticSize.Y,
	})

	-- RichText overlay for syntax highlighting
	self._editorOverlay = make("TextLabel", {
		Name = "EditorOverlay",
		Size = UDim2.new(1, -50, 0, 0),
		Position = UDim2.new(0, 45, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = th.EditorText,
		TextSize = 13,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		RichText = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
	})

	-- Line numbers
	self._lineNumbers = make("ScrollingFrame", {
		Name = "LineNumbers",
		Size = UDim2.new(0, 45, 1, 0),
		BackgroundColor3 = th.LineNumberBg,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingEnabled = false,
	})
	self._lineNumberLabels = make("Frame", {
		Name = "LineNumberLabels",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = false,
	})
	self._lineNumberLabels.Parent = self._lineNumbers
	self._lineNumbers.Parent = self._editorFrame

	self._editorFrame.Parent = self._main
	self._editorContent.Parent = self._editorFrame
	self._editorBox.Parent = self._editorContent
	self._editorOverlay.Parent = self._editorContent

	-- Sync scrolling between editor and line numbers
	self._editorFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		self._lineNumbers.CanvasPosition = Vector2.new(0, self._editorFrame.CanvasPosition.Y)
	end)
end

function Workspace:_buildStatusBar()
	local th = self._theme
	self._statusBar = make("Frame", {
		Name = "StatusBar",
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 1, -22),
		BackgroundColor3 = th.StatusBar,
		BorderSizePixel = 0,
	}, {
		make("TextLabel", {
			Name = "StatusLeft",
			Size = UDim2.new(0.5, -5, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Text = "MonacoUI",
			TextColor3 = th.StatusBarText,
			TextSize = 11,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		make("TextLabel", {
			Name = "StatusRight",
			Size = UDim2.new(0.5, -5, 1, 0),
			Position = UDim2.new(0.5, 3, 0, 0),
			BackgroundTransparency = 1,
			Text = "Ln 1, Col 1",
			TextColor3 = th.StatusBarText,
			TextSize = 11,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})
	self._statusBar.Parent = self._main
end

function Workspace:_connectEvents()
	local th = self._theme

	-- Close button
	self._closeBtn.MouseButton1Click:Connect(function()
		self:Destroy()
	end)
	self._closeBtn.MouseEnter:Connect(function()
		tween(self._closeBtn, { ImageColor3 = th.CloseBtnHover })
	end)
	self._closeBtn.MouseLeave:Connect(function()
		tween(self._closeBtn, { ImageColor3 = th.CloseBtn })
	end)

	-- Minimize button
	self._minBtn.MouseButton1Click:Connect(function()
		self:Minimize()
	end)

	-- Explorer toggle
	self._explorerBtn.MouseButton1Click:Connect(function()
		self:SetSidebarVisible(not self._sidebarVisible)
	end)

	-- Editor events
	self._editorBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:_onTextChanged()
	end)
	self._editorBox.Focused:Connect(function()
		tween(self._editorFrame, { BackgroundColor3 = Color3.fromRGB(35, 35, 35) })
	end)
	self._editorBox.FocusLost:Connect(function()
		tween(self._editorFrame, { BackgroundColor3 = th.EditorBg })
	end)

	-- Tab bar resize
	self._main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_repositionTabBar()
	end)
end

function Workspace:_makeDraggable(frame)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._dragging = true
			self._dragOffset = input.Position - self._main.AbsolutePosition
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and self._dragging then
			local pos = input.Position - self._dragOffset
			self._main.Position = UDim2.fromOffset(pos.X, pos.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._dragging = false
		end
	end)
end

function Workspace:_onTextChanged()
	local activeName = self._fs:GetActiveFile()
	if not activeName then return end
	local text = self._editorBox.Text
	self._fs:SetContent(activeName, text)
	self:_updateEditor()
end

function Workspace:_updateEditor()
	local th = self._theme
	local activeName = self._fs:GetActiveFile()
	local file = self._fs:GetFile(activeName)

	if not file then
		self._editorBox.Text = ""
		self._editorOverlay.Text = ""
		self:_updateLineNumbers({})
		self:_updateStatusBar(0, 0)
		return
	end

	local source = file.content or ""
	if self._editorBox.Text ~= source then
		self._editorBox.Text = source
	end

	-- Tokenize and build rich text
	local lines = tokenizeLua(source, th)
	local richLines = {}
	for _, tokens in ipairs(lines) do
		table.insert(richLines, buildRichText(tokens, th))
	end
	self._editorOverlay.Text = table.concat(richLines, "\n")

	-- Update line numbers
	self:_updateLineNumbers(lines)
	self:_updateStatusBar(#lines, 0)
end

function Workspace:_updateLineNumbers(lines)
	for _, child in ipairs(self._lineNumberLabels:GetChildren()) do
		child:Destroy()
	end

	local th = self._theme
	local count = #lines
	if count == 0 then count = 1 end

	local lineHeight = 18
	for i = 1, count do
		local lbl = make("TextLabel", {
			Name = "Line" .. i,
			Size = UDim2.new(1, 0, 0, lineHeight),
			Position = UDim2.new(0, 0, 0, (i-1) * lineHeight),
			BackgroundTransparency = 1,
			Text = tostring(i),
			TextColor3 = th.LineNumber,
			TextSize = 12,
			Font = Enum.Font.Code,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		lbl.Parent = self._lineNumberLabels
	end

	self._editorContent.Size = UDim2.new(1, 0, 0, math.max(count, 1) * lineHeight)
end

function Workspace:_updateStatusBar(lineCount, col)
	local right = self._statusBar:FindFirstChild("StatusRight")
	if right then
		right.Text = string.format("Ln %d, Col %d", lineCount, col)
	end
end

function Workspace:_repositionTabBar()
	local s = self._main.AbsoluteSize
	local activityW = 35
	local sidebarW = self._sidebarVisible and self._sidebarWidth or 0
	local offsetX = activityW + sidebarW

	self._tabBar.Size = UDim2.new(0, s.X - offsetX, 0, 35)
	self._tabBar.Position = UDim2.new(0, offsetX, 0, 30)
	self._editorFrame.Size = UDim2.new(0, s.X - offsetX, 1, -100)
	self._editorFrame.Position = UDim2.new(0, offsetX, 0, 65)
end

--=====================================================================
-- PUBLIC METHODS
--=====================================================================

function Workspace:AddFile(name, content)
	if self._fs:AddFile(name, content) then
		self:_refreshFileList()
		self:OpenFile(name)
		return true
	end
	return false
end

function Workspace:RemoveFile(name)
	self._fs:RemoveFile(name)
	self:_refreshFileList()
	if self._fs:GetFiles() then
		local active = self._fs:GetActiveFile()
		if active then
			self:OpenFile(active)
		else
			self._editorBox.Text = ""
			self._editorOverlay.Text = ""
			self:_updateLineNumbers({})
		end
	end
end

function Workspace:OpenFile(name)
	if self._fs:OpenFile(name) then
		self:_refreshTabs()
		self:_updateEditor()
	end
end

function Workspace:CloseFile(name)
	self._fs:CloseFile(name)
	self:_refreshTabs()
	self:_updateEditor()
end

function Workspace:GetContent(name)
	return self._fs:GetContent(name)
end

function Workspace:SetContent(name, content)
	if self._fs:SetContent(name, content) then
		if self._fs:GetActiveFile() == name then
			self:_updateEditor()
		end
		return true
	end
	return false
end

function Workspace:SetSidebarVisible(visible)
	self._sidebarVisible = visible
	self._sidebarFrame.Visible = visible
	self:_repositionTabBar()
end

function Workspace:Minimize()
	if not self._main then return end
	self._minimized = not self._minimized
	if self._minimized then
		tween(self._main, {
			Size = UDim2.fromOffset(self._size.Width, 30),
		})
		self._sidebarFrame.Visible = false
		self._tabBar.Visible = false
		self._editorFrame.Visible = false
		self._statusBar.Visible = false
		self._activityBar.Visible = false
	else
		tween(self._main, {
			Size = UDim2.fromOffset(self._size.Width, self._size.Height),
		})
		self._sidebarFrame.Visible = self._sidebarVisible
		self._tabBar.Visible = true
		self._editorFrame.Visible = true
		self._statusBar.Visible = true
		self._activityBar.Visible = true
	end
end

function Workspace:Destroy()
	self._destroyed = true
	if self._screenGui then
		self._screenGui:Destroy()
	end
	self._main = nil
	self._screenGui = nil
end

--=====================================================================
-- INTERNAL UI REFRESH
--=====================================================================

function Workspace:_refreshFileList()
	for _, child in ipairs(self._fileList:GetChildren()) do
		child:Destroy()
	end

	local th = self._theme
	local active = self._fs:GetActiveFile()

	-- Header label
	local header = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Text = "  WORKSPACE",
		TextColor3 = th.SidebarText,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	header.Parent = self._fileList

	local files = self._fs:GetFiles()
	local y = 24
	local itemHeight = 22

	-- Group files by extension
	local groups = {}
	for _, f in ipairs(files) do
		local ext = f.name:match("%.([%w]+)$") or "file"
		if not groups[ext] then groups[ext] = {} end
		table.insert(groups[ext], f)
	end

	local sortedExts = {}
	for ext in pairs(groups) do
		table.insert(sortedExts, ext)
	end
	table.sort(sortedExts)

	for _, ext in ipairs(sortedExts) do
		for _, f in ipairs(groups[ext]) do
			local isActive = f.name == active
			local btn = make("TextButton", {
				Name = f.name,
				Size = UDim2.new(1, -10, 0, itemHeight),
				Position = UDim2.new(0, 5, 0, y),
				BackgroundColor3 = isActive and th.SidebarSelected or th.Sidebar,
				BorderSizePixel = 0,
				Text = "",
			})

			local fileIcon = ext == "lua" and "◎" or ext == "luau" and "◎" or ext == "json" and "{}" or "◈"
			local lbl = make("TextLabel", {
				Size = UDim2.new(1, -10, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = fileIcon .. "  " .. f.name,
				TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or th.SidebarText,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			lbl.Parent = btn

			btn.MouseButton1Click:Connect(function()
				self:OpenFile(f.name)
			end)
			btn.MouseEnter:Connect(function()
				if f.name ~= active then
					tween(btn, { BackgroundColor3 = th.SidebarHover })
				end
			end)
			btn.MouseLeave:Connect(function()
				if f.name ~= active then
					tween(btn, { BackgroundColor3 = th.Sidebar })
				end
			end)

			btn.Parent = self._fileList
			y = y + itemHeight
		end
	end

	self._fileList.CanvasSize = UDim2.new(0, 0, 0, y + 4)
end

function Workspace:_refreshTabs()
	for _, child in ipairs(self._tabContainer:GetChildren()) do
		child:Destroy()
	end

	local th = self._theme
	local openFiles = self._fs:GetOpenFiles()
	local active = self._fs:GetActiveFile()

	local x = 0
	for _, name in ipairs(openFiles) do
		local isActive = name == active
		local tab = make("Frame", {
			Name = "Tab_" .. name,
			Size = UDim2.fromOffset(140, 35),
			Position = UDim2.fromOffset(x, 0),
			BackgroundColor3 = isActive and th.TabActive or th.TabInactive,
			BorderSizePixel = 0,
		})

		if isActive then
			make("Frame", {
				Name = "ActiveIndicator",
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = th.Accent,
				BorderSizePixel = 0,
			}).Parent = tab
		end

		-- Bottom border for inactive
		make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = th.TabBorder,
			BorderSizePixel = 0,
		}).Parent = tab

		-- Tab label
		local lbl = make("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -28, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1,
			Text = name,
			TextColor3 = isActive and th.TabTextActive or th.TabText,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		lbl.Parent = tab

		-- Close button on tab
		local closeTab = make("ImageButton", {
			Name = "CloseBtn",
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(1, -22, 0.5, -8),
			BackgroundTransparency = 1,
			Image = "rbxassetid://6031094678",
			ImageColor3 = th.TabText,
			ImageRectSize = Vector2.new(10, 10),
		})
		closeTab.MouseButton1Click:Connect(function()
			self:CloseFile(name)
		end)
		closeTab.Parent = tab

		-- Click to focus tab
		tab.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:OpenFile(name)
			end
		end)

		tab.Parent = self._tabContainer
		x = x + 140
	end

	self._tabContainer.Size = UDim2.fromOffset(math.max(x, 1), 35)
end

--=====================================================================
-- LIBRARY ENTRY POINT
--=====================================================================

function MonacoUI:CreateWorkspace(opts)
	local ws = Workspace.new(opts)
	-- Return only public methods
	return {
		AddFile = function(_, ...) return ws:AddFile(...) end,
		RemoveFile = function(_, ...) return ws:RemoveFile(...) end,
		OpenFile = function(_, ...) return ws:OpenFile(...) end,
		CloseFile = function(_, ...) return ws:CloseFile(...) end,
		GetContent = function(_, ...) return ws:GetContent(...) end,
		SetContent = function(_, ...) return ws:SetContent(...) end,
		SetSidebarVisible = function(_, ...) return ws:SetSidebarVisible(...) end,
		Minimize = function(...) return ws:Minimize(...) end,
		Destroy = function(...) return ws:Destroy(...) end,
	}
end

return MonacoUI
