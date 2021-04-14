class_name PlayerAnimator
extends Node2D

const UNFLIPPED_HORIZONTAL_SCALE := Vector2(1, 1)
const FLIPPED_HORIZONTAL_SCALE := Vector2(-1, 1)

var animator_params: PlayerAnimatorParams
var animation_player: AnimationPlayer

func _init() -> void:
    self.animator_params = _create_params()

func _ready() -> void:
    var animation_players: Array = \
            Gs.utils.get_children_by_type(self, AnimationPlayer)
    assert(animation_players.size() == 1)
    animation_player = animation_players[0]

func _create_params() -> PlayerAnimatorParams:
    Gs.logger.error("abstract PlayerAnimator._create_params is not implemented")
    return null

func _get_animation_player() -> AnimationPlayer:
    Gs.logger.error(
            "abstract PlayerAnimator._get_animation_player is not implemented")
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

func rest() -> void:
    _play_animation(
            animator_params.rest_name,
            animator_params.rest_playback_rate)

func rest_on_wall() -> void:
    _play_animation(
            animator_params.rest_on_wall_name,
            animator_params.rest_on_wall_playback_rate)

func jump_rise() -> void:
    _play_animation(
            animator_params.jump_rise_name,
            animator_params.jump_rise_playback_rate)

func jump_fall() -> void:
    _play_animation(
            animator_params.jump_fall_name,
            animator_params.jump_fall_playback_rate)

func walk() -> void:
    _play_animation(
            animator_params.walk_name,
            animator_params.walk_playback_rate)

func climb_up() -> void:
    _play_animation(
            animator_params.climb_up_name,
            animator_params.climb_up_playback_rate)

func climb_down() -> void:
    _play_animation(
            animator_params.climb_down_name,
            animator_params.climb_down_playback_rate)

func _play_animation(
        name: String,
        playback_rate: float = 1) -> bool:
    var is_current_animatior := animation_player.current_animation == name
    var is_playing := animation_player.is_playing()
    var is_changing_direction := \
            (animation_player.get_playing_speed() < 0) != (playback_rate < 0)
    
    var animation_was_not_playing := !is_current_animatior or !is_playing
    var animation_was_playing_in_wrong_direction := \
            is_current_animatior and is_changing_direction
    
    if animation_was_not_playing or \
            animation_was_playing_in_wrong_direction:
        animation_player.play(name, .1, playback_rate)
        return true
    else:
        return false
