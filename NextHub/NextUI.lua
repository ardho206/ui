local NextUI = {}
NextUI.__index = NextUI

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local function FontMontserrat(weight)
    weight = weight or Enum.FontWeight.Regular
    return Font.new("rbxasset://fonts/families/Montserrat.json", weight)
end

local function Get(url)
    if writefile and game.HttpGet then
        return game:HttpGet(url)
    else
        return HttpService:GetAsync(url)
    end
end

local RAW_PACKS = {
    lucide = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
    solar  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua",
    craft  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
    geist  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
}

local ICON_CACHE_FILE = "nexthub_icons.json"

local IconCache = {}
local IconLoaded = false

local function normalize(val)
    if type(val) == "string" then
        return val
    elseif type(val) == "table" and val.Image then
        return val.Image
    end
end

local function loadLocalCache()
    if isfile and isfile(ICON_CACHE_FILE) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(ICON_CACHE_FILE))
        end)
        if ok and type(decoded) == "table" then
            IconCache = decoded
            return true
        end
    end
end

local function saveLocalCache()
    if writefile then
        writefile(ICON_CACHE_FILE, HttpService:JSONEncode(IconCache))
    end
end

local function BuildIconCache()
    if IconLoaded then return end

    loadLocalCache()

    for _, pack in ipairs({"lucide","solar","craft","geist"}) do
        local ok, data = pcall(function()
            return loadstring(Get(RAW_PACKS[pack]))()
        end)

        if ok and type(data) == "table" then
            for name, val in pairs(data) do
                if not IconCache[name] then
                    IconCache[name] = normalize(val)
                end
            end
        else
            warn("[NextHub] failed load icon pack:", pack)
        end
    end

    saveLocalCache()
    IconLoaded = true
end

local function GetIconID(icon)
    if not IconLoaded then
        BuildIconCache()
    end

    if type(icon) ~= "string" then return nil end
    local name = icon:match(":(.+)") or icon
    return IconCache[name]
end

local function makeDraggable(dragArea, target)
    local dragging, dragInput, dragStart, startPos
    local conn

    local function update(input)
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position

            if conn then conn:Disconnect() end
            conn = UIS.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                    update(i)
                end
            end)

            input.Changed:Once(function()
                dragging = false
                if conn then conn:Disconnect() end
            end)
        end
    end)
end

