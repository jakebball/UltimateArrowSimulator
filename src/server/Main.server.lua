
local function startSystems()
    
    local systems = {}

    for _,systemModule in script.Parent.Systems:GetChildren() do
        local system = require(systemModule)
        systems[systemModule.Name] = system
    end

    for systemName, system in systems do
        print("Starting system: " .. systemName)
        system.Systems = systems

        if system.Start ~= nil then
            system.Start()
        end
    end
end

print("Starting Server Systems")
startSystems()
print("Server Systems Start Finished")