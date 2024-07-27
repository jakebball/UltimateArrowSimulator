local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = {}
local networkIndex = {}

function Network.Start()
    task.spawn(function()
        while true do
            for eventName, uniqueId in networkIndex do 
                local newId = HttpService:GenerateGUID(false)
             
                networkIndex[eventName] = newId
                ReplicatedStorage.Network[uniqueId].Name = newId
            end

            ReplicatedStorage.Network.NetworkSync:FireAllClients(networkIndex)

            task.wait(1)
        end
    end)
end

function Network.GetEvent(eventName)
    assert(typeof(eventName) == "string", "Event must be a string")

    if networkIndex[eventName] == nil then
        local eventId = HttpService:GenerateGUID(false)

        local event = Instance.new("RemoteEvent")
        event.Name = eventId
        event.Parent = ReplicatedStorage.Network

        networkIndex[eventName] = eventId

        return event
    else
        return networkIndex[eventName].instance
    end
end

function Network.GetFunction(functionName)
    assert(typeof(functionName) == "string", "Event must be a string")
    
    if networkIndex[functionName] == nil then
        local functionId = HttpService:GenerateGUID(false)

        local remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = functionId
        remoteFunction.Parent = ReplicatedStorage.Network

        networkIndex[functionName] = functionId
    else
        return networkIndex[functionName].instance
    end
end


return Network