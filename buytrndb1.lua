--[[
    🐉 DRACO TRAINING CHECKER + DEBUGGER
    Remote: RF/InteractDragonQuest → NPC=Dragon Wizard, Command=DragonRace
    Check: CommF_ → UpgradeRace, Check
    ❌ KHÔNG hook __namecall
]]

if getgenv().DTC then pcall(getgenv().DTC) end

local Player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local playerGui = Player:WaitForChild("PlayerGui")

-- ═══════════ REMOTES ═══════════
local CommF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local Net = RS:WaitForChild("Modules"):WaitForChild("Net")

local RF_Dragon = Net:FindFirstChild("RF/InteractDragonQuest") or Net:WaitForChild("RF/InteractDragonQuest", 5)
local RF_Craft = Net:FindFirstChild("RF/Craft") or Net:WaitForChild("RF/Craft", 5)

-- ═══════════ GUI ═══════════
local gui = Instance.new("ScreenGui")
gui.Name = "DracoTraining"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 340)
main.Position = UDim2.new(0.5, -160, 0.5, -170)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(255, 120, 20)

-- Bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 28)
bar.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local fix = Instance.new("Frame")
fix.Size = UDim2.new(1, 0, 0, 10)
fix.Position = UDim2.new(0, 0, 1, -10)
fix.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
fix.BorderSizePixel = 0
fix.Parent = bar

local titleL = Instance.new("TextLabel")
titleL.Size = UDim2.new(1, -30, 1, 0)
titleL.Position = UDim2.new(0, 10, 0, 0)
titleL.BackgroundTransparency = 1
titleL.Text = "🐉 DRACO TRAINING"
titleL.TextColor3 = Color3.fromRGB(255, 120, 20)
titleL.TextSize = 12
titleL.Font = Enum.Font.GothamBold
titleL.TextXAlignment = Enum.TextXAlignment.Left
titleL.Parent = bar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -24, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

-- ═══ STATUS SECTION ═══
local function MakeLabel(y, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 0, 16)
    l.Position = UDim2.new(0, 8, 0, y)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(180, 180, 200)
    l.TextSize = 11
    l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = main
    return l
end

local statusL = MakeLabel(32, "Status: ⏳")
local rawL = MakeLabel(50, "Raw: ...")
rawL.TextSize = 9
rawL.Font = Enum.Font.Gotham
rawL.TextColor3 = Color3.fromRGB(120, 120, 145)
local raceL = MakeLabel(64, "Race: ...")
raceL.TextSize = 9
raceL.Font = Enum.Font.Gotham
raceL.TextColor3 = Color3.fromRGB(120, 120, 145)
local remoteL = MakeLabel(78, "Remotes: ...")
remoteL.TextSize = 9
remoteL.Font = Enum.Font.Gotham
remoteL.TextColor3 = Color3.fromRGB(100, 100, 130)

-- Progress bar
local pBg = Instance.new("Frame")
pBg.Size = UDim2.new(1, -16, 0, 22)
pBg.Position = UDim2.new(0, 8, 0, 96)
pBg.BackgroundColor3 = Color3.fromRGB(25, 22, 38)
pBg.BorderSizePixel = 0
pBg.Parent = main
Instance.new("UICorner", pBg).CornerRadius = UDim.new(0, 6)

local pFill = Instance.new("Frame")
pFill.Size = UDim2.new(0, 0, 1, 0)
pFill.BackgroundColor3 = Color3.fromRGB(255, 150, 30)
pFill.BorderSizePixel = 0
pFill.Parent = pBg
Instance.new("UICorner", pFill).CornerRadius = UDim.new(0, 6)

local pText = Instance.new("TextLabel")
pText.Size = UDim2.new(1, 0, 1, 0)
pText.BackgroundTransparency = 1
pText.Text = "0/10"
pText.TextColor3 = Color3.fromRGB(255, 255, 255)
pText.TextSize = 12
pText.Font = Enum.Font.GothamBold
pText.ZIndex = 2
pText.Parent = pBg

-- ═══ LOG SECTION ═══
local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(1, -16, 0, 90)
logFrame.Position = UDim2.new(0, 8, 0, 122)
logFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 2
logFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 120, 20)
logFrame.Parent = main
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 6)

local logLay = Instance.new("UIListLayout")
logLay.Padding = UDim.new(0, 1)
logLay.SortOrder = Enum.SortOrder.LayoutOrder
logLay.Parent = logFrame

local logN = 0

local function AddLog(text, color)
    logN = logN + 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -4, 0, 13)
    l.BackgroundTransparency = 1
    l.Text = " " .. os.date("%H:%M:%S") .. " " .. text
    l.TextColor3 = color or Color3.fromRGB(160, 160, 180)
    l.TextSize = 9
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = -logN
    l.Parent = logFrame
    warn("[DracoLog] " .. text)
    task.defer(function()
        logFrame.CanvasSize = UDim2.new(0, 0, 0, logLay.AbsoluteContentSize.Y + 4)
    end)
end

-- Update remote info
remoteL.Text = "RF/Dragon: " .. (RF_Dragon and "✅" or "❌") .. " | RF/Craft: " .. (RF_Craft and "✅" or "❌") .. " | CommF_: " .. (CommF_ and "✅" or "❌")

