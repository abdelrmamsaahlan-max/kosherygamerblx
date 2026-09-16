local Players = game:GetService("Players")

local OrderService = {}

local REWARD = 25
local ORDER_NAME = "Koshary"

type OrderState = "None" | "Ordered" | "Prepared"

local playerStates: {[Player]: OrderState} = {}

local function getCash(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil
	end

	local cash = leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		return cash
	end

	return nil
end

function OrderService.GetState(player: Player): OrderState
	return playerStates[player] or "None"
end

function OrderService.StartOrder(player: Player): (boolean, string)
	if OrderService.GetState(player) ~= "None" then
		return false, "You already have a Koshary order in progress."
	end

	playerStates[player] = "Ordered"
	return true, "Koshary order received! Prepare it at the Prep Station."
end

function OrderService.PrepareOrder(player: Player): (boolean, string)
	if OrderService.GetState(player) ~= "Ordered" then
		return false, "You need to take a Koshary order first."
	end

	playerStates[player] = "Prepared"
	return true, "Koshary is ready! Deliver it to the customer."
end

function OrderService.DeliverOrder(player: Player): (boolean, string)
	if OrderService.GetState(player) ~= "Prepared" then
		return false, "You need to prepare the Koshary first."
	end

	local cash = getCash(player)
	if not cash then
		return false, "Cash system is not ready yet."
	end

	cash.Value += REWARD
	playerStates[player] = "None"

	return true, string.format("Order delivered! +$%d Cash.", REWARD)
end

function OrderService.Cleanup(player: Player)
	playerStates[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	OrderService.Cleanup(player)
end)

return OrderService
