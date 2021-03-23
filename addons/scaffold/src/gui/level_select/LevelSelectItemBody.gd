extends Node
class_name LevelSelectItemBody

var level_id: String

func update() -> void:
    pass

func get_button() -> ShinyButton:
    return $PlayButton as ShinyButton

func _on_PlayButton_pressed():
    Gs.utils.give_button_press_feedback(true)
    Gs.nav.open("game", true)
    Gs.nav.screens["game"].start_level(level_id)
