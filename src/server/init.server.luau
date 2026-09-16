local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ORDER_TIME = 60
local QUEUE_SIZE = 3
local RESTOCK_COST = 20
local RESTOCK_AMOUNT = 5

local INGREDIENTS = {
	Rice = 5, Lentils = 5, Pasta = 5, TomatoSauce = 5, CrispyOnions = 5,
	FavaBeans = 5, OliveOil = 5, Cumin = 5, Lemon = 5, Toppings = 5,
	FalafelMix = 5, Tahini = 5,
}

local STEP_INGREDIENT = {
	["Cook the Rice"] = "Rice", ["Add the Lentils"] = "Lentils", ["Add the Pasta"] = "Pasta",
	["Add the Tomato Sauce"] = "TomatoSauce", ["Add Crispy Onions"] = "CrispyOnions",
	["Cook the Fava Beans"] = "FavaBeans", ["Add Olive Oil"] = "OliveOil", ["Add Cumin"] = "Cumin",
	["Add Lemon"] = "Lemon", ["Add Toppings"] = "Toppings", ["Prepare the Falafel Mix"] = "FalafelMix",
	["Shape the Falafel"] = "FalafelMix", ["Fry the Falafel"] = "FalafelMix", ["Prepare Tahini"] = "Tahini",
	["Plate the Falafel"] = "Toppings",
}

local ORDER_TYPES = {
	Koshary = {reward = 25, steps = {"Cook the Rice", "Add the Lentils", "Add the Pasta", "Add the Tomato Sauce", "Add Crispy Onions"}},
	Ful = {reward = 20, steps = {"Cook the Fava Beans", "Add Olive Oil", "Add Cumin", "Add Lemon", "Add Toppings"}},
	Falafel = {reward = 30, steps = {"Prepare the Falafel Mix", "Shape the Falafel", "Fry the Falafel", "Prepare Tahini", "Plate the Falafel"}},
}
local ORDER_NAMES = {"Koshary", "Ful", "Falafel"}
local XP_PER_ORDER = 25
local LEVEL_XP = {0, 100, 250, 450, 700, 1000, 1400, 1850, 2400, 3000}

local playerStates: {[Player]: "None" | "Ordered" | "Cooking" | "Prepared"} = {}
local cookingSteps: {[Player]: number} = {}
local activeOrders: {[Player]: {customer: Model, expiresAt: number, orderName: string}} = {}
local customersInQueue: {Model} = {}

local remotes = ReplicatedStorage:FindFirstChild("RestaurantRemotes") or Instance.new("Folder")
remotes.Name = "RestaurantRemotes"; remotes.Parent = ReplicatedStorage
local orderStatusEvent = remotes:FindFirstChild("OrderStatus") or Instance.new("RemoteEvent")
orderStatusEvent.Name = "OrderStatus"; orderStatusEvent.Parent = remotes

local function sendStatus(player: Player, order: string, status: string)
	orderStatusEvent:FireClient(player, order, status)
end

local function getLevelForXP(xp: number): number
	local level = 1
	for i = 1, #LEVEL_XP do
		if xp >= LEVEL_XP[i] then level = i end
	end
	return level
end

local function getNextLevelXP(level: number): number?
	return LEVEL_XP[level + 1]
end

local function setupLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"; leaderstats.Parent = player
	local cash = leaderstats:FindFirstChild("Cash") or Instance.new("IntValue")
	cash.Name = "Cash"; cash.Parent = leaderstats
	if cash.Value == 0 then cash.Value = 100 end
	local level = leaderstats:FindFirstChild("Level") or Instance.new("IntValue")
	level.Name = "Level"; level.Parent = leaderstats
	if level.Value < 1 then level.Value = 1 end
	local xp = leaderstats:FindFirstChild("XP") or Instance.new("IntValue")
	xp.Name = "XP"; xp.Parent = leaderstats
	local tips = leaderstats:FindFirstChild("Tips") or Instance.new("IntValue")
	tips.Name = "Tips"; tips.Parent = leaderstats
end

