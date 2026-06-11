local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
repeat task.wait() until not PlayerGui:FindFirstChild("LoadingScreen")
repeat
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_"):InvokeServer("SetTeam", "Marines") -- hoặc "Marines"
    end)
    task.wait(1)
until LocalPlayer.Team ~= nil

local Config = {
    Name = "Blox Fruits - Auto Fruit",
    Team = "Marines",
    TweenSpeed = 150,
    SkipFruits = false,
    MaxIndividualFruit = 1,
    MaxStore = 3600,
    CheckInterval = 2500,
    TeleportInterval = 1000,
}

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")

local function Notify(Text)
    StarterGui:SetCore("SendNotification", {
        Title = Config.Name,
        Text = Text,
    })
end

local function GetCharacter(Player)
    return Player.Character or Player.CharacterAdded:Wait()
end

local function GetHumanoid(Player)
    local Character = GetCharacter(Player)
    return Character:WaitForChild("Humanoid")
end

local function GetRootPart(Player)
    local Character = GetCharacter(Player)
    return Character:WaitForChild("HumanoidRootPart")
end

local function TeleportTo(CFrame)
    local RootPart = GetRootPart(Player)
    local CurrentPos = RootPart.Position
    local TargetPos = CFrame.Position
    local Distance = (TargetPos - CurrentPos).magnitude
    local Duration = Distance / Config.TweenSpeed
    local TweenInfo = TweenInfo.new(Duration, Enum.EasingStyle.Linear)
    local Tween = TweenService:Create(RootPart, TweenInfo, {
        CFrame = CFrame,
    })

    Tween:Play()
    Tween.Completed:Wait()
end
function equipdevilfruit()
    local player = game.Players.LocalPlayer
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and string.find(tool.Name, "Fruit") then
            player.Character.Humanoid:EquipTool(tool)
            return true
        end
    end
    return false
end
local NoClipConnection

local function DisableNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
end

local function EnableNoClip()
    DisableNoClip()

    NoClipConnection = RunService.Stepped:Connect(function()
        if not Player.Character then
            return
        end

        for _, Item in pairs(Player.Character:GetDescendants()) do
            if Item:IsA("BasePart") and Item.CanCollide then
                Item.CanCollide = false
            end
        end
    end)
end

local function DisableSitting()
    local Humanoid = GetHumanoid(Player)
    Humanoid:SetStateEnabled("Seated", false)
    Humanoid.Sit = true
end

local function EnableSitting()
    local Humanoid = GetHumanoid(Player)
    Humanoid:SetStateEnabled("Seated", true)
    Humanoid.Sit = false
end


local function MonitorCharacter()
    local Character = GetCharacter(Player)

    Character.ChildAdded:Connect(function(Item)
        local Fruit = Item:FindFirstChild("Fruit")

        if Fruit then
            Notify("Drop: " .. Item.Name)  
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            
            for _, v in pairs(char:GetChildren()) do
                if v:FindFirstChild("EatRemote") then
                    print("Found fruit:", v.Name)
                    v.EatRemote:InvokeServer("Drop")
                end
            end            
        end
    end)
end

local function GetFruitInventory()
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
    vim:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
end

local function CountOccurrences(Table, Target)
    local Count = 0

    for _, Value in pairs(Table) do
        if Value == Target then
            Count = Count + 1
        end
    end

    return Count
end

local function getCharacter()
    return game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
end

