local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer

-- 📡 REMOTE HELPER
local function fireRemote(args)
	ReplicatedStorage
		:WaitForChild("NetworkingContainer")
		:WaitForChild("DataRemote")
		:FireServer(args)
end

-- ⏭️ SKIP
local function fireSkip()
	fireRemote({
		{
			"\226\129\130("
		}
	})
end

-- 🔁 SKIP LOOP
local skipRunning = false

local function startSkipLoop()
	if skipRunning then return end
	skipRunning = true

	task.spawn(function()
		while skipRunning do
			fireSkip()
			task.wait(0.01)
		end
	end)
end

-- 🧠 TROOP TRACKING
local trackedTroops = {}
local troopQueue = {}

local function addTroop(unit)
	if not unit then return end
	if trackedTroops[unit] then return end

	trackedTroops[unit] = true

	table.insert(troopQueue, {
		unit = unit,
		lastUpgrade = 0
	})

	print("Added troop:", unit.Name)
end

-- ⚡ ORDERED UPGRADE LOOP
task.spawn(function()

	local currentIndex = 1

	while true do

		local data = troopQueue[currentIndex]

		if data then

			local unit = data.unit

			if unit and unit.Parent then

				if tick() - data.lastUpgrade >= 0.15 then
					data.lastUpgrade = tick()

					fireRemote({
						{
							"\226\129\130#",
							unit
						}
					})
				end

			else
				print("Finished troop:", currentIndex)
				currentIndex += 1
			end
		end

		task.wait(0.05)
	end
end)

-- 🧠 PLACE + TRACK
local function handleTask(taskData)

	local troopsFolder = workspace:WaitForChild("Troops")

	if taskData.position then

		local existingTroops = {}

		for _, troop in ipairs(troopsFolder:GetChildren()) do
			existingTroops[troop] = true
		end

		-- PLACE
		fireRemote({
			{
				"\226\129\130\022",
				taskData.name,
				taskData.position,
				taskData.extra
			}
		})

		-- FIND NEW TROOP
		task.spawn(function()

			local foundTroop
			local start = tick()

			while tick() - start < 5 do

				for _, troop in ipairs(troopsFolder:GetChildren()) do

					if troop.Name == taskData.name then
						if not existingTroops[troop] then
							foundTroop = troop
							break
						end
					end
				end

				if foundTroop then
					break
				end

				task.wait(0.1)
			end

			if foundTroop then
				addTroop(foundTroop)
				print("Tracking:", foundTroop:GetFullName())
			else
				warn("Could not find troop:", taskData.name)
			end
		end)
	end
end

-- 🚶 PATHFIND TO TELEPORT
local function walkToLobby()

	local char = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	local targetPosition = Vector3.new(
		-129.188828,
		5.25753736,
		131.552063
	)

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 4
	})

	path:ComputeAsync(hrp.Position, targetPosition)

	if path.Status ~= Enum.PathStatus.Success then
		warn("Path failed")
		return
	end

	local waypoints = path:GetWaypoints()

	for _, waypoint in ipairs(waypoints) do

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end

		humanoid:MoveTo(waypoint.Position)

		local reached = humanoid.MoveToFinished:Wait()

		if not reached then
			warn("Failed reaching waypoint")
			return
		end
	end

	print("Reached teleport spot")

	task.wait(1)

	local args = {
		{
			{
				"\226\129\130;",
				"df63fa61-be10-46bb-83ba-ffc196b317d0"
			}
		}
	}

	ReplicatedStorage
		:WaitForChild("NetworkingContainer")
		:WaitForChild("DataRemote")
		:FireServer(unpack(args))
end

-- 📦 CHECKS
local correctPlace = (game.PlaceId == 13775256536)
local routeExists = workspace:FindFirstChild("Route")

if (not correctPlace) and (not routeExists) then

	print("Pathfinding to teleport")

	task.spawn(function()
		walkToLobby()
	end)

else

	print("Running system")

	-- 📦 QUEUE
	local Queue = {

		{
			delay = 15,
			name = "SpeakerHelicopter",
			position = Vector3.new(
				-77.65982055664062,
				2.3456802368164062,
				95.55828857421875
			),
			extra = 1
		},

		{
			delay = 61,
			name = "SpeakerHelicopter",
			position = Vector3.new(
				-69.34246063232422,
				2.3456802368164062,
				89.49198150634766
			),
			extra = 1
		}
	}

	-- 🚀 RUN QUEUE
	for _, taskData in ipairs(Queue) do
		task.delay(taskData.delay, function()
			handleTask(taskData)
		end)
	end

	-- ⏱️ START SKIP LOOP
	task.delay(20, function()
		startSkipLoop()
	end)
end
