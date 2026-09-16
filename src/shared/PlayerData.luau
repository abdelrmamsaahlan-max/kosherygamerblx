local PlayerData = {}

PlayerData.DEFAULT = {
	Cash = 0,
}

function PlayerData.createDefault()
	return {
		Cash = PlayerData.DEFAULT.Cash,
	}
end

return PlayerData
