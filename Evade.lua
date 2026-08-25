-- ============================================
-- KILLER SKILL REMOTE + ANIMATION CAPTURER
-- Klik tombol skill → copy remote + capture animasi
-- ============================================

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local playerGui = player:WaitForChild("PlayerGui")

-- Variabel global
local capturedAnims = {}  -- { [id] = {name=..., id=...} }
local remoteEventsList = {}
local selectedRemote = nil
local remoteArgsCache = {}  -- buat simpan argument per remote

-- ============================================
-- 1. BUAT GUI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillerSkillGUI"
screenGui.Parent = playerGui

-- Frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 650, 0, 500)
frame.Position = UDim2.new(0.5, -325, 0.5, -250)
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
title.Text = "🎯 Killer Skills + Animation Capture"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Parent = frame

-- ============================================
-- 1A. Panel KIRI: Daftar RemoteEvent
-- ============================================
local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0, 300, 0, 400)
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
rightPanel.Size = UDim2.new(0, 300, 0, 400)
rightPanel.Position = UDim2.new(0, 340, 0, 45)
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
    
    -- Tampilkan di panel kanan
    local item = Instance.new("Frame")
    item.Size = UDim2.new(1, 0, 0, 35)
    item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    item.BorderSizePixel = 0
    item.Parent = rightScroll
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 4)
    itemCorner.Parent = item
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 120, 1, 0)
    nameLabel.Text = animName or "Animation"
    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = item
    
    local idLabel = Instance.new("TextLabel")
    idLabel.Size = UDim2.new(0, 130, 1, 0)
    idLabel.Position = UDim2.new(0, 125, 0, 0)
    idLabel.Text = string.sub(animId, -12)
    idLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    idLabel.TextSize = 11
    idLabel.Font = Enum.Font.Gotham
    idLabel.BackgroundTransparency = 1
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.Parent = item
    
    -- Tombol Copy ID
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 30, 1, -4)
    copyBtn.Position = UDim2.new(0, 260, 0, 2)
    copyBtn.Text = "📋"
    copyBtn.TextSize = 14
    copyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    copyBtn.BorderSizePixel = 0
    copyBtn.Parent = item
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 4)
    copyCorner.Parent = copyBtn
    
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(animId)
            elseif toClipboard then toClipboard(animId) end
        end)
        notif("📋 ID disalin: " .. string.sub(animId, -12))
    end)
    
    -- Tombol Play Animasi
    local playBtn = Instance.new("TextButton")
    playBtn.Size = UDim2.new(0, 30, 1, -4)
    playBtn.Position = UDim2.new(0, 230, 0, 2)
    playBtn.Text = "▶"
    playBtn.TextSize = 14
    playBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    playBtn.BorderSizePixel = 0
    playBtn.Parent = item
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 4)
    playCorner.Parent = playBtn
    
    playBtn.MouseButton1Click:Connect(function()
        playAnimation(animId)
    end)
    
    -- Update scroll
    rightScroll.CanvasSize = UDim2.new(0, 0, 0, #capturedAnims * 40 + 10)
end

-- ============================================
-- 4. FUNGSI PLAY ANIMASI (Anti-Remote)
-- ============================================
local function playAnimation(animId)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    
    local track = hum:LoadAnimation(anim)
    if track then
        track:Play()
        notif("▶ Playing: " .. string.sub(animId, -12))
    else
        notif("❌ Gagal play animasi")
    end
end

-- ============================================
-- 5. NOTIFIKASI POPUP
-- ============================================
local function notif(msg)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 400, 0, 35)
    label.Position = UDim2.new(0.5, -200, 0.92, 0)
    label.Text = msg
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 16
    label.Font = Enum.Font.GothamBold
    label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    label.BackgroundTransparency = 0.3
    label.BorderSizePixel = 0
    label.Parent = frame
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 6)
    notifCorner.Parent = label
    
    game:GetService("Debris"):AddItem(label, 2)
end

