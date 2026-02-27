--[[
    ╔══════════════════════════════════════════════════════════╗
    ║          TITLE CHECKER - BLOX FRUITS                    ║
    ║    Check danh hiệu Race V2/V3 đã unlock hay chưa       ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ═══════════ ANTI DUPLICATE ═══════════
if getgenv().TitleCheckerRunning then
    if getgenv().TitleCheckerShutdown then
        pcall(getgenv().TitleCheckerShutdown)
    end
    task.wait(0.3)
end
getgenv().TitleCheckerRunning = true

-- ═══════════ SERVICES ═══════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ═══════════ TITLE DATA ═══════════
local TitleData = {
    -- V2 TITLES
    {name = "The Unleashed",     requirement = "Human V2",  race = "Human",  version = 2, order = 1},
    {name = "Unmatched Speed",   requirement = "Rabbit V2", race = "Rabbit", version = 2, order = 2},
    {name = "Sea Monster",       requirement = "Shark V2",  race = "Shark",  version = 2, order = 3},
    {name = "Sacred Warrior",    requirement = "Angel V2",  race = "Angel",  version = 2, order = 4},
    {name = "The Ghoul",         requirement = "Ghoul V2",  race = "Ghoul",  version = 2, order = 5},
    {name = "The Cyborg",        requirement = "Cyborg V2", race = "Cyborg", version = 2, order = 6},
    {name = "Elder Wyrm",        requirement = "Draco V2",  race = "Draco",  version = 2, order = 7},
    -- V3 TITLES
    {name = "Full Power",        requirement = "Human V3",  race = "Human",  version = 3, order = 8},
    {name = "Godspeed",          requirement = "Rabbit V3", race = "Rabbit", version = 3, order = 9},
    {name = "Warrior of the Sea",requirement = "Shark V3",  race = "Shark",  version = 3, order = 10},
    {name = "Perfect Being",     requirement = "Angel V3",  race = "Angel",  version = 3, order = 11},
    {name = "Hell Hound",        requirement = "Ghoul V3",  race = "Ghoul",  version = 3, order = 12},
    {name = "War Machine",       requirement = "Cyborg V3", race = "Cyborg", version = 3, order = 13},
    {name = "Ancient Flame",     requirement = "Draco V3",  race = "Draco",  version = 3, order = 14},
}

-- ═══════════ CHECK FUNCTIONS ═══════════
local function GetPlayerTitles()
    local unlocked = {}
    
    -- Method 1: InvokeServer getTitles
    pcall(function()
        local Remotes = RS:WaitForChild("Remotes", 5)
        local CommF_ = Remotes and Remotes:FindFirstChild("CommF_")
        if CommF_ then
            local result = CommF_:InvokeServer("getTitles")
            if type(result) == "table" then
                for titleName, _ in pairs(result) do
                    unlocked[tostring(titleName)] = true
                end
            end
        end
    end)

    -- Method 2: Scan GUI Titles frame
    pcall(function()
        local mainGui = playerGui:FindFirstChild("Main")
        if mainGui then
            local titlesFrame = mainGui:FindFirstChild("Titles")
            if titlesFrame then
                for _, desc in pairs(titlesFrame:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                        local txt = desc.Text or ""
                        if #txt > 2 then
                            for _, td in pairs(TitleData) do
                                if txt == td.name then
                                    unlocked[td.name] = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Method 3: Check player race data trực tiếp
    pcall(function()
        local plrData = player:FindFirstChild("Data") or player:FindFirstChild("PlayerData")
        if plrData then
            for _, child in pairs(plrData:GetChildren()) do
                local n = string.lower(child.Name)
                if string.find(n, "race") or string.find(n, "title") then
                    local val = child.Value
                    if type(val) == "string" then
                        unlocked[val] = true
                    end
                end
            end
        end
    end)

    -- Method 4: Scan leaderstats / hidden values
    pcall(function()
        for _, folder in pairs(player:GetChildren()) do
            if folder:IsA("Folder") or folder:IsA("Configuration") then
                for _, child in pairs(folder:GetDescendants()) do
                    if child:IsA("StringValue") or child:IsA("BoolValue") then
                        local n = string.lower(child.Name)
                        for _, td in pairs(TitleData) do
                            local raceLower = string.lower(td.race)
                            if string.find(n, raceLower) then
                                if child:IsA("BoolValue") and child.Value then
                                    -- Tìm version
                                    local verName = child.Name
                                    if string.find(verName, tostring(td.version)) or string.find(verName, "V"..td.version) then
                                        unlocked[td.name] = true
                                    end
                                elseif child:IsA("StringValue") then
                                    local v = child.Value
                                    if string.find(v, tostring(td.version)) then
                                        unlocked[td.name] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Method 5: Check _G hoặc shared data
    pcall(function()
        if _G.Titles then
            for k, v in pairs(_G.Titles) do
                unlocked[tostring(k)] = true
            end
        end
    end)

    return unlocked
end

-- ═══════════ GUI ═══════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TitleCheckerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then
    ScreenGui.Parent = playerGui
end

-- Main frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 380, 0, 540)
Main.Position = UDim2.new(0.5, -190, 0.5, -270)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 10)
mc.Parent = Main

local ms = Instance.new("UIStroke")
ms.Color = Color3.fromRGB(200, 170, 50)
ms.Thickness = 2
ms.Parent = Main

-- Title bar
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1, 0, 0, 44)
TBar.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
TBar.BorderSizePixel = 0
TBar.Parent = Main
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 10)

local TBarFix = Instance.new("Frame")
TBarFix.Size = UDim2.new(1, 0, 0, 10)
TBarFix.Position = UDim2.new(0, 0, 1, -10)
TBarFix.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
TBarFix.BorderSizePixel = 0
TBarFix.Parent = TBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🏆 TITLE CHECKER"
Title.TextColor3 = Color3.fromRGB(220, 190, 60)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TBar

-- Status counter
local Counter = Instance.new("TextLabel")
Counter.Size = UDim2.new(1, -16, 0, 20)
Counter.Position = UDim2.new(0, 8, 0, 46)
Counter.BackgroundTransparency = 1
Counter.Text = "⏳ Đang kiểm tra..."
Counter.TextColor3 = Color3.fromRGB(160, 155, 180)
Counter.TextSize = 12
Counter.Font = Enum.Font.GothamSemibold
Counter.TextXAlignment = Enum.TextXAlignment.Left
Counter.Parent = Main

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Min button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -72, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(55, 50, 80)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- ═══════════ SECTION HEADERS + LIST ═══════════
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -16, 1, -110)
ScrollFrame.Position = UDim2.new(0, 8, 0, 68)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 170, 50)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = Main
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 8)

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 3)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = ScrollFrame

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 6)
Padding.PaddingLeft = UDim.new(0, 6)
Padding.PaddingRight = UDim.new(0, 6)
Padding.Parent = ScrollFrame

