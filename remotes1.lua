--[[
    TITLE SPY V2 (RACE SPECIAL) - BLOX FRUITS
    - Chỉ hiện các Title quan trọng (Tộc V2, V3)
    - Nếu hiện trên bảng = Đã có | Không hiện = Chưa có
]]

if getgenv().TitleSpyV2 then
    if getgenv().TitleSpyV2Shutdown then pcall(getgenv().TitleSpyV2Shutdown) end
    task.wait(0.2)
end
getgenv().TitleSpyV2 = true

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Màu sắc & UI Helpers
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

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TitleSpyV2_Race"
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
TitleBar.Text = "  RACE TITLE SPY"
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

-- Danh sách Title lọc từ ảnh của bạn
local TargetTitles = {
    "The Unleashed", "Unmatched Speed", "Sea Monster", "Sacred Warrior", "The Ghoul", "The Cyborg", "Elder Wyrm",
    "Full Power", "Godspeed", "Warrior of the Sea", "Perfect Being", "Hell Hound", "War Machine", "Ancient Flame"
}

local function CreateCard(name, equipped)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -5, 0, 40)
    card.BackgroundColor3 = C.cardBg
    card.Parent = Scroll
    Corner(card, 6)
    
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -80, 1, 0)
    t.Position = UDim2.new(0, 10, 0, 0)
    t.Text = name
    t.TextColor3 = equipped and Color3.fromRGB(255,255,100) or C.text
    t.Font = equipped and "GothamBold" or "Gotham"
    t.TextXAlignment = "Left"
    t.BackgroundTransparency = 1
    t.Parent = card

    if equipped then
        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(0, 60, 0, 20)
        b.Position = UDim2.new(1, -65, 0.5, -10)
        b.Text = "USING"
        b.BackgroundColor3 = C.green
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 10
        b.Parent = card
        Corner(b, 4)
    end
end

function Scan()
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    
    pcall(function()
        local m = playerGui:FindFirstChild("Main")
        local tf = m and m:FindFirstChild("Titles")
        if tf then
            tf.Visible = true
            task.wait(0.3)
            
            local eq = nil
            for _, d in pairs(tf:GetDescendants()) do
                if d:IsA("TextLabel") and (d.Text:lower():find("equipped") or d.Text:lower():find("đang dùng")) then
                    for _, s in pairs(d.Parent:GetChildren()) do
                        if s:IsA("TextLabel") and s ~= d and #s.Text > 2 then eq = s.Text end
                    end
                end
            end

            local foundCount = 0
            for _, d in pairs(tf:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    for _, target in pairs(TargetTitles) do
                        if d.Text == target then
                            CreateCard(target, (target == eq))
                            foundCount = foundCount + 1
                        end
                    end
                end
            end
            Scroll.CanvasSize = UDim2.new(0,0,0, Layout.AbsoluteContentSize.Y + 10)
        end
    end)
end

-- Nút Refresh
local Ref = Instance.new("TextButton")
Ref.Size = UDim2.new(0, 80, 0, 30)
Ref.Position = UDim2.new(1, -90, 0, 5)
Ref.Text = "SCAN"
Ref.BackgroundColor3 = C.accent
Ref.TextColor3 = Color3.new(1,1,1)
Ref.Parent = Main
Corner(Ref, 6)
Ref.MouseButton1Click:Connect(Scan)

-- Phím tắt RightShift
UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then ScreenGui.Enabled = not ScreenGui.Enabled end
end)

getgenv().TitleSpyV2Shutdown = function()
    ScreenGui:Destroy()
    getgenv().TitleSpyV2 = false
end

task.spawn(Scan)
print("Title Spy Loaded! Nhấn RightShift để ẩn/hiện.")
