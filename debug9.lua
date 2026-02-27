--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║           TITLE SPY & EQUIP V2 - BLOX FRUITS               ║
    ║     KHÔNG hook __namecall - Không phá chức năng game        ║
    ╚══════════════════════════════════════════════════════════════╝
    
    V2 - Thay đổi:
    ✅ KHÔNG hook __namecall (nguyên nhân gây lỗi V1)
    ✅ Scan trực tiếp GUI Titles trong game 
    ✅ Listener nhẹ thay vì intercept
    ✅ Equip bằng firesignal / fireclick GUI
    ✅ Remote logger dùng .OnClientEvent (an toàn)
    ✅ Sniffer: theo dõi Remotes folder detect title remote
]]

-- ═══════════════════ ANTI DUPLICATE ═══════════════════
if getgenv().TitleSpyV2 then
    if getgenv().TitleSpyV2Shutdown then
        pcall(getgenv().TitleSpyV2Shutdown)
    end
    task.wait(0.5)
end
getgenv().TitleSpyV2 = true

-- ═══════════════════ SERVICES ═══════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safe CoreGui access
local ScreenGui
pcall(function()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TitleSpyV2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui or not ScreenGui.Parent then
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TitleSpyV2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = playerGui
end

-- ═══════════════════ REMOTE REFS ═══════════════════
local Remotes = RS:WaitForChild("Remotes", 10)
local CommF_ = Remotes and Remotes:FindFirstChild("CommF_")

-- ═══════════════════ STATE ═══════════════════
local RemoteLogs = {}
local FoundTitles = {}
local Connections = {}
local Running = true

-- ═══════════════════ COLORS ═══════════════════
local C = {
    bg = Color3.fromRGB(18, 18, 28),
    bg2 = Color3.fromRGB(28, 26, 44),
    accent = Color3.fromRGB(100, 60, 200),
    accent2 = Color3.fromRGB(130, 90, 230),
    green = Color3.fromRGB(50, 160, 70),
    greenHover = Color3.fromRGB(65, 190, 85),
    red = Color3.fromRGB(170, 45, 45),
    orange = Color3.fromRGB(200, 130, 50),
    blue = Color3.fromRGB(50, 120, 200),
    purple = Color3.fromRGB(160, 60, 200),
    text = Color3.fromRGB(220, 210, 255),
    textDim = Color3.fromRGB(130, 125, 160),
    textBright = Color3.fromRGB(255, 255, 255),
    cardBg = Color3.fromRGB(32, 30, 52),
    cardBorder = Color3.fromRGB(55, 50, 85),
    titleCard = Color3.fromRGB(45, 30, 70),
    titleBorder = Color3.fromRGB(120, 70, 220),
}

-- ═══════════════════ UI HELPERS ═══════════════════
local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.cardBorder
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function Tween(obj, props, dur)
    TweenService:Create(obj, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad), props):Play()
end

-- ═══════════════════ MAIN FRAME ═══════════════════
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 430, 0, 520)
Main.Position = UDim2.new(0.5, -215, 0.5, -260)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Corner(Main, 12)
Stroke(Main, C.accent, 2)

-- ═══════ TITLE BAR ═══════
local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1, 0, 0, 42)
TBar.BackgroundColor3 = Color3.fromRGB(25, 22, 42)
TBar.BorderSizePixel = 0
TBar.Parent = Main
Corner(TBar, 12)

local TBarFix = Instance.new("Frame")
TBarFix.Size = UDim2.new(1, 0, 0, 12)
TBarFix.Position = UDim2.new(0, 0, 1, -12)
TBarFix.BackgroundColor3 = Color3.fromRGB(25, 22, 42)
TBarFix.BorderSizePixel = 0
TBarFix.Parent = TBar

local TLabel = Instance.new("TextLabel")
TLabel.Size = UDim2.new(1, -90, 1, 0)
TLabel.Position = UDim2.new(0, 14, 0, 0)
TLabel.BackgroundTransparency = 1
TLabel.Text = "TITLE SPY V2 - Blox Fruits"
TLabel.TextColor3 = C.accent2
TLabel.TextSize = 15
TLabel.Font = Enum.Font.GothamBold
TLabel.TextXAlignment = Enum.TextXAlignment.Left
TLabel.Parent = TBar

