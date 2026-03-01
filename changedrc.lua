repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players and game.Players.LocalPlayer

local plr = game.Players.LocalPlayer
local CommF = game:GetService("ReplicatedStorage")
    :WaitForChild("Remotes")
    :WaitForChild("CommF_")

-- CONFIG
local CHECK_EVERY = 3

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")

pcall(function()
    local old = guiParent:FindFirstChild("GearStatusTextOnly")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GearStatusTextOnly"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.IgnoreGuiInset = true end)
ScreenGui.Parent = guiParent

local Text = Instance.new("TextLabel")
Text.BackgroundTransparency = 1
Text.AnchorPoint = Vector2.new(0.5, 0)
Text.Position = UDim2.new(0.5, 0, 0, 10)
Text.Size = UDim2.new(0, 1100, 0, 40)
Text.Font = Enum.Font.GothamBlack
Text.TextSize = 20
Text.TextStrokeTransparency = 0
Text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Text.TextXAlignment = Enum.TextXAlignment.Center
Text.TextYAlignment = Enum.TextYAlignment.Center
Text.Text = "Loading..."
Text.Parent = ScreenGui

pcall(function()
    if workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 700 then
        Text.Size = UDim2.new(0, math.floor(workspace.CurrentCamera.ViewportSize.X - 20), 0, 40)
    end
end)

local function setText(line, mode)
    Text.Text = tostring(line or "")

    if mode == "TRIAL" then
        Text.TextColor3 = Color3.fromRGB(0, 255, 80)
    elseif mode == "BUY" then
        Text.TextColor3 = Color3.fromRGB(255, 0, 255)
    elseif mode == "NO" then
        Text.TextColor3 = Color3.fromRGB(255, 70, 70)
    elseif mode == "DONE" then
        Text.TextColor3 = Color3.fromRGB(255, 200, 0)
    else
        Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- ===== CHECK =====
local last_line = ""

local function CheckGear()
    local char = plr.Character
    if not char or not char:FindFirstChild("RaceTransformed") then
        return "No Gear", nil, nil, nil
    end

    local ok, ret1, ret2, ret3 = pcall(function()
        return CommF:InvokeServer("UpgradeRace", "Check", 2)
    end)
    if not ok then
        return "No Gear", nil, nil, nil
    end

    print(" UpgradeRace Check ")
    print("ret1 (state):", ret1)
    print("ret2 (progress):", ret2)
    print("ret3 (fragments):", ret3)
    print("======================================")

    local map = {
        "Required Train More",
        (ret3 and ("Can Buy Gear With " .. ret3 .. " Fragments")) or "Required Train More",
        "Required Train More",
        (ret3 and ("Can Buy Gear With " .. ret3 .. " Fragments")) or "Required Train More",
        "Full Gear, Full 5 Training Seassions (Full Update)", -- ret1 = 5
        (ret2 and ("Gear 3, Upgrade completed: " .. (ret2 - 2) .. "/3, Need Trains More")) or "Gear 3, Need Trains More",
        (ret3 and ("Can Buy Gear With " .. ret3 .. " Fragments")) or "Can Buy Gear",
        (ret2 and ("Full Gear, Remaining: " .. (10 - ret2) .. "/5, Training Seassions")) or "Full Gear" -- ret1 = 8
    }

    if map[ret1] then
        return map[ret1], ret1, ret2, ret3
    end

    return "No Gear", ret1, ret2, ret3
end

local function getRemaining(txt)
    local n = tostring(txt):match("Remaining:%s*(%d+)%s*/%s*5")
    return n and tonumber(n) or nil
end

local function uiPrefixTier(result, ret1, ret2)
    if tostring(result):find("Full 5 Training Seassions %(Full Update%)") then
        return "Tier 10"
    end

    local rem = getRemaining(result)
    if rem then
        return "Tier 5"
    end

    if tostring(result):find("Can Buy Gear With") and tonumber(ret2) then
        return "Tier " .. tostring(tonumber(ret2) + 1)
    end

    if tonumber(ret1) then
        return "State " .. tostring(ret1)
    end

    return nil
end

-- ✅ CHỈ THÊM PHẦN NÀY
local fileWritten = false

local function updateUI()
    local result, ret1, ret2 = CheckGear()

    local tierTxt = uiPrefixTier(result, ret1, ret2)
    local line = tierTxt and (tierTxt .. " | " .. result) or result

    local mode = "NORMAL"
    if string.find(result, "Ready For Trial") then mode = "TRIAL" end
    if string.find(result, "Can Buy Gear With") then mode = "BUY" end
    if string.find(result, "No Gear") then mode = "NO" end
    if string.find(result, "Full 5 Training Seassions") then mode = "DONE" end

    -- ✅ CHỈ THÊM PHẦN NÀY
    if not fileWritten then
        local rem = getRemaining(result)
        if rem and rem == 5 then
            pcall(function()
                local fileName = plr.Name .. ".txt"
                if not isfile(fileName) then
                    writefile(fileName, "Completed-draco4fg")
                    print("[AutoLog] Đã ghi file: " .. fileName)
                end
            end)
            fileWritten = true
        end
    end

    if line ~= last_line then
        last_line = line
        setText(line, mode)
    end
end

while task.wait(CHECK_EVERY) do
    updateUI()
end
