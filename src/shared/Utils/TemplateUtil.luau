--!strict
--[[
    TemplateUtil.luau
    Shared API utility for resolving and cloning Studio templates from ReplicatedStorage.Templates.
    Location: src/shared/Utils/TemplateUtil.luau
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TemplateUtil = {}

--- Resolves or initializes the master CoinTemplate in ReplicatedStorage.Templates
function TemplateUtil.GetCoinTemplate(): BasePart
	local templatesFolder = ReplicatedStorage:FindFirstChild("Templates")
	if not templatesFolder then
		templatesFolder = Instance.new("Folder")
		templatesFolder.Name = "Templates"
		templatesFolder.Parent = ReplicatedStorage
	end

	local template = templatesFolder:FindFirstChild("CoinTemplate") :: BasePart?
	if not template then
		template = Instance.new("Part")
		template.Name = "CoinTemplate"
		template.Shape = Enum.PartType.Cylinder
		template.Size = Vector3.new(0.5, 2.5, 2.5)
		template.Orientation = Vector3.new(0, 0, 90)
		template.Color = Color3.fromRGB(255, 215, 0)
		template.Material = Enum.Material.Neon
		template.Anchored = true
		template.CanCollide = false
		template.Parent = templatesFolder
	end

	return template
end

--- Clones a fresh instance of CoinTemplate
function TemplateUtil.CloneCoinTemplate(): BasePart
	return TemplateUtil.GetCoinTemplate():Clone()
end

return TemplateUtil
