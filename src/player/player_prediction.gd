class_name PlayerPrediction
extends Node2D


var animation_state := PlayerAnimationState.new()
var animator: PlayerAnimator

var _tween: ScaffolderTween
var _tween_animation_state := PlayerAnimationState.new()


func set_up(player) -> void:
    animator = Sc.utils.add_scene(
            self,
            player.movement_params.animator_params.player_animator_path_or_scene)
    animator.set_up(player, false)
    
    _tween = ScaffolderTween.new()
    add_child(_tween)


func match_navigator_or_path(
        navigator_or_path,
        elapsed_time_from_now: float,
        tweens_player_position := true,
        tweens_animation_position := true) -> void:
    navigator_or_path.predict_animation_state(
            animation_state,
            elapsed_time_from_now)
    _update(tweens_player_position, tweens_animation_position)


func _update(
        tweens_player_position: bool,
        tweens_animation_position: bool) -> void:
    _tween.stop_all()
    
    _mod_animation_position_by_length()
    
    _tween_animation_state.animation_name = animation_state.animation_name
    _tween_animation_state.facing_left = animation_state.facing_left
    
    if tweens_player_position:
        _tween.interpolate_method(
                self,
                "_interpolate_player_position",
                _tween_animation_state.player_position,
                animation_state.player_position,
                Su.ann_manifest.nav_selection_prediction_tween_duration,
                "linear",
                0.0,
                TimeType.PLAY_PHYSICS)
    else:
        position = animation_state.player_position
    
    animator.set_static_frame(animation_state)
    
    if tweens_animation_position:
        var start_position: float = \
                _tween_animation_state.animation_position if \
                animation_state.animation_name == \
                        _tween_animation_state.animation_name else \
                0.0
        _tween.interpolate_method(
                self,
                "_interpolate_animation_position",
                start_position,
                animation_state.animation_position,
                Su.ann_manifest.nav_selection_prediction_tween_duration,
                "linear",
                0.0,
                TimeType.PLAY_PHYSICS)
    
    var modulation_progress := animation_state.confidence_multiplier
    var modulation: Color = lerp(
            PlayerAnimationState.LOW_CONFIDENCE_MODULATE_MASK,
            Color.white,
            modulation_progress)
    modulation.a = lerp(
            PlayerAnimationState.MIN_POST_PATH_CONFIDENCE_OPACITY,
            1.0,
            modulation_progress)
    animator.set_modulation(modulation)
    
    _tween.start()


func _mod_animation_position_by_length() -> void:
    var animation := animator.animation_player.get_animation(
            animation_state.animation_name)
    animation_state.animation_position = fmod(
            animation_state.animation_position,
            animation.length)


func _interpolate_player_position(player_position: Vector2) -> void:
    _tween_animation_state.player_position = player_position
    position = player_position


func _interpolate_animation_position(animation_position: float) -> void:
    _tween_animation_state.animation_position = animation_position
    animator.set_static_frame_position(animation_position)
