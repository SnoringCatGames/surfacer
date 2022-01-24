tool
class_name SurfacesTileSet
extends TileSet


const INVALID_BITMASK := -1

# SubtileBinding
# -   Each end of each side (e.g., top-left, top-right, left-top, left-bottom,
#     ...) of a subtile is represented by one of these flags.
#enum {
#    UNKNOWN,
#
#    EMPTY,
#    EXTERIOR,
#    INTERIOR,
#
#    # Exterior edges (the transition from exterior to air).
#    EXT_90,
#    EXT_45,
#    EXT_45N,
#    EXT_27P_SHALLOW,
#    EXT_27P_STEEP,
#    EXT_27N_STEEP,
#    EXT_27P_INV_STEEP,
#    EXT_27N_INV_STEEP,
#
#    # Interior edges (the transition from interior to exterior).
#    INT_90_PERPENDICULAR,
#    INT_90_PERP_AND_PARALLEL,
#    INT_90_PARALLEL,
#    INT_90_PARALLEL_TO_45,
#    INT_90_PARALLEL_TO_27_SHALLOW,
#    INT_90_PARALLEL_TO_27_STEEP_SHORT,
#    INT_90_PARALLEL_TO_27_STEEP_LONG,
#    INT_45,
#    INT_45_TO_PARALLEL,
#    INT_45_INV,
#    INT_45_INV_WITH_90_PERPENDICULAR,
#    INT_45_INV_WITH_90_PERP_AND_PARALLEL,
#    INT_45_INV_WITH_90_PARALLEL,
#    INT_45_INV_NARROW,
#    INT_45_INV_MID_NOTCH,
#    INT_27_SHALLOW,
#    INT_27_SHALLOW_TO_PARALLEL,
#    INT_27_STEEP_CLOSE,
#    INT_27_STEEP_CLOSE_TO_PARALLEL,
#    INT_27_STEEP_FAR,
#    INT_27_STEEP_FAR_TO_PARALLEL,
#    INT_27N_STEEP,
#}





# FIXME: LEFT OFF HERE: --------------------------------------------------------------
# - RE-THINK THE BINDING STRATEGY!
# - Instead of being based on sides (top-left, top-right, left-top, left-bottom, etc.), be based on corners.
#   - This should be more intuitive to conceptualize, and less text to encode?
# - This might be more enum cases, but probably simpler logic for matching.
# SubtileCorner
enum {
    UNKNOWN,
    
    # Air or space beyond the collision boundary.
    EMPTY,
    # Space inside the collision boundary, but before transitioning to the
    # more-faded interior (green, purple, yellow, or light-grey in the
    # template).
    EXTERIOR,
    # Space both inside the collision boundary, and after transitioning to the
    # more-faded interior (the darker grey colors in the template).
    INTERIOR,
    
    EXT_90H,
    EXT_90V,
    EXT_90_90_CONVEX,
    EXT_90_90_CONCAVE,
    
    
    EXT_45P_FLOOR,
    EXT_45N_FLOOR,
    EXT_45P_CEILING,
    EXT_45N_CEILING,
    
    
    EXT_27P_SHALLOW,
    EXT_27P_STEEP,
    EXT_27N_STEEP,
    
    
    EXT_27P_INV_SHALLOW,
    EXT_27N_INV_SHALLOW,
    EXT_27P_INV_STEEP,
    EXT_27N_INV_STEEP,
    
    
    EXT_90H_45_CONVEX,
    EXT_90H_45_CONCAVE,
    EXT_90V_45_CONVEX,
    EXT_90V_45_CONCAVE,
    
    
    
    
    
    
    
    INT_90H,
    INT_90V,
    INT_90_90_CONCAVE,
    INT_90_90_CONVEX,
    INT_90H_TO_45,
    INT_90V_TO_45,
    INT_90H_TO_27_SHALLOW,
    INT_90H_TO_27_STEEP_SHORT,
    INT_90H_TO_27_STEEP_LONG,
    INT_45,
    INT_45_TO_90H,
    INT_45_TO_90V,
    INT_45_TO_90H_AND_90V,
    INT_45_INV,
    INT_45_INV_WITH_90_90_CONCAVE,
    INT_45_INV_WITH_90_90_CONVEX,
    INT_45_INV_WITH_90H,
    INT_45_INV_WITH_90V,
    INT_45_INV_NARROW,
    INT_45_INV_MID_NOTCH_H,
    INT_45_INV_MID_NOTCH_V,
    
}





# FIXME: LEFT OFF HERE: ---------------------------
# - Abandon the 5x5 bitmask idea for internal tiles.
#   - Way too complicated:
#     - I'd need to encode a _lot_ of optional bits.
#     - I'd also need to know shapes of neighbors.
# - Instead, just describe the shape of the internal exposure transition.
#   - flat along side
#   - 90 in corner
#   - 45 in corner
#   - 27 in corner
# - Then, have the logic look at the interesting exposure edge cases, and
#   decide which exposure-transition-shape properties must be matched.

# FIXME: LEFT OFF HERE: ---------------------------------
# - Include in the subtiles configuration a way to specify which angles are
#   allowed to transition into eachother.
# - For example, 45 into 27, 27 into 90, 27-open into 27-closed, etc.
# - Then, the tile-set author can choose how much art they want to make.
# - And account for this in the matching logic.

