--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║       PREHISTORIC ISLAND DETECTOR + AUTO HOP                    ║
    ║                                                                  ║
    ║  Chức năng:                                                      ║
    ║  • Detect đảo Prehistoric Island (2 cách Banana)                ║
    ║  • Detect trạng thái trial (chưa kích / đang kích / xong)      ║
    ║  • Đếm số player khác trên đảo                                  ║
    ║  • Sau khi trial xong → nếu có người khác → hop __ServerBrowser║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

-- ══ 1. ĐỢI GAME LOAD ══
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")

-- ══ 2. JOIN TEAM ══
do
    local _plr = game.Players.LocalPlayer
    local _vim = game:GetService("VirtualInputManager")
    local _team = getgenv().Team or "Pirates"
    if _plr.Team == nil then
        repeat task.wait()
            for _, v in pairs(_plr.PlayerGui:GetChildren()) do
                if string.find(v.Name, "Main") then
                    pcall(function()
                        local btn = v.ChooseTeam.Container[_team].Frame.TextButton
                        btn.Size = UDim2.new(0,10000,0,10000)
                        btn.Position = UDim2.new(-4,0,-5,0)
                        btn.BackgroundTransparency = 1
                        task.wait(0.5)
                        _vim:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.05)
                        _vim:SendMouseButtonEvent(0,0,0,false,game,1); task.wait(0.05)
                    end)
                end
            end
        until _plr.Team ~= nil and game:IsLoaded()
        task.wait(2)
    end
end

-- ══ 3. ĐỢI CHARACTER ══
repeat task.wait() until game.Players.LocalPlayer.Character
    and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

getgenv().PreDetect = {
    Running = true,
    HopMaxPlayers = 5,       -- Max player server khi hop
    HopWaitTime = 8,         -- Chờ trước khi hop
    IslandRange = 800,       -- Phạm vi detect player trên đảo (studs)
    CheckInterval = 2,       -- Giây giữa mỗi lần check
    HopIfOthersOnIsland = true, -- Tự hop nếu có người khác sau trial xong
}

-- ==========================================
-- SERVICES
-- ==========================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TeleportService   = game:GetService("TeleportService")
local GuiService        = game:GetService("GuiService")

local PlaceId, JobId = game.PlaceId, game.JobId
local LocalPlayer = Players.LocalPlayer
local Character, Humanoid, HumanoidRootPart

local function RefreshCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(RefreshCharacter)
if LocalPlayer.Character then RefreshCharacter(LocalPlayer.Character) end

-- ==========================================
-- UI
-- ==========================================
pcall(function()
    local old = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("PreDetectUI")
    if old then old:Destroy() end
end)
local UIParent = (gethui and gethui()) or game:GetService("CoreGui")
local SG = Instance.new("ScreenGui"); SG.Name = "PreDetectUI"; SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; SG.Parent = UIParent

local MF = Instance.new("Frame"); MF.Name = "Main"; MF.Size = UDim2.new(0, 300, 0, 310)
MF.Position = UDim2.new(1, -320, 0, 20); MF.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MF.BorderSizePixel = 0; MF.Parent = SG; MF.Active = true; MF.Draggable = true
Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 10)
local stk = Instance.new("UIStroke", MF); stk.Color = Color3.fromRGB(255, 120, 0); stk.Thickness = 2

local TB = Instance.new("Frame", MF); TB.Size = UDim2.new(1, 0, 0, 32)
TB.BackgroundColor3 = Color3.fromRGB(255, 120, 0); TB.BorderSizePixel = 0
Instance.new("UICorner", TB).CornerRadius = UDim.new(0, 10)
local TBF = Instance.new("Frame", TB); TBF.Size = UDim2.new(1, 0, 0, 10)
TBF.Position = UDim2.new(0, 0, 1, -10); TBF.BackgroundColor3 = Color3.fromRGB(255, 120, 0); TBF.BorderSizePixel = 0
local TL = Instance.new("TextLabel", TB); TL.Size = UDim2.new(1, -40, 1, 0); TL.Position = UDim2.new(0, 10, 0, 0)
TL.BackgroundTransparency = 1; TL.Text = "🌋 PRE ISLAND DETECTOR"
TL.TextColor3 = Color3.new(1, 1, 1); TL.TextSize = 14; TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TB); MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -30, 0, 3); MinBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 0)
MinBtn.Text = "−"; MinBtn.TextColor3 = Color3.new(1, 1, 1); MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold; MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local CF = Instance.new("Frame", MF); CF.Name = "Content"; CF.Size = UDim2.new(1, -12, 1, -40)
CF.Position = UDim2.new(0, 6, 0, 36); CF.BackgroundTransparency = 1
local _min = false
MinBtn.MouseButton1Click:Connect(function()
    _min = not _min; CF.Visible = not _min
    MF.Size = _min and UDim2.new(0, 300, 0, 32) or UDim2.new(0, 300, 0, 310)
    MinBtn.Text = _min and "+" or "−"
end)

