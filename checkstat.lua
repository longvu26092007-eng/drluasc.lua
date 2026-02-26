-- ╔══════════════════════════════════════════════╗
-- ║        MY STATS - BLOX FRUITS               ║
-- ╚══════════════════════════════════════════════╝

local Players     = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Màu theo build
local BUILD_COLORS = {
    Fruit   = Color3.fromRGB(255, 100, 220),
    Sword   = Color3.fromRGB(100, 200, 255),
    Gun     = Color3.fromRGB(255, 200, 80),
    Melee   = Color3.fromRGB(255, 120, 80),
    Defense = Color3.fromRGB(120, 255, 120),
    Mixed   = Color3.fromRGB(180, 180, 255),
    Unknown = Color3.fromRGB(150, 150, 150),
}

local BUILD_ICONS = {
    Fruit   = "🍎 Fruit",
    Sword   = "⚔️ Sword",
    Gun     = "🔫 Gun",
    Melee   = "👊 Melee",
    Defense = "🛡️ Defense",
    Mixed   = "🔀 Mixed",
    Unknown = "❓ Unknown",
}

local function getStats()
    local s = { Melee=0, Defense=0, Sword=0, Gun=0, Fruit=0,
                Level=0, Points=0, Exp=0, Race="?", Beli=0,
                Fragments=0, Fruit_Name="None" }
    pcall(function()
        local D = LocalPlayer.Data
        s.Level     = D.Level.Value
        s.Points    = D.Points.Value
        s.Exp       = D.Exp.Value
        s.Race      = D.Race.Value
        s.Beli      = D.Beli.Value
        s.Fragments = D.Fragments.Value
        s.Fruit_Name = D.DevilFruit.Value ~= "" and D.DevilFruit.Value or "None"
        local S = D.Stats
        s.Melee   = S.Melee.Level.Value
        s.Defense = S.Defense.Level.Value
        s.Sword   = S.Sword.Level.Value
        s.Gun     = S.Gun.Level.Value
        s.Fruit   = S["Demon Fruit"].Level.Value
    end)
    return s
end

local function getBuild(s)
    local vals = { Fruit=s.Fruit, Sword=s.Sword, Gun=s.Gun, Melee=s.Melee, Defense=s.Defense }
    local top, topName, second = -1, "Unknown", -1
    for k, v in pairs(vals) do
        if v > top then second=top; topName=k; top=v
        elseif v > second then second=v end
    end
    if top == 0 then return "Unknown" end
    if (top - second) <= 50 and second > 0 then return "Mixed" end
    return topName
end

-- ===================== UI ===================== --
if game.CoreGui:FindFirstChild("MyStatsUI") then
    game.CoreGui.MyStatsUI:Destroy()
end

local SG = Instance.new("ScreenGui")
SG.Name = "MyStatsUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = game.CoreGui

-- Main frame
local F = Instance.new("Frame")
F.Size = UDim2.new(0, 280, 0, 370)
F.Position = UDim2.new(0, 20, 0.5, -185)
F.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
F.BorderSizePixel = 0
F.Parent = SG
Instance.new("UICorner", F).CornerRadius = UDim.new(0, 14)

-- Title bar
local TB = Instance.new("Frame")
TB.Size = UDim2.new(1, 0, 0, 42)
TB.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
TB.BorderSizePixel = 0
TB.Parent = F
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 14)
local TBfix = Instance.new("Frame")
TBfix.Size = UDim2.new(1, 0, 0, 14)
TBfix.Position = UDim2.new(0, 0, 1, -14)
TBfix.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
TBfix.BorderSizePixel = 0
TBfix.Parent = TB

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "📊 My Stats"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TB

-- Close button
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28)
Close.Position = UDim2.new(1, -35, 0.5, -14)
Close.BackgroundColor3 = Color3.fromRGB(210, 55, 55)
Close.Text = "✕"
Close.TextColor3 = Color3.fromRGB(255,255,255)
Close.TextSize = 13
Close.Font = Enum.Font.GothamBold
Close.BorderSizePixel = 0
Close.Parent = TB
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 7)
Close.MouseButton1Click:Connect(function() SG:Destroy() end)

