local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkClient = {}

local networkIndex = {}

local Promise = require(ReplicatedStorage.Shared.Packages.Promise)

function NetworkClient.Start()
	ReplicatedStorage.Network.NetworkSync.OnClientEvent:Connect(function(newNetworkIndex)
		networkIndex = newNetworkIndex
	end)
end

function NetworkClient.PromiseGetRemote(remoteName)
	return Promise.new(function(resolve)
		repeat
			task.wait()
		until networkIndex[remoteName] ~= nil

		resolve(ReplicatedStorage.Network[networkIndex[remoteName]])
	end)
end

return NetworkClient
