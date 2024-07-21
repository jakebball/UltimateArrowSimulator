
local CameraUtils = {}

local TweenService = game:GetService("TweenService")

local tween

function CameraUtils.setBlur(enabled, size)
    if workspace.CurrentCamera:FindFirstChild("Blur") == nil then
        local blur = Instance.new("BlurEffect")
        blur.Name = "Blur"
        blur.Size = 0
        blur.Parent = workspace.CurrentCamera
    end

    if tween then
        tween:Cancel()
    end

    if enabled then
        tween = TweenService:Create(workspace.CurrentCamera.Blur, TweenInfo.new(0.25), { Size = size })
        tween:Play()
    else
        tween = TweenService:Create(workspace.CurrentCamera.Blur, TweenInfo.new(0.25), { Size = 0 })
        tween:Play()
    end
end

function CameraUtils.fitBoundingBoxToCamera(size, fovDeg, aspectRatio)
	local radius = CameraUtils.getCubeoidDiameter(size)/2
	return CameraUtils.fitSphereToCamera(radius, fovDeg, aspectRatio)
end

function CameraUtils.fitSphereToCamera(radius, fovDeg, aspectRatio)
	local halfFov = 0.5 * math.rad(fovDeg)
	if aspectRatio < 1 then
		halfFov = math.atan(aspectRatio * math.tan(halfFov))
	end

	return radius / math.sin(halfFov)
end

function CameraUtils.getCubeoidDiameter(size)
	return math.sqrt(size.x^2 + size.y^2 + size.z^2)
end

return CameraUtils