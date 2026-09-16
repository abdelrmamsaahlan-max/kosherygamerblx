local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("EgyptianFoodMap", 30)
if not map then return end

local function findTruck()
	return map:FindFirstChild("FoodTruck")
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
	if not humanoid then
		npc:Destroy()
		return nil
	end

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
		if speed > 0.5 then
			if not walkTrack.IsPlaying then walkTrack:Play(0.15) end
		else
			if walkTrack.IsPlaying then walkTrack:Stop(0.2) end
		end
	end)

	local tag = Instance.new("BillboardGui")
	tag.Name = "RoleTag"
	tag.Size = UDim2.fromOffset(150, 42)
	tag.StudsOffset = Vector3.new(0, 3.2, 0)
	tag.AlwaysOnTop = true
	tag.Parent = npc:FindFirstChild("Head")
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = role == "Chef" and "👨‍🍳 CHEF" or "👤 CUSTOMER"
	text.TextColor3 = role == "Chef" and Color3.fromRGB(255, 210, 110) or Color3.fromRGB(255, 255, 255)
	text.TextStrokeTransparency = 0.35
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.Parent = tag

	return npc
end

local function addFoodDisplay(parent: Instance, position: Vector3, foodName: string)
	local model = Instance.new("Model")
	model.Name = foodName
	model.Parent = parent

	local plate = Instance.new("Part")
	plate.Name = "Plate"
	plate.Shape = Enum.PartType.Cylinder
	plate.Size = Vector3.new(3.8, 0.25, 3.8)
	plate.Position = position
	plate.Anchored = true
	plate.CanCollide = false
	plate.Material = Enum.Material.SmoothPlastic
	plate.Color = Color3.fromRGB(245, 245, 240)
	plate.Parent = model

	local food = Instance.new("Part")
	food.Name = "Food"
	food.Shape = Enum.PartType.Ball
	food.Size = Vector3.new(2.7, 1.2, 2.7)
	food.Position = position + Vector3.new(0, 0.65, 0)
	food.Anchored = true
	food.CanCollide = false
	food.Material = Enum.Material.SmoothPlastic
	food.Color = foodName == "Koshary" and Color3.fromRGB(188, 116, 54) or foodName == "Falafel" and Color3.fromRGB(142, 91, 40) or Color3.fromRGB(111, 76, 42)
	food.Parent = model

	if foodName == "Koshary" then
		for i = 1, 5 do
			local onion = Instance.new("Part")
			onion.Shape = Enum.PartType.Ball
			onion.Size = Vector3.new(0.38, 0.2, 0.38)
			onion.Position = position + Vector3.new((i - 3) * 0.38, 1.25, ((i % 2) - 0.5) * 0.65)
			onion.Anchored = true
			onion.CanCollide = false
			onion.Material = Enum.Material.SmoothPlastic
			onion.Color = Color3.fromRGB(230, 205, 155)
			onion.Parent = model
		end
	end

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(130, 32)
	label.StudsOffset = Vector3.new(0, 2.1, 0)
	label.AlwaysOnTop = true
	label.Parent = plate
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = foodName
	t.TextColor3 = Color3.fromRGB(255, 255, 255)
	t.TextStrokeTransparency = 0.35
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = label
end

local function setupTruck()
	local truck = findTruck()
	if not truck then return end
	if truck:FindFirstChild("TruckInterior") then return end

	local interior = Instance.new("Folder")
	interior.Name = "TruckInterior"
	interior.Parent = truck

	local function p(name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material)
		local x = Instance.new("Part")
		x.Name = name
		x.Size = size
		x.Position = pos
		x.Anchored = true
		x.CanCollide = true
		x.Color = color
		x.Material = material
		x.Parent = interior
		return x
	end

	p("ServingCounter", Vector3.new(8, 1.2, 3), Vector3.new(-35, 5.9, -31), Color3.fromRGB(91, 58, 37), Enum.Material.Wood)
	p("KitchenCounter", Vector3.new(5, 1.4, 2.5), Vector3.new(-40, 5.8, -27), Color3.fromRGB(150, 153, 157), Enum.Material.Metal)
	p("Stove", Vector3.new(3.5, 0.5, 2), Vector3.new(-40, 6.65, -27), Color3.fromRGB(45, 47, 50), Enum.Material.Metal)
	p("HotSurface", Vector3.new(2.2, 0.15, 1.3), Vector3.new(-40, 6.95, -27), Color3.fromRGB(255, 105, 45), Enum.Material.Neon)
	p("PrepCounter", Vector3.new(4, 1.1, 2.5), Vector3.new(-34, 5.8, -27), Color3.fromRGB(150, 153, 157), Enum.Material.Metal)
	p("MenuBoard", Vector3.new(7, 3, 0.25), Vector3.new(-35, 7.1, -31), Color3.fromRGB(30, 33, 38), Enum.Material.SmoothPlastic)

	local board = interior.MenuBoard
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "KOSHARY\nFUL • FALAFEL"
	label.TextColor3 = Color3.fromRGB(255, 220, 125)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui

	addFoodDisplay(interior, Vector3.new(-35, 7.1, -27), "Koshary")
	addFoodDisplay(interior, Vector3.new(-31.5, 7.1, -27), "Ful")
	addFoodDisplay(interior, Vector3.new(-28, 7.1, -27), "Falafel")
end

local function ensureFolder(name: string): Folder
	local folder = Workspace:FindFirstChild(name)
	if folder and folder:IsA("Folder") then return folder end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = Workspace
	return f
end

setupTruck()

local staffFolder = ensureFolder("RestaurantStaffNPCs")
if not staffFolder:FindFirstChild("TruckChef") then
	local chef = makeHumanoidNPC("TruckChef", Vector3.new(-38, 1.5, -25), "Chef")
	if chef then
		chef.Parent = staffFolder
		task.spawn(function()
			while chef.Parent do
				local targets = {Vector3.new(-40, 1.5, -25), Vector3.new(-34, 1.5, -25), Vector3.new(-35, 1.5, -29)}
				for _, target in ipairs(targets) do
					if chef.Parent then
						local humanoid = chef:FindFirstChildOfClass("Humanoid")
						if humanoid then humanoid:MoveTo(target); humanoid.MoveToFinished:Wait() end
						task.wait(1)
					end
				end
			end
		end)
	end
end

local customerFolder = ensureFolder("WalkingCustomers")
if #customerFolder:GetChildren() == 0 then
	for i = 1, 3 do
		local customer = makeHumanoidNPC("WalkingCustomer_" .. i, Vector3.new(-49 + i * 5, 1.5, -18), "Customer")
		if customer then
			customer.Parent = customerFolder
			task.spawn(function()
				while customer.Parent do
					local targets = {Vector3.new(-48, 1.5, -18), Vector3.new(-35, 1.5, -18), Vector3.new(-35, 1.5, -25), Vector3.new(-45, 1.5, -18)}
					for _, target in ipairs(targets) do
						if customer.Parent then
							local humanoid = customer:FindFirstChildOfClass("Humanoid")
							if humanoid then humanoid:MoveTo(target); humanoid.MoveToFinished:Wait() end
							task.wait(math.random(1, 3))
						end
					end
				end
			end)
		end
	end
end

print("NPCService: animated customers, chef, and food truck presentation ready")