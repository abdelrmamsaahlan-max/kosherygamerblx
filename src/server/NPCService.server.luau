local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("EgyptianFoodMap", 30)
if not map then return end

local TRUCK_SPAWN = Vector3.new(-62, 1.5, -12)
local TRUCK_APPROACH = Vector3.new(-48, 1.5, -18)
local TRUCK_QUEUE = {
	Vector3.new(-44, 1.5, -18),
	Vector3.new(-40, 1.5, -18),
	Vector3.new(-36, 1.5, -18),
}

local function getTruck(): Model?
	local truck = map:FindFirstChild("FoodTruck")
	return truck and truck:IsA("Model") and truck or nil
end

local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material, transparency: number?, canCollide: boolean?)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.Material = material
	part.Color = color
	part.Transparency = transparency or 0
	part.CastShadow = (transparency or 0) < 1
	part.Parent = parent
	return part
end

local function addSurfaceText(parent: BasePart, text: string, color: Color3, face: Enum.NormalId?)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 45
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.35
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui
	return gui
end

local function addFoodDish(parent: Instance, name: string, position: Vector3, scale: number, color: Color3)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local plate = makePart(model, "Plate", Vector3.new(3.1, 0.18, 3.1) * scale, position, Color3.fromRGB(245, 242, 232), Enum.Material.SmoothPlastic, 0, false)
	plate.Shape = Enum.PartType.Cylinder

	local bowl = makePart(model, "Food", Vector3.new(2.35, 0.85, 2.35) * scale, position + Vector3.new(0, 0.5 * scale, 0), color, Enum.Material.SmoothPlastic, 0, false)
	bowl.Shape = Enum.PartType.Ball

	if name == "Koshary" then
		for i = 1, 7 do
			local onion = makePart(model, "CrispyOnion", Vector3.new(0.42, 0.16, 0.42) * scale,
				position + Vector3.new(math.cos(i * 2.4) * 0.65 * scale, 0.95 * scale, math.sin(i * 2.4) * 0.65 * scale),
				Color3.fromRGB(221, 178, 102), Enum.Material.SmoothPlastic, 0, false)
			onion.Shape = Enum.PartType.Ball
		end
	elseif name == "Falafel" then
		for i = 1, 5 do
			local ball = makePart(model, "FalafelBall", Vector3.new(0.62, 0.62, 0.62) * scale,
				position + Vector3.new((i - 3) * 0.52 * scale, 0.9 * scale, (i % 2 == 0 and 0.38 or -0.32) * scale),
				Color3.fromRGB(117, 73, 36), Enum.Material.SmoothPlastic, 0, false)
			ball.Shape = Enum.PartType.Ball
		end
	end

	return model
end

