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

-- BIẾN STATUS ĐỂ HIỆN LÊN UI
local CurrentQuestStatus = "Đang kiểm tra..."
local CurrentActionStatus = "Đang khởi động..."
local CurrentLocationStatus = "Đang đứng yên"

Player.CharacterAdded:Connect(function(v)
    Character        = v
    Humanoid         = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)

-- ==========================================
-- [TWEEN] — Di chuyển xa (Bypass AntiCheat)
-- ==========================================
local _activeTween = nil

local function TweenTo(targetCFrame, locationName)
    CurrentLocationStatus = "Bay đến: " .. (locationName or "Tọa độ lạ")
    local chr = Player.Character
    if not chr or not chr:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = chr:WaitForChild("HumanoidRootPart")
    local hum = chr:WaitForChild("Humanoid")
    
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist <= 150 then 
        hrp.CFrame = targetCFrame
        CurrentLocationStatus = "Đã đến: " .. (locationName or "Đểm đích")
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
    if hum and hum.Parent and hum.Health > 0 then hum:ChangeState(8) end
    CurrentLocationStatus = "Đã đến: " .. (locationName or "Điểm đích")
    return true
end

-- ==========================================
-- [FAST ATTACK] — KaitunBoss encrypted hit
-- ==========================================
local remoteAttack, idremote
local seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()

task.spawn(function()
    for _, v in next, ({ReplicatedStorage.Util, ReplicatedStorage.Common, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.FX}) do
        for _, n in next, v:GetChildren() do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                remoteAttack, idremote = n, n:GetAttribute("Id")
            end
        end
        v.ChildAdded:Connect(function(n)
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                remoteAttack, idremote = n, n:GetAttribute("Id")
            end
        end)
    end
end)

local lastCallFA = tick()
local function FastAttack(validNames)
    if not HumanoidRootPart or not Character or not Character:FindFirstChildWhichIsA("Humanoid") or Character.Humanoid.Health <= 0 then return end
    local FAD = 0.01
    if FAD ~= 0 and tick() - lastCallFA <= FAD then return end
    
    local t = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h = e:FindFirstChild("Humanoid")
        local hrp = e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then
            local isValid = false
            if type(validNames) == "table" then
                for _, n in ipairs(validNames) do
                    if e.Name == n then isValid = true; break end
                end
            elseif type(validNames) == "string" then
                isValid = (e.Name == validNames)
            elseif validNames == nil then
                isValid = true
            end

            if isValid then
                t[#t + 1] = e
            end
        end
    end
    
    if #t > 0 then
        local n = ReplicatedStorage.Modules.Net
        local h = {[2] = {}}
        local last
        for i = 1, #t do
            local v = t[i]
            local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
            if not h[1] then h[1] = part end
            h[2][#h[2] + 1] = {v, part}
            last = v
        end
        n:FindFirstChild("RE/RegisterAttack"):FireServer()
        n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
        
        local attackRemote = typeof(cloneref) == "function" and cloneref(remoteAttack) or remoteAttack
        attackRemote:FireServer(string.gsub("RE/RegisterHit", ".", function(c)
            return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
        end), bit32.bxor(idremote + 909090, seed * 2), unpack(h))
    end
    lastCallFA = tick()
end

local function AttackNoCoolDown()
    pcall(function()
        local chr = Player.Character
        if not chr then return end
        local equippedWeapon = chr:FindFirstChildWhichIsA("Tool")
        if not equippedWeapon then return end
        local targets = {}
        local mainTarget = nil
        local playerPos = chr:GetPivot().Position
        for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
            if not enemy:GetAttribute("IsBoat") then
                local eh = enemy:FindFirstChild("Humanoid")
                local head = enemy:FindFirstChild("Head")
                if eh and head and eh.Health > 0 and (playerPos - head.Position).Magnitude <= 60 then
                    table.insert(targets, {enemy, head})
                    mainTarget = head
                end
            end
        end
        if not mainTarget then return end
        local storage = ReplicatedStorage
        local attackEvent = storage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterAttack")
        local hitEvent = storage:WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RE/RegisterHit")
        attackEvent:FireServer(0.0000000000001)
        hitEvent:FireServer(mainTarget, targets)
    end)
end

-- ==========================================
-- [HELPERS: HAKI, TOOL, SKILL]
-- ==========================================
local function EquipTool(toolTip)
    if not Character then return end
    local current = Character:FindFirstChildWhichIsA("Tool")
    if current and current.ToolTip == toolTip then return end
    for _, item in pairs(Player.Backpack:GetChildren()) do
        if item:IsA("Tool") and item.ToolTip == toolTip then
            Humanoid:EquipTool(item)
            return
        end
    end
end

local function AutoHaki()
    pcall(function()
        if Character and not Character:FindFirstChild("HasBuso") then
            COMMF_:InvokeServer("Buso")
        end
    end)
end

local function PressKey(key, delay)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(delay or 0)
    VIM:SendKeyEvent(false, key, false, game)
end

local function equipAndUseSkill(toolType)
    pcall(function()
        local backpack = Player.Backpack
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.ToolTip == toolType then
                item.Parent = Player.Character
                for _, skill in ipairs({"Z", "X", "C", "V", "F"}) do
                    task.wait(0.1)
                    pcall(function() PressKey(skill) end)
                end
                item.Parent = backpack
                break
            end
        end
    end)
end

-- ==========================================
-- [FLOAT SYSTEM] — Chống bay giật Yo-yo
-- ==========================================
local _floatConn   = nil
local _floatTarget = nil

local function StartFloat()
    if _floatConn then return end
    _floatConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local chr = Player.Character
            if not chr then return end
            local hrp = chr:FindFirstChild("HumanoidRootPart")
            local hum = chr:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end
            if _floatTarget then
                hrp.CFrame = _floatTarget
            end
            hum.Sit = false
            hum:ChangeState(11)
            for _, part in pairs(chr:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end)
    end)
end

local function StopFloat()
    if _floatConn then _floatConn:Disconnect(); _floatConn = nil end
    _floatTarget = nil
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid:ChangeState(8)
        end
    end)
