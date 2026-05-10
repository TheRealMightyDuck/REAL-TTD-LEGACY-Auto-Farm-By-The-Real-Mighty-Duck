local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- 🖥️ ACTIVATED GUI (ADDED INTO SYSTEM)
task.spawn(function()
	local playerGui = Player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StatusGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Parent = screenGui
	label.Size = UDim2.new(0, 200, 0, 40)
	label.Position = UDim2.new(1, -210, 0, 10)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(0, 255, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Text = "Activated"
	label.TextTransparency = 1

	for i = 1, 10 do
		label.TextTransparency -= 0.1
		task.wait(0.03)
	end
end)

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

-- 🧠 ORDERED TROOP SYSTEM
local orderedTroops = {}
local troopIndex = 0
local currentTroop = 1

local function getLevel(unit)
	local lvl = unit:FindFirstChild("TroopLevel")
	if lvl and lvl:IsA("IntValue") then
		return lvl.Value
	end
	return 1
end

local function getMaxLevel(unit)
	return MaxLevelTroops[unit.Name] or math.huge
end

local function addTroop(unit)
	if not unit then return end

	troopIndex += 1

	orderedTroops[troopIndex] = {
		unit = unit,
		lastUpgrade = 0
	}

	print("Added troop #", troopIndex, unit.Name)
end

-- ⚡ ORDERED UPGRADE LOOP
task.spawn(function()

	while true do

		local data = orderedTroops[currentTroop]

		if data then
			local unit = data.unit

			if unit and unit.Parent then

				local level = getLevel(unit)
				local maxLevel = getMaxLevel(unit)

				if tick() - data.lastUpgrade >= 0.15 then
					data.lastUpgrade = tick()

					fireRemote({
						{
							"\226\129\130#",
							unit
						}
					})
				end

				if level >= maxLevel then
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
