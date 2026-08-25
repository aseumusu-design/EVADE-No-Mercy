--[[
    🔥 POV LOCK – MODE LUNGE + REMOTE TRIGGER (PREDIKSI)
    - Target dipilih dari panel (indikator cyan)
    - Saat animasi lunge atau remote Leap/TrailEvent dipanggil → lock + prediksi
    - Kamera lepas saat animasi selesai
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
local ANIM_KEYWORDS = {"lunge", "lungehold", "stab", "dash", "leap"}  -- tambah "leap"

-- ===== VARIABEL =====
local isEnabled = true
local character = player.Character
local selectedTarget = nil
local targetName = ""
local isLunging = false
local lastPositions = {}
local lastTime = 0
local lockUntil = 0
local LOCK_DURATION = 0.8

-- =====================================================
--  1. UI (PASTI MUNCUL)
-- =====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POVLockUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Tombol ON/OFF
local toggleFrame = Instance.new("Frame")
toggleFrame.Size = UDim2.new(0, 120, 0, 40)
toggleFrame.Position = UDim2.new(0, 10, 0, 10)
toggleFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleFrame.BackgroundTransparency = 0.2
toggleFrame.BorderSizePixel = 0
toggleFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,8)
corner.Parent = toggleFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1,0,1,0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
toggleBtn.Text = "🔒 ON"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = toggleFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0,8)
btnCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleBtn.Text = isEnabled and "🔒 ON" or "🔓 OFF"
    toggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(0,170,255) or Color3.fromRGB(200,50,50)
    if not isEnabled then updateIndicator(false) end
end)

-- Indikator lingkaran
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0,20,0,20)
indicator.Position = UDim2.new(0.5,-10,0.5,-10)
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
        indicator.BackgroundColor3 = Color3.fromRGB(0,255,0)   -- hijau
        indicator.BackgroundTransparency = 0.3
    elseif selectedTarget then
        indicator.BackgroundColor3 = Color3.fromRGB(0,255,255) -- cyan
        indicator.BackgroundTransparency = 0.4
    else
        indicator.BackgroundColor3 = Color3.fromRGB(255,0,0)
        indicator.BackgroundTransparency = 0.5
    end
end

-- Panel target
local targetPanel = Instance.new("Frame")
targetPanel.Size = UDim2.new(0,200,0,300)
targetPanel.Position = UDim2.new(1,-210,0,10)
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
--  2. FUNGSI UTAMA
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
--  3. TRIGGER LOCK (ANIMASI + REMOTE)
-- =====================================================
local function triggerLock()
    if not isEnabled then return end
    -- Jika belum ada target, ambil terdekat
    if not selectedTarget or not selectedTarget.Parent then
        local nearest = getNearestTarget()
        if nearest then
            selectedTarget = nearest
            targetName = nearest.Parent and nearest.Parent.Name or ""
            updateTargetList()
        end
    end
    if selectedTarget and selectedTarget.Parent then
        isLunging = true
        lockUntil = tick() + LOCK_DURATION
        updateIndicator(true)
        lockToTarget(selectedTarget)
    end
end

local function releaseLock()
    isLunging = false
    updateIndicator(false)
end

-- Deteksi animasi
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
            print("[POV] Animasi lunge terdeteksi: " .. (track.Name or ""))
            triggerLock()
        end
    end)

    animator.AnimationTrackRemoved:Connect(function(track)
        if isLungeAnim(track) then
            print("[POV] Animasi lunge selesai: " .. (track.Name or ""))
            releaseLock()
        end
    end)

    -- Cek animasi yang sedang berjalan
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if isLungeAnim(track) then
            print("[POV] Animasi lunge sedang berjalan: " .. (track.Name or ""))
            triggerLock()
            break
        end
    end
end

-- Hook remote Leap dan TrailEvent
local function hookRemote(remotePath, remoteName)
    local remote = ReplicatedStorage
    for _, part in ipairs(remotePath) do
        remote = remote and remote:FindFirstChild(part)
        if not remote then break end
    end
    if not remote then
        warn("[POV] Remote " .. remoteName .. " tidak ditemukan")
        return
    end
    if remote:IsA("RemoteEvent") then
        local original = remote.FireServer
        remote.FireServer = function(self, ...)
            print("[POV] Remote " .. remoteName .. " dipanggil, trigger lock")
            triggerLock()
            -- Set timer untuk melepas lock jika tidak ada animasi yang menahan
            task.delay(LOCK_DURATION, function()
                if isLunging and tick() - lockUntil > LOCK_DURATION then
                    releaseLock()
                end
            end)
            return original(self, ...)
        end
        print("[POV] Hook remote: " .. remoteName)
    end
end

-- Pasang hook untuk Leap dan TrailEvent
hookRemote({"Remotes", "Killers", "Hidden", "Leap"}, "Leap")
hookRemote({"Remotes", "Attacks", "TrailEvent"}, "TrailEvent")

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
    pcall(updateTargetList)
    pcall(updateIndicator, false)
end

if character then
    pcall(initCharacter, character)
else
    player.CharacterAdded:Connect(function(newChar)
        pcall(initCharacter, newChar)
    end)
end

-- Loop update kamera
RunService.Heartbeat:Connect(function()
    if not isEnabled then return end
    if isLunging and selectedTarget and selectedTarget.Parent then
        pcall(lockToTarget, selectedTarget)
    end
end)

-- Update list saat pemain berubah
Players.PlayerAdded:Connect(pcall(updateTargetList))
Players.PlayerRemoving:Connect(pcall(updateTargetList))

pcall(updateTargetList)
pcall(updateIndicator, false)

print("✅ POV Lock siap! Trigger: animasi lunge + remote Leap/TrailEvent.")
print("📌 Pilih target di panel kanan (cyan).")
print("📌 Saat skill dipakai → hijau, kamera lock + prediksi.")
