-- ==========================================
-- SCRIPT CHECK DOJO BELT (YELLOW) - FIXED TIMEOUT
-- ==========================================
local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommF = ReplicatedStorage:WaitForChild("Remotes", 30):WaitForChild("CommF_", 30)

-- UI
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
    StatusText.Text = "🔍 Khởi tạo Check Yellow..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 12
    StatusText.Parent = MainFrame

    return StatusText, MainFrame, Stroke
end

local StatusLabel, MainFrame, Stroke = CreateMiniUI()

local function MarkFound(source)
    local fileName = Player.Name .. ".txt"
    pcall(function() writefile(fileName, "Completed-trade") end)
    StatusLabel.Text = "✅ ĐÃ CÓ YELLOW BELT! (" .. source .. ")"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    Stroke.Color = Color3.fromRGB(255, 215, 0)
    warn("[YellowBelt] Tìm thấy trong " .. source .. "! Ghi file: " .. fileName)
    return true
end

-- InvokeServer có timeout - tránh đứng đơ
local function InvokeWithTimeout(remote, timeout, ...)
    local result = nil
    local done   = false
    local args   = {...}

    task.spawn(function()
        local ok, res = pcall(function()
            return remote:InvokeServer(table.unpack(args))
        end)
        if ok then result = res end
        done = true
    end)

    local elapsed = 0
    while not done and elapsed < timeout do
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end

    if not done then
        warn("[YellowBelt] InvokeServer timeout sau " .. timeout .. "s")
    end

    return result
end

local function CheckYellowBeltAndSave()
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

    -- CHECK 3: Inventory với timeout 8 giây
    if not CommF then
        StatusLabel.Text = "⏳ Đợi Remote (CommF_)..."
        return false
    end

    StatusLabel.Text = "🔍 Đang quét Inventory..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    local inv = InvokeWithTimeout(CommF, 8, "getInventory")

    if type(inv) == "table" then
        for _, item in pairs(inv) do
            if type(item) == "table" and item.Name == "Dojo Belt (Yellow)" then
                return MarkFound("Inventory")
            end
        end
        StatusLabel.Text = "❌ CHƯA CÓ YELLOW BELT"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        -- Timeout hoặc lỗi → không đứng đơ, tiếp tục loop
        StatusLabel.Text = "⚠️ Timeout/Lỗi Inventory, thử lại..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        warn("[YellowBelt] getInventory timeout hoặc lỗi, thử lại sau 15s")
    end

    return false
end

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    warn("[YellowBelt] Bắt đầu vòng lặp check 15s.")

    while true do
        local success = CheckYellowBeltAndSave()
        if success then
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
end)
