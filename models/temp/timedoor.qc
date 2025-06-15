$modelname	"timedoor/timedoor.mdl"
$model "body"	"timedoor"

$surfaceprop	glass
$cdmaterials	"timedoor"
$mostlyopaque

$collisionmodel	"phys"
{
	$automass
}

$root "root"

$sequence idle	"anims/timedoor_idle"
$sequence open	"anims/timedoor_open"
$sequence close	"anims/timedoor_close"
$sequence idleglitchy	"anims/timedoor_idleglitchy"