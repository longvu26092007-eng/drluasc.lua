--[[
    🔍 HYDRA REMOTE DEBUGGER - VU NGUYEN
    Bắt tất cả remote liên quan Hydra + UpgradeRace + Draco
    Hiện realtime trên UI + in ra console F9
]]

if getgenv().HydraDebug then pcall(getgenv().HydraDebug) end

local Player = game.Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local playerGui = Player:WaitForChild("PlayerGui")

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "HydraDebugger"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = playerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 500)
main.Position = UDim2.new(0.5, -200, 0.5, -250)
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
bar.Size = UDim2.new(1, 0, 0, 34)
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

local titleL = Instance.new("TextLabel")
titleL.Size = UDim2.new(1, -70, 1, 0)
titleL.Position = UDim2.new(0, 10, 0, 0)
titleL.BackgroundTransparency = 1
titleL.Text = "🔍 HYDRA REMOTE DEBUGGER"
titleL.TextColor3 = Color3.fromRGB(255, 150, 30)
titleL.TextSize = 12
titleL.Font = Enum.Font.GothamBold
titleL.TextXAlignment = Enum.TextXAlignment.Left
titleL.Parent = bar

-- Buttons
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 40, 0, 22)
clearBtn.Position = UDim2.new(1, -98, 0, 6)
clearBtn.BackgroundColor3 = Color3.fromRGB(60, 50, 30)
clearBtn.Text = "CLR"
clearBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
clearBtn.TextSize = 10
clearBtn.Font = Enum.Font.GothamBold
clearBtn.BorderSizePixel = 0
clearBtn.Parent = bar
Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

local testBtn = Instance.new("TextButton")
testBtn.Size = UDim2.new(0, 40, 0, 22)
testBtn.Position = UDim2.new(1, -54, 0, 6)
testBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 30)
testBtn.Text = "TEST"
testBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
testBtn.TextSize = 10
testBtn.Font = Enum.Font.GothamBold
testBtn.BorderSizePixel = 0
testBtn.Parent = bar
Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Info panel (hiện các remote đã tìm được)
local infoPanel = Instance.new("Frame")
infoPanel.Size = UDim2.new(1, -12, 0, 60)
infoPanel.Position = UDim2.new(0, 6, 0, 38)
infoPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
infoPanel.BorderSizePixel = 0
infoPanel.Parent = main
Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 6)

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -10, 1, -4)
infoText.Position = UDim2.new(0, 5, 0, 2)
infoText.BackgroundTransparency = 1
infoText.Text = "⏳ Đang scan remote..."
infoText.TextColor3 = Color3.fromRGB(180, 180, 200)
infoText.TextSize = 10
infoText.Font = Enum.Font.Gotham
infoText.TextWrapped = true
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.Parent = infoPanel

-- Log scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -106)
scroll.Position = UDim2.new(0, 6, 0, 102)
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

-- ═══════════ SCAN REMOTES ═══════════
local hydraRemote = nil
local commF = nil
local allRemotes = {}

