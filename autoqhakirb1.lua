-- [[ AUTO RAINBOW HAKI - STANDALONE ]]
-- Bảo mật: KaitunBoss XOR FastAttack + BananaCat NoClip/BodyClip/AntiStun
-- Farm: KaitunBoss KillMonster style + BananaCat quest detection
-- Config: chọn weapon type ở đây

-- ==========================================
-- CONFIG
-- ==========================================
getgenv().Team = "Pirates"
getgenv().WeaponType = getgenv().WeaponType or "Melee" -- "Melee" / "Sword" / "Blox Fruit"

-- ==========================================
-- CHỌN TEAM (VirtualInputManager)
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
-- SERVICES & PLAYER
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
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
local Humanoid = Character and Character:FindFirstChild("Humanoid")
local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(v)
    Character = v
    Humanoid = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)

if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
    task.wait(10 - workspace.DistributedGameTime)
end
repeat task.wait(2) until Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChildWhichIsA("Humanoid") and Character:IsDescendantOf(workspace.Characters)

-- ==========================================
-- SECURITY: XOR ENCRYPTED FAST ATTACK (KaitunBoss)
-- ==========================================
local remoteAttack, idremote
local seed = RS.Modules.Net.seed:InvokeServer()
task.spawn((function() for _, v in next, ({RS.Util, RS.Common, RS.Remotes, RS.Assets, RS.FX}) do
    for _, n in next, v:GetChildren() do if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
    end v.ChildAdded:Connect(function(n) if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id")
    end end) end
end))

local lastCallFA = tick()
local function FastAttack(x)
    if not HumanoidRootPart or not Character:FindFirstChildWhichIsA("Humanoid") or Character.Humanoid.Health <= 0 or not Character:FindFirstChildWhichIsA("Tool") then return end
    local FAD = 0.01
    if FAD ~= 0 and tick() - lastCallFA <= FAD then return end
    local t = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h = e:FindFirstChild("Humanoid") local hrp = e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then t[#t + 1] = e end
    end
    local n = RS.Modules.Net
    local h = {[2] = {}}
    local last
    for i = 1, #t do local v = t[i]
        local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
        if not h[1] then h[1] = part end
        h[2][#h[2] + 1] = {v, part} last = v
    end
    -- XOR encrypted remote (KaitunBoss security)
    n:FindFirstChild("RE/RegisterAttack"):FireServer()
    n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
    cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".",function(c)
        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1))
    end), bit32.bxor(idremote+909090, seed*2), unpack(h))
    lastCallFA = tick()
end

-- ==========================================
-- SECURITY: BANANA ATTACK (LeftClickRemote fallback)
-- ==========================================
local function AttackNoCoolDown()
    if not Character then return end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if not tool then return end

    local function isAlive(m)
        local h = m and m:FindFirstChild("Humanoid")
        return h and h.Health > 0
    end

    if tool:FindFirstChild("LeftClickRemote") then
        -- LeftClickRemote method (BananaCat)
        local counter = 1
        for _, e in next, workspace.Enemies:GetChildren() do
            local hrp = e:FindFirstChild("HumanoidRootPart")
            if hrp and isAlive(e) and (hrp.Position - Character:GetPivot().Position).Magnitude <= 60 then
                local dir = (hrp.Position - Character:GetPivot().Position).Unit
                pcall(function() tool.LeftClickRemote:FireServer(dir, counter) end)
                counter = counter + 1 > 1000000000 and 1 or counter + 1
            end
        end
    else
        -- RE/RegisterHit method (KaitunBoss XOR)
        FastAttack()
    end
end

-- ==========================================
-- SECURITY: NOCLIP + BODYCLIP + ANTI STUN (BananaCat)
-- ==========================================
local _rainbowActive = false

-- BodyClip: anti-gravity giữ character không rơi
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _rainbowActive then
                if not HumanoidRootPart:FindFirstChild("BodyClip") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "BodyClip"
                    bv.Parent = HumanoidRootPart
                    bv.MaxForce = Vector3.new(100000, 100000, 100000)
                    bv.Velocity = Vector3.new(0, 0, 0)
                end
            else
                local bc = HumanoidRootPart:FindFirstChild("BodyClip")
                if bc then bc:Destroy() end
            end
        end)
    end
end)

