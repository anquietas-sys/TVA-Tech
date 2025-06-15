AddCSLuaFile()
include("shared.lua")

local SoundScripts = include("tempad/soundscripts.lua")
//local TeleportThroughDoor = include("tempad/teleport.lua")

function ENT:Initialize()
    self:SetModel("models/timedoor/timedoor.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end

    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self:SetTrigger(true)

    -- Play "open" animation on spawn
    local seq = self:LookupSequence("open")
    if seq and seq > 0 then
        self:ResetSequence(seq)
        self:SetCycle(0)
    else
        print("Timedoor: 'open' animation not found!")
    end

    -- Play open sound
    SoundScripts.PlayOpenSound(self:GetPos())

    -- DEBUG: assign nearest partner door on spawn
  //  self:FindNearestPartner()
end
--[[
function ENT:FindNearestPartner()
    local doors = ents.FindByClass("timedoor")
    local nearestDoor = nil
    local nearestDist = math.huge

    for _, door in ipairs(doors) do
        if door ~= self then
            local dist = self:GetPos():Distance(door:GetPos())
            if dist < nearestDist then
                nearestDist = dist
                nearestDoor = door
            end
        end
    end

    self.Partner = nearestDoor

    if IsValid(self.Partner) then
        print(self, "partner set to", self.Partner)
    else
        print(self, "no partner found")
    end
end
]]
function ENT:StartTouch(ent)
    if not IsValid(ent) then return end

    if ent:IsPlayer() then
        self:OnPlayerPass(ent)
        return
    end

    if ent:GetClass() == "prop_physics" then
        local propSize = ent:OBBMaxs() - ent:OBBMins()
        local doorSize = self:OBBMaxs() - self:OBBMins()

        local propLongest = math.max(propSize.x, propSize.y, propSize.z)
        local doorLongest = math.max(doorSize.x, doorSize.y, doorSize.z)

        if propLongest <= (doorLongest * 2) then
            self:OnSmallPropPass(ent)
        end
    end
end

function ENT:OnPlayerPass(ply)
    print(ply:Nick() .. " entered a Time Door.")
    SoundScripts.PlayTravelSound(self:GetPos())

  //  if IsValid(self.Partner) then
    	//print("Calling TeleportThroughDoor with:", ply, self, self.Partner)
		//TeleportThroughDoor(ply, self, self.Partner)
   // end
end

function ENT:OnSmallPropPass(prop)
    print("A small prop passed through a Time Door: " .. tostring(prop))
    SoundScripts.PlayTravelSound(self:GetPos())

 //   if IsValid(self.Partner) then
    	//print("Teleport: traveller", traveller, "entrance", entrance, "exit", exit)
       // TeleportThroughDoor(prop, self, self.Partner)
   // end
end
