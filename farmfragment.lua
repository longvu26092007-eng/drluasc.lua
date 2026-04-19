-- ==========================================
-- [ FARM FRAGMENT SCRIPT ]
-- Chức năng: Chọn Team (UI Click) -> Farm Fragment đến khi đủ 8000 -> Ghi file
-- ==========================================

-- [[ KEY CHECK ]]
local NhapKey = getgenv().Key

if not NhapKey or NhapKey == "" then
    warn("[FarmFrag] ❌ Chưa set getgenv().Key ở executor! Hủy script.")
    return
end
warn("[FarmFrag] ✅ Key nhận được: " .. string.sub(NhapKey, 1, 6) .. "***")

-- [[ CONFIG ]]
getgenv().Team = getgenv().Team or "Marines"
local FRAGMENT_MIN = 4000

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

-- ==========================================
-- [ PHẦN 1 : SERVICES & PLAYER ]
-- ==========================================
local Player  = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local function GetFragments()
    local val = 0
    pcall(function() val = Player.Data.Fragments.Value end)
    return val
end

-- ==========================================
-- [ PHẦN 2 : UI (VÀNG - ĐEN) ]
-- ==========================================
if CoreGui:FindFirstChild("FarmFragUI") then
    CoreGui.FarmFragUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FarmFragUI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size             = UDim2.new(0, 320, 0, 130)
MainFrame.Position         = UDim2.new(0.5, -160, 0.5, -65)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active           = true
MainFrame.Draggable        = true
Instance.new("UIStroke", MainFrame).Color        = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size                   = UDim2.new(1, 0, 0, 30)
Title.Text                   = "Farm Fragment"
Title.TextColor3             = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font                   = Enum.Font.GothamBold
Title.TextSize               = 14

local Line = Instance.new("Frame", Title)
Line.Size             = UDim2.new(1, 0, 0, 1)
Line.Position         = UDim2.new(0, 0, 1, 0)
Line.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
Line.BorderSizePixel  = 0

local ActionStatus = Instance.new("TextLabel", MainFrame)
ActionStatus.Size                   = UDim2.new(1, -20, 0, 22)
ActionStatus.Position               = UDim2.new(0, 10, 0, 38)
ActionStatus.Text                   = "Hành động: Khởi động..."
ActionStatus.TextColor3             = Color3.fromRGB(200, 200, 200)
ActionStatus.Font                   = Enum.Font.Gotham
ActionStatus.BackgroundTransparency = 1
ActionStatus.TextSize               = 12
ActionStatus.TextXAlignment         = Enum.TextXAlignment.Left

local FragLabel = Instance.new("TextLabel", MainFrame)
FragLabel.Size                   = UDim2.new(1, -20, 0, 22)
FragLabel.Position               = UDim2.new(0, 10, 0, 65)
FragLabel.Text                   = "🔮 Fragments: ..."
FragLabel.TextColor3             = Color3.fromRGB(200, 160, 255)
FragLabel.Font                   = Enum.Font.GothamBold
FragLabel.BackgroundTransparency = 1
FragLabel.TextSize               = 13
FragLabel.TextXAlignment         = Enum.TextXAlignment.Left

-- ==========================================
-- [ PHẦN 3 : LOGIC FARM FRAGMENT ]
-- ==========================================

local function RunFarmFragment()
    repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer
    getgenv().Key    = NhapKey
    getgenv().NewUI  = true
    getgenv().Config = {
        ["Select Method Farm"] = "Farm Katakuri",
        ["Hop Find Katakuri"]  = true,
        ["Start Farm"]         = true,
    }
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
    end)
    if ok then
        warn("[FarmFrag] BananaHub load thành công!")
    else
        warn("[FarmFrag] BananaHub load thất bại: " .. tostring(err))
    end
end

do
    local frag = GetFragments()
    FragLabel.Text = "🔮 Fragments: " .. tostring(frag)

    if frag >= FRAGMENT_MIN then
        ActionStatus.Text    = "Hành động: ✅ Fragment đã đủ (" .. frag .. "/" .. FRAGMENT_MIN .. "), không cần farm!"
        FragLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        warn("[FarmFrag] Fragment = " .. frag .. " >= " .. FRAGMENT_MIN .. " → Không cần farm!")
    else
        ActionStatus.Text = "Hành động: Fragment thiếu (" .. frag .. "/" .. FRAGMENT_MIN .. "), bắt đầu farm Katakuri..."
        warn("[FarmFrag] Fragment = " .. frag .. " < " .. FRAGMENT_MIN .. " → Chạy farm!")
        RunFarmFragment()

        repeat
            task.wait(3)
            frag = GetFragments()
            ActionStatus.Text    = string.format("Hành động: Đang farm Fragment (%d/%d)...", frag, FRAGMENT_MIN)
            FragLabel.Text       = "🔮 Fragments: " .. tostring(frag)
            FragLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        until frag >= FRAGMENT_MIN

        FragLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        ActionStatus.Text    = "Hành động: ✅ Đủ Fragment (" .. frag .. "/" .. FRAGMENT_MIN .. ")!"
        warn("[FarmFrag] Fragment đủ rồi!")
    end

    -- GHI FILE SAU KHI ĐỦ FRAGMENT
    ActionStatus.Text = "Hành động: Đang ghi file " .. Player.Name .. ".txt..."
    pcall(function()
        writefile(Player.Name .. ".txt", "Completed-fragment")
    end)
    warn("[FarmFrag] Đã ghi file " .. Player.Name .. ".txt → Completed-fragment")
    task.wait(1)
    ActionStatus.Text = "Hành động: ✅ HOÀN THÀNH! File: " .. Player.Name .. ".txt → Completed-fragment"
end
