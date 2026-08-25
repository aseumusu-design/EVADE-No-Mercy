local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
	Enabled = false,
	TargetPlayer = nil
}

-- Buat UI Panel Lynx
if PlayerGui:FindFirstChild("LynxDoubleFireSync") then
	PlayerGui.LynxDoubleFireSync:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LynxDoubleFireSync"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 290)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Lynx Aim (Double Fire Sync)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 12
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.13, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleBtn.Text = "Silent Aim: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = MainFrame

ToggleBtn.MouseButton1Click:Connect(function()
	Config.Enabled = not Config.Enabled
	if Config.Enabled then
		ToggleBtn.Text = "Silent Aim: ON"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
	else
		ToggleBtn.Text = "Silent Aim: OFF"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	end
end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 25)
StatusLabel.Position = UDim2.new(0.05, 0, 0.28, 0)
StatusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
StatusLabel.Text = "Target: Belum dipilih"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.Parent = MainFrame

local ScrollingList = Instance.new("ScrollingFrame")
ScrollingList.Size = UDim2.new(0.9, 0, 0, 110)
ScrollingList.Position = UDim2.new(0.05, 0, 0.40, 0)
ScrollingList.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ScrollingList.BorderSizePixel = 0
ScrollingList.CanvasSize = UDim2.new(0, 0, 2, 0)
ScrollingList.ScrollBarThickness = 5
ScrollingList.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollingList
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0.9, 0, 0, 25)
RefreshBtn.Position = UDim2.new(0.05, 0, 0.86, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RefreshBtn.Text = "Refresh Player"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.TextSize = 11
RefreshBtn.Parent = MainFrame

local function RefreshList()
	for _, child in pairs(ScrollingList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 25)
			btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			btn.Text = p.Name
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 11
			btn.Parent = ScrollingList
			btn.MouseButton1Click:Connect(function()
				Config.TargetPlayer = p
				StatusLabel.Text = "Target: " .. p.Name
			end)
		end
	end
end

RefreshBtn.MouseButton1Click:Connect(RefreshList)
RefreshList()

-- Mendapatkan posisi kepala target
local function getTargetHeadPosition()
	if Config.TargetPlayer and Config.TargetPlayer.Character then
		local targetChar = Config.TargetPlayer.Character
		local head = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
		local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
		if head and humanoid and humanoid.Health > 0 then
			return head.Position
		end
	end
	return nil
end

-- Variabel pencegah spam tak terbatas (anti crash)
local isFiring = false

-- Memantau remote Fire bawaan game secara langsung (Event Listener)
local fireRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Items"):WaitForChild("Twist of Fate"):WaitForChild("Fire")

fireRemote.OnClientEvent:Connect(function()
	-- Cadangan jika game pakai ClientEvent
end)

-- Kita gunakan teknik hook ringan khusus untuk menangkap saat remote Fire dipanggil oleh tombol asli game
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
	local method = getnamecallmethod()
	local args = {...}

	-- Jika game memanggil FireServer untuk senjata Twist of Fate dan fitur aktif
	if Config.Enabled and method == "FireServer" and self == fireRemote and not isFiring then
		isFiring = true
		
		-- Jalankan tembakan kedua versi kita secara bersamaan ke kepala target
		task.spawn(function()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("Head") then
				local tool = char:FindFirstChild("Twist of Fate")
				local targetPos = getTargetHeadPosition()
				
				if tool and targetPos then
					local newDir = (targetPos - char.Head.Position).Unit
					local customArgs = {
						tool,
						vector.create(newDir.X, newDir.Y, newDir.Z)
					}
					
					pcall(function()
						fireRemote:FireServer(unpack(customArgs))
					end)
				end
			end
			task.wait(0.1) -- Jeda mikro agar tidak infinite loop/crash
			isFiring = false
		end)
	end

	return oldNamecall(self, unpack(args))
end)
