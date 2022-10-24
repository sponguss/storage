local lp=game:GetService"Players".LocalPlayer
local char=lp.Character or lp.CharacterAdded:Wait()
local hum=char:FindFirstChildOfClass("Humanoid")
local root=char.HumanoidRootPart

local DefaultConfig={
    speed = 1,
    breakLights = true,
    flickerLenght = 1,
    height = 5.2,
    ambushMechanics = {
        enabled = false,
        minimumRebounds = 1,
        maximumRebounds = 6,
        startMusic = workspace.Ambience_Ambush,
        waitTimeIncreasePerRebound = 0.5,
        speedIncreasePerRebound = 20,
    },
    sounds = { "PlaySound", "Footsteps" },
    waitTime = 5,
    shaking = {
        enabled = false,
        config = { 7.5, 15, 0.1, 1 },
        activateAtStuds = 35,
    }, 
    nextbots={
        enabled=false,
        image="nextbot.png",
        sounds={
            farSound="far.mp3",
            closeSound="close.mp3"
        }
    },
    killPlayer=false,
    entityModel=nil,
    guidingLightMessage={"Dale a tu cuerpo alegría, Macarena", "Que tu cuerpo es pa' darle alegría y cosa buena", "Dale a tu cuerpo alegría, Macarena", "Eh, Macarena (¡Ay!)"},
    code={
        onEntitySpawn=function(entityModel) end,
        onEntityConfig=function(config) end,
        onPlayerKill=function(entityModel, player) end,
        onTween=function(entityModel) end, 
        onDespawn=function(entityModel) end,
        onRebound=function(entityModel) end,
        onEntityStart=function(entityModel) end,
        onReboundFinish=function(entityModel) end
    },
    flashingLightsColor=BrickColor.Red()
}

