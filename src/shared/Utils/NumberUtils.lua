local NumberUtils = {}

function NumberUtils.Abbreviate(number)
    local s = tostring(math.floor(number))
	return string.sub(s, 1, ((#s - 1) % 3) + 1) .. ({"", "K", "M", "B", "T", "QA", "QI", "SX", "SP", "OC", "NO", "DC", "UD", "DD", "TD", "QAD", "QID", "SXD", "SPD", "OCD", "NOD", "VG", "UVG"})[math.floor((#s - 1) / 3) + 1]
end

return NumberUtils