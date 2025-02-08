class_name ScaffolderManifest
extends Resource


@export var god_mode := false

# FIXME: Incorporate Godot's new built-in Time time-scale into ScaffolderTime.
@export_range(0.5, 5.0, 0.1) var debug_time_scale := 1.0

@export var dev_mode := true
@export var skip_main_menu_in_dev_mode := false

@export var pauses_on_focus_out := true

@export var render_debug_annotations := false

@export var show_hud := true

@export_group("Logging")
# FIXME: Use these.
@export var log_surfacer_events := false
@export var log_surfacer_events_verbose := false
@export var log_scaffolder_events := false
@export var log_scaffolder_events_verbose := false
@export_group("")

@export var dev_mode_level: PackedScene
@export var main_level: PackedScene

@export var main_theme: Theme

@export var screens: Dictionary[String, PackedScene] = {
    "credits" = preload("res://scaffolder/src/ui/screens/credits/credits_screen.tscn"),
    "game_over" = preload("res://scaffolder/src/ui/screens/game_over/game_over_screen.tscn"),
    "game" = preload("res://scaffolder/src/ui/screens/game/game_screen.tscn"),
    "main_menu" = preload("res://scaffolder/src/ui/screens/main_menu/main_menu_screen.tscn"),
    "pause" = preload("res://scaffolder/src/ui/screens/pause/pause_screen.tscn"),
    "settings" = preload("res://scaffolder/src/ui/screens/settings/settings_screen.tscn"),
}

@export var canvas_layers: Array[ScaffolderCanvasLayerConfig] = [
    ScaffolderCanvasLayerConfig.new("top", Node.ProcessMode.PROCESS_MODE_ALWAYS),
    ScaffolderCanvasLayerConfig.new("notifications", Node.ProcessMode.PROCESS_MODE_ALWAYS),
    ScaffolderCanvasLayerConfig.new("super_hud", Node.ProcessMode.PROCESS_MODE_ALWAYS),
    ScaffolderCanvasLayerConfig.new("screens", Node.ProcessMode.PROCESS_MODE_ALWAYS),
    ScaffolderCanvasLayerConfig.new("hud", Node.ProcessMode.PROCESS_MODE_PAUSABLE),
    ScaffolderCanvasLayerConfig.new("annotations", Node.ProcessMode.PROCESS_MODE_PAUSABLE),
    ScaffolderCanvasLayerConfig.new("game", Node.ProcessMode.PROCESS_MODE_PAUSABLE),
]

# FIXME: Move the required hard-coded values to a separate const, and assign that const here.
#      - Then, in on-change or on-load, ensure that every required hard-coded value is present and wasn't removed by the user.
#      - Do the same for canvas_layers.
#      - Do the same for screens.
@export var sfxs: Dictionary[String, AudioStream] = {
    game_load = preload("res://scaffolder/assets/sfx/game_load.tres"),
    level_start = preload("res://scaffolder/assets/sfx/level_start.tres"),
    level_success = preload("res://scaffolder/assets/sfx/level_success.tres"),
    level_failure = preload("res://scaffolder/assets/sfx/level_failure.tres"),
    pause = preload("res://scaffolder/assets/sfx/pause.tres"),
    unpause = preload("res://scaffolder/assets/sfx/unpause.tres"),
    widget_click = preload("res://scaffolder/assets/sfx/menu_click.tres"),
}

var initial_screen: String:
    get:
        return (
            "game"
            if dev_mode and skip_main_menu_in_dev_mode
            else "main_menu"
        )


func get_screen_scene(name: String) -> PackedScene:
    return screens[name]


func has_screen_scene(name: String) -> bool:
    return screens.has(name)
