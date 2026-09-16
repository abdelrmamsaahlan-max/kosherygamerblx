local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent:WaitForChild("DataService"))

local function setupLeaderstats(player: Player, data: {Cash: number})
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(data.Cash)
	cash.Parent = leaderstats

	cash.Changed:Connect(function(value)
		local current = DataService:Get(player)
		if current then
			current.Cash = math.max(0, value)
		end
	end)
end

local function onPlayerAdded(player: Player)
	local data = DataService:Load(player)
	setupLeaderstats(player, data)
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
