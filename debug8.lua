--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              TITLE SPY & EQUIP TOOL - BLOX FRUITS           ║
    ║         Phát hiện Remote/Invoker liên quan đến Title        ║
    ║                  + Equip Title trực tiếp                    ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Chức năng:
    1. Remote Spy - Hook tất cả FireServer/InvokeServer, lọc Title
    2. Hiển thị danh sách Title đã unlock
    3. Equip Title trực tiếp từ GUI
    4. Log tất cả remote liên quan Title vào console
]]

-- ═══════════════════ ANTI DUPLICATE ═══════════════════
if getgenv().TitleSpyRunning then
    if getgenv().TitleSpyShutdown then
        getgenv().TitleSpyShutdown()
    end
end
getgenv().TitleSpyRunning = true

-- ═══════════════════ SERVICES ═══════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ═══════════════════ REMOTE REFERENCES ═══════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")

-- ═══════════════════ CONFIG ═══════════════════
local Config = {
    SpyEnabled = true,
    LogAllRemotes = false,    -- true = log ALL remotes, false = chỉ log title-related
    AutoRefresh = true,
    RefreshInterval = 5,
}

-- ═══════════════════ REMOTE LOG STORAGE ═══════════════════
local RemoteLogs = {}
local TitleList = {}
local CurrentTitle = "None"

