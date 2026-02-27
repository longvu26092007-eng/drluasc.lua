--[[
    🏆 RACE TITLE CHECKER - BLOX FRUITS
    Scan bảng Titles tìm dòng "Unlock ... V2/V3."
    Hiện = ✓ ĐÃ CÓ | Không hiện = ✗ CHƯA
]]

if getgenv().TC then pcall(getgenv().TC) end

local player = game:GetService("Players").LocalPlayer
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local playerGui = player:WaitForChild("PlayerGui")

-- 14 unlock cần check (đúng text hiện trong game)
local CheckList = {
    {t = "Unlock Human V2.",  v = 2},
    {t = "Unlock Rabbit V2.", v = 2},
    {t = "Unlock Shark V2.",  v = 2},
    {t = "Unlock Angel V2.",  v = 2},
    {t = "Unlock Ghoul V2.",  v = 2},
    {t = "Unlock Cyborg V2.", v = 2},
    {t = "Unlock Draco V2.",  v = 2},
    {t = "Unlock Human V3.",  v = 3},
    {t = "Unlock Rabbit V3.", v = 3},
    {t = "Unlock Shark V3.",  v = 3},
    {t = "Unlock Angel V3.",  v = 3},
    {t = "Unlock Ghoul V3.",  v = 3},
    {t = "Unlock Cyborg V3.", v = 3},
    {t = "Unlock Draco V3.",  v = 3},
}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RaceTitleChecker"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 480)
main.Position = UDim2.new(0.5, -160, 0.5, -240)
main.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local st = Instance.new("UIStroke", main)
st.Color = Color3.fromRGB(200, 170, 50)
st.Thickness = 2

-- Bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 36)
bar.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
Instance.new("Frame", bar).Size = UDim2.new(1, 0, 0, 10)
Instance.new("Frame", bar):FindFirstChildOfClass("Frame") -- fix corners
local fix = Instance.new("Frame")
fix.Size = UDim2.new(1, 0, 0, 10)
fix.Position = UDim2.new(0, 0, 1, -10)
fix.BackgroundColor3 = Color3.fromRGB(25, 22, 40)
fix.BorderSizePixel = 0
fix.Parent = bar

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, -100, 1, 0)
countLabel.Position = UDim2.new(0, 12, 0, 0)
countLabel.BackgroundTransparency = 1
countLabel.Text = "🏆 RACE TITLES 0/14"
countLabel.TextColor3 = Color3.fromRGB(220, 190, 60)
countLabel.TextSize = 13
countLabel.Font = Enum.Font.GothamBold
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Parent = bar

-- Buttons
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0, 50, 0, 24)
scanBtn.Position = UDim2.new(1, -96, 0, 6)
scanBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 200)
scanBtn.Text = "SCAN"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.TextSize = 11
scanBtn.Font = Enum.Font.GothamBold
scanBtn.BorderSizePixel = 0
scanBtn.Parent = bar
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -44)
scroll.Position = UDim2.new(0, 6, 0, 40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 170, 50)
scroll.Parent = main

local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 3)
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Parent = scroll

