class_name PauseButton
extends Node2D


func _ready() -> void:
    update_gui_scale()


func update_gui_scale() -> bool:
    $ScaffolderTextureButton.update_gui_scale()
    position.x = \
            get_viewport().size.x - \
            $ScaffolderTextureButton.rect_size.x - \
            InspectorPanel.PANEL_MARGIN_RIGHT * Gs.gui.scale
    position.y = InspectorPanel.PANEL_MARGIN_RIGHT * Gs.gui.scale
    return true


func _on_ScaffolderTextureButton_pressed() -> void:
    Gs.level.pause()
