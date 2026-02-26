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

-- Hành động
local ActionStatus = Instance.new("TextLabel", InfoPanel)
ActionStatus.Size               = UDim2.new(1, 0, 0, 22)
ActionStatus.Position           = UDim2.new(0, 0, 0, 0)
ActionStatus.Text               = "Hành động: Khởi động kịch bản..."
ActionStatus.TextColor3         = Color3.fromRGB(200, 200, 200)
ActionStatus.Font               = Enum.Font.Gotham
ActionStatus.BackgroundTransparency = 1
ActionStatus.TextSize           = 12
ActionStatus.TextXAlignment     = Enum.TextXAlignment.Left

-- Mastery
local MasteryLabel = Instance.new("TextLabel", InfoPanel)
MasteryLabel.Size               = UDim2.new(1, 0, 0, 22)
MasteryLabel.Position           = UDim2.new(0, 0, 0, 25)
MasteryLabel.Text               = "Mastery: Chờ xác nhận vũ khí..."
MasteryLabel.TextColor3         = Color3.fromRGB(255, 200, 0)
MasteryLabel.Font               = Enum.Font.GothamBold
MasteryLabel.BackgroundTransparency = 1
MasteryLabel.TextSize           = 13
MasteryLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Divider
local Div = Instance.new("Frame", InfoPanel)
Div.Size             = UDim2.new(1, 0, 0, 1)
Div.Position         = UDim2.new(0, 0, 0, 52)
Div.BackgroundColor3 = Color3.fromRGB(80, 60, 0)
Div.BorderSizePixel  = 0

-- Race
local RaceLabel = Instance.new("TextLabel", InfoPanel)
RaceLabel.Size               = UDim2.new(1, 0, 0, 22)
RaceLabel.Position           = UDim2.new(0, 0, 0, 58)
RaceLabel.Text               = "🧬 Race: ..."
RaceLabel.TextColor3         = Color3.fromRGB(160, 200, 255)
RaceLabel.Font               = Enum.Font.Gotham
RaceLabel.BackgroundTransparency = 1
RaceLabel.TextSize           = 12
RaceLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Fragments
local FragLabel = Instance.new("TextLabel", InfoPanel)
FragLabel.Size               = UDim2.new(1, 0, 0, 22)
FragLabel.Position           = UDim2.new(0, 0, 0, 82)
FragLabel.Text               = "🔮 Fragments: ..."
FragLabel.TextColor3         = Color3.fromRGB(200, 160, 255)
FragLabel.Font               = Enum.Font.Gotham
FragLabel.BackgroundTransparency = 1
FragLabel.TextSize           = 12
FragLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Điểm stat chưa dùng
local PointsLabel = Instance.new("TextLabel", InfoPanel)
PointsLabel.Size               = UDim2.new(1, 0, 0, 22)
PointsLabel.Position           = UDim2.new(0, 0, 0, 106)
PointsLabel.Text               = "⭐ Điểm stat chưa dùng: ..."
PointsLabel.TextColor3         = Color3.fromRGB(255, 220, 80)
PointsLabel.Font               = Enum.Font.GothamSemibold
PointsLabel.BackgroundTransparency = 1
PointsLabel.TextSize           = 12
PointsLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Stat hàng ngang
local StatRowLabel = Instance.new("TextLabel", InfoPanel)
StatRowLabel.Size               = UDim2.new(1, 0, 0, 22)
StatRowLabel.Position           = UDim2.new(0, 0, 0, 130)
StatRowLabel.Text               = "Melee:0 | Def:0 | Sword:0 | Gun:0 | Fruit:0"
StatRowLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
StatRowLabel.Font               = Enum.Font.Gotham
StatRowLabel.BackgroundTransparency = 1
StatRowLabel.TextSize           = 11
StatRowLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Weapon backpack check
local WeaponRowLabel = Instance.new("TextLabel", InfoPanel)
WeaponRowLabel.Size               = UDim2.new(1, 0, 0, 22)
WeaponRowLabel.Position           = UDim2.new(0, 0, 0, 154)
WeaponRowLabel.Text               = "Heart: ❌  |  Storm: ❌"
WeaponRowLabel.TextColor3         = Color3.fromRGB(220, 220, 220)
WeaponRowLabel.Font               = Enum.Font.Gotham
WeaponRowLabel.BackgroundTransparency = 1
WeaponRowLabel.TextSize           = 11
WeaponRowLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Auto update stats mỗi 3 giây
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
-- Chờ UI load xong rồi mới bắt đầu logic
-- ==========================================

