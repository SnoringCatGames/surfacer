class_name SurfacerHud
extends ScaffolderHud


const _INSPECTOR_PANEL_PATH := \
        "res://addons/surfacer/src/gui/panels/inspector_panel.tscn"
const _PAUSE_BUTTON_PATH := \
        "res://addons/surfacer/src/gui/pause_button.tscn"

var inspector_panel: InspectorPanel
var pause_button: PauseButton


func create_inspector() -> void:
    if Surfacer.is_inspector_enabled:
        inspector_panel = Gs.utils.add_scene(
                self,
                _INSPECTOR_PANEL_PATH)
        Gs.gui.hud.inspector_panel = inspector_panel
    else:
        pause_button = Gs.utils.add_scene(
                self,
                _PAUSE_BUTTON_PATH)


func get_is_inspector_panel_open() -> bool:
    return is_instance_valid(inspector_panel) and \
            inspector_panel.is_open
