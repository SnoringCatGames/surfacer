class_name Scaffolder
extends Node
## S (Scaffolder)
##
## -   This is an autoload that holds a bunch of modules for the Scaffolder
##     framework.
## -   These modules provide lots of common functionality that is reusable across
##     many different kinds of games.
##
## Set up:
## -   Register this as an Autoload named S.
## -   Change stuff in manifest.tres.


signal loaded

signal level_loaded
signal level_started
signal level_ended

# FIXME: Register this with manifest (under an _internal_ group).
const SCAFFOLDER_SHELL_SCENE := preload("res://scaffolder/src/core/scaffolder_shell.tscn")

var manifest: ScaffolderManifest

var log: ScaffolderLog
var utils: ScaffolderUtils
var time: ScaffolderTime
var settings: ScaffolderSettings
var audio: ScaffolderAudio
var screens: ScaffolderScreenHandler
var shell: ScaffolderShell
var game_screen: ScaffolderGameScreen
var session: ScaffolderGameSession

var level: ScaffolderLevel
var super_hud: ScaffolderSuperHud
var hud: ScaffolderHud
var player: Node


# NOTE: Call this as early as possible from your main class.
func set_up(manifest: ScaffolderManifest) -> void:
    self.manifest = manifest

    var node_modules := [
        ["log", ScaffolderLog],
        ["utils", ScaffolderUtils],
        ["time", ScaffolderTime],
        ["audio", ScaffolderAudio],
        ["screens", ScaffolderScreenHandler],
    ]

    for entry in node_modules:
        _instantiate_attach_and_record_module(entry[0], entry[1])

    # Load the user's custom settings if they exist, otherwise, load the default settings.
    if ResourceLoader.exists(ScaffolderSettings.USER_SETTINGS_PATH):
        settings = load(ScaffolderSettings.USER_SETTINGS_PATH)
        if is_instance_valid(settings):
            S.log.print("Loaded player's previous settings")
        else:
            S.log.warning("An error occurred loading the player's previous settings")
    if not is_instance_valid(settings):
        settings = load(ScaffolderSettings.DEFAULT_SETTINGS_PATH)
        S.log.print("Loaded default settings")

    var set_up_modules := [
        "settings",
        "log",
        "utils",
        "time",
        "audio",
        "screens",
    ]
    for entry in set_up_modules:
        _set_up_module(entry)

    # FIXME: Instantiate a Script that was registered with Manifest.
    session = ScaffolderGameSession.new()

    # Inject the ScaffolderShell into the scene root.
    var shell := SCAFFOLDER_SHELL_SCENE.instantiate()
    get_tree().get_current_scene().add_child(shell)

    _on_loaded()


func _instantiate_attach_and_record_module(property_name: String, script: Script) -> void:
    var instance: Node = script.new()
    set(property_name, instance)
    add_child(instance)
    instance.process_mode = Node.PROCESS_MODE_ALWAYS


func _set_up_module(property_name: String) -> void:
    var instance: Object = get(property_name)
    if instance.has_method("set_up"):
        instance.set_up()


func _on_loaded() -> void:
    if S.log.logs_early_bootstrap_events:
        S.log.print("S.loaded")
    loaded.emit()
    audio.play_sfx("game_load")
