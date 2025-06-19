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
    local relPos = WorldToLocal(entPos, Angle(), entrance:GetPos(), entrance:GetAngles())
    local newPos = LocalToWorld(relPos, Angle(), exit:GetPos(), exit:GetAngles())

    -- Transform velocity relative to entrance into local space
    local localVel = WorldToLocal(entVel, Angle(), Vector(0, 0, 0), entrance:GetAngles())
    local newVel = LocalToWorld(localVel, Angle(), Vector(0, 0, 0), exit:GetAngles())

    -- Transform view direction properly (avoid pitch inversion)
    local localForward = WorldToLocal(entAng:Forward(), Angle(), Vector(0, 0, 0), entrance:GetAngles())
    local exitForward = LocalToWorld(localForward, Angle(), Vector(0, 0, 0), exit:GetAngles())
    local newAng = exitForward:Angle()

    -- Apply teleport
    traveller:SetPos(newPos)

    if traveller:IsPlayer() then
        traveller:SetEyeAngles(newAng)
        traveller:SetVelocity(-traveller:GetVelocity()) -- Cancel movement
        traveller:SetVelocity(newVel)
    else
        traveller:SetAngles(newAng)
        local phys = traveller:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(newVel)
        end
    end
end

return TeleportFunctions
