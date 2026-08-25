-- ============================================
-- KILLER SKILL REMOTE + ANIMATION CAPTURER + LOOP
-- ============================================

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local playerGui = player:WaitForChild("PlayerGui")

-- Variabel global
local capturedAnims = {}  -- { [id] = {name=..., id=...} }
local remoteEventsList = {}
local activeTracks = {}   -- menyimpan track yang sedang berjalan

-- ============================================
-- 1. BUAT GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillerSkillGUI"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 700, 0, 520)
frame.Position = UDim2.new(0.5, -350, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "🎯 Killer Skills + Animation Capture (Loop)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Parent = frame

-- ============================================
-- 1A. Panel KIRI: Daftar RemoteEvent
-- ============================================
local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0, 320, 0, 400)
leftPanel.Position = UDim2.new(0, 10, 0, 45)
leftPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
leftPanel.BorderSizePixel = 0
leftPanel.Parent = frame

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 6)
leftCorner.Parent = leftPanel

local leftLabel = Instance.new("TextLabel")
leftLabel.Size = UDim2.new(1, 0, 0, 25)
leftLabel.Text = "📡 RemoteEvents"
leftLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
leftLabel.TextSize = 14
leftLabel.Font = Enum.Font.GothamBold
leftLabel.BackgroundTransparency = 1
leftLabel.Parent = leftPanel

local leftScroll = Instance.new("ScrollingFrame")
leftScroll.Size = UDim2.new(1, -10, 1, -35)
leftScroll.Position = UDim2.new(0, 5, 0, 30)
leftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
leftScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
leftScroll.BorderSizePixel = 0
leftScroll.Parent = leftPanel

local leftLayout = Instance.new("UIListLayout")
leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
leftLayout.Padding = UDim.new(0, 2)
leftLayout.Parent = leftScroll

-- ============================================
-- 1B. Panel KANAN: Animasi yang tertangkap
-- ============================================
local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0, 340, 0, 400)
rightPanel.Position = UDim2.new(0, 350, 0, 45)
rightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
rightPanel.BorderSizePixel = 0
rightPanel.Parent = frame

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 6)
rightCorner.Parent = rightPanel

local rightLabel = Instance.new("TextLabel")
rightLabel.Size = UDim2.new(1, 0, 0, 25)
rightLabel.Text = "🎬 Captured Animations"
rightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
rightLabel.TextSize = 14
rightLabel.Font = Enum.Font.GothamBold
rightLabel.BackgroundTransparency = 1
rightLabel.Parent = rightPanel

local rightScroll = Instance.new("ScrollingFrame")
rightScroll.Size = UDim2.new(1, -10, 1, -35)
rightScroll.Position = UDim2.new(0, 5, 0, 30)
rightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
rightScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
rightScroll.BorderSizePixel = 0
rightScroll.Parent = rightPanel

local rightLayout = Instance.new("UIListLayout")
rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
rightLayout.Padding = UDim.new(0, 2)
rightLayout.Parent = rightScroll

-- ============================================
-- 2. FUNGSI PENCARI REMOTEEVENT
-- ============================================
local function findRemoteEvents(parent)
    local events = {}
    for _, obj in pairs(parent:GetChildren()) do
        if obj:IsA("RemoteEvent") then
            table.insert(events, obj.Name)
        elseif obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Tool") then
            for _, name in pairs(findRemoteEvents(obj)) do
                table.insert(events, name)
            end
        end
    end
    return events
end

