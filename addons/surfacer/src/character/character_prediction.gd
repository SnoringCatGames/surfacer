class_name CharacterPrediction
extends Node2D


var animation_state := SurfacerCharacterAnimationState.new()
var animator: ScaffolderCharacterAnimator
var character: ScaffolderCharacter

var _tween: ScaffolderTween
var _tween_animation_state := SurfacerCharacterAnimationState.new()


func set_up(character) -> void:
    self.character = character
    animator = Sc.utils.add_scene(
            self,
            character.animator.filename)
    animator.is_desaturatable = false
    
    _tween = ScaffolderTween.new()
    add_child(_tween)


func match_navigator_or_path(
        navigator_or_path,
        elapsed_time_from_now: float,
        tweens_character_position := true,
        tweens_animation_position := true) -> void:
    navigator_or_path.predict_animation_state(
            animation_state,
            elapsed_time_from_now)
    _update(tweens_character_position, tweens_animation_position)


func _update(
        tweens_character_position: bool,
        tweens_animation_position: bool) -> void:
    _tween.stop_all()
    
    _mod_animation_position_by_length()
    
    _tween_animation_state.animation_name = animation_state.animation_name
    _tween_animation_state.facing_left = animation_state.facing_left
    
    var grab_normal: Vector2 = \
            Sc.geometry.get_surface_normal_at_point(
                    animation_state.grabbed_surface,
                    animation_state.grab_position) if \
            is_instance_valid(animation_state.grabbed_surface) else \
            Vector2.INF
    animator.sync_position_rotation_for_contact_normal(
            animation_state.character_position,
            character.collider,
            animation_state.grabbed_surface,
            animation_state.grab_position,
            grab_normal)
    
    if tweens_character_position:
        _tween.interpolate_method(
                self,
                "_interpolate_character_position",
                _tween_animation_state.character_position,
                animation_state.character_position,
                Su.ann_manifest.nav_selection_prediction_tween_duration,
                "linear",
                0.0,
                TimeType.PLAY_PHYSICS)
    else:
        position = animation_state.character_position
    
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
            CharacterAnimationState.LOW_CONFIDENCE_MODULATE_MASK,
            Color.white,
            modulation_progress)
    modulation.a = lerp(
            CharacterAnimationState.MIN_POST_PATH_CONFIDENCE_OPACITY,
            1.0,
            modulation_progress)
    animator.set_modulation(modulation)
    
    _tween.start()


func _mod_animation_position_by_length() -> void:
    var specific_animation := \
            animator._standand_animation_name_to_specific_animation_name(
                    animation_state.animation_name)
    var animation := \
            animator.animation_player.get_animation(specific_animation)
    animation_state.animation_position = fmod(
            animation_state.animation_position,
            animation.length)


func _interpolate_character_position(character_position: Vector2) -> void:
    _tween_animation_state.character_position = character_position
    position = character_position


func _interpolate_animation_position(animation_position: float) -> void:
    _tween_animation_state.animation_position = animation_position
    animator.set_static_frame_position(animation_position)
#     animator.set_static_frame(_tween_animation_state)
