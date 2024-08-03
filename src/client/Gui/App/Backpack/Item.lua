local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ItemTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.Item)

local ModelRenderer = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.ModelRenderer)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)
local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local RarityInfo = require(ReplicatedStorage.Shared.RarityInfo)

local e = React.createElement

return function(props)
	local instance

	if props.itemType == "Bows" then
		instance = ReplicatedStorage.Assets.Bows[props.bowId]
	end

	local rarity

	if props.bowId then
		rarity = ItemInfo[props.bowId].rarity
	end

	local sellStyles = ReactSpring.useSpring({
		size = if props.isBeingSold then UDim2.new(0.8, 0, 0.8, 0) else UDim2.new(0, 0, 0, 0),
		rotation = if props.isBeingSold then 0 else -180,
		config = ConfigStyles.defaultButton,
	})

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
		},

		Sell = {
			Size = sellStyles.size,
			Rotation = sellStyles.rotation,
		},

		Count = {
			Text = "x" .. props.amount,
		},
	})
end
