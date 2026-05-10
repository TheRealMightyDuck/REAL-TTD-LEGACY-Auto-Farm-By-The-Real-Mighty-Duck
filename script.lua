local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

	-- 📍 PLACE
	if taskData.position then

		-- store current troops BEFORE placing
		local existingTroops = {}

		for _, troop in ipairs(troopsFolder:GetChildren()) do
			existingTroops[troop] = true
		end

		-- place troop
		fireRemote({
			{
				"\226\129\130\022",
				taskData.name,
				taskData.position,
				taskData.extra
			}
		})

		-- detect NEW troop instance
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

		return
	end
end

-- 🚶 WALK TO TELEPORT SPOT
local function walkToLobby()

	local char = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	local targetCFrame = CFrame.new(
		-129.188828, 5.25753736, 131.552063
	)

	local targetPosition = targetCFrame.Position

	humanoid:MoveTo(targetPosition)

	local reached = false

	local connection
	connection = humanoid.MoveToFinished:Connect(function(success)
		reached = true
		connection:Disconnect()
	end)

	-- fallback distance checker
	while not reached do

		if not hrp.Parent then
			break
		end

		local distance = (hrp.Position - targetPosition).Magnitude

		if distance <= 6 then
			reached = true
			if connection then
				connection:Disconnect()
			end
			break
		end

		task.wait(0.1)
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

	print("Walking to teleport")

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
