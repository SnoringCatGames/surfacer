tool
class_name SurfacerColors
extends ScaffolderColors


const WHITE := Color(1.0, 1.0, 1.0)
const PURPLE := Color(0.734, 0.277, 1.0)
const TEAL := Color(0.277, 0.973, 1.0)
const RED := Color(1.0, 0.305, 0.277)
const ORANGE := Color(1.0, 0.648, 0.277)

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
