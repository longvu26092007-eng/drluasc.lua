repeat task.wait() until game:IsLoaded()

getgenv().Config = getgenv().Config or {}
local Config = getgenv().Config
Config.TEAM = Config.TEAM or "Pirates" -- "Marines"
Config.WEB_BASE_URL = "https://vunguyendraco.online" -- dashboard/API đang chạy ở domain gốc
Config.ACCOUNT_ID = Config.ACCOUNT_ID or nil 
Config.AUTO_WEB = (Config.AUTO_WEB ~= false)
Config.POLL_INTERVAL = tonumber(Config.POLL_INTERVAL) or 3
Config.FAIL_WAIT = tonumber(Config.FAIL_WAIT) or 5
Config.TRADE_TIMEOUT = tonumber(Config.TRADE_TIMEOUT) or 180
Config.PAIR_READY_TIMEOUT = tonumber(Config.PAIR_READY_TIMEOUT) or 600
Config.HEARTBEAT_RETRY = tonumber(Config.HEARTBEAT_RETRY) or 3

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
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")
local TradeFunction = Remotes:WaitForChild("TradeFunction")
local ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig"))

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
    if ok and type(inv) == "table" then
        return inv
    end
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
    if hum then
        hum.Health = 0
        print("RESET OK")
        return true
    else
        warn("Ko Ok")
        return false
    end
end

local FRUIT_ALIAS_MAP = {
    kilo = {"rocket"}, rocket = {"kilo"},
    chop = {"blade"}, blade = {"chop"},
    falcon = {"eagle"}, eagle = {"falcon"},
    revive = {"ghost"}, ghost = {"revive"},
    barrier = {"creation"}, creation = {"barrier"},
    door = {"portal"}, portal = {"door"},
    string = {"spider"}, spider = {"string"},
    rumble = {"lightning"}, lightning = {"rumble"},
    paw = {"pain"}, pain = {"paw"},
    soul = {"spirit"}, spirit = {"soul"},
    leopard = {"tiger"}, tiger = {"leopard"},
}

local function normalizeFruitKey(str)
    local s = tostring(str or ""):lower()
    s = s:gsub("_", " ")
    s = s:gsub("%s+fruit%s*$", "")

    local a, b = s:match("^%s*(.-)%s*%-%s*(.-)%s*$")
    if a and b then
        local ca = a:gsub("%s+fruit%s*$", ""):gsub("[^%w]", "")
        local cb = b:gsub("%s+fruit%s*$", ""):gsub("[^%w]", "")
        if ca ~= "" and ca == cb then
            s = a
        end
    end

    s = s:gsub("fruit", "")
    s = s:gsub("[^%w]", "")
    return s
end

local function addFruitKeyWithAliases(set, value)
    local key = normalizeFruitKey(value)
    if key == "" then return end
    set[key] = true
    local aliases = FRUIT_ALIAS_MAP[key]
    if type(aliases) == "table" then
        for _, alias in ipairs(aliases) do
            local ak = normalizeFruitKey(alias)
            if ak ~= "" then set[ak] = true end
        end
    end
end

local function fruitKeySet(...)
    local set = {}
    for _, value in ipairs({...}) do
        addFruitKeyWithAliases(set, value)
    end
    return set
end

