
local PlayerdataSystem = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ReplicatedStorage.Shared.Packages.ProfileService)

local SaveFileTemplate = require(script.SaveFileTemplate)
local ProductFunctions = require(script.ProductFunctions)
local PurchaseIdLog = 50

local GameProfileStore = ProfileService.GetProfileStore(
    "PlayerData-6",
    SaveFileTemplate
)

local USE_MOCK_STORES = true

local Profiles = {} 

local function PlayerAdded(player)
    local profile 

    if USE_MOCK_STORES then
        profile = GameProfileStore.Mock:LoadProfileAsync("Player_" .. player.UserId)
    else
        profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    end

    if profile ~= nil then
        profile:AddUserId(player.UserId) 
        profile:Reconcile()
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick() 
        end)
        if player:IsDescendantOf(Players) == true then
            Profiles[player] = profile

            for key,value in profile.Data do
                if key == "IsFlaggedForExploit" then continue end

                if typeof(value) == "table" then
                    value = HttpService:JSONEncode(value)
                end

                player:SetAttribute(key, value)

                player:GetAttributeChangedSignal(key):Connect(function()
                    profile.Data[key] = player:GetAttribute(key)
                end)
            end
        else
            profile:Release() 
        end
    else
        player:Kick() 
    end
end

local function PurchaseIdCheckAsync(profile, purchase_id, grant_product_callback) --> Enum.ProductPurchaseDecision

    if profile:IsActive() ~= true then

        return Enum.ProductPurchaseDecision.NotProcessedYet

    else

        local meta_data = profile.MetaData

        local local_purchase_ids = meta_data.MetaTags.ProfilePurchaseIds
        if local_purchase_ids == nil then
            local_purchase_ids = {}
            meta_data.MetaTags.ProfilePurchaseIds = local_purchase_ids
        end

        if table.find(local_purchase_ids, purchase_id) == nil then
            while #local_purchase_ids >= PurchaseIdLog do
                table.remove(local_purchase_ids, 1)
            end
            table.insert(local_purchase_ids, purchase_id)
            task.spawn(grant_product_callback)
        end

        local result = nil

        local function check_latest_meta_tags()
            local saved_purchase_ids = meta_data.MetaTagsLatest.ProfilePurchaseIds
            if saved_purchase_ids ~= nil and table.find(saved_purchase_ids, purchase_id) ~= nil then
                result = Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end

        check_latest_meta_tags()

        local meta_tags_connection = profile.MetaTagsUpdated:Connect(function()
            check_latest_meta_tags()
            -- When MetaTagsUpdated fires after profile release:
            if profile:IsActive() == false and result == nil then
                result = Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end)

        while result == nil do
            task.wait()
        end

        meta_tags_connection:Disconnect()

        return result

    end

end

local function GetPlayerProfileAsync(player)
    local profile = Profiles[player]

    while profile == nil and player:IsDescendantOf(Players) == true do
        task.wait()
        profile = Profiles[player]
    end

    return profile
end

local function GrantProduct(player, product_id)
    local profile = Profiles[player]
    local product_function = ProductFunctions[product_id]
    if product_function ~= nil then
        product_function(profile)
    else
        warn("ProductId " .. tostring(product_id) .. " has not been defined in Products table")
    end
end

local function ProcessReceipt(receipt_info)
    local player = Players:GetPlayerByUserId(receipt_info.PlayerId)

    if player == nil then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local profile = GetPlayerProfileAsync(player)

    if profile ~= nil then

        return PurchaseIdCheckAsync(
            profile,
            receipt_info.PurchaseId,
            function()
                GrantProduct(player, receipt_info.ProductId)
            end
        )

    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

function PlayerdataSystem.Start()
    for _, player in Players:GetPlayers() do
        task.spawn(PlayerAdded, player)
    end

    MarketplaceService.ProcessReceipt = ProcessReceipt

    Players.PlayerAdded:Connect(PlayerAdded)

    Players.PlayerRemoving:Connect(function(player)
        local profile = Profiles[player]
        if profile ~= nil then
            profile:Release()
        end
    end)
end

function PlayerdataSystem.EditProfileData(player, key, value)
    local profile = Profiles[player] 

    if profile then
        profile.Data[key] = value
    end
end

ReplicatedStorage.GetSaveTemplate.OnServerInvoke = function()
    return SaveFileTemplate
end

return PlayerdataSystem