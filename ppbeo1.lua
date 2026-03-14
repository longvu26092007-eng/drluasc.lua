--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║         DOJO PURPLE BELT - AUTO ELITE BOSS FARM + HOP          ║
    ║                     + UI TIẾN TRÌNH                             ║
    ║  Fix: 7s timeout hop + Purple Belt inventory check               ║
    ╚══════════════════════════════════════════════════════════════════╝
--]]

getgenv().PurpleBelt = {
    Running = true,
    Team = "Pirates",
    WeaponType = "Melee",
    HopMaxPlayers = 5,
    AttackRange = 65,
    TweenSpeed = 250,
    AutoBuso = true,
    AutoKen = true,
    HopWaitTime = 8,
}

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local RunService          = game:GetService("RunService")
local TweenService        = game:GetService("TweenService")
local CollectionService   = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService     = game:GetService("TeleportService")
local StarterGui          = game:GetService("StarterGui")
local GuiService          = game:GetService("GuiService")

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
    local old = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild("PurpleBeltUI")
    if old then old:Destroy() end
end)
local UIParent = (gethui and gethui()) or game:GetService("CoreGui")
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "PurpleBeltUI"; ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; ScreenGui.Parent = UIParent

local MainFrame = Instance.new("Frame"); MainFrame.Name = "Main"; MainFrame.Size = UDim2.new(0,320,0,400)
MainFrame.Position = UDim2.new(0,20,0.5,-200); MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,30)
MainFrame.BorderSizePixel = 0; MainFrame.Parent = ScreenGui; MainFrame.Active = true; MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,10)
local st = Instance.new("UIStroke", MainFrame); st.Color = Color3.fromRGB(138,43,226); st.Thickness = 2

local TitleBar = Instance.new("Frame", MainFrame); TitleBar.Size = UDim2.new(1,0,0,36)
TitleBar.BackgroundColor3 = Color3.fromRGB(138,43,226); TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,10)
local TF = Instance.new("Frame", TitleBar); TF.Size = UDim2.new(1,0,0,12); TF.Position = UDim2.new(0,0,1,-12)
TF.BackgroundColor3 = Color3.fromRGB(138,43,226); TF.BorderSizePixel = 0
local TL = Instance.new("TextLabel", TitleBar); TL.Size = UDim2.new(1,-40,1,0); TL.Position = UDim2.new(0,12,0,0)
TL.BackgroundTransparency = 1; TL.Text = "🥋 PURPLE BELT FARM"; TL.TextColor3 = Color3.new(1,1,1)
TL.TextSize = 15; TL.Font = Enum.Font.GothamBold; TL.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TitleBar); MinBtn.Size = UDim2.new(0,28,0,28)
MinBtn.Position = UDim2.new(1,-32,0,4); MinBtn.BackgroundColor3 = Color3.fromRGB(100,30,180)
MinBtn.Text = "−"; MinBtn.TextColor3 = Color3.new(1,1,1); MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold; MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,6)

local CF = Instance.new("Frame", MainFrame); CF.Name = "Content"; CF.Size = UDim2.new(1,-16,1,-44)
CF.Position = UDim2.new(0,8,0,40); CF.BackgroundTransparency = 1
local _min = false
MinBtn.MouseButton1Click:Connect(function()
    _min = not _min; CF.Visible = not _min
    MainFrame.Size = _min and UDim2.new(0,320,0,36) or UDim2.new(0,320,0,400)
    MinBtn.Text = _min and "+" or "−"
end)

local _labels = {}; local _labelY = 0
local function ML(n,t)
    local l = Instance.new("TextLabel", CF); l.Name = n; l.Size = UDim2.new(1,0,0,22)
    l.Position = UDim2.new(0,0,0,_labelY); l.BackgroundTransparency = 1; l.Text = t or ""
    l.TextColor3 = Color3.fromRGB(220,220,240); l.TextSize = 13; l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left; _labelY = _labelY + 24; _labels[n] = l; return l
end
local function MS()
    local s = Instance.new("Frame", CF); s.Size = UDim2.new(1,0,0,1); s.Position = UDim2.new(0,0,0,_labelY)
    s.BackgroundColor3 = Color3.fromRGB(80,50,130); s.BorderSizePixel = 0; _labelY = _labelY + 6
end
local function UL(n,t) if _labels[n] then _labels[n].Text = t end end
local function SLC(n,c) if _labels[n] then _labels[n].TextColor3 = c end end

