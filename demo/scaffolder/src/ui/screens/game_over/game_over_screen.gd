class_name ScaffolderGameOverScreen
extends ScaffolderScreen


# FIXME: Configure game-over music in the manifest.
# FIXME: Also, configure main-menu and pause music.


func _ready() -> void:
    super()


func _on_play_button_pressed() -> void:
    _play()


func _play() -> void:
    S.screens.open("game")
    S.screens.close(self)
