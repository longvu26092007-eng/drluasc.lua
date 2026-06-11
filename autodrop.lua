--========================================================
--  AUTO DROP - Blox Fruits
--  Giai đoạn 1: Wait load -> Config + Choose Team -> UI (SlotPlayer + Status)
--========================================================

--// 1. Đợi game load: cần đủ cả 3 (game loaded + LocalPlayer + PlayerGui)
--//    để chắc chắn dựng UI / gọi remote không lỗi.
repeat task.wait(0.25)
until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

--// 2. CONFIG: chọn team qua getgenv().team = "Pirates" / "Marines"
--//    Không set -> mặc định "Marines"
local TEAM do
    local t = tostring(getgenv().team or "Marines"):lower()
    if t == "pirates" or t == "pirate" then
        TEAM = "Pirates"
    else
        TEAM = "Marines"
    end
end

--// Tổng số acc cần đủ để đánh slot ; bỏ trống = 10
local TOTAL  = tonumber(getgenv().total) or 10
--// Bán kính quét player gần (studs) ; bỏ trống = 100
local RADIUS = tonumber(getgenv().radius) or 100

--// Biến slot dùng chung toàn script (luôn cập nhật theo danh sách "sống")
local MY_SLOT   = nil   -- slot hiện tại của mình (số), nil nếu chưa có
local SLOT_LIST = {}    -- danh sách player cùng team đang gần, sort theo UserId

--// cloneref an toàn (fallback nếu executor không có)
getgenv().cloneref = cloneref or clonereference or function(x) return x end

--// Services (lazy-load qua metatable)
local Services = setmetatable({}, {__index = function(self, name)
    local ok, svc = pcall(function() return cloneref(game:GetService(name)) end)
    if ok then rawset(self, name, svc) return svc end
    error("Invalid Roblox Service: " .. tostring(name))
end})

local ReplicatedStorage = Services.ReplicatedStorage
local Players           = Services.Players
local StarterGui        = Services.StarterGui
local TweenService      = Services.TweenService
local RunService        = Services.RunService

local LocalPlayer = Players.LocalPlayer
local COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--// Character (luôn cập nhật mới nhất)
local Character, Humanoid, HumanoidRootPart
local function SetupCharacter(char)
    Character        = char
    Humanoid         = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(SetupCharacter)
if LocalPlayer.Character then SetupCharacter(LocalPlayer.Character) end

--// Toạ độ + tốc độ bay
local SPEED    = 220
local DOJO_POS = CFrame.new(5862.036621, 1208.302124, 872.385437)

--// Điểm drop/nhặt chung của cả ring (mặc định lấy EXTRA_POS của script gốc)
--// có thể override: getgenv().dropPos = {x,y,z}
local DROP_POS = CFrame.new(5801.733887, 1208.568481, 877.088684)
do
    local dp = getgenv().dropPos
    if type(dp) == "table" and #dp == 3 then
        DROP_POS = CFrame.new(dp[1], dp[2], dp[3])
    end
end

--// Thời gian mỗi khe lượt (giây) ; bỏ trống = 7. Mỗi slot có 1 khe để bay+nhặt+drop.
local SLOT_TIME = tonumber(getgenv().slotTime) or 7

--// Bay (tween) tới toạ độ, gọi onDone khi tới nơi
local function toposition(Pos, onDone)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")

    local root = char:FindFirstChild("Root")
    if not root then
        root = Instance.new("Part")
        root.Size = Vector3.new(20, 0.5, 20)
        root.Name = "Root"
        root.Anchored = true
        root.Transparency = 1
        root.CanCollide = false
        root.CFrame = hrp.CFrame * CFrame.new(0, 0.6, 0)
        root.Parent = char
    end

    if hum and hum.Sit then hum.Sit = false end

    local distance = (Pos.Position - hrp.Position).Magnitude
    if distance <= 10 then
        root.CFrame = Pos
        hrp.CFrame  = Pos
        if typeof(onDone) == "function" then onDone() end
        return
    end

    local info = TweenInfo.new(math.max(distance / SPEED, 0.05), Enum.EasingStyle.Linear)
    local tweenObj = TweenService:Create(root, info, { CFrame = Pos })
    tweenObj:Play()

    local running = true
    task.spawn(function()
        while running and tweenObj.PlaybackState == Enum.PlaybackState.Playing do
            task.wait()
            pcall(function()
                hrp.CFrame = root.CFrame
                if (root.Position - hrp.Position).Magnitude >= 1 then
                    root.CFrame = hrp.CFrame
                end
            end)
        end
    end)

    tweenObj.Completed:Connect(function()
        running = false
        pcall(function() hrp.CFrame = root.CFrame end)
        if typeof(onDone) == "function" then onDone() end
    end)