ML("header","═══ TRẠNG THÁI ═══"); SLC("header",Color3.fromRGB(138,43,226)); MS()
ML("status","⏳ Đang khởi tạo..."); ML("sea","🌊 Sea: ..."); ML("belt","🥋 Belt: ...")
ML("quest","📜 Quest: ..."); ML("elite","👹 Elite Boss: ..."); ML("progress","📊 Elite Killed: ...")
ML("server","🖥️ Server: "..string.sub(JobId,1,20).."..."); ML("weapon","⚔️ Weapon: "..getgenv().PurpleBelt.WeaponType)
ML("team","🏴 Team: "..getgenv().PurpleBelt.Team); MS()
ML("header2","═══ LOG ═══"); SLC("header2",Color3.fromRGB(138,43,226)); MS()
ML("log1",""); ML("log2",""); ML("log3","")

local _logLines = {"","",""}
local function AddLog(msg)
    table.remove(_logLines,1); table.insert(_logLines,"• "..msg)
    UL("log1",_logLines[1]); UL("log2",_logLines[2]); UL("log3",_logLines[3])
    print("[PurpleBelt] "..msg)
end

MS(); _labelY = _labelY + 2; local startY = _labelY
local function MB(text,cb)
    local b = Instance.new("TextButton", CF); b.Size = UDim2.new(0.48,0,0,28); b.Position = UDim2.new(0,0,0,_labelY)
    b.BackgroundColor3 = Color3.fromRGB(138,43,226); b.Text = text; b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 12; b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); b.MouseButton1Click:Connect(cb); return b
end
MB("⏹ DỪNG", function()
    getgenv().PurpleBelt.Running = false; UL("status","⛔ Đã dừng!"); SLC("status",Color3.fromRGB(255,80,80))
    AddLog("Dừng bởi người dùng")
end)
local hb = MB("🔄 HOP NGAY", function() end); hb.Position = UDim2.new(0.52,0,0,startY)
getgenv()._manualHop = false; hb.MouseButton1Click:Connect(function() getgenv()._manualHop = true; AddLog("Hop thủ công...") end)

-- ==========================================
-- LOAD GAME + JOIN TEAM
-- ==========================================
UL("status","⏳ Đang chờ game load...")
if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then task.wait(10 - workspace.DistributedGameTime) end
local COMMF_ = ReplicatedStorage:WaitForChild("Remotes") and ReplicatedStorage.Remotes:WaitForChild("CommF_")
if not COMMF_ then repeat task.wait(1) until COMMF_ end

task.spawn(function() xpcall(function()
    if not LocalPlayer.Team then
        if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then repeat task.wait(1) until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") end
        xpcall(function() COMMF_:InvokeServer("SetTeam", getgenv().PurpleBelt.Team)
        end, function() pcall(function() firesignal(LocalPlayer.PlayerGui["Main (minimal)"].ChooseTeam.Container[getgenv().PurpleBelt.Team]) end) end)
        task.wait(2); AddLog("Join team: "..getgenv().PurpleBelt.Team)
    end
end, function() end) end)

repeat task.wait(2) until Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChildWhichIsA("Humanoid") and Character:IsDescendantOf(workspace.Characters)
UL("status","✅ Game đã load!")

-- ==========================================
-- CORE FUNCTIONS (giữ nguyên từ bản gốc)
-- ==========================================
local function CheckSea(v) local ok,r = pcall(function() return v == tonumber(workspace:GetAttribute("MAP"):match("%d+")) end); return ok and r end

local remoteAttack, idremote, seed
pcall(function() seed = ReplicatedStorage.Modules.Net.seed:InvokeServer() end)
task.spawn(function()
    local folders = {}
    pcall(function() table.insert(folders, ReplicatedStorage.Util) end)
    pcall(function() table.insert(folders, ReplicatedStorage.Common) end)
    pcall(function() table.insert(folders, ReplicatedStorage.Remotes) end)
    pcall(function() table.insert(folders, ReplicatedStorage.Assets) end)
    pcall(function() table.insert(folders, ReplicatedStorage.FX) end)
    for _, v in next, folders do
        for _, n in next, v:GetChildren() do if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end end
        v.ChildAdded:Connect(function(n) if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end end)
    end
end)

