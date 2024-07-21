local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)

local CloseButtonTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.CloseButton)

local e = React.createElement

return function(props)

    local buttonStyles, buttonApi = ReactSpring.useSpring(function()
        return {
            size = props.size,
            rotation = -10,
            config = ConfigStyles.defaultButton
        }
    end)
    
    return e(CloseButtonTemplate, {
        [RoactTemplate.Root] = {
            Position = props.position,
            Size = buttonStyles.size,
            Rotation = buttonStyles.rotation,

            [React.Event.MouseEnter] = function()
                buttonApi.start({
                    size = UDim2.new(props.size.X.Scale * 1.2, 0, props.size.Y.Scale * 1.2, 0),
                    rotation = -20
                })
            end,

            [React.Event.MouseLeave] = function()
                buttonApi.start({
                    size = props.size,
                    rotation = -10
                })
            end,

            [React.Event.Activated] = function()
                props.activated()

                buttonApi.start({
                    size = props.size,
                    rotation = -10
                })

                ReplicatedStorage.Assets.Sounds.Close:Play()
            end
        }
    })
end