local Players = game:GetService("Players")

local OrderService = require(script.Parent.OrderService)

local function setupLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cash = leaderstats:FindFirstChild("Cash")
	if not cash then
		cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = leaderstats
	end
end

local function createStation(parent: Folder, name: string, position: Vector3, color: Color3, actionText: string)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(8, 3, 6)
	part.Position = position
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = parent

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	return part, prompt
end

local function setupRestaurant()
	local existing = workspace:FindFirstChild("Restaurant")
	if existing then
		existing:Destroy()
	end

	local restaurant = Instance.new("Folder")
	restaurant.Name = "Restaurant"
	restaurant.Parent = workspace

	local orderCounter, orderPrompt = createStation(
		restaurant,
		"Order Counter",
		Vector3.new(0, 1.5, 0),
		Color3.fromRGB(255, 205, 80),
		"Take Order"
	)

	local prepStation, prepPrompt = createStation(
		restaurant,
		"Koshary Prep Station",
		Vector3.new(12, 1.5, 0),
		Color3.fromRGB(95, 175, 255),
		"Prepare Koshary"
	)

	local deliveryCounter, deliveryPrompt = createStation(
		restaurant,
		"Delivery Counter",
		Vector3.new(24, 1.5, 0),
		Color3.fromRGB(95, 210, 125),
		"Deliver Order"
	)

	orderPrompt.Triggered:Connect(function(player)
		local success, message = OrderService.StartOrder(player)
		print(string.format("[%s] %s", player.Name, message))
		if success then
			orderPrompt.ObjectText = "Koshary Order"
		end
	end)

	prepPrompt.Triggered:Connect(function(player)
		local success, message = OrderService.PrepareOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)

	deliveryPrompt.Triggered:Connect(function(player)
		local success, message = OrderService.DeliverOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)

	print("Restaurant stations created: Order -> Prep -> Delivery")
end

local function onPlayerAdded(player: Player)
	setupLeaderstats(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

setupRestaurant()

print("EgyptianFood server initialized - Cash leaderboard ready")
