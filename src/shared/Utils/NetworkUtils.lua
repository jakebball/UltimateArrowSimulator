local NetworkUtils = {}

local eventConnections = {}

function NetworkUtils.ConnectPromiseRemoteEvent(systems, eventName, func)
	systems.Network.PromiseGetRemote(eventName):andThen(function(remote)
		eventConnections[eventName] = remote.OnClientEvent:Connect(func)
	end)
end

function NetworkUtils.DisconnectRemoteEvent(eventName)
	eventConnections[eventName]:Disconnect()
	eventConnections[eventName] = nil
end

function NetworkUtils.ConnectPromiseRemoteFunction(systems, eventName, func)
	return systems.Network.PromiseGetRemote(eventName):andThen(function(remote)
		remote.OnClientInvoke = func
	end)
end

function NetworkUtils.FirePromiseRemoteEvent(systems, eventName, ...)
	local args = { ... }

	return systems.Network.PromiseGetRemote(eventName):andThen(function(remote)
		remote:FireServer(unpack(args))
	end)
end

function NetworkUtils.InvokePromiseRemoteFunction(systems, eventName, ...)
	local args = { ... }

	return systems.Network.PromiseGetFunction(eventName):andThen(function(remote)
		remote:InvokeServer(unpack(args))
	end)
end

return NetworkUtils
