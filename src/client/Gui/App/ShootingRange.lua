local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)
local PlayerUtils = require(ReplicatedStorage.Shared.Utils.PlayerUtils)
local CameraUtils = require(ReplicatedStorage.Shared.Utils.CameraUtils)

local AnimatedButton = require(script.Parent.Parent.Components.AnimatedButton)

local ShootingRangeTemplate =
	RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.ShootingRange)

local e = React.createElement

local sounds = ReplicatedStorage.Assets.Sounds

--[[
				for _ = 1, 25 do
					setHealthPositionOffset(
						Vector2.new(Random.new():NextNumber(-0.01, 0.01), Random.new():NextNumber(-0.01, 0.01))
					)
					task.wait()
				end

				setHealthPositionOffset(Vector2.new(0, 0))

                
]]

return function(props)
	local range, setRange = React.useState()
	local stage, setStage = React.useState("start")
	local countdown, setCountdown = React.useState(3)
	local healthPositionOffset, setHealthPositionOffset = React.useState(Vector2.new(0, 0))

	local rangeStyles = ReactSpring.useSpring({
		position = UDim2.new(if props.visible then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local startMenuStyles = ReactSpring.useSpring({
		position = UDim2.new(if stage == "start" then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local runningMenuStyles = ReactSpring.useSpring({
		position = UDim2.new(if stage == "running" then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local countdownStyles, countdownApi = ReactSpring.useSpring(function()
		return {
			position = UDim2.new(0.5, 0, 0.093, 0),
			config = ConfigStyles.menuTransition,
		}
	end)

	React.useEffect(function()
		local prompts = {}

		if range == nil then
			for _, range in workspace.ShootingRanges:GetChildren() do
				local useRangePrompt = Instance.new("ProximityPrompt")
				useRangePrompt.ObjectText = RangeInfo[range.Name].displayName
				useRangePrompt.ActionText = "Activate"
				useRangePrompt.Parent = range.Activate

				useRangePrompt.Triggered:Connect(function()
					props.setMenuState("shootingRange")

					setRange(range.Name)

					CameraUtils.setBlur(true, 14)

					workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
					workspace.CurrentCamera.Focus = range.Floor.CFrame

					local camTween = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.25), {
						CFrame = range.SelectCamera.CFrame,
					})
					camTween:Play()
					camTween.Completed:Wait()

					local humanoid = PlayerUtils.getHumanoidFromPlayer(Players.LocalPlayer)

					if humanoid then
						humanoid.WalkSpeed = 0
						humanoid.JumpHeight = 0

						PlayerUtils.toggleOtherPlayersVisible(false)
					end
				end)

				table.insert(prompts, useRangePrompt)
			end
		end

		return function()
			for _, prompt in ipairs(prompts) do
				prompt:Destroy()
			end
		end
	end, { props.setMenuState, range })

	React.useEffect(function()
		if stage == "intro" then
			task.spawn(function()
				CameraUtils.setBlur(false)

				sounds.ShootingRange.IntroTheme:Play()

				--transfer this code to settings at some point
				for _, sound in sounds.AmbientMusic:GetChildren() do
					TweenService:Create(sound, TweenInfo.new(0.5), {
						Volume = 0,
					}):Play()
				end

				task.wait(0.03)

				workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

				props.systems.Cutscene.PlayCutscene({
					{
						startCFrame = workspace.ShootingRanges[range].StartCutscene1.CFrame,
						endCFrame = workspace.ShootingRanges[range].StartCutscene2.CFrame,
						tweenInfo = TweenInfo.new(1),
					},
					{
						startCFrame = workspace.ShootingRanges[range].StartCutscene3.CFrame,
						endCFrame = workspace.ShootingRanges[range].StartCutscene4.CFrame,
						tweenInfo = TweenInfo.new(1),

						onCompleted = function()
							setStage("running")

							task.spawn(function()
								for i = 3, 0, -1 do
									setCountdown(i)
									task.wait(1)
								end

								countdownApi.start({
									position = UDim2.new(0.5, 0, -0.5, 0),
								})
							end)
						end,
					},
					{
						startCFrame = workspace.ShootingRanges[range].StartCutscene5.CFrame,
						endCFrame = workspace.ShootingRanges[range].StageRunningCam.CFrame,
						tweenInfo = TweenInfo.new(1),
					},
				}, true)
			end)
		end
	end, { stage, range, countdownApi })

	local startStyle
	local startText

	if range then
		if table.find(props.playerdata.unlockedRanges, range) then
			startStyle = "confirm"
			startText = "Start"
		else
			local previousRange = RangeInfo[range].previousRange

			if table.find(props.playerdata.unlockedRanges, previousRange) then
				startStyle = "option1"
				startText = "Unlock"
			else
				startStyle = "cancel"
				startText = "Locked"
			end
		end
	end

	return e(ShootingRangeTemplate, {
		Main = {
			Position = rangeStyles.position,
		},

		StartMenu = {
			Position = startMenuStyles.position,

			[RoactCompat.Children] = {
				Start = range and e(AnimatedButton, {
					size = UDim2.new(0.2, 0, 0.2, 0),
					position = UDim2.new(0.5, 0, 0.85, 0),
					style = startStyle,
					text = startText,

					activated = function()
						setStage("intro")
					end,
				}),
			},
		},

		RoundRunning = {
			Position = runningMenuStyles.position,
		},

		RoundCountdown = {
			Text = "Starting in " .. countdown,
			Position = countdownStyles.position,
		},

		Health = {
			Position = UDim2.new(0.5 + healthPositionOffset.X, 0, 0.902 + healthPositionOffset.Y, 0),
		},

		BackingUIStroke = {
			Color = if healthPositionOffset == Vector2.new(0, 0)
				then Color3.fromRGB(0, 132, 0)
				else Color3.fromRGB(255, 0, 0),
		},
	})
end
