@tool
@icon("res://icons/ScaffolderTextureButton.svg")
class_name ScaffolderTextureButton
extends TextureButton


@export var master_texture: Texture2D

@export_group("Modulations")
@export var modulate_normal := Color.WHITE
@export var modulate_pressed := Color.from_hsv(0, 0, 0.5)
@export var modulate_hovered := Color.from_hsv(0, 0, 0.75)
@export var modulate_disabled := Color.from_hsv(0, 0, 1, 0.5)
@export_group("")

# TODO: Use is_hovered() once the Godot bug is fixed.
var hovered = false


func _ready() -> void:
    if is_instance_valid(master_texture):
        texture_normal = master_texture
        texture_pressed = master_texture
        texture_hover = master_texture
        texture_disabled = master_texture
        texture_focused = master_texture
    _update_button_state_modulation()


func _get_button_state_modulation() -> Color:
    if disabled:
        return modulate_disabled
    elif button_pressed:
        return modulate_pressed
    elif hovered:
        return modulate_hovered
    else:
        return modulate_normal


func _update_button_state_modulation() -> void:
    if is_instance_valid(master_texture):
        modulate = _get_button_state_modulation()


func _on_pressed() -> void:
    S.audio.play_sfx("widget_click")
    var button_name := (
        master_texture.resource_name
        if is_instance_valid(master_texture)
        else "_"
    )
    S.log.print("ScaffolderTextureButton pressed: %s" % button_name)


func _on_button_down() -> void:
    _update_button_state_modulation()
func _on_button_up() -> void:
    _update_button_state_modulation()
func _on_focus_entered() -> void:
    _update_button_state_modulation()
func _on_focus_exited() -> void:
    _update_button_state_modulation()
func _on_mouse_entered() -> void:
    hovered = true
    _update_button_state_modulation()
func _on_mouse_exited() -> void:
    hovered = false
    _update_button_state_modulation()
