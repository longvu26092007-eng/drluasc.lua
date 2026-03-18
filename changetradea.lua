-- ==========================================
-- SCRIPT CHECK DOJO BELT (YELLOW) - BY GEMINI
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

local function CheckYellowBeltAndSave()
    if not CommF then
        StatusLabel.Text = "⏳ Đợi Remote (CommF_)..."
        return false
    end

    local ok, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)

    if ok and type(inv) == "table" then
        StatusLabel.Text = "🔍 Đang quét Inventory (15s)..."
        
        local hasYellowBelt = false
        for _, item in pairs(inv) do
            if type(item) == "table" then
                -- Nhận diện Dojo Belt (Yellow)
                if item.Name == "Dojo Belt (Yellow)" then
                    hasYellowBelt = true
                    break
                end
            end
        end

        if hasYellowBelt then
            local fileName = Player.Name .. ".txt"
            local content = "Completed-trade"
            
            pcall(function()
                writefile(fileName, content)
            end)
            
            StatusLabel.Text = "✅ ĐÃ CÓ YELLOW BELT!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Màu vàng cho rực rỡ
            Stroke.Color = Color3.fromRGB(255, 215, 0)
            
            warn("[DracoHub] Da tim thay Dojo Belt (Yellow)! Ghi file: " .. fileName)
            return true 
        else
            StatusLabel.Text = "❌ CHƯA CÓ YELLOW BELT"
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
    warn("[DracoHub] Bat dau vong lap check 15s cho Yellow Belt.")
    
    while true do
        local success = CheckYellowBeltAndSave()
        if success then 
            task.wait(5) -- Giữ UI báo thành công trong 5s rồi xóa
            if MainFrame.Parent then MainFrame.Parent:Destroy() end
            break 
        end
        task.wait(15) -- Check liên tiếp mỗi 15 giây theo yêu cầu của cậu
    end
end)
