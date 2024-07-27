local ShootingRange = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)
local PlayerUtils = require(ReplicatedStorage.Shared.Utils.PlayerUtils)

local localPlayer = Players.LocalPlayer

local setGuiState = ReplicatedStorage.Bindables.SetGuiState

function ShootingRange.Start()
	for _, range in workspace.ShootingRanges:GetChildren() do
		local useRangePrompt = Instance.new("ProximityPrompt")
		useRangePrompt.ObjectText = RangeInfo[range.Name].displayName
		useRangePrompt.ActionText = "Activate"
		useRangePrompt.Parent = range.Activate

		useRangePrompt.Triggered:Connect(function()
			setGuiState:Fire("shootingRange")

			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
			workspace.CurrentCamera.Focus = range.Floor.CFrame

			local camTween = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.25), {
				CFrame = range.Camera.CFrame,
			})
			camTween:Play()
			camTween.Completed:Wait()

			local humanoid = PlayerUtils.getHumanoidFromPlayer(localPlayer)

			if humanoid then
				humanoid.WalkSpeed = 0
				humanoid.JumpHeight = 0

				PlayerUtils.toggleOtherPlayersVisible(false)
			end
		end)
	end
end

return ShootingRange
