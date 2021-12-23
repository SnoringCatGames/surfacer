tool
class_name TileSetWithManyAngles
extends SurfacesTileSet


const _PROPERTIES_MANIFEST := [
    # TODO: Use separate inclusion lists for assigning non-default properties
    #       for certain tile IDs.
    ["disabled", []],
]


func _init().(_PROPERTIES_MANIFEST) -> void:
    pass


func _is_tile_bound( \
        drawn_id: int, \
        neighbor_id: int) -> bool:
    if neighbor_id == TileMap.INVALID_CELL:
        return false
    
    return true
