local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerData"))

local STORE_NAME = "EgyptianFoodPlayerData_v1"
local store = DataStoreService:GetDataStore(STORE_NAME)

local DataService = {}
local loadedData: {[Player]: {Cash: number}} = {}
local saving: {[Player]: boolean} = {}

local function cloneDefault()
	return PlayerData.createDefault()
end

function DataService:Load(player: Player)
	if loadedData[player] then
		return loadedData[player]
	end

	local key = "Player_" .. player.UserId
	local data = cloneDefault()

	local success, result = pcall(function()
		return store:GetAsync(key)
	end)

	if success and type(result) == "table" then
		if type(result.Cash) == "number" then
			data.Cash = math.max(0, result.Cash)
		end
	elseif not success then
		warn(("[DataService] Failed to load %s: %s"):format(player.Name, tostring(result)))
	end

	loadedData[player] = data
	return data
end

function DataService:Get(player: Player)
	return loadedData[player]
end

function DataService:Save(player: Player)
	local data = loadedData[player]
	if not data or saving[player] then
		return false
	end

	saving[player] = true
	local key = "Player_" .. player.UserId
	local payload = {
		Cash = math.max(0, math.floor(data.Cash)),
	}

	local success, err = pcall(function()
		store:UpdateAsync(key, function()
			return payload
		end)
	end)

	saving[player] = nil

	if not success then
		warn(("[DataService] Failed to save %s: %s"):format(player.Name, tostring(err)))
		return false
	end

	return true
end

function DataService:Release(player: Player)
	loadedData[player] = nil
	saving[player] = nil
end

return DataService
