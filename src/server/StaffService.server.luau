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
billboard.Size = UDim2.fromOffset(280, 76)
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
label.Text = "STAFF DESK\nHire helpers for better tips"
label.Parent = billboard
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local function getStaff(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Staff") :: IntValue?
end

local function createStaffVisual(player: Player, index: number)
	local folder = restaurant:FindFirstChild("Staff_" .. player.UserId)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Staff_" .. player.UserId
		folder.Parent = restaurant
	end
	local existing = folder:FindFirstChild("Helper_" .. index)
	if existing then existing:Destroy() end

	local model = Instance.new("Model")
	model.Name = "Helper_" .. index
	model.Parent = folder
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.1, 3, 1.3)
	body.Position = Vector3.new(56 + (index - 1) * 3.5, 2.2, 5)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(220, 150, 75)
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

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(150, 42)
	tag.StudsOffset = Vector3.new(0, 2.2, 0)
	tag.AlwaysOnTop = true
	tag.Parent = head
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 13
	text.Text = "Helper " .. index
	text.Parent = tag
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
end)

prompt.Triggered:Connect(function(player)
	local staff = getStaff(player)
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash") :: IntValue?
	if not staff or not cash then return end

	local nextLevel = staff.Value + 1
	local cost = STAFF_COSTS[nextLevel]
	if not cost then
		status:FireClient(player, "Staff Desk", "Your restaurant has all 3 helpers!")
		return
	end
	if cash.Value < cost then
		status:FireClient(player, "Staff Desk", string.format("Need $%d to hire Helper %d.", cost, nextLevel))
		return
	end

	cash.Value -= cost
	staff.Value = nextLevel
	createStaffVisual(player, nextLevel)
	status:FireClient(player, "Staff Desk", string.format("Helper %d hired! Each helper adds +$%d to tips.", nextLevel, STAFF_BONUS_TIP))
end)

print("EgyptianFood - Staff Service ready")