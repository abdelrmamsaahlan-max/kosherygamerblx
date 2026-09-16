local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ORDER_TIME = 60
local QUEUE_SIZE = 3

local ORDER_TYPES = {
	Koshary = {
		reward = 25,
		steps = {"Cook the Rice", "Add the Lentils", "Add the Pasta", "Add the Tomato Sauce", "Add Crispy Onions"},
	},
	Ful = {
		reward = 20,
		steps = {"Cook the Fava Beans", "Add Olive Oil", "Add Cumin", "Add Lemon", "Add Toppings"},
	},
	Falafel = {
		reward = 30,
		steps = {"Prepare the Falafel Mix", "Shape the Falafel", "Fry the Falafel", "Prepare Tahini", "Plate the Falafel"},
	},
}

local ORDER_NAMES = {"Koshary", "Ful", "Falafel"}

local playerStates: {[Player]: "None" | "Ordered" | "Cooking" | "Prepared"} = {}
local cookingSteps: {[Player]: number} = {}
local activeOrders: {[Player]: {customer: Model, expiresAt: number, orderName: string}} = {}
local customersInQueue: {Model} = {}

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

local function getOrderData(player: Player)
	local active = activeOrders[player]
	return active and ORDER_TYPES[active.orderName], active
end

local function updateCustomerDisplay(customer: Model, text: string)
	local head = customer:FindFirstChild("Head")
	local billboard = head and head:FindFirstChild("OrderBubble")
	local label = billboard and billboard:FindFirstChild("TextLabel")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function moveCustomer(customer: Model, target: Vector3)
	local body = customer:FindFirstChild("Body")
	local head = customer:FindFirstChild("Head")
	if body and body:IsA("BasePart") then
		body.Position = target + Vector3.new(0, 2.2, 0)
	end
	if head and head:IsA("BasePart") then
		head.Position = target + Vector3.new(0, 4.5, 0)
	end
end

