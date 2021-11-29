tool
class_name TileSetWithManyAngles
extends SurfacesTileSet


const _TILE_IDS := [
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

const _DISABLED_SURFACES_TILE_IDS := {
}


func _get_tile_manifest() -> Dictionary:
    var manifest := {}
    for tile_id in _TILE_IDS:
        var tile_config := {}
        # TODO: Use separate inclusion/exclusion lists for assigning non-default
        #       properties for certain tile IDs.
        if _DISABLED_SURFACES_TILE_IDS.has(tile_id):
            tile_config.surface_properties = \
                    Su.surface_properties.properties["disabled"]
        else:
            tile_config.surface_properties = \
                    Su.surface_properties.properties["default"]
        manifest[tile_id] = tile_config
    return manifest


func _is_tile_bound( \
        drawn_id: int, \
        neighbor_id: int) -> bool:
    if neighbor_id == TileMap.INVALID_CELL:
        return false
    
    return true