-- Refresh button
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, -16, 0, 36)
RefreshBtn.Position = UDim2.new(0, 8, 1, -42)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(200, 170, 50)
RefreshBtn.Text = "🔄 REFRESH / KIỂM TRA LẠI"
RefreshBtn.TextColor3 = Color3.fromRGB(15, 15, 22)
RefreshBtn.TextSize = 13
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Parent = Main
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 8)

-- ═══════════ BUILD FUNCTIONS ═══════════
local function CreateSectionHeader(text, layoutOrder, parent)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -4, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    header.BorderSizePixel = 0
    header.LayoutOrder = layoutOrder
    header.Parent = parent
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 170, 50)
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header

    return header
end

local function CreateTitleRow(titleInfo, isUnlocked, layoutOrder, parent)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 44)
    row.BackgroundColor3 = isUnlocked and Color3.fromRGB(20, 35, 20) or Color3.fromRGB(25, 22, 35)
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = isUnlocked and Color3.fromRGB(50, 140, 50) or Color3.fromRGB(50, 45, 65)
    stroke.Thickness = 1
    stroke.Parent = row

    -- Status icon (✓ hoặc ✗)
    local statusIcon = Instance.new("TextLabel")
    statusIcon.Size = UDim2.new(0, 36, 0, 36)
    statusIcon.Position = UDim2.new(0, 4, 0.5, -18)
    statusIcon.BackgroundColor3 = isUnlocked and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
    statusIcon.Text = isUnlocked and "✓" or "✗"
    statusIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusIcon.TextSize = 18
    statusIcon.Font = Enum.Font.GothamBold
    statusIcon.Parent = row
    Instance.new("UICorner", statusIcon).CornerRadius = UDim.new(0, 8)

    -- Title name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 170, 0, 20)
    nameLabel.Position = UDim2.new(0, 46, 0, 3)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = titleInfo.name
    nameLabel.TextColor3 = isUnlocked and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 190, 220)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = row

    -- Requirement
    local reqLabel = Instance.new("TextLabel")
    reqLabel.Size = UDim2.new(0, 170, 0, 16)
    reqLabel.Position = UDim2.new(0, 46, 0, 24)
    reqLabel.BackgroundTransparency = 1
    reqLabel.Text = "Unlock " .. titleInfo.requirement
    reqLabel.TextColor3 = isUnlocked and Color3.fromRGB(70, 170, 70) or Color3.fromRGB(130, 125, 150)
    reqLabel.TextSize = 10
    reqLabel.Font = Enum.Font.Gotham
    reqLabel.TextXAlignment = Enum.TextXAlignment.Left
    reqLabel.Parent = row

    -- Race badge
    local raceBadge = Instance.new("TextLabel")
    raceBadge.Size = UDim2.new(0, 60, 0, 20)
    raceBadge.Position = UDim2.new(1, -70, 0.5, -10)
    raceBadge.BackgroundColor3 = isUnlocked and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(55, 50, 75)
    raceBadge.Text = titleInfo.race
    raceBadge.TextColor3 = isUnlocked and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(160, 155, 180)
    raceBadge.TextSize = 10
    raceBadge.Font = Enum.Font.GothamSemibold
    raceBadge.Parent = row
    Instance.new("UICorner", raceBadge).CornerRadius = UDim.new(0, 5)

    return row
