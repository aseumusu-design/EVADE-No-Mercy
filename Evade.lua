--[[
    🔥 POV LOCK PRO + DAFTAR TARGET MANUAL
    - Tampilkan semua musuh dalam radius (nama + jarak)
    - Klik nama untuk lock ke target itu
    - Tombol "Auto" untuk kembali ke target terdekat
    - Kamera tetap mengikuti target saat gerak / skill
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== KONFIGURASI =====
local RADIUS = 100
local LOCK_DURATION = 0.8
local SKILL_KEY = Enum.KeyCode.E

-- ===== VARIABEL =====
local isEnabled = true
local lockUntil = 0
local character = player.Character or player.CharacterAdded:Wait()
local selectedTarget = nil          -- Target yang dipilih manual (HumanoidRootPart)
local targetName = ""

-- ===== FUNGSI MENDAPATKAN SEMUA MUSUH DALAM RADIUS =====
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
                        table.insert(targets, {
                            player = otherPlayer,
                            rootPart = otherRoot,
                            distance = dist,
                            name = otherPlayer.Name
                        })
                    end
                end
            end
        end
    end
    table.sort(targets, function(a, b) return a.distance < b.distance end)
    return targets
end

-- ===== FUNGSI TARGET TERDEKAT (AUTO) =====
local function getNearestTarget()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearestPart = nil
    local nearestDist = RADIUS

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

-- ===== LOCK KAMERA KE TARGET =====
local function lockToTarget(target)
    if target and isEnabled then
        local currentPos = camera.CFrame.Position
        camera.CFrame = CFrame.new(currentPos, target.Position)
        return true
    end
    return false
end

-- ===== CARI TARGET AKTIF =====
local function getActiveTarget()
    if selectedTarget and selectedTarget.Parent and selectedTarget.Parent:FindFirstChild("Humanoid") and
        selectedTarget.Parent.Humanoid.Health > 0 then
        return selectedTarget
    else
        selectedTarget = nil
        targetName = ""
        return nil
    end
end

-- ===== HOOK REMOTE (SEMUA) =====
local function hookRemote(remote)
    if not remote then return end
    if remote:IsA("RemoteEvent") then
        local success, original = pcall(function() return remote.FireServer end)
        if not success or type(original) ~= "function" then return end
        remote.FireServer = function(self, ...)
            if isEnabled then
                local target = getActiveTarget() or getNearestTarget()
                if target then
                    lockToTarget(target)
                    lockUntil = tick() + LOCK_DURATION
                end
            end
            return original(self, ...)
        end
    elseif remote:IsA("RemoteFunction") then
        local success, original = pcall(function() return remote.InvokeServer end)
        if not success or type(original) ~= "function" then return end
        remote.InvokeServer = function(self, ...)
            if isEnabled then
                local target = getActiveTarget() or getNearestTarget()
                if target then
                    lockToTarget(target)
                    lockUntil = tick() + LOCK_DURATION
                end
            end
            return original(self, ...)
        end
    end
end

-- Scan & hook semua remote
local function scanAndHook(parent)
    if not parent then return end
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            hookRemote(child)
        elseif child:IsA("Folder") or child:IsA("Model") or child:IsA("Tool") then
            scanAndHook(child)
        end
    end
end
pcall(scanAndHook, ReplicatedStorage)

-- ===== LOOP UTAMA =====
RunService.Heartbeat:Connect(function()
    if not character or character.Parent == nil then
        character = player.Character
        if not character then return end
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local isMoving = (humanoid.MoveDirection.Magnitude > 0.1)
    local isUsingKey = UserInputService:IsKeyDown(SKILL_KEY)
    local isLockedByRemote = (tick() < lockUntil)

    if isEnabled and (isMoving or isUsingKey or isLockedByRemote) then
        local target = getActiveTarget() or getNearestTarget()
        if target then
            lockToTarget(target)
            updateIndicator(true)
        else
            updateIndicator(false)
        end
    else
        updateIndicator(false)
    end

    -- Update daftar target setiap saat (untuk UI)
    updateTargetList()
end)

-- ===== UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POVLockUI"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

-- Tombol ON/OFF (pojok kiri atas)
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

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    toggleBtn.Text = isEnabled and "🔒 ON" or "🔓 OFF"
    toggleBtn.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(200, 50, 50)
end)

-- Indikator lingkaran tengah
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 20, 0, 20)
indicator.Position = UDim2.new(0.5, -10, 0.5, -10)
indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
indicator.BackgroundTransparency = 0.5
indicator.BorderSizePixel = 0
indicator.Parent = screenGui

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1, 0)
indicatorCorner.Parent = indicator

function updateIndicator(locked)
    if locked then
        indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        indicator.BackgroundTransparency = 0.3
    else
        indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        indicator.BackgroundTransparency = 0.5
    end
end

-- ===== PANEL DAFTAR TARGET (pojok kanan atas) =====
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

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 24)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎯 TARGETS"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = targetPanel

-- Tombol "Auto" (kembali ke nearest)
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
end)

-- Scrolling frame untuk daftar target
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

-- Fungsi update daftar target
local function updateTargetList()
    -- Hapus semua tombol sebelumnya (kecuali UIListLayout)
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local targets = getTargetsInRadius()
    local active = getActiveTarget()

    for i, data in ipairs(targets) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        btn.Text = string.format("%s (%.1f)", data.name, data.distance)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = scrollFrame

        -- Highlight jika target ini sedang dipilih
        if active and active == data.rootPart then
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
        end

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            selectedTarget = data.rootPart
            targetName = data.name
            -- Update highlight
            updateTargetList()
        end)
    end

    -- Update canvas size
    local count = #targets
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 24 + 10)

    -- Tampilkan target aktif di title
    if active then
        local name = targetName ~= "" and targetName or (active.Parent and active.Parent.Name or "?")
        titleLabel.Text = "🎯 " .. name
    else
        titleLabel.Text = "🎯 TARGETS"
    end
end

-- Inisialisasi daftar
updateTargetList()

-- Update daftar setiap kali ada pemain baru/keluar
Players.PlayerAdded:Connect(updateTargetList)
Players.PlayerRemoving:Connect(updateTargetList)
-- Update juga setiap kali karakter berubah
player.CharacterAdded:Connect(function()
    character = player.Character
    selectedTarget = nil
    updateTargetList()
end)

print("✅ POV Lock + Target List siap!")
print("📌 Klik nama target di panel kanan atas untuk lock.")
print("📌 Klik 'Auto' untuk kembali ke target terdekat.")
