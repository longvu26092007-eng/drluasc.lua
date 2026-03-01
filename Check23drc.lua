--[[
    🐉 DRACO CHECKER - BLOX FRUITS
    Auto check Draco V2/V3 mỗi 30s
    Khi có Draco V3 → tạo file PlayerName.txt
]]

if getgenv().TC then pcall(getgenv().TC) end

local player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local playerGui = player:WaitForChild("PlayerGui")

local CheckList = {
    {t = "Unlock Draco V2.", v = 2},
    {t = "Unlock Draco V3.", v = 3},
}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DracoChecker"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 120)
main.Position = UDim2.new(0.5, -130, 0, 10)
main.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(200, 100, 30)
Instance.new("UIStroke", main).Thickness = 2

-- Bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 30)
bar.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local fix = Instance.new("Frame")
fix.Size = UDim2.new(1, 0, 0, 10)
fix.Position = UDim2.new(0, 0, 1, -10)
fix.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
fix.BorderSizePixel = 0
fix.Parent = bar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🐉 DRACO CHECKER"
titleLabel.TextColor3 = Color3.fromRGB(220, 130, 40)
titleLabel.TextSize = 12
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = bar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -26, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

-- Rows
local function MakeRow(yPos, text)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -16, 0, 28)
    row.Position = UDim2.new(0, 8, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(28, 24, 38)
    row.BorderSizePixel = 0
    row.Parent = main
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", row).Color = Color3.fromRGB(45, 40, 60)

    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 22, 0, 22)
    icon.Position = UDim2.new(0, 3, 0.5, -11)
    icon.BackgroundColor3 = Color3.fromRGB(110, 35, 35)
    icon.Text = "✗"
    icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    icon.TextSize = 14
    icon.Font = Enum.Font.GothamBold
    icon.Parent = row
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)

    local nm = Instance.new("TextLabel")
    nm.Name = "Label"
    nm.Size = UDim2.new(1, -80, 1, 0)
    nm.Position = UDim2.new(0, 30, 0, 0)
    nm.BackgroundTransparency = 1
    nm.Text = text
    nm.TextColor3 = Color3.fromRGB(180, 175, 200)
    nm.TextSize = 11
    nm.Font = Enum.Font.GothamSemibold
    nm.TextXAlignment = Enum.TextXAlignment.Left
    nm.Parent = row

    local badge = Instance.new("TextLabel")
    badge.Name = "Badge"
    badge.Size = UDim2.new(0, 45, 0, 16)
    badge.Position = UDim2.new(1, -50, 0.5, -8)
    badge.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
    badge.Text = "CHƯA"
    badge.TextColor3 = Color3.fromRGB(255, 140, 140)
    badge.TextSize = 9
    badge.Font = Enum.Font.GothamBold
    badge.Parent = row
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

    return row
end

local rowV2 = MakeRow(34, "Unlock Draco V2.")
local rowV3 = MakeRow(66, "Unlock Draco V3.")

-- Timer label
local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0, 16)
timerLabel.Position = UDim2.new(0, 0, 1, -16)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "⏳ Next scan: 30s"
timerLabel.TextColor3 = Color3.fromRGB(100, 95, 130)
timerLabel.TextSize = 9
timerLabel.Font = Enum.Font.Gotham
timerLabel.Parent = main

-- Update row UI
local function SetRow(row, ok)
    local icon = row:FindFirstChild("Icon")
    local label = row:FindFirstChild("Label")
    local badge = row:FindFirstChild("Badge")

    if ok then
        row.BackgroundColor3 = Color3.fromRGB(18, 32, 18)
        row:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(50, 130, 50)
        icon.BackgroundColor3 = Color3.fromRGB(35, 110, 35)
        icon.Text = "✓"
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        badge.BackgroundColor3 = Color3.fromRGB(35, 100, 35)
        badge.Text = "ĐÃ CÓ"
        badge.TextColor3 = Color3.fromRGB(140, 255, 140)
    else
        row.BackgroundColor3 = Color3.fromRGB(28, 24, 38)
        row:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(45, 40, 60)
        icon.BackgroundColor3 = Color3.fromRGB(110, 35, 35)
        icon.Text = "✗"
        label.TextColor3 = Color3.fromRGB(180, 175, 200)
        badge.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
        badge.Text = "CHƯA"
        badge.TextColor3 = Color3.fromRGB(255, 140, 140)
    end
end

-- Save file
local dracoV3Done = false

local function SaveFile()
    if dracoV3Done then return end
    dracoV3Done = true
    local fileName = player.Name .. ".txt"
    pcall(function()
        writefile(fileName, "Completed-draco3")
    end)
    print("✅ Đã lưu file: " .. fileName .. " → Completed-draco3")
end

-- Scan
local function DoScan()
    -- Mở bảng Titles
    pcall(function()
        local CommF_ = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
        CommF_:InvokeServer("getTitles")
    end)
    pcall(function()
        local m = playerGui:FindFirstChild("Main")
        if m and m:FindFirstChild("Titles") then m.Titles.Visible = true end
    end)

    task.wait(1)

    -- Scan text
    local foundTexts = {}
    pcall(function()
        local m = playerGui:FindFirstChild("Main")
        if m then
            local tf = m:FindFirstChild("Titles")
            if tf then
                for _, d in pairs(tf:GetDescendants()) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
                        foundTexts[d.Text] = true
                    end
                end
            end
        end
    end)

    -- Đóng bảng Titles
    pcall(function()
        local m = playerGui:FindFirstChild("Main")
        if m and m:FindFirstChild("Titles") then m.Titles.Visible = false end
    end)

    -- Check
    for _, item in ipairs(CheckList) do
        local ok = foundTexts[item.t] or false
        if not ok then ok = foundTexts[item.t:sub(1, -2)] or false end
        if not ok then
            for txt, _ in pairs(foundTexts) do
                if txt:find(item.t, 1, true) or txt:find(item.t:sub(1, -2), 1, true) then
                    ok = true
                    break
                end
            end
        end

        if item.v == 2 then SetRow(rowV2, ok) end
        if item.v == 3 then
            SetRow(rowV3, ok)
            if ok then SaveFile() end
        end
    end
end

-- Auto loop 30s
local running = true

task.spawn(function()
    while running do
        DoScan()
        for i = 30, 1, -1 do
            if not running then return end
            timerLabel.Text = "⏳ Next scan: " .. i .. "s"
            task.wait(1)
        end
    end
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    running = false
    getgenv().TC = nil
    gui:Destroy()
end)
getgenv().TC = function() running = false; pcall(function() gui:Destroy() end) end

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

print("🐉 Draco Checker | Auto scan 30s | RightShift = ẩn/hiện")
