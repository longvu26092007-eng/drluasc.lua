-- [[ AUTO RAINBOW HAKI v4 ]]
-- Di chuyển: Tween HRP (file 1 Tween2 style, speed 350)
-- Bỏ: ChangeState(15) reset → tránh detect
-- requestEntrance: Hydra Leader, Captain Elephant, Beautiful Pirate (file 2)
-- Combat: XOR FastAttack (KaitunBoss) + LeftClickRemote (file 1/5) + OldCFrame lock + freeze

-- ==========================================
-- CONFIG
-- ==========================================
getgenv().Team = "Pirates"
getgenv().WeaponType = getgenv().WeaponType or "Melee" -- "Melee" / "Sword" / "Blox Fruit"

-- ==========================================
-- CHỌN TEAM
-- ==========================================
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")

if game:GetService("Players").LocalPlayer.Team == nil then
    repeat task.wait()
        for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.Size = UDim2.new(0, 10000, 0, 10000)
                v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.Position = UDim2.new(-4, 0, -5, 0)
                v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.BackgroundTransparency = 1
                task.wait(.5)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.05)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1)
                task.wait(0.05)
            end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end

-- ==========================================
-- SERVICES
-- ==========================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local PlaceId, JobId = game.PlaceId, game.JobId
local COMMF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local plr = Players.LocalPlayer
local Character = plr.Character
local Humanoid, HumanoidRootPart

local function UpdateChar(v)
    Character = v
    Humanoid = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end
if Character then pcall(function() UpdateChar(Character) end) end
plr.CharacterAdded:Connect(UpdateChar)

if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
    task.wait(10 - workspace.DistributedGameTime)
end
repeat task.wait(2) until Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChildWhichIsA("Humanoid") and Character:IsDescendantOf(workspace.Characters)

local function CheckSea(v) return v == tonumber(workspace:GetAttribute("MAP"):match("%d+")) end
local World3 = CheckSea(3)

-- ==========================================
-- XOR FAST ATTACK (KaitunBoss)
-- ==========================================
local remoteAttack, idremote
local seed = RS.Modules.Net.seed:InvokeServer()
task.spawn(function() for _, v in next, ({RS.Util, RS.Common, RS.Remotes, RS.Assets, RS.FX}) do
    for _, n in next, v:GetChildren() do if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end end
    v.ChildAdded:Connect(function(n) if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end end)
end end)

local lastCallFA = tick()
local function FastAttack(x)
    if not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 or not Character:FindFirstChildWhichIsA("Tool") then return end
    if tick() - lastCallFA <= 0.01 then return end
    local t = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h, hrp = e:FindFirstChild("Humanoid"), e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then t[#t+1] = e end
    end
    local n = RS.Modules.Net
    local h = {[2] = {}}
    for i = 1, #t do local v = t[i]
        local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
        if not h[1] then h[1] = part end
        h[2][#h[2]+1] = {v, part}
    end
    n:FindFirstChild("RE/RegisterAttack"):FireServer()
    n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
    cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit",".",function(c)
        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1))
    end), bit32.bxor(idremote+909090, seed*2), unpack(h))
    lastCallFA = tick()
end

-- ==========================================
-- ATTACK (LeftClickRemote fallback)
-- ==========================================
local function AttackNoCoolDown()
    if not Character then return end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    if tool:FindFirstChild("LeftClickRemote") then
        local counter = 1
        for _, e in next, workspace.Enemies:GetChildren() do
            local hrp, eh = e:FindFirstChild("HumanoidRootPart"), e:FindFirstChild("Humanoid")
            if hrp and eh and eh.Health > 0 and (hrp.Position - Character:GetPivot().Position).Magnitude <= 60 then
                pcall(function() tool.LeftClickRemote:FireServer((hrp.Position - Character:GetPivot().Position).Unit, counter) end)
                counter = counter + 1 > 1e9 and 1 or counter + 1
            end
        end
    else
        FastAttack()
    end
end

-- ==========================================
-- NOCLIP + BODYCLIP + ANTI STUN
-- ==========================================
local _active = false

