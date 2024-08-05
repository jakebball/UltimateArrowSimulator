local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelUtils = require(ReplicatedStorage.Shared.Utils.ModelUtils)
local AttributeUtils = require(ReplicatedStorage.Shared.Utils.AttributeUtils)

local BowFiring = {}

function BowFiring.DefaultFire(bowModel, specialData)
	specialData = specialData or {}

	local tween = TweenService:Create(
		bowModel.MiddleNock.Weld,
		TweenInfo.new(
			specialData.drawbackTime or AttributeUtils.GetAttribute(bowModel, "drawbackTime", 0.3),
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		),
		{ C0 = CFrame.new(0, AttributeUtils.GetAttribute(bowModel, "middleNockY", -1), -1) }
	)
	tween:Play()
	tween.Completed:Wait()

	task.wait()

	local fireTween = TweenService:Create(
		bowModel.MiddleNock.Weld,
		TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{ C0 = CFrame.new(0, AttributeUtils.GetAttribute(bowModel, "middleNockY", -1), 0) }
	)
	fireTween:Play()

	local arrow = bowModel.Arrow:Clone()
	arrow.Parent = workspace

	local targetCFrame = arrow:GetPivot() * CFrame.new(0, 0, -60)

	local t = (targetCFrame.Position - arrow:GetPivot().Position).Magnitude / 140

	local fireTweenArrow =
		TweenService:Create(arrow.Notch, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
	fireTweenArrow:Play()

	arrow.Hitbox:AddTag("Arrow")

	fireTweenArrow.Completed:Connect(function()
		if arrow:FindFirstChild("Hitbox") and arrow.Hitbox:HasTag("Arrow") then
			arrow:Destroy()
		end
	end)

	ModelUtils.ToggleVisiblity(bowModel.Arrow, false)

	task.wait(specialData.reloadTime or AttributeUtils.GetAttribute(bowModel, "reloadTime", 0.5))

	ModelUtils.ToggleVisiblity(bowModel.Arrow, true)
end

function BowFiring.rapidFire(bowModel)
	for _ = 1, 7 do
		BowFiring.DefaultFire(bowModel, { drawbackTime = 0.1, reloadTime = 0.1 })
	end
end

return BowFiring
