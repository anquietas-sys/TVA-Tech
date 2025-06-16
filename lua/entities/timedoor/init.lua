AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local SoundScripts = include("tempad/soundscripts.lua")
local TeleportFunctions = include("tempad/teleport.lua")
local config = include("tempad/config.lua")

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

    self.Open = false
    self.Partner = nil

    self.DebugTrigger = true

    self.UseCooldown = CurTime()

    if !self.Open then
        self:OpenDoor()
    end

end

function ENT:Use()
    if CurTime() >= self.UseCooldown then
        self.DebugTrigger = !self.DebugTrigger
        self:SetTrigger(self.DebugTrigger)

        Entity(1):ChatPrint(tostring(self.DebugTrigger))

        self.UseCooldown = CurTime() + 1
    end
end

function ENT:StartTouch(ent)
    if not IsValid(ent) then return end

    if ent:IsPlayer() then
        self:OnPlayerPass(ent)
    end

    if ent:GetClass() != "timedoor" then
        local propSize = ent:OBBMaxs() - ent:OBBMins()
        local doorSize = self:OBBMaxs() - self:OBBMins()

        local propLongest = math.max(propSize.x, propSize.y, propSize.z)
        local doorLongest = math.max(doorSize.x, doorSize.y, doorSize.z)

        if propLongest <= (doorLongest * 2) then
            self:OnSmallPropPass(ent)
        end
    end

    if ent:GetClass() == "timedoor" then
        self.Partner = ent
        ent.Partner = self
    end
end

function ENT:OnPlayerPass(ply)
  //  print(ply:Nick() .. " entered a Time Door.")
    SoundScripts.PlayTravelSound(self:GetPos())

    if ply.TimeDoorCooldown == nil then
        ply.TimeDoorCooldown = CurTime()
    end

    if CurTime() >= ply.TimeDoorCooldown then
        // Player is entering time door
        ply.TimeDoorCooldown = CurTime() + 0.1
        TeleportFunctions.Teleport(ply, self, self.Partner)
    end
end

function ENT:OnSmallPropPass(prop)
  //  print("A small prop passed through a Time Door: " .. tostring(prop))
    SoundScripts.PlayTravelSound(self:GetPos())

    if prop.TimeDoorCooldown == nil then
        prop.TimeDoorCooldown = CurTime()
    end

    if CurTime() >= prop.TimeDoorCooldown then
        // Player is entering time door
        prop.TimeDoorCooldown = CurTime() + 0.1
        TeleportFunctions.Teleport(prop, self, self.Partner)
    end
end

function ENT:OpenDoor()
    -- Play "open" animation on spawn
    local seq = self:LookupSequence("open")
    self:SetCycle(0)
    self:SetPlaybackRate(1)
    self:SetSequence(seq)

    -- Play open sound
    SoundScripts.PlayOpenSound(self:GetPos())

    self.Open = true

    timer.Simple(self:SequenceDuration(), function()
        if IsValid(self) then
            local seq = self:LookupSequence("idle")
            self:SetPlaybackRate(0)
            self:SetSequence(seq)
        end
    end)
end

function ENT:CloseDoor(toRemove)
    -- Play "open" animation on spawn
    local seq = self:LookupSequence("close")
    self:SetCycle(0)
    self:SetPlaybackRate(1)
    self:SetSequence(seq)

    -- Play open sound
    SoundScripts.PlayCloseSound(self:GetPos())

    self.Open = false

    timer.Simple(self:SequenceDuration(), function()
        if IsValid(self) then
            self:SetPlaybackRate(0)
            self:SetCycle(1)

            if toRemove == true then
                self:Remove()
            end
        end
    end)
end
