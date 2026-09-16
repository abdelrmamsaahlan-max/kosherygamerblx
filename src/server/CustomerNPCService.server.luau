local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local restaurant=Workspace:WaitForChild("Restaurant",30); if not restaurant then return end
local customers=restaurant:WaitForChild("Customers",30); if not customers then return end
local function animate(model)
 local h=model:FindFirstChildOfClass("Humanoid"); if not h then return end
 local a=h:FindFirstChildOfClass("Animator") or Instance.new("Animator"); a.Parent=h
 local idle=Instance.new("Animation"); idle.AnimationId="rbxassetid://507766666"
 local walk=Instance.new("Animation"); walk.AnimationId="rbxassetid://507777826"
 local it=a:LoadAnimation(idle); it.Looped=true; it.Priority=Enum.AnimationPriority.Idle; it:Play()
 local wt=a:LoadAnimation(walk); wt.Looped=true; wt.Priority=Enum.AnimationPriority.Movement
 h.Running:Connect(function(s) if s>.5 then if not wt.IsPlaying then wt:Play(.15) end else if wt.IsPlaying then wt:Stop(.2) end end end); h.WalkSpeed=8
end
local function convert(model,index)
 if model:GetAttribute("NPCReady") then return end
 local body=model:FindFirstChild("Body"); local proxyHead=model:FindFirstChild("Head"); if not body or not proxyHead then return end
 local ok,npc=pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"),Enum.HumanoidRigType.R15) end); if not ok or not npc then return end
 for _,child in ipairs(npc:GetChildren()) do child.Parent=model end; npc:Destroy()
 local actualHead=model:FindFirstChild("Head"); if actualHead and actualHead~=proxyHead then actualHead.Name="NPCHead" end
 local h=model:FindFirstChildOfClass("Humanoid"); local root=model:FindFirstChild("HumanoidRootPart"); if not h or not root then return end
 body.Transparency=1; proxyHead.Transparency=1; body.CanCollide=false; proxyHead.CanCollide=false
 model:SetAttribute("NPCReady",true); model:PivotTo(CFrame.new(-60,2,-8)); animate(model)
 local tag=Instance.new("BillboardGui"); tag.Size=UDim2.fromOffset(150,34); tag.StudsOffset=Vector3.new(0,3.2,0); tag.AlwaysOnTop=true; tag.Parent=proxyHead
 local text=Instance.new("TextLabel"); text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1; text.Text="👤 CUSTOMER"; text.TextColor3=Color3.new(1,1,1); text.TextStrokeTransparency=.35; text.Font=Enum.Font.GothamBold; text.TextScaled=true; text.Parent=tag
 local targets={Vector3.new(-44,2,-20),Vector3.new(-40,2,-20),Vector3.new(-36,2,-20)}
 task.spawn(function() h:MoveTo(targets[index] or targets[1]); h.MoveToFinished:Wait() end)
end
local function sync()
 for _,m in ipairs(customers:GetChildren()) do
  if m:IsA("Model") and m:GetAttribute("NPCReady") then
   local root=m:FindFirstChild("HumanoidRootPart"); local body=m:FindFirstChild("Body"); local head=m:FindFirstChild("Head")
   if root and body and head then
    if (body.Position-root.Position).Magnitude>.3 then root.CFrame=CFrame.new(body.Position+Vector3.new(0,-2.2,0)) end
    body.Position=root.Position+Vector3.new(0,2.2,0); head.Position=root.Position+Vector3.new(0,4.5,0)
   end
  end
 end
end
for i,m in ipairs(customers:GetChildren()) do if m:IsA("Model") then convert(m,i) end end
customers.ChildAdded:Connect(function(c) if c:IsA("Model") then task.wait(.15); convert(c,#customers:GetChildren()) end end)
RunService.Heartbeat:Connect(sync)
local old=Workspace:FindFirstChild("WalkingCustomers"); if old then old:Destroy() end
print("CustomerNPCService: animated street-to-truck customers ready")