-- ============================================
-- 3. FUNGSI CAPTURE ANIMASI
-- ============================================
local function captureAnimation(animId, animName)
    if not animId or capturedAnims[animId] then return end
    capturedAnims[animId] = { name = animName, id = animId }
    
    local item = Instance.new("Frame")
    item.Size = UDim2.new(1, 0, 0, 40)
    item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    item.BorderSizePixel = 0
    item.Parent = rightScroll
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 4)
    itemCorner.Parent = item
    
    -- Nama animasi
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 100, 1, 0)
    nameLabel.Text = animName or "Animation"
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = item
    
    -- ID singkat
    local idLabel = Instance.new("TextLabel")
    idLabel.Size = UDim2.new(0, 110, 1, 0)
    idLabel.Position = UDim2.new(0, 105, 0, 0)
    idLabel.Text = string.sub(animId, -12)
    idLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    idLabel.TextSize = 11
    idLabel.Font = Enum.Font.Gotham
    idLabel.BackgroundTransparency = 1
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.Parent = item
    
    -- Tombol Play (sekali)
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0, 28, 0, 28)
    playBtn.Position = UDim2.new(0, 220, 0, 6)
    playBtn.Text = "▶"
    playBtn.TextSize = 16
    playBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    playBtn.BorderSizePixel = 0
    playBtn.Parent = item
    local pCorner = Instance.new("UICorner"); pCorner.CornerRadius = UDim.new(0, 4); pCorner.Parent = playBtn
    playBtn.MouseButton1Click:Connect(function() playAnimation(animId, false) end)
    
    -- Tombol Loop (berulang)
    local loopBtn = Instance.new("TextButton")
    loopBtn.Size = UDim2.new(0, 28, 0, 28)
    loopBtn.Position = UDim2.new(0, 252, 0, 6)
    loopBtn.Text = "🔄"
    loopBtn.TextSize = 16
    loopBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    loopBtn.BorderSizePixel = 0
    loopBtn.Parent = item
    local lCorner = Instance.new("UICorner"); lCorner.CornerRadius = UDim.new(0, 4); lCorner.Parent = loopBtn
    loopBtn.MouseButton1Click:Connect(function() playAnimation(animId, true) end)
    
    -- Tombol Stop semua
    local stopBtn = Instance.new("TextButton")
    stopBtn.Size = UDim2.new(0, 28, 0, 28)
    stopBtn.Position = UDim2.new(0, 284, 0, 6)
    stopBtn.Text = "⏹"
    stopBtn.TextSize = 16
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    stopBtn.BorderSizePixel = 0
    stopBtn.Parent = item
    local sCorner = Instance.new("UICorner"); sCorner.CornerRadius = UDim.new(0, 4); sCorner.Parent = stopBtn
    stopBtn.MouseButton1Click:Connect(function()
        stopAllAnimations()
        notif("⏹ Semua animasi dihentikan")
    end)
    
    -- Tombol Copy ID
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 28, 0, 28)
    copyBtn.Position = UDim2.new(0, 316, 0, 6)
    copyBtn.Text = "📋"
    copyBtn.TextSize = 16
    copyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    copyBtn.BorderSizePixel = 0
    copyBtn.Parent = item
    local cCorner = Instance.new("UICorner"); cCorner.CornerRadius = UDim.new(0, 4); cCorner.Parent = copyBtn
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(animId)
            elseif toClipboard then toClipboard(animId) end
        end)
        notif("📋 ID disalin: " .. string.sub(animId, -12))
    end)
    
    rightScroll.CanvasSize = UDim2.new(0, 0, 0, #capturedAnims * 45 + 10)
end

-- ============================================
-- 4. FUNGSI PLAY ANIMASI (dengan opsi loop)
-- ============================================
local function playAnimation(animId, loop)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    -- Hentikan animasi yang sama jika sedang berjalan
    stopAllAnimations()
    
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    
    local track = hum:LoadAnimation(anim)
    if track then
        if loop then
            track.Looped = true
            track:Play()
            table.insert(activeTracks, track)
            notif("🔄 Looping: " .. string.sub(animId, -12))
        else
            track.Looped = false
            track:Play()
            notif("▶ Playing: " .. string.sub(animId, -12))
        end
    else
        notif("❌ Gagal play animasi")
    end
end

-- ============================================
-- 5. FUNGSI STOP SEMUA ANIMASI
-- ============================================
local function stopAllAnimations()
    for _, track in pairs(activeTracks) do
        pcall(function() track:Stop() end)
    end
    activeTracks = {}
end

-- ============================================
-- 6. NOTIFIKASI
-- ============================================
local function notif(msg)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 450, 0, 35)
    label.Position = UDim2.new(0.5, -225, 0.94, 0)
    label.Text = msg
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    label.BackgroundTransparency = 0.3
    label.BorderSizePixel = 0
    label.Parent = frame
    local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 6); nc.Parent = label
    game:GetService("Debris"):AddItem(label, 2)
