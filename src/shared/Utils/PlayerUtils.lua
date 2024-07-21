
local PlayerUtils = {}

local Players = game.Players

function PlayerUtils.GetPlayerFromHumanoidRootPart(part)
    if Players:FindFirstChild(part.Parent.Name) then
        return Players:GetPlayerFromCharacter(part.Parent)
    end
end

function PlayerUtils.getCharacterFromPlayer(player)
    if player.Character ~= nil  and player.Character:FindFirstChild("HumanoidRootPart") ~= nil then
        return player.Character
    end
end

return PlayerUtils