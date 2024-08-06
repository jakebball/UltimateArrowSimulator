local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatCalculationUtils = require(ReplicatedStorage.Shared.Utils.StatCalculationUtils)
local NumberUtils = require(ReplicatedStorage.Shared.Utils.NumberUtils)
local AttributeUtils = require(ReplicatedStorage.Shared.Utils.AttributeUtils)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)
local EnemyInfo = require(ReplicatedStorage.Shared.EnemyInfo)

local Trove = require(ReplicatedStorage.Shared.Packages.Trove)

local ShootingRange = {}

local rangeTroves = {}

local randomObject

function ShootingRange.SetupPlayer(player)
	local enemyFolder = Instance.new("Folder")
	enemyFolder.Name = "Enemies"
	enemyFolder.Parent = player
end

function ShootingRange.StartShootingRange(player, range)
	if AttributeUtils.GetAttribute(player, "ActiveRange") then
		warn("Player is already in a range")
		return
	end

	local unlockedRanges = AttributeUtils.GetAttribute(player, "unlockedRanges", {})

	if table.find(unlockedRanges, range) == nil then
		warn("Player does not own range")
		return
	end

	AttributeUtils.SetAttribute(player, "ActiveRange", range)
	AttributeUtils.SetAttribute(player, "ActiveRangeHealth", 100)
	AttributeUtils.SetAttribute(player, "ActiveRangeSpecialEnergy", 0)
	AttributeUtils.SetAttribute(player, "ActiveLaneRangeIndex", 2)
	AttributeUtils.SetAttribute(player, "RangeEnemiesDefeated", 0)

	AttributeUtils.SetAttribute(player, "rangeRandomSeed", math.random(1, 1000))

	local amountOfEnemies = RangeInfo[range].enemyKillRequirement

	randomObject = Random.new(AttributeUtils.GetAttribute(player, "rangeRandomSeed"))

	local trove = Trove.new()

	rangeTroves[player.UserId] = trove

	task.spawn(function()
		local enemyIndex = 1

		while AttributeUtils.GetAttribute(player, "ActiveRange") ~= nil and enemyIndex <= amountOfEnemies do
			local randomEnemyTypeIndex = randomObject:NextInteger(1, #RangeInfo[range].enemies)

			local enemyType = RangeInfo[range].enemies[randomEnemyTypeIndex]

			local info = EnemyInfo[range][enemyType]

			local enemyData = {
				id = enemyIndex,
				type = enemyType,
				health = randomObject:NextNumber(info.healthRange[1], info.healthRange[2]),
				damage = info.damage,
				speed = info.speed,
			}

			local healthDecrement = info.damage

			local selectedSpawn = randomObject:NextInteger(1, 3)

			local enemyObject = Instance.new("StringValue")
			enemyObject.Name = enemyIndex

			trove:Add(enemyObject)

			AttributeUtils.SetAttribute(enemyObject, "health", enemyData.health)
			AttributeUtils.SetAttribute(enemyObject, "damage", enemyData.damage)
			AttributeUtils.SetAttribute(enemyObject, "lastDamage", enemyData.speed)
			AttributeUtils.SetAttribute(enemyObject, "type", enemyData.type)
			AttributeUtils.SetAttribute(enemyObject, "selectedSpawn", selectedSpawn)

			enemyObject.Parent = player.Enemies

			enemyIndex += 1

			local timeToReachEnd = (
				workspace.ShootingRanges[range].Spawns[1].Position - workspace.ShootingRanges[range].Ends[1].Position
			).Magnitude / enemyData.speed

			trove:Add(task.delay(timeToReachEnd + 0.1, function()
				if AttributeUtils.GetAttribute(enemyObject, "health", 0) > 0 then
					AttributeUtils.IncrementAttribute(player, "ActiveRangeHealth", -healthDecrement)

					if AttributeUtils.GetAttribute(player, "ActiveRangeHealth", 0) <= 0 then
						ShootingRange.EndShootingRange(player)
					end
				end
			end))

			task.wait(randomObject:NextNumber(1, 2))
		end
	end)
end

function ShootingRange.EndShootingRange(player)
	ShootingRange.Systems.Network.GetEvent("ShootingRangeEnded"):FireClient(player)

	local rangeInfo = RangeInfo[player:GetAttribute("ActiveRange")]

	AttributeUtils.SetAttribute(player, "ActiveRange", AttributeUtils.Nil)
	AttributeUtils.SetAttribute(player, "ActiveRangeHealth", AttributeUtils.Nil)
	AttributeUtils.SetAttribute(player, "ActiveRangeSpecialEnergy", AttributeUtils.Nil)
	AttributeUtils.SetAttribute(player, "ActiveLaneRangeIndex", AttributeUtils.Nil)
	AttributeUtils.SetAttribute(player, "RangeEnemiesDefeated", AttributeUtils.Nil)

	rangeTroves[player.UserId]:Destroy()

	local selectedGrade = NumberUtils.GetWeightedRandomItem(rangeInfo.rewards.tokenGradeTable)
	local selectedRarity = NumberUtils.GetWeightedRandomItem(rangeInfo.rewards.tokenRarityTable)

	local simulationTokens = AttributeUtils.GetAttribute(player, "simulationTokens")

	if simulationTokens then
		simulationTokens[selectedRarity .. selectedGrade] += 1

		AttributeUtils.SetAttribute(player, "simulationTokens", simulationTokens)

		ShootingRange.Systems.Network.GetEvent("SendPlayerReward"):FireClient(player, {
			grade = selectedGrade,
			rarity = selectedRarity,
		})
	end
end

function ShootingRange.EnemyHit(player, enemyId, damage, energy)
	local enemyObject = player.Enemies[enemyId]

	local equippedItems = AttributeUtils.GetAttribute(player, "equippedItems", {})

	local itemInfo = ItemInfo[equippedItems.playerBowSlot]
	local enemyInfo =
		EnemyInfo[AttributeUtils.GetAttribute(player, "ActiveRange")][AttributeUtils.GetAttribute(enemyObject, "type")]

	local withinRange = false

	if
		damage >= itemInfo.damageRange[1]
		and damage <= itemInfo.damageRange[2]
		and energy >= enemyInfo.energyRange[1]
		and energy <= enemyInfo.energyRange[2]
	then
		withinRange = true
	end

	if not withinRange then
		print("hit not within range")
		return
	end

	local realDamage = StatCalculationUtils.GetTotalDamage(player, damage)

	AttributeUtils.IncrementAttribute(enemyObject, "health", -realDamage)

	local realEnergy = StatCalculationUtils.GetTotalEnergy(player, energy)

	local currentSpecialEnergy = AttributeUtils.GetAttribute(player, "ActiveRangeSpecialEnergy", 0)

	AttributeUtils.SetAttribute(
		player,
		"ActiveRangeSpecialEnergy",
		math.clamp(currentSpecialEnergy + realEnergy, 0, 300)
	)

	if AttributeUtils.GetAttribute(enemyObject, "health") <= 0 then
		AttributeUtils.IncrementAttribute(player, "RangeEnemiesDefeated", 1)

		if
			AttributeUtils.GetAttribute(player, "RangeEnemiesDefeated", 0)
			== RangeInfo[AttributeUtils.GetAttribute(player, "ActiveRange")].enemyKillRequirement
		then
			ShootingRange.EndShootingRange(player)
		end
	end
end

function ShootingRange.SpecialUsed(player)
	AttributeUtils.IncrementAttribute(player, "ActiveRangeSpecialEnergy", -100)
end

function ShootingRange.Start()
	ShootingRange.Systems.Network.GetEvent("StartShootingRange").OnServerEvent:Connect(ShootingRange.StartShootingRange)
	ShootingRange.Systems.Network.GetEvent("EnemyHit").OnServerEvent:Connect(ShootingRange.EnemyHit)
	ShootingRange.Systems.Network.GetEvent("SpecialUsed").OnServerEvent:Connect(ShootingRange.SpecialUsed)

	Players.PlayerAdded:Connect(ShootingRange.SetupPlayer)
end

return ShootingRange
