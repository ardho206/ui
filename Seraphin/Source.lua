-- Seraphin UI - full styled single-file (matches example screenshot vibe)
-- includes: section (expand/collapse), subsection, dropdown(s), slider, button, toggle, paragraph, notify, input
-- API: Library:Window(opts) -> window; win:Tab(data) -> tab; tab:Section(opts) -> sectionAPI

local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local isStudio = RunService:IsStudio()
local parentGui = (isStudio and Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui")) or (gethui and gethui()) or game:GetService("CoreGui")

local function new(class, props)
    local o = Instance.new(class)
    if props then for k,v in pairs(props) do o[k] = v end end
    return o
end

local function tween(obj, time, props, style, dir)
    style = style or Enum.EasingStyle.Exponential
    dir = dir or Enum.EasingDirection.Out
    return TweenService:Create(obj, TweenInfo.new(time or 0.18, style, dir), props)
end

-- theme / style values to resemble screenshot
local STYLE = {
    windowSize = UDim2.new(0, 720, 0, 420),
    shadowColor = Color3.fromRGB(6, 7, 8),
    bgColor = Color3.fromRGB(21,21,23),
    pageColor = Color3.fromRGB(18,18,20),
    cardColor = Color3.fromRGB(28,28,30),
    accent = Color3.fromRGB(91,68,209),
    text = Color3.fromRGB(235,235,236),
    mutedText = Color3.fromRGB(160,160,165),
    subtleBorder = Color3.fromRGB(34,34,36),
    notificationWidth = 300
}

-- small helper: rounded frame with optional stroke
local function createCard(parent, size, pos)
    local shadow = new("ImageLabel", {
        Parent = parent,
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10,10,118,118),
        ImageColor3 = STYLE.shadowColor,
        ImageTransparency = 0.85,
        Size = size or UDim2.new(0, 300, 0, 60),
        Position = pos or UDim2.new(0,0,0,0),
        ZIndex = 10
    })
    local bg = new("Frame", {
        Parent = shadow,
        BackgroundColor3 = STYLE.cardColor,
        Size = UDim2.new(1, -0, 1, -0),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
        ZIndex = 11
    })
    new("UICorner", {Parent = bg, CornerRadius = UDim.new(0, 10)})
    return shadow, bg
end

