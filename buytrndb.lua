--[[
    🔍 BUY TRAINING DEBUGGER - VU NGUYEN
    Bắt remote khi mua Training Session ở đảo Hydra
    ❌ KHÔNG hook __namecall
    ✅ Wrap từng remote cụ thể đã scan được
]]

if getgenv().BTD then pcall(getgenv().BTD) end

local Player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local playerGui = Player:WaitForChild("PlayerGui")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "BuyTrainingDebug"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 480)
main.Position = UDim2.new(0.5, -200, 0.5, -240)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(255, 120, 20)

-- Bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 30)
bar.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local barfix = Instance.new("Frame")
barfix.Size = UDim2.new(1, 0, 0, 10)
barfix.Position = UDim2.new(0, 0, 1, -10)
barfix.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
barfix.BorderSizePixel = 0
barfix.Parent = bar

local titleL = Instance.new("TextLabel")
titleL.Size = UDim2.new(1, -80, 1, 0)
titleL.Position = UDim2.new(0, 10, 0, 0)
titleL.BackgroundTransparency = 1
titleL.Text = "🔍 BUY TRAINING DEBUGGER"
titleL.TextColor3 = Color3.fromRGB(255, 120, 20)
titleL.TextSize = 11
titleL.Font = Enum.Font.GothamBold
titleL.TextXAlignment = Enum.TextXAlignment.Left
titleL.Parent = bar

local statusDot = Instance.new("TextLabel")
statusDot.Size = UDim2.new(0, 60, 0, 16)
statusDot.Position = UDim2.new(1, -108, 0, 7)
statusDot.BackgroundColor3 = Color3.fromRGB(30, 120, 30)
statusDot.Text = "● LIVE"
statusDot.TextColor3 = Color3.fromRGB(100, 255, 100)
statusDot.TextSize = 9
statusDot.Font = Enum.Font.GothamBold
statusDot.Parent = bar
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(0, 4)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 28, 0, 18)
clearBtn.Position = UDim2.new(1, -72, 0, 6)
clearBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 25)
clearBtn.Text = "🗑"
clearBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
clearBtn.TextSize = 10
clearBtn.BorderSizePixel = 0
clearBtn.Parent = bar
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 4)

local pauseBtn = Instance.new("TextButton")
pauseBtn.Size = UDim2.new(0, 18, 0, 18)
pauseBtn.Position = UDim2.new(1, -42, 0, 6)
pauseBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 20)
pauseBtn.Text = "⏸"
pauseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pauseBtn.TextSize = 10
pauseBtn.BorderSizePixel = 0
pauseBtn.Parent = bar
Instance.new("UICorner", pauseBtn).CornerRadius = UDim.new(0, 4)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -22, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 10
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- Instruction
local instrL = Instance.new("TextLabel")
instrL.Size = UDim2.new(1, -12, 0, 22)
instrL.Position = UDim2.new(0, 6, 0, 32)
instrL.BackgroundColor3 = Color3.fromRGB(40, 30, 15)
instrL.Text = "  💡 Bấm MUA ở NPC → xem remote hiện bên dưới"
instrL.TextColor3 = Color3.fromRGB(255, 200, 100)
instrL.TextSize = 10
instrL.Font = Enum.Font.GothamSemibold
instrL.TextXAlignment = Enum.TextXAlignment.Left
instrL.BorderSizePixel = 0
instrL.Parent = main
Instance.new("UICorner", instrL).CornerRadius = UDim.new(0, 5)

-- Log scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -60)
scroll.Position = UDim2.new(0, 6, 0, 56)
scroll.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 120, 20)
scroll.Parent = main
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 2)
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Parent = scroll

-- ═══════════ STATE ═══════════
local running = true
local paused = false
local logCount = 0
local conns = {}

