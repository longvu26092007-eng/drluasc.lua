repeat task.wait() until game:IsLoaded()

getgenv().Config = getgenv().Config or {
    TEAM = "Pirates" -- "Marines"
}
local Config = getgenv().Config

repeat task.wait() until game:GetService("Players").LocalPlayer
repeat task.wait() until game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")

do
    local Players = game:GetService("Players")
    local VIM = game:GetService("VirtualInputManager")
    local plr = Players.LocalPlayer

    if plr.Team == nil then
        repeat task.wait()
            for _, v in pairs(plr.PlayerGui:GetChildren()) do
                if string.find(v.Name, "Main") and v:FindFirstChild("ChooseTeam") then
                    local btn = v.ChooseTeam.Container[Config.TEAM].Frame.TextButton
                    btn.Size = UDim2.new(0, 10000, 0, 10000)
                    btn.Position = UDim2.new(-4, 0, -5, 0)
                    btn.BackgroundTransparency = 1
                    task.wait(0.35)
                    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1); task.wait(0.05)
                    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1); task.wait(0.05)
                end
            end
        until plr.Team ~= nil and game:IsLoaded()
        task.wait(1.5)
    end
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local SPEED = 220

local SEATS = {
    {Name = "Chair 1", CFrame = CFrame.new(-12591.058594, 337.443481, -7544.756836)},
    {Name = "Chair 2", CFrame = CFrame.new(-12602.312500, 337.442780, -7544.756836)},
    {Name = "Chair 3", CFrame = CFrame.new(-12602.312500, 337.442780, -7556.756836)},
    {Name = "Chair 4", CFrame = CFrame.new(-12591.058594, 337.443481, -7556.756836)},
    {Name = "Chair 5", CFrame = CFrame.new(-12591.058594, 337.443481, -7568.756836)},
    {Name = "Chair 6", CFrame = CFrame.new(-12602.312500, 337.442780, -7568.756836)},
}

local DOJO_POS  = CFrame.new(5862.036621, 1208.302124, 872.385437)
local EXTRA_POS = CFrame.new(5801.733887, 1208.568481, 877.088684)
local AFTER_QUEST_POS = CFrame.new(-12545.984375, 337.190063, -7546.318848)

local function getInventory()
    local ok, inv = pcall(function()
        return CommF_:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then return inv end
    return {}
end

local function getFruitsFromInventory()
    local inv = getInventory()
    local fruits = {}
    for _, item in pairs(inv) do
        if item and item.Type == "Blox Fruit" and item.Name then
            table.insert(fruits, item.Name)
        end
    end
    table.sort(fruits)
    return fruits
end

local function resetCharacter()
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0; print("RESET OK"); return true end
    warn("Ko Ok"); return false
end

local function loadFruitThenReset(fruitName)
    local ok, res = pcall(function()
        return CommF_:InvokeServer("LoadFruit", fruitName)
    end)
    if ok then resetCharacter() end
    return ok, res
end

local function toposition(Pos, onDone)
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    local xTweenPosition = {}
    local root = char:FindFirstChild("Root")

    if not root then
        local K = Instance.new("Part")
        K.Size = Vector3.new(20, 0.5, 20); K.Name = "Root"
        K.Anchored = true; K.Transparency = 1; K.CanCollide = false
        K.CFrame = hrp.CFrame * CFrame.new(0, 0.6, 0); K.Parent = char
        root = K
    end

    local distance = (Pos.Position - hrp.Position).Magnitude
    local info = TweenInfo.new(math.max(distance / SPEED, 0.05), Enum.EasingStyle.Linear)

    local function PartToPlayers() root.CFrame = hrp.CFrame end
    local function PlayersToPart() hrp.CFrame = root.CFrame end

    if hum and hum.Sit then hum.Sit = false end

    if distance <= 10 then
        root.CFrame = Pos; hrp.CFrame = Pos
        if typeof(onDone) == "function" then onDone() end
        return xTweenPosition
    end

    local tweenObj = TweenService:Create(root, info, { CFrame = Pos })
    tweenObj:Play()

    function xTweenPosition:Stop() pcall(function() tweenObj:Cancel() end) end

    local running = true
    task.spawn(function()
        while running and tweenObj.PlaybackState == Enum.PlaybackState.Playing do
            task.wait()
            pcall(function()
                PlayersToPart()
                if (root.Position - hrp.Position).Magnitude >= 1 then PartToPlayers() end
            end)
        end
    end)

    tweenObj.Completed:Connect(function()
        running = false
        pcall(function() hrp.CFrame = root.CFrame end)
        if typeof(onDone) == "function" then onDone() end
    end)

    return xTweenPosition
end

local function requestQuest()
    local args = { [1] = { NPC = "Dojo Trainer", Command = "RequestQuest" } }
    local ok, progress = pcall(function()
        return ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args))
    end)
    if ok then warn("[RequestQuest] OK:", progress) else warn("[RequestQuest] FAILED:", progress) end
    return ok, progress
