class_name PlayerPrediction
extends Node2D

var animation_state := PlayerAnimationState.new()
var animator := PlayerAnimator.new()

func set_player(player) -> void:
    animator = Gs.utils.add_scene(
            self,
            player.movement_params.animator_params.player_animator_scene_path)
    animator.set_player(player)

func match_navigator(
        navigator: Navigator,
        elapsed_time_from_now: float) -> void:
    navigator.predict_animation_state(
            animation_state,
            elapsed_time_from_now)
    position = animation_state.player_position
    animator.set_static_frame(
            animation_state.animation_type,
            animation_state.animation_position)

func match_path(
        path: PlatformGraphPath,
        elapsed_time_from_now: float) -> void:
    path.predict_animation_state(
            animation_state,
            elapsed_time_from_now)
    position = animation_state.player_position
    animator.set_static_frame(
            animation_state.animation_type,
            animation_state.animation_position)
