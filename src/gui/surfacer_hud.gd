class_name SurfacerHud
extends ScaffolderHud


const INSPECTOR_PANEL_SCENE := \
        preload("res://addons/surfacer/src/gui/panels/inspector_panel.tscn")
const PAUSE_BUTTON_SCENE := \
        preload("res://addons/surfacer/src/gui/pause_button.tscn")

var inspector_panel: InspectorPanel
var pause_button: PauseButton


func create_inspector() -> void:
    if Su.is_inspector_enabled:
        inspector_panel = Sc.utils.add_scene(
                fadable_container,
                INSPECTOR_PANEL_SCENE)
        Sc.gui.hud.inspector_panel = inspector_panel
    else:
        pause_button = Sc.utils.add_scene(
                fadable_container,
                PAUSE_BUTTON_SCENE)


func get_is_inspector_panel_open() -> bool:
    return is_instance_valid(inspector_panel) and \
            inspector_panel.is_open


func _destroy() -> void:
    ._destroy()
    if is_instance_valid(inspector_panel):
        inspector_panel._destroy()
