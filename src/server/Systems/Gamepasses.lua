local Players = game:GetService("Players")
local Gamepasses = {}

local GAMEPASS_ID_TO_ROBLOX_ID = {}

function Gamepasses.playerOwnsGamepass(assetId)
	return true
end

function Gamepasses.updateGamepassAttributes(player)
	for gamepassId, assetId in GAMEPASS_ID_TO_ROBLOX_ID do
		local ownsGamepass = Gamepasses.playerOwnsGamepass(assetId)

		player:SetAttribute("OwnsGamepass" .. gamepassId, ownsGamepass)
	end
end

Players.PlayerAdded:Connect(function(player)
	Gamepasses.updateGamepassAttributes(player)
end)

for _, player in Players:GetPlayers() do
	Gamepasses.updateGamepassAttributes(player)
end

return Gamepasses
