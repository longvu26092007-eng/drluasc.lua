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

local Character        = Player.Character
local Humanoid         = Character and Character:FindFirstChild("Humanoid")
local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(v)
    Character        = v
    Humanoid         = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)

-- ==========================================
-- [ 1.1 ] HỆ THỐNG DI CHUYỂN BÓNG (TWEEN)
-- Fix hoàn toàn lỗi giật tại chỗ
-- ==========================================
local _tweenGhost = nil
local _tweenConn  = nil
local _tweenObj   = nil

local function SmoothTween(targetCFrame, speed)
    speed = speed or 300
    local char = Player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart

    if not _tweenGhost or not _tweenGhost.Parent then
        _tweenGhost = Instance.new("Part")
        _tweenGhost.Name         = "DracoGhost"
        _tweenGhost.Transparency = 1
        _tweenGhost.Anchored     = true
        _tweenGhost.CanCollide   = false
        _tweenGhost.Size         = Vector3.new(50, 50, 50)
        _tweenGhost.CFrame       = hrp.CFrame
        _tweenGhost.Parent       = workspace
    end

    if _tweenObj then _tweenObj:Cancel(); _tweenObj = nil end

    local dist = (targetCFrame.Position - _tweenGhost.Position).Magnitude
    local timeToTween = dist / speed

    if dist > 5000 then
        _tweenGhost.CFrame = targetCFrame
    else
        _tweenObj = TweenService:Create(_tweenGhost, TweenInfo.new(timeToTween, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        _tweenObj:Play()
    end

    if not _tweenConn then
        _tweenConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local c = Player.Character
                if c and c:FindFirstChild("HumanoidRootPart") and _tweenGhost and _tweenGhost.Parent then
                    c.HumanoidRootPart.CFrame = _tweenGhost.CFrame
                    local h = c:FindFirstChild("Humanoid")
                    if h then h.Sit = false end
                    for _, p in pairs(c:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end)
        end)
    end
end

local function StopSmoothTween()
    if _tweenObj then _tweenObj:Cancel(); _tweenObj = nil end
    if _tweenConn then _tweenConn:Disconnect(); _tweenConn = nil end
    if _tweenGhost then _tweenGhost:Destroy(); _tweenGhost = nil end
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

local function TweenTo(targetCFrame, speed)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    SmoothTween(targetCFrame, speed)

    while _tweenGhost and _tweenGhost.Parent and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") do
        local dist = (Player.Character.HumanoidRootPart.Position - targetCFrame.Position).Magnitude
        if dist <= 10 then break end
        task.wait(0.1)
    end
    return true
end

-- ==========================================
-- [ PHẦN 1.3 ] HỆ THỐNG ATTACK
-- Đã fix: Sát thương đa mục tiêu (Array)
-- ==========================================
local COMMF_ = ReplicatedStorage:WaitForChild("Remotes") and ReplicatedStorage.Remotes:WaitForChild("CommF_")
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
            -- TÌM KIẾM THEO LIST (ARRAY)
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

local function EquipWeaponTool(tooltipName)
    if not Character then return end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if tool and tool.ToolTip and tool.ToolTip == tooltipName then return end
    for _, x in next, Player.Backpack:GetChildren() do
        if x:IsA("Tool") and x.ToolTip == tooltipName then
            Humanoid:EquipTool(x)
            return
        end
    end
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
local function EnsureBuso()
    pcall(function()
        if Character and not Character:FindFirstChild("HasBuso") then
            COMMF_:InvokeServer("Buso")
        end
    end)
end

-- ==========================================
-- HÀM ATTACK + BRING MOB (GOM CÙNG LÚC NHIỀU QUÁI)
-- ==========================================
local function SafeKillMob(targetModel, validNamesList)
    xpcall(function()
        if not targetModel or not targetModel.Parent then return end
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or vh.Health <= 0 or not vhrp then return end

        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        pcall(function()
            if setsimulationradius then setsimulationradius(math.huge, math.huge) end
            if sethiddenproperty then sethiddenproperty(Player, "SimulationRadius", math.huge) end
            Player.SimulationRadius = math.huge
        end)

        if not targetModel:GetAttribute("Locked") then
            targetModel:SetAttribute("Locked", vhrp.CFrame)
        end
        local lockedPos = targetModel:GetAttribute("Locked").Position
        local lockedCFrame = CFrame.new(lockedPos)

        -- TÍCH HỢP BRING MOB NHIỀU TÊN CÙNG LÚC
        pcall(function()
            for _, enemy in pairs(workspace.Enemies:GetChildren()) do
                local eh = enemy:FindFirstChild("Humanoid")
                local ehrp = enemy:FindFirstChild("HumanoidRootPart")
                if eh and eh.Health > 0 and ehrp and enemy ~= targetModel then
                    
                    local isValid = false
                    if type(validNamesList) == "table" then
                        for _, n in ipairs(validNamesList) do
                            if enemy.Name == n then isValid = true; break end
                        end
                    else
                        isValid = (enemy.Name == targetModel.Name)
                    end

                    if isValid and (ehrp.Position - lockedPos).Magnitude <= 350 then
                        ehrp.CFrame = lockedCFrame
                        ehrp.CanCollide = false
                        eh.WalkSpeed = 0
                        eh.JumpPower = 0
                        eh:ChangeState(11) 
                        if ehrp:FindFirstChild("BodyVelocity") then ehrp.BodyVelocity:Destroy() end
                    end
                end
            end
        end)

        local dx = hrp.Position.X - lockedPos.X
        local dy = hrp.Position.Y - lockedPos.Y
        local dz = hrp.Position.Z - lockedPos.Z
        local sqrMag = dx*dx + dy*dy + dz*dz

        if sqrMag <= 4900 then
            EquipWeaponTool("Melee")
            FastAttack(validNamesList or targetModel.Name)

            if tick() - lastKenCall >= 10 then
                lastKenCall = tick()
                pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end)
            end

            local yOffset = lockedPos.Y > 60 and -20 or 20
            local attackPos = CFrame.new(lockedPos + Vector3.new(0, yOffset, 0), lockedPos)
            SmoothTween(attackPos, 350)
        else
            SmoothTween(lockedCFrame * CFrame.new(0, 20, 0), 350)
        end
    end, function(e) warn("[DracoAuto] SafeKillMob ERROR:", e) end)
