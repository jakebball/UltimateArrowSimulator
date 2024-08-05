local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local NetworkUtils = require(ReplicatedStorage.Shared.Utils.NetworkUtils)
local ItemUtils = require(ReplicatedStorage.Shared.Utils.ItemUtils)

local BackpackTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.Backpack)

local CloseButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.CloseButton)
local AnimatedButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.AnimatedButton)
local ModeButton = require(script.ModeButton)
local Item = require(script.Item)
local ItemSlot = require(script.ItemSlot)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local ButtonStyles = require(ReplicatedStorage.Shared.ButtonStyles)

local SORTING_MODES = {
	"Best",
	"Worst",
}

local e = React.createElement

local BOW_STACK_SIZE = 99
local MODE_BUTTON_SIZE = UDim2.new(1, 0, 0.5, 0)

return function(props)
	local backpackMode, setBackpackMode = React.useState("bows")
	local destroyActive, setDestroyActive = React.useState(false)
	local destroyList, setDestroyList = React.useState({})
	local sortMode, setSortMode = React.useState(1)
	local runTextureAnim, setRunTextureAnim = React.useState(false)

	local keyIndexToAmount = {}

	local backpackStyles = ReactSpring.useSpring({
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

	local listChildren = {}

	listChildren.UIGridLayout = e("UIGridLayout", {
		CellPadding = UDim2.new(0.03, 0, 0.02, 0),
		CellSize = UDim2.new(0.222, 0, 0.168, 0),
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

	listChildren.UIPadding = e("UIPadding", {
		PaddingBottom = UDim.new(0, 0),
		PaddingLeft = UDim.new(0.02, 0),
		PaddingRight = UDim.new(0.01, 0),
		PaddingTop = UDim.new(0.01, 0),
	})

	if backpackMode == "bows" then
		for bowId, amount in props.playerdata.bows do
			local remainingBows = amount

			local keyIndex = 1

			local bowIndex = {}

			while remainingBows > 0 do
				local stackSize = math.min(remainingBows, BOW_STACK_SIZE)
				remainingBows = remainingBows - stackSize

				keyIndex += 1

				if bowIndex[bowId] == nil then
					bowIndex[bowId] = 1
				else
					bowIndex[bowId] += 1
				end

				local function element(amount, keyIndex)
					local layoutOrder = 0

					if sortMode == 1 then
						layoutOrder = -ItemUtils.GetItemScore(bowId)
					else
						layoutOrder = ItemUtils.GetItemScore(bowId)
					end

					return e(Item, {
						itemType = "Bows",
						bowId = bowId,
						amount = amount,
						isBeingSold = table.find(destroyList, keyIndex) ~= nil,
						layoutOrder = layoutOrder,

						activated = function()
							if destroyActive then
								setDestroyList(function(prev)
									prev = table.clone(prev)

									local index = table.find(prev, keyIndex)

									if index then
										table.remove(prev, index)
									else
										table.insert(prev, keyIndex)
									end

									return prev
								end)
							else
								NetworkUtils.FirePromiseRemoteEvent(props.systems, "ToggleBowEquip", bowId)
							end
						end,
					})
				end

				if stackSize == BOW_STACK_SIZE then
					listChildren[bowId .. keyIndex] = element(BOW_STACK_SIZE, bowId .. keyIndex)

					keyIndexToAmount[bowId .. keyIndex] = {
						amount = BOW_STACK_SIZE,
						id = bowId,
					}
				else
					listChildren[bowId .. keyIndex] = element(stackSize, bowId .. keyIndex)

					keyIndexToAmount[bowId .. keyIndex] = {
						amount = stackSize,
						id = bowId,
					}
				end
			end
		end
	end

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

	return e(BackpackTemplate, {
		Main = {
			Position = backpackStyles.position,

			[RoactCompat.Children] = {
				Close = e(CloseButton, {
					position = UDim2.new(1, 0, 0, 0),
					size = UDim2.new(0.2, 0, 0.2, 0),

					activated = function()
						ReplicatedStorage.Bindables.SetGuiState:Fire("gameplay")
						setDestroyActive(false)
					end,
				}),
			},
		},

		Buttons = {
			[RoactCompat.Children] = {
				UIListLayout = e("UIListLayout", {
					Padding = UDim.new(0.02, 0),
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				Destroy = (destroyActive == false) and e(AnimatedButton, {
					size = UDim2.new(0.269, 0, 0.9, 0),
					style = "cancel",
					text = "Destroy",
					layoutOrder = 2,

					activated = function()
						setDestroyActive(true)
					end,
				}),

				EquipBest = (destroyActive == false) and (backpackMode == "bows") and e(AnimatedButton, {
					size = UDim2.new(0.269, 0, 0.9, 0),
					style = "confirm",
					text = "Equip Best",
					layoutOrder = 1,

					activated = function()
						local scores = {}

						for bowId, _ in props.playerdata.bows do
							table.insert(scores, {
								score = ItemUtils.GetItemScore(bowId),
								id = bowId,
							})
						end

						table.sort(scores, function(a, b)
							return a.score > b.score
						end)

						NetworkUtils.FirePromiseRemoteEvent(props.systems, "ToggleBowEquip", scores[1].id)
					end,
				}),

				SortBy = (destroyActive == false) and e(AnimatedButton, {
					size = UDim2.new(0.269, 0, 0.9, 0),
					style = "option1",
					text = "Sort By: " .. SORTING_MODES[sortMode],
					layoutOrder = 3,

					activated = function()
						setSortMode(function(prev)
							return (prev % #SORTING_MODES) + 1
						end)
					end,
				}),

				CancelDestroy = (destroyActive == true) and e(AnimatedButton, {
					size = UDim2.new(0.269, 0, 0.9, 0),
					style = "cancel",
					text = "Cancel Destroy",
					layoutOrder = 2,

					activated = function()
						setDestroyActive(false)
						setDestroyList({})
					end,
				}),

				ConfirmDestroy = (destroyActive == true) and e(AnimatedButton, {
					size = UDim2.new(0.269, 0, 0.9, 0),
					style = "confirm",
					text = "Confirm Destroy",
					layoutOrder = 1,

					activated = function()
						setDestroyActive(false)

						local data = {}

						for _, key in destroyList do
							table.insert(data, {
								id = keyIndexToAmount[key].id,
								amount = keyIndexToAmount[key].amount,
							})
						end

						setDestroyList({})

						NetworkUtils.FirePromiseRemoteEvent(props.systems, "DestroyBows", data)
					end,
				}),
			},
		},

		ModeButtons = {
			[RoactCompat.Children] = {
				UIListLayout = e("UIListLayout", {
					Padding = UDim.new(0.05, 0),
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				Bows = (destroyActive == false) and e(ModeButton, {
					size = MODE_BUTTON_SIZE,
					style = if backpackMode == "bows" then "confirm" else "option1",
					isSelected = backpackMode == "bows",
					text = "Bows",
					activated = function()
						setBackpackMode("bows")
						setRunTextureAnim(true)
					end,
				}),

				Tokens = (destroyActive == false) and e(ModeButton, {
					size = MODE_BUTTON_SIZE,
					style = if backpackMode == "tokens" then "confirm" else "option1",
					isSelected = backpackMode == "tokens",
					text = "Tokens",
					activated = function()
						setBackpackMode("tokens")
						setRunTextureAnim(true)
					end,
				}),

				Gear = (destroyActive == false) and e(ModeButton, {
					size = MODE_BUTTON_SIZE,
					style = if backpackMode == "gear" then "confirm" else "option1",
					isSelected = backpackMode == "gear",
					text = "Gear",
					activated = function()
						setBackpackMode("gear")
						setRunTextureAnim(true)
					end,
				}),
			},
		},

		TitleLabel = {
			Text = string.upper(string.sub(backpackMode, 1, 1)) .. string.sub(backpackMode, 2),
		},

		List = {
			[RoactCompat.Children] = listChildren,
		},

		SellingGrey = {
			Visible = destroyActive,
		},

		SlotFrame = {
			[RoactCompat.Children] = {
				BowSlot1 = e(ItemSlot, {
					slotType = "Bow",
					itemId = props.playerdata.equippedItems.playerBowSlot,
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