local function improveTruck()
	local truck = getTruck()
	if not truck then return end
	if truck:FindFirstChild("PremiumTruckDetail") then return end

	local detail = Instance.new("Folder")
	detail.Name = "PremiumTruckDetail"
	detail.Parent = truck

	-- Serving awning and trim
	local awning = makePart(detail, "ServingAwning", Vector3.new(15, 0.35, 3.6), Vector3.new(-35, 7.1, -31.7), Color3.fromRGB(120, 28, 24), Enum.Material.SmoothPlastic)
	local awningEdge = makePart(detail, "AwningEdge", Vector3.new(15.2, 0.22, 0.28), Vector3.new(-35, 6.92, -33.45), Color3.fromRGB(241, 194, 69), Enum.Material.Metal)

	-- Roof sign
	local sign = makePart(detail, "KosheryRoofSign", Vector3.new(7.5, 2.8, 0.35), Vector3.new(-35, 8.15, -27), Color3.fromRGB(91, 18, 18), Enum.Material.SmoothPlastic)
	addSurfaceText(sign, "كشري\nEGYPTIAN FOOD", Color3.fromRGB(255, 224, 126), Enum.NormalId.Front)

	-- Stainless steel serving rail
	makePart(detail, "ServingRail", Vector3.new(14.5, 0.18, 0.18), Vector3.new(-35, 6.05, -33.1), Color3.fromRGB(225, 228, 232), Enum.Material.Metal, 0, false)

	-- Ingredient trays
	local trayColors = {
		Color3.fromRGB(242, 228, 190), Color3.fromRGB(105, 65, 36), Color3.fromRGB(218, 52, 38),
		Color3.fromRGB(214, 171, 70), Color3.fromRGB(80, 140, 72), Color3.fromRGB(235, 235, 225),
	}
	for i, color in ipairs(trayColors) do
		local x = -41.2 + (i - 1) * 2.45
		local tray = makePart(detail, "IngredientTray_" .. i, Vector3.new(2.15, 0.48, 1.7), Vector3.new(x, 6.55, -33), Color3.fromRGB(65, 68, 72), Enum.Material.Metal)
		local food = makePart(detail, "Ingredient_" .. i, Vector3.new(1.75, 0.32, 1.35), Vector3.new(x, 6.88, -33), color, Enum.Material.SmoothPlastic, 0, false)
		food.Shape = Enum.PartType.Cylinder
	end

	-- Pots and cooking equipment
	for i, x in ipairs({-42, -39.4}) do
		local pot = makePart(detail, "CookingPot_" .. i, Vector3.new(2.3, 1.25, 2.3), Vector3.new(x, 7.25, -27.1), Color3.fromRGB(72, 76, 82), Enum.Material.Metal, 0, false)
		pot.Shape = Enum.PartType.Cylinder
		local food = makePart(detail, "PotContents_" .. i, Vector3.new(1.8, 0.18, 1.8), Vector3.new(x, 7.9, -27.1), i == 1 and Color3.fromRGB(188, 105, 43) or Color3.fromRGB(107, 72, 40), Enum.Material.SmoothPlastic, 0, false)
		food.Shape = Enum.PartType.Cylinder
	end

	-- Counter display food
	addFoodDish(detail, "KosharyDisplay", Vector3.new(-35, 6.75, -33.9), 0.62, Color3.fromRGB(171, 101, 45))
	addFoodDish(detail, "FulDisplay", Vector3.new(-31.8, 6.7, -33.9), 0.58, Color3.fromRGB(116, 76, 39))
	addFoodDish(detail, "FalafelDisplay", Vector3.new(-28.7, 6.7, -33.9), 0.58, Color3.fromRGB(133, 82, 39))

	-- Condiment bottles
	for i, color in ipairs({Color3.fromRGB(210, 42, 35), Color3.fromRGB(238, 229, 196), Color3.fromRGB(72, 108, 55)}) do
		local bottle = makePart(detail, "Condiment_" .. i, Vector3.new(0.6, 1.35, 0.6), Vector3.new(-27.2 + i * 0.85, 6.75, -33.25), color, Enum.Material.SmoothPlastic, 0, false)
		bottle.Shape = Enum.PartType.Cylinder
		local cap = makePart(detail, "Cap_" .. i, Vector3.new(0.28, 0.25, 0.28), bottle.Position + Vector3.new(0, 0.78, 0), color, Enum.Material.SmoothPlastic, 0, false)
		cap.Shape = Enum.PartType.Cylinder
	end

	-- Warm work lights
	for i = 1, 5 do
		local lamp = makePart(detail, "WorkLight_" .. i, Vector3.new(0.3, 0.3, 0.3), Vector3.new(-42.2 + (i - 1) * 3.5, 7.0, -33.4), Color3.fromRGB(255, 207, 112), Enum.Material.Neon, 0, false)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 201, 110)
		light.Brightness = 1.4
		light.Range = 9
		light.Parent = lamp
	end
end

local function addAnimationController(npc: Model, role: string)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	humanoid.WalkSpeed = role == "Chef" and 6.5 or 8
	humanoid.AutoRotate = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid

	local idle = Instance.new("Animation")
	idle.AnimationId = "rbxassetid://507766666"
	local walk = Instance.new("Animation")
	walk.AnimationId = "rbxassetid://507777826"

	local idleTrack = animator:LoadAnimation(idle)
	idleTrack.Looped = true
	idleTrack.Priority = Enum.AnimationPriority.Idle
	idleTrack:Play(0.15)

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

	return humanoid
end

