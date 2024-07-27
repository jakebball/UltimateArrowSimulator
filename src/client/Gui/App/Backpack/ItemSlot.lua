
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local ItemTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.ItemSlot)

local ItemInfo = require(ReplicatedStorage.Shared.ItemInfo)

local ModelRenderer = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.ModelRenderer)

local e = React.createElement

return function(props)

    local text

    if props.slotType == "Bow" then
        if props.itemId then
            text = ItemInfo[props.itemId].displayName
        else
            text = "Bow Slot"
        end
    end

    local model 
  
    if props.slotType == "Bow" then
        model = ReplicatedStorage.Assets.Bows:FindFirstChild(props.itemId or "")
    end
    
    return e(ItemTemplate, {
        [RoactTemplate.Root] = {
            [RoactCompat.Children] = {
                ModelRenderer = model and e(ModelRenderer, {
                    model = model,
                    size = UDim2.new(1, 0, 1, 0),
                    position = UDim2.new(0.5, 0, 0.5, 0),
                }),
            },
        },

        SlotName = {
            Text = text
        }
    })
end