-- 3.0 — Chờ UI hiện ra hoàn toàn trước khi làm gì
repeat task.wait(0.5) until ScreenGui and ScreenGui.Parent ~= nil
repeat task.wait(0.5) until MainFrame and MainFrame.Visible
task.wait(1)

ActionStatus.Text = "Hành động: UI sẵn sàng, bắt đầu kiểm tra..."

-- ==========================================
-- [ 3.05 ] KIỂM TRA FRAGMENT
-- Nếu dưới 12000 → chạy farm Katakuri, block cho đến khi đủ
-- Nếu đủ rồi → tiếp tục xuống 3.1
-- ==========================================

local FRAGMENT_MIN = 12000

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
        -- Chưa đủ → load farm, đợi cho đến khi Fragment >= 12000
        ActionStatus.Text = "Hành động: [3.05] Fragment thiếu (" .. frag .. "/" .. FRAGMENT_MIN .. "), bắt đầu farm Katakuri..."
        warn("[DracoAuto] [3.05] Fragment = " .. frag .. " < " .. FRAGMENT_MIN .. " → Chạy FarmFragment!")

        RunFarmFragment()

        -- Vòng chờ: cập nhật UI mỗi 3 giây cho đến khi đủ fragment
        repeat
            task.wait(3)
            frag = GetFragments()
            ActionStatus.Text = string.format(
                "Hành động: [3.05] Đang farm Fragment (%d/%d)...",
                frag, FRAGMENT_MIN
            )
            -- FragLabel cũng được update bởi vòng Phần 2, nhưng cập nhật luôn cho chắc
            FragLabel.Text      = "🔮 Fragments: " .. tostring(frag)
            FragLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        until frag >= FRAGMENT_MIN

        -- Đủ rồi
        FragLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        ActionStatus.Text    = "Hành động: [3.05] ✅ Đủ Fragment (" .. frag .. ")! Tiếp tục kịch bản..."
        warn("[DracoAuto] [3.05] Fragment đủ rồi → tiếp tục 3.1!")
        task.wait(1)

    else
        -- Đã đủ ngay từ đầu
        ActionStatus.Text    = "Hành động: [3.05] Fragment đủ (" .. frag .. "), bỏ qua farm!"
        FragLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        warn("[DracoAuto] [3.05] Fragment = " .. frag .. " >= " .. FRAGMENT_MIN .. " → Bỏ qua farm, vào 3.1!")
        task.wait(0.5)
    end
end


-- ==========================================
-- [ 3.1 ] HELPERS DÙNG CHUNG
-- ==========================================

-- Equip vũ khí qua remote LoadItem
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

-- Lấy inventory server, có fallback cache
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

-- Kiểm tra item (3 lớp: đang equip → backpack local → kho server)
-- Trả về: hasItem (bool), count (number)
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
-- [ 3.1 ] LUỒNG CHÍNH
-- Kiểm tra Heart & Storm trước
-- → Luồng 1: có cả hai → equip → qua 3.2
-- → Luồng 2: chưa có → farm Scale → farm Ember → kick
-- ==========================================

