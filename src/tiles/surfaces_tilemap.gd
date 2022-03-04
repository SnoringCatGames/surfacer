tool
class_name SurfacesTilemap, \
"res://addons/surfacer/assets/images/editor_icons/surfaces_tilemap.png"
extends CornerMatchTilemap
## The surfaces that a character can collide with.


const GROUP_NAME_SURFACES := "surfaces"

export var id: String


func _ready() -> void:
    add_to_group(GROUP_NAME_SURFACES, true)
