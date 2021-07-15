class_name PauseButton, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_placeholder.png"
extends Node2D


func _ready() -> void:
    $ScaffolderTextureButton \
            .texture_pressed = Sc.icons.pause_circle_active
    $ScaffolderTextureButton \
            .texture_hover = Sc.icons.pause_circle_hover
    $ScaffolderTextureButton \
            .texture_normal = Sc.icons.pause_circle_normal
    $ScaffolderTextureButton.texture_scale = Vector2(4.0, 4.0)
    _on_gui_scale_changed()


func _on_gui_scale_changed() -> bool:
    $ScaffolderTextureButton._on_gui_scale_changed()
    position.x = \
            Sc.device.get_viewport_size().x - \
            $ScaffolderTextureButton.rect_size.x - \
            InspectorPanel.PANEL_MARGIN_RIGHT * Sc.gui.scale
    position.y = InspectorPanel.PANEL_MARGIN_RIGHT * Sc.gui.scale
    return true


func _on_ScaffolderTextureButton_pressed() -> void:
    Sc.level.pause()
