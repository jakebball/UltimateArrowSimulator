local ShootingRange = {}

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local NetworkUtils = require(ReplicatedStorage.Shared.Utils.NetworkUtils)
local NumberUtils = require(ReplicatedStorage.Shared.Utils.NumberUtils)
local StatCalculationUtils = require(ReplicatedStorage.Shared.Utils.StatCalculationUtils)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local EnemyInfo = require(ReplicatedStorage.Shared.EnemyInfo)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)

local enemiesKilled = 0
local randomObject

function ShootingRange.GenerateEnemyModel(enemyId, enemyType, enemyHealth, laneIndex)
	local enemyModel =
		ReplicatedStorage.Assets.Enemies[ShootingRange.LocalPlayer:GetAttribute("ActiveRange")][enemyType]:Clone()
	enemyModel.Name = enemyId
	enemyModel:SetAttribute("type", enemyType)
	enemyModel:SetAttribute("health", enemyHealth)
	enemyModel:SetAttribute("laneIndex", laneIndex)
	enemyModel:AddTag("Enemy")

	ShootingRange.LocalPlayer:WaitForChild(enemyId):GetAttributeChangedSignal("health"):Connect(function()
		if ShootingRange.LocalPlayer[enemyId]:GetAttribute("health") <= 0 then
			ShootingRange.RunKillEffects(enemyModel)
		end
	end)

	enemyModel.Parent = workspace

	return enemyModel
end

function ShootingRange.CreateEnemy(enemyId, enemyType, enemyHealth, enemySpeed, shootingRangeModel)
	local selectedSpawn = randomObject:NextInteger(1, #shootingRangeModel.Spawns:GetChildren())

	local enemyModel = ShootingRange.GenerateEnemyModel(enemyId, enemyType, enemyHealth, selectedSpawn)
	enemyModel.TrackAlignPoint.CFrame = shootingRangeModel.Spawns[selectedSpawn].CFrame

	local timeToReachEnd = (
		shootingRangeModel.Spawns[selectedSpawn].Position - shootingRangeModel.Ends[selectedSpawn].Position
	).Magnitude / enemySpeed

	local tween = TweenService:Create(
		enemyModel.TrackAlignPoint,
		TweenInfo.new(timeToReachEnd, Enum.EasingStyle.Linear),
		{ CFrame = shootingRangeModel.Ends[selectedSpawn].CFrame }
	)
	tween:Play()
	tween.Completed:Connect(function()
		enemyModel:Destroy()
		ReplicatedStorage.Bindables.RangeDamaged:Fire()

		if ShootingRange.LocalPlayer:GetAttribute("ActiveRangeHealth") <= 0 then
			ShootingRange.EndShootingRange()
		end
	end)
end

function ShootingRange.RunHitEffects(damage, realDamage, enemy, damageRange, energy)
	task.spawn(function()
		local animLength = 0.5

		local markerRotation = if math.random(1, 2) == 1 then 10 else -10

		local isCritical = if damage >= damageRange[2] - 10 then true else false

		local hitMarker

		if isCritical then
			hitMarker = ReplicatedStorage.Assets.Gui.CriticalHitMarker:Clone()
			hitMarker.Text = NumberUtils.Abbreviate(realDamage)
			hitMarker.Rotation = markerRotation
			hitMarker.Position = UDim2.new(0.5, 0, 0, 0)
			hitMarker.Parent = enemy.HitMarkers

			TweenService:Create(hitMarker, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
				Size = UDim2.new(1.5, 0, 1.5, 0),
			}):Play()

			local markerTween = TweenService:Create(hitMarker, TweenInfo.new(animLength), {
				Rotation = markerRotation + 5,
				Position = UDim2.new(0.5, 0, -0.5, 0),
			})
			markerTween:Play()
			markerTween.Completed:Connect(function()
				local tweenOut = TweenService:Create(hitMarker, TweenInfo.new(0.2), {
					Size = UDim2.new(0, 0, 0, 0),
					Rotation = 920,
				})
				tweenOut:Play()
				tweenOut.Completed:Connect(function()
					hitMarker:Destroy()
				end)
			end)
		else
			hitMarker = ReplicatedStorage.Assets.Gui.RegularHitMarker:Clone()
			hitMarker.Text = NumberUtils.Abbreviate(realDamage)
			hitMarker.Rotation = markerRotation
			hitMarker.Position = UDim2.new(0.5, 0, 0, 0)
			hitMarker.Parent = enemy.HitMarkers

			local markerTween = TweenService:Create(hitMarker, TweenInfo.new(animLength), {
				Rotation = markerRotation + 5,
				Position = UDim2.new(0.5, 0, -0.5, 0),
			})
			markerTween:Play()
			markerTween.Completed:Connect(function()
				local tweenOut = TweenService:Create(hitMarker, TweenInfo.new(0.2), {
					Size = UDim2.new(0, 0, 0, 0),
					Rotation = 920,
				})
				tweenOut:Play()
				tweenOut.Completed:Connect(function()
					hitMarker:Destroy()
				end)
			end)
		end

		local energyMarker = ReplicatedStorage.Assets.Gui.EnergyHitMarker:Clone()
		energyMarker.Text = "+" .. NumberUtils.Abbreviate(energy)
		energyMarker.Position = UDim2.new(0.5, 0, 0.5, 0)
		energyMarker.Parent = enemy.HitMarkers

		local energyTween = TweenService:Create(energyMarker, TweenInfo.new(animLength), {
			Position = UDim2.new(0.5, 0, 0.6, 0),
		})
		energyTween:Play()
		energyTween.Completed:Connect(function()
			local tweenOut = TweenService:Create(energyMarker, TweenInfo.new(0.2), {
				Size = UDim2.new(0, 0, 0, 0),
			})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				energyMarker:Destroy()
			end)
		end)
	end)

	task.spawn(function()
		local hitHighlight = Instance.new("Highlight")
		hitHighlight.FillColor = Color3.fromRGB(255, 0, 0)
		hitHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		hitHighlight.FillTransparency = 0.5
		hitHighlight.OutlineTransparency = 0
		hitHighlight.Parent = enemy

		task.wait(0.25)

		local tween = TweenService:Create(hitHighlight, TweenInfo.new(1), {
			FillTransparency = 1,
			OutlineTransparency = 1,
		})
		tween:Play()
		tween.Completed:Wait()

		hitHighlight:Destroy()
	end)

	local equippedBow = HttpService:JSONDecode(ShootingRange.LocalPlayer:GetAttribute("equippedItems")).playerBowSlot

	local arrowModel = ReplicatedStorage.Assets.Arrows[equippedBow]:Clone()
	arrowModel.Parent = enemy
