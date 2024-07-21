local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local HUDTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.HUD)

local HUDButton = require(script.HUDButton)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)

local e = React.createElement

return function(props)

    local hudStyles = ReactSpring.useSpring({
        position = UDim2.new(if props.visible then 0.5 else -1.5, 0, 0.5, 0),
        config = ConfigStyles.menuTransition
    })

    local shopButtonStyles, shopButtonApi = ReactSpring.useSpring(function()
        return {
            size = UDim2.new(0.148, 0, 0.062, 0),
            config = ConfigStyles.defaultButton
        }
    end)

    return e(HUDTemplate, {
        Main = {
            Position = hudStyles.position
        },

        LeftButtons = {
            [RoactCompat.Children] = {
                UIGridLayout = e("UIGridLayout", {
                    CellPadding = UDim2.new(0.15, 0,0.075, 0),
                    CellSize = UDim2.new(0.5, 0, 0.8, 0),
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder
                }, {
                    UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
                        AspectRatio = 1,
                        AspectType = Enum.AspectType.FitWithinMaxSize,
                        DominantAxis = Enum.DominantAxis.Width,
                    }),
                }),

                Backpack = e(HUDButton, {
                    buttonTemplateName = "BackpackButton",

                    activated = function()
                        if props.menuState == "gameplay" then
                            ReplicatedStorage.Bindables.SetGuiState:Fire("backpack")   
                        else
                            ReplicatedStorage.Bindables.SetGuiState:Fire("gameplay")   
                        end
                    end
                })
            }
        },

        TopButtons = {
            [RoactCompat.Children] = {
                UIGridLayout = e("UIGridLayout", {
                    CellPadding = UDim2.new(0.15, 0,0.075, 0),
                    CellSize = UDim2.new(0.5, 0, 0.8, 0),
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder
                }, {
                    UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
                        AspectRatio = 1,
                        AspectType = Enum.AspectType.FitWithinMaxSize,
                        DominantAxis = Enum.DominantAxis.Width,
                    })
                }),

                SettingsButton = e(HUDButton, {
                    buttonTemplateName = "SettingsButton"
                }),

                CodesButton = e(HUDButton, {
                    buttonTemplateName = "CodesButton"
                })
            }
        },

        ShopButtonHolder = {
            Size = shopButtonStyles.size,
        },

        ShopButton = {    
            [React.Event.MouseEnter] = function()
                shopButtonApi.start({
                    size = UDim2.new(0.148 * 1.2, 0, 0.062 * 1.2, 0)
                })
            end,

            [React.Event.MouseLeave] = function()
                shopButtonApi.start({
                    size = UDim2.new(0.148, 0, 0.062, 0)
                })
            end,

            [React.Event.Activated] = function()
                shopButtonApi.start({
                    size = UDim2.new(0.148, 0, 0.062, 0)
                })
            end
        },
    })
end
