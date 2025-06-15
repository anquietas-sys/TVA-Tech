include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

net.Receive("Timedoor_PlayOpenAnim", function()
    LocalPlayer():ChatPrint("CL: NETWORK MESSAGE")
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

    self:NextThink(CurTime())
    return true
end
