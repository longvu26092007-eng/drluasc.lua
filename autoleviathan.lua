-- [[ VU NGUYEN KAITUN LEVI - MULTI-SCRIPT SUPPORT ]]
-- Flow: AUTO TEAM -> WAIT 15S -> AUTO SEA 3 -> AUTO BUY DRAGON TALON -> DETECT OWNER -> AUTO KICK

local NhapKey = getgenv().Key
if not NhapKey or NhapKey == "" then warn("[Levi] Chưa set Key!"); return end
warn("[Levi] Key: " .. string.sub(NhapKey, 1, 6) .. "***")
getgenv().Team = getgenv().Team or "Marines"

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")
if game.Players.LocalPlayer.Team == nil then
    repeat task.wait()
        for _, v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then pcall(function()
                local tb = v.ChooseTeam.Container[getgenv().Team].Frame.TextButton
                tb.Size = UDim2.new(0,10000,0,10000); tb.Position = UDim2.new(-4,0,-5,0); tb.BackgroundTransparency = 1
                task.wait(0.5)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.05)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,false,game,1)
            end) end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end
repeat task.wait() until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
task.wait(2)

local success, services = pcall(function() return {
    UserInputService = game:GetService("UserInputService"), TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"), CoreGui = game:GetService("CoreGui"),
    Players = game:GetService("Players"), ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
} end)
if not success then return end

local Player = services.Players.LocalPlayer
local PlaceId = tostring(game.PlaceId)
local SEA_1 = {["2753915549"]=true,["85211729168715"]=true}
local SEA_2 = {["4442272183"]=true,["79091703265657"]=true}
local SEA_3 = {["7449423635"]=true,["100117331123089"]=true}
local Uzoth_CFrame = CFrame.new(5661.898, 1210.877, 863.176)

local function CheckDragonTalon()
    local c = Player.Character; local bp = Player:FindFirstChild("Backpack")
    return (c and c:FindFirstChild("Dragon Talon")) or (bp and bp:FindFirstChild("Dragon Talon"))
end

local function TweenTo(targetCFrame)
    local char = Player.Character or Player.CharacterAdded:Wait()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char:WaitForChild("HumanoidRootPart"); local hum = char:WaitForChild("Humanoid")
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist <= 250 then hrp.CFrame = targetCFrame; return true end
    local bv = hrp:FindFirstChild("LeviAntiGrav") or Instance.new("BodyVelocity")
    bv.Name = "LeviAntiGrav"; bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge); bv.Velocity = Vector3.zero; bv.Parent = hrp
    local tw = services.TweenService:Create(hrp, TweenInfo.new(dist/300, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    local nc; nc = services.RunService.Stepped:Connect(function()
        if hum and hum.Parent then hum:ChangeState(11) end
        if char and char.Parent then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
    end)
    tw:Play(); tw.Completed:Wait()
    if bv and bv.Parent then bv:Destroy() end; if nc then nc:Disconnect() end
    if hum and hum.Parent and hum.Health > 0 then hum:ChangeState(8); return true end; return false
end

local function DoBuyDragonTalon()
    pcall(function()
        local check = services.CommF:InvokeServer("BuyDragonTalon", true)
        if check == 3 then services.CommF:InvokeServer("Bones","Buy",1,1); task.wait(0.3); services.CommF:InvokeServer("BuyDragonTalon",true)
        elseif check == 1 then services.CommF:InvokeServer("BuyDragonTalon")
        else services.CommF:InvokeServer("Bones","Buy",1,1); task.wait(0.3); services.CommF:InvokeServer("BuyDragonTalon",true); task.wait(0.3); services.CommF:InvokeServer("BuyDragonTalon") end
    end)
end

-- UI
local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Size = UDim2.new(0,260,0,200); MainFrame.Position = UDim2.new(1,-270,0.1,0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15,15,15); Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255,200,0); Instance.new("UICorner", MainFrame)
local Title = Instance.new("TextLabel", MainFrame); Title.Size = UDim2.new(1,0,0,30); Title.Text = "VuNguyen Levi Multi-System"
Title.TextColor3 = Color3.fromRGB(255,200,0); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold
local StatusLabel = Instance.new("TextLabel", MainFrame); StatusLabel.Size = UDim2.new(1,-20,0,60); StatusLabel.Position = UDim2.new(0,10,0,40)
StatusLabel.Text = "Team: "..tostring(Player.Team).." ✅"; StatusLabel.TextColor3 = Color3.fromRGB(0,255,0)
StatusLabel.BackgroundTransparency = 1; StatusLabel.TextWrapped = true; StatusLabel.Font = Enum.Font.GothamSemibold; StatusLabel.TextSize = 11
local StartBtn = Instance.new("TextButton", MainFrame); StartBtn.Size = UDim2.new(1,-20,0,35); StartBtn.Position = UDim2.new(0,10,1,-45)
StartBtn.Text = "🚀 BẬT LEVIATHAN NGAY"; StartBtn.TextColor3 = Color3.fromRGB(0,0,0); StartBtn.BackgroundColor3 = Color3.fromRGB(255,200,0)
StartBtn.Font = Enum.Font.GothamBold; StartBtn.TextSize = 13; StartBtn.Visible = false; Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0,6)

