-- ==========================================
-- DEBUG MODE (ROBLOX STUDIO COMPATIBILITY)
-- ==========================================
if not isfile then
	_G.DebugFileSystem = _G.DebugFileSystem or {}

	function isfile(path)
		return _G.DebugFileSystem[path] ~= nil
	end

	function readfile(path)
		local data = _G.DebugFileSystem[path]
		if not data then warn("[Debug Mode] File not found (simulated): " .. path) end
		return data or ""
	end

	function writefile(path, content)
		_G.DebugFileSystem[path] = content
		print("[Debug Mode] Saved to memory: " .. path)
	end
end

local NextHub = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- NEXTHUB UI: STYLE & VISUALS
-- ==========================================
local Style = {
	DarkBg = Color3.fromRGB(20,20,20),
	SidebarBg = Color3.fromRGB(20,20,20),
	InputBg = Color3.fromRGB(30,30,30),
	InputStroke = Color3.fromRGB(150,150,150),
	Primary = Color3.fromRGB(100, 180, 255),
	Text = Color3.fromRGB(255,255,255),
	TextDim = Color3.fromRGB(140,140,140),
	HeaderBadge = Color3.fromRGB(100, 180, 255),
	VersionBadge = Color3.fromRGB(255, 232, 25),
	ToggleOff = Color3.fromRGB(70,70,70),
	FontBase = "rbxasset://fonts/families/Montserrat.json",

	ElementBackground = Color3.fromRGB(30,30,30),
	Outline = Color3.fromRGB(60,60,70),
	Hover = Color3.fromRGB(40, 45, 60)
}

local function GetFont(weight)
	weight = weight or Enum.FontWeight.Regular
	return Font.new(Style.FontBase, weight)
end

-- ==========================================
-- NEXTHUB UI: ICON FETCHER
-- ==========================================
local IconCache = {}
local RawPacks = {
	lucide = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
	solar  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua",
	craft  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
	geist  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
}

local function Fetch(url) return game:HttpGet(url) end

local function InitIcons()
	if next(IconCache) then return end
	if isfile and isfile("nexthub_icons.json") then
		local suc, data = pcall(function() return HttpService:JSONDecode(readfile("nexthub_icons.json")) end)
		if suc then IconCache = data end
	end
	if next(IconCache) then return end 

	for name, url in pairs(RawPacks) do
		local ok, data = pcall(function() return loadstring(Fetch(url))() end)
		if ok and type(data) == "table" then
			for k, v in pairs(data) do
				if type(v) == "table" and v.Image then IconCache[k] = v.Image end
			end
		end
	end
	if writefile then 
		pcall(function() 
			writefile("nexthub_icons.json", HttpService:JSONEncode(IconCache)) 
		end) 
	end
end

local function GetIcon(name)
	if type(name) ~= "string" then return "" end
	InitIcons()
	local clean = name:match(":(.+)") or name
	return IconCache[clean] or ""
end

-- ==========================================
-- NEXTHUB UI: LOGIC & UTILITIES
-- ==========================================
local Connections = {}

local function MakeDraggable(topbarobject, object)
	local Dragging = nil
	local DragInput = nil
	local DragStart = nil
	local StartPosition = nil

	local function Update(input)
		local Delta = input.Position - DragStart
		local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
		local Tween = TweenService:Create(object, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos})
		Tween:Play()
	end

	table.insert(Connections, topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = input.Position
			StartPosition = object.Position
			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
					if connection then connection:Disconnect() end
				end
			end)
		end
	end))

	table.insert(Connections, topbarobject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			DragInput = input
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			Update(input)
		end
	end))
end

local function Create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		instance[k] = v
	end
	return instance
end

-- NextHub UI Config System
local ConfigData = {}
local function loadConfig()
	if isfile and readfile then
		local success, data = pcall(function()
			return HttpService:JSONDecode(readfile("NextHubConfig.json"))
		end)
		if success then
			ConfigData = data
		end
	end
end
local function saveConfig()
	if writefile then
		pcall(function()
			writefile("NextHubConfig.json", HttpService:JSONEncode(ConfigData))
		end)
	end
end
loadConfig()

