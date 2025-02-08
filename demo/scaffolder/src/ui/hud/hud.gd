@icon("res://icons/ScaffolderNode.svg")
class_name ScaffolderHud
extends PanelContainer


func _ready() -> void:
    S.hud = self

    self.visible = S.manifest.get("show_hud")


func _on_pause_pressed() -> void:
    S.level.pause()
