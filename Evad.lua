--[[
    🔥 POV LOCK – MODE LUNGE ONLY (UI TETAP MUNCUL)
    - UI dibuat pertama kali, tidak terganggu error lain
    - Target dipilih dari panel, indikator cyan
    - Saat animasi lunge dimulai, kamera lock + prediksi
    - Semua fungsi karakter dibungkus pcall agar aman
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== KONFIGURASI =====
local RADIUS = 100
local PREDICT_TIME = 0.3
local ANIM_KEYWORDS = {"lunge", "lungehold", "stab", "dash"}

-- ===== VARIABEL =====
local isEnabled = true
local character = player.Character
local selectedTarget = nil
local targetName = ""
local isLunging = false
local lastPositions = {}
local lastTime = 0

-- =====================================================
--  1. UI DIBUAT PALING AWAL (BIAR PASTI MUNCUL)
-- =====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POVLockUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Tombol ON/OFF (kiri atas)
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
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = toggleFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleBtn.Text = isEnabled and "🔒 ON" or "🔓 OFF"
    toggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(200, 50, 50)
    if not isEnabled then updateIndicator(false) end
end)

-- Indikator lingkaran tengah
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 20, 0, 20)
indicator.Position = UDim2.new(0.5, -10, 0.5, -10)
indicator.BackgroundColor3 = Color3.fromRGB(255,0,0)
indicator.BackgroundTransparency = 0.5
indicator.BorderSizePixel = 0
indicator.Parent = screenGui

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1,0)
indicatorCorner.Parent = indicator

function updateIndicator(locked)
    if not isEnabled then
        indicator.BackgroundColor3 = Color3.fromRGB(255,0,0)
        indicator.BackgroundTransparency = 0.5
        return
    end
    if locked then
        indicator.BackgroundColor3 = Color3.fromRGB(0,255,0)   -- hijau (lock aktif)
        indicator.BackgroundTransparency = 0.3
    elseif selectedTarget then
        indicator.BackgroundColor3 = Color3.fromRGB(0,255,255) -- cyan (target terpilih)
        indicator.BackgroundTransparency = 0.4
    else
        indicator.BackgroundColor3 = Color3.fromRGB(255,0,0)   -- merah
        indicator.BackgroundTransparency = 0.5
    end
end

-- Panel daftar target (kanan atas)
local targetPanel = Instance.new("Frame")
targetPanel.Size = UDim2.new(0, 200, 0, 300)
targetPanel.Position = UDim2.new(1, -210, 0, 10)
targetPanel.BackgroundColor3 = Color3.fromRGB(20,20,30)
targetPanel.BackgroundTransparency = 0.3
targetPanel.BorderSizePixel = 0
targetPanel.Parent = screenGui
targetPanel.Visible = true

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0,8)
panelCorner.Parent = targetPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(60,60,80)
panelStroke.Thickness = 1
panelStroke.Parent = targetPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,0,0,24)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎯 TARGETS"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = targetPanel

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0,60,0,20)
autoBtn.Position = UDim2.new(0.5,-30,0,2)
autoBtn.BackgroundColor3 = Color3.fromRGB(70,70,90)
autoBtn.Text = "Auto"
autoBtn.TextColor3 = Color3.new(1,1,1)
autoBtn.TextSize = 12
autoBtn.Font = Enum.Font.GothamBold
autoBtn.BorderSizePixel = 0
autoBtn.Parent = targetPanel
local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0,4)
autoCorner.Parent = autoBtn

autoBtn.MouseButton1Click:Connect(function()
    selectedTarget = nil
    targetName = ""
    updateTargetList()
    updateIndicator(false)
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,-4,1,-30)
scrollFrame.Position = UDim2.new(0,2,0,26)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100,100,130)
scrollFrame.Parent = targetPanel

local uiList = Instance.new("UIListLayout")
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0,2)
uiList.Parent = scrollFrame

-- =====================================================
--  2. FUNGSI UTAMA (TARGET, PREDIKSI, DLL)
-- =====================================================
local function getTargetsInRadius()
    local root = character and character:FindFirstChild("HumanoidRootPart")
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
                        table.insert(targets, {player=otherPlayer, rootPart=otherRoot, distance=dist, name=otherPlayer.Name})
                    end
                end
            end
        end
    end
    table.sort(targets, function(a,b) return a.distance < b.distance end)
    return targets
end

local function getNearestTarget()
    local root = character and character:FindFirstChild("HumanoidRootPart")
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

