-- ==========================================
-- [ KEY CHECK ] — Lấy key từ executor bên ngoài
-- ==========================================
local NhapKey = getgenv().Key

if not NhapKey or NhapKey == "" then
    warn("[DracoAuto] ❌ Chưa set getgenv().Key ở executor! Hủy script.")
    return
end
warn("[DracoAuto] ✅ Key nhận được: " .. string.sub(NhapKey, 1, 6) .. "***")

-- ==========================================
-- [ PHẦN 0 : CHỌN TEAM & ĐỢI GAME LOAD ]
-- ==========================================
getgenv().Team = getgenv().Team or "Marines"
if not game:IsLoaded() then
    game.Loaded:Wait()
end
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")
if game.Players.LocalPlayer.Team == nil then
    repeat
        task.wait()
        for _, v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                pcall(function()
                    local teamBtn = v.ChooseTeam.Container[getgenv().Team].Frame.TextButton
                    teamBtn.Size     = UDim2.new(0, 10000, 0, 10000)
                    teamBtn.Position = UDim2.new(-4, 0, -5, 0)
                    teamBtn.BackgroundTransparency = 1
                    task.wait(0.5)
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,true,game,1)
                    task.wait(0.05)
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,false,game,1)
                    task.wait(0.05)
                end)
            end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end
repeat task.wait() until game.Players.LocalPlayer.Character
    and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
task.wait(2)

-- ==========================================
-- [ PHẦN 1 ] LÕI LOGIC (CORE)
-- ==========================================
local Player       = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM          = game:GetService("VirtualInputManager")
local COMMF_       = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local Character        = Player.Character
local Humanoid         = Character and Character:FindFirstChild("Humanoid")
local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

local CurrentQuestStatus = "Đang kiểm tra..."
local CurrentActionStatus = "Đang khởi động..."
local CurrentLocationStatus = "Đang đứng yên"

Player.CharacterAdded:Connect(function(v)
    Character        = v
    Humanoid         = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)

-- ==========================================
-- [TWEEN] — Chuẩn Banana Hub
-- ==========================================
local _activeTween = nil

local function TweenTo(targetCFrame, locationName)
    CurrentLocationStatus = "Bay đến: " .. (locationName or "Đảo Hydra")
    local chr = Player.Character
    if not chr or not chr:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = chr:WaitForChild("HumanoidRootPart")
    local hum = chr:WaitForChild("Humanoid")
    
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist <= 150 then 
        hrp.CFrame = targetCFrame
        return true 
    end

    if _activeTween then _activeTween:Cancel() end
    local speed = 320
    local tweenObj = TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    _activeTween = tweenObj

    local noclip
    noclip = RunService.Stepped:Connect(function()
        if hum and hum.Parent then hum:ChangeState(11) end
        if chr and chr.Parent then
            for _, p in pairs(chr:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end)
    
    tweenObj:Play()
    tweenObj.Completed:Wait()
    if noclip then noclip:Disconnect() end
    return true
end

-- ==========================================
-- [FAST ATTACK] — Encrypted
-- ==========================================
local remoteAttack, idremote
local seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()
task.spawn(function()
    for _, v in next, ({ReplicatedStorage.Util, ReplicatedStorage.Common, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.FX}) do
        for _, n in next, v:GetChildren() do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
        end
    end
end)

local lastCallFA = tick()
local function FastAttack(x)
    if not HumanoidRootPart or Character.Humanoid.Health <= 0 then return end
    if tick() - lastCallFA <= 0.01 then return end
    local t = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h = e:FindFirstChild("Humanoid")
        local hrp = e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then
            t[#t + 1] = e
        end
    end
    if #t > 0 then
        local n = ReplicatedStorage.Modules.Net
        local h = {[2] = {}}
        for i = 1, #t do
            local v = t[i]
            local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
            if not h[1] then h[1] = part end
            h[2][#h[2] + 1] = {v, part}
        end
        n:FindFirstChild("RE/RegisterAttack"):FireServer()
        n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
    end
    lastCallFA = tick()
end

-- ==========================================
-- [FLOAT & NPC INTERACT]
-- ==========================================
local _floatTarget = nil
local _floatConn = RunService.Heartbeat:Connect(function()
    pcall(function()
        if _floatTarget and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.CFrame = _floatTarget
            Player.Character.Humanoid:ChangeState(11)
        end
    end)
end)

local function SafeGoTo(targetCFrame, locationName)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if (hrp.Position - targetCFrame.Position).Magnitude > 50 then
        _floatTarget = nil
        TweenTo(targetCFrame, locationName)
    end
    _floatTarget = targetCFrame
end

local function ClaimQuest()
    CurrentActionStatus = "Đang nhận nhiệm vụ tại NPC..."
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
        }))
    end)
