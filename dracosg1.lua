-- ==========================================
-- SCRIPT CHỈ NHẬN QUEST DRAGON HUNTER & RE-QUEST
-- ==========================================

local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Tọa độ NPC Dojo Trainer để nhận quest
local DOJO_POS = CFrame.new(5813, 1208, 884) 

-- ==========================================
-- [HÀM DI CHUYỂN AN TOÀN]
-- ==========================================
local function TweenTo(targetCFrame)
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChild("Humanoid")
    
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist <= 10 then 
        hrp.CFrame = targetCFrame
        return true 
    end

    local bv = hrp:FindFirstChild("DracoAntiGravity") or Instance.new("BodyVelocity")
    bv.Name = "DracoAntiGravity"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp

    local speed = 320
    local tweenObj = TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    
    local noclip = RunService.Stepped:Connect(function()
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
        if hum then hum:ChangeState(11) end
    end)
    
    tweenObj:Play()
    tweenObj.Completed:Wait()
    
    if noclip then noclip:Disconnect() end
    if bv then bv:Destroy() end
    if hum then hum:ChangeState(8) end
end

-- ==========================================
-- [HÀM NHẬN QUEST & CHECK NOTI]
-- ==========================================

-- Gọi Remote nhận quest chuẩn Banana
local function ClaimDragonQuest()
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
        }))
    end)
end

-- Kiểm tra thông báo hoàn thành để đi nhận lại
local function IsNeedToReQuest()
    local result = false
    pcall(function()
        local notifications = Player.PlayerGui:FindFirstChild("Notifications")
        if notifications then
            for _, b in pairs(notifications:GetChildren()) do
                if b.Name == "NotificationTemplate" and string.find(b.Text, "Head back to the Dojo") then
                    result = true
                    break
                end
            end
        end
    end)
    return result
end

-- Kiểm tra xem hiện tại đã có quest chưa (để tránh spam)
local function HasQuestActive()
    local active = false
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        local questData = Net:WaitForChild("RF/DragonHunter"):InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
        if questData and questData.Text and not string.find(questData.Text, "Head back") then
            active = true
        end
    end)
    return active
end

-- ==========================================
-- [VÒNG LẶP CHÍNH]
-- ==========================================

warn("[Draco] Script Nhận Quest Only đã chạy!")

task.spawn(function()
    while true do
        local needRequest = IsNeedToReQuest()
        local active = HasQuestActive()
        
        -- Nếu có thông báo cần về Dojo HOẶC chưa có quest nào đang làm
        if needRequest or not active then
            print("[Draco] Phát hiện cần nhận nhiệm vụ, đang bay tới NPC...")
            
            -- Bay tới NPC
            TweenTo(DOJO_POS)
            
            -- Nhận quest
            task.wait(0.5)
            ClaimDragonQuest()
            print("[Draco] Đã thực hiện nhận quest. Đang đứng chờ...")
            
            -- Đứng đợi 3s để thông báo cũ biến mất và quest mới ổn định
            task.wait(3)
        end
        
        task.wait(1) -- Check mỗi giây để không lag máy
    end
end)
