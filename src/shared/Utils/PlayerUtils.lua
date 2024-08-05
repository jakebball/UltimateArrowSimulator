local PlayerUtils = {}

local Players = game.Players

function PlayerUtils.GetPlayerFromHumanoidRootPart(part)
	if Players:FindFirstChild(part.Parent.Name) then
		return Players:GetPlayerFromCharacter(part.Parent)
	end
end

function PlayerUtils.GetHumanoidFromPlayer(player)
	if player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil then
		return player.Character.Humanoid
	end
end

function PlayerUtils.TogglePlayersVisible(toggle, excludeTable)
	excludeTable = excludeTable or {}

	if toggle then
		for _, player in Players:GetPlayers() do
			if table.find(excludeTable, player) then
				continue
			end

			if player.Character then
				player.Character.Parent = workspace
			end
		end
	else
		for _, player in Players:GetPlayers() do
			if table.find(excludeTable, player) then
				continue
			end

			if player.Character then
				player.Character.Parent = nil
			end
		end
	end
end

return PlayerUtils
