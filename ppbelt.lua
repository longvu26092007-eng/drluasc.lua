--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║         DOJO PURPLE BELT - AUTO ELITE BOSS FARM + HOP          ║
    ║                                                                  ║
    ║  Nguồn gốc:                                                     ║
    ║  • Bảo mật + Attack + Tween + Hop: KaitunBoss (__ServerBrowser) ║
    ║  • Belt detect + Elite logic + Anti-detect: 6 file Banana       ║
    ║                                                                  ║
    ║  Flow:                                                           ║
    ║  1. Join team → 2. Nhận quest Purple Belt → 3. Detect Elite     ║
    ║  4. Không có Elite → Hop __ServerBrowser → 5. Có Elite → Kill   ║
    ║  6. Xong quest → Ghi file Completed → Dừng                     ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

-- ==========================================
-- CẤU HÌNH
-- ==========================================
getgenv().PurpleBelt = {
    Running = true,             -- Master switch
    Team = "Pirates",           -- "Pirates" hoặc "Marines"
    WeaponType = "Melee",       -- "Melee" / "Sword" / "Blox Fruit"
    HopMaxPlayers = 5,          -- Chỉ hop vào server < X người
    AttackRange = 65,           -- Phạm vi tấn công (studs)
    TweenSpeed = 250,           -- Tốc độ bay (studs/giây)
    AutoBuso = true,            -- Tự bật Buso Haki
    AutoKen = true,             -- Tự bật Ken Haki  
    HopWaitTime = 8,            -- Chờ X giây sau khi vào server mới trước khi hop tiếp
}

-- ==========================================
-- SERVICES
-- ==========================================
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local CollectionService  = game:GetService("CollectionService")
local VirtualInputManager= game:GetService("VirtualInputManager")
local TeleportService    = game:GetService("TeleportService")
local StarterGui         = game:GetService("StarterGui")
local GuiService         = game:GetService("GuiService")
local Lighting           = game:GetService("Lighting")

-- ==========================================
-- PLAYER & CHARACTER
-- ==========================================
local PlaceId, JobId = game.PlaceId, game.JobId
local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, HumanoidRootPart

local function RefreshCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(RefreshCharacter)
if LocalPlayer.Character then
    RefreshCharacter(LocalPlayer.Character)
end

-- ==========================================
-- CHỜ GAME LOAD XONG (KaitunBoss style)
-- ==========================================
StarterGui:SetCore("SendNotification", {
    Title = "Purple Belt",
    Text = "Đang load... Vui lòng chờ",
    Duration = 5
})

if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
    task.wait(10 - workspace.DistributedGameTime)
end

local COMMF_ = ReplicatedStorage:WaitForChild("Remotes") and ReplicatedStorage.Remotes:WaitForChild("CommF_")
if not COMMF_ then repeat task.wait(1) until COMMF_ end

-- ==========================================
-- BƯỚC 1: JOIN TEAM (KaitunBoss style)
-- ==========================================
task.spawn(function()
    xpcall(function()
        if not LocalPlayer.Team then
            if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
                repeat task.wait(1) until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
            end
            xpcall(function()
                COMMF_:InvokeServer("SetTeam", getgenv().PurpleBelt.Team)
            end, function()
                pcall(function()
                    firesignal(LocalPlayer.PlayerGui["Main (minimal)"].ChooseTeam.Container[getgenv().PurpleBelt.Team])
                end)
            end)
            task.wait(2)
        end
    end, function(err) warn("[PurpleBelt] Team join error:", err) end)
end)

-- Chờ character spawn xong hoàn toàn
repeat task.wait(2) until Character
    and Character:FindFirstChild("HumanoidRootPart")
    and Character:FindFirstChildWhichIsA("Humanoid")
    and Character:IsDescendantOf(workspace.Characters)

-- ==========================================
-- KIỂM TRA SEA
-- ==========================================
local function CheckSea(v)
    local ok, result = pcall(function()
        return v == tonumber(workspace:GetAttribute("MAP"):match("%d+"))
    end)
    return ok and result
end

-- ==========================================
-- OBFUSCATED ATTACK SYSTEM (KaitunBoss)
-- Remote attack với seed + bxor bypass anti-cheat
-- ==========================================
local remoteAttack, idremote
local seed

pcall(function()
    seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()
end)

