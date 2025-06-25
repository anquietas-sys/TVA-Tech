SWEP.PrintName			= "Tempad"
SWEP.Author			= "Time Variance Authority"
SWEP.Instructions		= "Left Mouse to open the menu, Right mouse to close a Time Door."
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
SWEP.WorldModel			= "models/weapons/w_tempad.mdl"
SWEP.ViewModelFOV = 54
SWEP.UseHands = true
SWEP.ShootSound = Sound( "buttons/button15.wav" )

local selectedPlayer = nil
local destinationpos = {}
local destinationang = {}
local waypoints = waypoints or {}

-- Weapon selector icon
if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID( 'weapons/tempad' )
end


// This following code will run on both client AND server
function SWEP:SecondaryAttack()
	if ( game.SinglePlayer() ) then self:CallOnClient( "SecondaryAttack" ) end
	self:SetNextSecondaryFire( CurTime() + 0.5 )

	if SERVER then
		local owner = self:GetOwner()

		local tr = owner:GetEyeTrace()
		local targetEnt = tr.Entity

		if IsValid(targetEnt) and targetEnt:GetClass() == "timedoor" or targetEnt:GetClass() == "timedoorglitchy" then
    	local ptnr = targetEnt.Partner
    	if IsValid(ptnr) then
    		ptnr:CloseDoor(true)
    	end
    	targetEnt:CloseDoor(true)
		end
	end
end

function SWEP:PrimaryAttack()
	if ( game.SinglePlayer() ) then self:CallOnClient( "PrimaryAttack" ) end
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
    local destPos = net.ReadVector()
    local destAng = net.ReadAngle()
    local color = net.ReadColor(false)
    local glitch = net.ReadBool()
    local autocloseTime = net.ReadFloat() or 20

    if glitch == false then
    	classname = "timedoor"
    else
    	classname = "timedoorglitchy"
    end

    // print(classname)

    if not destPos or not destAng then
        ply:ChatPrint("Invalid destination data.")
        return
    end

    -- Create the first door at where the player is looking
    local door1 = ents.Create(classname)
    door1:SetPos(ply:GetEyeTrace().HitPos)
    door1:SetAngles(ply:GetForward():Angle())
    door1:Spawn()

    -- Create the second door at the destination received
    local door2 = ents.Create(classname)
    door2:SetPos(destPos)
    door2:SetAngles(destAng)
    door2:Spawn()

    door1.Partner = door2
    door2.Partner = door1
    door1:SetColor(color)
    door2:SetColor(color)

    undo.Create("Time Door")
        undo.AddEntity(door1)
        undo.AddEntity(door2)
        undo.SetPlayer(ply)
    undo.Finish()

    timer.Simple(autocloseTime, function()
        if IsValid(door1) then
            door1:CloseDoor(true)
            door2:CloseDoor(true)
        end
    end)

	end)
end

if CLIENT then
	function SWEP:CloseDoor()

	end
end




