local ShootingRange = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local NetworkUtils = require(ReplicatedStorage.Shared.Utils.NetworkUtils)
local NumberUtils = require(ReplicatedStorage.Shared.Utils.NumberUtils)
local StatCalculationUtils = require(ReplicatedStorage.Shared.Utils.StatCalculationUtils)
local AttributeUtils = require(ReplicatedStorage.Shared.Utils.AttributeUtils)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local EnemyInfo = require(ReplicatedStorage.Shared.EnemyInfo)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)

local Trove = require(ReplicatedStorage.Shared.Packages.Trove)

local roundTrove = Trove.new()

function ShootingRange.GenerateEnemyModel(enemyId, enemyType, enemyHealth, laneIndex)
	local activeRange = AttributeUtils.GetAttribute(ShootingRange.LocalPlayer, "ActiveRange", "olreliable")

	local enemyModel = ReplicatedStorage.Assets.Enemies[activeRange][enemyType]:Clone()
	enemyModel.Name = enemyId
	AttributeUtils.SetAttribute(enemyModel, "type", enemyType)
	AttributeUtils.SetAttribute(enemyModel, "health", enemyHealth)
	AttributeUtils.SetAttribute(enemyModel, "laneIndex", laneIndex)
	enemyModel:AddTag("Enemy")

	roundTrove:Add(enemyModel)

	local enemyObject = ShootingRange.LocalPlayer.Enemies[enemyId]

	if enemyObject then
		AttributeUtils.AttributeChanged(enemyObject, "health", function(health)
			if health <= 0 then
				ShootingRange.RunKillEffects(enemyModel)
			end
		end)
	end

	enemyModel.Parent = workspace

	return enemyModel
end

function ShootingRange.CreateEnemy(enemyId, enemyType, enemyHealth, enemySpeed, shootingRangeModel, selectedSpawn)
	local enemyModel = ShootingRange.GenerateEnemyModel(enemyId, enemyType, enemyHealth, selectedSpawn)
	enemyModel.TrackAlignPoint.CFrame = shootingRangeModel.Spawns[selectedSpawn].CFrame

	roundTrove:Add(enemyModel)

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

		local damage = EnemyInfo[shootingRangeModel.Name][enemyType].damage

		ReplicatedStorage.Bindables.RangeDamaged:Fire(damage)
	end)

	return selectedSpawn
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
			hitMarker.Parent = enemy.TrackAlignPoint.HitMarkers

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
			hitMarker.Parent = enemy.TrackAlignPoint.HitMarkers

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
		energyMarker.Parent = enemy.TrackAlignPoint.HitMarkers

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
end

function ShootingRange.RunKillEffects(enemy)
	if ShootingRange.LocalPlayer:GetAttribute("ActiveRange") == nil then
		return
	end

	local activeRange = AttributeUtils.GetAttribute(ShootingRange.LocalPlayer, "ActiveRange", "olreliable")

	local enemyDefeated = ReplicatedStorage.Assets.Gui.EnemyDefeated:Clone()
	enemyDefeated.Text = EnemyInfo[activeRange][AttributeUtils.GetAttribute(enemy, "type")].displayName .. " Defeated!"
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

	enemy:Destroy()
end

