extends Node2D

const UNFLIPPED_HORIZONTAL_SCALE = Vector2(1,1)
const FLIPPED_HORIZONTAL_SCALE = Vector2(-1,1)
const HEAD_UNBLINK_REGION = Rect2(26, 39, 22, 18)
const HEAD_BLINK_REGION = Rect2(47, 91, 22, 18)

const WALK_ANIMATION_SPEED = 7.5
const CLIMB_UP_ANIMATION_SPEED = 9
const CLIMB_DOWN_ANIMATION_SPEED = -CLIMB_UP_ANIMATION_SPEED / 2.33
const REST_ANIMATION_SPEED = 0.8

func face_left():
    set_scale(UNFLIPPED_HORIZONTAL_SCALE)

func face_right():
    set_scale(FLIPPED_HORIZONTAL_SCALE)

func move_torse_up():
    $Hip/Torso/TorsoSprite.z_index = 0

func move_torse_down():
    $Hip/Torso/TorsoSprite.z_index = -1

func rest():
    _play_animation("Rest", REST_ANIMATION_SPEED)

func rest_on_wall():
    _play_animation("RestOnWall", REST_ANIMATION_SPEED)

func jump_ascend():
    _play_animation("JumpAscend")

func jump_descend():
    _play_animation("JumpDescend")

func walk():
    _play_animation("Walk", WALK_ANIMATION_SPEED)

func climb_up():
    _play_animation("Climb", CLIMB_UP_ANIMATION_SPEED)

func climb_down():
    _play_animation("Climb", CLIMB_DOWN_ANIMATION_SPEED)

func blink():
    $Hip/Torso/Neck/Head.region_rect = HEAD_BLINK_REGION

func unblink():
    $Hip/Torso/Neck/Head.region_rect = HEAD_UNBLINK_REGION

func _play_animation(name, playback_rate = 1):
    var isCurrentAnimation = $AnimationPlayer.current_animation == name
    var isPlaying = $AnimationPlayer.is_playing()
    var isChangingDirection = ($AnimationPlayer.get_playing_speed() < 0) != (playback_rate < 0)
    
    var animationWasNotPlaying = !isCurrentAnimation or !isPlaying
    var animationWasPlayingInWrongDirection = isCurrentAnimation and isChangingDirection
    
    if animationWasNotPlaying or animationWasPlayingInWrongDirection:
        # In case we transition out mid-blink.
        unblink()
        
        # Most animations need the torso to be in front of the hip.
        move_torse_up()
        
        $AnimationPlayer.play(name, .1, playback_rate)
