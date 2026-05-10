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

-- 🧠 ORDERED TROOP SYSTEM (FIX)
local orderedTroops = {}
local troopIndex = 0

local function addTroop(unit)
	if not unit then return end

	troopIndex += 1

	orderedTroops[troopIndex] = {
		unit = unit,
		lastUpgrade = 0,
		done = false
	}

	print("Added troop #", troopIndex, unit.Name)
end

-- ⚡ ORDERED UPGRADE LOOP (FIXED CORE)
task.spawn(function()

	local current = 1

	while true do

		local data = orderedTroops[current]

		if data then
			local unit = data.unit

			if unit and unit.Parent and not data.done then

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
				-- move to next troop ONLY when this one is gone/done
				data.done = true
				current += 1
			end
		end

		task.wait(0.05)
	end
end)

-- 🧠 QUEUE HANDLER
local function handleTask(taskData)

	local troopsFolder = workspace:WaitForChild("Troops")

	if taskData.position then

		local before = {}

		for _, t in ipairs(troopsFolder:GetChildren()) do
			before[t] = true
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
					if t.Name == taskData.name and not before[t] then
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