// Will only run on the client. I put this at the bottom because clientside code (especially vgui stuff) takes a lot of space;
//    Space I doubt you want to wade through to get to literally any other code haha	
if CLIENT then
    local waypoints = {}

    -- Customization config table
    local customizationData = {
        useCustomColor = false,
        color = Color(255, 198, 114, 255),
        glitchy = false
    }

    -- File paths
    local function GetWaypointFileName()
        return "TVA/" .. game.GetMap() .. ".txt"
    end

    local function SaveWaypoints()
        file.CreateDir("TVA")
        local json = util.TableToJSON(waypoints, true)
        file.Write(GetWaypointFileName(), json)
    end

    local function LoadWaypoints()
        waypoints = {}
        if file.Exists(GetWaypointFileName(), "DATA") then
            local json = file.Read(GetWaypointFileName(), "DATA")
            waypoints = util.JSONToTable(json) or {}
        end
    end

    local function SaveCustomizations()
        file.CreateDir("TVA")
        file.Write("TVA/tempad_customisations.txt", util.TableToJSON(customizationData, true))
    end

    local function LoadCustomizations()
        if file.Exists("TVA/tempad_customisations.txt", "DATA") then
            local json = file.Read("TVA/tempad_customisations.txt", "DATA")
            local tbl = util.JSONToTable(json)
            if tbl then
                customizationData = tbl
                -- Fix color table: convert to Color object if needed
                if customizationData.color and not istable(customizationData.color.r) then
                    local c = customizationData.color
                    customizationData.color = Color(c.r or 255, c.g or 198, c.b or 114, c.a or 255)
                end
            end
        end
    end

    function SWEP:OpenMenu()

        if (game.SinglePlayer()) != true then
            if not IsFirstTimePredicted() then return end
        end
        
        LoadWaypoints()
        LoadCustomizations()

        local frameWidth = ScrW() / 2
        local frameHeight = ScrH() / 1.5


        local frame = vgui.Create("DFrame")
        frame:SetSize(frameWidth, frameHeight)
        frame:Center()
        frame:MakePopup()
        frame:SetTitle("Tempad")

        function frame:Paint(w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(100, 68, 0, 250))
        end

        -- LEFT: Player list
        local playerList = vgui.Create("DListView", frame)
        playerList:SetSize(frameWidth / 3, frameHeight - 40)
        playerList:SetPos(10, 30)
        playerList:AddColumn("Name")

        for _, ply in ipairs(player.GetAll()) do
            playerList:AddLine(ply:Nick())
        end

        playerList.OnRowSelected = function(_, _, row)
            local name = row:GetColumnText(1)
            for _, ply in ipairs(player.GetAll()) do
                if ply:Nick() == name then
                    selectedPlayer = ply
                    local backOffset = -100
                    local ang = ply:EyeAngles()
                    ang.p = 0 ang.r = 0
                    destinationpos = ply:GetPos() + ang:Forward() * backOffset
                    destinationang = ang
                    break
                end
            end
        end

        -- MIDDLE: Waypoints
        local waypointPanelX = frameWidth / 3 + 10
        local waypointPanelWidth = frameWidth / 3 - 20

        local addWaypointButton = vgui.Create("DButton", frame)
        addWaypointButton:SetPos(waypointPanelX, 30)
        addWaypointButton:SetSize(waypointPanelWidth, 25)
        addWaypointButton:SetText("Add Waypoint (Your Position)")

        local waypointNameEntry = vgui.Create("DTextEntry", frame)
        waypointNameEntry:SetPos(waypointPanelX, 60)
        waypointNameEntry:SetSize(waypointPanelWidth, 25)
        waypointNameEntry:SetPlaceholderText("Enter waypoint name...")

        local waypointList = vgui.Create("DListView", frame)
        waypointList:SetPos(waypointPanelX, 90)
        waypointList:SetSize(waypointPanelWidth, frameHeight - 130)
        waypointList:AddColumn("Name")
        waypointList:AddColumn("Position")
        waypointList:AddColumn("Angle")

        for _, wp in ipairs(waypoints) do
            local posStr = string.format("X: %.1f Y: %.1f Z: %.1f", wp.pos.x, wp.pos.y, wp.pos.z)
            local angStr = string.format("Yaw: %.1f Pitch: %.1f", wp.ang.yaw, wp.ang.pitch)
            waypointList:AddLine(wp.name, posStr, angStr)
        end

        waypointList.OnRowSelected = function(_, _, row)
            local name = row:GetColumnText(1)
            for _, wp in ipairs(waypoints) do
                if wp.name == name then
                    selectedWaypoint = wp
                    destinationpos = wp.pos
                    destinationang = wp.ang
                    break
                end
            end
        end

        waypointList.OnRowRightClick = function(_, lineID, line)
            local menu = DermaMenu()
            menu:AddOption("Delete", function()
                local name = line:GetColumnText(1)
                for k, wp in ipairs(waypoints) do
                    if wp.name == name then
                        table.remove(waypoints, k)
                        break
                    end
                end
                waypointList:RemoveLine(lineID)
                SaveWaypoints()
            end):SetIcon("icon16/delete.png")
            menu:Open()
        end

        addWaypointButton.DoClick = function()
            local name = waypointNameEntry:GetValue()
            if name == "" then
                chat.AddText(Color(248, 134, 30), "[Tempad] Please enter a name for the waypoint!")
                return
            end
            local ply = LocalPlayer()
            local ang = ply:EyeAngles()
            ang.p = 0 ang.r = 0
            local wp = { name = name, pos = ply:GetPos(), ang = ang }
            table.insert(waypoints, wp)
            SaveWaypoints()

            local posStr = string.format("X: %.1f Y: %.1f Z: %.1f", wp.pos.x, wp.pos.y, wp.pos.z)
            local angStr = string.format("Yaw: %.1f Pitch: %.1f", wp.ang.yaw, wp.ang.pitch)
            waypointList:AddLine(name, posStr, angStr)
            waypointNameEntry:SetText("")
        end

        -- RIGHT: Customization Panel
        local customizationPanel = vgui.Create("DPanel", frame)
        customizationPanel:SetSize(frameWidth / 3 - 20, frameHeight - 40)
        customizationPanel:SetPos(frameWidth * (2 / 3) + 10, 30)
        customizationPanel:SetBackgroundColor(Color(120, 80, 20))

        local titleLabel = vgui.Create("DLabel", customizationPanel)
        titleLabel:SetText("Customisation")
        titleLabel:SetFont("DermaLarge")
        titleLabel:SizeToContents()
        titleLabel:SetPos(10, 5)

        local previewWidth = customizationPanel:GetWide() - 200
        local previewHeight = previewWidth * 1.6

        local texturePanel = vgui.Create("DPanel", customizationPanel)
        texturePanel:SetSize(previewWidth, previewHeight)
        texturePanel:SetPos(10, 40)
        texturePanel:SetBackgroundColor(customizationData.color or Color(255, 198, 114, 255))

        texturePanel.Paint = function(self, w, h)
            surface.SetDrawColor(self:GetBackgroundColor())
            surface.SetMaterial(Material("UI/timedoor_preview"))
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local enableColor = vgui.Create("DCheckBoxLabel", customizationPanel)
        enableColor:SetText("Custom Color")
        enableColor:SetPos(10, texturePanel:GetY() + texturePanel:GetTall() + 10)
        enableColor:SetValue(customizationData.useCustomColor or false)
        enableColor:SizeToContents()

        local colorPicker = vgui.Create("DColorMixer", customizationPanel)
        colorPicker:SetPos(10, enableColor:GetY() + 25)
        colorPicker:SetSize(customizationPanel:GetWide() - 20, 150)
        colorPicker:SetPalette(true)
        colorPicker:SetAlphaBar(true)
        colorPicker:SetWangs(true)
        colorPicker:SetEnabled(enableColor:GetChecked())
        colorPicker:SetColor(customizationData.color or Color(255, 198, 114, 255))

        local function UpdateTextureColor()
            if not IsValid(texturePanel) then return end
            local col = enableColor:GetChecked() and colorPicker:GetColor() or Color(255, 198, 114, 255)
            texturePanel:SetBackgroundColor(col)
            customizationData.color = col
            customizationData.useCustomColor = enableColor:GetChecked()
            SaveCustomizations()
        end

        enableColor.OnChange = function(_, val)
            colorPicker:SetEnabled(val)
            UpdateTextureColor()
        end

        colorPicker.ValueChanged = function(_, color)
            UpdateTextureColor()
        end

        local glitchyCheck = vgui.Create("DCheckBoxLabel", customizationPanel)
        glitchyCheck:SetText("Glitchy")
        glitchyCheck:SetPos(10, colorPicker:GetY() + colorPicker:GetTall() + 10)
        glitchyCheck:SetValue(customizationData.glitchy or false)
        glitchyCheck:SizeToContents()

        glitchyCheck.OnChange = function(_, val)
            customizationData.glitchy = val
            SaveCustomizations()
        end

        local autocloseSlider = vgui.Create("DNumSlider", customizationPanel)
        autocloseSlider:SetText("Auto-close Time")
        autocloseSlider:SetMin(1)
        autocloseSlider:SetMax(60)
        autocloseSlider:SetDecimals(0)
        autocloseSlider:SetValue(customizationData.autocloseTime or 20)
        autocloseSlider:SetSize(customizationPanel:GetWide() - 20, 30)
        autocloseSlider:SetPos(10, glitchyCheck:GetY() + glitchyCheck:GetTall() + 10)

        autocloseSlider.OnValueChanged = function(_, val)
            customizationData.autocloseTime = math.Round(val)
            SaveCustomizations()
        end

        -- BOTTOM BUTTON: Open Time Door
        local networked = vgui.Create("DButton", frame)
        networked:SetHeight(frameHeight / 10)
        networked:Dock(BOTTOM)
        networked:SetText("Open a Time Door to the destination.")

        networked.DoClick = function()
            local function IsVector(val)
                return getmetatable(val) == getmetatable(Vector(0, 0, 0))
            end

            if IsVector(destinationpos) then
                local colorToSend = enableColor:GetChecked() and colorPicker:GetColor() or Color(255, 198, 114, 254)
                net.Start("TVA_CreateDoor")
                    net.WriteVector(destinationpos)
                    net.WriteAngle(destinationang)
                    net.WriteColor(colorToSend, false)
                    net.WriteBool(glitchyCheck:GetChecked())
                    net.WriteFloat(autocloseSlider:GetValue())
                net.SendToServer()
                frame:Close()
            else
                chat.AddText(Color(248, 134, 30), "[Tempad] No destination set!")
            end
        end
    end
end