local function styleNPC(npc: Model, role: string, index: number)
	for _, obj in ipairs(npc:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CastShadow = true
			if obj.Name == "Torso" or obj.Name == "UpperTorso" or obj.Name == "LowerTorso" then
				obj.Color = role == "Chef" and Color3.fromRGB(235, 235, 232) or ({Color3.fromRGB(48, 86, 126), Color3.fromRGB(120, 54, 44), Color3.fromRGB(58, 112, 76)})[((index - 1) % 3) + 1]
			end
		end
	end

	local head = npc:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local tag = Instance.new("BillboardGui")
		tag.Name = "RoleTag"
		tag.Size = UDim2.fromOffset(150, 34)
		tag.StudsOffset = Vector3.new(0, 3.25, 0)
		tag.AlwaysOnTop = true
		tag.Parent = head

		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = role == "Chef" and "👨‍🍳 CHEF" or "CUSTOMER"
		text.TextColor3 = role == "Chef" and Color3.fromRGB(255, 215, 112) or Color3.fromRGB(255, 255, 255)
		text.TextStrokeTransparency = 0.3
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = tag
	end
end

local function addProxyBody(npc: Model)
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	local proxy = Instance.new("Part")
	proxy.Name = "Body"
	proxy.Size = Vector3.new(2.2, 3, 1.4)
	proxy.Transparency = 1
	proxy.CanCollide = false
	proxy.CanTouch = false
	proxy.CanQuery = false
	proxy.Massless = true
	proxy.CFrame = root.CFrame
	proxy.Parent = npc

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = proxy
	weld.Part1 = root
	weld.Parent = proxy
end

local function transformPlaceholder(placeholder: Model, index: number)
	if placeholder:GetAttribute("AnimatedNPC") then return placeholder end
	local oldPivot = placeholder:GetPivot()
	local description = Instance.new("HumanoidDescription")
	local ok, npc = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not npc then
		warn("NPCService: could not create animated customer " .. placeholder.Name)
		return placeholder
	end

	local role = "Customer"
	for _, child in ipairs(placeholder:GetChildren()) do
		child:Destroy()
	end
	for _, child in ipairs(npc:GetChildren()) do
		child.Parent = placeholder
	end
	npc:Destroy()
	placeholder:SetAttribute("AnimatedNPC", true)
	placeholder:PivotTo(oldPivot)

	local humanoid = addAnimationController(placeholder, role)
	if humanoid then
		humanoid.DisplayName = ""
	end
	addProxyBody(placeholder)
	styleNPC(placeholder, role, index)
	return placeholder
end

local function walkTo(npc: Model, target: Vector3, timeout: number)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return false end
	humanoid:MoveTo(target)
	local reached = false
	local connection = humanoid.MoveToFinished:Connect(function(ok)
		reached = ok
	end)
	local deadline = os.clock() + timeout
	while npc.Parent and os.clock() < deadline and (root.Position - target).Magnitude > 3 do
		task.wait(0.1)
	end
	connection:Disconnect()
	return reached or (root.Position - target).Magnitude <= 3
end

local function upgradeCustomerQueue()
	local restaurant = Workspace:WaitForChild("Restaurant", 15)
	if not restaurant then return end
	local customers = restaurant:WaitForChild("Customers", 15)
	if not customers then return end

	local list = customers:GetChildren()
	table.sort(list, function(a, b) return a.Name < b.Name end)
	for i, child in ipairs(list) do
		if child:IsA("Model") then
			local npc = transformPlaceholder(child, i)
			local spawn = TRUCK_SPAWN + Vector3.new(0, 0, (i - 2) * 3)
			npc:PivotTo(CFrame.new(spawn))
			task.spawn(function()
				task.wait(0.4 + i * 0.35)
				walkTo(npc, TRUCK_APPROACH, 8)
				walkTo(npc, TRUCK_QUEUE[math.clamp(i, 1, #TRUCK_QUEUE)], 8)
			end)
		end
	end
end

local function createChef()
	local folder = Workspace:FindFirstChild("RestaurantStaffNPCs")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RestaurantStaffNPCs"
		folder.Parent = Workspace
	end
	if folder:FindFirstChild("TruckChef") then return end

	local description = Instance.new("HumanoidDescription")
	local ok, chef = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not chef then return end
	chef.Name = "TruckChef"
	chef.Parent = folder
	chef:PivotTo(CFrame.new(-39, 1.5, -26))
	local humanoid = addAnimationController(chef, "Chef")
	if humanoid then humanoid.DisplayName = "" end
	styleNPC(chef, "Chef", 1)

	task.spawn(function()
		local targets = {
			Vector3.new(-41, 1.5, -27),
			Vector3.new(-37, 1.5, -27),
			Vector3.new(-33, 1.5, -27),
			Vector3.new(-36, 1.5, -29),
		}
		while chef.Parent do
			for _, target in ipairs(targets) do
				if not chef.Parent then break end
				walkTo(chef, target, 7)
				task.wait(1.5)
			end
		end
	end)
end

improveTruck()
createChef()

task.spawn(function()
	-- init.server.luau builds the Restaurant folder after the map starts.
	task.wait(2)
	upgradeCustomerQueue()
	print("NPCService: premium truck + animated street-to-truck customers ready")
end)