end

--// Gửi RequestQuest tới Dojo Trainer
local function requestQuest()
    local args = { { NPC = "Dojo Trainer", Command = "RequestQuest" } }
    local ok, res = pcall(function()
        local net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        return net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args))
    end)
    if ok then warn("[RequestQuest] OK:", res) else warn("[RequestQuest] FAIL:", res) end
    return ok, res
end

-- ==========================================================================
-- PHASE 4a: LỚP HÀNH ĐỘNG FRUIT (port từ autotradeadrop1.lua)
-- random fruit / drop fruit / claim quest / detect fruit bằng OBJECT
-- (không đọc title GUI)
-- ==========================================================================

--// Nhận diện 1 Tool có phải devil fruit không.
--// Ưu tiên cấu trúc: Tool chứa child "Fruit" (chuẩn của Blox Fruits),
--// fallback theo tên cho chắc.
local function isFruitTool(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    if tool:FindFirstChild("Fruit") then return true end
    return string.find(tool.Name, "Fruit") ~= nil
end

--// Lấy inventory từ server
local function getInventory()
    local ok, inv = pcall(function()
        return COMMF_:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then return inv end
    return {}
end

--// Đếm số Blox Fruit đang sở hữu (inventory) -> để diff trước/sau khi nhặt
local function countOwnedFruits()
    local n = 0
    for _, item in pairs(getInventory()) do
        if item and item.Type == "Blox Fruit" then n = n + 1 end
    end
    return n
end

--// Mua fruit ngẫu nhiên (Cousin Buy)
local function randomFruit()
    local ok, res = pcall(function() return COMMF_:InvokeServer("Cousin", "Buy") end)
    if ok then warn("[RandomFruit] OK:", res) else warn("[RandomFruit] FAIL:", res) end
    return ok, res
end

--// Ẩn dialogue nếu có (tránh kẹt khi equip)
local function hideDialogueIfAny()
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local main = pg and pg:FindFirstChild("Main")
        local dlg = main and main:FindFirstChild("Dialogue")
        if dlg and dlg.Visible == true then dlg.Visible = false end
    end)
end

--// Trang bị tool theo tên (trong char hoặc backpack)
local function EquipWeapon(toolName)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local tool = char:FindFirstChild(toolName)
    if not tool then
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then tool = bp:FindFirstChild(toolName) end
    end
    if tool and tool:IsA("Tool") then
        pcall(function() hum:EquipTool(tool) end)
        return tool
    end
    return nil
end

--// Thả 1 fruit theo tên tool qua EatRemote:Drop
local function dropToolFruitByName(name)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    EquipWeapon(name); task.wait(0.1); hideDialogueIfAny(); EquipWeapon(name); task.wait(0.05)
    local toolInChar = char:FindFirstChild(name)
    if not toolInChar then return false end
    local eatRemote = toolInChar:FindFirstChild("EatRemote")
    if not eatRemote then return false end
    return (pcall(function()
        if eatRemote:IsA("RemoteFunction") then eatRemote:InvokeServer("Drop")
        elseif eatRemote:IsA("RemoteEvent") then eatRemote:FireServer("Drop")
        else error("EatRemote sai loại") end
    end))
end

--// Thả TẤT CẢ fruit tool (backpack + char). Trả về số đã thả.
local function DropFruits()
    local dropped = 0
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if isFruitTool(tool) then
                if dropToolFruitByName(tool.Name) then dropped += 1 end
            end
        end
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    for _, tool in ipairs(char:GetChildren()) do
        if isFruitTool(tool) then
            if dropToolFruitByName(tool.Name) then dropped += 1 end
        end
    end
    return dropped
end

--// Một object trong workspace có phải fruit nằm trên đất không?
--// Ưu tiên cấu trúc (có child "Fruit"), fallback theo tên; phải có Handle.
local function isGroundFruit(obj)
    local handle = obj:FindFirstChild("Handle")
    if not (handle and handle:IsA("BasePart")) then return false end
    if obj:FindFirstChild("Fruit") then return true end
    return string.find(obj.Name, "Fruit") ~= nil
end

--// Đếm số OBJECT fruit đang nằm trên đất (trong workspace)
local function countFruitsOnGround()
    local n = 0
    for _, v in pairs(workspace:GetChildren()) do
        if isGroundFruit(v) then n = n + 1 end
    end
    return n
end

--// Kéo mọi object fruit trên đất về người (nhặt). Trả về số đã kéo.
local function collectFruits()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    local moved = 0
    for _, v in pairs(workspace:GetChildren()) do
        if isGroundFruit(v) then
            pcall(function() v.Handle.CFrame = hrp.CFrame end)
            moved += 1
        end
    end
    return moved
end

--// Nhặt + DETECT bằng inventory-diff: nhặt xong nếu số fruit sở hữu TĂNG.
--// timeout: số giây tối đa chờ. Trả về true nếu đã nhặt được (số tăng).
local function collectAndDetect(timeout)
    timeout = timeout or 8
    local before = countOwnedFruits()
    local t = 0
    repeat
        collectFruits()
        task.wait(0.4)
        t = t + 0.4
        if countOwnedFruits() > before then return true end
    until t >= timeout
    return countOwnedFruits() > before
end

--// Claim quest Dojo
local function claimQuest()
    local args = { { NPC = "Dojo Trainer", Command = "ClaimQuest" } }
    local ok, res = pcall(function()
        local net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
        return net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args))
    end)
    if ok then warn("[ClaimQuest] OK:", res) else warn("[ClaimQuest] FAIL:", res) end
    return ok, res
