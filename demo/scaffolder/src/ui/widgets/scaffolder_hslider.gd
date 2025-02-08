@icon("res://icons/ScaffolderHSlider.svg")
class_name ScaffolderHSlider
extends HSlider


func _on_drag_ended(value_changed: bool) -> void:
    S.audio.play_sfx("widget_click")
    S.log.print("ScaffolderHSlider value changed: %s" % value)
