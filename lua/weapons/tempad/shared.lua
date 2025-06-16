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
SWEP.m_WeaponDeploySpeed = 6
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
SWEP.ViewModel			= "models/weapons/c_tempad.mdl"
SWEP.WorldModel			= "models/items/healthkit.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.ShootSound = Sound( "buttons/button15.wav" )

// This following code will run on both client AND server
function SWEP:PrimaryAttack()
	if ( game.SinglePlayer() ) then self:CallOnClient( "PrimaryAttack" ) end
	self:SetNextPrimaryFire( CurTime() + 0.5 )

	// Do shit here idk
end

function SWEP:SecondaryAttack()
	if ( game.SinglePlayer() ) then self:CallOnClient( "SecondaryAttack" ) end
	self:SetNextPrimaryFire( CurTime() + 0.5 )
	if CLIENT then
		self:OpenMenu()
	end
end

// Will only run on the server.
if SERVER then
	util.AddNetworkString("TVA_CreateDoor") // Add a new net message into the pool, so we can use this net message later
	// P.S. I can see this creating issues in multiplayer, it might try to call this over and over so be aware
	// 		For now though, it'll do.

	// Specify what to do when the server recieves the 'TVA_CreateDoor' net message:
	// 		(len is useless, it's the net message length)
	net.Receive("TVA_CreateDoor", function(len, ply)
		// Create door!
		local door = ents.Create("timedoor")
		door:SetPos(ply:GetEyeTrace().HitPos) // Position it where the player is looking
		door:SetAngles(ply:GetForward():Angle())
		door:Spawn()

		// Make it undoable
		undo.Create("Time Door")
		    undo.AddEntity(door)
		    undo.SetPlayer(ply)
		undo.Finish()
	end)
end

// Will only run on the client. I put this at the bottom because clientside code (especially vgui stuff) takes a lot of space;
//    Space I doubt you want to wade through to get to literally any other code haha	
if CLIENT then
	function SWEP:OpenMenu()
		local frame = vgui.Create("DFrame")
		frame:SetSize(ScrW()/2, ScrH()/2) // Set the frame size to half of the screen's width and height
		frame:Center() // Centers the frame on the screen
		frame:MakePopup() // Unlocks the mouse, shows the cursor so we can interact with the panel
		frame:SetTitle("Tempad") // Sets the title of the frame

		// doin a heckin advanced!1!! (use this to set the background color of the frame)
		function frame:Paint(w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(25,25,25,250))
		end

  	 	    -- Scrollable panel
    	local scroll = vgui.Create("DScrollPanel", frame)
    	scroll:Dock(FILL)

    	-- Iterate over all players
    	for _, ply in ipairs(player.GetAll()) do
        	local button = scroll:Add("DButton")
        	button:Dock(TOP)
        	button:DockMargin(0, 0, 0, 5)
        	button:SetText(ply:Nick())
        	button:SetTall(30)

        	-- Optional: Add click behavior
        	button.DoClick = function()
            chat.AddText(Color(0, 255, 0), "You clicked on: " .. ply:Nick())
        end
    end
		local networked = vgui.Create("DButton", frame)
		networked:SetHeight(frame:GetTall()/10) // Size everything relative to the frame to keep support for all monitor resolutions.
		networked:Dock(BOTTOM) // Fills the bottom spot with the button
		networked:SetText("Spawn a door in front of me!")

		networked.DoClick = function(btn)
			net.Start("TVA_CreateDoor") // Spool up the hypothetical net-message railgun
			net.SendToServer() // Fire it at the server
			frame:Close()
		end

		// Removed close button because DFrame already has a close button unless DFrame:ShowCloseButton is set to false.
	end
end