end

function ShootingRange.RunKillEffects(enemy)
	if ShootingRange.LocalPlayer:GetAttribute("ActiveRange") == nil then
		return
	end

	local enemyDefeated = ReplicatedStorage.Assets.Gui.EnemyDefeated:Clone()
	enemyDefeated.Text = EnemyInfo[ShootingRange.LocalPlayer:GetAttribute("ActiveRange")][enemy:GetAttribute("type")].displayName
		.. " Defeated!"
	enemyDefeated.Position = UDim2.new(0.5, 0, -0.5, 0)
	enemyDefeated.Parent = ShootingRange.LocalPlayer.PlayerGui.ShootingRange.Main

	local tween = TweenService:Create(enemyDefeated, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {
		Position = UDim2.new(0.5, 0, 0.068, 0),
	})
	tween:Play()
	tween.Completed:Connect(function()
		local endTween = TweenService:Create(enemyDefeated, TweenInfo.new(1, Enum.EasingStyle.Sine), {
			Position = UDim2.new(0.5, 0, 0.1, 0),
		})
		endTween:Play()
		endTween.Completed:Connect(function()
			enemyDefeated:Destroy()
		end)
	end)

	enemiesKilled += 1

	if enemiesKilled >= RangeInfo[ShootingRange.LocalPlayer:GetAttribute("ActiveRange")].enemySpawnAmount then
		ShootingRange.EndShootingRange()
	end

	enemy:Destroy()
end

