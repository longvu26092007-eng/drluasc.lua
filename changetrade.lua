-- ==========================================
-- SCRIPT CHECK DOJO BELT (YELLOW) - BY GEMINI (FIXED)
-- Fix: Check 3 nơi (Character + Backpack + Inventory)
-- ==========================================
local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Chờ Remote tồn tại
local CommF = ReplicatedStorage:WaitForChild("Remotes", 30):WaitForChild("CommF_", 30)
-- Tạo UI nhỏ ở góc màn hình để theo dõi trạng thái
local function CreateMiniUI()
    local SafeGuiParent = pcall(function() return gethui() end) and gethui() 
        or CoreGui:FindFirstChild("RobloxGui") or CoreGui
    
    if SafeGuiParent:FindFirstChild("YellowBeltStatusUI") then
        SafeGuiParent.YellowBeltStatusUI:Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "YellowBeltStatusUI"
    ScreenGui.Parent = SafeGuiParent
    ScreenGui.ResetOnSpawn = false
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 220, 0, 50)
    MainFrame.Position = UDim2.new(1, -230, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    
    local Corner = Instance.new("UICorner", MainFrame)
    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(150, 150, 150)
    Stroke.Thickness = 1.5
    local StatusText = Instance.new("TextLabel", MainFrame)
    StatusText.Name = "StatusLabel"
    StatusText.Size = UDim2.new(1, 0, 1, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "🔍 Khởi tạo Check Yellow..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12
    StatusText.Parent = MainFrame
    return StatusText, MainFrame, Stroke
end
local StatusLabel, MainFrame, Stroke = CreateMiniUI()

local function MarkFound(source)
    local fileName = Player.Name .. ".txt"
    pcall(function() writefile(fileName, "Completed-trade") end)
    StatusLabel.Text = "✅ ĐÃ CÓ YELLOW BELT! (" .. source .. ")"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    Stroke.Color = Color3.fromRGB(255, 215, 0)
    warn("[DracoHub] Da tim thay Dojo Belt (Yellow) trong " .. source .. "! Ghi file: " .. fileName)
    return true
end

local function CheckYellowBeltAndSave()
    -- CHECK 1: Character (đang equip trên người)
    local chr = Player.Character
    if chr and chr:FindFirstChild("Dojo Belt (Yellow)") then
        return MarkFound("Character")
    end

    -- CHECK 2: Backpack (trong túi đồ)
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild("Dojo Belt (Yellow)") then
        return MarkFound("Backpack")
    end

    -- CHECK 3: Inventory remote (kho đồ server)
    if not CommF then
        StatusLabel.Text = "⏳ Đợi Remote (CommF_)..."
        return false
    end

    local ok, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
        StatusLabel.Text = "🔍 Đang quét Inventory (15s)..."
        for _, item in pairs(inv) do
            if type(item) == "table" and item.Name == "Dojo Belt (Yellow)" then
                return MarkFound("Inventory")
            end
        end
        StatusLabel.Text = "❌ CHƯA CÓ YELLOW BELT"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        StatusLabel.Text = "⚠️ Lỗi Inventory, đang thử lại..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    return false
end

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    warn("[DracoHub] Bat dau vong lap check 15s cho Yellow Belt.")
    
    while true do
        local success = CheckYellowBeltAndSave()
        if success then 
            task.wait(5)
            if MainFrame.Parent then MainFrame.Parent:Destroy() end
            break 
        end
        task.wait(15)
    end
end)