-- ═══════════ CHECK FUNCTION ═══════════
local function DoCheck()
    -- Race
    local race = "?"
    pcall(function() race = Player.Data.Race.Value end)
    local hasRT = false
    pcall(function() hasRT = Player.Character:FindFirstChild("RaceTransformed") ~= nil end)
    raceL.Text = "Race: " .. race .. " | V4 Transform: " .. (hasRT and "✅" or "❌")
    
    -- UpgradeRace Check
    local ok, v1, v2, v3
    ok = pcall(function()
        v1, v2, v3 = CommF_:InvokeServer("UpgradeRace", "Check")
    end)
    
    if not ok then
        statusL.Text = "Status: ❌ Lỗi gọi remote"
        rawL.Text = "Raw: error"
        AddLog("Check failed", Color3.fromRGB(255, 80, 80))
        return v1, v2, v3
    end
    
    rawL.Text = "Raw: v1=" .. tostring(v1) .. " | v2=" .. tostring(v2) .. " | v3=" .. tostring(v3)
    
    local sessions = tonumber(v2) or 0
    local frags = tonumber(v3) or 0
    local progress = 0
    local msg = ""
    local col = Color3.fromRGB(200, 200, 220)
    local barCol = Color3.fromRGB(255, 150, 30)
    
    if v1 == 8 then
        progress = sessions
        msg = "📋 Training: " .. progress .. "/10 (còn " .. (10 - progress) .. ")"
        col = Color3.fromRGB(100, 180, 255)
    elseif v1 == 2 or v1 == 4 or v1 == 7 then
        progress = sessions
        msg = "💰 MUA ĐƯỢC! " .. frags .. " fragments"
        col = Color3.fromRGB(255, 220, 50)
        barCol = Color3.fromRGB(255, 220, 50)
    elseif v1 == 1 or v1 == 3 then
        progress = sessions
        msg = "🏋 Cần train thêm"
        col = Color3.fromRGB(255, 200, 100)
    elseif v1 == 5 then
        progress = 10
        msg = "🎉 HOÀN THÀNH V4!"
        col = Color3.fromRGB(80, 255, 80)
        barCol = Color3.fromRGB(80, 220, 80)
    elseif v1 == 6 then
        progress = sessions
        msg = "⬆ Upgrades: " .. ((tonumber(v2) or 2) - 2) .. "/3"
        col = Color3.fromRGB(200, 150, 255)
    elseif v1 == 0 then
        progress = 10
        msg = "⚔ READY FOR TRIAL!"
        col = Color3.fromRGB(255, 100, 80)
        barCol = Color3.fromRGB(255, 80, 50)
    else
        progress = sessions
        msg = "❓ v1=" .. tostring(v1)
    end
    
    statusL.Text = "Status: " .. msg
    statusL.TextColor3 = col
    pText.Text = progress .. "/10"
    pFill.BackgroundColor3 = barCol
    TS:Create(pFill, TweenInfo.new(0.4), {Size = UDim2.new(math.clamp(progress/10, 0, 1), 0, 1, 0)}):Play()
    
    AddLog("Check: v1=" .. tostring(v1) .. " v2=" .. tostring(v2) .. " → " .. msg, col)
    return v1, v2, v3
end

-- ═══════════ BUTTONS ═══════════
local function MakeBtn(y, text, color, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 28)
    b.Position = UDim2.new(0, 8, 0, y)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        local orig = b.Text
        b.Text = "⏳..."
        pcall(callback)
        task.wait(0.5)
        b.Text = orig
    end)
    return b
end

-- BUY TRAINING (RF/InteractDragonQuest)
MakeBtn(218, "💰 MUA TRAINING (Dragon Wizard → DragonRace)", Color3.fromRGB(120, 70, 15), function()
    if RF_Dragon then
        local ret = RF_Dragon:InvokeServer({NPC = "Dragon Wizard", Command = "DragonRace"})
        AddLog("RF/InteractDragonQuest → DragonRace | Return: " .. tostring(ret), Color3.fromRGB(255, 150, 30))
    else
        AddLog("❌ RF/InteractDragonQuest không tìm thấy!", Color3.fromRGB(255, 50, 50))
    end
    task.wait(0.5)
    DoCheck()
end)

-- BUY GEAR (CommF_ UpgradeRace Buy) 
MakeBtn(250, "⚙ MUA GEAR (CommF_ → UpgradeRace Buy)", Color3.fromRGB(80, 50, 120), function()
    local ret = CommF_:InvokeServer("UpgradeRace", "Buy")
    AddLog("UpgradeRace Buy → Return: " .. tostring(ret), Color3.fromRGB(200, 100, 255))
    task.wait(0.5)
    DoCheck()
end)

-- REFRESH
MakeBtn(282, "🔄 CHECK STATUS", Color3.fromRGB(40, 80, 40), function()
    DoCheck()
end)

-- Timer
local timerL = Instance.new("TextLabel")
timerL.Size = UDim2.new(1, 0, 0, 14)
timerL.Position = UDim2.new(0, 0, 1, -14)
timerL.BackgroundTransparency = 1
timerL.Text = ""
timerL.TextColor3 = Color3.fromRGB(70, 70, 100)
timerL.TextSize = 9
timerL.Font = Enum.Font.Gotham
timerL.Parent = main

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
    getgenv().DTC = nil
    gui:Destroy()
end)
getgenv().DTC = function() running = false; pcall(function() gui:Destroy() end) end

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

AddLog("🐉 Draco Training Checker loaded!", Color3.fromRGB(255, 150, 30))
print("🐉 Draco Training | Auto 15s | RightShift ẩn/hiện")
