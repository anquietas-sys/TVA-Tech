SWEP.PrintName			= "Tempad"
SWEP.Author			= "Time Variance Authority"
SWEP.Instructions		= "Left Mouse to open a Time Door, Right mouse to open menu."
SWEP.Category = "Time Variance Authority"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"
SWEP.Weight			= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Slot			= 5
SWEP.SlotPos			= 3
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true
SWEP.ViewModel			= "models/weapons/c_medkit.mdl"
SWEP.WorldModel			= "models/items/healthkit.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.ShootSound = Sound( "buttons/button15.wav" )

local function OpenMenu()

	local myTitleLabel = vgui.Create( "DLabel", myBasePanel )
	myTitleLabel:SetText( "My Awesome Panel" )
	myTitleLabel:SetPos( 10, 10 )
	myTitleLabel:SizeToContents()
	myTitleLabel:SetTextColor( color_white )

	local myCloseButton = vgui.Create( "DButton", myBasePanel )
	myCloseButton:SetText( "Close Me" )
	myCloseButton:SetSize( 100, 30 )
	local panelW, panelH = myBasePanel:GetSize()
	myCloseButton:SetPos( panelW - 110, panelH - 40 )

	myCloseButton.DoClick = function( theButton )
	  print( "Close button clicked!" )
	  myBasePanel:Remove()
	end
end



function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.5 )
	print("test")
end

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire( CurTime() + 0.5 )
	OpenMenu()
end
