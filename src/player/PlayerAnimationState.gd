class_name PlayerAnimationState
extends Reference

var player_position := Vector2.INF
var animation_name := ""
var animation_position := 0.0

func reset() -> void:
    self.player_position = Vector2.INF
    self.animation_name = ""
    self.animation_position = 0.0
