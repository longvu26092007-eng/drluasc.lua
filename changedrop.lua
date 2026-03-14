-- ==========================================
-- SCRIPT CHECK DOJO BELT (GREEN) - BY GEMINI
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
    
    if SafeGuiParent:FindFirstChild("GreenBeltStatusUI") then
        SafeGuiParent.GreenBeltStatusUI:Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GreenBeltStatusUI"
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
    StatusText.Text = "🔍 Khởi tạo Check Green..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12
    StatusText.Parent = MainFrame
    return StatusText, MainFrame, Stroke
end
local StatusLabel, MainFrame, Stroke = CreateMiniUI()
local function CheckGreenBeltAndSave()
    if not CommF then
        StatusLabel.Text = "⏳ Đợi Remote (CommF_)..."
        return false
    end
    local ok, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
        StatusLabel.Text = "🔍 Đang quét Inventory (15s)..."
        
        local hasGreenBelt = false
        for _, item in pairs(inv) do
            if type(item) == "table" then
                if item.Name == "Dojo Belt (Green)" then
                    hasGreenBelt = true
                    break
                end
            end
        end
        if hasGreenBelt then
            local fileName = Player.Name .. ".txt"
            local content = "Completed-drop"
            
            pcall(function()
                writefile(fileName, content)
            end)
            
            StatusLabel.Text = "✅ ĐÃ CÓ GREEN BELT!"
            StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
            Stroke.Color = Color3.fromRGB(80, 255, 80)
            
            warn("[DracoHub] Da tim thay Dojo Belt (Green)! Ghi file: " .. fileName)
            return true 
        else
            StatusLabel.Text = "❌ CHƯA CÓ GREEN BELT"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    else
        StatusLabel.Text = "⚠️ Lỗi Inventory, đang thử lại..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    return false
end
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    warn("[DracoHub] Bat dau vong lap check 15s cho Green Belt.")
    
    while true do
        local success = CheckGreenBeltAndSave()
        if success then 
            task.wait(5)
            if MainFrame.Parent then MainFrame.Parent:Destroy() end
            break 
        end
        task.wait(15)
    end
end)
