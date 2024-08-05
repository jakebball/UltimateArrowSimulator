local Bows = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AttributeUtils = require(ReplicatedStorage.Shared.Utils.AttributeUtils)

function Bows.ToggleBowEquip(player, bowId)
	local bows = HttpService:JSONDecode(player:GetAttribute("bows"))

	if bows[bowId] == nil then
		--flag user
		return
	end

	local equippedItems = AttributeUtils.GetAttribute(player, "equippedItems", {})

	if equippedItems.playerBowSlot == bowId then
		equippedItems.playerBowSlot = nil
		AttributeUtils.SetAttribute(player, "equippedItems", equippedItems)
		return
	end

	equippedItems.playerBowSlot = bowId

	AttributeUtils.SetAttribute(player, "equippedItems", equippedItems)
end

function Bows.DestroyBows(player, destroyData)
	local bows = AttributeUtils.GetAttribute(player, "bows", {})
	local equippedItems = AttributeUtils.GetAttribute(player, "equippedItems", {})

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
			AttributeUtils.SetAttribute(player, "equippedItems", equippedItems)
		end
	end

	AttributeUtils.SetAttribute(player, "equippedItems", equippedItems)
	AttributeUtils.SetAttribute(player, "bows", bows)
end

function Bows.Start()
	Bows.Systems.Network.GetEvent("ToggleBowEquip").OnServerEvent:Connect(Bows.ToggleBowEquip)
	Bows.Systems.Network.GetEvent("DestroyBows").OnServerEvent:Connect(Bows.DestroyBows)
end

return Bows
