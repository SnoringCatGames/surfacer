tool
extends TileSet
class_name TileSetWithManyAngles


const TILE_NAMES := [
    "1_tile_with_90s",
    "2_tile_with_45s",
    "3_tile_with_27s_floors_pos",
    "4_tile_with_27s_floors_neg",
    "5_tile_with_27s_ceilings_pos",
    "6_tile_with_27s_ceilings_neg",
    "7_tile_with_halves",
    "8_tile_with_odd_joins",
    "9_tile_with_corner_caps",
]


func _is_tile_bound( \
        drawn_id: int, \
        neighbor_id: int) -> bool:
    if neighbor_id == TileMap.INVALID_CELL:
        return false
    
    return true
