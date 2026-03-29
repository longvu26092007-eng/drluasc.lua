-- ==========================================
-- [ KEY CHECK ] — Lấy key từ executor bên ngoài
-- ==========================================
-- Cách dùng ở executor:
--   getgenv().Key = "51e126ee832d3c4fff7b6178"
--   loadstring(game:HttpGet("...link git chứa lua..."))()
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

local function TweenTo(targetCFrame)
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

    local hrp      = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance <= 250 then
        hrp.CFrame = targetCFrame
        return true
    end

    local bv = hrp:FindFirstChild("DracoAntiGravity") or Instance.new("BodyVelocity")
    bv.Name     = "DracoAntiGravity"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent   = hrp

    local speed    = 300
    local time     = distance / speed
    local tweenObj = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCFrame})

    local noclip
    noclip = RunService.Stepped:Connect(function()
        if humanoid and humanoid.Parent then
            humanoid:ChangeState(11)
        end
        if character and character.Parent then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    tweenObj:Play()
    tweenObj.Completed:Wait()

    if bv and bv.Parent then bv:Destroy() end
    if noclip then noclip:Disconnect() end

    if humanoid and humanoid.Parent and humanoid.Health > 0 then
        humanoid:ChangeState(8)
        return true
    end
    return false
end

-- ==========================================
-- [ PHẦN 1.3 ] HỆ THỐNG ATTACK (từ KaitunBoss)
-- Bảo mật: seed + remoteAttack + XOR encrypted hit
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
local function FastAttack(x)
    if not HumanoidRootPart or not Character or not Character:FindFirstChildWhichIsA("Humanoid") or Character.Humanoid.Health <= 0 then return end
    local FAD = 0.01
    if FAD ~= 0 and tick() - lastCallFA <= FAD then return end
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
    cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
    end), bit32.bxor(idremote + 909090, seed * 2), unpack(h))
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

