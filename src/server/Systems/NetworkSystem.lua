local HttpService = game:GetService("HttpService")

local NetworkSystem = {}

local networkIndex = {}

local Network = game.ReplicatedStorage.Network

function NetworkSystem.Start()
    task.spawn(function()
        while true do
            for eventName, uniqueId in networkIndex do 
                local newId = HttpService:GenerateGUID(false)

                networkIndex[eventName] = newId
                Network[uniqueId].Name = newId
            end

            Network.NetworkSync:FireAllClients(networkIndex)

            task.wait(1)
        end
    end)
end

function NetworkSystem.GetEvent(eventName)
    assert(typeof(eventName) == "string", "Event must be a string")

    if networkIndex[eventName] == nil then
        local eventId = HttpService:GenerateGUID(false)

        local event = Instance.new("RemoteEvent")
        event.Name = eventId
        event.Parent = Network

        networkIndex[eventName] = eventId

        return event
    else
        return networkIndex[eventName].instance
    end
end

function NetworkSystem.GetFunction(functionName)
    assert(typeof(functionName) == "string", "Event must be a string")
    
    if networkIndex[functionName] == nil then
        local functionId = HttpService:GenerateGUID(false)

        local remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = functionId
        remoteFunction.Parent = Network

        networkIndex[functionName] = functionId
    else
        return networkIndex[functionName].instance
    end
end


return NetworkSystem