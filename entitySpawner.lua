if not entityTable then getgenv().entityTable={} end
return {
    createEntity=function(name)
        entityTable[name]={
            Speed=75,
            BreakLights=true,
            FlickerLenght=1,
            Model=nil,
            Height=5.2,
            Ambush={
                Enabled=false,
                MinCycles=1,
                MaxCycles=6,
                AmbienceMusic=workspace.Ambience_Ambush,
                WT_Increase=0.5,
                Speed_Increase=20
            },
            Sounds={"PlaySounds", "Footsteps"},
            WaitTime=5,
            Shaking={
                Enabled=false,
                Config={15,8.8,0,2,1,6},
                ActivateAtStuds=35
            }
        }
    end,
    runEntity=function(name)
        local entityObject=entityTable[name]
        local currentModel=entityObject.Model
        if type(entityObject.Model)=="string" then
            pcall(makefolder, "Entities")
            if not isfile("Entites/"..name..".txt") then
                writefile("Entities/"..name..".txt", game:HttpGet(entityObject.Model))
            end
            currentModel=game:GetObjects((getcustomasset or getsynasset)("Entities/"..name..".txt"))[1]
        end
        local room_l=workspace.CurrentRooms[tostring(game:GetService("ReplicatedStorage").GameData.LatestRoom.Value)]
        local room_f=(workspace.CurrentRooms:FindFirstChildOfClass("Model").Name=="0" and workspace.CurrentRooms["1"] or workspace.CurrentRooms:FindFirstChildOfClass("Model"))

        currentModel.Parent=workspace
        currentModel:FindFirstChildOfClass("Part").CanCollide=false
        if not room_f:FindFirstChild("RoomStart") then
            for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                if room:FindFirstChild("RoomStart") then room_f=room; break end
            end
        end
        currentModel:MoveTo(room_f:FindFirstChild("RoomStart").Position + Vector3.new(0,entityObject.Height,0))
        require(game.ReplicatedStorage.ClientModules.Module_Events).flickerLights(tonumber(room_l.Name), entityObject.FlickerLenght)

        if entityObject.Ambush.Enabled then
            local sounds={currentModel:FindFirstChild(entityObject.Sounds[1], true), currentModel:FindFirstChild(entityObject.Sounds[2], true)}
            sounds[1]:Play(); sounds[2]:Play()
            
            local ogVol=sounds[1].Volume
            task.wait()
            sounds[1].Volume=0
            game:GetService("TweenService"):Create(currentModel:FindFirstChild(entityObject.Sounds[1], true), TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                Volume=ogVol
            }):Play()

            local a=entityObject.Ambush.AmbienceMusic:Clone()
            a.Volume=2.3
            a.Parent=workspace
            a:Play()
            delay(10, function() a:Destroy() end)

            task.wait(entityObject.WaitTime)
           
            if entityObject.Shaking.Enabled then
                local cameraShaker = require(game.ReplicatedStorage.CameraShaker)
                local camera = workspace.CurrentCamera
    
                local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(cf)
                    camera.CFrame = camera.CFrame * cf
                end)
    
                camShake:Start()
                coroutine.create(function() 
                    while true do
                        if (currentModel:FindFirstChildOfClass("Part").Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= entityObject.Shaking.ActivateAtStuds then
                            camShake:ShakeOnce(unpack(entityObject.Shaking.Config))
                        end
                        task.wait(.2)
                    end
                end)
            end
            
            local rng=math.random(entityObject.Ambush.MinCycles, entityObject.Ambush.MaxCycles)
            local cycles=0
            repeat
                local rooms=workspace.CurrentRooms:GetChildren()
                for _, room in pairs(rooms) do
                    if not room:FindFirstChild("Nodes") or tonumber(room.Name)>tonumber(room_l.Name) then continue end
        
                    local nodes=room.Nodes:GetChildren()
                    local entityPart=currentModel:FindFirstChildOfClass("Part")
                    for _, node in pairs(nodes) do
                        local timeC = (math.abs((node.Position - entityPart.Position).Magnitude)) / entityObject.Speed
                        game:GetService("TweenService"):Create(entityPart, TweenInfo.new(timeC, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                            CFrame = CFrame.new(node.CFrame.X, node.CFrame.Y + entityObject.Height, node.CFrame.Z),
                        }):Play()
                        if entityObject.BreakLights then require(game.ReplicatedStorage.ClientModules.Module_Events).breakLights(room) end
                        task.wait(timeC)
                    end
                end
                for i=#rooms, 1, -1 do
                    local room=rooms[i]
                    if not room:FindFirstChild("Nodes") then continue end
        
                    local nodes=room.Nodes:GetChildren()
                    local entityPart=currentModel:FindFirstChildOfClass("Part")
                    for k=#nodes, 1, -1 do
                        local node=nodes[k]
                        local timeC = (math.abs((node.Position - entityPart.Position).Magnitude)) / entityObject.Speed
                        game:GetService("TweenService"):Create(entityPart, TweenInfo.new(timeC, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                            CFrame = CFrame.new(node.CFrame.X, node.CFrame.Y + entityObject.Height, node.CFrame.Z),
                        }):Play()
                        if entityObject.BreakLights then require(game.ReplicatedStorage.ClientModules.Module_Events).breakLights(room) end
                        task.wait(timeC)
                    end
                end
                cycles+=1
                entityObject.Speed+=entityObject.Ambush.Speed_Increase
                entityObject.WaitTime+=entityObject.Ambush.WT_Increase
                task.wait(entityObject.WaitTime)
            until cycles==rng
            task.wait(.5)
            currentModel:FindFirstChildOfClass("Part").Anchored=false; currentModel:FindFirstChildOfClass("Part").CanCollide=false;
            room_l:WaitForChild("Door").ClientOpen:FireServer()
            
        else
            currentModel:FindFirstChild(entityObject.Sounds[1], true):Play(); currentModel:FindFirstChild(entityObject.Sounds[2], true):Play()
            task.wait(entityObject.WaitTime)
    
            for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
                if not room:FindFirstChild("Nodes") then continue end
    
                local nodes=room.Nodes:GetChildren()
                local entityPart=currentModel:FindFirstChildOfClass("Part")
                for _, node in pairs(nodes) do
                    local timeC = (math.abs((node.Position - entityPart.Position).Magnitude)) / entityObject.Speed
                    game:GetService("TweenService"):Create(entityPart, TweenInfo.new(timeC, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                        CFrame = CFrame.new(node.CFrame.X, node.CFrame.Y + entityObject.Height, node.CFrame.Z),
                    }):Play()
                    if entityObject.BreakLights then require(game.ReplicatedStorage.ClientModules.Module_Events).breakLights(room) end
                    task.wait(timeC)
                end
                if room == room_l then
                    task.wait(.5)
                    entityPart.Anchored=false; entityPart.CanCollide=false;
                    room_l:WaitForChild("Door").ClientOpen:FireServer()
                end
            end
        end
    end
}