-- BringEnemy: kéo mob về 1 điểm, freeze movement (từ Banana)
local function BringEnemy(centerPos)
    pcall(function()
        Player.SimulationRadius = math.huge
        for _, v in pairs(workspace.Enemies:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
                if (v.HumanoidRootPart.Position - centerPos).Magnitude <= 300 then
                    v.HumanoidRootPart.CFrame = CFrame.new(centerPos)
                    v.HumanoidRootPart.CanCollide = true
                    v.Humanoid.WalkSpeed = 0
                    v.Humanoid.JumpPower = 0
                    if v.Humanoid:FindFirstChild("Animator") then
                        v.Humanoid.Animator:Destroy()
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- Ghost Float System (KaitunBoss TweenGhost pattern)
-- Part ẩn Anchored 50x50x50, Heartbeat mỗi frame lock player → không rơi
-- ==========================================
local _floatGhost = nil     -- Part anchored ẩn
local _floatConn  = nil     -- Heartbeat connection

local function StartFloat()
    if _floatConn then return end

    -- Tạo ghost part giống KaitunBoss: Anchored, 50x50x50, ẩn
    if not _floatGhost or not _floatGhost.Parent then
        _floatGhost = Instance.new("Part")
        _floatGhost.Name         = "DracoFloatGhost"
        _floatGhost.Transparency = 1
        _floatGhost.Anchored     = true
        _floatGhost.CanCollide   = false
        _floatGhost.Size         = Vector3.new(50, 50, 50)
        _floatGhost.Parent       = workspace
        if HumanoidRootPart then
            _floatGhost.CFrame = HumanoidRootPart.CFrame
        end
    end

    -- Heartbeat: MỖI FRAME lock player CFrame = ghost CFrame (KaitunBoss cách làm)
    _floatConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local chr = Player.Character
            if not chr then return end
            local hrp = chr:FindFirstChild("HumanoidRootPart")
            local hum = chr:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end

            -- Lock CFrame mỗi frame → player dính ghost, không rơi
            if _floatGhost and _floatGhost.Parent then
                hrp.CFrame = _floatGhost.CFrame
            end

            -- Noclip
            hum.Sit = false
            for _, part in pairs(chr:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

-- Di chuyển ghost → player tự bay theo mỗi frame
local function SetFloatPos(cf)
    if _floatGhost and _floatGhost.Parent then
        _floatGhost.CFrame = cf
    end
end

local function StopFloat()
    if _floatConn then _floatConn:Disconnect(); _floatConn = nil end
    pcall(function()
        if _floatGhost and _floatGhost.Parent then _floatGhost:Destroy() end
        _floatGhost = nil
    end)
    pcall(function()
        local chr = Player.Character
        if chr and chr:FindFirstChild("Humanoid") then
            chr.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

-- Tìm mob gần nhất trong danh sách tên
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
-- KillMonster: bay trên đầu 1 con mob, đánh nó (gọi mỗi tick trong repeat loop)
-- SetFloatPos di chuyển ghost → Heartbeat giữ player ở đó liên tục
local function KillMonster(targetModel)
    xpcall(function()
        if not targetModel or not targetModel.Parent then return end
        local vh = targetModel:FindFirstChild("Humanoid")
        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
        if not vh or vh.Health <= 0 or not vhrp then return end

        -- Lock vị trí gốc của mob (Banana style)
        if not targetModel:GetAttribute("Locked") then
            targetModel:SetAttribute("Locked", vhrp.CFrame)
        end
        local lockedPos = targetModel:GetAttribute("Locked").Position

        -- BringEnemy: kéo mob về, freeze
        BringEnemy(lockedPos)

        -- Di chuyển ghost trên đầu mob 30 stud → Heartbeat lock player theo
        SetFloatPos(vhrp.CFrame * CFrame.new(0, 30, 0) * CFrame.Angles(0, math.rad(180), 0))

        -- Equip + FastAttack (KaitunBoss encrypted)
        EquipWeaponTool("Melee")
        FastAttack(targetModel.Name)

        -- Ken Haki mỗi 10s
        if tick() - lastKenCall >= 10 then
            lastKenCall = tick()
            pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end)
        end

    end, function(e) warn("[DracoAuto] KillMonster ERROR:", e) end)
end

local function EnsureBuso()
    pcall(function()
        if Character and not Character:FindFirstChild("HasBuso") then
            COMMF_:InvokeServer("Buso")
        end
    end)
end

-- PressKey: bấm phím skill (từ KaitunBoss PressKeyEvent + Banana Useskills)
local VIM = game:GetService("VirtualInputManager")
local function PressKey(key, delay)
    VIM:SendKeyEvent(true, key, false, game)
    task.wait(delay or 0)
    VIM:SendKeyEvent(false, key, false, game)
end

-- UseSkills: spam tất cả skills để phá bambootree (từ Banana)
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
-- Dùng NhapKey từ executor, không hardcode key
-- ==========================================
local function LoadBananaHub(config)
    repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
    getgenv().Key    = NhapKey       -- ← key từ executor
    getgenv().NewUI  = true
    getgenv().Config = config
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
    end)
    if ok then
        warn("[DracoAuto] BananaHub load OK! (key=" .. string.sub(NhapKey, 1, 6) .. "***)")
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

-- Thread bật Buso Haki định kỳ (từ KaitunBoss)
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
        warn("[DracoAuto] [3.05] Fragment = " .. frag .. " < " .. FRAGMENT_MIN .. " → Chạy FarmFragment!")

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
        warn("[DracoAuto] [3.05] Fragment đủ rồi → tiếp tục 3.1!")
        task.wait(1)
    else
        ActionStatus.Text    = "Hành động: [3.05] Fragment đủ (" .. frag .. "), bỏ qua farm!"
        FragLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        warn("[DracoAuto] [3.05] Fragment = " .. frag .. " >= " .. FRAGMENT_MIN .. " → Bỏ qua farm, vào 3.1!")
        task.wait(0.5)
    end
end

-- ==========================================
-- [ 3.1 ] HELPERS DÙNG CHUNG
-- ==========================================

local function EquipWeapon(weaponName)
    local chr = Player.Character
    if chr and chr:FindFirstChild(weaponName) then
        warn("[DracoAuto] EquipWeapon: " .. weaponName .. " đã equip rồi, bỏ qua.")
        return true
    end
    local ok, err = pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("LoadItem", weaponName)
    end)
    if ok then
        warn("[DracoAuto] EquipWeapon: Đã equip " .. weaponName)
    else
        warn("[DracoAuto] EquipWeapon: Lỗi equip " .. weaponName .. " → " .. tostring(err))
    end
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
    if _lastInvCache ~= nil then
        return _lastInvCache, false
    end
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

    WeaponRowLabel.Text = string.format(
        "Heart: %s  |  Storm: %s",
        hasHeart and "✅" or "❌",
        hasStorm and "✅" or "❌"
    )

    if hasHeart and hasStorm then
        warn("[DracoAuto] [3.1] Luồng 1: Phát hiện Heart + Storm!")
        ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonheart..."
        EquipWeapon("Dragonheart")
        task.wait(0.8)
        ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonstorm..."
        EquipWeapon("Dragonstorm")
        task.wait(0.8)
        ActionStatus.Text = "Hành động: [3.1] ✅ Đã equip xong! Chuyển sang 3.2..."
        warn("[DracoAuto] [3.1] Luồng 1 hoàn tất → tiếp tục 3.2!")
        task.wait(1)
    else
        warn("[DracoAuto] [3.1] Luồng 2: Chưa có Heart/Storm → farm nguyên liệu!")
        ActionStatus.Text = "Hành động: [3.1] Chưa có Heart & Storm → farm nguyên liệu..."
        task.wait(1)

        local SCALE_MIN = 5
        local EMBER_MIN = 55

        -- ==========================================
        -- BƯỚC A: FARM DRAGON SCALE (ĐÃ FIX SECURITY KICK)
        -- ==========================================
        do
            local invA, _ = GetInventory()
            local _, scaleCount = HasItem(invA, "Dragon Scale")
            if scaleCount >= SCALE_MIN then
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale đủ (" .. scaleCount .. "/5), bỏ qua!"
                task.wait(0.5)
            else
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale thiếu (" .. scaleCount .. "/5) → Farm..."
                warn("[DracoAuto] [3.1-A] Bắt đầu farm Dragon Scale...")

                local SCALE_MOBS = {"Dragon Crew Archer", "Dragon Crew Warrior"}
                local SCALE_POS  = CFrame.new(6594, 383, 139)
                local _farmingScale = true

                -- FIX SECURITY KICK: Viết lại logic đánh riêng an toàn cho Scale
                local function SafeKillScaleMob(targetModel)
                    xpcall(function()
                        if not targetModel or not targetModel.Parent then return end
                        local vh = targetModel:FindFirstChild("Humanoid")
                        local vhrp = targetModel:FindFirstChild("HumanoidRootPart")
                        if not vh or vh.Health <= 0 or not vhrp then return end

                        if not targetModel:GetAttribute("Locked") then
                            targetModel:SetAttribute("Locked", vhrp.CFrame)
                        end
                        local lockedPos = targetModel:GetAttribute("Locked").Position

                        -- Giữ mob an toàn, không thay đổi WalkSpeed hay phá Animator để tránh Anti-Cheat quét
                        pcall(function()
                            if (vhrp.Position - lockedPos).Magnitude > 5 then
                                vhrp.CFrame = CFrame.new(lockedPos)
                            end
                            vhrp.CanCollide = false
                        end)

                        -- GIẢM ĐỘ CAO XUỐNG CÒN 15 STUD (Tầm đánh an toàn, 30 stud dễ bị AC soi Reach hack)
                        local safePos = CFrame.new(lockedPos) * CFrame.new(0, 15, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        SetFloatPos(safePos)

                        EquipWeaponTool("Melee")
                        FastAttack(targetModel.Name)

                        if tick() - lastKenCall >= 10 then
                            lastKenCall = tick()
                            pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end)
                        end
                    end, function(e) warn("[DracoAuto] SafeKillScaleMob ERROR:", e) end)
                end

                -- Bật float để lơ lửng
                StartFloat()
                -- Bay tới bãi với độ cao 15
                TweenTo(SCALE_POS * CFrame.new(0, 15, 0))
                SetFloatPos(SCALE_POS * CFrame.new(0, 15, 0))

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
                                SafeKillScaleMob(target)
                                task.wait(0.2) -- Tăng delay lên 0.2s để giảm tải remote packet
                            until not _farmingScale
                                or not target or not target.Parent
                                or not target:FindFirstChild("Humanoid")
                                or target.Humanoid.Health <= 0
                        else
                            SetFloatPos(SCALE_POS * CFrame.new(0, 15, 0))
                        end
                    end)
                    task.wait(0.2)
                end

                StopFloat()

                local invFinal, _ = GetInventory()
                local _, finalScale = HasItem(invFinal, "Dragon Scale")
                if finalScale >= SCALE_MIN then
                    ActionStatus.Text = "Hành động: [3.1-A] ✅ Đủ " .. finalScale .. "/5 Dragon Scale! Kick..."
                    warn("[DracoAuto] [3.1-A] Đủ Dragon Scale → Kick!")
                    task.wait(2)
                    Player:Kick("\n[ Draco Auto ]\nĐủ 5/5 Dragon Scale!\nRejoin để farm Blaze Ember.")
                end
            end
        end

        -- ==========================================
        -- BƯỚC B: FARM BLAZE EMBER (Auto Dragon Hunter)
        -- Quest: RF/DragonHunter → Defeat mob hoặc Destroy bambootree
        -- Mob: "Hydra Enforcer", "Venomous Assailant"
        -- Vị trí mob: CFrame.new(4620, 1002, 399)
        -- Dojo claim: CFrame.new(5813, 1208, 884)
        -- Ember: workspace.EmberTemplate.Part
        -- Attack: KillMonster + FastAttack (KaitunBoss)
        -- ==========================================
        do
            local invB, _ = GetInventory()
            local _, emberCount = HasItem(invB, "Blaze Ember")
            if emberCount >= EMBER_MIN then
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember đủ (" .. emberCount .. "/55), bỏ qua!"
                task.wait(0.5)
            else
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember thiếu (" .. emberCount .. "/55) → Farm Dragon Hunter..."
                warn("[DracoAuto] [3.1-B] Bắt đầu Auto Dragon Hunter...")

                local DOJO_POS  = CFrame.new(5813, 1208, 884)
                local HYDRA_POS = CFrame.new(4620.61572265625, 1002.2954711914062, 399.0868835449219)
                local _farmingEmber = true

                -- Check quest Dragon Hunter (logic từ Banana)
                local function checkDragonQuest()
                    local questData = nil
                    local hasQuest  = false
                    local mobName, questCount, questType = nil, nil, nil

                    pcall(function()
                        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                        local RF  = Net:WaitForChild("RF/DragonHunter")
                        pcall(function()
                            RF:InvokeServer(unpack({[1] = {["Context"] = "RequestQuest"}}))
                        end)
                        questData = RF:InvokeServer(unpack({[1] = {["Context"] = "Check"}}))
                    end)

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

                    return hasQuest, mobName, questCount, questType
                end

                -- Check notification hoàn thành quest
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

                -- Claim quest tại Dojo
                local function claimDragonQuest()
                    pcall(function()
                        local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                        Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack({
                            [1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}
                        }))
                    end)
                end

                -- Thread phụ: nhặt Ember (direct CFrame, không dùng SetFloatPos để tránh conflict combat)
                task.spawn(function()
                    while _farmingEmber do
                        pcall(function()
                            if workspace:FindFirstChild("EmberTemplate") and workspace.EmberTemplate:FindFirstChild("Part") then
                                if Character and HumanoidRootPart then
                                    -- Flash CFrame 1 frame để nhặt, Heartbeat sẽ kéo về ghost ngay frame sau
                                    HumanoidRootPart.CFrame = workspace.EmberTemplate.Part.CFrame
                                end
                            end
                        end)
                        task.wait(0.15)
                    end
                end)

                -- Bật float
                StartFloat()

                -- Loop chính farm Dragon Hunter
                while _farmingEmber do
                    pcall(function()
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
                                        -- Lock con này, đánh đến chết
                                        EnsureBuso()
                                        repeat
                                            KillMonster(target)
                                            task.wait(0.15)
                                        until not _farmingEmber
                                            or not target or not target.Parent
                                            or not target:FindFirstChild("Humanoid")
                                            or target.Humanoid.Health <= 0
                                            or isBackToDojo()
                                    else
                                        -- Mob chưa spawn → float giữ tại vùng mob chờ
                                        SetFloatPos(HYDRA_POS * CFrame.new(0, 30, 0))
                                    end
                                end

                            -- QUEST LOẠI 2: Destroy bambootree
                            elseif questType == 2 then
                                pcall(function()
                                    local tree = workspace.Map.Waterfall.IslandModel:FindFirstChild("Meshes/bambootree", true)
                                    if tree then
                                        -- Tạm tắt float để đến cây
                                        StopFloat()
                                        TweenTo(tree.CFrame * CFrame.new(4, 0, 0))
                                        if HumanoidRootPart and (tree.Position - HumanoidRootPart.Position).Magnitude <= 200 then
                                            UseAllSkills()
                                        end
                                        -- Bật lại float
                                        StartFloat()
                                    end
                                end)
                            end
                        else
                            -- Không có quest / cần quay về Dojo → tắt float, bay về, claim, bật lại
                            StopFloat()
                            if isBackToDojo() then
                                TweenTo(DOJO_POS)
                                task.wait(0.3)
                                claimDragonQuest()
                                task.wait(0.5)
                            else
                                TweenTo(DOJO_POS)
                                task.wait(0.5)
                            end
                            StartFloat()
                        end
                    end)
                    task.wait(0.2)
                end

                -- Tắt float
                StopFloat()

                _farmingEmber = false

                local invFinal, _ = GetInventory()
                local _, finalEmber = HasItem(invFinal, "Blaze Ember")
                if finalEmber >= EMBER_MIN then
                    ActionStatus.Text = "Hành động: [3.1-B] ✅ Đủ " .. finalEmber .. "/55 Blaze Ember! Kick..."
                    warn("[DracoAuto] [3.1-B] Đủ Blaze Ember → Kick!")
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

    WeaponRowLabel.Text = string.format("Heart: %s  |  Storm: %s",
        hasHeartNow and "✅" or "❌", hasStormNow and "✅" or "❌")

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
                WeaponRowLabel.Text = string.format("Heart: %s  |  Storm: %s",
                    heartAfter and "✅" or "❌", stormAfter and "✅" or "❌")

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
        if ok and success then
            warn("[DracoAuto] [3.3] DoChangeRace: Thành công!")
            return true
        else
            warn("[DracoAuto] [3.3] DoChangeRace: Thất bại!", err)
            return false
        end
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
        warn("[DracoAuto] [3.4] ResetStat: Bắt đầu refund...")
        pcall(function() CommF:InvokeServer("BlackbeardReward", "Refund", "1") end)
        task.wait(0.3)
        pcall(function() CommF:InvokeServer("BlackbeardReward", "Refund", "2") end)
        task.wait(0.5)
        warn("[DracoAuto] [3.4] ResetStat: Hoàn tất!")
    end

    local function AddStatPoint(statName, amount)
        pcall(function()
            CommF:InvokeServer("AddPoint", statName, amount)
        end)
        warn("[DracoAuto] [3.4] AddStatPoint: " .. statName .. " +" .. amount)
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
    warn("[DracoAuto] [3.4] HeartMastery=" .. heartMastery .. " StormMastery=" .. stormMastery)

    -- ==========================================
    -- LUỒNG 1: DRAGONHEART (SWORD) MASTERY < 500
    -- ==========================================
    if heartMastery < MASTERY_MAX then
        warn("[DracoAuto] [3.4-L1] Heart mastery " .. heartMastery .. " < 500 → Farm Sword mastery!")
        ActionStatus.Text = "Hành động: [3.4-L1] Heart mastery " .. heartMastery .. "/500 → Kiểm tra stat Sword build..."

        if IsStatCorrect("Sword") then
            ActionStatus.Text = "Hành động: [3.4-L1] ✅ Stat đã đúng Sword build, giữ nguyên!"
            warn("[DracoAuto] [3.4-L1] Stat đã đúng Melee/Defense/Sword → giữ nguyên!")
            task.wait(1)
        else
            warn("[DracoAuto] [3.4-L1] Stat sai → delay 5s rồi reset!")
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

            ActionStatus.Text = "Hành động: [3.4-L1] ✅ Hoàn tất Sword build!"
            warn("[DracoAuto] [3.4-L1] Xong reset + nâng Melee/Defense/Sword = " .. STAT_MAX)
        end

        ActionStatus.Text = "Hành động: [3.4-L1] Load farm Sword mastery sau 4s..."
        task.wait(4)

        warn("[DracoAuto] [3.4-L1] Load BananaHub HeartMastery...")
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
            MasteryLabel.TextColor3 = heartMastery >= MASTERY_MAX
                and Color3.fromRGB(0, 255, 0)
                or  Color3.fromRGB(255, 200, 0)
            ActionStatus.Text = string.format("Hành động: [3.4-L1] Đang farm Heart mastery (%d/500)...", heartMastery)
            warn("[DracoAuto] [3.4-L1] Heart mastery: " .. heartMastery)
        until heartMastery >= MASTERY_MAX

        ActionStatus.Text = "Hành động: [3.4-L1] ✅ Heart mastery đạt " .. heartMastery .. "/500! Kick..."
        warn("[DracoAuto] [3.4-L1] Heart mastery đủ 500 → Kick!")
        task.wait(2)
        Player:Kick("\n[ Draco Auto ]\nDragonheart đạt " .. heartMastery .. "/500 Mastery!\nRejoin để farm Dragonstorm mastery.")

    -- ==========================================
    -- LUỒNG 2: HEART >= 500 → FARM DRAGONSTORM (GUN) MASTERY
    -- ==========================================
    else
        warn("[DracoAuto] [3.4-L2] Heart mastery " .. heartMastery .. " >= 500 → Check Storm!")

        stormMastery = GetWeaponMastery("Dragonstorm")
        MasteryLabel.Text = string.format("Mastery: Heart %d/500 | Storm %d/500", heartMastery, stormMastery)

        if stormMastery >= MASTERY_MAX then
            ActionStatus.Text = "Hành động: [3.4-L2] ✅ Cả Heart + Storm đều đủ 500!"
            warn("[DracoAuto] [3.4-L2] Cả hai đã đủ mastery → Ghi file + kick!")

            pcall(function() writefile(Player.Name .. ".txt", "Completed-mastery") end)
            warn("[DracoAuto] [3.4-L2] Đã ghi file " .. Player.Name .. ".txt → Completed-mastery")

            for i = 10, 1, -1 do
                ActionStatus.Text = "Hành động: [3.4-L2] ✅ HOÀN THÀNH! Kick sau " .. i .. "s..."
                task.wait(1)
            end
            Player:Kick("\n[ Draco Auto ]\n✅ HOÀN THÀNH!\nHeart: " .. heartMastery .. "/500 | Storm: " .. stormMastery .. "/500\nFile " .. Player.Name .. ".txt đã ghi.")

        else
            warn("[DracoAuto] [3.4-L2] Storm mastery " .. stormMastery .. " < 500 → Farm Gun mastery!")
            ActionStatus.Text = "Hành động: [3.4-L2] Storm mastery " .. stormMastery .. "/500 → Kiểm tra stat Gun build..."

            if IsStatCorrect("Gun") then
                ActionStatus.Text = "Hành động: [3.4-L2] ✅ Stat đã đúng Gun build, giữ nguyên!"
                warn("[DracoAuto] [3.4-L2] Stat đã đúng Melee/Defense/Gun → giữ nguyên!")
                task.wait(1)
            else
                warn("[DracoAuto] [3.4-L2] Stat sai → delay 5s rồi reset!")
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

                ActionStatus.Text = "Hành động: [3.4-L2] ✅ Hoàn tất Gun build!"
                warn("[DracoAuto] [3.4-L2] Xong reset + nâng Melee/Defense/Gun = " .. STAT_MAX)
            end

            ActionStatus.Text = "Hành động: [3.4-L2] Load farm Storm (Gun) mastery sau 4s..."
            task.wait(4)

            warn("[DracoAuto] [3.4-L2] Load BananaHub StormMastery...")
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
                MasteryLabel.TextColor3 = stormMastery >= MASTERY_MAX
                    and Color3.fromRGB(0, 255, 0)
                    or  Color3.fromRGB(255, 200, 0)
                ActionStatus.Text = string.format("Hành động: [3.4-L2] Đang farm Storm mastery (%d/500)...", stormMastery)
                warn("[DracoAuto] [3.4-L2] Storm mastery: " .. stormMastery)
            until stormMastery >= MASTERY_MAX

            ActionStatus.Text = "Hành động: [3.4-L2] ✅ Storm mastery đạt " .. stormMastery .. "/500! Ghi file..."
            warn("[DracoAuto] [3.4-L2] Storm mastery đủ 500 → Ghi file!")

            pcall(function() writefile(Player.Name .. ".txt", "Completed-mastery") end)
            warn("[DracoAuto] [3.4-L2] Đã ghi file " .. Player.Name .. ".txt → Completed-mastery")

            ActionStatus.Text = "Hành động: [3.4-L2] ✅ Đã ghi file! Kick sau 10s..."
            for i = 10, 1, -1 do
                ActionStatus.Text = "Hành động: [3.4-L2] ✅ HOÀN THÀNH! Kick sau " .. i .. "s..."
                task.wait(1)
            end
            Player:Kick("\n[ Draco Auto ]\n✅ HOÀN THÀNH!\nHeart: " .. heartMastery .. "/500 | Storm: " .. stormMastery .. "/500\nFile " .. Player.Name .. ".txt đã ghi.")
        end
    end
end
