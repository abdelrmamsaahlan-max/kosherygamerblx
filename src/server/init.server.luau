local Players = game:GetService("Players")

local DataService = require(script.Parent:WaitForChild("DataService"))

local function setupLeaderstats(player: Player, startingCash: number)
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		existing:Destroy()
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.max(0, math.floor(startingCash))
	cash.Parent = leaderstats

	cash.Changed:Connect(function(value)
		local current = DataService:Get(player)
		if current then
			current.Cash = math.max(0, value)
		end
	end)

	return cash
end

local function onPlayerAdded(player: Player)
	-- Create the visible Cash stat immediately so it never depends on DataStore availability.
	local cash = setupLeaderstats(player, 0)

	local success, data = pcall(function()
		return DataService:Load(player)
	end)

	if success and data then
		cash.Value = math.max(0, math.floor(data.Cash or 0))
	else
		warn("[EgyptianFood] Data failed to load for " .. player.Name .. "; using Cash = 0")
	end
end

local function onPlayerRemoving(player: Player)
	DataService:Save(player)
	DataService:Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	local players = Players:GetPlayers()
	local remaining = #players

	if remaining == 0 then
		return
	end

	for _, player in players do
		task.spawn(function()
			DataService:Save(player)
			remaining -= 1
		end)
	end

	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do
		task.wait()
	end
end)

print("EgyptianFood server initialized")
