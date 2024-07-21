
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local NetworkUtils = require(ReplicatedStorage.Shared.Utils.NetworkUtils)
local ItemUtils = require(ReplicatedStorage.Shared.Utils.ItemUtils)

local BackpackTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.Backpack)

local CloseButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.CloseButton)
local AnimatedButton = require(game.StarterPlayer.StarterPlayerScripts.Client.Gui.Components.AnimatedButton)
local ModeButton = require(script.ModeButton)
local Item = require(script.Item)

local ConfigStyles = require(ReplicatedStorage.Shared.ConfigStyles)
local ButtonStyles = require(ReplicatedStorage.Shared.ButtonStyles)

local SORTING_MODES = {
    "Best",
    "Worst"
}

local e = React.createElement

local BOW_STACK_SIZE = 99

return function(props)

    local backpackStyles = ReactSpring.useSpring({
        position = UDim2.new(if props.visible then 0.5 else -1.5, 0, 0.5, 0),
        config = ConfigStyles.menuTransition
    })

    local backpackMode, setBackpackMode = React.useState("bows")
    local destroyActive, setDestroyActive = React.useState(false)
    local destroyList, setDestroyList = React.useState({})
    local sortMode, setSortMode = React.useState(1)
    local keyIndexToAmount = {}

    local listChildren = {}

    listChildren.UIGridLayout = e("UIGridLayout", {
        CellPadding = UDim2.new(0.03, 0, 0.02, 0),
        CellSize = UDim2.new(0.222, 0, 0.168, 0),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top
    }, {
        UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
            AspectRatio = 1,
            AspectType = Enum.AspectType.FitWithinMaxSize,
            DominantAxis = Enum.DominantAxis.Width
        })
    })

    listChildren.UIPadding = e("UIPadding", {
        PaddingBottom = UDim.new(0, 0),
        PaddingLeft = UDim.new(0.02, 0),
        PaddingRight = UDim.new(0.01, 0),
        PaddingTop = UDim.new(0.01, 0)
    })

    if backpackMode == "bows" then
        for bowId, amount in props.playerdata.bows do

            local remainingBows = amount

            local keyIndex = 1

            local bowIndex = {}

            while remainingBows > 0 do
                local stackSize = math.min(remainingBows, BOW_STACK_SIZE)
                remainingBows = remainingBows - stackSize

                keyIndex += 1

                if bowIndex[bowId] == nil then
                    bowIndex[bowId] = 1
                else
                    bowIndex[bowId] += 1
                end

                local function element(amount, keyIndex)

                    local layoutOrder = 0

                    if sortMode == 1 then
                        layoutOrder = -ItemUtils.getItemScore(bowId)
                    else
                        layoutOrder = ItemUtils.getItemScore(bowId)
                    end

                    local equipped = (props.playerdata.equippedItems.playerBowSlot == bowId) and bowIndex[bowId] == 1

                    if equipped then
                        layoutOrder = -math.huge
                    end
                    
                    return e(Item, {
                        itemType = "Bows",
                        bowId = bowId, 
                        amount = amount,
                        equipped = equipped,
                        isBeingSold = table.find(destroyList, keyIndex) ~= nil,
                        layoutOrder = layoutOrder,

                        activated = function()
                            if destroyActive then
                                setDestroyList(function(prev)
                                    prev = table.clone(prev)
        
                                    local index = table.find(prev, keyIndex)
        
                                    if index then
                                        table.remove(prev, index)
                                    else
                                        table.insert(prev, keyIndex)
                                    end
        
                                    return prev
                                end)
                            else
                                NetworkUtils.firePromiseRemoteEvent(props.systems, "ToggleBowEquip", bowId)
                            end
                        end
                    })
                end

                if stackSize == BOW_STACK_SIZE then
                    listChildren[bowId .. keyIndex] = element(BOW_STACK_SIZE, bowId .. keyIndex)

                    keyIndexToAmount[bowId .. keyIndex] = {
                        amount = BOW_STACK_SIZE,
                        id = bowId
                    }
                else
                    listChildren[bowId .. keyIndex] = element(stackSize, bowId .. keyIndex)

                    keyIndexToAmount[bowId .. keyIndex] = {
                        amount = stackSize,
                        id = bowId 
                    }
                end
            end
        end
    end

    return e(BackpackTemplate, {
        Main = {
            Position = backpackStyles.position,

            [RoactCompat.Children] = {
                Close = e(CloseButton, {
                    position = UDim2.new(1, 0, 0, 0),
                    size = UDim2.new(0.2, 0, 0.2, 0),

                    activated = function()
                        ReplicatedStorage.Bindables.SetGuiState:Fire("gameplay")
                        setDestroyActive(false)
                    end 
                })
            }
        },

        Buttons = {
            [RoactCompat.Children] = {
                UIListLayout = e("UIListLayout", {
                    Padding = UDim.new(0.02, 0),
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center
                }),

                Destroy = (destroyActive == false) and e(AnimatedButton, {
                    size = UDim2.new(0.269, 0, 0.9, 0),
                    style = "cancel",
                    text = "Destroy",
                    layoutOrder = 2,

                    activated = function()
                        setDestroyActive(true)
                    end
                }),
                
                EquipBest = (destroyActive == false) and (backpackMode == "bows") and e(AnimatedButton, {
                    size = UDim2.new(0.269, 0, 0.9, 0),
                    style = "confirm",
                    text = "Equip Best",
                    layoutOrder = 1,

                    activated = function()
                        local scores = {}

                        for bowId, _ in props.playerdata.bows do
                            table.insert(scores, {
                                score = ItemUtils.getItemScore(bowId),
                                id = bowId
                            })
                        end

                        table.sort(scores, function(a, b)
                            return a.score > b.score
                        end)

                        NetworkUtils.firePromiseRemoteEvent(props.systems, "ToggleBowEquip", scores[1].id)
                    end
                }),

                SortBy = (destroyActive == false) and e(AnimatedButton, {
                    size = UDim2.new(0.269, 0, 0.9, 0),
                    style = "option1",
                    text = "Sort By: " .. SORTING_MODES[sortMode],
                    layoutOrder = 3,

                    activated = function()
                        setSortMode(function(prev)
                            return (prev % #SORTING_MODES) + 1
                        end)
                    end
                }),

                CancelDestroy = (destroyActive == true) and e(AnimatedButton, {
                    size = UDim2.new(0.269, 0, 0.9, 0),
                    style = "cancel",
                    text = "Cancel Destroy",
                    layoutOrder = 2,

                    activated = function()
                        setDestroyActive(false)
                        setDestroyList({})
                    end
                }),

                ConfirmDestroy = (destroyActive == true) and e(AnimatedButton, {
                    size = UDim2.new(0.269, 0, 0.9, 0),
                    style = "confirm",
                    text = "Confirm Destroy",
                    layoutOrder = 1,

                    activated = function()
                        setDestroyActive(false)
                        
                        local data = {}
                        
                        for _,key in destroyList do
                            table.insert(data, {
                                id = keyIndexToAmount[key].id,
                                amount = keyIndexToAmount[key].amount
                            })
                        end

                        setDestroyList({})

                        NetworkUtils.firePromiseRemoteEvent(props.systems, "DestroyBows", data)
                    end
                }),
            }
        },

        ModeButtons = {
            [RoactCompat.Children] = {
                UIListLayout = e("UIListLayout", {
                    Padding = UDim.new(0.02, 0),
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center
                }),

                Bows = (destroyActive == false) and e(ModeButton, {
                    size = UDim2.new(0.269, 0, 0.9, 0),
                    style = if backpackMode == "bows" then "confirm" else "option1",
                    isSelected = backpackMode == "bows",
                    text = "Bows",
                    activated = function()
                        setBackpackMode("bows")
                    end
                }),

                Tokens = (destroyActive == false) and e(ModeButton, {
                    size = UDim2.new(0.269, 0, 0.9, 0),
                    style = if backpackMode == "tokens" then "confirm" else "option1",
                    isSelected = backpackMode == "tokens",
                    text = "Tokens",
                    activated = function()
                        setBackpackMode("tokens")
                    end
                }),
            }
        },

        TitleLabel = {
            Text = string.upper(string.sub(backpackMode, 1, 1)) .. string.sub(backpackMode, 2)
        },

        List = {
            [RoactCompat.Children] = listChildren
        },

        SellingGrey = {
            Visible = destroyActive
        }
    })
end
