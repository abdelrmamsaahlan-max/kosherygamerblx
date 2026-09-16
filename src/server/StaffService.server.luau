local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STAFF_COSTS = {250, 500, 900}
local STAFF_BONUS_TIP = 1

local remotes = ReplicatedStorage:FindFirstChild("RestaurantRemotes") or Instance.new("Folder")
remotes.Name = "RestaurantRemotes"
remotes.Parent = ReplicatedStorage
local status = remotes:FindFirstChild("OrderStatus") or Instance.new("RemoteEvent")
status.Name = "OrderStatus"
status.Parent = remotes

local restaurant = workspace:WaitForChild("Restaurant")
local oldDesk = restaurant:FindFirstChild("Staff Desk")
if oldDesk then oldDesk:Destroy() end

local desk = Instance.new("Part")
desk.Name = "Staff Desk"
desk.Size = Vector3.new(8, 3, 6)
desk.Position = Vector3.new(60, 1.5, 0)
desk.Anchored = true
desk.Material = Enum.Material.SmoothPlastic
desk.Color = Color3.fromRGB(95, 170, 115)
desk.Parent = restaurant

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Hire Staff"
prompt.ObjectText = "Staff Desk"
prompt.HoldDuration = 0.7
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.Parent = desk

local billboard = Instance.new("BillboardGui")
billboard.Name = "StaffInfo"
billboard.Size = UDim2.fromOffset(300, 82)
billboard.StudsOffset = Vector3.new(0, 3.2, 0)
billboard.AlwaysOnTop = true
billboard.Parent = desk

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
label.BackgroundTransparency = 0.08
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextWrapped = true
label.Text = "STAFF DESK\nHire Waiters & Chefs"
label.Parent = billboard
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local function getStaff(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Staff") :: IntValue?
end

local function makePerson(parent: Instance, name: string, position: Vector3, role: string, bodyColor: Color3)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.1, 3, 1.3)
	body.Position = position
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = bodyColor
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.7, 1.7, 1.7)
	head.Position = position + Vector3.new(0, 2.3, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(230, 190, 145)
	head.Parent = model

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(180, 48)
	tag.StudsOffset = Vector3.new(0, 2.2, 0)
	tag.AlwaysOnTop = true
	tag.Parent = head

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0.35
	text.Font = Enum.Font.GothamBold
	text.TextSize = 13
	text.Text = role
	text.Parent = tag

	return model
end

local function createStaffVisual(player: Player, index: number)
	local folder = restaurant:FindFirstChild("Staff_" .. player.UserId)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Staff_" .. player.UserId
		folder.Parent = restaurant
	end

	local role = index == 1 and "🍽️ Waiter" or "👨‍🍳 Chef"
	local existing = folder:FindFirstChild("Staff_" .. index)
	if existing then existing:Destroy() end

	local position = Vector3.new(56 + (index - 1) * 3.5, 2.2, 5)
	local color = index == 1 and Color3.fromRGB(80, 145, 220) or Color3.fromRGB(220, 150, 75)
	makePerson(folder, "Staff_" .. index, position, role, color)

	-- Every chef works in both locations. The Truck may not exist yet, so we also
	-- check again whenever the Workspace hierarchy changes.
	if index >= 2 then
		local truck = workspace:FindFirstChild("Truck") or workspace:FindFirstChild("Food Truck")
		if truck then
			local truckFolder = truck:FindFirstChild("Staff_" .. player.UserId)
			if not truckFolder then
				truckFolder = Instance.new("Folder")
				truckFolder.Name = "Staff_" .. player.UserId
				truckFolder.Parent = truck
			end
			local oldChef = truckFolder:FindFirstChild("Chef_" .. index)
			if oldChef then oldChef:Destroy() end
			makePerson(truckFolder, "Chef_" .. index, Vector3.new(0, 2.2, 0), "👨‍🍳 Chef", Color3.fromRGB(220, 150, 75))
		end
	end
end

local function setupPlayer(player: Player)
	local stats = player:WaitForChild("leaderstats")
	local staff = stats:FindFirstChild("Staff") :: IntValue?
	if not staff then
		staff = Instance.new("IntValue")
		staff.Name = "Staff"
		staff.Value = 0
		staff.Parent = stats
	end

	local tips = stats:WaitForChild("Tips") :: IntValue
	local cash = stats:WaitForChild("Cash") :: IntValue
	local lastTips = tips.Value

	tips:GetPropertyChangedSignal("Value"):Connect(function()
		local delta = tips.Value - lastTips
		lastTips = tips.Value
		if delta <= 0 or staff.Value <= 0 then return end
		local bonus = staff.Value * STAFF_BONUS_TIP
		tips.Value += bonus
		cash.Value += bonus
		lastTips = tips.Value
		status:FireClient(player, "Staff Bonus", string.format("Staff helped! +$%d extra tip", bonus))
	end)

	for i = 1, staff.Value do
		createStaffVisual(player, i)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do task.spawn(setupPlayer, player) end

Players.PlayerRemoving:Connect(function(player)
	local folder = restaurant:FindFirstChild("Staff_" .. player.UserId)
	if folder then folder:Destroy() end
	for _, truckName in ipairs({"Truck", "Food Truck"}) do
		local truck = workspace:FindFirstChild(truckName)
		if truck then
			local truckFolder = truck:FindFirstChild("Staff_" .. player.UserId)
			if truckFolder then truckFolder:Destroy() end
		end
	end
end)

-- If the Truck is added later, place all already-hired chefs inside it.
workspace.ChildAdded:Connect(function(child)
	if child.Name ~= "Truck" and child.Name ~= "Food Truck" then return end
	task.wait(0.2)
	for _, player in Players:GetPlayers() do
		local staff = getStaff(player)
		if staff then
			for i = 2, staff.Value do
				createStaffVisual(player, i)
			end
		end
	end
end)

prompt.Triggered:Connect(function(player)
	local staff = getStaff(player)
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash") :: IntValue?
	if not staff or not cash then return end

	local nextLevel = staff.Value + 1
	local cost = STAFF_COSTS[nextLevel]
	if not cost then
		status:FireClient(player, "Staff Desk", "Your restaurant has all 3 staff members!")
		return
	end
	if cash.Value < cost then
		status:FireClient(player, "Staff Desk", string.format("Need $%d to hire Staff %d.", cost, nextLevel))
		return
	end

	cash.Value -= cost
	staff.Value = nextLevel
	createStaffVisual(player, nextLevel)

	if nextLevel == 1 then
		status:FireClient(player, "Staff Desk", "🍽️ Waiter hired! Your waiter works in the restaurant.")
	else
		status:FireClient(player, "Staff Desk", "👨‍🍳 Chef hired! Your chef works in the truck and restaurant.")
	end
end)

print("EgyptianFood - Staff Service ready")