-- Anti-detect
LocalPlayer.Idled:Connect(function() local VU = game:GetService("VirtualUser"); VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame); task.wait(); VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)
task.defer(function() pcall(function() if ReplicatedStorage:FindFirstChild("Effect") and ReplicatedStorage.Effect:FindFirstChild("Container") and ReplicatedStorage.Effect.Container:FindFirstChild("Death") then local dm = require(ReplicatedStorage.Effect.Container.Death); local cs = require(ReplicatedStorage.Util.CameraShaker); if cs then cs:Stop() end; if hookfunction then hookfunction(dm, function(...) return ... end) end end end) end)
task.spawn(function() pcall(function() if Character:FindFirstChild("Stun") then Character.Stun.Changed:Connect(function() pcall(function() if Character:FindFirstChild("Stun") then Character.Stun.Value = 0 end end) end) end end) end)

local _noclipActive = false
pcall(function() RunService.Stepped:Connect(function() if _noclipActive and Character then for _, v in pairs(Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end end) end)
local function EnsureBodyClip() if not Character or not HumanoidRootPart then return end; if not HumanoidRootPart:FindFirstChild("BodyClip") then local bv = Instance.new("BodyVelocity"); bv.Name = "BodyClip"; bv.Parent = HumanoidRootPart; bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Velocity = Vector3.zero end end
local function RemoveBodyClip() pcall(function() if HumanoidRootPart and HumanoidRootPart:FindFirstChild("BodyClip") then HumanoidRootPart.BodyClip:Destroy() end end) end

local ELITE_NAMES = {"Diablo", "Deandre", "Urban"}
local function IsEliteName(name) if not name then return false end; for _, n in next, ELITE_NAMES do if name == n or name:find(n) then return true end end; return false end
local function CheckTool(v) for _, x in next, {LocalPlayer.Backpack, Character} do if x then for _, v2 in next, x:GetChildren() do if v2:IsA("Tool") and (v2.Name == v or v2.Name:find(v)) then return true end end end end; return false end
local function CheckInventory(...) local ok, inv = pcall(function() return COMMF_:InvokeServer("getInventory") end); if not ok or not inv then return false end; for _, v in pairs(inv) do for _, n in next, {...} do if v.Name == n then return true end end end; return false end
local function CheckMonster(...) local args = {...}; for _, container in next, {workspace.Enemies, ReplicatedStorage} do for _, m in next, container:GetChildren() do if m:IsA("Model") and m.Name ~= "Blank Buddy" then local h, r = m:FindFirstChild("Humanoid"), m:FindFirstChild("HumanoidRootPart"); if h and r and h.Health > 0 then for _, n in next, args do if m.Name == n or m.Name:lower():find(n:lower()) then return m end end end end end end; return false end
local function EquipWeapon(wt) if not Character then return end; local t = Character:FindFirstChildWhichIsA("Tool"); if t and t.ToolTip == wt then return end; for _, x in next, LocalPlayer.Backpack:GetChildren() do if x:IsA("Tool") and x.ToolTip == wt then Humanoid:EquipTool(x) return end end end
local function EliteBossExists() for _, name in next, ELITE_NAMES do if ReplicatedStorage:FindFirstChild(name) or workspace.Enemies:FindFirstChild(name) then return true end end; return false end
local function FindEliteBossName() for _, name in next, ELITE_NAMES do if workspace.Enemies:FindFirstChild(name) then return name, "Enemies" end; if ReplicatedStorage:FindFirstChild(name) then return name, "Replicated" end end; return nil, nil end

-- FastAttack
local lastCallFA = tick()
local function FastAttack(targetName)
    if not HumanoidRootPart or not Character:FindFirstChildWhichIsA("Humanoid") then return end
    if Character.Humanoid.Health <= 0 or not Character:FindFirstChildWhichIsA("Tool") then return end
    if tick() - lastCallFA <= 0.01 then return end
    local targets = {}
    for _, e in next, workspace.Enemies:GetChildren() do local h, hrp = e:FindFirstChild("Humanoid"), e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and (targetName and e.Name == targetName or not targetName) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= getgenv().PurpleBelt.AttackRange then targets[#targets+1] = e end
    end
    if #targets == 0 then return end
    local n = ReplicatedStorage.Modules.Net; local h = {[2] = {}}
    for i = 1, #targets do local v = targets[i]; local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart"); if not h[1] then h[1] = part end; h[2][#h[2]+1] = {v, part} end
    pcall(function() n:FindFirstChild("RE/RegisterAttack"):FireServer() end)
    pcall(function() n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h)) end)
    pcall(function() if remoteAttack and idremote and seed then cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".", function(c) return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1)) end), bit32.bxor(idremote+909090, seed*2), unpack(h)) end end)
    lastCallFA = tick()
