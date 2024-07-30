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

	local defeatedEnemies = Instance.new("Folder")
	defeatedEnemies.Name = "DefeatedEnemies"
	defeatedEnemies.Parent = player

	lastEnemyHitTick[player.UserId] = {}

	task.spawn(function()
		while true do
			player:SetAttribute("hitRandomSeed", math.random(1, 100))

			task.wait(Random.new():NextNumber(0, 1))
		end
	end)

	local amountOfEnemies = RangeInfo[range].enemySpawnAmount
	local healthDecrement = 100 / amountOfEnemies

	for i = 1, amountOfEnemies do
		if player:GetAttribute("ActiveRange") == nil then
			break
		end

		local enemyType = "enemyType_" .. math.random(1, #Assets.Enemies[range]:GetChildren())
		local info = EnemyInfo[range][enemyType]

		local enemyData = {
			id = i,
			type = enemyType,
			health = math.random(info.healthRange[1], info.healthRange[2]),
			damage = info.damage,
			speed = info.speed,
		}

		local enemyObject = Instance.new("StringValue")
		enemyObject.Name = i
		enemyObject:SetAttribute("health", enemyData.health)
		enemyObject:SetAttribute("damage", enemyData.damage)
		enemyObject:SetAttribute("lastDamage", enemyData.speed)
		enemyObject.Parent = player

		ShootingRange.Systems.Network.GetEvent("SpawnRangeEnemy"):FireClient(player, enemyData)

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

		task.wait(math.random(2, 3))
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

	lastEnemyHitTick[player.UserId][enemyId] = os.clock()

	local itemInfo = ItemInfo[HttpService:JSONDecode(player:GetAttribute("equippedItems")).playerBowSlot]

	local damage = Random.new(player:GetAttribute("hitRandomSeed") or math.random(1, 100))
		:NextInteger(unpack(itemInfo.damageRange))

	local realDamage = StatCalculationUtils.GetTotalDamage(player, damage)

	if player:FindFirstChild(enemyId) then
		player[enemyId]:SetAttribute("health", player[enemyId]:GetAttribute("health") - realDamage)
	end
end

function ShootingRange.Start()
	ShootingRange.Systems.Network.GetEvent("StartShootingRange").OnServerEvent:Connect(ShootingRange.StartShootingRange)
	ShootingRange.Systems.Network.GetEvent("EnemyHit").OnServerEvent:Connect(ShootingRange.EnemyHit)
end

return ShootingRange