local function fruitKeySetsMatch(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return nil end
    for key in pairs(a) do
        if b[key] then return key end
    end
    return nil
end

local function fruitKeysToString(set)
    local arr = {}
    if type(set) == "table" then
        for key in pairs(set) do table.insert(arr, key) end
    end
    table.sort(arr)
    return table.concat(arr, "/")
end

local function NormalizeFruitDeleteName(str)
    return normalizeFruitKey(str)
end

local function fruitBaseName(name)
    local s = tostring(name or "")
    s = s:gsub("%s+[Ff]ruit$", "")
    s = s:gsub("%s*%-%s*", "-")
    local p = string.match(s, "^(.+)%-%1$")
    if p then s = p end
    return s
end

local function addCandidate(list, seen, value)
    value = tostring(value or "")
    if value == "" or seen[value] then return end
    seen[value] = true
    table.insert(list, value)
end

local function findInventoryFruitNameForDelete(targetName)
    local targetKeys = fruitKeySet(targetName)
    local inv = getInventory()

    for _, item in pairs(inv) do
        if item and item.Type == "Blox Fruit" and item.Name then
            local itemName = tostring(item.Name)
            if fruitKeySetsMatch(targetKeys, fruitKeySet(itemName)) then
                return itemName
            end
        end
    end

    return nil
end

local function findLoadedFruitTool(targetName)
    local targetKeys = fruitKeySet(targetName)
    local containers = {}

    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then table.insert(containers, bp) end
    if plr.Character then table.insert(containers, plr.Character) end

    for _, container in ipairs(containers) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("EatRemote", true) then
                local originalName = tool:GetAttribute("OriginalName")
                local toolKeys = fruitKeySet(tool.Name, originalName)
                if fruitKeySetsMatch(targetKeys, toolKeys) then
                    return tool
                end
            end
        end
    end

    return nil
end

local function waitLoadedFruitTool(targetName, timeoutSec)
    local started = tick()
    repeat
        local tool = findLoadedFruitTool(targetName)
        if tool then return tool end
        task.wait(0.2)
    until (tick() - started) >= (timeoutSec or 5)
    return nil
end

local function loadFruitThenReset(fruitName)

    local requested = tostring(fruitName or "")
    local invName = findInventoryFruitNameForDelete(requested)

    local candidates, seen = {}, {}
    addCandidate(candidates, seen, invName)
    addCandidate(candidates, seen, requested)

    local base = fruitBaseName(invName or requested)
    addCandidate(candidates, seen, base)
    if base ~= "" and not string.find(base, "%-") then
        addCandidate(candidates, seen, base .. "-" .. base)
        addCandidate(candidates, seen, base .. " Fruit")
    end

    local alreadyTool = findLoadedFruitTool(requested)
    if alreadyTool then
        warn("[DeleteFruit] Fruit already loaded as tool:", alreadyTool.Name, "-> reset")
        resetCharacter()
        return true, "already loaded tool: " .. tostring(alreadyTool.Name)
    end

    local lastRes = nil
    for _, candidate in ipairs(candidates) do
        warn("[DeleteFruit] LoadFruit attempt:", tostring(candidate), "| target:", requested)
        local ok, res = pcall(function()
            return CommF_:InvokeServer("LoadFruit", candidate)
        end)
        lastRes = res

        if ok and res ~= false then
            local tool = waitLoadedFruitTool(requested, 4) or waitLoadedFruitTool(candidate, 2)
            if tool then
                warn("[DeleteFruit] Loaded fruit tool:", tool.Name, "from:", tostring(candidate), "-> reset")
                resetCharacter()
                return true, "loaded " .. tostring(tool.Name) .. " then reset"
            else
                warn("[DeleteFruit] LoadFruit returned but tool not found yet:", tostring(candidate), tostring(res))
            end
        else
            warn("[DeleteFruit] LoadFruit failed:", tostring(candidate), tostring(res))
        end

        task.wait(0.35)
    end

    return false, "LoadFruit không tạo tool fruit để reset | target=" .. requested .. " | inventoryName=" .. tostring(invName) .. " | last=" .. tostring(lastRes)
end

local function toposition(Pos, onDone)
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    local xTweenPosition = {}
    local root = char:FindFirstChild("Root")

    if not root then
        local K = Instance.new("Part")
        K.Size = Vector3.new(20, 0.5, 20)
        K.Name = "Root"
        K.Anchored = true
        K.Transparency = 1
        K.CanCollide = false
        K.CFrame = hrp.CFrame * CFrame.new(0, 0.6, 0)
        K.Parent = char
        root = K
    end

    local distance = (Pos.Position - hrp.Position).Magnitude
    local info = TweenInfo.new(math.max(distance / SPEED, 0.05), Enum.EasingStyle.Linear)

    local function PartToPlayers()
        root.CFrame = hrp.CFrame
    end
    local function PlayersToPart()
        hrp.CFrame = root.CFrame
    end

    if hum and hum.Sit then hum.Sit = false end

    if distance <= 10 then
        root.CFrame = Pos
        hrp.CFrame = Pos
        if typeof(onDone) == "function" then onDone() end
        return xTweenPosition
    end

    local tweenObj = TweenService:Create(root, info, { CFrame = Pos })
    tweenObj:Play()

    function xTweenPosition:Stop()
        pcall(function() tweenObj:Cancel() end)
    end

    local running = true
    task.spawn(function()
        while running and tweenObj.PlaybackState == Enum.PlaybackState.Playing do
            task.wait()
            pcall(function()
                PlayersToPart()
                if (root.Position - hrp.Position).Magnitude >= 1 then
                    PartToPlayers()
                end
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
        return ReplicatedStorage
            :WaitForChild("Modules")
            :WaitForChild("Net")
            :FindFirstChild("RF/InteractDragonQuest")
            :InvokeServer(unpack(args))
    end)
    if ok then warn("[RequestQuest] OK:", progress) else warn("[RequestQuest] FAILED:", progress) end
    return ok, progress
end

local function claimQuest()
    local args = { [1] = { NPC = "Dojo Trainer", Command = "ClaimQuest" } }
    local ok, progress = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Modules")
            :WaitForChild("Net")
            :FindFirstChild("RF/InteractDragonQuest")
            :InvokeServer(unpack(args))
    end)
    if ok then warn("[ClaimQuest] OK:", progress) else warn("[ClaimQuest] FAILED:", progress) end
    return ok, progress
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local PlayerGui = plr:WaitForChild("PlayerGui")
local Backpack = plr:WaitForChild("Backpack")

getgenv().AutoCloseSpinner = getgenv().AutoCloseSpinner ~= false
getgenv().AutoStoreFruit = getgenv().AutoStoreFruit ~= false
getgenv().CloseSpinnerInterval = tonumber(getgenv().CloseSpinnerInterval) or 0.15
getgenv().StoreFruitInterval = tonumber(getgenv().StoreFruitInterval) or 0.5

local closingSpinner = false
local storingTools = setmetatable({}, {__mode = "k"})
local lastStoredAt = 0
local lastStoreResult = nil

local function getSpinnerWindow()
    return PlayerGui:FindFirstChild("SpinnerWindow", true)
end

local function getSpinnerCloseButton()
    local spinner = getSpinnerWindow()
    if not spinner then
        return nil
    end

    local aboveSpinner = spinner:FindFirstChild("AboveSpinner")
    local navigation = aboveSpinner and aboveSpinner:FindFirstChild("Navigation")
    local closeButton = navigation and navigation:FindFirstChild("CloseButton")

    if closeButton then
        return closeButton
    end

    return spinner:FindFirstChild("CloseButton", true)
end

local function isGuiVisible(object)
    if not object or not object.Parent then
        return false
    end

    local screenGui = object:FindFirstAncestorOfClass("ScreenGui")
    if screenGui and screenGui.Enabled == false then
        return false
    end

    local current = object
    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") and current.Visible == false then
            return false
        end
        current = current.Parent
    end

    return true
end

local function fireButtonConnections(button)
    if type(getconnections) ~= "function" then
        return false
    end

    local fired = false

    for _, signalName in ipairs({
        "Activated",
        "MouseButton1Click",
        "MouseButton1Down",
        "MouseButton1Up"
    }) do
        local okSignal, signal = pcall(function()
            return button[signalName]
        end)

        if okSignal and typeof(signal) == "RBXScriptSignal" then
            local okConnections, connections = pcall(getconnections, signal)

            if okConnections and type(connections) == "table" then
                for _, connection in ipairs(connections) do
                    pcall(function()
                        if connection.Enabled ~= false then
                            connection:Fire()
                            fired = true
                        end
                    end)
                end
            end
        end
    end

    return fired
end

local function clickButtonPosition(button)
    if not button or not button:IsA("GuiObject") then
        return false
    end

    local position = button.AbsolutePosition
    local size = button.AbsoluteSize

    if size.X <= 0 or size.Y <= 0 then
        return false
    end

    local x = position.X + size.X / 2
    local y = position.Y + size.Y / 2

    local ok = pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)

    return ok
end

local function pressCloseButton(button)
    local fired = fireButtonConnections(button)

    if not fired then
        fired = clickButtonPosition(button)
    end

    return fired
end

local function CloseSpinnerWindow(timeout)
    if not getgenv().AutoCloseSpinner or closingSpinner then
        return false
    end

    closingSpinner = true
    timeout = tonumber(timeout) or 3

    local startedAt = tick()
    local closed = false

    repeat
        if not getgenv().AutoCloseSpinner then
            break
        end

        local closeButton = getSpinnerCloseButton()

        if closeButton and isGuiVisible(closeButton) then
            pressCloseButton(closeButton)
            task.wait(0.2)

            if not closeButton.Parent or not isGuiVisible(closeButton) then
                closed = true
                break
            end

            local spinner = getSpinnerWindow()
            if spinner and spinner:IsA("ScreenGui") then
                pcall(function()
                    spinner.Enabled = false
                end)
                closed = true
                break
            end
        end

        task.wait(0.05)
    until tick() - startedAt >= timeout

    closingSpinner = false
    return closed
end

getgenv().CloseSpinnerWindow = CloseSpinnerWindow

PlayerGui.DescendantAdded:Connect(function(object)
    if not getgenv().AutoCloseSpinner then
        return
    end

    if object.Name == "SpinnerWindow" or object.Name == "CloseButton" then
        task.defer(function()
            CloseSpinnerWindow(5)
        end)
    end
end)

task.spawn(function()
    while task.wait(getgenv().CloseSpinnerInterval) do
        if getgenv().AutoCloseSpinner then
            local closeButton = getSpinnerCloseButton()

            if closeButton and isGuiVisible(closeButton) then
                CloseSpinnerWindow(1)
            end
        end
    end
end)

local function getFruitOriginalName(tool)
    if not tool or not tool:IsA("Tool") then
        return nil
    end

    local eatRemote = tool:FindFirstChild("EatRemote", true)
    if not eatRemote then
        return nil
    end

    local originalName

    if eatRemote.Parent then
        originalName = eatRemote.Parent:GetAttribute("OriginalName")
    end

    if type(originalName) ~= "string" or originalName == "" then
        originalName = tool:GetAttribute("OriginalName")
    end

    if type(originalName) ~= "string" or originalName == "" then
        originalName = tool.Name
    end

    if type(originalName) ~= "string" or originalName == "" then
        return nil
    end

    return originalName
end

local function moveToolToBackpack(tool)
    if not tool or not tool.Parent then
        return false
    end

    if tool.Parent == Backpack then
        return true
    end

    local character = plr.Character
    if character and tool.Parent == character then
        pcall(function()
            tool.Parent = Backpack
        end)
        task.wait(0.1)
    end

    return tool.Parent == Backpack
