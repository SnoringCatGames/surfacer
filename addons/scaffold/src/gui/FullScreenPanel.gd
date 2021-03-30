tool
class_name FullScreenPanel, "res://addons/scaffold/assets/images/editor_icons/FullScreenPanel.png"
extends PanelContainer

func _init() -> void:
    theme = Gs.theme
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
