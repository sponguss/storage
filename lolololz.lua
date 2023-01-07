local model=game:GetObjects("rbxassetid://6903238241")[1]
local usedBtools={}
local waitPerPart=.1
local waitPerAction=1
local function switchBtools()
	pcall(function()
		local currentBt=game.Players.LocalPlayer.Character:FindFirstChild("Building Tools")
		table.insert(usedBtools, currentBt)
		delay(1.5, function()
			table.remove(usedBtools, table.find(usedBtools,currentBt))
		end)
		currentBt.Parent=game.Players.LocalPlayer.Backpack
	end)
	local btools=game.Players.LocalPlayer.Backpack:GetChildren()
	local bt
	repeat
		bt=btools[math.random(1,#btools)]
		task.wait()
	until bt.Name=="Building Tools" and not table.find(usedBtools,bt)
	bt.Parent=game.Players.LocalPlayer.Character
end
model:PivotTo(game.Players.LocalPlayer.Character:GetPivot())
for _, i in pairs(model:GetDescendants()) do
	if not i:IsA("BasePart") and not i:IsA("Seat") and not i:IsA("VehicleSeat") or i:IsA("MeshPart") then continue end
	task.spawn(function()
		switchBtools() 
		local invk=game:GetService("Players").LocalPlayer.Character:FindFirstChild("Building Tools").SyncAPI.ServerEndpoint
		local p=invk:InvokeServer("CreatePart", i:IsA("Seat") and "Seat" or i.ClassName=="TrussPart" and "Truss" or i.ClassName=="WedgePart" and "Wedge" or i.ClassName=="CornerWedgePart" and "Corner" or ((i.ClassName=="Part" and i.Shape==Enum.PartType.Cylinder) and "Cylinder") or i:IsA("VehicleSeat") and "Vehicle Seat" or ((i.ClassName=="Part" and i.Shape==Enum.PartType.Ball) and "Ball") or "Normal",
			i.CFrame,
			workspace:FindFirstChild("Private Building Areas")[game.Players.LocalPlayer.Name.."BuildArea"].Build
		)
		task.wait(waitPerAction)
		invk:InvokeServer("SyncResize", {{Part=p, CFrame=i.CFrame, Size=i.Size}})
		task.wait(waitPerAction)
		invk:InvokeServer("SyncColor", {{Part=p, Color=i.Color, UnionColoring=true}})
		task.wait(waitPerAction)
		invk:InvokeServer("SyncMaterial", {{Part=p, Material=i.Material}})
		task.wait(waitPerAction)
		invk:InvokeServer("SyncMaterial", {{Part=p, Transparency=i.Transparency}})
		task.wait(waitPerAction)
		invk:InvokeServer("SyncMaterial", {{Part=p, Reflectance=i.Reflectance}})
		task.wait(waitPerAction)
		invk:InvokeServer("SyncCollision", {{Part=p, CanCollide=false}})
		task.wait(waitPerAction)
		
		for _, mesh in pairs(i:GetChildren()) do
			if mesh:IsA("SpecialMesh") then
				invk:InvokeServer("CreateMeshes", {{Part=p}})
				task.wait(waitPerAction)
				task.wait(5)
				invk:InvokeServer("SyncMesh",{{MeshType=mesh.MeshType, Part=p}})
				task.wait(waitPerAction)
				invk:InvokeServer("SyncMesh",{{Scale=mesh.Scale, Part=p}})
				task.wait(waitPerAction)
				invk:InvokeServer("SyncMesh",{{Offset=mesh.Offset, Part=p}})
				task.wait(waitPerAction)
				pcall(function()
					task.wait(5)
					invk:InvokeServer("SyncMesh",{{MeshId=mesh.MeshId, Part=p}})
					task.wait(waitPerAction)
					invk:InvokeServer("SyncMesh",{{TextureID=mesh.TextureID, Part=p}})
					task.wait(waitPerAction)
				end)
			end
		end
		for _, decal in pairs(i:GetChildren()) do
			if decal.ClassName=="Decal" then
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Decal"}})
				task.wait(waitPerAction)
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Decal", Texture=decal.Texture}})
				task.wait(waitPerAction)
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Decal", Transparency=decal.Transparency}})
				task.wait(waitPerAction)
			elseif decal.ClassName=="Texture" then
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Texture"}})
				task.wait(waitPerAction)
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Texture", Texture=decal.Texture}})
				task.wait(waitPerAction)
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Texture", Transparency=decal.Transparency}})
				task.wait(waitPerAction)
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Texture", StudsPerTileU=decal.StudsPerTileU}})
				task.wait(waitPerAction)
				invk:InvokeServer("CreateTextures", {{Part=p, Face=decal.Face, TextureType="Texture", StudsPerTileV=decal.StudsPerTileV}})
				task.wait(waitPerAction)
			end
		end
		task.wait(waitPerAction)
		invk:InvokeServer("SyncCollision", {{Part=p, CanCollide=i.CanCollide}})
	end)
	task.wait(waitPerPart)
end
