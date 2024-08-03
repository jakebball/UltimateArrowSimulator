local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local SimulationMatrixTemplate =
	RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.SimulationMatrix)

local CloseButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.CloseButton)
local AnimatedButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.AnimatedButton)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local ButtonStyles = require(ReplicatedStorage.Shared.ButtonStyles)

local SORTING_MODES = {
	"Best",
	"Worst",
}

local e = React.createElement

local TOKEN_STACK_SIZE = 99

return function(props)
	local sortMode, setSortMode = React.useState(1)
	local runTextureAnim, setRunTextureAnim = React.useState(false)

	local simulationMatrixStyles = ReactSpring.useSpring({
		position = UDim2.new(if props.visible then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local textureStyles, textureApi = ReactSpring.useSpring(function()
		return {
			texture1Position = UDim2.new(0, 0, 0, 0),
			texture2Position = UDim2.new(1, 0, 0, 0),
			config = ConfigStyles.textureTransition,
		}
	end)

	React.useEffect(function()
		local prompt = Instance.new("ProximityPrompt")
		prompt.RequiresLineOfSight = false
		prompt.ObjectText = "Simulation Matrix"
		prompt.ActionText = "Use Matrix"
		prompt.Parent = workspace.OpenSimulationGui

		prompt.Triggered:Connect(function()
			props.setMenuState("simulationMatrix")
		end)
	end, {})

	React.useEffect(function()
		if runTextureAnim then
			textureApi
				.start({
					texture1Position = UDim2.new(0, 0, 1, 0),
					texture2Position = UDim2.new(0, 0, 0, 0),
				})
				:andThen(function()
					textureApi.start({
						texture1Position = UDim2.new(0, 0, 0, 0),
						texture2Position = UDim2.new(0, 0, -1, 0),
						immediate = true,
					})

					setRunTextureAnim(false)
				end)
		end
	end, { runTextureAnim })

	return e(SimulationMatrixTemplate, {
		Main = {
			Position = simulationMatrixStyles.position,
		},

		Holder = {
			[RoactCompat.Children] = {
				Close = e(CloseButton, {
					position = UDim2.new(1, 0, 0, 0),
					size = UDim2.new(0.2, 0, 0.2, 0),

					activated = function()
						props.setMenuState("gameplay")
					end,
				}),
			},
		},

		Buttons = {
			[RoactCompat.Children] = {
				UIListLayout = e("UIListLayout", {
					Padding = UDim.new(0.05, 0),
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				SortBy = e(AnimatedButton, {
					size = UDim2.new(0.269, 0, 0.9, 0),
					style = "option1",
					text = "Sort By: " .. SORTING_MODES[sortMode],
					layoutOrder = 3,

					activated = function()
						setSortMode(function(prev)
							return (prev % #SORTING_MODES) + 1
						end)

						setRunTextureAnim(true)
					end,
				}),

				SimulateToken = e(AnimatedButton, {
					size = UDim2.new(0.269 * 1.1, 0, 0.9 * 1.1, 0),
					style = "confirm",
					text = "Simulate Token",
					layoutOrder = 2,

					activated = function() end,
				}),

				AutoSimulate = e(AnimatedButton, {
					size = UDim2.new(0.269, 0, 0.9, 0),
					style = "confirm",
					text = "Auto Simulate (2)",
					layoutOrder = 1,

					activated = function() end,
				}),
			},
		},

		Texture1 = {
			Position = textureStyles.texture1Position,
		},

		Texture2 = {
			Position = textureStyles.texture2Position,
		},
	})
end