local function addXP(player: Player, amount: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	if not xp or not level then return end

	local oldLevel = getLevelForXP(xp.Value)
	xp.Value += amount
	local newLevel = getLevelForXP(xp.Value)
	level.Value = newLevel

	if newLevel > oldLevel then
		local nextXP = getNextLevelXP(newLevel)
		if nextXP then
			sendStatus(player, "LEVEL UP!", string.format("⭐ Restaurant Level %d! Next level at %d XP.", newLevel, nextXP))
		else
			sendStatus(player, "LEVEL UP!", string.format("⭐ Restaurant Level %d! Max progression tier reached.", newLevel))
		end
	end
end

local function setupInventory(player: Player)
	local inventory = player:FindFirstChild("Inventory") or Instance.new("Folder")
	inventory.Name = "Inventory"; inventory.Parent = player
	for name, amount in pairs(INGREDIENTS) do
		local value = inventory:FindFirstChild(name) or Instance.new("IntValue")
		value.Name = name; value.Parent = inventory
		if value.Value == 0 then value.Value = amount end
	end
end

local function inventoryText(player: Player)
	local inv = player:FindFirstChild("Inventory")
	if not inv then return "Inventory unavailable" end
	return string.format("Rice %d | Lentils %d | Pasta %d | Sauce %d | Onions %d", inv.Rice.Value, inv.Lentils.Value, inv.Pasta.Value, inv.TomatoSauce.Value, inv.CrispyOnions.Value)
end

local function getState(player: Player) return playerStates[player] or "None" end
local function getOrderData(player: Player)
	local active = activeOrders[player]
	return active and ORDER_TYPES[active.orderName], active
end

local function updateCustomerDisplay(customer: Model, text: string)
	local head = customer:FindFirstChild("Head")
	local billboard = head and head:FindFirstChild("OrderBubble")
	local label = billboard and billboard:FindFirstChild("TextLabel")
	if label and label:IsA("TextLabel") then label.Text = text end
end

local function moveCustomer(customer: Model, target: Vector3)
	local body = customer:FindFirstChild("Body"); local head = customer:FindFirstChild("Head")
	if body and body:IsA("BasePart") then body.Position = target + Vector3.new(0,2.2,0) end
	if head and head:IsA("BasePart") then head.Position = target + Vector3.new(0,4.5,0) end
end

local function createCustomer(parent: Folder, position: Vector3, index: number): Model
	local model = Instance.new("Model"); model.Name = "Customer_"..index; model.Parent = parent
	local body = Instance.new("Part"); body.Name="Body"; body.Size=Vector3.new(2.2,3,1.4); body.Position=position+Vector3.new(0,2.2,0); body.Anchored=true; body.CanCollide=false; body.Material=Enum.Material.SmoothPlastic; body.Color=Color3.fromRGB(80+math.min(index,5)*20,105,145); body.Parent=model
	local head=Instance.new("Part"); head.Name="Head"; head.Shape=Enum.PartType.Ball; head.Size=Vector3.new(1.8,1.8,1.8); head.Position=position+Vector3.new(0,4.5,0); head.Anchored=true; head.CanCollide=false; head.Material=Enum.Material.SmoothPlastic; head.Color=Color3.fromRGB(230,190,145); head.Parent=model
	local billboard=Instance.new("BillboardGui"); billboard.Name="OrderBubble"; billboard.Size=UDim2.fromOffset(220,70); billboard.StudsOffset=Vector3.new(0,3.5,0); billboard.AlwaysOnTop=true; billboard.Parent=head
	local label=Instance.new("TextLabel"); label.Name="TextLabel"; label.Size=UDim2.fromScale(1,1); label.BackgroundColor3=Color3.fromRGB(20,24,32); label.BackgroundTransparency=.08; label.TextColor3=Color3.fromRGB(255,255,255); label.Font=Enum.Font.GothamBold; label.TextSize=15; label.TextWrapped=true; label.Text="👤 Customer\nWaiting in line"; label.Parent=billboard
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=label
	return model
end

local function refreshQueueDisplays()
	for i,customer in ipairs(customersInQueue) do if customer.Parent then updateCustomerDisplay(customer, i==1 and "👤 Customer 1\nReady to order" or string.format("👤 Customer %d\nWaiting in line",i)) end end
end

local function buildQueue(parent: Folder)
	customersInQueue={}; local positions={Vector3.new(-2,0,-8),Vector3.new(-6,0,-8),Vector3.new(-10,0,-8)}
	for i=1,QUEUE_SIZE do customersInQueue[i]=createCustomer(parent,positions[i],i) end
	refreshQueueDisplays()
end

local function refillQueue(parent: Folder)
	while #customersInQueue<QUEUE_SIZE do
		local i=#customersInQueue+1; local positions={Vector3.new(-2,0,-8),Vector3.new(-6,0,-8),Vector3.new(-10,0,-8)}
		customersInQueue[i]=createCustomer(parent,positions[i],i+math.random(1,50))
	end
end

local function shiftQueue()
	local positions={Vector3.new(-2,0,-8),Vector3.new(-6,0,-8),Vector3.new(-10,0,-8)}
	for i,c in ipairs(customersInQueue) do moveCustomer(c,positions[i]) end
	refreshQueueDisplays()
end

local function removeFrontCustomer() local c=table.remove(customersInQueue,1); if c then c:Destroy() end end
local function destroyActiveCustomer(player: Player)
	local active=activeOrders[player]; if active and active.customer then active.customer:Destroy() end
	activeOrders[player]=nil; cookingSteps[player]=nil
end
local function expireOrder(player: Player)
	playerStates[player]="None"; destroyActiveCustomer(player); sendStatus(player,"No active order","Customer left — order expired")
	refillQueue(workspace.Restaurant.Customers); shiftQueue()
end
local function chooseOrder() local name=ORDER_NAMES[math.random(1,#ORDER_NAMES)]; return name,ORDER_TYPES[name] end

local function startOrder(player: Player)
	if getState(player)~="None" then sendStatus(player,"Current Order","Finish your current order first"); return false,"You already have an order in progress." end
	local restaurant=workspace:FindFirstChild("Restaurant"); local customers=restaurant and restaurant:FindFirstChild("Customers")
	if not customers or #customersInQueue==0 then return false,"No customer is waiting right now." end
	local customer=customersInQueue[1]; local name,data=chooseOrder()
	playerStates[player]="Ordered"; cookingSteps[player]=1; activeOrders[player]={customer=customer,expiresAt=os.clock()+ORDER_TIME,orderName=name}
	updateCustomerDisplay(customer,string.format("🥘 %s\nI want this!",name)); sendStatus(player,name,string.format("Order taken — ⏱ 60s • Step 1/%d",#data.steps))
	task.spawn(function()
		while player.Parent and (getState(player)=="Ordered" or getState(player)=="Cooking") do
			local active=activeOrders[player]; if not active then break end
			local remaining=math.max(0,math.ceil(active.expiresAt-os.clock())); if remaining<=0 then expireOrder(player); break end
			local d=ORDER_TYPES[active.orderName]; local step=cookingSteps[player] or 1; sendStatus(player,active.orderName,string.format("⏱ %ds left • %s",remaining,d.steps[step] or "Finish the order")); updateCustomerDisplay(customer,string.format("🥘 %s\nWaiting... %ds",active.orderName,remaining)); task.wait(1)
		end
	end)
	return true,string.format("%s order taken! Start cooking.",name)
end

local function cookOrder(player: Player)
	local state=getState(player); if state~="Ordered" and state~="Cooking" then sendStatus(player,"No active order","Take an order first"); return false,"You need to take an order first." end
	local data,active=getOrderData(player); if not data or not active or active.expiresAt<=os.clock() then expireOrder(player); return false,"The customer left because the order expired." end
	local step=cookingSteps[player] or 1; local stepName=data.steps[step]
	if stepName then
		local ingredient=STEP_INGREDIENT[stepName]; local inv=player:FindFirstChild("Inventory"); local item=inv and ingredient and inv:FindFirstChild(ingredient)
		if not item or item.Value<=0 then sendStatus(player,active.orderName,"❌ Out of "..(ingredient or "ingredients").." — visit the Ingredient Shop"); return false,"You are out of "..(ingredient or "ingredients")..". Buy a restock first." end
		item.Value-=1; playerStates[player]="Cooking"; cookingSteps[player]=step+1
		sendStatus(player,active.orderName,string.format("Cooking %d/%d: %s",step,#data.steps,stepName)); updateCustomerDisplay(active.customer,string.format("🥘 %s\nCooking %d/%d",active.orderName,step,#data.steps))
		return true,stepName.." done!"
	end
	playerStates[player]="Prepared"; sendStatus(player,active.orderName,"✅ "..active.orderName.." ready — deliver it!"); updateCustomerDisplay(active.customer,"🥘 "..active.orderName.."\nReady! Bring my food!"); return true,active.orderName.." is ready!"
end

local function getCustomerSatisfaction(remaining: number): (number, number, string)
	if remaining >= 45 then return 5, 8, "😍 Amazing service!"
	elseif remaining >= 30 then return 4, 5, "😊 Great service!"
	elseif remaining >= 15 then return 3, 2, "🙂 Good service!"
	elseif remaining > 0 then return 2, 0, "😐 That took a while..."
	else return 1, 0, "😕 Customer left unhappy."
	end
end

local function deliverOrder(player: Player)
	if getState(player)~="Prepared" then sendStatus(player,"Current Order","Finish all cooking steps first"); return false,"Finish the cooking steps first." end
	local data,active=getOrderData(player); if not data or not active then return false,"Order data is missing." end
	local remaining=math.max(0,math.ceil(active.expiresAt-os.clock()))
	if remaining<=0 then expireOrder(player); return false,"The customer left because the order expired." end
	local cash=player.leaderstats and player.leaderstats:FindFirstChild("Cash"); if not cash then return false,"Cash system is not ready." end
	local satisfaction,tip,message=getCustomerSatisfaction(remaining)
	cash.Value+=data.reward
	local tips=player.leaderstats:FindFirstChild("Tips")
	if tips then tips.Value+=tip end
	if tip>0 then cash.Value+=tip end
	addXP(player, XP_PER_ORDER)
	removeFrontCustomer(); activeOrders[player]=nil; cookingSteps[player]=nil; playerStates[player]="None"; refillQueue(workspace.Restaurant.Customers); shiftQueue()
	if tip>0 then
		sendStatus(player,"Customer Satisfaction",string.format("%s • ⭐ %d/5 • +$%d tip",message,satisfaction,tip))
	else
		sendStatus(player,"Customer Satisfaction",string.format("%s • ⭐ %d/5 • No tip",message,satisfaction))
	end
	if getLevelForXP((player.leaderstats.XP :: IntValue).Value) >= 2 then
		sendStatus(player,"Order Complete",string.format("+%d XP • +$%d reward%s • Restaurant Level %d",XP_PER_ORDER,data.reward,tip>0 and string.format(" + $%d tip",tip) or "",player.leaderstats.Level.Value))
	else
		sendStatus(player,"Order Complete",string.format("+%d XP • +$%d reward%s • %d XP to Level 2",XP_PER_ORDER,data.reward,tip>0 and string.format(" + $%d tip",tip) or "",LEVEL_XP[2] - player.leaderstats.XP.Value))
	end
	return true,string.format("%s delivered! +$%d reward%s and +%d XP.",active.orderName,data.reward,tip>0 and string.format(" + $%d tip",tip) or "",XP_PER_ORDER)
end

local function restock(player: Player)
	local cash=player.leaderstats and player.leaderstats:FindFirstChild("Cash"); local inv=player:FindFirstChild("Inventory")
	if not cash or not inv then return false,"Shop is not ready." end
	if cash.Value<RESTOCK_COST then sendStatus(player,"Ingredient Shop",string.format("Need $%d to restock",RESTOCK_COST)); return false,"You need $"..RESTOCK_COST.." to restock." end
	cash.Value-=RESTOCK_COST
	for name in pairs(INGREDIENTS) do local item=inv:FindFirstChild(name); if item then item.Value+=RESTOCK_AMOUNT end end
	sendStatus(player,"Ingredient Shop",string.format("Restocked +%d of every ingredient • -$%d",RESTOCK_AMOUNT,RESTOCK_COST)); return true,"Ingredients restocked!"
end

local function createStation(parent: Folder,name:string,position:Vector3,color:Color3,actionText:string)
	local part=Instance.new("Part"); part.Name=name; part.Size=Vector3.new(8,3,6); part.Position=position; part.Anchored=true; part.Material=Enum.Material.SmoothPlastic; part.Color=color; part.Parent=parent
	local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=actionText; prompt.ObjectText=name; prompt.HoldDuration=.5; prompt.MaxActivationDistance=10; prompt.RequiresLineOfSight=false; prompt.Parent=part; return prompt
end

local function setupRestaurant()
	local existing=workspace:FindFirstChild("Restaurant"); if existing then existing:Destroy() end
	local restaurant=Instance.new("Folder"); restaurant.Name="Restaurant"; restaurant.Parent=workspace
	local customers=Instance.new("Folder"); customers.Name="Customers"; customers.Parent=restaurant; buildQueue(customers)
	local orderPrompt=createStation(restaurant,"Order Counter",Vector3.new(0,1.5,0),Color3.fromRGB(255,205,80),"Take Order")
	local prepPrompt=createStation(restaurant,"Koshary Prep Station",Vector3.new(12,1.5,0),Color3.fromRGB(95,175,255),"Cook Step")
	local deliveryPrompt=createStation(restaurant,"Delivery Counter",Vector3.new(24,1.5,0),Color3.fromRGB(95,210,125),"Deliver Order")
	local shopPrompt=createStation(restaurant,"Ingredient Shop",Vector3.new(36,1.5,0),Color3.fromRGB(180,120,255),"Restock $20")
	orderPrompt.Triggered:Connect(function(p) local _,m=startOrder(p); print(p.Name,m) end)
	prepPrompt.Triggered:Connect(function(p) local _,m=cookOrder(p); print(p.Name,m) end)
	deliveryPrompt.Triggered:Connect(function(p) local _,m=deliverOrder(p); print(p.Name,m) end)
	shopPrompt.Triggered:Connect(function(p) local _,m=restock(p); print(p.Name,m) end)
end

local function onPlayerAdded(player: Player)
	playerStates[player]="None"; setupLeaderstats(player); setupInventory(player)
	task.defer(function() if player.Parent then sendStatus(player,"No active order",inventoryText(player).." • Customer is waiting") end end)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player) playerStates[player]=nil; destroyActiveCustomer(player) end)
for _,player in Players:GetPlayers() do task.spawn(onPlayerAdded,player) end
math.randomseed(os.time()); setupRestaurant(); print("EgyptianFood server initialized - Inventory + Progression + Satisfaction ready")