-- Draggable
local dragging, dragInput, dragStart, startPos
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = i.Position; startPos = F.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
TB.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dragInput = i end
end)
game:GetService("UserInputService").InputChanged:Connect(function(i)
    if i == dragInput and dragging then
        local d = i.Position - dragStart
        F.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- Build badge
local BuildBadge = Instance.new("Frame")
BuildBadge.Size = UDim2.new(1, -20, 0, 36)
BuildBadge.Position = UDim2.new(0, 10, 0, 48)
BuildBadge.BackgroundColor3 = Color3.fromRGB(22, 22, 42)
BuildBadge.BorderSizePixel = 0
BuildBadge.Parent = F
Instance.new("UICorner", BuildBadge).CornerRadius = UDim.new(0, 10)

local BuildLabel = Instance.new("TextLabel")
BuildLabel.Size = UDim2.new(1, 0, 1, 0)
BuildLabel.BackgroundTransparency = 1
BuildLabel.Text = "Build: ..."
BuildLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BuildLabel.TextSize = 15
BuildLabel.Font = Enum.Font.GothamBold
BuildLabel.Parent = BuildBadge

-- Info bar (Level, Race, Beli, Fragments)
local function makeInfo(parent, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(160, 160, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local InfoLevel = makeInfo(F, 90)
local InfoRace  = makeInfo(F, 107)
local InfoBeli  = makeInfo(F, 124)
local InfoFrag  = makeInfo(F, 141)

-- Divider
local Div = Instance.new("Frame")
Div.Size = UDim2.new(1, -20, 0, 1)
Div.Position = UDim2.new(0, 10, 0, 161)
Div.BackgroundColor3 = Color3.fromRGB(45, 45, 75)
Div.BorderSizePixel = 0
Div.Parent = F

-- Stat bars
local STAT_LIST = {
    {"🍎 Fruit",   "Fruit",   BUILD_COLORS.Fruit},
    {"⚔️ Sword",   "Sword",   BUILD_COLORS.Sword},
    {"🔫 Gun",     "Gun",     BUILD_COLORS.Gun},
    {"👊 Melee",   "Melee",   BUILD_COLORS.Melee},
    {"🛡️ Defense", "Defense", BUILD_COLORS.Defense},
}

local statBars = {}
local statLabels = {}

for i, st in ipairs(STAT_LIST) do
    local y = 168 + (i-1) * 36

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 14)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = st[1] .. ": 0"
    lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = F
    statLabels[st[2]] = lbl

    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, -20, 0, 12)
    barBG.Position = UDim2.new(0, 10, 0, y + 16)
    barBG.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    barBG.BorderSizePixel = 0
    barBG.Parent = F
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(0, 6)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = st[3]
    fill.BackgroundTransparency = 0.15
    fill.BorderSizePixel = 0
    fill.Parent = barBG
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 6)
    statBars[st[2]] = fill
end

-- Points còn lại
local PointsLabel = Instance.new("TextLabel")
PointsLabel.Size = UDim2.new(1, -20, 0, 20)
PointsLabel.Position = UDim2.new(0, 10, 0, 350)
PointsLabel.BackgroundTransparency = 1
PointsLabel.Text = "Điểm stat chưa dùng: 0"
PointsLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
PointsLabel.TextSize = 12
PointsLabel.Font = Enum.Font.GothamSemibold
PointsLabel.TextXAlignment = Enum.TextXAlignment.Left
PointsLabel.Parent = F

-- ===== Update function ===== --
local function updateStats()
    local s = getStats()
    local build = getBuild(s)
    local bColor = BUILD_COLORS[build]

    -- Build badge
    BuildBadge.BackgroundColor3 = Color3.fromRGB(
        math.floor(bColor.R*255*0.3), math.floor(bColor.G*255*0.3), math.floor(bColor.B*255*0.3))
    BuildLabel.Text = "Build chính: " .. (BUILD_ICONS[build] or "?")
    BuildLabel.TextColor3 = bColor

    -- Info
    InfoLevel.Text = string.format("⚡ Level: %d   |   EXP: %d", s.Level, s.Exp)
    InfoRace.Text  = string.format("🧬 Race: %s   |   Trái: %s", s.Race, s.Fruit_Name)
    InfoBeli.Text  = string.format("💰 Beli: %s", tostring(s.Beli))
    InfoFrag.Text  = string.format("🔮 Fragments: %s", tostring(s.Fragments))

    -- Stat bars
    local maxVal = math.max(s.Fruit, s.Sword, s.Gun, s.Melee, s.Defense, 1)
    local dataMap = { Fruit=s.Fruit, Sword=s.Sword, Gun=s.Gun, Melee=s.Melee, Defense=s.Defense }

    for k, val in pairs(dataMap) do
        statLabels[k].Text = ({
            Fruit="🍎 Fruit", Sword="⚔️ Sword", Gun="🔫 Gun",
            Melee="👊 Melee", Defense="🛡️ Defense"
        })[k] .. ": " .. val

        local ratio = val / maxVal
        TweenService:Create(statBars[k], TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
            Size = UDim2.new(ratio, 0, 1, 0)
        }):Play()
    end

    PointsLabel.Text = "Điểm stat chưa dùng: " .. s.Points
end

-- Auto update mỗi 3 giây
task.spawn(function()
    while SG.Parent do
        updateStats()
        task.wait(3)
    end
end)
