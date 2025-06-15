local _Angle = Angle

local function AngleInverse(ang)
    return _Angle(-ang.p, -ang.y, -ang.r)
end

local function TeleportThroughDoor(traveller, entrance, exit)
    if not (IsValid(traveller) and IsValid(entrance) and IsValid(exit)) then return end

    local entPos = traveller:GetPos()
    local entAng = traveller:GetAngles()
    local entVel = traveller:GetVelocity()

    local entAngEntrance = entrance:GetAngles()
    local invEntranceAng = AngleInverse(entAngEntrance)

    local relativePos = invEntranceAng:RotateVector(entPos - entrance:GetPos())
    local relativeAng = entAng - entAngEntrance
    local relativeVel = invEntranceAng:RotateVector(entVel)

    local exitAng = exit:GetAngles()

    local newPos = exit:GetPos() + exitAng:RotateVector(relativePos)
    local newAng = relativeAng + exitAng
    local newVel = exitAng:RotateVector(relativeVel)

    traveller:SetPos(newPos)
    traveller:SetAngles(newAng)

    local phys = traveller:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(newVel)
    elseif traveller:IsPlayer() then
        traveller:SetVelocity(newVel)
        traveller:SetEyeAngles(newAng)
    end
end

return TeleportThroughDoor