end

local function claimQuest()
    local args = { [1] = { NPC = "Dojo Trainer", Command = "ClaimQuest" } }
    local ok, progress = pcall(function()
        return ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net"):FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(args))
    end)
    if ok then warn("[ClaimQuest] OK:", progress) else warn("[ClaimQuest] FAILED:", progress) end
    return ok, progress
end

local function randomFruit()
    local ok, res = pcall(function() return CommF_:InvokeServer("Cousin", "Buy") end)
    if ok then warn("[RandomFruit] OK:", res) else warn("[RandomFruit] FAILED:", res) end
    return ok, res
end

local function hideDialogueIfAny()
    pcall(function()
        local pg = plr:FindFirstChildOfClass("PlayerGui")
        local main = pg and pg:FindFirstChild("Main")
        local dlg = main and main:FindFirstChild("Dialogue")
        if dlg and dlg.Visible == true then dlg.Visible = false end
    end)
end

local function EquipWeapon(toolName)
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local tool = char:FindFirstChild(toolName)
    if not tool then
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp then tool = bp:FindFirstChild(toolName) end
    end
    if tool and tool:IsA("Tool") then pcall(function() humanoid:EquipTool(tool) end); return tool end
    return nil
end

local function dropToolFruitByName(name)
    local char = plr.Character or plr.CharacterAdded:Wait()
    EquipWeapon(name); task.wait(0.1); hideDialogueIfAny(); EquipWeapon(name); task.wait(0.05)
    local toolInChar = char:FindFirstChild(name)
    if not toolInChar then return false end
    local eatRemote = toolInChar:FindFirstChild("EatRemote")
    if not eatRemote then return false end
    local ok = pcall(function()
        if eatRemote:IsA("RemoteFunction") then eatRemote:InvokeServer("Drop")
        elseif eatRemote:IsA("RemoteEvent") then eatRemote:FireServer("Drop")
        else error("EatRemote is not RemoteFunction/RemoteEvent") end
    end)
    return ok
end

local function DropFruits()
    local dropped = 0
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name, "Fruit") then
                if dropToolFruitByName(tool.Name) then dropped += 1 end
            end
        end
    end
    local char = plr.Character or plr.CharacterAdded:Wait()
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and string.find(tool.Name, "Fruit") then
            if dropToolFruitByName(tool.Name) then dropped += 1 end
        end
    end
    return dropped
end

local function collectFruits(success)
    if not success then return 0 end
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local moved = 0
    for _, v1 in pairs(workspace:GetChildren()) do
        if typeof(v1) == "Instance" and string.find(v1.Name, "Fruit") then
            local handle = v1:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                pcall(function() handle.CFrame = hrp.CFrame end)
                moved += 1
            end
        end
    end
    return moved
end

local function hasGreenDojoBelt()
    local inv = getInventory()
    for _, item in pairs(inv) do
        if item and item.Name == "Dojo Belt (Green)" then return true end
    end
    return false
end

local lastTrigger = 0
local COOLDOWN = 6