-- ═══════════ LOG ═══════════
local function Log(tag, text, color, extraLines)
    if paused then return end
    logCount = logCount + 1
    
    local lines = extraLines or {}
    local height = 30 + (#lines * 13)
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, height)
    card.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
    card.BorderSizePixel = 0
    card.LayoutOrder = -logCount
    card.Parent = scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 5)
    
    -- Highlight important
    if tag == "INVOKE" or tag == "FIRE" or tag == "RETURN" then
        Instance.new("UIStroke", card).Color = color or Color3.fromRGB(255, 150, 30)
        card.BackgroundColor3 = Color3.fromRGB(25, 20, 12)
    end

    -- Badge
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 50, 0, 14)
    badge.Position = UDim2.new(0, 3, 0, 2)
    badge.BackgroundColor3 = color or Color3.fromRGB(80, 80, 120)
    badge.Text = tag
    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
    badge.TextSize = 8
    badge.Font = Enum.Font.GothamBold
    badge.Parent = card
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)

    -- # + time
    local numL = Instance.new("TextLabel")
    numL.Size = UDim2.new(0, 80, 0, 14)
    numL.Position = UDim2.new(0, 56, 0, 2)
    numL.BackgroundTransparency = 1
    numL.Text = "#" .. logCount .. " " .. os.date("%H:%M:%S")
    numL.TextColor3 = Color3.fromRGB(90, 90, 120)
    numL.TextSize = 8
    numL.Font = Enum.Font.Gotham
    numL.TextXAlignment = Enum.TextXAlignment.Left
    numL.Parent = card

    -- Main text
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -8, 0, 13)
    txt.Position = UDim2.new(0, 3, 0, 16)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(200, 200, 220)
    txt.TextSize = 10
    txt.Font = Enum.Font.GothamSemibold
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextTruncate = Enum.TextTruncate.AtEnd
    txt.Parent = card

    -- Extra lines
    for i, line in ipairs(lines) do
        local el = Instance.new("TextLabel")
        el.Size = UDim2.new(1, -8, 0, 12)
        el.Position = UDim2.new(0, 3, 0, 28 + (i-1) * 13)
        el.BackgroundTransparency = 1
        el.Text = line
        el.TextColor3 = Color3.fromRGB(150, 150, 180)
        el.TextSize = 9
        el.Font = Enum.Font.Gotham
        el.TextXAlignment = Enum.TextXAlignment.Left
        el.TextTruncate = Enum.TextTruncate.AtEnd
        el.Parent = card
    end

    warn("[#" .. logCount .. " " .. tag .. "] " .. text)
    for _, l in ipairs(lines) do warn("  " .. l) end
    
    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 4)
    end)
end

-- ═══════════ HELPER: SERIALIZE ARGS ═══════════
local function SerializeArgs(...)
    local args = {...}
    local parts = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "Instance" then
            table.insert(parts, "[" .. i .. "] " .. t .. " = " .. v:GetFullName())
        elseif t == "table" then
            local sub = {}
            for k, val in pairs(v) do
                table.insert(sub, tostring(k) .. "=" .. tostring(val))
            end
            table.insert(parts, "[" .. i .. "] table = {" .. table.concat(sub, ", ") .. "}")
        elseif t == "Vector3" or t == "CFrame" then
            table.insert(parts, "[" .. i .. "] " .. t .. " = " .. tostring(v))
        else
            table.insert(parts, "[" .. i .. "] " .. t .. " = " .. tostring(v))
        end
    end
    return parts
end

-- ═══════════ WRAP REMOTES (KHÔNG HOOK __namecall) ═══════════
-- Dùng hookfunction để wrap từng remote cụ thể

local wrappedCount = 0

local function WrapRemoteFunction(remote)
    pcall(function()
        local oldInvoke = remote.InvokeServer
        remote.InvokeServer = newcclosure(function(self, ...)
            local argLines = SerializeArgs(...)
            Log("INVOKE", "→ " .. remote:GetFullName(), Color3.fromRGB(255, 130, 30), argLines)
            
            local results = {oldInvoke(self, ...)}
            
            -- Log return
            local retLines = {}
            for i, v in ipairs(results) do
                local t = typeof(v)
                if t == "table" then
                    local sub = {}
                    for k, val in pairs(v) do table.insert(sub, tostring(k) .. "=" .. tostring(val)) end
                    table.insert(retLines, "ret[" .. i .. "] table = {" .. table.concat(sub, ", "):sub(1, 200) .. "}")
                else
                    table.insert(retLines, "ret[" .. i .. "] " .. t .. " = " .. tostring(v))
                end
            end
            Log("RETURN", "← " .. remote.Name, Color3.fromRGB(50, 180, 50), retLines)
            
            return unpack(results)
        end)
        wrappedCount = wrappedCount + 1
    end)
end

local function WrapRemoteEvent(remote)
    pcall(function()
        -- Bắt outgoing (FireServer)
        local oldFire = remote.FireServer
        remote.FireServer = newcclosure(function(self, ...)
            local argLines = SerializeArgs(...)
            Log("FIRE", "→ " .. remote:GetFullName(), Color3.fromRGB(30, 130, 255), argLines)
            return oldFire(self, ...)
        end)
        wrappedCount = wrappedCount + 1
        
        -- Bắt incoming (OnClientEvent)
        local conn = remote.OnClientEvent:Connect(function(...)
            if running and not paused then
                local argLines = SerializeArgs(...)
                Log("EVENT", "← " .. remote:GetFullName(), Color3.fromRGB(100, 200, 100), argLines)
            end
        end)
        table.insert(conns, conn)
    end)
end

-- ═══════════ WRAP TẤT CẢ REMOTE LIÊN QUAN ═══════════
Log("INIT", "Đang wrap remotes...", Color3.fromRGB(80, 80, 120))

-- 1. DracoTrial (từ scan: ReplicatedStorage.Remotes.DracoTrial)
pcall(function()
    local r = RS.Remotes:FindFirstChild("DracoTrial")
    if r then
        if r:IsA("RemoteFunction") then WrapRemoteFunction(r)
        elseif r:IsA("RemoteEvent") then WrapRemoteEvent(r) end
        Log("WRAP", "✅ DracoTrial → " .. r.ClassName, Color3.fromRGB(255, 100, 255))
    end
end)

