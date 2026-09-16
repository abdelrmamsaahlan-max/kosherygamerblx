local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")

local ORDER_TIME = 60
local QUEUE_SIZE = 3
local STARTING_CASH = 100
local XP_PER_ORDER = 25
local LEVEL_XP = {0, 100, 250, 450, 700, 1000, 1400, 1850, 2400, 3000}

local INGREDIENTS = {Rice=8,Lentils=8,Pasta=8,TomatoSauce=8,CrispyOnions=8,FavaBeans=8,OliveOil=8,Cumin=8,Lemon=8,Toppings=8,FalafelMix=8,Tahini=8}
local ORDER_TYPES = {
	Koshary={reward=25,steps={"Cook Rice","Add Lentils","Add Pasta","Add Tomato Sauce","Add Crispy Onions"}},
	Ful={reward=20,steps={"Cook Fava Beans","Add Olive Oil","Add Cumin","Add Lemon","Add Toppings"}},
	Falafel={reward=30,steps={"Mix Falafel","Shape Falafel","Fry Falafel","Prepare Tahini","Plate Falafel"}},
}
local ORDER_NAMES={"Koshary","Ful","Falafel"}
local STEP_INGREDIENT={
	["Cook Rice"]="Rice",["Add Lentils"]="Lentils",["Add Pasta"]="Pasta",["Add Tomato Sauce"]="TomatoSauce",["Add Crispy Onions"]="CrispyOnions",
	["Cook Fava Beans"]="FavaBeans",["Add Olive Oil"]="OliveOil",["Add Cumin"]="Cumin",["Add Lemon"]="Lemon",["Add Toppings"]="Toppings",
	["Mix Falafel"]="FalafelMix",["Shape Falafel"]="FalafelMix",["Fry Falafel"]="FalafelMix",["Prepare Tahini"]="Tahini",["Plate Falafel"]="Toppings",
}

local remotes=ReplicatedStorage:FindFirstChild("RestaurantRemotes") or Instance.new("Folder")
remotes.Name="RestaurantRemotes"; remotes.Parent=ReplicatedStorage
local orderStatus=remotes:FindFirstChild("OrderStatus") or Instance.new("RemoteEvent")
orderStatus.Name="OrderStatus"; orderStatus.Parent=remotes
local orderState=remotes:FindFirstChild("OrderState") or Instance.new("RemoteEvent")
orderState.Name="OrderState"; orderState.Parent=remotes

local playerOrders={}; local customers={}; local busyCustomer={}; local timerTokens={}
local map=Workspace:WaitForChild("EgyptianFoodMap",30)
local restaurant=Workspace:FindFirstChild("Restaurant") or Instance.new("Folder")
restaurant.Name="Restaurant"; restaurant.Parent=Workspace
local customerFolder=restaurant:FindFirstChild("Customers") or Instance.new("Folder")
customerFolder.Name="Customers"; customerFolder.Parent=restaurant
local npcFolder=Workspace:FindFirstChild("RestaurantStaffNPCs") or Instance.new("Folder")
npcFolder.Name="RestaurantStaffNPCs"; npcFolder.Parent=Workspace

local STREET_SPAWN=Vector3.new(-62,1.5,-18)
local QUEUE_POINTS={Vector3.new(-44,1.5,-18),Vector3.new(-40,1.5,-18),Vector3.new(-36,1.5,-18)}
local CUSTOMER_APPROACH=Vector3.new(-34,1.5,-24)
local TRUCK_EXIT=Vector3.new(-57,1.5,-18)
local COOK_POINTS={Vector3.new(-42,1.5,-27),Vector3.new(-38,1.5,-27),Vector3.new(-34,1.5,-27)}
local SERVE_POINT=Vector3.new(-35,1.5,-32)

local function getLevel(xp)
	local level=1
	for i,threshold in ipairs(LEVEL_XP) do if xp>=threshold then level=i end end
	return level
end
local function status(player,title,message) orderStatus:FireClient(player,title,message) end
local function inventorySnapshot(player)
	local inv=player:FindFirstChild("Inventory"); local result={}
	if not inv then return result end
	for name in pairs(INGREDIENTS) do local item=inv:FindFirstChild(name); result[name]=item and item.Value or 0 end
	return result