end

--// Kiểm tra đã có Green Belt (điều kiện hoàn thành)
local function hasGreenDojoBelt()
    for _, item in pairs(getInventory()) do
        if item and item.Name == "Dojo Belt (Green)" then return true end
    end
    return false
end

--// Quét player CÙNG team đang đứng trong bán kính RADIUS (kể cả mình),
--// trả về danh sách đã sort theo UserId tăng dần.
local function getNearbyTeamPlayers()
    local list = {}
    local myHrp = HumanoidRootPart
    if not myHrp then return list end
    local myPos = myHrp.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Team and p.Team.Name == TEAM then
            if p == LocalPlayer then
                table.insert(list, p)
            else
                local char = p.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - myPos).Magnitude <= RADIUS then
                    table.insert(list, p)
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.UserId < b.UserId end)
    return list
end

--// Cập nhật SLOT_LIST + MY_SLOT theo danh sách "sống" hiện tại.
--// Trả về MY_SLOT (số) hoặc nil. Cũng cập nhật UI khung Slot.
local function recomputeSlot()
    SLOT_LIST = getNearbyTeamPlayers()
    MY_SLOT = nil
    for i, p in ipairs(SLOT_LIST) do
        if p == LocalPlayer then MY_SLOT = i break end
    end
    if MY_SLOT then
        SetSlot(string.format("🎯 Slot %d / %d", MY_SLOT, #SLOT_LIST))
    else
        SetSlot("⚠️ Không có slot")
    end
    return MY_SLOT
end

-- ==========================================================================
-- CHOOSE TEAM (SetTeam remote + fallback firesignal + retry)
-- ==========================================================================
local function LoadTeam()
    xpcall(function()
        if LocalPlayer.Team then return end
        if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
            repeat task.wait(1)
            until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
        end
        xpcall(function()
            COMMF_:InvokeServer("SetTeam", TEAM)
        end, function()
            pcall(function()
                firesignal(LocalPlayer.PlayerGui["Main (minimal)"].ChooseTeam.Container[TEAM])
            end)
        end)
        task.wait(2)
    end, function(err) warn("[Team Error]:", err) end)
end

-- ==========================================================================
-- RGB ANIMATION REGISTRY
-- ==========================================================================
local RGBObjects = {}
local RGB_SPEED  = 0.18

local function RegisterRGB(stroke, hueOffset, sat, val)
    table.insert(RGBObjects, {
        obj    = stroke,
        offset = hueOffset or 0,
        sat    = sat or 0.85,
        val    = val or 1
    })
end

local rgbStartTime = tick()
RunService.RenderStepped:Connect(function()
    local elapsed = tick() - rgbStartTime
    for i = #RGBObjects, 1, -1 do
        local r = RGBObjects[i]
        if r.obj and r.obj.Parent then
            r.obj.Color = Color3.fromHSV((elapsed * RGB_SPEED + r.offset) % 1, r.sat, r.val)
        else
            table.remove(RGBObjects, i)
        end
    end
end)

-- ==========================================================================
-- UI (SlotPlayer + Status)
-- ==========================================================================
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("AutoDropGui")
    if old then old:Destroy() end
end)

local Gui = Instance.new("ScreenGui")
Gui.Name           = "AutoDropGui"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = false
Gui.DisplayOrder   = 1000
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = LocalPlayer.PlayerGui

-- Toggle button
local Toggle = Instance.new("TextButton")
Toggle.Size                   = UDim2.new(0, 54, 0, 54)
Toggle.Position               = UDim2.new(1, -70, 0.32, 0)
Toggle.BackgroundColor3       = Color3.fromRGB(18, 20, 28)
Toggle.BorderSizePixel        = 0
Toggle.Text                   = "🍈"
Toggle.TextSize               = 26
Toggle.Font                   = Enum.Font.GothamBold
Toggle.TextColor3             = Color3.fromRGB(255, 255, 255)
Toggle.TextStrokeTransparency = 0.4
Toggle.AutoButtonColor        = false
Toggle.Parent                 = Gui
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 14)

