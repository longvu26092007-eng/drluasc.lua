--[[
    ⚙ TRAINING SESSIONS CHECKER - BLOX FRUITS
    Check tiến trình mua gear V4 từ Ancient One
    Hiện status + progress x/10 + auto refresh
]]

if getgenv().TSC then pcall(getgenv().TSC) end

local Player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local playerGui = Player:WaitForChild("PlayerGui")
local CommF_ = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TrainingCheck"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 210)
main.Position = UDim2.new(0.5, -150, 0.5, -105)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(255, 180, 0)

-- Bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 32)
bar.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local fix = Instance.new("Frame")
fix.Size = UDim2.new(1, 0, 0, 10)
fix.Position = UDim2.new(0, 0, 1, -10)
fix.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
fix.BorderSizePixel = 0
fix.Parent = bar

local titleL = Instance.new("TextLabel")
titleL.Size = UDim2.new(1, -60, 1, 0)
titleL.Position = UDim2.new(0, 10, 0, 0)
titleL.BackgroundTransparency = 1
titleL.Text = "⚙ TRAINING CHECKER"
titleL.TextColor3 = Color3.fromRGB(255, 180, 0)
titleL.TextSize = 12
titleL.Font = Enum.Font.GothamBold
titleL.TextXAlignment = Enum.TextXAlignment.Left
titleL.Parent = bar

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 22, 0, 22)
refreshBtn.Position = UDim2.new(1, -54, 0, 5)
refreshBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
refreshBtn.Text = "↻"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 14
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = bar
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Status label
local statusL = Instance.new("TextLabel")
statusL.Size = UDim2.new(1, -16, 0, 18)
statusL.Position = UDim2.new(0, 8, 0, 36)
statusL.BackgroundTransparency = 1
statusL.Text = "Status: ..."
statusL.TextColor3 = Color3.fromRGB(200, 200, 220)
statusL.TextSize = 11
statusL.Font = Enum.Font.GothamSemibold
statusL.TextXAlignment = Enum.TextXAlignment.Left
statusL.Parent = main

-- Raw values
local rawL = Instance.new("TextLabel")
rawL.Size = UDim2.new(1, -16, 0, 14)
rawL.Position = UDim2.new(0, 8, 0, 55)
rawL.BackgroundTransparency = 1
rawL.Text = "Raw: ..."
rawL.TextColor3 = Color3.fromRGB(130, 130, 155)
rawL.TextSize = 10
rawL.Font = Enum.Font.Gotham
rawL.TextXAlignment = Enum.TextXAlignment.Left
rawL.Parent = main

-- Race label
local raceL = Instance.new("TextLabel")
raceL.Size = UDim2.new(1, -16, 0, 14)
raceL.Position = UDim2.new(0, 8, 0, 70)
raceL.BackgroundTransparency = 1
raceL.Text = "Race: ..."
raceL.TextColor3 = Color3.fromRGB(130, 130, 155)
raceL.TextSize = 10
raceL.Font = Enum.Font.Gotham
raceL.TextXAlignment = Enum.TextXAlignment.Left
raceL.Parent = main

-- Progress bar bg
local pBarBg = Instance.new("Frame")
pBarBg.Size = UDim2.new(1, -16, 0, 20)
pBarBg.Position = UDim2.new(0, 8, 0, 90)
pBarBg.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
pBarBg.BorderSizePixel = 0
pBarBg.Parent = main
Instance.new("UICorner", pBarBg).CornerRadius = UDim.new(0, 6)

local pBarFill = Instance.new("Frame")
pBarFill.Size = UDim2.new(0, 0, 1, 0)
pBarFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
pBarFill.BorderSizePixel = 0
pBarFill.Parent = pBarBg
Instance.new("UICorner", pBarFill).CornerRadius = UDim.new(0, 6)

local pBarText = Instance.new("TextLabel")
pBarText.Size = UDim2.new(1, 0, 1, 0)
pBarText.BackgroundTransparency = 1
pBarText.Text = "0/10"
pBarText.TextColor3 = Color3.fromRGB(255, 255, 255)
pBarText.TextSize = 11
pBarText.Font = Enum.Font.GothamBold
pBarText.ZIndex = 2
pBarText.Parent = pBarBg