function ShootingRange.StartShootingRange(range)
	local rangeInfo = RangeInfo[range]

	repeat
		task.wait()
	until ShootingRange.LocalPlayer:GetAttribute("rangeRandomSeed")

	repeat
		task.wait()
	until ShootingRange.LocalPlayer:GetAttribute("ActiveRange")

	local shootingRangeModel = workspace.ShootingRanges[range]

	local function bindAction(actionName, inputState)
		if actionName == "ActivateSpecial" and inputState == Enum.UserInputState.Begin then
			if ShootingRange.LocalPlayer:GetAttribute("ActiveRangeSpecialEnergy") >= 100 then
				if ShootingRange.LocalPlayer:GetAttribute("SpecialActive") then
					ShootingRange.LocalPlayer:SetAttribute("SpecialActive", nil)
				else
					ShootingRange.LocalPlayer:SetAttribute(
						"ActiveRangeSpecialEnergy",
						ShootingRange.LocalPlayer:GetAttribute("ActiveRangeSpecialEnergy") - 100
					)

					ShootingRange.Systems.Bows.FireSpecial(ShootingRange.LocalPlayer:GetAttribute("equippedSpecial"))
				end
			end
		elseif actionName == "MoveLaneLeft" and inputState == Enum.UserInputState.Begin then
			local currentLaneIndex = ShootingRange.LocalPlayer:GetAttribute("ActiveLaneRangeIndex")

			if currentLaneIndex > 1 then
				ShootingRange.LocalPlayer:SetAttribute("ActiveLaneRangeIndex", currentLaneIndex - 1)
			end
		elseif actionName == "MoveLaneRight" and inputState == Enum.UserInputState.Begin then
			local currentLaneIndex = ShootingRange.LocalPlayer:GetAttribute("ActiveLaneRangeIndex")

			if currentLaneIndex < #shootingRangeModel.Spawns:GetChildren() then
				ShootingRange.LocalPlayer:SetAttribute("ActiveLaneRangeIndex", currentLaneIndex + 1)
			end
		end
	end

	ContextActionService:BindAction("ActivateSpecial", bindAction, false, Enum.KeyCode.E)
	ContextActionService:BindAction("MoveLaneLeft", bindAction, false, Enum.KeyCode.A)
	ContextActionService:BindAction("MoveLaneRight", bindAction, false, Enum.KeyCode.D)

	local mouse = ShootingRange.LocalPlayer:GetMouse()

	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if mouse.Target.Parent.Name == "LaneClick" then
					ShootingRange.LocalPlayer:SetAttribute("ActiveLaneRangeIndex", mouse.Target.Name)
				end
			end
		end
	end)

	randomObject = Random.new(ShootingRange.LocalPlayer:GetAttribute("rangeRandomSeed"))

	for i = 1, rangeInfo.enemySpawnAmount do
		local randomEnemyTypeIndex = randomObject:NextInteger(1, #ReplicatedStorage.Assets.Enemies[range]:GetChildren())

		local enemyType = "enemyType_" .. randomEnemyTypeIndex

		local info = EnemyInfo[range][enemyType]
		local enemyHealth = randomObject:NextNumber(info.healthRange[1], info.healthRange[2])

		ShootingRange.CreateEnemy(i, enemyType, enemyHealth, info.speed, shootingRangeModel)

		task.wait(randomObject:NextNumber(1, 2))
	end
end

function ShootingRange.EndShootingRange()
	ContextActionService:UnbindAction("ActivateSpecial")
	ContextActionService:UnbindAction("MoveLaneLeft")
	ContextActionService:UnbindAction("MoveLaneRight")

	enemiesKilled = 0
end

function ShootingRange.Heartbeat()
	for _, enemy in CollectionService:GetTagged("Enemy") do
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = { CollectionService:GetTagged("Arrow") }
		overlapParams.FilterType = Enum.RaycastFilterType.Include

		local results = workspace:GetPartBoundsInBox(enemy.Hitbox.CFrame, enemy.Hitbox.Size, overlapParams)

		if #results >= 1 then
			for _, arrow in results do
				arrow.Parent:Destroy()

				ReplicatedStorage.Assets.Sounds.ShootingRange.EnemyHit:Play()

				local itemInfo = ItemInfo[HttpService:JSONDecode(
					ShootingRange.LocalPlayer:GetAttribute("equippedItems")
				).playerBowSlot]

				local enemyInfo =
					EnemyInfo[ShootingRange.LocalPlayer:GetAttribute("ActiveRange") or "olreliable"][enemy:GetAttribute(
						"type"
					) or "enemyType_1"]

				local damage = randomObject:NextInteger(unpack(itemInfo.damageRange))

				local realDamage = StatCalculationUtils.GetTotalDamage(ShootingRange.LocalPlayer, damage)

				local energy = randomObject:NextInteger(unpack(enemyInfo.energyRange))

				local realEnergy = StatCalculationUtils.GetTotalEnergy(ShootingRange.LocalPlayer, energy)

				ShootingRange.RunHitEffects(damage, realDamage, enemy, itemInfo.damageRange, realEnergy)

				ShootingRange.LocalPlayer[enemy.Name]:SetAttribute(
					"health",
					ShootingRange.LocalPlayer[enemy.Name]:GetAttribute("health") - realDamage
				)

				NetworkUtils.FirePromiseRemoteEvent(ShootingRange.Systems, "EnemyHit", tonumber(enemy.Name))
			end
		end
	end
end

function ShootingRange.Start()
	RunService.Heartbeat:Connect(ShootingRange.Heartbeat)
end

return ShootingRange
