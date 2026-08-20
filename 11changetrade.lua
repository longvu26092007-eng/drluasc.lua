-- ==========================================
-- SCRIPT CHECK DOJO BELT (YELLOW)
-- Đợi game load xong rồi mới khởi tạo check
-- ==========================================

-- ══ ĐỢI GAME LOAD XONG TRƯỚC ══
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer.Character
    and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- ══════════════════════════════════════════════════════════════════════════
-- INVENTORY SYSTEM MỚI (ItemReplicationService)
-- ══════════════════════════════════════════════════════════════════════════

local InvModules = {
    Inventory = nil,
    ItemConfig = nil,
    ItemService = nil,
    KEYS = nil,
    Ready = false
}

local InventoryCache = {}

-- Thread Identity Protection
local function RaiseIdentity(level)
    local fn = setthreadidentity or setidentity or set_thread_identity
    if fn then pcall(fn, level) end
end

local function RestoreIdentity()
    local fn = setthreadidentity or setidentity or set_thread_identity
    if fn then pcall(fn, 2) end
end

-- Load Inventory Modules
local function LoadInventoryModules()
    if InvModules.Ready then return true end

    local paths = {
        Inventory = "Controllers.UI.Inventory",
        ItemConfig = "ItemConfig",
        ItemService = "ItemReplicationService",
        KEYS = "ItemReplicationService.KEYS"
    }

    for name, path in pairs(paths) do
        local parts = {}
        for part in path:gmatch("[^.]+") do
            table.insert(parts, part)
        end

        local node = ReplicatedStorage
        for _, part in ipairs(parts) do
            node = node:FindFirstChild(part)
            if not node then
                warn("[YellowBelt] Không tìm thấy: " .. path)
                return false
            end
        end

        local ok, mod = pcall(function()
            RaiseIdentity(3)
            local result = require(node)
            RestoreIdentity()
            return result
        end)

        if not ok then
            warn("[YellowBelt] Require lỗi: " .. path)
            return false
        end

        InvModules[name] = mod
    end

    InvModules.Ready = true
    return true
end

-- Refresh Inventory
local function RefreshInventory()
    if not InvModules.Ready then
        if not LoadInventoryModules() then
            return false
        end
    end

    -- Đợi initialized
    for i = 1, 10 do
        local ok1, res1 = pcall(function() return InvModules.Inventory:GetIfInitialized() end)
        local ok2, res2 = pcall(function() return InvModules.ItemService.IsInitialized end)

        if ok1 and res1 == true and ok2 and res2 == true then
            break
        end

        if i == 10 then
            warn("[YellowBelt] Inventory chưa initialized")
            return false
        end

        task.wait(0.5)
    end

    -- Đọc inventory
    InventoryCache = {}

    local amounts = {}
    local okQty, qtyList = pcall(function()
        return InvModules.ItemService:GetItems(InvModules.KEYS.QUANTITY)
    end)

    if okQty and type(qtyList) == "table" then
        for _, item in pairs(qtyList) do
            if type(item) == "table" and item.ItemId then
                amounts[item.ItemId] = (amounts[item.ItemId] or 0) + (tonumber(item.Value) or 0)
            end
        end
    end

    local okTiles, tiles = pcall(function() return InvModules.Inventory:GetTiles() end)
    if not okTiles or type(tiles) ~= "table" then
        warn("[YellowBelt] GetTiles lỗi")
        return false
    end

    local seen = {}
    for _, tile in pairs(tiles) do
        local id = type(tile) == "table" and tile.ItemId or nil
        if id and not seen[id] then
            seen[id] = true

            local okCfg, config = pcall(function()
                return InvModules.ItemConfig.match(id):unwrap()
            end)

            if okCfg and type(config) == "table" and config.Display then
                local name = config.Display.Name
                    or (config.Index and config.Index.StorageKey)
                    or tostring(id)

                InventoryCache[tostring(name)] = {
                    Name = tostring(name),
                    Count = amounts[id] or 1,
                    ItemId = id
                }
            end
        end
    end

    return true
end

-- Check item trong cache
local function CheckItemInCache(itemName)
    return InventoryCache[itemName] ~= nil
end

