
local NetworkUtils = {}

function NetworkUtils.connectPromiseRemoteEvent(systems, eventName, func)
    return systems.Network.promiseGetRemote(eventName):andThen(function(remote)
        remote.OnClientEvent:Connect(func)
    end)
end

function NetworkUtils.connectPromiseRemoteFunction(systems, eventName, func)
    return systems.Network.promiseGetRemote(eventName):andThen(function(remote)
        remote.OnClientInvoke = func
    end)
end


function NetworkUtils.firePromiseRemoteEvent(systems, eventName, ...)

    local args = {...}

    return systems.Network.promiseGetRemote(eventName):andThen(function(remote)
        remote:FireServer(unpack(args))
    end)
end

function NetworkUtils.invokePromiseRemoteFunction(systems, eventName, ...)

    local args = {...}

    return systems.Network.promiseGetFunction(eventName):andThen(function(remote)
        remote:InvokeServer(unpack(args))   
    end)
end

return NetworkUtils