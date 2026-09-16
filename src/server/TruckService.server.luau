local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TRUCK_POSITION = Vector3.new(-30, 2, 0)
local CHEF_POSITIONS = {
	Vector3.new(-34, 2.2, 5),
	Vector3.new(-30, 2.2, 5),
}

local remotes = ReplicatedStorage:FindFirstChild("RestaurantRemotes") or Instance.new("Folder")
remotes.Name = "RestaurantRemotes"
remotes.Parent = ReplicatedStorage
local status = remotes:FindFirstChild("OrderStatus") or Instance.new("RemoteEvent")
status.Name = "OrderStatus"
status.Parent = remotes

local restaurant = workspace:WaitForChild("Restaurant")
local oldTruck = restaurant:FindFirstChild("Food Truck")
if oldTruck then oldTruck:Destroy() end

local truck = Instance.new("Part")
truck.Name = "Food Truck"
truck.Size = Vector3.new(12, 4, 8)
truck.Position = TRUCK_POSITION
truck.Anchored = true
truck.Material = Enum.Material.SmoothPlastic
truck.Color = Color3.fromRGB(220, 85, 45)
truck.Parent = restaurant

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Work at Truck"
prompt.ObjectText = "Food Truck"
prompt.HoldDuration = 0.6
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.Parent = truck

local sign = Instance.new("BillboardGui")
sign.Name = "TruckInfo"
sign.Size = UDim2.fromOffset(280, 72)
sign.StudsOffset = Vector3.new(0, 3.5, 0)
sign.AlwaysOnTop = true
sign.Parent = truck

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
label.BackgroundTransparency = 0.08
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextWrapped = true
label.Text = "FOOD TRUCK\nYour first restaurant business"
label.Parent = sign
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local function createChef(player: Player, index: number)
	local folder = restaurant:FindFirstChild("TruckChefs_" .. player.UserId)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TruckChefs_" .. player.UserId
		folder.Parent = restaurant
	end
	local modelName = "Chef_" .. index
	local existing = folder:FindFirstChild(modelName)
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = modelName
	model.Parent = folder

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.1, 3, 1.3)
	body.Position = CHEF_POSITIONS[index]
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(235, 235, 235)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.7, 1.7, 1.7)
	head.Position = body.Position + Vector3.new(0, 2.3, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(230, 190, 145)
	head.Parent = model

	local hat = Instance.new("Part")
	hat.Name = "ChefHat"
	hat.Size = Vector3.new(1.9, 0.7, 1.9)
	hat.Position = head.Position + Vector3.new(0, 1.05, 0)
	hat.Anchored = true
	hat.CanCollide = false
	hat.Material = Enum.Material.SmoothPlastic
	hat.Color = Color3.fromRGB(255, 255, 255)
	hat.Parent = model

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(150, 42)
	tag.StudsOffset = Vector3.new(0, 2.5, 0)
	tag.AlwaysOnTop = true
	tag.Parent = head

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 13
	text.Text = "Chef " .. index
	text.Parent = tag
end

local function setupPlayer(player: Player)
	if player:GetAttribute("RestaurantOpened") == nil then
		player:SetAttribute("RestaurantOpened", false)
	end
	if player:GetAttribute("TruckChefs") == nil then
		player:SetAttribute("TruckChefs", 0)
	end
	for i = 1, player:GetAttribute("TruckChefs") or 0 do
		if i <= #CHEF_POSITIONS then createChef(player, i) end
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do task.spawn(setupPlayer, player) end

Players.PlayerRemoving:Connect(function(player)
	local folder = restaurant:FindFirstChild("TruckChefs_" .. player.UserId)
	if folder then folder:Destroy() end
end)

prompt.Triggered:Connect(function(player)
	status:FireClient(player, "Food Truck", "Your Food Truck is ready! Chefs can work here now.")
end)

print("EgyptianFood - Truck Service ready")