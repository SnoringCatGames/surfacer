@icon("res://icons/ScaffolderLinkButton.svg")
class_name ScaffolderLinkButton
extends LinkButton


func _on_pressed() -> void:
    S.audio.play_sfx("widget_click")
    S.log.print("ScaffolderLinkButton pressed: %s" % text)
