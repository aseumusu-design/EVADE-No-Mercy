--[[
=========================================================================
    A2 HUB V4.0 - ULTIMATE SURVIVAL AIMBOT & VISUAL
    - 100% Working Glowing Laser Tracer & FOV Circle
    - Universal Range & Millisecond Prediction (Akurat Jauh/Dekat)
    - Aim Part Selector: Head (Kepala) / Body (Badan)
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

-- ==================== STATE CONFIG ====================
local Config = {
    AimbotEnabled = true,
    AimVersion    = "V2",          -- V2 (Smooth Cam Lock)
    TargetType    = "Killer",      -- Killer, Survivor, Zombie
    SpecificName  = "",
    AimPart       = "Head",        -- "Head" (Kepala) atau "Body" (Badan)
    MaxDistance   = 9999,          -- Jangkauan luas bebas dekat/jauh
    Prediction    = true,
    AutoShoot     = true,
    FireDelay     = 0.05,
    
    LaserEnabled  = true,
    FOVCircleOn   = true,
    FOVRadius     = 250,
}

local CurrentTarget = nil
local LastFireTime = 0

-- ==================== VISUAL: LASER TRACER (100% MUNCUL) ====================
local LaserPart = Instance.new("Part")
LaserPart.Name = "A2_LaserTracer"
LaserPart.Anchored = true
LaserPart.CanCollide = false
LaserPart.CanQuery = false
LaserPart.CanTouch = false
LaserPart.Material = Enum.Material.Neon
LaserPart.Size = Vector3.new(0.12, 0.12, 1)
LaserPart.Transparency = 1
LaserPart.Parent = Workspace

-- ==================== VISUAL: SCREEN FOV CIRCLE ====================
local guiParent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
pcall(function() if guiParent:FindFirstChild("A2HubV4") then guiParent.A2HubV4:Destroy() end end)

local ScreenGui = Instance.new("ScreenGui", guiParent)
ScreenGui.Name = "A2HubV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local FOVFrame = Instance.new("Frame", ScreenGui)
FOVFrame.Name = "FOVCircle"
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = Config.FOVCircleOn

local UICornerFOV = Instance.new("UICorner", FOVFrame)
UICornerFOV.CornerRadius = UDim.new(1, 0)

local UIStrokeFOV = Instance.new("UIStroke", FOVFrame)
UIStrokeFOV.Color = Color3.fromRGB(255, 255, 255)
UIStrokeFOV.Thickness = 1.8
UIStrokeFOV.Transparency = 0.2

-- ==================== UTILS TARGET & COMBAT ====================
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

local function MatchesFilter(p, char, kind)
    if Config.TargetType == "All" then return true end
    if Config.TargetType == "Survivor" and Config.SpecificName ~= "" then
        return p.Name:lower() == Config.SpecificName:lower()
    end
    return kind == Config.TargetType
end

local function GetTargetPart(char)
    if Config.AimPart == "Head" then
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    end
end

local function FindBestTarget()
    local origin = Camera.CFrame.Position
    local best, bestScore = nil, math.huge
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p.Character) then
            local kind = ClassifyTarget(p.Character, p)
            if MatchesFilter(p, p.Character, kind) then
                local part = GetTargetPart(p.Character)
                if part then
                    local dist = (part.Position - origin).Magnitude
                    if dist <= Config.MaxDistance and dist < bestScore then
                        best = { player = p, char = p.Character, kind = kind, name = p.Name }
                        bestScore = dist
                    end
                end
            end
        end
    end
    return best
end

local function GetPredictPos(char)
    local part = GetTargetPart(char)
    if not part then return nil end
    if not Config.Prediction then return part.Position end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.AssemblyLinearVelocity then
        local distance = (Camera.CFrame.Position - part.Position).Magnitude
        local travelTime = distance / 1200 -- Kalkulasi presisi waktu tempuh peluru per milidetik
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

local function FireWeapon(targetPos)
    local now = tick()
    if now - LastFireTime < Config.FireDelay then return end
    LastFireTime = now

    local gun = GetEmperorGun()
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    remote = remote and remote:FindFirstChild("Items")
    remote = remote and remote:FindFirstChild("Twist of Fate")
    remote = remote and remote:FindFirstChild("Fire")

    if gun and remote then
        local from = gun:IsA("BasePart") and gun.Position or Camera.CFrame.Position
        local dir = (targetPos - from).Unit
        pcall(function() remote:FireServer(gun, Vector3.new(dir.X, dir.Y, dir.Z)) end)
    end
end

-- ==================== MAIN AIMBOT & LASER LOOP ====================
RunService.RenderStepped:Connect(function()
    FOVFrame.Visible = Config.FOVCircleOn
    FOVFrame.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)

    if not Config.AimbotEnabled then
        LaserPart.Transparency = 1
        return
    end

    if not (CurrentTarget and IsAlive(CurrentTarget.char) and MatchesFilter(CurrentTarget.player, CurrentTarget.char, CurrentTarget.kind)) then
        CurrentTarget = FindBestTarget()
    end

    if CurrentTarget then
        local pos = GetPredictPos(CurrentTarget.char)
        if pos then
            -- Render Laser Terang Langsung dari Posisi Senjata ke Target
            if Config.LaserEnabled then
                local gun = GetEmperorGun()
                local from = (gun and gun.Position) or Camera.CFrame.Position
                
                LaserPart.Transparency = 0.2
                LaserPart.Color = TARGET_COLORS[CurrentTarget.kind] or THEME.White
                LaserPart.CFrame = CFrame.lookAt(from, pos) * CFrame.new(0, 0, -(pos - from).Magnitude / 2)
                LaserPart.Size = Vector3.new(0.1, 0.1, (pos - from).Magnitude)
            else
                LaserPart.Transparency = 1
            end

            -- Smooth Camera Lock V2
            if Config.AimVersion == "V2" then
                local targetCF = CFrame.new(Camera.CFrame.Position, pos)
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.5)
            end

            if Config.AutoShoot then
                FireWeapon(pos)
            end
        end
    else
        LaserPart.Transparency = 1
    end