task.spawn(function()
    while task.wait() do
        pcall(function()
            if _active and HumanoidRootPart then
                if not HumanoidRootPart:FindFirstChild("BodyClip") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "BodyClip"; bv.Parent = HumanoidRootPart
                    bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Velocity = Vector3.zero
                end
            elseif HumanoidRootPart then
                local bc = HumanoidRootPart:FindFirstChild("BodyClip")
                if bc then bc:Destroy() end
            end
        end)
    end
end)

RunService.Stepped:Connect(function()
    if _active and Character then
        pcall(function() for _, p in next, Character:GetDescendants() do if p:IsA("BasePart") then p.CanCollide = false end end end)
    end
end)

task.spawn(function()
    pcall(function()
        if Character:FindFirstChild("Stun") then
            Character.Stun.Changed:Connect(function()
                pcall(function() if Character:FindFirstChild("Stun") then Character.Stun.Value = 0 end end)
            end)
        end
    end)
end)

-- ==========================================
-- TWEEN DI CHUYỂN (file 1 Tween2 style, speed 350)
-- Blocking: đợi đến nơi rồi return
-- Không giật: chỉ gọi 1 lần, TweenService tự chạy
-- ==========================================
local _currentTween = nil

local function TweenTo(targetCF)
    if not HumanoidRootPart then return end
    -- Cancel tween cũ
    if _currentTween then pcall(function() _currentTween:Cancel() end) _currentTween = nil end
    pcall(function() Humanoid.Sit = false end)

    local dist = (targetCF.Position - HumanoidRootPart.Position).Magnitude
    if dist < 5 then return end -- đã gần

    local speed = 350
    local tweenTime = dist / speed
    _currentTween = TweenService:Create(HumanoidRootPart, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = targetCF})
    _currentTween:Play()
    _currentTween.Completed:Wait()
    _currentTween = nil
end

-- Non-blocking tween: không chờ, dùng cho combat loop
local function TweenStart(targetCF)
    if not HumanoidRootPart then return end
    if _currentTween then pcall(function() _currentTween:Cancel() end) _currentTween = nil end
    pcall(function() Humanoid.Sit = false end)

    local dist = (targetCF.Position - HumanoidRootPart.Position).Magnitude
    if dist < 5 then return end

    local speed = 350
    _currentTween = TweenService:Create(HumanoidRootPart, TweenInfo.new(dist/speed, Enum.EasingStyle.Linear), {CFrame = targetCF})
    _currentTween:Play()
end

local function StopTween()
    if _currentTween then pcall(function() _currentTween:Cancel() end) _currentTween = nil end
end

local function GetDist(pos)
    if not HumanoidRootPart then return 9999 end
    return (HumanoidRootPart.Position - pos).Magnitude
end

-- ==========================================
-- WEAPON
-- ==========================================
local SelectWeapon = ""
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            for _, src in next, {plr.Backpack, Character} do
                if src then for _, t in next, src:GetChildren() do
                    if t:IsA("Tool") and t.ToolTip == getgenv().WeaponType then SelectWeapon = t.Name return end
                end end
            end
        end)
    end
end)

local function EquipWeapon()
    if not Character or SelectWeapon == "" then return end
    local cur = Character:FindFirstChildWhichIsA("Tool")
    if cur and cur.Name == SelectWeapon then return end
    local tool = plr.Backpack:FindFirstChild(SelectWeapon)
    if tool then Humanoid:EquipTool(tool) end
end

local function AutoHaki()
    pcall(function()
        -- Check đã học Buso chưa (CollectionService tag từ KaitunBoss)
        if not CollectionService:HasTag(Character, "Buso") then
            -- Chưa học → mua Buso ($25,000 Beli)
            COMMF_:InvokeServer("BuyHaki", "Buso")
            task.wait(0.5)
        end
        -- Bật Buso nếu chưa active
        if not Character:FindFirstChild("HasBuso") then
            COMMF_:InvokeServer("Buso")
        end
    end)
end

