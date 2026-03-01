--[[
    🔍 HYDRA REMOTE DEBUGGER V2 - VU NGUYEN
    ❌ KHÔNG hook __namecall
    ✅ Chỉ gọi trực tiếp + listener OnClientEvent
]]

if getgenv().HydraDebug then pcall(getgenv().HydraDebug) end

local Player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local playerGui = Player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "HydraDebugV2"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 380, 0, 460)
main.Position = UDim2.new(0.5, -190, 0.5, -230)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", main).Color = Color3.fromRGB(255, 150, 30)

-- Bar
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 32)
bar.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
bar.BorderSizePixel = 0
bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)
local fix = Instance.new("Frame")
fix.Size = UDim2.new(1, 0, 0, 10)
fix.Position = UDim2.new(0, 0, 1, -10)
fix.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
fix.BorderSizePixel = 0
fix.Parent = bar

Instance.new("TextLabel", bar).Size = UDim2.new(1, -70, 1, 0)
bar.TextLabel.Position = UDim2.new(0, 10, 0, 0)
bar.TextLabel.BackgroundTransparency = 1
bar.TextLabel.Text = "🔍 HYDRA DEBUGGER V2 (Safe)"
bar.TextLabel.TextColor3 = Color3.fromRGB(255, 150, 30)
bar.TextLabel.TextSize = 11
bar.TextLabel.Font = Enum.Font.GothamBold
bar.TextLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 30, 0, 22)
clearBtn.Position = UDim2.new(1, -62, 0, 5)
clearBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 25)
clearBtn.Text = "CLR"
clearBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
clearBtn.TextSize = 9
clearBtn.Font = Enum.Font.GothamBold
clearBtn.BorderSizePixel = 0
clearBtn.Parent = bar
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

-- Log scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -150)
scroll.Position = UDim2.new(0, 6, 0, 36)
scroll.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 150, 30)
scroll.Parent = main
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 2)
lay.SortOrder = Enum.SortOrder.LayoutOrder
lay.Parent = scroll

local logCount = 0

-- ═══════════ LOG ═══════════
local function Log(tag, text, color)
    logCount = logCount + 1
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 28)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    card.BorderSizePixel = 0
    card.LayoutOrder = -logCount
    card.Parent = scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 4)

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 45, 0, 14)
    badge.Position = UDim2.new(0, 3, 0, 2)
    badge.BackgroundColor3 = color or Color3.fromRGB(80, 80, 120)
    badge.Text = tag
    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
    badge.TextSize = 8
    badge.Font = Enum.Font.GothamBold
    badge.Parent = card
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -8, 0, 12)
    txt.Position = UDim2.new(0, 3, 0, 16)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(180, 180, 200)
    txt.TextSize = 9
    txt.Font = Enum.Font.Gotham
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextTruncate = Enum.TextTruncate.AtEnd
    txt.Parent = card

    warn("[" .. tag .. "] " .. text)
    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 4)
    end)
end

-- ═══════════ BUTTONS ═══════════
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, -12, 0, 108)
btnFrame.Position = UDim2.new(0, 6, 1, -114)
btnFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
btnFrame.BorderSizePixel = 0
btnFrame.Parent = main
Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 6)

local bLay = Instance.new("UIGridLayout")
bLay.CellSize = UDim2.new(0.5, -4, 0, 30)
bLay.CellPadding = UDim2.new(0, 4, 0, 4)
bLay.SortOrder = Enum.SortOrder.LayoutOrder
bLay.Parent = btnFrame
Instance.new("UIPadding", btnFrame).PaddingTop = UDim.new(0, 4)
Instance.new("UIPadding", btnFrame).PaddingLeft = UDim.new(0, 4)

local function MakeBtn(text, order, color, callback)
    local b = Instance.new("TextButton")
    b.Text = text
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.LayoutOrder = order
    b.Parent = btnFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function()
        b.Text = "⏳..."
        pcall(callback)
        task.wait(0.3)
        b.Text = text
    end)
    return b
