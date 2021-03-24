class_name DebugPanel
extends Node2D

const CORNER_OFFSET := Vector2(0.0, 0.0)

var is_ready := false
var text := ""

func _enter_tree() -> void:
    position.y = max(CORNER_OFFSET.y, Gs.utils.get_safe_area_margin_top())
    position.x = max(CORNER_OFFSET.x, Gs.utils.get_safe_area_margin_left())
    
    _log_device_settings()

func _ready() -> void:
    is_ready = true
    Gs.time.set_timeout(funcref(self, "_delayed_init"), 0.8)
    Gs.utils.connect( \
            "display_resized", \
            self, \
            "_on_resized")
    _on_resized()

func _on_resized() -> void:
    var viewport_size := get_viewport().size
    $PanelContainer/ScrollContainer.rect_min_size = viewport_size
    $PanelContainer/ScrollContainer/Label.rect_min_size.x = viewport_size.x

func _delayed_init() -> void:
    $PanelContainer/ScrollContainer/Label.text = text
    Gs.time.set_timeout(funcref(self, "_scroll_to_bottom"), 0.2)

func add_message(message: String) -> void:
    text += "> " + message + "\n"
    if is_ready:
        $PanelContainer/ScrollContainer/Label.text = text
        Gs.time.set_timeout(funcref(self, "_scroll_to_bottom"), 0.2)

func _scroll_to_bottom() -> void:
    $PanelContainer/ScrollContainer.scroll_vertical = \
            $PanelContainer/ScrollContainer.get_v_scrollbar().max_value

func _log_device_settings() -> void:
    var utils_model_name: String = Gs.utils.get_model_name()
    var utils_screen_scale: float = Gs.utils.get_screen_scale()
    var ios_resolution: String = \
            Gs.utils._get_ios_screen_ppi() if \
            Gs.utils.get_is_ios_device() else \
            "N/A"
    add_message("** Welcome to the debug panel! **")
    add_message( \
            ("Device settings:" + \
            "\n    OS.get_name()=%s" + \
            "\n    OS.get_model_name()=%s" + \
            "\n    Gs.utils.get_model_name()=%s" + \
            "\n    get_viewport().size=(%4d,%4d)" + \
            "\n    OS.window_size=%s" + \
            "\n    OS.get_real_window_size()=%s" + \
            "\n    OS.get_screen_size()=%s" + \
            "\n    Gs.utils.get_screen_scale()=%s" + \
            "\n    OS.get_screen_scale()=%s" + \
            "\n    Gs.utils.get_screen_ppi()=%s" + \
            "\n    Gs.utils.get_viewport_ppi()=%s" + \
            "\n    OS.get_screen_dpi()=%s" + \
            "\n    IosResolutions.get_screen_ppi()=%s" + \
            "\n    Gs.utils.get_viewport_size_inches()=%s" + \
            "\n    Gs.utils.get_viewport_diagonal_inches()=%s" + \
            "\n    Gs.utils.get_viewport_safe_area()=%s" + \
            "\n    OS.get_window_safe_area()=%s" + \
            "\n    Gs.utils.get_safe_area_margin_top()=%s" + \
            "\n    Gs.utils.get_safe_area_margin_bottom()=%s" + \
            "\n    Gs.utils.get_safe_area_margin_left()=%s" + \
            "\n    Gs.utils.get_safe_area_margin_right()=%s" + \
            "") % [
                OS.get_name(),
                OS.get_model_name(),
                utils_model_name,
                get_viewport().size.x,
                get_viewport().size.y,
                OS.window_size,
                OS.get_real_window_size(),
                OS.get_screen_size(),
                utils_screen_scale,
                OS.get_screen_scale(),
                Gs.utils.get_screen_ppi(),
                Gs.utils.get_viewport_ppi(),
                OS.get_screen_dpi(),
                ios_resolution,
                Gs.utils.get_viewport_size_inches(),
                Gs.utils.get_viewport_diagonal_inches(),
                Gs.utils.get_viewport_safe_area(),
                OS.get_window_safe_area(),
                Gs.utils.get_safe_area_margin_top(),
                Gs.utils.get_safe_area_margin_bottom(),
                Gs.utils.get_safe_area_margin_left(),
                Gs.utils.get_safe_area_margin_right(),
            ])

func _on_PanelContainer_gui_input(event: InputEvent) -> void:
    var is_mouse_down: bool = \
            event is InputEventMouseButton and \
            event.pressed and \
            event.button_index == BUTTON_LEFT
    var is_touch_down: bool = \
            (event is InputEventScreenTouch and \
                    event.pressed) or \
            event is InputEventScreenDrag
    var is_scroll: bool = \
            event is InputEventMouseButton and \
            (event.button_index == BUTTON_WHEEL_UP or \
            event.button_index == BUTTON_WHEEL_DOWN)\
    
#    if (is_mouse_down or is_touch_down or is_scroll) and \
#            $PanelContainer.get_rect().has_point(event.position):
#        $PanelContainer.accept_event()
