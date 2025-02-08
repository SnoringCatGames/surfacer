class_name ScaffolderLevel
extends Node2D


# FIXME: Move this to to Manifest.
const GAME_OVER_SCREEN_DELAY := 2.0

var has_started := false
var has_ended := false


func _init() -> void:
    S.level = self


func _ready() -> void:
    S.level_loaded.emit()


func _reset() -> void:
    has_started = false
    has_ended = false


func start() -> void:
    S.log.print("Starting level: %s" % S.utils.get_display_name(self))
    _reset()
    S.session.reset()
    S.session.start_time = S.time.get_play_time()
    unpause()
    has_started = true
    S.level_started.emit()
    S.audio.play_sfx("level_start")


func pause() -> void:
    if S.screens.is_top_screen("game"):
        S.screens.open("pause")
    get_tree().paused = true


func unpause() -> void:
    if not S.screens.is_top_screen("game"):
        S.screens.close_screens_above("game")
    get_tree().paused = false


func game_over(success: bool) -> void:
    S.log.print("Game over: %s on level %s" % [
        ("success" if success else "failure"),
        S.utils.get_display_name(self),
    ])
    S.session.end_time = S.time.get_play_time()
    has_ended = true
    S.level_ended.emit()

    await get_tree().create_timer(GAME_OVER_SCREEN_DELAY).timeout
    _show_game_over_screen()


func _physics_process(delta: float) -> void:
    if not has_started or has_ended:
        return


func _show_game_over_screen() -> void:
    S.screens.open("game_over")
    S.screens.close("game")
