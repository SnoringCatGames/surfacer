tool
class_name SurfacesTileSet
extends TileSet


const INVALID_BITMASK := -1

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


func _is_tile_bound(
        drawn_id: int,
        neighbor_id: int) -> bool:
    if neighbor_id == TileMap.INVALID_CELL:
        return false
    return _tile_id_to_config[drawn_id].is_collidable and \
            _tile_id_to_config[neighbor_id].is_collidable


func tile_get_angle_type(tile_id: int) -> int:
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
