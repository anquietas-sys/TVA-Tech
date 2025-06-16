$modelname	"weapons/w_tempad"
$model "body"	"w_tempad"

$surfaceprop "weapon"

$contents "solid"

$illumposition -0.296 -0.347 -0.422

$cdmaterials	"models/weapons/"

$cbox 0 0 0 0 0 0

$bbox -7.645 -7.454 -8.97 8.338 6.861 8.127

$definebone "w_medkit" "" 0 0 0 0 0 0 0 0 0 0 0 0
$definebone "ValveBiped.Bip01_R_Hand" "w_medkit" -6.422761 1.205736 0.652292 47.116158 -30.091457 -132.311938 0 0 0 0 0 0

$sequence "idle" {
	"anims\idle.smd"
	fadein 0.2
	fadeout 0.2
	fps 1
	loop
}

$collisionmodel "w_tempad_physics.smd"
{
	$mass 1
	$inertia 1
	$damping 0
	$rotdamping 0
	$rootbone " "

}

