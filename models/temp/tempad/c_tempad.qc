$modelname	"weapons/c_tempad"
$model "body"	"c_tempad"

$cdmaterials	"models/weapons/"

$root "ValveBiped.Bip01_Spine4"

$sequence idle	"anims/idle" loop fps 30 activity ACT_VM_IDLE 1 node 0
$sequence draw	"anims/draw" fps 30 snap activity ACT_VM_DRAW 1 node 0
$sequence holster	"anims/holster" fps 30 activity ACT_VM_HOLSTER 1 node 0
