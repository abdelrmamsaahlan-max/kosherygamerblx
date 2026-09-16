local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("EgyptianFoodMap", 15)
if not map then
	return
end

local old = map:FindFirstChild("Decor")
if old then
	old:Destroy()
end

local decor = Instance.new("Folder")
decor.Name = "Decor"
decor.Parent = map

local function part(name: string, size: Vector3, position: Vector3, material: Enum.Material, color: Color3, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.CanCollide = true
	p.Material = material
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function cylinder(name: string, size: Vector3, position: Vector3, material: Enum.Material, color: Color3, parent: Instance): BasePart
	local p = part(name, size, position, material, color, parent)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ball(name: string, size: Vector3, position: Vector3, material: Enum.Material, color: Color3, parent: Instance): BasePart
	local p = part(name, size, position, material, color, parent)
	p.Shape = Enum.PartType.Ball
	return p
end

local function sign(text: string, position: Vector3, size: Vector2, parent: Instance)
	local board = part("Sign", Vector3.new(size.X, 0.5, size.Y), position, Enum.Material.SmoothPlastic, Color3.fromRGB(28, 32, 38), parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 220, 120)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end

-- Decorative Egyptian street buildings.
local buildings = {
	{Vector3.new(-58, 5, -12), Vector3.new(22, 10, 18), Color3.fromRGB(216, 185, 137), "CAIRO CAFE"},
	{Vector3.new(-8, 5, -48), Vector3.new(24, 10, 16), Color3.fromRGB(194, 164, 119), "BAKERY"},
	{Vector3.new(53, 5, -48), Vector3.new(26, 10, 18), Color3.fromRGB(226, 201, 157), "MARKET"},
	{Vector3.new(115, 5, -10), Vector3.new(24, 10, 18), Color3.fromRGB(204, 174, 128), "TEA HOUSE"},
}

for _, info in ipairs(buildings) do
	local pos = info[1] :: Vector3
	local size = info[2] :: Vector3
	local color = info[3] :: Color3
	local name = info[4] :: string
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = decor
	part("Building", size, pos, Enum.Material.Concrete, color, model)
	part("Roof", Vector3.new(size.X + 1, 1, size.Z + 1), pos + Vector3.new(0, size.Y / 2 + 0.5, 0), Enum.Material.Slate, Color3.fromRGB(91, 77, 67), model)
	part("Door", Vector3.new(3.5, 5, 0.4), pos + Vector3.new(0, -2.5, size.Z / 2 + 0.25), Enum.Material.Wood, Color3.fromRGB(90, 54, 32), model)
	for x = -size.X / 2 + 4, size.X / 2 - 3, 6 do
		part("Window", Vector3.new(3, 3, 0.35), pos + Vector3.new(x, 1, size.Z / 2 + 0.25), Enum.Material.Glass, Color3.fromRGB(105, 180, 210), model)
	end
	sign(name, pos + Vector3.new(0, 4.5, size.Z / 2 + 0.5), Vector2.new(math.min(size.X - 3, 16), 2.4), model)
end

-- Palm trees.
local treePositions = {
	Vector3.new(-70, 0, 31), Vector3.new(-52, 0, -1), Vector3.new(-24, 0, 34),
	Vector3.new(8, 0, -8), Vector3.new(39, 0, 34), Vector3.new(67, 0, -5),
	Vector3.new(101, 0, 31), Vector3.new(123, 0, 2),
}

for i, pos in ipairs(treePositions) do
	local tree = Instance.new("Model")
	tree.Name = "PalmTree_" .. i
	tree.Parent = decor
	cylinder("Trunk", Vector3.new(1.7, 8, 1.7), pos + Vector3.new(0, 4, 0), Enum.Material.Wood, Color3.fromRGB(121, 78, 43), tree)
	local top = pos + Vector3.new(0, 8.2, 0)
	ball("Leaves", Vector3.new(6, 2.5, 6), top, Enum.Material.Grass, Color3.fromRGB(55, 126, 70), tree)
	for angle = 0, 300, 60 do
		local r = math.rad(angle)
		part("PalmLeaf", Vector3.new(0.6, 0.35, 5.5), top + Vector3.new(math.sin(r) * 2.2, 0.2, math.cos(r) * 2.2), Enum.Material.Grass, Color3.fromRGB(65, 145, 75), tree).CFrame = CFrame.new(top + Vector3.new(math.sin(r) * 2.2, 0.2, math.cos(r) * 2.2)) * CFrame.Angles(0, r, math.rad(-18))
	end
end

-- Restaurant patio furniture.
local patio = Instance.new("Folder")
patio.Name = "RestaurantPatio"
patio.Parent = decor

for row = 0, 1 do
	for col = 0, 2 do
		local x = 66 + col * 10
		local z = -30 + row * 10
		local table = Instance.new("Model")
		table.Name = "Table"
		table.Parent = patio
		part("Top", Vector3.new(5, 0.6, 5), Vector3.new(x, 2.8, z), Enum.Material.Wood, Color3.fromRGB(124, 76, 43), table)
		cylinder("Leg", Vector3.new(0.7, 2.8, 0.7), Vector3.new(x, 1.4, z), Enum.Material.Metal, Color3.fromRGB(65, 65, 65), table)
		for _, offset in ipairs({Vector3.new(0, 1.3, 4), Vector3.new(0, 1.3, -4)}) do
			part("Chair", Vector3.new(3, 0.5, 2.5), Vector3.new(x, 1.1, z) + offset, Enum.Material.Wood, Color3.fromRGB(91, 57, 38), table)
		end
	end
end

-- Restaurant kitchen props: stove, sink, prep counters.
local kitchen = Instance.new("Model")
kitchen.Name = "RestaurantKitchen"
kitchen.Parent = decor
part("KitchenBack", Vector3.new(30, 7, 1), Vector3.new(78, 4, -3), Enum.Material.Concrete, Color3.fromRGB(70, 73, 78), kitchen)
for i = 0, 3 do
	local x = 65 + i * 9
	part("Counter", Vector3.new(7.5, 2, 3.5), Vector3.new(x, 1.5, 0), Enum.Material.Metal, Color3.fromRGB(145, 148, 151), kitchen)
end
for i = 0, 1 do
	local stove = part("Stove", Vector3.new(6, 0.5, 3), Vector3.new(69 + i * 12, 2.8, -2), Enum.Material.Metal, Color3.fromRGB(42, 45, 49), kitchen)
	for burner = -1, 1, 2 do
		cylinder("Burner", Vector3.new(1, 0.12, 1), stove.Position + Vector3.new(burner * 1.5, 0.32, 0), Enum.Material.Neon, Color3.fromRGB(255, 111, 45), kitchen)
	end
end
part("Sink", Vector3.new(5, 1, 3), Vector3.new(96, 2.2, 0), Enum.Material.Metal, Color3.fromRGB(170, 175, 180), kitchen)

-- Decorative food crates near ingredient shop.
local crates = Instance.new("Folder")
crates.Name = "FoodCrates"
crates.Parent = decor
for i, pos in ipairs({Vector3.new(12, 1, -36), Vector3.new(15, 1, -36), Vector3.new(18, 1, -36), Vector3.new(15, 3, -36)}) do
	part("Crate_" .. i, Vector3.new(2.5, 2, 2.5), pos, Enum.Material.Wood, Color3.fromRGB(151, 95, 48), crates)
end

-- Street lamps with soft light.
local lampPositions = {-63, -38, -12, 15, 42, 69, 96, 120}
for i, x in ipairs(lampPositions) do
	local lamp = Instance.new("Model")
	lamp.Name = "StreetLamp_" .. i
	lamp.Parent = decor
	cylinder("Pole", Vector3.new(0.55, 7, 0.55), Vector3.new(x, 3.5, 28), Enum.Material.Metal, Color3.fromRGB(42, 44, 49), lamp)
	part("LampHead", Vector3.new(2, 0.5, 2), Vector3.new(x, 7.2, 28), Enum.Material.Metal, Color3.fromRGB(55, 57, 61), lamp)
	local lightPart = part("Glow", Vector3.new(1.2, 0.3, 1.2), Vector3.new(x, 6.9, 28), Enum.Material.Neon, Color3.fromRGB(255, 214, 132), lamp)
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 221, 160)
	light.Parent = lightPart
end

-- Direction signs connecting the main gameplay areas.
sign("FOOD TRUCK  →", Vector3.new(-35, 4, -12), Vector2.new(12, 2), decor)
sign("INGREDIENT SHOP  →", Vector3.new(20, 4, -12), Vector2.new(16, 2), decor)
sign("←  RESTAURANT", Vector3.new(78, 4, -12), Vector2.new(16, 2), decor)

print("EgyptianFood: polished 3D map decor loaded")