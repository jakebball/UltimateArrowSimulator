local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)

local e = React.createElement

return function(props)
    
    local HUDButtonTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.HUDButtons[props.buttonTemplateName])

    local styles, api = ReactSpring.useSpring(function()
        return {
            size = UDim2.new(1,0,1,0),
            rotation = 0,
            config = ConfigStyles.defaultButton
        }
    end)

    return e(HUDButtonTemplate, {
        Holder = {
            Size = styles.size,
            Rotation = styles.rotation,

            [React.Event.MouseEnter] = function()
                api.start({
                    size = UDim2.new(1.2,0,1.2,0),
                    rotation = -10
                })
            end,

            [React.Event.MouseLeave] = function()
                api.start({
                    size = UDim2.new(1,0,1,0),
                    rotation = 0
                })
            end,
        },

        Button = {
            [React.Event.Activated] = function()
                api.start({
                    size = UDim2.new(1,0,1,0),
                    rotation = 0
                })

                ReplicatedStorage.Assets.Sounds.Click:Play()

                props.activated()
            end,
        }
    })
end