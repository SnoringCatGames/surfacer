@icon("res://icons/ScaffolderButton.svg")
class_name ScaffolderButton
extends Button


func _on_pressed() -> void:
    S.audio.play_sfx("widget_click")
    S.log.print("ScaffolderButton pressed: %s" % text)
