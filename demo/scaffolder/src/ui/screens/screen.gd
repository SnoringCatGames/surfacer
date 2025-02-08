@icon("res://icons/ScaffolderScreen.svg")
class_name ScaffolderScreen
extends PanelContainer


enum ScreenState {
    CLOSED,
    OPEN,
    TOP,
}


@export var canvas_layer := "screens"
@export var pauses_game_when_open := true

var screen_state := ScreenState.CLOSED:
    set = _set_screen_state


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    theme = S.manifest.main_theme


func _set_screen_state(state: ScreenState) -> void:
    screen_state = state
