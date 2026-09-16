local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local restaurant = workspace:WaitForChild("Restaurant")
local remotes = ReplicatedStorage:WaitForChild("RestaurantRemotes")
local statusEvent = remotes:WaitForChild("OrderStatus")

-- These roles are intentionally locked until the restaurant is opened.
-- The future truck/restaurant expansion can unlock them by setting:
-- player:SetAttribute("RestaurantOpened", true)

local ROLE_CONFIG = {
	Waiter = {
		cost = 400,
		label = "🍽️ WAITER",
		description = "Serves customers and handles deliveries",
		position = Vector3.new(84, 1.5, 5),
	},
	Cook = {
		cost = 600,
		label = "👨‍🍳 COOK",
		description = "Prepares cooking steps automatically",
		position = Vector3.new(92, 1.5, 5),
	},
}

local function notify(player: Player, text: string)
	statusEvent:FireClient(player, text)
end

local function createNPC(roleName: string, config)
	local folder = restaurant:FindFirstChild("FutureStaff")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "FutureStaff"
		folder.Parent = restaurant
	end

	local model = Instance.new("Model")
	model.Name = roleName .. " Staff"
	model.Parent = folder

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 3, 1.5)
	body.Position = config.position
	body.Anchored = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = roleName == "Cook" and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(70, 120, 180)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Position = config.position + Vector3.new(0, 2.2, 0)
	head.Anchored = true
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(255, 204, 153)
	head.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hire " .. roleName
	prompt.ObjectText = config.label
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 10
	prompt.Parent = body

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(260, 75)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = config.label .. "\n$" .. config.cost .. " • " .. config.description
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	prompt.Triggered:Connect(function(player)
		if not player:GetAttribute("RestaurantOpened") then
			notify(player, "🔒 " .. roleName .. " unlocks after you open the restaurant from the truck.")
			return
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		local cash = leaderstats and leaderstats:FindFirstChild("Cash")
		if not cash then return end

		local attribute = roleName .. "Staff"
		if player:GetAttribute(attribute) then
			notify(player, "You already hired a " .. roleName .. ".")
			return
		end

		if cash.Value < config.cost then
			notify(player, string.format("You need $%d to hire the %s.", config.cost, roleName))
			return
		end

		cash.Value -= config.cost
		player:SetAttribute(attribute, true)
		notify(player, "✅ " .. roleName .. " hired! " .. config.description .. ".")
	end)
end

createNPC("Waiter", ROLE_CONFIG.Waiter)
createNPC("Cook", ROLE_CONFIG.Cook)

local function setupPlayer(player: Player)
	if player:GetAttribute("RestaurantOpened") == nil then
		player:SetAttribute("RestaurantOpened", false)
	end
	player:SetAttribute("WaiterStaff", false)
	player:SetAttribute("CookStaff", false)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

-- Role effects are prepared here and will become active once the restaurant-opening
-- system is added. This keeps the jobs ready without changing the current truck stage.
task.spawn(function()
	while true do
		task.wait(2)
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("RestaurantOpened") then
				if player:GetAttribute("WaiterStaff") then
					player:SetAttribute("WaiterActive", true)
				end
				if player:GetAttribute("CookStaff") then
					player:SetAttribute("CookActive", true)
				end
			end
		end
	end
end)