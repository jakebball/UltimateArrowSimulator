local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)
local Trove = require(Packages.Trove)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local RangeInfo = require(ReplicatedStorage.Shared.RangeInfo)
local PlayerUtils = require(ReplicatedStorage.Shared.Utils.PlayerUtils)
local CameraUtils = require(ReplicatedStorage.Shared.Utils.CameraUtils)
local NetworkUtils = require(ReplicatedStorage.Shared.Utils.NetworkUtils)
local RarityInfo = require(ReplicatedStorage.Shared.RarityInfo)
local GradeInfo = require(ReplicatedStorage.Shared.GradeInfo)

local AnimatedButton = require(script.Parent.Parent.Components.AnimatedButton)
local ModelRenderer = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.ModelRenderer)
local CloseButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.CloseButton)

local ShootingRangeTemplate =
	RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.ShootingRange)

local e = React.createElement

local sounds = ReplicatedStorage.Assets.Sounds

return function(props)
	local range, setRange = React.useState()
	local stage, setStage = React.useState("start")
	local countdown, setCountdown = React.useState(3)
	local healthPositionOffset, setHealthPositionOffset = React.useState(Vector2.new(0, 0))
	local health, setHealth = React.useState(100)
	local roundEnergy, setEnergy = React.useState(0)
	local energyProgressGradientRotation, setEnergyProgressGradientRotation = React.useState(0)
	local specialAbilityKeyCode, setSpecialAbilityKeyCode = React.useState("E")
	local autoRetry, setAutoRetry = React.useState(false)
	local autoRetryCountdown, setAutoRetryCountdown = React.useState(1)
	local rewardModel, setRewardModel = React.useState()
	local rewardGrade, setRewardGrade = React.useState()
	local rewardRarity, setRewardRarity = React.useState()
	local previousCameraFocus, setPreviousCameraFocus = React.useState()

	local rangeStyles = ReactSpring.useSpring({
		position = UDim2.new(if props.visible then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local startMenuStyles = ReactSpring.useSpring({
		position = UDim2.new(if stage == "start" then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local endMenuStyles = ReactSpring.useSpring({
		position = UDim2.new(if stage == "end" then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransitionEnd,
	})

	local runningMenuStyles = ReactSpring.useSpring({
		position = UDim2.new(if stage == "running" then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local healthStyles = ReactSpring.useSpring({
		size = UDim2.new(health / 100, 0, 1, 0),
		config = ConfigStyles.healthBar,
	})

	local healthWhiteStyles = ReactSpring.useSpring({
		size = UDim2.new(health / 100, 0, 1, 0),
		config = ConfigStyles.whiteHealthBar,
	})

	local energyStyles = ReactSpring.useSpring({
		size = UDim2.new(1 - (roundEnergy / 100), 0, 1, 0),
		config = ConfigStyles.healthBar,
	})

	local keyFrameStyles = ReactSpring.useSpring({
		size = if roundEnergy >= 100 then UDim2.new(0.25, 0, 0.25, 0) else UDim2.new(0, 0, 0, 0),
		config = ConfigStyles.checkmark,
	})

	local extraChargeStyles = ReactSpring.useSpring({
		size = UDim2.new(1 - (roundEnergy % 100) / 100, 0, 1, 0),
		config = ConfigStyles.healthBar,
	})

	local specialFrameStyles = ReactSpring.useSpring({
		size = if roundEnergy >= 100 then UDim2.new(0.137 * 1.1, 0, 2.354 * 1.1, 0) else UDim2.new(0.137, 0, 2.354, 0),
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

					setPreviousCameraFocus(workspace.CurrentCamera.Focus)

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

						PlayerUtils.togglePlayersVisible(false)
					end
				end)

				table.insert(prompts, useRangePrompt)
			end
		end

		return function()
			for _, prompt in prompts do
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
					},
					{
						startCFrame = workspace.ShootingRanges[range].StartCutscene5.CFrame,
						endCFrame = workspace.ShootingRanges[range].StageRunningCam.CFrame,
						tweenInfo = TweenInfo.new(1),

						onCompleted = function()
							setStage("running")

							task.spawn(function()
								countdownApi.start({
									position = UDim2.new(0.5, 0, 0.1, 0),
								})

								for i = 3, 1, -1 do
									setCountdown(i)
									task.wait(1)
								end

								NetworkUtils.FirePromiseRemoteEvent(props.systems, "StartShootingRange", range)

								task.spawn(props.systems.ShootingRange.StartShootingRange, range)

								countdownApi.start({
									position = UDim2.new(0.5, 0, -0.5, 0),
								})
							end)
						end,
					},
				}, true)
			end)
		elseif stage == "running" then
			CameraUtils.setBlur(false)

			local trove = Trove.new()

			trove:Add(ReplicatedStorage.Bindables.RangeDamaged.Event:Connect(function()
				if Players.LocalPlayer:GetAttribute("ActiveRange") then
					local amountOfEnemies = RangeInfo[Players.LocalPlayer:GetAttribute("ActiveRange")].enemySpawnAmount

					local healthDecreaseIncrement = 100 / amountOfEnemies

					for _ = 1, 25 do
						setHealthPositionOffset(
							Vector2.new(Random.new():NextNumber(-0.02, 0.02), Random.new():NextNumber(-0.02, 0.02))
						)
						task.wait()
					end

					setHealthPositionOffset(Vector2.new(0, 0))

					setHealth(function(prev)
						return prev - healthDecreaseIncrement
					end)
				end
			end))

			trove:Add(Players.LocalPlayer:GetAttributeChangedSignal("ActiveRangeSpecialEnergy"):Connect(function()
				setEnergy(Players.LocalPlayer:GetAttribute("ActiveRangeSpecialEnergy") or 0)
			end))

			trove:Add(Players.LocalPlayer:GetAttributeChangedSignal("ActiveRange"):Connect(function()
				if Players.LocalPlayer:GetAttribute("ActiveRange") == nil then
					task.wait(1)

					setStage("end")
				end
			end))

			return function()
				trove:Destroy()
			end
		elseif stage == "end" then
			CameraUtils.setBlur(true, 14)

			local trove = Trove.new()

			if autoRetry == true then
				trove:Add(task.spawn(function()
					for i = 5, 1, -1 do
						setAutoRetryCountdown(i)

						task.wait(1)
					end

					setStage("intro")
				end))
			end

			return function()
				trove:Destroy()
			end
		end
	end, { stage, range, countdownApi, healthPositionOffset, autoRetry })

	React.useEffect(function()
		if roundEnergy >= 100 then
			local conn = RunService.Heartbeat:Connect(function(dt)
				setEnergyProgressGradientRotation(function(prev)
					local newRotation = prev + (dt * 300)

					if newRotation >= 360 then
						return 0
					else
						return newRotation
					end
				end)
			end)

			return function()
				conn:Disconnect()
			end
		else
			setHealthPositionOffset(Vector2.new(0, 0))
		end
	end, { roundEnergy })

	React.useEffect(function()
		NetworkUtils.ConnectPromiseRemoteEvent(props.systems, "SendPlayerReward", function(reward)
			setRewardModel(ReplicatedStorage.Assets.SimulationTokens[reward.rarity][reward.grade])
			setRewardRarity(RarityInfo[reward.rarity].displayName)
			setRewardGrade(GradeInfo[reward.grade].displayName)
		end)

		return function()
			NetworkUtils.DisconnectRemoteEvent("SendPlayerReward")
		end
	end, {})

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

				Close = e(CloseButton, {
					position = UDim2.new(0.8, 0, 0.2, 0),
					size = UDim2.new(0.15, 0, 0.15, 0),

					activated = function()
						workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
						workspace.CurrentCamera.Focus = previousCameraFocus

						setRange(nil)

						local humanoid = PlayerUtils.getHumanoidFromPlayer(Players.LocalPlayer)

						if humanoid then
							humanoid.WalkSpeed = 16
							humanoid.JumpHeight = 30

							PlayerUtils.togglePlayersVisible(true)
						end

						CameraUtils.setBlur(false)

						props.setMenuState("gameplay")
					end,
				}),
			},
		},

		EndMenu = {
			Position = endMenuStyles.position,

			[RoactCompat.Children] = {
				EndMenuViewport = rewardModel and e(ModelRenderer, {
					model = rewardModel,
					position = UDim2.new(0.5, 0, 0.415, 0),
					size = UDim2.new(0.265, 0, 0.35, 0),
				}),
			},
		},

		EndButtonList = {
			[RoactCompat.Children] = {
				Retry = e(AnimatedButton, {
					size = UDim2.new(0.5, 0, 0.5, 0),
					position = UDim2.new(0.5, 0, 0.85, 0),
					style = "confirm",
					text = "Retry",
					layoutOrder = 2,

					activated = function()
						setStage("intro")
					end,
				}),

				Leave = e(AnimatedButton, {
					size = UDim2.new(0.5, 0, 0.5, 0),
					position = UDim2.new(0.5, 0, 0.85, 0),
					style = "cancel",
					text = "Leave",
					layoutOrder = 1,

					activated = function()
						workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
						workspace.CurrentCamera.Focus = previousCameraFocus

						setRange(nil)

						local humanoid = PlayerUtils.getHumanoidFromPlayer(Players.LocalPlayer)

						if humanoid then
							humanoid.WalkSpeed = 16
							humanoid.JumpHeight = 30

							PlayerUtils.togglePlayersVisible(true)
						end

						CameraUtils.setBlur(false)

						props.setMenuState("gameplay")
					end,
				}),

				ToggleAutoRetry = e(AnimatedButton, {
					size = UDim2.new(0.5, 0, 0.5, 0),
					position = UDim2.new(0.5, 0, 0.85, 0),
					style = if autoRetry then "cancel" else "confirm",
					text = if autoRetry then "Cancel Auto Retry (" .. autoRetryCountdown .. ")" else "Use Auto Retry",
					layoutOrder = 3,

					activated = function()
						setAutoRetry(function(prev)
							return not prev
						end)
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

		HealthBacking = {
			Position = UDim2.new(0.5 + healthPositionOffset.X, 0, 0.5 + healthPositionOffset.Y, 0),
		},

		HealthLabel = {
			Text = "Health: " .. health .. "/100",
		},

		HealthProgress = {
			Size = healthStyles.size,
		},

		HealthProgressWhite = {
			Size = healthWhiteStyles.size,
		},

		BackingUIStroke = {
			Color = if healthPositionOffset == Vector2.new(0, 0)
				then Color3.fromRGB(0, 132, 0)
				else Color3.fromRGB(255, 0, 0),
		},

		EnergyProgressGrey = {
			Size = energyStyles.size,
		},

		EnergyProgressGradient = {
			Rotation = energyProgressGradientRotation,
		},

		KeyFrame = {
			Size = keyFrameStyles.size,
		},

		SpecialKey = {
			Text = specialAbilityKeyCode,
		},

		KeyUIStroke = {
			Transparency = if roundEnergy >= 100 then 0 else 1,
		},

		Special = {
			Size = specialFrameStyles.size,
		},

		ExtraChargesLabel = {
			Text = if roundEnergy >= 100 then string.sub(roundEnergy, 1, 1) else 0,
		},

		SpecialChargeGrey = {
			Size = extraChargeStyles.size,
		},

		GradeLabel = {
			Text = rewardGrade,
		},

		PullRarityLabel = {
			Text = rewardRarity,
		},
	})
end
