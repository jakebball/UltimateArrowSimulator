local ItemUtils = {}

local ItemInfo = require(script.Parent.Parent.ItemInfo)
local RarityInfo = require(script.Parent.Parent.RarityInfo)
local TokenInfo = require(script.Parent.Parent.TokenInfo)

function ItemUtils.GetItemScore(id)
	local itemInfo = ItemInfo[id]

	local rarity

	if TokenInfo[id] then
		rarity = TokenInfo[id].rarity
	elseif ItemInfo[id] then
		rarity = ItemInfo[id].rarity
	end

	local score = 1

	score = score + RarityInfo[rarity].weight

	return score
end

return ItemUtils
