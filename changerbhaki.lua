--[[
    🌈 RAINBOW SAVIOUR CHECKER
    Auto check Rainbow Haki mỗi 30s
    Khi có Rainbow Haki → tạo file PlayerName.txt
]]

if getgenv().TC then pcall(getgenv().TC) end

local player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local playerGui = player:WaitForChild("PlayerGui")

-- Mục tiêu quét mới
local TargetTitle = "Unlock Rainbow Saviour aura color."

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RainbowChecker"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 90) -- Thu nhỏ lại vì chỉ check 1 dòng
main.Position = UDim2.new(0.5, -130, 0, 10)
main.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(200, 100, 200) -- Đổi sang màu tím/hồng cho hợp Haki
Instance.new("UIStroke", main).Thickness = 2

-- Bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 30)
bar.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🌈 RAINBOW SAVIOUR CHECKER"
titleLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
titleLabel.TextSize = 10
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

-- Row hiển thị
local row = Instance.new("Frame")
row.Size = UDim2.new(1, -16, 0, 28)
row.Position = UDim2.new(0, 8, 0, 34)
row.BackgroundColor3 = Color3.fromRGB(28, 24, 38)
row.BorderSizePixel = 0
row.Parent = main
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
local rowStroke = Instance.new("UIStroke", row)
rowStroke.Color = Color3.fromRGB(45, 40, 60)

local icon = Instance.new("TextLabel")
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
nm.Size = UDim2.new(1, -80, 1, 0)
nm.Position = UDim2.new(0, 30, 0, 0)
nm.BackgroundTransparency = 1
nm.Text = "Rainbow Saviour Haki"
nm.TextColor3 = Color3.fromRGB(180, 175, 200)
nm.TextSize = 11
nm.Font = Enum.Font.GothamSemibold
nm.TextXAlignment = Enum.TextXAlignment.Left
nm.Parent = row

local badge = Instance.new("TextLabel")
badge.Size = UDim2.new(0, 45, 0, 16)
badge.Position = UDim2.new(1, -50, 0.5, -8)
badge.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
badge.Text = "CHƯA"
badge.TextColor3 = Color3.fromRGB(255, 140, 140)
badge.TextSize = 9
badge.Font = Enum.Font.GothamBold
badge.Parent = row
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

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

-- Update UI
local function SetStatus(ok)
    if ok then
        row.BackgroundColor3 = Color3.fromRGB(18, 32, 18)
        rowStroke.Color = Color3.fromRGB(50, 130, 50)
        icon.BackgroundColor3 = Color3.fromRGB(35, 110, 35)
        icon.Text = "✓"
        nm.TextColor3 = Color3.fromRGB(100, 255, 100)
        badge.BackgroundColor3 = Color3.fromRGB(35, 100, 35)
        badge.Text = "ĐÃ CÓ"
        badge.TextColor3 = Color3.fromRGB(140, 255, 140)
    else
        row.BackgroundColor3 = Color3.fromRGB(28, 24, 38)
        rowStroke.Color = Color3.fromRGB(45, 40, 60)
        icon.BackgroundColor3 = Color3.fromRGB(110, 35, 35)
        icon.Text = "✗"
        nm.TextColor3 = Color3.fromRGB(180, 175, 200)
        badge.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
        badge.Text = "CHƯA"
        badge.TextColor3 = Color3.fromRGB(255, 140, 140)
    end
end

-- Save file
local rainbowDone = false
local function SaveFile()
    if rainbowDone then return end
    rainbowDone = true
    local fileName = player.Name .. ".txt"
    pcall(function()
        writefile(fileName, "Completed-rainbow")
    end)
    warn("✅ Đã phát hiện Rainbow Haki! Đã lưu file: " .. fileName)
end

-- Scan logic
local function DoScan()
    -- Mở bảng Titles
    pcall(function()
        local CommF_ = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
        CommF_:InvokeServer("getTitles")
    end)

    task.wait(1)

    -- Scan text
    local found = false
    pcall(function()
        local m = playerGui:FindFirstChild("Main")
        if m and m:FindFirstChild("Titles") then
            for _, d in pairs(m.Titles:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
                    if d.Text:find(TargetTitle, 1, true) then
                        found = true
                        break
                    end
                end
            end
        end
    end)

    SetStatus(found)
    if found then SaveFile() end
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

-- Close / Keybind
closeBtn.MouseButton1Click:Connect(function()
    running = false
    getgenv().TC = nil
    gui:Destroy()
end)

getgenv().TC = function() running = false; pcall(function() gui:Destroy() end) end

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

print("🌈 Rainbow Checker Loaded | RightShift = ẩn/hiện")
