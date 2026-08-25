--[[
=========================================================================
    A2 HUB V7.0 - SYNCED DOUBLE FIRE & SMART COMBAT
    - Fixed: Tidak spam otomatis, menembak pas saat tombol game ditekan
    - Hook FireServer murni untuk sinkronisasi peluru yang akurat
    - Compact FOV (80-120), Laser Tracer, & Smart CamLock
=========================================================================
]]

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ==================== THEME CONFIG ====================
local THEME = {
    Bg       = Color3.fromRGB(12, 12, 18),
    Dark     = Color3.fromRGB(18, 18, 26),
    Panel    = Color3.fromRGB(24, 24, 35),
    Accent   = Color3.fromRGB(138, 43, 226),
    Green    = Color3.fromRGB(46, 204, 113),
    Red      = Color3.fromRGB(231, 76, 60),
    White    = Color3.fromRGB(255, 255, 255),
    TextDim  = Color3.fromRGB(150, 150, 170),
}

local TARGET_COLORS = {
    Killer   = Color3.fromRGB(255, 60, 60),
    Survivor = Color3.fromRGB(52, 152, 219),
    Zombie   = Color3.fromRGB(46, 204, 113),
    All      = Color3.fromRGB(241, 196, 15),
}

-- ==================== SMART CONFIG ====================
local Config = {
    TargetType     = "Killer",  -- Killer, Survivor, Zombie, All
    AimPart        = "Head",    -- "Head" atau "Body"
    
    LaserEnabled   = true,      -- Laser penunjuk langsung ke target
    CamLockEnabled = true,      -- Camera Lock halus
    Prediction     = true,      -- Prediksi milidetik pergerakan target
    DoubleFireSync = true,      -- Sinkronisasi peluru pas saat menembak
    
    FOVRadius      = 100,       -- Ukuran FOV kompak (Range 80 - 120)
    MinDist        = 5,         -- Batas jarak terlalu dekat (Aman dari bug)
    MaxDist        = 800,       -- Jarak maksimal
}

local CurrentTarget = nil
local isFiringSync  = false

-- ==================== VISUAL: LASER TRACER ====================
local LaserPart = Instance.new("Part")
LaserPart.Name = "A2_LaserTracer"
LaserPart.Anchored = true
LaserPart.CanCollide = false
LaserPart.CanQuery = false
LaserPart.CanTouch = false
LaserPart.Material = Enum.Material.Neon
LaserPart.Size = Vector3.new(0.1, 0.1, 1)
LaserPart.Transparency = 1
LaserPart.Parent = Workspace

-- ==================== VISUAL: FOV CIRCLE (80 - 120) ====================
local guiParent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
pcall(function() if guiParent:FindFirstChild("A2HubV7") then guiParent.A2HubV7:Destroy() end end)

local ScreenGui = Instance.new("ScreenGui", guiParent)
ScreenGui.Name = "A2HubV7"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local FOVFrame = Instance.new("Frame", ScreenGui)
FOVFrame.Name = "FOVCircle"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
FOVFrame.BackgroundTransparency = 1

local UICornerFOV = Instance.new("UICorner", FOVFrame)
UICornerFOV.CornerRadius = UDim.new(1, 0)

local UIStrokeFOV = Instance.new("UIStroke", FOVFrame)
UIStrokeFOV.Color = Color3.fromRGB(255, 255, 255)
UIStrokeFOV.Thickness = 1.5
UIStrokeFOV.Transparency = 0.3

-- ==================== UTILS & SMART CHECKS ====================
local function ClassifyTarget(char, plr)
    local n = (char and char.Name or ""):lower()
    local t = (plr and plr.Team and plr.Team.Name or ""):lower()
    if n:find("kill") or n:find("monster") or n:find("slasher") or n:find("murder") or t:find("kill") then 
        return "Killer" 
    end
    if n:find("zomb") or n:find("infect") then return "Zombie" end
    if plr then return "Survivor" end
    return "Killer"
end

local function IsAlive(char)
    if not char or not char.Parent then return false end
    local h = char:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0 and (char:FindFirstChild("Head") ~= nil or char:FindFirstChild("HumanoidRootPart") ~= nil)
end

local function GetTargetPart(char)
    if Config.AimPart == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    end
end

-- WallCheck Pintar: Deteksi halangan tembok
local function HasLineOfSight(targetPart)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetPart then return false end

    local origin = hrp.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char, Camera}
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel ~= targetPart.Parent then
            return false
        end
    end
    return true
end

-- Cari target di dalam radius FOV kecil
local function FindSmartTarget()
    local origin = Camera.CFrame.Position
    local best, bestScore = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p.Character) then
            local kind = ClassifyTarget(p.Character, p)
            if Config.TargetType == "All" or kind == Config.TargetType then
                local part = GetTargetPart(p.Character)
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mouseDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if mouseDist <= Config.FOVRadius then
                            local dist = (part.Position - origin).Magnitude
                            if dist <= Config.MaxDist and dist < bestScore then
                                best = { player = p, char = p.Character, kind = kind, name = p.Name, part = part }
                                bestScore = dist
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Prediksi Milidetik Pergerakan Target
local function GetPredictPos(char, part)
    if not part then return nil end
    if not Config.Prediction then return part.Position end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.AssemblyLinearVelocity then
        local distance = (Camera.CFrame.Position - part.Position).Magnitude
        local travelTime = distance / 1500 
        return part.Position + (hrp.AssemblyLinearVelocity * travelTime)
    end
    return part.Position