end

local function StoreFruit(tool)
    if not getgenv().AutoStoreFruit or not tool or storingTools[tool] then
        return false
    end

    local originalName = getFruitOriginalName(tool)
    if not originalName then
        return false
    end

    if not moveToolToBackpack(tool) then
        return false
    end

    storingTools[tool] = true
    local stored = false
    local resultText = nil

    for _ = 1, 5 do
        if not getgenv().AutoStoreFruit or not tool.Parent then
            break
        end

        local ok, result = pcall(function()
            return CommF_:InvokeServer("StoreFruit", originalName, tool)
        end)

        resultText = result
        if ok and result ~= false then
            stored = true
            lastStoredAt = tick()
            lastStoreResult = result
            task.wait(0.25)

            if tool.Parent ~= Backpack then
                break
            end
        end

        task.wait(0.25)
    end

    storingTools[tool] = nil
    warn("[AutoStoreFruit]", tostring(originalName), "stored=", tostring(stored), "result=", tostring(resultText))
    return stored, resultText
end

local function StoreAllFruits()
    if not getgenv().AutoStoreFruit then
        return false, 0, "disabled"
    end

    local tools = {}

    for _, tool in ipairs(Backpack:GetChildren()) do
        table.insert(tools, tool)
    end

    local character = plr.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(tools, tool)
            end
        end
    end

    local storedAny = false
    local storedCount = 0
    local lastResult = nil

    for _, tool in ipairs(tools) do
        if getFruitOriginalName(tool) then
            local ok, result = StoreFruit(tool)
            lastResult = result
            if ok then
                storedAny = true
                storedCount += 1
            end
        end
        task.wait(0.1)
    end

    return storedAny, storedCount, lastResult
end

getgenv().StoreFruit = StoreFruit
getgenv().StoreAllFruits = StoreAllFruits

local function handleNewTool(tool)
    task.spawn(function()
        if getgenv().AutoCloseSpinner then
            CloseSpinnerWindow(3)
        end

        task.wait(0.2)

        for _ = 1, 20 do
            if not tool or not tool.Parent then
                break
            end

            if getFruitOriginalName(tool) then
                StoreFruit(tool)
                break
            end

            task.wait(0.15)
        end
    end)
end

Backpack.ChildAdded:Connect(handleNewTool)

local function connectAutoStoreCharacter(character)
    character.ChildAdded:Connect(function(tool)
        if tool:IsA("Tool") then
            handleNewTool(tool)
        end
    end)
end

if plr.Character then
    connectAutoStoreCharacter(plr.Character)
end

plr.CharacterAdded:Connect(connectAutoStoreCharacter)

task.spawn(function()
    while task.wait(getgenv().StoreFruitInterval) do
        if getgenv().AutoStoreFruit then
            pcall(StoreAllFruits)
        end
    end
end)

task.spawn(function()
    CloseSpinnerWindow(3)
    StoreAllFruits()
end)

local function randomFruit()
    local beforeStoreAt = lastStoredAt
    local beforeTools = {}

    for _, container in ipairs({Backpack, plr.Character}) do
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                if obj:IsA("Tool") then
                    beforeTools[obj] = true
                end
            end
        end
    end

    warn("[RandomFruit] Sending Cousin Buy...")
    local ok, res = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Cousin","Buy")
    end)

    if not ok or res == false then
        warn("[RandomFruit] BUY FAILED:", tostring(res))
        return false, res, 0, nil
    end

    warn("[RandomFruit] BUY OK:", tostring(res))

    local newFruitTool = nil
    local waitToolStarted = tick()
    repeat
        for _, container in ipairs({Backpack, plr.Character}) do
            if container then
                for _, obj in ipairs(container:GetChildren()) do
                    if obj:IsA("Tool") and not beforeTools[obj] and obj:FindFirstChild("EatRemote", true) then
                        newFruitTool = obj
                        break
                    end
                end
            end
            if newFruitTool then break end
        end
        if not newFruitTool then task.wait(0.1) end
    until newFruitTool or (tick() - waitToolStarted) >= 4

    CloseSpinnerWindow(5)
    task.wait(0.35)

    local startedAt = tick()
    local storedCount = 0
    local storeResult = nil

    repeat
        CloseSpinnerWindow(1)

        if newFruitTool and newFruitTool.Parent then
            local stored, result = StoreFruit(newFruitTool)
            storeResult = result or storeResult
            if stored then
                storedCount = 1
            end
        end

        if storedCount <= 0 then
            local storedAny, count, result = StoreAllFruits()
            storeResult = result or storeResult
            if storedAny then
                storedCount = math.max(storedCount, tonumber(count) or 1)
            end
        end

        if storedCount > 0 or lastStoredAt > beforeStoreAt then
            if storedCount <= 0 then storedCount = 1 end
            storeResult = storeResult or lastStoreResult
            break
        end

        task.wait(0.2)
    until tick() - startedAt >= 12

    if storedCount > 0 or lastStoredAt > beforeStoreAt then
        warn("[RandomFruit] BUY + STORE OK | count=", storedCount, "result=", tostring(storeResult))
        return true, res, storedCount, storeResult
    end

    warn("[RandomFruit] BUY OK but STORE pending/timeout | result=", tostring(storeResult))
    return true, res, 0, storeResult or "store pending"
end

local function NormalizeName(str)
    return normalizeFruitKey(str)
end

local function GetItemName(itemId)
    local ok, data = pcall(function()
        return ItemConfig.match(itemId):unwrap()
    end)

    if not ok or not data then
        return "Unknown"
    end

    return data.Display.Title
        or data.Display.Name
        or data.Index.DebugLabel
        or data.Index.StorageKey
        or tostring(itemId)
end

local function AddFruit(FruitName)
    local okInv, tradeInv = pcall(function()
        return CommF_:InvokeServer("getTradeInventory")
    end)

    if not okInv or not tradeInv then
        warn("[AddFruit] Không lấy được trade inventory:", tradeInv)
        return false, "no trade inventory"
    end

    local items = tradeInv.Items or tradeInv
    if not items then
        warn("[AddFruit] Không có tradeInv.Items")
        return false, "no items"
    end

    local targetKeys = fruitKeySet(FruitName)
    if not next(targetKeys) then
        return false, "empty fruit name"
    end

    for _, item in pairs(items) do
        if type(item) == "table" and item.ItemId then
            local amount = tonumber(item.Amount or item.amount or 1) or 1
            if amount > 0 then
                local realName = GetItemName(item.ItemId)
                local itemKeys = fruitKeySet(
                    realName,
                    item.ItemId,
                    item.Name,
                    item.name,
                    item.DisplayName,
                    item.displayName,
                    item.Fruit,
                    item.fruit
                )
                local matchedKey = fruitKeySetsMatch(targetKeys, itemKeys)

                print("[AddFruit] Check:", realName, "| ItemId:", item.ItemId, "| Amount:", item.Amount, "| targetKeys:", fruitKeysToString(targetKeys), "| itemKeys:", fruitKeysToString(itemKeys), "| match:", tostring(matchedKey or "no"))

                if matchedKey then
                    local okAdd, result = pcall(function()
                        return TradeFunction:InvokeServer("addItem", item.ItemId, 1)
                    end)

                    if okAdd and result ~= false then
                        warn("[AddFruit] Added:", realName, "| ItemId:", item.ItemId, "| MatchKey:", tostring(matchedKey), "| Result:", result)
                        return true, result
                    end

                    warn("[AddFruit] Add failed:", realName, "| ItemId:", item.ItemId, "| Result:", result)
                    return false, result
                end
            end
        end
    end

    warn("[AddFruit] Không tìm thấy fruit:", FruitName, "| targetKeys:", fruitKeysToString(targetKeys))
    return false, "fruit not found: " .. tostring(FruitName) .. " | keys=" .. fruitKeysToString(targetKeys)