-- Min/Close buttons
local function MakeBtn(text, pos, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = pos
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = C.textBright
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = TBar
    Corner(b, 6)
    return b
end

local MinBtn = MakeBtn("-", UDim2.new(1, -66, 0, 7), Color3.fromRGB(55, 48, 85))
local CloseBtn = MakeBtn("X", UDim2.new(1, -33, 0, 7), C.red)

-- ═══════ TABS ═══════
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 32)
TabBar.Position = UDim2.new(0, 8, 0, 46)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local Pages = {}
local TabBtns = {}

local function CreatePage(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name
    scroll.Size = UDim2.new(1, -16, 1, -92)
    scroll.Position = UDim2.new(0, 8, 0, 82)
    scroll.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = C.accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Visible = false
    scroll.Parent = Main
    Corner(scroll, 8)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    pad.Parent = scroll

    Pages[name] = scroll
    return scroll
end

local function CreateTab(name, pos, icon)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0, 130, 1, 0)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(38, 34, 58)
    b.Text = icon .. " " .. name
    b.TextColor3 = C.textDim
    b.TextSize = 12
    b.Font = Enum.Font.GothamSemibold
    b.BorderSizePixel = 0
    b.Parent = TabBar
    Corner(b, 8)
    TabBtns[name] = b
    return b
end

local tabTitles = CreateTab("TITLES", UDim2.new(0, 0, 0, 0), "🏆")
local tabSpy = CreateTab("SNIFFER", UDim2.new(0, 138, 0, 0), "📡")
local tabTools = CreateTab("TOOLS", UDim2.new(0, 276, 0, 0), "🔧")

CreatePage("TITLES")
CreatePage("SNIFFER")
CreatePage("TOOLS")

Pages["TITLES"].Visible = true

local activeTab = "TITLES"
local function SwitchTab(name)
    activeTab = name
    for n, page in pairs(Pages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(TabBtns) do
        local isActive = (n == name)
        Tween(btn, {
            BackgroundColor3 = isActive and C.accent or Color3.fromRGB(38, 34, 58),
            TextColor3 = isActive and C.textBright or C.textDim
        })
    end
end
SwitchTab("TITLES")

tabTitles.MouseButton1Click:Connect(function() SwitchTab("TITLES") end)
tabSpy.MouseButton1Click:Connect(function() SwitchTab("SNIFFER") end)
tabTools.MouseButton1Click:Connect(function() SwitchTab("TOOLS") end)

-- ═══════ STATUS BAR ═══════
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 18)
Status.Position = UDim2.new(0, 8, 1, -22)
Status.BackgroundTransparency = 1
Status.Text = "V2 | Scan mode - Không hook __namecall"
Status.TextColor3 = Color3.fromRGB(100, 180, 100)
Status.TextSize = 10
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

-- ═══════ MINIMIZE / CLOSE ═══════
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Tween(Main, {Size = minimized and UDim2.new(0, 430, 0, 46) or UDim2.new(0, 430, 0, 520)}, 0.25)
    MinBtn.Text = minimized and "+" or "-"
end)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().TitleSpyV2 = false
    if getgenv().TitleSpyV2Shutdown then
        pcall(getgenv().TitleSpyV2Shutdown)
    end
end)

-- ═════════════════════════════════════════════════════════
-- ███ CORE: SCAN GUI TITLES (KHÔNG CẦN INVOKE SERVER) ███
-- ═════════════════════════════════════════════════════════