return function(config)
    table.foreach(DefaultConfig, function(i)
        if not config[i] then 
            config[i]=DefaultConfig[i]
        end
        if type(i)=="table" then
            table.foreach(i, function(k)
                if not i[k] then
                    i[k]=DefaultConfig[i][k]
                end
            end)
        end
    end)
    config.speed=75/100*config.Speed
    config.code.onEntityConfig(config)

    pcall(writefile, "customentity.txt", game:HttpGet(config.entityModel))
    local entityModel=(game:GetObjects((type(config.entityModel)=="string" and "customentity.txt" or "rbxassetid://"..tostring(config.entityModel)))[1])

    if entityModel:IsA("BasePart") then local temp=Instance.new("Model", game:GetService("Teams")); temp.Name=entityModel.Name; entityModel.Parent=temp; entityModel=temp end
    local entityRoot=entityModel.PrimaryPart or entityModel:FindFirstAncestorWhichIsA("BasePart")
    entityRoot.Anchored=true; entityRoot.CanCollide=true;
    local event; event=game:GetService"RunService".Heartbeat:Connect(function() -- mainly skidded from vynixu's code
        if config.killPlayer and not char:GetAttribute("Hiding") then
            local found = workspace:FindPartOnRayWithIgnoreList(Ray.new(root.Position, (entityRoot.Position - root.Position).Unit * 100), { entityModel })
            if found and found:IsDescendantOf(char) then
                event:Disconnect()
                game:GetService("ReplicatedStorage").GameStats["player_"..lp.Name].Total.DeathCause=entityModel.Name
                game:GetService("ReplicatedStorage").GameStats["player_"..lp.Name].Total.DeathReason=entityModel.Name
                hum.Health = 0
                config.code.onPlayerKill(entityModel, lp)

                if #config.guidingLightMessage > 0 then
                    debug.setupvalue(getconnections(game:GetService("ReplicatedStorage").Bricks.DeathHint.OnClientEvent)[1].Function, 1, config.guidingLightMessage)
                end
            end
        end

        local mag = (root.Position - entityRoot.Position).Magnitude

        if config.shaking.config.enabled and mag <= config.shaking.config.activateAtStuds then
            config.shaking.config[1] = DefaultConfig.shaking.config[1] / config.shaking.config[3] * (config.shaking.config[3] - math.min(mag, config.shaking.config[3]))
            
            require(lp.PlayerGui.MainUI.Initiator.Main_Game).camShaker:ShakeOnce(table.unpack(config.shaking.config[2]))
        end
    end)

    local room_l = workspace.CurrentRooms[tostring(game:GetService("ReplicatedStorage").GameData.LatestRoom.Value)]
    local room_f = workspace.CurrentRooms:FindFirstChildOfClass("Model")

    if not room_f:FindFirstChild("RoomStart") then
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("RoomStart") then
                room_f = room
                break
            end
        end
    end

    entityModel.Parent=workspace
    entityModel:MoveTo(room_f.RoomStart.Position + Vector3.new(0,config.Height,0))
    config.code.onEntitySpawn(entityModel)

    require(game:GetService("ReplicatedStorage").ClientModules.Module_Events).flickerLights(room_l, config.flickerLenght)

    
    local sounds = {
        entityModel:FindFirstChild(entityModel.sounds[1], true),
        entityModel:FindFirstChild(entityModel.sounds[2], true),
    }
    sounds[1]:Play()
    sounds[2]:Play()

    if config.ambushMechanics.enabled then
        local ogVol = sounds[1].Volume
        task.wait()
        sounds[1].Volume = 0
        game:GetService("TweenService")
            :Create(
                entityModel:FindFirstChild(sounds[1], true),
                TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
                {
                    Volume = ogVol,
                }
            )
            :Play()

        local a = config.ambushMechanics.startMusic:Clone()
        a.Volume = 2.3
        a.Parent = workspace
        a.PlayOnRemove=true
        a:Destroy()
    end
    task.wait(config.waitTime)
    local random=math.random(config.ambushMechanics.minimumRebounds, config.ambushMechanics.maximumRebounds)
    local cycles=0
    config.code.onEntityStart(entityModel)
    if config.ambushMechanics.enabled then
        repeat
            local rooms = table.remove(workspace.CurrentRooms:GetChildren(), tonumber(room_l.Name)+1)
            for _, room in pairs(rooms) do
                if not room:FindFirstChild("Nodes") then continue end

                local nodes = room.Nodes:GetChildren()
                for _, node in pairs(nodes) do
                    local timeC = (math.abs((node.Position - entityRoot.Position).Magnitude)) / config.speed
                    game:GetService("TweenService")
                        :Create(
                            entityRoot,
                            TweenInfo.new(timeC, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
                            {
                                CFrame = CFrame.new(
                                    node.CFrame.X,
                                    node.CFrame.Y + config.Height,
                                    node.CFrame.Z
                                ),
                            }
                        )
                        :Play()
                        config.code.onTween(entityModel)
                    if config.breakLights then
                        require(game.ReplicatedStorage.ClientModules.Module_Events).breakLights(room)
                    end
                    task.wait(timeC)
                end
                config.code.onRebound(entityModel)
            end
            for i = #rooms, 1, -1 do
                local room = rooms[i]
                if not room:FindFirstChild("Nodes") then
                    continue
                end

                local nodes = room.Nodes:GetChildren()
                for k = #nodes, 1, -1 do
                    local node = nodes[k]
                    local timeC = (math.abs((node.Position - entityRoot.Position).Magnitude)) / config.speed
                    game:GetService("TweenService")
                        :Create(
                            entityRoot,
                            TweenInfo.new(timeC, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
                            {
                                CFrame = CFrame.new(
                                    node.CFrame.X,
                                    node.CFrame.Y + config.Height,
                                    node.CFrame.Z
                                ),
                            }
                        )
                        :Play()
                    config.code.onTween(entityModel)
                    if config.breakLights then
                        require(game.ReplicatedStorage.ClientModules.Module_Events).breakLights(room)
                    end
                    task.wait(timeC)
                end
                config.code.onReboundFinish(entityModel)
            end
            cycles += 1
            config.speed += config.ambushMechanics.speedIncreasePerRebound
            config.waitTime += config.ambushMechanics.waitTimeIncreasePerRebound
            task.wait(config.waitTime)
        until cycles == random
        task.wait(0.5)
        entityRoot.Anchored = false
        config.code.onDespawn(entityModel)
        room_l:WaitForChild("Door").ClientOpen:FireServer()
    else
        for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
            if not room:FindFirstChild("Nodes") then continue end

            local nodes = room.Nodes:GetChildren()
            for _, node in pairs(nodes) do
                local timeC = (math.abs((node.Position - entityRoot.Position).Magnitude)) / config.Speed
                game:GetService("TweenService")
                    :Create(entityRoot, TweenInfo.new(timeC, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                        CFrame = CFrame.new(node.CFrame.X, node.CFrame.Y + config.Height, node.CFrame.Z),
                    })
                    :Play()
                config.code.onTween(entityModel)
                if config.breakLights then
                    require(game.ReplicatedStorage.ClientModules.Module_Events).breakLights(room)
                end
                task.wait(timeC)
            end
            if room == room_l then
                task.wait(0.5)
                entityRoot.Anchored = false
                config.code.onDespawn(entityModel)
                room_l:WaitForChild("Door").ClientOpen:FireServer()
            end
        end
    end
end
