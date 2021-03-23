extends Control
class_name LevelSelectItemUnlockedHeader

var is_unlocked := false

func update() -> void:
    visible = is_unlocked

func update_caret_rotation(rotation: float) -> void:
    $HBoxContainer/CaretWrapper/Caret.rect_rotation = rotation
