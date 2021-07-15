class_name SurfacerHud
extends ScaffolderHud


const INSPECTOR_PANEL_SCENE := \
        preload("res://addons/surfacer/src/gui/panels/inspector_panel.tscn")
const PAUSE_BUTTON_SCENE := \
        preload("res://addons/surfacer/src/gui/pause_button.tscn")

var inspector_panel: InspectorPanel
var pause_button: PauseButton


func create_inspector() -> void:
    if Surfacer.is_inspector_enabled:
        inspector_panel = Gs.utils.add_scene(
                self,
                INSPECTOR_PANEL_SCENE)
        Gs.gui.hud.inspector_panel = inspector_panel
    else:
        pause_button = Gs.utils.add_scene(
                self,
                PAUSE_BUTTON_SCENE)


func get_is_inspector_panel_open() -> bool:
    return is_instance_valid(inspector_panel) and \
            inspector_panel.is_open


func _destroy() -> void:
    ._destroy()
    if is_instance_valid(inspector_panel):
        inspector_panel._destroy()