local function ClearPage(pageName)
    for _, child in pairs(Pages[pageName]:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function UpdateCanvasSize(pageName)
    task.wait()
    local layout = Pages[pageName]:FindFirstChildOfClass("UIListLayout")
    if layout then
        Pages[pageName].CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end
end

local function CreateTitleCard(titleName, parent, equipped)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 48)
    card.BackgroundColor3 = equipped and C.titleCard or C.cardBg
    card.BorderSizePixel = 0
    card.Parent = parent
    Corner(card, 8)
    Stroke(card, equipped and C.titleBorder or C.cardBorder)

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.Position = UDim2.new(0, 8, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = equipped and "⭐" or "🏆"
    icon.TextSize = 18
    icon.Parent = card

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -140, 1, 0)
    name.Position = UDim2.new(0, 40, 0, 0)
    name.BackgroundTransparency = 1
    name.Text = tostring(titleName)
    name.TextColor3 = equipped and Color3.fromRGB(255, 220, 100) or C.text
    name.TextSize = 13
    name.Font = equipped and Enum.Font.GothamBold or Enum.Font.GothamSemibold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = card

    if equipped then
        local badge = Instance.new("TextLabel")
        badge.Size = UDim2.new(0, 70, 0, 20)
        badge.Position = UDim2.new(1, -82, 0.5, -10)
        badge.BackgroundColor3 = C.accent
        badge.Text = "EQUIPPED"
        badge.TextColor3 = C.textBright
        badge.TextSize = 9
        badge.Font = Enum.Font.GothamBold
        badge.Parent = card
        Corner(badge, 5)
    else
        local eqBtn = Instance.new("TextButton")
        eqBtn.Size = UDim2.new(0, 70, 0, 28)
        eqBtn.Position = UDim2.new(1, -82, 0.5, -14)
        eqBtn.BackgroundColor3 = C.green
        eqBtn.Text = "EQUIP"
        eqBtn.TextColor3 = C.textBright
        eqBtn.TextSize = 11
        eqBtn.Font = Enum.Font.GothamBold
        eqBtn.BorderSizePixel = 0
        eqBtn.Parent = card
        Corner(eqBtn, 6)

        eqBtn.MouseEnter:Connect(function() Tween(eqBtn, {BackgroundColor3 = C.greenHover}) end)
        eqBtn.MouseLeave:Connect(function() Tween(eqBtn, {BackgroundColor3 = C.green}) end)

        eqBtn.MouseButton1Click:Connect(function()
            eqBtn.Text = "..."
            
            local ok = false

            -- METHOD 1: Tìm và click button trong game GUI
            pcall(function()
                local mainGui = playerGui:FindFirstChild("Main")
                if mainGui then
                    local titlesFrame = mainGui:FindFirstChild("Titles")
                    if titlesFrame then
                        titlesFrame.Visible = true
                        task.wait(0.2)
                        for _, desc in pairs(titlesFrame:GetDescendants()) do
                            if (desc:IsA("TextLabel") or desc:IsA("TextButton")) then
                                if desc.Text == titleName or string.find(desc.Text or "", titleName, 1, true) then
                                    -- Tìm nút equip gần đó
                                    local container = desc.Parent
                                    for _, sibling in pairs(container:GetDescendants()) do
                                        if sibling:IsA("TextButton") then
                                            local txt = string.lower(sibling.Text or "")
                                            if txt == "equip" or txt == "select" or txt == "chọn" or txt == "trang bị" then
                                                if firesignal then
                                                    firesignal(sibling.MouseButton1Click)
                                                    ok = true
                                                elseif fireclickdetector then
                                                    sibling.MouseButton1Click:Fire()
                                                    ok = true
                                                end
                                            end
                                        end
                                    end
                                    -- Nếu chính nó là button
                                    if not ok and desc:IsA("TextButton") then
                                        if firesignal then
                                            firesignal(desc.MouseButton1Click)
                                            ok = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            -- METHOD 2: InvokeServer trực tiếp
            if not ok and CommF_ then
                pcall(function()
                    CommF_:InvokeServer("equipTitle", titleName)
                    ok = true
                end)
            end

            -- METHOD 3: Thử tất cả remote khác
            if not ok and Remotes then
                pcall(function()
                    for _, remote in pairs(Remotes:GetChildren()) do
                        if remote:IsA("RemoteFunction") and remote.Name ~= "CommF_" then
                            pcall(function()
                                remote:InvokeServer("equipTitle", titleName)
                            end)
                        end
                    end
                end)
            end

            if ok then
                Tween(eqBtn, {BackgroundColor3 = C.accent})
                eqBtn.Text = "OK ✓"
            else
                Tween(eqBtn, {BackgroundColor3 = C.orange})
                eqBtn.Text = "THỬ LẠI"
            end
            
            task.wait(2)
            Tween(eqBtn, {BackgroundColor3 = C.green})
            eqBtn.Text = "EQUIP"

            -- Refresh sau khi equip
            task.wait(0.5)
            ScanTitlesGUI()
        end)
    end

    return card
end

-- ═══════════════════════════════════════════════════
-- ███ SCAN: Đọc title từ GUI game thay vì remote ███
-- ═══════════════════════════════════════════════════

function ScanTitlesGUI()
    ClearPage("TITLES")
    FoundTitles = {}
    
    local found = false
    local equippedTitle = nil

    -- Thử mở bảng titles trước (nhẹ, chỉ set visible)
    pcall(function()
        local mainGui = playerGui:FindFirstChild("Main")
        if mainGui then
            local titlesFrame = mainGui:FindFirstChild("Titles")
            if titlesFrame then
                titlesFrame.Visible = true
                task.wait(0.5) -- đợi game load title list
                
                -- Tìm title đang equipped
                pcall(function()
                    for _, desc in pairs(titlesFrame:GetDescendants()) do
                        if desc:IsA("TextLabel") then
                            local txt = string.lower(desc.Text or "")
                            if txt == "equipped" or txt == "đang dùng" or txt == "selected" then
                                -- Title name thường ở sibling hoặc parent
                                local container = desc.Parent
                                for _, sib in pairs(container:GetChildren()) do
                                    if sib:IsA("TextLabel") and sib ~= desc and #sib.Text > 2 then
                                        equippedTitle = sib.Text
                                    end
                                end
                            end
                        end
                    end
                end)

                -- Scan tất cả text elements trong Titles frame
                local titleElements = {}
                
                for _, desc in pairs(titlesFrame:GetDescendants()) do
                    -- Tìm theo TextButton (thường là button equip title)
                    if desc:IsA("TextButton") or desc:IsA("TextLabel") then
                        local txt = desc.Text or ""
                        -- Lọc: bỏ các text UI (quá ngắn, chung chung)
                        if #txt > 2 and #txt < 80 then
                            local lower = string.lower(txt)
                            -- Bỏ các text control UI
                            local isControl = (lower == "equip" or lower == "select" 
                                or lower == "close" or lower == "x" or lower == "back"
                                or lower == "equipped" or lower == "selected"
                                or lower == "titles" or lower == "title" 
                                or lower == "danh hiệu" or lower == "thành tựu"
                                or lower == "chọn" or lower == "trang bị"
                                or lower == "đóng" or lower == "quay lại"
                                or string.find(lower, "search") 
                                or string.find(lower, "filter"))
                            
                            if not isControl and not FoundTitles[txt] then
                                -- Kiểm tra xem có phải tên title không
                                -- Title thường nằm trong frame riêng, có sibling là button
                                local parent = desc.Parent
                                local hasEquipButton = false
                                if parent then
                                    for _, sib in pairs(parent:GetChildren()) do
                                        if sib:IsA("TextButton") then
                                            local sibTxt = string.lower(sib.Text or "")
                                            if sibTxt == "equip" or sibTxt == "select" or sibTxt == "equipped" 
                                                or sibTxt == "chọn" or sibTxt == "trang bị" then
                                                hasEquipButton = true
                                            end
                                        end
                                    end
                                end
                                
                                -- Thêm vào list nếu có button equip hoặc là ImageButton/clickable
                                if hasEquipButton or desc:IsA("TextButton") then
                                    FoundTitles[txt] = true
                                    titleElements[txt] = (txt == equippedTitle)
                                    found = true
                                end
                            end
                        end
                    end
                end

                -- Nếu không tìm được bằng cách trên, scan rộng hơn
                if not found then
                    for _, desc in pairs(titlesFrame:GetDescendants()) do
                        if desc:IsA("Frame") or desc:IsA("ImageLabel") then
                            -- Tìm frame con chứa text
                            local titleText = nil
                            for _, child in pairs(desc:GetChildren()) do
                                if (child:IsA("TextLabel") or child:IsA("TextButton")) then
                                    local txt = child.Text or ""
                                    if #txt > 2 and #txt < 80 then
                                        local lower = string.lower(txt)
                                        if lower ~= "equip" and lower ~= "select" and lower ~= "equipped" 
                                            and lower ~= "close" and lower ~= "x" and lower ~= "titles"
                                            and lower ~= "chọn" and lower ~= "trang bị" then
                                            titleText = txt
                                        end
                                    end
                                end
                            end
                            if titleText and not FoundTitles[titleText] then
                                FoundTitles[titleText] = true
                                titleElements[titleText] = (titleText == equippedTitle)
                                found = true
                            end
                        end
                    end
                end

                -- Tạo cards cho mỗi title tìm được
                -- Hiện equipped title trước
                for titleName, isEquipped in pairs(titleElements) do
                    if isEquipped then
                        CreateTitleCard(titleName, Pages["TITLES"], true)
                    end
                end
                for titleName, isEquipped in pairs(titleElements) do
                    if not isEquipped then
                        CreateTitleCard(titleName, Pages["TITLES"], false)
                    end
                end

                -- Ẩn lại bảng titles game nếu muốn
                -- titlesFrame.Visible = false
            end
        end
    end)

    if not found then
        -- Info card khi không tìm được
        local info = Instance.new("Frame")
        info.Size = UDim2.new(1, -4, 0, 160)
        info.BackgroundColor3 = C.cardBg
        info.BorderSizePixel = 0
        info.Parent = Pages["TITLES"]
        Corner(info, 8)

        local infoText = Instance.new("TextLabel")
        infoText.Size = UDim2.new(1, -16, 1, -8)
        infoText.Position = UDim2.new(0, 8, 0, 4)
        infoText.BackgroundTransparency = 1
        infoText.RichText = true
        infoText.Text = [[<font color="#FFD700">⚠ Chưa tìm thấy title nào</font>

<font color="#CCCCDD">Thử các bước sau:</font>

<font color="#AAAACC">1. Mở bảng Title trong game trước (thủ công)
2. Bấm SCAN LẠI ở dưới
3. Hoặc bật SNIFFER tab, rồi equip 1 title
   thủ công để tool detect remote

Lưu ý: V2 không hook remote nên 
các chức năng game hoạt động bình thường!</font>]]
        infoText.TextColor3 = C.text
        infoText.TextSize = 12
        infoText.Font = Enum.Font.Gotham
        infoText.TextWrapped = true
        infoText.TextYAlignment = Enum.TextYAlignment.Top
        infoText.TextXAlignment = Enum.TextXAlignment.Left
        infoText.Parent = info
    end

    -- Nút Scan lại
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(1, -4, 0, 38)
    scanBtn.BackgroundColor3 = C.accent
    scanBtn.Text = "🔄 SCAN LẠI TITLES"
    scanBtn.TextColor3 = C.textBright
    scanBtn.TextSize = 13
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.BorderSizePixel = 0
    scanBtn.Parent = Pages["TITLES"]
    Corner(scanBtn, 8)

    scanBtn.MouseButton1Click:Connect(function()
        scanBtn.Text = "⏳ Đang scan..."
        task.wait(0.3)
        ScanTitlesGUI()
    end)

    scanBtn.MouseEnter:Connect(function() Tween(scanBtn, {BackgroundColor3 = C.accent2}) end)
    scanBtn.MouseLeave:Connect(function() Tween(scanBtn, {BackgroundColor3 = C.accent}) end)

    -- Nút mở title GUI game
    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(1, -4, 0, 34)
    openBtn.BackgroundColor3 = Color3.fromRGB(45, 40, 70)
    openBtn.Text = "📋 MỞ BẢNG TITLE GAME (InvokeServer)"
    openBtn.TextColor3 = C.text
    openBtn.TextSize = 12
    openBtn.Font = Enum.Font.GothamSemibold
    openBtn.BorderSizePixel = 0
    openBtn.Parent = Pages["TITLES"]
    Corner(openBtn, 8)

    openBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if CommF_ then
                CommF_:InvokeServer("getTitles")
            end
            local mainGui = playerGui:FindFirstChild("Main")
            if mainGui and mainGui:FindFirstChild("Titles") then
                mainGui.Titles.Visible = true
            end
        end)
        openBtn.Text = "✓ Đã mở! Bấm SCAN LẠI"
        task.wait(2)
        openBtn.Text = "📋 MỞ BẢNG TITLE GAME (InvokeServer)"
    end)

    local count = 0
    for _ in pairs(FoundTitles) do count = count + 1 end
    Status.Text = "V2 | Tìm thấy " .. count .. " title | Scan mode (safe)"

    UpdateCanvasSize("TITLES")