end

local function getTradeGui()
    local pg = plr:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    return main and main:FindFirstChild("Trade")
end

local function isTradeGuiVisible()
    local tradeGui = getTradeGui()
    return tradeGui and tradeGui.Visible == true
end

local function waitTradeGui(timeoutSec)
    local started = tick()
    while (tick() - started) < (timeoutSec or 45) do
        if isTradeGuiVisible() then
            return true
        end
        task.wait(0.25)
    end
    return false
end

local function acceptTrade(repeatCount)
    local okAny = false
    for i = 1, (repeatCount or 2) do
        local ok, res = pcall(function()
            return TradeFunction:InvokeServer("accept")
        end)
        if ok then
            okAny = true
            warn("[Trade] Accept sent:", tostring(res))
        else
            warn("[Trade] Accept failed:", tostring(res))
        end
        task.wait(0.45)
    end
    return okAny
end

local function addGiveFruitsAndAccept(job)
    local give = job and job.give or {}
    if type(give) ~= "table" or #give == 0 then
        return true, "no give fruit"
    end

    if not waitTradeGui(45) then
        return false, "timeout waiting trade gui"
    end

    for _, fruitName in ipairs(give) do
        local added = false
        local lastErr = nil

        for attempt = 1, 6 do
            local ok, res = AddFruit(fruitName)
            lastErr = res
            if ok then
                added = true
                break
            end
            task.wait(0.75)
        end

        if not added then
            return false, "cannot add " .. tostring(fruitName) .. ": " .. tostring(lastErr)
        end

        task.wait(0.5)
    end

    task.wait(1.5)
    acceptTrade(3)
    return true, "added fruits and accepted"
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

    if tool and tool:IsA("Tool") then
        pcall(function() humanoid:EquipTool(tool) end)
        return tool
    end
    return nil
end

local function dropToolFruitByName(name)
    local char = plr.Character or plr.CharacterAdded:Wait()

    EquipWeapon(name)
    task.wait(0.1)
    hideDialogueIfAny()
    EquipWeapon(name)
    task.wait(0.05)

    local toolInChar = char:FindFirstChild(name)
    if not toolInChar then return false end

    local eatRemote = toolInChar:FindFirstChild("EatRemote")
    if not eatRemote then return false end

    local ok = pcall(function()
        if eatRemote:IsA("RemoteFunction") then
            eatRemote:InvokeServer("Drop")
        elseif eatRemote:IsA("RemoteEvent") then
            eatRemote:FireServer("Drop")
        else
            error("EatRemote is not RemoteFunction/RemoteEvent")
        end
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
                pcall(function()
                    handle.CFrame = hrp.CFrame
                end)
                moved += 1
            end
        end
    end
    return moved
end

local function hasGreenDojoBelt()
    local inv = getInventory()
    for _, item in pairs(inv) do
        if item and item.Name == "Dojo Belt (Green)" then
            return true
        end
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
pcall(function()
    local old = pg:FindFirstChild("DojoSeatHubGUI")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "DojoSeatHubGUI"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 280, 0, 380)
frame.Position = UDim2.new(0, 20, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local titleBar = Instance.new("Frame")
titleBar.Parent = frame
titleBar.Size = UDim2.new(1, 0, 0, 52)
titleBar.BackgroundTransparency = 1
titleBar.Active = true

local title = Instance.new("TextLabel")
title.Parent = titleBar
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 12, 0, 0)
title.Size = UDim2.new(1, -120, 1, 0)
title.Text = "Auto Dojo + Web Trade"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = titleBar
toggleBtn.Size = UDim2.new(0, 34, 0, 28)
toggleBtn.Position = UDim2.new(1, -42, 0, 12)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
toggleBtn.BorderSizePixel = 0
toggleBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.Text = "–"
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Parent = frame
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 12, 0, 48)
status.Size = UDim2.new(1, -24, 0, 18)
status.Text = "Auto: chuẩn bị RequestQuest..."
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextXAlignment = Enum.TextXAlignment.Left

local tabBar = Instance.new("Frame")
tabBar.Parent = frame
tabBar.BackgroundTransparency = 1
tabBar.Position = UDim2.new(0, 12, 0, 72)
tabBar.Size = UDim2.new(1, -24, 0, 34)

local function makeTab(text, xScale, wScale)
    local b = Instance.new("TextButton")
    b.Parent = tabBar
    b.Size = UDim2.new(wScale, -6, 1, 0)
    b.Position = UDim2.new(xScale, 0, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    b.BorderSizePixel = 0
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(235, 235, 235)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    return b
end


local tabDrop  = makeTab("Drop", 0/3, 1/3)
local tabTrade = makeTab("Trade", 1/3, 1/3)
local tabFruit = makeTab("Fruit", 2/3, 1/3)

local content = Instance.new("Frame")
content.Parent = frame
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, 110)
content.Size = UDim2.new(1, 0, 1, -110)

local dojoPage = Instance.new("Frame")
dojoPage.Parent = content
dojoPage.BackgroundTransparency = 1
dojoPage.Size = UDim2.new(1, 0, 1, 0)

local seatsPage = Instance.new("Frame")
seatsPage.Parent = content
seatsPage.BackgroundTransparency = 1
seatsPage.Size = UDim2.new(1, 0, 1, 0)
seatsPage.Visible = false

local fruitPage = Instance.new("Frame")
fruitPage.Parent = content
fruitPage.BackgroundTransparency = 1
fruitPage.Size = UDim2.new(1, 0, 1, 0)
fruitPage.Visible = false

local currentTab = "Drop"
local function setActiveTab(tabName)
    currentTab = tabName

    dojoPage.Visible  = (tabName == "Drop")
    seatsPage.Visible = (tabName == "Trade")
    fruitPage.Visible = (tabName == "Fruit")

    tabDrop.BackgroundColor3  = (tabName == "Drop")  and Color3.fromRGB(55, 55, 55) or Color3.fromRGB(35, 35, 35)
    tabTrade.BackgroundColor3 = (tabName == "Trade") and Color3.fromRGB(55, 55, 55) or Color3.fromRGB(35, 35, 35)
    tabFruit.BackgroundColor3 = (tabName == "Fruit") and Color3.fromRGB(55, 55, 55) or Color3.fromRGB(35, 35, 35)
end

tabDrop.MouseButton1Click:Connect(function() setActiveTab("Drop") end)
tabTrade.MouseButton1Click:Connect(function() setActiveTab("Trade") end)
tabFruit.MouseButton1Click:Connect(function() setActiveTab("Fruit") end)


do
    local dragging = false
    local dragStartPos
    local startFramePos
    local dragInput

    local function update(input)
        local delta = input.Position - dragStartPos
        frame.Position = UDim2.new(
            startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
            startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
        )
    end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            startFramePos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)
end


local expandedSize = frame.Size
local collapsedSize = UDim2.new(0, 280, 0, 52)
local isCollapsed = false

local function setCollapsed(state)
    isCollapsed = state
    content.Visible = not state
    tabBar.Visible = not state
    status.Visible = not state
    toggleBtn.Text = state and "+" or "–"

    local goal = { Size = state and collapsedSize or expandedSize }
    TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