end

-- ═══════════ REMOTES ═══════════
local commF = nil
pcall(function() commF = RS:WaitForChild("Remotes", 5):FindFirstChild("CommF_") end)

local hydraRemote = nil
pcall(function()
    local hf = workspace:FindFirstChild("HydraIslandClient")
    if hf then
        for _, c in pairs(hf:GetDescendants()) do
            if c:IsA("RemoteFunction") or c:IsA("RemoteEvent") then
                hydraRemote = c
                break
            end
        end
    end
end)

Log("INIT", "CommF_: " .. (commF and "✅" or "❌") .. " | Hydra: " .. (hydraRemote and "✅ " .. hydraRemote.ClassName or "❌"), Color3.fromRGB(50, 120, 50))

-- ═══════════ TEST BUTTONS ═══════════

-- 1. Hydra Interacted
MakeBtn("🐉 Hydra Interacted", 1, Color3.fromRGB(150, 80, 20), function()
    if hydraRemote and hydraRemote:IsA("RemoteFunction") then
        local ret = hydraRemote:InvokeServer("Interacted")
        Log("HYDRA", "InvokeServer('Interacted') → Return: " .. tostring(ret), Color3.fromRGB(255, 150, 30))
    elseif hydraRemote and hydraRemote:IsA("RemoteEvent") then
        hydraRemote:FireServer("Interacted")
        Log("HYDRA", "FireServer('Interacted')", Color3.fromRGB(255, 150, 30))
    else
        Log("ERROR", "Hydra remote không tìm thấy!", Color3.fromRGB(255, 50, 50))
    end
end)

-- 2. UpgradeRace Check
MakeBtn("⚙ UpgradeRace Check", 2, Color3.fromRGB(100, 50, 150), function()
    if commF then
        local v1, v2, v3 = commF:InvokeServer("UpgradeRace", "Check")
        Log("RACE", "Check → v1=" .. tostring(v1) .. " v2=" .. tostring(v2) .. " v3=" .. tostring(v3), Color3.fromRGB(200, 100, 255))
        
        -- Dịch status
        local msg = ""
        if v1 == 0 then msg = "→ Ready For Trial!"
        elseif v1 == 1 or v1 == 3 then msg = "→ Required Train More"
        elseif v1 == 2 or v1 == 4 or v1 == 7 then msg = "→ Can Buy Gear (" .. tostring(v3) .. " fragments)"
        elseif v1 == 5 then msg = "→ DONE! Race completed!"
        elseif v1 == 6 then msg = "→ Upgrades: " .. tostring((tonumber(v2) or 2) - 2) .. "/3"
        elseif v1 == 8 then msg = "→ Training: " .. tostring(v2) .. "/10 (còn " .. tostring(10 - (tonumber(v2) or 0)) .. ")"
        end
        if msg ~= "" then
            Log("STATUS", msg, Color3.fromRGB(150, 80, 255))
        end
    else
        Log("ERROR", "CommF_ không tìm thấy!", Color3.fromRGB(255, 50, 50))
    end
end)

-- 3. UpgradeRace Buy
MakeBtn("💰 UpgradeRace Buy", 3, Color3.fromRGB(120, 100, 20), function()
    if commF then
        local ret = commF:InvokeServer("UpgradeRace", "Buy")
        Log("BUY", "UpgradeRace Buy → Return: " .. tostring(ret), Color3.fromRGB(255, 200, 50))
    end
end)

-- 4. getTitles
MakeBtn("📋 getTitles", 4, Color3.fromRGB(40, 80, 120), function()
    if commF then
        local ret = commF:InvokeServer("getTitles")
        local count = 0
        if type(ret) == "table" then for _ in pairs(ret) do count = count + 1 end end
        Log("TITLE", "getTitles → " .. type(ret) .. " (" .. count .. " items)", Color3.fromRGB(80, 160, 255))
    end
end)