local toggleGrad = Instance.new("UIGradient", Toggle)
toggleGrad.Rotation = 90
toggleGrad.Color    = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 38, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 17, 25)),
}
local toggleStroke = Instance.new("UIStroke", Toggle)
toggleStroke.Thickness       = 2.5
toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
RegisterRGB(toggleStroke, 0)

Toggle.MouseEnter:Connect(function()
    TweenService:Create(Toggle, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
end)
Toggle.MouseLeave:Connect(function()
    TweenService:Create(Toggle, TweenInfo.new(0.2), {Size = UDim2.new(0, 54, 0, 54)}):Play()
end)

-- Main panel
local Panel = Instance.new("Frame")
Panel.Size             = UDim2.new(0, 280, 0, 220)
Panel.Position         = UDim2.new(1, -300, 0.5, -110)
Panel.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
Panel.BorderSizePixel  = 0
Panel.Active           = true
Panel.Draggable        = true
Panel.Visible          = true
Panel.Parent           = Gui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 16)

local panelGrad = Instance.new("UIGradient", Panel)
panelGrad.Rotation = 135
panelGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(22, 25, 38)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 16, 24)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 11, 18)),
}
local panelStroke = Instance.new("UIStroke", Panel)
panelStroke.Thickness       = 2.5
panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
RegisterRGB(panelStroke, 0, 0.9, 1)

local shadow = Instance.new("Frame")
shadow.Size                   = UDim2.new(1, 16, 1, 16)
shadow.Position               = UDim2.new(0, -8, 0, -8)
shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel        = 0
shadow.ZIndex                 = 0
shadow.Parent                 = Panel
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 22)

-- Header
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, -20, 0, 44)
Header.Position         = UDim2.new(0, 10, 0, 10)
Header.BackgroundColor3 = Color3.fromRGB(20, 23, 35)
Header.BorderSizePixel  = 0
Header.Parent           = Panel
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local hGrad = Instance.new("UIGradient", Header)
hGrad.Rotation = 0
hGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 32, 48)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 20, 30)),
}

local Title = Instance.new("TextLabel")
Title.Size                   = UDim2.new(1, -50, 1, 0)
Title.Position               = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text                   = "🍈 AUTO DROP"
Title.TextColor3             = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment         = Enum.TextXAlignment.Left
Title.Font                   = Enum.Font.GothamBold
Title.TextSize               = 16
Title.TextStrokeTransparency = 0.6
Title.Parent                 = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 30, 0, 30)
CloseBtn.Position         = UDim2.new(1, -36, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 15
CloseBtn.AutoButtonColor  = false
CloseBtn.Parent           = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}):Play()
end)

