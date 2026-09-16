local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local COSTS={250,500,900}
local remotes=ReplicatedStorage:FindFirstChild("RestaurantRemotes") or Instance.new("Folder"); remotes.Name="RestaurantRemotes"; remotes.Parent=ReplicatedStorage
local status=remotes:FindFirstChild("OrderStatus") or Instance.new("RemoteEvent"); status.Name="OrderStatus"; status.Parent=remotes
local action=remotes:FindFirstChild("StaffAction") or Instance.new("RemoteEvent"); action.Name="StaffAction"; action.Parent=remotes
local function setup(player)
 local stats=player:WaitForChild("leaderstats")
 local staff=stats:FindFirstChild("Staff") or Instance.new("IntValue"); staff.Name="Staff"; staff.Parent=stats
 local tips=stats:WaitForChild("Tips"); local cash=stats:WaitForChild("Cash"); local last=tips.Value
 tips:GetPropertyChangedSignal("Value"):Connect(function() local delta=tips.Value-last; last=tips.Value; if delta>0 and staff.Value>0 then local extra=staff.Value; tips.Value+=extra; cash.Value+=extra; last=tips.Value; status:FireClient(player,"Staff Bonus",string.format("Staff helped! +$%d extra tip",extra)) end end)
end
Players.PlayerAdded:Connect(setup); for _,p in Players:GetPlayers() do task.spawn(setup,p) end
action.OnServerEvent:Connect(function(player,index)
 if typeof(index)~="number" then return end
 local stats=player:FindFirstChild("leaderstats"); local staff=stats and stats:FindFirstChild("Staff"); local cash=stats and stats:FindFirstChild("Cash"); if not staff or not cash then return end
 local nextIndex=staff.Value+1
 if index~=nextIndex then status:FireClient(player,"Workers","Hire workers in order."); return end
 local cost=COSTS[nextIndex]
 if not cost then status:FireClient(player,"Workers","You already have all 3 workers."); return end
 if cash.Value<cost then status:FireClient(player,"Workers",string.format("Need $%d to hire worker %d.",cost,nextIndex)); return end
 cash.Value-=cost; staff.Value=nextIndex
 if nextIndex==1 then status:FireClient(player,"Workers","🍽️ Waiter hired — restaurant only.") else status:FireClient(player,"Workers","👨‍🍳 Chef hired — truck + restaurant.") end
end)
local restaurant=workspace:FindFirstChild("Restaurant"); if restaurant then local desk=restaurant:FindFirstChild("Staff Desk"); if desk then desk:Destroy() end end
print("EgyptianFood - UI Staff Service ready")