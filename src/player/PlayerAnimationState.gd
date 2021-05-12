class_name PlayerAnimationState
extends Reference

var player_position := Vector2.INF
var animation_type := PlayerAnimationType.UNKNOWN
var animation_position := 0.0
var facing_left := false

func reset() -> void:
    self.player_position = Vector2.INF
    self.animation_type = PlayerAnimationType.UNKNOWN
    self.animation_position = 0.0
    self.facing_left = false
