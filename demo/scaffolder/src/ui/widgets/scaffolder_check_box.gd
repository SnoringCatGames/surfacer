@icon("res://icons/ScaffolderCheckBox.svg")
class_name ScaffolderCheckBox
extends CheckBox


func _on_toggled(toggled_on: bool) -> void:
    S.audio.play_sfx("widget_click")
    S.log.print("ScaffolderCheckBox pressed")
