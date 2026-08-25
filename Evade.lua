-- =====================================================
-- GUI SKILL KILLER + REMOTE EVENT FIRER + ANIMATION CAPTURE
-- =====================================================

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

-- Variabel untuk menyimpan Animation ID yang tertangkap
local capturedAnimations = {}
local lastCapturedAnim = nil

-- ====== FUNGSI CAPTURE ANIMATION ======
local function captureAnimation(animId, animName)
    if not animId or capturedAnimations[animId] then return end
    capturedAnimations[animId] = true
    
    -- Simpan sebagai data terakhir
    lastCapturedAnim = {
        id = animId,
        name = animName or "Unknown"
    }
    
    -- Tampilkan di console
    print("🎬 Animation tertangkap: " .. animName)
    print("   ID: " .. animId)
end

-- Pasang listener untuk menangkap animasi
hum.AnimationPlayed:Connect(function(track)
    local anim = track.Animation
    if anim and anim.AnimationId then
        captureAnimation(anim.AnimationId, anim.Name)
    end
end)

-- ====== BUAT GUI ======
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillerSkillGUI"
screenGui.Parent = playerGui

-- Frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 500)
frame.Position = UDim2.new(0.5, -175, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🔪 KILLER SKILLS"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Parent = frame

-- ScrollingFrame untuk daftar skill
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -100)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
scrollFrame.BackgroundTransparency = 0.5
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = frame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 6)
scrollCorner.Parent = scrollFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 4)
uiListLayout.Parent = scrollFrame

-- ====== DAFTAR SKILL KILLER ======
local skillList = {
    {name = "Lunge", remote = "Lunge"},
    {name = "Carry Survivor", remote = "CarrySurvivorEvent"},
    {name = "Hook Survivor", remote = "HookEvent"},
    {name = "Activate Power", remote = "ActivatePower"},
    {name = "Deactivate Power", remote = "Deactivatepower"},
    {name = "Spear Throw", remote = "Spearthrow"},
    {name = "Leap", remote = "Leap"},
    {name = "Basic Attack", remote = "BasicAttack"},
    {name = "Pallet Break", remote = "PalletBreakCommit"},
    {name = "Grab", remote = "grab"},
    {name = "Mori", remote = "Startmori"},
    {name = "Teleport", remote = "Teleport"},
}

-- ====== FUNGSI FIRE REMOTE + CAPTURE ======
local function fireRemoteAndCapture(remoteName, skillName)
    -- Cari RemoteEvent di ReplicatedStorage
    local remote = nil
    local replicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Cari secara rekursif di ReplicatedStorage
    local function findRemote(parent)
        for _, obj in pairs(parent:GetChildren()) do
            if obj:IsA("RemoteEvent") and obj.Name == remoteName then
                return obj
            elseif obj:IsA("Folder") or obj:IsA("Model") then
                local found = findRemote(obj)
                if found then return found end
            end
        end
        return nil
    end
    
    remote = findRemote(replicatedStorage)
    
    if not remote then
        -- Coba cari di Workspace juga
        remote = findRemote(game.Workspace)
    end
    
    -- Notifikasi
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 300, 0, 40)
    notif.Position = UDim2.new(0.5, -150, 0.9, 0)
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notif.BackgroundTransparency = 0.2
    notif.BorderSizePixel = 0
    notif.Parent = frame
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 6)
    notifCorner.Parent = notif
    notif.TextSize = 16
    notif.Font = Enum.Font.GothamBold
    notif.TextScaled = false
    
    if remote then
        -- FIRE RemoteEvent (jalankan skill)
        pcall(function()
            remote:FireServer()
            remote:FireClient()
        end)
        
        -- Copy nama RemoteEvent ke clipboard
        local copySuccess = false
        pcall(function()
            if setclipboard then
                setclipboard(remoteName)
                copySuccess = true
            elseif toClipboard then
                toClipboard(remoteName)
                copySuccess = true
            end
        end)
        
        -- Reset capture animasi sebelumnya
        lastCapturedAnim = nil
        
        -- Tunggu sebentar untuk menangkap animasi
        task.wait(0.3)
        
        -- Tampilkan notifikasi
        local msg = "✅ " .. skillName .. " berhasil dijalankan!\n"
        msg = msg .. "📋 Remote: " .. remoteName .. " (disalin)\n"
        if lastCapturedAnim then
            msg = msg .. "🎬 Animasi: " .. lastCapturedAnim.name .. "\n"
            msg = msg .. "   ID: " .. lastCapturedAnim.id
            -- Copy juga Animation ID ke clipboard (tambahan)
            pcall(function()
                if setclipboard then
                    setclipboard(lastCapturedAnim.id)
                end
            end)
        else
            msg = msg .. "⏳ Belum ada animasi tertangkap"
        end
        
        notif.Text = msg
        notif.TextColor3 = Color3.fromRGB(100, 255, 100)
        notif.Size = UDim2.new(0, 400, 0, 80) -- lebih tinggi karena banyak teks
        
    else
        notif.Text = "❌ RemoteEvent '" .. remoteName .. "' tidak ditemukan!"
        notif.TextColor3 = Color3.fromRGB(255, 100, 100)
        notif.Size = UDim2.new(0, 350, 0, 40)
    end
    
    -- Hilangkan notifikasi setelah 2 detik
    game:GetService("Debris"):AddItem(notif, 2.5)
