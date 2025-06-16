AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

// Any hooks you add here will override the logic the timedoor entity sets up.
// That being said, we've made some functions in our parent entity specifically for the purpose of being overridden.

function ENT:PostInitialize()
    self:MakeGlitchy(true)
end

function ENT:PostUse()
    
end

function ENT:PostTouch()

end