local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("EgyptianFoodMap", 30)
if not map then return end

Lighting.ClockTime = 17.35
Lighting.Brightness = 2.2
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.42
Lighting.EnvironmentSpecularScale = 0.55
Lighting.OutdoorAmbient = Color3.fromRGB(118, 108, 96)
Lighting.Ambient = Color3.fromRGB(78, 78, 84)

local atmosphere = Lighting:FindFirstChild("EgyptianFoodAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "EgyptianFoodAtmosphere"
atmosphere.Density = 0.18
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(214, 207, 193)
atmosphere.Decay = Color3.fromRGB(105, 91, 80)
atmosphere.Glare = 0.12
atmosphere.Haze = 0.55
atmosphere.Parent = Lighting

local bloom = Lighting:FindFirstChild("EgyptianFoodBloom") or Instance.new("BloomEffect")
bloom.Name = "EgyptianFoodBloom"
bloom.Intensity = 0.16
bloom.Size = 18
bloom.Threshold = 1.2
bloom.Parent = Lighting

local color = Lighting:FindFirstChild("EgyptianFoodColor") or Instance.new("ColorCorrectionEffect")
color.Name = "EgyptianFoodColor"
color.Brightness = 0.03
color.Contrast = 0.08
color.Saturation = 0.04
color.TintColor = Color3.fromRGB(255, 247, 231)
color.Parent = Lighting

local polish = map:FindFirstChild("WorldPolish") or Instance.new("Folder")
polish.Name = "WorldPolish"
polish.Parent = map

local function makePart(name, size, position, color3, material, parent, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = material
	part.Color = color3
	part.Transparency = transparency or 0
	part.Parent = parent
	return part
end

if not polish:FindFirstChild("FoodTruckGlow") then
	local glow = makePart("FoodTruckGlow", Vector3.new(18, 0.15, 7), Vector3.new(-35, 0.12, -27), Color3.fromRGB(255, 180, 86), Enum.Material.Neon, polish, 0.72)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 177, 94)
	light.Brightness = 1.25
	light.Range = 18
	light.Shadows = true
	light.Parent = glow
end

local function addLamp(position, height)
	local pole = makePart("StreetLampPole", Vector3.new(0.28, height, 0.28), position + Vector3.new(0, height / 2, 0), Color3.fromRGB(44, 45, 49), Enum.Material.Metal, polish)
	local cap = makePart("StreetLampCap", Vector3.new(0.9, 0.18, 0.9), pole.Position + Vector3.new(0, height / 2, 0), Color3.fromRGB(255, 201, 113), Enum.Material.Neon, polish)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 192, 104)
	light.Brightness = 1.05
	light.Range = 15
	light.Shadows = true
	light.Parent = cap
end

if not polish:FindFirstChild("LampMarker") then
	local marker = makePart("LampMarker", Vector3.new(0.1, 0.1, 0.1), Vector3.new(0, -100, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, polish, 1)
	addLamp(Vector3.new(-18, 0.15, -5), 7)
	addLamp(Vector3.new(8, 0.15, -5), 7)
	addLamp(Vector3.new(31, 0.15, -15), 7)
	addLamp(Vector3.new(56, 0.15, -7), 7)
	addLamp(Vector3.new(-4, 0.15, -42), 7)
end

local function addSign(name, position, text)
	if polish:FindFirstChild(name) then return end
	local board = makePart(name, Vector3.new(5.4, 2.1, 0.22), position, Color3.fromRGB(47, 38, 34), Enum.Material.Wood, polish)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 45
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 224, 147)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
end

addSign("CairoStreetSign", Vector3.new(-9, 4.8, -5), "CAIRO STREET")
addSign("KosheryDirectionSign", Vector3.new(13, 4.8, -5), "KOSHERY HOUSE  →")
addSign("TruckDirectionSign", Vector3.new(-18, 4.8, -27), "FOOD TRUCK  →")

if not polish:FindFirstChild("TruckBanner") then
	local banner = makePart("TruckBanner", Vector3.new(12, 0.28, 0.18), Vector3.new(-35, 6.3, -33.25), Color3.fromRGB(241, 194, 69), Enum.Material.Metal, polish)
	for i = 1, 6 do
		local stripe = makePart("BannerStripe", Vector3.new(1.65, 0.12, 0.12), banner.Position + Vector3.new(-5.1 + (i - 1) * 2.05, -0.22, 0), i % 2 == 0 and Color3.fromRGB(119, 27, 26) or Color3.fromRGB(244, 231, 194), Enum.Material.SmoothPlastic, polish)
		stripe.Orientation = Vector3.new(0, 0, 8)
	end
end

print("EgyptianFood WorldPolish: lighting, ambience, street lamps and signage ready")
