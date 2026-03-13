-- ==========================================
-- SCRIPT CHECK DOJO BELT (WHITE) - FIXED NAME
-- ==========================================
local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommF = ReplicatedStorage:WaitForChild("Remotes", 30):WaitForChild("CommF_", 30)

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
    StatusText.Text = "🔍 Đang khởi tạo..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12
    StatusText.Parent = MainFrame

    return StatusText, MainFrame, Stroke
end

local StatusLabel, MainFrame, Stroke = CreateMiniUI()

local function CheckWhiteBeltAndSave()
    if not CommF then
        StatusLabel.Text = "⏳ Đang đợi Remote..."
        return false
    end

    local ok, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)

    if ok and type(inv) == "table" then
        StatusLabel.Text = "🔍 Đang quét Inventory..."
        
        local hasWhiteBelt = false
        for _, item in pairs(inv) do
            if type(item) == "table" then
                -- FIX: Tên chính xác trong game là "Dojo Belt (White)"
                if item.Name == "Dojo Belt (White)" or item.Name == "White Belt" then
                    hasWhiteBelt = true
                    break
                end
            end
        end

        if hasWhiteBelt then
            local fileName = Player.Name .. ".txt"
            local content = "Completed-trade"
            
            pcall(function()
                writefile(fileName, content)
            end)
            
            StatusLabel.Text = "✅ ĐÃ TÌM THẤY DOJO BELT!"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
            Stroke.Color = Color3.fromRGB(0, 255, 127)
            
            warn("[DracoHub] Da tim thay Dojo Belt (White)! Da ghi file: " .. fileName)
            return true 
        else
            StatusLabel.Text = "❌ KHÔNG TÌM THẤY ĐAI"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        end
    else
        StatusLabel.Text = "⚠️ Lỗi Inventory, đang thử lại..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    return false
end

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    
    while true do
        local success = CheckWhiteBeltAndSave()
        if success then 
            task.wait(5)
            if MainFrame.Parent then MainFrame.Parent:Destroy() end
            break 
        end
        task.wait(5)
    end
end)
