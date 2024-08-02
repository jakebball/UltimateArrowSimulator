local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets

local StatCalculationUtils = require(ReplicatedStorage.Shared.Utils.StatCalculationUtils)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)
local EnemyInfo = require(ReplicatedStorage.Shared.EnemyInfo)

local ShootingRange = {}

local lastEnemyHitTick = {}

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

	lastEnemyHitTick[player.UserId] = {}

	player:SetAttribute("rangeRandomSeed", math.random(1, 1000))

	local amountOfEnemies = RangeInfo[range].enemySpawnAmount
	local healthDecrement = 100 / amountOfEnemies

	randomObject = Random.new(player:GetAttribute("rangeRandomSeed"))

	for i = 1, amountOfEnemies do
		if player:GetAttribute("ActiveRange") == nil then
			break
		end

		local randomEnemyTypeIndex = randomObject:NextInteger(1, #Assets.Enemies[range]:GetChildren())

		local enemyType = "enemyType_" .. randomEnemyTypeIndex
		local info = EnemyInfo[range][enemyType]

		local enemyData = {
			id = i,
			type = enemyType,
			health = randomObject:NextNumber(info.healthRange[1], info.healthRange[2]),
			damage = info.damage,
			speed = info.speed,
		}

		local selectedSpawn = randomObject:NextInteger(1, 3)

		local enemyObject = Instance.new("StringValue")
		enemyObject.Name = i
		enemyObject:SetAttribute("health", enemyData.health)
		enemyObject:SetAttribute("damage", enemyData.damage)
		enemyObject:SetAttribute("lastDamage", enemyData.speed)
		enemyObject:SetAttribute("energy", enemyData.energy)
		enemyObject:SetAttribute("type", enemyData.type)
		enemyObject:SetAttribute("selectedSpawn", selectedSpawn)
		enemyObject.Parent = player

		lastEnemyHitTick[player.UserId][i] = os.clock()

		local timeToReachEnd = (
			workspace.ShootingRanges[range].Spawns[1].Position - workspace.ShootingRanges[range].Ends[1].Position
		).Magnitude / enemyData.speed

		task.delay(timeToReachEnd, function()
			player:SetAttribute("ActiveRangeHealth", player:GetAttribute("ActiveRangeHealth") - healthDecrement)

			if player:GetAttribute("ActiveRangeHealth") <= 0 then
				ShootingRange.EndShootingRange(player)
			end
		end)

		task.wait(randomObject:NextNumber(1, 2))

		if player:GetAttribute("ActiveRange") == nil then
			break
		end
	end
end

function ShootingRange.EndShootingRange(player)
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
end

function ShootingRange.EnemyHit(player, enemyId)
	if lastEnemyHitTick[player.UserId] == nil then
		return
	end

	if lastEnemyHitTick[player.UserId][enemyId] == nil then
		return
	end

	local timeSinceLastHit = os.clock() - lastEnemyHitTick[player.UserId][enemyId]

	if timeSinceLastHit < 0.25 then
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

		player:SetAttribute("RangeEnemiesDefeated", nil)
	end
end

function ShootingRange.SpecialUsed(player)
	player:SetAttribute("ActiveRangeSpecialEnergy", player:GetAttribute("ActiveRangeSpecialEnergy") - 100)
end

function ShootingRange.ToggleChallengeMode(player, active)
	player:SetAttribute("ChallengeMode", active)
end

function ShootingRange.Start()
	ShootingRange.Systems.Network.GetEvent("StartShootingRange").OnServerEvent:Connect(ShootingRange.StartShootingRange)
	ShootingRange.Systems.Network.GetEvent("EnemyHit").OnServerEvent:Connect(ShootingRange.EnemyHit)
	ShootingRange.Systems.Network.GetEvent("SpecialUsed").OnServerEvent:Connect(ShootingRange.SpecialUsed)
	ShootingRange.Systems.Network
		.GetEvent("ToggleChallengeMode").OnServerEvent
		:Connect(ShootingRange.ToggleChallengeMode)
end

return ShootingRange
