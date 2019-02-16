extends Node2D

const UNFLIPPED_HORIZONTAL_SCALE = Vector2(1,1)
const FLIPPED_HORIZONTAL_SCALE = Vector2(-1,1)
const HEAD_UNBLINK_REGION = Rect2(26, 34, 22, 18)
const HEAD_BLINK_REGION = Rect2(47, 86, 22, 18)

const WALK_ANIMATION_SPEED = 7.5
const CLIMB_UP_ANIMATION_SPEED = 9
const CLIMB_DOWN_ANIMATION_SPEED = -CLIMB_UP_ANIMATION_SPEED / 2.33
const REST_ANIMATION_SPEED = 0.8

func face_left():
    set_scale(UNFLIPPED_HORIZONTAL_SCALE)

func face_right():
    set_scale(FLIPPED_HORIZONTAL_SCALE)

func move_torse_up():
    $hip/torso/torso_sprite.z_index = 0

func move_torse_down():
    $hip/torso/torso_sprite.z_index = -1

func rest():
    play_animation("Rest", REST_ANIMATION_SPEED)

func rest_on_wall():
    play_animation("RestOnWall", REST_ANIMATION_SPEED)

func jump_ascend():
    play_animation("JumpAscend")

func jump_descend():
    play_animation("JumpDescend")

func walk():
    play_animation("Walk", WALK_ANIMATION_SPEED)

func climb_up():
    play_animation("Climb", CLIMB_UP_ANIMATION_SPEED)

func climb_down():
    play_animation("Climb", CLIMB_DOWN_ANIMATION_SPEED)

func blink():
    $hip/torso/neck/head.region_rect = HEAD_BLINK_REGION

func unblink():
    $hip/torso/neck/head.region_rect = HEAD_UNBLINK_REGION

func play_animation(name, playback_rate = 1):
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