local function screenHasTradeText()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local t = obj.Text
            if type(t) == "string" and t ~= "" then
                if string.find(t, "Trade completed", 1, true) or string.find(t, "Check your Inventory", 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

local pg = plr:WaitForChild("PlayerGui")
pcall(function() local old = pg:FindFirstChild("DojoSeatHubGUI"); if old then old:Destroy() end end)

local gui = Instance.new("ScreenGui")
gui.Name = "DojoSeatHubGUI"; gui.ResetOnSpawn = false; gui.Parent = pg

local frame = Instance.new("Frame")
frame.Parent = gui; frame.Size = UDim2.new(0, 280, 0, 380)
frame.Position = UDim2.new(0, 20, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15); frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local titleBar = Instance.new("Frame")
titleBar.Parent = frame; titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundTransparency = 1; titleBar.Active = true

local title = Instance.new("TextLabel")
title.Parent = titleBar; title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 12, 0, 0); title.Size = UDim2.new(1, -120, 1, 0)
title.Text = "Auto Dojo Quest"; title.Font = Enum.Font.GothamBold
title.TextSize = 16; title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = titleBar; toggleBtn.Size = UDim2.new(0, 34, 0, 28)
toggleBtn.Position = UDim2.new(1, -42, 0, 12)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); toggleBtn.BorderSizePixel = 0
toggleBtn.TextColor3 = Color3.fromRGB(235, 235, 235); toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16; toggleBtn.Text = "–"
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Parent = frame; status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 12, 0, 48); status.Size = UDim2.new(1, -24, 0, 18)
status.Text = "Auto: chuẩn bị RequestQuest..."; status.Font = Enum.Font.Gotham
status.TextSize = 12; status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextXAlignment = Enum.TextXAlignment.Left

local tabBar = Instance.new("Frame")
tabBar.Parent = frame; tabBar.BackgroundTransparency = 1
tabBar.Position = UDim2.new(0, 12, 0, 72); tabBar.Size = UDim2.new(1, -24, 0, 34)

local function makeTab(text, xScale, wScale)
    local b = Instance.new("TextButton"); b.Parent = tabBar
    b.Size = UDim2.new(wScale, -6, 1, 0); b.Position = UDim2.new(xScale, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 35); b.BorderSizePixel = 0
    b.Text = text; b.Font = Enum.Font.GothamBold; b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(235, 235, 235)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    return b
end

local tabDrop  = makeTab("Drop",  0/3, 1/3)
local tabTrade = makeTab("Trade", 1/3, 1/3)
local tabFruit = makeTab("Fruit", 2/3, 1/3)

local content = Instance.new("Frame")
content.Parent = frame; content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 110); content.Size = UDim2.new(1, 0, 1, -110)

local dojoPage = Instance.new("Frame")
dojoPage.Parent = content; dojoPage.BackgroundTransparency = 1; dojoPage.Size = UDim2.new(1, 0, 1, 0)

local seatsPage = Instance.new("Frame")
seatsPage.Parent = content; seatsPage.BackgroundTransparency = 1
seatsPage.Size = UDim2.new(1, 0, 1, 0); seatsPage.Visible = false

local fruitPage = Instance.new("Frame")
fruitPage.Parent = content; fruitPage.BackgroundTransparency = 1
fruitPage.Size = UDim2.new(1, 0, 1, 0); fruitPage.Visible = false

local currentTab = "Drop"
local function setActiveTab(tabName)
    currentTab = tabName
    dojoPage.Visible  = (tabName == "Drop")
    seatsPage.Visible = (tabName == "Trade")
    fruitPage.Visible = (tabName == "Fruit")
    tabDrop.BackgroundColor3  = (tabName == "Drop")  and Color3.fromRGB(55,55,55) or Color3.fromRGB(35,35,35)
    tabTrade.BackgroundColor3 = (tabName == "Trade") and Color3.fromRGB(55,55,55) or Color3.fromRGB(35,35,35)
    tabFruit.BackgroundColor3 = (tabName == "Fruit") and Color3.fromRGB(55,55,55) or Color3.fromRGB(35,35,35)
end

tabDrop.MouseButton1Click:Connect(function() setActiveTab("Drop") end)
tabTrade.MouseButton1Click:Connect(function() setActiveTab("Trade") end)
tabFruit.MouseButton1Click:Connect(function() setActiveTab("Fruit") end)

do
    local dragging = false; local dragStartPos; local startFramePos; local dragInput
    local function update(input)
        local delta = input.Position - dragStartPos
        frame.Position = UDim2.new(startFramePos.X.Scale, startFramePos.X.Offset + delta.X, startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
    end
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStartPos = input.Position; startFramePos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input == dragInput then update(input) end end)
end

