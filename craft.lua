repeat task.wait() until game:IsLoaded()
getgenv().Config = {
    TEAM = "Pirates" --Marines
}
local Config = getgenv().Config

repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")
if game:GetService("Players").LocalPlayer.Team == nil then
    repeat task.wait()
        for i, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                v.ChooseTeam.Container[Config.TEAM].Frame.TextButton.Size = UDim2.new(0, 10000, 0, 10000)
                v.ChooseTeam.Container[Config.TEAM].Frame.TextButton.Position = UDim2.new(-4, 0, -5, 0)
                v.ChooseTeam.Container[Config.TEAM].Frame.TextButton.BackgroundTransparency = 1
                task.wait(.5)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1);task.wait(0.05)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1);task.wait(0.05)
            end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SPEED = 240
local targetPos = CFrame.new(5864.833008, 1209.483032, 811.329224)


local RFCraft = ReplicatedStorage
    :WaitForChild("Modules")
    :WaitForChild("Net")
    :WaitForChild("RF/Craft")

local function requestEntranceFirst()
    local entrancePos = Vector3.new(
        5661.5322265625,
        1013.0907592773438,
        -334.9649963378906
    )

    local ok, result = pcall(function()
        return ReplicatedStorage
            .Remotes
            .CommF_
            :InvokeServer("requestEntrance", entrancePos)
    end)

    if ok then
        warn("[requestEntrance] OK:", result)
    else
        warn("[requestEntrance] FAILED:", result)
    end
end

local function craftByRF(itemName)
    local args = {
        [1] = "Craft",
        [2] = itemName,
        [3] = {}
    }

    local ok, res = pcall(function()
        return RFCraft:InvokeServer(unpack(args))
    end)

    if not ok then
        warn("[RF/Craft] Failed (" .. tostring(itemName) .. "):", res)
    else
        warn("[RF/Craft] Sent successfully (" .. tostring(itemName) .. "):", res)
    end
end

local function craftDragonheart()
    craftByRF("Dragonheart")
end

local function craftDragonstorm()
    craftByRF("Dragonstorm")
end

local function toposition(Pos, onDone)
    local plr = Players.LocalPlayer
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
    local info = TweenInfo.new(distance / SPEED, Enum.EasingStyle.Linear)

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
        pcall(function()
            tweenObj:Cancel()
        end)
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
        pcall(function()
            hrp.CFrame = root.CFrame
        end)
        if typeof(onDone) == "function" then onDone() end
    end)

    return xTweenPosition
end

requestEntranceFirst()
task.wait(0.2)

toposition(targetPos, function()
    task.wait(0.2)
    craftDragonheart()
    task.wait(3) 
    craftDragonstorm()
end)
