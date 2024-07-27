
local Moderation = {}

local HttpService = game:GetService("HttpService")


function Moderation.Start()
    for _,remote in game.ReplicatedStorage.RemoteEvents:GetChildren() do
        remote.OnServerEvent:Connect(function(player)
     
        end)
    end
end

function Moderation.KickUser(player, exploitCode)
    HttpService:PostAsync(
        "https://discord.com/api/webhooks/1165392798741184592/0amq_2EX9h43YnSB0uMisF5i27w4ubAh59dk9cRwpFNEHemypq7EGqwdRj4pFnYWhz9D",
        HttpService:JSONEncode({
            embeds = {
                {
                    ["title"] = "Exploit Flag",
                    ["color"] = "14177041",
                    ["fields"] = {
                        {
                            ["name"] = "Username",
                            ["value"] = tostring(player.Name),
                            ["inline"] = true
                        },
                        {
                            ["name"] = "UserId",
                            ["value"] = tostring(player.UserId),
                            ["inline"] = true
                        },
                        {
                            ["name"] = "Exploit Code:",
                            ["value"] = exploitCode,
                        },
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
                }
            }
        }),
        Enum.HttpContentType.ApplicationJson
    )

    task.delay(math.random(900, 1800), function()
        player:Kick("There was a problem receiving data, please reconnect. (Error Code: 260)")
    end)
end


return Moderation