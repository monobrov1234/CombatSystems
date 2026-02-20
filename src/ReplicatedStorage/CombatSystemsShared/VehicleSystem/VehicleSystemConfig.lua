local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")

local config = {
	FolderTag = "SpawnableVehicles", -- can be any instance, all vehicles that can be spawned should be there
	Folder = (nil :: any) :: Folder, -- will be set internally to a folder resolved by the FolderTag attribute

	Tag = "VehicleControl", -- Vehicle model should have this tag for vehicle system to recognize it as a vehicle
	DismountPartName = "DismountPart", -- on exit, player will be teleported to that part, it should be direct child of the vehicle model
	PassengerSeatTag = "PassengerSeat", -- all seats in vehicle model with this tag will be rigged as passenger seats and will have proximity prompts
	TeamAttribute = "VehicleTeam", -- used to determine if the vehicle is friendly or not

	VehicleAccessToolTag = "VehicleAccessTool", -- access admin tool, player will be able to enter in any vehicle if he have this tool
	VehicleDeleterToolTag = "VehicleDeleterTool", -- deleter admin tool, allows to select and delete vehicles
	VehicleSpawnerToolTag = "VehicleSpawnerTool", -- spawner admin tool, allows to spawn any vehicle

	-- will be called on vehicle sit, to hide player tools and tool gui (VehicleControllerLocal)
	HideToolsCallback = function(character: Model, humanoid: Humanoid)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		humanoid:UnequipTools()
	end,

	-- wil be called on vehicle dismount, to show player tool gui (VehicleControllerLocal)
	ShowToolsCallback = function(character: Model, humanoid: Humanoid)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end,

	BasePrompt = script.BasePrompt, -- this will be used for all vehicle system prompts (spawner prompts, driver prompts, passenger prompts, etc.)
}

-- find and set the config folder
for _, tagged: Instance in ipairs(CollectionService:GetTagged(config.FolderTag)) do
	assert(tagged:IsA("Folder"))
	assert(not config.Folder, "Multiple instances tagged by the VehicleSystemConfig FolderTag detected. There must be only one")
	config.Folder = tagged
end
assert(config.Folder, "VehicleSystem spawnable vehicles folder not found, please create one")

return config
