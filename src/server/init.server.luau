local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REWARD = 25
local playerStates: {[Player]: "None" | "Ordered" | "Prepared"} = {}

local remotes = ReplicatedStorage:FindFirstChild("RestaurantRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "RestaurantRemotes"
	remotes.Parent = ReplicatedStorage
end

local orderStatusEvent = remotes:FindFirstChild("OrderStatus")
if not orderStatusEvent then
	orderStatusEvent = Instance.new("RemoteEvent")
	orderStatusEvent.Name = "OrderStatus"
	orderStatusEvent.Parent = remotes
end

local function sendStatus(player: Player, order: string, status: string)
	orderStatusEvent:FireClient(player, order, status)
end

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

local function getState(player: Player)
	return playerStates[player] or "None"
end

local function startOrder(player: Player)
	if getState(player) ~= "None" then
		sendStatus(player, "Koshary", "You already have an order in progress")
		return false, "You already have a Koshary order in progress."
	end

	playerStates[player] = "Ordered"
	sendStatus(player, "Koshary", "Order received — prepare it")
	return true, "Koshary order received! Prepare it at the Prep Station."
end

local function prepareOrder(player: Player)
	if getState(player) ~= "Ordered" then
		sendStatus(player, "No active order", "Take an order first")
		return false, "You need to take a Koshary order first."
	end

	playerStates[player] = "Prepared"
	sendStatus(player, "Koshary", "Ready — deliver the order")
	return true, "Koshary is ready! Deliver it to the customer."
end

local function deliverOrder(player: Player)
	if getState(player) ~= "Prepared" then
		sendStatus(player, "Koshary", "Prepare the order first")
		return false, "You need to prepare the Koshary first."
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if not cash or not cash:IsA("IntValue") then
		sendStatus(player, "Koshary", "Cash system is not ready")
		return false, "Cash system is not ready yet."
	end

	cash.Value += REWARD
	playerStates[player] = "None"
	sendStatus(player, "No active order", string.format("Order complete — +$%d. Take another!", REWARD))
	return true, string.format("Order delivered! +$%d Cash.", REWARD)
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

	return prompt
end

local function setupRestaurant()
	local existing = workspace:FindFirstChild("Restaurant")
	if existing then
		existing:Destroy()
	end

	local restaurant = Instance.new("Folder")
	restaurant.Name = "Restaurant"
	restaurant.Parent = workspace

	local orderPrompt = createStation(restaurant, "Order Counter", Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 205, 80), "Take Order")
	local prepPrompt = createStation(restaurant, "Koshary Prep Station", Vector3.new(12, 1.5, 0), Color3.fromRGB(95, 175, 255), "Prepare Koshary")
	local deliveryPrompt = createStation(restaurant, "Delivery Counter", Vector3.new(24, 1.5, 0), Color3.fromRGB(95, 210, 125), "Deliver Order")

	orderPrompt.Triggered:Connect(function(player)
		local _, message = startOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)

	prepPrompt.Triggered:Connect(function(player)
		local _, message = prepareOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)

	deliveryPrompt.Triggered:Connect(function(player)
		local _, message = deliverOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)

	print("Restaurant stations created: Order -> Prep -> Delivery")
end

local function onPlayerAdded(player: Player)
	playerStates[player] = "None"
	setupLeaderstats(player)
	task.defer(function()
		if player.Parent then
			sendStatus(player, "No active order", "Go to the Order Counter")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

setupRestaurant()

print("EgyptianFood server initialized - Cash + Koshary gameplay ready")
