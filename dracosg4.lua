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
        if vh:FindFirstChild("Animator") then vh.Animator:Destroy() end
    end)
end

local function KillOneMonster(targetModel)
    xpcall(function()
        if not targetModel or not targetModel.Parent then return end
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or vh.Health <= 0 or not vhrp then return end

        CurrentActionStatus = "Đang chém: " .. targetModel.Name
        local attackCFrame = vhrp.CFrame * CFrame.new(0, 20, 0)
        SafeGoTo(attackCFrame, "Vùng chém quái")
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
    local hasQuest, mobName, questCount, questType = false, nil, nil, nil
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        local RF = Net:WaitForChild("RF/DragonHunter")
        pcall(function() RF:InvokeServer(unpack({[1] = {["Context"] = "RequestQuest"}})) end)
        local questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
        if questData and questData.Text then
            hasQuest = true
            local txt = tostring(questData.Text)
            if string.find(txt, "Defeat") then
                questType = 1
                questCount = tonumber(string.sub(txt, 8, 9))
                for _, m in pairs({"Hydra Enforcer", "Venomous Assailant"}) do
                    if string.find(txt, m) then mobName = m; break end
                end
                CurrentQuestStatus = "Đánh quái: " .. mobName .. " (" .. questCount .. ")"
            elseif string.find(txt, "Destroy") then
                questType = 2
                questCount = 10
                CurrentQuestStatus = "Đốn cây trúc (10 cây)"
            end
        else
            CurrentQuestStatus = "Không có nhiệm vụ"
        end
    end)
    return hasQuest, mobName, questCount, questType
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
    CurrentActionStatus = "Đang trả nhiệm vụ..."
    pcall(function()
        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
        }))
    end)
end

-- ==========================================
-- [PHẦN 2] GIAO DIỆN MONITOR (VÀNG - ĐEN)
-- ==========================================
if CoreGui:FindFirstChild("DracoAutoUI") then CoreGui.DracoAutoUI:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui); ScreenGui.Name = "DracoAutoUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 240); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35); Title.Text = " Draco Hub VuNguyen - Dragon Hunter"
Title.TextColor3 = Color3.fromRGB(255, 200, 0); Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold; Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Center

local InfoPanel = Instance.new("Frame", MainFrame)
InfoPanel.Size = UDim2.new(1, -20, 1, -50); InfoPanel.Position = UDim2.new(0, 10, 0, 40); InfoPanel.BackgroundTransparency = 1

local function CreateLabel(text, pos)
    local lbl = Instance.new("TextLabel", InfoPanel)
    lbl.Size = UDim2.new(1, 0, 0, 25); lbl.Position = UDim2.new(0, 0, 0, pos)
    lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255, 255, 255); lbl.Font = Enum.Font.GothamBold
    lbl.BackgroundTransparency = 1; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local QuestLabel = CreateLabel("Nhiệm vụ: ...", 0)
local LocationLabel = CreateLabel("Vị trí: ...", 30)
local ActionLabel = CreateLabel("Hành động: ...", 60)
local MasteryLabel = CreateLabel("Mastery: Đang kiểm tra...", 90)
local EmberLabel = CreateLabel("Ember Status: Đang chờ...", 120)

task.spawn(function()
    while true do
        QuestLabel.Text = "Nhiệm vụ: " .. CurrentQuestStatus
        LocationLabel.Text = "Vị trí: " .. CurrentLocationStatus
        ActionLabel.Text = "Hành động: " .. CurrentActionStatus
        task.wait(0.5)
    end
end)

-- ==========================================
-- [CONSTANTS & THREADS]
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

local _questThreadRunning = false
local _isCollectingEmber = false

local function StartQuestThread()
    if _questThreadRunning then return end
    _questThreadRunning = true
    pcall(function() COMMF_:InvokeServer("requestEntrance", Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906)) end)
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
            task.wait(2)
        end
        _questThreadRunning = false
    end)
end

task.spawn(function()
    while true do
        if _G.FarmBlazeEM then
            pcall(function()
                local ember = workspace:FindFirstChild("EmberTemplate")
                if ember and ember:FindFirstChild("Part") then
                    _isCollectingEmber = true
                    EmberLabel.Text = "Ember Status: ĐANG NHẶT EMBER!"
                    EmberLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    SafeGoTo(ember.Part.CFrame, "Chỗ Blaze Ember rơi")
                else
                    _isCollectingEmber = false
                    EmberLabel.Text = "Ember Status: Đang chờ rơi..."
                    EmberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- [MAIN LOOP] — Farm Dragon Hunter
-- ==========================================
_G.FarmBlazeEM = true -- Bật mặc định

spawn(function()
    while task.wait(0.2) do
        if _G.FarmBlazeEM then
            pcall(function()
                StartQuestThread()
                StartFloat()
                if _isCollectingEmber then return end

                local hasQuest, mobName, questCount, questType = checkQuesta()

                if hasQuest and not BackTODoJo() then
                    if questType == 1 then
                        local target = FindClosestMob({mobName})
                        if target then
                            repeat
                                if not _isCollectingEmber then KillOneMonster(target) end
                                task.wait(0.15)
                            until not _G.FarmBlazeEM or not target or not target.Parent or target.Humanoid.Health <= 0 or BackTODoJo()
                        else
                            CurrentActionStatus = "Đang đợi " .. mobName .. " spawn..."
                            SafeGoTo(HYDRA_POS * CFrame.new(0, 20, 0), "Vùng Hydra Island")
                        end
                    elseif questType == 2 then
                        for i, treePos in ipairs(TREE_TARGETS) do
                            if not _G.FarmBlazeEM or BackTODoJo() or _isCollectingEmber then break end
                            CurrentActionStatus = "Đang đốn cây thứ " .. i
                            TweenTo(treePos, "Cây trúc số " .. i)
                            task.wait(0.2)
                            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - treePos.Position).Magnitude <= 50 then
                                pcall(function()
                                    hrp.Anchored = true
                                    hrp.CFrame = CFrame.new(hrp.Position, treePos.Position)
                                end)
                                AutoHaki(); equipAndUseSkill("Melee"); equipAndUseSkill("Sword"); equipAndUseSkill("Gun")
                                pcall(function() if hrp then hrp.Anchored = false end end)
                            end
                        end
                    end
                else
                    StopFloat()
                    if BackTODoJo() then
                        CurrentQuestStatus = "Hoàn thành! Về trả quest."
                        TweenTo(DOJO_POS, "Dojo Trainer")
                        ClaimQuest()
                    else
                        CurrentActionStatus = "Đang bay về Dojo nhận Quest..."
                        TweenTo(DOJO_POS, "Dojo Trainer")
                    end
                    StartFloat()
                end
            end)
        end
    end
end)
