local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REWARD = 25
local ORDER_TIME = 45
local playerStates: {[Player]: "None" | "Ordered" | "Prepared"} = {}
local activeOrders: {[Player]: {customer: Model, expiresAt: number}} = {}

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

local function createCustomer(parent: Folder, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Customer"
	model.Parent = parent

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.2, 3, 1.4)
	body.Position = position + Vector3.new(0, 2.2, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(80, 105, 145)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.8, 1.8, 1.8)
	head.Position = position + Vector3.new(0, 4.5, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(230, 190, 145)
	head.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OrderBubble"
	billboard.Size = UDim2.fromOffset(170, 55)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	label.BackgroundTransparency = 0.08
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.Text = "🥘 Koshary\nWaiting for my order"
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	return model
end

local function destroyCustomer(player: Player)
	local order = activeOrders[player]
	if order and order.customer then
		order.customer:Destroy()
	end
	activeOrders[player] = nil
end

local function startOrder(player: Player)
	if getState(player) ~= "None" then
		sendStatus(player, "Koshary", "You already have an order in progress")
		return false, "You already have a Koshary order in progress."
	end

	local restaurant = workspace:FindFirstChild("Restaurant")
	local customers = restaurant and restaurant:FindFirstChild("Customers")
	if not customers then
		return false, "Customer system is not ready yet."
	end

	local customer = createCustomer(customers, Vector3.new(-2, 0, -8))
	playerStates[player] = "Ordered"
	activeOrders[player] = {customer = customer, expiresAt = os.clock() + ORDER_TIME}
	sendStatus(player, "Koshary", string.format("Order received — %ds to prepare", ORDER_TIME))

	task.spawn(function()
		while player.Parent and getState(player) == "Ordered" do
			local order = activeOrders[player]
			if not order then
				break
			end

			local remaining = math.max(0, math.ceil(order.expiresAt - os.clock()))
			sendStatus(player, "Koshary", string.format("Prepare the order — %ds left", remaining))
			if remaining <= 0 then
				playerStates[player] = "None"
				destroyCustomer(player)
				sendStatus(player, "No active order", "Customer left — order expired")
				break
			end
			task.wait(1)
		end
	end)

	return true, "Koshary order received! Prepare it at the Prep Station."
end

local function prepareOrder(player: Player)
	if getState(player) ~= "Ordered" then
		sendStatus(player, "No active order", "Take an order first")
		return false, "You need to take a Koshary order first."
	end

	local order = activeOrders[player]
	if not order or order.expiresAt <= os.clock() then
		playerStates[player] = "None"
		destroyCustomer(player)
		sendStatus(player, "No active order", "Customer left — order expired")
		return false, "The order expired."
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
		return false, "Cash system is not ready yet."
	end

	cash.Value += REWARD
	playerStates[player] = "None"
	destroyCustomer(player)
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

	local customers = Instance.new("Folder")
	customers.Name = "Customers"
	customers.Parent = restaurant

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
	destroyCustomer(player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

setupRestaurant()
print("EgyptianFood server initialized - Customers + Koshary orders ready")