-- ═══════════════════ UTILITY FUNCTIONS ═══════════════════
local function SerializeArgs(args)
    local result = {}
    for i, v in pairs(args) do
        local t = typeof(v)
        if t == "string" then
            table.insert(result, '"' .. tostring(v) .. '"')
        elseif t == "Instance" then
            table.insert(result, v:GetFullName())
        elseif t == "table" then
            table.insert(result, "{table:" .. #v .. " items}")
        elseif t == "boolean" then
            table.insert(result, tostring(v))
        elseif t == "number" then
            table.insert(result, tostring(v))
        elseif t == "CFrame" or t == "Vector3" then
            table.insert(result, t .. "(" .. tostring(v) .. ")")
        else
            table.insert(result, tostring(v))
        end
    end
    return table.concat(result, ", ")
end

local function IsTitleRelated(args)
    for _, v in pairs(args) do
        if type(v) == "string" then
            local lower = string.lower(v)
            if string.find(lower, "title") 
            or string.find(lower, "achievement")
            or string.find(lower, "gettitle")
            or string.find(lower, "equiptitle")
            or string.find(lower, "settitle")
            or string.find(lower, "selecttitle") then
                return true
            end
        end
    end
    return false
end

local function LogRemote(remoteName, remoteType, args, returnValue)
    local logEntry = {
        Time = os.clock(),
        Remote = remoteName,
        Type = remoteType,
        Args = SerializeArgs(args),
        RawArgs = args,
        Return = returnValue and tostring(returnValue) or "N/A",
        IsTitleRelated = IsTitleRelated(args)
    }
    table.insert(RemoteLogs, 1, logEntry)
    if #RemoteLogs > 200 then
        table.remove(RemoteLogs)
    end
    return logEntry
end

-- ═══════════════════ GUI CREATION ═══════════════════
local function CreateGUI()
    -- Cleanup old GUI
    if CoreGui:FindFirstChild("TitleSpyGUI") then
        CoreGui.TitleSpyGUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TitleSpyGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui

    -- ══════ MAIN FRAME ══════
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -210, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    MainFrame.Active = true
    MainFrame.Draggable = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(100, 60, 200)
    MainStroke.Thickness = 2
    MainStroke.Parent = MainFrame

    -- ══════ TITLE BAR ══════
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleBarCorner = Instance.new("UICorner")
    TitleBarCorner.CornerRadius = UDim.new(0, 10)
    TitleBarCorner.Parent = TitleBar

    -- Fix bottom corners of title bar
    local TitleBarFix = Instance.new("Frame")
    TitleBarFix.Size = UDim2.new(1, 0, 0, 10)
    TitleBarFix.Position = UDim2.new(0, 0, 1, -10)
    TitleBarFix.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
    TitleBarFix.BorderSizePixel = 0
    TitleBarFix.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "🔍 TITLE SPY & EQUIP"
    TitleLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    -- Minimize button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -70, 0, 5)
    MinBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 90)
    MinBtn.Text = "─"
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinBtn.TextSize = 14
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TitleBar
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- Close button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    -- ══════ TAB BUTTONS ══════
    local TabFrame = Instance.new("Frame")
    TabFrame.Size = UDim2.new(1, -20, 0, 35)
    TabFrame.Position = UDim2.new(0, 10, 0, 45)
    TabFrame.BackgroundTransparency = 1
    TabFrame.Parent = MainFrame

    local function CreateTab(name, pos, isActive)
        local btn = Instance.new("TextButton")
        btn.Name = name .. "Tab"
        btn.Size = UDim2.new(0, 125, 1, 0)
        btn.Position = pos
        btn.BackgroundColor3 = isActive and Color3.fromRGB(80, 50, 160) or Color3.fromRGB(40, 35, 60)
        btn.Text = name
        btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamSemibold
        btn.BorderSizePixel = 0
        btn.Parent = TabFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    local TabTitles = CreateTab("📜 TITLES", UDim2.new(0, 0, 0, 0), true)
    local TabSpy = CreateTab("🔎 REMOTE SPY", UDim2.new(0, 135, 0, 0), false)
    local TabSettings = CreateTab("⚙ SETTINGS", UDim2.new(0, 270, 0, 0), false)

    -- ══════ CONTENT AREA ══════
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -20, 1, -95)
    ContentFrame.Position = UDim2.new(0, 10, 0, 85)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ClipsDescendants = true
    ContentFrame.Parent = MainFrame
    Instance.new("UICorner", ContentFrame).CornerRadius = UDim.new(0, 8)

    -- ═══════ PAGE: TITLES ═══════
    local TitlesPage = Instance.new("ScrollingFrame")
    TitlesPage.Name = "TitlesPage"
    TitlesPage.Size = UDim2.new(1, 0, 1, 0)
    TitlesPage.BackgroundTransparency = 1
    TitlesPage.ScrollBarThickness = 4
    TitlesPage.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 200)
    TitlesPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    TitlesPage.Parent = ContentFrame
    TitlesPage.Visible = true

    local TitlesLayout = Instance.new("UIListLayout")
    TitlesLayout.Padding = UDim.new(0, 4)
    TitlesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TitlesLayout.Parent = TitlesPage

    local TitlesPadding = Instance.new("UIPadding")
    TitlesPadding.PaddingTop = UDim.new(0, 5)
    TitlesPadding.PaddingLeft = UDim.new(0, 5)
    TitlesPadding.PaddingRight = UDim.new(0, 5)
    TitlesPadding.Parent = TitlesPage

    -- ═══════ PAGE: REMOTE SPY ═══════
    local SpyPage = Instance.new("ScrollingFrame")
    SpyPage.Name = "SpyPage"
    SpyPage.Size = UDim2.new(1, 0, 1, 0)
    SpyPage.BackgroundTransparency = 1
    SpyPage.ScrollBarThickness = 4
    SpyPage.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 200)
    SpyPage.CanvasSize = UDim2.new(0, 0, 0, 0)
    SpyPage.Parent = ContentFrame
    SpyPage.Visible = false

    local SpyLayout = Instance.new("UIListLayout")
    SpyLayout.Padding = UDim.new(0, 3)
    SpyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SpyLayout.Parent = SpyPage

    local SpyPadding = Instance.new("UIPadding")
    SpyPadding.PaddingTop = UDim.new(0, 5)
    SpyPadding.PaddingLeft = UDim.new(0, 5)
    SpyPadding.PaddingRight = UDim.new(0, 5)
    SpyPadding.Parent = SpyPage

    -- ═══════ PAGE: SETTINGS ═══════
    local SettingsPage = Instance.new("Frame")
    SettingsPage.Name = "SettingsPage"
    SettingsPage.Size = UDim2.new(1, 0, 1, 0)
    SettingsPage.BackgroundTransparency = 1
    SettingsPage.Parent = ContentFrame
    SettingsPage.Visible = false

    -- ═══════ STATUS BAR ═══════
    local StatusBar = Instance.new("TextLabel")
    StatusBar.Size = UDim2.new(1, -20, 0, 20)
    StatusBar.Position = UDim2.new(0, 10, 1, -25)
    StatusBar.BackgroundTransparency = 1
    StatusBar.Text = "🟢 Spy Active | Current Title: None"
    StatusBar.TextColor3 = Color3.fromRGB(120, 200, 120)
    StatusBar.TextSize = 11
    StatusBar.Font = Enum.Font.Gotham
    StatusBar.TextXAlignment = Enum.TextXAlignment.Left
    StatusBar.Parent = MainFrame

    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TitlesPage = TitlesPage,
        SpyPage = SpyPage,
        SettingsPage = SettingsPage,
        TabTitles = TabTitles,
        TabSpy = TabSpy,
        TabSettings = TabSettings,
        StatusBar = StatusBar,
        MinBtn = MinBtn,
        CloseBtn = CloseBtn,
        ContentFrame = ContentFrame,
    }
