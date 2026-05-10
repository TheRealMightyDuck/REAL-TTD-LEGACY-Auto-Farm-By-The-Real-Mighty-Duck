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
			task.wait(0.1)
		end
	end)
end

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
		return
	end

	-- ⬆️ UPGRADE
	if taskData.action == "Upgrade" then
		local unit = troopsFolder:FindFirstChild(taskData.name)
		if not unit then return end

		fireRemote({
			{
				"\226\129\130#",
				unit
			}
		})
	end
end

-- 📦 CHECKS
local correctPlace = (game.PlaceId == 13775256536)
local routeExists = workspace:FindFirstChild("Route")

if (not correctPlace) and (not routeExists) then
	print("Teleporting")

	local char = Player.Character or Player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")

	hrp.CFrame = CFrame.new(
		-129.188828, 5.25753736, 131.552063,
		-0.949930847, 4.12199519e-08, 0.312460154,
		6.88082764e-08, 1, 7.72679485e-08,
		-0.312460154, 9.48990575e-08, -0.949930847
	)

else
	print("Running system")

	-- 📦 QUEUE
	local Queue = {
		{delay = 15, name = "SpeakerHelicopter",
			position = Vector3.new(-77.65982055664062, 2.3456802368164062, 95.55828857421875),
			extra = 1},
		{delay = 40, name = "SpeakerHelicopter", action = "Upgrade"},
		{delay = 82, name = "SpeakerHelicopter", action = "Upgrade"},
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
