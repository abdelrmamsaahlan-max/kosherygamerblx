local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UPGRADE_COSTS = {150, 300, 500, 750, 1000}
local BONUS_PERCENT = {0, 10, 20, 30, 40, 50}

local remotes = ReplicatedStorage:FindFirstChild("RestaurantRemotes") or Instance.new("Folder")
remotes.Name = "RestaurantRemotes"
remotes.Parent = ReplicatedStorage
local orderStatus = remotes:FindFirstChild("OrderStatus") or Instance.new("RemoteEvent")
orderStatus.Name = "OrderStatus"
orderStatus.Parent = remotes
local action = remotes:FindFirstChild("UpgradeAction") or Instance.new("RemoteEvent")
action.Name = "UpgradeAction"
action.Parent = remotes

local restaurant = workspace:WaitForChild("Restaurant")
local old = restaurant:FindFirstChild("Restaurant Upgrades")
if old then old:Destroy() end

local function setupPlayer(player: Player)
	local stats = player:WaitForChild("leaderstats")
	local upgrade = stats:FindFirstChild("RestaurantUpgrade") :: IntValue?
	if not upgrade then
		upgrade = Instance.new("IntValue")
		upgrade.Name = "RestaurantUpgrade"
		upgrade.Value = 0
		upgrade.Parent = stats
	end
	local bonus = player:FindFirstChild("RewardBonusPercent") :: IntValue?
	if not bonus then
		bonus = Instance.new("IntValue")
		bonus.Name = "RewardBonusPercent"
		bonus.Parent = player
	end
	bonus.Value = BONUS_PERCENT[upgrade.Value + 1] or 0
	upgrade.Changed:Connect(function()
		bonus.Value = BONUS_PERCENT[upgrade.Value + 1] or 0
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do task.spawn(setupPlayer, player) end

action.OnServerEvent:Connect(function(player, requestedLevel)
	if typeof(requestedLevel) ~= "number" then return end
	local stats = player:FindFirstChild("leaderstats")
	local upgrade = stats and stats:FindFirstChild("RestaurantUpgrade") :: IntValue?
	local cash = stats and stats:FindFirstChild("Cash") :: IntValue?
	if not upgrade or not cash then return end
	local nextLevel = upgrade.Value + 1
	if requestedLevel ~= nextLevel then
		orderStatus:FireClient(player, "Restaurant Upgrades", "Unlock upgrades in order.")
		return
	end
	local cost = UPGRADE_COSTS[nextLevel]
	if not cost then
		orderStatus:FireClient(player, "Restaurant Upgrades", "🏆 Your restaurant is fully upgraded!")
		return
	end
	if cash.Value < cost then
		orderStatus:FireClient(player, "Restaurant Upgrades", string.format("Need $%d for Upgrade Level %d.", cost, nextLevel))
		return
	end
	cash.Value -= cost
	upgrade.Value = nextLevel
	local newBonus = BONUS_PERCENT[nextLevel + 1] or 0
	local nextCost = UPGRADE_COSTS[nextLevel + 1]
	if nextCost then
		orderStatus:FireClient(player, "Restaurant Upgrades", string.format("🚀 Upgrade Level %d! +%d%% order bonus. Next: $%d.", nextLevel, newBonus, nextCost))
	else
		orderStatus:FireClient(player, "Restaurant Upgrades", string.format("🏆 Upgrade Level %d MAX! +%d%% order bonus.", nextLevel, newBonus))
	end
end)

print("EgyptianFood - Upgrade Service ready; core handles reward bonuses")
