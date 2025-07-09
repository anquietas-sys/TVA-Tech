AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local SoundScripts = include("tempad/soundscripts.lua")
local TeleportFunctions = include("tempad/teleport.lua")
local config = include("tempad/config.lua")

// Setting these up so that our children entities can use them without overriding the original logic
function ENT:PostInitialize() end
function ENT:PostStartTouch(activator) end

function ENT:Dot(ent)
    local up = self:GetForward()
    local dir = ent:GetPos()-self:GetPos()
    return up:Dot(dir:GetNormalized())
end

function ENT:Initialize()
    self:SetModel("models/timedoor/timedoor.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetColor(Color(255, 198, 114, 254))

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end

    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    self:SetTrigger(true)

    self:SetNWBool("Open", false)
    self:SetNWBool("FullyClosed", true)
    self:SetNWBool("Glitchy", false)
    self.Partner = nil
    self.Glitchy = false
    self.TouchingEntities = {}

    self.DebugTrigger = true

    self:PostInitialize()

    if !self:GetNWBool("Open") then
        self:OpenDoor()
    end

    -- Wiremod stuff.
    if istable(WireLib) and WireLib.AdjustInputs then
        -- WireLib is installed and functional

        print("Creating Wire Inputs for Time Door")

        self.Inputs = WireLib.CreateInputs(self, {
            "Partner (Links this Time Door to another Time Door.) [ENTITY]",
            "Open (Controls if the Time Door is open.) [NORMAL]",
        })
    end

end

function ENT:TriggerInput( name, value )
    if (name == "Partner") then
        self.Partner = value
    elseif (name == "Open") then
        if value >= 1 then
            if self:GetNWBool("Open") == false then
                self:OpenDoor()
            end
        else
            if self:GetNWBool("Open") == true then
                self:CloseDoor()
            end
        end
    end
end

function ENT:EndTouch(ent)
    if not IsValid(ent) then return end
    if not self:GetNWBool("Open") then return end

    -- Under certain circumstances, especially with high velocities, Touch() can miss the calculation on some entities.
    -- Below is a fallback in case that happens.
    if (self.TouchingEntities[ent] != nil and self.TouchingEntities[ent] != false and ent.NextTimeDoor != self) then
        local dot = self:Dot(ent)
        local initialDot = self.TouchingEntities[ent]

        -- This one is more sensitive. If the difference is above 0.5, run the teleport. We still want to be able to edge the door.
        if (math.abs(dot-initialDot) >= 0.5) then
            self:PrepareTeleport(ent)
        end
    end

    -- Clear this so we can walk back through the door
    if ent.NextTimeDoor == self then ent.NextTimeDoor = nil end
    -- Clear the previous dot product for this entity, we no longer need it.
    self.TouchingEntities[ent] = false

    self:PostStartTouch(ent) 
end

function ENT:StartTouch(ent)
    if not IsValid(ent) then return end
    if not self:GetNWBool("Open") then return end

    -- Set our initial dot product for this entity. We'll use it later.
    self.TouchingEntities[ent] = self:Dot(ent)
end

function ENT:Touch(ent)
    if not IsValid(ent) then return end
    if not self:GetNWBool("Open") then return end
    if self.TouchingEntities[ent] == false then return end
    if ent.NextTimeDoor == self then return end
    
    local dot = self:Dot(ent)
    local initialDot = self.TouchingEntities[ent]

    -- Think of the below like the 'difference' between the initial dot value and the current one.
    -- if the difference is above 1, run the teleport. 1 is the point that the dot values flip from positive to negative.
    if (math.abs(dot-initialDot) >= 1) then
        self:PrepareTeleport(ent)
    end
end

function ENT:PrepareTeleport(ent)
    if !IsValid(ent) or !IsEntity(ent) or ent == nil then return end

    if ent.NextTimeDoor == self then return end

    ent.NextTimeDoor = self.Partner

    -- If the entity is a player, skip the BS and teleport them.
    if ent:IsPlayer() then
        self:OnPlayerPass(ent)
    end

    -- Make sure that the entity isn't blacklisted
    local classtest = string.Trim(ent:GetClass())
    local parenttest = ent:GetParent()
    local parentClasstest = IsValid(parenttest) and string.Trim(parenttest:GetClass()) or nil
    local blacklisted = config.Blacklist[classtest] or (parentClasstest and config.Blacklist[parentClasstest])
    if not blacklisted then
        local propSize = ent:OBBMaxs() - ent:OBBMins()
        local doorSize = self:OBBMaxs() - self:OBBMins()

        local propLongest = math.max(propSize.x, propSize.y, propSize.z)
        local doorLongest = math.max(doorSize.x, doorSize.y, doorSize.z)

        local phys = ent:GetPhysicsObject()

        if !IsValid(phys) or phys == nil then return end
        -- Make sure the entity fits, if it does, send it through!
        if propLongest <= (doorLongest * 2) and phys:IsMotionEnabled() then
            self:OnSmallPropPass(ent)
        end
    end
end

function ENT:OnPlayerPass(ply)
    SoundScripts.PlayTravelSound(self:GetPos())

    if self.Partner != nil and IsValid(self.Partner) and IsEntity(self.Partner) then
        SoundScripts.PlayTravelSound(self.Partner:GetPos())
    end
    
    -- Register the partner door with the player and send them through.
    ply.TimeDoorNext = self.Partner

    ply:ScreenFade(SCREENFADE.IN, Color(
        math.Clamp(self:GetColor().r * 0.5, 0, 255),
        math.Clamp(self:GetColor().g * 0.5, 0, 255),
        math.Clamp(self:GetColor().b * 0.5, 0, 255),
        255 -- fully opaque fade
    ), 0.2, 0)
    
    TeleportFunctions.Teleport(ply, self, self.Partner)
end

function ENT:OnSmallPropPass(prop)
    SoundScripts.PlayTravelSound(self:GetPos())

    if self.Partner != nil and IsValid(self.Partner) and IsEntity(self.Partner) then
        SoundScripts.PlayTravelSound(self.Partner:GetPos())
    end
    
    if prop.TimeDoorCooldown == nil then
        prop.TimeDoorCooldown = CurTime()
    end

    if CurTime() >= prop.TimeDoorCooldown then
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
    if self.Glitchy then
        SoundScripts.PlayGlitchyOpenSound(self:GetPos())
    else
        SoundScripts.PlayOpenSound(self:GetPos())
    end

    self:SetNWBool("FullyClosed", false)
    self:SetNWBool("Open", true)

    timer.Simple(self:SequenceDuration(), function()
        if IsValid(self) then
            local seq = self:LookupSequence("idle")
            self:SetPlaybackRate(0)
            self:SetSequence(seq)
        end
    end)
end

function ENT:CloseDoor(toRemove)
    self:SetNWBool("FullyClosed", false)
    
    local seq = self:LookupSequence("close")
    self:SetCycle(0)
    self:SetPlaybackRate(1)
    self:SetSequence(seq)

    -- Play close sound
    if self.Glitchy then
        SoundScripts.PlayGlitchyCloseSound(self:GetPos())
    else
        SoundScripts.PlayCloseSound(self:GetPos())
    end

    self:SetNWBool("Open", false)

    timer.Simple(self:SequenceDuration(), function()
        if IsValid(self) then
            self:SetPlaybackRate(0)
            self:SetCycle(1)

            self:SetNWBool("FullyClosed", true) // Let us know when to stop drawing the entity on the client

            if toRemove == true then
                self:Remove()
            end
        end
    end)
end

function ENT:MakeGlitchy(glitchy)
    self.Glitchy = glitchy
    self:SetNWBool("Glitchy", glitchy)
    if glitchy == true then
        self:SetRenderFX(15)
        self:SetColor(Color(255, 168, 63, 254))
    else
        self:SetRenderFX(0)
        self:SetColor(Color(255,255,255,255))
    end
end