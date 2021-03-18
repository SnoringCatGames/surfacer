tool
extends PanelContainer
class_name CenteredPanel

export var stretches_horizontally := false \
        setget _set_stretches_horizontally,_get_stretches_horizontally
export var stretches_vertically := false \
        setget _set_stretches_vertically,_get_stretches_vertically

func _init() -> void:
    add_font_override("font", ScaffoldConfig.main_font_m)

func _ready() -> void:
    ScaffoldUtils.connect( \
            "display_resized", \
            self, \
            "_handle_display_resized")
    _handle_display_resized()

func _handle_display_resized() -> void:
    if Engine.editor_hint:
        rect_min_size = Vector2(480, 480)
        return
    
    var viewport := get_viewport()
    if viewport == null:
        return
    
    var game_area_region: Rect2 = ScaffoldUtils.get_game_area_region()
    
    rect_position = (viewport.size - game_area_region.size) * 0.5
    rect_min_size = game_area_region.size
    rect_size = game_area_region.size
    
    if stretches_horizontally:
        size_flags_horizontal = Control.SIZE_EXPAND_FILL
        rect_position.x = 0.0
        rect_min_size.x = 0.0
        rect_size.x = 0.0
    else:
        size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    
    if stretches_vertically:
        size_flags_vertical = Control.SIZE_EXPAND_FILL
        rect_position.y = 0.0
        rect_position.y = 0.0
        rect_min_size.y = 0.0
        rect_size.y = 0.0
    else:
        size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _set_stretches_horizontally(value: bool) -> void:
    stretches_horizontally = value
    _handle_display_resized()

func _get_stretches_horizontally() -> bool:
    return stretches_horizontally

func _set_stretches_vertically(value: bool) -> void:
    stretches_vertically = value
    _handle_display_resized()

func _get_stretches_vertically() -> bool:
    return stretches_vertically