# FIXME: LEFT OFF HERE: ----------------------------------
# - Plan how to deal with 45-interior-transition strips that don't actually fade
#   to dark, and then also end abruptly due to not opening up into a wider area.

# FIXME: LEFT OFF HERE: ----------------------------------
# - How to handle the special subtiles that are designed to transition into a
#   different angle on the next subtile:
#   - Allow an optional second pair of flags for a side to indicate the in-bound
#     shape that this side will bind to.


# Dictionary<int, Dictionary>
var _tile_id_to_config: Dictionary

# Dictionary<String, Dictionary<String,SurfaceProperties>>
var _tile_name_to_properties: Dictionary


func _init(tiles_manifest := []) -> void:
    _parse_tiles_manifest(tiles_manifest)


func _parse_tiles_manifest(tiles_manifest: Array) -> void:
    _tile_id_to_config = {}
    
    # Create a mapping from each explicitly registered tile name to tile config.
    for entry in tiles_manifest:
        assert(entry is Dictionary)
        assert(entry.has("name") and entry.name is String)
        assert(entry.has("is_collidable") and entry.is_collidable is bool)
        assert(!entry.is_collidable or \
                entry.has("angle") and entry.angle is int)
        assert(!entry.has("properties") or entry.properties is String)
        var tile_id := find_tile_by_name(entry.name)
        assert(tile_id != TileMap.INVALID_CELL)
        entry.id = tile_id
        _tile_id_to_config[tile_id] = entry
    
    # Add default mappings for all tiles that weren't explicitly registered.
    for tile_id in get_tiles_ids():
        var tile_name := tile_get_name(tile_id)
        if !_tile_id_to_config.has(tile_id):
            _tile_id_to_config[tile_id] = {
                id = tile_id,
                name = tile_name,
                is_collidable = true,
                angle = CellAngleType.A90,
                properties = "",
            }
    
    # Ensure at least one tile is configured as collidable.
    var is_at_least_one_tile_collidable := false
    for entry in _tile_id_to_config.values():
        is_at_least_one_tile_collidable = \
                is_at_least_one_tile_collidable or entry.is_collidable
    assert(is_at_least_one_tile_collidable)


func get_tile_properties(tile_name: String) -> SurfaceProperties:
    if _tile_name_to_properties.empty():
        _tile_name_to_properties = _create_tiles_to_properties()
    return _tile_name_to_properties[tile_name].surface_properties


func _create_tiles_to_properties() -> Dictionary:
    var tiles_to_properties := {}
    for entry in _tile_id_to_config.values():
        var tile_config := {}
        tiles_to_properties[entry.name] = tile_config
        if entry.has("properties") and \
                entry.properties != "":
            tile_config.surface_properties = \
                    Su.surface_properties.properties[entry.properties]
        else:
            tile_config.surface_properties = \
                    Su.surface_properties.properties.default
    return tiles_to_properties


func _is_tile_bound( \
        drawn_id: int, \
        neighbor_id: int) -> bool:
    if neighbor_id == TileMap.INVALID_CELL:
        return false
    return _tile_id_to_config[drawn_id].is_collidable and \
            _tile_id_to_config[neighbor_id].is_collidable


func tile_get_neighbor_angle_type(tile_id: int) -> int:
    if tile_id == TileMap.INVALID_CELL:
        return CellAngleType.EMPTY
    else:
        return _tile_id_to_config[tile_id].angle


func get_collidable_tiles_ids() -> Array:
    var collidable_tiles_ids := []
    for tile_id in get_tiles_ids():
        collidable_tiles_ids.push_back(tile_id)
    return collidable_tiles_ids


func get_cell_autotile_bitmask(
        position: Vector2,
        tile_map: TileMap) -> int:
    var tile_id := tile_map.get_cellv(position)
    if tile_id == TileMap.INVALID_CELL:
        return INVALID_BITMASK
    
    var tile_mode := tile_get_tile_mode(tile_id)
    if tile_mode != AUTO_TILE:
        return INVALID_BITMASK
    
    var subtile_position := \
            tile_map.get_cell_autotile_coord(position.x, position.y)
    
    return autotile_get_bitmask(tile_id, subtile_position)


func get_cell_actual_bitmask(
        position: Vector2,
        tile_map: TileMap) -> int:
    var bitmask := 0
    if tile_map.get_cellv(position + Vector2(-1, -1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_TOPLEFT
    if tile_map.get_cellv(position + Vector2(0, -1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_TOP
    if tile_map.get_cellv(position + Vector2(1, -1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_TOPRIGHT
    if tile_map.get_cellv(position + Vector2(-1, 0)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_LEFT
    if tile_map.get_cellv(position) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_CENTER
    if tile_map.get_cellv(position + Vector2(1, 0)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_RIGHT
    if tile_map.get_cellv(position + Vector2(-1, 1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_BOTTOMLEFT
    if tile_map.get_cellv(position + Vector2(0, 1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_BOTTOM
    if tile_map.get_cellv(position + Vector2(1, 1)) != TileMap.INVALID_CELL:
        bitmask |= TileSet.BIND_BOTTOMRIGHT
    return bitmask


# FIXME: LEFT OFF HERE: -------------------------------------------
static func get_subtile_side_binding_string(type: int) -> String:
    match type:
#        UNKNOWN:
#            return "UNKNOWN"
        _:
            Sc.logger.error()
            return "??"
