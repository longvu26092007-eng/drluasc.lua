-- ==========================================
-- DRACO FAST MODE DETECTOR (OFFICIAL BUTTON)
-- Tác dụng: Phát hiện khi người chơi bật/tắt Fast Mode của game
-- ==========================================

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Đường dẫn đến nút Fast Mode trong UI của Blox Fruits
-- Cấu trúc: Main -> Settings -> ScrollingFrame -> FastMode -> Button
local function GetFastModeButton()
    local mainUI = PlayerGui:FindFirstChild("Main")
    if mainUI then
        local settingsFrame = mainUI:FindFirstChild("Settings")
        if settingsFrame then
            local scroll = settingsFrame:FindFirstChild("ScrollingFrame")
            if scroll then
                local fastMode = scroll:FindFirstChild("FastMode")
                if fastMode then
                    return fastMode:FindFirstChild("Button")
                end
            end
        end
    end
    return nil
end

-- Hàm xử lý khi trạng thái Fast Mode thay đổi
local function OnFastModeChanged(button)
    -- Trong Blox Fruits, nút này thường dùng hình ảnh hoặc màu sắc để báo trạng thái
    -- Thường là xanh (Bật) và đỏ/xám (Tắt)
    local isOn = false
    if button:FindFirstChild("On") then
        isOn = button.On.Visible -- Kiểm tra xem dấu tích "On" có hiện không
    end

    if isOn then
        warn("🚀 [SYSTEM] Người chơi vừa BẬT Fast Mode của game!")
        -- Bạn có thể chèn lệnh tối ưu Hub của bạn ở đây
    else
        print("🐢 [SYSTEM] Người chơi vừa TẮT Fast Mode của game!")
    end
end

-- Luồng theo dõi liên tục
task.spawn(function()
    local fastBtn = nil
    
    while true do
        if not fastBtn then
            fastBtn = GetFastModeButton()
            if fastBtn then
                -- Kết nối sự kiện khi bấm nút
                fastBtn.MouseButton1Click:Connect(function()
                    task.wait(0.1) -- Đợi 0.1s để game cập nhật UI xong
                    OnFastModeChanged(fastBtn)
                end)
                warn("✅ [DEBUG] Đã tìm thấy và đang theo dõi nút Fast Mode!")
            end
        end
        task.wait(5) -- Kiểm tra lại mỗi 5s đề phòng game reset UI (khi chết/đổi sea)
    end
end)
