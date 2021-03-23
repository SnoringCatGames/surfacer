tool
extends PanelContainer
class_name FullScreenPanel

func _init() -> void:
    add_font_override("font", Gs.fonts.main_m)

func _enter_tree() -> void:
    if Engine.editor_hint:
        rect_size = Vector2(960, 960)
    else:
        Gs.utils.connect( \
                "display_resized", \
                self, \
                "_on_resized")
        _on_resized()

func _on_resized() -> void:
    rect_size = get_viewport().size
