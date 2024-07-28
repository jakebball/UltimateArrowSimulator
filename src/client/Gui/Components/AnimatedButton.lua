local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local ButtonStyles = require(ReplicatedStorage.Shared.ButtonStyles)

local AnimatedButtonTemplate =
	RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.AnimatedButton)

local e = React.createElement

--[[
    @prop UDim2 props.size
    @prop UDim2 props.position
    @prop string props.style
    @prop string props.text
    @prop number props.layoutOrder? 
    @prop function props.activated?
]]

return function(props)
	local buttonStyles, buttonApi = ReactSpring.useSpring(function()
		return {
			size = props.size,
			config = ConfigStyles.defaultButton,
		}
	end)

	return e(AnimatedButtonTemplate, {
		[RoactTemplate.Root] = {
			Position = props.position,
			Size = buttonStyles.size,
			LayoutOrder = props.layoutOrder or 0,
		},

		Backing = {
			BackgroundColor3 = ButtonStyles[props.style].backingColor,
		},

		UIGradient = {
			Color = ButtonStyles[props.style].primaryColorSequence,
		},

		UIStroke = {
			Color = ButtonStyles[props.style].strokeColor,
		},

		Button = {
			[React.Event.Activated] = function()
				if props.activated then
					props.activated()
				else
					warn("No activated function provided for AnimatedButton")
				end

				ReplicatedStorage.Assets.Sounds.Click:Play()

				buttonApi.start({
					size = props.size,
				})
			end,

			[React.Event.MouseEnter] = function()
				buttonApi.start({
					size = UDim2.new(
						props.size.X.Scale * 1.1,
						props.size.X.Offset,
						props.size.Y.Scale * 1.1,
						props.size.Y.Offset
					),
				})
			end,

			[React.Event.MouseLeave] = function()
				buttonApi.start({
					size = props.size,
				})
			end,
		},

		TextLabel = {
			Text = props.text,
		},
	})
end