end

-- ═══════════════════ BUILD GUI ═══════════════════
local GUI = CreateGUI()
local isMinimized = false

-- ═══════════════════ TAB SWITCHING ═══════════════════
local function SwitchTab(activeTab)
    local tabs = {
        {btn = GUI.TabTitles, page = GUI.TitlesPage},
        {btn = GUI.TabSpy, page = GUI.SpyPage},
        {btn = GUI.TabSettings, page = GUI.SettingsPage},
    }
    for _, t in pairs(tabs) do
        local isActive = (t.btn == activeTab)
        t.page.Visible = isActive
        TweenService:Create(t.btn, TweenInfo.new(0.2), {
            BackgroundColor3 = isActive and Color3.fromRGB(80, 50, 160) or Color3.fromRGB(40, 35, 60),
            TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
        }):Play()
    end
end

GUI.TabTitles.MouseButton1Click:Connect(function() SwitchTab(GUI.TabTitles) end)
GUI.TabSpy.MouseButton1Click:Connect(function() SwitchTab(GUI.TabSpy) end)
GUI.TabSettings.MouseButton1Click:Connect(function() SwitchTab(GUI.TabSettings) end)

-- ═══════════════════ MINIMIZE / CLOSE ═══════════════════
GUI.MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local targetSize = isMinimized and UDim2.new(0, 420, 0, 45) or UDim2.new(0, 420, 0, 500)
    TweenService:Create(GUI.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = targetSize
    }):Play()
    GUI.MinBtn.Text = isMinimized and "□" or "─"
    GUI.ContentFrame.Visible = not isMinimized
    GUI.StatusBar.Visible = not isMinimized
end)

GUI.CloseBtn.MouseButton1Click:Connect(function()
    getgenv().TitleSpyRunning = false
    if getgenv().TitleSpyShutdown then
        getgenv().TitleSpyShutdown()
    end
    GUI.ScreenGui:Destroy()
end)