-- Auto refresh khi có thay đổi
pcall(function()
    local ItemService = ReplicatedStorage:FindFirstChild("ItemReplicationService")
    if ItemService then
        local ItemAdded = ItemService:FindFirstChild("ItemAdded")
        local ItemRemoved = ItemService:FindFirstChild("ItemRemoved")

        if ItemAdded then
            ItemAdded.Event:Connect(function()
                task.delay(0.5, RefreshInventory)
            end)
        end

        if ItemRemoved then
            ItemRemoved.Event:Connect(function()
                task.delay(0.5, RefreshInventory)
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════════

-- ══ TẠO UI SAU KHI GAME ĐÃ LOAD ══
local function CreateMiniUI()
    local SafeGuiParent = pcall(function() return gethui() end) and gethui()
        or CoreGui:FindFirstChild("RobloxGui") or CoreGui

    if SafeGuiParent:FindFirstChild("YellowBeltStatusUI") then
        SafeGuiParent.YellowBeltStatusUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "YellowBeltStatusUI"
    ScreenGui.Parent = SafeGuiParent
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 220, 0, 50)
    MainFrame.Position = UDim2.new(1, -230, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Instance.new("UICorner", MainFrame)

    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(150, 150, 150)
    Stroke.Thickness = 1.5

    local StatusText = Instance.new("TextLabel", MainFrame)
    StatusText.Name = "StatusLabel"
    StatusText.Size = UDim2.new(1, 0, 1, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "🔍 Đang check Yellow Belt..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12
    StatusText.Parent = MainFrame

    return StatusText, MainFrame, Stroke
end

local StatusLabel, MainFrame, Stroke = CreateMiniUI()

-- ══ MARK FOUND ══
local function MarkFound(source)
    local fileName = Player.Name .. ".txt"
    pcall(function() writefile(fileName, "Completed-trade") end)
    StatusLabel.Text = "✅ ĐÃ CÓ YELLOW BELT! (" .. source .. ")"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    Stroke.Color = Color3.fromRGB(255, 215, 0)
    warn("[YellowBelt] Tìm thấy trong " .. source .. "! Ghi file: " .. fileName)
    return true
end

-- ══ CHECK LOGIC MỚI ══
local CheckAttempts = 0
local MaxRefreshAttempts = 3

local function CheckYellowBelt()
    -- CHECK 1: Character
    local chr = Player.Character
    if chr and chr:FindFirstChild("Dojo Belt (Yellow)") then
        return MarkFound("Character")
    end

    -- CHECK 2: Backpack
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild("Dojo Belt (Yellow)") then
        return MarkFound("Backpack")
    end

    -- CHECK 3: Inventory mới (ItemReplicationService)
    StatusLabel.Text = "🔍 Đang quét Inventory... (" .. (CheckAttempts + 1) .. ")"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    CheckAttempts = CheckAttempts + 1

    -- Chỉ refresh tối đa 3 lần mỗi vòng check
    if CheckAttempts <= MaxRefreshAttempts then
        local ok = RefreshInventory()

        if not ok then
            StatusLabel.Text = "⚠️ Đang load Inventory... (" .. CheckAttempts .. "/" .. MaxRefreshAttempts .. ")"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 160, 0)
            return false
        end
    end

    -- Check cache
    if CheckItemInCache("Dojo Belt (Yellow)") then
        return MarkFound("Inventory")
    end

    -- Reset counter sau khi check xong
    if CheckAttempts >= MaxRefreshAttempts then
        CheckAttempts = 0
        StatusLabel.Text = "❌ CHƯA CÓ YELLOW BELT"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    return false
end

-- ══ MAIN LOOP ══
warn("[YellowBelt] Game đã load — Bắt đầu check mỗi 15s.")

-- Đợi thêm 5s để inventory system load
task.wait(5)

while true do
    local ok, success = pcall(CheckYellowBelt)

    if ok and success then
        task.wait(5)
        pcall(function()
            if MainFrame and MainFrame.Parent then
                MainFrame.Parent:Destroy()
            end
        end)
        break
    end

    if not ok then
        warn("[YellowBelt] Lỗi check: " .. tostring(success))
    end

    task.wait(15)
end