end

local VIM = game:GetService("VirtualInputManager")
local function PressKey(key, delay)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(delay or 0)
    VIM:SendKeyEvent(false, key, false, game)
end

local function UseAllSkills()
    EquipWeaponTool("Melee")
    task.wait(0.1)
    PressKey("Z") PressKey("X") PressKey("C")
    task.wait(0.3)
    EquipWeaponTool("Sword")
    task.wait(0.1)
    PressKey("Z") PressKey("X")
    task.wait(0.3)
    EquipWeaponTool("Melee")
    task.wait(0.1)
    PressKey("Z") PressKey("X") PressKey("C")
end

-- ==========================================
-- [ PHẦN 1.5 ] CHECK BACKPACK & STATS
-- ==========================================
local function CheckHasWeapon(weaponName)
    local chr = Player.Character
    if chr and chr:FindFirstChild(weaponName) then return true end
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(weaponName) then return true end
    local ok, inv = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
        for _, v in pairs(inv) do
            if type(v) == "table" and v.Name == weaponName then return true end
        end
    end
    return false
end

local function getStats()
    local s = { Race = "?", Fragments = 0, Points = 0,
                Melee = 0, Defense = 0, Sword = 0, Gun = 0, Fruit = 0 }
    pcall(function()
        local D     = Player.Data
        s.Race      = D.Race.Value
        s.Fragments = D.Fragments.Value
        s.Points    = D.Points.Value
        local S     = D.Stats
        s.Melee   = S.Melee.Level.Value
        s.Defense = S.Defense.Level.Value
        s.Sword   = S.Sword.Level.Value
        s.Gun     = S.Gun.Level.Value
        s.Fruit   = S["Demon Fruit"].Level.Value
    end)
    return s
end

local function GetWeaponMastery(weaponName)
    local p    = game.Players.LocalPlayer
    local item = p.Backpack:FindFirstChild(weaponName)
        or (p.Character and p.Character:FindFirstChild(weaponName))
    if item and item:FindFirstChild("Level") then
        return item.Level.Value
    end
    return 0
end

-- ==========================================
-- [ PHẦN 1.6 ] HÀM GỌI BANANAHUB GỌN
-- ==========================================
local function LoadBananaHub(config)
    repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
    getgenv().Key    = NhapKey
    getgenv().NewUI  = true
    getgenv().Config = config
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
    end)
    if ok then
        warn("[DracoAuto] BananaHub load OK!")
    else
        warn("[DracoAuto] BananaHub load FAIL: " .. tostring(err))
    end
    return ok
end

-- ==========================================
-- [ PHẦN 2 ] GIAO DIỆN UI (VÀNG - ĐEN)
-- ==========================================
if CoreGui:FindFirstChild("DracoAutoUI") then
    CoreGui.DracoAutoUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DracoAutoUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size             = UDim2.new(0, 450, 0, 265)
MainFrame.Position         = UDim2.new(0.5, -225, 0.5, -107)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active           = true
MainFrame.Draggable        = true
Instance.new("UIStroke", MainFrame).Color        = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size               = UDim2.new(1, 0, 0, 35)
Title.Text               = "Draco Auto"
Title.TextColor3         = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 14
Title.TextXAlignment     = Enum.TextXAlignment.Center

local Line = Instance.new("Frame", Title)
Line.Size             = UDim2.new(1, 0, 0, 1)
Line.Position         = UDim2.new(0, 0, 1, 0)
Line.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
Line.BorderSizePixel  = 0

local InfoPanel = Instance.new("Frame", MainFrame)
InfoPanel.Size               = UDim2.new(1, -20, 1, -50)
InfoPanel.Position           = UDim2.new(0, 10, 0, 40)
InfoPanel.BackgroundTransparency = 1

local ActionStatus = Instance.new("TextLabel", InfoPanel)
ActionStatus.Size               = UDim2.new(1, 0, 0, 22)
ActionStatus.Position           = UDim2.new(0, 0, 0, 0)
ActionStatus.Text               = "Hành động: Khởi động kịch bản..."
ActionStatus.TextColor3         = Color3.fromRGB(200, 200, 200)
ActionStatus.Font               = Enum.Font.Gotham
ActionStatus.BackgroundTransparency = 1
ActionStatus.TextSize           = 12
ActionStatus.TextXAlignment     = Enum.TextXAlignment.Left