end
local function pushState(player,extra)
	local state=playerOrders[player]
	orderState:FireClient(player,{active=state~=nil,order=state and state.orderName or "No active order",step=state and state.step or 0,total=state and #ORDER_TYPES[state.orderName].steps or 0,remaining=state and math.max(0,math.ceil(state.expiresAt-os.clock())) or 0,status=state and state.status or "Take an order from the first customer",cash=player.leaderstats and player.leaderstats.Cash.Value or 0,inventory=extra and extra.inventory or inventorySnapshot(player)})
end
local function setupPlayer(player)
	local leaderstats=player:FindFirstChild("leaderstats") or Instance.new("Folder"); leaderstats.Name="leaderstats"; leaderstats.Parent=player
	local cash=leaderstats:FindFirstChild("Cash") or Instance.new("IntValue"); cash.Name="Cash"; cash.Parent=leaderstats; if cash.Value<=0 then cash.Value=STARTING_CASH end
	local level=leaderstats:FindFirstChild("Level") or Instance.new("IntValue"); level.Name="Level"; level.Parent=leaderstats
	local xp=leaderstats:FindFirstChild("XP") or Instance.new("IntValue"); xp.Name="XP"; xp.Parent=leaderstats; level.Value=getLevel(xp.Value)
	local tips=leaderstats:FindFirstChild("Tips") or Instance.new("IntValue"); tips.Name="Tips"; tips.Parent=leaderstats
	local inventory=player:FindFirstChild("Inventory") or Instance.new("Folder"); inventory.Name="Inventory"; inventory.Parent=player
	for name,amount in pairs(INGREDIENTS) do local item=inventory:FindFirstChild(name) or Instance.new("IntValue"); item.Name=name; item.Parent=inventory; if item.Value<=0 then item.Value=amount end end
	cash.Changed:Connect(function() pushState(player) end)
	xp.Changed:Connect(function() local old=level.Value; level.Value=getLevel(xp.Value); if level.Value>old then status(player,"LEVEL UP!",string.format("⭐ Restaurant Level %d reached!",level.Value)) end; pushState(player) end)
end
local function makePrompt(parent,name,action,objectText,distance,hold)
	local old=parent:FindFirstChild(name); if old then old:Destroy() end
	local prompt=Instance.new("ProximityPrompt"); prompt.Name=name; prompt.ActionText=action; prompt.ObjectText=objectText; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.HoldDuration=hold or .25; prompt.MaxActivationDistance=distance or 10; prompt.RequiresLineOfSight=false; prompt.ClickablePrompt=true; prompt:SetAttribute("EgyptianFoodPrompt",true); prompt.Parent=parent; return prompt
end
local function addBillboard(model,text)
	local head=model:FindFirstChild("Head"); if not head or not head:IsA("BasePart") then return end
	local old=head:FindFirstChild("NPCLabel"); if old then old:Destroy() end
	local gui=Instance.new("BillboardGui"); gui.Name="NPCLabel"; gui.Size=UDim2.fromOffset(190,56); gui.StudsOffset=Vector3.new(0,3.3,0); gui.AlwaysOnTop=true; gui.MaxDistance=55; gui.Parent=head
	local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundColor3=Color3.fromRGB(20,24,31); label.BackgroundTransparency=.12; label.TextColor3=Color3.fromRGB(255,255,255); label.TextStrokeTransparency=.45; label.Font=Enum.Font.GothamBold; label.TextSize=13; label.TextWrapped=true; label.Text=text; label.Parent=gui
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=label
end
local SKINS={
	{shirt=Color3.fromRGB(45,88,140),pants=Color3.fromRGB(45,48,58),skin=Color3.fromRGB(196,145,112)},
	{shirt=Color3.fromRGB(151,62,46),pants=Color3.fromRGB(55,55,60),skin=Color3.fromRGB(220,170,135)},
	{shirt=Color3.fromRGB(52,115,82),pants=Color3.fromRGB(48,52,62),skin=Color3.fromRGB(173,119,88)},
	{shirt=Color3.fromRGB(115,72,137),pants=Color3.fromRGB(42,46,58),skin=Color3.fromRGB(232,185,150)},
}
local function setPartColor(model,names,color) for _,name in ipairs(names) do local part=model:FindFirstChild(name); if part and part:IsA("BasePart") then part.Color=color end end end
local function addAccessory(model,name,size,color,offset,shape)
	local target=model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart"); if not target or not target:IsA("BasePart") then return end
	local part=Instance.new("Part"); part.Name=name; part.Size=size; part.Color=color; part.Material=Enum.Material.SmoothPlastic; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Massless=true; part.CFrame=target.CFrame*offset; part.Parent=model; if shape then part.Shape=shape end
	local weld=Instance.new("WeldConstraint"); weld.Part0=part; weld.Part1=target; weld.Parent=part
end
local function animateNPC(model,role)
	local humanoid=model:FindFirstChildOfClass("Humanoid"); if not humanoid then return end
	humanoid.WalkSpeed=role=="Chef" and 7 or 8; humanoid.JumpPower=0; humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false); humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
	local animator=humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator"); animator.Parent=humanoid
	local idle=Instance.new("Animation"); idle.AnimationId="rbxassetid://507766666"; local walk=Instance.new("Animation"); walk.AnimationId="rbxassetid://507777826"
	local idleTrack=animator:LoadAnimation(idle); idleTrack.Priority=Enum.AnimationPriority.Idle; idleTrack.Looped=true; idleTrack:Play(.15)
	local walkTrack=animator:LoadAnimation(walk); walkTrack.Priority=Enum.AnimationPriority.Movement; walkTrack.Looped=true
	humanoid.Running:Connect(function(speed) if speed>.6 then if not walkTrack.IsPlaying then walkTrack:Play(.12) end else if walkTrack.IsPlaying then walkTrack:Stop(.15) end end end)
end
local function styleCustomer(model,index)
	local skin=SKINS[((index-1)%#SKINS)+1]
	setPartColor(model,{"Head","LeftHand","RightHand"},skin.skin); setPartColor(model,{"UpperTorso","LowerTorso","Torso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"},skin.shirt); setPartColor(model,{"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"},skin.pants)
	addAccessory(model,"HairStyle",Vector3.new(1.7,.45,1.55),Color3.fromRGB(35+(index*11)%45,25,20),CFrame.new(0,.75,0),Enum.PartType.Ball); animateNPC(model,"Customer"); model:SetAttribute("NPCType","Customer")
end
local function styleChef(model)
	setPartColor(model,{"Head","LeftHand","RightHand"},Color3.fromRGB(207,157,122)); setPartColor(model,{"UpperTorso","LowerTorso","Torso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm"},Color3.fromRGB(239,239,235)); setPartColor(model,{"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"},Color3.fromRGB(55,58,65))
	addAccessory(model,"ChefHat",Vector3.new(1.7,.8,1.7),Color3.fromRGB(248,248,244),CFrame.new(0,1.05,0),Enum.PartType.Ball); addAccessory(model,"Apron",Vector3.new(1.8,1.7,.16),Color3.fromRGB(44,48,56),CFrame.new(0,-.15,-.72)); animateNPC(model,"Chef"); model:SetAttribute("NPCType","Chef"); addBillboard(model,"👨‍🍳 CHEF\nWorking the truck")
end
local function createRig(name,position,role,index)
	local description=Instance.new("HumanoidDescription"); local skin=SKINS[((index-1)%#SKINS)+1]
	description.HeadColor=skin.skin; description.LeftArmColor=skin.skin; description.RightArmColor=skin.skin; description.LeftLegColor=skin.pants; description.RightLegColor=skin.pants; description.TorsoColor=skin.shirt; description.HeightScale=.98+((index%3)*.03); description.WidthScale=.92+((index%2)*.04)
	local ok,model=pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15) end); if not ok or not model then warn("EgyptianFood: NPC rig creation failed for "..name); return nil end
	model.Name=name; model.Parent=role=="Customer" and customerFolder or npcFolder; model:PivotTo(CFrame.new(position))
	for _,obj in ipairs(model:GetDescendants()) do if obj:IsA("BasePart") then obj.CanCollide=false; obj.CanTouch=false; obj.CastShadow=true end end
	if role=="Customer" then styleCustomer(model,index) else styleChef(model) end
	return model
end
local function walkNPC(model,target,timeout)
	local humanoid=model and model:FindFirstChildOfClass("Humanoid"); local root=model and model:FindFirstChild("HumanoidRootPart"); if not humanoid or not root then return false end
	local started=os.clock(); humanoid:MoveTo(target)
	while model.Parent and os.clock()-started<(timeout or 8) do if (root.Position-target).Magnitude<=2.5 then return true end task.wait(.25); if os.clock()-started>6 then humanoid:MoveTo(target) end end
	return (root.Position-target).Magnitude<=3
end
local function customerText(customer,text)
	local head=customer and customer:FindFirstChild("Head"); local gui=head and head:FindFirstChild("NPCLabel"); local label=gui and gui:FindFirstChildOfClass("TextLabel"); if label then label.Text=text end
end
local function refreshQueue()
	for i,customer in ipairs(customers) do if customer and customer.Parent then task.spawn(function() walkNPC(customer,QUEUE_POINTS[i],7) end); local order=customer:GetAttribute("OrderName"); if i==1 and not order then customerText(customer,"👤 CUSTOMER\nReady to order") elseif order then customerText(customer,"🥘 "..order.."\nWaiting for food") else customerText(customer,"👤 CUSTOMER\nWaiting in line") end end end
end
local function removeCustomer(customer)
	for i,item in ipairs(customers) do if item==customer then table.remove(customers,i) break end end; busyCustomer[customer]=nil
	if customer and customer.Parent then task.spawn(function() walkNPC(customer,TRUCK_EXIT,5); task.wait(.4); customer:Destroy() end) end
end
local function attachCustomerPrompt(customer)
	local prompt=makePrompt(customer,"CustomerPrompt","Take Order","Customer",8,.2); prompt:SetAttribute("CustomerPrompt",true)
end
local function spawnCustomer()
	local index=#customers+math.random(1,100); local customer=createRig("Customer_"..index,STREET_SPAWN,"Customer",index); if not customer then return end
	customer:SetAttribute("OrderName",""); table.insert(customers,customer); addBillboard(customer,"👤 CUSTOMER\nWalking to the truck..."); attachCustomerPrompt(customer)
	task.spawn(function() walkNPC(customer,CUSTOMER_APPROACH,8); refreshQueue() end)
end
local function ensureQueue() while #customers<QUEUE_SIZE do spawnCustomer(); task.wait(.15) end refreshQueue() end
local function createFoodModel(parent,name,position,baseColor,accentColor)
	local model=Instance.new("Model"); model.Name=name; model.Parent=parent
	local plate=Instance.new("Part"); plate.Name="Plate"; plate.Shape=Enum.PartType.Cylinder; plate.Size=Vector3.new(3.2,.18,3.2); plate.Position=position; plate.Anchored=true; plate.CanCollide=false; plate.Color=Color3.fromRGB(244,241,232); plate.Parent=model
	local food=Instance.new("Part"); food.Name="Food"; food.Shape=Enum.PartType.Ball; food.Size=Vector3.new(2.3,1,2.3); food.Position=position+Vector3.new(0,.55,0); food.Anchored=true; food.CanCollide=false; food.Color=baseColor; food.Parent=model
	for i=1,5 do local garnish=Instance.new("Part"); garnish.Name="Garnish"; garnish.Shape=Enum.PartType.Ball; garnish.Size=Vector3.new(.35,.2,.35); garnish.Position=position+Vector3.new(math.cos(i*1.2)*.7,1,math.sin(i*1.2)*.7); garnish.Anchored=true; garnish.CanCollide=false; garnish.Color=accentColor; garnish.Parent=model end
end
local function setupTruck()
	if not map then return end; local truck=map:FindFirstChild("FoodTruck"); if not truck then return end
	local folder=truck:FindFirstChild("GameplayStations") or Instance.new("Folder"); folder.Name="GameplayStations"; folder.Parent=truck; for _,child in ipairs(folder:GetChildren()) do child:Destroy() end
	local function station(name,position,size,color,action,objectText,hold)
		local part=Instance.new("Part"); part.Name=name; part.Size=size; part.Position=position; part.Anchored=true; part.CanCollide=false; part.Transparency=.18; part.Material=Enum.Material.Neon; part.Color=color; part.Parent=folder
		local prompt=makePrompt(part,"ActionPrompt",action,objectText,9,hold); prompt:SetAttribute("GameplayAction",name)
	end
	station("CookStation",COOK_POINTS[2]+Vector3.new(0,1.2,0),Vector3.new(5,2.5,3),Color3.fromRGB(255,155,60),"Cook Next Step","Kitchen",.35)
	station("ServeStation",SERVE_POINT+Vector3.new(0,1.1,0),Vector3.new(6,2.2,2),Color3.fromRGB(85,185,255),"Deliver Order","Serving Counter",.25)
	local restock=map:FindFirstChild("IngredientShop") or Workspace:FindFirstChild("IngredientShop",true)
	if restock then local promptPart=restock:IsA("BasePart") and restock or restock:FindFirstChildWhichIsA("BasePart",true); if promptPart then local prompt=makePrompt(promptPart,"RestockPrompt","Restock +8","Ingredients • $20",10,.4); prompt:SetAttribute("GameplayAction","Restock") end end
	local display=truck:FindFirstChild("FoodDisplay") or Instance.new("Folder"); display.Name="FoodDisplay"; display.Parent=truck; for _,child in ipairs(display:GetChildren()) do child:Destroy() end
	createFoodModel(display,"KosharyDish",Vector3.new(-32.2,4.25,-32.8),Color3.fromRGB(165,93,44),Color3.fromRGB(222,176,87)); createFoodModel(display,"FulDish",Vector3.new(-29.5,4.25,-32.8),Color3.fromRGB(112,72,39),Color3.fromRGB(205,165,78)); createFoodModel(display,"FalafelDish",Vector3.new(-26.8,4.25,-32.8),Color3.fromRGB(132,79,38),Color3.fromRGB(75,135,78))
	local menu=truck:FindFirstChild("GameplayMenu") or Instance.new("Part"); menu.Name="GameplayMenu"; menu.Size=Vector3.new(7,3.2,.25); menu.Position=Vector3.new(-38,5.6,-30.6); menu.Anchored=true; menu.CanCollide=false; menu.Color=Color3.fromRGB(35,37,42); menu.Parent=truck
	local surface=menu:FindFirstChildOfClass("SurfaceGui") or Instance.new("SurfaceGui"); surface.Face=Enum.NormalId.Front; surface.Parent=menu
	local label=surface:FindFirstChildOfClass("TextLabel") or Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.TextColor3=Color3.fromRGB(255,222,137); label.Font=Enum.Font.GothamBlack; label.TextScaled=true; label.Text="KOSHARY  $25\nFUL  $20\nFALAFEL  $30"; label.Parent=surface
end
local function setupChef()
	if npcFolder:FindFirstChild("TruckChef") then return end; local chef=createRig("TruckChef",Vector3.new(-40,1.5,-26),"Chef",1); if not chef then return end
	local points={Vector3.new(-42,1.5,-27),Vector3.new(-38,1.5,-27),Vector3.new(-34,1.5,-27),Vector3.new(-38,1.5,-25)}
	task.spawn(function() local index=1; while chef.Parent do walkNPC(chef,points[index],7); index=index%#points+1; task.wait(.5) end end)
end
local function addXP(player,amount) local xp=player.leaderstats and player.leaderstats:FindFirstChild("XP"); if xp then xp.Value+=amount end end
local function finishOrder(player)
	local state=playerOrders[player]; if not state then status(player,"No active order","Take a customer order first"); return end; local data=ORDER_TYPES[state.orderName]
	if state.step<=#data.steps then status(player,state.orderName,"❌ Finish every cooking step first"); return end
	local remaining=math.max(0,math.ceil(state.expiresAt-os.clock())); if remaining<=0 then local customer=state.customer; playerOrders[player]=nil; status(player,"Order expired","The customer left — take the next order"); if customer then removeCustomer(customer) end; ensureQueue(); pushState(player); return end
	local cash=player.leaderstats.Cash; local bonus=player:FindFirstChild("RewardBonusPercent"); local base=data.reward; local bonusCash=bonus and math.floor(base*bonus.Value/100) or 0; local tip=remaining>=45 and 8 or remaining>=30 and 5 or remaining>=15 and 2 or 0; local stars=remaining>=45 and 5 or remaining>=30 and 4 or remaining>=15 and 3 or 2
	cash.Value+=base+bonusCash+tip; player.leaderstats.Tips.Value+=tip; addXP(player,XP_PER_ORDER)
	status(player,"Customer Satisfaction",string.format("%s • ⭐ %d/5 • +$%d",stars==5 and "Amazing service!" or stars==4 and "Great service!" or stars==3 and "Good service!" or "Slow service...",stars,tip))
	local customer=state.customer; playerOrders[player]=nil; if customer then removeCustomer(customer) end; ensureQueue(); pushState(player)
end
local function takeOrder(player,customer)
	if not customer or not customer:IsA("Model") then return end; if playerOrders[player] then status(player,"Current Order","Finish your current order first"); return end; if busyCustomer[customer] then return end; if customers[1]~=customer then status(player,"Queue","Only the first customer can order"); return end
	busyCustomer[customer]=player; local orderName=ORDER_NAMES[math.random(1,#ORDER_NAMES)]; customer:SetAttribute("OrderName",orderName); customer:SetAttribute("ClaimedBy",player.UserId)
	local state={customer=customer,orderName=orderName,step=1,expiresAt=os.clock()+ORDER_TIME,status="Order taken"}; playerOrders[player]=state
	customerText(customer,string.format("🥘 %s\nCooking for %ds",orderName,ORDER_TIME)); status(player,orderName,string.format("Order taken • 60s • Step 1/%d",#ORDER_TYPES[orderName].steps)); pushState(player)
	local token={}; timerTokens[player]=token
	task.spawn(function()
		while player.Parent and playerOrders[player]==state and timerTokens[player]==token do
			local remaining=math.max(0,math.ceil(state.expiresAt-os.clock())); if remaining<=0 then playerOrders[player]=nil; status(player,"Order expired","Customer left — the next one is ready"); removeCustomer(customer); ensureQueue(); pushState(player); break end
			state.status=string.format("Step %d/%d • %ds left",math.min(state.step,#ORDER_TYPES[orderName].steps),#ORDER_TYPES[orderName].steps,remaining); pushState(player); customerText(customer,string.format("🥘 %s\n%ds left",orderName,remaining)); task.wait(1)
		end
	end)
end
local function cookNext(player)
	local state=playerOrders[player]; if not state then status(player,"Kitchen","Take an order first"); return end; local data=ORDER_TYPES[state.orderName]; if os.clock()>=state.expiresAt then return end; if state.step>#data.steps then status(player,state.orderName,"✅ Ready! Take it to the serving counter"); return end
	local stepName=data.steps[state.step]; local ingredient=STEP_INGREDIENT[stepName]; local inv=player:FindFirstChild("Inventory"); local item=inv and inv:FindFirstChild(ingredient); if not item or item.Value<=0 then status(player,"Out of ingredients","Visit the Ingredient Shop — $20 for +8 of every ingredient"); return end
	item.Value-=1; state.step+=1; state.status=state.step>#data.steps and "Ready to deliver" or "Cooking"; status(player,state.orderName,state.step>#data.steps and "✅ Food ready — deliver it!" or string.format("🔥 %s done • Step %d/%d",stepName,state.step-1,#data.steps)); if state.customer then customerText(state.customer,state.step>#data.steps and "🥘 READY!\nBring my food!" or string.format("🥘 %s\nStep %d/%d",state.orderName,state.step,#data.steps)) end; pushState(player,{inventory=inventorySnapshot(player)})
end
local function restock(player)
	local cash=player.leaderstats and player.leaderstats:FindFirstChild("Cash"); if not cash or cash.Value<20 then status(player,"Ingredient Shop","You need $20 to restock"); return end; cash.Value-=20; local inv=player:FindFirstChild("Inventory"); if inv then for name in pairs(INGREDIENTS) do local item=inv:FindFirstChild(name); if item then item.Value+=8 end end end; status(player,"Ingredient Shop","✅ Restocked every ingredient by +8"); pushState(player,{inventory=inventorySnapshot(player)})
end
ProximityPromptService.PromptTriggered:Connect(function(prompt,player)
	if prompt:GetAttribute("CustomerPrompt") then takeOrder(player,prompt.Parent); return end
	if not prompt:GetAttribute("EgyptianFoodPrompt") then return end
	local action=prompt:GetAttribute("GameplayAction"); if action=="Restock" then restock(player) elseif action=="CookStation" then cookNext(player) elseif action=="ServeStation" then finishOrder(player) end
end)
Players.PlayerAdded:Connect(function(player) setupPlayer(player); task.defer(function() pushState(player) end) end)
Players.PlayerRemoving:Connect(function(player) local state=playerOrders[player]; if state and state.customer then removeCustomer(state.customer) end; playerOrders[player]=nil; timerTokens[player]=nil end)
for _,player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
for _,child in ipairs(customerFolder:GetChildren()) do child:Destroy() end
setupTruck(); setupChef(); ensureQueue()
print("EgyptianFood Core: rebuilt truck gameplay, animated street customers, cooking, delivery, timers, inventory and progression")