task.spawn(function()
    local folders = {}
    pcall(function() table.insert(folders, ReplicatedStorage.Util) end)
    pcall(function() table.insert(folders, ReplicatedStorage.Common) end)
    pcall(function() table.insert(folders, ReplicatedStorage.Remotes) end)
    pcall(function() table.insert(folders, ReplicatedStorage.Assets) end)
    pcall(function() table.insert(folders, ReplicatedStorage.FX) end)

    for _, v in next, folders do
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

-- ==========================================
-- ANTI-DETECT (từ Banana files)
-- ==========================================

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    local VU = game:GetService("VirtualUser")
    VU:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait()
    VU:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- Death effect bypass
task.defer(function()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Effect")
            and ReplicatedStorage.Effect:FindFirstChild("Container")
            and ReplicatedStorage.Effect.Container:FindFirstChild("Death") then
            local deathModule = require(ReplicatedStorage.Effect.Container.Death)
            local cameraShaker = require(ReplicatedStorage.Util.CameraShaker)
            if cameraShaker then cameraShaker:Stop() end
            if hookfunction then
                hookfunction(deathModule, function(...) return ... end)
            end
        end
    end)
end)

-- Stun bypass
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

-- NoClip khi đang farm (Banana style)
local _noclipActive = false
pcall(function()
    RunService.Stepped:Connect(function()
        if _noclipActive and Character then
            for _, v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)
end)

-- BodyVelocity giữ vị trí (Banana style)
local function EnsureBodyClip()
    if not Character or not HumanoidRootPart then return end
    if not HumanoidRootPart:FindFirstChild("BodyClip") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "BodyClip"
        bv.Parent = HumanoidRootPart
        bv.MaxForce = Vector3.new(100000, 100000, 100000)
        bv.Velocity = Vector3.new(0, 0, 0)
    end
end

local function RemoveBodyClip()
    pcall(function()
        if HumanoidRootPart and HumanoidRootPart:FindFirstChild("BodyClip") then
            HumanoidRootPart.BodyClip:Destroy()
        end
    end)
end

-- ==========================================
-- TIỆN ÍCH CHUNG
-- ==========================================
local ELITE_NAMES = {"Diablo", "Deandre", "Urban"}

local function IsEliteName(name)
    if not name then return false end
    for _, n in next, ELITE_NAMES do
        if name == n or name:find(n) then return true end
    end
    return false
end

local function CheckTool(v)
    for _, x in next, {LocalPlayer.Backpack, Character} do
        if x then
            for _, v2 in next, x:GetChildren() do
                if v2:IsA("Tool") and (v2.Name == v or (v2.Name:find(v))) then return true end
            end
        end
    end
    return false
end

local function CheckInventory(...)
    local ok, inv = pcall(function() return COMMF_:InvokeServer("getInventory") end)
    if not ok or not inv then return false end
    for _, v in pairs(inv) do
        for _, n in next, {...} do
            if v.Name == n then return true end
        end
    end
    return false
end

-- Tìm monster trong Enemies hoặc ReplicatedStorage (KaitunBoss style)
local function CheckMonster(...)
    local args = {...}
    local containers = {workspace.Enemies, ReplicatedStorage}
    for _, container in next, containers do
        for _, m in next, container:GetChildren() do
            if m:IsA("Model") and m.Name ~= "Blank Buddy" then
                local h = m:FindFirstChild("Humanoid")
                local r = m:FindFirstChild("HumanoidRootPart")
                if h and r and h.Health > 0 then
                    for _, n in next, args do
                        if m.Name == n or m.Name:lower():find(n:lower()) then
                            return m
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Equip vũ khí theo ToolTip
local function EquipWeapon(weaponType)
    if not Character then return end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if tool and tool.ToolTip == weaponType then return end
    for _, x in next, LocalPlayer.Backpack:GetChildren() do
        if x:IsA("Tool") and x.ToolTip == weaponType then
            Humanoid:EquipTool(x)
            return
        end
    end
end

-- Elite Boss tồn tại ở server?
local function EliteBossExists()
    for _, name in next, ELITE_NAMES do
        if ReplicatedStorage:FindFirstChild(name) or workspace.Enemies:FindFirstChild(name) then
            return true
        end
    end
    return false
end

-- ==========================================
-- FAST ATTACK (KaitunBoss - obfuscated remote)
-- ==========================================
local lastCallFA = tick()