end

local function GetEmperorGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tof = char:FindFirstChild("Twist of Fate")
    if not tof then return nil end
    local arm = tof:FindFirstChild("Right Arm")
    if not arm then return nil end
    return arm:FindFirstChild("EmperorGun")
end

-- ==================== SINKRONISASI TEMBAKAN (HOOK FIRE SERVER) ====================
local fireRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Items"):WaitForChild("Twist of Fate"):WaitForChild("Fire")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Hanya menyinkronkan arah peluru pas saat tombol tembak asli game ditekan
    if Config.DoubleFireSync and method == "FireServer" and self == fireRemote and not isFiringSync then
        if CurrentTarget and IsAlive(CurrentTarget.char) then
            isFiringSync = true
            task.spawn(function()
                local part = GetTargetPart(CurrentTarget.char)
                if part then
                    local predictedPos = GetPredictPos(CurrentTarget.char, part)
                    local gun = GetEmperorGun()
                    local from = (gun and gun.IsA and gun:IsA("BasePart") and gun.Position) or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position) or Camera.CFrame.Position
                    local newDir = (predictedPos - from).Unit
                    
                    local customArgs = {
                        args[1], -- Tool reference
                        vector.create(newDir.X, newDir.Y, newDir.Z)
                    }
                    pcall(function()
                        fireRemote:FireServer(unpack(customArgs))
                    end)
                end
                task.wait(0.08)
                isFiringSync = false
            end)
        end
    end

    return oldNamecall(self, unpack(args))
end)

-- ==================== MAIN RENDER STEPPED LOOP ====================
RunService.RenderStepped:Connect(function()
    FOVFrame.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)

    CurrentTarget = FindSmartTarget()

    if CurrentTarget and IsAlive(CurrentTarget.char) then
        local part = GetTargetPart(CurrentTarget.char)
        if part then
            local predictedPos = GetPredictPos(CurrentTarget.char, part)
            local distToTarget = (part.Position - Camera.CFrame.Position).Magnitude

            -- 1. LASER TRACER INDEPENDEN
            if Config.LaserEnabled then
                local gun = GetEmperorGun()
                local from = (gun and gun.Position) or Camera.CFrame.Position
                LaserPart.Transparency = 0.2
                LaserPart.Color = TARGET_COLORS[CurrentTarget.kind] or THEME.White
                LaserPart.CFrame = CFrame.lookAt(from, predictedPos) * CFrame.new(0, 0, -(predictedPos - from).Magnitude / 2)
                LaserPart.Size = Vector3.new(0.09, 0.09, (predictedPos - from).Magnitude)
            else
                LaserPart.Transparency = 1
            end

            -- 2. SMART CAMERA LOCK (Dengan Cek Tembok & Jarak Aman)
            local canLock = true
            if distToTarget < Config.MinDist then canLock = false end 
            if not HasLineOfSight(part) then canLock = false end        

            if Config.CamLockEnabled and canLock then
                local targetCF = CFrame.new(Camera.CFrame.Position, predictedPos)
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.4) 
            end
        end
    else
        LaserPart.Transparency = 1
    end
end)

-- ==================== MODULAR SIMPLE UI (A2 HUB V7) ====================
local Bubble = Instance.new("ImageButton", ScreenGui)
Bubble.Size = UDim2.new(0, 50, 0, 50)
Bubble.Position = UDim2.new(0, 15, 0.25, 0)
Bubble.BackgroundColor3 = THEME.Dark
Bubble.Image = "rbxassetid://126404877070566"
Bubble.Active = true
Bubble.Draggable = true
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

local Window = Instance.new("Frame", ScreenGui)
Window.Size = UDim2.new(0, 440, 0, 380)
Window.Position = UDim2.new(0.5, -220, 0.5, -190)
Window.BackgroundColor3 = THEME.Bg
Window.Active = true
Window.Draggable = true
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 12)

Bubble.MouseButton1Click:Connect(function() Window.Visible = not Window.Visible end)

local Header = Instance.new("Frame", Window)
Header.Size = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = THEME.Dark
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "A2 HUB V7.0 — SYNCED COMBAT"
Title.TextColor3 = THEME.White
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = THEME.Red
CloseBtn.Text = "X"
CloseBtn.TextColor3 = THEME.White
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Window.Visible = false end)

local MainScroll = Instance.new("ScrollingFrame", Window)
MainScroll.Size = UDim2.new(1, -20, 1, -50)
MainScroll.Position = UDim2.new(0, 10, 0, 45)
MainScroll.BackgroundTransparency = 1
MainScroll.ScrollBarThickness = 2
MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local uiLay = Instance.new("UIListLayout", MainScroll)
uiLay.Padding = UDim.new(0, 8)