-- main builder
function Library:Window(opts)
    opts = opts or {}
    local title = opts.Title or "Seraphin | Premium"
    local subtitle = opts.Desc or "Seraphin On Top!"
    local root = new("ScreenGui", {Parent = parentGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, Name = "SeraphinUI_" .. HttpService:GenerateGUID(false)})
    -- outer shadow container
    local shadow = new("ImageLabel", {
        Parent = root,
        Name = "WindowShadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = opts.Size or STYLE.windowSize,
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10,10,118,118),
        ImageColor3 = STYLE.shadowColor,
        ImageTransparency = 0.8
    })
    local bg = new("Frame", {Parent = shadow, Size = UDim2.new(1,0,1,0), BackgroundColor3 = STYLE.bgColor})
    new("UICorner", {Parent = bg, CornerRadius = UDim.new(0, 12)})
    bg.ClipsDescendants = true

    -- topbar (title, subtitle, theme combo, window controls)
    local topbar = new("Frame", {Parent = bg, Size = UDim2.new(1,0,0,48), BackgroundTransparency = 1})
    local topbarInner = new("Frame", {Parent = topbar, Size = UDim2.new(1,-8,1,-8), Position = UDim2.new(0,8,0,4), BackgroundTransparency = 1})
    local topLeft = new("Frame", {Parent = topbarInner, Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1})
    local topRight = new("Frame", {Parent = topbarInner, Size = UDim2.new(0.4,0,1,0), Position = UDim2.new(0.6,0,0,0), BackgroundTransparency = 1})

    local titleLabel = new("TextLabel", {Parent = topLeft, Text = title, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = STYLE.text, Position = UDim2.new(0,6,0,2)})
    local subLabel = new("TextLabel", {Parent = topLeft, Text = subtitle, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = STYLE.mutedText, Position = UDim2.new(0,6,0,22)})
    -- theme dropdown mock (right)
    local themeBox = new("TextButton", {Parent = topRight, BackgroundColor3 = STYLE.cardColor, Size = UDim2.new(0,150,0,28), Position = UDim2.new(1,-160,0,10), Text = "Dark ▾", Font = Enum.Font.GothamBold, TextSize = 12})
    new("UICorner",{Parent = themeBox, CornerRadius = UDim.new(0,6)})
    -- controls (min, max, close)
    local btnMin = new("TextButton", {Parent = topRight, Text = "▁", Size = UDim2.new(0,28,0,28), Position = UDim2.new(1,-48,0,10), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = STYLE.mutedText})
    local btnMax = new("TextButton", {Parent = topRight, Text = "▢", Size = UDim2.new(0,28,0,28), Position = UDim2.new(1,-84,0,10), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = STYLE.mutedText})
    local btnClose = new("TextButton", {Parent = topRight, Text = "✕", Size = UDim2.new(0,28,0,28), Position = UDim2.new(1,-20,0,10), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = STYLE.mutedText})

    -- layout base: left sidebar + content area
    local left = new("Frame", {Parent = bg, Size = UDim2.new(0, 140, 1, -56), Position = UDim2.new(0,0,0,56), BackgroundTransparency = 1})
    new("UICorner", {Parent = left, CornerRadius = UDim.new(0,10)})
    local leftList = new("ScrollingFrame", {Parent = left, Size = UDim2.new(1,1,1,0), BackgroundTransparency = 1, ScrollBarThickness = 3})
    local leftLayout = new("UIListLayout", {Parent = leftList, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top})
    leftList.CanvasSize = UDim2.new(0,0,0,0)

    local content = new("Frame", {Parent = bg, Size = UDim2.new(1, -140, 1, -56), Position = UDim2.new(0,140,0,56), BackgroundColor3 = STYLE.pageColor})
    new("UICorner", {Parent = content, CornerRadius = UDim.new(0,8)})
    content.ClipsDescendants = true
    local contentScroll = new("ScrollingFrame", {Parent = content, Size = UDim2.new(1,1,1,0), BackgroundTransparency = 1, ScrollBarThickness = 4})
    local contentLayout = new("UIListLayout", {Parent = contentScroll, Padding = UDim.new(0,12), SortOrder = Enum.SortOrder.LayoutOrder})
    contentScroll.CanvasSize = UDim2.new(0,0,0,0)
    -- update canvas helper
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScroll.CanvasSize = UDim2.new(0,0,0, contentLayout.AbsoluteContentSize.Y + 16)
    end)
    leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        leftList.CanvasSize = UDim2.new(0,0,0, leftLayout.AbsoluteContentSize.Y + 18)
    end)

    -- notification container (bottom-right)
    local notifFrame = new("Frame", {Parent = bg, Size = UDim2.new(0, STYLE.notificationWidth, 0, 200), Position = UDim2.new(1, -STYLE.notificationWidth - 12, 1, -12), BackgroundTransparency = 1})
    local notifLayout = new("UIListLayout", {Parent = notifFrame, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom})

    -- TAB system (left items + content stacking)
    local tabs = {}
    local currentTab = nil

    local function selectTab(idx)
        if currentTab and currentTab.page then currentTab.page.Visible = false end
        currentTab = tabs[idx]
        if currentTab then currentTab.page.Visible = true end
    end

    -- component factories for inside content (styled)
    local Components = {}

    function Components:Section(parent, data)
        data = data or {}
        local title = data.Title or "Section"
        local shadowCard, card = createCard(parent, UDim2.new(1, -24, 0, 60), nil)
        -- position: parent layout will handle; use child frames inside card
        local header = new("Frame", {Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,36)})
        local titleLbl = new("TextLabel", {Parent = header, Text = title, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = STYLE.text, Position = UDim2.new(0, 12, 0, 6)})
        new("UICorner", {Parent = shadowCard, CornerRadius = UDim.new(0,8)})
        -- content area hidden by default (but section default open)
        local contentHolder = new("Frame", {Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, 36), ClipsDescendants = true})
        local contentLayout = new("UIListLayout", {Parent = contentHolder, Padding = UDim.new(0,8)})
        contentHolder.ChildAdded:Connect(function() -- adjust card size when children change
            local target = contentLayout.AbsoluteContentSize.Y + 48
            tween(shadowCard, 0.18, {Size = UDim2.new(1, -24, 0, target)}):Play()
        end)
        -- toggle icon on right
        local toggleBtn = new("TextButton", {Parent = header, Text = "▾", BackgroundTransparency = 1, Size = UDim2.new(0,28,0,28), Position = UDim2.new(1, -36, 0, 4), Font = Enum.Font.GothamBold, TextSize = 14})
        toggleBtn.MouseButton1Click:Connect(function()
            if contentHolder.Size.Y.Offset == 0 then
                -- expand
                local target = contentLayout.AbsoluteContentSize.Y + 48
                tween(shadowCard, 0.18, {Size = UDim2.new(1, -24, 0, target)}):Play()
                contentHolder:TweenSize(UDim2.new(1, -24, 0, contentLayout.AbsoluteContentSize.Y), Enum.EasingDirection.Out, Enum.EasingStyle.Exponential, 0.18, true)
                toggleBtn.Text = "▴"
            else
                -- collapse
                tween(shadowCard, 0.18, {Size = UDim2.new(1, -24, 0, 60)}):Play()
                contentHolder:TweenSize(UDim2.new(1, -24, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Exponential, 0.18, true)
                toggleBtn.Text = "▾"
            end
        end)
        local sectionAPI = {}

        function sectionAPI:Subsection(subTitle)
            local subShadow, subCard = createCard(contentHolder, UDim2.new(1,0,0,46))
            local sLabel = new("TextLabel", {Parent = subCard, BackgroundTransparency = 1, Text = subTitle or "Subsection", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.new(0,12,0,8)})
            return {
                AddLabel = function(self, t, d) Components:Paragraph(subCard, t, d) end,
                AddButton = function(self, o) Components:Button(subCard, o) end
            }
        end

        function sectionAPI:Label(o)
            Components:Paragraph(contentHolder, o.Title or "", o.Desc or "")
        end

        function sectionAPI:Paragraph(textTitle, textBody)
            Components:Paragraph(contentHolder, textTitle, textBody)
        end

        function sectionAPI:Button(o)
            Components:Button(contentHolder, o)
        end

        function sectionAPI:Toggle(o)
            return Components:Toggle(contentHolder, o)
        end

        function sectionAPI:Slider(o)
            return Components:Slider(contentHolder, o)
        end

        function sectionAPI:Dropdown(o)
            return Components:Dropdown(contentHolder, o)
        end

        function sectionAPI:Input(o)
            return Components:Input(contentHolder, o)
        end

        return sectionAPI
    end

    function Components:Paragraph(parent, title, body)
        local row = new("Frame", {Parent = parent, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,48)})
        local lbl = new("TextLabel", {Parent = row, BackgroundTransparency = 1, Text = title or "", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.new(0,12,0,4), Size = UDim2.new(1,-24,0,18), TextXAlignment = Enum.TextXAlignment.Left})
        local bodyLbl = new("TextLabel", {Parent = row, BackgroundTransparency = 1, Text = body or "", Font = Enum.Font.Gotham, TextSize = 11, Position = UDim2.new(0,12,0,22), Size = UDim2.new(1,-24,0,20), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left})
        lbl.TextColor3 = STYLE.text
        bodyLbl.TextColor3 = STYLE.mutedText
        return row
    end

    function Components:Button(parent, o)
        o = o or {}
        local frame = new("Frame", {Parent = parent, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,34)})
        local btn = new("TextButton", {
            Parent = frame,
            Size = UDim2.new(1, -24, 0, 30),
            Position = UDim2.new(0,12,0,2),
            BackgroundColor3 = STYLE.cardColor,
            BorderSizePixel = 0,
            Text = o.Title or "Button",
            Font = Enum.Font.GothamBold,
            TextSize = 12
        })
        new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
        btn.MouseButton1Click:Connect(function() pcall(function() if o.Callback then o.Callback() end end) end)
        return btn
    end

    function Components:Toggle(parent, opts)
        opts = opts or {}
        local frame = new("Frame", {Parent = parent, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,28)})
        local text = new("TextLabel", {Parent = frame, BackgroundTransparency = 1, Text = opts.Title or "Toggle", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.new(0,12,0,6), Size = UDim2.new(1,-80,0,16), TextXAlignment = Enum.TextXAlignment.Left})
        local box = new("Frame", {Parent = frame, BackgroundColor3 = STYLE.cardColor, Size = UDim2.new(0,44,0,22), Position = UDim2.new(1,-60,0,3)})
        new("UICorner", {Parent = box, CornerRadius = UDim.new(1,0)})
        local dot = new("Frame", {Parent = box, BackgroundColor3 = STYLE.accent, Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,4,0,2)})
        new("UICorner", {Parent = dot, CornerRadius = UDim.new(1,0)})
        local state = opts.Value or false
        local function set(v)
            state = v
            if v then
                tween(dot, 0.12, {Position = UDim2.new(1, -22, 0, 2)}):Play()
            else
                tween(dot, 0.12, {Position = UDim2.new(0,4,0,2)}):Play()
            end
            pcall(opts.Callback, state)
        end
        local click = new("TextButton", {Parent = frame, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0)})
        click.MouseButton1Click:Connect(function() set(not state) end)
        set(state)
        return {Set = set}
    end

    function Components:Slider(parent, opts)
        opts = opts or {}
        local frame = new("Frame", {Parent = parent, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,44)})
        local label = new("TextLabel", {Parent = frame, BackgroundTransparency = 1, Text = opts.Title or "Slider", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.new(0,12,0,4)})
        local bar = new("Frame", {Parent = frame, BackgroundColor3 = STYLE.cardColor, Size = UDim2.new(1,-80,0,8), Position = UDim2.new(0,12,0,26)})
        new("UICorner", {Parent = bar, CornerRadius = UDim.new(1,0)})
        local fill = new("Frame", {Parent = bar, BackgroundColor3 = STYLE.accent, Size = UDim2.new(0,0,1,0)})
        new("UICorner", {Parent = fill, CornerRadius = UDim.new(1,0)})
        local valueLabel = new("TextLabel", {Parent = frame, BackgroundTransparency = 1, Text = tostring(opts.Default or 0), Position = UDim2.new(1, -60, 0, 6), Size = UDim2.new(0,48,0,18)})
        local min = opts.Min or 0
        local max = opts.Max or 100
        local cur = opts.Default or min
        local dragging = false
        local function update(v)
            cur = math.clamp(v, min, max)
            local ratio = (cur - min) / math.max(1, (max - min))
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            valueLabel.Text = tostring(math.floor(cur))
            pcall(opts.Callback, cur)
        end
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local conn
                conn = UserInput.InputChanged:Connect(function(move)
                    if move.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                        local x = math.clamp((move.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                        update(min + x * (max - min))
                    end
                end)
                local upConn
                upConn = UserInput.InputEnded:Connect(function(e)
                    if e.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                        conn:Disconnect()
                        upConn:Disconnect()
                    end
                end)
            end
        end)
        update(cur)
        return {Set = function(_,v) update(v) end}
    end

    function Components:Dropdown(parent, opts)
        opts = opts or {}
        local frame = new("Frame", {Parent = parent, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,34)})
        local label = new("TextLabel", {Parent = frame, BackgroundTransparency = 1, Text = opts.Title or "Dropdown", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.new(0,12,0,6)})
        local curVal = new("TextLabel", {Parent = frame, BackgroundTransparency = 1, Text = opts.Default or (opts.Options and opts.Options[1]) or "", Position = UDim2.new(1,-120,0,6), Size = UDim2.new(0,110,0,22), TextXAlignment = Enum.TextXAlignment.Right})
        local arrow = new("TextButton", {Parent = frame, Text = "▾", BackgroundTransparency = 1, Position = UDim2.new(1,-18,0,6), Size = UDim2.new(0,18,0,22)})
        local list = new("Frame", {Parent = frame, BackgroundColor3 = STYLE.cardColor, Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,34), ClipsDescendants = true, Visible = false})
        local layout = new("UIListLayout", {Parent = list, Padding = UDim.new(0,6)})
        local function refreshList()
            list.Size = UDim2.new(1,0,0, layout.AbsoluteContentSize.Y + 8)
        end
        if opts.Options then
            for _,v in ipairs(opts.Options) do
                local item = new("TextButton", {Parent = list, BackgroundTransparency = 1, Text = v, Size = UDim2.new(1,-24,0,24), Position = UDim2.new(0,12,0,0), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left})
                item.MouseButton1Click:Connect(function()
                    curVal.Text = v
                    list.Visible = false
                    pcall(opts.Callback, v)
                end)
            end
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshList)
        arrow.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
        return {
            Set = function(_,v) curVal.Text = v end,
            Get = function() return curVal.Text end
        }
    end

    function Components:Input(parent, opts)
        opts = opts or {}
        local frame = new("Frame", {Parent = parent, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,34)})
        local textBox = new("TextBox", {Parent = frame, BackgroundColor3 = STYLE.cardColor, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0,12,0,4), Text = opts.Default or "", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 12})
        new("UICorner", {Parent = textBox, CornerRadius = UDim.new(0,6)})
        textBox.FocusLost:Connect(function(enter)
            if enter then pcall(opts.Callback, textBox.Text) end
        end)
        return {Get = function() return textBox.Text end, Set = function(_,v) textBox.Text = v end}
    end

    function Components:Notify(opts)
        opts = opts or {}
        local title = opts.Title or "Notice"
        local desc = opts.Desc or ""
        local dur = opts.Time or 4
        local shadowN, bgN = createCard(notifFrame, UDim2.new(1,0,0,60))
        bgN.Size = UDim2.new(1,0,1,0)
        local t = new("TextLabel", {Parent = bgN, BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.new(0,12,0,6)})
        local d = new("TextLabel", {Parent = bgN, BackgroundTransparency = 1, Text = desc, Font = Enum.Font.Gotham, TextSize = 11, Position = UDim2.new(0,12,0,28), TextColor3 = STYLE.mutedText})
        tween(shadowN, 0.12, {Size = UDim2.new(1,0,0,60)}):Play()
        task.spawn(function()
            task.wait(dur)
            tween(shadowN, 0.12, {Size = UDim2.new(1,0,0,0)}):Play():Wait()
            shadowN:Destroy()
        end)
    end

    -- API to create a Tab (left icon + title + content page)
    function win.Tab(self, data)
        data = data or {}
        local title = data.Title or "Tab"
        local icon = data.Icon -- not implemented sprite mapping here, use only text for icons
        local tabFrame = new("Frame", {Parent = leftList, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,36)})
        local btn = new("TextButton", {Parent = tabFrame, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "  "..title, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = STYLE.mutedText})
        btn.MouseEnter:Connect(function() btn.TextColor3 = STYLE.text end)
        btn.MouseLeave:Connect(function() if currentTab and currentTab.title == title then btn.TextColor3 = STYLE.accent else btn.TextColor3 = STYLE.mutedText end end)
        -- page
        local page = new("Frame", {Parent = contentScroll, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0)})
        local pageScroll = new("ScrollingFrame", {Parent = page, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ScrollBarThickness = 4})
        local pageLayout = new("UIListLayout", {Parent = pageScroll, Padding = UDim.new(0,12)})
        pageScroll.CanvasSize = UDim2.new(0,0,0,0)
        page.Visible = false

        local index = #tabs + 1
        tabs[index] = {page = page, title = title, button = btn}

        btn.MouseButton1Click:Connect(function()
            for i,v in ipairs(tabs) do
                v.page.Visible = false
                v.button.TextColor3 = STYLE.mutedText
            end
            tabs[index].page.Visible = true
            tabs[index].button.TextColor3 = STYLE.accent
            currentTab = tabs[index]
        end)

        local tabAPI = {}

        function tabAPI:Section(opts)
            local s = Components:Section(pageScroll, opts)
            return s -- s has methods for label/button/etc
        end

        function tabAPI:Label(o)
            Components:Paragraph(pageScroll, o.Title, o.Desc)
        end

        function tabAPI:Notify(o)
            Components:Notify(o)
        end

        function tabAPI:Button(o)
            Components:Button(pageScroll, o)
        end

        return tabAPI
    end

    -- expose window API
    local win = {}
    function win:Tab(data) return win.Tab(win, data) end
    -- implement window inner Tab in function closure
    win.Tab = function(self, data) return win.Tab(self, data) end -- placeholder; will be overridden below

    -- To fix closure ordering (define function after Components exist)
    -- rebind win.Tab to correct implementation (redefine using the function created earlier)
    do
        local function createTab(data)
            data = data or {}
            local title = data.Title or "Tab"
            local tabFrame = new("Frame", {Parent = leftList, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,36)})
            local btn = new("TextButton", {Parent = tabFrame, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Text = "  "..title, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = STYLE.mutedText})
            btn.MouseEnter:Connect(function() btn.TextColor3 = STYLE.text end)
            btn.MouseLeave:Connect(function() if currentTab and currentTab.title == title then btn.TextColor3 = STYLE.accent else btn.TextColor3 = STYLE.mutedText end end)
            local page = new("Frame", {Parent = contentScroll, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0)})
            local pageScroll = new("ScrollingFrame", {Parent = page, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ScrollBarThickness = 4})
            local pageLayout = new("UIListLayout", {Parent = pageScroll, Padding = UDim.new(0,12)})
            pageScroll.CanvasSize = UDim2.new(0,0,0,0)
            page.Visible = false

            local index = #tabs + 1
            tabs[index] = {page = page, title = title, button = btn}
            btn.MouseButton1Click:Connect(function()
                for i,v in ipairs(tabs) do
                    v.page.Visible = false
                    v.button.TextColor3 = STYLE.mutedText
                end
                tabs[index].page.Visible = true
                tabs[index].button.TextColor3 = STYLE.accent
                currentTab = tabs[index]
            end)

            local tabAPI = {}
            function tabAPI:Section(opts)
                return Components:Section(pageScroll, opts)
            end
            function tabAPI:Label(o) Components:Paragraph(pageScroll, o.Title, o.Desc) end
            function tabAPI:Button(o) Components:Button(pageScroll, o) end
            function tabAPI:Notify(o) Components:Notify(o) end
            function tabAPI:Dropdown(o) return Components:Dropdown(pageScroll, o) end
            function tabAPI:Input(o) return Components:Input(pageScroll, o) end
            function tabAPI:Slider(o) return Components:Slider(pageScroll, o) end
            function tabAPI:Toggle(o) return Components:Toggle(pageScroll, o) end

            return tabAPI
        end

        win.Tab = function(self, data) return createTab(data) end
    end

    -- auto-create default tab if given in opts
    if opts.Tabs then
        for _,t in ipairs(opts.Tabs) do
            win:Tab(t)
        end
        -- open first tab by default
        if #tabs > 0 then
            tabs[1].button.MouseButton1Click:Wait()
        end
    end

    -- return public window api
    return win
end

return Library