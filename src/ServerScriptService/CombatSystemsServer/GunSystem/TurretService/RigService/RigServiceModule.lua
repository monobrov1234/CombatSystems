--!strict

local module = {}

-- IMPORTS
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VehicleSystemConfig = require(ReplicatedStorage.CombatSystemsShared.VehicleSystem.Configs.VehicleSystemConfig)
local TurretConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.TurretConfigUtilModule)
local TurretUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.TurretUtilModule)
local Signal = require(ReplicatedStorage.CombatSystemsShared.Utils.SignalModule)
local RigUtil = require(ServerScriptService.CombatSystemsServer.Utils.RigUtilModule)

-- INTERNAL API
module.SeatPromptTriggered = Signal.new() -- (player: Player, turretInfo: TurretUtil.TurretInfo, prompt: ProximityPrompt)

-- PUBLIC API

-- every turret should be prompted using one of those methods
-- will create proximity prompt for each turret seat that's not a vehicle seat
function module.promptTurrets(instance: Instance)
	local turrets: { Model } = TurretUtil.findDescendantTurrets(instance)
	for _, turretModel: Model in ipairs(turrets) do
		module.promptTurret(turretModel)
	end
end

-- will create proximity prompt for turret seat if it isn't a vehicle seat
function module.promptTurret(turretModel: Model)
	local seat: BasePart? = TurretUtil.findTurretSeat(turretModel)
	if not seat then return end

	local turretInfo = TurretUtil.parseTurretInfo(turretModel)
	local prompt: ProximityPrompt = VehicleSystemConfig.BasePrompt:Clone()
	prompt.ObjectText = turretModel.Name
	prompt.ActionText = "Use"
	prompt.HoldDuration = turretInfo.TurretConfig.SeatConfig.PromptHoldDuration
	prompt.MaxActivationDistance = turretInfo.TurretConfig.SeatConfig.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player: Player)
		module.SeatPromptTriggered:fire(player, turretInfo, prompt)
	end)
	prompt.Parent = seat
end

function module.rigTurrets(instance: Instance)
	local turrets: { Model } = TurretUtil.findDescendantTurrets(instance)
	for _, turretModel: Model in ipairs(turrets) do
		module.rigTurret(turretModel)
	end
end