local function FastAttack(targetName)
    if not HumanoidRootPart then return end
    if not Character:FindFirstChildWhichIsA("Humanoid") then return end
    if Character.Humanoid.Health <= 0 then return end
    if not Character:FindFirstChildWhichIsA("Tool") then return end

    local FAD = 0.01
    if tick() - lastCallFA <= FAD then return end

    local targets = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h = e:FindFirstChild("Humanoid")
        local hrp = e:FindFirstChild("HumanoidRootPart")
        if e ~= Character
            and (targetName and e.Name == targetName or not targetName)
            and h and hrp and h.Health > 0
            and (hrp.Position - HumanoidRootPart.Position).Magnitude <= getgenv().PurpleBelt.AttackRange
        then
            targets[#targets + 1] = e
        end
    end
    if #targets == 0 then return end

    local n = ReplicatedStorage.Modules.Net
    local h = {[2] = {}}
    for i = 1, #targets do
        local v = targets[i]
        local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
        if not h[1] then h[1] = part end
        h[2][#h[2] + 1] = {v, part}
    end

    -- Standard attack remotes
    pcall(function() n:FindFirstChild("RE/RegisterAttack"):FireServer() end)
    pcall(function() n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h)) end)

    -- Obfuscated attack (KaitunBoss bypass anti-cheat)
    pcall(function()
        if remoteAttack and idremote and seed then
            cloneref(remoteAttack):FireServer(
                string.gsub("RE/RegisterHit", ".", function(c)
                    return string.char(bit32.bxor(
                        string.byte(c),
                        math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
                    ))
                end),
                bit32.bxor(idremote + 909090, seed * 2),
                unpack(h)
            )
        end
    end)

    lastCallFA = tick()
end

-- ==========================================
-- TWEEN SYSTEM (KaitunBoss - TweenGhost)
-- ==========================================
local _conn, _tween, _pathPart, _isTweening = nil, nil, nil, false

local function Tween(targetCFrame, target)
    pcall(function() if Character and Humanoid then Humanoid.Sit = false end end)

    -- Character chết → reset
    if not Character or not Humanoid or Humanoid.Health <= 0 then
        pcall(function() workspace:FindFirstChild("TweenGhost"):Destroy() end)
        _conn, _tween, _pathPart, _isTweening = nil, nil, nil, false
        return
    end

    -- Tween(false) = hủy tween hiện tại
    if targetCFrame == false then
        if _tween then pcall(function() _tween:Cancel() end) _tween = nil end
        if _conn then _conn:Disconnect() _conn = nil end
        if _pathPart then _pathPart:Destroy() _pathPart = nil end
        _isTweening = false
        return
    end

    if _isTweening or not targetCFrame then return end
    _isTweening = true

    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then _isTweening = false return end

    target = target or root
    local distance = (targetCFrame.Position - target.Position).Magnitude
    local offsetY = (target ~= root) and CFrame.new(0, 30, 0) or CFrame.new(0, 5, 0)

    _pathPart = Instance.new("Part")
    _pathPart.Name = "TweenGhost"
    _pathPart.Transparency = 1
    _pathPart.Anchored = true
    _pathPart.CanCollide = false
    _pathPart.CFrame = target.CFrame
    _pathPart.Size = Vector3.new(50, 50, 50)
    _pathPart.Parent = workspace

    _tween = TweenService:Create(
        _pathPart,
        TweenInfo.new(distance / getgenv().PurpleBelt.TweenSpeed, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame * offsetY}
    )

    _conn = RunService.Heartbeat:Connect(function()
        if target and _pathPart then
            target.CFrame = _pathPart.CFrame * offsetY
        end
    end)

    _tween.Completed:Connect(function()
        if _conn then _conn:Disconnect() _conn = nil end
        if _pathPart then _pathPart:Destroy() _pathPart = nil end
        _tween = nil
        _isTweening = false
    end)

    _tween:Play()
end

-- ==========================================
-- KILL ELITE BOSS (KaitunBoss style tối ưu)
-- ==========================================
local lastKenCall = tick()

