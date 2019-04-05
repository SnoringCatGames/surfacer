extends Node2D
class_name CatAnimator

const UNFLIPPED_HORIZONTAL_SCALE := Vector2(1,1)
const FLIPPED_HORIZONTAL_SCALE := Vector2(-1,1)
const HEAD_UNBLINK_REGION := Rect2(26, 39, 22, 18)
const HEAD_BLINK_REGION := Rect2(47, 91, 22, 18)

const WALK_ANIMATION_SPEED := 7.5
const CLIMB_UP_ANIMATION_SPEED := 9
const CLIMB_DOWN_ANIMATION_SPEED := -CLIMB_UP_ANIMATION_SPEED / 2.33
const REST_ANIMATION_SPEED := 0.8

func face_left() -> void:
    set_scale(UNFLIPPED_HORIZONTAL_SCALE)

func face_right() -> void:
    set_scale(FLIPPED_HORIZONTAL_SCALE)

func move_torse_up() -> void:
    $Hip/Torso/TorsoSprite.z_index = 0

func move_torse_down() -> void:
    $Hip/Torso/TorsoSprite.z_index = -1

func rest() -> void:
    _play_animation("Rest", REST_ANIMATION_SPEED)

func rest_on_wall() -> void:
    _play_animation("RestOnWall", REST_ANIMATION_SPEED)

func jump_ascend() -> void:
    _play_animation("JumpAscend")

func jump_descend() -> void:
    _play_animation("JumpDescend")

func walk() -> void:
    _play_animation("Walk", WALK_ANIMATION_SPEED)

func climb_up() -> void:
    _play_animation("Climb", CLIMB_UP_ANIMATION_SPEED)

func climb_down() -> void:
    _play_animation("Climb", CLIMB_DOWN_ANIMATION_SPEED)

func blink() -> void:
    $Hip/Torso/Neck/Head.region_rect = HEAD_BLINK_REGION

func unblink() -> void:
    $Hip/Torso/Neck/Head.region_rect = HEAD_UNBLINK_REGION

func _play_animation(name: String, playback_rate: float = 1) -> void:
    var isCurrentAnimation: bool = $AnimationPlayer.current_animation == name
    var isPlaying: bool = $AnimationPlayer.is_playing()
    var isChangingDirection: bool = ($AnimationPlayer.get_playing_speed() < 0) != (playback_rate < 0)
    
    var animationWasNotPlaying := !isCurrentAnimation or !isPlaying
    var animationWasPlayingInWrongDirection := isCurrentAnimation and isChangingDirection
    
    if animationWasNotPlaying or animationWasPlayingInWrongDirection:
        # In case we transition out mid-blink.
        unblink()
        
        # Most animations need the torso to be in front of the hip.
        move_torse_up()
        
        $AnimationPlayer.play(name, .1, playback_rate)
