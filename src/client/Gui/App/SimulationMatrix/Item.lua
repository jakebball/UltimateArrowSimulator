local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ItemTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.Item)

local ModelRenderer = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.ModelRenderer)

local TokenInfo = require(ReplicatedStorage.Shared.TokenInfo)
local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local RarityInfo = require(ReplicatedStorage.Shared.RarityInfo)

local e = React.createElement

return function(props)
	local instance = ReplicatedStorage.Assets.SimulationTokens[props.tokenId]

	local rarity = TokenInfo[props.tokenId].rarity

	return e(ItemTemplate, {
		UIStroke = {
			Color = RarityInfo[rarity].strokeColor,
		},

		UIGradient = {
			Color = RarityInfo[rarity].gradientSequence,
		},

		Button = {
			[React.Event.Activated] = function()
				props.activated()
			end,
		},

		[RoactTemplate.Root] = {
			[RoactCompat.Children] = {
				ModelRenderer = e(ModelRenderer, {
					model = instance,
					size = UDim2.new(1, 0, 1, 0),
					position = UDim2.new(0.5, 0, 0.5, 0),
				}),
			},

			LayoutOrder = props.layoutOrder,
			ZIndex = 10,
		},

		Count = {
			Text = "x" .. props.amount,
		},

		Sell = {
			Visible = false,
		},
	})
end
