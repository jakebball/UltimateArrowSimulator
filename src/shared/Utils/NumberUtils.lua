local NumberUtils = {}

function NumberUtils.Abbreviate(number)
	local s = tostring(math.floor(number))
	return string.sub(s, 1, ((#s - 1) % 3) + 1)
		.. ({
			"",
			"K",
			"M",
			"B",
			"T",
			"QA",
			"QI",
			"SX",
			"SP",
			"OC",
			"NO",
			"DC",
			"UD",
			"DD",
			"TD",
			"QAD",
			"QID",
			"SXD",
			"SPD",
			"OCD",
			"NOD",
			"VG",
			"UVG",
		})[math.floor((#s - 1) / 3) + 1]
end

function NumberUtils.getWeightedRandomItem(items)
	local totalWeight = 0

	for _, item in items do
		totalWeight = totalWeight + item.weight
	end

	local randomValue = math.random() * totalWeight
	local cumulativeWeight = 0

	for _, item in items do
		cumulativeWeight = cumulativeWeight + item.weight

		if randomValue <= cumulativeWeight then
			return item.name
		end
	end
end

function NumberUtils.getWeightedProbabilities(items)
	local totalWeight = 0

	for _, item in items do
		totalWeight = totalWeight + item.weight
	end

	local probabilityTable = {}

	for _, item in items do
		local probability = item.weight / totalWeight

		probabilityTable[item.name] = probability * 100
	end

	return probabilityTable
end

return NumberUtils
