local Workspace = game:GetService("Workspace")
local map = Workspace:WaitForChild("EgyptianFoodMap", 20)
if not map then return end
local old = map:FindFirstChild("WorldUpgrade")
if old then old:Destroy() end
local world = Instance.new("Folder")
world.Name = "WorldUpgrade"
world.Parent = map
local function part(name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material, parent: Instance?): BasePart
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Position = pos; p.Anchored = true; p.Color = color; p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent or world
	return p
end
local function cylinder(name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material, parent: Instance?): BasePart
	local p = part(name, size, pos, color, material, parent); p.Shape = Enum.PartType.Cylinder; return p
end
local function ball(name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material, parent: Instance?): BasePart
	local p = part(name, size, pos, color, material, parent); p.Shape = Enum.PartType.Ball; return p
end
local function textSign(name: string, text: string, pos: Vector3, size: Vector3)
	local board = part(name, size, pos, Color3.fromRGB(34,36,41), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Front; gui.PixelsPerStud = 45; gui.Parent = board
	local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1,1); label.BackgroundTransparency = 1; label.Text = text
	label.TextColor3 = Color3.fromRGB(255,220,125); label.Font = Enum.Font.GothamBlack; label.TextScaled = true; label.Parent = gui
end
local road = Instance.new("Folder"); road.Name = "StreetDetails"; road.Parent = world
for x = -68,124,8 do part("LaneMarker", Vector3.new(4.2,.08,.25), Vector3.new(x,.08,17), Color3.fromRGB(238,222,166), Enum.Material.Neon, road) end
for x = -52,-28,4 do part("Crosswalk", Vector3.new(2.2,.1,8), Vector3.new(x,.09,-14), Color3.fromRGB(225,225,218), Enum.Material.Concrete, road) end
local planterPositions = {Vector3.new(-53,.9,-5),Vector3.new(-18,.9,-6),Vector3.new(46,.9,-7),Vector3.new(108,.9,-5)}
for i,pos in ipairs(planterPositions) do
	local planter = Instance.new("Model"); planter.Name = "Planter_"..i; planter.Parent = world
	part("Pot",Vector3.new(2.4,1.8,2.4),pos,Color3.fromRGB(151,91,51),Enum.Material.Slate,planter)
	for j=1,4 do ball("Plant",Vector3.new(1.3,1.5,1.3),pos+Vector3.new((j-2.5)*.5,1.3,((j%2)-.5)*.45),Color3.fromRGB(52,118,66),Enum.Material.Grass,planter) end
end
for i,pos in ipairs({Vector3.new(55,1.1,12),Vector3.new(93,1.1,12)}) do
	local bench=Instance.new("Model"); bench.Name="Bench_"..i; bench.Parent=world
	part("Seat",Vector3.new(6,.5,1.5),pos,Color3.fromRGB(108,67,40),Enum.Material.Wood,bench)
	part("Back",Vector3.new(6,2,.45),pos+Vector3.new(0,1.05,.6),Color3.fromRGB(108,67,40),Enum.Material.Wood,bench)
	for _,x in ipairs({-2.2,2.2}) do cylinder("Leg",Vector3.new(.35,1.2,.35),pos+Vector3.new(x,-.55,0),Color3.fromRGB(48,50,54),Enum.Material.Metal,bench) end
end
for i,x in ipairs({-60,6,72,118}) do
	local flag=Instance.new("Model"); flag.Name="EgyptFlag_"..i; flag.Parent=world
	cylinder("Pole",Vector3.new(.18,4.5,.18),Vector3.new(x,2.25,24),Color3.fromRGB(190,190,185),Enum.Material.Metal,flag)
	local cloth=part("Flag",Vector3.new(2.4,1.3,.08),Vector3.new(x+1.15,3.55,24),Color3.fromRGB(206,43,43),Enum.Material.Fabric,flag)
	part("WhiteStripe",Vector3.new(2.4,.42,.1),cloth.Position,Color3.fromRGB(238,238,232),Enum.Material.Fabric,flag)
	part("BlackStripe",Vector3.new(2.4,.42,.1),cloth.Position+Vector3.new(0,-.43,0),Color3.fromRGB(35,35,38),Enum.Material.Fabric,flag)
end
local shop=map:FindFirstChild("IngredientShop")
if shop then
	part("ShopCanopy",Vector3.new(16,.35,4),Vector3.new(20,6.2,-31),Color3.fromRGB(205,48,40),Enum.Material.Fabric,world)
	part("ShopCanopyTrim",Vector3.new(16.2,.2,.25),Vector3.new(20,6,-32.9),Color3.fromRGB(247,207,87),Enum.Material.Metal,world)
	textSign("IngredientShopSign","INGREDIENTS • RICE • LENTILS • FUL",Vector3.new(20,7.4,-30.8),Vector3.new(15,1.8,.25))
end
textSign("RestaurantSign","KOSHERY HOUSE",Vector3.new(78,7.2,-9),Vector3.new(18,2.2,.3))
for i=1,4 do
	local lamp=part("EntranceLight_"..i,Vector3.new(.35,.35,.35),Vector3.new(68+(i-1)*7,5.5,-10.1),Color3.fromRGB(255,210,108),Enum.Material.Neon,world)
	local light=Instance.new("PointLight"); light.Range=10; light.Brightness=1.1; light.Color=Color3.fromRGB(255,210,108); light.Parent=lamp
end
print("EgyptianFood: world upgrade loaded")