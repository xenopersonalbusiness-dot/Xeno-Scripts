

local CONFIG = {
	ApiUrl = "https://opencode.ai/zen/v1/chat/completions",
	ApiKey = "sk-SxeAsboRdixZjIERfnviWniZxqThpcS6ity8lbduru9ib8l57md83FrRFeDgahbu",
	Model = "big-pickle",
	SystemPrompt = [[You are an AI inside a Roblox game. You have LIVE access by writing Lua code in ```exec blocks. It auto-runs and results come back to you. Use this:

```exec
print(game:GetService("Players"):GetPlayers()[1].Name)
```

RULES:
- NEVER explain what you can do. NEVER describe capabilities. NEVER say "I can...". Just DO it.
- For ANY question: immediately write ```exec code to get the answer. No preamble.
- To list players => write exec code that prints them. To get a value => write exec code that finds and prints it. To modify something => write exec code that does it.
- To find something unknown (e.g. a leaderboard), search services via code until you find it.
- print() outputs are returned to you. Use multiple exec steps if needed.
- When you have the data, answer directly and concisely. NO fluff, NO meta-commentary.
- Be extremely concise. One-line answers preferred.]]],
	MaxTokens = 4096,
	Temperature = 0.7,
	MaxExecSteps = 8,
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function httpPost(url, body, headers)
	local function checkResponse(resp)
		if not resp then return false, "nil response" end
		local status = resp.StatusCode or resp.statusCode or resp.status_code or resp.Status or 0
		local responseBody = resp.Body or resp.body or resp.Content or resp.content or ""
		return status >= 200 and status < 300, responseBody
	end

	if syn and syn.request then
		local r = syn.request({ Url = url, Method = "POST", Headers = headers, Body = body })
		return checkResponse(r)
	end
	if request then
		local r = request({ Url = url, Method = "POST", Headers = headers, Body = body })
		return checkResponse(r)
	end
	if http_request then
		local r = http_request({ Url = url, Method = "POST", Headers = headers, Body = body })
		return checkResponse(r)
	end
	local ok, result = pcall(function()
		return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, headers)
	end)
	if ok then return true, result end
	return false, "No HTTP method available"
end

local function copyToClipboard(text)
	local ok = pcall(function()
		if setclipboard then setclipboard(text) return end
		if toclipboard then toclipboard(text) return end
		if Clipboard and Clipboard.set then Clipboard.set(text) return end
		if writeclipboard then writeclipboard(text) return end
		error("No clipboard method")
	end)
	return ok
end

local function executeLua(code)
	local output = {}
	local function cap(...)
		local parts = {}
		for i = 1, select("#", ...) do
			parts[i] = tostring(select(i, ...))
		end
		output[#output + 1] = table.concat(parts, "  ")
	end

	local env = {
		print = cap,
		warn = cap,
		game = game,
		workspace = workspace,
		script = script,
		shared = _G,
		Players = Players,
		HttpService = HttpService,
		TweenService = TweenService,
		UserInputService = UserInputService,
		player = player,
		task = task,
		delay = task.delay,
		spawn = task.spawn,
		wait = task.wait,
		pcall = pcall,
		xpcall = xpcall,
		tostring = tostring,
		tonumber = tonumber,
		type = type,
		typeof = typeof,
		pairs = pairs,
		ipairs = ipairs,
		next = next,
		select = select,
		unpack = table.unpack or unpack,
		error = error,
		assert = assert,
		table = table,
		string = string,
		math = math,
		Vector2 = Vector2,
		Vector3 = Vector3,
		CFrame = CFrame,
		Color3 = Color3,
		UDim2 = UDim2,
		UDim = UDim,
		BrickColor = BrickColor,
		Instance = Instance,
		Enum = Enum,
		Axes = Axes,
		Ray = Ray,
		Region3 = Region3,
		Region3int16 = Region3int16,
		TweenInfo = TweenInfo,
		NumberRange = NumberRange,
		NumberSequence = NumberSequence,
		ColorSequence = ColorSequence,
		NumberSequenceKeypoint = NumberSequenceKeypoint,
		ColorSequenceKeypoint = ColorSequenceKeypoint,
		Faces = Faces,
		Random = Random,
		Rect = Rect,
		DateTime = DateTime,
		PathWaypoint = PathWaypoint,
		_ = _G,
	}

	local fn, loadErr
	if loadstring then
		fn, loadErr = loadstring(code)
	elseif load then
		fn, loadErr = load(code)
	else
		return "Error: No code execution method available (loadstring/load not found)"
	end

	if not fn then
		return "Error: " .. tostring(loadErr)
	end

	local ok, setOk = pcall(function()
		if setfenv then
			setfenv(fn, env)
			setOk = true
		end
	end)

	local ok, execResult = pcall(fn)
	if not ok then
		return "Error: " .. tostring(execResult)
	end

	if execResult ~= nil and #output == 0 then
		output[#output + 1] = tostring(execResult)
	end

	if #output == 0 then
		return "(executed successfully, no output)"
	end

	return table.concat(output, "\n")
end

local conversationHistory = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AIAgentGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 480, 0, 600)
main.Position = UDim2.new(0.5, -240, 0.5, -300)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(35, 35, 45)
stroke.Parent = main

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 12)
titleBarCorner.Parent = titleBar

