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

-- 🧠 MAX LEVEL CONFIG
local MaxLevelTroops = {
	SpeakerHelicopter = 4,
}

-- 🧠 ORDERED SYSTEM
local orderedTroops = {}
local troopIndex = 0
local currentTroop = 1

-- 🔥 STABLE PROGRESS TRACKER
local troopProgress = {} -- [unitId] = level

local function getKey(unit)
	return unit:GetDebugId()
end

local function addTroop(unit)
	if not unit then return end

	troopIndex += 1

	orderedTroops[troopIndex] = {
		unit = unit,
		lastUpgrade = 0
	}

	troopProgress[getKey(unit)] = 1

	print("Added troop #", troopIndex, unit.Name)
end

-- ⚡ UPGRADE LOOP
task.spawn(function()
	while true do

		local data = orderedTroops[currentTroop]

		if data then
			local unit = data.unit

			if unit and unit.Parent then

				local name = unit.Name
				local maxLevel = MaxLevelTroops[name] or math.huge
				local key = getKey(unit)

				local level = troopProgress[key] or 1

				-- 🔥 upgrade spam (controlled)
				if level < maxLevel then

					if tick() - data.lastUpgrade >= 0.15 then
						data.lastUpgrade = tick()

						fireRemote({
							{
								"\226\129\130#",
								unit
							}
						})

						-- ⚠️ DO NOT assume upgrade success blindly
						-- we only increment after small delay + validity check
						task.delay(0.1, function()
							if unit and unit.Parent then
								troopProgress[key] = (troopProgress[key] or 1) + 1
							end
						end)
					end

				else
					print("Maxed troop #", currentTroop, unit.Name)
					currentTroop += 1
				end

			else
				currentTroop += 1
			end
		end

		task.wait(0.05)
	end
end)

-- 🧠 QUEUE HANDLER
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
			else
				warn("Troop not found:", taskData.name)
			end
		end)
	end
end

-- 📦 CHECKS
local correctPlace = (game.PlaceId == 13775256536)
local routeExists = workspace:FindFirstChild("Route")

warn("Credits To mightyducklingking!")
warn("Join The Discord!")

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
		game:GetService("ReplicatedStorage")
			:WaitForChild("NetworkingContainer")
			:WaitForChild("DataRemote")
			:FireServer({
				{
					"\226\129\130;",
					"df63fa61-be10-46bb-83ba-ffc196b317d0"
				}
			})
	end)

else

	print("Running system")

	local Queue = {

		{
			delay = 15,
			name = "SpeakerHelicopter",
			position = Vector3.new(-77.6598, 2.3456, 95.5582),
			extra = 1
		},

		{
			delay = 61,
			name = "SpeakerHelicopter",
			position = Vector3.new(-69.3424, 2.3456, 89.4919),
			extra = 1
		}
	}

	for _, taskData in ipairs(Queue) do
		task.delay(taskData.delay, function()
			handleTask(taskData)
		end)
	end

	task.delay(20, function()
		startSkipLoop()
	end)
end