local expandedSize = frame.Size
local collapsedSize = UDim2.new(0, 280, 0, 52)
local isCollapsed = false

local function setCollapsed(state)
    isCollapsed = state
    content.Visible = not state; tabBar.Visible = not state; status.Visible = not state
    toggleBtn.Text = state and "+" or "–"
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = state and collapsedSize or expandedSize}):Play()
end
toggleBtn.MouseButton1Click:Connect(function() setCollapsed(not isCollapsed) end)

local function makeBtn(parent, text, y)
    local b = Instance.new("TextButton"); b.Parent = parent
    b.Size = UDim2.new(1, -24, 0, 44); b.Position = UDim2.new(0, 12, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 35); b.BorderSizePixel = 0
    b.Text = text; b.Font = Enum.Font.GothamBold; b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(235, 235, 235)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
    return b
end

local btnClaim   = makeBtn(dojoPage, "CLAIM QUEST (GO DOJO)", 8)
local btnDrop    = makeBtn(dojoPage, "DROP FRUITS", 60)
local btnGo      = makeBtn(dojoPage, "GO TO COORD", 112)
local btnCollect = makeBtn(dojoPage, "COLLECT FRUITS", 164)
local btnRandom  = makeBtn(dojoPage, "RANDOM FRUIT", 216)

local btnTichHop = makeBtn(dojoPage, "⚡ TÍCH HỢP", 268)
btnTichHop.BackgroundColor3 = Color3.fromRGB(60, 40, 0)
Instance.new("UIStroke", btnTichHop).Color = Color3.fromRGB(255, 200, 0)

local busy = true
local function lockDojoButtons(isLocked)
    local v = not isLocked
    btnClaim.AutoButtonColor = v; btnDrop.AutoButtonColor = v
    btnGo.AutoButtonColor = v; btnCollect.AutoButtonColor = v
    btnRandom.AutoButtonColor = v; btnTichHop.AutoButtonColor = v
end

local CHAIR_KEY_MAP = {
    [Enum.KeyCode.One]=1, [Enum.KeyCode.Two]=2, [Enum.KeyCode.Three]=3,
    [Enum.KeyCode.Four]=4, [Enum.KeyCode.Five]=5, [Enum.KeyCode.Six]=6,
}

local function goToChair(index)
    local seat = SEATS[index]; if not seat then return end
    status.Text = "Chair: bay tới " .. seat.Name .. " [phím " .. index .. "]..."
    toposition(seat.CFrame, function() status.Text = "Chair: tới " .. seat.Name .. "!" end)
end

local y = 8
for i = 1, #SEATS do
    local seat = SEATS[i]
    local btn = Instance.new("TextButton"); btn.Parent = seatsPage
    btn.Size = UDim2.new(1, -24, 0, 36); btn.Position = UDim2.new(0, 12, 0, y)
    btn.Text = seat.Name .. "  [" .. i .. "]"; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13; btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(function() goToChair(i) end)
    y = y + 42
end

local fruitTop = Instance.new("Frame"); fruitTop.Parent = fruitPage
fruitTop.BackgroundTransparency = 1; fruitTop.Position = UDim2.new(0, 12, 0, 8)
fruitTop.Size = UDim2.new(1, -24, 0, 36)

local fruitRefresh = Instance.new("TextButton"); fruitRefresh.Parent = fruitTop
fruitRefresh.Size = UDim2.new(1, 0, 1, 0)
fruitRefresh.BackgroundColor3 = Color3.fromRGB(35, 35, 35); fruitRefresh.BorderSizePixel = 0
fruitRefresh.Text = "REFRESH / CHECK FRUITS"; fruitRefresh.Font = Enum.Font.GothamBold
fruitRefresh.TextSize = 13; fruitRefresh.TextColor3 = Color3.fromRGB(235, 235, 235)
Instance.new("UICorner", fruitRefresh).CornerRadius = UDim.new(0, 12)

