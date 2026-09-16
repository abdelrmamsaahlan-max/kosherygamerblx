local Workspace = game:GetService("Workspace")
local SKINS = {
	{skin=Color3.fromRGB(198,145,105), shirt=Color3.fromRGB(42,82,126), pants=Color3.fromRGB(38,42,48)},
	{skin=Color3.fromRGB(224,176,132), shirt=Color3.fromRGB(148,58,46), pants=Color3.fromRGB(48,52,62)},
	{skin=Color3.fromRGB(170,112,76), shirt=Color3.fromRGB(48,116,78), pants=Color3.fromRGB(43,44,50)},
	{skin=Color3.fromRGB(236,191,150), shirt=Color3.fromRGB(202,148,50), pants=Color3.fromRGB(62,52,42)},
	{skin=Color3.fromRGB(185,128,91), shirt=Color3.fromRGB(94,65,135), pants=Color3.fromRGB(43,46,54)},
}
local function weld(npc,name,size,color,material,target,offset,shape)
	local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Color=color; p.Material=material; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.CFrame=target.CFrame*offset; p.Parent=npc
	if shape then p.Shape=shape end
	local w=Instance.new("WeldConstraint"); w.Part0=target; w.Part1=p; w.Parent=p
end
local function style(npc,index,chef)
	if npc:GetAttribute("SkinUpgraded") then return end
	local s=SKINS[((index-1)%#SKINS)+1]
	for _,o in ipairs(npc:GetDescendants()) do
		if o:IsA("BasePart") then
			o.CastShadow=true
			if o.Name=="Head" or string.find(o.Name,"Hand") or string.find(o.Name,"Foot") then o.Color=s.skin
			elseif string.find(o.Name,"Torso") then o.Color=chef and Color3.fromRGB(242,242,235) or s.shirt
			elseif string.find(o.Name,"Leg") then o.Color=chef and Color3.fromRGB(45,48,54) or s.pants end
		end
	end
	local head=npc:FindFirstChild("Head")
	local torso=npc:FindFirstChild("UpperTorso") or npc:FindFirstChild("Torso")
	if head and head:IsA("BasePart") then
		if chef then weld(npc,"ChefHat",Vector3.new(1.7,.62,1.7),Color3.fromRGB(248,248,242),Enum.Material.Fabric,head,CFrame.new(0,.78,0),Enum.PartType.Cylinder)
		else local hair={Color3.fromRGB(35,28,24),Color3.fromRGB(70,45,28),Color3.fromRGB(25,25,28),Color3.fromRGB(92,60,34)}; weld(npc,"Hair",Vector3.new(1.65,.48,1.65),hair[((index-1)%#hair)+1],Enum.Material.SmoothPlastic,head,CFrame.new(0,.62,0),Enum.PartType.Ball) end
	end
	if torso and torso:IsA("BasePart") and chef then
		weld(npc,"Apron",Vector3.new(1.7,2.25,.08),Color3.fromRGB(236,236,225),Enum.Material.Fabric,torso,CFrame.new(0,-.05,-.72))
		weld(npc,"ApronStripe",Vector3.new(1.5,.12,.1),Color3.fromRGB(205,45,38),Enum.Material.Fabric,torso,CFrame.new(0,.2,-.77))
	end
	npc:SetAttribute("SkinUpgraded",true)
end
local function animations(npc,role)
	local h=npc:FindFirstChildOfClass("Humanoid"); if not h or h:GetAttribute("WalkAnimReady") then return end
	h:SetAttribute("WalkAnimReady",true); h.WalkSpeed=role=="Chef" and 6.5 or 8; h.AutoRotate=true
	local a=h:FindFirstChildOfClass("Animator") or Instance.new("Animator",h)
	local idle=Instance.new("Animation"); idle.AnimationId="rbxassetid://507766666"
	local walk=Instance.new("Animation"); walk.AnimationId="rbxassetid://507777826"
	local it=a:LoadAnimation(idle); it.Looped=true; it.Priority=Enum.AnimationPriority.Idle; it:Play(.15)
	local wt=a:LoadAnimation(walk); wt.Looped=true; wt.Priority=Enum.AnimationPriority.Movement
	h.Running:Connect(function(speed) if speed>.5 then if not wt.IsPlaying then wt:Play(.15) end elseif wt.IsPlaying then wt:Stop(.2) end end)
end
local function process(folder,role)
	for i,npc in ipairs(folder:GetChildren()) do if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then style(npc,i,role=="Chef"); animations(npc,role) end end
end
local staff=Workspace:FindFirstChild("RestaurantStaffNPCs"); local walking=Workspace:FindFirstChild("WalkingCustomers")
if staff then process(staff,"Chef"); staff.ChildAdded:Connect(function() task.wait(.2); process(staff,"Chef") end) end
if walking then process(walking,"Customer"); walking.ChildAdded:Connect(function() task.wait(.2); process(walking,"Customer") end) end
local restaurant=Workspace:FindFirstChild("Restaurant"); local queue=restaurant and restaurant:FindFirstChild("Customers")
if queue then process(queue,"Customer"); queue.ChildAdded:Connect(function() task.wait(.2); process(queue,"Customer") end) end
print("NPCSkinUpgrade: varied customer skins + chef uniform + walking animations ready")