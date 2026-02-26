-- ==========================================
-- [ PHẦN 0 : CHỌN TEAM & ĐỢI GAME LOAD ]
-- ==========================================
getgenv().Team = getgenv().Team or "Marines"
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

-- ==========================================
-- [ PHẦN 1 ] LÕI LOGIC (CORE)
-- ==========================================
local Player       = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")

local function TweenTo(targetCFrame)
    local character = Player.Character or Player.CharacterAdded:Wait()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

    local hrp      = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance <= 250 then
        hrp.CFrame = targetCFrame
        return true
    end

    local bv = hrp:FindFirstChild("DracoAntiGravity") or Instance.new("BodyVelocity")
    bv.Name     = "DracoAntiGravity"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent   = hrp

    local speed    = 300
    local time     = distance / speed
    local tweenObj = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = targetCFrame})

    local noclip
    noclip = RunService.Stepped:Connect(function()
        if humanoid and humanoid.Parent then
            humanoid:ChangeState(11)
        end
        if character and character.Parent then
            for _, part in pairs(character:GetDescendants()) do
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

    if humanoid and humanoid.Parent and humanoid.Health > 0 then
        humanoid:ChangeState(8)
        return true
    end
    return false
end

-- ==========================================
-- [ PHẦN 2 ] GIAO DIỆN UI (VÀNG - ĐEN)
-- ==========================================

if CoreGui:FindFirstChild("DracoAutoUI") then
    CoreGui.DracoAutoUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "DracoAutoUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size             = UDim2.new(0, 450, 0, 160)
MainFrame.Position         = UDim2.new(0.5, -225, 0.5, -80)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active           = true
MainFrame.Draggable        = true
Instance.new("UIStroke", MainFrame).Color        = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size               = UDim2.new(1, 0, 0, 35)
Title.Text               = "Draco Auto"
Title.TextColor3         = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 14
Title.TextXAlignment     = Enum.TextXAlignment.Center

local Line = Instance.new("Frame", Title)
Line.Size             = UDim2.new(1, 0, 0, 1)
Line.Position         = UDim2.new(0, 0, 1, 0)
Line.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
Line.BorderSizePixel  = 0

local InfoPanel = Instance.new("Frame", MainFrame)
InfoPanel.Size               = UDim2.new(1, -20, 1, -50)
InfoPanel.Position           = UDim2.new(0, 10, 0, 40)
InfoPanel.BackgroundTransparency = 1

local ActionStatus = Instance.new("TextLabel", InfoPanel)
ActionStatus.Size               = UDim2.new(1, 0, 0, 25)
ActionStatus.Position           = UDim2.new(0, 0, 0, 0)
ActionStatus.Text               = "Hành động: Khởi động kịch bản..."
ActionStatus.TextColor3         = Color3.fromRGB(200, 200, 200)
ActionStatus.Font               = Enum.Font.Gotham
ActionStatus.BackgroundTransparency = 1
ActionStatus.TextSize           = 12
ActionStatus.TextXAlignment     = Enum.TextXAlignment.Left

local MasteryLabel = Instance.new("TextLabel", InfoPanel)
MasteryLabel.Size               = UDim2.new(1, 0, 0, 25)
MasteryLabel.Position           = UDim2.new(0, 0, 0, 25)
MasteryLabel.Text               = "Mastery: Chờ xác nhận vũ khí..."
MasteryLabel.TextColor3         = Color3.fromRGB(255, 200, 0)
MasteryLabel.Font               = Enum.Font.GothamBold
MasteryLabel.BackgroundTransparency = 1
MasteryLabel.TextSize           = 13
MasteryLabel.TextXAlignment     = Enum.TextXAlignment.Left
