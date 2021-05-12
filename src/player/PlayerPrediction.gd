class_name PlayerPrediction
extends Node2D

var animation_state := PlayerAnimationState.new()
var animator := PlayerAnimator.new()

func set_player(player) -> void:
    animator.copy(player.animator)