end

-- ════════════════════════════════════════════════════════
-- ███ SNIFFER: Theo dõi remote KHÔNG CẦN hook namecall ███
-- ════════════════════════════════════════════════════════

local snifferActive = false
local snifferConns = {}

local function CreateLogCard(logType, remoteName, direction, args, parent)
    local isTitle = false
    local argsStr = ""
    
    if type(args) == "table" then
        local parts = {}
        for i, v in pairs(args) do
            local s = tostring(v)
            table.insert(parts, s)
            if type(v) == "string" and (string.find(string.lower(v), "title") or string.find(string.lower(v), "equip")) then
                isTitle = true
            end
        end
        argsStr = table.concat(parts, ", ")
    else
        argsStr = tostring(args or "")
    end

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 55)
    card.BackgroundColor3 = isTitle and C.titleCard or C.cardBg
    card.BorderSizePixel = 0
    card.LayoutOrder = -os.clock() * 1000
    card.Parent = parent
    Corner(card, 6)
    Stroke(card, isTitle and C.titleBorder or C.cardBorder)

    -- Type badge
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 55, 0, 16)
    badge.Position = UDim2.new(0, 6, 0, 4)
    badge.BackgroundColor3 = direction == "OUT" and C.orange or C.blue
    badge.Text = direction
    badge.TextColor3 = C.textBright
    badge.TextSize = 9
    badge.Font = Enum.Font.GothamBold
    badge.Parent = card
    Corner(badge, 4)

    if isTitle then
        local tb = Instance.new("TextLabel")
        tb.Size = UDim2.new(0, 40, 0, 16)
        tb.Position = UDim2.new(0, 66, 0, 4)
        tb.BackgroundColor3 = C.purple
        tb.Text = "TITLE"
        tb.TextColor3 = C.textBright
        tb.TextSize = 9
        tb.Font = Enum.Font.GothamBold
        tb.Parent = card
        Corner(tb, 4)
    end

    -- Remote name
    local rname = Instance.new("TextLabel")
    rname.Size = UDim2.new(1, -12, 0, 16)
    rname.Position = UDim2.new(0, 6, 0, 22)
    rname.BackgroundTransparency = 1
    rname.Text = logType .. " → " .. remoteName
    rname.TextColor3 = C.text
    rname.TextSize = 11
    rname.Font = Enum.Font.GothamSemibold
    rname.TextXAlignment = Enum.TextXAlignment.Left
    rname.TextTruncate = Enum.TextTruncate.AtEnd
    rname.Parent = card

    -- Args
    local argsLabel = Instance.new("TextLabel")
    argsLabel.Size = UDim2.new(1, -12, 0, 14)
    argsLabel.Position = UDim2.new(0, 6, 0, 38)
    argsLabel.BackgroundTransparency = 1
    argsLabel.Text = "Args: " .. (argsStr ~= "" and argsStr or "(none)")
    argsLabel.TextColor3 = C.textDim
    argsLabel.TextSize = 10
    argsLabel.Font = Enum.Font.Gotham
    argsLabel.TextXAlignment = Enum.TextXAlignment.Left
    argsLabel.TextTruncate = Enum.TextTruncate.AtEnd
    argsLabel.Parent = card

    UpdateCanvasSize("SNIFFER")
    return card
