local ModelUtils = {}

local modelInvisiblity = {}

function ModelUtils.ToggleVisiblity(model, state, customInvisibleTransparency)
	if modelInvisiblity[model] == nil then
		modelInvisiblity[model] = true

		for _, v in model:GetDescendants() do
			if v:IsA("BasePart") then
				v:SetAttribute("ModelUtils_Transparency", v.Transparency)
			end
		end

		model.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				modelInvisiblity[model] = nil
			end
		end)
	end

	if state then
		for _, v in model:GetDescendants() do
			if v:IsA("BasePart") then
				v.Transparency = v:GetAttribute("ModelUtils_Transparency")
			end
		end
	else
		for _, v in model:GetDescendants() do
			if v:IsA("BasePart") then
				v.Transparency = if customInvisibleTransparency then customInvisibleTransparency else 1
			end
		end
	end
end

return ModelUtils