-- ===== SLOT PLAYER section =====
local SlotFrame = Instance.new("Frame")
SlotFrame.Size             = UDim2.new(1, -20, 0, 56)
SlotFrame.Position         = UDim2.new(0, 10, 0, 64)
SlotFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
SlotFrame.BorderSizePixel  = 0
SlotFrame.Parent           = Panel
Instance.new("UICorner", SlotFrame).CornerRadius = UDim.new(0, 10)

local slotStroke = Instance.new("UIStroke", SlotFrame)
slotStroke.Thickness       = 1.8
slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
RegisterRGB(slotStroke, 0.66, 0.85, 1)

local SlotTitle = Instance.new("TextLabel")
SlotTitle.Size                   = UDim2.new(1, -16, 0, 16)
SlotTitle.Position               = UDim2.new(0, 12, 0, 6)
SlotTitle.BackgroundTransparency = 1
SlotTitle.Text                   = "● SLOT PLAYER"
SlotTitle.TextColor3             = Color3.fromRGB(180, 160, 255)
SlotTitle.TextXAlignment         = Enum.TextXAlignment.Left
SlotTitle.Font                   = Enum.Font.GothamBold
SlotTitle.TextSize               = 11
SlotTitle.Parent                 = SlotFrame

local SlotLabel = Instance.new("TextLabel")
SlotLabel.Size                   = UDim2.new(1, -20, 0, 26)
SlotLabel.Position               = UDim2.new(0, 10, 0, 24)
SlotLabel.BackgroundTransparency = 1
SlotLabel.Text                   = "Slot: --"
SlotLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
SlotLabel.TextXAlignment         = Enum.TextXAlignment.Left
SlotLabel.Font                   = Enum.Font.GothamBold
SlotLabel.TextSize               = 15
SlotLabel.TextStrokeTransparency = 0.7
SlotLabel.Parent                 = SlotFrame

-- ===== STATUS section =====
local StatusFrame = Instance.new("Frame")
StatusFrame.Size             = UDim2.new(1, -20, 0, 70)
StatusFrame.Position         = UDim2.new(0, 10, 0, 128)
StatusFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
StatusFrame.BorderSizePixel  = 0
StatusFrame.Parent           = Panel
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 10)

local statusStroke = Instance.new("UIStroke", StatusFrame)
statusStroke.Thickness       = 1.8
statusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
RegisterRGB(statusStroke, 0.33, 0.85, 1)

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Size                   = UDim2.new(1, -16, 0, 16)
StatusTitle.Position               = UDim2.new(0, 12, 0, 6)
StatusTitle.BackgroundTransparency = 1
StatusTitle.Text                   = "● STATUS"
StatusTitle.TextColor3             = Color3.fromRGB(140, 200, 255)
StatusTitle.TextXAlignment         = Enum.TextXAlignment.Left
StatusTitle.Font                   = Enum.Font.GothamBold
StatusTitle.TextSize               = 11
StatusTitle.Parent                 = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size                   = UDim2.new(1, -20, 1, -28)
StatusLabel.Position               = UDim2.new(0, 10, 0, 24)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text                   = "Đang khởi động..."
StatusLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
StatusLabel.TextXAlignment         = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment         = Enum.TextYAlignment.Center
StatusLabel.Font                   = Enum.Font.GothamBold
StatusLabel.TextSize               = 13
StatusLabel.TextStrokeTransparency = 0.7
StatusLabel.TextWrapped            = true
StatusLabel.RichText               = true
StatusLabel.Parent                 = StatusFrame

--// Hàm cập nhật UI
local function SetStatus(text)
    StatusLabel.Text = text
    print("[AutoDrop] " .. text)
end
local function SetSlot(text)
    SlotLabel.Text = text
end

CloseBtn.MouseButton1Click:Connect(function() Panel.Visible = false end)
Toggle.MouseButton1Click:Connect(function() Panel.Visible = not Panel.Visible end)