local titleBarFill = Instance.new("Frame")
titleBarFill.Size = UDim2.new(1, 0, 0, 12)
titleBarFill.Position = UDim2.new(0, 0, 1, -12)
titleBarFill.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
titleBarFill.BorderSizePixel = 0
titleBarFill.Parent = titleBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 200, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Xeno's Assistant"
title.TextColor3 = Color3.fromRGB(200, 200, 210)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -36, 0.5, -15)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(120, 120, 130)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -66, 0.5, -15)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "─"
minimizeBtn.TextColor3 = Color3.fromRGB(120, 120, 130)
minimizeBtn.TextSize = 18
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Parent = titleBar

local chatContainer = Instance.new("Frame")
chatContainer.Name = "ChatContainer"
chatContainer.Size = UDim2.new(1, -20, 1, -106)
chatContainer.Position = UDim2.new(0, 10, 0, 52)
chatContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
chatContainer.BorderSizePixel = 0
chatContainer.ClipsDescendants = true
chatContainer.Parent = main

local chatContainerCorner = Instance.new("UICorner")
chatContainerCorner.CornerRadius = UDim.new(0, 8)
chatContainerCorner.Parent = chatContainer

local chatList = Instance.new("ScrollingFrame")
chatList.Name = "ChatList"
chatList.Size = UDim2.new(1, -16, 1, -16)
chatList.Position = UDim2.new(0, 8, 0, 8)
chatList.BackgroundTransparency = 1
chatList.BorderSizePixel = 0
chatList.ClipsDescendants = true
chatList.ScrollBarThickness = 4
chatList.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
chatList.CanvasSize = UDim2.new(0, 0, 0, 0)
chatList.Parent = chatContainer

local chatPadding = Instance.new("UIPadding")
chatPadding.PaddingTop = UDim.new(0, 6)
chatPadding.Parent = chatList

local chatLayout = Instance.new("UIListLayout")
chatLayout.Padding = UDim.new(0, 8)
chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
chatLayout.Parent = chatList

local function updateCanvas()
	chatList.CanvasSize = UDim2.new(0, 0, 0, chatLayout.AbsoluteContentSize.Y + 12)
end

chatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

local inputContainer = Instance.new("Frame")
inputContainer.Name = "InputContainer"
inputContainer.Size = UDim2.new(1, -20, 0, 42)
inputContainer.Position = UDim2.new(0, 10, 1, -52)
inputContainer.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
inputContainer.BorderSizePixel = 0
inputContainer.Parent = main

local inputContainerCorner = Instance.new("UICorner")
inputContainerCorner.CornerRadius = UDim.new(0, 8)
inputContainerCorner.Parent = inputContainer

local inputStroke = Instance.new("UIStroke")
inputStroke.Thickness = 1
inputStroke.Color = Color3.fromRGB(40, 40, 52)
inputStroke.Parent = inputContainer