toggleBtn.MouseButton1Click:Connect(function()
    setCollapsed(not isCollapsed)
end)


local function makeBtn(parent, text, y)
    local b = Instance.new("TextButton")
    b.Parent = parent
    b.Size = UDim2.new(1, -24, 0, 44)
    b.Position = UDim2.new(0, 12, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    b.BorderSizePixel = 0
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(235, 235, 235)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
    return b
end


local btnClaim   = makeBtn(dojoPage, "CLAIM QUEST (GO DOJO)", 8)
local btnDrop    = makeBtn(dojoPage, "DROP FRUITS", 60)
local btnGo      = makeBtn(dojoPage, "GO TO COORD", 112)
local btnCollect = makeBtn(dojoPage, "COLLECT FRUITS", 164)
local btnRandom  = makeBtn(dojoPage, "RANDOM FRUIT", 216)

local busy = true
local initialAutoBusy = true
local function lockDojoButtons(isLocked)
    local v = not isLocked
    btnClaim.AutoButtonColor   = v
    btnDrop.AutoButtonColor    = v
    btnGo.AutoButtonColor      = v
    btnCollect.AutoButtonColor = v
    btnRandom.AutoButtonColor  = v
end


task.delay(150, function()
    if initialAutoBusy then
        warn("[AutoInit] Timeout, unlock busy so web/random can continue")
        initialAutoBusy = false
        busy = false
        lockDojoButtons(false)
        status.Text = "Auto init timeout -> đã mở khóa WEB/Random"
    end
end)


local y = 8
for i = 1, #SEATS do
    local seat = SEATS[i]
    local btn = Instance.new("TextButton")
    btn.Parent = seatsPage
    btn.Size = UDim2.new(1, -24, 0, 36)
    btn.Position = UDim2.new(0, 12, 0, y)
    btn.Text = seat.Name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        status.Text = "Seats: bay tới " .. seat.Name .. "..."
        toposition(seat.CFrame, function()
            status.Text = "Seats: tới " .. seat.Name .. "!"
        end)
    end)

    y = y + 42
end


local fruitTop = Instance.new("Frame")
fruitTop.Parent = fruitPage
fruitTop.BackgroundTransparency = 1
fruitTop.Position = UDim2.new(0, 12, 0, 8)
fruitTop.Size = UDim2.new(1, -24, 0, 36)

local fruitRefresh = Instance.new("TextButton")
fruitRefresh.Parent = fruitTop
fruitRefresh.Size = UDim2.new(1, 0, 1, 0)
fruitRefresh.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
fruitRefresh.BorderSizePixel = 0
fruitRefresh.Text = "REFRESH / CHECK FRUITS"
fruitRefresh.Font = Enum.Font.GothamBold
fruitRefresh.TextSize = 13
fruitRefresh.TextColor3 = Color3.fromRGB(235, 235, 235)
Instance.new("UICorner", fruitRefresh).CornerRadius = UDim.new(0, 12)

local fruitScroll = Instance.new("ScrollingFrame")
fruitScroll.Parent = fruitPage
fruitScroll.Position = UDim2.new(0, 12, 0, 52)
fruitScroll.Size = UDim2.new(1, -24, 1, -60)
fruitScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
fruitScroll.BorderSizePixel = 0
fruitScroll.ScrollBarThickness = 6
fruitScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", fruitScroll).CornerRadius = UDim.new(0, 12)

local fruitPad = Instance.new("UIPadding")
fruitPad.Parent = fruitScroll
fruitPad.PaddingTop = UDim.new(0, 10)
fruitPad.PaddingLeft = UDim.new(0, 10)
fruitPad.PaddingRight = UDim.new(0, 10)
fruitPad.PaddingBottom = UDim.new(0, 10)

local fruitLayout = Instance.new("UIListLayout")
fruitLayout.Parent = fruitScroll
fruitLayout.Padding = UDim.new(0, 8)
fruitLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function clearFruitButtons()
    for _, c in ipairs(fruitScroll:GetChildren()) do
        if c:IsA("TextButton") then
            c:Destroy()
        end
    end
end

local function makeFruitButton(fruitName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.BorderSizePixel = 0
    btn.Text = fruitName .. "  (Load + Reset)"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(235, 235, 235)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local debounce = false
    btn.MouseButton1Click:Connect(function()
        if debounce then return end
        debounce = true

        status.Text = "Fruit: Loading " .. fruitName .. "..."
        local ok, res = loadFruitThenReset(fruitName)

        if ok then
            status.Text = "Fruit: Loaded " .. fruitName .. " -> RESET"
        else
            status.Text = "Fruit: Load error: " .. tostring(res)
        end

        debounce = false
    end)

    return btn
end

local function renderFruitList()
    status.Text = "Fruit: checking inventory..."
    clearFruitButtons()

    local fruits = getFruitsFromInventory()
    if #fruits == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Parent = fruitScroll
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.Text = "Không có fruit trong inventory."
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

    else
        status.Text = "Fruit: Found " .. tostring(#fruits) .. " fruits. Click để Load + Reset."
        for _, name in ipairs(fruits) do
            makeFruitButton(name).Parent = fruitScroll
        end
    end

    task.wait()
    fruitScroll.CanvasSize = UDim2.new(0, 0, 0, fruitLayout.AbsoluteContentSize.Y + 20)
end

fruitRefresh.MouseButton1Click:Connect(renderFruitList)

task.spawn(function()
    lockDojoButtons(true)
    status.Text = "Auto: bay lên Dojo..."

    toposition(DOJO_POS, function()
        task.wait(0.25)

        status.Text = "Auto: RequestQuest..."
        local ok = select(1, requestQuest())

        if ok then
            if hasGreenDojoBelt() then
                status.Text = "Auto: Có Green Belt -> không cần teleport!"
                lockDojoButtons(false)
                initialAutoBusy = false
                busy = false
                return
            end

            status.Text = "Auto: RequestQuest OK -> Tele tới vị trí..."
            task.wait(0.25)

            toposition(AFTER_QUEST_POS, function()
                status.Text = "Auto done: Đã tele tới vị trí sau quest! (Ready)"
                lockDojoButtons(false)
                initialAutoBusy = false
                busy = false
            end)
        else
            status.Text = "Auto: RequestQuest FAIL (xem warn/log)"
            lockDojoButtons(false)
            initialAutoBusy = false
            busy = false
        end
    end)
end)


btnClaim.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    lockDojoButtons(true)
    btnClaim.Text = "RUNNING..."
    status.Text = "Bay lên Dojo..."

    toposition(DOJO_POS, function()
        task.wait(0.25)
        status.Text = "ClaimQuest..."
        local ok = select(1, claimQuest())
        status.Text = ok and "ClaimQuest OK!" or "ClaimQuest FAIL (xem warn)"
        task.wait(0.8)

        btnClaim.Text = "CLAIM QUEST (GO DOJO)"
        lockDojoButtons(false)
        busy = false
    end)
end)

btnDrop.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    lockDojoButtons(true)
    btnDrop.Text = "DROPPING..."
    status.Text = "Dropping fruits..."

    local ok, res = pcall(function()
        return DropFruits()
    end)

    status.Text = ok and ("Dropped: " .. tostring(res)) or ("Drop error: " .. tostring(res))
    task.wait(0.8)

    btnDrop.Text = "DROP FRUITS"
    lockDojoButtons(false)
    busy = false
end)

