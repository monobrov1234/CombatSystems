local module = {}
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.GunUtil)
local Logger = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)

-- IMPORTS INTERNAL
local GunStateService = require(script.Parent.GunStateService)

-- FINALS
local log: Logger.SelfObject = Logger.new("GunService")

function funcs.handleGunEquipped(player: Player, gunInfo: GunUtil.GunInfo)
	local character = player.Character
	if not character then return end
	local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator: Animator? = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	local torso = (humanoid.RigType == Enum.HumanoidRigType.R6
		and character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")) :: BasePart?
	if not torso then return end

	local animPart = gunInfo.Tool:FindFirstChild("AnimPart") :: BasePart
	local toolAnim = Instance.new("Motor6D")
	toolAnim.Name = "toolAnim"
	toolAnim.Part0 = torso
	toolAnim.Part1 = animPart
	toolAnim.Parent = torso

	log:debug("Server gun equipped: {}", gunInfo.Tool.Name)
end

function funcs.handleGunUnequipped(player: Player, gunInfo: GunUtil.GunInfo)
	local character = player.Character
	if not character then return end
	local humanoid: Humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local torso = humanoid.RigType == Enum.HumanoidRigType.R6 and character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then return end

	local toolAnim = torso:FindFirstChild("toolAnim")
	if not toolAnim then return end
	toolAnim:Destroy()

	log:debug("Server gun unequipped: {}", gunInfo.Tool.Name)
end

-- custom
GunStateService.GunEquipped:connect(funcs.handleGunEquipped)
GunStateService.GunUnequipped:connect(funcs.handleGunUnequipped)

return module