local textBox = Instance.new("TextBox")
textBox.Name = "TextBox"
textBox.Size = UDim2.new(1, -52, 1, 0)
textBox.Position = UDim2.new(0, 12, 0, 0)
textBox.BackgroundTransparency = 1
textBox.PlaceholderText = "Message AI Agent..."
textBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(220, 220, 230)
textBox.TextSize = 14
textBox.Font = Enum.Font.Gotham
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.ClearTextOnFocus = false
textBox.Parent = inputContainer

local sendBtn = Instance.new("TextButton")
sendBtn.Name = "SendBtn"
sendBtn.Size = UDim2.new(0, 32, 0, 32)
sendBtn.Position = UDim2.new(1, -40, 0.5, -16)
sendBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
sendBtn.Text = "→"
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 18
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Parent = inputContainer

local sendBtnCorner = Instance.new("UICorner")
sendBtnCorner.CornerRadius = UDim.new(0, 6)
sendBtnCorner.Parent = sendBtn

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function scrollToBottom()
	updateCanvas()
	task.wait()
	chatList.CanvasPosition = Vector2.new(0, chatList.CanvasSize.Y.Offset)
end

local thinkingRow = Instance.new("Frame")
thinkingRow.Name = "ThinkingRow"
thinkingRow.BackgroundTransparency = 1
thinkingRow.BorderSizePixel = 0
thinkingRow.Size = UDim2.new(1, 0, 0, 0)
thinkingRow.AutomaticSize = Enum.AutomaticSize.Y
thinkingRow.Visible = false
thinkingRow.Parent = chatList

local thinkAvatar = Instance.new("Frame")
thinkAvatar.Name = "ThinkAvatar"
thinkAvatar.Size = UDim2.new(0, 28, 0, 28)
thinkAvatar.Position = UDim2.new(0, 0, 0, 0)
thinkAvatar.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
thinkAvatar.BorderSizePixel = 0
thinkAvatar.Parent = thinkingRow

local thinkAvatarCorner = Instance.new("UICorner")
thinkAvatarCorner.CornerRadius = UDim.new(1, 0)
thinkAvatarCorner.Parent = thinkAvatar

local thinkAvatarLabel = Instance.new("TextLabel")
thinkAvatarLabel.Size = UDim2.new(1, 0, 1, 0)
thinkAvatarLabel.BackgroundTransparency = 1
thinkAvatarLabel.Text = "AI"
thinkAvatarLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
thinkAvatarLabel.TextSize = 12
thinkAvatarLabel.Font = Enum.Font.GothamBold
thinkAvatarLabel.Parent = thinkAvatar

local thinkPill = Instance.new("Frame")
thinkPill.Name = "ThinkPill"
thinkPill.Size = UDim2.new(0, 60, 0, 32)
thinkPill.Position = UDim2.new(0, 36, 0, 0)
thinkPill.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
thinkPill.BorderSizePixel = 0
thinkPill.Parent = thinkingRow

local thinkPillCorner = Instance.new("UICorner")
thinkPillCorner.CornerRadius = UDim.new(1, 0)
thinkPillCorner.Parent = thinkPill

local thinkDots = Instance.new("TextLabel")
thinkDots.Name = "ThinkDots"
thinkDots.Size = UDim2.new(1, 0, 1, 0)
thinkDots.BackgroundTransparency = 1
thinkDots.Text = "..."
thinkDots.TextColor3 = Color3.fromRGB(180, 180, 190)
thinkDots.TextSize = 20
thinkDots.Font = Enum.Font.GothamBold
thinkDots.Parent = thinkPill

local thinkThread = nil
local function showThinking()
	thinkingRow.Visible = true
	thinkingRow.LayoutOrder = 99999
	thinkingRow.Parent = chatList
	scrollToBottom()

	local dots = { "   ", ".  ", ".. ", "..." }
	local i = 0
	thinkThread = task.spawn(function()
		while thinkingRow.Visible do
			i = i % 4 + 1
			thinkDots.Text = dots[i]
			task.wait(0.4)
		end
	end)
