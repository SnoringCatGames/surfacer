extends Node
class_name LevelInput

var _control: Control
var _focused_control: Control
var _an_active_overlay_has_focus := false

func _init() -> void:
    print("LevelInput._init")
    _control = Control.new()
    add_child(_control)

func _process(_delta_sec: float) -> void:
    var next_focused_control := _control.get_focus_owner()
    if _focused_control != next_focused_control:
        _focused_control = next_focused_control
        for overlay in Gs.active_overlays:
            assert(is_instance_valid(overlay) and overlay is Control)
            if Gs.utils.does_control_have_focus_recursively(overlay):
                _an_active_overlay_has_focus = true
                return
        _an_active_overlay_has_focus = false

func is_action_pressed(name: String) -> bool:
    return get_level_has_focus() and \
            Input.is_action_pressed(name)

func is_action_released(name: String) -> bool:
    return get_level_has_focus() and \
            Input.is_action_released(name)

func is_action_just_pressed(name: String) -> bool:
    return get_level_has_focus() and \
            Input.is_action_just_pressed(name)

func is_action_just_released(name: String) -> bool:
    return get_level_has_focus() and \
            Input.is_action_just_released(name)

func is_key_pressed(code: int) -> bool:
    return get_level_has_focus() and \
            Input.is_key_pressed(code)

func get_level_has_focus() -> bool:
    return !_an_active_overlay_has_focus