-- ==========================================
-- KILL BOSS (OldCFrame lock + freeze + dual attack)
-- Dùng TweenStart non-blocking để đến gần boss
-- ==========================================
local lastKen = tick()
local function KillBoss(bossName)
    local boss = nil
    for _, c in next, {workspace.Enemies, RS} do
        for _, m in next, c:GetChildren() do
            if m.Name == bossName then
                local h, hrp = m:FindFirstChild("Humanoid"), m:FindFirstChild("HumanoidRootPart")
                if h and h.Health > 0 and hrp then boss = m break end
            end
        end
        if boss then break end
    end
    if not boss then return nil end

    local bhrp = boss.HumanoidRootPart
    local dist = GetDist(bhrp.Position)

    if dist > 70 then
        TweenStart(bhrp.CFrame * CFrame.new(0, 20, 0))
        return false
    end

    -- Đã gần → dừng tween, lock boss, đánh
    StopTween()

    local oldCF = bhrp.CFrame
    bhrp.CFrame = oldCF
    bhrp.CanCollide = false
    bhrp.Size = Vector3.new(50, 50, 50)
    pcall(function() boss.Humanoid.JumpPower = 0; boss.Humanoid.WalkSpeed = 0 end)

    -- Đứng sát boss
    HumanoidRootPart.CFrame = CFrame.new(bhrp.Position + Vector3.new(0, 20, 0))

    EquipWeapon()
    AutoHaki()
    FastAttack(bossName)
    AttackNoCoolDown()

    if tick() - lastKen >= 10 then
        lastKen = tick()
        pcall(function() RS.Remotes.CommE:FireServer("Ken", true) end)
    end
    return true
end

-- ==========================================
-- HOP SERVER (__ServerBrowser)
-- ==========================================
local function IfTableHaveIndex(j) for _ in j do return true end end
local _lastPull, _cache
local function GetServers()
    if _lastPull and os.time() - _lastPull < 60 then return _cache end
    for i = 1, 100 do
        local d = RS:WaitForChild("__ServerBrowser"):InvokeServer(i)
        if IfTableHaveIndex(d) then _lastPull = os.time(); _cache = d; return d end
    end