end

-- ====== BUAT TOMBOL SKILL ======
for _, skill in pairs(skillList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = skill.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.BorderSizePixel = 0
    btn.Parent = scrollFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    -- Efek hover
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    end)
    
    -- Saat diklik → fire remote + capture animasi
    btn.MouseButton1Click:Connect(function()
        fireRemoteAndCapture(skill.remote, skill.name)
    end)
end

-- Update canvas size
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #skillList * 44 + 10)

-- ====== TOMBOL TUTUP ======
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 35)
closeBtn.Position = UDim2.new(1, -90, 0, 5)
closeBtn.Text = "✖"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 20
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

-- ====== TOMBOL CAPTURE ANIMASI MANUAL ======
local captureBtn = Instance.new("TextButton")
captureBtn.Size = UDim2.new(0, 150, 0, 35)
captureBtn.Position = UDim2.new(0, 10, 0, 5)
captureBtn.Text = "🎬 Capture Anim"
captureBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
captureBtn.TextSize = 14
captureBtn.Font = Enum.Font.GothamBold
captureBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
captureBtn.BorderSizePixel = 0
captureBtn.Parent = frame

local captureCorner = Instance.new("UICorner")
captureCorner.CornerRadius = UDim.new(0, 6)
captureCorner.Parent = captureBtn

captureBtn.MouseButton1Click:Connect(function()
    lastCapturedAnim = nil
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0, 300, 0, 40)
    notif.Position = UDim2.new(0.5, -150, 0.85, 0)
    notif.Text = "⏳ Lakukan emote/skill sekarang..."
    notif.TextColor3 = Color3.fromRGB(255, 255, 100)
    notif.TextSize = 16
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    notif.BackgroundTransparency = 0.2
    notif.BorderSizePixel = 0
    notif.Parent = frame
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 6)
    notifCorner.Parent = notif
    
    -- Tunggu maksimal 5 detik untuk menangkap animasi
    local startTime = tick()
    repeat
        task.wait(0.1)
        if lastCapturedAnim then
            notif.Text = "✅ Animasi tertangkap: " .. lastCapturedAnim.name
            notif.TextColor3 = Color3.fromRGB(100, 255, 100)
            pcall(function()
                if setclipboard then
                    setclipboard(lastCapturedAnim.id)
                end
            end)
            break
        end
    until tick() - startTime > 5
    
    if not lastCapturedAnim then
        notif.Text = "❌ Tidak ada animasi tertangkap!"
        notif.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    
    game:GetService("Debris"):AddItem(notif, 2)
end)

print("🔪 Killer Skill GUI siap!")