end

-- Tween
local _conn, _tw, _pp, _isTw = nil, nil, nil, false
local function Tween(targetCF, target)
    pcall(function() if Humanoid then Humanoid.Sit = false end end)
    if not Character or not Humanoid or Humanoid.Health <= 0 then pcall(function() workspace:FindFirstChild("TweenGhost"):Destroy() end); _conn, _tw, _pp, _isTw = nil, nil, nil, false; return end
    if targetCF == false then if _tw then pcall(function() _tw:Cancel() end) _tw = nil end; if _conn then _conn:Disconnect() _conn = nil end; if _pp then _pp:Destroy() _pp = nil end; _isTw = false; return end
    if _isTw or not targetCF then return end; _isTw = true
    local root = Character:FindFirstChild("HumanoidRootPart"); if not root then _isTw = false return end
    target = target or root; local dist = (targetCF.Position - target.Position).Magnitude
    local oY = (target ~= root) and CFrame.new(0,30,0) or CFrame.new(0,5,0)
    _pp = Instance.new("Part"); _pp.Name = "TweenGhost"; _pp.Transparency = 1; _pp.Anchored = true; _pp.CanCollide = false; _pp.CFrame = target.CFrame; _pp.Size = Vector3.new(50,50,50); _pp.Parent = workspace
    _tw = TweenService:Create(_pp, TweenInfo.new(dist / getgenv().PurpleBelt.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = targetCF * oY})
    _conn = RunService.Heartbeat:Connect(function() if target and _pp then target.CFrame = _pp.CFrame * oY end end)
    _tw.Completed:Connect(function() if _conn then _conn:Disconnect() _conn = nil end; if _pp then _pp:Destroy() _pp = nil end; _tw = nil; _isTw = false end)
    _tw:Play()
end

-- KillElite
local lastKenCall = tick()
local function KillEliteBoss(bossName)
    xpcall(function()
        for _, v in next, workspace.Enemies:GetChildren() do
            local vh, vhrp = v:FindFirstChild("Humanoid"), v:FindFirstChild("HumanoidRootPart")
            if vh and vh.Health > 0 and vhrp and v.Name == bossName then
                local dx,dy,dz = HumanoidRootPart.Position.X-vhrp.Position.X, HumanoidRootPart.Position.Y-vhrp.Position.Y, HumanoidRootPart.Position.Z-vhrp.Position.Z
                if dx*dx+dy*dy+dz*dz <= (getgenv().PurpleBelt.AttackRange^2) then
                    _noclipActive = true; EnsureBodyClip(); FastAttack(bossName)
                    if getgenv().PurpleBelt.AutoBuso and not Character:FindFirstChild("HasBuso") then pcall(function() COMMF_:InvokeServer("Buso") end) end
                    if getgenv().PurpleBelt.AutoKen and tick()-lastKenCall >= 10 then lastKenCall = tick(); pcall(function() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end) end
                    Tween(CFrame.new(vhrp.Position + vhrp.CFrame.LookVector*20 + Vector3.new(0, vhrp.Position.Y>60 and -20 or 20, 0)))
                    EquipWeapon(getgenv().PurpleBelt.WeaponType); return true
                end
                Tween(vhrp.CFrame); return true
            end
        end
        for _, v in next, ReplicatedStorage:GetChildren() do local vhrp = v:FindFirstChild("HumanoidRootPart"); if v:IsA("Model") and vhrp and v.Name == bossName then Tween(vhrp.CFrame) return true end end
        return false
    end, function(e) warn("[PurpleBelt] Kill ERROR:", e) end)
end

