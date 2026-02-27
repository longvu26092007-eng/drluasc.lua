--[[
    🏆 TITLE CHECKER - BLOX FRUITS
    Check 14 danh hiệu Race V2/V3
]]

if getgenv().TC then pcall(getgenv().TC) end

local player = game:GetService("Players").LocalPlayer
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CommF_ = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")

-- 14 title cần check
local Titles = {
    {n="The Unleashed",      r="Unlock Human V2",  v=2},
    {n="Unmatched Speed",    r="Unlock Rabbit V2", v=2},
    {n="Sea Monster",        r="Unlock Shark V2",  v=2},
    {n="Sacred Warrior",     r="Unlock Angel V2",  v=2},
    {n="The Ghoul",          r="Unlock Ghoul V2",  v=2},
    {n="The Cyborg",         r="Unlock Cyborg V2", v=2},
    {n="Elder Wyrm",         r="Unlock Draco V2",  v=2},
    {n="Full Power",         r="Unlock Human V3",  v=3},
    {n="Godspeed",           r="Unlock Rabbit V3", v=3},
    {n="Warrior of the Sea", r="Unlock Shark V3",  v=3},
    {n="Perfect Being",      r="Unlock Angel V3",  v=3},
    {n="Hell Hound",         r="Unlock Ghoul V3",  v=3},
    {n="War Machine",        r="Unlock Cyborg V3", v=3},
    {n="Ancient Flame",      r="Unlock Draco V3",  v=3},
}

-- Lấy danh sách title từ server (giống Spy V2)
local owned = {}
pcall(function()
    local result = CommF_:InvokeServer("getTitles")
    if type(result) == "table" then
        for k, _ in pairs(result) do
            owned[tostring(k)] = true
        end
    end
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TC"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player.PlayerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 0)
main.Position = UDim2.new(0.5, -170, 0.5, -240)
main.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local mStroke = Instance.new("UIStroke", main)
mStroke.Color = Color3.fromRGB(200, 170, 50)
mStroke.Thickness = 2

-- Title bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 38)
bar.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local barFix = Instance.new("Frame")
barFix.Size = UDim2.new(1, 0, 0, 10)
barFix.Position = UDim2.new(0, 0, 1, -10)
barFix.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
barFix.BorderSizePixel = 0
barFix.Parent = bar

-- Count
local has = 0
for _, t in pairs(Titles) do if owned[t.n] then has = has + 1 end end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🏆 RACE TITLES  " .. has .. "/14"
title.TextColor3 = Color3.fromRGB(220, 190, 60)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Progress bar
local pBar = Instance.new("Frame")
pBar.Size = UDim2.new(1, -16, 0, 5)
pBar.Position = UDim2.new(0, 8, 0, 40)
pBar.BackgroundColor3 = Color3.fromRGB(35, 32, 50)
pBar.BorderSizePixel = 0
pBar.Parent = main
Instance.new("UICorner", pBar).CornerRadius = UDim.new(1, 0)

local pFill = Instance.new("Frame")
pFill.Size = UDim2.new(has / 14, 0, 1, 0)
pFill.BackgroundColor3 = has == 14 and Color3.fromRGB(80, 220, 80) or Color3.fromRGB(200, 170, 50)
pFill.BorderSizePixel = 0
pFill.Parent = pBar
Instance.new("UICorner", pFill).CornerRadius = UDim.new(1, 0)

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -55)
scroll.Position = UDim2.new(0, 6, 0, 49)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 170, 50)
scroll.Parent = main

local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 3)
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Parent = scroll

-- Build rows
local function Header(text, order)
    local h = Instance.new("TextLabel")
    h.Size = UDim2.new(1, -6, 0, 24)
    h.BackgroundColor3 = Color3.fromRGB(30, 28, 48)
    h.Text = "  " .. text
    h.TextColor3 = Color3.fromRGB(200, 170, 50)
    h.TextSize = 12
    h.Font = Enum.Font.GothamBold
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.BorderSizePixel = 0
    h.LayoutOrder = order
    h.Parent = scroll
    Instance.new("UICorner", h).CornerRadius = UDim.new(0, 6)
end

local function Row(info, order)
    local ok = owned[info.n] or false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -6, 0, 36)
    row.BackgroundColor3 = ok and Color3.fromRGB(18, 32, 18) or Color3.fromRGB(28, 24, 38)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 7)
    local s = Instance.new("UIStroke", row)
    s.Color = ok and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(50, 42, 65)
    s.Thickness = 1

    -- ✓ or ✗
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 28, 0, 28)
    icon.Position = UDim2.new(0, 4, 0.5, -14)
    icon.BackgroundColor3 = ok and Color3.fromRGB(35, 110, 35) or Color3.fromRGB(110, 35, 35)
    icon.Text = ok and "✓" or "✗"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextSize = 16
    icon.Font = Enum.Font.GothamBold
    icon.Parent = row
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 7)

    -- Name
    local nm = Instance.new("TextLabel")
    nm.Size = UDim2.new(1, -120, 0, 18)
    nm.Position = UDim2.new(0, 38, 0, 1)
    nm.BackgroundTransparency = 1
    nm.Text = info.n
    nm.TextColor3 = ok and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(190, 185, 210)
    nm.TextSize = 12
    nm.Font = Enum.Font.GothamBold
    nm.TextXAlignment = Enum.TextXAlignment.Left
    nm.Parent = row

    -- Requirement
    local rq = Instance.new("TextLabel")
    rq.Size = UDim2.new(1, -120, 0, 14)
    rq.Position = UDim2.new(0, 38, 0, 19)
    rq.BackgroundTransparency = 1
    rq.Text = info.r
    rq.TextColor3 = ok and Color3.fromRGB(60, 150, 60) or Color3.fromRGB(110, 105, 130)
    rq.TextSize = 10
    rq.Font = Enum.Font.Gotham
    rq.TextXAlignment = Enum.TextXAlignment.Left
    rq.Parent = row

    -- Status
    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(0, 55, 0, 20)
    st.Position = UDim2.new(1, -62, 0.5, -10)
    st.BackgroundColor3 = ok and Color3.fromRGB(35, 100, 35) or Color3.fromRGB(70, 35, 35)
    st.Text = ok and "ĐÃ CÓ" or "CHƯA"
    st.TextColor3 = ok and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 140, 140)
    st.TextSize = 10
    st.Font = Enum.Font.GothamBold
    st.Parent = row
    Instance.new("UICorner", st).CornerRadius = UDim.new(0, 5)
end

-- Render
Header("⚔ RACE V2", 0)
local ord = 1
for _, t in pairs(Titles) do
    if t.v == 2 then Row(t, ord); ord = ord + 1 end
end
Header("👑 RACE V3", ord)
ord = ord + 1
for _, t in pairs(Titles) do
    if t.v == 3 then Row(t, ord); ord = ord + 1 end
end

-- Canvas
task.wait()
scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8)

-- Animate open
main.Size = UDim2.new(0, 340, 0, 38)
TS:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 340, 0, 480)
}):Play()

-- Close + keybind
closeBtn.MouseButton1Click:Connect(function()
    getgenv().TC = nil; gui:Destroy()
end)
getgenv().TC = function() pcall(function() gui:Destroy() end) end

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

print("🏆 Title Checker | "..has.."/14 | RightShift = ẩn/hiện")