do
    local inv, _ = GetInventory()
    local hasHeart, _ = HasItem(inv, "Dragonheart")
    local hasStorm, _ = HasItem(inv, "Dragonstorm")

    -- Cập nhật UI
    WeaponRowLabel.Text = string.format(
        "Heart: %s  |  Storm: %s",
        hasHeart and "✅" or "❌",
        hasStorm and "✅" or "❌"
    )

    -- ==========================================
    -- LUỒNG 1: Đã có cả Heart + Storm → equip rồi qua 3.2
    -- ==========================================
    if hasHeart and hasStorm then
        warn("[DracoAuto] [3.1] Luồng 1: Phát hiện Heart + Storm trong inventory!")
        ActionStatus.Text = "Hành động: [3.1] Phát hiện Heart + Storm → Đang equip..."

        -- Equip Heart
        ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonheart..."
        EquipWeapon("Dragonheart")
        task.wait(0.8)

        -- Equip Storm
        ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonstorm..."
        EquipWeapon("Dragonstorm")
        task.wait(0.8)

        ActionStatus.Text = "Hành động: [3.1] ✅ Đã equip xong! Chuyển sang 3.2..."
        warn("[DracoAuto] [3.1] Luồng 1 hoàn tất → tiếp tục 3.2!")
        task.wait(1)

    -- ==========================================
    -- LUỒNG 2: Chưa có Heart/Storm → farm Scale → farm Ember
    -- ==========================================
    else
        warn("[DracoAuto] [3.1] Luồng 2: Chưa có Heart/Storm → bắt đầu farm nguyên liệu!")
        ActionStatus.Text = "Hành động: [3.1] Chưa có Heart & Storm → bắt đầu farm nguyên liệu..."
        task.wait(1)

        -- ----------------------------------------
        -- BƯỚC A: FARM DRAGON SCALE (cần 5/5)
        -- ----------------------------------------
        local SCALE_MIN = 5
        local EMBER_MIN = 55

        do
            local invA, _ = GetInventory()
            local _, scaleCount = HasItem(invA, "Dragon Scale")

            if scaleCount >= SCALE_MIN then
                -- Đã đủ Scale ngay từ đầu → bỏ qua farm
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale đủ (" .. scaleCount .. "/5), bỏ qua farm!"
                warn("[DracoAuto] [3.1-A] Scale = " .. scaleCount .. " >= 5 → skip farm Scale!")
                task.wait(0.5)
            else
                -- Chưa đủ → load BananaHub DragonScale
                ActionStatus.Text = "Hành động: [3.1-A] Dragon Scale thiếu (" .. scaleCount .. "/5) → Bắt đầu farm..."
                warn("[DracoAuto] [3.1-A] Scale = " .. scaleCount .. " < 5 → Load BananaHub DragonScale!")

                -- Script farm Dragon Scale (để riêng như yêu cầu)
                repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
                getgenv().Key    = "1f34f32b6f1917a66d57e8c6"
                getgenv().NewUI  = true
                getgenv().Config = {
                    ["Select Material"] = "Dragon Scale",
                    ["Farm Material"]   = true,
                    ["Start Farm"]      = true,
                }
                local okA, errA = pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
                end)
                if okA then
                    warn("[DracoAuto] [3.1-A] BananaHub DragonScale load thành công!")
                else
                    warn("[DracoAuto] [3.1-A] BananaHub DragonScale load thất bại: " .. tostring(errA))
                end

                -- Vòng check liên tục mỗi 3s, kick ngay khi đủ 5/5
                local lastScaleCount = scaleCount
                repeat
                    task.wait(3)
                    local invLoop, _ = GetInventory()
                    local _, nowScale = HasItem(invLoop, "Dragon Scale")
                    ActionStatus.Text = string.format(
                        "Hành động: [3.1-A] Đang farm Dragon Scale (%d/5)...", nowScale
                    )
                    warn("[DracoAuto] [3.1-A] Scale hiện tại: " .. nowScale)

                    -- Kick ngay khi vừa đủ 5 (chuyển từ dưới 5 lên)
                    if lastScaleCount < SCALE_MIN and nowScale >= SCALE_MIN then
                        ActionStatus.Text = "Hành động: [3.1-A] ✅ Đủ 5/5 Dragon Scale! Đang Kick để nhận diện..."
                        warn("[DracoAuto] [3.1-A] Scale đủ 5/5 → Kick!")
                        task.wait(2)
                        Player:Kick("\n[ Draco Auto ]\nĐủ 5/5 Dragon Scale!\nRejoin để tiến hành farm Blaze Ember.")
                    end

                    lastScaleCount = nowScale
                until nowScale >= SCALE_MIN
            end
        end

        -- ----------------------------------------
        -- BƯỚC B: FARM BLAZE EMBER (cần 55/55)
        -- Chỉ chạy đến đây nếu chưa bị kick ở bước A
        -- (tức là có sẵn >= 5 Scale từ đầu)
        -- ----------------------------------------
        do
            local invB, _ = GetInventory()
            local _, emberCount = HasItem(invB, "Blaze Ember")

            if emberCount >= EMBER_MIN then
                -- Đã đủ Ember ngay từ đầu → bỏ qua farm
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember đủ (" .. emberCount .. "/55), bỏ qua farm!"
                warn("[DracoAuto] [3.1-B] Ember = " .. emberCount .. " >= 55 → skip farm Ember!")
                task.wait(0.5)
            else
                -- Chưa đủ → load BananaHub BlazeEmber
                ActionStatus.Text = "Hành động: [3.1-B] Blaze Ember thiếu (" .. emberCount .. "/55) → Bắt đầu farm..."
                warn("[DracoAuto] [3.1-B] Ember = " .. emberCount .. " < 55 → Load BananaHub BlazeEmber!")

                -- Script farm Blaze Ember (để riêng như yêu cầu)
                repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
                getgenv().Key    = "1f34f32b6f1917a66d57e8c6"
                getgenv().NewUI  = true
                getgenv().Config = {
                    ["Auto Quest Dragon Hunter"] = true,
                }
                local okB, errB = pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
                end)
                if okB then
                    warn("[DracoAuto] [3.1-B] BananaHub BlazeEmber load thành công!")
                else
                    warn("[DracoAuto] [3.1-B] BananaHub BlazeEmber load thất bại: " .. tostring(errB))
                end

                -- Vòng check liên tục mỗi 3s, kick ngay khi đủ 55/55
                local lastEmberCount = emberCount
                repeat
                    task.wait(3)
                    local invLoop, _ = GetInventory()
                    local _, nowEmber = HasItem(invLoop, "Blaze Ember")
                    ActionStatus.Text = string.format(
                        "Hành động: [3.1-B] Đang farm Blaze Ember (%d/55)...", nowEmber
                    )
                    warn("[DracoAuto] [3.1-B] Ember hiện tại: " .. nowEmber)

                    -- Kick ngay khi vừa đủ 55
                    if lastEmberCount < EMBER_MIN and nowEmber >= EMBER_MIN then
                        ActionStatus.Text = "Hành động: [3.1-B] ✅ Đủ 55/55 Blaze Ember! Đang Kick để nhận diện..."
                        warn("[DracoAuto] [3.1-B] Ember đủ 55/55 → Kick!")
                        task.wait(2)
                        Player:Kick("\n[ Draco Auto ]\nĐủ 55/55 Blaze Ember!\nRejoin để tiến hành Craft Heart & Storm.")
                    end

                    lastEmberCount = nowEmber
                until nowEmber >= EMBER_MIN
            end
        end

        -- Đủ cả Scale + Ember (không bị kick) → tiếp tục 3.2
        ActionStatus.Text = "Hành động: [3.1] ✅ Đủ nguyên liệu! Chuyển sang 3.2 (Craft)..."
        warn("[DracoAuto] [3.1] Luồng 2 hoàn tất → tiếp tục 3.2!")
        task.wait(1)
    end
end

-- ==========================================
-- [ 3.2 ] (SẼ LÀM SAU)
-- ==========================================