-- NoClip: xuyên tường khi farm
RunService.Stepped:Connect(function()
    if _rainbowActive and Character then
        pcall(function()
            for _, part in next, Character:GetDescendants() do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
end)

-- Anti Stun: chống bị stun
task.spawn(function()
    pcall(function()
        if Character:FindFirstChild("Stun") then
            Character.Stun.Changed:Connect(function()
                pcall(function()
                    if Character:FindFirstChild("Stun") then
                        Character.Stun.Value = 0
                    end
                end)
            end)
        end
    end)
end)

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
local SelectWeapon = ""

-- Auto detect weapon by type
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            for _, src in next, {LocalPlayer.Backpack, Character} do
                if src then
                    for _, t in next, src:GetChildren() do
                        if t:IsA("Tool") and t.ToolTip == getgenv().WeaponType then
                            SelectWeapon = t.Name
                            return
                        end
                    end
                end
            end
        end)
    end
end)

local function EquipWeapon(name)
    if not Character then return end
    -- Đã cầm đúng tool → skip
    local current = Character:FindFirstChildWhichIsA("Tool")
    if current and current.Name == name then return end
    local tool = LocalPlayer.Backpack:FindFirstChild(name)
    if tool then Humanoid:EquipTool(tool) end
end

local function AutoHaki()
    pcall(function()
        if not Character:FindFirstChild("HasBuso") then
            COMMF_:InvokeServer("Buso")
        end
    end)
end

-- Tween (KaitunBoss ghost part style - mượt hơn)
local connection, tween, pathPart, isTweening = nil, nil, nil, false
local function Tween(targetCFrame)
    pcall(function() Character.Humanoid.Sit = false end)
    if not Character.Humanoid or Character.Humanoid.Health <= 0 then
        pcall(function() workspace.TweenGhost:Destroy() end)
        connection, tween, pathPart, isTweening = nil, nil, nil, false
        return
    end
    if targetCFrame == false then
        if tween then pcall(function() tween:Cancel() end) tween = nil end
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        isTweening = false
        return
    end
    if isTweening or not targetCFrame then return end
    isTweening = true
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then isTweening = false return end
    local distance = (targetCFrame.Position - root.Position).Magnitude
    pathPart = Instance.new("Part")
    pathPart.Name = "TweenGhost"
    pathPart.Transparency = 1
    pathPart.Anchored = true
    pathPart.CanCollide = false
    pathPart.CFrame = root.CFrame
    pathPart.Size = Vector3.new(50, 50, 50)
    pathPart.Parent = workspace
    tween = TweenService:Create(pathPart, TweenInfo.new(distance / 250, Enum.EasingStyle.Linear), {CFrame = targetCFrame * CFrame.new(0, 5, 0)})
    connection = RunService.Heartbeat:Connect(function()
        if root and pathPart then root.CFrame = pathPart.CFrame * CFrame.new(0, 5, 0) end
    end)
    tween.Completed:Connect(function()
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        tween = nil
        isTweening = false
    end)
    tween:Play()
end