-- Tìm Hydra remote
local function ScanRemotes()
    local info = {}
    
    -- 1. CommF_
    pcall(function()
        commF = RS:WaitForChild("Remotes", 5):FindFirstChild("CommF_")
        if commF then
            table.insert(info, "✅ CommF_: " .. commF:GetFullName())
        end
    end)
    
    -- 2. Hydra Island remotes
    pcall(function()
        local hydraFolder = workspace:FindFirstChild("HydraIslandClient")
        if hydraFolder then
            for _, child in pairs(hydraFolder:GetChildren()) do
                if child:IsA("RemoteFunction") or child:IsA("RemoteEvent") then
                    hydraRemote = child
                    table.insert(info, "✅ Hydra: " .. child.ClassName .. " → " .. child:GetFullName())
                end
            end
            if not hydraRemote then
                for _, child in pairs(hydraFolder:GetDescendants()) do
                    if child:IsA("RemoteFunction") or child:IsA("RemoteEvent") then
                        hydraRemote = child
                        table.insert(info, "✅ Hydra: " .. child.ClassName .. " → " .. child:GetFullName())
                    end
                end
            end
        else
            table.insert(info, "❌ HydraIslandClient không tìm thấy")
        end
    end)
    
    -- 3. Scan tất cả remote trong workspace liên quan hydra/draco/race
    pcall(function()
        for _, desc in pairs(workspace:GetDescendants()) do
            if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) then
                local path = desc:GetFullName():lower()
                if path:find("hydra") or path:find("draco") or path:find("race") or path:find("upgrade") then
                    if desc ~= hydraRemote then
                        table.insert(info, "📡 " .. desc.ClassName .. " → " .. desc:GetFullName())
                    end
                    allRemotes[desc:GetFullName()] = desc
                end
            end
        end
    end)
    
    -- 4. Scan ReplicatedStorage
    pcall(function()
        for _, desc in pairs(RS:GetDescendants()) do
            if (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) then
                local name = desc.Name:lower()
                if name:find("hydra") or name:find("draco") or name:find("race") or name:find("upgrade") then
                    table.insert(info, "📡 RS: " .. desc.ClassName .. " → " .. desc:GetFullName())
                    allRemotes[desc:GetFullName()] = desc
                end
            end
        end
    end)
    
    if #info == 0 then
        table.insert(info, "❌ Không tìm thấy remote nào")
    end
    
    infoText.Text = table.concat(info, "\n")
end

-- ═══════════ LOG FUNCTIONS ═══════════
local function AddLog(logType, source, args, returnVal)
    logCount = logCount + 1
    
    local argsStr = ""
    if type(args) == "table" then
        local parts = {}
        for i, v in pairs(args) do
            table.insert(parts, tostring(i) .. "=" .. tostring(v))
        end
        argsStr = table.concat(parts, ", ")
    else
        argsStr = tostring(args or "")
    end
    
    -- Màu theo loại
    local typeColor = Color3.fromRGB(100, 180, 255) -- mặc định xanh
    local isImportant = false
    
    if source:find("Hydra") or source:find("hydra") then
        typeColor = Color3.fromRGB(255, 150, 30)
        isImportant = true
    elseif argsStr:find("UpgradeRace") or argsStr:find("Upgrade") then
        typeColor = Color3.fromRGB(255, 80, 255)
        isImportant = true
    elseif argsStr:find("Interact") or argsStr:find("interact") then
        typeColor = Color3.fromRGB(255, 255, 50)
        isImportant = true
    end
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -6, 0, isImportant and 52 or 40)
    card.BackgroundColor3 = isImportant and Color3.fromRGB(25, 20, 10) or Color3.fromRGB(18, 18, 28)
    card.BorderSizePixel = 0
    card.LayoutOrder = -logCount
    card.Parent = scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 5)
    if isImportant then
        Instance.new("UIStroke", card).Color = Color3.fromRGB(255, 150, 30)
    end
    
    -- Badge
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 50, 0, 14)
    badge.Position = UDim2.new(0, 4, 0, 3)
    badge.BackgroundColor3 = logType == "INVOKE" and Color3.fromRGB(200, 100, 30) 
        or logType == "FIRE" and Color3.fromRGB(30, 100, 200) 
        or logType == "RETURN" and Color3.fromRGB(30, 150, 30)
        or Color3.fromRGB(100, 100, 100)
    badge.Text = logType
    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
    badge.TextSize = 8
    badge.Font = Enum.Font.GothamBold
    badge.Parent = card
    Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)
    
    -- #
    local numL = Instance.new("TextLabel")
    numL.Size = UDim2.new(0, 25, 0, 14)
    numL.Position = UDim2.new(0, 58, 0, 3)
    numL.BackgroundTransparency = 1
    numL.Text = "#" .. logCount
    numL.TextColor3 = Color3.fromRGB(100, 100, 130)
    numL.TextSize = 9
    numL.Font = Enum.Font.Gotham
    numL.Parent = card
    
    -- Source
    local srcL = Instance.new("TextLabel")
    srcL.Size = UDim2.new(1, -10, 0, 13)
    srcL.Position = UDim2.new(0, 4, 0, 18)
    srcL.BackgroundTransparency = 1
    srcL.Text = "→ " .. source
    srcL.TextColor3 = typeColor
    srcL.TextSize = 10
    srcL.Font = Enum.Font.GothamSemibold
    srcL.TextXAlignment = Enum.TextXAlignment.Left
    srcL.TextTruncate = Enum.TextTruncate.AtEnd
    srcL.Parent = card
    
    -- Args
    local argL = Instance.new("TextLabel")
    argL.Size = UDim2.new(1, -10, 0, 12)
    argL.Position = UDim2.new(0, 4, 0, isImportant and 32 or 30)
    argL.BackgroundTransparency = 1
    argL.Text = "Args: " .. argsStr
    argL.TextColor3 = Color3.fromRGB(140, 140, 160)
    argL.TextSize = 9
    argL.Font = Enum.Font.Gotham
    argL.TextXAlignment = Enum.TextXAlignment.Left
    argL.TextTruncate = Enum.TextTruncate.AtEnd
    argL.Parent = card
    
    -- Return value (nếu có)
    if returnVal ~= nil and isImportant then
        local retL = Instance.new("TextLabel")
        retL.Size = UDim2.new(1, -10, 0, 12)
        retL.Position = UDim2.new(0, 4, 0, 42)
        retL.BackgroundTransparency = 1
        retL.Text = "Return: " .. tostring(returnVal)
        retL.TextColor3 = Color3.fromRGB(80, 220, 80)
        retL.TextSize = 9
        retL.Font = Enum.Font.GothamBold
        retL.TextXAlignment = Enum.TextXAlignment.Left
        retL.Parent = card
    end
    
    -- Console log
    local msg = string.format("[#%d %s] %s | Args: %s", logCount, logType, source, argsStr)
    if returnVal ~= nil then msg = msg .. " | Return: " .. tostring(returnVal) end
    if isImportant then
        warn("🔥 " .. msg)
    else
        print("📡 " .. msg)
    end
    
    -- Update canvas
    task.defer(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 6)
    end)
