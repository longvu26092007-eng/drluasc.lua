
Hi Claude! I'm new here. Could you develop coding standards? If you need more information from me, ask me 1-2 key questions right away. If you think I should give you more context or upload anything to help you do a better job, let me know.

If it makes sense, create something we can look at together—like a visual, a checklist, or something interactive. Thanks for your help!

09:51
A couple quick questions to make sure the standards are tailored to you! Also, if you have an existing codebase, style guide, or linting config you'd like me to align with, feel free to upload it — that'll help me make things much more relevant.

hê lô claude nhá

09:51
Xin chào! 👋 Bạn đang học tiếng Anh hay muốn tiếp tục bằng tiếng Việt? Mình có thể hỗ trợ cả hai nhé!

Bạn đã chọn ngôn ngữ/stack và mục tiêu cho coding standards chưa? Khi bạn trả lời 2 câu hỏi bên trên, mình sẽ tạo ngay một tài liệu chuẩn đẹp để cả team có thể dùng được! 😊


-- ========================================== -- [ PHẦN 0 : CHỌN TEAM & ĐỢI GAME LOAD ] -- ========================================== getgenv().Team = getgenv().Team or "Marines" if not game:IsLoaded() then game.Loaded:Wait() end repeat task.wait() until game.Players.LocalPlayer repe

pasted

nè phân tích khúc excute script banana nó hay bị không excute

09:52
Mình đọc code rồi. Vấn đề nằm ở hàm LoadBananaHub — có 3 nguyên nhân chính khiến script Banana hay bị không execute:

1. Guard condition quá chặt (_G.HubLoadedType)

lua
if _G.HubLoadedType == typeStr then return end  -- ← đây là thủ phạm chính
if _G.HubIsLoading  then return end
Nếu lần đầu load bị lỗi giữa chừng (pcall fail), _G.HubLoadedType đã bị gán = typeStr rồi nhưng script thực ra chưa chạy. Lần sau gọi lại → bị block ngay, không bao giờ retry.

Fix:

lua
local function LoadBananaHub(typeStr)
    if _G.HubIsLoading then return end
    if _G.HubLoadedType == typeStr then return end
    -- Chỉ gán sau khi load THÀNH CÔNG, không gán trước
Chuyển _G.HubLoadedType = typeStr xuống sau khi loadstring chạy xong và không lỗi.

2. pcall nuốt lỗi im lặng

lua
pcall(function()
    loadstring(game:HttpGet("...BananaHub.lua"))()
end)
Nếu HttpGet timeout, hoặc loadstring lỗi syntax → pcall bắt lỗi, không có gì báo, _G.HubIsLoading bị kẹt true mãi không reset.

Fix:

lua
local ok, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/..."))()
end)
if not ok then
    warn("[BananaHub] Load thất bại:", err)
    _G.HubLoadedType = "None"  -- reset để có thể retry
end
_G.HubIsLoading = false  -- luôn reset dù lỗi hay không
3. _G.HubIsLoading không được reset khi lỗi

Hiện tại _G.HubIsLoading = false chỉ nằm cuối task.spawn, nhưng nếu pcall crash giữa chừng thì dòng đó không bao giờ được chạy → kẹt true mãi.

Code fix gọn cho LoadBananaHub:

lua
local function LoadBananaHub(typeStr)
    if _G.HubLoadedType == typeStr then return end
    if _G.HubIsLoading then return end
    _G.HubIsLoading = true

    task.spawn(function()
        -- ... setup getgenv().Config như cũ ...

        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
        end)

        if ok then
            _G.HubLoadedType = typeStr  -- chỉ gán khi thành công
        else
            warn("[BananaHub] Lỗi load:", err)
            _G.HubLoadedType = "None"   -- cho phép retry
        end

        _G.HubIsLoading = false  -- luôn reset
    end)
end
Tóm lại thứ tự ưu tiên fix:

Chuyển _G.HubLoadedType = typeStr xuống sau load thành công
Luôn reset _G.HubIsLoading = false trong mọi trường hợp
Log lỗi ra warn để debug dễ hơn

-- ========================================== -- [ PHẦN 0 : CHỌN TEAM & ĐỢI GAME LOAD ] -- ========================================== getgenv().Team = getgenv().Team or "Marines" if not game:IsLoaded() then game.Loaded:Wait() end repeat task.wait() until game.Players.LocalPlayer repe

pasted

sửa hẳn vào đây cho tớ với

09:55
Được, mình fix hàm LoadBananaHub trực tiếp vào code cho bạn:


Check uploaded files
Check uploaded files
File chỉ có trong context, mình tạo file mới với fix luôn nhé:


Full script with LoadBananaHub fixed
Full script with LoadBananaHub fixed

Claude's response was interrupted

-- ========================================== -- [ PHẦN 0 : CHỌN TEAM & ĐỢI GAME LOAD ] -- ========================================== getgenv().Team = getgenv().Team or "Marines" if not game:IsLoaded() then game.Loaded:Wait() end repeat task.wait() until game.Players.LocalPlayer repe

pasted

sửa hẳn vào lua này đây cho tớ với

09:56
Mình sẽ tạo file với fix đúng chỗ vào hàm LoadBananaHub:


Created 2 files, ran a command, read a file
Created 2 files, ran a command, read a file

Full DracoHub script with LoadBananaHub fixed - move HubLoadedType assignment to after successful load, always reset HubIsLoading
DracoHub_Fixed.lua

Remove old file

Script

Full DracoHub script with LoadBananaHub fixed
DracoHub_Fixed.lua

Presented file
Done
Xong rồi! Chỉ có 3 dòng thay đổi trong hàm LoadBananaHub, phần còn lại giữ nguyên 100%:

Trước (lỗi):

lua
_G.HubLoadedType = typeStr   -- gán sớm dù chưa load xong
...
pcall(function()
    loadstring(...)()
end)
-- HubIsLoading không reset nếu pcall crash
_G.HubIsLoading = false
Sau (đã fix):

lua
-- KHÔNG gán HubLoadedType ở đây nữa
...
local ok, err = pcall(function()
    loadstring(...)()
end)
if ok then
    _G.HubLoadedType = typeStr  -- chỉ gán khi THÀNH CÔNG
else
    _G.HubLoadedType = "None"   -- reset để retry được
    warn("[BananaHub] Load thất bại: " .. tostring(err))
