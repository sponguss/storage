local ts = game:GetService("TweenService")
local rs = game:GetService("RunService")
local module = {}

function ProcessHuman(Human)
	-- turn "player" object into "character" if player
	if Human:IsA("Player") then
		if not Human.Character then return end
		Human = Human.Character
	end

	-- turn object into "humanoid" if not "humanoid" (usually when argument is passed in as the player's character)
	if not Human:IsA("Humanoid") then
		local lochum = Human:FindFirstChildOfClass("Humanoid")
		if lochum then
			Human = lochum
		else
			warn("Passed argument for 'Human' is not Humanoid or Character model")
		end
	end

	return Human
end

function InsertC1(motor)
	if not motor:FindFirstChild("AltC1") then
		local c1 = Instance.new("CFrameValue")
		c1.Value = motor.C1
		c1.Name = "AltC1"
		c1.Parent = motor
	end
end

function mot(pose,motor)
	return motor.AltC1.Value * pose.CFrame:Inverse()
end

function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end



-- you can pass character, player OR humanoid for "Human" argument
-- pass in "joints" argument as a dictionary (optional)
--[[

e.g.
joints = {
RightArm = RightShoulderJoint,
LeftArm = LeftShoulderJoint,
}

]]
module.Load = function(Human,KFS,joints)
	Human = ProcessHuman(Human)

	local track = {}


	-- new events
	local Played = Instance.new("BindableEvent")
	track.Played = Played.Event

	local Stopped = Instance.new("BindableEvent")
	track.Stopped = Stopped.Event

	local MarkerReached = Instance.new("BindableEvent")
	track.MarkerReached = MarkerReached.Event

	track.IsPlaying = false
	
	if not joints then
		joints = {}
	end
	
	
	
	
	local function findmotor(pose)
		
		if joints[pose.Name] then -- return motor from joints table if found
			return joints[pose.Name]
		elseif joints[pose.Name] ~= nil then
			return nil
		end
		
		for _, motor in pairs(Human.Parent:GetDescendants()) do -- search anim model's descendants for a potential motor6d
			if motor:IsA("Motor6D") and motor.Part1 and motor.Part1.Name == pose.Name then
				joints[pose.Name] = motor
				return motor
			end
		end
		if pose.Name ~= "AnimBase" then
			warn("Didn't find motor for "..pose.Name..", keyframes for this pose are excluded.")
		end
		joints[pose.Name] = false -- non-nil false value
		return nil
	end
	
	
	
	-- used for :Pose(), recursive
	local function playpose(pose,t)
		if pose.Weight > 0 and pose.Name ~= "AnimBase" then
			local motor = findmotor(pose)
			if motor then

				if t > 0 then
					if pose.EasingStyle.Name == "Constant" then
						task.delay(t,function()
							motor.C1 = mot(pose,motor)
						end)
						
					else
						local easingstyle = Enum.EasingStyle[pose.EasingStyle.Name]
						local easingdirection = Enum.EasingDirection[pose.EasingDirection.Name]

						ts:Create(motor,TweenInfo.new(t,easingstyle,easingdirection),{
							C1 = mot(pose,motor)
						}):Play() -- used to be Transform = pose.CFrame
					end
					
				else
					motor.C1 = mot(pose,motor)
				end


			end
		end

		for i,pose2 in pairs(pose:GetChildren()) do
			if pose2:IsA("Pose") then
				playpose(pose2,t)
			end
		end
	end
	
	
	
	-- used for :Play(), non-recursive
	local function playpose2(pose,nextpose,t)
		if nextpose.Weight <= 0 or nextpose.Name == "AnimBase" then
			return
		end
		local motor = findmotor(nextpose)
		if not motor then return end
		
		if pose.EasingStyle.Name == "Constant" then
			task.delay(t,function()
				motor.C1 = mot(nextpose,motor)
			end)

		else
			local easingstyle = Enum.EasingStyle[pose.EasingStyle.Name]
			local easingdirection = Enum.EasingDirection[pose.EasingDirection.Name]

			ts:Create(motor,TweenInfo.new(t,easingstyle,easingdirection),{
				C1 = mot(nextpose,motor)
			}):Play() -- used to be Transform = pose.CFrame
		end

	end
	
	local function lockpose(pose)
		if pose.Weight <= 0 or pose.Name == "AnimBase" then
			return
		end
		local motor = findmotor(pose)
		if not motor then return end
		
		motor.C1 = mot(pose,motor)
	end
	
	
	
	local function ScreenMotors(pose)
		local motor = findmotor(pose)
		if motor then
			InsertC1(motor)
		end

		for i,pose2 in pairs(pose:GetChildren()) do
			if pose2:IsA("Pose") then
				ScreenMotors(pose2)
			end
		end
	end



	local function playframe(keyframe,t)
		local pose = keyframe:FindFirstChildOfClass("Pose")
		if not pose then return end
		playpose(pose,t)
	end

	local function playmarker(keyframe)
		local marker = keyframe:FindFirstChildOfClass("KeyframeMarker")
		if not marker then return end
		MarkerReached:Fire(marker.Name,marker.Value)
	end
	
	
	
	local oldframes = KFS:GetChildren()
	local frames = {}
	
	
	
	-- ordering keyframe table by time
	local loop = true
	while loop do

		local min = oldframes[1].Time
		local index = 1

		for i, keyframe in pairs(oldframes) do
			local pose = keyframe:FindFirstChildOfClass("Pose")
			if pose then
				ScreenMotors(pose)
			end
			
			if min > keyframe.Time then
				min = keyframe.Time
				index = i
			end
		end

		table.insert(frames,oldframes[index])
		table.remove(oldframes,index)

		if #oldframes == 0 then
			oldframes = nil
			loop = false
		end
	end
	
	
	
	
	
	local poses = {}
	
	local function recursive(pose,kf)
		if not poses[pose.Name] then
			poses[pose.Name] = {t = 1, poses = {}}
		end
		table.insert(poses[pose.Name].poses,{kf.Time,pose})
		
		for i,pose2 in pairs(pose:GetChildren()) do
			if pose2:IsA("Pose") then
				recursive(pose2,kf)
			end
		end
	end
	
	for i, keyframe in pairs(frames) do
		local pose = keyframe:FindFirstChildOfClass("Pose")
		if pose then
			recursive(pose,keyframe)
		end
		
		local marker = keyframe:FindFirstChildOfClass("KeyframeMarker")
		if marker then
			if not poses.KeyframeMarker then
				poses.KeyframeMarker = {t = 1, markers = {}}
			end
			
			table.insert(poses.KeyframeMarker.markers,{keyframe.Time,marker})
		end
	end
	
	local function resetPoses()
		for i,v in pairs(poses) do
			v.t = 1
		end
	end

	
	

	
	local function OnPlayed()
		if track.IsPlaying then
			track.IsPlaying = false
			Played:Fire()
			Stopped:Fire()
		end
	end

	function track:Play()
		
		coroutine.wrap(function()
			track.IsPlaying = true
			local t = 0
			local endtime = frames[#frames].Time
			
			resetPoses()
			
			while track.IsPlaying do
				
				if t >= endtime then
					if KFS.Loop then
						resetPoses()
						t = 0
					else
						break
					end
				end
				
				for i,v in pairs(poses) do
					if i == "KeyframeMarker" then
						if v.t <= #v.markers and t >= v.markers[v.t][1] then
							local marker = v.markers[v.t][2]
							v.t = v.t + 1
							MarkerReached:Fire(marker.Name,marker.Value)
						end
					else
						if v.t < #v.poses and t >= v.poses[v.t][1] then
							local pose = v.poses[v.t][2]
							local nextpose = v.poses[v.t+1][2]
							if t == 0 then
								lockpose(pose)
							end
							playpose2(pose,nextpose,v.poses[v.t+1][1] - t)
							v.t = v.t + 1
						end
					end
				end
				
				t = t + rs.Heartbeat:Wait()
			end
			
			OnPlayed()
		end)()
	end
	
	function track:Pose(initial,t)
		coroutine.wrap(function()
			track.IsPlaying = true
			
			for part, cf in pairs(initial) do
				joints[part].AltC1.Value = cf
			end
			
			playframe(frames[1],t)
			task.wait(t)
			
			OnPlayed()
		end)()
	end

	function track:Stop()
		track.IsPlaying = false
		playframe(frames[#frames],0)
		Stopped:Fire()
	end
	
	function track:Stop2()
		track.IsPlaying = false
		Stopped:Fire()
	end

	return track
end



return module
