-- ==========================================
-- SCRIPT CHECK WHITE BELT ONLY + MINI UI
-- ==========================================
local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Tạo UI nhỏ ở góc màn hình
local function CreateMiniUI()
    local SafeGuiParent = pcall(function() return gethui() end) and gethui() 
        or CoreGui:FindFirstChild("RobloxGui") or CoreGui
    
    if SafeGuiParent:FindFirstChild("WhiteBeltStatusUI") then
        SafeGuiParent.WhiteBeltStatusUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WhiteBeltStatusUI"
    ScreenGui.Parent = SafeGuiParent
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 200, 0, 45)
    MainFrame.Position = UDim2.new(1, -210, 0.1, 0) -- Ở góc trên bên phải
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner", MainFrame)
    Corner.CornerRadius = UDim.new(0, 10)
    
    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(100, 100, 100)
    Stroke.Thickness = 1.5

    local StatusText = Instance.new("TextLabel", MainFrame)
    StatusText.Name = "StatusLabel"
    StatusText.Size = UDim2.new(1, 0, 1, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "🔍 Đang đợi White Belt..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12

    return StatusText, MainFrame, Stroke
end

local StatusLabel, MainFrame, Stroke = CreateMiniUI()

local function CheckWhiteBeltAndSave()
    local ok, inv = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("getInventory")
    end)

    if ok and type(inv) == "table" then
        local hasWhiteBelt = false
        
        for _, item in pairs(inv) do
            if type(item) == "table" and item.Name == "White Belt" then
                hasWhiteBelt = true
                break
            end
        end

        if hasWhiteBelt then
            local fileName = Player.Name .. ".txt"
            local content = "Completed-trade"
            
            pcall(function()
                writefile(fileName, content)
            end)
            
            -- Cập nhật UI khi thành công
            StatusLabel.Text = "✅ ĐÃ TÌM THẤY WHITE BELT!"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
            Stroke.Color = Color3.fromRGB(0, 255, 127)
            
            warn("[DracoHub] Da tim thay White Belt! Da ghi file: " .. fileName)
            return true 
        end
    else
        StatusLabel.Text = "⚠️ Lỗi kết nối Server..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    end
    return false
end

-- Chạy vòng lặp kiểm tra
task.spawn(function()
    warn("[DracoHub] Dang bat dau kiem tra White Belt...")
    while true do
        local success = CheckWhiteBeltAndSave()
        if success then 
            warn("[DracoHub] Hoàn thành! Script sẽ dừng sau 5 giây.")
            task.wait(5)
            -- Tự xóa UI sau khi báo thành công
            if StatusLabel.Parent.Parent then
                StatusLabel.Parent.Parent:Destroy()
            end
            break 
        end
        task.wait(5)
    end
end)