local function createCustomer(parent: Folder, position: Vector3, index: number): Model
	local model = Instance.new("Model")
	model.Name = "Customer_" .. index
	model.Parent = parent

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.2, 3, 1.4)
	body.Position = position + Vector3.new(0, 2.2, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(80 + index * 20, 105, 145)
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
	billboard.Size = UDim2.fromOffset(220, 70)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	label.BackgroundTransparency = 0.08
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextWrapped = true
	label.Text = "👤 Customer\nWaiting for a seat"
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	return model
end

local function refreshQueueDisplays()
	for index, customer in ipairs(customersInQueue) do
		if customer.Parent then
			if index == 1 then
				updateCustomerDisplay(customer, "👤 Customer 1\nReady to order")
			else
				updateCustomerDisplay(customer, string.format("👤 Customer %d\nWaiting in line", index))
			end
		end
	end
end

local function buildQueue(parent: Folder)
	customersInQueue = {}
	local queuePositions = {
		Vector3.new(-2, 0, -8),
		Vector3.new(-6, 0, -8),
		Vector3.new(-10, 0, -8),
	}

	for index = 1, QUEUE_SIZE do
		customersInQueue[index] = createCustomer(parent, queuePositions[index], index)
	end
	refreshQueueDisplays()
end

local function removeFrontCustomer()
	local customer = table.remove(customersInQueue, 1)
	if customer then
		customer:Destroy()
	end
end

local function refillQueue(parent: Folder)
	while #customersInQueue < QUEUE_SIZE do
		local index = #customersInQueue + 1
		local queuePositions = {
			Vector3.new(-2, 0, -8),
			Vector3.new(-6, 0, -8),
			Vector3.new(-10, 0, -8),
		}
		customersInQueue[index] = createCustomer(parent, queuePositions[index], index + math.random(1, 50))
	end
end

local function shiftQueue()
	local queuePositions = {
		Vector3.new(-2, 0, -8),
		Vector3.new(-6, 0, -8),
		Vector3.new(-10, 0, -8),
	}
	for index, customer in ipairs(customersInQueue) do
		moveCustomer(customer, queuePositions[index])
	end
	refreshQueueDisplays()
end

local function destroyActiveCustomer(player: Player)
	local active = activeOrders[player]
	if active and active.customer then
		active.customer:Destroy()
	end
	activeOrders[player] = nil
	cookingSteps[player] = nil
end

local function resetPlayerOrder(player: Player, message: string)
	playerStates[player] = "None"
	destroyActiveCustomer(player)
	sendStatus(player, "No active order", message)
end

local function expireOrder(player: Player)
	resetPlayerOrder(player, "Customer left — order expired")
	refillQueue(workspace.Restaurant.Customers)
	shiftQueue()
end

local function chooseOrder()
	local name = ORDER_NAMES[math.random(1, #ORDER_NAMES)]
	return name, ORDER_TYPES[name]
end

local function startOrder(player: Player)
	if getState(player) ~= "None" then
		sendStatus(player, "Current Order", "Finish your current order first")
		return false, "You already have an order in progress."
	end

	local restaurant = workspace:FindFirstChild("Restaurant")
	local customersFolder = restaurant and restaurant:FindFirstChild("Customers")
	if not customersFolder or #customersInQueue == 0 then
		return false, "No customer is waiting right now."
	end

	local customer = customersInQueue[1]
	local orderName, orderData = chooseOrder()

	playerStates[player] = "Ordered"
	cookingSteps[player] = 1
	activeOrders[player] = {
		customer = customer,
		expiresAt = os.clock() + ORDER_TIME,
		orderName = orderName,
	}

	updateCustomerDisplay(customer, string.format("🥘 %s\nI want this!", orderName))
	sendStatus(player, orderName, string.format("Order taken — ⏱ 60s • Step 1/%d", #orderData.steps))

	task.spawn(function()
		while player.Parent and (getState(player) == "Ordered" or getState(player) == "Cooking") do
			local active = activeOrders[player]
			if not active then
				break
			end

			local remaining = math.max(0, math.ceil(active.expiresAt - os.clock()))
			if remaining <= 0 then
				expireOrder(player)
				break
			end

			local data = ORDER_TYPES[active.orderName]
			local step = cookingSteps[player] or 1
			local stepName = data.steps[step] or "Finish the order"
			sendStatus(player, active.orderName, string.format("⏱ %ds left • %s", remaining, stepName))
			updateCustomerDisplay(customer, string.format("🥘 %s\nWaiting... %ds", active.orderName, remaining))
			task.wait(1)
		end
	end)

	return true, string.format("%s order taken! Start cooking.", orderName)
end

local function cookOrder(player: Player)
	local state = getState(player)
	if state ~= "Ordered" and state ~= "Cooking" then
		sendStatus(player, "No active order", "Take an order first")
		return false, "You need to take an order first."
	end

	local data, active = getOrderData(player)
	if not data or not active or active.expiresAt <= os.clock() then
		expireOrder(player)
		return false, "The customer left because the order expired."
	end

	playerStates[player] = "Cooking"
	local step = cookingSteps[player] or 1
	local stepName = data.steps[step]

	if stepName then
		cookingSteps[player] = step + 1
		sendStatus(player, active.orderName, string.format("Cooking %d/%d: %s", step, #data.steps, stepName))
		updateCustomerDisplay(active.customer, string.format("🥘 %s\nCooking %d/%d", active.orderName, step, #data.steps))
		return true, string.format("%s done! Continue cooking.", stepName)
	end

	playerStates[player] = "Prepared"
	sendStatus(player, active.orderName, string.format("✅ %s ready — deliver it!", active.orderName))
	updateCustomerDisplay(active.customer, string.format("🥘 %s\nReady! Bring my food!", active.orderName))
	return true, string.format("%s is ready! Deliver it.", active.orderName)
end

local function deliverOrder(player: Player)
	if getState(player) ~= "Prepared" then
		sendStatus(player, "Current Order", "Finish all cooking steps first")
		return false, "Finish the cooking steps first."
	end

	local data, active = getOrderData(player)
	if not data or not active then
		return false, "Order data is missing."
	end

	if active.expiresAt <= os.clock() then
		expireOrder(player)
		return false, "The customer left because the order expired."
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if not cash or not cash:IsA("IntValue") then
		return false, "Cash system is not ready yet."
	end

	cash.Value += data.reward
	removeFrontCustomer()
	activeOrders[player] = nil
	cookingSteps[player] = nil
	playerStates[player] = "None"

	refillQueue(workspace.Restaurant.Customers)
	shiftQueue()

	local nextCustomer = customersInQueue[1]
	if nextCustomer then
		updateCustomerDisplay(nextCustomer, "👤 Customer 1\nReady to order")
	end

	sendStatus(player, "No active order", string.format("Order complete — +$%d • Next customer is ready!", data.reward))
	return true, string.format("%s delivered! +$%d Cash.", active.orderName, data.reward)
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

	local customersFolder = Instance.new("Folder")
	customersFolder.Name = "Customers"
	customersFolder.Parent = restaurant
	buildQueue(customersFolder)

	local orderPrompt = createStation(restaurant, "Order Counter", Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 205, 80), "Take Order")
	local prepPrompt = createStation(restaurant, "Koshary Prep Station", Vector3.new(12, 1.5, 0), Color3.fromRGB(95, 175, 255), "Cook Step")
	local deliveryPrompt = createStation(restaurant, "Delivery Counter", Vector3.new(24, 1.5, 0), Color3.fromRGB(95, 210, 125), "Deliver Order")

	orderPrompt.Triggered:Connect(function(player)
		local _, message = startOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)

	prepPrompt.Triggered:Connect(function(player)
		local _, message = cookOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)

	deliveryPrompt.Triggered:Connect(function(player)
		local _, message = deliverOrder(player)
		print(string.format("[%s] %s", player.Name, message))
	end)
end

local function onPlayerAdded(player: Player)
	playerStates[player] = "None"
	setupLeaderstats(player)
	task.defer(function()
		if player.Parent then
			sendStatus(player, "No active order", "Customer is waiting — go take the order")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
	destroyActiveCustomer(player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

math.randomseed(os.time())
setupRestaurant()
print("EgyptianFood server initialized - Customer Queue + Multiple Orders ready")