local MasteryLabel = Instance.new("TextLabel", InfoPanel)
MasteryLabel.Size               = UDim2.new(1, 0, 0, 22)
MasteryLabel.Position           = UDim2.new(0, 0, 0, 25)
MasteryLabel.Text               = "Mastery: Chờ xác nhận vũ khí..."
MasteryLabel.TextColor3         = Color3.fromRGB(255, 200, 0)
MasteryLabel.Font               = Enum.Font.GothamBold
MasteryLabel.BackgroundTransparency = 1
MasteryLabel.TextSize           = 13
MasteryLabel.TextXAlignment     = Enum.TextXAlignment.Left

local Div = Instance.new("Frame", InfoPanel)
Div.Size             = UDim2.new(1, 0, 0, 1)
Div.Position         = UDim2.new(0, 0, 0, 52)
Div.BackgroundColor3 = Color3.fromRGB(80, 60, 0)
Div.BorderSizePixel  = 0

local RaceLabel = Instance.new("TextLabel", InfoPanel)
RaceLabel.Size               = UDim2.new(1, 0, 0, 22)
RaceLabel.Position           = UDim2.new(0, 0, 0, 58)
RaceLabel.Text               = "🧬 Race: ..."
RaceLabel.TextColor3         = Color3.fromRGB(160, 200, 255)
RaceLabel.Font               = Enum.Font.Gotham
RaceLabel.BackgroundTransparency = 1
RaceLabel.TextSize           = 12
RaceLabel.TextXAlignment     = Enum.TextXAlignment.Left

local FragLabel = Instance.new("TextLabel", InfoPanel)
FragLabel.Size               = UDim2.new(1, 0, 0, 22)
FragLabel.Position           = UDim2.new(0, 0, 0, 82)
FragLabel.Text               = "🔮 Fragments: ..."
FragLabel.TextColor3         = Color3.fromRGB(200, 160, 255)
FragLabel.Font               = Enum.Font.Gotham
FragLabel.BackgroundTransparency = 1
FragLabel.TextSize           = 12
FragLabel.TextXAlignment     = Enum.TextXAlignment.Left

local PointsLabel = Instance.new("TextLabel", InfoPanel)
PointsLabel.Size               = UDim2.new(1, 0, 0, 22)
PointsLabel.Position           = UDim2.new(0, 0, 0, 106)
PointsLabel.Text               = "⭐ Điểm stat chưa dùng: ..."
PointsLabel.TextColor3         = Color3.fromRGB(255, 220, 80)
PointsLabel.Font               = Enum.Font.GothamSemibold
PointsLabel.BackgroundTransparency = 1
PointsLabel.TextSize           = 12
PointsLabel.TextXAlignment     = Enum.TextXAlignment.Left

local StatRowLabel = Instance.new("TextLabel", InfoPanel)
StatRowLabel.Size               = UDim2.new(1, 0, 0, 22)
StatRowLabel.Position           = UDim2.new(0, 0, 0, 130)
StatRowLabel.Text               = "Melee:0 | Def:0 | Sword:0 | Gun:0 | Fruit:0"
StatRowLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
StatRowLabel.Font               = Enum.Font.Gotham
StatRowLabel.BackgroundTransparency = 1
StatRowLabel.TextSize           = 11
StatRowLabel.TextXAlignment     = Enum.TextXAlignment.Left

local WeaponRowLabel = Instance.new("TextLabel", InfoPanel)
WeaponRowLabel.Size               = UDim2.new(1, 0, 0, 22)
WeaponRowLabel.Position           = UDim2.new(0, 0, 0, 154)
WeaponRowLabel.Text               = "Heart: ❌  |  Storm: ❌"
WeaponRowLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
WeaponRowLabel.Font               = Enum.Font.Gotham
WeaponRowLabel.BackgroundTransparency = 1
WeaponRowLabel.TextSize           = 11
WeaponRowLabel.TextXAlignment     = Enum.TextXAlignment.Left

task.spawn(function()
    while ScreenGui.Parent do
        local s = getStats()
        RaceLabel.Text    = "🧬 Race: " .. s.Race
        FragLabel.Text    = "🔮 Fragments: " .. tostring(s.Fragments)
        PointsLabel.Text  = "⭐ Điểm stat chưa dùng: " .. tostring(s.Points)
        StatRowLabel.Text = string.format(
            "Melee:%d | Def:%d | Sword:%d | Gun:%d | Fruit:%d",
            s.Melee, s.Defense, s.Sword, s.Gun, s.Fruit
        )
        local hasHeart = CheckHasWeapon("Dragonheart")
        local hasStorm = CheckHasWeapon("Dragonstorm")
        WeaponRowLabel.Text = string.format(
            "Heart: %s  |  Storm: %s",
            hasHeart and "✅" or "❌",
            hasStorm and "✅" or "❌"
        )
        task.wait(3)
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        EnsureBuso()
        task.wait(4)
    end
end)

-- ==========================================
-- [ PHẦN 3 : AUTOMATIC ]
-- ==========================================
repeat task.wait(0.5) until ScreenGui and ScreenGui.Parent ~= nil
repeat task.wait(0.5) until MainFrame and MainFrame.Visible
task.wait(1)

