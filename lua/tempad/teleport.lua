local TeleportFunctions = {}

-- Inverts an angle's direction
local function AngleInverse(ang)
    return Angle(-ang.p, -ang.y, -ang.r)
end

-- Rotates a local-space vector into world-space using the angle's basis
local function RotateVectorByAngle(vec, ang)
    return ang:Forward() * vec.x + -ang:Right() * vec.y + ang:Up() * vec.z
end

local function TransformToLocalSpace(pos, ang, origin, basisAng)
    local relativePos = pos - origin
    local inverseAng = AngleInverse(basisAng)

    -- Convert world-space vector to local space
    local localPos = RotateVectorByAngle(Vector(
        relativePos:Dot(basisAng:Forward()),
        relativePos:Dot(basisAng:Right()),
        relativePos:Dot(basisAng:Up())
    ), inverseAng)

    local localAng = ang - basisAng
    return localPos, localAng
end

local function TransformToWorldSpace(localPos, localAng, origin, basisAng)
    -- Rotate local-space vector into world-space
    local worldPos = origin + RotateVectorByAngle(localPos, basisAng)
    local worldAng = localAng + basisAng
    return worldPos, worldAng
end

function TeleportFunctions.Teleport(traveller, entrance, exit)
    if not (IsValid(traveller) and IsValid(entrance) and IsValid(exit)) then return end

     -- Prevent teleport if entrance or exit is outside the map bounds
    if not util.IsInWorld(entrance:LocalToWorld(entrance:OBBCenter())) or not util.IsInWorld(exit:LocalToWorld(exit:OBBCenter())) then
        print("Time Door", entrance, "Tried to teleport", traveller, "to point outside the map at", exit)
        return
    end

    local entPos = traveller:GetPos()
    local entAng = traveller:EyeAngles()
    local entVel = traveller:GetVelocity()

    -- Transform position relative to entrance
    local newPos = nil
    if !traveller:IsPlayer() then
        local relPos = WorldToLocal(entPos, Angle(), entrance:GetPos(), entrance:GetAngles())
        newPos = LocalToWorld(relPos, Angle(), exit:GetPos(), exit:GetAngles())
    else
        -- Prevents a bug where players can end up way behind the door in certain scenarios
        newPos = exit:GetPos()
    end

    -- Transform velocity relative to entrance into local space
    local localVel = WorldToLocal(entVel, Angle(), Vector(0, 0, 0), entrance:GetAngles())
    local newVel = LocalToWorld(localVel, Angle(), Vector(0, 0, 0), exit:GetAngles())

    -- Compute relative angle between entrance and entity
    local entranceAng = entrance:GetAngles()
    local exitAng = exit:GetAngles()

    if traveller:IsPlayer() then 
        entAngWorld = traveller:EyeAngles()
    else 
        entAngWorld = traveller:GetAngles()
    end

    -- Convert world angle to local (relative to entrance)
    local localAng = entAngWorld - entranceAng

    -- Apply local angle relative to exit
    local transformedAng = localAng + exitAng

    -- Apply teleport
    traveller:SetPos(newPos)

    if traveller:IsPlayer() then
        local currentVelocity = -(traveller:GetVelocity())

        timer.Simple(0, function()
            if not IsValid(traveller) then return end

            -- Use fully transformed pitch and yaw for eye angles
            traveller:SetEyeAngles(Angle(transformedAng.p, transformedAng.y, 0))

            -- Set player model yaw (pitch and roll 0 to keep upright)
            traveller:SetAngles(Angle(0, transformedAng.y, 0))

            -- Set velocity (zero then apply new velocity)
            traveller:SetLocalVelocity(Vector(0,0,0))
            traveller:SetVelocity(newVel)
        end)
    else
        local entAng = traveller:GetAngles()
        local entranceAng = entrance:GetAngles()
        local exitAng = exit:GetAngles()

        -- Calculate the local angle of the prop relative to the entrance portal
        local localAng = entAng - entranceAng

        -- Reapply this local angle relative to the exit portal
        local newAng = localAng + exitAng

        -- Set the new angle on the entity
        traveller:SetAngles(newAng)
        local phys = traveller:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(Vector(0,0,0))
            phys:SetVelocity(newVel)
        end
    end
end

return TeleportFunctions