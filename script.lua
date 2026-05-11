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
			task.wait(0.05)
		end
	end)
end

-- 🧠 MAX LEVELS
local MaxLevelTroops = {
	SpeakerHelicopter = 4,
}

-- 🧠 ORDER SYSTEM
local orderedTroops = {}
local troopIndex = 0
local currentTroop = 1

-- 🔥 TRACK LEVELS (simple)
local troopLevel = {}

-- ➕ ADD TROOP
local function addTroop(unit)
	if not unit then return end

	troopIndex += 1
	orderedTroops[troopIndex] = unit

	troopLevel[unit] = 1

	print("Added troop:", unit.Name)
end

-- ⚡ UPGRADE LOOP (FIXED + 1 SECOND COOLDOWN)
task.spawn(function()

	while true do

		local unit = orderedTroops[currentTroop]

		if unit and unit.Parent then

			local name = unit.Name
			local maxLevel = MaxLevelTroops[name] or math.huge

			local level = troopLevel[unit] or 1

			if level < maxLevel then

				fireRemote({
					{
						"\226\129\130#",
						unit
					}
				})

				-- ⏱️ upgrade once per second ONLY
				task.wait(1)

				-- ⚠️ still assuming success (no server feedback available)
				troopLevel[unit] = level + 1

			else
				print("Maxed:", unit.Name)
				currentTroop += 1
			end

		else
			currentTroop += 1
			task.wait(0.2)
		end

	end
end)

-- 🧠 QUEUE HANDLER
local function handleTask(taskData)

	local troopsFolder = workspace:WaitForChild("Troops")

	if taskData.position then

		local before = troopsFolder:GetChildren()

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
					if t.Name == taskData.name and not table.find(before, t) then
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

	hrp.CFrame = CFrame.new(-129.188828, 5.25753736, 131.552063)

	task.delay(1, function()
		ReplicatedStorage
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

warn("Credits To mightyducklingking!")
warn("Join The Discord!")