-- Message label
local msgL = Instance.new("TextLabel")
msgL.Size = UDim2.new(1, -16, 0, 36)
msgL.Position = UDim2.new(0, 8, 0, 115)
msgL.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
msgL.Text = "..."
msgL.TextColor3 = Color3.fromRGB(180, 180, 200)
msgL.TextSize = 11
msgL.Font = Enum.Font.GothamSemibold
msgL.TextWrapped = true
msgL.BorderSizePixel = 0
msgL.Parent = main
Instance.new("UICorner", msgL).CornerRadius = UDim.new(0, 6)

-- Buy button
local buyBtn = Instance.new("TextButton")
buyBtn.Size = UDim2.new(1, -16, 0, 30)
buyBtn.Position = UDim2.new(0, 8, 0, 156)
buyBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 15)
buyBtn.Text = "💰 MUA GEAR (UpgradeRace Buy)"
buyBtn.TextColor3 = Color3.fromRGB(255, 200, 80)
buyBtn.TextSize = 11
buyBtn.Font = Enum.Font.GothamBold
buyBtn.BorderSizePixel = 0
buyBtn.Parent = main
Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

-- Timer
local timerL = Instance.new("TextLabel")
timerL.Size = UDim2.new(1, 0, 0, 14)
timerL.Position = UDim2.new(0, 0, 1, -14)
timerL.BackgroundTransparency = 1
timerL.Text = ""
timerL.TextColor3 = Color3.fromRGB(80, 80, 110)
timerL.TextSize = 9
timerL.Font = Enum.Font.Gotham
timerL.Parent = main

-- ═══════════ CHECK FUNCTION ═══════════
local function DoCheck()
    statusL.Text = "Status: ⏳ Đang check..."
    statusL.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    -- Check RaceTransformed
    local hasRT = false
    pcall(function()
        hasRT = Player.Character and Player.Character:FindFirstChild("RaceTransformed") and true or false
    end)
    
    -- Check Race
    local raceName = "?"
    pcall(function()
        raceName = Player.Data.Race.Value or "?"
    end)
    raceL.Text = "Race: " .. raceName .. " | V4 Transform: " .. (hasRT and "✅ CÓ" or "❌ CHƯA")
    
    if not hasRT then
        statusL.Text = "Status: ❌ Chưa có RaceTransformed"
        statusL.TextColor3 = Color3.fromRGB(255, 100, 100)
        rawL.Text = "Raw: Cần biến hình V4 trước (ở Temple Of Time)"
        msgL.Text = "⚠ Bạn chưa kích hoạt V4 Transform.\nCần hoàn thành quest tại Temple Of Time trước."
        msgL.TextColor3 = Color3.fromRGB(255, 150, 100)
        pBarText.Text = "?/10"
        return
    end
    
    -- Call UpgradeRace Check
    local ok, v229, v228, v227
    ok = pcall(function()
        v229, v228, v227 = CommF_:InvokeServer("UpgradeRace", "Check")
    end)
    
    if not ok then
        statusL.Text = "Status: ❌ Lỗi gọi remote"
        statusL.TextColor3 = Color3.fromRGB(255, 80, 80)
        rawL.Text = "Raw: pcall failed"
        msgL.Text = "⚠ Không gọi được CommF_ UpgradeRace Check"
        msgL.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    rawL.Text = "Raw: v1=" .. tostring(v229) .. " | v2=" .. tostring(v228) .. " | v3=" .. tostring(v227)
    
    -- Parse status
    local sessions = tonumber(v228) or 0
    local fragments = tonumber(v227) or 0
    local progress = 0
    local statusMsg = ""
    local statusColor = Color3.fromRGB(200, 200, 220)
    local msgText = ""
    local msgColor = Color3.fromRGB(180, 180, 200)
    local barColor = Color3.fromRGB(255, 180, 0)
    
    if v229 == 8 then
        -- Remaining x/10
        progress = sessions
        statusMsg = "📋 Training Sessions: " .. progress .. "/10"
        statusColor = Color3.fromRGB(100, 180, 255)
        msgText = "Còn " .. (10 - progress) .. " lần train nữa.\nMua gear → train → lặp lại."
        msgColor = Color3.fromRGB(150, 200, 255)
        
    elseif v229 == 1 or v229 == 3 then
        progress = sessions
        statusMsg = "🏋 Required Train More"
        statusColor = Color3.fromRGB(255, 200, 100)
        msgText = "Cần hoàn thành trial hiện tại trước.\nVào cửa tộc để train."
        msgColor = Color3.fromRGB(255, 200, 100)
        
    elseif v229 == 2 or v229 == 4 or v229 == 7 then
        progress = sessions
        statusMsg = "💰 Có thể MUA GEAR! (" .. fragments .. " fragments)"
        statusColor = Color3.fromRGB(255, 220, 50)
        msgText = "Bấm nút MUA GEAR bên dưới!\nGiá: " .. fragments .. " fragments."
        msgColor = Color3.fromRGB(255, 220, 80)
        barColor = Color3.fromRGB(255, 220, 50)
        
    elseif v229 == 5 then
        progress = 10
        statusMsg = "🎉 HOÀN THÀNH! Race V4 Done!"
        statusColor = Color3.fromRGB(80, 255, 80)
        msgText = "✅ Bạn đã hoàn thành Race V4!\nKhông cần làm gì thêm."
        msgColor = Color3.fromRGB(80, 255, 80)
        barColor = Color3.fromRGB(80, 220, 80)
        
    elseif v229 == 6 then
        local upgrades = (tonumber(v228) or 2) - 2
        progress = sessions
        statusMsg = "⬆ Upgrades: " .. upgrades .. "/3 - Cần train thêm"
        statusColor = Color3.fromRGB(200, 150, 255)
        msgText = "Đã upgrade " .. upgrades .. "/3.\nCần train thêm để mở upgrade tiếp."
        msgColor = Color3.fromRGB(200, 160, 255)
        
    elseif v229 == 0 then
        progress = 10
        statusMsg = "⚔ READY FOR TRIAL!"
        statusColor = Color3.fromRGB(255, 100, 100)
        msgText = "🔥 Sẵn sàng đi Trial!\nVào cửa tộc của bạn để bắt đầu."
        msgColor = Color3.fromRGB(255, 120, 80)
        barColor = Color3.fromRGB(255, 100, 50)
        
    else
        progress = sessions
        statusMsg = "❓ Status: " .. tostring(v229)
        statusColor = Color3.fromRGB(180, 180, 180)
        msgText = "Status không xác định: " .. tostring(v229)
        msgColor = Color3.fromRGB(180, 180, 180)
    end
    
    statusL.Text = "Status: " .. statusMsg
    statusL.TextColor3 = statusColor
    msgL.Text = msgText
    msgL.TextColor3 = msgColor
    
    -- Progress bar
    local ratio = math.clamp(progress / 10, 0, 1)
    pBarText.Text = progress .. "/10"
    pBarFill.BackgroundColor3 = barColor
    TS:Create(pBarFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Size = UDim2.new(ratio, 0, 1, 0)
    }):Play()
    
    -- Console log
    print(string.format("⚙ Training Check: v1=%s v2=%s v3=%s | %s", 
        tostring(v229), tostring(v228), tostring(v227), statusMsg))
