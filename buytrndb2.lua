-- ==============================================================
-- 🐉 DRACO RACE V4 TRAINING CHECKER (STANDALONE) 🐉
-- Tác dụng: Tạo UI nhỏ góc màn hình theo dõi tiến trình Train V4
-- ==============================================================

local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- 1. Xóa UI cũ nếu đã chạy trước đó để không bị trùng lặp
if CoreGui:FindFirstChild("DracoTrainingUI") then
    CoreGui.DracoTrainingUI:Destroy()
end

-- 2. Tạo Giao Diện Nhỏ (Mini UI)
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DracoTrainingUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 60)
MainFrame.Position = UDim2.new(0.5, -125, 0, 20) -- Hiển thị ở giữa cạnh trên màn hình
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Có thể kéo thả

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 255, 255) -- Viền Xanh Ngọc

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "🐉 Draco Training Session"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13

local InfoLabel = Instance.new("TextLabel", MainFrame)
InfoLabel.Size = UDim2.new(1, 0, 0, 35)
InfoLabel.Position = UDim2.new(0, 0, 0, 25)
InfoLabel.Text = "Đang kiểm tra dữ liệu..."
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.TextSize = 14

-- 3. Hàm Xử Lý Kiểm Tra Tiến Trình V4
local function GetTrainingSession()
    -- Kiểm tra xem Data Race có tồn tại không
    local playerData = Player:FindFirstChild("Data")
    if not playerData or not playerData:FindFirstChild("Race") then
        return "Lỗi Data Người Chơi!"
    end

    local raceName = playerData.Race.Value

    -- Có thể tắt dòng if này nếu bạn muốn check cả các tộc khác (Mink, Human...)
    if not (string.find(raceName, "Draco") or string.find(raceName, "Dragon")) then
        return "Đang dùng tộc: " .. raceName
    end

    -- Gọi Remote kiểm tra đồng hồ cổ đại (Check UpgradeRace)
    local ok, res = pcall(function()
        return CommF:InvokeServer("UpgradeRace", "Check")
    end)

    if ok and type(res) == "string" then
        -- Lọc số từ chuỗi trả về (VD: "You need to train 3/5 times")
        local current, max = string.match(res, "(%d+)/(%d+)")
        
        if current and max then
            return "Tiến trình: " .. current .. " / " .. max
        elseif string.find(string.lower(res), "max") or string.find(string.lower(res), "fully") then
            return "Tiến trình: MAX 🌟"
        else
            -- Nếu có tộc nhưng chưa bắt đầu train đợt nào
            return "Chưa bắt đầu Train (0/X)"
        end
    elseif ok and res == nil then
         return "Chưa thức tỉnh V4"
    else
        return "Không lấy được dữ liệu"
    end
end

-- 4. Vòng lặp cập nhật liên tục (Mỗi 3 giây)
task.spawn(function()
    while task.wait(3) do
        if not CoreGui:FindFirstChild("DracoTrainingUI") then break end -- Dừng loop nếu UI bị tắt
        
        pcall(function()
            local statusText = GetTrainingSession()
            InfoLabel.Text = statusText
            
            -- Đổi màu text cho đẹp mắt
            if string.find(statusText, "MAX") then
                InfoLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá nếu Max
            elseif string.find(statusText, "/") then
                InfoLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- Xanh ngọc nếu đang train
            else
                InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Xám nếu lỗi/chưa có
            end
        end)
    end
end)
