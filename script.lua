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

-- 🧠 TRACKED TROOPS TABLE
local trackedTroops = {}

local function addTroop(unit)
	if not unit then return end
	if trackedTroops[unit] then return end

	trackedTroops[unit] = {
		lastUpgrade = 0
	}
end

local function removeTroop(unit)
	trackedTroops[unit] = nil
end

-- ⚡ GLOBAL UPGRADE LOOP (THIS IS THE KEY IDEA)
task.spawn(function()
	while true do
		for unit, data in pairs(trackedTroops) do
			if unit and unit.Parent then
				-- simple throttle so it doesn’t spam too hard
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
				trackedTroops[unit] = nil
			end
		end

		task.wait(0.05)
	end
end)

-- 🧠 QUEUE HANDLER
local function handleTask(taskData)

	local troopsFolder = workspace:WaitForChild("Troops")

	-- 📍 PLACE
	if taskData.position then
		fireRemote({
			{
				"\226\129\130\022",
				taskData.name,
				taskData.position,
				taskData.extra
			}
		})

		-- 🔥 ADD TO TRACKER AFTER PLACING
		task.delay(1, function()
			local unit = troopsFolder:FindFirstChild(taskData.name)
			if unit then
				addTroop(unit)
			end
		end)

		return
	end
end

-- 📦 CHECKS
local correctPlace = (game.PlaceId == 13775256536)
local routeExists = workspace:FindFirstChild("Route")

if (not correctPlace) and (not routeExists) then
	print("Teleporting")

	local char = Player.Character or Player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	
	task.delay(1, function()
		local args = {
			{
				{
					"\226\129\130;",
					"df63fa61-be10-46bb-83ba-ffc196b317d0"
				}
			}
		}
		game:GetService("ReplicatedStorage"):WaitForChild("NetworkingContainer"):WaitForChild("DataRemote"):FireServer(unpack(args))
	end)

else
	print("Running system")

	-- 📦 QUEUE
	local Queue = {
		{delay = 15, name = "SpeakerHelicopter",
			position = Vector3.new(-77.65982055664062, 2.3456802368164062, 95.55828857421875),
			extra = 1
		},

		{delay = 35, name = "SpeakerHelicopter",
			position = Vector3.new(-69.34246063232422, 2.3456802368164062, 89.49198150634766),
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