-- Hàm bật/tắt noclip
local function toggleNoclip(Toggle)
    local character = getCharacter()
    if not character then return end
    for _, v in pairs(character:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = not Toggle
        end
    end
end

local function SmoothMove(targetPos)
    local character = getCharacter()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local startPos = rootPart.Position
    local distance = (targetPos - startPos).Magnitude
    if distance < 0.1 then return true end -- đã ở đó rồi
    local direction = (targetPos - startPos).Unit
    local speed = 230
    local duration = distance / speed
    local startTime = tick()
    toggleNoclip(true)
    while true do
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        local newPos = startPos:Lerp(targetPos, progress)
        rootPart.CFrame = CFrame.new(newPos, newPos + direction)
        if progress >= 1 then break end
        task.wait()
    end
    toggleNoclip(false)
    return true
end

local function TeleportToFruits()
    local TargetPos = Vector3.new(5865.6083984375, 1208.3153076171875, 875.4540405273438)
    local MaxDistance = 80

    local fruits = {}
    for _, item in pairs(workspace:GetDescendants()) do
        if item:IsA("BasePart") and item.Parent then
            local isFruit = item.Parent:FindFirstChild("Fruit")
                or string.find(item.Parent.Name, "Fruit")
            if isFruit then
                local dist = (item.Position - TargetPos).Magnitude
                if dist <= MaxDistance then
                    local already = false
                    for _, f in ipairs(fruits) do
                        if f.parent == item.Parent then already = true; break end
                    end
                    if not already then
                        table.insert(fruits, { part = item, parent = item.Parent, dist = dist })
                    end
                end
            end
        end
    end

    table.sort(fruits, function(a, b) return a.dist < b.dist end)

    if #fruits == 0 then
        print("[Belt5] No fruits nearby (" .. MaxDistance .. " studs from Dojo)")
        return
    end

    for _, f in ipairs(fruits) do
        if f.part and f.part.Parent then
            Notify("Lụm: " .. f.parent.Name)
            SmoothMove(f.part.Position)
        end
    end
end

local function WaitForFruitEquipped(timeout)
    local t0 = tick()
    repeat
        local char = getCharacter()  
        if char then
            for _, v in pairs(char:GetChildren()) do
                if v:FindFirstChild("EatRemote") then return v end
            end
        end
        task.wait()
    until tick() - t0 > (timeout or 5)
    return nil
end
local function DropAllBackpackFruits()
    local player = game.Players.LocalPlayer
    local char = getCharacter()
    local maxTries = 20
    for i = 1, maxTries do
        local fruit = nil
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name, "Fruit") then
                fruit = tool; break
            end
        end
        if not fruit then break end  -- hết fruit

        if char and char:FindFirstChildWhichIsA("Humanoid") then
            char:FindFirstChildWhichIsA("Humanoid"):EquipTool(fruit)
        end
        local equipped = nil
        local t0 = tick()
        repeat
            char = getCharacter()
            if char then
                for _, v in pairs(char:GetChildren()) do
                    if v:FindFirstChild("EatRemote") then equipped = v; break end
                end
            end
            if not equipped then task.wait() end
        until equipped or tick() - t0 > 3

        -- Drop ngay tại Dojo Belt
        if equipped then
            pcall(function() equipped.EatRemote:InvokeServer("Drop") end)
            task.wait(0.2)  
        else
            break  
        end
    end
end

function HyperCahaya(Pos)
    local character = getCharacter()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    SmoothMove(Pos.Position)
    character = getCharacter()
    rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    if (rootPart.Position - Pos.Position).Magnitude > 10 then return end
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("Cousin", "Buy")
    end)
    EnableNoClip()
    DisableSitting()
    TeleportToFruits()
    SmoothMove(Pos.Position)
    DropAllBackpackFruits()
    DisableNoClip()
    toggleNoclip(false)
    EnableSitting()
end
-- Hàm checklocation gọi HyperCahaya
function checklocation(targetCFrame)
    local character = getCharacter()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local distanceToTarget = (rootPart.Position - targetCFrame.Position).Magnitude
    HyperCahaya(targetCFrame)
end


task.spawn(function()
    while task.wait(3) do
        local targetCFrame = CFrame.new(5865.6083984375, 1208.3153076171875, 875.4540405273438)
        checklocation(targetCFrame)

        -- Gửi yêu cầu nhận nhiệm vụ
        local args1 = {
            {
                NPC = "Dojo Trainer",
                Command = "RequestQuest"
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RF/InteractDragonQuest"):InvokeServer(unpack(args1))
        -- Gửi yêu cầu nhận thưởng
        local args2 = {
            {
                NPC = "Dojo Trainer",
                Command = "ClaimQuest"
            }
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Net"):WaitForChild("RF/InteractDragonQuest"):InvokeServer(unpack(args2))
    end
end)
