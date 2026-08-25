-- GUI Skill Killer dengan Fitur Copy RemoteEvent

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillerSkillGUI"
screenGui.Parent = playerGui

-- Frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 450, 0, 500)
frame.Position = UDim2.new(0.5, -225, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.9
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🎯 Killer Skills - Copy RemoteEvent"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Parent = frame

-- ScrollingFrame untuk daftar skill
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 0, 380)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BorderSizePixel = 0
scrollFrame.Parent = frame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 4)
scrollCorner.Parent = scrollFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = scrollFrame

-- Data skill: {Nama yang tampil, RemoteEvent yang akan di-copy}
local skills = {
    {name = "🔪 Basic Attack", event = "AttackEvent"},
    {name = "🏃 Lunge", event = "Lunge"},
    {name = "🔄 Carry Survivor", event = "CarrySurvivorEvent"},
    {name = "🪝 Hook Survivor", event = "HookEvent"},
    {name = "⚡ Activate Power", event = "ActivatePower"},
    {name = "⛔ Deactivate Power", event = "DeactivatePower"},
    {name = "🔱 Spear Throw", event = "Spearthrow"},
    {name = "🦘 Leap", event = "Leap"},
    {name = "💨 Rush", event = "Rush"},
    {name = "🔥 Fire (Projectile)", event = "Fire"},
    {name = "💣 Throw Grenade", event = "Throw"},
    {name = "📡 Teleport", event = "Teleport"},
    {name = "🎯 Stalk", event = "StartStalking"},
    {name = "👀 Instinct", event = "Instinct"},
    {name = "🔄 Frenzy Hit", event = "FrenzyHitEvent"},
    {name = "🗡️ Mori", event = "Startmori"},
    {name = "🌀 Corrupt", event = "corrupt"},
    {name = "⚫ Echo Void", event = "EchoVoid_Trigger"},
    -- Tambahkan skill lain sesuai keinginan
}

-- Fungsi untuk membuat tombol skill
local function createSkillButton(skillData)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 40)
    button.Text = skillData.name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 18
    button.Font = Enum.Font.GothamBold
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.BorderSizePixel = 0
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.Parent = scrollFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
    
    -- 🔥 Saat diklik, copy RemoteEvent-nya
    button.MouseButton1Click:Connect(function()
        local eventName = skillData.event
        local success, err = pcall(function()
            if setclipboard then
                setclipboard(eventName)
            elseif toClipboard then
                toClipboard(eventName)
            else
                error("Clipboard function not available")
            end
        end)
        
        -- Notifikasi
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 350, 0, 40)
        notif.Position = UDim2.new(0.5, -175, 0.92, 0)
        notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        notif.BackgroundTransparency = 0.2
        notif.BorderSizePixel = 0
        notif.Parent = frame
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 6)
        notifCorner.Parent = notif
        
        if success then
            notif.Text = "✅ Copied: " .. eventName .. " (ready to use)"
            notif.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            notif.Text = "❌ Failed to copy!"
            notif.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        notif.TextSize = 18
        notif.Font = Enum.Font.GothamBold
        game:GetService("Debris"):AddItem(notif, 2)
    end)
    
    return button
end

-- Buat semua tombol skill
for _, skill in pairs(skills) do
    createSkillButton(skill)
end

-- Update canvas size
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #skills * 45 + 10)

-- Tombol Tutup
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 100, 0, 40)
closeButton.Position = UDim2.new(0.8, 0, 0.88, 0)
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
