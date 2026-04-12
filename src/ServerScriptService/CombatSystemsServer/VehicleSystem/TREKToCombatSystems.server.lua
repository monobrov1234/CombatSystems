-- TREK to CombatSystems vehicle rigger script
--!strict

if not game:GetService("RunService"):IsStudio() then return end
local funcs = {}

-- IMPORTS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LoggerUtil = require(ReplicatedStorage.CombatSystemsShared.Utils.LoggerUtil)

-- ROBLOX OBJECTS
local trekVehiclesFolder = workspace:FindFirstChild("TrekVehicles") :: Folder?
local portedVehiclesFolder = workspace:FindFirstChild("TrekVehiclesPorted") :: Folder?
if not trekVehiclesFolder or not trekVehiclesFolder:IsA("Folder") or not portedVehiclesFolder or not portedVehiclesFolder:IsA("Folder") then return end

-- FINALS
local log: LoggerUtil.SelfObject = LoggerUtil.new("TREKToCombatSystems")

function funcs.start()
    task.wait(2)

    for _, vehicle: Instance in ipairs(trekVehiclesFolder:GetChildren()) do
        if not vehicle:IsA("Model") then continue end
        if not funcs.stripTVehicle(vehicle) then continue end
        funcs.cleanupVehicle(vehicle)
        if not funcs.translateParts(vehicle) then continue end
        if not funcs.translateWheels(vehicle) then continue end
        if not funcs.translateTurret(vehicle) then continue end

        local chassis = vehicle:FindFirstChild("Chassis") :: BasePart?
        assert(chassis and chassis:IsA("BasePart"))

        -- adjust vehicle center of mass
        local wheelParts = {} :: {BasePart}
        local wheels = (vehicle:FindFirstChild("Wheels") or vehicle:FindFirstChild("Tracks")) :: Model?
        assert(wheels and wheels:IsA("Model"))
        for _, wheel: Instance in ipairs(wheels:GetDescendants()) do
            if wheel:HasTag("Wheel") then
                table.insert(wheelParts, wheel :: BasePart)
            end
        end

        if #wheelParts == 0 then
            log:error("Vehicle {} has no wheels!", vehicle.Name)
            continue
        end

        local sum = Vector3.zero
        for _, wp in wheelParts do
            sum += wp.Position
        end

        local center = sum / #wheelParts
        local cf = chassis.CFrame
        chassis.CFrame = CFrame.new(center) * (cf - cf.Position)
		
		vehicle:AddTag("VehicleControl")
		vehicle:SetAttribute("DObjectArmor", "BulletProofArmor")
		vehicle.PrimaryPart = chassis

        -- move the vehicle to the ported vehicles folder
        vehicle.Parent = portedVehiclesFolder

        log:info("Successfully ported vehicle {}", vehicle.Name)
    end
end

function funcs.stripTVehicle(vehicle: Model): boolean -- step 1
    local tVehicle = vehicle:FindFirstChild("TVehicle") :: Model?
    if not tVehicle or not tVehicle:IsA("Model") then
        log:error("Vehicle {} doesn't have TVehicle model!", vehicle.Name)
        return false 
    end 
    
    for _, child: Instance in tVehicle:GetChildren() do
        child.Parent = vehicle
    end
    
    tVehicle:Destroy()
    return true
end

function funcs.cleanupVehicle(vehicle: Model) -- step 2
    local statsFolder: Instance? = vehicle:FindFirstChild("Stats")
    if statsFolder and statsFolder:IsA("Folder") then
        statsFolder:Destroy()
    end
    
    local wobbleAxis = vehicle:FindFirstChild("WobbleAxis") :: BasePart?
    if wobbleAxis then
        wobbleAxis:Destroy()
    end

    -- destroy trash - values, proximity prompts, scripts, folders, attributes
    for _, descendant: Instance in vehicle:GetDescendants() do
        if descendant:IsA("ValueBase")
            or descendant:IsA("ProximityPrompt")
            or descendant:IsA("Script") 
            or descendant:IsA("LocalScript")
            or (descendant:IsA("Folder") and (descendant.Name == "TeamLock" or descendant.Name == "GroupLock"))
        then
            descendant:Destroy()
        end
        
        for attribute: string, value: any in pairs(descendant:GetAttributes()) do
            if attribute == "RBXRefinementScale" then continue end
            descendant:SetAttribute(attribute, nil)
        end
    end
end

function funcs.translateParts(vehicle: Model): boolean -- step 3
    -- core to chassis
    local core = vehicle:FindFirstChild("Core") :: BasePart?
    if not core or not core:IsA("BasePart") then
        log:error("Vehicle {} doesn't have Core part!", vehicle.Name)
        return false
    end
    core.Name = "Chassis"

    local systemParts = vehicle:FindFirstChild("SystemParts") :: Model?
    if not systemParts or not systemParts:IsA("Model") then
        log:error("Vehicle {} doesn't have SystemParts model!", vehicle.Name)
        return false
    end

    -- driver dismount
    local driverExit = (systemParts:FindFirstChild("DriverExit") or systemParts:FindFirstChild("DriverGunnerExit")) :: BasePart?
    if not driverExit or not driverExit:IsA("BasePart") then
        log:error("Vehicle {} doesn't have any driver exit part!", vehicle.Name)
        return false
    end
    driverExit.Name = "DismountPart"
    driverExit.Parent = vehicle

    -- cameras
    local camera = systemParts:FindFirstChild("VehicleCamera") :: BasePart?
    if not camera or not camera:IsA("BasePart") then
        log:error("Vehicle {} doesn't have VehicleCamera part!", vehicle.Name)
        return false
    end
    camera.Name = "Camera"
    camera.Parent = vehicle

    local opticCamera = (systemParts:FindFirstChild("OpticCamera") or camera:Clone()) :: BasePart 
    opticCamera.Name = "CameraFirstPerson"
    opticCamera.Parent = vehicle
    
    -- translate passenger seats
    for _, descendant: Instance in vehicle:GetDescendants() do
        if not descendant:IsA("Seat") then continue end
        if descendant.Parent == vehicle then continue end
        descendant.Parent = vehicle
        descendant:AddTag("PassengerSeat")
    end

    return true
