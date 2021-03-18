tool
extends PanelContainer
class_name FullScreenPanel

func _init() -> void:
    add_font_override("font", ScaffoldConfig.main_font_m)

func _enter_tree() -> void:
    if Engine.editor_hint:
        rect_size = Vector2(480, 480)
    else:
        ScaffoldUtils.connect( \
                "display_resized", \
                self, \
                "_handle_display_resized")
        _handle_display_resized()

func _handle_display_resized() -> void:
    rect_size = get_viewport().size
