local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local HUDTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.HUD)

local HUDButton = require(script.HUDButton)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)

local e = React.createElement

return function(props)
	local bottomButtonsHovered, setBottomButtonsHovered = React.useState(false)

	local hudStyles = ReactSpring.useSpring({
		position = UDim2.new(if props.visible then 0.5 else -1.5, 0, 0.5, 0),
		config = ConfigStyles.menuTransition,
	})

	local bottomButtonShadowStyles = ReactSpring.useSpring({
		size = UDim2.new(0.512, 0, if bottomButtonsHovered then 0.15 else 0, 0),
		config = ConfigStyles.bottomShadow,
	})

	return e(HUDTemplate, {
		Main = {
			Position = hudStyles.position,
		},

		BottomButtons = {
			[RoactCompat.Children] = {
				UIListLayout = e("UIListLayout", {
					Padding = UDim.new(0.08, 0),
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, {
					UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
						AspectRatio = 1,
						AspectType = Enum.AspectType.FitWithinMaxSize,
						DominantAxis = Enum.DominantAxis.Width,
					}),
				}),

				Backpack = e(HUDButton, {
					buttonTemplateName = "BackpackButton",
					holderSize = UDim2.new(0.127, 0, if bottomButtonsHovered then 0.85 else 0.75, 0),

					activated = function()
						if props.menuState == "gameplay" then
							ReplicatedStorage.Bindables.SetGuiState:Fire("backpack")
						else
							ReplicatedStorage.Bindables.SetGuiState:Fire("gameplay")
						end
					end,
				})
			},
		},

		BottomButtonShadow = {
			Size = bottomButtonShadowStyles.size,
		},

		ShadowButton = {
			[React.Event.MouseEnter] = function()
				setBottomButtonsHovered(true)
			end,

			[React.Event.MouseLeave] = function()
				setBottomButtonsHovered(false)
			end,
		},
	})
end
