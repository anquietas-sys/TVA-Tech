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

    local entPos = traveller:GetPos()
    local entAng = traveller:EyeAngles()
    local entVel = traveller:GetVelocity()

    -- Transform position/angle/velocity into entrance local space
    local relPos = WorldToLocal(entPos, Angle(), entrance:GetPos(), entrance:GetAngles())
    local relAng = entAng - entrance:GetAngles()
    local relVel = RotateVectorByAngle(entVel, AngleInverse(entrance:GetAngles()))

    -- Convert to world space from exit's orientation
    local entranceAngles = entrance:GetAngles()
    local exitAngles = exit:GetAngles()
    local localForward = RotateVectorByAngle(entAng:Forward(), AngleInverse(entranceAngles))
    local exitForward = RotateVectorByAngle(localForward, exitAngles)
    local newPos = LocalToWorld(relPos, Angle(), exit:GetPos(), exit:GetAngles())
    local newAng = exitForward:Angle()
    local newVel = RotateVectorByAngle(relVel, exit:GetAngles())

    traveller:SetPos(newPos)

    if traveller:IsPlayer() then
        traveller:SetEyeAngles(newAng)
        traveller:SetVelocity(-traveller:GetVelocity()) -- Cancel current movement
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
