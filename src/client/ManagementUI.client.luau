local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("RestaurantRemotes")
local upgradeAction = remotes:WaitForChild("UpgradeAction")
local staffAction = remotes:WaitForChild("StaffAction")
local gui = Instance.new("ScreenGui")
gui.Name = "ManagementUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local function makeButton(parent, text, pos, size)
 local b=Instance.new("TextButton"); b.Position=pos; b.Size=size; b.BackgroundColor3=Color3.fromRGB(32,40,54); b.TextColor3=Color3.fromRGB(245,247,250); b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=14; b.AutoButtonColor=false; b.Parent=parent
 local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=b
 b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(52,65,86)}):Play() end)
 b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(32,40,54)}):Play() end)
 return b
end
local bar=Instance.new("Frame"); bar.AnchorPoint=Vector2.new(.5,1); bar.Position=UDim2.new(.5,0,1,-20); bar.Size=UDim2.fromOffset(390,54); bar.BackgroundTransparency=1; bar.Parent=gui
local upgrades=makeButton(bar,"⭐ UPGRADES",UDim2.fromOffset(0,0),UDim2.fromOffset(185,50))
local workers=makeButton(bar,"👥 WORKERS",UDim2.fromOffset(195,0),UDim2.fromOffset(185,50))
local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(.5,1); panel.Position=UDim2.new(.5,0,1,-82); panel.Size=UDim2.fromOffset(420,300); panel.BackgroundColor3=Color3.fromRGB(17,21,29); panel.Visible=false; panel.Parent=gui
local pc=Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,16); pc.Parent=panel
local ps=Instance.new("UIStroke"); ps.Color=Color3.fromRGB(85,100,125); ps.Transparency=.2; ps.Parent=panel
local heading=Instance.new("TextLabel"); heading.BackgroundTransparency=1; heading.Position=UDim2.fromOffset(18,12); heading.Size=UDim2.new(1,-65,0,30); heading.Font=Enum.Font.GothamBold; heading.TextColor3=Color3.new(1,1,1); heading.TextSize=21; heading.TextXAlignment=Enum.TextXAlignment.Left; heading.Parent=panel
local close=makeButton(panel,"×",UDim2.new(1,-52,0,10),UDim2.fromOffset(38,38)); close.TextSize=22
local content=Instance.new("Frame"); content.BackgroundTransparency=1; content.Position=UDim2.fromOffset(18,55); content.Size=UDim2.new(1,-36,1,-68); content.Parent=panel
local function clear() for _,child in ipairs(content:GetChildren()) do child:Destroy() end end
local function openUpgrades()
 panel.Visible=true; heading.Text="Restaurant Upgrades"; clear(); local costs={150,300,500,750,1000}; local bonuses={10,20,30,40,50}
 for i=1,5 do local b=makeButton(content,string.format("LEVEL %d   •   $%d   •   +%d%%",i,costs[i],bonuses[i]),UDim2.fromOffset(0,(i-1)*46),UDim2.new(1,0,0,40)); b.MouseButton1Click:Connect(function() upgradeAction:FireServer(i) end) end
end
local function openWorkers()
 panel.Visible=true; heading.Text="Workers"; clear(); local costs={250,500,900}; local names={"🍽️ HIRE WAITER","👨‍🍳 HIRE CHEF","👨‍🍳 HIRE CHEF"}
 for i=1,3 do local b=makeButton(content,string.format("%s   •   $%d",names[i],costs[i]),UDim2.fromOffset(0,(i-1)*54),UDim2.new(1,0,0,46)); b.MouseButton1Click:Connect(function() staffAction:FireServer(i) end) end
 local note=Instance.new("TextLabel"); note.BackgroundTransparency=1; note.Position=UDim2.fromOffset(0,175); note.Size=UDim2.new(1,0,0,60); note.Text="Waiter: restaurant only\nChef: truck + restaurant"; note.TextColor3=Color3.fromRGB(165,178,198); note.Font=Enum.Font.Gotham; note.TextSize=13; note.TextWrapped=true; note.Parent=content
end
upgrades.MouseButton1Click:Connect(openUpgrades); workers.MouseButton1Click:Connect(openWorkers); close.MouseButton1Click:Connect(function() panel.Visible=false end)
print("ManagementUI: upgrades and workers buttons ready")