ActionStatus.Text = "Hành động: UI sẵn sàng, bắt đầu kiểm tra..."

-- ==========================================
-- [ 3.05 ] KIỂM TRA FRAGMENT
-- ==========================================
local FRAGMENT_MIN = 8000

local function GetFragments()
    local val = 0
    pcall(function() val = Player.Data.Fragments.Value end)
    return val
end

do
    local frag = GetFragments()

    if frag < FRAGMENT_MIN then
        ActionStatus.Text = "Hành động: [3.05] Fragment thiếu (" .. frag .. "/" .. FRAGMENT_MIN .. "), bắt đầu farm Katakuri..."

        LoadBananaHub({
            ["Select Method Farm"] = "Farm Katakuri",
            ["Hop Find Katakuri"]  = true,
            ["Start Farm"]         = true,
        })

        repeat
            task.wait(3)
            frag = GetFragments()
            ActionStatus.Text = string.format("Hành động: [3.05] Đang farm Fragment (%d/%d)...", frag, FRAGMENT_MIN)
            FragLabel.Text      = "🔮 Fragments: " .. tostring(frag)
            FragLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        until frag >= FRAGMENT_MIN
        FragLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        ActionStatus.Text    = "Hành động: [3.05] ✅ Đủ Fragment (" .. frag .. ")! Tiếp tục kịch bản..."
        task.wait(1)
    else
        ActionStatus.Text    = "Hành động: [3.05] Fragment đủ (" .. frag .. "), bỏ qua farm!"
        FragLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        task.wait(0.5)
    end
end

-- ==========================================
-- [ 3.1 ] HELPERS DÙNG CHUNG
-- ==========================================
local function EquipWeapon(weaponName)
    local chr = Player.Character
    if chr and chr:FindFirstChild(weaponName) then return true end
    local ok, err = pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("LoadItem", weaponName)
    end)
    return ok
end

local _lastInvCache = nil
local _invFailCount = 0
local function GetInventory()
    local ok, inv = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" and next(inv) ~= nil then
        _lastInvCache = inv
        _invFailCount = 0
        return inv, true
    end
    _invFailCount = _invFailCount + 1
    if _lastInvCache ~= nil then return _lastInvCache, false end
    return {}, false
end

local function HasItem(invData, itemName)
    local chr = Player.Character
    if chr and chr:FindFirstChild(itemName) then return true, 1 end
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(itemName) then return true, 1 end
    for _, v in pairs(invData) do
        if type(v) == "table" and v.Name == itemName then
            return true, (v.Count or 1)
        end
    end
    return false, 0
end

