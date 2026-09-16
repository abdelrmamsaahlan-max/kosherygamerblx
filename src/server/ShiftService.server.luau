local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local restaurant = workspace:WaitForChild("Restaurant")
local remotes = ReplicatedStorage:WaitForChild("RestaurantRemotes")
local statusEvent = remotes:WaitForChild("OrderStatus")

local SHIFT_LENGTH = 300
local GOAL_ORDERS = 5
local SHIFT_REWARD = 150

local shiftState: {[Player]: {active: boolean, endsAt: number, orders: number, day: number}} = {}

local function getShift(player: Player)
	return shiftState[player]
end

local function send(player: Player, text: string)
	statusEvent:FireClient(player, text)
end

local function createStation()
	local existing = restaurant:FindFirstChild("Shift Desk")
	if existing then return existing end

	local part = Instance.new("Part")
	part.Name = "Shift Desk"
	part.Size = Vector3.new(5, 3, 4)
	part.Position = Vector3.new(72, 1.5, 0)
	part.Anchored = true
	part.Material = Enum.Material.WoodPlanks
	part.Color = Color3.fromRGB(95, 65, 40)
	part.Parent = restaurant

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Start Shift"
	prompt.ObjectText = "Shift Desk"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 10
	prompt.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ShiftBillboard"
	billboard.Size = UDim2.fromOffset(260, 70)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "🌅 SHIFT DESK\nStart your restaurant day"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	prompt.Triggered:Connect(function(player)
		local state = shiftState[player]
		if state and state.active then
			send(player, string.format("🌅 Shift in progress | Orders: %d/%d", state.orders, GOAL_ORDERS))
			return
		end

		local day = state and state.day or 0
		day += 1
		shiftState[player] = {
			active = true,
			endsAt = os.clock() + SHIFT_LENGTH,
			orders = 0,
			day = day,
		}

		prompt.ActionText = "Shift Active"
		send(player, string.format("🌅 DAY %d STARTED! Goal: %d orders in 5 minutes. Reward: $%d", day, GOAL_ORDERS, SHIFT_REWARD))
	end)

	return part
end

createStation()

local function setupPlayer(player: Player)
	shiftState[player] = {active = false, endsAt = 0, orders = 0, day = 0}
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	shiftState[player] = nil
end)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

-- Count completed orders from XP increases. The current restaurant awards 25 XP per delivered order.
task.spawn(function()
	while true do
		task.wait(1)
		for player, state in pairs(shiftState) do
			if player.Parent and state.active then
				local remaining = math.max(0, math.ceil(state.endsAt - os.clock()))
				local leaderstats = player:FindFirstChild("leaderstats")
				local xp = leaderstats and leaderstats:FindFirstChild("XP")
				if xp then
					local marker = player:GetAttribute("ShiftXPMarker")
					if marker == nil then
						player:SetAttribute("ShiftXPMarker", xp.Value)
					else
						local delta = xp.Value - marker
						if delta >= 25 then
							local completed = math.floor(delta / 25)
							state.orders += completed
							player:SetAttribute("ShiftXPMarker", marker + completed * 25)
							if state.orders >= GOAL_ORDERS then
								local cash = leaderstats:FindFirstChild("Cash")
								if cash then cash.Value += SHIFT_REWARD end
								send(player, string.format("🏆 DAY %d COMPLETE! Goal reached: %d/%d orders. +$%d daily reward!", state.day, state.orders, GOAL_ORDERS, SHIFT_REWARD))
								state.active = false
							else
								send(player, string.format("📋 Shift progress: %d/%d orders | %ds left", state.orders, GOAL_ORDERS, remaining))
							end
						end
					end
				end

				if state.active and remaining <= 0 then
					send(player, string.format("🌙 DAY %d ENDED | Orders: %d/%d. Start another shift at the desk.", state.day, state.orders, GOAL_ORDERS))
					state.active = false
				end
			end
		end
	end
end)