-- HopServer
local LastPull, CachedSrv
local function GetServers() if LastPull and os.time()-LastPull < 60 then return CachedSrv end; for i = 1, 100 do local ok, data = pcall(function() return ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer(i) end); if ok and data then local h = false; for _ in data do h = true break end; if h then LastPull = os.time(); CachedSrv = data; return data end end end; return nil end
local function HopServer(reason)
    AddLog("Hop: "..tostring(reason)); UL("status","🔄 Đang hop server...")
    local Servers = GetServers(); if not Servers then AddLog("Không lấy được server list") return false end
    local arr = {}; for jid, v in Servers do arr[#arr+1] = {JobId=jid, Players=v.Count, Region=v.Region} end
    for _ = 1, math.min(#arr, 20) do local sd = arr[math.random(1,#arr)]
        if sd and sd.Players < getgenv().PurpleBelt.HopMaxPlayers then
            AddLog("→ "..string.sub(sd.JobId,1,16).." ("..sd.Players.."p)")
            pcall(function() ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer("teleport", sd.JobId) end)
            task.wait(10) return true
        end
    end; AddLog("Không tìm server phù hợp") return false
end

-- Belt detection
local DOJO_POS = CFrame.new(5865.0234375, 1208.3154296875, 871.15185546875)
local HYDRA_ENTRANCE = Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906)
local function TeleportToHydra() pcall(function() COMMF_:InvokeServer("requestEntrance", HYDRA_ENTRANCE) end) end

-- Kiểm tra đang đứng gần Dojo Trainer (Banana style: Magnitude <= 50)
local function IsNearDojo()
    if not HumanoidRootPart then return false end
    return (DOJO_POS.Position - HumanoidRootPart.Position).Magnitude <= 50
end

-- Bay đến Dojo Trainer và chờ đến nơi (timeout 30s)
local function EnsureNearDojo()
    if IsNearDojo() then return true end
    TeleportToHydra(); task.wait(1)
    UL("status","✈️ Bay đến Dojo Trainer..."); Tween(DOJO_POS)
    local t0 = tick()
    repeat task.wait(0.5) until not HumanoidRootPart or IsNearDojo() or tick()-t0 > 30
    Tween(false); task.wait(0.5)
    return IsNearDojo()
end

-- CHỈ gọi RequestQuest khi đứng cạnh NPC (theo Banana file 2)
local function GetCurrentBeltName()
    if not IsNearDojo() then
        if not EnsureNearDojo() then return nil, nil end
    end
    local ok, progress = pcall(function() local args = {[1] = {["NPC"]="Dojo Trainer",["Command"]="RequestQuest"}}; return ReplicatedStorage.Modules.Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args)) end)
    if ok and type(progress)=="table" and progress.Quest and progress.Quest["BeltName"] then return progress.Quest["BeltName"], progress end
    return nil, progress
end

-- CHỈ gọi ClaimQuest khi đứng cạnh NPC (theo Banana file 2: dòng 5812-5815)
local function ClaimDojoQuest()
    if not IsNearDojo() then
        if not EnsureNearDojo() then AddLog("Không đến được Dojo → skip claim") return end
    end
    AddLog("Đứng cạnh Dojo → Claim quest")
    pcall(function() local args = {[1] = {["NPC"]="Dojo Trainer",["Command"]="ClaimQuest"}}; ReplicatedStorage.Modules.Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args)) end)
end

-- Nhận quest Elite Hunter (gọi cạnh Dojo luôn vì đang ở đó)
local function AcceptEliteQuestAtDojo()
    if not IsNearDojo() then
        if not EnsureNearDojo() then AddLog("Không đến được Dojo → skip Elite quest") return end
    end
    AddLog("Đứng cạnh Dojo → Nhận quest Elite")
    task.spawn(function() pcall(function() COMMF_:InvokeServer("EliteHunter") end) end)
end

local function HasPurpleBelt() return CheckInventory("Purple Belt") or CheckInventory("Dojo Belt (Purple)") end

local function GetQuestInfo()
    local ok, r = pcall(function() local q = LocalPlayer.PlayerGui.Main.Quest; if q.Visible then local t = q.Container.QuestTitle.Title.Text; return {visible=true, text=t, isElite=IsEliteName(t)} end; return {visible=false, text="", isElite=false} end)
    return ok and r or {visible=false, text="", isElite=false}
end
local function GetEliteProgress() local ok, p = pcall(function() return COMMF_:InvokeServer("EliteHunter", "Progress") end); return ok and p or 0 end

-- File
local function WriteCompletedFile(content)
    content = content or "Completed-ppbelt"
    pcall(function() if writefile then writefile(LocalPlayer.Name..".txt", content); AddLog("GHI FILE: "..LocalPlayer.Name..".txt → "..content) end end)