end
_G.HubIsLoading = false  -- luôn reset dù lỗi hay không
Dracohub fixed
LUA 

Dex_Explorer.lua.txt
txt


Infinite Yeild.txt
txt


Matsune (1) (1).txt
txt


Min_BLACKTRAP_.txt
txt


Remote_Spy.lua.txt
txt


autobuy2items.txt
168 lines

txt


autobuydraco.txt
135 lines

txt

Đọc các script này và dựa theo nó tạo bảng debugger với các thứ mình nhấn vào 
Ví dụ FAST Mode hoặc là khi mình nhấn vào __sever browser nó gọi hàm nào để get list 100 sever 
kiểu kiểu là jobid......
sever region ở đâu 
kiểu vậy vậy á 
tham khảo thêm các nơi nó có thể giấu module hoặc net hoặc RF

17:11
Để mình đọc kỹ các file trước rồi tạo debugger phù hợp:


Ran 5 commands
Ran 5 commands
Đủ thông tin rồi. Mình tạo debugger tool hoàn chỉnh:


Created a file, read a file
Created a file, read a file

Blox Fruits Debugger Panel - full featured with server browser, remote explorer, module scanner
BFDebugger.lua

Presented file
Done
Xong! Đây là bảng debugger với 5 tab đầy đủ:

🌐 Tab Server Browser

Gọi games.roblox.com/v1/games/{PlaceId}/servers/Public?sortOrder=Desc&limit=100 để lấy 100 server
Hiển thị từng server: id (JobId), playing/maxPlayers, đánh dấu server đang ở
Nút JOIN từng server, Serverhop random, Copy JobId
Giải thích luôn: Region không có trong Public API — Roblox chỉ expose id, playing, maxPlayers, ping, fps thôi
📡 Tab Remotes — Scan toàn bộ RemoteFunction/RemoteEvent trong RS và RS.Modules.Net.*

⚡ Tab Invoke — Bấm 1 cái gọi thẳng:

getInventory, BuyDragonTalon, requestEntrance
RF/InteractDragonQuest (DragonRace, LearnTether)
RF/Craft (Dragonheart, Dragonstorm)
Detect Race, Custom invoke box
📦 Tab Modules — Deep scan RS.Modules, RS.Remotes, liệt kê hết chỗ game giấu module/net

👤 Tab Player — Stats, race, inventory, ping, position realtime

Bfdebugger
LUA 
đây có phải remote debugger không

17:14
Không hẳn! Đây là Debugger Tool (công cụ debug/test), không phải Remote Debugger theo đúng nghĩa.

Khác nhau như thế này:

BFDebugger vừa tạo = Tool để bạn chủ động gọi remote và xem kết quả. Bạn bấm nút → nó invoke → log ra. Giống như Postman cho API.

Remote Debugger / Remote Spy thật sự = Tool lắng nghe thụ động, tự động bắt MỌI remote được gọi trong game (kể cả từ LocalScript khác), hiển thị tên remote + arguments + return value theo thời gian thực — không cần bạn bấm gì.

Cái Remote_Spy_lua.txt bạn upload mới là Remote Spy thật, nó dùng hookmetamethod để hook vào __namecall của game, bắt mọi :InvokeServer() / :FireServer() xảy ra tự động.

Bạn muốn mình làm cái nào?

Q: Bạn cần loại tool nào?
A: Gộp cả hai vào 1 UI

17:15
Để mình đọc Remote Spy gốc trước để hiểu cách hook đúng:


Ran 3 commands
Ran 3 commands
Đủ rồi, mình hiểu rõ cơ chế hook. Tạo luôn:


Created a file, read a file
Created a file, read a file
Xong! Đây là 4 tab gộp thành 1 UI:

📡 Tab Remote Spy ← cái này mới là "Remote Debugger thật"

Hook __namecall bằng hookmetamethod — tự động bắt MỌI :FireServer() và :InvokeServer() trong game
Panel trái: danh sách remote bị bắt, dedup theo tên (hiện số lần gọi ×N)
Panel phải: click vào remote → xem đầy đủ method, path, arguments từng kiểu (string/number/Instance/Vector3/table...)
Nút ▶ Replay — gọi lại remote đó với args y hệt
Nút 🚫 Blacklist — ẩn remote không cần thiết
Nút 📋 Copy Snippet — tạo code Lua sẵn để paste
Filter box để lọc tên remote
⚡ Tab Invoke — bấm nút gọi thẳng CommF_/RF có log output

🌐 Tab Servers — Server Browser đầy đủ với JOIN/Serverhop

🔍 Tab Scanner — Deep scan RS tìm hết Module/Remote

Bfremotedebugger v2
LUA 


Want to be notified when Claude responds?



Claude is AI and can make mistakes. Please double-check responses.
Bfremotedebugger v2 · LUA
Copy

-- ============================================================
-- BF REMOTE DEBUGGER v2  (Remote Spy + Invoke Tester + Server Browser)
-- VuNguyen | Tham khảo: SimpleSpy, Infinite Yield, autobuydraco, autobuy2items
-- ============================================================
-- Cần exploit hỗ trợ: hookmetamethod / hookfunction / getnamecallmethod
-- ============================================================

-- ============================================================
-- [0] COMPAT LAYER
-- ============================================================
local hookmetamethod  = hookmetamethod
local hookfunction    = hookfunction
local getnamecallmethod = getnamecallmethod
local newcclosure     = newcclosure     or function(f) return f end
local clonefunction   = clonefunction   or function(f) return f end
local cloneref        = cloneref        or function(i) return i end
local checkcaller     = checkcaller     or function() return false end
local getrawmetatable = getrawmetatable
local makewriteable   = makewriteable   or function(t) pcall(setreadonly,t,false) end
local makereadonly    = makereadonly    or function(t) pcall(setreadonly,t,true)  end
local setclipboard    = setclipboard   or toclipboard or set_clipboard or function() end
local httprequest     = (syn and syn.request) or (http and http.request) or request

-- hookmetamethod fallback
if not hookmetamethod then
    hookmetamethod = function(obj, mm, fn)
        local mt = getrawmetatable(obj)
        local old = mt[mm]
        makewriteable(mt)
        mt[mm] = fn
        makereadonly(mt)
        return old
    end
end

