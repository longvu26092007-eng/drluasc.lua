-- ==========================================
-- SERVER HOP DÙNG REMOTE NỘI BỘ CỦA GAME
-- ==========================================
local function ServerHop()
    local TeleportService = game:GetService("TeleportService")
    local ReportActivity  = game:GetService("ReplicatedStorage")
        :WaitForChild("Remotes")
        :WaitForChild("ReportActivity")

    local currentJobId = game.JobId
    local PlaceId      = game.PlaceId
    local servers      = {}
    local received     = false

    -- Bắt data trả về từ server
    local conn
    conn = ReportActivity.OnClientEvent:Connect(function(data)
        -- data có thể là table list server hoặc wrapped
        if type(data) == "table" then
            for _, v in pairs(data) do
                if type(v) == "table" and v.id and v.id ~= currentJobId then
                    -- Ưu tiên server ít người
                    local playing   = tonumber(v.playing)   or 0
                    local maxPlayer = tonumber(v.maxPlayers) or 0
                    if playing < maxPlayer then
                        table.insert(servers, { id = v.id, playing = playing })
                    end
                elseif type(v) == "string" and v ~= currentJobId then
                    -- Trường hợp trả về thẳng mảng jobId string
                    table.insert(servers, { id = v, playing = 0 })
                end
            end
            received = true
        end
        conn:Disconnect()
    end)

    -- Fire remote
    local args = { [1] = "ServerBrowser" }
    ReportActivity:FireServer(unpack(args))

    -- Đợi tối đa 5 giây
    local timeout = tick()
    repeat task.wait(0.1) until received or (tick() - timeout > 5)

    if #servers == 0 then
        warn("[DracoHub] ServerHop: Không tìm thấy server phù hợp!")
        return false
    end

    -- Sắp xếp theo số người ít nhất (server ít lag hơn)
    table.sort(servers, function(a, b) return a.playing < b.playing end)

    -- Chọn ngẫu nhiên trong top 10 server ít người nhất
    local pool   = math.min(10, #servers)
    local chosen = servers[math.random(1, pool)]

    warn("[DracoHub] ServerHop → " .. chosen.id .. " (" .. chosen.playing .. " players)")
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PlaceId, chosen.id, Player)
    end)
    return true
end
