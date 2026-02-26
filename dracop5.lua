-- ==========================================
-- [ PHẦN 3 : AUTOMATIC ]
-- Chờ UI load xong → bắt đầu logic tự động
-- ==========================================

-- ---- 3.0 : Chờ UI sẵn sàng ----
-- Đảm bảo ScreenGui + MainFrame đã visible
-- (ScreenGui được tạo ở Phần 2 trước đó)
repeat task.wait(0.5) until ScreenGui and ScreenGui.Parent ~= nil
repeat task.wait(0.5) until MainFrame and MainFrame.Visible
task.wait(1) -- buffer nhỏ sau khi UI hiện xong

ActionStatus.Text = "Hành động: UI sẵn sàng, bắt đầu kiểm tra..."

-- ==========================================
-- [ PHẦN 3 HELPERS ] Dùng chung với Phần 1-2
-- ==========================================

-- Lấy inventory từ server (kèm fallback cache)
local _lastValidInv3 = nil
local _invFail3      = 0

local function GetInventoryData3()
    local ok, inv = pcall(function()
        return game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" and next(inv) ~= nil then
        _lastValidInv3 = inv
        _invFail3      = 0
        return inv, true
    end
    _invFail3 = _invFail3 + 1
    if _lastValidInv3 ~= nil then
        return _lastValidInv3, false
    end
    return {}, false
end

-- Kiểm tra item trong inventory server (bảng trả về từ getInventory)
local function CheckItemInInv3(invData, itemName)
    -- 1. Character đang equip
    local chr = Player.Character
    if chr and chr:FindFirstChild(itemName) then return true, 1 end
    -- 2. Backpack local
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(itemName) then return true, 1 end
    -- 3. Kho inventory server
    for _, v in pairs(invData) do
        if type(v) == "table" and v.Name == itemName then
            return true, (v.Count or 1)
        end
    end
    return false, 0
end

-- Equip vũ khí qua CommF_ LoadItem
local function EquipWeapon3(weaponName)
    -- Nếu đang equip rồi thì bỏ qua
    local chr = Player.Character
    if chr and chr:FindFirstChild(weaponName) then
        warn("[DracoAuto] EquipWeapon3: " .. weaponName .. " đã được equip rồi, bỏ qua.")
        return true
    end
    local ok, err = pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("LoadItem", weaponName)
    end)
    if ok then
        warn("[DracoAuto] EquipWeapon3: Đã equip " .. weaponName)
    else
        warn("[DracoAuto] EquipWeapon3: Lỗi khi equip " .. weaponName .. " - " .. tostring(err))
    end
    return ok
end

-- ==========================================
-- [ 3.1 ] AUTO EQUIP DRAGONHEART & DRAGONSTORM
-- Phát hiện có trong inventory → equip cả hai
-- ==========================================

task.spawn(function()
    ActionStatus.Text = "Hành động: [3.1] Đang kiểm tra inventory cho Heart & Storm..."

    -- Vòng lặp kiểm tra mỗi 5 giây
    -- Dừng khi đã equip đủ cả hai hoặc không còn trong inventory
    local heartEquipped = false
    local stormEquipped = false

    while true do
        local inv, invValid = GetInventoryData3()

        if not invValid and _invFail3 <= 3 then
            ActionStatus.Text = "Hành động: [3.1] Inventory lỗi tạm thời, thử lại..."
            task.wait(5)
            continue
        end

        local hasHeart, _ = CheckItemInInv3(inv, "Dragonheart")
        local hasStorm, _ = CheckItemInInv3(inv, "Dragonstorm")

        -- Cập nhật WeaponRowLabel (đã khai báo ở Phần 2)
        WeaponRowLabel.Text = string.format(
            "Heart: %s  |  Storm: %s",
            hasHeart and "✅" or "❌",
            hasStorm and "✅" or "❌"
        )

        -- Nếu có cả hai → equip lần lượt
        if hasHeart and hasStorm then
            ActionStatus.Text = "Hành động: [3.1] Phát hiện Heart + Storm! Tiến hành equip..."

            -- Equip Dragonheart trước
            if not heartEquipped then
                ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonheart..."
                local ok1 = EquipWeapon3("Dragonheart")
                if ok1 then
                    heartEquipped = true
                    ActionStatus.Text = "Hành động: [3.1] Dragonheart đã equip ✓"
                    task.wait(0.8)
                end
            end

            -- Equip Dragonstorm sau
            if not stormEquipped then
                ActionStatus.Text = "Hành động: [3.1] Đang equip Dragonstorm..."
                local ok2 = EquipWeapon3("Dragonstorm")
                if ok2 then
                    stormEquipped = true
                    ActionStatus.Text = "Hành động: [3.1] Dragonstorm đã equip ✓"
                    task.wait(0.8)
                end
            end

            -- Cả hai đã xong
            if heartEquipped and stormEquipped then
                ActionStatus.Text = "Hành động: [3.1] ✅ Đã equip cả Dragonheart & Dragonstorm!"
                warn("[DracoAuto] [3.1] Hoàn tất equip Heart + Storm.")
                break -- Thoát vòng lặp, không cần kiểm tra nữa
            end

        elseif hasHeart and not hasStorm then
            -- Chỉ có Heart, chưa có Storm → equip Heart thôi rồi chờ
            if not heartEquipped then
                ActionStatus.Text = "Hành động: [3.1] Chỉ có Dragonheart, equip và chờ Storm..."
                local ok1 = EquipWeapon3("Dragonheart")
                if ok1 then heartEquipped = true end
            else
                ActionStatus.Text = "Hành động: [3.1] Có Heart ✓ | Chờ Dragonstorm..."
            end

        elseif not hasHeart and hasStorm then
            -- Chỉ có Storm → equip Storm rồi chờ Heart
            if not stormEquipped then
                ActionStatus.Text = "Hành động: [3.1] Chỉ có Dragonstorm, equip và chờ Heart..."
                local ok2 = EquipWeapon3("Dragonstorm")
                if ok2 then stormEquipped = true end
            else
                ActionStatus.Text = "Hành động: [3.1] Có Storm ✓ | Chờ Dragonheart..."
            end

        else
            -- Chưa có cái nào → chờ
            ActionStatus.Text = "Hành động: [3.1] Chưa có Heart & Storm, đang chờ..."
        end

        task.wait(5)
    end
end)