btnGo.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    lockDojoButtons(true)
    btnGo.Text = "MOVING..."
    status.Text = "Bay tới tọa độ..."

    toposition(EXTRA_POS, function()
        status.Text = "Đã tới tọa độ!"
        task.wait(0.8)
        btnGo.Text = "GO TO COORD"
        lockDojoButtons(false)
        busy = false
    end)
end)

btnCollect.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    lockDojoButtons(true)
    btnCollect.Text = "COLLECTING..."
    status.Text = "Đang kéo fruit về người..."

    local ok, movedOrErr = pcall(function()
        return collectFruits(true)
    end)

    status.Text = ok and ("Collect done! Moved: " .. tostring(movedOrErr)) or ("Collect error: " .. tostring(movedOrErr))
    task.wait(0.8)

    btnCollect.Text = "COLLECT FRUITS"
    lockDojoButtons(false)
    busy = false
end)

btnRandom.MouseButton1Click:Connect(function()
    if busy then
        status.Text = "Random đang bị khóa vì script còn BUSY"
        warn("[RandomFruit] Button ignored because busy=true")
        return
    end
    busy = true
    lockDojoButtons(true)
    btnRandom.Text = "ROLLING..."
    status.Text = "Random fruit (Cousin Buy)..."

    local ok, res, stored = randomFruit()
    status.Text = ok and ("Random OK! Stored: " .. tostring(stored or 0)) or ("Random FAIL: " .. tostring(res))

    task.wait(0.8)
    btnRandom.Text = "RANDOM FRUIT"
    lockDojoButtons(false)
    busy = false
end)


task.spawn(function()
    while task.wait(0.5) do
        if screenHasTradeText() and (tick() - lastTrigger) > COOLDOWN then
            lastTrigger = tick()
            warn("[DETECT] Trade completed -> ClaimQuest")
            status.Text = "Detect: Trade completed -> đi Dojo ClaimQuest..."

            task.wait(1.2)
            toposition(DOJO_POS, function()
                task.wait(0.2)
                claimQuest()
                status.Text = "Detect: ClaimQuest xong (xem warn/log)."
            end)
        end
    end
end)


UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
    end
end)


setActiveTab("Drop")
renderFruitList()

local HttpService = game:GetService("HttpService")
local WEB_BASE_URL = tostring(Config.WEB_BASE_URL or ""):gsub("/+$", "")
local WEB_ACCOUNT_ID = tostring(Config.ACCOUNT_ID or (plr.Name .. "_" .. tostring(plr.UserId)))
local WEB_POLL_INTERVAL = tonumber(Config.POLL_INTERVAL) or 3
local WEB_FAIL_WAIT = tonumber(Config.FAIL_WAIT) or math.max(WEB_POLL_INTERVAL, 5)
local WEB_RETRY = tonumber(Config.HEARTBEAT_RETRY) or 3
local WEB_TRADE_TIMEOUT = tonumber(Config.TRADE_TIMEOUT) or 180
local WEB_PAIR_READY_TIMEOUT = tonumber(Config.PAIR_READY_TIMEOUT) or 600
local WEB_ENABLED = (Config.AUTO_WEB ~= false)
local webStatus = "idle"
local webBusy = false

local requestFunc = (syn and syn.request) or http_request or request

local function webSetStatus(txt)
    pcall(function()
        status.Text = txt
    end)
end

local function joinArray(arr)
    if type(arr) ~= "table" then return "" end
    local t = {}
    for _, v in ipairs(arr) do table.insert(t, tostring(v)) end
    return table.concat(t, ", ")
end

local function routeToDirectApi(path)
    local clean, query = string.match(path, "^([^?]+)(.*)$")
    query = query or ""

    if clean == "/heartbeat" then
        return "/api/heartbeat.php" .. query
    elseif clean == "/get-job" then
        return "/api/get-job.php" .. query
    elseif clean == "/job-status" then
        return "/api/job-status.php" .. query
    elseif clean == "/state" then
        return "/api/state.php" .. query
    end

    return path
end

local function rawRequestJson(method, path, data)
    local req = {
        Url = WEB_BASE_URL .. path,
        Method = method,
        Headers = { ["Content-Type"] = "application/json" }
    }
    if data ~= nil then
        req.Body = HttpService:JSONEncode(data)
    end

    local ok, res = pcall(function()
        return requestFunc(req)
    end)
    if not ok then return nil, tostring(res) end

    local statusCode = res.StatusCode or res.statusCode or res.Status or res.status or 0
    local body = res.Body or res.body or ""
    if body == "" then
        return nil, "Empty response | HTTP " .. tostring(statusCode) .. " | URL " .. tostring(req.Url)
    end

    local okDecode, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not okDecode then
        local bodyShort = tostring(body)
        if #bodyShort > 300 then bodyShort = string.sub(bodyShort, 1, 300) .. "..." end
        return nil, "JSON decode lỗi | HTTP " .. tostring(statusCode) .. " | URL " .. tostring(req.Url) .. " | body=" .. bodyShort
    end
    return decoded, nil
end

local function requestJson(method, path, data)
    if not requestFunc then
        return nil, "Executor không hỗ trợ request/http_request"
    end

    local lastErr = nil
    local apiPath = routeToDirectApi(path)

    for attempt = 1, WEB_RETRY do
        local decoded, err = rawRequestJson(method, path, data)
        if decoded then return decoded, nil end
        lastErr = tostring(err)

        if apiPath ~= path then
            local decoded2, err2 = rawRequestJson(method, apiPath, data)
            if decoded2 then return decoded2, nil end
            lastErr = lastErr .. " | fallback: " .. tostring(err2)
        end

        task.wait(0.45 + (attempt * 0.35))
    end

    return nil, lastErr
end

local function postJson(path, data)
    return requestJson("POST", path, data)
end

local function getJson(path)
    return requestJson("GET", path, nil)
end

local function isNearAfterQuestPosition(maxDist)
    local ok, dist = pcall(function()
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return math.huge end
        return (hrp.Position - AFTER_QUEST_POS.Position).Magnitude
    end)
    return ok and dist <= (maxDist or 25)
end

local function sendHeartbeat()
    local fruits = getFruitsFromInventory()
    return postJson("/heartbeat", {
        accountId = WEB_ACCOUNT_ID,
        serverJobId = tostring(game.JobId or ""),
        placeId = tostring(game.PlaceId or ""),
        fruits = fruits,
        status = webStatus,
        atAfterQuest = isNearAfterQuestPosition(25)
    })
end

local function updateJobStatus(job, newStatus, message)
    webStatus = (newStatus == "done" or newStatus == "failed" or newStatus == "cancelled") and "idle" or newStatus
    return postJson("/job-status", {
        accountId = WEB_ACCOUNT_ID,
        jobId = tostring(job.jobId),
        status = newStatus,
        message = tostring(message or "")
    })
end

local function moveToCFrameWait(cf, timeoutSec)
    local done = false
    local started = tick()
    local ok = pcall(function()
        toposition(cf, function()
            done = true
        end)
    end)
    if not ok then return false end
    local nextHb = tick() + 8
    while not done and (tick() - started) < (timeoutSec or 120) do
        if tick() >= nextHb then
            pcall(function() sendHeartbeat() end)
            nextHb = tick() + 8
        end
        task.wait(0.2)
    end
    return done
end

local function getCharHumHrp()
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
    return char, hum, hrp
end

local function horizontalDist(a, b)
    return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
end