-- ============================================================
-- [1] SERVICES
-- ============================================================
local Players         = cloneref(game:GetService("Players"))
local RS              = cloneref(game:GetService("ReplicatedStorage"))
local CoreGui         = cloneref(game:GetService("CoreGui"))
local TweenService    = cloneref(game:GetService("TweenService"))
local HttpService     = cloneref(game:GetService("HttpService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local RunService      = cloneref(game:GetService("RunService"))

local LocalPlayer     = Players.LocalPlayer
local PlaceId         = game.PlaceId
local JobId           = game.JobId

-- ============================================================
-- [2] DESTROY OLD
-- ============================================================
if CoreGui:FindFirstChild("BFRemoteDebugger") then
    CoreGui.BFRemoteDebugger:Destroy()
end
if getgenv().BFDebugger_Shutdown then
    pcall(getgenv().BFDebugger_Shutdown)
end

-- ============================================================
-- [3] REMOTE SPY STATE
-- ============================================================
local spyActive     = false
local spyLogs       = {}       -- { time, remote, method, args, path }
local maxLogs       = 300
local spyBlacklist  = {}       -- { [remoteName] = true }
local originalNamecall
local originalFireServer
local originalInvokeServer

local remoteEvent    = Instance.new("RemoteEvent")
local remoteFunction = Instance.new("RemoteFunction")
originalFireServer   = remoteEvent.FireServer
originalInvokeServer = remoteFunction.InvokeServer

-- ============================================================
-- [4] HELPERS
-- ============================================================
local function getPath(inst)
    local path = inst.Name
    local ok, parent = pcall(function() return inst.Parent end)
    while ok and parent and parent ~= game do
        path = parent.Name .. "." .. path
        ok, parent = pcall(function() return parent.Parent end)
    end
    return path
end

local function argsToString(args)
    local parts = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "string" then
            parts[i] = '"' .. tostring(v):sub(1,40) .. '"'
        elseif t == "Instance" then
            parts[i] = "[" .. v.ClassName .. "] " .. v.Name
        elseif t == "table" then
            local ok2, enc = pcall(HttpService.JSONEncode, HttpService, v)
            parts[i] = ok2 and enc:sub(1,60) or "{table}"
        else
            parts[i] = tostring(v):sub(1,30)
        end
    end
    return table.concat(parts, ", ")
end

local function deepclone(v, seen)
    seen = seen or {}
    if type(v) == "table" then
        if seen[v] then return {} end
        seen[v] = true
        local c = {}
        for k, val in pairs(v) do c[k] = deepclone(val, seen) end
        return c
    elseif typeof(v) == "Instance" then
        return cloneref(v)
    else
        return v
    end
end

-- ============================================================
-- [5] UI BUILD
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BFRemoteDebugger"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Window
local Win = Instance.new("Frame")
Win.Name = "Win"
Win.Size = UDim2.new(0, 680, 0, 500)
Win.Position = UDim2.new(0.5, -340, 0.5, -250)
Win.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Win.Active = true
Win.Draggable = true
Win.Parent = ScreenGui
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 8)
local winStroke = Instance.new("UIStroke", Win)
winStroke.Color = Color3.fromRGB(255, 170, 0)
winStroke.Thickness = 1.5

-- Title bar
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1, 0, 0, 34)
TBar.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
TBar.BorderSizePixel = 0
TBar.Parent = Win
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0, 8)

local TTitle = Instance.new("TextLabel")
TTitle.Size = UDim2.new(1, -80, 1, 0)
TTitle.Position = UDim2.new(0, 10, 0, 0)
TTitle.BackgroundTransparency = 1
TTitle.Text = "🔬 BF Remote Debugger  |  " .. LocalPlayer.Name
TTitle.TextColor3 = Color3.fromRGB(255, 170, 0)
TTitle.Font = Enum.Font.GothamBold
TTitle.TextSize = 12
TTitle.TextXAlignment = Enum.TextXAlignment.Left
TTitle.Parent = TBar

-- Status dot
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 10, 0, 10)
StatusDot.Position = UDim2.new(1, -108, 0.5, -5)
StatusDot.BackgroundColor3 = Color3.fromRGB(80,80,80)
StatusDot.Parent = TBar
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(0, 40, 1, 0)
StatusLbl.Position = UDim2.new(1, -98, 0, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text = "OFF"
StatusLbl.TextColor3 = Color3.fromRGB(150,150,150)
StatusLbl.Font = Enum.Font.GothamBold
StatusLbl.TextSize = 10
StatusLbl.Parent = TBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Parent = TBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
CloseBtn.MouseButton1Click:Connect(function()
    if spyActive then
        pcall(function()
            hookmetamethod(game, "__namecall", originalNamecall)
            hookfunction(originalFireServer, clonefunction(remoteEvent.FireServer))
            hookfunction(originalInvokeServer, clonefunction(remoteFunction.InvokeServer))
        end)
    end
    ScreenGui:Destroy()
end)

-- ============================================================
-- TAB BAR
-- ============================================================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 30)
TabBar.Position = UDim2.new(0, 0, 0, 34)
TabBar.BackgroundColor3 = Color3.fromRGB(14,14,14)
TabBar.BorderSizePixel = 0
TabBar.Parent = Win
local TBL = Instance.new("UIListLayout")
TBL.FillDirection = Enum.FillDirection.Horizontal
TBL.Padding = UDim.new(0, 2)
TBL.Parent = TabBar
Instance.new("UIPadding", TabBar).PaddingLeft = UDim.new(0, 4)

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -64)
Content.Position = UDim2.new(0, 0, 0, 64)
Content.BackgroundTransparency = 1
Content.Parent = Win

local tabBtns = {}
local tabPages = {}

local function makeTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    btn.Text = icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(140,140,140)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Content

    tabBtns[name] = btn
    tabPages[name] = page

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(tabPages) do
            p.Visible = false
            tabBtns[n].BackgroundColor3 = Color3.fromRGB(20,20,20)
            tabBtns[n].TextColor3 = Color3.fromRGB(140,140,140)
        end
        page.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255,170,0)
        btn.TextColor3 = Color3.fromRGB(0,0,0)
    end)

    return page
end

local function openTab(name)
    tabBtns[name].MouseButton1Click:Fire()
end

