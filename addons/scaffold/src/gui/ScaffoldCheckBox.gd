tool
class_name ScaffoldCheckBox, "res://addons/scaffold/assets/images/editor_icons/ScaffoldCheckBox.png"
extends Control

signal pressed
signal toggled(pressed)

export var text: String setget _set_text,_get_text
export var pressed := false setget _set_pressed,_get_pressed
export var disabled := false setget _set_disabled,_get_disabled

var _is_ready := false

func _ready() -> void:
    _is_ready = true
    _set_text(text)
    _set_pressed(pressed)
    _set_disabled(disabled)
    update_gui_scale(1.0)

func update_gui_scale(gui_scale: float) -> void:
    $CheckBox.rect_size = Vector2( \
            Gs.current_checkbox_icon_size, \
            Gs.current_checkbox_icon_size)
    var check_box_scale := _get_icon_scale()
    $CheckBox.rect_scale = Vector2(check_box_scale, check_box_scale)
    rect_min_size *= gui_scale
    rect_size *= gui_scale
    call_deferred("_update_check_box_position")

func _update_check_box_position() -> void:
    $CheckBox.rect_position = \
            (rect_size - $CheckBox.rect_size * _get_icon_scale()) / 2.0

func _get_icon_scale() -> float:
    var target_icon_size := Gs.default_checkbox_icon_size * Gs.gui_scale
    return target_icon_size / Gs.current_checkbox_icon_size

func _set_text(value: String) -> void:
    text = value
    if _is_ready:
        $CheckBox.text = value

func _get_text() -> String:
    return text

func _set_pressed(value: bool) -> void:
    pressed = value
    if _is_ready:
        $CheckBox.pressed = value

func _get_pressed() -> bool:
    return pressed

func _set_disabled(value: bool) -> void:
    disabled = value
    if _is_ready:
        $CheckBox.disabled = value

func _get_disabled() -> bool:
    return disabled

func _on_CheckBox_pressed() -> void:
    emit_signal("pressed")

func _on_CheckBox_toggled(pressed: bool) -> void:
    emit_signal("toggled", pressed)
