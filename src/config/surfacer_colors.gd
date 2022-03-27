tool
class_name SurfacerColors
extends ScaffolderColors


# --- Configured colors ---

var surface_click_selection: Color
var grid_indices: Color
var invalid: Color
var inspector_origin: Color

var _surfacer_defaults := {
    surface_click_selection = ScaffolderColors.static_opacify(
            WHITE, ScaffolderColors.ALPHA_SOLID),
    grid_indices = ScaffolderColors.static_opacify(
            WHITE, ScaffolderColors.ALPHA_FAINT),
    invalid = RED,
    inspector_origin = ScaffolderColors.static_opacify(
            ORANGE, ScaffolderColors.ALPHA_FAINT),
}

# --- Derived colors ---

# ---


func _parse_manifest(manifest: Dictionary) -> void:
    for key in _surfacer_defaults:
        var value = \
                manifest[key] if \
                manifest.has(key) else \
                _defaults[key]
        self.set(key, value)
    
    ._parse_manifest(manifest)


#func _derive_colors() -> void:
#    ._derive_colors()