-- ==========================================
-- NEXTHUB UI: MAIN WINDOW
-- ==========================================
function NextHub:CreateWindow(props)
	props = props or {}
	local title = props.Title or "NextHub"
	local logo = props.Logo or "rbxassetid://111607497408853"
	local version = props.Version or "1.0.0"
	local game = props.Game or "Unknown"

	local function GetParent()
		local Success, Parent = pcall(function()
			return (gethui and gethui()) or game:GetService("CoreGui")
		end)
		if not Success or not Parent then
			return LocalPlayer:WaitForChild("PlayerGui")
		end
		return Parent
	end

	local ScreenGui = Create("ScreenGui", {
		Name = "NextHubUI",
		Parent = GetParent(),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false
	})

	local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local InitialSize = IsMobile and UDim2.new(0, 500, 0, 320) or UDim2.new(0, 700, 0, 450)
	local InitialPosition = IsMobile and UDim2.new(0.5, -250, 0.5, -160) or UDim2.new(0.5, -350, 0.5, -225)

	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		BackgroundColor3 = Style.DarkBg,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Position = InitialPosition,
		Size = InitialSize,
		ClipsDescendants = false
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
	Create("UIStroke", { Color = Style.Primary, Thickness = 1.7, Transparency = 0.2, Parent = MainFrame })

	local header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = MainFrame
	})
	MakeDraggable(header, MainFrame)

	local headerLogo = Create("ImageLabel", {
		Image = logo,
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.fromOffset(6, 1.5),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Parent = header
	})

	local headerTitle = Create("TextLabel", {
		Text = title,
		Size = UDim2.new(1, -20, 0, 44),
		Position = UDim2.fromOffset(54, 0),
		BackgroundTransparency = 1,
		FontFace = GetFont(Enum.FontWeight.Bold),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Style.Text,
		Parent = header
	})

	local typeBadge = Create("TextLabel", {
		Size = UDim2.new(0, 56, 0, 21),
		Position = UDim2.new(0, 54 + headerTitle.TextBounds.X + 15, 0, 12),
		BackgroundColor3 = Style.HeaderBadge,
		TextColor3 = Style.Text,
		Text = "BETA",
		FontFace = GetFont(Enum.FontWeight.SemiBold),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = header
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = typeBadge})

	local versionBadge = Create("TextLabel", {
		Text = version,
		Size = UDim2.new(0, 62, 0, 21),
		Position = UDim2.new(0, 54 + headerTitle.TextBounds.X + 80, 0, 12),
		BackgroundColor3 = Style.VersionBadge,
		TextColor3 = Style.Text,
		FontFace = GetFont(Enum.FontWeight.SemiBold),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = header
	})
	Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = versionBadge})

	local closeBtn = Create("ImageButton", {
		Size = UDim2.fromOffset(21, 21),
		Position = UDim2.new(1, -36, 0, 12),
		BackgroundTransparency = 1,
		Image = GetIcon("x"),
		ImageColor3 = Color3.fromRGB(190,220,255),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 10,
		Parent = header
	})
	closeBtn.MouseButton1Click:Connect(function()
		TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
		task.wait(0.3)
		ScreenGui:Destroy()
	end)

	local minimizeBtn = Create("ImageButton", {
		Size = UDim2.fromOffset(21, 21),
		Position = UDim2.new(1, -70, 0, 12),
		BackgroundTransparency = 1,
		Image = GetIcon("minus"),
		ImageColor3 = Color3.fromRGB(190,220,255),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 10,
		Parent = header
	})

	local IsMinimized = false
	local toggleBtn = Create("ImageButton", {
		Name = "ToggleUI",
		Parent = ScreenGui,
		BackgroundColor3 = Style.DarkBg,
		BorderSizePixel = 0,
		Position = UDim2.new(0.1, 0, 0.1, 0),
		Size = UDim2.new(0, 47, 0, 47),
		Image = "rbxassetid://111607497408853",
		ImageColor3 = Style.Text,
		Visible = true, 
		Active = true,
		Draggable = true,
		ZIndex = 100
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = toggleBtn })
	Create("UIStroke", { Color = Style.InputStroke, Thickness = 1, Parent = toggleBtn })

	local function ToggleUI()
		IsMinimized = not IsMinimized
		if IsMinimized then
			MainFrame.Visible = false
			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Size = UDim2.new(0,0,0,0), 
				BackgroundTransparency = 1
			}):Play()
		else
			MainFrame.Visible = true
			MainFrame.Size = UDim2.new(0, 0, 0, 0)
			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = InitialSize,
				BackgroundTransparency = 0.1
			}):Play()
		end
	end
	toggleBtn.MouseButton1Click:Connect(ToggleUI)
	minimizeBtn.MouseButton1Click:Connect(ToggleUI)

	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Parent = MainFrame,
		BackgroundColor3 = Style.SidebarBg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 30),
		Size = UDim2.new(0, 180, 1, -30)
	})

	local TabContainer = Create("ScrollingFrame", {
		Name = "TabContainer",
		Parent = Sidebar,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 15),
		Size = UDim2.new(1, 0, 1, -25),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Style.Primary
	})

	local ButtonsHolder = Create("Frame", {
		Name = "ButtonsHolder",
		Parent = TabContainer,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	})

	Create("UIListLayout", {
		Parent = ButtonsHolder,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5)
	})

	Create("UIPadding", {
		Parent = ButtonsHolder,
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7)
	})

	local SlidingIndicator = Create("Frame", {
		Name = "SlidingIndicator",
		Parent = TabContainer,
		BackgroundColor3 = Style.Primary,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 4, 0, 26),
		Visible = false,
		ZIndex = 2
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SlidingIndicator })

	local ContentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = MainFrame,
		BackgroundTransparency = 0.7,
		BackgroundColor3 = Style.InputStroke,
		Position = UDim2.new(0, 180, 0, 44),
		Size = UDim2.new(1, -180, 1, -44),
		ClipsDescendants = true
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ContentContainer })

	local gameName = Create("TextLabel", {
		Name = "TabBtn_" .. game,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Color3.fromRGB(50,50,50),
		TextColor3 = Style.Primary,
		Text = "Game: " .. game,
		TextSize = 12,
		FontFace = GetFont(Enum.FontWeight.Bold),
		BackgroundTransparency = 0.2,
		Parent = ButtonsHolder
	})
	Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = gameName})

	local Window = {
		Tabs = {},
		TabButtons = {},
		TabContents = {},
		Elements = {},
		__tabChanged = Instance.new("BindableEvent")
	}

	local NotificationHolder = Create("Frame", {
		Name = "NotificationHolder",
		Parent = ScreenGui,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, 300, 1, -20),
		AnchorPoint = Vector2.new(1, 1),
		ZIndex = 100
	})
	Create("UIListLayout", {
		Parent = NotificationHolder,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 10)
	})

	function Window:Notify(options)
		options = options or {}

		local Title = options.Title or "Notification"
		local Content = options.Content or "Message"
		local Duration = options.Duration or 3

		local NotifyFrame = Create("Frame", {
			Name = "NotifyFrame",
			Parent = NotificationHolder,
			BackgroundColor3 = Style.DarkBg,
			BackgroundTransparency = 0.1,
			Size = UDim2.new(1, 0, 0, 60),
			ClipsDescendants = true
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = NotifyFrame })
		Create("UIStroke", { Color = Style.Primary, Transparency = 0.5, Thickness = 1, Parent = NotifyFrame })

		local Icon = Create("ImageLabel", {
			Parent = NotifyFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 12),
			Size = UDim2.new(0, 36, 0, 36),
			Image = GetIcon("bell"),
			ImageColor3 = Style.Primary
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Icon })

		Create("TextLabel", {
			Parent = NotifyFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 58, 0, 10),
			Size = UDim2.new(1, -68, 0, 20),
			FontFace = GetFont(Enum.FontWeight.Bold),
			Text = Title,
			TextColor3 = Style.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		Create("TextLabel", {
			Parent = NotifyFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 58, 0, 30),
			Size = UDim2.new(1, -68, 0, 20),
			FontFace = GetFont(Enum.FontWeight.Regular),
			Text = Content,
			TextColor3 = Style.TextDim,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true
		})

		NotifyFrame.Position = UDim2.new(1, 320, 0, 0)
		TweenService:Create(NotifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

		local ProgressBar = Create("Frame", {
			Parent = NotifyFrame,
			BackgroundColor3 = Style.Primary,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, -2),
			Size = UDim2.new(1, 0, 0, 2)
		})
		TweenService:Create(ProgressBar, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

		task.delay(Duration, function()
			TweenService:Create(NotifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 320, 0, 0)}):Play()
			task.wait(0.5)
			NotifyFrame:Destroy()
		end)
	end

	function Window:LoadConfig(name)
		for key, data in pairs(Window.Elements) do
			if ConfigData[key] ~= nil then
				pcall(function()
					data.Object:Set(ConfigData[key])
				end)
			end
		end
		self:Notify({Title="Config", Content="Loaded Successfully"})
	end

	local function MoveIndicatorToButton(btn)
		if not SlidingIndicator.Visible then
			SlidingIndicator.Visible = true
		end

		local btnAbsPos = btn.AbsolutePosition
		local containerAbsPos = TabContainer.AbsolutePosition

		local targetX = btnAbsPos.X - containerAbsPos.X + 6

		local targetY = btnAbsPos.Y - containerAbsPos.Y + 6

		TweenService:Create(SlidingIndicator, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(targetX, targetY)
		}):Play()
	end

	-- ==========================================
	-- TAB COMPONENT
	-- ==========================================
	function Window:AddTab(tabProps)
		local Components = {}
		local ElementIndex = 0
		local CurrentGroup
		local LastElementType = nil

		tabProps = tabProps or {}

		local tabTitle = tabProps.Title or "Tab"
		local tabIcon = tabProps.Icon
		local index = #self.Tabs + 1

		self.Tabs[index] = tabProps

		local BG_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		local btn = Create("ImageButton", {
			Name = "TabBtn_" .. index,
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = (index == 1) and Style.Primary or Color3.fromRGB(50,50,50),
			BackgroundTransparency = (index == 1) and 0.75 or 1,
			AutoButtonColor = false,
			Parent = ButtonsHolder
		})
		self.TabButtons[index] = btn

		Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = btn})

		if tabIcon then
			local id = GetIcon(tabIcon)
			Create("ImageLabel", {
				Size = UDim2.fromOffset(20,20),
				Position = UDim2.new(0,32,0.5,-10),
				BackgroundTransparency = 1,
				Image = id or "",
				Parent = btn
			})
		end

		local label = Create("TextLabel", {
			Text = tabTitle,
			Size = UDim2.new(1, -50, 1, 0),
			Position = UDim2.new(0,64,0,0),
			BackgroundTransparency = 1,
			TextColor3 = Style.Text,
			FontFace = GetFont(Enum.FontWeight.Medium),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn
		})

		local content = Create("ScrollingFrame", {
			Name = "TabContent_" .. index,
			Size = UDim2.new(1,0,1,0),
			CanvasSize = UDim2.new(0,0,0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 1.7,
			ScrollBarImageColor3 = Style.Primary,
			BackgroundTransparency = 1,
			Visible = (index == 1),
			Parent = ContentContainer
		})
		self.TabContents[index] = content

		Create("UIListLayout", { 
			Parent = content,
			SortOrder = Enum.SortOrder.LayoutOrder
		})
		Create("UIPadding", {
			PaddingTop = UDim.new(0,12),
			PaddingLeft = UDim.new(0,12),
			PaddingRight = UDim.new(0,12),
			PaddingBottom = UDim.new(0,12),
			Parent = content
		})

		local function AddDivider()
			if not CurrentGroup then return end

			local Divider = Create("Frame", {
				Parent = CurrentGroup,
				BackgroundColor3 = Style.Outline,
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1.5),
				LayoutOrder = ElementIndex
			})

			Create("UIPadding", {
				Parent = Divider,
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12)
			})
		end

		local function ActivateTab()
			Window.__tabChanged:Fire()

			for i, c in ipairs(self.TabContents) do
				local active = (i == index)
				local b = self.TabButtons[i]
				c.Visible = active

				TweenService:Create(b, BG_TWEEN, {
					BackgroundTransparency = active and 0.75 or 1,
					BackgroundColor3 = active and Style.Primary or Color3.fromRGB(50,50,50)
				}):Play()
			end

			MoveIndicatorToButton(btn)
		end

		btn.MouseButton1Click:Connect(function()
			ActivateTab()
		end)

		if index == 1 then
			task.wait()
			ActivateTab()
		end

		-- ==========================================
		-- SECTION COMPONENT
		-- ==========================================
		function Components:AddSection(props)
			props = props or {}

			local SectionTitle = props.Title or "Section"
			local Icon = props.Icon

			ElementIndex = ElementIndex + 1

			local SectionContainer = Create("Frame", {
				Parent = content,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = ElementIndex
			})

			local CurrentX = 0
			if Icon then
				Create("ImageLabel", {
					Parent = SectionContainer,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0.5, -9),
					Size = UDim2.new(0, 18, 0, 18),
					Image = GetIcon(Icon),
					ImageColor3 = Style.Primary
				})
				CurrentX = 24
			end

			CurrentGroup = Create("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1,0,0,0),
				BackgroundTransparency = 0.5,
				BackgroundColor3 = Style.ElementBackground,
				Parent = content,
				LayoutOrder = ElementIndex
			})
			Create("UIListLayout", {
				Parent = CurrentGroup,
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
			Create("UICorner", {
				Parent = CurrentGroup,
				CornerRadius = UDim.new(0,5)
			})

			local Label = Create("TextLabel", {
				Name = "SectionLabel",
				Parent = SectionContainer,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, CurrentX, 0, 0),
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				FontFace = GetFont(Enum.FontWeight.Bold),
				Text = SectionTitle,
				TextColor3 = Style.Primary,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			task.delay(0.05, function()
				local TextWidth = Label.TextBounds.X
				local LineX = CurrentX + TextWidth + 10
				local Separator = Create("Frame", {
					Parent = SectionContainer,
					BackgroundColor3 = Style.Primary,
					BorderSizePixel = 0,
					Position = UDim2.new(0, LineX, 0.5, 0),
					Size = UDim2.new(1, -LineX, 0.05, 1)
				})
				Create("UICorner", {CornerRadius = UDim.new(0.8, 0), Parent = Separator})
			end)

			LastElementType = "Section"

			local SectionObject = { Frame = SectionContainer }
			return SectionObject
		end

		-- ==========================================
		-- PARAGRAPH COMPONENT
		-- ==========================================
		function Components:AddParagraph(props)
			props = props or {}

			local ParagraphTitle = props.Title or ""
			local ParagraphText = props.Text or "Paragraph text goes here..."
			local ParagraphColor = props.Color or Style.Text

			if LastElementType == "Component" then
				AddDivider()
			end

			ElementIndex = ElementIndex + 1

			local ParagraphFrame = Create("Frame", {
				Name = "ParagraphFrame",
				Parent = CurrentGroup,
				BackgroundColor3 = Style.ElementBackground,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = ElementIndex
			})

			local Padding = Create("UIPadding", {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = ParagraphFrame
			})

			local TitleLabel = nil
			if ParagraphTitle ~= "" then
				TitleLabel = Create("TextLabel", {
					Parent = ParagraphFrame,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					FontFace = GetFont(Enum.FontWeight.SemiBold),
					Text = ParagraphTitle,
					TextColor3 = Style.Primary,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top
				})
			end

			local TextLabel = Create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				TextWrapped = true,
				RichText = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = ParagraphColor,
				FontFace = GetFont(Enum.FontWeight.Medium),
				TextSize = props.TextSize or 14,
				Text = ParagraphText,
				Parent = ParagraphFrame
			})

			if TitleLabel then
				local Layout = Create("UIListLayout", {
					Parent = ParagraphFrame,
					Padding = UDim.new(0, 5),
					SortOrder = Enum.SortOrder.LayoutOrder
				})
				TitleLabel.LayoutOrder = 1
				TextLabel.LayoutOrder = 2
				Padding:Destroy()
				Create("UIPadding", {
					PaddingTop = UDim.new(0, 10),
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
					Parent = ParagraphFrame
				})
			end
			
			LastElementType = "Component"

			local ParagraphObject = { Frame = ParagraphFrame }
			function ParagraphObject:SetText(t) TextLabel.Text = t end
			return ParagraphObject
		end

		-- ==========================================
		-- BUTTON COMPONENT
		-- ==========================================
		function Components:AddButton(props)
			props = props or {}

			local ButtonTitle = props.Title or "Button"
			local ButtonIcon = props.Icon
			local Callback = props.Callback or function() end

			if LastElementType == "Component" then
				AddDivider()
			end

			ElementIndex = ElementIndex + 1

			local ButtonFrame = Create("Frame", {
				Name = "ButtonFrame",
				Parent = CurrentGroup,
				BackgroundColor3 = Style.ElementBackground,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 38),
				LayoutOrder = ElementIndex
			})

			if ButtonIcon then
				local IconImg = Create("ImageLabel", {
					BackgroundTransparency = 1,
					Image = GetIcon(ButtonIcon),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 12, 0.5, 0),
					ImageColor3 = Style.Primary,
					Size = UDim2.fromOffset(20, 20),
					ScaleType = Enum.ScaleType.Fit,
					Parent = ButtonFrame
				})
			end

			local TextLabel = Create("TextLabel", {
				Text = ButtonTitle,
				Size = UDim2.new(1, -48, 1, 0),
				Position = UDim2.new(0, 44, 0, 0),
				BackgroundTransparency = 1,
				FontFace = GetFont(Enum.FontWeight.SemiBold),
				TextSize = 14,
				TextColor3 = Style.Primary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				Parent = ButtonFrame
			})

			if not ButtonIcon then
				TextLabel.Position = UDim2.new(0, 12, 0, 0)
				TextLabel.Size = UDim2.new(1, -24, 1, 0)
			end

			local ClickBtn = Create("TextButton", {
				Parent = ButtonFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				ZIndex = 10
			})

			ClickBtn.MouseButton1Click:Connect(function()
				task.spawn(function()
					local mouse = LocalPlayer:GetMouse()
					local Ripple = Create("Frame", {
						Parent = ButtonFrame,
						BackgroundColor3 = Style.Primary,
						BackgroundTransparency = 0.8,
						BorderSizePixel = 0,
						Position = UDim2.new(0, mouse.X - ButtonFrame.AbsolutePosition.X, 0, mouse.Y - ButtonFrame.AbsolutePosition.Y),
						Size = UDim2.new(0, 0, 0, 0),
						ZIndex = 5
					})
					Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Ripple })
					local Tween = TweenService:Create(Ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 200, 0, 200),
						Position = UDim2.new(0, mouse.X - ButtonFrame.AbsolutePosition.X - 100, 0, mouse.Y - ButtonFrame.AbsolutePosition.Y - 100),
						BackgroundTransparency = 1
					})
					Tween:Play()
					Tween.Completed:Wait()
					Ripple:Destroy()
				end)

				Callback()
			end)

			LastElementType = "Component"

			local ButtonObject = { Frame = ButtonFrame }
			function ButtonObject:SetText(t) TextLabel.Text = t end
			return ButtonObject
		end

		-- ==========================================
		-- INPUT COMPONENT
		-- ==========================================
		function Components:AddInput(props)
			props = props or {}

			local InputTitle = props.Title or "Input"
			local InputPlaceholder = props.Placeholder or "Value.."
			local InputDefault = props.Default or ""
			local Callback = props.Callback or function() end
			local ConfigKey = props.ConfigKey or InputTitle

			if ConfigData[ConfigKey] ~= nil then InputDefault = ConfigData[ConfigKey] end
			local InputValue = InputDefault

			if LastElementType == "Component" then
				AddDivider()
			end

			ElementIndex = ElementIndex + 1

			local InputFrame = Create("Frame", {
				Name = "InputFrame",
				Parent = CurrentGroup,
				BackgroundColor3 = Style.ElementBackground,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 38),
				LayoutOrder = ElementIndex
			})

			local Label = Create("TextLabel", {
				Parent = InputFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(0.5, -12, 1, 0),
				FontFace = GetFont(Enum.FontWeight.SemiBold),
				Text = InputTitle,
				TextColor3 = Style.Primary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center
			})

			local boxFrame = Create("Frame", {
				Size = UDim2.new(0.5, -20, 1, -16),
				Position = UDim2.new(0.5, 12, 0, 8),
				BackgroundColor3 = Style.InputBg,
				BackgroundTransparency = 0.50,
				Parent = InputFrame
			})
			Create("UICorner", {CornerRadius = UDim.new(0,5), Parent = boxFrame})
			Create("UIStroke", {Color = Style.InputStroke, Transparency = 0.15, Thickness = 1.4, Parent = boxFrame})

			local box = Create("TextBox", {
				Position = UDim2.new(0,8,0,0),
				Size = UDim2.new(1,-16,1,0),
				BackgroundTransparency = 1,
				PlaceholderText = InputPlaceholder,
				Text = InputValue,
				ClearTextOnFocus = false,
				FontFace = GetFont(Enum.FontWeight.Medium),
				TextSize = 14,
				TextColor3 = Style.Text,
				PlaceholderColor3 = Style.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = boxFrame
			})

			local function setValue(v, silent)
				v = tostring(v or "")
				box.Text = v
				if not silent and typeof(Callback) == "function" then Callback(v) end
			end

			box.FocusLost:Connect(function()
				ConfigData[ConfigKey] = box.Text
				setValue(box.Text)
			end)

			LastElementType = "Component"

			local InputObject = { Frame = InputFrame }
			function InputObject:SetValue(v) setValue(v, true) end
			function InputObject:GetValue() return box.Text end

			if ConfigKey then Window.Elements[ConfigKey] = { Object = InputObject, Type = "Input" } end
			return InputObject
		end

		-- ==========================================
		-- TOGGLE COMPONENT
		-- ==========================================
		function Components:AddToggle(props)
			props = props or {}

			local ToggleTitle = props.Title or "Toggle"
			local ToggleDefault = props.Default or false
			local Callback = props.Callback or function() end
			local ConfigKey = props.ConfigKey or ToggleTitle

			if ConfigData[ConfigKey] ~= nil then ToggleDefault = ConfigData[ConfigKey] end
			local Toggled = ToggleDefault

			if LastElementType == "Component" then
				AddDivider()
			end

			ElementIndex = ElementIndex + 1

			local ToggleFrame = Create("Frame", {
				Name = "ToggleFrame",
				Parent = CurrentGroup,
				BackgroundColor3 = Style.ElementBackground,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 38),
				LayoutOrder = ElementIndex
			})

			local Label = Create("TextLabel", {
				Parent = ToggleFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -60, 1, 0),
				FontFace = GetFont(Enum.FontWeight.SemiBold),
				Text = ToggleTitle,
				TextColor3 = Style.Primary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center
			})

			local SwitchBg = Create("Frame", {
				Parent = ToggleFrame,
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Toggled and Style.Primary or Style.ToggleOff,
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.new(0, 40, 0, 20)
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBg })

			local SwitchCircle = Create("Frame", {
				Parent = SwitchBg,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Style.Text,
				Position = UDim2.new(0, Toggled and 22 or 2, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16)
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchCircle })

			local Button = Create("TextButton", {
				Parent = ToggleFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = ""
			})

			LastElementType = "Component"

			local ToggleObject = { Value = ToggleDefault }

			local function UpdateToggleState(newValue)
				Toggled = newValue
				ToggleObject.Value = Toggled

				local TweenInfoData = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

				TweenService:Create(SwitchBg, TweenInfoData, {
					BackgroundColor3 = Toggled and Style.Primary or Style.ToggleOff
				}):Play()

				TweenService:Create(SwitchCircle, TweenInfoData, {
					Position = UDim2.new(0, Toggled and 22 or 2, 0.5, 0)
				}):Play()

				ConfigData[ConfigKey] = Toggled
				Callback(Toggled)
			end

			Button.MouseButton1Click:Connect(function()
				UpdateToggleState(not Toggled)
			end)

			function ToggleObject:SetValue(newValue)
				if type(newValue) ~= "boolean" then newValue = newValue == true end
				UpdateToggleState(newValue)
			end

			if ConfigKey then Window.Elements[ConfigKey] = { Object = ToggleObject, Type = "Toggle" } end
			return ToggleObject
		end

		-- ==========================================
		-- DROPDOWN COMPONENT
		-- ==========================================
		function Components:AddDropdown(props, section)
			props = props or {}

			local DropdownName = props.Name or "Dropdown"
			local Items = props.Options or {}
			local Default = props.Default or Items[1]
			local Callback = props.Callback or function() end
			local ConfigKey = props.ConfigKey or DropdownName
			local IsMulti = props.Multi or false
			local SingleSelected = Default
			local Selected = {}

			if IsMulti then
				Selected = type(ConfigData[ConfigKey]) == "table" and ConfigData[ConfigKey] or {}
			else
				if type(ConfigData[ConfigKey]) == "table" then
					local first = ConfigData[ConfigKey][1]
					if first and table.find(Items, first) then
						Default = first
						SingleSelected = Default
					end
				end
			end


			if LastElementType == "Component" then
				AddDivider()
			end

			ElementIndex  = ElementIndex + 1

			local DropdownFrame = Create("Frame", {
				Name = "DropdownFrame",
				Parent = CurrentGroup,
				BackgroundColor3 = Style.ElementBackground,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 38),
				ClipsDescendants = true,
				ZIndex = 2,
				LayoutOrder = ElementIndex
			})

			local Label = Create("TextLabel", {
				Parent = DropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -40, 0, 38),
				FontFace = GetFont(Enum.FontWeight.SemiBold),
				Text = DropdownName,
				TextColor3 = Style.Primary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2
			})

			local CurrentValue = Create("TextLabel", {
				Parent = DropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, -35, 0, 38),
				FontFace = GetFont(Enum.FontWeight.Regular),
				Text = IsMulti and "Select..." or (Default or "Select..."),
				TextColor3 = Style.TextDim,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 2
			})

			local Arrow = Create("ImageLabel", {
				Parent = DropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -28, 0, 9),
				Size = UDim2.new(0, 20, 0, 20),
				Image = GetIcon("chevron-down"),
				ImageColor3 = Style.TextDim,
				ZIndex = 2
			})

			local Button = Create("TextButton", {
				Parent = DropdownFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 38),
				Text = "",
				ZIndex = 3
			})

			local SearchBar = Create("TextBox", {
				Parent = DropdownFrame,
				BackgroundColor3 = Style.InputBg,
				BackgroundTransparency = 0.5,
				Position = UDim2.new(0, 6, 0, 42),
				Size = UDim2.new(1, -12, 0, 26),
				FontFace = GetFont(),
				PlaceholderText = "Search...",
				Text = "",
				TextColor3 = Style.Text,
				PlaceholderColor3 = Style.TextDim,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3,
				Visible = false
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = SearchBar })
			Create("UIPadding", { Parent = SearchBar, PaddingLeft = UDim.new(0, 8) })

			local DropdownContainer = Create("ScrollingFrame", {
				Parent = DropdownFrame,
				Active = true,
				BackgroundColor3 = Style.InputBg,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 6, 0, 74),
				Size = UDim2.new(1, -12, 0, 0),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Style.Primary,
				ZIndex = 3
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = DropdownContainer })

			local ListLayout = Create("UIListLayout", {
				Parent = DropdownContainer,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4)
			})
			Create("UIPadding", {
				Parent = DropdownContainer,
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4)
			})

			local Open = false
			local ItemButtons = {}

			local function UpdateList(filter)
				filter = filter and filter:lower() or ""
				local contentSize = 0
				for _, btn in pairs(ItemButtons) do
					if btn.Text:lower():find(filter, 1, true) then
						btn.Visible = true
						contentSize = contentSize + 28
					else
						btn.Visible = false
					end
				end
				DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, contentSize + 8)
			end

			local function ToggleDropdown()
				Open = not Open
				SearchBar.Visible = Open
				local TargetHeight = Open and math.min(#Items * 28 + 12, 160) or 0
				local FrameHeight = Open and (TargetHeight + 80) or 38

				TweenService:Create(DropdownFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, FrameHeight)}):Play()
				TweenService:Create(DropdownContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, -12, 0, TargetHeight)}):Play()
				TweenService:Create(Arrow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Rotation = Open and 180 or 0}):Play()

				if Open then SearchBar:CaptureFocus() else SearchBar.Text = "" UpdateList("") end
			end

			Button.MouseButton1Click:Connect(ToggleDropdown)
			SearchBar:GetPropertyChangedSignal("Text"):Connect(function() UpdateList(SearchBar.Text) end)

			local function UpdateItemVisual(btn, item)
				if IsMulti then
					if table.find(Selected, item) then
						btn.BackgroundColor3 = Style.Primary
						btn.TextColor3 = Style.Text
					else
						btn.BackgroundColor3 = Style.DarkBg
						btn.TextColor3 = Style.TextDim
					end
				else
					if SingleSelected == item then
						btn.BackgroundColor3 = Style.Primary
						btn.TextColor3 = Style.Text
					else
						btn.BackgroundColor3 = Style.DarkBg
						btn.TextColor3 = Style.TextDim
					end
				end
			end

			local function UpdateDisplayText()
				if not IsMulti then return end

				if #Selected == 0 then
					CurrentValue.Text = "Select..."
				elseif #Selected == 1 then
					CurrentValue.Text = Selected[1]
				elseif #Selected <= 2 then
					CurrentValue.Text = table.concat(Selected, ", ")
				else
					CurrentValue.Text = Selected[1] .. ", +" .. (#Selected - 1)
				end
			end

			local function RefreshItems(newItems)
				Items = newItems or Items
				for _, btn in pairs(ItemButtons) do btn:Destroy() end
				ItemButtons = {}

				for _, item in pairs(Items) do
					local ItemButton = Create("TextButton", {
						Parent = DropdownContainer,
						BackgroundColor3 = Style.DarkBg,
						BackgroundTransparency = 0.5,
						Size = UDim2.new(1, 0, 0, 24),
						FontFace = GetFont(),
						Text = item,
						TextColor3 = Style.TextDim,
						TextSize = 13,
						ZIndex = 3,
						AutoButtonColor = false,
						ClipsDescendants = true
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ItemButton })

					UpdateItemVisual(ItemButton, item)

					ItemButton.MouseButton1Click:Connect(function()
						if IsMulti then
							if table.find(Selected, item) then
								table.remove(Selected, table.find(Selected, item))
							else
								table.insert(Selected, item)
							end

							for _, btn in pairs(ItemButtons) do
								UpdateItemVisual(btn, btn.Text)
							end

							UpdateDisplayText()
							ConfigData[ConfigKey] = Selected
							Callback(Selected)
						else
							SingleSelected = item
							CurrentValue.Text = item

							ConfigData[ConfigKey] = { item }
							Callback({ item })

							for _, btn in pairs(ItemButtons) do
								UpdateItemVisual(btn, btn.Text)
							end

							ToggleDropdown()
						end
					end)
					table.insert(ItemButtons, ItemButton)
				end
			end

			RefreshItems(Items)
			ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 8)
			end)

			if IsMulti then
				UpdateDisplayText()
			end

			LastElementType = "Component"

			local DropdownObject = { Items = Items, Value = Default }

			function DropdownObject:Refresh(newItems)
				Items = newItems or Items
				self.Items = Items
				RefreshItems(Items)

				if IsMulti then
					UpdateDisplayText()
				else
					if not table.find(Items, CurrentValue.Text) then
						CurrentValue.Text = Items[1] or "none"
					end
				end
			end

			function DropdownObject:Set(value)

				if IsMulti then
					if typeof(value) ~= "table" then return end
					Selected = {}

					for _, v in ipairs(value) do
						if table.find(self.Items, v) then
							table.insert(Selected, v)
						end
					end

					UpdateDisplayText()
					ConfigData[ConfigKey] = Selected
					Callback(Selected)
				else
					if typeof(value) ~= "table" then return end

					Selected = {}

					for _, v in ipairs(value) do
						if table.find(self.Items, v) then
							table.insert(Selected, v)
						end
					end

					SingleSelected = Selected[1]
					CurrentValue.Text = SingleSelected or "Select..."

					ConfigData[ConfigKey] = Selected
					Callback(Selected)
				end

			end

			if ConfigKey then Window.Elements[ConfigKey] = { Object = DropdownObject, Type = "Dropdown" } end
			return DropdownObject
		end

		return Components
	end
	return Window
end

return NextHub