local function findSeatForIndex(seatIndex, targetCF)
    local targetPos = targetCF.Position
    local best, bestDist = nil, 999999
    local maxHorizontalDist = 7.0
    local maxYDiff = 8.0

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Seat") then
            local dx = math.abs(obj.Position.X - targetPos.X)
            local dz = math.abs(obj.Position.Z - targetPos.Z)
            local dy = math.abs(obj.Position.Y - targetPos.Y)
            local hd = horizontalDist(obj.Position, targetPos)

            if hd <= maxHorizontalDist and dy <= maxYDiff and dx <= maxHorizontalDist and dz <= maxHorizontalDist then
                if hd < bestDist then
                    best = obj
                    bestDist = hd
                end
            end
        end
    end

    return best, bestDist
end

local function clearSeatState()
    pcall(function()
        local char, hum, hrp = getCharHumHrp()
        if hum then
            hum.Sit = false
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 5, 0)
        end
    end)
    task.wait(0.35)
end

local function forceSitOnSeatPart(seatPart, fallbackCF)
    local char, hum, hrp = getCharHumHrp()
    if not hum or not hrp then
        return false, "missing humanoid/hrp"
    end

    local targetCF = (seatPart and seatPart.CFrame) or fallbackCF

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        char:PivotTo(targetCF * CFrame.new(0, 2.35, 0))
    end)
    task.wait(0.12)

    if seatPart and seatPart:IsA("Seat") then
        pcall(function()
            seatPart:Sit(hum)
        end)
    end

    task.wait(0.18)
    pcall(function()
        hum.Sit = true
    end)

    return true, "sit sent"
end

local function sitAtSeat(seatIndex)
    local seat = SEATS[seatIndex]
    if not seat then return false, "Seat không hợp lệ: " .. tostring(seatIndex) end

    local fixedTargetCF = seat.CFrame
    local seatPart, seatDist = findSeatForIndex(seatIndex, fixedTargetCF)
    local seatInfo = seatPart and (seatPart:GetFullName() .. " | hd=" .. string.format("%.2f", seatDist or 0)) or "không tìm thấy Seat sát tọa độ, dùng CFrame cố định"

    warn("[SeatFixV2] Target seatIndex=", tostring(seatIndex), seat.Name, "fixedPos=", tostring(fixedTargetCF.Position), "->", seatInfo)
    webSetStatus("WEB Trade: tới " .. seat.Name .. " | seatIndex=" .. tostring(seatIndex))

    for attempt = 1, 7 do
        clearSeatState()

        local okMove = moveToCFrameWait(fixedTargetCF * CFrame.new(0, 3.25, 0), 90)
        if not okMove then
            warn("[SeatFixV2] move timeout attempt", attempt, seat.Name)
        end

        seatPart, seatDist = findSeatForIndex(seatIndex, fixedTargetCF)
        if seatPart then
            warn("[SeatFixV2] using real Seat:", seatPart:GetFullName(), "hd=", string.format("%.2f", seatDist or 0))
        else
            warn("[SeatFixV2] no real Seat near", seat.Name, "-> fallback fixed CFrame only")
        end

        local okSit, sitMsg = forceSitOnSeatPart(seatPart, fixedTargetCF)
        if not okSit then
            warn("[SeatFixV2] sit failed:", sitMsg)
        end

        local startWait = tick()
        while (tick() - startWait) < 8 do
            if isTradeGuiVisible() then
                warn("[SeatFixV2] Trade GUI opened at", seat.Name, "attempt", attempt)
                return true, seat.Name .. " | trade gui opened"
            end

            local _, hum = getCharHumHrp()
            if hum and hum.SeatPart ~= nil then
                webSetStatus("WEB Trade: đã ngồi " .. seat.Name .. " | chờ bảng trade...")
            else
                webSetStatus("WEB Trade: ở đúng " .. seat.Name .. " | chưa sit, thử lại...")
            end

            task.wait(0.25)
        end

        warn("[SeatFixV2] chưa mở trade gui, nhảy lên ngồi lại | attempt", attempt, seat.Name)
        webSetStatus("WEB Trade: chưa mở bảng, ngồi lại " .. tostring(attempt) .. "/7 tại " .. seat.Name)
    end

    return false, "Đã thử ngồi lại 7 lần nhưng bảng trade chưa mở: " .. tostring(seat.Name)
end

local function waitTradeCompleted(timeoutSec)
    local started = tick()
    while (tick() - started) < (timeoutSec or WEB_TRADE_TIMEOUT) do
        if screenHasTradeText() then
            return true
        end
        task.wait(0.5)
    end
    return false
end

local function waitTradeSeatRelease(job, timeoutSec)
    local started = tick()
    local lastErr = nil
    local jobId = tostring(job and job.jobId or "")
    local nextHb = tick()

    while (tick() - started) < (timeoutSec or WEB_PAIR_READY_TIMEOUT) do
        if tick() >= nextHb then
            pcall(function() sendHeartbeat() end)
            nextHb = tick() + 5
        end
        local latest, err = getJson("/get-job?accountId=" .. HttpService:UrlEncode(WEB_ACCOUNT_ID))
        if latest and latest.ok and tostring(latest.jobId or "") == jobId then
            local st = tostring(latest.status or "")
            if latest.canSit == true and tonumber(latest.seat) then
                return latest, "released"
            end
            if st == "failed" or st == "cancelled" or st == "error" then
                return nil, "job " .. st
            end
            webSetStatus("WEB Trade: đã tới AFTER_QUEST_POS | chờ partner/ghế | " .. st)
        elseif latest and latest.ok and latest.status == "idle" then
            return nil, "server trả idle, job không còn active"
        elseif err then
            lastErr = tostring(err)
            warn("[WEB TRADE] wait seat release get-job error:", lastErr)
        end
        task.wait(1)
    end

    return nil, "timeout chờ partner/ghế sau AFTER_QUEST_POS" .. (lastErr and (" | " .. lastErr) or "")
end

local function handleDeleteFruitJob(job)
    webBusy = true
    busy = true
    lockDojoButtons(true)

    local fruit = tostring(job.fruit or "")
    webSetStatus("WEB Action: delete/load+reset " .. fruit)
    updateJobStatus(job, "moving", "delete fruit " .. fruit)

    local ok, res = false, nil
    if fruit ~= "" then
        ok, res = loadFruitThenReset(fruit)
    end

    if ok then
        updateJobStatus(job, "done", "deleted/load+reset " .. fruit)
        webSetStatus("WEB Action done: " .. fruit)
    else
        updateJobStatus(job, "failed", "delete failed: " .. tostring(res))
        webSetStatus("WEB Action failed: " .. tostring(res))
    end

    task.wait(1)
    lockDojoButtons(false)
    busy = false
    webBusy = false
end

local function handleRandomFruitJob(job)
    webBusy = true
    busy = true
    lockDojoButtons(true)

    webSetStatus("WEB Action: random fruit...")
    updateJobStatus(job, "moving", "random fruit")
    local ok, res, stored, storeRes = randomFruit()

    if ok then
        updateJobStatus(job, "done", "random buy ok, stored=" .. tostring(stored or 0) .. " | store=" .. tostring(storeRes))
        if (tonumber(stored) or 0) > 0 then
            webSetStatus("WEB Action done: random + store OK | stored=" .. tostring(stored))
        else
            webSetStatus("WEB Action done: random OK | store đang chờ")
        end
    else
        updateJobStatus(job, "failed", "random buy failed: " .. tostring(res) .. " | store=" .. tostring(storeRes))
        webSetStatus("WEB Action failed: " .. tostring(res))
    end

    task.wait(1)
    lockDojoButtons(false)
    busy = false
    webBusy = false
