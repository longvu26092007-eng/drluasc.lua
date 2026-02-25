-- ==========================================
-- [ REMOTE DEBUGGER 2 CHIỀU ]
-- Bắt cả outgoing (FireServer) VÀ incoming (OnClientEvent)
-- Mục tiêu: tìm remote trả data Server Browser về client
-- ==========================================

local HttpService  = game:GetService("HttpService")
local RS           = game:GetService("ReplicatedStorage")

-- =============================================
-- PHẦN 1: HOOK OUTGOING - bắt FireServer / InvokeServer
-- (giống Remote Spy nhưng chỉ focus ServerBrowser)
-- =============================================

-- Hook __namecall để bắt tất cả FireServer / InvokeServer
local oldNamecall
local mt = getrawmetatable(game)
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if (method == "FireServer" or method == "InvokeServer") and
        (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        local args = {...}
        local argStr = "[không serialize được]"
        pcall(function() argStr = game:GetService("HttpService"):JSONEncode(args) end)
        warn(string.format("[OUT >>] Remote: '%s' | Method: %s | Args: %s", self.Name, method, argStr))
    end
    return oldNamecall(self, ...)
end))

-- =============================================
-- PHẦN 2: HOOK INCOMING - bắt TẤT CẢ OnClientEvent
-- Đây là phần Remote Spy KHÔNG làm
-- =============================================

local hookedEvents = {}

local function HookRemoteEvent(re)
    if hookedEvents[re] then return end
    hookedEvents[re] = true

    re.OnClientEvent:Connect(function(...)
        local args = {...}
        local argStr = "[không serialize được]"
        pcall(function() argStr = game:GetService("HttpService"):JSONEncode(args) end)
        warn(string.format("[IN <<] Remote: '%s' | Data: %s", re.Name, argStr))

        -- Nếu data là table → in chi tiết từng entry
        for _, v in pairs(args) do
            if type(v) == "table" then
                local count = 0
                for k2, v2 in pairs(v) do
                    count = count + 1
                    if count <= 5 then
                        pcall(function()
                            warn(string.format("  [Entry %d] key=%s → %s", count, tostring(k2), game:GetService("HttpService"):JSONEncode(v2)))
                        end)
                    end
                end
                if count > 5 then
                    warn(string.format("  ... và %d entries nữa (tổng %d)", count - 5, count))
                end
            end
        end
    end)
end

-- Đệ quy hook tất cả RemoteEvent trong game
local function HookAll(parent)
    for _, v in pairs(parent:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            HookRemoteEvent(v)
        end
    end
    parent.DescendantAdded:Connect(function(v)
        if v:IsA("RemoteEvent") then
            task.wait(0.1)
            HookRemoteEvent(v)
        end
    end)
end

HookAll(RS)
pcall(function() HookAll(game:GetService("Players").LocalPlayer.PlayerGui) end)
pcall(function() HookAll(game:GetService("Workspace")) end)

-- =============================================
-- PHẦN 3: SCAN TOÀN BỘ REMOTE TRONG GAME
-- Liệt kê hết để biết có gì
-- =============================================
warn("=== [DEBUGGER] Danh sách toàn bộ Remote trong ReplicatedStorage ===")
for _, v in pairs(RS:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        warn(string.format("  [%s] %s | Path: %s", v.ClassName, v.Name, v:GetFullName()))
    end
end
warn("=== [DEBUGGER] Hết danh sách ===")

-- =============================================
-- PHẦN 4: KÍCH HOẠT ServerBrowser để trigger response
-- =============================================
task.wait(0.5)
warn("=== [DEBUGGER] Đang fire ServerBrowser... ===")

local ok, err = pcall(function()
    local ReportActivity = RS:WaitForChild("Remotes", 5):WaitForChild("ReportActivity", 5)
    ReportActivity:FireServer("ServerBrowser")
    warn("[DEBUGGER] FireServer('ServerBrowser') đã gửi. Chờ OnClientEvent response...")
end)

if not ok then
    warn("[DEBUGGER] Lỗi:", err)
end

warn("=== [DEBUGGER] Đang lắng nghe 15 giây... mở Console để xem [IN <<] ===")
task.wait(15)
warn("=== [DEBUGGER] Kết thúc. Tìm dòng [IN <<] trong console để biết remote nào nhận data. ===")
