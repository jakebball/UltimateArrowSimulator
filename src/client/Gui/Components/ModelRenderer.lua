local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local Trove = require(Packages.Trove)

local e = React.createElement

return function(props)
 
    local viewportRef = React.useRef()
  
    React.useEffect(function()
        local trove = Trove.new()

        local model = props.model:Clone()   
        model.Name = "Model"
        model:PivotTo(workspace.ModelCFrame.CFrame)
        model.Parent = viewportRef.current
        trove:Add(model)

        local camera = Instance.new("Camera")
        camera.CFrame = CFrame.lookAt(workspace.ViewportCFrame.Position, workspace.ModelCFrame.Position)
        trove:Add(camera)

        viewportRef.current.CurrentCamera = camera

        return function()
            trove:Destroy()
        end
    end, {props.model, viewportRef})

    React.useEffect(function()
        if props.spinning then

            local defaultModelCFrame = viewportRef.current.Model:GetPivot()

            local connection = game:GetService("RunService").Heartbeat:Connect(function()
                viewportRef.current.Model:PivotTo(viewportRef.current.Model:GetPivot() * CFrame.Angles(0, math.rad(1), 0))
            end)

            return function()
                connection:Disconnect()

                if viewportRef.current then
                    viewportRef.current.Model:PivotTo(defaultModelCFrame)
                end
            end
        end
    end, {props.spinning})

    return e("ViewportFrame", {
        Size = props.size,
        Position = props.position,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ref = viewportRef,
    })
end