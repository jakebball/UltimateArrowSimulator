
local NetworkSystemClient = {}

local networkIndex = {}

local Network = game.ReplicatedStorage.Network

local Promise = require(game.ReplicatedStorage.Shared.Packages.Promise)

function NetworkSystemClient.Start()
    Network.NetworkSync.OnClientEvent:Connect(function(newNetworkIndex)
        networkIndex = newNetworkIndex
    end)
end

function NetworkSystemClient.promiseGetRemote(remoteName)
    return Promise.new(function(resolve)       
        repeat
            task.wait()
        until networkIndex[remoteName] ~= nil

        resolve(Network[networkIndex[remoteName]])
    end)
end


return NetworkSystemClient