end

-- ═══════════ BUY GEAR ═══════════
buyBtn.MouseButton1Click:Connect(function()
    buyBtn.Text = "⏳ Đang mua..."
    
    local ok, ret
    ok = pcall(function()
        ret = CommF_:InvokeServer("UpgradeRace", "Buy")
    end)
    
    if ok then
        buyBtn.Text = "✅ Đã gọi! Return: " .. tostring(ret)
        print("💰 UpgradeRace Buy → Return: " .. tostring(ret))
    else
        buyBtn.Text = "❌ Lỗi!"
    end
    
    task.wait(1.5)
    DoCheck()
    buyBtn.Text = "💰 MUA GEAR (UpgradeRace Buy)"
end)

buyBtn.MouseEnter:Connect(function()
    TS:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(70, 60, 20)}):Play()
end)
buyBtn.MouseLeave:Connect(function()
    TS:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 40, 15)}):Play()
end)

-- ═══════════ REFRESH ═══════════
refreshBtn.MouseButton1Click:Connect(function()
    refreshBtn.Text = "⏳"
    DoCheck()
    refreshBtn.Text = "↻"
end)

-- ═══════════ AUTO CHECK 15s ═══════════
local running = true

task.spawn(function()
    while running do
        DoCheck()
        for i = 15, 1, -1 do
            if not running then return end
            timerL.Text = "Auto check: " .. i .. "s"
            task.wait(1)
        end
    end
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    running = false
    getgenv().TSC = nil
    gui:Destroy()
end)
getgenv().TSC = function() running = false; pcall(function() gui:Destroy() end) end

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

-- Init
DoCheck()

print("⚙ Training Checker | Auto 15s | ↻ = refresh | RightShift = ẩn/hiện")
