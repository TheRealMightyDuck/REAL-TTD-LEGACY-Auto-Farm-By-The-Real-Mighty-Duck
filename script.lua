local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- 🧠 MAX LEVELS
local MaxLevelTroops = {
	SpeakerHelicopter = 4,
}

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

-- 🧠 TRACKED TROOPS
local trackedTroops = {}

-- 📦 GET TROOP LEVEL
local function getTroopLevel(unit)
	local level = unit:FindFirstChild("TroopLevel")

	if level and level:IsA("IntValue") then
		return level.Value
	end

	return 1
end

-- 📦 GET MAX LEVEL
local function getMaxLevel(unit)
	return MaxLevelTroops[unit.Name] or 0
end

-- ➕ ADD TROOP
local function addTroop(unit)
	if not unit then return end
	if trackedTroops[unit] then return end

	table.insert(trackedTroops, unit)
end

-- ➖ REMOVE TROOP
local function removeInvalidTroops()
	for i = #trackedTroops, 1, -1 do
		local troop = trackedTroops[i]

		if not troop or not troop.Parent then
			table.remove(trackedTroops, i)
		end
	end
end

-- ⚡ AUTO UPGRADE SYSTEM
-- only upgrades the OLDEST troop until maxed,
-- then moves onto the next placed troop
task.spawn(function()
	while true do
		removeInvalidTroops()

		for i, troop in ipairs(trackedTroops) do
			if troop and troop.Parent then
				local currentLevel = getTroopLevel(troop)
				local maxLevel = getMaxLevel(troop)

				-- only upgrade if not maxed
				if currentLevel < maxLevel then

					fireRemote({
						{
							"\226\129\130#",
							troop
						}
					})

					-- wait a little before next upgrade
					task.wait(0.2)

					-- IMPORTANT:
					-- stop here so this troop gets maxed first
					break
				end
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

		-- 🔥 TRACK NEW TROOP
		task.delay(1, function()

			-- find newest troop with matching name
			local newestTroop

			for _, troop in ipairs(troopsFolder:GetChildren()) do
				if troop.Name == taskData.name then
					newestTroop = troop
				end
			end

			if newestTroop then
				addTroop(newestTroop)
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

	hrp.CFrame = CFrame.new(
		-129.188828, 5.25753736, 131.552063,
		-0.949930847, 4.12199519e-08, 0.312460154,
		6.88082764e-08, 1, 7.72679485e-08,
		-0.312460154, 9.48990575e-08, -0.949930847
	)

	task.delay(1, function()
		local args = {
			{
				{
					"\226\129\130;",
					"df63fa61-be10-46bb-83ba-ffc196b317d0"
				}
			}
		}

		game:GetService("ReplicatedStorage")
			:WaitForChild("NetworkingContainer")
			:WaitForChild("DataRemote")
			:FireServer(unpack(args))
	end)

else
	print("Running system")

	-- 📦 QUEUE
	local Queue = {

		{delay = 15, name = "SpeakerHelicopter",
			position = Vector3.new(-77.65982055664062, 2.3456802368164062, 95.55828857421875),
			extra = 1},

		{delay = 61, name = "SpeakerHelicopter",
			position = Vector3.new(-69.34246063232422, 2.3456802368164062, 89.49198150634766),
			extra = 1},
	}

	-- 🚀 RUN QUEUE
	for _, taskData in ipairs(Queue) do
		task.delay(taskData.delay, function()
			handleTask(taskData)
		end)
	end

	-- ⏱️ START SKIP LOOP
	task.delay(20, function()
		s
