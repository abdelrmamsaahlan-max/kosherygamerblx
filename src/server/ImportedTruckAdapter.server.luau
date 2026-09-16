local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("EgyptianFoodMap", 30)
if not map then return end

local function disableScripts(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") then
			obj.Disabled = true
		elseif obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanTouch = false
		end
	end
end

local function integrate(imported)
	if not imported or not imported:IsA("Model") or imported:GetAttribute("TruckIntegrated") then return end
	local placeholder = map:FindFirstChild("FoodTruck")
	local targetPivot = placeholder and placeholder:GetPivot() or CFrame.new(-35, 3, -27)
	imported:SetAttribute("TruckIntegrated", true)
	imported.Name = "FoodTruckImported"
	imported:PivotTo(targetPivot)
	disableScripts(imported)
	if placeholder and placeholder ~= imported then placeholder:Destroy() end
	local anchors = imported:FindFirstChild("GameplayAnchors") or Instance.new("Folder")
	anchors.Name = "GameplayAnchors"
	anchors.Parent = imported
	local counter = anchors:FindFirstChild("ServingCounterAnchor") or Instance.new("Part")
	counter.Name = "ServingCounterAnchor"
	counter.Size = Vector3.new(1, 1, 1)
	counter.Transparency = 1
	counter.Anchored = true
	counter.CanCollide = false
	counter.CanTouch = false
	counter.CanQuery = false
	counter.CFrame = imported:GetPivot() * CFrame.new(0, 1.5, -4)
	counter.Parent = anchors
	print("EgyptianFood ImportedTruckAdapter: integrated ImportedFoodTruck safely")
end

local function scan()
	local imported = map:FindFirstChild("ImportedFoodTruck") or Workspace:FindFirstChild("ImportedFoodTruck")
	if imported and imported:IsA("Model") then integrate(imported) end
end

scan()
map.DescendantAdded:Connect(function(child)
	if child:IsA("Model") and child.Name == "ImportedFoodTruck" then task.wait(0.25); integrate(child) end
end)
Workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child.Name == "ImportedFoodTruck" then task.wait(0.25); integrate(child) end
end)
