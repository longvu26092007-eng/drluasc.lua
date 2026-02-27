-- Danh sách các Title quan trọng cần kiểm tra (Dựa trên ảnh của bạn)
local TargetTitles = {
    "The Unleashed", "Unmatched Speed", "Sea Monster", "Sacred Warrior", "The Ghoul", "The Cyborg", "Elder Wyrm", -- Nhóm V2
    "Full Power", "Godspeed", "Warrior of the Sea", "Perfect Being", "Hell Hound", "War Machine", "Ancient Flame" -- Nhóm V3
}

function ScanTitlesGUI()
    ClearPage("TITLES")
    FoundTitles = {}
    local equippedTitle = nil

    pcall(function()
        local mainGui = playerGui:FindFirstChild("Main")
        local titlesFrame = mainGui and mainGui:FindFirstChild("Titles")
        if titlesFrame then
            titlesFrame.Visible = true
            task.wait(0.5)

            -- 1. Tìm title đang dùng
            for _, desc in pairs(titlesFrame:GetDescendants()) do
                if desc:IsA("TextLabel") and (string.lower(desc.Text) == "equipped") then
                    for _, sib in pairs(desc.Parent:GetChildren()) do
                        if sib:IsA("TextLabel") and sib ~= desc and #sib.Text > 2 then
                            equippedTitle = sib.Text
                        end
                    end
                end
            end

            -- 2. Quét và lọc: Chỉ hiện những Title nằm trong danh sách TargetTitles
            for _, desc in pairs(titlesFrame:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                    local txt = desc.Text
                    for _, target in pairs(TargetTitles) do
                        if txt == target and not FoundTitles[txt] then
                            FoundTitles[txt] = true
                            CreateTitleCard(txt, Pages["TITLES"], (txt == equippedTitle))
                        end
                    end
                end
            end
        end
    end)

    -- Nút Scan lại (Viết ngắn gọn)
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(1, -4, 0, 35)
    scanBtn.BackgroundColor3 = C.accent
    scanBtn.Text = "🔄 CẬP NHẬT TRẠNG THÁI"
    scanBtn.TextColor3 = C.textBright
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.Parent = Pages["TITLES"]
    Corner(scanBtn, 8)
    scanBtn.MouseButton1Click:Connect(ScanTitlesGUI)

    UpdateCanvasSize("TITLES")
end
