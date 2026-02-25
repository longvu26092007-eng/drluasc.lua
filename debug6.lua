-- ==========================================
-- [ SERVER BROWSER DEBUGGER - FOCUSED ]
-- Chỉ bắt data trả về sau khi fire ServerBrowser
-- Không hook lung tung gây rối console
-- ==========================================

local RS          = game:GetService("ReplicatedStorage")
local Http        = game:GetService("HttpService")
local Player      = game.Players.LocalPlayer

-- Lưu kết quả vào file để đọc sau
local function SaveResult(label, data)
    local str = ""
    pcall(function() str = Http:JSONEncode(data) end)
    pcall(function()
        local existing = ""
        if isfile and isfile("SB_Debug.txt") then
            existing = readfile("SB_Debug.txt") .. "\n"
        end
        writefile("SB_Debug.txt", existing .. "[" .. label .. "]\n" .. str .. "\n")
    end)
    warn("[SB] " .. label .. " → " .. str:sub(1, 200))
end

-- =============================================
-- Bước 1: Tắt tất cả remote noise, chỉ hook
-- remote nào fire TRONG VÒNG 5 GIÂY sau ServerBrowser
-- =============================================

local capturing      = false
local capturedEvents = {} -- {remoteName, data}

-- Hook __namecall để bắt InvokeServer trả về
local oldNC
oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    -- Chỉ log khi đang capturing
    if capturing then
        if method == "FireServer" and self:IsA("RemoteEvent") then
            local args = {...}
            -- Bỏ qua chính ReportActivity đã fire
            if self.Name ~= "ReportActivity" then
                warn("[SB-OUT] " .. self.Name .. " fired trong lúc capture")
            end
        elseif method == "InvokeServer" and self:IsA("RemoteFunction") then
            warn("[SB-OUT-RF] " .. self.Name .. " invoked trong lúc capture")
        end
    end

    return oldNC(self, ...)
end))

-- =============================================
-- Bước 2: Hook tất cả OnClientEvent CHỈ khi capturing
-- =============================================

local function MonitorAllOnClientEvent(duration)
    local connections = {}
    local found = false

    -- Scan tất cả RemoteEvent hiện có
    for _, v in pairs(RS:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local re = v
            local conn = re.OnClientEvent:Connect(function(...)
                if not capturing then return end
                local args = {...}
                local entry = {remote = re:GetFullName(), data = args}
                table.insert(capturedEvents, entry)

                -- Print ngắn gọn
                local preview = ""
                pcall(function() preview = Http:JSONEncode(args):sub(1, 300) end)
                warn(string.format("[SB-IN] Remote='%s' | Data=%s", re.Name, preview))

                -- In chi tiết nếu là table lớn
                if type(args[1]) == "table" then
                    local count = 0
                    for k, v2 in pairs(args[1]) do
                        count = count + 1
                    end
                    warn(string.format("  └─ Table với %d key/entry", count))
                    -- In 3 entry đầu để xem cấu trúc
                    local shown = 0
                    for k, v2 in pairs(args[1]) do
                        if shown >= 3 then break end
                        shown = shown + 1
                        pcall(function()
                            warn(string.format("  [%s] = %s", tostring(k), Http:JSONEncode(v2)))
                        end)
                    end
                end

                found = true
                SaveResult("OnClientEvent_" .. re.Name, args)
            end)
            table.insert(connections, conn)
        end
    end

    -- Chờ hết duration rồi ngắt kết nối
    task.delay(duration, function()
        capturing = false
        for _, c in pairs(connections) do
            pcall(function() c:Disconnect() end)
        end
        warn("=== [SB] Capture kết thúc. Tìm dòng [SB-IN] ở trên ===")
        if not found then
            warn("=== [SB] KHÔNG tìm thấy OnClientEvent nào! Có thể data trả về qua cách khác ===")
            warn("=== [SB] → Thử kiểm tra RemoteFunction (InvokeServer có return value) ===")
            warn("=== [SB] → Hoặc data được lưu vào DataModel property thay vì remote ===")
        end
        warn("=== [SB] File kết quả: SB_Debug.txt ===")
    end)
end

-- =============================================
-- Bước 3: Fire ServerBrowser và bắt đầu capture
-- =============================================

warn("=== [SB DEBUGGER] Khởi động... ===")

-- Trước khi fire: liệt kê ngắn gọn remote trong game
warn("--- Remotes trong RS.Remotes ---")
local remotesFolder = RS:FindFirstChild("Remotes")
if remotesFolder then
    for _, v in pairs(remotesFolder:GetChildren()) do
        warn(string.format("  %s [%s]", v.Name, v.ClassName))
    end
end
warn("---")

task.wait(0.3)

-- Bắt đầu capture 8 giây
capturing = true
MonitorAllOnClientEvent(8)

-- Fire ngay
local ok, err = pcall(function()
    local ReportActivity = RS.Remotes:WaitForChild("ReportActivity", 3)
    warn("[SB] Firing ReportActivity:FireServer('ServerBrowser')...")
    ReportActivity:FireServer("ServerBrowser")
    warn("[SB] Đã fire xong. Chờ server response trong 8 giây...")
end)

if not ok then
    capturing = false
    warn("[SB] LỖI khi fire: " .. tostring(err))
    warn("[SB] Kiểm tra tên remote, thử args khác:")
    warn("  → FireServer(1) thay vì FireServer('ServerBrowser')")
    warn("  → Hoặc FireServer({Action='ServerBrowser'})")
end