end)

-- ==================== MODULAR UI INTERFACE (A2 HUB) ====================
local Bubble = Instance.new("ImageButton", ScreenGui)
Bubble.Size = UDim2.new(0, 55, 0, 55)
Bubble.Position = UDim2.new(0, 15, 0.25, 0)
Bubble.BackgroundColor3 = THEME.Dark
Bubble.Image = "rbxassetid://126404877070566"
Bubble.Active = true
Bubble.Draggable = true
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

local Window = Instance.new("Frame", ScreenGui)
Window.Size = UDim2.new(0, 500, 0, 400)
Window.Position = UDim2.new(0.5, -250, 0.5, -200)
Window.BackgroundColor3 = THEME.Bg
Window.Active = true
Window.Draggable = true
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 12)

Bubble.MouseButton1Click:Connect(function() Window.Visible = not Window.Visible end)

local Header = Instance.new("Frame", Window)
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = THEME.Dark
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "A2 HUB — SURVIVAL EXCLUSIVE"
Title.TextColor3 = THEME.White
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = THEME.Red
CloseBtn.Text = "X"
CloseBtn.TextColor3 = THEME.White
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Window.Visible = false end)

local Sidebar = Instance.new("ScrollingFrame", Window)
Sidebar.Size = UDim2.new(0, 130, 1, -50)
Sidebar.Position = UDim2.new(0, 10, 0, 45)
Sidebar.BackgroundTransparency = 1
Sidebar.ScrollBarThickness = 2
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
local sideLayout = Instance.new("UIListLayout", Sidebar)
sideLayout.Padding = UDim.new(0, 5)

