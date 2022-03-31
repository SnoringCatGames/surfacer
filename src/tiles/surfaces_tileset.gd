tool
class_name SurfacesTileset
extends CornerMatchTileset


const INVALID_BITMASK := -1

# Dictionary<int, Dictionary>
var _tile_id_to_config := {}

# Dictionary<String, Dictionary<String,SurfaceProperties>>
var _tile_name_to_properties := {}


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


func get_collidable_tiles_ids() -> Array:
    var collidable_tiles_ids := []
    for tile_id in get_tiles_ids():
        if _tile_id_to_config[tile_id].is_collidable:
            collidable_tiles_ids.push_back(tile_id)
    return collidable_tiles_ids


func get_is_tile_collidable(tile_id: int) -> bool:
    return tile_id != TileMap.INVALID_CELL and \
            _tile_id_to_config[tile_id].is_collidable


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