-- ═══════════════════ TITLE CARD BUILDER ═══════════════════
local function CreateTitleCard(titleName, titleData, parent)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -10, 0, 50)
    Card.BackgroundColor3 = Color3.fromRGB(30, 28, 48)
    Card.BorderSizePixel = 0
    Card.Parent = parent
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Color3.fromRGB(60, 45, 100)
    CardStroke.Thickness = 1
    CardStroke.Parent = Card

    -- Title name
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -120, 1, 0)
    NameLabel.Position = UDim2.new(0, 12, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = "🏆 " .. tostring(titleName)
    NameLabel.TextColor3 = Color3.fromRGB(220, 200, 255)
    NameLabel.TextSize = 14
    NameLabel.Font = Enum.Font.GothamSemibold
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Card

    -- Equip button
    local EquipBtn = Instance.new("TextButton")
    EquipBtn.Size = UDim2.new(0, 80, 0, 30)
    EquipBtn.Position = UDim2.new(1, -95, 0.5, -15)
    EquipBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
    EquipBtn.Text = "EQUIP"
    EquipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    EquipBtn.TextSize = 12
    EquipBtn.Font = Enum.Font.GothamBold
    EquipBtn.BorderSizePixel = 0
    EquipBtn.Parent = Card
    Instance.new("UICorner", EquipBtn).CornerRadius = UDim.new(0, 6)

    -- Equip logic
    EquipBtn.MouseButton1Click:Connect(function()
        EquipBtn.Text = "..."
        local success, result = pcall(function()
            -- Method 1: InvokeServer equipTitle
            return CommF_:InvokeServer("equipTitle", titleName)
        end)
        
        if not success then
            -- Method 2: Try via GUI simulation
            pcall(function()
                local TitlesGUI = playerGui:FindFirstChild("Main") 
                    and playerGui.Main:FindFirstChild("Titles")
                if TitlesGUI then
                    for _, child in pairs(TitlesGUI:GetDescendants()) do
                        if child:IsA("TextButton") or child:IsA("TextLabel") then
                            if child.Text == titleName then
                                local equipBtn = child.Parent:FindFirstChild("Equip") 
                                    or child.Parent:FindFirstChild("Select")
                                    or child.Parent:FindFirstChild("EquipButton")
                                if equipBtn and equipBtn:IsA("TextButton") then
                                    firesignal(equipBtn.MouseButton1Click)
                                end
                            end
                        end
                    end
                end
            end)
        end

        CurrentTitle = titleName
        GUI.StatusBar.Text = "🟢 Spy Active | Current Title: " .. titleName
        
        TweenService:Create(EquipBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(80, 50, 160)
        }):Play()
        EquipBtn.Text = "EQUIPPED"
        
        task.wait(1.5)
        TweenService:Create(EquipBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(60, 140, 60)
        }):Play()
        EquipBtn.Text = "EQUIP"
    end)

    -- Hover effects
    EquipBtn.MouseEnter:Connect(function()
        TweenService:Create(EquipBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        }):Play()
    end)
    EquipBtn.MouseLeave:Connect(function()
        TweenService:Create(EquipBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(60, 140, 60)
        }):Play()
    end)

    return Card
end

-- ═══════════════════ REMOTE LOG CARD BUILDER ═══════════════════
local function CreateLogCard(logEntry, parent)
    local color = logEntry.IsTitleRelated 
        and Color3.fromRGB(50, 30, 70)
        or Color3.fromRGB(28, 28, 40)
    
    local borderColor = logEntry.IsTitleRelated
        and Color3.fromRGB(140, 80, 255)
        or Color3.fromRGB(50, 50, 70)

    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1, -10, 0, 60)
    Card.BackgroundColor3 = color
    Card.BorderSizePixel = 0
    Card.Parent = parent
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = borderColor
    Stroke.Thickness = 1
    Stroke.Parent = Card

    -- Type badge
    local TypeBadge = Instance.new("TextLabel")
    TypeBadge.Size = UDim2.new(0, 70, 0, 18)
    TypeBadge.Position = UDim2.new(0, 8, 0, 5)
    TypeBadge.BackgroundColor3 = logEntry.Type == "InvokeServer" 
        and Color3.fromRGB(200, 120, 50) 
        or Color3.fromRGB(50, 120, 200)
    TypeBadge.Text = logEntry.Type == "InvokeServer" and "INVOKE" or "FIRE"
    TypeBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    TypeBadge.TextSize = 10
    TypeBadge.Font = Enum.Font.GothamBold
    TypeBadge.Parent = Card
    Instance.new("UICorner", TypeBadge).CornerRadius = UDim.new(0, 4)

    -- Title related badge
    if logEntry.IsTitleRelated then
        local TitleBadge = Instance.new("TextLabel")
        TitleBadge.Size = UDim2.new(0, 50, 0, 18)
        TitleBadge.Position = UDim2.new(0, 84, 0, 5)
        TitleBadge.BackgroundColor3 = Color3.fromRGB(180, 50, 180)
        TitleBadge.Text = "TITLE"
        TitleBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleBadge.TextSize = 10
        TitleBadge.Font = Enum.Font.GothamBold
        TitleBadge.Parent = Card
        Instance.new("UICorner", TitleBadge).CornerRadius = UDim.new(0, 4)
    end

    -- Remote name
    local RemoteName = Instance.new("TextLabel")
    RemoteName.Size = UDim2.new(1, -16, 0, 16)
    RemoteName.Position = UDim2.new(0, 8, 0, 26)
    RemoteName.BackgroundTransparency = 1
    RemoteName.Text = "📡 " .. logEntry.Remote
    RemoteName.TextColor3 = Color3.fromRGB(180, 180, 220)
    RemoteName.TextSize = 12
    RemoteName.Font = Enum.Font.GothamSemibold
    RemoteName.TextXAlignment = Enum.TextXAlignment.Left
    RemoteName.TextTruncate = Enum.TextTruncate.AtEnd
    RemoteName.Parent = Card

    -- Args
    local ArgsLabel = Instance.new("TextLabel")
    ArgsLabel.Size = UDim2.new(1, -16, 0, 14)
    ArgsLabel.Position = UDim2.new(0, 8, 0, 42)
    ArgsLabel.BackgroundTransparency = 1
    ArgsLabel.Text = "Args: " .. logEntry.Args
    ArgsLabel.TextColor3 = Color3.fromRGB(130, 130, 160)
    ArgsLabel.TextSize = 10
    ArgsLabel.Font = Enum.Font.Gotham
    ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgsLabel.TextTruncate = Enum.TextTruncate.AtEnd
    ArgsLabel.Parent = Card

    -- Copy button
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0, 45, 0, 18)
    CopyBtn.Position = UDim2.new(1, -55, 0, 5)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    CopyBtn.Text = "COPY"
    CopyBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    CopyBtn.TextSize = 10
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.BorderSizePixel = 0
    CopyBtn.Parent = Card
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 4)

    CopyBtn.MouseButton1Click:Connect(function()
        local code = string.format(
            'game:GetService("ReplicatedStorage").Remotes.%s:%s(%s)',
            logEntry.Remote,
            logEntry.Type,
            logEntry.Args
        )
        if setclipboard then
            setclipboard(code)
            CopyBtn.Text = "✓"
            task.wait(1)
            CopyBtn.Text = "COPY"
        end
    end)

    return Card
