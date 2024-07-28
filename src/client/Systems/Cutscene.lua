local TweenService = game:GetService("TweenService")

local Cutscene = {
	ReturnToPlayer = {},
}

local camera = workspace.CurrentCamera

function Cutscene.PlayCutscene(states, yield)
	local previousCFrame = camera.CFrame

	for _, state in states do

		if state == Cutscene.ReturnToPlayer then
			camera.CFrame = previousCFrame
			break
		end

		camera.CFrame = state.startCFrame

		local tween = TweenService:Create(camera, state.tweenInfo, {
			CFrame = state.endCFrame,
		})
		tween:Play()

		if state.onCompleted then
			state.onCompleted()
		end

		if yield then
			tween.Completed:Wait()
		end
	end
end

return Cutscene
