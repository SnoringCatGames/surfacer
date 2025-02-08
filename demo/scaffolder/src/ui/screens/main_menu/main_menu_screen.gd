class_name ScaffolderMainMenuScreen
extends ScaffolderScreen


func _unhandled_input(event: InputEvent) -> void:
    if (event.is_released() and
            (event is InputEventMouseButton or event is InputEventKey) and
            screen_state == ScreenState.TOP):
        S.log.print("MainMenuScreen pressed")
        S.screens.open("game")
        S.screens.close(self)
