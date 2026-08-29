-- [[ VU NGUYEN KAITUN LEVI - MULTI-SCRIPT SUPPORT ]]
-- Chức năng: AUTO TEAM -> WAIT 15S -> AUTO SEA 3 -> AUTO BUY DRAGON TALON -> DETECT OWNER -> AUTO KICK

-- ==========================================
-- [ KEY CHECK ]
-- ==========================================
local NhapKey = getgenv().Key

if not NhapKey or NhapKey == "" then
    warn("[Levi] ❌ Chưa set getgenv().Key ở executor! Hủy script.")
    return
end
warn("[Levi] ✅ Key nhận được: " .. string.sub(NhapKey, 1, 6) .. "***")

-- [[ CONFIG AREA ]]
getgenv().Team = getgenv().Team or "Marines"

-- ==========================================
-- [ PHẦN 0 : CHỌN TEAM & ĐỢI GAME LOAD ]
-- ==========================================
if not game:IsLoaded() then
    game.Loaded:Wait()
end
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")
if game.Players.LocalPlayer.Team == nil then
    repeat
        task.wait()
        for _, v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                pcall(function()
                    local teamBtn = v.ChooseTeam.Container[getgenv().Team].Frame.TextButton
                    teamBtn.Size     = UDim2.new(0, 10000, 0, 10000)
                    teamBtn.Position = UDim2.new(-4, 0, -5, 0)
                    teamBtn.BackgroundTransparency = 1
                    task.wait(0.5)
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,true,game,1)
                    task.wait(0.05)
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,false,game,1)
                    task.wait(0.05)
                end)
            end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end
repeat task.wait() until game.Players.LocalPlayer.Character
    and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
task.wait(2)

