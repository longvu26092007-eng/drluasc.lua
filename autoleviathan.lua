-- [[ VU NGUYEN KAITUN LEVI - MULTI-SCRIPT SUPPORT ]]
-- Chức năng: AUTO TEAM -> WAIT 15S -> AUTO SEA 3 -> DETECT OWNER -> AUTO KICK

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
-- LOGIC: WAIT 15S → SEA 3 → DETECT OWNER
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
    -- BƯỚC 2: LOGIC QUÉT OWNER (CHỈ SEA 3)
    -- ========================================
    if SEA_3[PlaceId] then

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
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))()
                end)

                -- ========================================
                -- CHECK LEVIATHAN HEART (0.5s interval)
                -- ========================================
                task.spawn(function()
                    warn("[Levi] Bắt đầu check Leviathan Heart...")
                    while task.wait(0.5) do
                        local heartCount = 0
                        pcall(function()
                            local inv = services.CommF:InvokeServer("getInventory")
                            if type(inv) == "table" then
                                for _, item in ipairs(inv) do
                                    if item.Name == "Leviathan Heart" then
                                        heartCount = item.Count or 1
                                        break
                                    end
                                end
                            end
                        end)

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

                            pcall(function()
                                writefile(Player.Name .. ".txt", "Completed-heart")
                            end)
                            warn("[Levi] Đã ghi file: " .. Player.Name .. ".txt → Completed-heart")

                            StatusLabel.Text = "✅ Completed-heart!\n📄 " .. Player.Name .. ".txt"
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
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
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))()
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