end

local function StartSniffer()
    if snifferActive then return end
    snifferActive = true

    -- Listen tất cả RemoteEvent .OnClientEvent (nhận từ server)
    if Remotes then
        for _, remote in pairs(Remotes:GetChildren()) do
            if remote:IsA("RemoteEvent") then
                local conn = remote.OnClientEvent:Connect(function(...)
                    if not Running then return end
                    local args = {...}
                    CreateLogCard("Event", remote.Name, "IN", args, Pages["SNIFFER"])
                end)
                table.insert(snifferConns, conn)
            end
        end
    end

    -- Theo dõi remote mới được thêm
    if Remotes then
        local addConn = Remotes.ChildAdded:Connect(function(child)
            if child:IsA("RemoteEvent") then
                local conn = child.OnClientEvent:Connect(function(...)
                    if not Running then return end
                    CreateLogCard("Event", child.Name, "IN", {...}, Pages["SNIFFER"])
                end)
                table.insert(snifferConns, conn)
            end
        end)
        table.insert(snifferConns, addConn)
    end

    Status.Text = "V2 | Sniffer ON - Listening..."
end

local function StopSniffer()
    snifferActive = false
    for _, conn in pairs(snifferConns) do
        pcall(function() conn:Disconnect() end)
    end
    snifferConns = {}
    Status.Text = "V2 | Sniffer OFF"
