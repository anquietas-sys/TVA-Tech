if SERVER then
    AddCSLuaFile()
end

SWEP.PrintName = "Time Stick"
SWEP.Author = "Time Variance Authority"
SWEP.Instructions = "Left-click to hit things."
SWEP.Category = "Time Variance Authority"

SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Base = "weapon_base"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_timestick.mdl"
SWEP.WorldModel = "models/weapons/w_timestick.mdl"
SWEP.ViewModelFOV = 54

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HitDistance = 75
SWEP.Damage = 1

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1.2)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_MISSCENTER)

    if SERVER then
        self:EmitSound("weapons/timestick_swing.wav", 75, math.random(95, 105), 1)

        local tr = util.TraceHull({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * self.HitDistance,
            filter = owner,
            mins = Vector(-10, -10, -10),
            maxs = Vector(10, 10, 10),
            mask = MASK_SHOT_HULL
        })

        if tr.Hit then
            local hitEnt = tr.Entity

            if IsValid(hitEnt) then
                local constrainedEnts = constraint.GetAllConstrainedEntities(hitEnt)

                for ent, _ in pairs(constrainedEnts) do
                    if IsValid(ent) and ent:GetClass() ~= "worldspawn" then
                        local dmg = DamageInfo()
                        dmg:SetAttacker(owner)
                        dmg:SetInflictor(self)
                        dmg:SetDamage(self.Damage)
                        dmg:SetDamageType(DMG_DISSOLVE)

                        ent:Dissolve(2, 3)
                        ent:TakeDamageInfo(dmg)
                    end
                end

                hitEnt:EmitSound("weapons/timestick_dissolve.wav", 75, math.random(95, 105))
            else
                self:EmitSound("physics/flesh/flesh_impact_bullet5.wav", 75, math.random(95, 105))
            end
        end
    end
end

function SWEP:SecondaryAttack()
-- anti-shotgun measures
end