local Container = Instance.new("Frame", Window)
Container.Size = UDim2.new(1, -150, 1, -50)
Container.Position = UDim2.new(0, 145, 0, 45)
Container.BackgroundColor3 = THEME.Panel
Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 8)

local Tabs = {}
local function CreateTab(name)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size = UDim2.new(1, 0, 0, 32)
    TabBtn.BackgroundColor3 = THEME.Dark
    TabBtn.Text = "  " .. name
    TabBtn.TextColor3 = THEME.TextDim
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize, TabBtn.TextXAlignment = 11, Enum.TextXAlignment.Left
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

    local Page = Instance.new("ScrollingFrame", Container)
    Page.Size = UDim2.new(1, -10, 1, -10)
    Page.Position = UDim2.new(0, 5, 0, 5)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 3
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    
    local pageLayout = Instance.new("UIListLayout", Page)
    pageLayout.Padding = UDim.new(0, 8)

    Tabs[name] = { Btn = TabBtn, Page = Page }
    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.Page.Visible = false t.Btn.TextColor3 = THEME.TextDim end
        Page.Visible = true
        TabBtn.TextColor3 = THEME.White
    end)
    return Page
end

local AimTab = CreateTab("Aimbot Setup")
local VisualTab = CreateTab("Visuals & Laser")

Tabs["Aimbot Setup"].Page.Visible = true
Tabs["Aimbot Setup"].Btn.TextColor3 = THEME.White

local function AddToggle(parent, text, default, callback)
    local holder = Instance.new("Frame", parent)
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

