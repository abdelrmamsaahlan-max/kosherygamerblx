local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("EgyptianFoodMap", 30)
if not map then return end

local function findTruck()
	return map:FindFirstChild("FoodTruck")
end

local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, collide: boolean?, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = collide ~= false
	part.Material = material
	part.Color = color
	if shape then part.Shape = shape end
	part.Parent = parent
	return part
end

local function addText(part: BasePart, text: string, face: Enum.NormalId, textColor: Color3, bg: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TextDisplay"
	gui.Face = face
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = bg or Color3.fromRGB(25, 25, 28)
	label.BackgroundTransparency = bg and 0 or 0.08
	label.Text = text
	label.TextColor3 = textColor
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
end

local function addFoodDisplay(parent: Instance, position: Vector3, foodName: string)
	local model = Instance.new("Model")
	model.Name = foodName
	model.Parent = parent

	local plate = makePart(model, "Plate", Vector3.new(3.8, 0.25, 3.8), CFrame.new(position), Color3.fromRGB(245,245,240), Enum.Material.SmoothPlastic, false, Enum.PartType.Cylinder)
	local foodColor = foodName == "Koshary" and Color3.fromRGB(165,95,38) or foodName == "Falafel" and Color3.fromRGB(115,70,30) or Color3.fromRGB(120,78,35)
	local food = makePart(model, "Food", Vector3.new(2.7,1.15,2.7), CFrame.new(position + Vector3.new(0,0.65,0)), foodColor, Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)

	if foodName == "Koshary" then
		for i = 1, 7 do
			makePart(model, "CrispyOnion_"..i, Vector3.new(.38,.18,.55), CFrame.new(position + Vector3.new((i-4)*.32,1.22,((i%3)-1)*.35)), Color3.fromRGB(225,175,88), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
		end
	end
	if foodName == "Falafel" then
		for i = 1, 5 do
			makePart(model, "FalafelBall_"..i, Vector3.new(.55,.55,.55), CFrame.new(position + Vector3.new((i-3)*.48,1.05,((i%2)-.5)*.5)), Color3.fromRGB(104,61,25), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
		end
	end
	if foodName == "Ful" then
		for i = 1, 6 do
			makePart(model, "Bean_"..i, Vector3.new(.34,.28,.34), CFrame.new(position + Vector3.new((i-3.5)*.35,1.08,((i%3)-1)*.3)), Color3.fromRGB(124,79,35), Enum.Material.SmoothPlastic, false, Enum.PartType.Ball)
		end
	end

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(130,32)
	label.StudsOffset = Vector3.new(0,2.1,0)
	label.AlwaysOnTop = true
	label.Parent = plate
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1,1)
	t.BackgroundTransparency = 1
	t.Text = foodName
	t.TextColor3 = Color3.new(1,1,1)
	t.TextStrokeTransparency = .35
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = label
end

local function makeHumanoidNPC(name: string, position: Vector3, role: string): Model?
	local description = Instance.new("HumanoidDescription")
	local ok, npc = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not npc then
		warn("NPCService: failed to create " .. name)
		return nil
	end

	npc.Name = name
	npc.Parent = Workspace
	npc:PivotTo(CFrame.new(position))
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then npc:Destroy(); return nil end

	humanoid.DisplayName = role
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.WalkSpeed = role == "Chef" and 7 or 8

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local idle = Instance.new("Animation")
	idle.AnimationId = "rbxassetid://507766666"
	local walk = Instance.new("Animation")
	walk.AnimationId = "rbxassetid://507777826"
	local idleTrack = animator:LoadAnimation(idle)
	idleTrack.Looped = true
	idleTrack.Priority = Enum.AnimationPriority.Idle
	idleTrack:Play()
	local walkTrack = animator:LoadAnimation(walk)
	walkTrack.Looped = true
	walkTrack.Priority = Enum.AnimationPriority.Movement
	humanoid.Running:Connect(function(speed)
		if speed > .5 then
			if not walkTrack.IsPlaying then walkTrack:Play(.15) end
		else
			if walkTrack.IsPlaying then walkTrack:Stop(.2) end
		end
	end)

	local head = npc:FindFirstChild("Head")
	if head then
		local tag = Instance.new("BillboardGui")
		tag.Name = "RoleTag"
		tag.Size = UDim2.fromOffset(150,42)
		tag.StudsOffset = Vector3.new(0,3.2,0)
		tag.AlwaysOnTop = true
		tag.Parent = head
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1,1)
		text.BackgroundTransparency = 1
		text.Text = role == "Chef" and "👨‍🍳 CHEF" or "👤 CUSTOMER"
		text.TextColor3 = role == "Chef" and Color3.fromRGB(255,210,110) or Color3.new(1,1,1)
		text.TextStrokeTransparency = .35
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = tag
	end
	return npc
end

local function setupTruck()
	local truck = findTruck()
	if not truck then return end
	if truck:FindFirstChild("PremiumTruckBuild") then return end

	local build = Instance.new("Folder")
	build.Name = "PremiumTruckBuild"
	build.Parent = truck

	-- Main premium shell: the existing MapBuilder truck stays underneath this detailed skin.
	makePart(build,"MainBody",Vector3.new(18,6,8),CFrame.new(-36,5,-27),Color3.fromRGB(168,38,34),Enum.Material.SmoothPlastic)
	makePart(build,"LowerBody",Vector3.new(18,.55,8.2),CFrame.new(-36,2.25,-27),Color3.fromRGB(28,29,32),Enum.Material.Metal)
	makePart(build,"Roof",Vector3.new(18,.55,8.2),CFrame.new(-36,8.05,-27),Color3.fromRGB(25,26,29),Enum.Material.Metal)
	makePart(build,"FrontCab",Vector3.new(6,5.6,7.7),CFrame.new(-28.9,5,-27),Color3.fromRGB(35,36,40),Enum.Material.SmoothPlastic)
	makePart(build,"Windshield",Vector3.new(.12,2.4,5.6),CFrame.new(-25.82,6.1,-27),Color3.fromRGB(38,79,92),Enum.Material.Glass, false)
	makePart(build,"SideWindow",Vector3.new(2.2,2.3,.12),CFrame.new(-30.2,6.1,-30.9),Color3.fromRGB(38,79,92),Enum.Material.Glass, false)
	makePart(build,"ServingAwning",Vector3.new(11,.3,3.1),CFrame.new(-37,7.15,-31.9),Color3.fromRGB(239,228,205),Enum.Material.SmoothPlastic)

	-- Black/red trim and lights.
	makePart(build,"RedTrim",Vector3.new(17,.22,.22),CFrame.new(-36,7.55,-31.1),Color3.fromRGB(255,65,48),Enum.Material.Neon, false)
	for i = 1, 5 do
		makePart(build,"AwningLight_"..i,Vector3.new(.22,.22,.22),CFrame.new(-41.5+(i-1)*2.2,6.95,-33.15),Color3.fromRGB(255,215,120),Enum.Material.Neon, false, Enum.PartType.Ball)
	end
	makePart(build,"HeadlightL",Vector3.new(.22,.75,1.2),CFrame.new(-25.8,4.1,-29.1),Color3.fromRGB(255,238,170),Enum.Material.Neon, false)
	makePart(build,"HeadlightR",Vector3.new(.22,.75,1.2),CFrame.new(-25.8,4.1,-24.9),Color3.fromRGB(255,238,170),Enum.Material.Neon, false)

	-- Large readable Egyptian food sign.
	local sign = makePart(build,"KosharySign",Vector3.new(7.2,2.3,.35),CFrame.new(-36,9.45,-27),Color3.fromRGB(32,25,25),Enum.Material.SmoothPlastic)
	addText(sign,"كُشري\nEGYPTIAN FOOD",Enum.NormalId.Front,Color3.fromRGB(255,214,125),Color3.fromRGB(46,28,27))
	local menu = makePart(build,"MenuBoard",Vector3.new(5.7,3.2,.2),CFrame.new(-41.8,5.25,-31.15),Color3.fromRGB(27,28,31),Enum.Material.SmoothPlastic)
	addText(menu,"MENU\nKOSHARY  $25\nFUL  $20\nFALAFEL  $30",Enum.NormalId.Front,Color3.fromRGB(255,218,132),Color3.fromRGB(27,28,31))

	-- Serving counter with ingredient trays.
	makePart(build,"ServingCounter",Vector3.new(11,.75,2.3),CFrame.new(-37,5.75,-32),Color3.fromRGB(86,54,35),Enum.Material.Wood)
	local trayColors = {
		Color3.fromRGB(230,196,120), Color3.fromRGB(185,120,50), Color3.fromRGB(125,72,30),
		Color3.fromRGB(210,55,45), Color3.fromRGB(75,150,70), Color3.fromRGB(236,155,45)
	}
	for i, c in ipairs(trayColors) do
		local tray = makePart(build,"IngredientTray_"..i,Vector3.new(1.45,.28,1.45),CFrame.new(-41.5+(i-1)*1.8,6.28,-32),c,Enum.Material.SmoothPlastic, false)
		tray.Shape = Enum.PartType.Cylinder
	end

	-- Open kitchen props.
	makePart(build,"KitchenCounter",Vector3.new(4,.95,2.4),CFrame.new(-44,5.45,-27),Color3.fromRGB(145,149,154),Enum.Material.Metal)
	makePart(build,"PrepCounter",Vector3.new(4,.95,2.4),CFrame.new(-37.8,5.45,-27),Color3.fromRGB(145,149,154),Enum.Material.Metal)
	makePart(build,"Stove",Vector3.new(3.3,.35,1.8),CFrame.new(-44,6.1,-27),Color3.fromRGB(35,37,40),Enum.Material.Metal)
	for i = 1, 2 do
		makePart(build,"Burner_"..i,Vector3.new(1,.12,1),CFrame.new(-44.8+(i-1)*1.6,6.32,-27),Color3.fromRGB(255,95,45),Enum.Material.Neon, false, Enum.PartType.Cylinder)
	end
	makePart(build,"Pot",Vector3.new(1.8,1.15,1.8),CFrame.new(-44,7,-27),Color3.fromRGB(85,87,90),Enum.Material.Metal, false, Enum.PartType.Cylinder)
	makePart(build,"PotLid",Vector3.new(1.55,.12,1.55),CFrame.new(-44,7.62,-27),Color3.fromRGB(115,117,120),Enum.Material.Metal, false, Enum.PartType.Cylinder)

	-- Side Egyptian flag accents.
	local flag = makePart(build,"EgyptFlag",Vector3.new(2.4,1.45,.08),CFrame.new(-30.2,3.9,-31.05),Color3.fromRGB(255,255,255),Enum.Material.SmoothPlastic, false)
	addText(flag,"🇪🇬",Enum.NormalId.Front,Color3.new(1,1,1),Color3.fromRGB(210,210,210))

	-- Wheels and hubcaps.
	for i, x in ipairs({-41.5,-30.5}) do
		for _, z in ipairs({-31.05,-22.95}) do
			local wheel = makePart(build,"Wheel_"..i.."_"..tostring(z),Vector3.new(2.1,.65,2.1),CFrame.new(x,2.2,z)*CFrame.Angles(math.rad(90),0,0),Color3.fromRGB(18,19,21),Enum.Material.Rubber, true, Enum.PartType.Cylinder)
			makePart(build,"Hub",Vector3.new(.75,.7,.75),wheel.CFrame,Color3.fromRGB(155,157,160),Enum.Material.Metal, false, Enum.PartType.Cylinder)
		end
	end

	-- Food display inside the truck.
	addFoodDisplay(build,Vector3.new(-39.5,6.65,-27),"Koshary")
	addFoodDisplay(build,Vector3.new(-35.7,6.65,-27),"Ful")
	addFoodDisplay(build,Vector3.new(-31.9,6.65,-27),"Falafel")

	local neon = makePart(build,"UnderGlow",Vector3.new(13,.12,.12),CFrame.new(-36,2.35,-31.8),Color3.fromRGB(255,65,48),Enum.Material.Neon, false)
	neon.Transparency = .15
end

setupTruck()

local staffFolder = Workspace:FindFirstChild("RestaurantStaffNPCs")
if not staffFolder then staffFolder = Instance.new("Folder"); staffFolder.Name = "RestaurantStaffNPCs"; staffFolder.Parent = Workspace end
if not staffFolder:FindFirstChild("TruckChef") then
	local chef = makeHumanoidNPC("TruckChef",Vector3.new(-41,1.5,-26),"Chef")
	if chef then
		chef.Parent = staffFolder
		task.spawn(function()
			while chef.Parent do
				for _, target in ipairs({Vector3.new(-44,1.5,-26),Vector3.new(-38,1.5,-26),Vector3.new(-35,1.5,-30)}) do
					if not chef.Parent then break end
					local humanoid = chef:FindFirstChildOfClass("Humanoid")
					if humanoid then humanoid:MoveTo(target); humanoid.MoveToFinished:Wait() end
					task.wait(1)
				end
			end
		end)
	end
end

local customerFolder = Workspace:FindFirstChild("WalkingCustomers")
if not customerFolder then customerFolder = Instance.new("Folder"); customerFolder.Name = "WalkingCustomers"; customerFolder.Parent = Workspace end
if #customerFolder:GetChildren() == 0 then
	for i = 1,3 do
		local customer = makeHumanoidNPC("WalkingCustomer_"..i,Vector3.new(-55+i*5,1.5,-17),"Customer")
		if customer then
			customer.Parent = customerFolder
			task.spawn(function()
				while customer.Parent do
					for _, target in ipairs({Vector3.new(-50,1.5,-17),Vector3.new(-43,1.5,-20),Vector3.new(-39,1.5,-29),Vector3.new(-48,1.5,-17)}) do
						if not customer.Parent then break end
						local humanoid = customer:FindFirstChildOfClass("Humanoid")
						if humanoid then humanoid:MoveTo(target); humanoid.MoveToFinished:Wait() end
						task.wait(math.random(1,3))
					end
				end
			end)
		end
	end
end

print("NPCService: premium Egyptian food truck, animated chef, customers and 3D food ready")