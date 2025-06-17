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
SWEP.ViewModel = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFOV = 54

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.HitDistance = 75
SWEP.Damage = 3000

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
        self:EmitSound("weapons/stunstick/stunstick_swing1.wav", 75, 100, 1)

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
                local dmg = DamageInfo()
                dmg:SetAttacker(owner)
                dmg:SetInflictor(self)
                dmg:SetDamage(self.Damage)
                dmg:SetDamageType(DMG_DISSOLVE)

                hitEnt:TakeDamageInfo(dmg)
                hitEnt:Dissolve(2, 3)

                self:EmitSound("weapons/stunstick/stunstick_fleshhit1.wav")
            else
                self:EmitSound("weapons/stunstick/stunstick_impact1.wav")
            end
        end
    end
end

function SWEP:SecondaryAttack()
-- anti-shotgun measures
end
