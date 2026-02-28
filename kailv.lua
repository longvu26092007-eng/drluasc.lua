-- [[ VU NGUYEN KAITUN LEVI - MULTI-SCRIPT SUPPORT ]]
-- Chức năng: DELAY 10S -> AUTO MARINES -> WAIT 15S -> AUTO SEA 3 -> DETECT OWNER -> AUTO KICK

-- [[ CONFIG AREA ]]
getgenv().Team = "Marines" -- Thiết lập Marines

-- [[ SECURITY & SERVICES ]]
local success, services = pcall(function()
    return {
        UserInputService = game:GetService("UserInputService"),
        TweenService = game:GetService("TweenService"),
        CoreGui = game:GetService("CoreGui"),
        Players = game:GetService("Players"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    }
end)

if not success then return end

local Player = services.Players.LocalPlayer
local PlaceId = tostring(game.PlaceId)

-- ID CÁC SEA ĐỂ FIX LỖI CHUYỂN VÙNG
local SEA_1 = {["2753915549"] = true, ["85211729168715"] = true}
local SEA_2 = {["4442272183"] = true, ["79091703265657"] = true}
local SEA_3 = {["7449423635"] = true, ["100117331123089"] = true}

-- ==========================================
-- MONITOR UI (RIGHT SIDE - GOLD/BLACK)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 160)
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
StatusLabel.Text = "Waiting 10s to start..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextWrapped = true

-- ==========================================
-- LOGIC TRÌNH TỰ: TEAM -> WAIT 15S -> SEA -> DETECT
-- ==========================================
task.spawn(function()
    repeat task.wait() until game:IsLoaded() and Player
    
    -- BƯỚC 1: DELAY 10 GIÂY
    for i = 10, 1, -1 do
        StatusLabel.Text = "System Starting in: " .. i .. "s"
        task.wait(1)
    end

    -- BƯỚC 2: CHỌN TEAM MARINES (CHỜ ĐẾN KHI XONG)
    StatusLabel.Text = "Selecting Team: " .. getgenv().Team
    if Player.Team == nil then
        repeat 
            task.wait(0.5) 
            services.CommF:InvokeServer("SetTeam", getgenv().Team) 
        until Player.Team ~= nil
    end
    task.wait(1)

    -- BƯỚC 3: ĐỢI 15 GIÂY TRƯỚC KHI CHECK SEA & TELEPORT
    for i = 15, 1, -1 do
        StatusLabel.Text = "Waiting before Sea check: " .. i .. "s"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        task.wait(1)
    end

    -- BƯỚC 4: KIỂM TRA VÀ CHUYỂN SEA
    if SEA_1[PlaceId] then
        StatusLabel.Text = "Sea 1 Detected. Traveling to Sea 3..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        task.wait(1)
        services.CommF:InvokeServer("TravelDressrosa") -- Qua Sea 2
        return
    elseif SEA_2[PlaceId] then
        StatusLabel.Text = "Sea 2 Detected. Traveling to Sea 3..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        task.wait(1)
        services.CommF:InvokeServer("TravelZou") -- Lên Sea 3
        return
    end

    -- BƯỚC 5: LOGIC QUÉT OWNER (CHỈ CHẠY TẠI SEA 3)
    if SEA_3[PlaceId] then
        local function GetOwnerInServer()
            for _, p in ipairs(services.Players:GetPlayers()) do
                local name = p.Name:lower()
                if name == "nlvrblx" or name == "nhkyqqox" or name == "minkawai2007" then 
                    return p.Name 
                end
            end
            return nil
        end

        if Player.Name:lower() ~= "nlvrblx" and Player.Name:lower() ~= "minkawai2007" then
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
                
                getgenv().Key = "1f34f32b6f1917a66d57e8c6"
                getgenv().Config = {
                    ["Select Owner Boat Beast Hunter"] = foundOwner,
                    ["No Frog"] = true,
                    ["Boost Fps"] = true,
                    ["Start Hunt Leviathan"] = true
                }
                loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))()

                task.wait(20)
                StatusLabel.Text = "Loading bfchangeacc..."
                loadstring(game:HttpGet("https://raw.githubusercontent.com/skadidau/unfazedfree/refs/heads/main/bfchangeacc"))()
            else
                StatusLabel.Text = "No Owner detected. Auto Kicking..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(2)
                Player:Kick("Không tìm thấy chủ tàu sau 20s quét.")
            end
        else
            -- LOGIC DÀNH CHO CHỦ TÀU
            StatusLabel.Text = "Main Account Mode Active.\nLoading Leviathan Script..."
            getgenv().Key = "1f34f32b6f1917a66d57e8c6"
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))()
        end
    end
end)

-- Drag System
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = MainFrame.Position end end)
services.UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
services.UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