end

local function handleTradeJob(job)
    webBusy = true
    busy = true
    lockDojoButtons(true)

    local function unlockAndReturn()
        lockDojoButtons(false)
        busy = false
        webBusy = false
    end

    local pairLabel = tostring(job.pairLabel or job.partner or "")
    local waveId = tostring(job.waveId or "")
    local pairIndex = tostring(job.pairIndex or "?")
    local pairCount = tostring(job.pairCount or "3")

    webSetStatus("WEB Trade: nhận job wave " .. waveId .. " pair " .. pairIndex .. "/" .. pairCount)
    warn("[WEB TRADE] job=", tostring(job.jobId), "wave=", waveId, "pair=", pairIndex .. "/" .. pairCount, "seat=", tostring(job.seat), "canSit=", tostring(job.canSit), "pairLabel=", pairLabel)
    warn("[WEB TRADE] GIVE:", joinArray(job.give or {}), "| RECEIVE:", joinArray(job.receive or {}))

    if job.requireAfterQuestReady ~= false then
        updateJobStatus(job, "waiting_after_quest", "moving to AFTER_QUEST_POS before seat")
        webSetStatus("WEB Trade: bay tới AFTER_QUEST_POS trước khi ngồi ghế...")

        local okAfter = moveToCFrameWait(AFTER_QUEST_POS, 140)
        if not okAfter then
            updateJobStatus(job, "failed", "timeout moving to AFTER_QUEST_POS")
            webSetStatus("WEB Trade failed: không tới được AFTER_QUEST_POS")
            unlockAndReturn()
            return
        end

        local res = updateJobStatus(job, "after_quest_ready", "arrived AFTER_QUEST_POS, waiting partner/seat")
        if res and res.job and tostring(res.job.jobId or "") == tostring(job.jobId or "") then
            job = res.job
        end

        if not (job.canSit == true and tonumber(job.seat)) then
            local latest, waitMsg = waitTradeSeatRelease(job, WEB_PAIR_READY_TIMEOUT)
            if not latest then
                updateJobStatus(job, "failed", tostring(waitMsg))
                webSetStatus("WEB Trade failed: " .. tostring(waitMsg))
                unlockAndReturn()
                return
            end
            job = latest
        end
    end

    local seatIndex = tonumber(job.seat)
    if not seatIndex then
        updateJobStatus(job, "failed", "server chưa cấp seat/canSit")
        webSetStatus("WEB Trade failed: server chưa cấp seat/canSit")
        unlockAndReturn()
        return
    end

    updateJobStatus(job, "moving", "moving from AFTER_QUEST_POS to seat " .. tostring(seatIndex))
    local okSeat, seatMsg = sitAtSeat(seatIndex)
    if not okSeat then
        updateJobStatus(job, "failed", seatMsg)
        webSetStatus("WEB Trade failed: " .. tostring(seatMsg))
        unlockAndReturn()
        return
    end

    updateJobStatus(job, "trading", "at " .. tostring(seatMsg) .. ", adding fruits")
    webSetStatus("WEB Trade: " .. tostring(seatMsg) .. " | Add: " .. joinArray(job.give or {}))

    local okAdd, addMsg = addGiveFruitsAndAccept(job)
    if not okAdd then
        updateJobStatus(job, "failed", tostring(addMsg))
        webSetStatus("WEB Trade failed: " .. tostring(addMsg))
        unlockAndReturn()
        return
    end

    updateJobStatus(job, "trading", "added fruits + accepted, waiting trade completed")
    webSetStatus("WEB Trade: đã add fruit + accept | chờ completed...")

    local completed = waitTradeCompleted(WEB_TRADE_TIMEOUT)
    if completed then
        lastTrigger = tick()
        updateJobStatus(job, "done", "trade completed detected")
        webSetStatus("WEB Trade done -> account này sẽ bị khóa trade lại")
        task.wait(1)
        pcall(function()
            toposition(DOJO_POS, function()
                task.wait(0.2)
                claimQuest()
                webSetStatus("WEB Trade done + ClaimQuest xong")
            end)
        end)
    else
        updateJobStatus(job, "failed", "timeout waiting trade completed")
        webSetStatus("WEB Trade timeout: chưa thấy Trade completed")
    end

    task.wait(1)
    unlockAndReturn()
end

local function handleWebJob(job)
    if not job or not job.jobId then return end
    local kind = tostring(job.kind or job.action or "")
    if kind == "delete_fruit" then
        handleDeleteFruitJob(job)
    elseif kind == "random_fruit" then
        handleRandomFruitJob(job)
    elseif kind == "trade" then
        handleTradeJob(job)
    end
end

if WEB_ENABLED then
    task.spawn(function()

        local stagger = 0.2 + ((tonumber(plr.UserId) or 0) % 10) / 10 + (math.random(1, 20) / 100)
        task.wait(stagger)
        if WEB_BASE_URL == "" then
            webSetStatus("WEB off: thiếu WEB_BASE_URL")
            return
        end
        if not requestFunc then
            webSetStatus("WEB off: executor không hỗ trợ request/http_request")
            warn("[WEB] Executor không hỗ trợ request/http_request")
            return
        end

        warn("[WEB] Auto poll enabled | account=", WEB_ACCOUNT_ID, "base=", WEB_BASE_URL)
        webSetStatus("WEB starting | acc=" .. WEB_ACCOUNT_ID .. " | base=" .. WEB_BASE_URL)

        local hbOkCount = 0
        local hbFailCount = 0

        while true do
            local loopWait = WEB_POLL_INTERVAL + (math.random(0, 40) / 100)
            local hb, hbErr = sendHeartbeat()

            if not hb then
                hbFailCount += 1
                webSetStatus("WEB heartbeat lỗi x" .. tostring(hbFailCount) .. ": " .. tostring(hbErr))
                warn("[WEB] heartbeat error x" .. tostring(hbFailCount) .. ":", hbErr)
                task.wait(WEB_FAIL_WAIT + (math.random(0, 100) / 100))
            else
                hbOkCount += 1
                hbFailCount = 0
                if hbOkCount == 1 or hbOkCount % 10 == 0 then
                    warn("[WEB] heartbeat OK #" .. tostring(hbOkCount), "account=", tostring(hb.accountId or WEB_ACCOUNT_ID), "online=", tostring(hb.online), "job=", tostring(hb.job and hb.job.jobId or "nil"))
                end

                if not busy and not webBusy then
                    local job = hb.job
                    local err = nil

                    if not (job and job.jobId) then
                        job, err = getJson("/get-job?accountId=" .. HttpService:UrlEncode(WEB_ACCOUNT_ID))
                    end

                    if job and job.ok ~= false and job.jobId then
                        handleWebJob(job)
                    elseif err then
                        webSetStatus("WEB get-job lỗi: " .. tostring(err))
                        warn("[WEB] get-job error:", err)
                    else
                        webSetStatus("WEB OK | acc=" .. WEB_ACCOUNT_ID .. " | fruits=" .. tostring(#getFruitsFromInventory()) .. " | hb#" .. tostring(hbOkCount))
                    end
                else
                    webSetStatus("WEB OK | busy | acc=" .. WEB_ACCOUNT_ID .. " | hb#" .. tostring(hbOkCount))
                end

                task.wait(loopWait)
            end
        end
    end)
end
