local Bows = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function Bows.ToggleBowEquip(player, bowId)
	local bows = HttpService:JSONDecode(player:GetAttribute("bows"))

	if bows[bowId] == nil then
		--flag user
		return
	end

	local equippedItems = HttpService:JSONDecode(player:GetAttribute("equippedItems"))

	if equippedItems.playerBowSlot == bowId then
		equippedItems.playerBowSlot = nil
		player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
		return
	end

	equippedItems.playerBowSlot = bowId

	player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
end

function Bows.DestroyBows(player, destroyData)
	local bows = HttpService:JSONDecode(player:GetAttribute("bows"))
	local equippedItems = HttpService:JSONDecode(player:GetAttribute("equippedItems"))

	for _, v in destroyData do
		local bowId = v.id
		local amount = v.amount

		if bows[bowId] == nil then
			--flag user
			return
		end

		if bows[bowId] and amount > bows[bowId] then
			--flag user
			return
		end

		local newAmount = bows[bowId] - amount
		bows[bowId] = newAmount

		if newAmount == 0 and equippedItems.playerBowSlot == bowId then
			equippedItems.playerBowSlot = nil
			player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
		end
	end

	player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
	player:SetAttribute("bows", HttpService:JSONEncode(bows))
end

function Bows.Start()
	Bows.Systems.Network.GetEvent("ToggleBowEquip").OnServerEvent:Connect(Bows.ToggleBowEquip)
	Bows.Systems.Network.GetEvent("DestroyBows").OnServerEvent:Connect(Bows.DestroyBows)
end

return Bows