local function KillEliteBoss(bossName)
    xpcall(function()
        -- 1. Tìm trong workspace.Enemies (đã spawn, đánh được)
        for _, v in next, workspace.Enemies:GetChildren() do
            local vh = v:FindFirstChild("Humanoid")
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if vh and vh.Health > 0 and vhrp and v.Name == bossName then
                local dx = HumanoidRootPart.Position.X - vhrp.Position.X
                local dy = HumanoidRootPart.Position.Y - vhrp.Position.Y
                local dz = HumanoidRootPart.Position.Z - vhrp.Position.Z
                local sqrMag = dx*dx + dy*dy + dz*dz

                if sqrMag <= (getgenv().PurpleBelt.AttackRange ^ 2) then
                    -- Trong phạm vi → tấn công
                    _noclipActive = true
                    EnsureBodyClip()
                    FastAttack(bossName)

                    -- Auto Buso
                    if getgenv().PurpleBelt.AutoBuso then
                        if not Character:FindFirstChild("HasBuso") then
                            pcall(function() COMMF_:InvokeServer("Buso") end)
                        end
                    end

                    -- Auto Ken (throttled 10s)
                    if getgenv().PurpleBelt.AutoKen then
                        if tick() - lastKenCall >= 10 then
                            lastKenCall = tick()
                            pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end)
                        end
                    end

                    -- Đứng trước mặt boss (KaitunBoss positioning)
                    Tween(CFrame.new(
                        vhrp.Position
                        + (vhrp.CFrame.LookVector * 20)
                        + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)
                    ))

                    EquipWeapon(getgenv().PurpleBelt.WeaponType)
                    return true -- đang đánh
                end

                -- Ngoài phạm vi → tween đến
                Tween(vhrp.CFrame)
                return true -- đang di chuyển tới
            end
        end

        -- 2. Tìm trong ReplicatedStorage (chưa spawn vào Enemies)
        for _, v in next, ReplicatedStorage:GetChildren() do
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and v.Name == bossName then
                Tween(vhrp.CFrame)
                return true -- đang di chuyển tới spawn
            end
        end

        return false -- không tìm thấy
    end, function(e) warn("[PurpleBelt] KillEliteBoss ERROR:", e) return false end)
end

-- ==========================================
-- HOP SERVER (__ServerBrowser - KaitunBoss)
-- ==========================================
local LastServersDataPulled, CachedServers

local function IfTableHaveIndex(j)
    for _ in j do return true end
    return false
end

local function GetServers()
    if LastServersDataPulled and os.time() - LastServersDataPulled < 60 then
        return CachedServers
    end
    for i = 1, 100 do
        local ok, data = pcall(function()
            return ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer(i)
        end)
        if ok and data and IfTableHaveIndex(data) then
            LastServersDataPulled = os.time()
            CachedServers = data
            return data
        end
    end
    return nil
end

local function HopServer(reason)
    local Servers = GetServers()
    if not Servers then
        warn("[PurpleBelt] Không lấy được danh sách server")
        return
    end

    local ArrayServers = {}
    for jobId, v in Servers do
        table.insert(ArrayServers, {
            JobId = jobId,
            Players = v.Count,
            Region = v.Region
        })
    end

    print("[PurpleBelt] " .. #ArrayServers .. " servers | Lý do: " .. tostring(reason))

    for attempt = 1, math.min(#ArrayServers, 20) do
        local Index = math.random(1, #ArrayServers)
        local ServerData = ArrayServers[Index]
        if ServerData and ServerData.Players < getgenv().PurpleBelt.HopMaxPlayers then
            print("[PurpleBelt] → Hop đến: " .. ServerData.JobId .. " (" .. ServerData.Players .. " players)")
            StarterGui:SetCore("SendNotification", {
                Title = "Purple Belt",
                Text = "Hop server: " .. tostring(reason),
                Duration = 3
            })
            pcall(function()
                ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer("teleport", ServerData.JobId)
            end)
            task.wait(10) -- chờ teleport
            return true
        end
    end

    warn("[PurpleBelt] Không tìm server phù hợp, thử lại...")
    return false
end

-- ==========================================
-- DOJO BELT DETECTION (từ Banana file 2)
-- ==========================================

-- Lấy tên Belt hiện tại từ Dojo Trainer
local function GetCurrentBeltName()
    local ok, progress = pcall(function()
        local args = {[1] = {["NPC"] = "Dojo Trainer", ["Command"] = "RequestQuest"}}
        return ReplicatedStorage.Modules.Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args))
    end)
    if ok and type(progress) == "table" and progress.Quest and progress.Quest["BeltName"] then
        return progress.Quest["BeltName"], progress
    end
    return nil, progress
end

-- Nhận quest Purple Belt
local function RequestPurpleBeltQuest()
    local beltName, progress = GetCurrentBeltName()
    return beltName, progress
end

-- Claim quest đã hoàn thành
local function ClaimDojoQuest()
    pcall(function()
        local args = {[1] = {["NPC"] = "Dojo Trainer", ["Command"] = "ClaimQuest"}}
        ReplicatedStorage.Modules.Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args))
    end)
