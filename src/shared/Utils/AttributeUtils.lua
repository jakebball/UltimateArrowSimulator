local AttributeUtils = {}

local HttpService = game:GetService("HttpService")

AttributeUtils.Nil = {}

local function isJsonTable(str)
	local success, result = pcall(function()
		return HttpService:JSONDecode(str)
	end)

	return success and type(result) == "table"
end

function AttributeUtils.GetAttribute(instance, attributeName, defaultValue)
	local value = instance:GetAttribute(attributeName)

	if value then
		if typeof(value) == "string" and isJsonTable(value) then
			return HttpService:JSONDecode(value)
		else
			return value
		end
	else
		return defaultValue
	end
end

function AttributeUtils.SetAttribute(instance, attributeName, value)
	if typeof(value) == "table" then
		if value == AttributeUtils.Nil then
			instance:SetAttribute(attributeName, nil)
		else
			instance:SetAttribute(attributeName, HttpService:JSONEncode(value))
		end
	else
		if value == AttributeUtils.Nil then
			instance:SetAttribute(attributeName, nil)
		else
			instance:SetAttribute(attributeName, value)
		end
	end

	return value
end

function AttributeUtils.IncrementAttribute(instance, attributeName, incrementValue)
	local newAmount = AttributeUtils.GetAttribute(instance, attributeName, 0) + incrementValue
	return AttributeUtils.SetAttribute(instance, attributeName, newAmount)
end

function AttributeUtils.AttributeChanged(instance, attributeName, onChangeFunc)
	local changedConn = instance:GetAttributeChangedSignal(attributeName):Connect(function()
		onChangeFunc(AttributeUtils.GetAttribute(instance, attributeName))
	end)

	return function()
		changedConn:Disconnect()
	end
end

return AttributeUtils
