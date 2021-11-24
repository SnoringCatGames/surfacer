tool
class_name SurfacesTileSet
extends TileSet


# Dictionary<String, Dictionary>
var _manifest: Dictionary


func _get_tile_manifest() -> Dictionary:
    Sc.logger.error(
            "Abstract SurfacesTileSet._get_tile_manifest " +
            "is not implemented")
    return {}


func get_tile_properties(tile_id: String) -> SurfaceProperties:
    if _manifest.empty():
        _manifest = _get_tile_manifest()
    return _manifest[tile_id].surface_properties