-- ==================== AIMBOT TAB CONTENT ====================
AddToggle(AimTab, "Enable Aim Lock", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
AddToggle(AimTab, "Auto Shoot Target", Config.AutoShoot, function(v) Config.AutoShoot = v end)

-- Aim Part Selector (Head / Body)
local partFrame = Instance.new("Frame", AimTab)
partFrame.Size = UDim2.new(1, 0, 0, 50)
partFrame.BackgroundColor3 = THEME.Dark
Instance.new("UICorner", partFrame).CornerRadius = UDim.new(0, 6)

local partLbl = Instance.new("TextLabel", partFrame)
partLbl.Size = UDim2.new(1, -10, 0, 16)
partLbl.Position = UDim2.new(0, 8, 0, 2)
partLbl.BackgroundTransparency = 1
partLbl.Text = "Bagian Target (Head / Body):"
partLbl.TextColor3 = THEME.TextDim
partLbl.Font = Enum.Font.GothamMedium
partLbl.TextSize = 10
partLbl.TextXAlignment = Enum.TextXAlignment.Left

local btnHead = Instance.new("TextButton", partFrame)
btnHead.Size = UDim2.new(0.48, 0, 0, 24)
btnHead.Position = UDim2.new(0, 5, 0, 22)
btnHead.BackgroundColor3 = THEME.Green
btnHead.Text = "Head (Kepala)"
btnHead.TextColor3 = THEME.White
btnHead.Font = Enum.Font.GothamBold
btnHead.TextSize = 10
Instance.new("UICorner", btnHead).CornerRadius = UDim.new(0, 4)

local btnBody = Instance.new("TextButton", partFrame)
btnBody.Size = UDim2.new(0.48, 0, 0, 24)
btnBody.Position = UDim2.new(0.52, -2, 0, 22)
btnBody.BackgroundColor3 = THEME.Panel
btnBody.Text = "Body (Badan)"
btnBody.TextColor3 = THEME.TextDim
btnBody.Font = Enum.Font.GothamBold
btnBody.TextSize = 10
Instance.new("UICorner", btnBody).CornerRadius = UDim.new(0, 4)

btnHead.MouseButton1Click:Connect(function()
    Config.AimPart = "Head"
    btnHead.BackgroundColor3 = THEME.Green
    btnHead.TextColor3 = THEME.White
    btnBody.BackgroundColor3 = THEME.Panel
    btnBody.TextColor3 = THEME.TextDim
end)

btnBody.MouseButton1Click:Connect(function()
    Config.AimPart = "Body"
    btnBody.BackgroundColor3 = THEME.Green
    btnBody.TextColor3 = THEME.White
    btnHead.BackgroundColor3 = THEME.Panel
    btnHead.TextColor3 = THEME.TextDim
end)

local targetTypeLbl = Instance.new("TextLabel", AimTab)
targetTypeLbl.Size = UDim2.new(1, 0, 0, 18)
targetTypeLbl.BackgroundTransparency = 1
targetTypeLbl.Text = "Pilih Target Kategori:"
targetTypeLbl.TextColor3 = THEME.TextDim
targetTypeLbl.Font = Enum.Font.GothamMedium
targetTypeLbl.TextSize = 10
targetTypeLbl.TextXAlignment = Enum.TextXAlignment.Left

local typesContainer = Instance.new("Frame", AimTab)
typesContainer.Size = UDim2.new(1, 0, 0, 28)
typesContainer.BackgroundTransparency = 1
local tcLayout = Instance.new("UIListLayout", typesContainer)
tcLayout.FillDirection = Enum.FillDirection.Horizontal
tcLayout.Padding = UDim.new(0, 5)

local survivorDropdown = Instance.new("ScrollingFrame", AimTab)
survivorDropdown.Size = UDim2.new(1, 0, 0, 90)
survivorDropdown.BackgroundColor3 = THEME.Dark
survivorDropdown.ScrollBarThickness = 3
survivorDropdown.AutomaticCanvasSize = Enum.AutomaticSize.Y
survivorDropdown.Visible = false
Instance.new("UICorner", survivorDropdown).CornerRadius = UDim.new(0, 6)
local sdl = Instance.new("UIListLayout", survivorDropdown)
sdl.Padding = UDim.new(0, 3)

local function RefreshSurvivors()
    for _, c in ipairs(survivorDropdown:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local sBtn = Instance.new("TextButton", survivorDropdown)
            sBtn.Size = UDim2.new(1, -4, 0, 24)
            sBtn.BackgroundColor3 = THEME.Panel
            sBtn.Text = "  " .. p.Name
            sBtn.TextColor3 = THEME.White
            sBtn.TextSize = 10
            sBtn.Font = Enum.Font.Gotham
            sBtn.TextXAlignment = Enum.TextXAlignment.Left
            Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 4)
            sBtn.MouseButton1Click:Connect(function()
                Config.SpecificName = p.Name
                CurrentTarget = nil
                survivorDropdown.Visible = false
            end)
        end
    end
end

for _, tName in ipairs({"Killer", "Survivor", "Zombie"}) do
    local tBtn = Instance.new("TextButton", typesContainer)
    tBtn.Size = UDim2.new(0.32, 0, 1, 0)
    tBtn.BackgroundColor3 = (Config.TargetType == tName) and THEME.Accent or THEME.Dark
    tBtn.Text = tName
    tBtn.TextColor3 = THEME.White
    tBtn.Font = Enum.Font.GothamBold
    tBtn.TextSize = 10
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
    
    tBtn.MouseButton1Click:Connect(function()
        Config.TargetType = tName
        CurrentTarget = nil
        survivorDropdown.Visible = (tName == "Survivor")
        if tName == "Survivor" then RefreshSurvivors() end
        for _, child in ipairs(typesContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = (child.Text == tName) and THEME.Accent or THEME.Dark
            end
        end
    end)
end

-- ==================== VISUAL TAB CONTENT ====================
AddToggle(VisualTab, "Laser Tracer ON/OFF", Config.LaserEnabled, function(v) Config.LaserEnabled = v end)
AddToggle(VisualTab, "FOV Circle ON/OFF", Config.FOVCircleOn, function(v) Config.FOVCircleOn = v end)

print("✅ A2 HUB V4.0 Loaded Successfully with Guaranteed Laser & Smooth Aim!")