-- KillMonster hybrid: KaitunBoss distance check + dual attack
local lastKenCall = tick()
local function KillBoss(bossName)
    for _, container in next, {workspace.Enemies, RS} do
        for _, v in next, container:GetChildren() do
            if v.Name == bossName then
                local vh = v:FindFirstChild("Humanoid")
                local vhrp = v:FindFirstChild("HumanoidRootPart")
                if vh and vh.Health > 0 and vhrp then
                    local dist = (HumanoidRootPart.Position - vhrp.Position).Magnitude
                    if dist <= 70 then
                        -- Dual attack: FastAttack XOR + AttackNoCoolDown
                        FastAttack(bossName)
                        AttackNoCoolDown()
                        -- Ken Haki mỗi 10s
                        if tick() - lastKenCall >= 10 then
                            lastKenCall = tick()
                            pcall(function() RS.Remotes.CommE:FireServer("Ken", true) end)
                        end
                        AutoHaki()
                        EquipWeapon(SelectWeapon)
                        -- Giữ boss đứng yên (BananaCat style)
                        vhrp.CanCollide = false
                        vhrp.Size = Vector3.new(50, 50, 50)
                        -- Tween offset (KaitunBoss style)
                        Tween(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                        return true
                    end
                    Tween(vhrp.CFrame)
                    return false
                end
            end
        end
    end
    return nil -- boss not found
end

-- ==========================================
-- HOP SERVER (__ServerBrowser - KaitunBoss gốc)
-- ==========================================
function IfTableHaveIndex(j)
    for _ in j do
        return true
    end
end
local LastServersDataPulled, CachedServers
function GetServers()
    if LastServersDataPulled then
        if os.time() - LastServersDataPulled < 60 then
            return CachedServers
        end
    end
    for i = 1, 100, 1 do
        local data = game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer(i)
        if IfTableHaveIndex(data) then
            LastServersDataPulled = os.time()
            CachedServers = data
            return data
        end
    end
end
HopServer = function(Reason, MaxPlayers, ForcedRegion)
    local Servers = GetServers()
    local ArrayServers = {}
    for i, v in Servers do
        table.insert(ArrayServers, {
            JobId = i,
            Players = v.Count,
            LastUpdate = v.__LastUpdate,
            Region = v.Region
        })
    end
    print(#ArrayServers, 'servers received')
    local ServerData
    for i = 1, #ArrayServers do
        while task.wait() do
            local Index = math.random(1, #ArrayServers)
            ServerData = ArrayServers[Index]
            if ServerData then
                if not MaxPlayers or ServerData.Players < 5 then
                    if not ForcedRegion or ServerData.Regoin == ForcedRegion then
                        print("Found Server:", ServerData.JobId, 'Player Count:', ServerData.Players, "Region:",
                            ServerData.Region)
                        break
                    end
                end
            end
        end
        print('Teleporting to', ServerData.JobId, '...')
        game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer('teleport', ServerData.JobId)
    end
end

-- ==========================================
-- UI (GOLD/BLACK)
-- ==========================================
if CoreGui:FindFirstChild("RainbowHaki_UI") then
    CoreGui.RainbowHaki_UI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "RainbowHaki_UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 100)
MainFrame.Position = UDim2.new(0.5, -140, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Text = "Auto Rainbow Haki"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -16, 0, 20)
StatusLabel.Position = UDim2.new(0, 8, 0, 28)
StatusLabel.Text = "Weapon: " .. getgenv().WeaponType .. " | Starting..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local QuestLabel = Instance.new("TextLabel", MainFrame)
QuestLabel.Size = UDim2.new(1, -16, 0, 20)
QuestLabel.Position = UDim2.new(0, 8, 0, 50)
QuestLabel.Text = "Quest: Checking..."
QuestLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
QuestLabel.BackgroundTransparency = 1
QuestLabel.Font = Enum.Font.Gotham
QuestLabel.TextSize = 10
QuestLabel.TextXAlignment = Enum.TextXAlignment.Left

local BossLabel = Instance.new("TextLabel", MainFrame)
BossLabel.Size = UDim2.new(1, -16, 0, 20)
BossLabel.Position = UDim2.new(0, 8, 0, 70)
BossLabel.Text = "Boss: ---"
BossLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
BossLabel.BackgroundTransparency = 1
BossLabel.Font = Enum.Font.Gotham
BossLabel.TextSize = 10
BossLabel.TextXAlignment = Enum.TextXAlignment.Left

-- LeftAlt toggle
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.LeftAlt then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- ==========================================
-- BOSS CONFIG: Quest text → Boss name → TP location
-- ==========================================
local HORNED_MAN_CFRAME = CFrame.new(-11892.0703125, 930.57672119141, -8760.1591796875)

local QUEST_BOSSES = {
    {quest = "Stone",            boss = "Stone",            tp = CFrame.new(-1086.11621, 38.8425903, 6768.71436)},
    {quest = "Hydra Leader",     boss = "Hydra Leader",     tp = CFrame.new(5713.98877, 601.922974, 202.751251)},
    {quest = "Kilo Admiral",     boss = "Kilo Admiral",     tp = CFrame.new(2877.61743, 423.558685, -7207.31006)},
    {quest = "Captain Elephant", boss = "Captain Elephant", tp = CFrame.new(-13485.0283, 331.709259, -8012.4873)},
    {quest = "Beautiful Pirate", boss = "Beautiful Pirate", tp = CFrame.new(5312.3598632813, 20.141201019287, -10.158538818359)},
}

-- ==========================================
-- MAIN LOOP: Auto Rainbow Haki
-- ==========================================
_rainbowActive = true
local _bossWaitStart = nil
local BOSS_WAIT_TIMEOUT = 10 -- đợi boss 10s, không spawn → hop

task.spawn(function()
    while task.wait(0.2) do
        if not _rainbowActive then continue end
        xpcall(function()
            local questUI = LocalPlayer.PlayerGui:FindFirstChild("Main")
            local questVisible = questUI and questUI.Quest and questUI.Quest.Visible
            local questText = ""

            if questVisible then
                pcall(function()
                    questText = questUI.Quest.Container.QuestTitle.Title.Text
                end)
            end

            if questVisible and questText ~= "" then
                -- Có quest → tìm boss tương ứng
                local matchedBoss = nil
                for _, cfg in ipairs(QUEST_BOSSES) do
                    if string.find(questText, cfg.quest) then
                        matchedBoss = cfg
                        break
                    end
                end

                if matchedBoss then
                    QuestLabel.Text = "Quest: " .. matchedBoss.quest
                    QuestLabel.TextColor3 = Color3.fromRGB(0, 255, 0)

                    -- Check boss có spawn không
                    local bossModel = nil
                    for _, container in next, {workspace.Enemies, RS} do
                        for _, m in next, container:GetChildren() do
                            if m.Name == matchedBoss.boss and m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 then
                                bossModel = m
                                break
                            end
                        end
                        if bossModel then break end
                    end

                    if bossModel then
                        -- Boss có → đánh, reset timer
                        _bossWaitStart = nil
                        BossLabel.Text = "Boss: " .. matchedBoss.boss .. " | HP: " .. math.floor(bossModel.Humanoid.Health / bossModel.Humanoid.MaxHealth * 100) .. "%"
                        BossLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                        StatusLabel.Text = "Fighting " .. matchedBoss.boss .. "..."
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)

                        KillBoss(matchedBoss.boss)
                    else
                        -- Boss chưa spawn → TP đến vị trí boss + đợi
                        Tween(matchedBoss.tp)

                        -- Bắt đầu đếm thời gian đợi
                        if not _bossWaitStart then
                            _bossWaitStart = tick()
                        end

                        local waited = math.floor(tick() - _bossWaitStart)
                        local remaining = BOSS_WAIT_TIMEOUT - waited

                        if remaining > 0 then
                            BossLabel.Text = "Boss: " .. matchedBoss.boss .. " | Đợi spawn " .. remaining .. "s..."
                            BossLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                            StatusLabel.Text = "Waiting for " .. matchedBoss.boss .. "..."
                        else
                            -- Hết thời gian đợi → Hop server
                            _bossWaitStart = nil
                            BossLabel.Text = "Boss: " .. matchedBoss.boss .. " | HOP SERVER!"
                            BossLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                            StatusLabel.Text = "Boss không spawn → Hop..."
                            StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                            warn("[Rainbow] " .. matchedBoss.boss .. " không spawn sau " .. BOSS_WAIT_TIMEOUT .. "s → Hop!")

                            Tween(false) -- cancel tween
                            task.wait(1)
                            HopServer(8)
                        end
                    end
                else
                    -- Quest không match boss nào
                    _bossWaitStart = nil
                    QuestLabel.Text = "Quest: " .. string.sub(questText, 1, 30) .. "..."
                    QuestLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                    BossLabel.Text = "Boss: Không khớp quest"
                end
            else
                -- Không có quest → TP đến HornedMan nhận quest
                _bossWaitStart = nil
                QuestLabel.Text = "Quest: Chưa có → Đến HornedMan..."
                QuestLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                BossLabel.Text = "Boss: ---"

                Tween(HORNED_MAN_CFRAME)

                -- Đến gần → nhận quest
                if HumanoidRootPart and (HORNED_MAN_CFRAME.Position - HumanoidRootPart.Position).Magnitude <= 30 then
                    StatusLabel.Text = "Nhận quest từ HornedMan..."
                    Tween(false)
                    task.wait(1.5)
                    pcall(function()
                        COMMF_:InvokeServer("HornedMan", "Bet")
                    end)
                    StatusLabel.Text = "Đã nhận quest!"
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    task.wait(1)
                end
            end
        end, function(err) warn("[Rainbow] Error:", err) end)
    end
end)

-- ==========================================
-- AUTO BUSO/KEN (Background)
-- ==========================================
task.spawn(function()
    while task.wait(4) do
        xpcall(function()
            if not Character.Humanoid or Character.Humanoid.Health <= 0 then
                pcall(function() workspace.TweenGhost:Destroy() end)
                connection, tween, pathPart, isTweening = nil, nil, nil, false
                return
            end
            AutoHaki()
            -- Ken Haki
            pcall(function() RS.Remotes.CommE:FireServer("Ken", true) end)
        end, function() end)
    end
end)

-- ==========================================
-- ERROR HANDLING (KaitunBoss)
-- ==========================================
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, message)
    if teleportResult == Enum.TeleportResult.GameFull then
        -- do nothing
    elseif teleportResult == Enum.TeleportResult.IsTeleporting and (message:find("previous teleport")) then
        StarterGui:SetCore("SendNotification", {Title = "Death Hop Found", Text = message, Duration = 8})
        task.delay(10, function() game:Shutdown() end)
    end
end)
GuiService.ErrorMessageChanged:Connect(newcclosure(function()
    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
        while true do TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer) task.wait(5) end
    end
end))

print("[Rainbow Haki] ✅ Loaded | LeftAlt ẩn/hiện | Weapon: " .. getgenv().WeaponType)
