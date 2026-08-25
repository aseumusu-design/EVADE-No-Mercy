--[[
=========================================================================
    A2 HUB - SIMPLE AIMBOT EDITION (UI LIBRARY SIMPEL)
    - Bersih, ringan, tidak bikin kaku / tangan kosong
    - Auto Aim / Camera Lock mulus saat target masuk FOV
=========================================================================
]]

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

local Config = {
    AimbotEnabled = true,
    TargetType    = "Killer", -- Killer, Survivor, Zombie, All
    AimPart       = "Head",   -- Head atau HumanoidRootPart
    FOVRadius     = 100,      -- Ukuran lingkaran FOV
    Smoothness    = 0.2,      -- Kehalusan Aimbot (Semakin kecil semakin halus)
}

local CurrentTarget = nil

-- ==================== FOV CIRCLE VISUAL ====================
local guiParent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
pcall(function() if guiParent:FindFirstChild("A2SimpleAim") then guiParent.A2SimpleAim:Destroy() end end)

local ScreenGui = Instance.new("ScreenGui", guiParent)
ScreenGui.Name = "A2SimpleAim"
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
UIStrokeFOV.Transparency = 0.4

-- ==================== UTILS ====================
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

local function FindClosestTarget()
    local best, bestDist = nil, math.huge
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
                        if mouseDist <= Config.FOVRadius and mouseDist < bestDist then
                            best = part
                            bestDist = mouseDist
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ==================== MAIN AIMBOT LOOP ====================
RunService.RenderStepped:Connect(function()
    FOVFrame.Size = UDim2.new(0, Config.FOVRadius * 2, 0, Config.FOVRadius * 2)

    if Config.AimbotEnabled then
        CurrentTarget = FindClosestTarget()
        if CurrentTarget then
            local targetCF = CFrame.new(Camera.CFrame.Position, CurrentTarget.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, Config.Smoothness)
        end
    end
end)

-- ==================== SIMPLE UI (SIMPEL & ELEGAN) ====================
local Window = Instance.new("Frame", ScreenGui)
Window.Size = UDim2.new(0, 220, 0, 150)
Window.Position = UDim2.new(0.05, 0, 0.3, 0)
Window.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Window.Active = true
Window.Draggable = true
Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Window)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Title.Text = " A2 SIMPLE AIMBOT"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local ToggleBtn = Instance.new("TextButton", Window)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.3, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "Aimbot: ON"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function()
    Config.AimbotEnabled = not Config.AimbotEnabled
    ToggleBtn.Text = Config.AimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
    ToggleBtn.BackgroundColor3 = Config.AimbotEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
end)

local HideBtn = Instance.new("TextButton", Window)
HideBtn.Size = UDim2.new(0.9, 0, 0, 30)
HideBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
HideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
HideBtn.Text = "Minimize / Close UI"
HideBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
HideBtn.Font = Enum.Font.GothamMedium
HideBtn.TextSize = 10
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 6)

HideBtn.MouseButton1Click:Connect(function()
    Window.Visible = false
    -- Munculkan kembali tombol kecil transparan di layar jika ingin dibuka lagi
    local openBtn = Instance.new("TextButton", ScreenGui)
    openBtn.Size = UDim2.new(0, 40, 0, 40)
    openBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
    openBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    openBtn.Text = "A2"
    openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    openBtn.Font = Enum.Font.GothamBold
    openBtn.Active = true
    openBtn.Draggable = true
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
    openBtn.MouseButton1Click:Connect(function()
        Window.Visible = true
        openBtn:Destroy()
    end)
end)

print("✅ A2 Simple Aimbot Loaded Successfully!")
