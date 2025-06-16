include("shared.lua")

function ENT:Initialize()
    self.LightColor = self:GetColor()
    self.LightProperties = {
        r = self.LightColor.r,
        g = self.LightColor.g,
        b = self.LightColor.b,
        brightness = 3,
        Decay = 512,
        Size = 128
    }
end

function ENT:OnColorChanged(color)
    self.LightProperties = {
        r = color.r,
        g = color.g,
        b = color.b,
        brightness = 3,
        Decay = 512,
        Size = 128
    }
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:Think()
    self:FrameAdvance()

    if self._IsPlayingOpenAnim then
        local cycle = self:GetCycle()
        print("Timedoor open anim cycle:", cycle)  -- debug output

        if cycle >= 1 then
            local idleSeq = self:LookupSequence("idle")
            print("Idle seq index:", idleSeq)
            if idleSeq and idleSeq >= 0 then
                self:ResetSequence(idleSeq)
                self:SetCycle(0)
                self:SetPlaybackRate(1)
                self.AutomaticFrameAdvance = false -- stop advancing frames on idle
            else
                print("Timedoor: idle animation missing!")
            end
            self._IsPlayingOpenAnim = false
        end
    end

    local curColor = self:GetColor()
    if curColor ~= self._lastColor then
        self._lastColor = curColor
        self:OnColorChanged(curColor)
    end

    local dlight = DynamicLight(self:EntIndex())

    if dlight then
        dlight.pos = self:GetPos() + self:GetUp() * 35
        dlight.r = self.LightProperties.r
        dlight.g = self.LightProperties.g
        dlight.b = self.LightProperties.b
        dlight.brightness = self.LightProperties.brightness
        dlight.Decay = self.LightProperties.Decay
        dlight.Size = self.LightProperties.Size
        dlight.dietime = CurTime() + 0.1
    end

    self:NextThink(CurTime())
    return true
end

net.Receive("Timedoor_PlayOpenAnim", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    ent:SetNoDraw(false) -- show the door

    local seq = ent:LookupSequence("open")
    if IsValid(seq) then
        ent:ResetSequence(seq)
        ent:SetCycle(0)
        ent:SetPlaybackRate(1)
        ent._IsPlayingOpenAnim = true -- flag for tracking
    else
        print("Timedoor: 'open' animation not found on client!")
    end
end)