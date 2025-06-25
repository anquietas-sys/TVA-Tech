AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local SoundScripts = include("tempad/soundscripts.lua")
local TeleportFunctions = include("tempad/teleport.lua")
local config = include("tempad/config.lua")

// Setting these up so that our children entities can use them without overriding the original logic
function ENT:PostInitialize() end
function ENT:PostUse(activator, caller, usetype, value) end
function ENT:PostStartTouch(activator) end

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

    self.DebugTrigger = true

    self.UseCooldown = CurTime()

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
    else
        -- do nothing
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

    -- First, check if the entity has just been teleported here
    if ent.TimeDoorNext != self then
        -- If this is their first teleport, send them through!
        if ent:IsPlayer() then
            self:OnPlayerPass(ent)
        end

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


            if propLongest <= (doorLongest * 2) and phys:IsMotionEnabled() then
                self:OnSmallPropPass(ent)
            end
        end

        -- Debug code to link timedoors spawned in the menu
        local entTable = scripted_ents.Get(ent:GetClass())

        if (ent:GetClass() == "timedoor") or (entTable and entTable.Base == "timedoor") then
            self.Partner = ent
            ent.Partner = self
        end
    else
        -- The entity was just teleported here, so let's not send them through.

        -- Reset the next time door, and prevent the rest of the function from running.
        ent.TimeDoorNext = nil
    end

    self:PostStartTouch(ent)
end

function ENT:OnPlayerPass(ply)
    SoundScripts.PlayTravelSound(self:GetPos())
    
    -- Register the partner door with the player and send them through.
    ply.TimeDoorNext = self.Partner
    TeleportFunctions.Teleport(ply, self, self.Partner)
end

function ENT:OnSmallPropPass(prop)
    SoundScripts.PlayTravelSound(self:GetPos())

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