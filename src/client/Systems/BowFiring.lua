local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelUtils = require(ReplicatedStorage.Shared.Utils.ModelUtils)

local BowFiring = {}

function BowFiring.DefaultFire(bowModel, specialData)
	specialData = specialData or {}

	local tween = TweenService:Create(
		bowModel.MiddleNock.Weld,
		TweenInfo.new(
			specialData.drawbackTime or bowModel:GetAttribute("drawbackTime"),
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		),
		{ C0 = CFrame.new(0, -1.43, 1) }
	)
	tween:Play()
	tween.Completed:Wait()

	task.wait()

	local fireTween = TweenService:Create(
		bowModel.MiddleNock.Weld,
		TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{ C0 = CFrame.new(0, -1.43, 0) }
	)
	fireTween:Play()

	local arrow = bowModel.Arrow:Clone()
	arrow.Parent = workspace

	local targetCFrame = arrow:GetPivot() * CFrame.new(0, 0, 60)

	local t = (targetCFrame.Position - arrow:GetPivot().Position).Magnitude / 140

	local fireTweenArrow =
		TweenService:Create(arrow.Notch, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
	fireTweenArrow:Play()

	arrow.Hitbox:AddTag("Arrow")

	fireTweenArrow.Completed:Connect(function()
		arrow:Destroy()
	end)

	ModelUtils.toggleVisiblity(bowModel.Arrow, false)

	task.wait(specialData.reloadTime or bowModel:GetAttribute("reloadTime"))

	ModelUtils.toggleVisiblity(bowModel.Arrow, true)
end

function BowFiring.rapidFire(bowModel)
	for _ = 1, 7 do
		BowFiring.DefaultFire(bowModel, { drawbackTime = 0.1, reloadTime = 0.1 })
	end
end

return BowFiring