local function getPredictedPosition(targetRoot)
    if not targetRoot then return nil end
    local now = tick()
    local pos = targetRoot.Position
    local vel = Vector3.new(0,0,0)
    if lastPositions[targetRoot] and lastTime > 0 then
        local dt = now - lastTime
        if dt > 0.01 then
            vel = (pos - lastPositions[targetRoot]) / dt
            if vel.Magnitude > 50 then vel = vel.Unit * 50 end
        end
    end
    lastPositions[targetRoot] = pos
    lastTime = now
    return pos + vel * PREDICT_TIME
end

local function lockToTarget(target)
    if not target or not isEnabled then return end
    local predicted = getPredictedPosition(target)
    if predicted then
        local currentPos = camera.CFrame.Position
        camera.CFrame = CFrame.new(currentPos, predicted)
    end
end

function updateTargetList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local targets = getTargetsInRadius()
    for _, data in ipairs(targets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-4,0,22)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,55)
        btn.Text = string.format("%s (%.1f)", data.name, data.distance)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = scrollFrame
        if selectedTarget == data.rootPart then
            btn.BackgroundColor3 = Color3.fromRGB(0,150,80)
        end
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0,4)
        bc.Parent = btn
        btn.MouseButton1Click:Connect(function()
            selectedTarget = data.rootPart
            targetName = data.name
            updateTargetList()
            updateIndicator(false)
        end)
    end
    scrollFrame.CanvasSize = UDim2.new(0,0,0, #targets * 24 + 10)
    if selectedTarget and targetName ~= "" then
        titleLabel.Text = "🎯 " .. targetName
    else
        titleLabel.Text = "🎯 TARGETS"
    end
end

-- =====================================================
--  3. DETEKSI ANIMASI (DIBUNGKUS PCALL AGAR AMAN)
-- =====================================================
local function setupAnimationDetection()
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return end

    local function isLungeAnim(track)
        if not track then return false end
        local name = (track.Name or ""):lower()
        for _, kw in ipairs(ANIM_KEYWORDS) do
            if string.find(name, kw) then return true end
        end
        local id = track.Animation and track.Animation.AnimationId
        if id and type(id) == "string" then
            id = id:lower()
            for _, kw in ipairs(ANIM_KEYWORDS) do
                if string.find(id, kw) then return true end
            end
        end
        return false
    end

    animator.AnimationTrackAdded:Connect(function(track)
        if isLungeAnim(track) then
            isLunging = true
            updateIndicator(true)
            if not selectedTarget or not selectedTarget.Parent then
                local nearest = getNearestTarget()
                if nearest then
                    selectedTarget = nearest
                    targetName = nearest.Parent and nearest.Parent.Name or ""
                    updateTargetList()
                end
            end
        end
    end)

    animator.AnimationTrackRemoved:Connect(function(track)
        if isLungeAnim(track) then
            isLunging = false
            updateIndicator(false)
        end
    end)

    -- Cek animasi yang sudah berjalan
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if isLungeAnim(track) then
            isLunging = true
            updateIndicator(true)
            if not selectedTarget or not selectedTarget.Parent then
                local nearest = getNearestTarget()
                if nearest then
                    selectedTarget = nearest
                    targetName = nearest.Parent and nearest.Parent.Name or ""
                    updateTargetList()
                end
            end
            break
        end
    end
end

-- =====================================================
--  4. INIT & LOOP
-- =====================================================
local function initCharacter(newChar)
    character = newChar
    selectedTarget = nil
    targetName = ""
    isLunging = false
    lastPositions = {}
    lastTime = 0
    pcall(setupAnimationDetection)
    updateTargetList()
    updateIndicator(false)
end

-- Event karakter
if character then
    pcall(initCharacter, character)
else
    player.CharacterAdded:Connect(function(newChar)
        pcall(initCharacter, newChar)
    end)
end

-- Loop utama (update kamera saat lunging)
RunService.Heartbeat:Connect(function()
    if not isEnabled or not isLunging then return end
    if selectedTarget and selectedTarget.Parent then
        pcall(lockToTarget, selectedTarget)
    end
end)

-- Update daftar target saat ada pemain baru/keluar
Players.PlayerAdded:Connect(function()
    pcall(updateTargetList)
end)
Players.PlayerRemoving:Connect(function()
    pcall(updateTargetList)
end)

-- Inisialisasi pertama
pcall(updateTargetList)
pcall(updateIndicator, false)

print("✅ POV Lock – Mode Lunge Only siap! UI harus muncul.")
print("📌 Klik target di panel kanan → indikator cyan.")
print("📌 Saat lunge → indikator hijau, kamera lock + prediksi.")
