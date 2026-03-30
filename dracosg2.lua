-- =============================================
-- AUTO DRAGON HUNTER — Combined v3
-- Toggle/Flow: 2.txt | Kill/Tree/Ember: 3.txt
-- Attack: KaitunBoss FastAttack (encrypted)
-- Float: KaitunBoss Heartbeat style
-- =============================================

-- =============================================
-- [SERVICES & VARIABLES]
-- =============================================
local Player            = game.Players.LocalPlayer
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM               = game:GetService("VirtualInputManager")
local COMMF_            = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local Character         = Player.Character
local Humanoid          = Character and Character:FindFirstChild("Humanoid")
local HumanoidRootPart  = Character and Character:FindFirstChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(v)
    Character        = v
    Humanoid         = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)

-- =============================================
-- [TWEEN] — Di chuyển xa (dùng khi cần bay đến vùng mới)
-- =============================================
local function TweenTo(targetCFrame)
    local chr = Player.Character
    if not chr or not chr:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = chr:WaitForChild("HumanoidRootPart")
    local hum = chr:WaitForChild("Humanoid")
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist <= 250 then hrp.CFrame = targetCFrame; return true end

    local speed = 300
    local tweenObj = TweenService:Create(hrp, TweenInfo.new(dist / speed, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
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
    if hum and hum.Parent and hum.Health > 0 then hum:ChangeState(8); return true end
    return false
end

-- =============================================
-- [FAST ATTACK] — KaitunBoss encrypted hit registration
-- =============================================
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
    cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
    end), bit32.bxor(idremote + 909090, seed * 2), unpack(h))
    lastCallFA = tick()
end

-- =============================================
-- [ATTACK NO COOLDOWN] — 3.txt RegisterAttack + RegisterHit
-- =============================================
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

-- =============================================
-- [EQUIP TOOL] — By ToolTip name (3.txt style)
-- =============================================
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

-- =============================================
-- [AUTO HAKI] — 3.txt
-- =============================================
local function AutoHaki()
    pcall(function()
        if Character and not Character:FindFirstChild("HasBuso") then
            COMMF_:InvokeServer("Buso")
        end
    end)
end

-- =============================================
-- [PRESS KEY] — VirtualInputManager
-- =============================================
local function PressKey(key, delay)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(delay or 0)
    VIM:SendKeyEvent(false, key, false, game)
end

-- =============================================
-- [FLOAT SYSTEM] — KaitunBoss Heartbeat style
-- Mỗi frame set CFrame → không bao giờ rơi
-- =============================================
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

-- =============================================
-- [BRING ENEMY] — 3.txt: freeze + resize hitbox
-- =============================================
local function BringEnemy(targetModel)
    pcall(function()
        Player.SimulationRadius = math.huge
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or not vhrp or vh.Health <= 0 then return end

        -- Resize hitbox 60x60x60 (3.txt trick)
        vhrp.Size = Vector3.new(60, 60, 60)
        vhrp.Transparency = 1

        -- Freeze mob
        vh.JumpPower = 0
        vh.WalkSpeed = 0
        vhrp.CanCollide = false

        -- Destroy Animator (Banana style)
        if vh:FindFirstChild("Animator") then
            vh.Animator:Destroy()
        end
    end)
end

-- =============================================
-- [KILL MONSTER] — Lock 1 con, bay trên đầu 20 stud
-- Kết hợp: 3.txt repeat lock + KaitunBoss FastAttack
-- =============================================
local lastKenCall = tick()

local function KillOneMonster(targetModel)
    -- Gọi mỗi tick trong repeat loop
    xpcall(function()
        if not targetModel or not targetModel.Parent then return end
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or vh.Health <= 0 or not vhrp then return end

        -- BringEnemy: resize + freeze (3.txt)
        BringEnemy(targetModel)

        -- Cập nhật floatTarget: bay trên đầu mob 20 stud (3.txt Pos offset)
        _floatTarget = vhrp.CFrame * CFrame.new(0, 20, 0)

        -- Equip + Attack
        EquipTool("Melee")
        AttackNoCoolDown()
        FastAttack(targetModel.Name)

        -- Ken Haki mỗi 10s
        if tick() - lastKenCall >= 10 then
            lastKenCall = tick()
            pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end)
        end
    end, function(e) warn("[DragonHunter] KillOneMonster ERROR:", e) end)
end

-- =============================================
-- [FIND CLOSEST MOB] — Tìm con gần nhất trong danh sách
-- =============================================
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

-- =============================================
-- [checkQuesta()] — 2.txt: parse quest text thông minh
-- =============================================
local function checkQuesta()
    local hasQuest  = false
    local mobName   = nil
    local questCount = nil
    local questType = nil  -- 1=Defeat, 2=Destroy

    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        local RF = Net:WaitForChild("RF/DragonHunter")

        -- RequestQuest (xin quest mới nếu chưa có)
        pcall(function()
            RF:InvokeServer(unpack({[1] = {["Context"] = "RequestQuest"}}))
        end)

        -- Check quest hiện tại
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

-- =============================================
-- [BackTODoJo()] — 2.txt: check notification hoàn thành quest
-- =============================================
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

-- =============================================
-- [CLAIM QUEST] — Dojo Trainer
-- =============================================
local function ClaimQuest()
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
        }))
    end)
end