end

-- ═══════════ HOOK __namecall (CHỈ LOG, KHÔNG CHẶN) ═══════════
local running = true
local oldNamecall

pcall(function()
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if running and (method == "InvokeServer" or method == "FireServer") then
            local path = ""
            pcall(function() path = self:GetFullName() end)
            local name = ""
            pcall(function() name = self.Name end)
            
            -- Log tất cả nếu liên quan hydra/race/upgrade
            local shouldLog = false
            local pathLower = path:lower()
            local argsCheck = ""
            for _, v in pairs(args) do argsCheck = argsCheck .. tostring(v):lower() end
            
            if pathLower:find("hydra") or pathLower:find("draco") or pathLower:find("race") then
                shouldLog = true
            elseif argsCheck:find("hydra") or argsCheck:find("upgrade") or argsCheck:find("interact") 
                or argsCheck:find("race") or argsCheck:find("draco") or argsCheck:find("gear")
                or argsCheck:find("trial") or argsCheck:find("ancient") then
                shouldLog = true
            elseif name == "CommF_" then
                -- Log CommF_ nếu args chứa keyword
                if argsCheck:find("upgrade") or argsCheck:find("race") or argsCheck:find("title") 
                    or argsCheck:find("gear") or argsCheck:find("trial") then
                    shouldLog = true
                end
            end
            
            if shouldLog then
                local logType = method == "InvokeServer" and "INVOKE" or "FIRE"
                
                if method == "InvokeServer" then
                    -- Gọi original và bắt return value
                    local ret = oldNamecall(self, ...)
                    task.spawn(function()
                        AddLog(logType, path, args, ret)
                    end)
                    return ret
                else
                    task.spawn(function()
                        AddLog(logType, path, args, nil)
                    end)
                end
            end
        end
        
        return oldNamecall(self, ...)
    end))
end)