end
local function HopServer()
    local sv = GetServers(); if not sv then return end
    local arr = {}; for i, v in sv do arr[#arr+1] = {JobId=i, Players=v.Count} end
    for _ = 1, #arr do
        local s = arr[math.random(1, #arr)]
        if s and s.Players < 5 then RS:WaitForChild("__ServerBrowser"):InvokeServer('teleport', s.JobId) return end
    end
end

-- ==========================================
-- UI
-- ==========================================
if CoreGui:FindFirstChild("RH_UI") then CoreGui.RH_UI:Destroy() end
local gui = Instance.new("ScreenGui", CoreGui); gui.Name = "RH_UI"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,280,0,100); frame.Position = UDim2.new(0.5,-140,0,10)
frame.BackgroundColor3 = Color3.fromRGB(10,10,10); frame.Active = true; frame.Draggable = true
Instance.new("UIStroke", frame).Color = Color3.fromRGB(255,200,0)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

local function MakeLabel(y, text, color)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(1,-16,0,20); l.Position = UDim2.new(0,8,0,y)
    l.Text = text; l.TextColor3 = color or Color3.fromRGB(200,200,200)
    l.BackgroundTransparency = 1; l.Font = Enum.Font.Gotham; l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left; return l
end

local TitleL = MakeLabel(2, "Auto Rainbow Haki v4", Color3.fromRGB(255,200,0))
TitleL.Font = Enum.Font.GothamBold; TitleL.TextSize = 13; TitleL.TextXAlignment = Enum.TextXAlignment.Center
local StatusL = MakeLabel(28, "Weapon: "..getgenv().WeaponType.." | Starting...")
StatusL.Font = Enum.Font.GothamSemibold
local QuestL = MakeLabel(50, "Quest: ---", Color3.fromRGB(255,200,0))
local BossL = MakeLabel(72, "Boss: ---")

UIS.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.LeftAlt then frame.Visible = not frame.Visible end end)

-- ==========================================
-- BOSS CONFIG (file 2 entrance + file 1/3/4/5 positions)
-- ==========================================
local NPC_POS = CFrame.new(-11892.0703125, 930.57672119141, -8760.1591796875)

local BOSSES = {
    {q="Stone", boss="Stone",
        tp = CFrame.new(-1086.11621, 38.8425903, 6768.71436)},
    {q="Hydra Leader", boss="Hydra Leader",
        tp = CFrame.new(5821.89794921875, 1019.0950927734375, -73.71923065185547),
        entrance = Vector3.new(5643.45263671875, 1013.0858154296875, -340.51025390625)},
    {q="Kilo Admiral", boss="Kilo Admiral",
        tp = CFrame.new(2877.61743, 423.558685, -7207.31006)},
    {q="Captain Elephant", boss="Captain Elephant",
        tp = CFrame.new(-13376.7578125, 433.28689575195, -8071.392578125),
        entrance = Vector3.new(-12471.169921875, 374.94024658203, -7551.677734375)},
    {q="Beautiful Pirate", boss="Beautiful Pirate",
        tp = CFrame.new(5312.3598632813, 20.141201019287, -10.158538818359),
        entrance = Vector3.new(5314.54638671875, 22.562219619750977, -127.06755065917969)},
}

-- ==========================================
-- RAINBOW CHECKER
-- ==========================================
local rainbowDone = false

local function CheckRainbow()
    local found = false
    pcall(function()
        local inv = COMMF_:InvokeServer("getInventory")
        if type(inv) == "table" then
            for _, item in pairs(inv) do
                if type(item) == "table" then
                    local n = item.Name or item.name or ""
                    if type(n) == "string" and n:lower():find("rainbow") then found = true break end
                end
            end
        end
    end)
    if not found then
        pcall(function()
            local r = RS.Modules.Net:FindFirstChild("RF/FruitCustomizerRF"):InvokeServer({
                StorageName="Rainbow Saviour", Type="AuraSkin", Context="Equip"
            })
            if r ~= nil and r ~= false then found = true end
        end)
    end
    return found
end

local function OnFound()
    if rainbowDone then return end
    rainbowDone = true; _active = false; StopTween()
    pcall(function() writefile(plr.Name..".txt","Completed-rainbow") end)
    warn("[Rainbow] ✅ DONE!")
    StatusL.Text = "✅ ĐÃ CÓ RAINBOW HAKI!"
    StatusL.TextColor3 = Color3.fromRGB(0,255,0)
    QuestL.Text = "🌈 Completed-rainbow!"
    QuestL.TextColor3 = Color3.fromRGB(0,255,0)
    BossL.Text = "Dừng farm."; BossL.TextColor3 = Color3.fromRGB(0,255,0)
end

StatusL.Text = "Check Rainbow Haki..."
if CheckRainbow() then OnFound() end

task.spawn(function()
    while task.wait(30) do
        if rainbowDone then break end
        if CheckRainbow() then OnFound() break end
    end
end)

-- ==========================================
-- CHECK SEA 3
-- ==========================================
if not World3 and not rainbowDone then
    StatusL.Text = "TP Sea 3..."
    pcall(function() COMMF_:InvokeServer("TravelZou") end)
    task.wait(5)
end

-- ==========================================
-- MAIN LOOP
-- ==========================================
if not rainbowDone then _active = true end
local _waitStart = nil
local WAIT_TIMEOUT = 15

task.spawn(function()
    while task.wait(0.3) do
        if not _active then continue end
        xpcall(function()
            local questVisible = false
            local questText = ""
            pcall(function()
                questVisible = plr.PlayerGui.Main.Quest.Visible
                if questVisible then
                    questText = plr.PlayerGui.Main.Quest.Container.QuestTitle.Title.Text
                end
            end)

            if not questVisible then
                -- ĐẾN HORNEDMAN NHẬN QUEST
                _waitStart = nil
                QuestL.Text = "Quest: → HornedMan..."
                QuestL.TextColor3 = Color3.fromRGB(255,100,100)
                BossL.Text = "Boss: ---"

                local dist = GetDist(NPC_POS.Position)
                if dist > 20 then
                    StatusL.Text = "Tween HornedMan... "..math.floor(dist)
                    TweenTo(NPC_POS) -- blocking tween, đợi đến nơi
                end
                -- Đã đến gần → nhận quest
                StatusL.Text = "Nhận quest..."
                task.wait(1)
                pcall(function() COMMF_:InvokeServer("HornedMan","Bet") end)
                StatusL.Text = "Đã nhận!"
                StatusL.TextColor3 = Color3.fromRGB(0,255,0)
                task.wait(2)
                return
            end

            -- CÓ QUEST → match boss
            local matched = nil
            for _, cfg in ipairs(BOSSES) do
                if string.find(questText, cfg.q) then matched = cfg break end
            end

            if not matched then
                _waitStart = nil
                QuestL.Text = "Quest: "..string.sub(questText,1,25)
                BossL.Text = "Boss: ???"
                return
            end

            QuestL.Text = "Quest: "..matched.q
            QuestL.TextColor3 = Color3.fromRGB(0,255,0)

            -- requestEntrance nếu boss cần cổng (file 2)
            if matched.entrance then
                pcall(function() COMMF_:InvokeServer("requestEntrance", matched.entrance) end)
                task.wait(2) -- đợi cổng mở xong
            end

            -- Tìm boss
            local bossModel = nil
            for _, container in next, {workspace.Enemies, RS} do
                for _, m in next, container:GetChildren() do
                    if m.Name == matched.boss and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                        bossModel = m break
                    end
                end
                if bossModel then break end
            end

            if bossModel then
                -- BOSS CÓ → đánh
                _waitStart = nil
                local hp = math.floor(bossModel.Humanoid.Health / bossModel.Humanoid.MaxHealth * 100)
                BossL.Text = "Boss: "..matched.boss.." | "..hp.."%"
                BossL.TextColor3 = Color3.fromRGB(255,100,100)
                StatusL.Text = "Fight "..matched.boss

                repeat
                    task.wait()
                    KillBoss(matched.boss)
                until not _active
                    or not bossModel.Parent
                    or bossModel.Humanoid.Health <= 0
                    or not plr.PlayerGui.Main.Quest.Visible
            else
                -- BOSS CHƯA SPAWN → tween đến vị trí chờ
                if GetDist(matched.tp.Position) > 50 then
                    StatusL.Text = "Tween "..matched.boss.."..."
                    TweenStart(matched.tp) -- non-blocking
                end

                if not _waitStart then _waitStart = tick() end
                local remain = WAIT_TIMEOUT - math.floor(tick() - _waitStart)

                if remain > 0 then
                    BossL.Text = "Boss: "..matched.boss.." | Đợi "..remain.."s"
                    BossL.TextColor3 = Color3.fromRGB(255,200,0)
                    StatusL.Text = "Waiting..."
                else
                    _waitStart = nil
                    StopTween()
                    BossL.Text = "HOP!"; BossL.TextColor3 = Color3.fromRGB(255,0,0)
                    StatusL.Text = "Hop server..."
                    task.wait(1)
                    HopServer()
                end
            end
        end, function(err) warn("[Rainbow]", err) end)
    end
end)

-- ==========================================
-- AUTO BUSO/KEN
-- ==========================================
task.spawn(function()
    while task.wait(4) do
        if not _active then continue end
        pcall(function()
            if Humanoid and Humanoid.Health > 0 then
                AutoHaki()
                pcall(function() RS.Remotes.CommE:FireServer("Ken", true) end)
            end
        end)
    end
end)

-- ==========================================
-- ERROR HANDLING
-- ==========================================
TeleportService.TeleportInitFailed:Connect(function(_, res, msg)
    if res == Enum.TeleportResult.IsTeleporting and msg:find("previous teleport") then
        task.delay(10, function() game:Shutdown() end)
    end
end)
GuiService.ErrorMessageChanged:Connect(newcclosure(function()
    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
        while true do TeleportService:TeleportToPlaceInstance(PlaceId, JobId, plr) task.wait(5) end
    end
end))

print("[Rainbow v4] ✅ | LeftAlt ẩn/hiện | "..getgenv().WeaponType)
