tool
class_name SurfacesTileMap, \
"res://addons/surfacer/assets/images/editor_icons/surfaces_tile_map.png"
extends TileMap


const GROUP_NAME_SURFACES := "surfaces"

export var id: String
## This can be useful for debugging.
export var draws_tile_indices := false setget _set_draws_tile_indices


func _ready() -> void:
    add_to_group(GROUP_NAME_SURFACES)
    
    if tile_set == null:
        tile_set = Su.default_tile_set


func _draw() -> void:
    if draws_tile_indices:
        Sc.draw.draw_tile_map_indices(
                    self,
                    self,
                    Color.white,
                    false)


func _set_draws_tile_indices(value: bool) -> void:
    draws_tile_indices = value
    update()
