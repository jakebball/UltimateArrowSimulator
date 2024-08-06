local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local NetworkUtils = require(ReplicatedStorage.Shared.Utils.NetworkUtils)
local ItemUtils = require(ReplicatedStorage.Shared.Utils.ItemUtils)

local Item = require(script.Parent.Item)

local TokenListTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.TokenList)

local e = React.createElement

local TOKEN_STACK_SIZE = 99

return function(props)
	local listChildren = {}

	listChildren.UIGridLayout = e("UIGridLayout", {
		CellPadding = UDim2.new(0.03, 0, 0.02, 0),
		CellSize = UDim2.new(0.3, 0, 0.3, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, {
		UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
			AspectRatio = 1,
			AspectType = Enum.AspectType.FitWithinMaxSize,
			DominantAxis = Enum.DominantAxis.Width,
		}),
	})

	for token, amount in props.playerdata.simulationTokens do
		local remainingTokens = amount

		local keyIndex = 0

		while remainingTokens > 0 do
			local stackSize = math.min(remainingTokens, TOKEN_STACK_SIZE)
			remainingTokens = remainingTokens - stackSize

			keyIndex += 1

			local function element(amount)
				local layoutOrder = 0

				if props.sortMode == 1 then
					layoutOrder = -ItemUtils.GetItemScore(token)
				else
					layoutOrder = ItemUtils.GetItemScore(token)
				end

				return e(Item, {
					tokenId = token,
					amount = amount,
					layoutOrder = layoutOrder,

					activated = function() end,
				})
			end

			if stackSize == TOKEN_STACK_SIZE then
				listChildren[token .. keyIndex] = element(TOKEN_STACK_SIZE)
			else
				listChildren[token .. keyIndex] = element(stackSize)
			end
		end
	end

	listChildren.UIPadding = e("UIPadding", {
		PaddingBottom = UDim.new(0, 0),
		PaddingLeft = UDim.new(0.02, 0),
		PaddingRight = UDim.new(0.01, 0),
		PaddingTop = UDim.new(0.01, 0),
	})

	return e(TokenListTemplate, {
		[RoactTemplate.Root] = {
			[RoactCompat.Children] = listChildren,

			ZIndex = 5,
		},
	})
end
