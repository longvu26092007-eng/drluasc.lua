-- ==========================================
-- [ SERVER BROWSER PASSIVE LISTENER ]
-- KHÔNG tự fire gì cả
-- Bạn tự bấm vào Server Browser trong game
-- Script chỉ lắng nghe và lọc noise
-- ==========================================

local RS   = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")

-- Remote noise cần bỏ qua
local BLACKLIST = {
    ["DMGDEBUG"]       = true,
    ["FX"]             = true,
    ["TimeSyncEvent"]  = true,
    ["RE/PlayAttackStartEffect"] = true,
    ["CharacterTransparency"]    = true,
    ["RequestStreamAroundAsync"] = true,
    ["FortBuilderAlliesReplication"] = true,
}

-- Chỉ log remote MỚI (chưa từng thấy) hoặc remote có data lớn bất thường
local seenRemotes  = {}
local captureLog   = {}

local function Serialize(v)
    local s = tostring(v)
    pcall(function() s = Http:JSONEncode(v) end)
    return s:sub(1, 500)
end

local function OnData(remoteName, ...)
    if BLACKLIST[remoteName] then return end

    local args = {...}

    -- Tính "kích thước" data để phát hiện response lớn (server list)
    local dataStr = Serialize(args)
    local dataSize = #dataStr

    -- Log tất cả remote chưa thấy lần nào
    local isNew = not seenRemotes[remoteName]
    seenRemotes[remoteName] = true

    -- Log nếu: remote mới HOẶC data > 200 chars (có thể là server list)
    if isNew or dataSize > 200 then
        local tag = isNew and "[NEW]" or "[BIG]"
        warn(string.format("%s Remote='%s' | Size=%d | Data=%s",
            tag, remoteName, dataSize, dataStr:sub(1, 300)))

        table.insert(captureLog, {
            remote = remoteName,
            size   = dataSize,
            data   = dataStr
        })

        -- Lưu file nếu data lớn (có thể là server list)
        if dataSize > 500 then
            pcall(function()
                local txt = ""
                if isfile and isfile("SB_passive.txt") then
                    txt = readfile("SB_passive.txt") .. "\n---\n"
                end
                writefile("SB_passive.txt", txt .. remoteName .. "\n" .. dataStr .. "\n")
            end)
            warn("  ↑ Data lớn! Đã lưu vào SB_passive.txt")
        end
    end
end

-- Connect vào TẤT CẢ RemoteEvent (thụ động)
local count = 0
for _, v in pairs(RS:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        local name = v.Name
        v.OnClientEvent:Connect(function(...)
            OnData(name, ...)
        end)
        count = count + 1
    end
end

-- Cũng bắt remote mới sinh ra
RS.DescendantAdded:Connect(function(v)
    if v:IsA("RemoteEvent") then
        task.wait(0.05)
        local name = v.Name
        v.OnClientEvent:Connect(function(...)
            OnData(name, ...)
        end)
    end
end)

warn("==========================================")
warn("[SB PASSIVE] Đã connect " .. count .. " remotes")
warn("[SB PASSIVE] >> BÂY GIỜ BẤM VÀO SERVER BROWSER TRONG GAME <<")
warn("[SB PASSIVE] Chỉ hiện remote MỚI hoặc data > 200 chars")
warn("[SB PASSIVE] Tìm dòng [NEW] hoặc [BIG] sau khi bấm")
warn("==========================================")

-- Sau 60 giây tổng kết
task.delay(60, function()
    warn("==========================================")
    warn("[SB PASSIVE] Tổng kết sau 60s:")
    warn("  Remote đã thấy: " .. #captureLog)
    for _, v in ipairs(captureLog) do
        warn(string.format("  → '%s' size=%d", v.remote, v.size))
    end
    warn("==========================================")
end)