-- Nếu không hook được __namecall, dùng OnClientEvent listener
if not oldNamecall then
    warn("[HydraDebug] Không hook được __namecall, dùng listener mode")
    
    -- Listen Hydra remote
    pcall(function()
        local hydraFolder = workspace:FindFirstChild("HydraIslandClient")
        if hydraFolder then
            for _, child in pairs(hydraFolder:GetDescendants()) do
                if child:IsA("RemoteEvent") then
                    child.OnClientEvent:Connect(function(...)
                        if running then
                            AddLog("EVENT", child:GetFullName(), {...}, nil)
                        end
                    end)
                end
            end
        end
    end)
    
    -- Listen CommF_ events
    pcall(function()
        local remotes = RS:FindFirstChild("Remotes")
        if remotes then
            for _, child in pairs(remotes:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    child.OnClientEvent:Connect(function(...)
                        if running then
                            local args = {...}
                            local check = ""
                            for _, v in pairs(args) do check = check .. tostring(v):lower() end
                            if check:find("hydra") or check:find("race") or check:find("upgrade") or check:find("draco") then
                                AddLog("EVENT", child:GetFullName(), args, nil)
                            end
                        end
                    end)
                end
            end
        end
    end)
end

-- ═══════════ TEST BUTTONS ═══════════
testBtn.MouseButton1Click:Connect(function()
    testBtn.Text = "..."
    
    -- Test 1: Hydra Interacted
    AddLog("TEST", "--- TEST START ---", {}, nil)
    
    if hydraRemote then
        pcall(function()
            local ret = hydraRemote:InvokeServer("Interacted")
            AddLog("TEST", "Hydra:InvokeServer('Interacted')", {"Interacted"}, ret)
        end)
    else
        AddLog("TEST", "Hydra remote KHÔNG TÌM THẤY", {}, nil)
    end
    
    -- Test 2: UpgradeRace Check
    if commF then
        pcall(function()
            local v1, v2, v3 = commF:InvokeServer("UpgradeRace", "Check")
            AddLog("TEST", "CommF_('UpgradeRace','Check')", {"UpgradeRace","Check"}, 
                "v1=" .. tostring(v1) .. " v2=" .. tostring(v2) .. " v3=" .. tostring(v3))
        end)
    end
    
    -- Test 3: getTitles
    if commF then
        pcall(function()
            local ret = commF:InvokeServer("getTitles")
            local count = 0
            if type(ret) == "table" then
                for _ in pairs(ret) do count = count + 1 end
            end
            AddLog("TEST", "CommF_('getTitles')", {"getTitles"}, type(ret) .. " (" .. count .. " items)")
        end)
    end
    
    -- Test 4: Check RaceTransformed
    pcall(function()
        local char = Player.Character
        local hasRT = char and char:FindFirstChild("RaceTransformed")
        AddLog("TEST", "RaceTransformed check", {}, 
            hasRT and ("Value=" .. tostring(hasRT.Value)) or "KHÔNG CÓ")
    end)
    
    -- Test 5: Check Race value
    pcall(function()
        local raceVal = Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Race")
        AddLog("TEST", "Player.Data.Race", {}, 
            raceVal and ("Race=" .. tostring(raceVal.Value)) or "không tìm thấy")
    end)
    
    AddLog("TEST", "--- TEST END ---", {}, nil)
    testBtn.Text = "TEST"
end)

-- Clear
clearBtn.MouseButton1Click:Connect(function()
    for _, c in pairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    logCount = 0
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    running = false
    getgenv().HydraDebug = nil
    -- Restore hook
    if oldNamecall then
        pcall(function() hookmetamethod(game, "__namecall", oldNamecall) end)
    end
    gui:Destroy()
end)
getgenv().HydraDebug = function()
    running = false
    if oldNamecall then
        pcall(function() hookmetamethod(game, "__namecall", oldNamecall) end)
    end
    pcall(function() gui:Destroy() end)
end

-- Keybind
UIS.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

-- Init
ScanRemotes()

print("══════════════════════════════════════")
print("  🔍 HYDRA REMOTE DEBUGGER")
print("  ✅ Hook: " .. (oldNamecall and "namecall" or "listener"))
print("  📡 Bắt: Hydra, UpgradeRace, Draco, Trial, Gear")
print("  🔧 TEST = gọi thử remote")
print("  🗑 CLR = xóa log")
print("  RightShift = ẩn/hiện")
print("══════════════════════════════════════")