end

-- ============================================
-- 7. FIRING REMOTE + CAPTURE
-- ============================================
local function fireRemoteAndCapture(remoteName, remotePath, args)
    -- Copy remote name
    pcall(function()
        if setclipboard then setclipboard(remoteName)
        elseif toClipboard then toClipboard(remoteName) end
    end)
    notif("📋 Remote disalin: " .. remoteName)
    
    local remote = remotePath or game:GetService("ReplicatedStorage"):FindFirstChild(remoteName, true)
    if not remote then
        notif("❌ Remote tidak ditemukan")
        return
    end
    
    local success, err = pcall(function()
        if args then remote:FireServer(unpack(args))
        else remote:FireServer() end
    end)
    if not success then notif("❌ Gagal fire: " .. err) return end
    
    notif("🔥 Fired: " .. remoteName .. " (tunggu animasi...)")
end

-- ============================================
-- 8. LISTENER ANIMASI (capture otomatis)
-- ============================================
hum.AnimationPlayed:Connect(function(track)
    local anim = track.Animation
    if anim and anim.AnimationId then
        local id = anim.AnimationId
        local name = anim.Name or "Animation"
        captureAnimation(id, name)
        -- Copy ID ke clipboard
        pcall(function()
            if setclipboard then setclipboard(id)
            elseif toClipboard then toClipboard(id) end
        end)
        notif("🎬 Animasi tertangkap & ID disalin: " .. name)
    end
end)

-- ============================================
-- 9. TAMPILKAN DAFTAR REMOTE
-- ============================================
local function displayRemoteEvents()
    for _, child in pairs(leftScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    remoteEventsList = {}
    local rs = game:GetService("ReplicatedStorage")
    if rs then
        for _, name in pairs(findRemoteEvents(rs)) do
            table.insert(remoteEventsList, name)
        end
    end
    
    for _, name in pairs(remoteEventsList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(220,220,220)
        btn.TextSize = 13
        btn.Font = Enum.Font.Gotham
        btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = leftScroll
        
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = btn
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70,70,70) end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(50,50,50) end)
        
        btn.MouseButton1Click:Connect(function()
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
            local args = nil
            if name == "M2" or name == "Lunge" then args = { {}, true }
            elseif name == "TrailEvent" then args = { true }
            elseif name == "Leap" then args = { true }
            elseif name == "CarrySurvivorEvent" then args = { game.Players.LocalPlayer.Character }
            elseif name == "ActivatePower" or name == "DeactivatePower" then args = { true }
            end
            fireRemoteAndCapture(name, remote, args)
        end)
    end
    
    leftScroll.CanvasSize = UDim2.new(0, 0, 0, #remoteEventsList * 35 + 10)
end

-- ============================================
-- 10. TOMBOL REFRESH & TUTUP
-- ============================================
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 150, 0, 35)
refreshBtn.Position = UDim2.new(0.5, -75, 0.94, 0)
refreshBtn.Text = "🔄 Refresh List"
refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
refreshBtn.TextSize = 16
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.BackgroundColor3 = Color3.fromRGB(0,120,255)
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = frame
local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,6); rc.Parent = refreshBtn
refreshBtn.MouseButton1Click:Connect(displayRemoteEvents)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 35)
closeBtn.Position = UDim2.new(0.9, 0, 0.94, 0)
closeBtn.Text = "✖ Tutup"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,6); cc.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled = not screenGui.Enabled end)

-- ============================================
-- 11. JALANKAN
-- ============================================
displayRemoteEvents()
notif("✅ Siap! Klik skill → copy remote + capture animasi (bisa loop)")
