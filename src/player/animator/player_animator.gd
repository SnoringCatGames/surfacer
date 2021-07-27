tool
class_name PlayerAnimator
extends Node2D


const DEFAULT_ANIMATION_NAMES := [
    "Walk",
    "ClimbUp",
    "ClimbDown",
    "Rest",
    "RestOnWall",
    "JumpFall",
    "JumpRise",
]

const UNFLIPPED_HORIZONTAL_SCALE := Vector2(1, 1)
const FLIPPED_HORIZONTAL_SCALE := Vector2(-1, 1)

var animator_params: PlayerAnimatorParams
var animation_player: AnimationPlayer

var is_desaturatable: bool
var _animation_name := "Rest"
var _base_rate := 1.0

var _configuration_warning := ""


func set_up(
        player_on_animator_params,
        is_desaturatable: bool) -> void:
    self.is_desaturatable = is_desaturatable
    # FIXME: -----------------------------------------
#    self.animator_params = \
#            player_on_animator_params if \
#            player_on_animator_params is PlayerAnimatorParams else \
#            player_on_animator_params.movement_params.animator_params
    
    var animation_players: Array = \
            Sc.utils.get_children_by_type(self, AnimationPlayer)
    assert(animation_players.size() == 1)
    animation_player = animation_players[0]
    
    if is_desaturatable:
        # Register these as desaturatable for the slow-motion effect.
        var sprites: Array = Sc.utils.get_children_by_type(self, Sprite, true)
        for sprite in sprites:
            sprite.add_to_group(Sc.slow_motion.GROUP_NAME_DESATURATABLES)


func _enter_tree() -> void:
    Sc.slow_motion.add_animator(self)
    _update_editor_configuration()


func _exit_tree() -> void:
    Sc.slow_motion.remove_animator(self)


func _destroy() -> void:
    Sc.slow_motion.remove_animator(self)
    if !is_queued_for_deletion():
        queue_free()


func _get_animation_player() -> AnimationPlayer:
    Sc.logger.error(
            "Abstract PlayerAnimator._get_animation_player is not implemented")
    return null


func _update_editor_configuration() -> void:
    if !Engine.editor_hint:
        return
    
    if !Sc.utils.check_whether_sub_classes_are_tools(self):
        _configuration_warning = \
                "Subclasses of PlayerAnimator must be marked as tool."
        update_configuration_warning()
        return
    
    _configuration_warning = ""
    update_configuration_warning()


func _get_configuration_warning() -> String:
    return _configuration_warning


func face_left() -> void:
    # FIXME: -------------------------------
    var scale := FLIPPED_HORIZONTAL_SCALE
#    var scale := \
#            FLIPPED_HORIZONTAL_SCALE if \
#            animator_params.faces_right_by_default else \
#            UNFLIPPED_HORIZONTAL_SCALE
    self.scale = scale


func face_right() -> void:
    # FIXME: -------------------------------
    var scale := UNFLIPPED_HORIZONTAL_SCALE
#    var scale := \
#            UNFLIPPED_HORIZONTAL_SCALE if \
#            animator_params.faces_right_by_default else \
#            FLIPPED_HORIZONTAL_SCALE
    self.scale = scale


func play(animation_name: String) -> void:
    _play_animation(animation_name)


func set_static_frame(animation_state: PlayerAnimationState) -> void:
    _animation_name = animation_state.animation_name
    
    var playback_rate := animation_type_to_playback_rate(_animation_name)
    var position := animation_state.animation_position * playback_rate
    
    if animation_state.facing_left:
        face_left()
    else:
        face_right()
    
    animation_player.play(_animation_name)
    animation_player.seek(position, true)
    animation_player.stop(false)


func set_static_frame_position(animation_position: float) -> void:
    var playback_rate := animation_type_to_playback_rate(_animation_name)
    var position := animation_position * playback_rate
    animation_player.seek(position, true)


func match_rate_to_time_scale() -> void:
    if is_instance_valid(animation_player):
        animation_player.playback_speed = \
                _base_rate * Sc.time.get_combined_scale()


func get_current_animation_name() -> String:
    return _animation_name


func set_modulation(modulation: Color) -> void:
    self.modulate = modulation


func _play_animation(
        animation_name: String,
        blend := 0.1) -> bool:
    var playback_rate := animation_type_to_playback_rate(animation_name)
    
    _animation_name = animation_name
    _base_rate = playback_rate
    
    var is_current_animatior := \
            animation_player.current_animation == animation_name
    var is_playing := animation_player.is_playing()
    var is_changing_direction := \
            (animation_player.get_playing_speed() < 0) != (playback_rate < 0)
    
    var animation_was_not_playing := !is_current_animatior or !is_playing
    var animation_was_playing_in_wrong_direction := \
            is_current_animatior and is_changing_direction
    
    if animation_was_not_playing or \
            animation_was_playing_in_wrong_direction:
        animation_player.play(animation_name, blend)
        match_rate_to_time_scale()
        return true
    else:
        return false


func animation_type_to_playback_rate(animation_name: String) -> float:
    match animation_name:
        "Rest":
            return 1.0
        "RestOnWall":
            return 1.0
        "JumpRise":
            return 1.0
        "JumpFall":
            return 1.0
        "Walk":
            return 1.0
        "ClimbUp":
            return 1.0
        "ClimbDown":
            return 1.0
        _:
            Sc.logger.error("Unrecognized animation name: %s" % animation_name)
            return 0.0


func animation_name_to_sprite(name: String) -> Sprite:
    Sc.logger.error(
            "Abstract PlayerAnimator.animation_name_to_sprite " +
            "is not implemented")
    return null
