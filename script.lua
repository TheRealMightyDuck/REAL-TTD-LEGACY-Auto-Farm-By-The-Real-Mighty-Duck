local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

-- 🧠 TROOP SYSTEM
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
	local i = 1

	while true do
		local data = troopQueue[i]

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
				print("Finished troop:", i)
				i += 1
			end
		end

		task.wait(0.05)
	end
end)

-- 🧠 PLACE + DETECT NEW INSTANCE
local function handleTask(taskData)

	local troopsFolder = workspace:WaitForChild("Troops")

	if taskData.position then

		local existing = {}

		for _, t in ipairs(troopsFolder:GetChildren()) do
			existing[t] = true
		end

		fireRemote({
			{
				"\226\129\130\022",
				taskData.name,
				taskData.position,
				taskData.extra
			}
		})

		task.spawn(function()

			local found
			local start = tick()

			while tick() - start < 5 do
				for _, t in ipairs(troopsFolder:GetChildren()) do
					if t.Name == taskData.name and not existing[t] then
						found = t
						break
					end
				end

				if found then break end
				task.wait(0.1)
			end

			if found then
				addTroop(found)
				print("Tracking:", found.Name)
			else
				warn("Troop not found:", taskData.name)
			end
		end)
	end
end

-- 🚶 SMOOTH WALK (NO TELEPORT / NO PATHFIND)
local function walkToLobby()

	local char = Player.Character or Player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")

	local target = Vector3.new(
		-129.188828,
		5.25753736,
		131.552063
	)

	local connection

	connection = RunService.RenderStepped:Connect(function()

		if not hrp.Parent then
			connection:Disconnect()
			return
		end

		local offset = target - hrp.Position
		local dist = offset.Magnitude

		if dist < 6 then
			connection:Disconnect()
			print("Reached spot")
			return
		end

		local dir = offset.Unit

		-- obstacle avoidance
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist
		rayParams.FilterDescendantsInstances = {char}

		local hit = workspace:Raycast(hrp.Position, dir * 5, rayParams)

		if hit then
			dir = (dir + hit.Normal * 1.8).Unit
		end

		hrp.AssemblyLinearVelocity = dir * 18
	end)

	while connection.Connected do
		task.wait(0.1)
	end

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

	print("Walking (no teleport)")

	task.spawn(function()
		walkToLobby()
	end)

else

	print("Running system")

	local Queue = {

		{
			delay = 15,
			name = "SpeakerHelicopter",
			position = Vector3.new(-77.65, 2.34, 95.55),
			extra = 1
		},

		{
			delay = 61,
			name = "SpeakerHelicopter",
			position = Vector3.new(-69.34, 2.34, 89.49),
			extra = 1
		}
	}

	for _, t in ipairs(Queue) do
		task.delay(t.delay, function()
			handleTask(t)
		end)
	end

	task.delay(20, function()
		startSkipLoop()
	end)
end
