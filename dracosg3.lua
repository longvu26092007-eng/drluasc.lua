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

Player.CharacterAdded:Connect(function(v)
    Character        = v
    Humanoid         = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)

-- ==========================================
-- [TWEEN] — Di chuyển xa (đã fix chống đè Tween)
-- ==========================================
local _activeTween = nil

local function TweenTo(targetCFrame)
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
    if hum and hum.Parent and hum.Health > 0 then hum:ChangeState(8) end
    return true
end

-- ==========================================
-- [FAST ATTACK] — KaitunBoss encrypted hit registration
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
local function FastAttack(x)
    if not HumanoidRootPart or not Character or not Character:FindFirstChildWhichIsA("Humanoid") or Character.Humanoid.Health <= 0 then return end
    if tick() - lastCallFA <= 0.01 then return end
    local t = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h = e:FindFirstChild("Humanoid")
        local hrp = e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then
            t[#t + 1] = e
        end
    end
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
    
    local remoteToFire = typeof(cloneref) == "function" and cloneref(remoteAttack) or remoteAttack
    remoteToFire:FireServer(string.gsub("RE/RegisterHit", ".", function(c)
        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
    end), bit32.bxor(idremote + 909090, seed * 2), unpack(h))
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
-- [EQUIP TOOL & AUTO HAKI & PRESS KEY]
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
-- [FLOAT SYSTEM] — Ngăn lỗi Yo-yo
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
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
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

-- HÀM MỚI: Tự động Tween nếu vị trí quá xa (Chống Yo-yo)
local function SafeGoTo(targetCFrame)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if (hrp.Position - targetCFrame.Position).Magnitude > 50 then
        StopFloat()
        TweenTo(targetCFrame)
        StartFloat()
    end
    _floatTarget = targetCFrame
end

-- ==========================================
-- [BRING ENEMY & FIND MOB & KILL]
-- ==========================================
local function BringEnemy(targetModel)
    pcall(function()
        Player.SimulationRadius = math.huge
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or not vhrp or vh.Health <= 0 then return end

        vhrp.Size = Vector3.new(60, 60, 60)
        vhrp.Transparency = 1
        vh.JumpPower = 0
        vh.WalkSpeed = 0
        vhrp.CanCollide = false

        if vh:FindFirstChild("Animator") then
            vh.Animator:Destroy()
        end
    end)
end

local function FindClosestMob(mobNames)
    local closest = nil
    local closestDist = math.huge
    if not HumanoidRootPart then return nil end
    for _, enemy in pairs(workspace.Enemies:GetChildren()) do
        local eh = enemy:FindFirstChild("Humanoid")
        local ehrp = enemy:FindFirstChild("HumanoidRootPart")
        if eh and ehrp and eh.Health > 0 then
            for _, name in ipairs(mobNames) do
                if enemy.Name == name then
                    local d = (ehrp.Position - HumanoidRootPart.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = enemy
                    end
                end
            end
        end
    end
    return closest
end

local lastKenCall = tick()

local function KillOneMonster(targetModel)
    xpcall(function()
        if not targetModel or not targetModel.Parent then return end
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or vh.Health <= 0 or not vhrp then return end

        -- Bay an toàn tới quái để chống giật
        local attackCFrame = vhrp.CFrame * CFrame.new(0, 20, 0)
        SafeGoTo(attackCFrame)

        BringEnemy(targetModel)

        EquipTool("Melee")
        AttackNoCoolDown()
        FastAttack(targetModel.Name)

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
    local hasQuest  = false
    local mobName   = nil
    local questCount = nil
    local questType = nil

    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        local RF = Net:WaitForChild("RF/DragonHunter")

        pcall(function()
            RF:InvokeServer(unpack({[1] = {["Context"] = "RequestQuest"}}))
        end)

        local questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))

        if questData and questData.Text then
            hasQuest = true
            local txt = tostring(questData.Text)

            if string.find(txt, "Defeat") then
                questType = 1
                questCount = tonumber(string.sub(txt, 8, 9))
                for _, m in pairs({"Hydra Enforcer", "Venomous Assailant"}) do
                    if string.find(txt, m) then
                        mobName = m
                        break
                    end
                end
            elseif string.find(txt, "Destroy") then
                questType = 2
                questCount = 10
            end
        end
    end)
    return hasQuest, mobName, questCount, questType
end

local function BackTODoJo()
    local result = false
    pcall(function()
        for _, b in pairs(Player.PlayerGui.Notifications:GetChildren()) do
            if b.Name == "NotificationTemplate" then
                if string.find(b.Text, "Head back to the Dojo to complete more tasks") then
                    result = true
                end
            end
        end
    end)
    return result
end

local function ClaimQuest()
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
        }))
    end)
end

local function RequestEntrance()
    pcall(function()
        COMMF_:InvokeServer("requestEntrance", Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906))
    end)
end