-- ==========================================
-- [ 3.1 ] LUỒNG CHÍNH — CHECK HEART & STORM
-- ==========================================
do
    local inv, _ = GetInventory()
    local hasHeart, _ = HasItem(inv, "Dragonheart")
    local hasStorm, _ = HasItem(inv, "Dragonstorm")

    WeaponRowLabel.Text = string.format("Heart: %s  |  Storm: %s", hasHeart and "✅" or "❌", hasStorm and "✅" or "❌")

    if hasHeart and hasStorm then
        ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonheart..."
        EquipWeapon("Dragonheart")
        task.wait(0.8)
        ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonstorm..."
        EquipWeapon("Dragonstorm")
        task.wait(0.8)
        ActionStatus.Text = "Hành động: [3.1] ✅ Đã equip xong! Chuyển sang 3.2..."
        task.wait(1)
    else
        ActionStatus.Text = "Hành động: [3.1] Chưa có Heart & Storm → farm nguyên liệu..."
        task.wait(1)

        local SCALE_MIN = 5
        local EMBER_MIN = 55

        -- ==========================================
        -- BƯỚC A: FARM DRAGON SCALE
        -- ==========================================
        do
            local invA, _ = GetInventory()
            local _, scaleCount = HasItem(invA, "Dragon Scale")
            if scaleCount >= SCALE_MIN then
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale đủ (" .. scaleCount .. "/5), bỏ qua!"
                task.wait(0.5)
            else
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale thiếu (" .. scaleCount .. "/5) → Farm..."

                local SCALE_MOBS = {"Dragon Crew Archer", "Dragon Crew Warrior"}
                local SCALE_POS  = CFrame.new(6594, 383, 139)
                local _farmingScale = true

                while _farmingScale do
                    pcall(function()
                        local invLoop, _ = GetInventory()
                        local _, nowScale = HasItem(invLoop, "Dragon Scale")
                        ActionStatus.Text = string.format("Hành động: [3.1-A] Đang farm Dragon Scale (%d/5)...", nowScale)

                        if nowScale >= SCALE_MIN then
                            _farmingScale = false
                            return
                        end

                        local target = FindClosestMob(SCALE_MOBS)
                        if target then
                            EnsureBuso()
                            repeat
                                SafeKillMob(target, SCALE_MOBS)
                                task.wait(0.15) 
                            until not _farmingScale
                                or not target or not target.Parent
                                or not target:FindFirstChild("Humanoid")
                                or target.Humanoid.Health <= 0
                        else
                            SmoothTween(SCALE_POS * CFrame.new(0, 30, 0), 300)
                        end
                    end)
                    task.wait(0.2)
                end
                
                StopSmoothTween()

                local invFinal, _ = GetInventory()
                local _, finalScale = HasItem(invFinal, "Dragon Scale")
                if finalScale >= SCALE_MIN then
                    ActionStatus.Text = "Hành động: [3.1-A] ✅ Đủ " .. finalScale .. "/5 Dragon Scale! Kick..."
                    task.wait(2)
                    Player:Kick("\n[ Draco Auto ]\nĐủ 5/5 Dragon Scale!\nRejoin để farm Blaze Ember.")
                end
            end
        end

        -- ==========================================
        -- BƯỚC B: FARM BLAZE EMBER
        -- ==========================================
        do
            local invB, _ = GetInventory()
            local _, emberCount = HasItem(invB, "Blaze Ember")
            if emberCount >= EMBER_MIN then
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember đủ (" .. emberCount .. "/55), bỏ qua!"
                task.wait(0.5)
            else
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember thiếu (" .. emberCount .. "/55) → Farm Dragon Hunter..."

                local DOJO_POS  = CFrame.new(5813, 1208, 884)
                local HYDRA_POS = CFrame.new(4620.61572265625, 1002.2954711914062, 399.0868835449219)
                local _farmingEmber = true
                local isCollectingEmber = false

                local function checkDragonQuest()
                    local hasQuest, mobName, questCount, questType = false, nil, nil, nil
                    pcall(function()
                        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                        local RF  = Net:WaitForChild("RF/DragonHunter")
                        local questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
                        
                        if not questData or not questData.Text then
                            RF:InvokeServer(unpack({[1] = {["Context"] = "RequestQuest"}}))
                            questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
                        end
                        
                        if questData and questData.Text then
                            hasQuest = true
                            local txt = tostring(questData.Text)
                            if string.find(txt, "Defeat") then
                                questType  = 1
                                questCount = tonumber(string.sub(txt, 8, 9))
                                for _, m in pairs({"Hydra Enforcer", "Venomous Assailant"}) do
                                    if string.find(txt, m) then mobName = m; break end
                                end
                            elseif string.find(txt, "Destroy") then
                                questType  = 2
                                questCount = 10
                            end
                        end
                    end)
                    return hasQuest, mobName, questCount, questType
                end

                local function isBackToDojo()
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

                local function claimDragonQuest()
                    pcall(function()
                        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
                            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
                        }))
                    end)
                end

                -- Luồng chuyên săn Ember
                task.spawn(function()
                    while _farmingEmber do
                        pcall(function()
                            local ember = workspace:FindFirstChild("EmberTemplate")
                            if ember and ember:FindFirstChild("Part") then
                                isCollectingEmber = true
                                StopSmoothTween()
                                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = ember.Part.CFrame
                                end
                            else
                                isCollectingEmber = false
                            end
                        end)
                        task.wait(0.1)
                    end
                end)

                while _farmingEmber do
                    pcall(function()
                        if isCollectingEmber then return end

                        local invLoop, _ = GetInventory()
                        local _, nowEmber = HasItem(invLoop, "Blaze Ember")
                        ActionStatus.Text = string.format("Hành động: [3.1-B] Đang farm Blaze Ember (%d/55)...", nowEmber)

                        if nowEmber >= EMBER_MIN then
                            _farmingEmber = false
                            return
                        end

                        local hasQuest, mobName, questCount, questType = checkDragonQuest()

                        if hasQuest and not isBackToDojo() then
                            -- QUEST LOẠI 1: Defeat mob
                            if questType == 1 then
                                if mobName == "Hydra Enforcer" or mobName == "Venomous Assailant" then
                                    local target = FindClosestMob({mobName})
                                    if target then
                                        EnsureBuso()
                                        repeat
                                            SafeKillMob(target, {mobName})
                                            task.wait(0.15)
                                        until not _farmingEmber
                                            or not target or not target.Parent
                                            or not target:FindFirstChild("Humanoid")
                                            or target.Humanoid.Health <= 0
                                            or isBackToDojo()
                                            or isCollectingEmber
                                    else
                                        SmoothTween(HYDRA_POS * CFrame.new(0, 30, 0), 300)
                                    end
                                end

                            -- QUEST LOẠI 2: Destroy bambootree (CƠ CHẾ MỚI CHUẨN BANANA)
                            elseif questType == 2 then
                                pcall(function()
                                    local tree = workspace.Map.Waterfall.IslandModel:FindFirstChild("Meshes/bambootree", true)
                                    if tree then
                                        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                                        local targetPos = tree.CFrame * CFrame.new(0, 5, 20) -- Đứng cách 20 stud, ngang tầm

                                        if hrp and (tree.Position - hrp.Position).Magnitude <= 40 then
                                            -- Dừng toàn bộ di chuyển để tung skill
                                            StopSmoothTween()
                                            
                                            -- Khóa cứng nhân vật trên không bằng BodyVelocity
                                            local bv = hrp:FindFirstChild("SkillHover") or Instance.new("BodyVelocity")
                                            bv.Name = "SkillHover"
                                            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                            bv.Velocity = Vector3.new(0, 0, 0)
                                            bv.Parent = hrp
                                            
                                            -- Quay mặt nhìn thẳng vào cây
                                            hrp.CFrame = CFrame.new(hrp.Position, tree.Position)
                                            
                                            -- Bấm skill
                                            UseAllSkills()
                                            
                                            -- Hủy khóa cứng
                                            if bv then bv:Destroy() end
                                        else
                                            SmoothTween(targetPos, 300)
                                        end
                                    end
                                end)
                            end
                        else
                            StopSmoothTween()
                            if isBackToDojo() then
                                TweenTo(DOJO_POS)
                                task.wait(0.3)
                                claimDragonQuest()
                                task.wait(0.5)
                            else
                                TweenTo(DOJO_POS)
                                task.wait(0.5)
                            end
                        end
                    end)
                    task.wait(0.2)
                end

                StopSmoothTween()
                _farmingEmber = false

                local invFinal, _ = GetInventory()
                local _, finalEmber = HasItem(invFinal, "Blaze Ember")
                if finalEmber >= EMBER_MIN then
                    ActionStatus.Text = "Hành động: [3.1-B] ✅ Đủ " .. finalEmber .. "/55 Blaze Ember! Kick..."
                    task.wait(2)
                    Player:Kick("\n[ Draco Auto ]\nĐủ 55/55 Blaze Ember!\nRejoin để Craft Heart & Storm.")
                end
            end
        end

        ActionStatus.Text = "Hành động: [3.1] ✅ Đủ nguyên liệu! Sang 3.2 (Craft)..."
        task.wait(1)
    end