function ShootingRange.StartShootingRange(range)
	--[[
	unique case where I cant use attribute utils
	will fix later
	]]
	repeat
		task.wait()
	until ShootingRange.LocalPlayer:GetAttribute("ActiveRange")

	local shootingRangeModel = workspace.ShootingRanges[range]

	local function bindAction(actionName, inputState)
		local activeLaneRangeIndex = AttributeUtils.GetAttribute(ShootingRange.LocalPlayer, "ActiveLaneRangeIndex", 1)

		if actionName == "ActivateSpecial" and inputState == Enum.UserInputState.Begin then
			if AttributeUtils.GetAttribute(ShootingRange.LocalPlayer, "ActiveRangeSpecialEnergy", 0) >= 100 then
				if AttributeUtils.GetAttribute(ShootingRange.LocalPlayer, "SpecialActive") then
					AttributeUtils.SetAttribute(ShootingRange.LocalPlayer, "SpecialActive", AttributeUtils.Nil)
				end

				if ShootingRange.LocalPlayer:GetAttribute("SpecialActive") then
					ShootingRange.LocalPlayer:SetAttribute("SpecialActive", AttributeUtils.Nil)
				else
					AttributeUtils.IncrementAttribute(ShootingRange.LocalPlayer, "ActiveRangeSpecialEnergy", -100)

					ShootingRange.Systems.Bows.FireSpecial(ShootingRange.LocalPlayer:GetAttribute("equippedSpecial"))
				end
			end
		elseif actionName == "MoveLaneLeft" and inputState == Enum.UserInputState.Begin then
			if activeLaneRangeIndex > 1 then
				AttributeUtils.SetAttribute(ShootingRange.LocalPlayer, "ActiveLaneRangeIndex", activeLaneRangeIndex - 1)
			end
		elseif actionName == "MoveLaneRight" and inputState == Enum.UserInputState.Begin then
			if activeLaneRangeIndex < #shootingRangeModel.Spawns:GetChildren() then
				AttributeUtils.SetAttribute(ShootingRange.LocalPlayer, "ActiveLaneRangeIndex", activeLaneRangeIndex + 1)
			end
		end
	end

	ContextActionService:BindAction("ActivateSpecial", bindAction, false, Enum.KeyCode.E)
	ContextActionService:BindAction("MoveLaneLeft", bindAction, false, Enum.KeyCode.A)
	ContextActionService:BindAction("MoveLaneRight", bindAction, false, Enum.KeyCode.D)

	local mouse = ShootingRange.LocalPlayer:GetMouse()

	roundTrove:Add(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if not gameProcessedEvent then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if mouse.Target.Parent.Name == "LaneClick" then
					AttributeUtils.SetAttribute(
						ShootingRange.LocalPlayer,
						"ActiveLaneRangeIndex",
						tonumber(mouse.Target.Name)
					)
				end
			end
		end
	end))

	for _, enemy in ShootingRange.LocalPlayer.Enemies:GetChildren() do
		local enemyType = AttributeUtils.GetAttribute(enemy, "type")
		local enemyHealth = AttributeUtils.GetAttribute(enemy, "health")
		local enemyIndex = enemy.Name
		local selectedSpawn = AttributeUtils.GetAttribute(enemy, "selectedSpawn")

		local info = EnemyInfo[range][enemyType]

		ShootingRange.CreateEnemy(enemyIndex, enemyType, enemyHealth, info.speed, shootingRangeModel, selectedSpawn)
	end

	roundTrove:Add(ShootingRange.LocalPlayer.Enemies.ChildAdded:Connect(function(enemy)
		local enemyType = AttributeUtils.GetAttribute(enemy, "type")
		local enemyHealth = AttributeUtils.GetAttribute(enemy, "health")
		local enemyIndex = enemy.Name
		local selectedSpawn = AttributeUtils.GetAttribute(enemy, "selectedSpawn")

		local info = EnemyInfo[range][enemyType]

		ShootingRange.CreateEnemy(enemyIndex, enemyType, enemyHealth, info.speed, shootingRangeModel, selectedSpawn)
	end))

	NetworkUtils.ConnectPromiseRemoteEvent(ShootingRange.Systems, "ShootingRangeEnded", function()
		ShootingRange.EndShootingRange()
	end)

	roundTrove:Add(function()
		NetworkUtils.DisconnectRemoteEvent("ShootingRangeEnded")
	end)
end

function ShootingRange.EndShootingRange()
	ContextActionService:UnbindAction("ActivateSpecial")
	ContextActionService:UnbindAction("MoveLaneLeft")
	ContextActionService:UnbindAction("MoveLaneRight")

	for _, arrow in CollectionService:GetTagged("Arrow") do
		arrow.Parent:Destroy()
	end

	roundTrove:Clean()
end

function ShootingRange.Heartbeat()
	if AttributeUtils.GetAttribute(Players.LocalPlayer, "ActiveRange") then
		for _, enemy in CollectionService:GetTagged("Enemy") do
			local overlapParams = OverlapParams.new()
			overlapParams.FilterDescendantsInstances = { CollectionService:GetTagged("Arrow") }
			overlapParams.FilterType = Enum.RaycastFilterType.Include

			local results = workspace:GetPartBoundsInBox(enemy.Hitbox.CFrame, enemy.Hitbox.Size, overlapParams)

			if #results >= 1 then
				for _, arrowChild in results do
					local arrow = arrowChild.Parent
					arrow.Hitbox:RemoveTag("Arrow")
					arrow.Parent = enemy

					local arrowHitIndex = AttributeUtils.GetAttribute(enemy, "ArrowHitIndex", 1)

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = arrow.Notch
					weld.Part1 = enemy.Hitbox
					weld.Parent = arrow.Notch

					ReplicatedStorage.Assets.Sounds.ShootingRange.EnemyHit:Play()

					local equippedItems = AttributeUtils.GetAttribute(ShootingRange.LocalPlayer, "equippedItems")

					local itemInfo = ItemInfo[equippedItems.playerBowSlot]

					local activeRange =
						AttributeUtils.GetAttribute(ShootingRange.LocalPlayer, "ActiveRange", "olreliable")

					local enemyInfo = EnemyInfo[activeRange][AttributeUtils.GetAttribute(enemy, "type")]

					local damage = Random.new():NextInteger(unpack(itemInfo.damageRange))

					local realDamage = StatCalculationUtils.GetTotalDamage(ShootingRange.LocalPlayer, damage)

					local energy = Random.new():NextInteger(unpack(enemyInfo.energyRange))

					local realEnergy = StatCalculationUtils.GetTotalEnergy(ShootingRange.LocalPlayer, energy)

					ShootingRange.RunHitEffects(damage, realDamage, enemy, itemInfo.damageRange, realEnergy)

					AttributeUtils.IncrementAttribute(
						ShootingRange.LocalPlayer.Enemies[enemy.Name],
						"health",
						-realDamage
					)

					AttributeUtils.IncrementAttribute(ShootingRange.LocalPlayer, "ActiveRangeSpecialEnergy", realEnergy)

					NetworkUtils.FirePromiseRemoteEvent(
						ShootingRange.Systems,
						"EnemyHit",
						tonumber(enemy.Name),
						damage,
						energy
					)
				end
			end
		end
	end
end

function ShootingRange.Start()
	RunService.Heartbeat:Connect(ShootingRange.Heartbeat)
end

return ShootingRange