end

-- Kiểm tra Purple Belt đã có trong inventory chưa
local function HasPurpleBelt()
    return CheckInventory("Purple Belt") or CheckInventory("Dojo Belt (Purple)")
end

-- Vị trí Dojo Trainer (Dragon Dojo trên đảo Hydra)
local DOJO_TRAINER_POS = CFrame.new(5865.0234375, 1208.3154296875, 871.15185546875)
local HYDRA_ENTRANCE = Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906)

-- Teleport vào đảo Hydra
local function TeleportToHydra()
    pcall(function()
        COMMF_:InvokeServer("requestEntrance", HYDRA_ENTRANCE)
    end)
end

-- ==========================================
-- ELITE HUNTER QUEST (từ Banana files)
-- ==========================================
local function AcceptEliteQuest()
    pcall(function()
        COMMF_:InvokeServer("EliteHunter")
    end)
end

local function GetEliteProgress()
    local ok, progress = pcall(function()
        return COMMF_:InvokeServer("EliteHunter", "Progress")
    end)
    return ok and progress or 0
end

-- Kiểm tra quest GUI có đang hiển thị quest Elite không
local function GetQuestInfo()
    local ok, result = pcall(function()
        local questGUI = LocalPlayer.PlayerGui.Main.Quest
        if questGUI.Visible then
            local questText = questGUI.Container.QuestTitle.Title.Text
            return {visible = true, text = questText, isElite = IsEliteName(questText)}
        end
        return {visible = false, text = "", isElite = false}
    end)
    return ok and result or {visible = false, text = "", isElite = false}
end

-- ==========================================
-- GHI FILE HOÀN THÀNH
-- ==========================================
local function WriteCompletedFile()
    pcall(function()
        local playerName = LocalPlayer.Name
        local fileName = playerName .. ".txt"
        -- Ghi vào workspace (thư mục executor)
        if writefile then
            writefile(fileName, "Completed-ppbelt")
            print("[PurpleBelt] ĐÃ GHI FILE: " .. fileName .. " → Completed-ppbelt")
            StarterGui:SetCore("SendNotification", {
                Title = "Purple Belt HOÀN THÀNH!",
                Text = "Đã ghi: " .. fileName,
                Duration = 10
            })
        else
            warn("[PurpleBelt] writefile không khả dụng, không ghi được file")
        end
    end)
end

-- Kiểm tra đã hoàn thành chưa (đọc file)
local function AlreadyCompleted()
    local ok, content = pcall(function()
        if readfile and isfile then
            local fileName = LocalPlayer.Name .. ".txt"
            if isfile(fileName) then
                return readfile(fileName)
            end
        end
        return nil
    end)
    return ok and content == "Completed-ppbelt"
end

-- ==========================================
-- AUTO BUSO HAKI LOOP (KaitunBoss style)
-- ==========================================
task.spawn(function()
    while task.wait(4) do
        xpcall(function()
            if not getgenv().PurpleBelt.Running then return end
            if not Character or not Humanoid or Humanoid.Health <= 0 then
                pcall(function() workspace:FindFirstChild("TweenGhost"):Destroy() end)
                _conn, _tween, _pathPart, _isTweening = nil, nil, nil, false
                return
            end
            -- Auto buy abilities nếu chưa có
            if not Character:FindFirstChild("HasBuso") then
                pcall(function() COMMF_:InvokeServer("Buso") end)
            end
            for _, v in next, {"Buso", "Geppo", "Soru"} do
                if not CollectionService:HasTag(Character, v) then
                    local cost = v == "Geppo" and 1e4 or v == "Buso" and 2.5e4 or v == "Soru" and 1e5 or 0
                    if LocalPlayer.Data.Beli.Value >= cost then
                        pcall(function() COMMF_:InvokeServer("BuyHaki", v) end)
                    end
                end
            end
        end, function(err) end)
    end
end)

