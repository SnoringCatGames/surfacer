tool
class_name ScaffoldTextureButton, "res://addons/scaffold/assets/images/editor_icons/ScaffoldTextureButton.png"
extends Control

signal pressed

export var texture_normal: Texture setget \
        _set_texture_normal,_get_texture_normal
export var texture_pressed: Texture setget \
        _set_texture_pressed,_get_texture_pressed
export var texture_hover: Texture setget \
        _set_texture_hover,_get_texture_hover
export var texture_disabled: Texture setget \
        _set_texture_disabled,_get_texture_disabled
export var texture_focused: Texture setget \
        _set_texture_focused,_get_texture_focused
export var texture_click_mask: Texture setget \
        _set_texture_click_mask,_get_texture_click_mask

export var texture_scale := Vector2.ONE setget \
        _set_texture_scale,_get_texture_scale

var _is_ready := false

func _ready() -> void:
    _is_ready = true
    _set_texture_normal(texture_normal)
    _set_texture_pressed(texture_pressed)
    _set_texture_hover(texture_hover)
    _set_texture_disabled(texture_disabled)
    _set_texture_focused(texture_focused)
    _set_texture_click_mask(texture_click_mask)
    _set_texture_scale(texture_scale)
    update_gui_scale(1.0)

func update_gui_scale(gui_scale: float) -> void:
    rect_position *= gui_scale
    $TextureButton.rect_scale *= gui_scale
    _set_size(gui_scale * rect_size)
    set_custom_minimum_size(gui_scale * rect_min_size)

func _set_size(size: Vector2) -> void:
    ._set_size(size)
    if _is_ready:
        $TextureButton.rect_size = size / $TextureButton.rect_scale

func set_custom_minimum_size(min_size: Vector2) -> void:
    .set_custom_minimum_size(min_size)
    if _is_ready:
        $TextureButton.rect_size = min_size / $TextureButton.rect_scale

func _set_texture_normal(value: Texture) -> void:
    texture_normal = value
    if _is_ready:
        $TextureButton.texture_normal = value

func _get_texture_normal() -> Texture:
    return texture_normal

func _set_texture_pressed(value: Texture) -> void:
    texture_pressed = value
    if _is_ready:
        $TextureButton.texture_pressed = value

func _get_texture_pressed() -> Texture:
    return texture_pressed

func _set_texture_hover(value: Texture) -> void:
    texture_hover = value
    if _is_ready:
        $TextureButton.texture_hover = value

func _get_texture_hover() -> Texture:
    return texture_hover

func _set_texture_disabled(value: Texture) -> void:
    texture_disabled = value
    if _is_ready:
        $TextureButton.texture_disabled = value

func _get_texture_disabled() -> Texture:
    return texture_disabled

func _set_texture_focused(value: Texture) -> void:
    texture_focused = value
    if _is_ready:
        $TextureButton.texture_focused = value

func _get_texture_focused() -> Texture:
    return texture_focused

func _set_texture_click_mask(value: Texture) -> void:
    texture_click_mask = value
    if _is_ready:
        $TextureButton.texture_click_mask = value

func _get_texture_click_mask() -> Texture:
    return texture_click_mask

func _set_texture_scale(value: Vector2) -> void:
    texture_scale = value
    if _is_ready:
        $TextureButton.rect_scale = texture_scale

func _get_texture_scale() -> Vector2:
    return texture_scale

func _on_TextureButton_pressed() -> void:
    emit_signal("pressed")