-- ==========================================================================
-- MAIN FLOW (Giai đoạn 1)
-- ==========================================================================
SetStatus("Đang chọn team " .. TEAM .. "...")
LoadTeam()

local teamRetry = 0
while not LocalPlayer.Team and teamRetry < 5 do
    teamRetry = teamRetry + 1
    SetStatus("Retry chọn team... (" .. teamRetry .. "/5)")
    LoadTeam()
    task.wait(2)
end

if LocalPlayer.Team then
    SetStatus("✅ Team: " .. tostring(LocalPlayer.Team.Name))
else
    SetStatus("⚠️ Không chọn được team")
end

-- ==========================================================================
-- GIAI ĐOẠN 2: Bay lên Dojo RequestQuest rồi đứng yên
-- ==========================================================================
SetStatus("Đợi Character...")
repeat task.wait(0.5)
until Character and Character:FindFirstChild("HumanoidRootPart")

SetStatus("Bay lên Dojo...")
toposition(DOJO_POS, function()
    task.wait(0.25)
    SetStatus("RequestQuest...")
    requestQuest()
    SetStatus("✅ Đã RequestQuest - đứng yên tại Dojo.")

    -- ======================================================================
    -- GIAI ĐOẠN 3: Quét player gần -> đủ TOTAL thì đánh slot theo UserId
    -- Timeout 120s: chưa đủ vẫn tự chạy với số đang có.
    -- ======================================================================
    local waited = 0
    repeat
        SLOT_LIST = getNearbyTeamPlayers()
        SetSlot(string.format("Đợi: %d/%d player", #SLOT_LIST, TOTAL))
        SetStatus(string.format("Quét player gần... %d/%d (%ds/120s)", #SLOT_LIST, TOTAL, waited))
        if #SLOT_LIST >= TOTAL then break end
        task.wait(1)
        waited = waited + 1
    until waited >= 120

    -- Chốt slot lần đầu theo UserId
    recomputeSlot()
    for i, p in ipairs(SLOT_LIST) do
        print(string.format("   slot %d -> %s (UserId %d)", i, p.Name, p.UserId))
    end

    if MY_SLOT then
        SetStatus(string.format("✅ Đã đánh slot %d/%d (team %s)", MY_SLOT, #SLOT_LIST, TEAM))
    else
        SetStatus("⚠️ Không xác định được slot (chưa đúng team / chưa spawn?)")
    end

    -- Vòng nền nhẹ: recompute slot mỗi 2s theo danh sách "sống".
    -- Acc rớt/respawn -> danh sách tự dồn, thứ tự UserId vẫn ổn định.
    task.spawn(function()
        while true do
            task.wait(2)
            recomputeSlot()
        end
    end)

    -- ======================================================================
    -- GIAI ĐOẠN 4b: RING TUẦN TỰ (chung điểm, đồng bộ qua DistributedGameTime)
    -- Mỗi slot có 1 khe thời gian. activeSlot = slot đang tới lượt (mọi tab
    -- đọc cùng đồng hồ server -> nhất trí, không cần file).
    --
    -- Luồng hoàn chỉnh:
    --   - Feeder = slot 1 (UserId nhỏ nhất đang hiện diện). Seed 1 trái.
    --   - slot 2 -> 3 -> ... -> N lần lượt nhặt (của người trước) rồi thả lại.
    --   - Cuối cùng feeder nhặt trái mà slot N thả (của người khác -> hợp lệ).
    --   - Mỗi con nhặt được (inventory tăng) -> thả cho người sau -> đi claim.
    --
    -- Robust:
    --   - Feeder ĐỘNG: MY_SLOT==1 luôn là người UserId nhỏ nhất còn lại
    --     (recompute mỗi 2s) -> slot 1 rớt thì người kế tự thành feeder.
    --   - Chống tự-nhặt-seed: feeder phải thấy ground trống (seed đã được
    --     người khác nhặt) trước khi đủ điều kiện tự pickup.
    --   - Re-seed: nếu fruit biến mất quá lâu mà mình chưa xong -> feeder thả lại.
    -- ======================================================================
    if not MY_SLOT then
        SetStatus("⚠️ Không có slot -> không tham gia ring.")
        return
    end

    local DONE         = false   -- mình đã nhặt được của người khác chưa
    local hasSeeded    = false   -- (feeder) đã seed lần đầu chưa
    local seedReleased = false   -- (feeder) seed đã được người khác nhặt chưa
    local lastFruitSeen = workspace.DistributedGameTime  -- lần cuối thấy fruit trên đất

    local function liveN() return math.max(#SLOT_LIST, 1) end
    local function isFeeder() return MY_SLOT == 1 end

    --// Slot đang tới lượt theo đồng hồ server (mọi tab cùng kết quả)
    local function getActiveSlot()
        local n = liveN()
        return math.floor((workspace.DistributedGameTime % (n * SLOT_TIME)) / SLOT_TIME) + 1
    end

    --// Bay tới điểm drop (chờ tới nơi, timeout 10s)
    local function goDrop()
        local arrived = false
        toposition(DROP_POS, function() arrived = true end)
        local w = 0
        repeat task.wait(0.2) w = w + 0.2 until arrived or w >= 10
    end

    --// Feeder mua (nếu chưa có) + thả seed
    local function seedFruit()
        SetStatus("🍈 [Feeder] Mua fruit + thả seed...")
        goDrop()
        if countOwnedFruits() == 0 then randomFruit(); task.wait(1.5) end
        if DropFruits() > 0 then
            hasSeeded = true
            seedReleased = false
            SetStatus("🍈 [Feeder] Đã seed. Chờ người khác nhặt.")
        else
            SetStatus("⚠️ [Feeder] Seed thất bại (không có fruit để thả).")
        end
    end

    SetStatus(string.format("🔁 Vào ring (slot %d/%d). Chờ tới lượt...", MY_SLOT, liveN()))

    task.spawn(function()
        while not DONE do
            local active = getActiveSlot()
            local ground = countFruitsOnGround()
            if ground > 0 then lastFruitSeen = workspace.DistributedGameTime end

            if isFeeder() and not hasSeeded then
                -- Feeder seed 1 lần ở khe slot-1, khi ground trống
                if active == 1 and ground == 0 then
                    seedFruit()
                end

            elseif isFeeder() and hasSeeded and not seedReleased then
                -- Chờ seed được người khác nhặt (ground trống) -> tránh tự nhặt lại seed
                if ground == 0 then
                    seedReleased = true
                    SetStatus("🍈 [Feeder] Seed đã được nhặt. Chờ vòng quay lại.")
                end

            else
                -- PICKUP: tới khe của mình + có fruit (của người khác) trên đất
                if active == MY_SLOT and ground > 0 then
                    SetStatus(string.format("⬇️ Slot %d: tới lượt -> đi nhặt...", MY_SLOT))
                    goDrop()
                    if collectAndDetect(SLOT_TIME - 1) then
                        SetStatus(string.format("✅ Slot %d: NHẶT ĐƯỢC -> thả cho người sau...", MY_SLOT))
                        DropFruits()
                        DONE = true
                    else
                        SetStatus(string.format("⚠️ Slot %d: nhặt hụt, chờ lượt sau...", MY_SLOT))
                    end
                end

                -- RE-SEED: fruit mất quá lâu (despawn / rớt) mà mình chưa xong
                if isFeeder() and seedReleased and not DONE then
                    local idle = workspace.DistributedGameTime - lastFruitSeen
                    if ground == 0 and idle > (liveN() * SLOT_TIME * 1.5) then
                        SetStatus("♻️ [Feeder] Fruit mất quá lâu -> seed lại...")
                        seedFruit()
                    end
                end
            end

            task.wait(0.4)
        end

        -- ĐÃ NHẶT ĐƯỢC CỦA NGƯỜI KHÁC -> đi claim quest
        SetStatus("🏁 Bay lên Dojo ClaimQuest...")
        toposition(DOJO_POS, function()
            task.wait(0.25)
            claimQuest()
            task.wait(0.6)
            if hasGreenDojoBelt() then
                SetStatus("🎉 HOÀN THÀNH! Đã có Green Belt.")
            else
                SetStatus("✅ Đã ClaimQuest (kiểm tra lại belt nếu cần).")
            end
        end)
    end)
end)