-- UI Helpers
local function mkBtn(parent, txt, x, y, w, h, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w or 150, 0, h or 24)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(255,170,0)
    b.Text = txt
    b.TextColor3 = Color3.fromRGB(0,0,0)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    if cb then b.MouseButton1Click:Connect(function() task.spawn(cb) end) end
    return b
end

local function mkLbl(parent, txt, x, y, w, h, clr)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, w or 300, 0, h or 16)
    l.Position = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = clr or Color3.fromRGB(190,190,190)
    l.Font = Enum.Font.Code
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function mkScroll(parent, x, y, w, h)
    local s = Instance.new("ScrollingFrame")
    s.Size = UDim2.new(0, w, 0, h)
    s.Position = UDim2.new(0, x, 0, y)
    s.BackgroundColor3 = Color3.fromRGB(8,8,8)
    s.ScrollBarThickness = 5
    s.ScrollBarImageColor3 = Color3.fromRGB(255,170,0)
    s.CanvasSize = UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.BorderSizePixel = 0
    s.Parent = parent
    Instance.new("UICorner", s).CornerRadius = UDim.new(0,4)
    Instance.new("UIStroke", s).Color = Color3.fromRGB(40,40,40)
    Instance.new("UIListLayout", s).SortOrder = Enum.SortOrder.LayoutOrder
    return s
end

-- ============================================================
-- PAGE 1: REMOTE SPY
-- ============================================================
local pageSpy = makeTab("Remote Spy", "📡")

-- Left panel: log list
local spyLeft = Instance.new("Frame")
spyLeft.Size = UDim2.new(0, 220, 1, -8)
spyLeft.Position = UDim2.new(0, 4, 0, 4)
spyLeft.BackgroundColor3 = Color3.fromRGB(12,12,12)
spyLeft.BorderSizePixel = 0
spyLeft.Parent = pageSpy
Instance.new("UICorner", spyLeft).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", spyLeft).Color = Color3.fromRGB(40,40,40)

local spyListScroll = mkScroll(spyLeft, 0, 30, 220, 0)
spyListScroll.Size = UDim2.new(1,0,1,-30)
spyListScroll.Position = UDim2.new(0,0,0,30)

local spyTopBar = Instance.new("Frame")
spyTopBar.Size = UDim2.new(1,0,0,28)
spyTopBar.BackgroundColor3 = Color3.fromRGB(18,18,18)
spyTopBar.BorderSizePixel = 0
spyTopBar.Parent = spyLeft
Instance.new("UICorner", spyTopBar).CornerRadius = UDim.new(0,4)

local spyCountLbl = mkLbl(spyTopBar, "0 remotes", 6, 6, 120, 16, Color3.fromRGB(255,170,0))

mkBtn(spyTopBar, "🗑", 170, 3, 40, 22, function()
    for _, c in pairs(spyListScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    spyLogs = {}
    spyCountLbl.Text = "0 remotes"
end)

-- Right panel: detail
local spyRight = Instance.new("Frame")
spyRight.Size = UDim2.new(1,-232,1,-8)
spyRight.Position = UDim2.new(0,228,0,4)
spyRight.BackgroundColor3 = Color3.fromRGB(10,10,10)
spyRight.BorderSizePixel = 0
spyRight.Parent = pageSpy
Instance.new("UICorner", spyRight).CornerRadius = UDim.new(0,5)
Instance.new("UIStroke", spyRight).Color = Color3.fromRGB(40,40,40)

local detailTitle = mkLbl(spyRight, "← Chọn remote để xem chi tiết", 8, 6, 400, 16, Color3.fromRGB(255,170,0))

-- Method label
local detailMethod = mkLbl(spyRight, "", 8, 26, 400, 14, Color3.fromRGB(120,200,255))
-- Path
local detailPath = mkLbl(spyRight, "", 8, 42, 430, 14, Color3.fromRGB(180,255,180))
-- Time
local detailTime = mkLbl(spyRight, "", 8, 58, 300, 14, Color3.fromRGB(150,150,150))

-- Args box
local argsBox = Instance.new("ScrollingFrame")
argsBox.Size = UDim2.new(1,-16,0,120)
argsBox.Position = UDim2.new(0,8,0,78)
argsBox.BackgroundColor3 = Color3.fromRGB(6,6,6)
argsBox.ScrollBarThickness = 4
argsBox.ScrollBarImageColor3 = Color3.fromRGB(255,170,0)
argsBox.CanvasSize = UDim2.new(0,0,0,0)
argsBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
argsBox.BorderSizePixel = 0
argsBox.Parent = spyRight
Instance.new("UICorner", argsBox).CornerRadius = UDim.new(0,4)
Instance.new("UIStroke", argsBox).Color = Color3.fromRGB(50,50,50)
Instance.new("UIListLayout", argsBox)

local argsTitle = mkLbl(spyRight, "Arguments:", 8, 62, 150, 14, Color3.fromRGB(255,170,0))

-- Code snippet
local codeTitle = mkLbl(spyRight, "Script snippet:", 8, 204, 200, 14, Color3.fromRGB(255,170,0))

local codeBox = Instance.new("TextLabel")
codeBox.Size = UDim2.new(1,-16,0,60)
codeBox.Position = UDim2.new(0,8,0,220)
codeBox.BackgroundColor3 = Color3.fromRGB(6,6,6)
codeBox.TextColor3 = Color3.fromRGB(200,230,200)
codeBox.Font = Enum.Font.Code
codeBox.TextSize = 10
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.TextWrapped = true
codeBox.Text = ""
codeBox.BorderSizePixel = 0
codeBox.Parent = spyRight
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0,4)
Instance.new("UIStroke", codeBox).Color = Color3.fromRGB(50,50,50)

-- Action buttons
mkBtn(spyRight, "📋 Copy Snippet", 8, 284, 130, 24, function()
    pcall(setclipboard, codeBox.Text)
end)

-- Replay button
local replayBtn = mkBtn(spyRight, "▶ Replay", 144, 284, 90, 24, nil)

-- Blacklist toggle
local blacklistBtn = mkBtn(spyRight, "🚫 Blacklist", 240, 284, 100, 24, nil)
blacklistBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
blacklistBtn.TextColor3 = Color3.fromRGB(255,255,255)

