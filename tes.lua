local part = script.Parent

-- Membuat Attachment untuk ujung awal dan ujung akhir laser
local attachment0 = Instance.new("Attachment")
attachment0.Name = "LaserAttachment0"
attachment0.Parent = part
attachment0.Position = Vector3.new(0, 0, 0) -- Posisi pangkal laser di part

local attachment1 = Instance.new("Attachment")
attachment1.Name = "LaserAttachment1"
attachment1.Parent = part
attachment1.Position = Vector3.new(0, 0, -50) -- Panjang laser (ke depan sejauh 50 stud)

-- Membuat Beam untuk visual laser
local beam = Instance.new("Beam")
beam.Name = "LaserBeam"
beam.Attachment0 = attachment0
beam.Attachment1 = attachment1

-- Styling Warna & Tampilan Laser
beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0)) -- Warna Merah
beam.Width0 = 0.2 -- Lebar pangkal
beam.Width1 = 0.2 -- Lebar ujung
beam.FaceCamera = membuat_aktif or true
beam.LightEmission = 1 -- Membuat laser tampak bercahaya
beam.Parent = part

-- Variabel Status Laser (ON/OFF)
local isLaserOn = true

-- Fungsi untuk Menghidupkan atau Mematikan Laser
function toggleLaser(status)
	isLaserOn = status
	beam.Enabled = isLaserOn
	print("Laser status: " .. tostring(isLaserOn))
end

-- Contoh Penggunaan (Loop otomatis ON/OFF setiap 3 detik untuk testing)
task.spawn(function()
	while true do
		task.wait(3)
		toggleLaser(false) -- Matikan laser
		task.wait(3)
		toggleLaser(true)  -- Hidupkan lagi laser
	end
end)
