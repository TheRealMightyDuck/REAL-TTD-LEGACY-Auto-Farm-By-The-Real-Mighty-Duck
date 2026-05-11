local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- 📡 REMOTE
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

-- 🧠 CONFIG
local MaxLevelTroops = {
	SpeakerHelicopter = 4,
}

-- 📦 QUEUE SYSTEM (SAFE)
local orderedTroops = {}
local troopLevel = {}

local DEBUG = true
local function log(...)
	if DEBUG then
		print("[DEBUG]", ...)
	end
end

-- ➕ ADD TROOP
local function addTroop(unit)
	if not unit then return end

	table.insert(orderedTroops, unit)
	troopLevel[unit] = 1

	log("Added troop:", unit.Name, "Total:", #orderedTroops)
end

-- ⚡ SAFE UPGRADE LOOP
task.spawn(function()

	local index = 1

	while true do

		local unit = orderedTroops[index]

		-- ❌ NO UNIT
		if not unit then
			log("No unit at index:", index, "waiting...")
			task.wait(0.5)
			continue
		end

		-- ❌ UNIT GONE
		if not unit.Parent then
			log("Unit removed:", unit.Name)
			index += 1
			task.wait(0.2)
			continue
		end

		local name = unit.Name
		local maxLevel = MaxLevelTroops[name] or math.huge
		local level = troopLevel[unit] or 1

		log("Checking:", name, "Level:", level, "Max:", maxLevel, "Index:", index)

		-- ✅ MAXED → NEXT UNIT
		if level >= maxLevel then
			log("MAXED:", name)
			index += 1
			task.wait(0.5)
			continue
		end

		-- 🔼 UPGRADE (ONCE PER SECOND)
		fireRemote({
			{
				"\226\129\130#",
				unit
			}
		})

		troopLevel[unit] = level + 1

		log("Upgraded:", name, "New Level:", troopLevel[unit])

		task.wait(1)
	end
end)

-- 🧠 HANDLE TASK
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
				log("Found troop:", found.Name)
				addTroop(found)
			else
				warn("[DEBUG] FAILED TO FIND TROOP:", taskData.name)
			end
		end)
	end
end

-- 📦 CHECKS
local correctPlace = (game.PlaceId == 13775256536)
local routeExists = workspace:FindFirstChild("Route")

if (not correctPlace) and (not routeExists) then

	log("Teleporting...")

	local char = Player.Character or Player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")

	hrp.CFrame = CFrame.new(-129.188828, 5.25753736, 131.552063)

	task.delay(1, function()
		fireRemote({
			{
				"\226\129\130;",
				"df63fa61-be10-46bb-83ba-ffc196b317d0"
			}
		})
	end)

else

	log("Running system")

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
