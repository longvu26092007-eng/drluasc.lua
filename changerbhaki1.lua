--[[
    🌈 RAINBOW SAVIOUR CHECKER - ONLY EDITION
    - Tự động quét Rainbow Haki mỗi 30s
    - Khi có -> tạo file PlayerName.txt ghi "Completed-rainbow"
    - RightShift để ẩn/hiện
]]

if getgenv().TC then pcall(getgenv().TC) end

local player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local playerGui = player:WaitForChild("PlayerGui")

local TargetTitle = "Unlock Rainbow Saviour aura color."

-- GUI SETUP (Sử dụng bảo mật cao hơn để tránh bị game xóa)
local gui = Instance.new("ScreenGui")
gui.Name = "RainbowCheckerV3"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 85)
main.Position = UDim2.new(0.5, -120, 0.1, 0) -- Hiện ở phía trên giữa màn hình
main.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(255, 100, 255)
stroke.Thickness = 2

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 25)
bar.BackgroundColor3 = Color3.fromRGB(35, 25, 50)
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Text = "🌈 RAINBOW CHECKER"
titleLabel.TextColor3 = Color3.fromRGB(255, 150, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 10
titleLabel.BackgroundTransparency = 1
titleLabel.TextXAlignment = "Left"
titleLabel.Parent = bar

local row = Instance.new("Frame")
row.Size = UDim2.new(1, -16, 0, 30)
row.Position = UDim2.new(0, 8, 0, 32)
row.BackgroundColor3 = Color3.fromRGB(30, 25, 45)
row.Parent = main
Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

local stLabel = Instance.new("TextLabel")
stLabel.Size = UDim2.new(1, 0, 1, 0)
stLabel.Text = "Đang quét Titles..."
stLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
stLabel.Font = Enum.Font.GothamSemibold
stLabel.TextSize = 11
stLabel.BackgroundTransparency = 1
stLabel.Parent = row

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, 0, 0, 15)
timerLabel.Position = UDim2.new(0, 0, 1, -18)
timerLabel.Text = "⏳ Next scan: 30s"
timerLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
timerLabel.TextSize = 9
timerLabel.BackgroundTransparency = 1
timerLabel.Parent = main

-- Logic quét & Lưu file
local rainbowDone = false
local function SaveFile()
    if rainbowDone then return end
    rainbowDone = true
    local fileName = player.Name .. ".txt"
    pcall(function()
        writefile(fileName, "Completed-rainbow")
    end)
    warn("✅ Rainbow Saviour Detected! File saved: " .. fileName)
end

local function DoScan()
    -- Gửi lệnh cập nhật Title từ server
    pcall(function()
        local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
        local comm = remotes:WaitForChild("CommF_")
        comm:InvokeServer("getTitles")
    end)

    task.wait(1)

    local found = false
    pcall(function()
        -- Quét sâu vào PlayerGui để tìm text Haki
        local mainUI = playerGui:FindFirstChild("Main")
        local titlesUI = mainUI and mainUI:FindFirstChild("Titles")
        if titlesUI then
            for _, d in pairs(titlesUI:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text:find(TargetTitle, 1, true) then
                    found = true
                    break
                end
            end
        end
    end)

    if found then
        stLabel.Text = "✅ ĐÃ CÓ RAINBOW HAKI!"
        stLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        stroke.Color = Color3.fromRGB(0, 255, 0)
        SaveFile()
    else
        stLabel.Text = "❌ CHƯA CÓ RAINBOW"
        stLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- Vòng lặp
local running = true
task.spawn(function()
    while running do
        DoScan()
        for i = 30, 1, -1 do
            if not running then break end
            timerLabel.Text = "⏳ Next scan: " .. i .. "s"
            task.wait(1)
        end
    end
end)

-- Phím tắt ẩn/hiện
UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

-- Shutdown script cũ
getgenv().TC = function() running = false; gui:Destroy() end

print("🌈 Rainbow Checker Loaded! Check F9 để xem log.")