-- Scan function
local function DoScan()
    -- Clear
    for _, c in pairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    scanBtn.Text = "..."

    -- Mở bảng Titles game
    pcall(function()
        local CommF_ = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
        CommF_:InvokeServer("getTitles")
    end)
    pcall(function()
        local m = playerGui:FindFirstChild("Main")
        if m and m:FindFirstChild("Titles") then
            m.Titles.Visible = true
        end
    end)

    task.wait(1)

    -- Scan GUI tìm text "Unlock ... V2/V3."
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

    -- Check từng title
    local has = 0
    local ord = 0

    -- Header V2
    local h2 = Instance.new("TextLabel")
    h2.Size = UDim2.new(1, -4, 0, 22)
    h2.BackgroundColor3 = Color3.fromRGB(30, 28, 48)
    h2.Text = "  ⚔ RACE V2"
    h2.TextColor3 = Color3.fromRGB(200, 170, 50)
    h2.TextSize = 11
    h2.Font = Enum.Font.GothamBold
    h2.TextXAlignment = Enum.TextXAlignment.Left
    h2.BorderSizePixel = 0
    h2.LayoutOrder = ord
    h2.Parent = scroll
    Instance.new("UICorner", h2).CornerRadius = UDim.new(0, 5)
    ord = ord + 1

    for _, item in ipairs(CheckList) do
        if item.v == 2 then
            local ok = foundTexts[item.t] or false
            -- Cũng check không có dấu chấm cuối
            if not ok then
                local noPoint = item.t:sub(1, -2) -- bỏ dấu "."
                ok = foundTexts[noPoint] or false
            end
            -- Check chứa text
            if not ok then
                for txt, _ in pairs(foundTexts) do
                    if txt:find(item.t, 1, true) or txt:find(item.t:sub(1, -2), 1, true) then
                        ok = true
                        break
                    end
                end
            end

            if ok then has = has + 1 end

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 32)
            row.BackgroundColor3 = ok and Color3.fromRGB(18, 32, 18) or Color3.fromRGB(28, 24, 38)
            row.BorderSizePixel = 0
            row.LayoutOrder = ord
            row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
            local rs = Instance.new("UIStroke", row)
            rs.Color = ok and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(45, 40, 60)

            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(0, 26, 0, 26)
            icon.Position = UDim2.new(0, 3, 0.5, -13)
            icon.BackgroundColor3 = ok and Color3.fromRGB(35, 110, 35) or Color3.fromRGB(110, 35, 35)
            icon.Text = ok and "✓" or "✗"
            icon.TextColor3 = Color3.fromRGB(255, 255, 255)
            icon.TextSize = 15
            icon.Font = Enum.Font.GothamBold
            icon.Parent = row
            Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -90, 1, 0)
            nm.Position = UDim2.new(0, 34, 0, 0)
            nm.BackgroundTransparency = 1
            nm.Text = item.t
            nm.TextColor3 = ok and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(180, 175, 200)
            nm.TextSize = 12
            nm.Font = Enum.Font.GothamSemibold
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = row

            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 50, 0, 18)
            badge.Position = UDim2.new(1, -56, 0.5, -9)
            badge.BackgroundColor3 = ok and Color3.fromRGB(35, 100, 35) or Color3.fromRGB(70, 35, 35)
            badge.Text = ok and "ĐÃ CÓ" or "CHƯA"
            badge.TextColor3 = ok and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 140, 140)
            badge.TextSize = 9
            badge.Font = Enum.Font.GothamBold
            badge.Parent = row
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

            ord = ord + 1
        end
    end

    -- Header V3
    local h3 = Instance.new("TextLabel")
    h3.Size = UDim2.new(1, -4, 0, 22)
    h3.BackgroundColor3 = Color3.fromRGB(30, 28, 48)
    h3.Text = "  👑 RACE V3"
    h3.TextColor3 = Color3.fromRGB(200, 170, 50)
    h3.TextSize = 11
    h3.Font = Enum.Font.GothamBold
    h3.TextXAlignment = Enum.TextXAlignment.Left
    h3.BorderSizePixel = 0
    h3.LayoutOrder = ord
    h3.Parent = scroll
    Instance.new("UICorner", h3).CornerRadius = UDim.new(0, 5)
    ord = ord + 1

    for _, item in ipairs(CheckList) do
        if item.v == 3 then
            local ok = foundTexts[item.t] or false
            if not ok then
                local noPoint = item.t:sub(1, -2)
                ok = foundTexts[noPoint] or false
            end
            if not ok then
                for txt, _ in pairs(foundTexts) do
                    if txt:find(item.t, 1, true) or txt:find(item.t:sub(1, -2), 1, true) then
                        ok = true
                        break
                    end
                end
            end

            if ok then has = has + 1 end

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 32)
            row.BackgroundColor3 = ok and Color3.fromRGB(18, 32, 18) or Color3.fromRGB(28, 24, 38)
            row.BorderSizePixel = 0
            row.LayoutOrder = ord
            row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
            local rs = Instance.new("UIStroke", row)
            rs.Color = ok and Color3.fromRGB(50, 130, 50) or Color3.fromRGB(45, 40, 60)

            local icon = Instance.new("TextLabel")
            icon.Size = UDim2.new(0, 26, 0, 26)
            icon.Position = UDim2.new(0, 3, 0.5, -13)
            icon.BackgroundColor3 = ok and Color3.fromRGB(35, 110, 35) or Color3.fromRGB(110, 35, 35)
            icon.Text = ok and "✓" or "✗"
            icon.TextColor3 = Color3.fromRGB(255, 255, 255)
            icon.TextSize = 15
            icon.Font = Enum.Font.GothamBold
            icon.Parent = row
            Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -90, 1, 0)
            nm.Position = UDim2.new(0, 34, 0, 0)
            nm.BackgroundTransparency = 1
            nm.Text = item.t
            nm.TextColor3 = ok and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(180, 175, 200)
            nm.TextSize = 12
            nm.Font = Enum.Font.GothamSemibold
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = row

            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 50, 0, 18)
            badge.Position = UDim2.new(1, -56, 0.5, -9)
            badge.BackgroundColor3 = ok and Color3.fromRGB(35, 100, 35) or Color3.fromRGB(70, 35, 35)
            badge.Text = ok and "ĐÃ CÓ" or "CHƯA"
            badge.TextColor3 = ok and Color3.fromRGB(140, 255, 140) or Color3.fromRGB(255, 140, 140)
            badge.TextSize = 9
            badge.Font = Enum.Font.GothamBold
            badge.Parent = row
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

            ord = ord + 1
        end
    end

    -- Update UI
    countLabel.Text = "🏆 RACE TITLES  " .. has .. "/14"
    scanBtn.Text = "SCAN"

    task.wait()
    scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8)

    -- Debug log
    local totalFound = 0
    for _ in pairs(foundTexts) do totalFound = totalFound + 1 end
    print("🏆 Scan xong: " .. has .. "/14 | Tổng text trong Titles GUI: " .. totalFound)
    
    -- In ra tất cả text tìm được để debug
    if has == 0 then
        print("⚠ Không tìm thấy. Tất cả text trong Titles GUI:")
        for txt, _ in pairs(foundTexts) do
            print("  → \"" .. txt .. "\"")
        end
    end
end

-- Events
scanBtn.MouseButton1Click:Connect(DoScan)

closeBtn.MouseButton1Click:Connect(function()
    getgenv().TC = nil
    gui:Destroy()
end)
getgenv().TC = function() pcall(function() gui:Destroy() end) end

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

-- Auto scan
task.spawn(DoScan)

print("🏆 Race Title Checker | RightShift = ẩn/hiện | SCAN = quét lại")
