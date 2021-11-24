tool
class_name TileSetWithSquareCorners
extends SurfacesTileSet


func _get_tile_manifest() -> Dictionary:
    var manifest := {}
    for tile_id in get_tiles_ids():
        var tile_name := tile_get_name(tile_id)
        var tile_config := {}
        tile_config.surface_properties = Su.surface_properties["default"]
        manifest[tile_name] = tile_config
    return manifest