end
local function AlreadyCompleted()
    local ok, c = pcall(function() if readfile and isfile and isfile(LocalPlayer.Name..".txt") then return readfile(LocalPlayer.Name..".txt") end; return nil end)
    return ok and c == "Completed-ppbelt"
end

-- Auto Buso
task.spawn(function() while task.wait(4) do xpcall(function()
    if not getgenv().PurpleBelt.Running or not Character or not Humanoid or Humanoid.Health <= 0 then return end
    if not Character:FindFirstChild("HasBuso") then pcall(function() COMMF_:InvokeServer("Buso") end) end
    for _, v in next, {"Buso","Geppo","Soru"} do if not CollectionService:HasTag(Character, v) then local cost = v=="Geppo" and 1e4 or v=="Buso" and 2.5e4 or v=="Soru" and 1e5 or 0; if LocalPlayer.Data.Beli.Value >= cost then pcall(function() COMMF_:InvokeServer("BuyHaki", v) end) end end end
end, function() end) end end)

-- Anti-disconnect
TeleportService.TeleportInitFailed:Connect(function(_, teleportResult, message) if teleportResult == Enum.TeleportResult.IsTeleporting and message:find("previous teleport") then task.delay(10, function() game:Shutdown() end) end end)
GuiService.ErrorMessageChanged:Connect(newcclosure(function() if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then while true do TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer) task.wait(5) end end end))

-- ==========================================
-- ========== MAIN LOOP ===================
-- ==========================================
if AlreadyCompleted() then
    UL("status","✅ Đã hoàn thành từ trước!"); SLC("status",Color3.fromRGB(80,255,80))
    AddLog("File Completed-ppbelt đã tồn tại. Dừng."); return
end

-- Hàm dừng toàn bộ khi đã có Purple Belt
local function FinishPurpleBelt()
    UL("status","🎉 ĐÃ CÓ PURPLE BELT TRONG INVENTORY!")
    SLC("status", Color3.fromRGB(80, 255, 80))
    AddLog("*** Tìm thấy Dojo Belt (Purple) → HOÀN THÀNH! ***")
    WriteCompletedFile("Completed-ppbelt")
    getgenv().PurpleBelt.Running = false
    _noclipActive = false; RemoveBodyClip(); Tween(false)
end

