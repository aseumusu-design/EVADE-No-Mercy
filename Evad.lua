--[[
    🔥 POV LOCK – MODE LUNGE ONLY (DENGAN PREDIKSI)
    - Target dipilih dari daftar, crosshair hijau tapi kamera tidak lock
    - Saat animasi lunge/lungehold dimulai, kamera lock ke target + prediksi
    - Saat animasi selesai, kamera lepas (tapi target tetap terpilih)
    - Prediksi: kamera diarahkan ke posisi target + velocity * waktu tempuh (0.3s)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== KONFIGURASI =====
local RADIUS = 100
local PREDICT_TIME = 0.3      -- waktu tempuh serangan (detik), sesuaikan
local ANIM_KEYWORDS = {"lunge", "lungehold"}  -- kata kunci nama animasi

-- ===== VARIABEL =====
local isEnabled = true
local character = player.Character or player.CharacterAdded:Wait()
local selectedTarget = nil      -- HumanoidRootPart target yang dipilih
local targetName = ""
local isLunging = false         -- status apakah sedang animasi lunge
local lastPositions = {}        -- untuk menghitung kecepatan target
local lastTime = 0

-- ===== FUNGSI TARGET =====
local function getTargetsInRadius()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local targets = {}
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar then
                local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                local humanoid = otherChar:FindFirstChild("Humanoid")
                if otherRoot and humanoid and humanoid.Health > 0 then
                    local dist = (root.Position - otherRoot.Position).Magnitude
                    if dist <= RADIUS then
                        table.insert(targets, {player = otherPlayer, rootPart = otherRoot, distance = dist, name = otherPlayer.Name})
                    end
                end
            end
        end
    end
    table.sort(targets, function(a,b) return a.distance < b.distance end)
    return targets
end

local function getNearestTarget()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearestPart, nearestDist = nil, RADIUS
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local otherChar = otherPlayer.Character
            if otherChar then
                local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
                local humanoid = otherChar:FindFirstChild("Humanoid")
                if otherRoot and humanoid and humanoid.Health > 0 then
                    local dist = (root.Position - otherRoot.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestPart = otherRoot
                    end
                end
            end
        end
    end
    return nearestPart
end

-- ===== PREDIKSI POSISI TARGET =====
local function getPredictedPosition(targetRoot)
    if not targetRoot then return nil end
    local now = tick()
    local pos = targetRoot.Position
    -- Hitung kecepatan dari 2 frame terakhir
    local vel = Vector3.new(0,0,0)
    if lastPositions[targetRoot] and lastTime > 0 then
        local dt = now - lastTime
        if dt > 0.01 then
            vel = (pos - lastPositions[targetRoot]) / dt
            -- batasi kecepatan maksimal agar tidak terlalu ekstrim
            if vel.Magnitude > 50 then vel = vel.Unit * 50 end
        end
    end
    -- Simpan posisi terakhir
    lastPositions[targetRoot] = pos
    lastTime = now
    -- Prediksi posisi setelah PREDICT_TIME detik
    return pos + vel * PREDICT_TIME
end

-- ===== LOCK KAMERA KE TARGET (DENGAN PREDIKSI) =====
local function lockToTarget(target)
    if not target or not isEnabled then return end
    local predictedPos = getPredictedPosition(target)
    if predictedPos then
        local currentPos = camera.CFrame.Position
        camera.CFrame = CFrame.new(currentPos, predictedPos)
    end
end

-- ===== DETEKSI ANIMASI LUNGE =====
local function setupAnimationDetection()
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return end

    -- Fungsi untuk mengecek apakah animasi adalah lunge
    local function isLungeAnim(track)
        if not track then return false end
        local name = track.Name and track.Name:lower() or ""
        for _, kw in ipairs(ANIM_KEYWORDS) do
            if string.find(name, kw) then return true end
        end
        -- Cek juga dari AnimationId
        if track.Animation then
            local id = track.Animation.AnimationId
            if id and type(id) == "string" then
                id = id:lower()
                for _, kw in ipairs(ANIM_KEYWORDS) do
                    if string.find(id, kw) then return true end
                end
            end
        end
        return false
    end

    -- Hook saat ada track baru dimainkan
    animator.AnimationTrackAdded:Connect(function(track)
        if isLungeAnim(track) then
            isLunging = true
            -- Mulai lock dan update indicator
            updateIndicator(true)
            -- Jika belum ada target, ambil terdekat
            if not selectedTarget or not selectedTarget.Parent then
                selectedTarget = getNearestTarget()
                targetName = selectedTarget and selectedTarget.Parent.Name or ""
            end
        end
    end)

    -- Hook saat track selesai
    animator.AnimationTrackRemoved:Connect(function(track)
        if isLungeAnim(track) then
            isLunging = false
            updateIndicator(false)  -- matikan hijau, tapi target tetap tersimpan
        end
    end)

    -- Juga cek track yang sudah berjalan saat script mulai
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if isLungeAnim(track) then
            isLunging = true
            updateIndicator(true)
            if not selectedTarget or not selectedTarget.Parent then
                selectedTarget = getNearestTarget()
                targetName = selectedTarget and selectedTarget.Parent.Name or ""
            end
            break
        end
    end
end

-- Panggil saat karakter berubah
local function onCharacterAdded(newChar)
    character = newChar
    selectedTarget = nil
    targetName = ""
    isLunging = false
    lastPositions = {}
    setupAnimationDetection()
    updateTargetList()
end

player.CharacterAdded:Connect(onCharacterAdded)
if character then onCharacterAdded(character) end

-- ===== LOOP UTAMA (UPDATE KAMERA SAAT LUNGING) =====
RunService.Heartbeat:Connect(function()
    if not isEnabled then return end
    if isLunging and selectedTarget and selectedTarget.Parent then
        -- Lock ke target dengan prediksi
        lockToTarget(selectedTarget)
    elseif not isLunging then
        -- Saat tidak lunging, kamera tidak diubah (biarkan manual)
    end
end)

-- ===== HOOK REMOTE (TETAP, TAPI TIDAK MEMICU LOCK) =====
-- Biarkan hook remote tetap ada tapi tidak mengganggu mode lunge.
-- (Kita tidak perlu mengubahnya, karena kita sudah punya loop sendiri)
-- Tapi agar tidak bentrok, kita tetap pasang hook seperti sebelumnya.
local function hookRemote(remote)
    -- hook semua remote tapi hanya untuk update lockUntil (opsional)
end

-- ===== UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POVLockUI"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

-- Tombol ON/OFF
local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(0, 120, 0, 40)
toggleFrame.Position = UDim2.new(0, 10, 0, 10)
toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleFrame.BackgroundTransparency = 0.2
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
toggleBtn.Text = "🔒 ON"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = toggleFrame

toggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleBtn.Text = isEnabled and "🔒 ON" or "🔓 OFF"
    toggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(200, 50, 50)
    if not isEnabled then
        updateIndicator(false)
    end
end)

-- Indikator lingkaran tengah (hijau saat target dipilih, berkedip saat lunging?)
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 20, 0, 20)
indicator.Position = UDim2.new(0.5, -10, 0.5, -10)
indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- merah default
indicator.BackgroundTransparency = 0.5
indicator.BorderSizePixel = 0
indicator.Parent = screenGui

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1, 0)
indicatorCorner.Parent = indicator