-- ==========================================
-- [CONSTANTS]
-- ==========================================
local DOJO_POS   = CFrame.new(5813, 1208, 884)
local HYDRA_POS  = CFrame.new(4612.078125, 1002.283447265625, 498.2188720703125)
local TREE_TARGETS = {
    CFrame.new(5288.61962890625, 1005.4000244140625, 392.43011474609375),
    CFrame.new(5343.39453125, 1004.1998901367188, 361.0687561035156),
    CFrame.new(5235.78564453125, 1004.1998901367188, 431.4530944824219),
    CFrame.new(5321.30615234375, 1004.1998901367188, 440.8951416015625),
    CFrame.new(5258.96484375, 1004.1998901367188, 345.5052490234375),
}

-- ==========================================
-- [THREADS] — Quest, Ember, Haki
-- ==========================================
local _questThreadRunning = false
local _isCollectingEmber = false

local function StartQuestThread()
    if _questThreadRunning then return end
    _questThreadRunning = true
    RequestEntrance()
    task.spawn(function()
        while _questThreadRunning and _G.FarmBlazeEM do
            pcall(function()
                local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                local RF = Net:FindFirstChild("RF/DragonHunter")
                if RF then
                    RF:InvokeServer(unpack({[1] = {["Context"] = "RequestQuest"}}))
                    RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
                end
            end)
            task.wait(1)
        end
        _questThreadRunning = false
    end)
end

local function StopQuestThread()
    _questThreadRunning = false
end

local _emberThreadRunning = false
local function StartEmberThread()
    if _emberThreadRunning then return end
    _emberThreadRunning = true
    task.spawn(function()
        while _emberThreadRunning and _G.FarmBlazeEM do
            pcall(function()
                local ember = workspace:FindFirstChild("EmberTemplate")
                if ember and ember:FindFirstChild("Part") then
                    _isCollectingEmber = true
                    SafeGoTo(ember.Part.CFrame)
                else
                    _isCollectingEmber = false
                end
            end)
            task.wait(0.1)
        end
        _emberThreadRunning = false
    end)
end

local function StopEmberThread()
    _emberThreadRunning = false
end

task.spawn(function()
    while true do
        if _G.FarmBlazeEM then AutoHaki() end
        task.wait(4)
    end
end)

-- ==========================================
-- [MAIN LOOP] — Farm Dragon Hunter
-- ==========================================
_G.FarmBlazeEM = _G.FarmBlazeEM or false

spawn(function()
    while task.wait(0.2) do
        if _G.FarmBlazeEM then
            pcall(function()
                StartQuestThread()
                StartEmberThread()
                StartFloat()

                -- Bỏ qua thao tác đánh/nhận quest nếu đang nhặt Ember
                if _isCollectingEmber then return end

                local hasQuest, mobName, questCount, questType = checkQuesta()

                if hasQuest and not BackTODoJo() then
                    -- LOẠI 1: ĐÁNH QUÁI
                    if questType == 1 then
                        if mobName == "Hydra Enforcer" or mobName == "Venomous Assailant" then
                            local target = FindClosestMob({mobName})
                            if target then
                                repeat
                                    if not _isCollectingEmber then
                                        KillOneMonster(target)
                                    end
                                    task.wait(0.15)
                                until not _G.FarmBlazeEM
                                    or not target or not target.Parent
                                    or not target:FindFirstChild("Humanoid")
                                    or target.Humanoid.Health <= 0
                                    or BackTODoJo()
                            else
                                SafeGoTo(HYDRA_POS * CFrame.new(0, 20, 0))
                            end
                        end

                    -- LOẠI 2: ĐỐN CÂY (FIX LỖI BỊ VĂNG SKILL TẠI ĐÂY)
                    elseif questType == 2 then
                        StopFloat() 

                        for _, treePos in ipairs(TREE_TARGETS) do
                            if not _G.FarmBlazeEM then break end
                            if BackTODoJo() then break end

                            TweenTo(treePos)
                            task.wait(0.3)

                            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - treePos.Position).Magnitude <= 50 then
                                -- ĐÓNG BĂNG NHÂN VẬT VÀ XOAY MẶT VÀO CÂY
                                pcall(function()
                                    hrp.Anchored = true
                                    hrp.CFrame = CFrame.new(hrp.Position, treePos.Position)
                                end)
                                
                                AutoHaki()
                                equipAndUseSkill("Melee")
                                equipAndUseSkill("Sword")
                                equipAndUseSkill("Gun")

                                -- XẢ XONG THÌ MỞ KHÓA
                                pcall(function()
                                    if hrp then hrp.Anchored = false end
                                end)
                            end
                        end

                        StartFloat()
                    end

                -- VỀ DOJO NHẬN / TRẢ QUEST
                else
                    StopFloat()

                    if BackTODoJo() then
                        TweenTo(DOJO_POS)
                        task.wait(0.5)
                        ClaimQuest()
                        task.wait(0.5)
                    else
                        TweenTo(DOJO_POS)
                        task.wait(0.5)
                    end

                    StartFloat()
                end
            end)
        else
            StopFloat()
            StopQuestThread()
            StopEmberThread()
        end
    end
end)

warn("[DragonHunter] ✅ Script loaded! Đã fix lỗi Yo-yo và văng skill. Set _G.FarmBlazeEM = true to start.")