end

-- ═══════ BUILD SNIFFER PAGE ═══════
local function BuildSnifferPage()
    -- Toggle sniffer
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -4, 0, 38)
    toggleBtn.BackgroundColor3 = C.green
    toggleBtn.Text = "▶ BẬT SNIFFER (theo dõi remote)"
    toggleBtn.TextColor3 = C.textBright
    toggleBtn.TextSize = 13
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.LayoutOrder = -999999999
    toggleBtn.Parent = Pages["SNIFFER"]
    Corner(toggleBtn, 8)

    toggleBtn.MouseButton1Click:Connect(function()
        if snifferActive then
            StopSniffer()
            toggleBtn.Text = "▶ BẬT SNIFFER"
            Tween(toggleBtn, {BackgroundColor3 = C.green})
        else
            StartSniffer()
            toggleBtn.Text = "⏹ TẮT SNIFFER"
            Tween(toggleBtn, {BackgroundColor3 = C.red})
        end
    end)

    -- Info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -4, 0, 50)
    infoLabel.BackgroundColor3 = C.cardBg
    infoLabel.Text = "💡 Bật sniffer → equip title thủ công trong game\n→ Tool sẽ bắt được remote name + args\n→ Copy để dùng lại sau"
    infoLabel.TextColor3 = C.textDim
    infoLabel.TextSize = 10
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextWrapped = true
    infoLabel.BorderSizePixel = 0
    infoLabel.LayoutOrder = -999999998
    infoLabel.Parent = Pages["SNIFFER"]
    Corner(infoLabel, 6)

    -- Clear button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(1, -4, 0, 30)
    clearBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
    clearBtn.Text = "🗑 Xóa logs"
    clearBtn.TextColor3 = C.textDim
    clearBtn.TextSize = 11
    clearBtn.Font = Enum.Font.GothamSemibold
    clearBtn.BorderSizePixel = 0
    clearBtn.LayoutOrder = -999999997
    clearBtn.Parent = Pages["SNIFFER"]
    Corner(clearBtn, 6)

    clearBtn.MouseButton1Click:Connect(function()
        for _, child in pairs(Pages["SNIFFER"]:GetChildren()) do
            if child:IsA("Frame") and child ~= infoLabel then
                child:Destroy()
            end
        end
    end)