local fruitScroll = Instance.new("ScrollingFrame"); fruitScroll.Parent = fruitPage
fruitScroll.Position = UDim2.new(0, 12, 0, 52); fruitScroll.Size = UDim2.new(1, -24, 1, -60)
fruitScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25); fruitScroll.BorderSizePixel = 0
fruitScroll.ScrollBarThickness = 6; fruitScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", fruitScroll).CornerRadius = UDim.new(0, 12)

local fruitPad = Instance.new("UIPadding"); fruitPad.Parent = fruitScroll
fruitPad.PaddingTop = UDim.new(0, 10); fruitPad.PaddingLeft = UDim.new(0, 10)
fruitPad.PaddingRight = UDim.new(0, 10); fruitPad.PaddingBottom = UDim.new(0, 10)

local fruitLayout = Instance.new("UIListLayout"); fruitLayout.Parent = fruitScroll
fruitLayout.Padding = UDim.new(0, 8); fruitLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function clearFruitButtons()
    for _, c in ipairs(fruitScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
end

local function makeFruitButton(fruitName)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); btn.BorderSizePixel = 0
    btn.Text = fruitName .. "  (Load + Reset)"; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13; btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local debounce = false
    btn.MouseButton1Click:Connect(function()
        if debounce then return end; debounce = true
        status.Text = "Fruit: Loading " .. fruitName .. "..."
        local ok, res = loadFruitThenReset(fruitName)
        status.Text = ok and ("Fruit: Loaded " .. fruitName .. " -> RESET") or ("Fruit: Load error: " .. tostring(res))
        debounce = false
    end)
    return btn
end

