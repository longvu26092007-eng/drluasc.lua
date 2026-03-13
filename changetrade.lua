-- ======================================================================
-- SCRIPT CHECK WHITE BELT (FIXED) - BY GEMINI FOR VŨ
-- ======================================================================
local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Đợi Remote chuẩn (Sửa lại thời gian đợi để ổn định hơn)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 60)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 60)

local function CreateMiniUI()
    local SafeGuiParent = (run_on_actor and gethui()) or (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui
    
    if SafeGuiParent:FindFirstChild("WhiteBeltStatusUI") then
        SafeGuiParent.WhiteBeltStatusUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WhiteBeltStatusUI"
    ScreenGui.Parent = SafeGuiParent
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 220, 0, 50)
    MainFrame.Position = UDim2.new(1, -230, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    
    local Corner = Instance.new("UICorner", MainFrame)
    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(150, 150, 150)
    Stroke.Thickness = 2

    local StatusText = Instance.new("TextLabel", MainFrame)
    StatusText.Size = UDim2.new(1, 0, 1, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "🔍 Đang kết nối server..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 13

    return StatusText, MainFrame, Stroke
end

local StatusLabel, MainFrame, Stroke = CreateMiniUI()

local function CheckWhiteBelt()
    if not CommF then return false end

    -- Gọi lấy Inventory với pcall để tránh văng script
    local ok, inventory = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)

    if ok and type(inventory) == "table" then
        local found = false
        for _, item in pairs(inventory) do
            -- Kiểm tra cả Name và Type (thường là "Wear" hoặc "Accessory")
            if type(item) == "table" and item.Name == "White Belt" then
                found = true
                break
            end
        end

        if found then
            local fileName = Player.Name .. ".txt"
            local content = "Completed-trade"
            
            pcall(function()
                writefile(fileName, content)
            end)
            
            StatusLabel.Text = "✅ ĐÃ CÓ WHITE BELT!"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
            Stroke.Color = Color3.fromRGB(0, 255, 127)
            return true
        else
            StatusLabel.Text = "❌ CHƯA CÓ WHITE BELT"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
        end
    else
        StatusLabel.Text = "⚠️ Lỗi dữ liệu Inventory"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    return false
end

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    warn("[DracoHub] Hệ thống check đai trắng đã bật.")

    while true do
        local result = CheckWhiteBelt()
        if result then 
            task.wait(10) -- Giữ UI hiện 10s để báo cho Vũ biết là xong rồi
            if MainFrame.Parent then MainFrame.Parent:Destroy() end
            break 
        end
        task.wait(5) -- Quét lại mỗi 5 giây để tránh lag
    end
end)