function updateIndicator(locked)
    if locked and isEnabled then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)  -- hijau saat lunging
        indicator.BackgroundTransparency = 0.3
    elseif selectedTarget and not locked then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 255) -- cyan = target terpilih tapi belum lock
        indicator.BackgroundTransparency = 0.4
    else
        indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)  -- merah
        indicator.BackgroundTransparency = 0.5
    end
end

-- Panel daftar target (pojok kanan atas)
local targetPanel = Instance.new("Frame")
targetPanel.Size = UDim2.new(0, 200, 0, 300)
targetPanel.Position = UDim2.new(1, -210, 0, 10)
targetPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
targetPanel.BackgroundTransparency = 0.3
targetPanel.BorderSizePixel = 0
targetPanel.Parent = screenGui
targetPanel.Visible = true

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = targetPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(60, 60, 80)
panelStroke.Thickness = 1
panelStroke.Parent = targetPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 24)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎯 TARGETS"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = targetPanel

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 60, 0, 20)
autoBtn.Position = UDim2.new(0.5, -30, 0, 2)
autoBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
autoBtn.Text = "Auto"
autoBtn.TextColor3 = Color3.new(1, 1, 1)
autoBtn.TextSize = 12
autoBtn.Font = Enum.Font.GothamBold
autoBtn.BorderSizePixel = 0
autoBtn.Parent = targetPanel
local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 4)
autoCorner.Parent = autoBtn

autoBtn.MouseButton1Click:Connect(function()
    selectedTarget = nil
    targetName = "Auto"
    updateTargetList()
    updateIndicator(false)
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -4, 1, -30)
scrollFrame.Position = UDim2.new(0, 2, 0, 26)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
scrollFrame.Parent = targetPanel

local uiList = Instance.new("UIListLayout")
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 2)
uiList.Parent = scrollFrame

function updateTargetList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local targets = getTargetsInRadius()
    for i, data in ipairs(targets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        btn.Text = string.format("%s (%.1f)", data.name, data.distance)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = scrollFrame
        if selectedTarget == data.rootPart then
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        end
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        btn.MouseButton1Click:Connect(function()
            selectedTarget = data.rootPart
            targetName = data.name
            updateTargetList()
            updateIndicator(false)  -- target terpilih tapi belum lock (cyan)
        end)
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #targets * 24 + 10)
    if selectedTarget then
        local name = targetName ~= "" and targetName or "?"
        titleLabel.Text = "🎯 " .. name
    else
        titleLabel.Text = "🎯 TARGETS"
    end
end

-- Event update
Players.PlayerAdded:Connect(updateTargetList)
Players.PlayerRemoving:Connect(updateTargetList)
player.CharacterAdded:Connect(function()
    onCharacterAdded(player.Character)
end)

-- Inisialisasi
updateTargetList()
updateIndicator(false)

print("✅ POV Lock – Mode Lunge Only siap!")
print("📌 Klik target, indikator jadi cyan (target terpilih).")
print("📌 Saat animasi lunge dimulai, indikator hijau dan kamera lock + prediksi.")
print("📌 Animasi selesai, kamera lepas (indikator kembali cyan/merah).")
