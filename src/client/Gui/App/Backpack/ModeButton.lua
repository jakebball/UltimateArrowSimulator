
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ModeButtonTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.ModeButtonTemplate)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local ButtonStyles = require(ReplicatedStorage.Shared.ButtonStyles)

local e = React.createElement

return function(props)
    
    local buttonStyles, buttonApi = ReactSpring.useSpring(function()
        return {
            size = UDim2.new(0.44, 0, 0.672, 0),
            config = ConfigStyles.defaultButton
        }
    end)

    React.useEffect(function()
        if props.isSelected then
            buttonApi.start({
                size = UDim2.new(0.5, 0, 0.8, 0),
            })
        else
            buttonApi.start({
                size = UDim2.new(0.44, 0, 0.672, 0),
                rotation = 0
            })
        end
    end)

    return e(ModeButtonTemplate, {
        [RoactTemplate.Root] = {
            Size = buttonStyles.size,
            Rotation = buttonStyles.rotation,

            [React.Event.MouseEnter] = function()
                buttonApi.start({
                    size = UDim2.new(0.5, 0, 0.8, 0),
                    rotation = -10
                })
            end,

            [React.Event.MouseLeave] = function()
                if not props.isSelected then
                    buttonApi.start({
                        size = UDim2.new(0.44, 0, 0.672, 0),
                        rotation = 0
                    })
                end
            end,
        },

        Button = {
            [React.Event.Activated] = function()
                if not props.isSelected then
                    buttonApi.start({
                        size = UDim2.new(0.44, 0, 0.672, 0),
                        rotation = 0
                    })

                    ReplicatedStorage.Assets.Sounds.Click:Play()

                    props.activated()
                end
            end
        },

        Backing = {
            BackgroundColor3 = ButtonStyles[props.style].backingColor
        },

        UIGradient = {
            Color = ButtonStyles[props.style].primaryColorSequence
        },

        UIStroke = {
            Color = ButtonStyles[props.style].strokeColor
        },

        TextLabel = {
            Text = props.text,
        }
    })
end