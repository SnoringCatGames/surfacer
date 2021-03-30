class_name MainMenuImage
extends Control

func update_gui_scale(gui_scale: float) -> bool:
    rect_position *= gui_scale
    rect_min_size *= gui_scale
    rect_size *= gui_scale
    $Control.rect_position *= gui_scale
    $Control/AnimatedSprite.scale *= gui_scale
    return true