-- ==========================================
-- ANTI-DISCONNECT + AUTO REJOIN (KaitunBoss)
-- ==========================================
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, message)
    if teleportResult == Enum.TeleportResult.IsTeleporting and message:find("previous teleport") then
        StarterGui:SetCore("SendNotification", {
            Title = "PurpleBelt",
            Text = "Teleport conflict: " .. message,
            Duration = 8
        })
        task.delay(10, function() game:Shutdown() end)
    end
end)

GuiService.ErrorMessageChanged:Connect(newcclosure(function()
    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
        while true do
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
            task.wait(5)
        end
    end
end))

-- ==========================================
-- ========== MAIN LOOP ===================
-- ==========================================
print("[PurpleBelt] Bắt đầu...")

-- Kiểm tra đã hoàn thành từ trước
if AlreadyCompleted() then
    StarterGui:SetCore("SendNotification", {
        Title = "Purple Belt",
        Text = "Đã hoàn thành từ trước! File tồn tại.",
        Duration = 10
    })
    print("[PurpleBelt] Đã hoàn thành Purple Belt từ trước. Dừng script.")
    return
end

task.spawn(function()
    -- Chờ ổn định
    task.wait(getgenv().PurpleBelt.HopWaitTime)

    while getgenv().PurpleBelt.Running do
        xpcall(function()
            -- ==============================
            -- KIỂM TRA SEA 3
            -- ==============================
            if not CheckSea(3) then
                print("[PurpleBelt] Không ở Sea 3 → Teleport...")
                pcall(function() COMMF_:InvokeServer("TravelZou") end)
                task.wait(5)
                return
            end

            -- ==============================
            -- BƯỚC 2: DETECT & NHẬN QUEST PURPLE BELT
            -- ==============================

            -- Teleport vào Hydra Island (nơi có Dragon Dojo)
            TeleportToHydra()
            task.wait(1)

            -- Bay đến Dojo Trainer
            if HumanoidRootPart and (DOJO_TRAINER_POS.Position - HumanoidRootPart.Position).Magnitude > 50 then
                Tween(DOJO_TRAINER_POS)
                -- Chờ đến nơi
                local waitStart = tick()
                repeat task.wait(0.5) until
                    not HumanoidRootPart
                    or (DOJO_TRAINER_POS.Position - HumanoidRootPart.Position).Magnitude <= 50
                    or tick() - waitStart > 30
                Tween(false)
                task.wait(1)
            end

            -- Nhận/kiểm tra quest
            local beltName, progress = RequestPurpleBeltQuest()
            print("[PurpleBelt] Belt hiện tại: " .. tostring(beltName) .. " | Progress: " .. tostring(progress))

            -- ==============================
            -- BƯỚC 5: KIỂM TRA HOÀN THÀNH
            -- ==============================
            if not progress and not beltName then
                -- Không có quest = có thể đã xong → thử claim
                print("[PurpleBelt] Không có quest → Thử ClaimQuest...")
                ClaimDojoQuest()
                task.wait(1)

                -- Kiểm tra lại
                local beltName2, progress2 = RequestPurpleBeltQuest()
                if not progress2 and not beltName2 then
                    -- Vẫn không có quest → có thể đã hoàn thành Purple Belt
                    -- Kiểm tra inventory
                    if HasPurpleBelt() then
                        print("[PurpleBelt] ĐÃ HOÀN THÀNH PURPLE BELT!")
                        WriteCompletedFile()
                        getgenv().PurpleBelt.Running = false
                        _noclipActive = false
                        RemoveBodyClip()
                        Tween(false)
                        return
                    end
                end
            end

            -- Nếu KHÔNG phải Purple → script không xử lý
            if beltName and beltName ~= "Purple" then
                print("[PurpleBelt] Belt hiện tại là: " .. beltName .. " (không phải Purple)")
                StarterGui:SetCore("SendNotification", {
                    Title = "Purple Belt",
                    Text = "Belt hiện tại: " .. beltName .. " - Không phải Purple!",
                    Duration = 5
                })
                -- Vẫn tiếp tục loop để chờ Purple
                task.wait(5)
                return
            end

            -- ==============================
            -- BƯỚC 3: DETECT ELITE PIRATES
            -- ==============================
            if beltName == "Purple" then
                print("[PurpleBelt] Đang ở quest Purple Belt → Farm Elite!")

                -- Nhận quest Elite Hunter
                AcceptEliteQuest()
                task.wait(1)

                local questInfo = GetQuestInfo()

                if questInfo.visible and questInfo.isElite then
                    -- CÓ quest Elite → tìm boss

                    if EliteBossExists() then
                        -- ==============================
                        -- BƯỚC 4: KILL ELITE BOSS
                        -- ==============================
                        print("[PurpleBelt] Tìm thấy Elite Boss! Đang đánh...")
                        _noclipActive = true
                        EnsureBodyClip()

                        -- Tìm và đánh elite boss
                        for _, name in next, ELITE_NAMES do
                            local boss = CheckMonster(name)
                            if boss then
                                -- Loop đánh cho đến khi boss chết
                                repeat
                                    task.wait(0.1)
                                    if not getgenv().PurpleBelt.Running then break end
                                    KillEliteBoss(name)
                                until not boss
                                    or not boss.Parent
                                    or not boss:FindFirstChild("Humanoid")
                                    or boss.Humanoid.Health <= 0

                                Tween(false)
                                _noclipActive = false
                                RemoveBodyClip()
                                print("[PurpleBelt] Elite Boss đã chết! Tiếp tục...")
                                task.wait(2)
                                break
                            end
                        end
                    else
                        -- KHÔNG CÓ Elite Boss ở server này → HOP
                        print("[PurpleBelt] Không có Elite Boss → Hop server...")
                        Tween(false)
                        _noclipActive = false
                        RemoveBodyClip()
                        HopServer("Không tìm thấy Elite Boss")
                        task.wait(getgenv().PurpleBelt.HopWaitTime)
                        return
                    end

                elseif questInfo.visible and not questInfo.isElite then
                    -- Có quest nhưng KHÔNG phải Elite → hop (Banana file 2 logic)
                    print("[PurpleBelt] Có quest khác (không Elite) → Hop server...")
                    HopServer("Quest không phải Elite")
                    task.wait(getgenv().PurpleBelt.HopWaitTime)
                    return

                else
                    -- Không có quest → nhận lại
                    print("[PurpleBelt] Chưa có quest → Nhận quest Elite Hunter...")
                    AcceptEliteQuest()
                    task.wait(2)
                end

                -- Sau khi đánh xong → kiểm tra progress Purple Belt
                local beltCheck, progressCheck = RequestPurpleBeltQuest()
                if not progressCheck and not beltCheck then
                    -- Quest có thể đã xong → claim
                    ClaimDojoQuest()
                    task.wait(1)
                    
                    -- Kiểm tra hoàn thành
                    if HasPurpleBelt() then
                        print("[PurpleBelt] *** HOÀN THÀNH PURPLE BELT! ***")
                        WriteCompletedFile()
                        getgenv().PurpleBelt.Running = false
                        Tween(false)
                        _noclipActive = false
                        RemoveBodyClip()
                        StarterGui:SetCore("SendNotification", {
                            Title = "HOÀN THÀNH!",
                            Text = "Purple Belt đã xong! Đã ghi file.",
                            Duration = 15
                        })
                        return
                    end
                end
            end

        end, function(err)
            warn("[PurpleBelt] Main Loop ERROR:", err)
        end)

        task.wait(0.5) -- throttle chính
    end

    print("[PurpleBelt] Script đã dừng.")
    _noclipActive = false
    RemoveBodyClip()
    Tween(false)
end)

-- ==========================================
-- STATUS MONITOR (hiển thị tiến độ)
-- ==========================================
task.spawn(function()
    while task.wait(10) do
        if not getgenv().PurpleBelt.Running then break end
        xpcall(function()
            local progress = GetEliteProgress()
            local beltName = GetCurrentBeltName()
            local eliteExists = EliteBossExists()
            print(string.format(
                "[PurpleBelt] Belt: %s | Elite Killed: %s | Elite ở server: %s",
                tostring(beltName),
                tostring(progress),
                eliteExists and "CÓ" or "KHÔNG"
            ))
        end, function() end)
    end
end)

-- ==========================================
-- THÔNG BÁO HOÀN THÀNH
-- ==========================================
StarterGui:SetCore("SendNotification", {
    Title = "Purple Belt Farm",
    Text = "Script đã load thành công! Đang chạy...",
    Duration = 5
})

print("[PurpleBelt] Script loaded thành công!")
print("[PurpleBelt] Team: " .. getgenv().PurpleBelt.Team)
print("[PurpleBelt] Weapon: " .. getgenv().PurpleBelt.WeaponType)
print("[PurpleBelt] Để dừng: getgenv().PurpleBelt.Running = false")
