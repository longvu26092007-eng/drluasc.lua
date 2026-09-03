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
local TeleportService = game:GetService("TeleportService")

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
        warn("[GreenBelt] Timeout waiting for Inventory (30s)")
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

    if SafeGuiParent:FindFirstChild("GreenBeltStatusUI") then
        SafeGuiParent.GreenBeltStatusUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GreenBeltStatusUI"
    ScreenGui.Parent = SafeGuiParent
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 220, 0, 80)  -- Tăng chiều cao cho 2 dòng
    MainFrame.Position = UDim2.new(1, -230, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Instance.new("UICorner", MainFrame)

    local Stroke = Instance.new("UIStroke", MainFrame)
    Stroke.Color = Color3.fromRGB(150, 150, 150)
    Stroke.Thickness = 1.5

    local StatusText = Instance.new("TextLabel", MainFrame)
    StatusText.Name = "StatusLabel"
    StatusText.Size = UDim2.new(1, 0, 0.5, 0)
    StatusText.Position = UDim2.new(0, 0, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "🔍 Đang check Green Belt..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12
    StatusText.Parent = MainFrame

    -- ══ LABEL AFK ══
    local AfkText = Instance.new("TextLabel", MainFrame)
    AfkText.Name = "AfkLabel"
    AfkText.Size = UDim2.new(1, 0, 0.5, 0)
    AfkText.Position = UDim2.new(0, 0, 0.5, 0)
    AfkText.BackgroundTransparency = 1
    AfkText.Text = "🟢 Đang di chuyển"
    AfkText.TextColor3 = Color3.fromRGB(100, 255, 100)
    AfkText.Font = Enum.Font.GothamBold
    AfkText.TextSize = 11
    AfkText.Parent = MainFrame

    return StatusText, MainFrame, Stroke, AfkText
end

local StatusLabel, MainFrame, Stroke, AfkLabel = CreateMiniUI()

-- ══ MARK FOUND ══
local function MarkFound(source)
    local fileName = Player.Name .. ".txt"
    pcall(function() writefile(fileName, "Completed-drop") end)
    StatusLabel.Text = "✅ ĐÃ CÓ GREEN BELT! (" .. source .. ")"
    StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    Stroke.Color = Color3.fromRGB(80, 255, 80)
    warn("[GreenBelt] Tìm thấy trong " .. source .. "! Ghi file: " .. fileName)
    return true
end

-- ══ PHẦN A: CHECK AFK + AUTO REJOIN ══
local AFK_TIMEOUT = 5 * 60   -- 5 phút (giây)
local AFK_CHECK_INTERVAL = 1  -- Kiểm tra mỗi 1 giây
local MOVE_THRESHOLD = 0.5    -- Ngưỡng khoảng cách tính là "đang di chuyển"

local lastPosition = nil
local afkTimer = 0

local function StartAFKWatcher()
    task.spawn(function()
        while true do
            task.wait(AFK_CHECK_INTERVAL)

            local chr = Player.Character
            if not chr then
                afkTimer = 0
                lastPosition = nil
                continue
            end

            local hrp = chr:FindFirstChild("HumanoidRootPart")
            if not hrp then
                afkTimer = 0
                lastPosition = nil
                continue
            end

            local currentPos = hrp.Position

            if lastPosition == nil then
                lastPosition = currentPos
                afkTimer = 0
                continue
            end

            local distance = (currentPos - lastPosition).Magnitude

            if distance > MOVE_THRESHOLD then
                -- Người chơi đang di chuyển → reset timer
                afkTimer = 0
                lastPosition = currentPos
                if AfkLabel and AfkLabel.Parent then
                    AfkLabel.Text = "🟢 Đang di chuyển"
                    AfkLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                end
            else
                -- Người chơi đứng yên → tăng timer
                afkTimer = afkTimer + AFK_CHECK_INTERVAL
                local remaining = math.max(0, AFK_TIMEOUT - afkTimer)
                local mins = math.floor(remaining / 60)
                local secs = remaining % 60

                if AfkLabel and AfkLabel.Parent then
                    if afkTimer >= AFK_TIMEOUT * 0.75 then
                        AfkLabel.Text = string.format("⚠️ AFK: %d:%02d còn lại", mins, secs)
                        AfkLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
                    else
                        AfkLabel.Text = string.format("🟡 AFK: %d:%02d còn lại", mins, secs)
                        AfkLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                    end
                end

                if afkTimer >= AFK_TIMEOUT then
                    warn("[AFK] Không di chuyển trong 5 phút — Đang rejoin...")
                    if AfkLabel and AfkLabel.Parent then
                        AfkLabel.Text = "🔴 Đang Rejoin..."
                        AfkLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
                    end
                    task.wait(1.5)
                    pcall(function()
                        TeleportService:Teleport(game.PlaceId, Player)
                    end)
                    break
                end
            end
        end
    end)
end

-- ══ CHECK LOGIC ══
local function CheckGreenBelt()
    -- CHECK 1: Character
    local chr = Player.Character
    if chr and chr:FindFirstChild("Dojo Belt (Green)") then
        return MarkFound("Character")
    end

    -- CHECK 2: Backpack
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild("Dojo Belt (Green)") then
        return MarkFound("Backpack")
    end

    -- CHECK 3: Inventory (NEW SYSTEM)
    StatusLabel.Text = "🔍 Đang quét Inventory..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    if HasItemInInventory("Dojo Belt (Green)") then
        return MarkFound("Inventory")
    else
        StatusLabel.Text = "❌ CHƯA CÓ GREEN BELT"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end

    return false
end

-- ══ MAIN LOOP ══
warn("[GreenBelt] Game đã load — Bắt đầu check mỗi 15s.")
StartAFKWatcher()  -- Khởi động watcher AFK song song

while true do
    local ok, success = pcall(CheckGreenBelt)

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
