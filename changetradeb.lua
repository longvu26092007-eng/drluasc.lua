-- ==========================================
-- SCRIPT CHECK WHITE BELT ONLY
-- ==========================================
local Player = game.Players.LocalPlayer

local function CheckWhiteBeltAndSave()
    -- Lấy dữ liệu Inventory từ Server
    local ok, inv = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("getInventory")
    end)

    if ok and type(inv) == "table" then
        local hasWhiteBelt = false
        
        -- Duyệt qua túi đồ tìm White Belt
        for _, item in pairs(inv) do
            if type(item) == "table" and item.Name == "White Belt" then
                hasWhiteBelt = true
                break
            end
        end

        -- Nếu tìm thấy White Belt
        if hasWhiteBelt then
            local fileName = Player.Name .. ".txt"
            local content = "Completed-trade"
            
            -- Ghi file vào thư mục workspace của Executor
            pcall(function()
                writefile(fileName, content)
            end)
            
            warn("[DracoHub] Da tim thay White Belt! Da ghi file: " .. fileName)
            return true -- Trả về true để dừng vòng lặp
        end
    end
    return false
end

-- Chạy vòng lặp kiểm tra mỗi 5 giây
task.spawn(function()
    warn("[DracoHub] Dang bat dau kiem tra White Belt...")
    while true do
        local success = CheckWhiteBeltAndSave()
        if success then 
            warn("[DracoHub] Script dung hoat dong vi da hoan thanh Trade.")
            break 
        end
        task.wait(5) -- Đợi 5 giây rồi check lại lần nữa
    end
end)
