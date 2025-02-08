@icon("res://icons/ScaffolderButton.svg")
class_name ScaffolderOptionButton
extends OptionButton


func _on_pressed() -> void:
    S.audio.play_sfx("widget_click")
    S.log.print("ScaffolderOptionButton pressed: %s" % text)


func _on_item_selected(index: int) -> void:
    S.audio.play_sfx("widget_click")
    S.log.print("ScaffolderOptionButton item selected: %s %s" % [text, index])
