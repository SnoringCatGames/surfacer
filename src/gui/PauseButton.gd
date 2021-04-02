class_name PauseButton
extends Node2D

func _ready() -> void:
    update_gui_scale(Gs.gui_scale)

func update_gui_scale(gui_scale: float) -> bool:
    $ScaffoldTextureButton.update_gui_scale(gui_scale)
    position.x = \
            get_viewport().size.x - \
            $ScaffoldTextureButton.rect_size.x - \
            InspectorPanel.PANEL_MARGIN_RIGHT * Gs.gui_scale
    position.y = InspectorPanel.PANEL_MARGIN_RIGHT * Gs.gui_scale
    return true

func _on_ScaffoldTextureButton_pressed() -> void:
    Gs.utils.give_button_press_feedback()
    Gs.level.pause()