-- Toggle spy button (big)
local spyToggleBtn = mkBtn(spyRight, "▶ START SPY", 8, 316, 160, 28, nil)
spyToggleBtn.BackgroundColor3 = Color3.fromRGB(50,180,80)
spyToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)

local filterInput = Instance.new("TextBox")
filterInput.Size = UDim2.new(0, 150, 0, 22)
filterInput.Position = UDim2.new(0, 176, 0, 318)
filterInput.BackgroundColor3 = Color3.fromRGB(18,18,18)
filterInput.Text = ""
filterInput.PlaceholderText = "Filter remote name..."
filterInput.TextColor3 = Color3.fromRGB(200,200,200)
filterInput.Font = Enum.Font.Code
filterInput.TextSize = 10
filterInput.ClearTextOnFocus = false
filterInput.BorderSizePixel = 0
filterInput.Parent = spyRight
Instance.new("UICorner", filterInput).CornerRadius = UDim.new(0,4)
Instance.new("UIStroke", filterInput).Color = Color3.fromRGB(80,80,80)

local selectedLog = nil

local function showLog(log)
    selectedLog = log
    detailTitle.Text = "📡 " .. log.remoteName .. "  [" .. log.method .. "]"
    detailMethod.Text = "Method: " .. log.method
    detailPath.Text = "Path: " .. log.path
    detailTime.Text = "Time: t+" .. string.format("%.2f", log.time) .. "s   Count: " .. log.count

    -- Clear args
    for _, c in pairs(argsBox:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    if #log.args == 0 then
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,-4,0,14)
        l.BackgroundTransparency = 1
        l.Text = "(no arguments)"
        l.TextColor3 = Color3.fromRGB(120,120,120)
        l.Font = Enum.Font.Code
        l.TextSize = 10
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = argsBox
    else
        for i, arg in ipairs(log.args) do
            local t = typeof(arg)
            local display

            if t == "string" then
                display = string.format("[%d] string = %q", i, tostring(arg):sub(1,80))
            elseif t == "number" then
                display = string.format("[%d] number = %s", i, tostring(arg))
            elseif t == "boolean" then
                display = string.format("[%d] bool = %s", i, tostring(arg))
            elseif t == "table" then
                local ok2, enc = pcall(HttpService.JSONEncode, HttpService, arg)
                display = string.format("[%d] table = %s", i, ok2 and enc:sub(1,100) or "{cyclic/complex}")
            elseif typeof(arg) == "Instance" then
                display = string.format("[%d] Instance(%s) = %s", i, arg.ClassName, arg.Name)
            elseif typeof(arg) == "Vector3" then
                display = string.format("[%d] Vector3 = %.2f, %.2f, %.2f", i, arg.X, arg.Y, arg.Z)
            elseif typeof(arg) == "CFrame" then
                display = string.format("[%d] CFrame pos = %.2f, %.2f, %.2f", i, arg.X, arg.Y, arg.Z)
            else
                display = string.format("[%d] %s = %s", i, typeof(arg), tostring(arg):sub(1,60))
            end

            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1,-4,0,14)
            l.BackgroundTransparency = 1
            l.Text = display
            l.TextColor3 = t == "string" and Color3.fromRGB(255,200,100)
                        or t == "number" and Color3.fromRGB(100,200,255)
                        or t == "boolean" and Color3.fromRGB(180,255,180)
                        or Color3.fromRGB(200,200,200)
            l.Font = Enum.Font.Code
            l.TextSize = 10
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = argsBox
        end
    end

    -- Code snippet
    local varName = log.remoteName:gsub("[^%w]","_"):lower()
    local argStr = argsToString(log.args)
    local snippet
    if log.method == "FireServer" then
        snippet = string.format(
            'local %s = RS:FindFirstChild("%s", true)\n%s:FireServer(%s)',
            varName, log.remoteName, varName, argStr
        )
    else
        snippet = string.format(
            'local %s = RS:FindFirstChild("%s", true)\nlocal res = %s:InvokeServer(%s)',
            varName, log.remoteName, varName, argStr
        )
    end
    codeBox.Text = snippet

    -- Replay
    replayBtn.MouseButton1Click:Connect(function()
        local remote = log.remoteRef
        if not remote then return end
        task.spawn(function()
            local ok, err = pcall(function()
                if log.method == "FireServer" then
                    remote:FireServer(unpack(log.args))
                else
                    remote:InvokeServer(unpack(log.args))
                end
            end)
            if ok then
                warn("[BFDebug] Replay OK: " .. log.remoteName)
            else
                warn("[BFDebug] Replay Error: " .. tostring(err))
            end
        end)
    end)

    -- Blacklist
    blacklistBtn.MouseButton1Click:Connect(function()
        spyBlacklist[log.remoteName] = not spyBlacklist[log.remoteName]
        if spyBlacklist[log.remoteName] then
            blacklistBtn.Text = "✅ Unblacklist"
            blacklistBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
        else
            blacklistBtn.Text = "🚫 Blacklist"
            blacklistBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
        end
    end)
end

local logOrder = 0
local logRows  = {}  -- name → TextButton (deduplicate per remote)

local function addSpyLog(data)
    -- filter
    local filter = filterInput.Text:lower()
    if filter ~= "" and not data.remoteName:lower():find(filter, 1, true) then return end
    if spyBlacklist[data.remoteName] then return end

    -- Dedup: update existing row if same remote
    if logRows[data.remoteName] then
        local row = logRows[data.remoteName]
        -- update count in stored log
        for _, log in ipairs(spyLogs) do
            if log.remoteName == data.remoteName then
                log.count = (log.count or 1) + 1
                log.time = data.time
                log.args = data.args
                local mclr = data.method == "FireServer"
                    and Color3.fromRGB(255,180,80)
                    or  Color3.fromRGB(100,200,255)
                row.TextColor3 = mclr
                row.Text = string.format("[%s] %s ×%d",
                    data.method == "FireServer" and "RE" or "RF",
                    data.remoteName:sub(1,20),
                    log.count
                )
                break
            end
        end
        return
    end

    -- Max log check
    if #spyLogs >= maxLogs then
        local oldest = table.remove(spyLogs, 1)
        if logRows[oldest.remoteName] then
            logRows[oldest.remoteName]:Destroy()
            logRows[oldest.remoteName] = nil
        end
    end

    logOrder += 1
    data.count = 1
    table.insert(spyLogs, data)
    spyCountLbl.Text = #spyLogs .. " remotes"

    local isRE = data.method == "FireServer"
    local clr  = isRE and Color3.fromRGB(255,180,80) or Color3.fromRGB(100,200,255)

    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1,-4,0,22)
    row.BackgroundColor3 = logOrder % 2 == 0 and Color3.fromRGB(16,16,16) or Color3.fromRGB(20,20,20)
    row.TextColor3 = clr
    row.Text = string.format("[%s] %s", isRE and "RE" or "RF", data.remoteName:sub(1,22))
    row.Font = Enum.Font.Code
    row.TextSize = 10
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.LayoutOrder = logOrder
    row.BorderSizePixel = 0
    row.Parent = spyListScroll

    logRows[data.remoteName] = row

    row.MouseButton1Click:Connect(function()
        -- Find latest log for this remote
        for _, log in ipairs(spyLogs) do
            if log.remoteName == data.remoteName then
                showLog(log)
                break
            end
        end
    end)

    -- Auto scroll
    task.defer(function()
        spyListScroll.CanvasPosition = Vector2.new(0, spyListScroll.AbsoluteCanvasSize.Y)
    end)