local _labels = {}; local _lY = 0
local function ML(n, t)
    local l = Instance.new("TextLabel", CF); l.Name = n; l.Size = UDim2.new(1, 0, 0, 20)
    l.Position = UDim2.new(0, 0, 0, _lY); l.BackgroundTransparency = 1; l.Text = t or ""
    l.TextColor3 = Color3.fromRGB(220, 220, 240); l.TextSize = 13; l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left; _lY = _lY + 22; _labels[n] = l; return l
end
local function MS()
    local s = Instance.new("Frame", CF); s.Size = UDim2.new(1, 0, 0, 1); s.Position = UDim2.new(0, 0, 0, _lY)
    s.BackgroundColor3 = Color3.fromRGB(200, 100, 0); s.BorderSizePixel = 0; _lY = _lY + 5
end
local function UL(n, t) if _labels[n] then _labels[n].Text = t end end
local function SLC(n, c) if _labels[n] then _labels[n].TextColor3 = c end end

ML("header", "═══ ĐẢO PRE ═══"); SLC("header", Color3.fromRGB(255, 120, 0)); MS()
ML("island",   "🌋 Đảo: ...")
ML("trial",    "⚡ Trial: ...")
ML("golem",    "👹 Golem: ...")
ML("bones",    "🦴 Bones: ...")
ML("eggs",     "🥚 Eggs: ...")
MS()
ML("header2", "═══ PLAYERS ═══"); SLC("header2", Color3.fromRGB(255, 120, 0)); MS()
ML("players",  "👥 Người trên đảo: ...")
ML("names",    "📋 Tên: ...")
ML("action",   "🎯 Hành động: Đang chờ...")
ML("server",   "🖥️ Server: " .. string.sub(JobId, 1, 20) .. "...")

-- ==========================================
-- CHỜ GAME LOAD
-- ==========================================
UL("action", "🎯 Đang chờ game load...")
if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
    task.wait(10 - workspace.DistributedGameTime)
end
repeat task.wait(2) until Character and Character:FindFirstChild("HumanoidRootPart")
UL("action", "🎯 Game đã load!")

-- ==========================================
-- DETECT FUNCTIONS (Banana file 2 style)
-- ==========================================

local function IsIslandSpawned()
    local ok, r = pcall(function()
        return workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island") ~= nil
    end)
    return ok and r
end

local function IsIslandLoaded()
    local ok, r = pcall(function()
        return workspace.Map:FindFirstChild("PrehistoricIsland") ~= nil
    end)
    return ok and r
end

local function GetIslandPosition()
    local ok, pos = pcall(function()
        local loc = workspace._WorldOrigin.Locations:FindFirstChild("Prehistoric Island")
        if loc then return loc.CFrame.Position end
        local island = workspace.Map:FindFirstChild("PrehistoricIsland")
        if island and island:FindFirstChild("Core") then
            return island.Core.CFrame and island.Core.CFrame.Position or island:GetPivot().Position
        end
        return nil
    end)
    return ok and pos or nil
end

local function GetTrialState()
    if not IsIslandLoaded() then return "no_island" end
    local ok, state = pcall(function()
        local island = workspace.Map.PrehistoricIsland
        if not island:FindFirstChild("Core") then return "no_core" end
        local core = island.Core
        if core:FindFirstChild("ActivationPrompt") then
            if core.ActivationPrompt:FindFirstChild("ProximityPrompt", true) then
                return "not_activated"
            end
        end
        local golemAlive = false
        for _, e in pairs(workspace.Enemies:GetChildren()) do
            if e.Name == "Lava Golem" and e:FindFirstChild("Humanoid") and e.Humanoid.Health > 0 then
                golemAlive = true; break
            end
        end
        if golemAlive then return "fighting_golem" end
        local rocksGlowing = false
        if core:FindFirstChild("VolcanoRocks") then
            for _, rock in pairs(core.VolcanoRocks:GetChildren()) do
                if rock:FindFirstChild("VFXLayer") then
                    local ok2, glow = pcall(function() return rock.VFXLayer.At0.Glow.Enabled end)
                    if ok2 and glow then rocksGlowing = true; break end
                end
            end
        end
        if rocksGlowing then return "fixing_volcano" end
        local hasEggs = false
        if core:FindFirstChild("SpawnedDragonEggs") then
            hasEggs = #core.SpawnedDragonEggs:GetChildren() > 0
        end
        local hasBones = false
        for _, v in pairs(workspace:GetChildren()) do
            if v.Name == "DinoBone" then hasBones = true; break end
        end
        if hasEggs or hasBones then return "completed_loot" end
        return "completed_empty"
    end)
    return ok and state or "error"