-- 2. UpgradeInvoke (RF/Item/UpgradeInvoke)
pcall(function()
    local modules = RS:FindFirstChild("Modules")
    if modules then
        for _, desc in pairs(modules:GetDescendants()) do
            if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) 
                and (desc.Name:lower():find("upgrade") or desc.Name:lower():find("invoke")) then
                if desc:IsA("RemoteFunction") then WrapRemoteFunction(desc)
                else WrapRemoteEvent(desc) end
                Log("WRAP", "✅ " .. desc.Name .. " → " .. desc:GetFullName(), Color3.fromRGB(200, 100, 255))
            end
        end
    end
end)

-- 3. CommF_ 
pcall(function()
    local commF = RS.Remotes:FindFirstChild("CommF_")
    if commF and commF:IsA("RemoteFunction") then
        WrapRemoteFunction(commF)
        Log("WRAP", "✅ CommF_ → " .. commF:GetFullName(), Color3.fromRGB(200, 150, 50))
    end
end)

-- 4. UsedRaceSkill
pcall(function()
    local r = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("UsedRaceSkill")
    if r then
        WrapRemoteEvent(r)
        Log("WRAP", "✅ UsedRaceSkill", Color3.fromRGB(100, 180, 100))
    end
end)

-- 5. HydraIslandClient.RemoteFunction
pcall(function()
    local hf = workspace:FindFirstChild("HydraIslandClient")
    if hf then
        for _, c in pairs(hf:GetDescendants()) do
            if c:IsA("RemoteFunction") then
                WrapRemoteFunction(c)
                Log("WRAP", "✅ Hydra RF → " .. c:GetFullName(), Color3.fromRGB(255, 150, 30))
            elseif c:IsA("RemoteEvent") then
                WrapRemoteEvent(c)
                Log("WRAP", "✅ Hydra RE → " .. c:GetFullName(), Color3.fromRGB(255, 150, 30))
            end
        end
    end
end)

-- 6. Dragon Talon remotes (từ scan)
pcall(function()
    local char = Player.Character
    if char then
        for _, desc in pairs(char:GetDescendants()) do
            if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent"))
                and (desc:GetFullName():lower():find("dragon") or desc:GetFullName():lower():find("draco")) then
                if desc:IsA("RemoteFunction") then WrapRemoteFunction(desc)
                else WrapRemoteEvent(desc) end
                Log("WRAP", "✅ Char: " .. desc.Name .. " → " .. desc:GetFullName(), Color3.fromRGB(200, 130, 50))
            end
        end
    end
end)

-- 7. Waterfall Island remote
pcall(function()
    local wf = workspace:FindFirstChild("Map")
    if wf then
        for _, desc in pairs(wf:GetDescendants()) do
            if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent"))
                and (desc:GetFullName():lower():find("waterfall") or desc:GetFullName():lower():find("island")) then
                if desc:IsA("RemoteFunction") then WrapRemoteFunction(desc)
                else WrapRemoteEvent(desc) end
                Log("WRAP", "✅ Map: " .. desc.Name, Color3.fromRGB(100, 150, 200))
            end
        end
    end
end)

-- 8. Catch-all: mọi remote trong RS.Remotes
pcall(function()
    for _, r in pairs(RS.Remotes:GetChildren()) do
        local n = r.Name:lower()
        if n:find("draco") or n:find("hydra") or n:find("race") or n:find("upgrade") or n:find("trial") or n:find("gear") or n:find("ancient") then
            if r:IsA("RemoteFunction") then
                WrapRemoteFunction(r)
                Log("WRAP", "✅ RS.Remotes: " .. r.Name .. " (RF)", Color3.fromRGB(150, 120, 200))
            elseif r:IsA("RemoteEvent") then
                WrapRemoteEvent(r)
                Log("WRAP", "✅ RS.Remotes: " .. r.Name .. " (RE)", Color3.fromRGB(150, 120, 200))
            end
        end
    end
end)

Log("INIT", "✅ Wrapped " .. wrappedCount .. " remotes | Giờ đi MUA TRAINING SESSION!", Color3.fromRGB(80, 200, 80))

-- ═══════════ BUTTONS ═══════════
clearBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    logCount = 0
end)

local isPaused = false
pauseBtn.MouseButton1Click:Connect(function()
    isPaused = not isPaused
    paused = isPaused
    pauseBtn.Text = isPaused and "▶" or "⏸"
    statusDot.Text = isPaused and "● PAUSE" or "● LIVE"
    statusDot.BackgroundColor3 = isPaused and Color3.fromRGB(120, 80, 20) or Color3.fromRGB(30, 120, 30)
    statusDot.TextColor3 = isPaused and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(100, 255, 100)
end)

closeBtn.MouseButton1Click:Connect(function()
    running = false
    for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
    getgenv().BTD = nil
    gui:Destroy()
end)
getgenv().BTD = function()
    running = false
    for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

print("🔍 Buy Training Debugger | " .. wrappedCount .. " remotes wrapped | RightShift ẩn/hiện")