end

-- ==========================================
-- [ 3.2 ] AUTO CRAFT DRAGONHEART & DRAGONSTORM
-- ==========================================
do
    local invC, _ = GetInventory()
    local hasHeartNow, _ = HasItem(invC, "Dragonheart")
    local hasStormNow, _ = HasItem(invC, "Dragonstorm")

    WeaponRowLabel.Text = string.format("Heart: %s  |  Storm: %s", hasHeartNow and "✅" or "❌", hasStormNow and "✅" or "❌")

    if hasHeartNow and hasStormNow then
        ActionStatus.Text = "Hành động: [3.2] Đã có Heart + Storm, bỏ qua craft!"
        task.wait(1)
    else
        ActionStatus.Text = "Hành động: [3.2] Bắt đầu craft..."
        task.wait(0.5)

        local RFCraft
        local rfOk = pcall(function()
            RFCraft = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RF/Craft")
        end)

        if not rfOk or not RFCraft then
            ActionStatus.Text = "Hành động: [3.2] ❌ Không tìm được RF/Craft!"
        else
            local function RequestEntrance()
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.CommF_
                        :InvokeServer("requestEntrance", Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906))
                end)
            end

            local function CraftItem(itemName)
                local ok, res = pcall(function()
                    return RFCraft:InvokeServer(unpack({[1]="Craft",[2]=itemName,[3]={}}))
                end)
                return ok
            end

            local Craft_CFrame = CFrame.new(5864.833008, 1209.483032, 811.329224)
            ActionStatus.Text = "Hành động: [3.2] Đang bay đến NPC Craft..."
            local arrived = TweenTo(Craft_CFrame)

            if arrived then
                task.wait(0.3)
                RequestEntrance()
                task.wait(0.5)
                if not hasHeartNow then
                    ActionStatus.Text = "Hành động: [3.2] Craft Dragonheart..."
                    CraftItem("Dragonheart")
                    task.wait(3)
                end
                if not hasStormNow then
                    ActionStatus.Text = "Hành động: [3.2] Craft Dragonstorm..."
                    CraftItem("Dragonstorm")
                    task.wait(3)
                end

                local invAfter, _ = GetInventory()
                local heartAfter, _ = HasItem(invAfter, "Dragonheart")
                local stormAfter, _ = HasItem(invAfter, "Dragonstorm")
                WeaponRowLabel.Text = string.format("Heart: %s  |  Storm: %s", heartAfter and "✅" or "❌", stormAfter and "✅" or "❌")

                if heartAfter and stormAfter then
                    ActionStatus.Text = "Hành động: [3.2] ✅ Craft xong! Kick..."
                    task.wait(2)
                    Player:Kick("\n[ Draco Auto ]\nCraft xong Heart & Storm!\nRejoin để đổi Race.")
                else
                    ActionStatus.Text = "Hành động: [3.2] ⚠ Craft chưa đủ! Kiểm tra nguyên liệu!"
                end
            else
                ActionStatus.Text = "Hành động: [3.2] ❌ Bay đến NPC Craft thất bại!"
            end
        end
    end
end

