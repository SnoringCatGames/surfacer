tool
class_name PauseButton, \
"res://addons/scaffolder/assets/images/editor_icons/scaffolder_placeholder.png"
extends Node2D


func _ready() -> void:
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