function NextUI:CreateWindow(props)
    local window = {}

    local title = props.Title or "NextHub"
    local logo = props.Logo or "rbxassetid://111607497408853"
    local version = props.Version or "1.0.0"
    local game = "Game: " .. (props.Game or "Unknown")

    local gui = Instance.new("ScreenGui")
    gui.Name = "NextHubUI"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    window.Gui = gui

    local toggleBtn = Instance.new("ImageButton")
    toggleBtn.Size = UDim2.fromOffset(47, 47)
    toggleBtn.Position = UDim2.fromScale(0.03, 0.5)
    toggleBtn.AnchorPoint = Vector2.new(0, 0.5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    toggleBtn.BackgroundTransparency = 0.05
    toggleBtn.Image = "rbxassetid://111607497408853"
    toggleBtn.ZIndex = 50
    toggleBtn.Parent = gui
    window.ToggleButton = toggleBtn
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 5)
    makeDraggable(toggleBtn, toggleBtn)

    local main = Instance.new("Frame")
    main.Size = props.Size or UDim2.fromOffset(660, 400)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = Color3.fromRGB(20,20,20)
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Parent = gui
    window.Main = main
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(120,170,255)
    stroke.Transparency = 0.2
    stroke.Thickness = 1.7

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundTransparency = 1
    header.Parent = main
    makeDraggable(header, main)

    local logoImg = Instance.new("ImageLabel")
    logoImg.Image = logo
    logoImg.Size = UDim2.fromOffset(42, 42)
    logoImg.Position = UDim2.fromOffset(6, 1.5)
    logoImg.BackgroundTransparency = 1
    logoImg.ScaleType = Enum.ScaleType.Fit
    logoImg.Parent = header

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = title
    textLabel.Size = UDim2.new(1, -20, 0, 44)
    textLabel.Position = UDim2.fromOffset(54, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.FontFace = FontMontserrat(Enum.FontWeight.Bold)
    textLabel.TextSize = 18
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextColor3 = Color3.fromRGB(255,255,255)
    textLabel.Parent = header

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 56, 0, 21)
    badge.Position = UDim2.new(0, 54 + textLabel.TextBounds.X + 15, 0, 12)
    badge.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    badge.TextColor3 = Color3.fromRGB(255,255,255)
    badge.Text = "BETA"
    badge.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
    badge.TextSize = 14
    badge.TextXAlignment = Enum.TextXAlignment.Center
    badge.TextYAlignment = Enum.TextYAlignment.Center
    badge.Parent = header
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)

    local versionBadge = Instance.new("TextLabel")
    versionBadge.Text = version
    versionBadge.Size = UDim2.new(0, 62, 0, 21)
    versionBadge.Position = UDim2.new(0, 54 + textLabel.TextBounds.X + 80, 0, 12)
    versionBadge.BackgroundColor3 = Color3.fromRGB(255, 232, 25)
    versionBadge.TextColor3 = Color3.fromRGB(255,255,255)
    versionBadge.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
    versionBadge.TextSize = 14
    versionBadge.TextXAlignment = Enum.TextXAlignment.Center
    versionBadge.TextYAlignment = Enum.TextYAlignment.Center
    versionBadge.Parent = header
    Instance.new("UICorner", versionBadge).CornerRadius = UDim.new(0, 5)

    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.fromOffset(21, 21)
    closeBtn.Position = UDim2.new(1, -38, 0, 12)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = "rbxassetid://104399607275683"
    closeBtn.ImageColor3 = Color3.fromRGB(190,220,255)
    closeBtn.ScaleType = Enum.ScaleType.Fit
    closeBtn.ZIndex = 10
    closeBtn.Parent = header

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    local minimize = Instance.new("ImageButton")
    minimize.Size = UDim2.fromOffset(21, 21)
    minimize.Position = UDim2.new(1, -74, 0, 12)
    minimize.BackgroundTransparency = 1
    minimize.Image = "rbxassetid://95987902344341"
    minimize.ImageColor3 = Color3.fromRGB(190,220,255)
    minimize.ScaleType = Enum.ScaleType.Fit
    minimize.ZIndex = 10
    minimize.Parent = header

    local normalSize = main.Size
    local scaleDown = UDim2.fromOffset(
        normalSize.X.Offset * 0.9,
        normalSize.Y.Offset * 0.9
    )

    local opened = true
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function toggleWindow()
        opened = not opened

        if opened then
            main.Visible = true
            TweenService:Create(main, tweenInfo, {
                Size = normalSize,
                BackgroundTransparency = 0.1
            }):Play()
        else
            TweenService:Create(main, tweenInfo, {
                Size = scaleDown,
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.25, function()
                if not opened then
                    main.Visible = false
                end
            end)
        end
    end

    toggleBtn.MouseButton1Click:Connect(toggleWindow)
    minimize.MouseButton1Click:Connect(toggleWindow)

    window.Tabs = {}
    window.TabButtons = {}
    window.TabContents = {}

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 200, 1, -44)
    sidebar.Position = UDim2.new(0, 0, 0, 44)
    sidebar.BackgroundColor3 = Color3.fromRGB(20,20,20)
    sidebar.BackgroundTransparency = 1
    sidebar.Parent = main
    window.Sidebar = sidebar
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0,8)

    local gameLabel = Instance.new("TextLabel")
    gameLabel.Text = game
    gameLabel.Size = UDim2.new(1, -10, 0, 34)
    gameLabel.Position = UDim2.new(0, 5, 0, 0)
    gameLabel.BackgroundColor3 = Color3.fromRGB(50,50,50)
    gameLabel.BackgroundTransparency = 0.25
    gameLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
    gameLabel.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
    gameLabel.TextSize = 14
    gameLabel.Parent = sidebar
    Instance.new("UICorner", gameLabel).CornerRadius = UDim.new(0,5)

    local contentArea = Instance.new("ScrollingFrame")
    contentArea.CanvasSize = UDim2.new(0,0,1,0)
    contentArea.ScrollBarThickness = 0
    contentArea.ScrollBarImageTransparency = 1
    contentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentArea.Size = UDim2.new(1, -200, 1, -44)
    contentArea.Position = UDim2.new(0, 200, 0, 44)
    contentArea.BackgroundTransparency = 0.8
    contentArea.Parent = main
    window.ContentArea = contentArea
    Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0,5)

    function window:AddTab(tabProps)
        local Components = {}

        local title = tabProps.Title or "Tab"
        local icon = tabProps.Icon or nil

        local index = #self.Tabs + 1
        self.Tabs[index] = tabProps

        local btn = Instance.new("ImageButton")
        btn.Size = UDim2.new(1, -10, 0, 34)
        btn.Position = UDim2.new(0, 5, 0, 38 + (index-1)*38)
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        btn.BackgroundTransparency = 0.65
        btn.AutoButtonColor = false
        btn.Parent = self.Sidebar
        self.TabButtons[index] = btn
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

        if tabProps.Icon then
            local id = GetIconID(icon)
            if not id then warn("Icon not found for tab:", title) end
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.fromOffset(22,22)
            icon.Position = UDim2.new(0,20,0.5,-11)
            icon.BackgroundTransparency = 1
            icon.Image = id or ""
            icon.Parent = btn
        end

        local label = Instance.new("TextLabel")
        label.Text = title
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0,50,0,0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.FontFace = FontMontserrat(Enum.FontWeight.Medium)
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1,0,0,0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.Visible = (index == 1)
        content.Parent = self.ContentArea
        self.TabContents[index] = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0,8)
        layout.Parent = content

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0,12)
        padding.PaddingLeft = UDim.new(0,12)
        padding.PaddingRight = UDim.new(0,12)
        padding.PaddingBottom = UDim.new(0,12)
        padding.Parent = content

        btn.MouseButton1Click:Connect(function()
            for i, c in ipairs(self.TabContents) do
                c.Visible = (i == index)
                self.TabButtons[i].BackgroundColor3 = (i == index) and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(50,50,50)
                self.TabButtons[i].BackgroundTransparency = (i == index) and 0.25 or 0.65
            end
        end)

        function Components:AddSection(props)
            props = props or {}

            local title = props.Title or "Section"

            local opened = props.Opened or false
            local first = true

            local function addDivider(parent)
                local line = Instance.new("Frame")
                line.Size = UDim2.new(1, 0, 0, 1)
                line.Position = UDim2.new(0,6,0,0)
                line.BackgroundColor3 = Color3.fromRGB(80,80,80)
                line.BackgroundTransparency = 0.3
                line.BorderSizePixel = 0
                line.Parent = parent
            end

            local section = Instance.new("Frame")
            section.AutomaticSize = Enum.AutomaticSize.None
            section.ClipsDescendants = true
            section.Size = UDim2.new(1, 0, 0, 40)
            section.BackgroundTransparency = 1
            section.Parent = content

            local header = Instance.new("Frame")
            header.Size = UDim2.new(1, 0, 0, 40)
            header.BackgroundColor3 = Color3.fromRGB(20,20,20)
            header.BackgroundTransparency = 0.2
            header.Parent = section
            Instance.new("UICorner", header).CornerRadius = UDim.new(0,5)

            local textLabel = Instance.new("TextLabel")
            textLabel.Text = title
            textLabel.Size = UDim2.new(1, -40, 1, 0)
            textLabel.Position = UDim2.new(0,12,0,0)
            textLabel.BackgroundTransparency = 1
            textLabel.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
            textLabel.TextSize = 14
            textLabel.TextColor3 = Color3.fromRGB(100,180,255)
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = header

            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.fromOffset(18,18)
            arrow.Position = UDim2.new(1,-26,0.5,-9)
            arrow.BackgroundTransparency = 1
            arrow.Image = GetIconID("chevron-down")
            arrow.ImageColor3 = Color3.fromRGB(100,180,255)
            arrow.Parent = header

            local body = Instance.new("Frame")
            body.AutomaticSize = Enum.AutomaticSize.None
            body.Size = UDim2.new(1,0,0,0)
            body.ClipsDescendants = true
            body.Visible = false
            body.BackgroundColor3 = Color3.fromRGB(30,30,30)
            body.BackgroundTransparency = 0.5
            body.Position = UDim2.new(0,0,0,40)
            body.Parent = section
            Instance.new("UICorner", body).CornerRadius = UDim.new(0,5)

            local layout = Instance.new("UIListLayout", body)

            local HEADER_H = 40

            local function getBodyHeight()
                task.wait()
                return layout.AbsoluteContentSize.Y
            end

            header.InputBegan:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                opened = not opened

                if opened then
                    body.Visible = true
                    local h = getBodyHeight()

                    TweenService:Create(section,
                        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Size = UDim2.new(1,0,0,HEADER_H + h) }
                    ):Play()

                    TweenService:Create(body,
                        TweenInfo.new(0.25),
                        { Size = UDim2.new(1,0,0,h) }
                    ):Play()
                else
                    TweenService:Create(section,
                        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                        { Size = UDim2.new(1,0,0,HEADER_H) }
                    ):Play()

                    TweenService:Create(body,
                        TweenInfo.new(0.2),
                        { Size = UDim2.new(1,0,0,0) }
                    ):Play()

                    task.delay(0.2, function()
                        if not opened then body.Visible = false end
                    end)
                end

                TweenService:Create(arrow, TweenInfo.new(0.2), {
                    Rotation = opened and 0 or -180
                }):Play()
            end)

            local SectionComponents = {}

            function SectionComponents:AddParagraph(p)
                if not first then
                    addDivider(body)
                end
                first = false
                return Components:AddParagraph(p, body)
            end

            function SectionComponents:AddButton(p)
                if not first then
                    addDivider(body)
                end
                first = false
                return Components:AddButton(p, body)
            end

            function SectionComponents:AddInput(p)
                if not first then
                    addDivider(body)
                end
                first = false
                return Components:AddInput(p, body)
            end

            function SectionComponents:AddToggle(p)
                if not first then
                    addDivider(body)
                end
                first = false
                return Components:AddToggle(p, body)
            end

            function SectionComponents:AddDropdown(p)
                if not first then
                    addDivider(body)
                end
                first = false
                return Components:AddDropdown(p, body)
            end

            return SectionComponents
        end

        function Components:AddParagraph(props, parent)
            parent = parent or content
            props = props or {}

            local text = props.Text or "Paragraph"
            local size = props.TextSize or 14
            local color = props.Color or Color3.fromRGB(180,180,180)
            local align = props.TextXAlignment or Enum.TextXAlignment.Left

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,30)
            frame.BackgroundTransparency = 1
            frame.Parent = parent

            local label = Instance.new("TextLabel")
            label.Text = text
            label.Size = UDim2.new(1,0,1,0)
            label.Position = UDim2.new(0,0,0,0)
            label.BackgroundTransparency = 1
            label.TextColor3 = color
            label.FontFace = FontMontserrat(Enum.FontWeight.Medium)
            label.TextSize = size
            label.TextXAlignment = align
            label.TextYAlignment = Enum.TextYAlignment.Top
            label.RichText = true
            label.TextWrapped = true
            label.Parent = frame

            local Paragraph = {}
            Paragraph.Frame = frame

            function Paragraph:SetText(t)
                label.Text = t or ""
            end

            function Paragraph:Destroy()
                frame:Destroy()
            end

            return Paragraph
        end

        function Components:AddButton(props, parent)
            parent = parent or content
            props = props or {}

            local title = props.Title or "Button"
            local callback = props.Callback

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 45)
            frame.BackgroundTransparency = 1
            frame.Parent = parent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)

            local icon = Instance.new("ImageLabel")
            icon.BackgroundTransparency = 1
            icon.Image = GetIconID("mouse-pointer-click")
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.Position = UDim2.new(0, 28, 0.5, 0)
            icon.ImageColor3 = Color3.fromRGB(100, 180, 255)
            icon.Size = UDim2.fromOffset(24, 24)
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = frame

            local textLabel = Instance.new("TextLabel")
            textLabel.Text = title
            textLabel.Size = UDim2.new(1, -46, 1, 0)
            textLabel.Position = UDim2.new(0,62,0,-1.5)
            textLabel.BackgroundTransparency = 1
            textLabel.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
            textLabel.TextSize = props.TextSize or 16
            textLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame

            local click = Instance.new("TextButton")
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.Parent = frame

            if typeof(callback) == "function" then
                click.MouseButton1Click:Connect(callback)
            end

            local Button = {}

            Button.Frame = frame

            function Button:Destroy()
                frame:Destroy()
            end

            return Button
        end

        function Components:AddInput(props, parent)
            parent = parent or content
            props = props or {}

            local title = props.Title or "Input"
            local placeholder = props.Placeholder or "Value.."
            local default = props.Default or ""
            local callback = props.Callback

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 45)
            frame.BackgroundTransparency = 1
            frame.Parent = parent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)

            local textLabel = Instance.new("TextLabel")
            textLabel.Text = title
            textLabel.Size = UDim2.new(0.5, -10, 1, 0)
            textLabel.Position = UDim2.new(0,18,0,-1.5)
            textLabel.BackgroundTransparency = 1
            textLabel.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
            textLabel.TextSize = props.TextSize or 16
            textLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame

            local boxFrame = Instance.new("Frame")
            boxFrame.Size = UDim2.new(0.5, -20, 1, -16)
            boxFrame.Position = UDim2.new(0.5, 12, 0, 8)
            boxFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
            boxFrame.BackgroundTransparency = 0.50
            boxFrame.Parent = frame
            Instance.new("UICorner", boxFrame).CornerRadius = UDim.new(0,5)

            local boxStroke = Instance.new("UIStroke", boxFrame)
            boxStroke.Color = Color3.fromRGB(150,150,150)
            boxStroke.Transparency = 0.15
            boxStroke.Thickness = 1.8

            local box = Instance.new("TextBox")
            box.Position = UDim2.new(0,8,0,0)
            box.Size = UDim2.new(1,-16,1,0)
            box.BackgroundTransparency = 1
            box.PlaceholderText = placeholder
            box.Text = default
            box.ClearTextOnFocus = false
            box.FontFace = FontMontserrat(Enum.FontWeight.Medium)
            box.TextSize = 14
            box.TextColor3 = Color3.fromRGB(255,255,255)
            box.PlaceholderColor3 = Color3.fromRGB(140,140,140)
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Parent = boxFrame

            local function setValue(v, silent)
                v = tostring(v or "")
                box.Text = v
                if not silent and typeof(callback) == "function" then
                    callback(v)
                end
            end

            box.FocusLost:Connect(function()
                setValue(box.Text)
            end)

            local Input = {}

            Input.Frame = frame

            function Input:SetValue(v)
                setValue(v, true)
            end

            function Input:GetValue()
                return box.Text
            end

            function Input:Destroy()
                frame:Destroy()
            end

            return Input
        end

        function Components:AddToggle(props, parent)
            parent = parent or content
            props = props or {}

            local title = props.Title or "Toggle"
            local callback = props.Callback

            local state = props.Default or false

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 45)
            frame.BackgroundTransparency = 1
            frame.Parent = parent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)

            local textLabel = Instance.new("TextLabel")
            textLabel.Text = title
            textLabel.Size = UDim2.new(0.5, -10, 1, 0)
            textLabel.Position = UDim2.new(0,18,0,-1.5)
            textLabel.BackgroundTransparency = 1
            textLabel.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
            textLabel.TextSize = props.TextSize or 16
            textLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
            textLabel.TextXAlignment = Enum.TextXAlignment.Left
            textLabel.Parent = frame

            local rail = Instance.new("Frame")
            rail.Size = UDim2.fromOffset(40,20)
            rail.Position = UDim2.new(1,-50,0.5,-10)
            rail.BackgroundColor3 = state and Color3.fromRGB(100,180,255) or Color3.fromRGB(70,70,70)
            rail.Parent = frame
            Instance.new("UICorner", rail).CornerRadius = UDim.new(1,0)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(16,16)
            knob.Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
            knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            knob.Parent = rail
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

            local click = Instance.new("TextButton")
            click.Size = UDim2.new(1,0,1,0)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.Parent = frame

            local function apply()
                TweenService:Create(rail, TweenInfo.new(0.15), {
                    BackgroundColor3 = state and Color3.fromRGB(100,180,255) or Color3.fromRGB(70,70,70)
                }):Play()

                TweenService:Create(knob, TweenInfo.new(0.15), {
                    Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
                }):Play()

                if typeof(callback) == "function" then
                    callback(state)
                end
            end

            click.MouseButton1Click:Connect(function()
                state = not state
                apply()
            end)

            local Toggle = {}

            Toggle.Frame = frame

            function Toggle:SetValue(v)
                state = v and true or false
                apply()
            end

            function Toggle:GetValue()
                return state
            end

            function Toggle:Destroy()
                frame:Destroy()
            end

            return Toggle
        end

        function Components:AddDropdown(props, parent)
            parent = parent or content
            props = props or {}

            local title = props.Title or "Dropdown"
            local search = props.Search or false
            local multi = props.Multi or false
            local options = props.Options or {}
            local selected = multi and {} or props.Default
            local callback = props.Callback

            local ITEM_HEIGHT = 26
            local MAX_VISIBLE = 6
            local POOL_SIZE = MAX_VISIBLE + 2

            local opened = false
            local filtered = {}

            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1,0,0,45)
            frame.BackgroundTransparency = 1
            frame.Parent = parent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,5)

            local label = Instance.new("TextLabel")
            label.Text = title
            label.Size = UDim2.new(0.5,-10,1,0)
            label.Position = UDim2.new(0,18,0,-1.5)
            label.BackgroundTransparency = 1
            label.FontFace = FontMontserrat(Enum.FontWeight.SemiBold)
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(100,180,255)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local boxFrame = Instance.new("Frame")
            boxFrame.Size = UDim2.new(0.5,-20,1,-16)
            boxFrame.Position = UDim2.new(0.5,12,0,8)
            boxFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
            boxFrame.BackgroundTransparency = 0.5
            boxFrame.Parent = frame
            Instance.new("UICorner", boxFrame).CornerRadius = UDim.new(0,5)

            local stroke = Instance.new("UIStroke", boxFrame)
            stroke.Color = Color3.fromRGB(150,150,150)
            stroke.Transparency = 0.15
            stroke.Thickness = 1.8

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1,-32,1,0)
            box.Position = UDim2.new(0,8,0,0)
            box.BackgroundTransparency = 1
            box.ClearTextOnFocus = false
            box.TextEditable = search
            box.Active = search
            box.Text = props.Placeholder or "select..."
            box.FontFace = FontMontserrat(Enum.FontWeight.Medium)
            box.TextSize = 14
            box.TextColor3 = Color3.fromRGB(255,255,255)
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.Parent = boxFrame

            local arrow = Instance.new("ImageLabel")
            arrow.Size = UDim2.fromOffset(16,16)
            arrow.Position = UDim2.new(1,-22,0.5,-8)
            arrow.BackgroundTransparency = 1
            arrow.Image = GetIconID("chevron-down")
            arrow.ImageColor3 = Color3.fromRGB(180,180,180)
            arrow.Parent = boxFrame

            local list = Instance.new("ScrollingFrame")
            list.Size = UDim2.new(1,0,0,0)
            list.Position = UDim2.new(0,0,1,6)
            list.CanvasSize = UDim2.new(0,0,0,0)
            list.ScrollBarThickness = 4
            list.BackgroundColor3 = Color3.fromRGB(25,25,25)
            list.Visible = false
            list.ClipsDescendants = true
            list.Parent = boxFrame
            Instance.new("UICorner", list).CornerRadius = UDim.new(0,5)

            local pool = {}

            for i = 1, POOL_SIZE do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,-8,0,24)
                btn.Position = UDim2.new(0,4,0,0)
                btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
                btn.FontFace = FontMontserrat(Enum.FontWeight.Medium)
                btn.TextSize = 13
                btn.TextColor3 = Color3.fromRGB(255,255,255)
                btn.Parent = list
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

                btn.MouseButton1Click:Connect(function()
                    local value = btn:GetAttribute("Value")
                    if not value then return end

                    if multi then
                        selected[value] = not selected[value]
                        btn.TextColor3 = selected[value]
                            and Color3.fromRGB(100,180,255)
                            or Color3.fromRGB(255,255,255)
                    else
                        selected = value
                        box.Text = value
                        close()
                    end

                    if typeof(callback) == "function" then
                        callback(selected)
                    end
                end)

                pool[i] = btn
            end

            local function applyFilter(text)
                table.clear(filtered)
                text = text and string.lower(text)

                for _,opt in ipairs(options) do
                    if not text or string.find(string.lower(opt), text, 1, true) then
                        table.insert(filtered, opt)
                    end
                end

                list.CanvasSize = UDim2.new(0,0,0,#filtered * ITEM_HEIGHT)
            end

            local function render()
                local scroll = list.CanvasPosition.Y
                local start = math.floor(scroll / ITEM_HEIGHT) + 1

                for i,btn in ipairs(pool) do
                    local idx = start + i - 1
                    local value = filtered[idx]

                    if value then
                        btn.Visible = true
                        btn.Position = UDim2.new(0,4,0,(idx-1)*ITEM_HEIGHT)
                        btn.Text = value
                        btn:SetAttribute("Value", value)

                        if multi then
                            btn.TextColor3 = selected[value]
                                and Color3.fromRGB(100,180,255)
                                or Color3.fromRGB(255,255,255)
                        end
                    else
                        btn.Visible = false
                        btn:SetAttribute("Value", nil)
                    end
                end
            end

            list:GetPropertyChangedSignal("CanvasPosition"):Connect(render)

            function open()
                opened = true
                list.Visible = true
                applyFilter(search and box.Text or nil)
                render()

                TweenService:Create(list, TweenInfo.new(0.18), {
                    Size = UDim2.new(1,0,0,MAX_VISIBLE * ITEM_HEIGHT)
                }):Play()

                TweenService:Create(arrow, TweenInfo.new(0.15), {Rotation = 180}):Play()
            end

            function close()
                opened = false
                TweenService:Create(list, TweenInfo.new(0.18), {
                    Size = UDim2.new(1,0,0,0)
                }):Play()

                TweenService:Create(arrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
                task.delay(0.18, function()
                    if not opened then list.Visible = false end
                end)
            end

            boxFrame.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    if opened then close() else open() end
                end
            end)

            if search then
                local tick = 0
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    tick = tick + 1
                    local id = tick

                    task.delay(0.25, function()
                        if id == tick and opened then
                            applyFilter(box.Text)
                            render()
                        end
                    end)
                end)
            end

            local Dropdown = {}

            Dropdown.Frame = frame

            function Dropdown:SetValue(v)
                if multi then
                    selected = {}
                    for _,opt in ipairs(v or {}) do
                        selected[opt] = true
                    end
                    box.Text = table.concat(v or {}, ", ")
                else
                    selected = v
                    box.Text = v or ""
                end
            end

            function Dropdown:GetValue()
                return selected
            end

            function Dropdown:Refresh(newOptions)
                task.spawn(function()
                    options = newOptions or {}
                    applyFilter(search and box.Text or nil)
                    render()
                end)
            end

            function Dropdown:Destroy()
                frame:Destroy()
            end

            return Dropdown
        end

        return Components
    end

    function window:SetTab(set)
        if set >= 1 and set <= #self.Tabs then
            for i, c in ipairs(self.TabContents) do
                c.Visible = (i == set)
                self.TabButtons[i].BackgroundColor3 = (i == set) and Color3.fromRGB(100, 180, 255) or Color3.fromRGB(50,50,50)
                self.TabButtons[i].BackgroundTransparency = (i == set) and 0.25 or 0.65
            end
        end
    end
    
    function window:Destroy()
        if self.Gui then
            self.Gui:Destroy()
        end
    end

    return window
end

return NextUI