end

local function GetPlayersOnIsland()
    local islandPos = GetIslandPosition()
    if not islandPos then return {}, 0 end
    local myName = LocalPlayer.Name
    local range = getgenv().PreDetect.IslandRange
    local playersOnIsland = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name ~= myName and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if (hrp.Position - islandPos).Magnitude <= range then
                    table.insert(playersOnIsland, player.Name)
                end
            end
        end
    end
    return playersOnIsland, #playersOnIsland
end

local function CountBones()
    local count = 0
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "DinoBone" then count = count + 1 end
    end
    return count
end

local function CountEggs()
    local ok, count = pcall(function()
        local island = workspace.Map:FindFirstChild("PrehistoricIsland")
        if island and island:FindFirstChild("Core") and island.Core:FindFirstChild("SpawnedDragonEggs") then
            return #island.Core.SpawnedDragonEggs:GetChildren()
        end
        return 0
    end)
    return ok and count or 0
end

local function IsGolemAlive()
    for _, e in pairs(workspace.Enemies:GetChildren()) do
        if e.Name == "Lava Golem" and e:FindFirstChild("Humanoid") and e.Humanoid.Health > 0 then
            return true, e.Humanoid.Health, e.Humanoid.MaxHealth
        end
    end
    return false, 0, 0
end

-- ==========================================
-- HOP SERVER (__ServerBrowser KaitunBoss)
-- ==========================================
local LastPull, CachedSrv
local function GetServers()
    if LastPull and os.time() - LastPull < 60 then return CachedSrv end
    for i = 1, 100 do
        local ok, data = pcall(function()
            return ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer(i)
        end)
        if ok and data then
            local h = false; for _ in data do h = true; break end
            if h then LastPull = os.time(); CachedSrv = data; return data end
        end
    end
    return nil
end

