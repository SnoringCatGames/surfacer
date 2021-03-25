tool
class_name ScaffoldTextureRect, "res://addons/scaffold/assets/images/editor_icons/ScaffoldTextureRect.png"
extends Control

export var texture: Texture setget \
        _set_texture,_get_texture

export var texture_scale := Vector2.ONE setget \
        _set_texture_scale,_get_texture_scale

var _is_ready := false

func _ready() -> void:
    _is_ready = true
    _set_texture(texture)
    _set_texture_scale(texture_scale)
    update_gui_scale(1.0)

func update_gui_scale(gui_scale: float) -> void:
    rect_position *= gui_scale
    $TextureRect.rect_scale *= gui_scale
    _update_size_to_match_texture()

func _update_size_to_match_texture() -> void:
    if texture == null:
        return
    var size: Vector2 = texture.get_size() * $TextureRect.rect_scale
    rect_min_size = size
    rect_size = size

func _set_texture(value: Texture) -> void:
    texture = value
    if _is_ready:
        $TextureRect.texture = value
        _update_size_to_match_texture()

func _get_texture() -> Texture:
    return texture

func _set_texture_scale(value: Vector2) -> void:
    texture_scale = value
    if _is_ready:
        $TextureRect.rect_scale = texture_scale
        _update_size_to_match_texture()

func _get_texture_scale() -> Vector2:
    return texture_scale
