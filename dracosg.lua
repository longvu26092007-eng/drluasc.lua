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

-- Lấy mastery của vũ khí (tham khảo từ Draco Hub V1)
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

local function RunFarmFragment()
    repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
    getgenv().Key    = "1f34f32b6f1917a66d57e8c6"
    getgenv().NewUI  = true
    getgenv().Config = {
        ["Select Method Farm"] = "Farm Katakuri",
        ["Hop Find Katakuri"]  = true,
        ["Start Farm"]         = true,
    }
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
    end)
    if ok then
        warn("[DracoAuto] [3.05] BananaHub FarmFragment load thành công!")
    else
        warn("[DracoAuto] [3.05] BananaHub FarmFragment load thất bại: " .. tostring(err))
    end
end

do
    local frag = GetFragments()

    if frag < FRAGMENT_MIN then
        ActionStatus.Text = "Hành động: [3.05] Fragment thiếu (" .. frag .. "/" .. FRAGMENT_MIN .. "), bắt đầu farm Katakuri..."
        warn("[DracoAuto] [3.05] Fragment = " .. frag .. " < " .. FRAGMENT_MIN .. " → Chạy FarmFragment!")
        RunFarmFragment()
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

        -- BƯỚC A: FARM DRAGON SCALE
        do
            local invA, _ = GetInventory()
            local _, scaleCount = HasItem(invA, "Dragon Scale")
            if scaleCount >= SCALE_MIN then
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale đủ (" .. scaleCount .. "/5), bỏ qua!"
                task.wait(0.5)
            else
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale thiếu (" .. scaleCount .. "/5) → Farm..."
                repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
                getgenv().Key    = "1f34f32b6f1917a66d57e8c6"
                getgenv().NewUI  = true
                getgenv().Config = {
                    ["Select Material"] = "Dragon Scale",
                    ["Farm Material"]   = true,
                    ["Start Farm"]      = true,
                }
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
                end)
                local lastScaleCount = scaleCount
                repeat
                    task.wait(3)
                    local invLoop, _ = GetInventory()
                    local _, nowScale = HasItem(invLoop, "Dragon Scale")
                    ActionStatus.Text = string.format("Hành động: [3.1-A] Đang farm Dragon Scale (%d/5)...", nowScale)
                    if lastScaleCount < SCALE_MIN and nowScale >= SCALE_MIN then
                        ActionStatus.Text = "Hành động: [3.1-A] ✅ Đủ 5/5 Dragon Scale! Kick..."
                        task.wait(2)
                        Player:Kick("\n[ Draco Auto ]\nĐủ 5/5 Dragon Scale!\nRejoin để farm Blaze Ember.")
                    end
                    lastScaleCount = nowScale
                until nowScale >= SCALE_MIN
            end
        end

        -- BƯỚC B: FARM BLAZE EMBER
        do
            local invB, _ = GetInventory()
            local _, emberCount = HasItem(invB, "Blaze Ember")
            if emberCount >= EMBER_MIN then
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember đủ (" .. emberCount .. "/55), bỏ qua!"
                task.wait(0.5)
            else
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember thiếu (" .. emberCount .. "/55) → Farm..."
                repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
                getgenv().Key    = "1f34f32b6f1917a66d57e8c6"
                getgenv().NewUI  = true
                getgenv().Config = { ["Auto Quest Dragon Hunter"] = true }
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
                end)
                local lastEmberCount = emberCount
                repeat
                    task.wait(3)
                    local invLoop, _ = GetInventory()
                    local _, nowEmber = HasItem(invLoop, "Blaze Ember")
                    ActionStatus.Text = string.format("Hành động: [3.1-B] Đang farm Blaze Ember (%d/55)...", nowEmber)
                    if lastEmberCount < EMBER_MIN and nowEmber >= EMBER_MIN then
                        ActionStatus.Text = "Hành động: [3.1-B] ✅ Đủ 55/55 Blaze Ember! Kick..."
                        task.wait(2)
                        Player:Kick("\n[ Draco Auto ]\nĐủ 55/55 Blaze Ember!\nRejoin để Craft Heart & Storm.")
                    end
                    lastEmberCount = nowEmber
                until nowEmber >= EMBER_MIN
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
-- Tham khảo từ Draco Hub V1 (DoStatForMastery, ResetStat, AddStatPoint)
--
-- Luồng 1: Heart mastery < 500
--   → Check stat → cần Melee/Defense/Sword (2800 mỗi cái)
--   → Nếu sai → delay 5s → reset → nâng đúng build
--   → delay 4s → load BananaHub farm Sword
--   → loop check mỗi 10s → đủ 500 → kick
--
-- Luồng 2: Heart >= 500, Storm mastery < 500
--   → Check stat → cần Melee/Defense/Gun (2800 mỗi cái)
--   → Nếu sai → delay 5s → reset → nâng đúng build
--   → delay 4s → load BananaHub farm Gun
--   → loop check mỗi 10s → đủ 500
--   → ghi file PlayerName.txt = "Completed-mastery"
--   → delay 10s → kick
-- ==========================================