-- ============================================
-- 6. FIRING REMOTE + CAPTURE ANIMASI
-- ============================================
local function fireRemoteAndCapture(remoteName, remotePath, args)
    -- 1. Copy nama remote ke clipboard
    pcall(function()
        if setclipboard then setclipboard(remoteName)
        elseif toClipboard then toClipboard(remoteName) end
    end)
    notif("📋 Remote disalin: " .. remoteName)
    
    -- 2. Ambil RemoteEvent
    local remote = remotePath or game:GetService("ReplicatedStorage"):FindFirstChild(remoteName, true)
    if not remote then
        notif("❌ Remote tidak ditemukan: " .. remoteName)
        return
    end
    
    -- 3. Fire dengan argument
    local success, err = pcall(function()
        if args then
            remote:FireServer(unpack(args))
        else
            remote:FireServer()
        end
    end)
    
    if not success then
        notif("❌ Gagal fire: " .. err)
        return
    end
    
    notif("🔥 Fired: " .. remoteName .. " (menunggu animasi...)")
end

-- ============================================
-- 7. LISTENER ANIMASI (Otomatis capture)
-- ============================================
hum.AnimationPlayed:Connect(function(track)
    local anim = track.Animation
    if anim and anim.AnimationId then
        local id = anim.AnimationId
        local name = anim.Name or "Animation"
        
        -- Capture dan tampilkan
        captureAnimation(id, name)
        
        -- Langsung copy ke clipboard (opsional)
        pcall(function()
            if setclipboard then setclipboard(id)
            elseif toClipboard then toClipboard(id) end
        end)
        
        notif("🎬 Animasi tertangkap & disalin: " .. name)
    end
end)

-- ============================================
-- 8. TAMPILKAN DAFTAR REMOTE DI GUI
-- ============================================
local function displayRemoteEvents()
    -- Bersihkan panel kiri
    for _, child in pairs(leftScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    remoteEventsList = {}
    local rs = game:GetService("ReplicatedStorage")
    if rs then
        local found = findRemoteEvents(rs)
        for _, name in pairs(found) do
            table.insert(remoteEventsList, name)
        end
    end
    
    -- Buat tombol untuk setiap remote
    for _, name in pairs(remoteEventsList) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = leftScroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn
        
        -- Efek hover
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)
        
        -- Saat diklik: fire remote + capture animasi
        btn.MouseButton1Click:Connect(function()
            -- Cari path remote
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
            
            -- Tentukan argument default (bisa disesuaikan)
            local args = nil
            if name == "M2" or name == "Lunge" then
                args = { {}, true }
            elseif name == "TrailEvent" then
                args = { true }
            elseif name == "Leap" then
                args = { true }
            elseif name == "CarrySurvivorEvent" then
                args = { game.Players.LocalPlayer.Character }
            elseif name == "ActivatePower" or name == "DeactivatePower" then
                args = { true }
            end
            
            fireRemoteAndCapture(name, remote, args)
        end)
    end
    
    leftScroll.CanvasSize = UDim2.new(0, 0, 0, #remoteEventsList * 35 + 10)
end

-- ============================================
-- 9. TOMBOL REFRESH
-- ============================================
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 150, 0, 35)
refreshBtn.Position = UDim2.new(0.5, -75, 0.92, 0)
refreshBtn.Text = "🔄 Refresh List"
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.TextSize = 16
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = frame

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshBtn

refreshBtn.MouseButton1Click:Connect(displayRemoteEvents)

-- ============================================
-- 10. TOMBOL TUTUP
-- ============================================
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 35)
closeBtn.Position = UDim2.new(0.9, 0, 0.92, 0)
closeBtn.Text = "✖ Tutup"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
end)

-- ============================================
-- 11. JALANKAN
-- ============================================
displayRemoteEvents()
notif("✅ Siap! Klik skill → copy remote + capture animasi")

-- Buat label di panel kanan kosong
local emptyLabel = Instance.new("TextLabel")
emptyLabel.Size = UDim2.new(1, 0, 0, 30)
emptyLabel.Text = "Belum ada animasi tertangkap"
emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
emptyLabel.TextSize = 14
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.BackgroundTransparency = 1
emptyLabel.Parent = rightScroll
