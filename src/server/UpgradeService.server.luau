local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UPGRADE_COSTS = {150, 300, 500, 750, 1000}
local BONUS_PERCENT = {0, 10, 20, 30, 40, 50}
local ORDER_REWARDS = {
	[20] = true,
	[25] = true,
	[30] = true,
}

local remotes = ReplicatedStorage:FindFirstChild("RestaurantRemotes") or Instance.new("Folder")
remotes.Name = "RestaurantRemotes"
remotes.Parent = ReplicatedStorage

local orderStatus = remotes:FindFirstChild("OrderStatus") or Instance.new("RemoteEvent")
orderStatus.Name = "OrderStatus"
orderStatus.Parent = remotes

local restaurant = workspace:WaitForChild("Restaurant")
local existing = restaurant:FindFirstChild("Restaurant Upgrades")
if existing then
	existing:Destroy()
end

local station = Instance.new("Part")
station.Name = "Restaurant Upgrades"
station.Size = Vector3.new(8, 3, 6)
station.Position = Vector3.new(48, 1.5, 0)
station.Anchored = true
station.Material = Enum.Material.SmoothPlastic
station.Color = Color3.fromRGB(255, 170, 70)
station.Parent = restaurant

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Upgrade Restaurant"
prompt.ObjectText = "Restaurant Upgrades"
prompt.HoldDuration = 0.7
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.Parent = station

local billboard = Instance.new("BillboardGui")
billboard.Name = "UpgradeInfo"
billboard.Size = UDim2.fromOffset(260, 70)
billboard.StudsOffset = Vector3.new(0, 3.2, 0)
billboard.AlwaysOnTop = true
billboard.Parent = station

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
label.BackgroundTransparency = 0.08
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.TextWrapped = true
label.Text = "⭐ RESTAURANT UPGRADES\nEarn better rewards"
label.Parent = billboard

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local function getUpgrade(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("RestaurantUpgrade") :: IntValue?
end

local function setupPlayer(player: Player)
	local leaderstats = player:WaitForChild("leaderstats")
	local upgrade = leaderstats:FindFirstChild("RestaurantUpgrade") :: IntValue?
	if not upgrade then
		upgrade = Instance.new("IntValue")
		upgrade.Name = "RestaurantUpgrade"
		upgrade.Value = 0
		upgrade.Parent = leaderstats
	end

	local rewardBonus = player:FindFirstChild("RewardBonusPercent") :: IntValue?
	if not rewardBonus then
		rewardBonus = Instance.new("IntValue")
		rewardBonus.Name = "RewardBonusPercent"
		rewardBonus.Value = BONUS_PERCENT[upgrade.Value + 1] or 0
		rewardBonus.Parent = player
	else
		rewardBonus.Value = BONUS_PERCENT[upgrade.Value + 1] or 0
	end

	local cash = leaderstats:WaitForChild("Cash") :: IntValue
	local lastCash = cash.Value
	local changing = false

	cash:GetPropertyChangedSignal("Value"):Connect(function()
		local newCash = cash.Value
		local delta = newCash - lastCash
		lastCash = newCash

		if changing or delta <= 0 or not ORDER_REWARDS[delta] then
			return
		end

		local percent = rewardBonus.Value
		if percent <= 0 then
			return
		end

		local bonus = math.floor(delta * percent / 100)
		if bonus <= 0 then
			return
		end

		changing = true
		cash.Value += bonus
		lastCash = cash.Value
		changing = false
		orderStatus:FireClient(player, "Upgrade Bonus", string.format("⭐ Upgrade bonus +$%d (%d%%)", bonus, percent))
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(setupPlayer, player)
end

prompt.Triggered:Connect(function(player)
	local upgrade = getUpgrade(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash") :: IntValue?
	if not upgrade or not cash then
		return
	end

	local current = upgrade.Value
	local nextLevel = current + 1
	local cost = UPGRADE_COSTS[nextLevel]
	if not cost then
		orderStatus:FireClient(player, "Restaurant Upgrades", "🏆 Max upgrade reached — your restaurant is fully upgraded!")
		return
	end

	if cash.Value < cost then
		orderStatus:FireClient(player, "Restaurant Upgrades", string.format("Need $%d for Upgrade Level %d.", cost, nextLevel))
		return
	end

	cash.Value -= cost
	upgrade.Value = nextLevel
	local bonus = player:FindFirstChild("RewardBonusPercent") :: IntValue?
	if bonus then
		bonus.Value = BONUS_PERCENT[nextLevel + 1] or 0
	end

	local nextCost = UPGRADE_COSTS[nextLevel + 1]
	if nextCost then
		orderStatus:FireClient(player, "Restaurant Upgrades", string.format("🚀 Upgrade Level %d! Orders now give +%d%% bonus. Next upgrade: $%d.", nextLevel, bonus and bonus.Value or 0, nextCost))
	else
		orderStatus:FireClient(player, "Restaurant Upgrades", string.format("🏆 Upgrade Level %d MAX! Orders now give +%d%% bonus.", nextLevel, bonus and bonus.Value or 0))
	end
end)

print("EgyptianFood - Restaurant Upgrade Service ready")