end

-- ═══════════ RENDER LIST ═══════════
local function RenderList()
    -- Clear
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Get unlocked titles
    local unlocked = GetPlayerTitles()

    local unlockedCount = 0
    local totalCount = #TitleData

    -- V2 Section
    CreateSectionHeader("⚔ RACE V2 TITLES", 0, ScrollFrame)

    for _, td in pairs(TitleData) do
        if td.version == 2 then
            local has = unlocked[td.name] or false
            if has then unlockedCount = unlockedCount + 1 end
            CreateTitleRow(td, has, td.order, ScrollFrame)
        end
    end

    -- V3 Section
    CreateSectionHeader("👑 RACE V3 TITLES", 7.5, ScrollFrame)

    for _, td in pairs(TitleData) do
        if td.version == 3 then
            local has = unlocked[td.name] or false
            if has then unlockedCount = unlockedCount + 1 end
            CreateTitleRow(td, has, td.order, ScrollFrame)
        end
    end

    -- Update counter
    local pct = math.floor((unlockedCount / totalCount) * 100)
    Counter.Text = "✅ " .. unlockedCount .. "/" .. totalCount .. " titles (" .. pct .. "%)   |   "
    
    if unlockedCount == totalCount then
        Counter.Text = Counter.Text .. "🎉 FULL TITLES!"
        Counter.TextColor3 = Color3.fromRGB(100, 255, 100)
    elseif unlockedCount == 0 then
        Counter.Text = Counter.Text .. "💡 Bấm Refresh sau khi mở Title game"
        Counter.TextColor3 = Color3.fromRGB(200, 170, 80)
    else
        Counter.Text = Counter.Text .. "Còn " .. (totalCount - unlockedCount) .. " titles chưa có"
        Counter.TextColor3 = Color3.fromRGB(160, 155, 180)
    end

    -- Progress bar
    local existingBar = Main:FindFirstChild("ProgressBar")
    if existingBar then existingBar:Destroy() end

    local barBg = Instance.new("Frame")
    barBg.Name = "ProgressBar"
    barBg.Size = UDim2.new(1, -16, 0, 6)
    barBg.Position = UDim2.new(0, 8, 0, 62)
    barBg.BackgroundColor3 = Color3.fromRGB(35, 32, 50)
    barBg.BorderSizePixel = 0
    barBg.Parent = Main
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = unlockedCount == totalCount 
        and Color3.fromRGB(80, 220, 80) 
        or Color3.fromRGB(200, 170, 50)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

    -- Animate fill
    TweenService:Create(barFill, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(unlockedCount / totalCount, 0, 1, 0)
    }):Play()

    -- Update canvas size
    task.wait()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 12)
end

-- ═══════════ BUTTON EVENTS ═══════════
RefreshBtn.MouseButton1Click:Connect(function()
    RefreshBtn.Text = "⏳ Đang kiểm tra..."
    Counter.Text = "⏳ Đang kiểm tra..."
    
    -- Mở title GUI game trước để load data
    pcall(function()
        local Remotes = RS:FindFirstChild("Remotes")
        local CommF_ = Remotes and Remotes:FindFirstChild("CommF_")
        if CommF_ then
            CommF_:InvokeServer("getTitles")
        end
        local m = playerGui:FindFirstChild("Main")
        if m and m:FindFirstChild("Titles") then
            m.Titles.Visible = true
        end
    end)
    
    task.wait(0.8)
    RenderList()
    
    RefreshBtn.Text = "🔄 REFRESH / KIỂM TRA LẠI"
end)

RefreshBtn.MouseEnter:Connect(function()
    TweenService:Create(RefreshBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(230, 200, 70)
    }):Play()
end)
RefreshBtn.MouseLeave:Connect(function()
    TweenService:Create(RefreshBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(200, 170, 50)
    }):Play()
end)

-- Minimize
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, 380, 0, 44) or UDim2.new(0, 380, 0, 540)
    }):Play()
    MinBtn.Text = minimized and "+" or "-"
    ScrollFrame.Visible = not minimized
    RefreshBtn.Visible = not minimized
    Counter.Visible = not minimized
end)

-- Close
CloseBtn.MouseButton1Click:Connect(function()
    getgenv().TitleCheckerRunning = false
    ScreenGui:Destroy()
end)

-- Keybind RightShift
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Shutdown
getgenv().TitleCheckerShutdown = function()
    getgenv().TitleCheckerRunning = false
    pcall(function() ScreenGui:Destroy() end)
end

-- ═══════════ INIT ═══════════
task.spawn(function()
    task.wait(0.5)
    RenderList()
end)

print("═══════════════════════════════════")
print("  🏆 TITLE CHECKER - Blox Fruits")
print("  ✅ Loaded! RightShift = ẩn/hiện")
print("═══════════════════════════════════")