-- ==========================================
-- [ 3.3 ] CHECK RACE DRACO & AUTO ĐỔI RACE
-- ==========================================
do
    local function GetDragonRace()
        local raceStr = "Unknown"
        pcall(function()
            local CommF = game:GetService("ReplicatedStorage").Remotes.CommF_
            local v113  = CommF:InvokeServer("Wenlocktoad", "1")
            local v111  = CommF:InvokeServer("Alchemist", "1")
            local raceName = Player.Data.Race.Value
            if Player.Character and Player.Character:FindFirstChild("RaceTransformed") then
                raceStr = raceName .. "-V4"
            elseif v113 == -2 then
                raceStr = raceName .. "-V3"
            elseif v111 == -2 then
                raceStr = raceName .. "-V2"
            else
                raceStr = raceName .. "-V1"
            end
        end)
        return raceStr
    end

    local function IsDracoDetected()
        local race = GetDragonRace()
        return string.find(race, "Draco") ~= nil or string.find(race, "Dragon") ~= nil
    end

    local function DoChangeRace()
        local success = false
        local ok, err = pcall(function()
            local Net = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net")
            local RF = Net:FindFirstChild("RF/InteractDragonQuest") or Net:WaitForChild("RF/InteractDragonQuest")
            RF:InvokeServer(unpack({[1]={NPC="Dragon Wizard",Command="DragonRace"}}))
            success = true
        end)
        if ok and success then return true else return false end
    end

    local currentRace = GetDragonRace()
    local isDraco     = IsDracoDetected()
    RaceLabel.Text    = "🧬 Race: " .. currentRace

    if isDraco then
        ActionStatus.Text = "Hành động: [3.3] ✅ Đã là race " .. currentRace .. ", bỏ qua!"
        task.wait(1)
    else
        ActionStatus.Text = "Hành động: [3.3] Race: " .. currentRace .. " → Bay đến Dragon Wizard..."
        local Wizard_CFrame = CFrame.new(5773.936035, 1209.442871, 809.224548)
        local arrived = TweenTo(Wizard_CFrame)
        if arrived then
            task.wait(0.3)
            ActionStatus.Text = "Hành động: [3.3] Đang đổi race..."
            local raceOk = DoChangeRace()
            if raceOk then
                task.wait(1)
                local newRace = GetDragonRace()
                RaceLabel.Text = "🧬 Race: " .. newRace
                if IsDracoDetected() then
                    ActionStatus.Text = "Hành động: [3.3] ✅ Đổi race → " .. newRace .. "! Kick..."
                    task.wait(2)
                    Player:Kick("\n[ Draco Auto ]\nĐã đổi sang race " .. newRace .. "!\nRejoin để Farm Mastery.")
                else
                    ActionStatus.Text = "Hành động: [3.3] ⚠ Race vẫn là " .. newRace .. " — kiểm tra điều kiện!"
                end
            else
                ActionStatus.Text = "Hành động: [3.3] ❌ Đổi race thất bại!"
            end
        else
            ActionStatus.Text = "Hành động: [3.3] ❌ Bay đến Wizard thất bại!"
        end
    end
end