end

-- ============================================================
-- HOOK LOGIC
-- ============================================================
local startTime = tick()

local function handleRemote(method, remote, args)
    task.spawn(function()
        local ok, name = pcall(function() return remote.Name end)
        if not ok then return end
        local ok2, path = pcall(getPath, remote)

        addSpyLog({
            time       = tick() - startTime,
            remoteName = name,
            path       = ok2 and path or name,
            method     = method,
            args       = deepclone(args),
            remoteRef  = remote,
        })
    end)
end

local function startSpy()
    if spyActive then return end
    spyActive = true
    startTime = tick()

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if (method == "FireServer" or method == "InvokeServer") then
            if typeof(self) == "Instance" then
                local ok, isRE = pcall(function() return self:IsA("RemoteEvent") end)
                local ok2, isRF = pcall(function() return self:IsA("RemoteFunction") end)
                if (ok and isRE) or (ok2 and isRF) then
                    if not checkcaller() then
                        handleRemote(method, cloneref(self), {select(1, ...)})
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end))

    originalNamecall = oldNamecall
    spyToggleBtn.Text = "⏹ STOP SPY"
    spyToggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    StatusDot.BackgroundColor3 = Color3.fromRGB(50,220,50)
    StatusLbl.Text = "ON"
    StatusLbl.TextColor3 = Color3.fromRGB(50,220,50)
    winStroke.Color = Color3.fromRGB(50,220,50)
    warn("[BFDebug] Remote Spy STARTED")
end

local function stopSpy()
    if not spyActive then return end
    spyActive = false
    pcall(function()
        hookmetamethod(game, "__namecall", originalNamecall)
    end)
    spyToggleBtn.Text = "▶ START SPY"
    spyToggleBtn.BackgroundColor3 = Color3.fromRGB(50,180,80)
    StatusDot.BackgroundColor3 = Color3.fromRGB(80,80,80)
    StatusLbl.Text = "OFF"
    StatusLbl.TextColor3 = Color3.fromRGB(150,150,150)
    winStroke.Color = Color3.fromRGB(255,170,0)
    warn("[BFDebug] Remote Spy STOPPED")
end

spyToggleBtn.MouseButton1Click:Connect(function()
    if spyActive then stopSpy() else startSpy() end
end)

getgenv().BFDebugger_Shutdown = stopSpy

-- ============================================================
-- PAGE 2: INVOKE TESTER
-- ============================================================
local pageInvoke = makeTab("Invoke", "⚡")

-- Output log inside invoke page
local invokeLog = mkScroll(pageInvoke, 4, 310, 672, 110)
invokeLog.Size = UDim2.new(1,-8,0,110)
invokeLog.Position = UDim2.new(0,4,0,314)

local ilogCount = 0
local function iLog(msg, clr)
    ilogCount += 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-4,0,14)
    l.BackgroundTransparency = 1
    l.Text = msg
    l.TextColor3 = clr or Color3.fromRGB(180,255,180)
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = ilogCount
    l.Parent = invokeLog
    task.defer(function()
        invokeLog.CanvasPosition = Vector2.new(0, invokeLog.AbsoluteCanvasSize.Y)
    end)
    warn("[BFDebug] " .. msg)
end

local function invCommF(...)
    local args = {...}
    iLog("→ CommF_:InvokeServer(" .. argsToString(args) .. ")", Color3.fromRGB(255,220,100))
    local ok, res = pcall(function()
        return RS.Remotes.CommF_:InvokeServer(unpack(args))
    end)
    if ok then
        local disp = type(res) == "table" and (pcall(HttpService.JSONEncode,HttpService,res) and HttpService:JSONEncode(res) or "table") or tostring(res)
        iLog("✅ " .. disp:sub(1,120), Color3.fromRGB(100,255,100))
    else
        iLog("❌ " .. tostring(res), Color3.fromRGB(255,80,80))
    end
end

