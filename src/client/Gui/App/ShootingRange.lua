local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ShootingRangeTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.ShootingRange)

local AnimatedButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.AnimatedButton)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)

local e = React.createElement

return function(props)

    local hudStyles = ReactSpring.useSpring({
        position = UDim2.new(if props.visible then 0.5 else -1.5, 0, 0.5, 0),
        config = ConfigStyles.menuTransition
    })

    return e(ShootingRangeTemplate, {
        Main = {
            Position = hudStyles.position,

            [RoactCompat.Children] = {           
                PlayStageButton = e(AnimatedButton, {
                    position = UDim2.new(0.5, 0, 0.692, 0),
                    size = UDim2.new(0.185, 0, 0.081, 0),
                    style = "confirm",
    
                    activated = function()
                        ReplicatedStorage.RemoteEvents.PlayerStartedRange:FireServer()
                    end,
                })
            }
        },
    })
end
