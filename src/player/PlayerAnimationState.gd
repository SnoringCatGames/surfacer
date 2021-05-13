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

func copy(other: PlayerAnimationState) -> void:
    self.player_position = other.player_position
    self.animation_type = other.animation_type
    self.animation_position = other.animation_position
    self.facing_left = other.facing_left