end

local function SafeGoTo(targetCFrame, locationName)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if (hrp.Position - targetCFrame.Position).Magnitude > 50 then
        StopFloat()
        TweenTo(targetCFrame, locationName)
        StartFloat()
    end
    _floatTarget = targetCFrame
end

-- ==========================================
-- [GOM QUÁI & DIỆT QUÁI]
-- ==========================================
local function BringEnemy(targetModel, validNamesList)
    pcall(function()
        Player.SimulationRadius = math.huge
        local lockedPos = targetModel:GetAttribute("LockedPos") or targetModel.HumanoidRootPart.Position
        for _, enemy in pairs(workspace.Enemies:GetChildren()) do
            local eh = enemy:FindFirstChild("Humanoid")
            local ehrp = enemy:FindFirstChild("HumanoidRootPart")
            if eh and eh.Health > 0 and ehrp then
                local isValid = false
                if type(validNamesList) == "table" then
                    for _, n in ipairs(validNamesList) do
                        if enemy.Name == n then isValid = true; break end
                    end
                else
                    isValid = (enemy.Name == validNamesList)
                end
                if isValid and (ehrp.Position - lockedPos).Magnitude <= 350 then
                    ehrp.CFrame = CFrame.new(lockedPos)
                    ehrp.CanCollide = false
                    eh.WalkSpeed = 0
                    if eh:FindFirstChild("Animator") then eh.Animator:Destroy() end
                end
            end
        end
    end)
end

local function KillOneMonster(targetModel, validNamesList)
    xpcall(function()
        if not targetModel or not targetModel.Parent then return end
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or vh.Health <= 0 or not vhrp then return end

        CurrentActionStatus = "Đang chém: " .. targetModel.Name
        local attackCFrame = vhrp.CFrame * CFrame.new(0, 20, 0)
        SafeGoTo(attackCFrame, "Vùng chém quái")
        BringEnemy(targetModel, validNamesList)
        EquipTool("Melee")
        AttackNoCoolDown()
        FastAttack(validNamesList)

        if tick() - lastKenCall >= 10 then
            lastKenCall = tick()
            pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end)
        end
    end, function(e) warn("[DragonHunter] KillOneMonster ERROR:", e) end)
end

-- ==========================================
-- [HỆ THỐNG QUEST VÀ NPC]
-- ==========================================
local function checkQuesta()
    local hasQuest, mobName, questType = false, nil, nil
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        local RF = Net:WaitForChild("RF/DragonHunter")
        local questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
        if questData and questData.Text then
            hasQuest = true
            local txt = tostring(questData.Text)
            if string.find(txt, "Defeat") then
                questType = 1
                mobName = string.find(txt, "Hydra") and "Hydra Enforcer" or "Venomous Assailant"
                CurrentQuestStatus = "Nhiệm vụ: Tiêu diệt " .. mobName
            elseif string.find(txt, "Destroy") then
                questType = 2
                CurrentQuestStatus = "Nhiệm vụ: Đốn cây trúc"
            end
        else
            CurrentQuestStatus = "Nhiệm vụ: Chưa nhận"
        end
    end)
    return hasQuest, mobName, questType
end