local function AddToggle(text, default, callback)
    local holder = Instance.new("Frame", MainScroll)
    holder.Size = UDim2.new(1, 0, 0, 32)
    holder.BackgroundColor3 = THEME.Dark
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", holder)
    lbl.Size = UDim2.new(1, -45, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextColor3 = THEME.White
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local dot = Instance.new("Frame", holder)
    dot.Size = UDim2.new(0, 28, 0, 14)
    dot.Position = UDim2.new(1, -36, 0.5, -7)
    dot.BackgroundColor3 = default and THEME.Green or Color3.fromRGB(60, 60, 75)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local state = default
    holder.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            state = not state
            dot.BackgroundColor3 = state and THEME.Green or Color3.fromRGB(60, 60, 75)
            callback(state)
        end
    end)
end

-- Target Category Selector
local tLabel = Instance.new("TextLabel", MainScroll)
tLabel.Size = UDim2.new(1, 0, 0, 18)
tLabel.BackgroundTransparency = 1
tLabel.Text = "Pilih Target Kategori:"
tLabel.TextColor3 = THEME.TextDim
tLabel.Font = Enum.Font.GothamMedium
tLabel.TextSize = 11
tLabel.TextXAlignment = Enum.TextXAlignment.Left

local targetContainer = Instance.new("Frame", MainScroll)
targetContainer.Size = UDim2.new(1, 0, 0, 30)
targetContainer.BackgroundTransparency = 1
local tcLayout = Instance.new("UIListLayout", targetContainer)
tcLayout.FillDirection = Enum.FillDirection.Horizontal
tcLayout.Padding = UDim.new(0, 5)

for _, tName in ipairs({"Killer", "Survivor", "Zombie"}) do
    local btn = Instance.new("TextButton", targetContainer)
    btn.Size = UDim2.new(0.32, 0, 1, 0)
    btn.BackgroundColor3 = (Config.TargetType == tName) and THEME.Accent or THEME.Dark
    btn.Text = tName
    btn.TextColor3 = THEME.White
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        Config.TargetType = tName
        for _, child in ipairs(targetContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = (child.Text == tName) and THEME.Accent or THEME.Dark
            end
        end
    end)
end

-- FOV Radius Adjuster (80 - 120)
local fovFrame = Instance.new("Frame", MainScroll)
fovFrame.Size = UDim2.new(1, 0, 0, 40)
fovFrame.BackgroundColor3 = THEME.Dark
Instance.new("UICorner", fovFrame).CornerRadius = UDim.new(0, 6)

local fovLbl = Instance.new("TextLabel", fovFrame)
fovLbl.Size = UDim2.new(1, -10, 0, 18)
fovLbl.Position = UDim2.new(0, 10, 0, 2)
fovLbl.BackgroundTransparency = 1
fovLbl.Text = "FOV Circle Size: " .. Config.FOVRadius
fovLbl.TextColor3 = THEME.White
fovLbl.Font = Enum.Font.GothamMedium
fovLbl.TextSize = 11
fovLbl.TextXAlignment = Enum.TextXAlignment.Left

local btnMinus = Instance.new("TextButton", fovFrame)
btnMinus.Size = UDim2.new(0, 40, 0, 18)
btnMinus.Position = UDim2.new(0, 10, 0, 20)
btnMinus.BackgroundColor3 = THEME.Panel
btnMinus.Text = "-"
btnMinus.TextColor3 = THEME.White
Instance.new("UICorner", btnMinus).CornerRadius = UDim.new(0, 4)

local btnPlus = Instance.new("TextButton", fovFrame)
btnPlus.Size = UDim2.new(0, 40, 0, 18)
btnPlus.Position = UDim2.new(0, 55, 0, 20)
btnPlus.BackgroundColor3 = THEME.Panel
btnPlus.Text = "+"
btnPlus.TextColor3 = THEME.White
Instance.new("UICorner", btnPlus).CornerRadius = UDim.new(0, 4)

btnMinus.MouseButton1Click:Connect(function()
    Config.FOVRadius = math.clamp(Config.FOVRadius - 10, 80, 120)
    fovLbl.Text = "FOV Circle Size: " .. Config.FOVRadius
end)

btnPlus.MouseButton1Click:Connect(function()
    Config.FOVRadius = math.clamp(Config.FOVRadius + 10, 80, 120)
    fovLbl.Text = "FOV Circle Size: " .. Config.FOVRadius
end)

-- Toggles UI
AddToggle("Laser Tracer Active", Config.LaserEnabled, function(v) Config.LaserEnabled = v end)
AddToggle("Smart Camera Lock (CamLock)", Config.CamLockEnabled, function(v) Config.CamLockEnabled = v end)
AddToggle("Millisecond Prediction", Config.Prediction, function(v) Config.Prediction = v end)
AddToggle("Synced Double Fire (Auto Fire)", Config.DoubleFireSync, function(v) Config.DoubleFireSync = v end)

print("✅ A2 HUB V7.0 Loaded Successfully with Synced Fire & Clean Logic!")
