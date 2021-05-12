class_name PlayerAnimator
extends Node2D

const UNFLIPPED_HORIZONTAL_SCALE := Vector2(1, 1)
const FLIPPED_HORIZONTAL_SCALE := Vector2(-1, 1)

var animator_params: PlayerAnimatorParams
var animation_player: AnimationPlayer

var is_desaturatable: bool
var _animation_type := PlayerAnimationType.UNKNOWN
var _base_rate := 1.0

func set_up(player, is_desaturatable: bool) -> void:
    self.is_desaturatable = is_desaturatable
    self.animator_params = player.movement_params.animator_params
    _initialize()

func _initialize() -> void:
    var animation_players: Array = \
            Gs.utils.get_children_by_type(self, AnimationPlayer)
    assert(animation_players.size() == 1)
    animation_player = animation_players[0]
    
    if is_desaturatable:
        # Register these as desaturatable for the slow-motion effect.
        var sprites := Gs.utils.get_children_by_type(self, Sprite, true)
        for sprite in sprites:
            sprite.add_to_group(Surfacer.group_name_desaturatable)

func _get_animation_player() -> AnimationPlayer:
    Gs.logger.error(
            "Abstract PlayerAnimator._get_animation_player is not implemented")
    return null
            
func face_left() -> void:
    var scale := \
            FLIPPED_HORIZONTAL_SCALE if \
            animator_params.faces_right_by_default else \
            UNFLIPPED_HORIZONTAL_SCALE
    set_scale(scale)

func face_right() -> void:
    var scale := \
            UNFLIPPED_HORIZONTAL_SCALE if \
            animator_params.faces_right_by_default else \
            FLIPPED_HORIZONTAL_SCALE
    set_scale(scale)

func play(animation_type: int) -> void:
    _play_animation(animation_type)

func set_static_frame(
        animation_type: int,
        animation_position: float) -> void:
    var animation_name := _animation_type_to_name(animation_type)
    animation_player.play(animation_name)
    animation_player.seek(animation_position, true)
    animation_player.stop(false)

func match_rate_to_time_scale() -> void:
    animation_player.playback_speed = _base_rate * Gs.time.get_combined_scale()

func get_current_animation_type() -> int:
    return _animation_type

func _play_animation(
        animation_type: int,
        blend := 0.1) -> bool:
    var name := _animation_type_to_name(animation_type)
    var playback_rate := _animation_type_to_playback_rate(animation_type)
    
    _animation_type = animation_type
    _base_rate = playback_rate
    
    var is_current_animatior := animation_player.current_animation == name
    var is_playing := animation_player.is_playing()
    var is_changing_direction := \
            (animation_player.get_playing_speed() < 0) != (playback_rate < 0)
    
    var animation_was_not_playing := !is_current_animatior or !is_playing
    var animation_was_playing_in_wrong_direction := \
            is_current_animatior and is_changing_direction
    
    if animation_was_not_playing or \
            animation_was_playing_in_wrong_direction:
        animation_player.play(name, blend, playback_rate)
        match_rate_to_time_scale()
        return true
    else:
        return false

func _animation_type_to_name(animation_type: int) -> String:
    match animation_type:
        PlayerAnimationType.REST:
            return animator_params.rest_name
        PlayerAnimationType.REST_ON_WALL:
            return animator_params.rest_on_wall_name
        PlayerAnimationType.JUMP_RISE:
            return animator_params.jump_rise_name
        PlayerAnimationType.JUMP_FALL:
            return animator_params.jump_fall_name
        PlayerAnimationType.WALK:
            return animator_params.walk_name
        PlayerAnimationType.CLIMB_UP:
            return animator_params.climb_up_name
        PlayerAnimationType.CLIMB_DOWN:
            return animator_params.climb_down_name
        _:
            Gs.utils.error(
                    "Unrecognized PlayerAnimationType: %s" % animation_type)
            return ""

func _animation_type_to_playback_rate(animation_type: int) -> float:
    match animation_type:
        PlayerAnimationType.REST:
            return animator_params.rest_playback_rate
        PlayerAnimationType.REST_ON_WALL:
            return animator_params.rest_on_wall_playback_rate
        PlayerAnimationType.JUMP_RISE:
            return animator_params.jump_rise_playback_rate
        PlayerAnimationType.JUMP_FALL:
            return animator_params.jump_fall_playback_rate
        PlayerAnimationType.WALK:
            return animator_params.walk_playback_rate
        PlayerAnimationType.CLIMB_UP:
            return animator_params.climb_up_playback_rate
        PlayerAnimationType.CLIMB_DOWN:
            return animator_params.climb_down_playback_rate
        _:
            Gs.utils.error(
                    "Unrecognized PlayerAnimationType: %s" % animation_type)
            return 0.0