-- =============================================
-- [REQUEST ENTRANCE] — Vào Hydra Island
-- =============================================
local function RequestEntrance()
    pcall(function()
        COMMF_:InvokeServer("requestEntrance", Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906))
    end)
end

-- =============================================
-- [EQUIP AND USE SKILL] — 3.txt: equip tool + spam Z/X/C/V/F
-- =============================================
local function equipAndUseSkill(toolType)
    pcall(function()
        local backpack = Player.Backpack
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.ToolTip == toolType then
                item.Parent = Player.Character
                for _, skill in ipairs({"Z", "X", "C", "V", "F"}) do
                    task.wait()
                    pcall(function() PressKey(skill) end)
                end
                item.Parent = backpack
                break
            end
        end
    end)
end

-- =============================================
-- [CONSTANTS]
-- =============================================
local DOJO_POS   = CFrame.new(5813, 1208, 884)
local HYDRA_POS  = CFrame.new(4612.078125, 1002.283447265625, 498.2188720703125)

-- 5 tọa độ cây bambootree (3.txt hardcode)
local TREE_TARGETS = {
    CFrame.new(5288.61962890625, 1005.4000244140625, 392.43011474609375),
    CFrame.new(5343.39453125, 1004.1998901367188, 361.0687561035156),
    CFrame.new(5235.78564453125, 1004.1998901367188, 431.4530944824219),
    CFrame.new(5321.30615234375, 1004.1998901367188, 440.8951416015625),
    CFrame.new(5258.96484375, 1004.1998901367188, 345.5052490234375),
}

-- =============================================
-- [RF/DragonHunter RequestQuest THREAD] — 3.txt
-- Thread riêng liên tục request + check quest
-- =============================================
local _questThreadRunning = false

local function StartQuestThread()
    if _questThreadRunning then return end
    _questThreadRunning = true

    -- Request entrance vào Hydra Island
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

-- =============================================
-- [EMBER COLLECT THREAD] — 3.txt: dùng _floatTarget
-- =============================================
local _emberThreadRunning = false

local function StartEmberThread()
    if _emberThreadRunning then return end
    _emberThreadRunning = true

    task.spawn(function()
        while _emberThreadRunning and _G.FarmBlazeEM do
            pcall(function()
                if workspace:FindFirstChild("EmberTemplate") and workspace.EmberTemplate:FindFirstChild("Part") then
                    _floatTarget = workspace.EmberTemplate.Part.CFrame
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

-- =============================================
-- [AUTO HAKI THREAD] — Buso mỗi 4s
-- =============================================
task.spawn(function()
    while true do
        if _G.FarmBlazeEM then AutoHaki() end
        task.wait(4)
    end
end)

-- =============================================
-- [MAIN LOOP] — 2.txt flow + 3.txt kill logic
-- Toggle: _G.FarmBlazeEM (2.txt style)
-- =============================================
_G.FarmBlazeEM = _G.FarmBlazeEM or false

spawn(function()
    while task.wait(0.2) do
        if _G.FarmBlazeEM then
            pcall(function()
                -- Bật các thread phụ
                StartQuestThread()
                StartEmberThread()
                StartFloat()

                -- Check quest (2.txt checkQuesta)
                local hasQuest, mobName, questCount, questType = checkQuesta()

                if hasQuest and not BackTODoJo() then
                    -- ==========================================
                    -- QUEST LOẠI 1: Defeat mob (3.txt kill loop)
                    -- ==========================================
                    if questType == 1 then
                        if mobName == "Hydra Enforcer" or mobName == "Venomous Assailant" then
                            -- Tìm con gần nhất
                            local target = FindClosestMob({mobName})

                            if target then
                                -- Lock 1 con, đánh đến chết (3.txt style)
                                repeat
                                    KillOneMonster(target)
                                    task.wait(0.15)
                                until not _G.FarmBlazeEM
                                    or not target or not target.Parent
                                    or not target:FindFirstChild("Humanoid")
                                    or target.Humanoid.Health <= 0
                                    or BackTODoJo()
                            else
                                -- Mob chưa spawn → float chờ tại vùng mob
                                _floatTarget = HYDRA_POS * CFrame.new(0, 20, 0)
                            end
                        end

                    -- ==========================================
                    -- QUEST LOẠI 2: Destroy bambootree (3.txt)
                    -- 5 tọa độ cây + equipAndUseSkill
                    -- ==========================================
                    elseif questType == 2 then
                        StopFloat() -- tạm tắt float để di chuyển

                        for _, treePos in ipairs(TREE_TARGETS) do
                            if not _G.FarmBlazeEM then break end
                            if BackTODoJo() then break end

                            TweenTo(treePos)
                            task.wait(0.3)

                            -- Check đã đến chưa
                            if HumanoidRootPart and (HumanoidRootPart.Position - treePos.Position).Magnitude <= 10 then
                                AutoHaki()
                                equipAndUseSkill("Melee")
                                equipAndUseSkill("Sword")
                                equipAndUseSkill("Gun")
                            end
                        end

                        StartFloat() -- bật lại float
                    end

                else
                    -- ==========================================
                    -- KHÔNG CÓ QUEST / CẦN CLAIM
                    -- Về Dojo claim rồi nhận quest mới (2.txt flow)
                    -- ==========================================
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
            -- Tắt toggle → dọn dẹp
            StopFloat()
            StopQuestThread()
            StopEmberThread()
        end
    end
end)

warn("[DragonHunter] ✅ Script loaded! Set _G.FarmBlazeEM = true to start.")
