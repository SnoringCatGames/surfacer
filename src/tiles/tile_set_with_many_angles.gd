tool
class_name TileSetWithManyAngles
extends SurfacesTileSet


func _is_tile_bound( \
        drawn_id: int, \
        neighbor_id: int) -> bool:
    if neighbor_id == TileMap.INVALID_CELL:
        return false
    
    return true
