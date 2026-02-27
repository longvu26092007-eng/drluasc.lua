--[[
    TITLE SPY V2 (UNLOCK SCANNER) - BLOX FRUITS
    - Quét dựa trên dòng mô tả "Unlock..." trong game.
    - Hiện trên bảng = Đã đạt điều kiện | Không hiện = Chưa có.
]]

if getgenv().TitleSpyV2 then
    if getgenv().TitleSpyV2Shutdown then pcall(getgenv().TitleSpyV2Shutdown) end
    task.wait(0.2)
end
getgenv().TitleSpyV2 = true

local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
    bg = Color3.fromRGB(18, 18, 28),
    accent = Color3.fromRGB(100, 60, 200),
    text = Color3.fromRGB(220, 210, 255),
    cardBg = Color3.fromRGB(32, 30, 52),
    green = Color3.fromRGB(50, 160, 70)
}

local function Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TitleSpy_UnlockVer"
ScreenGui.Parent = game:GetService("CoreGui") or playerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 350, 0, 450)
Main.Position = UDim2.new(0.5, -175, 0.5, -225)
Main.BackgroundColor3 = C.bg
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Corner(Main, 12)

local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Text = "  RACE UNLOCK CHECKER"
TitleBar.TextColor3 = C.accent
TitleBar.TextXAlignment = "Left"
TitleBar.Font = "GothamBold"
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -60)
Scroll.Position = UDim2.new(0, 10, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.Parent = Scroll

-- Danh sách các dòng "Unlock" cần quét từ ảnh của bạn
local TargetUnlocks = {
    "Unlock Human V2.", "Unlock Rabbit V2.", "Unlock Shark V2.", "Unlock Angel V2.", "Unlock Ghoul V2.", "Unlock Cyborg V2.", "Unlock Draco V2.",
    "Unlock Human V3.", "Unlock Rabbit V3.", "Unlock Shark V3.", "Unlock Angel V3.", "Unlock Ghoul V3.", "Unlock Cyborg V3.", "Unlock Draco V3."
}

local function CreateCard(name)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -5, 0, 40)
    card.BackgroundColor3 = C.cardBg
    card.Parent = Scroll
    Corner(card, 6)
    
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 1, 0)
    t.Position = UDim2.new(0, 10, 0, 0)
    t.Text = "✅ " .. name
    t.TextColor3 = C.text
    t.Font = "GothamSemibold"
    t.TextXAlignment = "Left"
    t.BackgroundTransparency = 1
    t.Parent = card
end

function Scan()
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    
    pcall(function()
        local m = playerGui:FindFirstChild("Main")
        local tf = m and m:FindFirstChild("Titles")
        if tf then
            tf.Visible = true
            task.wait(0.5)
            
            local foundSomething = false
            for _, d in pairs(tf:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
                    for _, target in pairs(TargetUnlocks) do
                        -- So khớp chính xác hoặc chứa cụm từ Unlock
                        if d.Text == target or d.Text:find(target) then
                            if not Scroll:FindFirstChild(target) then -- Tránh trùng lặp
                                CreateCard(target)
                                foundSomething = true
                            end
                        end
                    end
                end
            end
            
            if not foundSomething then
                print("Chưa tìm thấy dòng Unlock nào. Hãy chắc chắn bạn đã mở bảng Title trong game.")
            end
            
            Scroll.CanvasSize = UDim2.new(0,0,0, Layout.AbsoluteContentSize.Y + 10)
        end
    end)
end

local Ref = Instance.new("TextButton")
Ref.Size = UDim2.new(0, 80, 0, 30)
Ref.Position = UDim2.new(1, -90, 0, 5)
Ref.Text = "SCAN"
Ref.BackgroundColor3 = C.accent
Ref.TextColor3 = Color3.new(1,1,1)
Ref.Parent = Main
Corner(Ref, 6)
Ref.MouseButton1Click:Connect(Scan)

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then ScreenGui.Enabled = not ScreenGui.Enabled end
end)

getgenv().TitleSpyV2Shutdown = function()
    ScreenGui:Destroy()
    getgenv().TitleSpyV2 = false
end

task.spawn(Scan)
