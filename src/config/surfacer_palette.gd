tool
class_name SurfacerPalette
extends ColorPalette


# Dictionary<String, Color|ColorConfig>
var _SURFACER_DEFAULT_COLORS := {
    surface_click_selection = \
        ColorFactory.opacify("white", ColorConfig.ALPHA_SOLID),
    grid_indices = ColorFactory.opacify("white", ColorConfig.ALPHA_FAINT),
    invalid = ColorFactory.palette("red"),
    inspector_origin = ColorFactory.opacify("orange", ColorConfig.ALPHA_FAINT),
}


func _register_defaults() -> void:
    ._register_defaults()
    for key in _SURFACER_DEFAULT_COLORS:
        _colors[key] = _SURFACER_DEFAULT_COLORS[key]
