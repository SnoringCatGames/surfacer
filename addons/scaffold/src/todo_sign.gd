tool
extends Node2D
class_name TodoSign

export var text := "TODO" setget _set_text,_get_text

func _set_text(value: String) -> void:
    $PanelContainer/Label.text = value

func _get_text() -> String:
    return $PanelContainer/Label.text
