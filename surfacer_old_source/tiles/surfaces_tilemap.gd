tool
class_name SurfacesTilemap, \
"res://addons/surfacer/assets/images/editor_icons/surfaces_tilemap.png"
extends CornerMatchTilemap
## The surfaces that a character can collide with.


const GROUP_NAME_SURFACES := "surfaces"


func _ready() -> void:
    self.add_to_group(GROUP_NAME_SURFACES, true)
    if is_instance_valid(inner_tilemap):
        inner_tilemap.add_to_group(GROUP_NAME_SURFACES, true)
        inner_tilemap.id = self.id + "_inner"
    assert(tile_set is SurfacesTileset)
    self.add_to_group(Sc.slow_motion.GROUP_NAME_DESATURATABLES)
    inner_tilemap.add_to_group(Sc.slow_motion.GROUP_NAME_DESATURATABLES)
