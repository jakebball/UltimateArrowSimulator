local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets

local StatCalculationUtils = require(ReplicatedStorage.Shared.Utils.StatCalculationUtils)
local NumberUtils = require(ReplicatedStorage.Shared.Utils.NumberUtils)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)
local EnemyInfo = require(ReplicatedStorage.Shared.EnemyInfo)

local Trove = require(ReplicatedStorage.Shared.Packages.Trove)

local ShootingRange = {}

local lastEnemyHitTick = {}
local rangeTroves = {}

local randomObject

function ShootingRange.StartShootingRange(player, range)
	if player:GetAttribute("ActiveRange") then
		warn("Player is already in a range")
		return
	end

	local unlockedRanges = HttpService:JSONDecode(player:GetAttribute("unlockedRanges"))

	if table.find(unlockedRanges, range) == nil then
		warn("Player does not own range")
		return
	end

	player:SetAttribute("ActiveRange", range)
	player:SetAttribute("ActiveRangeHealth", 100)
	player:SetAttribute("ActiveRangeSpecialEnergy", 0)
	player:SetAttribute("ActiveLaneRangeIndex", 2)
	player:SetAttribute("RangeEnemiesDefeated", 0)

	lastEnemyHitTick[player.UserId] = {}

	player:SetAttribute("rangeRandomSeed", math.random(1, 1000))

	local amountOfEnemies = RangeInfo[range].enemySpawnAmount
	local healthDecrement = 100 / amountOfEnemies

	randomObject = Random.new(player:GetAttribute("rangeRandomSeed"))

	local trove = Trove.new()

	rangeTroves[player.UserId] = trove

	task.spawn(function()
		local enemyIndex = 1

		while player:GetAttribute("ActiveRange") ~= nil and enemyIndex <= amountOfEnemies do
			local randomEnemyTypeIndex = randomObject:NextInteger(1, #Assets.Enemies[range]:GetChildren())

			local enemyType = "enemyType_" .. randomEnemyTypeIndex
			local info = EnemyInfo[range][enemyType]

			local enemyData = {
				id = enemyIndex,
				type = enemyType,
				health = randomObject:NextNumber(info.healthRange[1], info.healthRange[2]),
				damage = info.damage,
				speed = info.speed,
			}

			local selectedSpawn = randomObject:NextInteger(1, 3)

			local enemyObject = Instance.new("StringValue")
			enemyObject.Name = enemyIndex
			enemyObject:SetAttribute("health", enemyData.health)
			enemyObject:SetAttribute("damage", enemyData.damage)
			enemyObject:SetAttribute("lastDamage", enemyData.speed)
			enemyObject:SetAttribute("energy", enemyData.energy)
			enemyObject:SetAttribute("type", enemyData.type)
			enemyObject:SetAttribute("selectedSpawn", selectedSpawn)
			enemyObject.Parent = player

			lastEnemyHitTick[player.UserId][enemyIndex] = os.clock()

			enemyIndex += 1

			local timeToReachEnd = (
				workspace.ShootingRanges[range].Spawns[1].Position - workspace.ShootingRanges[range].Ends[1].Position
			).Magnitude / enemyData.speed

			trove:Add(task.delay(timeToReachEnd, function()
				player:SetAttribute("ActiveRangeHealth", player:GetAttribute("ActiveRangeHealth") - healthDecrement)

				if player:GetAttribute("ActiveRangeHealth") <= 0 then
					ShootingRange.EndShootingRange(player)
				end
			end))

			task.wait(randomObject:NextNumber(1, 2))
		end
	end)
end

function ShootingRange.EndShootingRange(player)
	local rangeInfo = RangeInfo[player:GetAttribute("ActiveRange")]

	player:SetAttribute("ActiveRange", nil)
	player:SetAttribute("ActiveRangeHealth", nil)
	player:SetAttribute("ActiveRangeSpecialEnergy", nil)
	player:SetAttribute("ActiveLaneRangeIndex", nil)
	player:SetAttribute("RangeEnemiesDefeated", 0)

	for _, v in player:GetChildren() do
		if v.ClassName == "StringValue" then
			v:Destroy()
		end
	end

	rangeTroves[player.UserId]:Destroy()

	local selectedGrade = NumberUtils.getWeightedRandomItem(rangeInfo.rewards.tokenGradeTable)
	local selectedRarity = NumberUtils.getWeightedRandomItem(rangeInfo.rewards.tokenRarityTable)

	local simulationTokens = HttpService:JSONDecode(player:GetAttribute("simulationTokens"))

	simulationTokens[selectedRarity][selectedGrade] += 1

	player:SetAttribute("simulationTokens", HttpService:JSONEncode(simulationTokens))

	ShootingRange.Systems.Network.GetEvent("SendPlayerReward"):FireClient(player, {
		grade = selectedGrade,
		rarity = selectedRarity,
	})
end

function ShootingRange.EnemyHit(player, enemyId)
	if lastEnemyHitTick[player.UserId] == nil then
		return
	end

	if lastEnemyHitTick[player.UserId][enemyId] == nil then
		return
	end

	local timeSinceLastHit = os.clock() - lastEnemyHitTick[player.UserId][enemyId]

	if timeSinceLastHit < 0.05 then
		return
	end

	local enemyObject = player[enemyId]

	lastEnemyHitTick[player.UserId][enemyId] = os.clock()

	local itemInfo = ItemInfo[HttpService:JSONDecode(player:GetAttribute("equippedItems")).playerBowSlot]

	local damage = randomObject:NextInteger(unpack(itemInfo.damageRange))

	local realDamage = StatCalculationUtils.GetTotalDamage(player, damage)

	enemyObject:SetAttribute("health", enemyObject:GetAttribute("health") - realDamage)

	local enemyInfo = EnemyInfo[player:GetAttribute("ActiveRange")][enemyObject:GetAttribute("type")]

	local energy = randomObject:NextInteger(unpack(enemyInfo.energyRange))

	local realEnergy = StatCalculationUtils.GetTotalEnergy(player, energy)

	player:SetAttribute(
		"ActiveRangeSpecialEnergy",
		math.clamp(player:GetAttribute("ActiveRangeSpecialEnergy") + realEnergy, 0, 300)
	)

	if enemyObject:GetAttribute("health") <= 0 then
		local enemiesDefeated = player:GetAttribute("RangeEnemiesDefeated") or 0

		enemiesDefeated = enemiesDefeated + 1

		if enemiesDefeated == RangeInfo[player:GetAttribute("ActiveRange")].enemySpawnAmount then
			ShootingRange.EndShootingRange(player)
		end

		player:SetAttribute("RangeEnemiesDefeated", enemiesDefeated)
	end
end

function ShootingRange.SpecialUsed(player)
	player:SetAttribute("ActiveRangeSpecialEnergy", player:GetAttribute("ActiveRangeSpecialEnergy") - 100)
end

function ShootingRange.Start()
	ShootingRange.Systems.Network.GetEvent("StartShootingRange").OnServerEvent:Connect(ShootingRange.StartShootingRange)
	ShootingRange.Systems.Network.GetEvent("EnemyHit").OnServerEvent:Connect(ShootingRange.EnemyHit)
	ShootingRange.Systems.Network.GetEvent("SpecialUsed").OnServerEvent:Connect(ShootingRange.SpecialUsed)
end

return ShootingRange
