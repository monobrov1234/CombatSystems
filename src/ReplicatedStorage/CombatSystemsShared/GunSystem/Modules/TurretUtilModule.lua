--!strict

local module = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TurretConfig = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Configs.TurretConfig)
local TurretConfigUtil = require(ReplicatedStorage.CombatSystemsShared.GunSystem.Modules.ConfigUtils.TurretConfigUtilModule)

-- FINALS
export type TurretInfo = {
	TurretModel: Model,
	TurretSeat: BasePart?,
	TurretConfig: TurretConfigUtil.DefaultType,
	TurretViewFolder: Folder,
	YawMotor: Motor6D,
	PitchMotor: Motor6D,
	CameraFirstPerson: BasePart,
	FiringPoint: BasePart,
	FiringPointCoax: BasePart?,
}

-- used in both TurretService and client
export type TurretStateInfo = {
	SelectedMunition: string,
	ClipSizeStorage: { [string]: number },
	MunitionStorage: { [string]: number },
	UsingMainGun: boolean,
	CoaxClipSize: number,
	CoaxAmmoSize: number,
}

function module.validateTurret(turretModel: Model): boolean
	return turretModel:HasTag(TurretConfig.Tag)
end

function module.findTurretSeat(turretModel: Model): Seat?
	return turretModel:FindFirstChild("TurretSeat") :: Seat?
end

function module.parseTurretInfo(turretModel: Model): TurretInfo
	assert(module.validateTurret(turretModel), "Turret doesn't have turret tag")

	-- find turret seat, it can be null
	local turretSeat = turretModel:FindFirstChild("TurretSeat") :: BasePart?
	assert(not turretSeat or turretSeat:IsA("BasePart"), "Turret model doesn't have TurretSeat BasePart")

	-- find turret config
	local turretConfig: TurretConfigUtil.DefaultType = TurretConfigUtil.getConfig(turretModel.Name)
	assert(turretConfig, "Turret " .. turretModel.Name .. "doesn't have config")

	-- find TurretView folder
	local viewFolder = turretModel:FindFirstChild("TurretView") :: Folder?
	assert(viewFolder and viewFolder:IsA("Folder"), "Turret model doesn't have TurretView folder")

	-- find turret motors
	local foundYawMotor = viewFolder:FindFirstChild("YawMotor") :: Motor6D?
	local foundPitchMotor = viewFolder:FindFirstChild("PitchMotor") :: Motor6D?
	assert(
		foundYawMotor and foundPitchMotor and foundYawMotor:IsA("Motor6D") and foundPitchMotor:IsA("Motor6D"),
		"No YawMotor or PitchMotor found in TurretView folder"
	)

	-- find utility parts
	local foundCameraFirstPerson = turretModel:FindFirstChild("CameraFirstPerson") :: BasePart?
	assert(foundCameraFirstPerson and foundCameraFirstPerson:IsA("BasePart"), "Turret model doesn't have CameraFirstPerson part")
	local foundFiringPoint = turretModel:FindFirstChild("FiringPoint") :: Attachment?
	assert(foundFiringPoint and foundFiringPoint:IsA("BasePart"), "Turret model doesn't have FiringPoint part")
	local foundFiringPointCoax = turretModel:FindFirstChild("FiringPointCoax") :: BasePart?
	assert(
		not turretConfig.GunConfig.EnableCoax or (foundFiringPointCoax and foundFiringPointCoax:IsA("BasePart")),
		"Turret have coax enabled but doesn't have FiringPointCoax part"
	)

	return {
		TurretModel = turretModel,
		TurretSeat = turretSeat,
		TurretConfig = turretConfig,
		TurretViewFolder = viewFolder,
		YawMotor = foundYawMotor,
		PitchMotor = foundPitchMotor,
		CameraFirstPerson = foundCameraFirstPerson,
		FiringPoint = foundFiringPoint,
		FiringPointCoax = foundFiringPointCoax,
	}
end

function module.findDescendantTurrets(instance: Instance): { Model }
	local found = {} :: { Model }
	for _, descendant: Instance in ipairs(instance:GetDescendants()) do
		if not descendant:IsA("Model") then continue end
		if module.validateTurret(descendant) then table.insert(found, descendant :: Model) end
	end
	return found
end

return module