-- 5. Check Race + Transform
MakeBtn("👤 Race + Transform", 5, Color3.fromRGB(60, 80, 60), function()
    local race = "?"
    pcall(function() race = Player.Data.Race.Value end)
    local hasRT = false
    pcall(function() hasRT = Player.Character:FindFirstChild("RaceTransformed") and true or false end)
    local rtVal = "N/A"
    pcall(function() rtVal = tostring(Player.Character.RaceTransformed.Value) end)
    Log("PLAYER", "Race=" .. race .. " | Transform=" .. (hasRT and "✅ ("..rtVal..")" or "❌"), Color3.fromRGB(100, 160, 100))
end)

-- 6. Scan all workspace remotes
MakeBtn("📡 Scan WS Remotes", 6, Color3.fromRGB(80, 60, 100), function()
    local count = 0
    for _, desc in pairs(workspace:GetDescendants()) do
        if desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent") then
            local path = desc:GetFullName()
            if path:lower():find("hydra") or path:lower():find("race") or path:lower():find("draco") or path:lower():find("upgrade") or path:lower():find("island") then
                Log("SCAN", desc.ClassName .. " → " .. path, Color3.fromRGB(130, 100, 180))
                count = count + 1
            end
        end
    end
    if count == 0 then
        Log("SCAN", "Không tìm thấy remote liên quan trong workspace", Color3.fromRGB(180, 100, 100))
    end
    -- Scan RS too
    for _, desc in pairs(RS:GetDescendants()) do
        if desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent") then
            local n = desc.Name:lower()
            if n:find("hydra") or n:find("race") or n:find("draco") or n:find("upgrade") then
                Log("SCAN", "RS: " .. desc.ClassName .. " → " .. desc:GetFullName(), Color3.fromRGB(130, 100, 180))
            end
        end
    end
end)

-- ═══════════ SAFE LISTENERS (không hook) ═══════════
local running = true
local conns = {}

-- Listen Hydra OnClientEvent
pcall(function()
    local hf = workspace:FindFirstChild("HydraIslandClient")
    if hf then
        for _, c in pairs(hf:GetDescendants()) do
            if c:IsA("RemoteEvent") then
                local conn = c.OnClientEvent:Connect(function(...)
                    if running then
                        local args = {}
                        for _, v in pairs({...}) do table.insert(args, tostring(v)) end
                        Log("EVENT", "Hydra → " .. c.Name .. " | " .. table.concat(args, ", "), Color3.fromRGB(255, 180, 50))
                    end
                end)
                table.insert(conns, conn)
            end
        end
    end
end)

-- Listen RS remotes
pcall(function()
    local remotes = RS:FindFirstChild("Remotes")
    if remotes then
        for _, c in pairs(remotes:GetChildren()) do
            if c:IsA("RemoteEvent") then
                local conn = c.OnClientEvent:Connect(function(...)
                    if running then
                        local args = {}
                        for _, v in pairs({...}) do table.insert(args, tostring(v):lower()) end
                        local all = table.concat(args, " ")
                        if all:find("hydra") or all:find("race") or all:find("upgrade") or all:find("draco") or all:find("gear") then
                            Log("EVENT", "RS → " .. c.Name .. " | " .. table.concat(args, ", "), Color3.fromRGB(100, 150, 255))
                        end
                    end
                end)
                table.insert(conns, conn)
            end
        end
    end
end)

-- Clear / Close
clearBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    logCount = 0
end)

closeBtn.MouseButton1Click:Connect(function()
    running = false
    for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
    getgenv().HydraDebug = nil
    gui:Destroy()
end)
getgenv().HydraDebug = function()
    running = false
    for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end

UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

print("🔍 Hydra Debugger V2 | KHÔNG hook | Game chạy bình thường | RightShift ẩn/hiện")