end

-- ==========================================
-- [UI]
-- ==========================================
if CoreGui:FindFirstChild("DracoAutoUI") then CoreGui.DracoAutoUI:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "DracoAutoUI"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 240); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35); Title.Text = " Draco Hub - Hydra Fix"; Title.TextColor3 = Color3.fromRGB(255, 200, 0); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.TextSize = 14

local InfoPanel = Instance.new("Frame", MainFrame)
InfoPanel.Size = UDim2.new(1, -20, 1, -50); InfoPanel.Position = UDim2.new(0, 10, 0, 40); InfoPanel.BackgroundTransparency = 1

local function CreateLabel(text, pos)
    local lbl = Instance.new("TextLabel", InfoPanel); lbl.Size = UDim2.new(1, 0, 0, 25); lbl.Position = UDim2.new(0, 0, 0, pos)
    lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255, 255, 255); lbl.Font = Enum.Font.GothamBold; lbl.BackgroundTransparency = 1; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local QuestLabel = CreateLabel("Nhiệm vụ: ...", 0)
local LocationLabel = CreateLabel("Vị trí: ...", 30)
local ActionLabel = CreateLabel("Hành động: ...", 60)
local EmberLabel = CreateLabel("Ember Status: Đang chờ...", 90)

task.spawn(function()
    while true do
        QuestLabel.Text = "Nhiệm vụ: " .. CurrentQuestStatus
        LocationLabel.Text = "Vị trí: " .. CurrentLocationStatus
        ActionLabel.Text = "Hành động: " .. CurrentActionStatus
        task.wait(0.5)
    end
end)

-- ==========================================
-- [CONSTANTS]
-- ==========================================
local DOJO_POS   = CFrame.new(5813, 1208, 884) -- Vị trí chuẩn NPC Dragon Hunter
local ENTRANCE_POS = Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906)
local HYDRA_POS  = CFrame.new(4612, 1002, 498)

-- ==========================================
-- [MAIN LOOP]
-- ==========================================
_G.FarmBlazeEM = true

task.spawn(function()
    while _G.FarmBlazeEM do
        pcall(function()
            local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
            local RF = Net:WaitForChild("RF/DragonHunter")
            
            -- Request Portal (Vào cổng Hydra Island)
            COMMF_:InvokeServer("requestEntrance", ENTRANCE_POS)
            
            local questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
            if not questData or not questData.Text then
                RF:InvokeServer(unpack({[1] = {["Context"] = "RequestQuest"}}))
                questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
            end

            if questData and questData.Text then
                local txt = tostring(questData.Text)
                if string.find(txt, "Head back to the Dojo") then
                    CurrentQuestStatus = "Đã xong! Về Dojo trả quest"
                    SafeGoTo(DOJO_POS, "Dojo Trainer")
                    ClaimQuest()
                elseif string.find(txt, "Defeat") then
                    local mobName = string.find(txt, "Hydra") and "Hydra Enforcer" or "Venomous Assailant"
                    CurrentQuestStatus = "Đang săn: " .. mobName
                    
                    local target = FindClosestMob({mobName})
                    if target then
                        CurrentActionStatus = "Đang tiêu diệt " .. mobName
                        SafeGoTo(target.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0), "Bãi quái Hydra")
                        EquipTool("Melee")
                        FastAttack(mobName)
                    else
                        CurrentActionStatus = "Đợi quái spawn..."
                        SafeGoTo(HYDRA_POS * CFrame.new(0, 25, 0), "Điểm chờ quái")
                    end
                end
            else
                CurrentQuestStatus = "Đang bay về nhận Quest mới..."
                SafeGoTo(DOJO_POS, "Dojo Trainer")
                ClaimQuest()
            end
            
            -- Nhặt Ember Template
            local ember = workspace:FindFirstChild("EmberTemplate")
            if ember and ember:FindFirstChild("Part") then
                EmberLabel.Text = "Ember Status: ĐANG NHẶT!"
                SafeGoTo(ember.Part.CFrame, "Chỗ Ember rơi")
            else
                EmberLabel.Text = "Ember Status: Đang chờ rơi..."
            end
        end)
        task.wait(0.2)
    end
end)
