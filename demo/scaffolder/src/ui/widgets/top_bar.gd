@tool
@icon("res://icons/ScaffolderNode.svg")
class_name TopBar
extends MarginContainer


@export var shows_credits := true
@export var shows_settings := true


func _ready() -> void:
    %Credits.visible = shows_credits
    %Settings.visible = shows_settings


func _on_credits_pressed() -> void:
    S.screens.open("credits")


func _on_settings_pressed() -> void:
    S.screens.open("settings")
