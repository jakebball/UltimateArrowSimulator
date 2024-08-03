local ItemUtils = {}

local ItemInfo = require(script.Parent.Parent.ItemInfo)
local RarityInfo = require(script.Parent.Parent.RarityInfo)

function ItemUtils.getItemScore(id)
	local itemInfo = ItemInfo[id]

	local score = 1

	score = score + RarityInfo[itemInfo.rarity].weight

	return score
end

return ItemUtils
