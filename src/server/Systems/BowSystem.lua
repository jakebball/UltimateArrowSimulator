
local BowSystem = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


function BowSystem.ToggleBowEquip(player, bowId)

    local bows = HttpService:JSONDecode(player:GetAttribute("bows"))

    if bows[bowId] == nil then 
        --flag user
        return 
    end

    local equippedItems = HttpService:JSONDecode(player:GetAttribute("equippedItems"))

    if equippedItems.playerBowSlot == bowId then
        equippedItems.playerBowSlot = nil
        player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
        return
    end
    
    equippedItems.playerBowSlot = bowId

    player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
end

function BowSystem.DestroyBows(player, destroyData)

    local bows = HttpService:JSONDecode(player:GetAttribute("bows"))
    local equippedItems = HttpService:JSONDecode(player:GetAttribute("equippedItems"))

    for _,v in destroyData do
        
        local bowId = v.id
        local amount = v.amount

        if bows[bowId] == nil then 
            --flag user
            return 
        end

        if bows[bowId] and amount > bows[bowId] then 
            --flag user
            return 
        end
        
        local newAmount = bows[bowId] - amount
        bows[bowId] = newAmount

        if newAmount ==0 and equippedItems.playerBowSlot == bowId then
            equippedItems.playerBowSlot = nil
            player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
        end
    end

    player:SetAttribute("equippedItems", HttpService:JSONEncode(equippedItems))
    player:SetAttribute("bows", HttpService:JSONEncode(bows))
end

function BowSystem.Start()
    BowSystem.Systems.NetworkSystem.GetEvent("ToggleBowEquip").OnServerEvent:Connect(BowSystem.ToggleBowEquip)
    BowSystem.Systems.NetworkSystem.GetEvent("DestroyBows").OnServerEvent:Connect(BowSystem.DestroyBows)
end

return BowSystem    