local function invRF(path, args)
    iLog("→ " .. path .. ":InvokeServer(" .. argsToString(args) .. ")", Color3.fromRGB(255,220,100))
    local parts = {}
    for p in path:gmatch("[^/]+") do parts[#parts+1] = p end
    local ok, res = pcall(function()
        local node = RS
        for _, p in ipairs(parts) do
            node = node:WaitForChild(p, 3)
        end
        return node:InvokeServer(unpack(args))
    end)
    if ok then
        iLog("✅ " .. tostring(res):sub(1,120), Color3.fromRGB(100,255,100))
    else
        iLog("❌ " .. tostring(res), Color3.fromRGB(255,80,80))
    end
end

-- Buttons grid
local BW, BH, BPX, BPY = 154, 26, 6, 6
local col, row2 = 0, 0
local function nextPos()
    local x = BPX + col * (BW + 4)
    local y = BPY + row2 * (BH + 4)
    col += 1
    if col >= 4 then col = 0; row2 += 1 end
    return x, y
end

local function addInvBtn(label, cb)
    local x, y = nextPos()
    mkBtn(pageInvoke, label, x, y, BW, BH, cb)
end

addInvBtn("📦 getInventory", function() invCommF("getInventory") end)
addInvBtn("🐉 BuyDragonTalon", function() invCommF("BuyDragonTalon", true) end)
addInvBtn("🚪 requestEntrance", function()
    invCommF("requestEntrance", Vector3.new(5661.5322265625, 1013.0907592773438, -334.9649963378906))
end)
addInvBtn("🔄 ResetStat Refund", function()
    invCommF("BlackbeardReward","Refund","1")
    task.wait(0.3)
    invCommF("BlackbeardReward","Refund","2")
end)

addInvBtn("🧙 DragonRace (RF)", function()
    invRF("Modules/Net/RF/InteractDragonQuest", {
        {NPC="Dragon Wizard", Command="DragonRace"}
    })
end)
addInvBtn("📖 Speak (RF)", function()
    invRF("Modules/Net/RF/InteractDragonQuest", {
        {NPC="Dragon Wizard", Command="Speak"}
    })
end)
addInvBtn("🎓 LearnTether (RF)", function()
    invRF("Modules/Net/RF/InteractDragonQuest", {
        {NPC="Dragon Wizard", Command="LearnTether"}
    })
end)
addInvBtn("❤️ Craft Dragonheart", function()
    invRF("Modules/Net/RF/Craft", {"Craft","Dragonheart",{}})
end)

addInvBtn("⚡ Craft Dragonstorm", function()
    invRF("Modules/Net/RF/Craft", {"Craft","Dragonstorm",{}})
end)
addInvBtn("🔍 Detect Race", function()
    local r1 = RS.Remotes.CommF_:InvokeServer("Wenlocktoad","1")
    local r2 = RS.Remotes.CommF_:InvokeServer("Alchemist","1")
    local race = "?"
    pcall(function() race = LocalPlayer.Data.Race.Value end)
    local v = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("RaceTransformed") and "V4"
           or r1 == -2 and "V3"
           or r2 == -2 and "V2"
           or "V1"
    iLog("🏁 Race: " .. race .. "-" .. v, Color3.fromRGB(100,255,200))
end)
addInvBtn("💀 Bones Buy x1", function() invCommF("Bones","Buy",1,1) end)
addInvBtn("📊 Player Stats", function()
    local ok, d = pcall(function() return LocalPlayer.Data end)
    if ok and d then
        iLog(string.format("Melee=%s Defense=%s Sword=%s Gun=%s",
            tostring(d.Melee and d.Melee.Value),
            tostring(d.Defense and d.Defense.Value),
            tostring(d.Sword and d.Sword.Value),
            tostring(d.Gun and d.Gun.Value)
        ))
    else
        iLog("❌ Player.Data not accessible", Color3.fromRGB(255,80,80))
    end
end)

-- Custom invoke row
mkLbl(pageInvoke, "Custom CommF_:", 6, 272, 120, 14, Color3.fromRGB(255,170,0))
local customBox = Instance.new("TextBox")
customBox.Size = UDim2.new(0, 340, 0, 22)
customBox.Position = UDim2.new(0, 130, 0, 270)
customBox.BackgroundColor3 = Color3.fromRGB(16,16,16)
customBox.Text = 'getInventory'
customBox.TextColor3 = Color3.fromRGB(200,200,200)
customBox.Font = Enum.Font.Code
customBox.TextSize = 11
customBox.ClearTextOnFocus = false
customBox.PlaceholderText = '"Action", arg1, arg2...'
customBox.BorderSizePixel = 0
customBox.Parent = pageInvoke
Instance.new("UICorner", customBox).CornerRadius = UDim.new(0,4)
Instance.new("UIStroke", customBox).Color = Color3.fromRGB(70,70,70)

mkBtn(pageInvoke, "▶ Run", 476, 270, 60, 22, function()
    local ok, args = pcall(function()
        return {HttpService:JSONDecode("[" .. customBox.Text .. "]")}
    end)
    if ok and args then
        invCommF(unpack(args[1] or args))
    else
        -- try as plain string
        invCommF(customBox.Text)
    end
end)

-- ============================================================
-- PAGE 3: SERVER BROWSER
-- ============================================================
local pageSrv = makeTab("Servers", "🌐")

mkLbl(pageSrv, "PlaceId: " .. PlaceId, 6, 4, 300, 14, Color3.fromRGB(255,220,100))
mkLbl(pageSrv, "JobId: " .. JobId:sub(1,36), 6, 20, 500, 14, Color3.fromRGB(255,220,100))

local srvScroll = mkScroll(pageSrv, 4, 40, 672, 0)
srvScroll.Size = UDim2.new(1,-8,0,340)
srvScroll.Position = UDim2.new(0,4,0,40)

local srvData   = {}
local srvRowNum = 0

local function clearSrvList()
    for _, c in pairs(srvScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    srvData   = {}
    srvRowNum = 0
end

local function addSrvRow(id, playing, maxPlayers)
    srvRowNum += 1
    local isCurrent = id == JobId

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,-4,0,24)
    row.BackgroundColor3 = isCurrent and Color3.fromRGB(30,50,20) or
        (srvRowNum % 2 == 0 and Color3.fromRGB(15,15,15) or Color3.fromRGB(18,18,18))
    row.BorderSizePixel = 0
    row.LayoutOrder = srvRowNum
    row.Parent = srvScroll

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-68,1,0)
    info.Position = UDim2.new(0,4,0,0)
    info.BackgroundTransparency = 1
    info.Text = string.format("#%d  %s  %d/%d%s",
        srvRowNum, id:sub(1,36), playing, maxPlayers,
        isCurrent and "  ◀ YOU" or "")
    info.TextColor3 = isCurrent and Color3.fromRGB(100,255,100) or Color3.fromRGB(170,170,170)
    info.Font = Enum.Font.Code
    info.TextSize = 10
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = row

    local jBtn = Instance.new("TextButton")
    jBtn.Size = UDim2.new(0,58,0,18)
    jBtn.Position = UDim2.new(1,-62,0,3)
    jBtn.BackgroundColor3 = isCurrent and Color3.fromRGB(50,50,50) or Color3.fromRGB(255,170,0)
    jBtn.Text = isCurrent and "HERE" or "JOIN"
    jBtn.TextColor3 = Color3.fromRGB(0,0,0)
    jBtn.Font = Enum.Font.GothamBold
    jBtn.TextSize = 10
    jBtn.BorderSizePixel = 0
    jBtn.Parent = row
    Instance.new("UICorner", jBtn).CornerRadius = UDim.new(0,4)

    if not isCurrent then
        jBtn.MouseButton1Click:Connect(function()
            iLog("🌐 Teleporting to " .. id)
            TeleportService:TeleportToPlaceInstance(PlaceId, id, LocalPlayer)
        end)
    end

    table.insert(srvData, {id=id, playing=playing, maxPlayers=maxPlayers})
