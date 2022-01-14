tool
class_name SurfacesTileSet
extends TileSet


const INVALID_BITMASK := -1
const FULL_BITMASK_3x3 := \
        TileSet.BIND_TOPLEFT | \
        TileSet.BIND_TOP | \
        TileSet.BIND_TOPRIGHT | \
        TileSet.BIND_LEFT | \
        TileSet.BIND_CENTER | \
        TileSet.BIND_RIGHT | \
        TileSet.BIND_BOTTOMLEFT | \
        TileSet.BIND_BOTTOM | \
        TileSet.BIND_BOTTOMRIGHT

# Array<[String,Array<String>]>
var _properties_manifest: Array

# Dictionary<String, Dictionary<String,SurfaceProperties>>
var _tiles_to_properties: Dictionary


func _init(properties_manifest := []) -> void:
    self._properties_manifest = properties_manifest


func get_tile_properties(tile_name: String) -> SurfaceProperties:
    if _tiles_to_properties.empty():
        _tiles_to_properties = \
                _create_tiles_to_properties(_properties_manifest)
    return _tiles_to_properties[tile_name].surface_properties


func _create_tiles_to_properties(
        properties_manifest: Array) -> Dictionary:
    var tiles_to_properties := {}
    
    # Assign non-default properties for any tiles that have been explicitly
    # registered.
    for entry in properties_manifest:
        assert(entry.size() == 2)
        assert(entry[0] is String)
        assert(entry[1] is Array)
        
        var properties_name: String = entry[0]
        var tiles_list: Array = entry[1]
        var surface_properties: SurfaceProperties = \
                Su.surface_properties.properties[properties_name]
        var tile_config := {surface_properties = surface_properties}
        
        for tile_name in tiles_list:
            assert(!tiles_to_properties.has(tile_name),
                    "Tile is registered for multiple properties: %s" % \
                    tile_name)
            tiles_to_properties[tile_name] = tile_config
    
    # Collect the tile names.
    var tile_ids := get_tiles_ids()
    var tile_names := []
    tile_names.resize(tile_ids.size())
    for i in tile_ids.size():
        tile_names[i] = tile_get_name(tile_ids[i])
    
    # Assign default properties for any tile that wasn't explicitly registered.
    for tile_name in tile_names:
        if !tiles_to_properties.has(tile_name):
            var surface_properties: SurfaceProperties = \
                    Su.surface_properties.properties["default"]
            var tile_config := {surface_properties = surface_properties}
            tiles_to_properties[tile_name] = tile_config
    
    return tiles_to_properties