do
    local STAT_MAX    = 2800
    local MASTERY_MAX = 500
    local CommF       = game:GetService("ReplicatedStorage").Remotes.CommF_

    -- Reset stat (tham khảo từ Draco Hub V1 - BlackbeardReward Refund)
    local function ResetStat()
        ActionStatus.Text = "Hành động: [3.4] Đang reset stat..."
        warn("[DracoAuto] [3.4] ResetStat: Bắt đầu refund...")
        pcall(function() CommF:InvokeServer("BlackbeardReward", "Refund", "1") end)
        task.wait(0.3)
        pcall(function() CommF:InvokeServer("BlackbeardReward", "Refund", "2") end)
        task.wait(0.5)
        warn("[DracoAuto] [3.4] ResetStat: Hoàn tất!")
    end

    -- Add stat point (tham khảo từ Draco Hub V1)
    local function AddStatPoint(statName, amount)
        pcall(function()
            CommF:InvokeServer("AddPoint", statName, amount)
        end)
        warn("[DracoAuto] [3.4] AddStatPoint: " .. statName .. " +" .. amount)
    end

    -- Kiểm tra stat có đúng build chưa
    -- "Sword" → cần Melee >= 2800, Defense >= 2800, Sword >= 2800
    -- "Gun"   → cần Melee >= 2800, Defense >= 2800, Gun >= 2800
    local function IsStatCorrect(buildType)
        local s = getStats()
        if buildType == "Sword" then
            return s.Melee >= STAT_MAX and s.Defense >= STAT_MAX and s.Sword >= STAT_MAX
        elseif buildType == "Gun" then
            return s.Melee >= STAT_MAX and s.Defense >= STAT_MAX and s.Gun >= STAT_MAX
        end
        return false
    end

    -- Equip cả hai vũ khí trước khi farm mastery
    ActionStatus.Text = "Hành động: [3.4] Đang equip Dragonheart & Dragonstorm..."
    EquipWeapon("Dragonheart")
    task.wait(0.5)
    EquipWeapon("Dragonstorm")
    task.wait(0.5)

    -- Đọc mastery hiện tại
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

        -- Check stat có đúng Melee/Defense/Sword chưa
        if IsStatCorrect("Sword") then
            ActionStatus.Text = "Hành động: [3.4-L1] ✅ Stat đã đúng Sword build, giữ nguyên!"
            warn("[DracoAuto] [3.4-L1] Stat đã đúng Melee/Defense/Sword → giữ nguyên!")
            task.wait(1)
        else
            -- Stat sai → delay 5s countdown → reset → nâng Melee/Defense/Sword
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

        -- Delay 4 giây rồi load BananaHub farm Sword mastery (LUỒNG 1)
        ActionStatus.Text = "Hành động: [3.4-L1] Load farm Sword mastery sau 4s..."
        task.wait(4)

        warn("[DracoAuto] [3.4-L1] Load BananaHub HeartMastery...")
        ActionStatus.Text = "Hành động: [3.4-L1] Đang load BananaHub farm Heart (Sword) mastery..."

        repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
        getgenv().Key    = "1f34f32b6f1917a66d57e8c6"
        getgenv().NewUI  = true
        getgenv().Config = {
            ["Select Weapon"]      = "Sword",
            ["Select Method Farm"] = "Farm Bones",
            ["Start Farm"]         = true,
        }
        local okH, errH = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
        end)
        if okH then
            warn("[DracoAuto] [3.4-L1] BananaHub HeartMastery load thành công!")
        else
            warn("[DracoAuto] [3.4-L1] BananaHub HeartMastery load thất bại: " .. tostring(errH))
        end

        -- Loop check mastery mỗi 10 giây (LUỒNG 1)
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

        -- Heart đủ 500 → kick để rejoin farm Storm
        ActionStatus.Text = "Hành động: [3.4-L1] ✅ Heart mastery đạt " .. heartMastery .. "/500! Kick..."
        warn("[DracoAuto] [3.4-L1] Heart mastery đủ 500 → Kick!")
        task.wait(2)
        Player:Kick("\n[ Draco Auto ]\nDragonheart đạt " .. heartMastery .. "/500 Mastery!\nRejoin để farm Dragonstorm mastery.")

    -- ==========================================
    -- LUỒNG 2: HEART >= 500 → FARM DRAGONSTORM (GUN) MASTERY
    -- ==========================================
    else
        warn("[DracoAuto] [3.4-L2] Heart mastery " .. heartMastery .. " >= 500 → Check Storm!")

        -- Re-read storm mastery sau khi equip
        stormMastery = GetWeaponMastery("Dragonstorm")
        MasteryLabel.Text = string.format("Mastery: Heart %d/500 | Storm %d/500", heartMastery, stormMastery)

        if stormMastery >= MASTERY_MAX then
            -- Cả hai đều đã đủ 500 → ghi file + delay 10s + kick
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
            -- Storm < 500 → farm Gun mastery
            warn("[DracoAuto] [3.4-L2] Storm mastery " .. stormMastery .. " < 500 → Farm Gun mastery!")
            ActionStatus.Text = "Hành động: [3.4-L2] Storm mastery " .. stormMastery .. "/500 → Kiểm tra stat Gun build..."

            -- Check stat có đúng Melee/Defense/Gun chưa
            if IsStatCorrect("Gun") then
                ActionStatus.Text = "Hành động: [3.4-L2] ✅ Stat đã đúng Gun build, giữ nguyên!"
                warn("[DracoAuto] [3.4-L2] Stat đã đúng Melee/Defense/Gun → giữ nguyên!")
                task.wait(1)
            else
                -- Stat sai → delay 5s countdown → reset → nâng Melee/Defense/Gun
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

            -- Delay 4 giây rồi load BananaHub farm Gun mastery (LUỒNG 2)
            ActionStatus.Text = "Hành động: [3.4-L2] Load farm Storm (Gun) mastery sau 4s..."
            task.wait(4)

            warn("[DracoAuto] [3.4-L2] Load BananaHub StormMastery...")
            ActionStatus.Text = "Hành động: [3.4-L2] Đang load BananaHub farm Storm (Gun) mastery..."

            repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
            getgenv().Key    = "1f34f32b6f1917a66d57e8c6"
            getgenv().NewUI  = true
            getgenv().Config = {
                ["Select Weapon"]              = "Melee",
                ["Select Method Farm"]         = "Farm Bones",
                ["Select Method Farm Mastery"] = "Gun",
                ["Health %"]                   = "45",
                ["Farm Mastery"]               = true,
                ["Start Farm"]                 = true,
            }
            local okS, errS = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
            end)
            if okS then
                warn("[DracoAuto] [3.4-L2] BananaHub StormMastery load thành công!")
            else
                warn("[DracoAuto] [3.4-L2] BananaHub StormMastery load thất bại: " .. tostring(errS))
            end

            -- Loop check mastery mỗi 10 giây (LUỒNG 2)
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

            -- Storm đủ 500 → ghi file Completed-mastery → delay 10s → kick
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
