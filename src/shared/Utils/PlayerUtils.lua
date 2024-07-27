
local PlayerUtils = {}

local Players = game.Players


function PlayerUtils.GetPlayerFromHumanoidRootPart(part)
    if Players:FindFirstChild(part.Parent.Name) then
        return Players:GetPlayerFromCharacter(part.Parent)
    end
end

function PlayerUtils.getHumanoidFromPlayer(player)
    if player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil then
        return player.Character.Humanoid
    end
end

function PlayerUtils.toggleOtherPlayersVisible(toggle)
    if toggle then
        for _,player in Players:GetPlayers() do
            if player.Character then
                player.Character.Parent = nil
            end
        end
    else
        for _,player in Players:GetPlayers() do
            if player.Character then
                player.Character.Parent = workspace
            end
        end
    end
end

return PlayerUtils