function module.rigTurret(turret: Model)
	assert(TurretUtil.validateTurret(turret), "Turret doesn't have turret tag")
	local turretConfig = TurretConfigUtil.getConfig(turret.Name)
	assert(turretConfig, "Turret doesn't have config")

	-- find turret seat if exists
	local turretSeat: BasePart? = TurretUtil.findTurretSeat(turret)

	-- find yaw and pitch bases
	local yawBase: BasePart? = turret:FindFirstChild("YawBase") :: BasePart?
	assert(yawBase and yawBase:IsA("Part"), "Turret yaw base part not found")
	local pitchBase: BasePart? = turret:FindFirstChild("PitchBase") :: BasePart?
	assert(pitchBase and pitchBase:IsA("Part"), "Turret pitch base part not found")

	-- find turret body and gun models and their primary parts
	local turretBody: Model? = turret:FindFirstChild("Body") :: Model?
	assert(turretBody and turretBody:IsA("Model"), "Turret body model not found")
	local turretGun: Model? = turret:FindFirstChild("Gun") :: Model?
	assert(turretGun and turretGun:IsA("Model"), "Turret gun model not found")
	local bodyRoot: BasePart? = turretBody.PrimaryPart
	assert(bodyRoot, "No primary part found in turret body model")
	local gunRoot: BasePart? = turretGun.PrimaryPart
	assert(gunRoot, "No primary part found in turret gun model")

	-- find utility parts
	local cameraFirstPerson: BasePart? = turret:FindFirstChild("CameraFirstPerson") :: BasePart?
	assert(cameraFirstPerson and cameraFirstPerson:IsA("BasePart"), "No CameraFirstPerson part found in turret model")
	local firingPoint: BasePart? = turret:FindFirstChild("FiringPoint") :: BasePart?
	assert(firingPoint and firingPoint:IsA("BasePart"), "No FiringPoint part found in turret model")
	local firingPointCoax: BasePart? = turret:FindFirstChild("FiringPointCoax") :: BasePart?
	assert(not turretConfig.GunConfig.EnableCoax or (firingPointCoax and firingPointCoax:IsA("BasePart")), "No FiringPointCoax part found in turret model")

	-- before everything, clear all welds
	for _, descendant: Instance in ipairs(turret:GetDescendants()) do
		if not descendant:IsA("Weld") then continue end
		if descendant.Parent == yawBase then continue end
		if descendant.Parent == turretSeat then continue end
		descendant:Destroy()
	end

	-- weld descendants in Body and Gun models to their root parts
	for _, descendant: Instance in ipairs(turretBody:GetDescendants()) do
		if not descendant:IsA("BasePart") then continue end
		if descendant == bodyRoot then continue end
		RigUtil.weld(descendant, bodyRoot)
	end
	for _, descendant: Instance in ipairs(turretGun:GetDescendants()) do
		if not descendant:IsA("BasePart") then continue end
		if descendant == gunRoot then continue end
		RigUtil.weld(descendant, gunRoot)
	end

	-- setup TurretView folder, assets like music and effects are contained there
	local turretViewFolder: Folder? = turret:FindFirstChild("TurretView") :: Folder?
	if not turretViewFolder then
		turretViewFolder = Instance.new("Folder")
		assert(turretViewFolder)
		turretViewFolder.Name = "TurretView"
		turretViewFolder.Parent = turret
	else
		assert(turretViewFolder:IsA("Folder"))
	end

	-- put all sounds from the config in their corresponding parts
	local soundConfig = turretConfig.DecorConfig.SoundsConfig
	local coaxSoundConfig = turretConfig.GunConfig.CoaxConfig.DecorConfig.SoundsConfig

	local function putSound(name: string, sound: Sound?, parent: Instance)
		if not sound then return end

		local foundDuplicated = parent:FindFirstChild(name)
		if foundDuplicated then foundDuplicated:Destroy() end

		local clone = sound:Clone()
		clone.Name = name
		clone.Parent = parent
	end

	-- firing point
	putSound("Fire", soundConfig.FireSound, firingPoint)
	if firingPointCoax then putSound("FireCoax", coaxSoundConfig.FireSound, firingPointCoax) end

	-- gun root
	putSound("Reload", soundConfig.ReloadSound, gunRoot)
	putSound("ReloadCoax", coaxSoundConfig.ReloadSound, gunRoot)
	putSound("Switch", soundConfig.SwitchSound, gunRoot)

	-- yaw base
	putSound("CoaxSelect", soundConfig.CoaxSelectSound, yawBase)
	putSound("TraverseStart", soundConfig.TraverseStartSound, yawBase)
	putSound("Traverse", soundConfig.TraverseSound, yawBase)
	putSound("TraverseEnd", soundConfig.TraverseEndSound, yawBase)

	-- connect bodyRoot to yawBase
	local yawMotor = Instance.new("Motor6D")
	yawMotor.Name = "YawMotor"
	yawMotor.Part0 = yawBase
	yawMotor.Part1 = bodyRoot
	yawMotor.C0 = yawBase.CFrame:ToObjectSpace(bodyRoot.CFrame)
	yawMotor.Parent = turretViewFolder

	-- weld pitchBase to bodyRoot
	bodyRoot.RootPriority = 1 -- bodyRoot will have priority over PitchBase
	RigUtil.weld(pitchBase, bodyRoot)

	-- connect gunRoot to pitchBase
	local pitchMotor = Instance.new("Motor6D")
	pitchMotor.Name = "PitchMotor"
	pitchMotor.Part0 = pitchBase
	pitchMotor.Part1 = gunRoot
	pitchMotor.C0 = pitchBase.CFrame:ToObjectSpace(gunRoot.CFrame)
	pitchMotor.Parent = turretViewFolder

	-- weld CameraFirstPerson to gunRoot
	RigUtil.weld(cameraFirstPerson, gunRoot)
	-- weld FiringPoint to gunRoot
	RigUtil.weld(firingPoint, gunRoot)
	if firingPointCoax then
		-- weld FiringPointCoax to gunRoot
		RigUtil.weld(firingPointCoax, gunRoot)
	end
end

return module