end

-- ═══════════════════ SETTINGS PAGE BUILDER ═══════════════════
local function BuildSettings()
    local settingsData = {
        {name = "Spy Enabled", key = "SpyEnabled", desc = "Bật/tắt hook remote"},
        {name = "Log All Remotes", key = "LogAllRemotes", desc = "Log tất cả remote (không chỉ title)"},
        {name = "Auto Refresh Titles", key = "AutoRefresh", desc = "Tự động refresh danh sách title"},
    }

    for i, setting in ipairs(settingsData) do
        local Row = Instance.new("Frame")
        Row.Size = UDim2.new(1, -20, 0, 45)
        Row.Position = UDim2.new(0, 10, 0, (i - 1) * 55 + 10)
        Row.BackgroundColor3 = Color3.fromRGB(30, 28, 48)
        Row.BorderSizePixel = 0
        Row.Parent = GUI.SettingsPage
        Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -80, 0, 20)
        Label.Position = UDim2.new(0, 12, 0, 4)
        Label.BackgroundTransparency = 1
        Label.Text = setting.name
        Label.TextColor3 = Color3.fromRGB(220, 200, 255)
        Label.TextSize = 13
        Label.Font = Enum.Font.GothamSemibold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Row

        local Desc = Instance.new("TextLabel")
        Desc.Size = UDim2.new(1, -80, 0, 14)
        Desc.Position = UDim2.new(0, 12, 0, 24)
        Desc.BackgroundTransparency = 1
        Desc.Text = setting.desc
        Desc.TextColor3 = Color3.fromRGB(100, 100, 130)
        Desc.TextSize = 10
        Desc.Font = Enum.Font.Gotham
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.Parent = Row

        local Toggle = Instance.new("TextButton")
        Toggle.Size = UDim2.new(0, 50, 0, 25)
        Toggle.Position = UDim2.new(1, -62, 0.5, -12)
        Toggle.BackgroundColor3 = Config[setting.key] 
            and Color3.fromRGB(60, 140, 60) 
            or Color3.fromRGB(140, 50, 50)
        Toggle.Text = Config[setting.key] and "ON" or "OFF"
        Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        Toggle.TextSize = 11
        Toggle.Font = Enum.Font.GothamBold
        Toggle.BorderSizePixel = 0
        Toggle.Parent = Row
        Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)

        Toggle.MouseButton1Click:Connect(function()
            Config[setting.key] = not Config[setting.key]
            TweenService:Create(Toggle, TweenInfo.new(0.2), {
                BackgroundColor3 = Config[setting.key] 
                    and Color3.fromRGB(60, 140, 60) 
                    or Color3.fromRGB(140, 50, 50)
            }):Play()
            Toggle.Text = Config[setting.key] and "ON" or "OFF"
        end)
    end

    -- Open Game Title UI Button
    local OpenTitleBtn = Instance.new("TextButton")
    OpenTitleBtn.Size = UDim2.new(1, -20, 0, 40)
    OpenTitleBtn.Position = UDim2.new(0, 10, 0, #settingsData * 55 + 20)
    OpenTitleBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 160)
    OpenTitleBtn.Text = "📋 MỞ TITLE GUI TRONG GAME"
    OpenTitleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    OpenTitleBtn.TextSize = 14
    OpenTitleBtn.Font = Enum.Font.GothamBold
    OpenTitleBtn.BorderSizePixel = 0
    OpenTitleBtn.Parent = GUI.SettingsPage
    Instance.new("UICorner", OpenTitleBtn).CornerRadius = UDim.new(0, 8)

    OpenTitleBtn.MouseButton1Click:Connect(function()
        pcall(function()
            CommF_:InvokeServer("getTitles")
            if playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Titles") then
                playerGui.Main.Titles.Visible = true
            end
        end)
        OpenTitleBtn.Text = "✓ ĐÃ MỞ!"
        task.wait(1.5)
        OpenTitleBtn.Text = "📋 MỞ TITLE GUI TRONG GAME"
    end)

    -- Clear Logs Button
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(1, -20, 0, 40)
    ClearBtn.Position = UDim2.new(0, 10, 0, #settingsData * 55 + 70)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    ClearBtn.Text = "🗑 XÓA REMOTE LOGS"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.TextSize = 14
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.BorderSizePixel = 0
    ClearBtn.Parent = GUI.SettingsPage
    Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 8)

    ClearBtn.MouseButton1Click:Connect(function()
        RemoteLogs = {}
        for _, child in pairs(GUI.SpyPage:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        ClearBtn.Text = "✓ ĐÃ XÓA!"
        task.wait(1)
        ClearBtn.Text = "🗑 XÓA REMOTE LOGS"
    end)
end

BuildSettings()

-- ═══════════════════ FETCH & DISPLAY TITLES ═══════════════════
local function RefreshTitles()
    -- Clear old cards
    for _, child in pairs(GUI.TitlesPage:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local success, titleData = pcall(function()
        return CommF_:InvokeServer("getTitles")
    end)

    if success and type(titleData) == "table" then
        TitleList = titleData
        local count = 0
        for titleName, titleInfo in pairs(titleData) do
            if type(titleName) == "string" and titleName ~= "" then
                CreateTitleCard(titleName, titleInfo, GUI.TitlesPage)
                count = count + 1
            end
        end
        GUI.TitlesPage.CanvasSize = UDim2.new(0, 0, 0, count * 54 + 10)
        GUI.StatusBar.Text = "🟢 Spy Active | " .. count .. " Titles | Current: " .. CurrentTitle
    else
        -- If server returns different format, try scanning GUI
        pcall(function()
            if playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Titles") then
                local titlesFrame = playerGui.Main.Titles
                local count = 0
                for _, child in pairs(titlesFrame:GetDescendants()) do
                    if (child:IsA("TextButton") or child:IsA("TextLabel")) and child.Text ~= "" then
                        local txt = child.Text
                        if not string.find(txt, "Title") and #txt > 2 and #txt < 60 then
                            if not TitleList[txt] then
                                TitleList[txt] = true
                                CreateTitleCard(txt, nil, GUI.TitlesPage)
                                count = count + 1
                            end
                        end
                    end
                end
                GUI.TitlesPage.CanvasSize = UDim2.new(0, 0, 0, count * 54 + 10)
            end
        end)

        -- Fallback message
        if #GUI.TitlesPage:GetChildren() <= 2 then
            local NoData = Instance.new("TextLabel")
            NoData.Size = UDim2.new(1, -10, 0, 80)
            NoData.BackgroundTransparency = 1
            NoData.Text = "⚠ Không lấy được danh sách title.\nHãy thử:\n1. Bấm 'MỞ TITLE GUI' ở Settings\n2. Equip 1 title trong game\n3. Quay lại đây và refresh"
            NoData.TextColor3 = Color3.fromRGB(200, 180, 100)
            NoData.TextSize = 12
            NoData.Font = Enum.Font.Gotham
            NoData.TextWrapped = true
            NoData.Parent = GUI.TitlesPage
        end
    end
end

-- Initial fetch
task.spawn(RefreshTitles)

-- ═══════════════════ REMOTE HOOKING (SPY) ═══════════════════
local oldNamecall
local connections = {}

local function StartSpy()
    if oldNamecall then return end -- Already hooked
    
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Config.SpyEnabled then
            if method == "FireServer" and self:IsA("RemoteEvent") then
                local isTitleRelated = IsTitleRelated(args)
                if Config.LogAllRemotes or isTitleRelated then
                    local entry = LogRemote(self.Name, "FireServer", args, nil)
                    
                    -- Update GUI on main thread
                    task.spawn(function()
                        if GUI.SpyPage then
                            CreateLogCard(entry, GUI.SpyPage)
                            local children = 0
                            for _, c in pairs(GUI.SpyPage:GetChildren()) do
                                if c:IsA("Frame") then children = children + 1 end
                            end
                            GUI.SpyPage.CanvasSize = UDim2.new(0, 0, 0, children * 63 + 10)
                        end
                    end)
                    
                    if isTitleRelated then
                        warn("[TitleSpy] 🔔 FireServer TITLE detected:", self.Name, SerializeArgs(args))
                    end
                end
                
            elseif method == "InvokeServer" and self:IsA("RemoteFunction") then
                local isTitleRelated = IsTitleRelated(args)
                if Config.LogAllRemotes or isTitleRelated then
                    local returnVal = oldNamecall(self, ...)
                    local entry = LogRemote(self.Name, "InvokeServer", args, returnVal)
                    
                    task.spawn(function()
                        if GUI.SpyPage then
                            CreateLogCard(entry, GUI.SpyPage)
                            local children = 0
                            for _, c in pairs(GUI.SpyPage:GetChildren()) do
                                if c:IsA("Frame") then children = children + 1 end
                            end
                            GUI.SpyPage.CanvasSize = UDim2.new(0, 0, 0, children * 63 + 10)
                        end
                    end)
                    
                    if isTitleRelated then
                        warn("[TitleSpy] 🔔 InvokeServer TITLE detected:", self.Name, SerializeArgs(args))
                    end
                    
                    return returnVal
                end
            end
        end
        
        return oldNamecall(self, ...)
    end))
    
    print("[TitleSpy] ✅ Remote hook đã kích hoạt!")
