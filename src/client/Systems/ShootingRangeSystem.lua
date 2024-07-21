
local ShootingRangeSystem = {}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game.Players

local CameraUtils = require(ReplicatedStorage.Shared.Utils.CameraUtils)

local camera = workspace.CurrentCamera

local player = Players.LocalPlayer

function ShootingRangeSystem.setupRanges()
    for _,shootingRange in CollectionService:GetTagged("ShootingRange") do
        local usePrompt = Instance.new("ProximityPrompt")
        usePrompt.ActionText = "Use"
        usePrompt.ObjectText = "Shooting Range"
        usePrompt.RequiresLineOfSight = false
        usePrompt.Parent = shootingRange.PrimaryInteraction

        usePrompt.Triggered:Connect(function()
            player.Character.Humanoid.WalkSpeed = 0
            player.Character.Humanoid.JumpPower = 0

            camera.CameraType = Enum.CameraType.Scriptable

            local tween = TweenService:Create(camera, TweenInfo.new(0.5), { CFrame = shootingRange.CameraPosition.CFrame })
            tween:Play()
            tween.Completed:Connect(function()
                ReplicatedStorage.Bindables.SetGuiState:Fire("shootingRange")
            end)
        end)
    end
end

function ShootingRangeSystem.Start()
    ShootingRangeSystem.setupRanges()
end

return ShootingRangeSystem