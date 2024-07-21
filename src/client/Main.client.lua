
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

task.spawn(function()
    require(script.Parent.SaveTemplate)
end)

local function startReact(systems)
    local e = React.createElement

    local App = require(script.Parent.Gui.App)
    
    local root = ReactRoblox.createRoot(Instance.new("Folder"))
    root:render(ReactRoblox.createPortal(e(App, { systems = systems }), Players.LocalPlayer.PlayerGui))
end

local function startSystems()
        
    local systems = {}

    for _,systemModule in script.Parent.Systems:GetChildren() do
        local system = require(systemModule)
        systems[systemModule.Name] = system
    end

    for systemName, system in systems do
        print("Starting Client System: " .. systemName)

        if system.Start then
            system.Start(systems)
        end
    end

    return systems
end

print("Starting Client Systems")
local systems = startSystems()
startReact(systems)
print("Finished Client Systems Start")