end

-- ═══════════════════ AUTO REFRESH LOOP ═══════════════════
task.spawn(function()
    while getgenv().TitleSpyRunning do
        task.wait(Config.RefreshInterval)
        if Config.AutoRefresh and getgenv().TitleSpyRunning then
            task.spawn(RefreshTitles)
        end
    end
end)

-- ═══════════════════ KEYBIND TOGGLE ═══════════════════
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        GUI.ScreenGui.Enabled = not GUI.ScreenGui.Enabled
    end
end)

-- ═══════════════════ SHUTDOWN HANDLER ═══════════════════
getgenv().TitleSpyShutdown = function()
    getgenv().TitleSpyRunning = false
    if oldNamecall then
        -- Restore original if possible
        pcall(function()
            hookmetamethod(game, "__namecall", oldNamecall)
        end)
    end
    if GUI.ScreenGui then
        GUI.ScreenGui:Destroy()
    end
    print("[TitleSpy] 🔴 Đã tắt.")
end

-- ═══════════════════ START ═══════════════════
StartSpy()
print("═══════════════════════════════════════")
print("  🔍 TITLE SPY & EQUIP - BLOX FRUITS")
print("  ✅ Đã khởi động thành công!")
print("  📌 Phím tắt: RightShift để ẩn/hiện")
print("  📌 Tab 1: Danh sách Title + Equip")
print("  📌 Tab 2: Remote Spy (log realtime)")
print("  📌 Tab 3: Settings")
print("═══════════════════════════════════════")
