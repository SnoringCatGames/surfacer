tool
class_name SurfacerCameraManifest
extends ScaffolderCameraManifest


var max_zoom_from_pointer := 1.5
var max_pan_distance_from_pointer := 512.0
var duration_to_max_pan_from_pointer_at_max_control := 0.67
var duration_to_max_zoom_from_pointer_at_max_control := 3.0
var screen_size_ratio_distance_from_edge_to_start_pan_from_pointer := 0.16


func _parse_manifest(manifest: Dictionary) -> void:
    ._parse_manifest(manifest)
    
    if manifest.has("max_zoom_from_pointer"):
        self.max_zoom_from_pointer = manifest.max_zoom_from_pointer
    if manifest.has("max_pan_distance_from_pointer"):
        self.max_pan_distance_from_pointer = \
                manifest.max_pan_distance_from_pointer
    if manifest.has("duration_to_max_pan_from_pointer_at_max_control"):
        self.duration_to_max_pan_from_pointer_at_max_control = \
                manifest.duration_to_max_pan_from_pointer_at_max_control
    if manifest.has("duration_to_max_zoom_from_pointer_at_max_control"):
        self.duration_to_max_zoom_from_pointer_at_max_control = \
                manifest.duration_to_max_zoom_from_pointer_at_max_control
    if manifest.has(
            "screen_size_ratio_distance_from_edge_to_start_pan_from_pointer"):
        self.screen_size_ratio_distance_from_edge_to_start_pan_from_pointer = \
                manifest \
                .screen_size_ratio_distance_from_edge_to_start_pan_from_pointer