local function renderFruitList()
    status.Text = "Fruit: checking inventory..."; clearFruitButtons()
    local fruits = getFruitsFromInventory()
    if #fruits == 0 then
        local lbl = Instance.new("TextLabel"); lbl.Parent = fruitScroll
        lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.Text = "Không có fruit trong inventory."; lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12; lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
    else
        status.Text = "Fruit: Found " .. tostring(#fruits) .. " fruits. Click để Load + Reset."
        for _, name in ipairs(fruits) do makeFruitButton(name).Parent = fruitScroll end
    end
    task.wait(); fruitScroll.CanvasSize = UDim2.new(0, 0, 0, fruitLayout.AbsoluteContentSize.Y + 20)
end

fruitRefresh.MouseButton1Click:Connect(renderFruitList)

task.spawn(function()
    lockDojoButtons(true); status.Text = "Auto: bay lên Dojo..."
    toposition(DOJO_POS, function()
        task.wait(0.25); status.Text = "Auto: RequestQuest..."
        local ok = select(1, requestQuest())
        if ok then
            if hasGreenDojoBelt() then
                status.Text = "Auto: Có Green Belt -> không cần teleport!"
                lockDojoButtons(false); busy = false; return
            end
            status.Text = "Auto: RequestQuest OK -> Tele tới vị trí..."
            task.wait(0.25)
            toposition(AFTER_QUEST_POS, function()
                status.Text = "Auto done: Đã tele tới vị trí sau quest! (Ready)"
                lockDojoButtons(false); busy = false
            end)
        else
            status.Text = "Auto: RequestQuest FAIL (xem warn/log)"
            lockDojoButtons(false); busy = false
        end
    end)
end)

btnClaim.MouseButton1Click:Connect(function()
    if busy then return end; busy = true; lockDojoButtons(true)
    btnClaim.Text = "RUNNING..."; status.Text = "Bay lên Dojo..."
    toposition(DOJO_POS, function()
        task.wait(0.25); status.Text = "ClaimQuest..."
        local ok = select(1, claimQuest())
        status.Text = ok and "ClaimQuest OK!" or "ClaimQuest FAIL (xem warn)"
        task.wait(0.8); btnClaim.Text = "CLAIM QUEST (GO DOJO)"; lockDojoButtons(false); busy = false
    end)
end)

btnDrop.MouseButton1Click:Connect(function()
    if busy then return end; busy = true; lockDojoButtons(true)
    btnDrop.Text = "DROPPING..."; status.Text = "Dropping fruits..."
    local ok, res = pcall(function() return DropFruits() end)
    status.Text = ok and ("Dropped: " .. tostring(res)) or ("Drop error: " .. tostring(res))
    task.wait(0.8); btnDrop.Text = "DROP FRUITS"; lockDojoButtons(false); busy = false
end)

btnGo.MouseButton1Click:Connect(function()
    if busy then return end; busy = true; lockDojoButtons(true)
    btnGo.Text = "MOVING..."; status.Text = "Bay tới tọa độ..."
    toposition(EXTRA_POS, function()
        status.Text = "Đã tới tọa độ!"; task.wait(0.8)
        btnGo.Text = "GO TO COORD"; lockDojoButtons(false); busy = false
    end)
end)

btnCollect.MouseButton1Click:Connect(function()
    if busy then return end; busy = true; lockDojoButtons(true)
    btnCollect.Text = "COLLECTING..."; status.Text = "Đang kéo fruit về người..."
    local ok, movedOrErr = pcall(function() return collectFruits(true) end)
    status.Text = ok and ("Collect done! Moved: " .. tostring(movedOrErr)) or ("Collect error: " .. tostring(movedOrErr))
    task.wait(0.8); btnCollect.Text = "COLLECT FRUITS"; lockDojoButtons(false); busy = false
end)

btnRandom.MouseButton1Click:Connect(function()
    if busy then return end; busy = true; lockDojoButtons(true)
    btnRandom.Text = "ROLLING..."; status.Text = "Random fruit (Cousin Buy)..."
    local ok = select(1, randomFruit())
    status.Text = ok and "Random OK! (xem warn/log)" or "Random FAIL (xem warn)"
    task.wait(0.8); btnRandom.Text = "RANDOM FRUIT"; lockDojoButtons(false); busy = false
end)

-- ==========================================
-- TÍCH HỢP: Collect → 1s → Go → 1s → Drop → 1s → Claim
-- ==========================================
btnTichHop.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true; lockDojoButtons(true)
    btnTichHop.Text = "⚡ ĐANG CHẠY..."
    btnTichHop.BackgroundColor3 = Color3.fromRGB(100, 70, 0)

    -- BƯỚC 1: COLLECT FRUITS
    status.Text = "⚡ [1/4] Collect Fruits..."
    pcall(function() collectFruits(true) end)
    status.Text = "⚡ [1/4] Collect xong! Đợi 1s..."
    task.wait(1)

    -- BƯỚC 2: GO TO COORD
    status.Text = "⚡ [2/4] Go to Coord..."
    local goFinished = false
    toposition(EXTRA_POS, function() goFinished = true end)
    repeat task.wait(0.1) until goFinished
    status.Text = "⚡ [2/4] Đã tới! Đợi 1s..."
    task.wait(1)

    -- BƯỚC 3: DROP FRUITS
    status.Text = "⚡ [3/4] Drop Fruits..."
    pcall(function() DropFruits() end)
    status.Text = "⚡ [3/4] Drop xong! Đợi 1s..."
    task.wait(1)

    -- BƯỚC 4: CLAIM QUEST (GO DOJO)
    status.Text = "⚡ [4/4] Bay lên Dojo Claim..."
    local claimFinished = false
    toposition(DOJO_POS, function()
        task.wait(0.25)
        claimQuest()
        claimFinished = true
    end)
    repeat task.wait(0.1) until claimFinished
    status.Text = "⚡ TÍCH HỢP HOÀN TẤT!"

    task.wait(1)
    btnTichHop.Text = "⚡ TÍCH HỢP"
    btnTichHop.BackgroundColor3 = Color3.fromRGB(60, 40, 0)
    lockDojoButtons(false); busy = false
end)

task.spawn(function()
    while task.wait(0.5) do
        if screenHasTradeText() and (tick() - lastTrigger) > COOLDOWN then
            lastTrigger = tick()
            warn("[DETECT] Trade completed -> ClaimQuest")
            status.Text = "Detect: Trade completed -> đi Dojo ClaimQuest..."
            task.wait(1.2)
            toposition(DOJO_POS, function()
                task.wait(0.2); claimQuest()
                status.Text = "Detect: ClaimQuest xong (xem warn/log)."
            end)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled; return
    end
    local chairIndex = CHAIR_KEY_MAP[input.KeyCode]
    if chairIndex then goToChair(chairIndex) end
end)

setActiveTab("Drop")
renderFruitList()