end

function funcs.translateWheels(vehicle: Model): boolean -- step 4
    local wheels = vehicle:FindFirstChild("Wheels") :: Model?
    if wheels and wheels:IsA("Model") then
        for _, wheelModel: Instance in ipairs(wheels:GetChildren()) do
            if not wheelModel:IsA("Model") then continue end
            
            local wheel = wheelModel:FindFirstChild("Wheel") :: BasePart?
            if not wheel then continue end
            local parts = wheelModel:FindFirstChild("Parts") :: Instance?
            if not parts then continue end

            for _, part: Instance in ipairs(parts:GetChildren()) do
                if not part:IsA("BasePart") then continue end
                part.Parent = wheel
            end
            parts:Destroy()

            if wheelModel.Name == "FL" then
                wheel:SetAttribute("SteeringDirection", "L")
            elseif wheelModel.Name == "FR" then
                wheel:SetAttribute("SteeringDirection", "R")
            end
            wheel:AddTag("Wheel")
        end
    else
        local tracks = vehicle:FindFirstChild("Tracks") :: Model?
        if not tracks or not tracks:IsA("Model") then
            log:error("Vehicle {} doesn't have any wheels nor tracks", vehicle.Name)
            return false
        end

        for _, trackModel: Instance in ipairs(tracks:GetChildren()) do
            if not trackModel:IsA("Model") then continue end

            for _, wheel: Instance in ipairs(trackModel:GetChildren()) do
                if not wheel:IsA("BasePart") then continue end
            
                if trackModel.Name == "L" then
                    wheel:SetAttribute("TrackSide", "L")
                elseif trackModel.Name == "R" then
                    wheel:SetAttribute("TrackSide", "R")
                end
                wheel:AddTag("Wheel")
            end
        end
    end

    return true
end

function funcs.translateTurret(vehicle: Model): boolean
    local turretBody = vehicle:FindFirstChild("Turret") :: Model?
    if not turretBody then return true end
    local turretGun = vehicle:FindFirstChild("Gun") :: Model?
    if not turretGun then return true end

    local turretBase = turretBody:FindFirstChild("TurretBase") :: BasePart?
    local turret = turretBody:FindFirstChild("Turret") :: BasePart?
    local gunBase = turretGun:FindFirstChild("GunBase") :: BasePart?
    local gun = turretGun:FindFirstChild("Gun") :: BasePart?
    if not turretBase or not turretBase:IsA("BasePart")
            or not turret or not turret:IsA("BasePart") 
            or not gunBase or not gunBase:IsA("BasePart")
            or not gun or not gun:IsA("BasePart") then
        log:warn("Vehicle {} has turret but its structure is incorrect", vehicle.Name)
        return true
    end

    local turretModel = Instance.new("Model")
    turretModel.Name = "PlaceholderTurret"
    turretModel.Parent = vehicle

    -- move body and gun
    turretBody.Parent = turretModel
    turretBody.Name = "Body"
    turretGun.Parent = turretModel
    
    local decorBarrel = vehicle:FindFirstChild("DecorBarrel") :: Model?
    if decorBarrel then
        decorBarrel.Parent = turretGun
    end
    
    local cameraFirstPerson = vehicle:FindFirstChild("CameraFirstPerson")
    assert(cameraFirstPerson)
    cameraFirstPerson.Parent = turretModel
    
    -- pitch base, yaw base
    local yawBase = turretBase
    yawBase.Name = "YawBase"
    yawBase.Parent = turretModel
    local yawTarget = turret
    yawTarget.Name = "BodyRoot"
    turretBody.PrimaryPart = yawTarget
    
    local pitchBase = gunBase
    pitchBase.Name = "PitchBase"
    pitchBase.Parent = turretModel
    local pitchTarget = gun
    pitchTarget.Name = "GunRoot"
    turretGun.PrimaryPart = pitchTarget
    
    -- firing point
    local barrel = turretGun:FindFirstChild("Barrel") :: BasePart?
    if not barrel or not barrel:IsA("BasePart") then
        log:error("Vehicle {} has turret but its structure is incorrect (Barrel)", vehicle.Name)
        return false
    end

    local firingPoint = barrel
    firingPoint.Name = "FiringPoint"
    firingPoint.Parent = turretModel
    local firingPointCoax = turretGun:FindFirstChild("96Barrel") :: BasePart
    if firingPointCoax then
        firingPointCoax.Name = "FiringPointCoax"
        firingPointCoax.Parent = turretModel
    end
    
    -- move seat
    local gunnerSeat = vehicle:FindFirstChild("GunnerSeat") :: VehicleSeat?
    if gunnerSeat then
        local alterSeat = Instance.new("Seat")
        alterSeat.CFrame = gunnerSeat.CFrame
        alterSeat.Size = gunnerSeat.Size
        alterSeat.Transparency = gunnerSeat.Transparency
        alterSeat.CanCollide = false
        alterSeat.CanTouch = false
        alterSeat.CanQuery = false
        alterSeat.Parent = turretModel
        gunnerSeat:Destroy()
    end
    
    -- tag
    turretModel:AddTag("TurretControl")
    return true
end

funcs.start()