-- ==========================================
-- MAIN: WAIT 15S → SEA 3 → BUY TALON → DETECT OWNER
-- ==========================================
task.spawn(function()

    -- BƯỚC 1: ĐỢI 15 GIÂY
    for i = 15, 1, -1 do
        StatusLabel.Text = "Waiting before Sea check: " .. i .. "s"; StatusLabel.TextColor3 = Color3.fromRGB(255,200,0); task.wait(1)
    end

    -- BƯỚC 2: CHUYỂN SEA 3
    if SEA_1[PlaceId] then
        StatusLabel.Text = "Sea 1 → Traveling to Sea 3..."; StatusLabel.TextColor3 = Color3.fromRGB(255,165,0); task.wait(1)
        services.CommF:InvokeServer("TravelDressrosa"); return
    elseif SEA_2[PlaceId] then
        StatusLabel.Text = "Sea 2 → Traveling to Sea 3..."; StatusLabel.TextColor3 = Color3.fromRGB(255,165,0); task.wait(1)
        services.CommF:InvokeServer("TravelZou"); return
    end

    -- BƯỚC 3: MUA DRAGON TALON (chỉ Sea 3)
    if CheckDragonTalon() then
        StatusLabel.Text = "Dragon Talon: ✅ Đã có"; StatusLabel.TextColor3 = Color3.fromRGB(0,255,0); task.wait(1)
    else
        for attempt = 1, 5 do
            if CheckDragonTalon() then break end
            StatusLabel.Text = "Dragon Talon: ❌ Bay đến NPC ("..attempt.."/5)"; StatusLabel.TextColor3 = Color3.fromRGB(255,200,0)
            if TweenTo(Uzoth_CFrame) then
                StatusLabel.Text = "Dragon Talon: Đang mua..."; task.wait(0.5); DoBuyDragonTalon(); task.wait(1)
                if CheckDragonTalon() then StatusLabel.Text = "Dragon Talon: ✅ Thành công!"; StatusLabel.TextColor3 = Color3.fromRGB(0,255,0); task.wait(1); break end
            end; task.wait(3)
        end
        if not CheckDragonTalon() then StatusLabel.Text = "Dragon Talon: ⚠ Không mua được!"; StatusLabel.TextColor3 = Color3.fromRGB(255,100,100); task.wait(2) end
    end

    -- BƯỚC 4: QUÉT OWNER (Sea 3)
    if SEA_3[PlaceId] then
        local function GetOwnerInServer()
            for _, p in ipairs(services.Players:GetPlayers()) do
                local n = p.Name:lower()
                if n == "ashleycraig7734" or n == "annasolis7667" or n == "arthurmills71535" or n == "bearcrafthyper200292" then return p.Name end
            end; return nil
        end

        if Player.Name:lower() ~= "ashleycraig7734" and Player.Name:lower() ~= "annasolis7667" and Player.Name:lower() ~= "arthurmills71535" and Player.Name:lower() ~= "bearcrafthyper200292" then
            -- ACC KHÁCH
            local foundOwner, timeLeft = nil, 20
            while timeLeft > 0 do
                foundOwner = GetOwnerInServer(); if foundOwner then break end
                StatusLabel.Text = string.format("Scanning for Owner...\nTime left: %ds", timeLeft)
                StatusLabel.TextColor3 = Color3.fromRGB(255,200,0); task.wait(2); timeLeft = timeLeft - 2
            end
            if foundOwner then
                StatusLabel.Text = "Owner Found: "..foundOwner.."\nExecuting Leviathan..."; StatusLabel.TextColor3 = Color3.fromRGB(0,255,0)
                task.spawn(function()
                    getgenv().Key = NhapKey
                    getgenv().Config = {
                        ["Select Owner Boat Beast Hunter"] = foundOwner, ["Auto light the torch"] = true,
                        ["No Frog"] = true, ["Boost Fps"] = true, ["Start Hunt Leviathan"] = true,
                        ["Select Skills Sword"] = {}, ["Select Skills Gun"] = {}, ["Select Skills Blox Fruit"] = {}
                    }
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))()
                end)

                -- CHECK LEVIATHAN HEART (mỗi 0.5s)
                task.spawn(function()
                    warn("[Levi] Check Leviathan Heart (0.5s)...")
                    while task.wait(0.5) do
                        local heartCount = 0
                        pcall(function()
                            local inv = services.CommF:InvokeServer("getInventory")
                            if type(inv) == "table" then for _, item in ipairs(inv) do
                                if item.Name == "Leviathan Heart" then heartCount = item.Count or 1; break end
                            end end
                        end)
                        if heartCount == 0 then pcall(function()
                            local bp = Player:FindFirstChild("Backpack"); local chr = Player.Character
                            if (bp and bp:FindFirstChild("Leviathan Heart")) or (chr and chr:FindFirstChild("Leviathan Heart")) then heartCount = 1 end
                        end) end
                        if heartCount >= 1 then
                            StatusLabel.Text = "💎 Heart: "..heartCount.." → Ghi file!"; StatusLabel.TextColor3 = Color3.fromRGB(0,255,0)
                            pcall(function() writefile(Player.Name..".txt", "Completed-heart") end)
                            warn("[Levi] "..Player.Name..".txt → Completed-heart")
                            StatusLabel.Text = "✅ Completed-heart! 📄 "..Player.Name..".txt"; break
                        end
                    end
                end)
            else
                StatusLabel.Text = "No Owner detected. Auto Kicking..."; StatusLabel.TextColor3 = Color3.fromRGB(255,0,0)
                task.wait(2); Player:Kick("Không tìm thấy chủ tàu sau 20s quét.")
            end
        else
            -- CHỦ THUYỀN
            local ownerStarted = false
            local function RunOwner()
                if ownerStarted then return end; ownerStarted = true; StartBtn.Visible = false
                StatusLabel.Text = "Owner Mode: Loading..."; StatusLabel.TextColor3 = Color3.fromRGB(0,255,0)
                task.spawn(function() getgenv().Key = NhapKey; loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))() end)
            end
            StartBtn.Visible = true; StartBtn.MouseButton1Click:Connect(RunOwner)
            StatusLabel.Text = "Owner Mode Active.\nĐợi 190s hoặc bấm button"; StatusLabel.TextColor3 = Color3.fromRGB(0,200,255)
            for i = 190, 1, -1 do
                if ownerStarted then break end
                StatusLabel.Text = string.format("Owner Mode: %d:%02d | Bấm button", math.floor(i/60), i%60); task.wait(1)
            end; RunOwner()
        end
    end
end)

-- Drag
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end end)
services.UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local d = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end)
services.UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
