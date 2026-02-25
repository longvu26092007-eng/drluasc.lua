-- ==========================================
-- DRACO REMOTE SNIPER - FAST MODE INVOKER
-- Tác dụng: Tìm chính xác Remote khi nhấn Fast Mode
-- ==========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("========================================")
print("🎯 [SYSTEM] Đang rình rập Invoker...")
print("🎯 Hãy mở Settings game và bấm nút FAST MODE!")
print("========================================")

-- Hook hệ thống gửi dữ liệu của Roblox
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local remoteName = tostring(self)

    -- Chỉ kiểm tra các phương thức gửi dữ liệu lên Server
    if method == "FireServer" or method == "InvokeServer" then
        
        -- Lọc các Remote phổ biến hoặc nghi vấn
        -- Blox Fruits dùng CommF_ cho 99% các chức năng
        if remoteName == "CommF_" or string.find(remoteName, "Set") or string.find(remoteName, "Config") then
            
            print("----------------------------------------")
            print("🚀 PHÁT HIỆN INVOKER!")
            print("🛰️ Remote Name: " .. remoteName)
            print("📡 Method: " .. method)
            
            -- In chi tiết các tham số gửi kèm (Dữ liệu quan trọng nhất ở đây)
            for i, arg in pairs(args) do
                local argType = typeof(arg)
                local value = tostring(arg)
                
                -- Nếu tham số là một Table (bảng dữ liệu), in chi tiết bên trong
                if argType == "table" then
                    value = "Table data" -- Bạn có thể dùng hàm in table nếu cần sâu hơn
                end
                
                warn(string.format("   🔹 Arg [%d] (%s): %s", i, argType, value))
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
