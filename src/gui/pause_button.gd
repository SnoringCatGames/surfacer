tool
class_name PauseButton, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_placeholder.png"
extends Node2D


func _ready() -> void:
    _on_gui_scale_changed()
    
    $SpriteModulationButton.normal_modulate = \
        ColorFactory.palette("button_hover")
    $SpriteModulationButton.hover_modulate = \
        ColorFactory.palette("white")
    $SpriteModulationButton.pressed_modulate = \
        ColorFactory.palette("button_pressed")
    $SpriteModulationButton.disabled_modulate = \
        ColorFactory.palette("button_disabled")


func _on_gui_scale_changed() -> bool:
    position.x = \
        Sc.device.get_viewport_size().x - \
        (InspectorPanel.FOOTER_BUTTON_RADIUS + \
        InspectorPanel.PANEL_MARGIN_RIGHT) * \
        Sc.gui.scale
    position.y = \
        (InspectorPanel.FOOTER_MARGIN_TOP + \
        InspectorPanel.FOOTER_BUTTON_RADIUS) * \
        Sc.gui.scale
    
    $SpriteModulationButton.shape_circle_radius = \
        InspectorPanel.FOOTER_BUTTON_RADIUS * Sc.gui.scale
    
    return true


func _on_SpriteModulationButton_touch_down(
        level_position: Vector2,
        is_already_handled: bool) -> void:
    Sc.level.pause()
