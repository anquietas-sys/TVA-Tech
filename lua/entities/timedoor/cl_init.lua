include("shared.lua")

local rt = GetRenderTargetEx("td_rt", ScrW(), ScrH(), RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_SEPARATE, 1+256, 0, IMAGE_FORMAT_RGBA16161616F)
local parentMaterial = Material("timedoor/timedoor_prert")
local childMaterial = Material("timedoor/timedoor_postrt")
local aberrationMaterial = Material("timedoor/timedoor_aberration")
local clearMaterial = Material("timedoor/timedoor_clearrt")

local function NormalizeColor(color)
    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255
    local a = color.a / 255
    return r, g, b, a
end

function ENT:Initialize()
    self.LightColor = Color(255, 170, 39)

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
    self.LightColor = color
    self.LightProperties = {
        r = color.r,
        g = color.g,
        b = color.b,
        brightness = 3,
        Decay = 512,
        Size = 128
    }
end

function ENT:DrawBlurEffect()
    -- reusing screeneffect texture, no need to create a new rendertarget
    local blur_texture = render.GetScreenEffectTexture(1)
    render.UpdateScreenEffectTexture(1) -- update current screen data

    -- aberration
    if self:GetNWBool("Glitchy") == true then
        aberrationMaterial:SetFloat("$c1_x", math.abs(math.sin(CurTime()*5)/300) + math.abs(math.cos(CurTime()*5)/300) )
    else
        aberrationMaterial:SetFloat("$c1_x", 0.004 )
    end
    aberrationMaterial:SetTexture("$basetexture", blur_texture)

    render.PushRenderTarget(blur_texture)
        render.SetMaterial(aberrationMaterial)
        render.DrawScreenQuad()
    render.PopRenderTarget()

    -- blur rt
    local cache = render.GetRenderTarget()
    render.BlurRenderTarget(blur_texture, 2, 2, 1)
    render.SetRenderTarget(cache)  -- blurrendertarget is fucked, gotta do this

    -- massive block of stencil setup
    render.ClearStencil()
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(0)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilEnable(true)

    -- k time to do the shits
    -- task: replace behind of model with a blurred version of the background

    -- first, we need to setup the area in the stencil buffer
    -- where our texture will be rendered
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilReferenceValue(1)

    -- draw our model
    -- before, you IGNORED z when drawing, but we dont actually want to do that
    -- in this situation we still want to obey the depth buffer, but not write to it
    -- othherwise that will make it draw through walls
    render.OverrideDepthEnable(true, false)
        self:DrawModel()
    render.OverrideDepthEnable(false, false)

    -- now, render our image in screenspace only on top of where our model was
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)

    render.DrawTextureToScreen(blur_texture)

    render.SetStencilEnable(false)
end

function ENT:UnfuckedClear()
    cam.Start2D()
        render.SetMaterial(clearMaterial)
        render.DrawScreenQuad()
        render.ClearDepth()
    cam.End2D()
end

function ENT:GetTouchingEntities()
    local touching = {}
    for _, ent in ipairs(ents.FindInBox(self:WorldSpaceAABB())) do
        if ent ~= self and IsValid(ent) then
            if ent:GetNoDraw() then continue end
            table.insert(touching, ent)
        end
    end
    return touching
end

function ENT:DrawHaloEffect()
    self:DrawModel()
    for _,ent in pairs(self:GetTouchingEntities()) do
        if !IsValid(ent) or !IsEntity(ent) then continue end
        if ent:GetClass() == "viewmodel" then continue end
        local entTable = scripted_ents.Get(ent:GetClass())
        if (ent:GetClass() == "timedoor") or (entTable and entTable.Base == "timedoor") then continue end

        local r,g,b,a = NormalizeColor(self.LightColor)

        childMaterial:SetTexture("$basetexture", rt)
        childMaterial:SetFloat("$c0_x", 1/ScrW())
        childMaterial:SetFloat("$c0_y", 1/ScrH())
        childMaterial:SetFloat("$c1_x", 1)
        childMaterial:SetFloat("$c2_x", r)
        childMaterial:SetFloat("$c2_y", g)
        childMaterial:SetFloat("$c2_z", b)
        childMaterial:SetFloat("$c2_w", a)

        render.PushRenderTarget(rt)
        self:UnfuckedClear()
        render.MaterialOverride(parentMaterial)
            render.OverrideDepthEnable(true, true)
                ent:DrawModel()
            render.OverrideDepthEnable(false, false)
            render.PopRenderTarget()
        render.MaterialOverride(nil)
        
        render.MaterialOverride(childMaterial)
            self:DrawModel()
        render.MaterialOverride(nil)
    end
end

function ENT:Draw()
    if self:GetNWBool("FullyClosed") then return end

    if halo.RenderedEntity() == self then
        self:DrawModel()
        return
    end

    self:DrawBlurEffect()
    self:DrawHaloEffect()
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

    if dlight and self:GetNWBool("Open") then
        dlight.pos = self:GetPos() + self:GetUp() * 35
        dlight.r = self.LightProperties.r
        dlight.g = self.LightProperties.g
        dlight.b = self.LightProperties.b
        dlight.brightness = self.LightProperties.brightness
        dlight.Decay = self.LightProperties.Decay
        dlight.Size = self.LightProperties.Size
        dlight.dietime = CurTime()+0.1
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
