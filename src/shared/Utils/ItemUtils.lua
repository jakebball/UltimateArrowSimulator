local ItemUtils = {}

local ItemInfo = require(script.Parent.Parent.ItemInfo)

function ItemUtils.getItemScore(id)
    local itemInfo = ItemInfo[id]

    local score = 1

    score = score + itemInfo.rarity

    return score
end


return ItemUtils