end

BuildSnifferPage()

-- ═══════ BUILD TOOLS PAGE ═══════
local function BuildToolsPage()
    local tools = {
        {
            name = "📋 Mở Title GUI Game",
            desc = "InvokeServer getTitles + hiện GUI",
            callback = function(btn)
                pcall(function()
                    if CommF_ then CommF_:InvokeServer("getTitles") end
                    local m = playerGui:FindFirstChild("Main")
                    if m and m:FindFirstChild("Titles") then m.Titles.Visible = true end
                end)
                btn.Text = "✓ Đã mở!"
                task.wait(1.5)
                btn.Text = "📋 Mở Title GUI Game"
            end
        },
        {
            name = "🎨 Mở Haki Color",
            desc = "Hiện bảng chọn màu Haki",
            callback = function(btn)
                pcall(function()
                    local m = playerGui:FindFirstChild("Main")
                    if m and m:FindFirstChild("Colors") then m.Colors.Visible = true end
                end)
            end
        },
        {
            name = "🔍 Scan Remotes Folder",
            desc = "Liệt kê tất cả remote trong game",
            callback = function(btn)
                if Remotes then
                    local count = 0
                    for _, child in pairs(Remotes:GetChildren()) do
                        count = count + 1
                        local logType = child:IsA("RemoteFunction") and "Function" or "Event"
                        CreateLogCard(logType, child.Name, "LIST", {child.ClassName}, Pages["SNIFFER"])
                    end
                    SwitchTab("SNIFFER")
                    btn.Text = "✓ " .. count .. " remotes"
                    task.wait(1.5)
                    btn.Text = "🔍 Scan Remotes Folder"
                end
            end
        },
        {
            name = "📊 Scan GUI Structure",  
            desc = "In cấu trúc Main GUI ra console",
            callback = function(btn)
                pcall(function()
                    local m = playerGui:FindFirstChild("Main")
                    if m then
                        print("\n══════ MAIN GUI STRUCTURE ══════")
                        local function scan(obj, depth)
                            local indent = string.rep("  ", depth)
                            local info = indent .. obj.ClassName .. " | " .. obj.Name
                            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                                info = info .. " | Text: \"" .. (obj.Text or "") .. "\""
                            end
                            info = info .. " | Visible: " .. tostring(obj.Visible)
                            print(info)
                            for _, child in pairs(obj:GetChildren()) do
                                if depth < 5 then scan(child, depth + 1) end
                            end
                        end
                        local titles = m:FindFirstChild("Titles")
                        if titles then
                            scan(titles, 0)
                        else
                            print("Titles frame không tìm thấy!")
                            for _, child in pairs(m:GetChildren()) do
                                print("  " .. child.ClassName .. " | " .. child.Name)
                            end
                        end
                        print("════════════════════════════════\n")
                    end
                end)
                btn.Text = "✓ Check console (F9)"
                task.wait(2)
                btn.Text = "📊 Scan GUI Structure"
            end
        },
        {
            name = "🔄 Force Refresh Titles",
            desc = "InvokeServer + đợi 1s + scan GUI",
            callback = function(btn)
                btn.Text = "⏳..."
                pcall(function()
                    if CommF_ then CommF_:InvokeServer("getTitles", true) end
                end)
                task.wait(1)
                pcall(function()
                    local m = playerGui:FindFirstChild("Main")
                    if m and m:FindFirstChild("Titles") then m.Titles.Visible = true end
                end)
                task.wait(0.5)
                ScanTitlesGUI()
                SwitchTab("TITLES")
                btn.Text = "🔄 Force Refresh Titles"
            end
        },
    }

    for i, tool in ipairs(tools) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 62)
        card.BackgroundColor3 = C.cardBg
        card.BorderSizePixel = 0
        card.Parent = Pages["TOOLS"]
        Corner(card, 8)
        Stroke(card)

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -12, 0, 14)
        desc.Position = UDim2.new(0, 6, 0, 40)
        desc.BackgroundTransparency = 1
        desc.Text = tool.desc
        desc.TextColor3 = C.textDim
        desc.TextSize = 10
        desc.Font = Enum.Font.Gotham
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = card

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 32)
        btn.Position = UDim2.new(0, 6, 0, 5)
        btn.BackgroundColor3 = Color3.fromRGB(45, 40, 72)
        btn.Text = tool.name
        btn.TextColor3 = C.text
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = card
        Corner(btn, 6)

        local originalText = tool.name
        btn.MouseButton1Click:Connect(function()
            tool.callback(btn)
        end)
        btn.MouseEnter:Connect(function() Tween(btn, {BackgroundColor3 = Color3.fromRGB(60, 52, 95)}) end)
        btn.MouseLeave:Connect(function() Tween(btn, {BackgroundColor3 = Color3.fromRGB(45, 40, 72)}) end)
    end

    UpdateCanvasSize("TOOLS")
end

BuildToolsPage()

-- ═══════════════════ KEYBIND ═══════════════════
table.insert(Connections, UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end))

-- ═══════════════════ SHUTDOWN ═══════════════════
getgenv().TitleSpyV2Shutdown = function()
    Running = false
    getgenv().TitleSpyV2 = false
    StopSniffer()
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
    print("[TitleSpy V2] Đã tắt.")
end

-- ═══════════════════ INIT ═══════════════════
task.spawn(function()
    task.wait(1)
    ScanTitlesGUI()
end)

print("═══════════════════════════════════════")
print("  TITLE SPY V2 - BLOX FRUITS")
print("  ✅ KHÔNG hook __namecall!")
print("  ✅ Game hoạt động bình thường!")
print("  ")
print("  RightShift = ẩn/hiện")
print("  Tab 1: Titles (scan GUI)")
print("  Tab 2: Sniffer (theo dõi remote)")  
print("  Tab 3: Tools (tiện ích)")
print("═══════════════════════════════════════")