end

local function hideThinking()
	thinkingRow.Visible = false
	thinkingRow.LayoutOrder = 0
	if thinkThread then
		task.cancel(thinkThread)
		thinkThread = nil
	end
end

local function parseCodeBlocks(text)
	local segments = {}
	local pattern = "```([%w_]+)\n(.-)```"
	local pos = 1
	while pos <= #text do
		local ms, me, lang, code = text:find(pattern, pos)
		if ms then
			if ms > pos then
				table.insert(segments, { type = "text", content = text:sub(pos, ms - 1) })
			end
			table.insert(segments, { type = "code", language = lang, content = code })
			pos = me + 1
		else
			local s2, e2, code2 = text:find("```\n(.-)```", pos)
			if s2 then
				if s2 > pos then
					table.insert(segments, { type = "text", content = text:sub(pos, s2 - 1) })
				end
				table.insert(segments, { type = "code", language = "", content = code2 })
				pos = e2 + 1
			else
				table.insert(segments, { type = "text", content = text:sub(pos) })
				break
			end
		end
	end
	if #segments == 0 then
		table.insert(segments, { type = "text", content = text })
	end
	return segments
end

local function extractExecBlock(text)
	local _, me, code = text:find("```exec\n(.-)```")
	if _ then return code end
	_, me, code = text:find("```exec (.-)```")
	if _ then return code end
	return nil
end

local BUBBLE_WIDTH = 340

local function createTextSegment(parent, text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 240)
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextWrapped = true
	label.RichText = true
	label.Size = UDim2.new(1, -24, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Parent = parent
	return label
end

local function createCodeSegment(parent, language, code)
	local container = Instance.new("Frame")
	container.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, -24, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Parent = parent

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 6)
	containerCorner.Parent = container

	local containerList = Instance.new("UIListLayout")
	containerList.SortOrder = Enum.SortOrder.LayoutOrder
	containerList.Parent = container

	local headerBar = Instance.new("Frame")
	headerBar.Size = UDim2.new(1, 0, 0, 28)
	headerBar.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	headerBar.BorderSizePixel = 0
	headerBar.Parent = container

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 6)
	headerCorner.Parent = headerBar

	local headerFill = Instance.new("Frame")
	headerFill.Size = UDim2.new(1, 0, 0, 8)
	headerFill.Position = UDim2.new(0, 0, 1, -8)
	headerFill.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	headerFill.BorderSizePixel = 0
	headerFill.Parent = headerBar

	local headerList = Instance.new("UIListLayout")
	headerList.FillDirection = Enum.FillDirection.Horizontal
	headerList.VerticalAlignment = Enum.VerticalAlignment.Center
	headerList.Padding = UDim.new(0, 8)
	headerList.Parent = headerBar

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 10)
	headerPad.PaddingRight = UDim.new(0, 10)
	headerPad.Parent = headerBar

	local langLabel = Instance.new("TextLabel")
	langLabel.Size = UDim2.new(0, 0, 1, 0)
	langLabel.AutomaticSize = Enum.AutomaticSize.X
	langLabel.BackgroundTransparency = 1
	local labelText = language:upper()
	if language == "exec" then labelText = "EXEC" else labelText = language:upper() end
	langLabel.Text = labelText
	langLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	langLabel.TextSize = 10
	langLabel.Font = Enum.Font.GothamBold
	langLabel.TextXAlignment = Enum.TextXAlignment.Left
	langLabel.Parent = headerBar

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0, 50, 0, 20)
	copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	copyBtn.Text = "Copy"
	copyBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
	copyBtn.TextSize = 10
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.Parent = headerBar

	local copyCorner = Instance.new("UICorner")
	copyCorner.CornerRadius = UDim.new(0, 4)
	copyCorner.Parent = copyBtn

	local codeBody = Instance.new("Frame")
	codeBody.BackgroundTransparency = 1
	codeBody.Size = UDim2.new(1, 0, 0, 0)
	codeBody.AutomaticSize = Enum.AutomaticSize.Y
	codeBody.Parent = container

	local codeBodyPad = Instance.new("UIPadding")
	codeBodyPad.PaddingLeft = UDim.new(0, 10)
	codeBodyPad.PaddingRight = UDim.new(0, 10)
	codeBodyPad.PaddingTop = UDim.new(0, 8)
	codeBodyPad.PaddingBottom = UDim.new(0, 10)
	codeBodyPad.Parent = codeBody

	local codeLabel = Instance.new("TextLabel")
	codeLabel.Size = UDim2.new(1, 0, 0, 0)
	codeLabel.BackgroundTransparency = 1
	codeLabel.Text = code
	codeLabel.TextColor3 = Color3.fromRGB(200, 220, 240)
	codeLabel.TextSize = 12
	codeLabel.Font = Enum.Font.Code
	codeLabel.TextWrapped = true
	codeLabel.TextXAlignment = Enum.TextXAlignment.Left
	codeLabel.AutomaticSize = Enum.AutomaticSize.Y
	codeLabel.Parent = codeBody

	copyBtn.MouseButton1Click:Connect(function()
		local ok = copyToClipboard(code)
		if ok then
			copyBtn.Text = "Copied!"
			copyBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 80)
			task.delay(2, function()
				copyBtn.Text = "Copy"
				copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			end)
		else
			copyBtn.Text = "Failed"
			copyBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			task.delay(2, function()
				copyBtn.Text = "Copy"
				copyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			end)
		end
	end)

	return container