-- [[ SECURITY & SERVICES ]]
local success, services = pcall(function()
    return {
        UserInputService = game:GetService("UserInputService"),
        TweenService = game:GetService("TweenService"),
        RunService = game:GetService("RunService"),
        CoreGui = game:GetService("CoreGui"),
        Players = game:GetService("Players"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    }
end)

if not success then return end

local Player = services.Players.LocalPlayer
local PlaceId = tostring(game.PlaceId)

local SEA_1 = {["2753915549"] = true, ["85211729168715"] = true}
local SEA_2 = {["4442272183"] = true, ["79091703265657"] = true}
local SEA_3 = {["7449423635"] = true, ["100117331123089"] = true}


-- ==========================================
-- [ MATERIAL TRACKER — LEVIATHAN HEART ]
-- Đọc Material bằng Inventory + ItemReplicationService.
-- Chạy nền để không chặn luồng Team / Sea / Dragon Talon / Owner.
-- ==========================================
local MaterialTracker = {
    Ready = false,
    Counts = {},
    NamesById = {},
    CategoriesById = {},
    LastError = nil,
}

local function NormalizeMaterialName(value)
    return tostring(value or "")
        :lower()
        :gsub("[^%w]", "")
end

local function GetMaterialCount(materialName)
    return tonumber(MaterialTracker.Counts[NormalizeMaterialName(materialName)]) or 0
end

task.spawn(function()
    local okRequire, Inventory, ItemConfig, ItemService, KEYS = pcall(function()
        local RS = services.ReplicatedStorage
        return
            require(RS.Controllers.UI.Inventory),
            require(RS.ItemConfig),
            require(RS.ItemReplicationService),
            require(RS.ItemReplicationService.KEYS)
    end)

    if not okRequire then
        MaterialTracker.LastError = tostring(Inventory)
        warn("[Levi][Material] Không load được Inventory module: " .. tostring(Inventory))
        return
    end

    local function InventoryInitialized()
        local ok, ready = pcall(function()
            return Inventory:GetIfInitialized()
        end)
        return ok and ready == true and ItemService.IsInitialized == true
    end

    -- Không khóa script chính. Chờ tối đa 30s rồi vẫn tiếp tục retry refresh nền.
    local inventoryDeadline = os.clock() + 30
    repeat task.wait(0.2)
    until InventoryInitialized() or os.clock() >= inventoryDeadline

    if not InventoryInitialized() then
        warn("[Levi][Material] Inventory chưa initialized sau 30s; tiếp tục retry nền")
    end

    local function ResolveItemInfo(itemId)
        if itemId == nil then return nil, nil end

        if MaterialTracker.NamesById[itemId] ~= nil then
            return MaterialTracker.NamesById[itemId], MaterialTracker.CategoriesById[itemId]
        end

        local successConfig, config = pcall(function()
            return ItemConfig.match(itemId):unwrap()
        end)

        if not successConfig or not config then
            return nil, nil
        end

        local display = config.Display or {}
        local index = config.Index or {}
        local name = display.Name or index.StorageKey or tostring(itemId)
        local category = display.Category

        MaterialTracker.NamesById[itemId] = name
        MaterialTracker.CategoriesById[itemId] = category
        return name, category
    end

    while true do
        local successRefresh, refreshError = pcall(function()
            local amounts = {}

            for _, item in pairs(ItemService:GetItems(KEYS.QUANTITY) or {}) do
                if type(item) == "table" and item.ItemId ~= nil then
                    amounts[item.ItemId] =
                        (amounts[item.ItemId] or 0)
                        + (tonumber(item.Value) or 0)
                end
            end

            local checked = {}
            local counts = {}

            -- Duyệt đúng theo Inventory:GetTiles() như detector mẫu.
            for _, tile in pairs(Inventory:GetTiles() or {}) do
                local id = tile and tile.ItemId

                if id and not checked[id] then
                    checked[id] = true

                    local name, category = ResolveItemInfo(id)
                    local key = NormalizeMaterialName(name)
                    if name and (category == "Material" or key == "leviathanheart") then
                        counts[key] = amounts[id] or 1
                    end
                end
            end

            -- Bổ sung resolve trực tiếp các ItemId có quantity.
            -- Tránh trường hợp quantity đã replicate nhưng tile chưa kịp xuất hiện.
            for id, amount in pairs(amounts) do
                if not checked[id] then
                    local name, category = ResolveItemInfo(id)
                    local key = NormalizeMaterialName(name)
                    if name and (category == "Material" or key == "leviathanheart") then
                        counts[key] = (counts[key] or 0) + amount
                    end
                end
            end

            MaterialTracker.Counts = counts
            MaterialTracker.Ready = true
            MaterialTracker.LastError = nil
        end)

        if not successRefresh then
            MaterialTracker.LastError = tostring(refreshError)
            warn("[Levi][Material] Refresh lỗi: " .. tostring(refreshError))
        end

        task.wait(0.5)
    end
end)

-- ==========================================
-- [ DRAGON TALON - CHECK & BUY ]
-- ==========================================
local Uzoth_CFrame = CFrame.new(5661.898, 1210.877, 863.176)

local function CheckDragonTalon()
    local char = Player.Character
    local bp = Player:FindFirstChild("Backpack")
    return (char and char:FindFirstChild("Dragon Talon"))
        or (bp and bp:FindFirstChild("Dragon Talon"))
end

local function TweenTo(targetCFrame)
    local char = Player.Character or Player.CharacterAdded:Wait()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance <= 250 then
        hrp.CFrame = targetCFrame
        return true
    end

    local bv = hrp:FindFirstChild("LeviAntiGrav") or Instance.new("BodyVelocity")
    bv.Name = "LeviAntiGrav"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp

    local tweenObj = services.TweenService:Create(hrp, TweenInfo.new(distance / 300, Enum.EasingStyle.Linear), {CFrame = targetCFrame})

    local noclip
    noclip = services.RunService.Stepped:Connect(function()
        if hum and hum.Parent then hum:ChangeState(11) end
        if char and char.Parent then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    tweenObj:Play()
    tweenObj.Completed:Wait()

    if bv and bv.Parent then bv:Destroy() end
    if noclip then noclip:Disconnect() end

    if hum and hum.Parent and hum.Health > 0 then
        hum:ChangeState(8)
        return true
    end
    return false
end

local function DoBuyDragonTalon()
    pcall(function()
        local check = services.CommF:InvokeServer("BuyDragonTalon", true)
        if check == 3 then
            services.CommF:InvokeServer("Bones", "Buy", 1, 1)
            task.wait(0.3)
            services.CommF:InvokeServer("BuyDragonTalon", true)
        elseif check == 1 then
            services.CommF:InvokeServer("BuyDragonTalon")
        else
            services.CommF:InvokeServer("Bones", "Buy", 1, 1)
            task.wait(0.3)
            services.CommF:InvokeServer("BuyDragonTalon", true)
            task.wait(0.3)
            services.CommF:InvokeServer("BuyDragonTalon")
        end
    end)
end

-- ==========================================
-- MONITOR UI (RIGHT SIDE - GOLD/BLACK)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 200)
MainFrame.Position = UDim2.new(1, -270, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "VuNguyen Levi Multi-System"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 60)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.Text = "Team: " .. tostring(Player.Team) .. " ✅"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextWrapped = true
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 11

local StartBtn = Instance.new("TextButton", MainFrame)
StartBtn.Size = UDim2.new(1, -20, 0, 35)
StartBtn.Position = UDim2.new(0, 10, 1, -45)
StartBtn.Text = "🚀 BẬT LEVIATHAN NGAY"
StartBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 13
StartBtn.Visible = false
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- [ DANH SÁCH ACC MAIN BOAT ]
-- ==========================================
local OwnerList = {
    "ashleycraig7734",
    "annasolis7667",
    "arthurmills71535",
    "annealvarado27936",
    "bearcrafthyper200292",
    "ananielsen801",
    "alexbishop97",
    "aimeepratt07",
    "abigailgalaxymax54",
    "annvelez091"
}

local function IsOwner(name)
    local lower = name:lower()
    for _, v in ipairs(OwnerList) do
        if lower == v then return true end
    end
    return false
end

-- ==========================================
-- [ CHANGE FOLDER — chuẩn hoá theo KaitunV4 ]
--   Config ngoài loader:
--     getgenv().ChangeFolderOnCompleted = true|false
--     getgenv().id1 = "..."   (bắt buộc)
--     getgenv().id2 = "..."   (bắt buộc)
--     getgenv().id3 = "..." | "........." | "nil" | nil   (optional)
-- ==========================================
local DESKTOP_DIR = "C:\\Users\\Administrator\\Desktop\\"

local _ChangeFolderLock          = false
local _LastChangeFolderFailAt    = 0
local _ChangeFolderRetryCooldown = 10

-- id optional: bỏ trống / "........." / chuỗi toàn dấu chấm / "nil" → trả về nil THẬT
local function NormalizeFolderId(value)
    if value == nil then return nil, false end
    local s = tostring(value)
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" or s == "........." or s:match("^%.+$") then return nil, false end
    if s:lower() == "nil" then return nil, false end
    return s, true
end

local function DoChangeFolder(reason)
    if not getgenv().ChangeFolderOnCompleted then return false end
    if _ChangeFolderLock then return false end
    if _LastChangeFolderFailAt > 0
        and (tick() - _LastChangeFolderFailAt) < _ChangeFolderRetryCooldown then
        return false
    end

    local client = getgenv().client
    if type(client) ~= "table" and type(client) ~= "userdata" then
        warn("[Levi][ChangeFolder] getgenv().client không tồn tại")
        _LastChangeFolderFailAt = tick()
        return false
    end
    if type(client.ChangeToFolder) ~= "function" then
        warn("[Levi][ChangeFolder] client:ChangeToFolder không tồn tại")
        _LastChangeFolderFailAt = tick()
        return false
    end

    local id1, ok1 = NormalizeFolderId(getgenv().id1)
    local id2, ok2 = NormalizeFolderId(getgenv().id2)
    local id3      = NormalizeFolderId(getgenv().id3)

    if not ok1 or not ok2 then
        warn("[Levi][ChangeFolder] Thiếu id1/id2, không gọi ChangeToFolder")
        _LastChangeFolderFailAt = tick()
        return false
    end

    _ChangeFolderLock = true
    warn("[Levi][ChangeFolder] Completed -> ChangeToFolder | reason=" .. tostring(reason)
        .. " | id1=" .. tostring(id1) .. " id2=" .. tostring(id2) .. " id3=" .. tostring(id3))

    local ok, ret = pcall(function()
        return client:ChangeToFolder(id1, id2, true, id3)
    end)

    if not ok then
        warn("[Levi][ChangeFolder] Lỗi khi gọi ChangeToFolder: " .. tostring(ret))
        _ChangeFolderLock = false
        _LastChangeFolderFailAt = tick()
        return false
    end

    if ret then
        warn("[Levi][ChangeFolder] Đổi folder thành công -> Disconnect + Shutdown")
        pcall(function()
            if type(client.Disconnect) == "function" then client:Disconnect() end
        end)
        task.wait(5)
        pcall(function() game:Shutdown() end)
        return true
    else
        warn("[Levi][ChangeFolder] Đổi folder thất bại, retry sau " .. _ChangeFolderRetryCooldown .. "s")
        _ChangeFolderLock = false
        _LastChangeFolderFailAt = tick()
        return false
    end
end

-- ==========================================
-- LOGIC: WAIT 15S → SEA 3 → BUY DRAGON TALON → DETECT OWNER
-- ==========================================
task.spawn(function()

    -- ========================================
    -- BƯỚC 0: ĐỢI 15 GIÂY
    -- ========================================
    for i = 15, 1, -1 do
        StatusLabel.Text = "Waiting before Sea check: " .. i .. "s"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        task.wait(1)
    end

    -- ========================================
    -- BƯỚC 1: KIỂM TRA VÀ CHUYỂN SEA
    -- ========================================
    if SEA_1[PlaceId] then
        StatusLabel.Text = "Sea 1 Detected. Traveling to Sea 3..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        task.wait(1)
        services.CommF:InvokeServer("TravelDressrosa")
        return
    elseif SEA_2[PlaceId] then
        StatusLabel.Text = "Sea 2 Detected. Traveling to Sea 3..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        task.wait(1)
        services.CommF:InvokeServer("TravelZou")
        return
    end

    -- ========================================
    -- BƯỚC 2: CHECK & MUA DRAGON TALON (CHỈ Ở SEA 3)
    -- ========================================
    if SEA_3[PlaceId] then
        if CheckDragonTalon() then
            StatusLabel.Text = "Dragon Talon: ✅ Đã có\nTiếp tục..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            warn("[Levi] Dragon Talon đã có, bỏ qua.")
            task.wait(1)
        else
            local maxRetry = 5
            for attempt = 1, maxRetry do
                if CheckDragonTalon() then break end

                StatusLabel.Text = "Dragon Talon: ❌ Chưa có\nĐang bay đến NPC... (" .. attempt .. "/" .. maxRetry .. ")"
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                warn("[Levi] Chưa có Dragon Talon, bay đến NPC (lần " .. attempt .. ")")

                local arrived = TweenTo(Uzoth_CFrame)
                if arrived then
                    StatusLabel.Text = "Dragon Talon: Đang mua..."
                    task.wait(0.5)
                    DoBuyDragonTalon()
                    task.wait(1)

                    if CheckDragonTalon() then
                        StatusLabel.Text = "Dragon Talon: ✅ Mua thành công!"
                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        warn("[Levi] Mua Dragon Talon thành công!")
                        task.wait(1)
                        break
                    else
                        StatusLabel.Text = "Dragon Talon: Mua thất bại, thử lại..."
                        warn("[Levi] Mua thất bại, retry...")
                    end
                else
                    StatusLabel.Text = "Dragon Talon: Bay thất bại, thử lại..."
                end
                task.wait(3)
            end

            if not CheckDragonTalon() then
                StatusLabel.Text = "Dragon Talon: ⚠ Không mua được!\nTiếp tục script..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                warn("[Levi] Không mua được Dragon Talon sau " .. maxRetry .. " lần. Tiếp tục.")
                task.wait(2)
            end
        end

        -- ========================================
        -- BƯỚC 3: LOGIC QUÉT OWNER (CHỈ SEA 3)
        -- ========================================
        local function GetOwnerInServer()
            for _, p in ipairs(services.Players:GetPlayers()) do
                if IsOwner(p.Name) then
                    return p.Name
                end
            end
            return nil
        end

        if not IsOwner(Player.Name) then
            -- ========================================
            -- ACC KHÁCH: Quét owner → load script
            -- ========================================
            local foundOwner = nil
            local timeLeft = 20

            while timeLeft > 0 do
                foundOwner = GetOwnerInServer()
                if foundOwner then break end

                StatusLabel.Text = string.format("Scanning for Owner...\nTime left: %ds", timeLeft)
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)

                task.wait(2)
                timeLeft = timeLeft - 2
            end

            if foundOwner then
                StatusLabel.Text = "Owner Found: " .. foundOwner .. "\nExecuting Leviathan Script..."
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)

                task.spawn(function()
                    getgenv().Key = NhapKey
                    getgenv().Config = {
                        ["Select Owner Boat Beast Hunter"] = foundOwner,
                        ["Auto light the torch"] = true,
                        ["No Frog"] = true,
                        ["Boost Fps"] = true,
                        ["Start Hunt Leviathan"] = true,
                        ["Select Skills Sword"] = {},
                        ["Select Skills Gun"] = {},
                        ["Select Skills Blox Fruit"] = {}
                    }
                    loadstring(game:HttpGet("https://banana-hub.xyz/scripts/kaitun_levi.lua"))()
                end)

                -- ========================================
                -- CHECK LEVIATHAN HEART MATERIAL (0.5s interval)
                -- ========================================
                task.spawn(function()
                    warn("[Levi] Bắt đầu check Leviathan Heart bằng Material tracker...")
                    while task.wait(0.5) do
                        local heartCount = GetMaterialCount("Leviathan Heart")

                        -- Fallback Tool chỉ để bắt khoảnh khắc Heart vừa được đưa vào Backpack/Character
                        -- trước khi ItemReplicationService refresh ở tick kế tiếp.
                        if heartCount == 0 then
                            pcall(function()
                                local bp = Player:FindFirstChild("Backpack")
                                local chr = Player.Character
                                if (bp and bp:FindFirstChild("Leviathan Heart"))
                                    or (chr and chr:FindFirstChild("Leviathan Heart")) then
                                    heartCount = 1
                                end
                            end)
                        end

                        if heartCount >= 1 then
                            StatusLabel.Text = "💎 Leviathan Heart: " .. heartCount .. " → Ghi file!"
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            warn("[Levi] Phát hiện Leviathan Heart x" .. heartCount .. "! Ghi file...")

                            local heartFile = DESKTOP_DIR .. Player.Name .. ".txt"
                            local wok, werr = pcall(function()
                                writefile(heartFile, "Completed-heart")
                            end)
                            if wok then
                                warn("[Levi] Đã ghi file: " .. heartFile .. " → Completed-heart")
                            else
                                warn("[Levi] Ghi Desktop lỗi (" .. tostring(werr) .. "), fallback workspace...")
                                pcall(function() writefile(Player.Name .. ".txt", "Completed-heart") end)
                                heartFile = Player.Name .. ".txt"
                            end

                            getgenv().CustomChange = true
                            warn("[Levi] Đã set getgenv().CustomChange = true")

                            StatusLabel.Text = "✅ Completed-heart!\n📄 " .. heartFile
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)

                            -- ========================================
                            -- CHANGE TO FOLDER SAU KHI CÓ HEART (chuẩn KaitunV4)
                            -- ========================================
                            if getgenv().ChangeFolderOnCompleted then
                                task.spawn(function()
                                    local done = DoChangeFolder("Completed-heart")
                                    if done then
                                        StatusLabel.Text = "✅ Completed-heart!\n📁 Folder đổi thành công"
                                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                    end
                                end)
                            else
                                warn("[Levi] ChangeFolderOnCompleted != true → bỏ qua ChangeToFolder")
                            end

                            break
                        end
                    end
                end)
            else
                StatusLabel.Text = "No Owner detected. Auto Kicking..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(2)
                Player:Kick("Không tìm thấy chủ tàu sau 20s quét.")
            end
        else
            -- ========================================
            -- CHỦ THUYỀN: Countdown 190s + Button bật sớm
            -- ========================================
            local ownerScriptStarted = false

            local function RunOwnerScript()
                if ownerScriptStarted then return end
                ownerScriptStarted = true
                StartBtn.Visible = false
                StatusLabel.Text = "Owner Mode: Loading Leviathan Script..."
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                warn("[Levi] Owner: Bật Leviathan Script!")

                task.spawn(function()
                    getgenv().Key = NhapKey
                    loadstring(game:HttpGet("https://banana-hub.xyz/scripts/kaitun_levi.lua"))()
                end)
            end

            StartBtn.Visible = true
            StartBtn.MouseButton1Click:Connect(function()
                RunOwnerScript()
            end)

            StatusLabel.Text = "Owner Mode Active.\nĐợi 190s hoặc bấm button bên dưới"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)

            for i = 190, 1, -1 do
                if ownerScriptStarted then break end
                StatusLabel.Text = string.format("Owner Mode: %d:%02d | Bấm button để bật sớm", math.floor(i/60), i%60)
                StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                task.wait(1)
            end

            RunOwnerScript()
        end
    end
end)

-- Drag System
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = MainFrame.Position end end)
services.UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
services.UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
