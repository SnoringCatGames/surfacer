tool
class_name SurfacerSurfacePropertiesManifest
extends Node


# Dictionary<String, SurfaceProperty>
var properties := {}


func _parse_manifest(manifest: Dictionary) -> void:
    self.properties.clear()
    for properties_name in manifest:
        var config: Dictionary = manifest[properties_name]
        var properties := SurfaceProperties.new()
        properties.name = properties_name
        for property_key in SurfaceProperties.KEYS:
            if config.has(property_key):
                properties.set(property_key, config[property_key])
        self.properties[properties_name] = properties
    
    if !self.properties.has("default"):
        self.properties["default"] = SurfaceProperties.new()