end

local function createMessageBubble(text, isUser)
	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y

	if isUser then row.Name = "UserRow" else row.Name = "AgentRow" end

	local avatar = Instance.new("Frame")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, 28, 0, 28)
	avatar.BorderSizePixel = 0
	avatar.Parent = row

	local avatarColor
	if isUser then
		avatarColor = Color3.fromRGB(80, 60, 180)
	else
		avatarColor = Color3.fromRGB(0, 130, 220)
	end
	avatar.BackgroundColor3 = avatarColor

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar

	if isUser then
		avatar.Position = UDim2.new(1, -28, 0, 0)
	else
		avatar.Position = UDim2.new(0, 0, 0, 0)
	end

	local bubble = Instance.new("Frame")
	bubble.Name = "Bubble"
	bubble.BorderSizePixel = 0
	bubble.Size = UDim2.new(0, BUBBLE_WIDTH, 0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y

	if isUser then
		bubble.BackgroundColor3 = Color3.fromRGB(0, 100, 190)
		bubble.Position = UDim2.new(1, -36, 0, 0)
		bubble.AnchorPoint = Vector2.new(1, 0)
	else
		bubble.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		bubble.Position = UDim2.new(0, 36, 0, 0)
	end
	bubble.Parent = row

	local bubbleCorner = Instance.new("UICorner")
	bubbleCorner.CornerRadius = UDim.new(0, 10)
	bubbleCorner.Parent = bubble

	if isUser then
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(230, 230, 240)
		label.TextSize = 14
		label.Font = Enum.Font.Gotham
		label.TextWrapped = true
		label.RichText = true
		label.Size = UDim2.new(1, -24, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Parent = bubble

		local bubblePad = Instance.new("UIPadding")
		bubblePad.PaddingLeft = UDim.new(0, 12)
		bubblePad.PaddingRight = UDim.new(0, 12)
		bubblePad.PaddingTop = UDim.new(0, 8)
		bubblePad.PaddingBottom = UDim.new(0, 8)
		bubblePad.Parent = bubble
	else
		local segments = parseCodeBlocks(text)
		local content = Instance.new("Frame")
		content.Name = "Content"
		content.BackgroundTransparency = 1
		content.Size = UDim2.new(1, 0, 0, 0)
		content.AutomaticSize = Enum.AutomaticSize.Y
		content.Parent = bubble

		local contentLayout = Instance.new("UIListLayout")
		contentLayout.Padding = UDim.new(0, 6)
		contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
		contentLayout.Parent = content

		local contentPad = Instance.new("UIPadding")
		contentPad.PaddingLeft = UDim.new(0, 12)
		contentPad.PaddingRight = UDim.new(0, 12)
		contentPad.PaddingTop = UDim.new(0, 8)
		contentPad.PaddingBottom = UDim.new(0, 8)
		contentPad.Parent = content

		for _, seg in ipairs(segments) do
			if seg.type == "text" then
				createTextSegment(content, seg.content)
			elseif seg.type == "code" then
				createCodeSegment(content, seg.language, seg.content)
			end
		end
	end

	return row
end

local function addMessage(text, isUser)
	local row = createMessageBubble(text, isUser)
	row.Parent = chatList
	task.wait()
	scrollToBottom()
end

local function callAPI(messages)
	local data = HttpService:JSONEncode({
		model = CONFIG.Model,
		messages = messages,
		max_tokens = CONFIG.MaxTokens,
		temperature = CONFIG.Temperature,
	})

	local headers = {
		["Authorization"] = "Bearer " .. CONFIG.ApiKey,
		["Content-Type"] = "application/json",
	}

	local ok, body = httpPost(CONFIG.ApiUrl, data, headers)
	if not ok then
		return nil, "HTTP request failed: " .. tostring(body):sub(1, 300)
	end

	local success, parsed = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not success then
		return nil, "API returned non-JSON: " .. (body or "nil"):sub(1, 300)
	end

	local content
	local parseOk = pcall(function()
		content = parsed.choices[1].message.content
	end)

	if not parseOk or not content then
		local reason = "(unknown)"
		pcall(function() reason = parsed.choices[1].finish_reason end)
		return nil, "API returned empty response (reason: " .. tostring(reason) .. ")"
	end

	return content, nil
end

local function queryAI(userMessage)
	if CONFIG.ApiKey == "" then
		hideThinking()
		addMessage("(!) API key not set.", false)
		return
	end

	local messages = {
		{ role = "system", content = CONFIG.SystemPrompt },
	}

	local startIdx = math.max(1, #conversationHistory - 19)
	for i = startIdx, #conversationHistory do
		table.insert(messages, conversationHistory[i])
	end

	table.insert(messages, { role = "user", content = userMessage })
	table.insert(conversationHistory, { role = "user", content = userMessage })

	local finalContent = nil
	local execSteps = 0
	local anyExecuted = false

	while execSteps < CONFIG.MaxExecSteps do
		local content, err = callAPI(messages)

		if not content then
			hideThinking()
			addMessage("(!) " .. err, false)
			return
		end

		local execCode = extractExecBlock(content)

		if not execCode then
			finalContent = content
			break
		end

		execSteps = execSteps + 1
		anyExecuted = true

		addMessage("```exec\n" .. execCode .. "\n```", false)

		local result = executeLua(execCode)
		local resultMsg = "[Execution result for your ```exec block:\n" .. result .. "\n]"
		table.insert(messages, { role = "assistant", content = content })
		table.insert(messages, { role = "user", content = resultMsg })
	end

	if not finalContent then
		finalContent = "(!) Reached maximum execution steps (" .. CONFIG.MaxExecSteps .. "). Please refine your request."
	end

	hideThinking()
	if anyExecuted then
		addMessage(finalContent .. "\n\n executed", false)
	else
		addMessage(finalContent, false)
	end
	table.insert(conversationHistory, { role = "assistant", content = finalContent })
end

local sending = false
local function sendMessage()
	local text = trim(textBox.Text)
	if text == "" or sending then return end
	sending = true

	textBox.Text = ""
	textBox.PlaceholderText = "waiting for response..."
	addMessage(text, true)
	showThinking()

	task.spawn(function()
		queryAI(text)
		textBox.PlaceholderText = "Message AI Agent..."
		sending = false
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		main:TweenSize(UDim2.new(0, 480, 0, 44), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
	else
		main:TweenSize(UDim2.new(0, 480, 0, 600), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
	end
	chatContainer.Visible = not minimized
	inputContainer.Visible = not minimized
end)

sendBtn.MouseButton1Click:Connect(sendMessage)

textBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then sendMessage() end
end)

local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

addMessage("Lets Begin", false)

