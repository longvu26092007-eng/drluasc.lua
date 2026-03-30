-- ==========================================
-- SCRIPT: AUTO NHẬN QUEST DRAGON HUNTER (STRICT FLOW)
-- Logic: Nhận lần đầu -> Đứng im -> Đợi Noti -> Nhận lại
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local DOJO_POS = CFrame.new(5813, 1208, 884) -- Tọa độ NPC Dojo Trainer

-- ==========================================
-- [HÀM DI CHUYỂN TWEEN AN TOÀN]
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
end

-- ==========================================
-- [HÀM NHẬN NHIỆM VỤ]
-- ==========================================
local function ClaimDragonQuest()
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
        }))
    end)
end

-- ==========================================
-- [HÀM QUÉT THÔNG BÁO - CHUẨN BANANA]
-- ==========================================
local function CheckBackToDojoNotification()
    local found = false
    pcall(function()
        local notifications = Player.PlayerGui:FindFirstChild("Notifications")
        if notifications then
            for _, v in pairs(notifications:GetChildren()) do
                if v.Name == "NotificationTemplate" and v:FindFirstChild("Text") then
                    if string.find(v.Text, "Head back to the Dojo to complete more tasks") then
                        found = true
                        -- Xóa thông báo sau khi đọc để tránh nhận nhầm vòng lặp sau
                        v:Destroy()
                        break
                    end
                end
            end
        end
    end)
    return found
end

-- ==========================================
-- [VÒNG LẶP CHÍNH - THEO TRÌNH TỰ]
-- ==========================================

warn("[Draco] Script Start: Chờ nhận nhiệm vụ đầu tiên...")

-- Bước 1: Nhận nhiệm vụ lần đầu
TweenTo(DOJO_POS)
task.wait(0.5)
ClaimDragonQuest()
warn("[Draco] Đã nhận xong nhiệm vụ đầu. Đứng im chờ thông báo hoàn thành...")

-- Bước 2: Chờ thông báo để nhận lại
task.spawn(function()
    while true do
        if CheckBackToDojoNotification() then
            warn("[Draco] Đã thấy thông báo Head back! Đang quay lại nhận quest mới...")
            
            -- Di chuyển về nhận tiếp
            TweenTo(DOJO_POS)
            task.wait(0.5)
            ClaimDragonQuest()
            
            warn("[Draco] Đã nhận quest mới. Tiếp tục đứng im...")
        end
        task.wait(1) -- Quét mỗi giây
    end
end)
