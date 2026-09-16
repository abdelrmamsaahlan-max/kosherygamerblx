local Workspace = game:GetService("Workspace")

local root = Workspace:FindFirstChild("EgyptianFoodMap")
if root then root:Destroy() end

root = Instance.new("Folder")
root.Name = "EgyptianFoodMap"
root.Parent = Workspace

local function part(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, parent: Instance?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Material = material or Enum.Material.SmoothPlastic
	p.Color = color
	p.Parent = parent or root
	return p
end

local function sign(name: string, text: string, position: Vector3, width: number, color: Color3)
	local board = part(name, Vector3.new(width, 2.8, 0.35), position, color, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
	return board
end

-- Main streets and sidewalks
part("MainRoad", Vector3.new(170, 0.4, 38), Vector3.new(25, 0, 12), Color3.fromRGB(48, 48, 52), Enum.Material.Asphalt)
part("SidewalkLeft", Vector3.new(170, 0.5, 12), Vector3.new(25, 0.35, -13), Color3.fromRGB(155, 150, 140), Enum.Material.Concrete)
part("SidewalkRight", Vector3.new(170, 0.5, 12), Vector3.new(25, 0.35, 37), Color3.fromRGB(155, 150, 140), Enum.Material.Concrete)

for x = -55, 105, 16 do
	part("RoadMarking", Vector3.new(9, 0.08, 0.7), Vector3.new(x, 0.25, 12), Color3.fromRGB(235, 205, 75), Enum.Material.Neon)
end

-- Food truck zone
part("TruckPad", Vector3.new(34, 0.6, 24), Vector3.new(-35, 0.5, -27), Color3.fromRGB(115, 108, 95), Enum.Material.Concrete)
sign("TruckSign", "FOOD TRUCK", Vector3.new(-35, 7, -28), 15, Color3.fromRGB(30, 115, 190))

local truck = Instance.new("Model")
truck.Name = "FoodTruck"
truck.Parent = root
local truckBody = part("TruckBody", Vector3.new(18, 5, 8), Vector3.new(-35, 3.2, -27), Color3.fromRGB(235, 185, 70), Enum.Material.SmoothPlastic, truck)
part("TruckCab", Vector3.new(7, 4.5, 7.5), Vector3.new(-28, 3.0, -27), Color3.fromRGB(245, 220, 120), Enum.Material.SmoothPlastic, truck)
part("TruckWindow", Vector3.new(0.2, 2.3, 4), Vector3.new(-24.35, 4.1, -27), Color3.fromRGB(55, 85, 100), Enum.Material.Glass, truck)
sign("TruckName", "KOSHERY", Vector3.new(-36, 4.6, -31.05), 9, Color3.fromRGB(35, 95, 150))

for _, x in ipairs({-41, -29}) do
	local wheel = Instance.new("Part")
	wheel.Name = "Wheel"
	wheel.Shape = Enum.PartType.Cylinder
	wheel.Size = Vector3.new(2.2, 2.2, 1)
	wheel.CFrame = CFrame.new(x, 1.3, -23.2) * CFrame.Angles(0, 0, math.rad(90))
	wheel.Anchored = true
	wheel.Color = Color3.fromRGB(25, 25, 25)
	wheel.Parent = truck
end

-- Ingredient shop building
local shop = Instance.new("Model")
shop.Name = "IngredientShop"
shop.Parent = root
part("ShopFloor", Vector3.new(26, 0.6, 22), Vector3.new(20, 0.5, -27), Color3.fromRGB(190, 165, 120), Enum.Material.Concrete, shop)
part("ShopBack", Vector3.new(26, 11, 0.8), Vector3.new(20, 5.8, -37.5), Color3.fromRGB(224, 204, 166), Enum.Material.Concrete, shop)
part("ShopLeft", Vector3.new(0.8, 11, 22), Vector3.new(7.5, 5.8, -27), Color3.fromRGB(224, 204, 166), Enum.Material.Concrete, shop)
part("ShopRight", Vector3.new(0.8, 11, 22), Vector3.new(32.5, 5.8, -27), Color3.fromRGB(224, 204, 166), Enum.Material.Concrete, shop)
sign("ShopSign", "INGREDIENT SHOP", Vector3.new(20, 10, -37.05), 17, Color3.fromRGB(70, 145, 80))

local counter = part("ShopCounter", Vector3.new(18, 2.5, 3), Vector3.new(20, 1.8, -22), Color3.fromRGB(105, 70, 45), Enum.Material.Wood, shop)
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Buy Ingredients"
prompt.ObjectText = "Ingredient Shop"
prompt.HoldDuration = 0.6
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.Parent = counter

local display = Instance.new("BillboardGui")
display.Name = "ShopInfo"
display.Size = UDim2.fromOffset(270, 80)
display.StudsOffset = Vector3.new(0, 3.2, 0)
display.AlwaysOnTop = true
display.Parent = counter
local displayText = Instance.new("TextLabel")
displayText.Size = UDim2.fromScale(1, 1)
displayText.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
displayText.BackgroundTransparency = 0.08
displayText.TextColor3 = Color3.new(1, 1, 1)
displayText.Font = Enum.Font.GothamBold
displayText.TextSize = 14
displayText.TextWrapped = true
displayText.Text = "INGREDIENT SHOP\nRestock ingredients • $20 / 5 each"
displayText.Parent = display
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = displayText

prompt.Triggered:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	if not cash then return end
	if cash.Value < 20 then
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RestaurantRemotes")
		local status = remotes and remotes:FindFirstChild("OrderStatus")
		if status then status:FireClient(player, "Ingredient Shop", "You need $20 to restock.") end
		return
	end
	cash.Value -= 20
	local inventory = player:FindFirstChild("IngredientInventory")
	if inventory then
		for _, value in inventory:GetChildren() do
			if value:IsA("IntValue") then value.Value += 5 end
		end
	end
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("RestaurantRemotes")
	local status = remotes and remotes:FindFirstChild("OrderStatus")
	if status then status:FireClient(player, "Ingredient Shop", "+5 of every ingredient purchased for $20!") end
end)

-- Restaurant zone, intentionally compact and expandable
part("RestaurantLot", Vector3.new(42, 0.5, 30), Vector3.new(78, 0.5, -18), Color3.fromRGB(180, 165, 145), Enum.Material.Concrete)
sign("RestaurantSign", "RESTAURANT", Vector3.new(78, 9, -32.5), 18, Color3.fromRGB(190, 75, 55))
part("RestaurantBack", Vector3.new(42, 12, 0.8), Vector3.new(78, 6, -32), Color3.fromRGB(218, 205, 180), Enum.Material.Concrete)
part("RestaurantLeft", Vector3.new(0.8, 12, 30), Vector3.new(57, 6, -18), Color3.fromRGB(218, 205, 180), Enum.Material.Concrete)
part("RestaurantRight", Vector3.new(0.8, 12, 30), Vector3.new(99, 6, -18), Color3.fromRGB(218, 205, 180), Enum.Material.Concrete)

-- Simple lamp posts for map atmosphere
for _, x in ipairs({-62, -5, 45, 108}) do
	local pole = part("LampPost", Vector3.new(0.5, 7, 0.5), Vector3.new(x, 3.8, 31), Color3.fromRGB(45, 45, 48), Enum.Material.Metal)
	local lamp = part("Lamp", Vector3.new(2, 0.5, 2), Vector3.new(x, 7.5, 31), Color3.fromRGB(255, 220, 120), Enum.Material.Neon)
end

print("EgyptianFood - Map and Ingredient Shop ready")