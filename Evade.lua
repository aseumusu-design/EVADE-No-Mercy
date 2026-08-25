-- Script GUI Pencari RemoteEvent dengan Fitur Copy
-- Versi Lengkap

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Membuat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteEventFinderGUI"
screenGui.Parent = playerGui

-- Frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 550, 0, 400)
frame.Position = UDim2.new(0.5, -275, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.9
frame.Parent = screenGui

-- Memberi sudut melengkung (opsional, jika didukung)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🔍 RemoteEvent Finder"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Parent = frame

-- ScrollingFrame untuk daftar
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 0, 270)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = frame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 4)
scrollCorner.Parent = scrollFrame

-- Layout untuk list
local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 2)
uiListLayout.Parent = scrollFrame

-- Variabel untuk menyimpan daftar RemoteEvent
local remoteEventsList = {}

-- Fungsi rekursif untuk mencari RemoteEvent
local function findRemoteEvents(parent)
    local events = {}
    for _, obj in pairs(parent:GetChildren()) do
        if obj:IsA("RemoteEvent") then
            table.insert(events, obj.Name)
        elseif obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Tool") then
            local childEvents = findRemoteEvents(obj)
            for _, name in pairs(childEvents) do
                table.insert(events, name)
            end
        end
    end
    return events
end

-- Fungsi untuk menampilkan daftar di GUI
local function displayRemoteEvents()
    -- Hapus label lama
    for _, child in pairs(scrollFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Cari RemoteEvent di ReplicatedStorage (bisa ditambah tempat lain)
    remoteEventsList = {}
    local replicatedStorage = game:GetService("ReplicatedStorage")
    if replicatedStorage then
        local found = findRemoteEvents(replicatedStorage)
        for _, name in pairs(found) do
            table.insert(remoteEventsList, name)
        end
    end
    
    -- (Opsional) Cari juga di Workspace, ServerStorage, dll.
    -- local workspaceEvents = findRemoteEvents(game.Workspace)
    -- ... tambahkan jika diinginkan
    
    -- Tampilkan setiap event sebagai label
    for _, eventName in pairs(remoteEventsList) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 28)
        label.Text = eventName
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 16
        label.Font = Enum.Font.Gotham
        label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        label.BorderSizePixel = 0
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = scrollFrame
        
        local labelCorner = Instance.new("UICorner")
        labelCorner.CornerRadius = UDim.new(0, 4)
        labelCorner.Parent = label
    end
    
    -- Update ukuran canvas
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #remoteEventsList * 30 + 10)
    
    -- Tampilkan jumlah ditemukan di judul (opsional)
    title.Text = "🔍 RemoteEvent Finder (" .. #remoteEventsList .. " ditemukan)"
end

-- Fungsi untuk menyalin semua nama ke clipboard
local function copyAllEvents()
    if #remoteEventsList == 0 then
        -- Jika belum ada daftar, jalankan pencarian dulu
        displayRemoteEvents()
    end
    
    if #remoteEventsList == 0 then
        -- Beri notifikasi tidak ada event
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 300, 0, 40)
        notif.Position = UDim2.new(0.5, -150, 0.9, 0)
        notif.Text = "Tidak ada RemoteEvent ditemukan!"
        notif.TextColor3 = Color3.fromRGB(255, 200, 100)
        notif.TextSize = 18
        notif.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        notif.BackgroundTransparency = 0.8
        notif.Parent = frame
        game:GetService("Debris"):AddItem(notif, 2)
        return
    end
    
    -- Buat string dengan format setiap nama di baris baru
    local textToCopy = table.concat(remoteEventsList, "\n")
    
    -- Salin ke clipboard (jika tersedia)
    local success, err = pcall(function()
        if setclipboard then
            setclipboard(textToCopy)
        elseif toClipboard then
            toClipboard(textToCopy)
        else
            error("Clipboard function not available")
        end
    end)
    
    if success then
        -- Tampilkan notifikasi berhasil
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 300, 0, 40)
        notif.Position = UDim2.new(0.5, -150, 0.9, 0)
        notif.Text = "✅ " .. #remoteEventsList .. " nama telah disalin!"
        notif.TextColor3 = Color3.fromRGB(100, 255, 100)
        notif.TextSize = 18
        notif.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        notif.BackgroundTransparency = 0.8
        notif.Parent = frame
        game:GetService("Debris"):AddItem(notif, 2)
    else
        -- Fallback: tampilkan di chat atau popup
        warn("Gagal menyalin: " .. err)
        -- Tampilkan pesan di layar
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 300, 0, 40)
        notif.Position = UDim2.new(0.5, -150, 0.9, 0)
        notif.Text = "❌ Gagal menyalin, coba manual."
        notif.TextColor3 = Color3.fromRGB(255, 100, 100)
        notif.TextSize = 18
        notif.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        notif.BackgroundTransparency = 0.8
        notif.Parent = frame
        game:GetService("Debris"):AddItem(notif, 3)
    end
end

-- Tombol "Cari RemoteEvents"
local findButton = Instance.new("TextButton")
findButton.Size = UDim2.new(0, 160, 0, 40)
findButton.Position = UDim2.new(0.05, 0, 0.85, 0)
findButton.Text = "🔎 Cari"
findButton.TextColor3 = Color3.fromRGB(255, 255, 255)
findButton.TextSize = 18
findButton.Font = Enum.Font.GothamBold
findButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
findButton.BorderSizePixel = 0
findButton.Parent = frame

local findCorner = Instance.new("UICorner")
findCorner.CornerRadius = UDim.new(0, 6)
findCorner.Parent = findButton

findButton.MouseButton1Click:Connect(displayRemoteEvents)

-- Tombol "Salin Semua"
local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(0, 160, 0, 40)
copyButton.Position = UDim2.new(0.5, -80, 0.85, 0)
copyButton.Text = "📋 Salin Semua"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.TextSize = 18
copyButton.Font = Enum.Font.GothamBold
copyButton.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
copyButton.BorderSizePixel = 0
copyButton.Parent = frame

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 6)
copyCorner.Parent = copyButton

copyButton.MouseButton1Click:Connect(copyAllEvents)

-- Tombol "Tutup"
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 80, 0, 40)
closeButton.Position = UDim2.new(0.85, 0, 0.85, 0)
closeButton.Text = "✖ Tutup"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 16
closeButton.Font = Enum.Font.GothamBold
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
end)

-- Jalankan pencarian otomatis saat GUI pertama kali muncul
displayRemoteEvents()
