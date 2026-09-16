local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("RestaurantRemotes")
local statusEvent = remotes:WaitForChild("OrderStatus")

local STREAK_REWARD = 10
local MILESTONE = 5

local function setup(player: Player)
	if player:GetAttribute("OrderStreak") == nil then
		player:SetAttribute("OrderStreak", 0)
	end
end

local function notify(player: Player, message: string)
	statusEvent:FireClient(player, message)
end

Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do
	setup(player)
end

-- The main restaurant currently awards 25 XP for every successful delivery.
-- Track XP increases and turn consecutive successful deliveries into streak bonuses.
task.spawn(function()
	local lastXP: {[Player]: number} = {}
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local leaderstats = player:FindFirstChild("leaderstats")
			local xp = leaderstats and leaderstats:FindFirstChild("XP")
			local cash = leaderstats and leaderstats:FindFirstChild("Cash")
			if xp and cash then
				local current = xp.Value
				local previous = lastXP[player]
				if previous == nil then
					lastXP[player] = current
				elseif current > previous then
					local deliveries = math.floor((current - previous) / 25)
					if deliveries > 0 then
						local streak = player:GetAttribute("OrderStreak") or 0
						streak += deliveries
						player:SetAttribute("OrderStreak", streak)

						if streak % MILESTONE == 0 then
							cash.Value += STREAK_REWARD
							notify(player, string.format("🔥 %d ORDER STREAK! +$%d streak bonus!", streak, STREAK_REWARD))
						else
							notify(player, string.format("🔥 Order streak: %d", streak))
						end
					end
					lastXP[player] = previous + deliveries * 25
				end
				lastXP[player] = math.max(lastXP[player] or current, current)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastXP[player] = nil
end)