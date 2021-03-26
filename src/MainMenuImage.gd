class_name MainMenuImage
extends Control

func update_gui_scale(gui_scale: float) -> void:
    rect_position.x *= gui_scale
    rect_min_size *= gui_scale
    rect_size *= gui_scale
    $AnimatedSprite.position *= gui_scale
    $AnimatedSprite.scale *= gui_scale
