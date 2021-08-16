tool
class_name SurfacerColors
extends ScaffolderColors


const WHITE := Color(1.0, 1.0, 1.0)
const PURPLE := Color(0.734, 0.277, 1.0)
const TEAL := Color(0.277, 0.973, 1.0)
const RED := Color(1.0, 0.305, 0.277)
const ORANGE := Color(1.0, 0.648, 0.277)

# --- Configured colors ---

var click: Color
var surface_click_selection: Color
var grid_indices: Color
var ruler: Color
var invalid: Color
var character_position: Color
var recent_movement: Color
var inspector_origin: Color

var _surfacer_defaults := {
    click = ScaffolderColors.static_opacify(
            WHITE, ScaffolderColors.ALPHA_SLIGHTLY_FAINT),
    surface_click_selection = ScaffolderColors.static_opacify(
            WHITE, ScaffolderColors.ALPHA_SOLID),
    grid_indices = ScaffolderColors.static_opacify(
            WHITE, ScaffolderColors.ALPHA_FAINT),
    ruler = WHITE,
    invalid = RED,
    character_position = TEAL,
    recent_movement = TEAL,
    inspector_origin = ScaffolderColors.static_opacify(
            ORANGE, ScaffolderColors.ALPHA_FAINT),
}

# --- Derived colors ---

# ---


func register_manifest(manifest: Dictionary) -> void:
    for key in _surfacer_defaults:
        var value = \
                manifest[key] if \
                manifest.has(key) else \
                _defaults[key]
        self.set(key, value)
    
    .register_manifest(manifest)


#func _derive_colors() -> void:
#    ._derive_colors()
