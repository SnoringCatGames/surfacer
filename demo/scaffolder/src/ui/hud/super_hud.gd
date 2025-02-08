@icon("res://icons/ScaffolderNode.svg")
class_name ScaffolderSuperHud
extends MarginContainer


func _ready() -> void:
    S.super_hud = self

    self.visible = S.manifest.get("show_hud")
