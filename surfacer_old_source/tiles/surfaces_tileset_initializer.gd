tool
class_name SurfacesTilesetInitializer
extends CornerMatchTilesetInitializer


func initialize_tileset(
        tile_set: CornerMatchTileset,
        forces_recalculate := false) -> void:
    tile_set._tile_id_to_config.clear()
    tile_set._tile_name_to_properties.clear()
    
    .initialize_tileset(tile_set, forces_recalculate)
    
    if tile_set is SurfacesTileset:
        _initialize_non_corner_match_tiles(tile_set, forces_recalculate)
    
    _initialize_unregistered_tiles(tile_set)
    
    # Ensure at least one tile is configured as collidable.
    var is_at_least_one_tile_collidable := false
    for entry in tile_set._tile_id_to_config.values():
        is_at_least_one_tile_collidable = \
                is_at_least_one_tile_collidable or entry.is_collidable
    assert(is_at_least_one_tile_collidable)


func _initialize_tile(
        tile: CornerMatchTile,
        forces_recalculate := false) -> void:
    ._initialize_tile(tile, forces_recalculate)
    
    var inner_tile_config: Dictionary = tile._config
    assert(inner_tile_config.is_collidable is bool)
    assert(!inner_tile_config.is_collidable or \
            (inner_tile_config.properties is String))
    
    inner_tile_config.id = inner_tile_config.inner_tile_id
    inner_tile_config.name = tile.tile_set.tile_get_name(inner_tile_config.id)
    tile.tile_set._tile_id_to_config[inner_tile_config.id] = inner_tile_config
    
    for outer_tile_id in inner_tile_config.outer_tile_ids:
        var outer_tile_config = inner_tile_config.duplicate(true)
        outer_tile_config.id = outer_tile_id
        outer_tile_config.name = tile.tile_set.tile_get_name(outer_tile_id)
        outer_tile_config.is_collidable = false
        outer_tile_config.properties = ""
        tile.tile_set._tile_id_to_config[outer_tile_id] = outer_tile_config


func _initialize_non_corner_match_tiles(
        tile_set: SurfacesTileset,
        forces_recalculate := false) -> void:
    # Create a mapping from each explicitly registered tile name to tile config.
    for tile_config in tile_set._config.non_corner_match_tiles:
        assert(tile_config is Dictionary)
        assert(tile_config.name is String)
        assert(tile_config.is_collidable is bool)
        assert(!tile_config.is_collidable or \
                (tile_config.properties is String))
        
        var tile_id := tile_set.find_tile_by_name(tile_config.name)
        assert(tile_id != TileMap.INVALID_CELL)
        tile_config.id = tile_id
        tile_set._tile_id_to_config[tile_id] = tile_config


func _initialize_unregistered_tiles(tile_set: SurfacesTileset) -> void:
    # Add default mappings for all tiles that weren't explicitly registered.
    for tile_id in tile_set.get_tiles_ids():
        var tile_name := tile_set.tile_get_name(tile_id)
        if !tile_set._tile_id_to_config.has(tile_id):
            tile_set._tile_id_to_config[tile_id] = {
                id = tile_id,
                name = tile_name,
                is_collidable = true,
                properties = "",
            }
