-- ==========================================
-- SCRIPT CHECK DOJO BELT (GREEN)
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

-- ══════════════════════════════════════════════════════════════════════════
-- INVENTORY SYSTEM - COPY Y HỆT changetrade.lua ĐÚNG
-- ══════════════════════════════════════════════════════════════════════════

-- Thread identity functions
local _setidentity = setthreadidentity or setidentity or set_thread_identity
local _getidentity = getthreadidentity or getidentity or get_thread_identity

local function RaiseIdentity()
    if not _setidentity then return nil end
    local prev
    if _getidentity then
        local ok, v = pcall(_getidentity)
        if ok then prev = v end
    end
    pcall(_setidentity, 8)
    return prev
end

local function RestoreIdentity(prev)
    if not _setidentity then return end
    pcall(_setidentity, prev or 8)
end

-- Require modules trực tiếp
local Inventory = require(ReplicatedStorage.Controllers.UI.Inventory)
local ItemConfig = require(ReplicatedStorage.ItemConfig)
local ItemService = require(ReplicatedStorage.ItemReplicationService)
local KEYS = require(ReplicatedStorage.ItemReplicationService.KEYS)

-- Check initialized
local function inventoryInitialized()
    local ok, ready = pcall(function()
        return Inventory:GetIfInitialized()
    end)
    return ok and ready and ItemService.IsInitialized == true
end

-- Check item có trong inventory không
local function HasItemInInventory(itemName)
    -- Đợi initialized (timeout 30s)
    local deadline = os.clock() + 30
    repeat
        task.wait(0.2)
    until inventoryInitialized() or os.clock() >= deadline

    if not inventoryInitialized() then
        warn("[BlueBelt] Timeout waiting for Inventory (30s)")
        return false
    end

    -- WRAP đọc inventory bằng RaiseIdentity
    local prev = RaiseIdentity()

    local found = false
    pcall(function()
        -- Lấy amounts
        local Amounts = {}
        for _, item in pairs(ItemService:GetItems(KEYS.QUANTITY) or {}) do
            Amounts[item.ItemId] = (Amounts[item.ItemId] or 0) + (tonumber(item.Value) or 0)
        end

        -- Check tiles
        local Checked = {}
        for _, tile in pairs(Inventory:GetTiles() or {}) do
            local id = tile.ItemId

            if id and not Checked[id] then
                Checked[id] = true

                local success, config = pcall(function()
                    return ItemConfig.match(id):unwrap()
                end)

                if success and config and config.Display then
                    local name = config.Display.Name
                        or config.Index.StorageKey
                        or tostring(id)

                    if name == itemName then
                        found = true
                    end
                end
            end
        end
    end)

    RestoreIdentity(prev)
    return found
end

-- ══════════════════════════════════════════════════════════════════════════

-- ══ TẠO UI SAU KHI GAME ĐÃ LOAD ══
local function CreateMiniUI()
    local SafeGuiParent = pcall(function() return gethui() end) and gethui()
        or CoreGui:FindFirstChild("RobloxGui") or CoreGui

    if SafeGuiParent:FindFirstChild("BlueBeltStatusUI") then
        SafeGuiParent.BlueBeltStatusUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BlueBeltStatusUI"
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
    StatusText.Text = "🔍 Đang check Blue Belt..."
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
    pcall(function() writefile(fileName, "Completed-blue") end)
    StatusLabel.Text = "✅ ĐÃ CÓ BLUE BELT! (" .. source .. ")"
    StatusLabel.TextColor3 = Color3.fromRGB(80, 150, 255)
    Stroke.Color = Color3.fromRGB(80, 150, 255)
    warn("[BlueBelt] Tìm thấy trong " .. source .. "! Ghi file: " .. fileName)
    return true
end

-- ══ CHECK LOGIC ══
local function CheckBlueBelt()
    -- CHECK 1: Character
    local chr = Player.Character
    if chr and chr:FindFirstChild("Dojo Belt (Blue)") then
        return MarkFound("Character")
    end

    -- CHECK 2: Backpack
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild("Dojo Belt (Blue)") then
        return MarkFound("Backpack")
    end

    -- CHECK 3: Inventory (NEW SYSTEM)
    StatusLabel.Text = "🔍 Đang quét Inventory..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    if HasItemInInventory("Dojo Belt (Blue)") then
        return MarkFound("Inventory")
    else
        StatusLabel.Text = "❌ CHƯA CÓ BLUE BELT"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    return false
end

-- ══ MAIN LOOP ══
warn("[BlueBelt] Game đã load — Bắt đầu check mỗi 15s.")

while true do
    local ok, success = pcall(CheckBlueBelt)

    if ok and success then
        task.wait(5)
        pcall(function()
            if MainFrame and MainFrame.Parent then
                MainFrame.Parent:Destroy()
            end
        end)
        break
    end

    task.wait(15)
end