end

local srvStatusLbl = mkLbl(pageSrv, "", 6, 386, 500, 14, Color3.fromRGB(150,150,150))

local function fetchServers(order, limit)
    clearSrvList()
    srvStatusLbl.Text = "⏳ Loading..."
    if not httprequest then
        srvStatusLbl.Text = "❌ httprequest not supported by your exploit"
        return
    end
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=%d",
        PlaceId, order, limit
    )
    local ok, res = pcall(httprequest, {Url=url, Method="GET"})
    if not ok or not res then
        srvStatusLbl.Text = "❌ Request failed"
        return
    end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not ok2 or not data or not data.data then
        srvStatusLbl.Text = "❌ JSON decode failed"
        return
    end
    local count = 0
    for _, s in ipairs(data.data) do
        if s.id then
            addSrvRow(s.id, s.playing or 0, s.maxPlayers or 0)
            count += 1
        end
    end
    srvStatusLbl.Text = string.format(
        "✅ %d servers loaded  |  nextPageCursor: %s  |  API: games.roblox.com/v1/games/{id}/servers/Public",
        count, tostring(data.nextPageCursor)
    )
end

mkBtn(pageSrv, "🔄 Load 100 (Desc)", 4, 406, 150, 26, function() fetchServers("Desc",100) end)
mkBtn(pageSrv, "⚡ Load 100 (Asc)", 160, 406, 150, 26, function() fetchServers("Asc",100) end)
mkBtn(pageSrv, "🎲 Serverhop", 316, 406, 110, 26, function()
    fetchServers("Desc",100)
    task.wait(1)
    local avail = {}
    for _, s in ipairs(srvData) do
        if s.playing < s.maxPlayers and s.id ~= JobId then
            table.insert(avail, s.id)
        end
    end
    if #avail > 0 then
        local pick = avail[math.random(1,#avail)]
        iLog("🎲 Hopping to " .. pick)
        TeleportService:TeleportToPlaceInstance(PlaceId, pick, LocalPlayer)
    else
        iLog("❌ No available server", Color3.fromRGB(255,80,80))
    end
end)
mkBtn(pageSrv, "📋 Copy JobId", 432, 406, 110, 26, function()
    pcall(setclipboard, JobId)
    iLog("📋 JobId copied: " .. JobId)
end)

mkLbl(pageSrv, "ℹ️  Fields: id=JobId, playing, maxPlayers, ping, fps  |  Region: KHÔNG có trong Public API", 4, 438, 670, 14, Color3.fromRGB(100,100,100))

-- ============================================================
-- PAGE 4: MODULE SCANNER
-- ============================================================
local pageMod = makeTab("Scanner", "🔍")

local modScroll = mkScroll(pageMod, 4, 36, 672, 0)
modScroll.Size = UDim2.new(1,-8,0,390)
modScroll.Position = UDim2.new(0,4,0,36)

local modCount = 0
local function addModRow(path, cls)
    modCount += 1
    local clr = cls == "RemoteFunction" and Color3.fromRGB(100,200,255)
             or cls == "RemoteEvent"    and Color3.fromRGB(180,255,180)
             or cls == "ModuleScript"   and Color3.fromRGB(255,200,100)
             or cls == "BindableFunction" and Color3.fromRGB(255,150,200)
             or Color3.fromRGB(160,160,160)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-4,0,14)
    l.BackgroundTransparency = 1
    l.Text = "[" .. cls .. "] " .. path
    l.TextColor3 = clr
    l.Font = Enum.Font.Code
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = modCount
    l.Parent = modScroll
end

local SCAN_CLS = {"RemoteFunction","RemoteEvent","BindableFunction","ModuleScript"}

local function deepScan(root, prefix, depth)
    if depth <= 0 then return end
    local ok, children = pcall(function() return root:GetChildren() end)
    if not ok then return end
    for _, child in ipairs(children) do
        local p = prefix .. "." .. child.Name
        for _, cls in ipairs(SCAN_CLS) do
            if child:IsA(cls) then
                addModRow(p, cls)
                break
            end
        end
        deepScan(child, p, depth - 1)
    end
end

local modStatusLbl = mkLbl(pageMod, "Chọn scan target", 4, 18, 500, 14, Color3.fromRGB(150,150,150))

local function clearMod()
    for _, c in pairs(modScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    modCount = 0
end

mkBtn(pageMod, "RS.Modules.Net", 4, 432, 140, 24, function()
    clearMod()
    modStatusLbl.Text = "Scanning..."
    local ok, m = pcall(function() return RS:WaitForChild("Modules",3):WaitForChild("Net",3) end)
    if ok and m then deepScan(m,"RS.Modules.Net",6) end
    modStatusLbl.Text = "✅ " .. modCount .. " items  |  RS.Modules.Net"
end)

mkBtn(pageMod, "RS.Remotes", 150, 432, 120, 24, function()
    clearMod()
    modStatusLbl.Text = "Scanning..."
    local ok, m = pcall(function() return RS:WaitForChild("Remotes",3) end)
    if ok and m then deepScan(m,"RS.Remotes",4) end
    modStatusLbl.Text = "✅ " .. modCount .. " items  |  RS.Remotes"
end)

mkBtn(pageMod, "Full RS Scan", 276, 432, 120, 24, function()
    clearMod()
    modStatusLbl.Text = "Deep scanning RS..."
    deepScan(RS,"RS",5)
    modStatusLbl.Text = "✅ " .. modCount .. " items  |  Full RS"
end)

mkBtn(pageMod, "🗑 Clear", 402, 432, 70, 24, function()
    clearMod()
    modStatusLbl.Text = "Cleared"
end)

-- ============================================================
-- OPEN DEFAULT TAB
-- ============================================================
openTab("Remote Spy")

warn("[BFRemoteDebugger] Loaded! hookmetamethod=" .. tostring(hookmetamethod ~= nil))
Develop coding standards - Claude
