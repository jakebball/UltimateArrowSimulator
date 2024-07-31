local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets

local StatCalculationUtils = require(ReplicatedStorage.Shared.Utils.StatCalculationUtils)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)
local EnemyInfo = require(ReplicatedStorage.Shared.EnemyInfo)

local ShootingRange = {}

local lastEnemyHitTick = {}

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

	local defeatedEnemies = Instance.new("Folder")
	defeatedEnemies.Name = "DefeatedEnemies"
	defeatedEnemies.Parent = player

	lastEnemyHitTick[player.UserId] = {}

	task.spawn(function()
		while true do
			player:SetAttribute("rangeRandomSeed", math.random(1, 100))

			task.wait(Random.new():NextNumber(0, 1))
		end
	end)

	local amountOfEnemies = RangeInfo[range].enemySpawnAmount
	local healthDecrement = 100 / amountOfEnemies

	for i = 1, amountOfEnemies do
		if player:GetAttribute("ActiveRange") == nil then
			break
		end

		local rangeRandom = Random.new(player:GetAttribute("rangeRandomSeed"))

		local randomEnemyTypeIndex = rangeRandom:NextInteger(1, #Assets.Enemies[range]:GetChildren())

		local enemyType = "enemyType_" .. randomEnemyTypeIndex
		local info = EnemyInfo[range][enemyType]

		local enemyData = {
			id = i,
			type = enemyType,
			health = rangeRandom:NextNumber(info.healthRange[1], info.healthRange[2]),
			damage = info.damage,
			speed = info.speed,
		}

		local enemyObject = Instance.new("StringValue")
		enemyObject.Name = i
		enemyObject:SetAttribute("health", enemyData.health)
		enemyObject:SetAttribute("damage", enemyData.damage)
		enemyObject:SetAttribute("lastDamage", enemyData.speed)
		enemyObject:SetAttribute("energy", enemyData.energy)
		enemyObject:SetAttribute("type", enemyData.type)
		enemyObject.Parent = player

		lastEnemyHitTick[player.UserId][i] = os.clock()

		local timeToReachEnd = (
			workspace.ShootingRanges[range].Spawns[1].Position - workspace.ShootingRanges[range].Ends[1].Position
		).Magnitude / enemyData.speed

		task.delay(timeToReachEnd, function()
			player:SetAttribute("ActiveRangeHealth", player:GetAttribute("ActiveRangeHealth") - healthDecrement)

			if player:GetAttribute("ActiveRangeHealth") <= 0 then
				player:SetAttribute("ActiveRange", nil)
				player:SetAttribute("ActiveRangeHealth", nil)

				for _, v in player:GetChildren() do
					if v.ClassName == "StringValue" then
						v:Destroy()
					end
				end
			end
		end)

		task.wait(rangeRandom:NextNumber(1, 5))
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

	local randomSeed = player:GetAttribute("rangeRandomSeed") or math.random(1, 100)

	local damage = Random.new(randomSeed):NextInteger(unpack(itemInfo.damageRange))

	local realDamage = StatCalculationUtils.GetTotalDamage(player, damage)

	enemyObject:SetAttribute("health", enemyObject:GetAttribute("health") - realDamage)

	local enemyInfo = EnemyInfo[player:GetAttribute("ActiveRange")][enemyObject:GetAttribute("type")]

	local energy = Random.new(randomSeed):NextInteger(unpack(enemyInfo.energyRange))

	local realEnergy = StatCalculationUtils.GetTotalEnergy(player, energy)

	player:SetAttribute(
		"ActiveRangeSpecialEnergy",
		math.clamp(player:GetAttribute("ActiveRangeSpecialEnergy") + realEnergy, 0, 100)
	)
end

function ShootingRange.Start()
	ShootingRange.Systems.Network.GetEvent("StartShootingRange").OnServerEvent:Connect(ShootingRange.StartShootingRange)
	ShootingRange.Systems.Network.GetEvent("EnemyHit").OnServerEvent:Connect(ShootingRange.EnemyHit)
end

return ShootingRange