local function HopServer(reason)
    UL("action", "🔄 Hop: " .. tostring(reason))
    local Servers = GetServers()
    if not Servers then UL("action", "❌ Không lấy được server list"); return false end
    local arr = {}
    for jid, v in Servers do
        arr[#arr + 1] = {JobId = jid, Players = v.Count, Region = v.Region}
    end
    for _ = 1, math.min(#arr, 20) do
        local sd = arr[math.random(1, #arr)]
        if sd and sd.Players < getgenv().PreDetect.HopMaxPlayers then
            UL("action", "🔄 → " .. string.sub(sd.JobId, 1, 16) .. " (" .. sd.Players .. "p)")
            pcall(function()
                ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer("teleport", sd.JobId)
            end)
            task.wait(10)
            return true
        end
    end
    UL("action", "❌ Không tìm server phù hợp")
    return false
end

-- ==========================================
-- ANTI-AFK + ANTI-DISCONNECT
-- ==========================================
LocalPlayer.Idled:Connect(function()
    local VU = game:GetService("VirtualUser")
    VU:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait()
    VU:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

TeleportService.TeleportInitFailed:Connect(function(_, teleportResult, message)
    if teleportResult == Enum.TeleportResult.IsTeleporting and message:find("previous teleport") then
        task.delay(10, function() game:Shutdown() end)
    end
end)
GuiService.ErrorMessageChanged:Connect(newcclosure(function()
    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
        while true do TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer) task.wait(5) end
    end
end))

-- ==========================================
-- TRIAL STATE → TIẾNG VIỆT
-- ==========================================
local STATE_TEXT = {
    no_island        = "❌ Không có đảo",
    no_core          = "⚠️ Đảo có nhưng chưa load Core",
    not_activated     = "🔴 Chưa kích hoạt (cần nhấn E)",
    fighting_golem   = "⚔️ Đang đánh Golem",
    fixing_volcano   = "🔧 Đang sửa núi lửa (đập đá)",
    completed_loot   = "✅ XONG! Có Eggs/Bones",
    completed_empty  = "✅ XONG! (hết loot)",
    error            = "⚠️ Lỗi detect",
}

-- ==========================================
-- MAIN DETECT LOOP
-- ==========================================
task.spawn(function()
    task.wait(3)

    while getgenv().PreDetect.Running do
        xpcall(function()
            local spawned = IsIslandSpawned()
            local loaded = IsIslandLoaded()

            if spawned or loaded then
                UL("island", "🌋 Đảo: ✅ CÓ" .. (loaded and " (loaded)" or " (spawned)"))
                SLC("island", Color3.fromRGB(80, 255, 80))
            else
                UL("island", "🌋 Đảo: ❌ KHÔNG CÓ")
                SLC("island", Color3.fromRGB(255, 80, 80))
                UL("trial", "⚡ Trial: —")
                UL("golem", "👹 Golem: —")
                UL("bones", "🦴 Bones: 0")
                UL("eggs", "🥚 Eggs: 0")
                UL("players", "👥 Người trên đảo: —")
                UL("names", "📋 Tên: —")
                UL("action", "🎯 Chờ đảo xuất hiện...")
                task.wait(getgenv().PreDetect.CheckInterval)
                return
            end

            local state = GetTrialState()
            UL("trial", "⚡ Trial: " .. (STATE_TEXT[state] or state))

            local golemAlive, golemHP, golemMax = IsGolemAlive()
            if golemAlive then
                local pct = golemMax > 0 and math.floor(golemHP / golemMax * 100) or 0
                UL("golem", "👹 Golem: SỐNG (" .. pct .. "% HP)")
                SLC("golem", Color3.fromRGB(255, 200, 50))
            else
                UL("golem", "👹 Golem: Không có")
                SLC("golem", Color3.fromRGB(220, 220, 240))
            end

            local boneCount = CountBones()
            local eggCount = CountEggs()
            UL("bones", "🦴 Bones: " .. boneCount)
            UL("eggs", "🥚 Eggs: " .. eggCount)
            if boneCount > 0 then SLC("bones", Color3.fromRGB(80, 255, 80)) else SLC("bones", Color3.fromRGB(220, 220, 240)) end
            if eggCount > 0 then SLC("eggs", Color3.fromRGB(80, 255, 80)) else SLC("eggs", Color3.fromRGB(220, 220, 240)) end

            local playerNames, playerCount = GetPlayersOnIsland()
            UL("players", "👥 Người trên đảo: " .. playerCount .. " (ngoài mình)")

            if playerCount > 0 then
                local nameStr = table.concat(playerNames, ", ")
                if #nameStr > 40 then nameStr = string.sub(nameStr, 1, 37) .. "..." end
                UL("names", "📋 Tên: " .. nameStr)
                SLC("players", Color3.fromRGB(255, 80, 80))
                SLC("names", Color3.fromRGB(255, 150, 150))
            else
                UL("names", "📋 Tên: Không ai")
                SLC("players", Color3.fromRGB(80, 255, 80))
                SLC("names", Color3.fromRGB(220, 220, 240))
            end

            if state == "completed_loot" or state == "completed_empty" then
                if playerCount > 0 and getgenv().PreDetect.HopIfOthersOnIsland then
                    UL("action", "🔄 Trial xong + " .. playerCount .. " người khác → HOP!")
                    SLC("action", Color3.fromRGB(255, 200, 50))
                    task.wait(2)
                    HopServer("Trial xong, " .. playerCount .. " người trên đảo")
                    task.wait(getgenv().PreDetect.HopWaitTime)
                    return
                else
                    UL("action", "✅ Trial xong, an toàn (0 người khác)")
                    SLC("action", Color3.fromRGB(80, 255, 80))
                end
            elseif state == "not_activated" then
                if playerCount > 0 then
                    UL("action", "⚠️ Chưa kích hoạt, " .. playerCount .. " người trên đảo")
                    SLC("action", Color3.fromRGB(255, 200, 50))
                else
                    UL("action", "🔴 Chưa kích hoạt, 0 người khác")
                    SLC("action", Color3.fromRGB(220, 220, 240))
                end
            elseif state == "fighting_golem" or state == "fixing_volcano" then
                UL("action", "⏳ Đang làm trial... (" .. playerCount .. " người)")
                SLC("action", Color3.fromRGB(255, 200, 50))
            else
                UL("action", "🎯 Đang theo dõi...")
                SLC("action", Color3.fromRGB(220, 220, 240))
            end

        end, function(err)
            warn("[PreDetect] ERROR:", err)
            UL("action", "⚠️ Lỗi: " .. string.sub(tostring(err), 1, 40))
        end)

        task.wait(getgenv().PreDetect.CheckInterval)
    end

    UL("action", "⛔ Đã dừng"); SLC("action", Color3.fromRGB(255, 80, 80))
end)

task.spawn(function()
    while task.wait(10) do
        if not getgenv().PreDetect.Running then break end
        UL("server", "🖥️ Server: " .. string.sub(JobId, 1, 20) .. "...")
    end
end)

print("[PreDetect] Loaded! Dừng: getgenv().PreDetect.Running = false")
