--[[
    🔥 POV LOCK PRO + AUTO FIND REMOTE (AMAN)
    - Mencari semua remote dengan kata kunci tertentu
    - Tombol ON/OFF + indikator lingkaran
    - Lock saat gerak & skill
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
local KEYWORDS = {"Hidden", "Stab", "M2", "Leap", "Skill"}  -- tambah sesuai kebutuhan

-- ===== VARIABEL =====
local isEnabled = true
local lockUntil = 0
local character = player.Character or player.CharacterAdded:Wait()

-- ===== FUNGSI TARGET =====
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

local function lockToTarget(target)
    if target and isEnabled then
        local currentPos = camera.CFrame.Position
        camera.CFrame = CFrame.new(currentPos, target.Position)
        return true
    end
    return false
end

-- ===== HOOK REMOTE =====
local function hookRemote(remote)
    if not remote then return end

    if remote:IsA("RemoteEvent") then
        local original = remote.FireServer
        remote.FireServer = function(self, ...)
            if isEnabled then
                local target = getNearestTarget()
                if target then
                    lockToTarget(target)
                    lockUntil = tick() + LOCK_DURATION
                end
            end
            return original(self, ...)
        end
        print("✅ Hook RemoteEvent: " .. remote.Name)
    elseif remote:IsA("RemoteFunction") then
        local original = remote.InvokeServer
        remote.InvokeServer = function(self, ...)
            if isEnabled then
                local target = getNearestTarget()
                if target then
                    lockToTarget(target)
                    lockUntil = tick() + LOCK_DURATION
                end
            end
            return original(self, ...)
        end
        print("✅ Hook RemoteFunction: " .. remote.Name)
    end
end

-- ===== CARI & HOOK SEMUA REMOTE DENGAN KATA KUNCI (REKURSIF AMAN) =====
local function findAndHookRemotes(parent, keywords)
    if not parent then return end  -- CEK NIL!

    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            for _, kw in ipairs(keywords) do
                if string.find(child.Name, kw) then
                    hookRemote(child)
                    break
                end
            end
        elseif child:IsA("Folder") or child:IsA("Model") or child:IsA("Tool") then
            -- Rekursi ke child, tapi pastikan child tidak nil
            findAndHookRemotes(child, keywords)
        end
    end
end

-- Jalankan pencarian (gunakan pcall untuk aman)
local success, err = pcall(function()
    findAndHookRemotes(ReplicatedStorage, KEYWORDS)
end)
if not success then
    warn("Gagal mencari remote: " .. tostring(err))
end

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
        local target = getNearestTarget()
        if target then
            lockToTarget(target)
            updateIndicator(true)
        else
            updateIndicator(false)
        end
    else
        updateIndicator(false)
    end
end)

-- ===== UI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POVLockUI"
screenGui.Parent = player.PlayerGui

-- Tombol ON/OFF
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 120, 0, 40)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
toggleBtn.Text = "🔒 ON"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = frame

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

updateIndicator(false)
print("✅ POV Lock siap! Mencari remote dengan kata kunci: " .. table.concat(KEYWORDS, ", "))