local function BackTODoJo()
    local result = false
    pcall(function()
        for _, b in pairs(Player.PlayerGui.Notifications:GetChildren()) do
            if b.Name == "NotificationTemplate" and string.find(b.Text, "Head back to the Dojo") then
                result = true
            end
        end
    end)
    return result
end

local function ClaimQuest()
    CurrentActionStatus = "Đang nhận quest tại NPC Dragon Hunter..."
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
        }))
    end)
end

-- ==========================================
-- [PHẦN 2] GIAO DIỆN MONITOR
-- ==========================================
if CoreGui:FindFirstChild("DracoAutoUI") then CoreGui.DracoAutoUI:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "DracoAutoUI"
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 240); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35); Title.Text = " Draco Hub - Dragon Hunter Logic"; Title.TextColor3 = Color3.fromRGB(255, 200, 0); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.TextSize = 14

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
local TimerLabel = CreateLabel("Chờ quái: ...", 90)

task.spawn(function()
    while true do
        QuestLabel.Text = CurrentQuestStatus
        LocationLabel.Text = CurrentLocationStatus
        ActionLabel.Text = "Hành động: " .. CurrentActionStatus
        task.wait(0.5)
    end
end)

-- ==========================================
-- [CONSTANTS & MAIN LOGIC]
-- ==========================================
local DOJO_POS   = CFrame.new(5813, 1208, 884)
local HYDRA_POS  = CFrame.new(4612, 1002, 498)
local ENTRANCE_POS = Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906)
local TREE_TARGETS = {
    CFrame.new(5288.61962890625, 1005.4000244140625, 392.43011474609375),
    CFrame.new(5343.39453125, 1004.1998901367188, 361.0687561035156),
    CFrame.new(5235.78564453125, 1004.1998901367188, 431.4530944824219),
    CFrame.new(5321.30615234375, 1004.1998901367188, 440.8951416015625),
    CFrame.new(5258.96484375, 1004.1998901367188, 345.5052490234375),
}

_G.FarmBlazeEM = true

task.spawn(function()
    while _G.FarmBlazeEM do
        pcall(function()
            local hasQuest, mobName, questType = checkQuesta()

            -- [BƯỚC 1: NẾU CHƯA CÓ QUEST -> BAY ĐẾN NPC NHẬN]
            if not hasQuest or BackTODoJo() then
                StopFloat()
                TweenTo(DOJO_POS, "NPC Dragon Hunter")
                ClaimQuest()
                task.wait(1)

            -- [BƯỚC 2: ĐANG LÀM QUEST]
            else
                if questType == 1 then -- Đánh quái
                    -- [BAY ĐẾN TỌA ĐỘ BÃI QUÁI TRƯỚC]
                    TweenTo(HYDRA_POS * CFrame.new(0, 25, 0), "Bãi quái Hydra Island")
                    
                    -- [ĐỢI 5 GIÂY ĐỂ SERVER SPAWN QUÁI]
                    for i = 5, 1, -1 do
                        TimerLabel.Text = "Chờ quái load: " .. i .. "s..."
                        CurrentActionStatus = "Đang đứng chờ quái xuất hiện..."
                        task.wait(1)
                    end
                    TimerLabel.Text = "Chờ quái: XONG"

                    -- [BẮT ĐẦU VÒNG LẶP ĐÁNH QUÁI]
                    StartFloat()
                    while _G.FarmBlazeEM and checkQuesta() and not BackTODoJo() do
                        COMMF_:InvokeServer("requestEntrance", ENTRANCE_POS)
                        
                        local target = FindClosestMob({mobName})
                        if target then
                            KillOneMonster(target, {mobName})
                        else
                            CurrentActionStatus = "Hết quái, đang đợi..."
                            _floatTarget = HYDRA_POS * CFrame.new(0, 25, 0)
                        end
                        task.wait(0.2)
                        
                        -- Nhặt Ember Template
                        local ember = workspace:FindFirstChild("EmberTemplate")
                        if ember and ember:FindFirstChild("Part") then
                            _floatTarget = ember.Part.CFrame
                            task.wait(0.2)
                        end
                    end
                
                elseif questType == 2 then -- Đốn cây
                    StopFloat()
                    for i, treePos in ipairs(TREE_TARGETS) do
                        if not _G.FarmBlazeEM or BackTODoJo() then break end
                        TweenTo(treePos, "Cây trúc số " .. i)
                        if HumanoidRootPart and (HumanoidRootPart.Position - treePos.Position).Magnitude <= 50 then
                            pcall(function()
                                HumanoidRootPart.Anchored = true
                                HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, treePos.Position)
                                AutoHaki(); equipAndUseSkill("Melee"); equipAndUseSkill("Sword"); equipAndUseSkill("Gun")
                                HumanoidRootPart.Anchored = false
                            end)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)