-- ==========================================
-- [ 3.4 ] FARM MASTERY DRAGONHEART & DRAGONSTORM
-- ==========================================
do
    local STAT_MAX    = 2800
    local MASTERY_MAX = 500
    local CommF       = game:GetService("ReplicatedStorage").Remotes.CommF_

    local function ResetStat()
        ActionStatus.Text = "Hành động: [3.4] Đang reset stat..."
        pcall(function() CommF:InvokeServer("BlackbeardReward", "Refund", "1") end)
        task.wait(0.3)
        pcall(function() CommF:InvokeServer("BlackbeardReward", "Refund", "2") end)
        task.wait(0.5)
    end

    local function AddStatPoint(statName, amount)
        pcall(function() CommF:InvokeServer("AddPoint", statName, amount) end)
    end

    local function IsStatCorrect(buildType)
        local s = getStats()
        if buildType == "Sword" then
            return s.Melee >= STAT_MAX and s.Defense >= STAT_MAX and s.Sword >= STAT_MAX
        elseif buildType == "Gun" then
            return s.Melee >= STAT_MAX and s.Defense >= STAT_MAX and s.Gun >= STAT_MAX
        end
        return false
    end

    ActionStatus.Text = "Hành động: [3.4] Đang equip Dragonheart & Dragonstorm..."
    EquipWeapon("Dragonheart")
    task.wait(0.5)
    EquipWeapon("Dragonstorm")
    task.wait(0.5)

    local heartMastery = GetWeaponMastery("Dragonheart")
    local stormMastery = GetWeaponMastery("Dragonstorm")

    MasteryLabel.Text = string.format("Mastery: Heart %d/500 | Storm %d/500", heartMastery, stormMastery)

    -- LUỒNG 1: DRAGONHEART (SWORD) MASTERY < 500
    if heartMastery < MASTERY_MAX then
        ActionStatus.Text = "Hành động: [3.4-L1] Heart mastery " .. heartMastery .. "/500 → Kiểm tra stat Sword build..."

        if IsStatCorrect("Sword") then
            ActionStatus.Text = "Hành động: [3.4-L1] ✅ Stat đã đúng Sword build, giữ nguyên!"
            task.wait(1)
        else
            for i = 5, 1, -1 do
                ActionStatus.Text = "Hành động: [3.4-L1] Stat chưa đúng! Reset sau " .. i .. "s..."
                task.wait(1)
            end
            ResetStat()
            task.wait(0.5)
            ActionStatus.Text = "Hành động: [3.4-L1] Nâng Melee → " .. STAT_MAX .. "..."
            AddStatPoint("Melee", STAT_MAX)
            task.wait(0.3)
            ActionStatus.Text = "Hành động: [3.4-L1] Nâng Defense → " .. STAT_MAX .. "..."
            AddStatPoint("Defense", STAT_MAX)
            task.wait(0.3)
            ActionStatus.Text = "Hành động: [3.4-L1] Nâng Sword → " .. STAT_MAX .. "..."
            AddStatPoint("Sword", STAT_MAX)
            task.wait(0.3)
        end

        ActionStatus.Text = "Hành động: [3.4-L1] Đang load BananaHub farm Heart (Sword) mastery..."
        LoadBananaHub({
            ["Select Weapon"]      = "Sword",
            ["Select Method Farm"] = "Farm Bones",
            ["Start Farm"]         = true,
        })

        repeat
            task.wait(10)
            heartMastery = GetWeaponMastery("Dragonheart")
            MasteryLabel.Text = string.format("Mastery: Heart %d/500 | Storm %d/500", heartMastery, stormMastery)
            MasteryLabel.TextColor3 = heartMastery >= MASTERY_MAX and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 200, 0)
            ActionStatus.Text = string.format("Hành động: [3.4-L1] Đang farm Heart mastery (%d/500)...", heartMastery)
        until heartMastery >= MASTERY_MAX

        ActionStatus.Text = "Hành động: [3.4-L1] ✅ Heart mastery đạt " .. heartMastery .. "/500! Kick..."
        task.wait(2)
        Player:Kick("\n[ Draco Auto ]\nDragonheart đạt " .. heartMastery .. "/500 Mastery!\nRejoin để farm Dragonstorm mastery.")

    -- LUỒNG 2: HEART >= 500 → FARM DRAGONSTORM (GUN) MASTERY
    else
        stormMastery = GetWeaponMastery("Dragonstorm")
        MasteryLabel.Text = string.format("Mastery: Heart %d/500 | Storm %d/500", heartMastery, stormMastery)

        if stormMastery >= MASTERY_MAX then
            ActionStatus.Text = "Hành động: [3.4-L2] ✅ Cả Heart + Storm đều đủ 500!"
            pcall(function() writefile(Player.Name .. ".txt", "Completed-mastery") end)
            for i = 10, 1, -1 do
                ActionStatus.Text = "Hành động: [3.4-L2] ✅ HOÀN THÀNH! Kick sau " .. i .. "s..."
                task.wait(1)
            end
            Player:Kick("\n[ Draco Auto ]\n✅ HOÀN THÀNH!\nHeart: " .. heartMastery .. "/500 | Storm: " .. stormMastery .. "/500\nFile " .. Player.Name .. ".txt đã ghi.")
        else
            ActionStatus.Text = "Hành động: [3.4-L2] Storm mastery " .. stormMastery .. "/500 → Kiểm tra stat Gun build..."
            if IsStatCorrect("Gun") then
                ActionStatus.Text = "Hành động: [3.4-L2] ✅ Stat đã đúng Gun build, giữ nguyên!"
                task.wait(1)
            else
                for i = 5, 1, -1 do
                    ActionStatus.Text = "Hành động: [3.4-L2] Stat chưa đúng! Reset sau " .. i .. "s..."
                    task.wait(1)
                end
                ResetStat()
                task.wait(0.5)
                ActionStatus.Text = "Hành động: [3.4-L2] Nâng Melee → " .. STAT_MAX .. "..."
                AddStatPoint("Melee", STAT_MAX)
                task.wait(0.3)
                ActionStatus.Text = "Hành động: [3.4-L2] Nâng Defense → " .. STAT_MAX .. "..."
                AddStatPoint("Defense", STAT_MAX)
                task.wait(0.3)
                ActionStatus.Text = "Hành động: [3.4-L2] Nâng Gun → " .. STAT_MAX .. "..."
                AddStatPoint("Gun", STAT_MAX)
                task.wait(0.3)
            end

            ActionStatus.Text = "Hành động: [3.4-L2] Đang load BananaHub farm Storm (Gun) mastery..."
            LoadBananaHub({
                ["Select Weapon"]              = "Melee",
                ["Select Method Farm"]         = "Farm Bones",
                ["Select Method Farm Mastery"] = "Gun",
                ["Health %"]                   = "45",
                ["Farm Mastery"]               = true,
                ["Start Farm"]                 = true,
            })

            repeat
                task.wait(10)
                stormMastery = GetWeaponMastery("Dragonstorm")
                MasteryLabel.Text = string.format("Mastery: Heart %d/500 | Storm %d/500", heartMastery, stormMastery)
                MasteryLabel.TextColor3 = stormMastery >= MASTERY_MAX and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 200, 0)
                ActionStatus.Text = string.format("Hành động: [3.4-L2] Đang farm Storm mastery (%d/500)...", stormMastery)
            until stormMastery >= MASTERY_MAX

            ActionStatus.Text = "Hành động: [3.4-L2] ✅ Storm mastery đạt " .. stormMastery .. "/500! Ghi file..."
            pcall(function() writefile(Player.Name .. ".txt", "Completed-mastery") end)
            for i = 10, 1, -1 do
                ActionStatus.Text = "Hành động: [3.4-L2] ✅ HOÀN THÀNH! Kick sau " .. i .. "s..."
                task.wait(1)
            end
            Player:Kick("\n[ Draco Auto ]\n✅ HOÀN THÀNH!\nHeart: " .. heartMastery .. "/500 | Storm: " .. stormMastery .. "/500\nFile " .. Player.Name .. ".txt đã ghi.")
        end
    end
end