task.spawn(function()
    task.wait(getgenv().PurpleBelt.HopWaitTime)

    while getgenv().PurpleBelt.Running do
        xpcall(function()
            -- ĐẦU MỖI LOOP: check Purple Belt trong inventory
            if HasPurpleBelt() then FinishPurpleBelt(); return end

            if getgenv()._manualHop then getgenv()._manualHop = false; HopServer("Hop thủ công"); task.wait(getgenv().PurpleBelt.HopWaitTime); return end

            local isSea3 = CheckSea(3)
            UL("sea","🌊 Sea: "..(isSea3 and "3 ✅" or "❌"))
            if not isSea3 then UL("status","🌊 Teleport Sea 3..."); AddLog("→ Sea 3"); pcall(function() COMMF_:InvokeServer("TravelZou") end); task.wait(5); return end

            TeleportToHydra(); task.wait(1)

            if not EnsureNearDojo() then
                AddLog("Không bay được đến Dojo, thử lại..."); task.wait(3); return
            end

            -- Check inventory lần nữa sau khi đến Dojo
            if HasPurpleBelt() then FinishPurpleBelt(); return end

            local beltName, progress = GetCurrentBeltName()
            UL("belt","🥋 Belt: "..(beltName or "N/A")); UL("progress","📊 Elite Killed: "..tostring(GetEliteProgress()))

            -- Quest xong → claim (đang đứng cạnh Dojo)
            if not progress and not beltName then
                UL("status","🔍 Đứng cạnh Dojo → Claim quest...")
                ClaimDojoQuest(); task.wait(1)
                -- Sau claim check inventory
                if HasPurpleBelt() then FinishPurpleBelt(); return end
                local bn2 = GetCurrentBeltName()
                if not bn2 then
                    AddLog("Claim xong, không có quest mới → check inventory lần nữa")
                    task.wait(2)
                    if HasPurpleBelt() then FinishPurpleBelt(); return end
                end
            end

            -- Sai belt (không phải Purple)
            if beltName and beltName ~= "Purple" then
                UL("status","⚠️ Belt: "..beltName.." (không phải Purple)"); AddLog("Belt: "..beltName)
                -- Vẫn check inventory phòng trường hợp đã có từ trước
                if HasPurpleBelt() then FinishPurpleBelt(); return end
                task.wait(5); return
            end

            -- =============================================
            -- === PURPLE BELT + 7S TIMEOUT ===
            -- =============================================
            if beltName == "Purple" then
                UL("status","🟣 Purple Belt → Nhận quest Elite...")

                -- Đứng cạnh Dojo → Claim quest cũ + Nhận quest Elite
                ClaimDojoQuest()
                task.wait(0.5)
                AcceptEliteQuestAtDojo()

                -- Chờ tối đa 7 giây
                local gotEliteQuest = false
                local waitStart = tick()

                repeat
                    task.wait(0.5)
                    local elapsed = math.floor(tick() - waitStart)
                    UL("quest","📜 Chờ quest Elite ("..elapsed.."/7s)...")

                    local qi = GetQuestInfo()
                    if qi.visible and qi.isElite then
                        gotEliteQuest = true
                        break
                    end
                    if qi.visible and not qi.isElite then
                        AddLog("Quest khác (không Elite) → Hop")
                        break
                    end
                until tick() - waitStart >= 7

                local qi = GetQuestInfo()
                UL("quest","📜 Quest: "..(qi.visible and qi.text or "Không có"))

                if not gotEliteQuest then
                    UL("status","🔄 7s timeout → Hop")
                    UL("elite","👹 Elite Boss: KHÔNG CÓ ❌")
                    AddLog("7s không có quest Elite → Hop")
                    Tween(false); _noclipActive = false; RemoveBodyClip()
                    HopServer("7s timeout - không có Elite")
                    task.wait(getgenv().PurpleBelt.HopWaitTime)
                    return
                end

                -- CÓ quest Elite → tìm boss
                local eName, eLoc = FindEliteBossName()
                UL("elite","👹 Elite: "..(eName or "?").." ["..(eLoc or "?").."]")

                if eName then
                    UL("status","⚔️ Đánh: "..eName); SLC("status",Color3.fromRGB(255,200,50))
                    AddLog("Đánh Elite: "..eName)
                    _noclipActive = true; EnsureBodyClip()

                    local boss = CheckMonster(eName)
                    if boss then
                        repeat task.wait(0.1)
                            if not getgenv().PurpleBelt.Running then break end
                            KillEliteBoss(eName)
                            pcall(function() if boss and boss:FindFirstChild("Humanoid") then
                                UL("elite","👹 "..eName.." HP: "..math.floor(boss.Humanoid.Health/boss.Humanoid.MaxHealth*100).."%")
                            end end)
                        until not boss or not boss.Parent or not boss:FindFirstChild("Humanoid") or boss.Humanoid.Health <= 0
                    end

                    Tween(false); _noclipActive = false; RemoveBodyClip()
                    AddLog(eName.." đã chết!"); UL("elite","👹 "..eName.." ĐÃ CHẾT ✅")
                    task.wait(2)

                    -- Sau khi đánh xong → check inventory
                    if HasPurpleBelt() then FinishPurpleBelt(); return end

                    -- Bay về Dojo claim
                    AddLog("Đánh xong → Bay về Dojo claim...")
                    if EnsureNearDojo() then
                        ClaimDojoQuest(); task.wait(1)
                        if HasPurpleBelt() then FinishPurpleBelt(); return end
                    end
                else
                    UL("status","🔄 Boss không thấy → Hop")
                    AddLog("Boss không spawn → Hop")
                    Tween(false); _noclipActive = false; RemoveBodyClip()
                    HopServer("Boss không spawn"); task.wait(getgenv().PurpleBelt.HopWaitTime); return
                end
            end

        end, function(err) warn("[PurpleBelt] ERROR:", err); AddLog("Lỗi: "..string.sub(tostring(err),1,50)) end)
        task.wait(0.5)
    end

    UL("status","⛔ Script đã dừng"); _noclipActive = false; RemoveBodyClip(); Tween(false)
end)

-- UI update
task.spawn(function() while task.wait(8) do if not getgenv().PurpleBelt.Running then break end
    xpcall(function() UL("server","🖥️ "..string.sub(JobId,1,24).."..."); UL("weapon","⚔️ "..getgenv().PurpleBelt.WeaponType); UL("progress","📊 Elite Killed: "..tostring(GetEliteProgress())) end, function() end)
end end)

AddLog("Script loaded!")
