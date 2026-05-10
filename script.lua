-- 🧠 MAX LEVEL CONFIG (your idea)
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

-- ⚡ FIXED ORDERED UPGRADE LOOP
task.spawn(function()

	while true do

		local data = orderedTroops[currentTroop]

		if data then
			local unit = data.unit

			if unit and unit.Parent then

				local level = getLevel(unit)
				local maxLevel = getMaxLevel(unit)

				-- 🔥 upgrade spam
				if tick() - data.lastUpgrade >= 0.15 then
					data.lastUpgrade = tick()

					fireRemote({
						{
							"\226\129\130#",
							unit
						}
					})
				end

				-- ✅ ADVANCE WHEN MAXED (THIS IS THE IMPORTANT FIX)
				if level >= maxLevel then
					print("Maxed troop #", currentTroop, unit.Name)
					currentTroop += 1
				end

			else
				-- fallback if removed / invalid
				currentTroop += 1
			end
		end

		task.wait(0.05)
	end
end)
