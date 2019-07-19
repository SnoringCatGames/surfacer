extends PlayerAnimator
class_name CatAnimator

const HEAD_UNBLINK_REGION := Rect2(26, 39, 22, 18)
const HEAD_BLINK_REGION := Rect2(47, 91, 22, 18)

func _create_params() -> PlayerAnimatorParams:
    var animator_params := PlayerAnimatorParams.new()
    
    animator_params.rest_name = "Rest"
    animator_params.rest_on_wall_name = "RestOnWall"
    animator_params.jump_ascend_name = "JumpAscend"
    animator_params.jump_descend_name = "JumpDescend"
    animator_params.walk_name = "Walk"
    animator_params.climb_up_name = "Climb"
    animator_params.climb_down_name = "Climb"

    animator_params.rest_playback_rate = 0.8
    animator_params.rest_on_wall_playback_rate = 0.8
    animator_params.jump_ascend_playback_rate = 1.0
    animator_params.jump_descend_playback_rate = 1.0
    animator_params.walk_playback_rate = 7.5
    animator_params.climb_up_playback_rate = 9.0
    animator_params.climb_down_playback_rate = -animator_params.climb_up_playback_rate / 2.33

    return animator_params

func move_torse_up() -> void:
    $Hip/Torso/TorsoSprite.z_index = 0

func move_torse_down() -> void:
    $Hip/Torso/TorsoSprite.z_index = -1

func blink() -> void:
    $Hip/Torso/Neck/Head.region_rect = HEAD_BLINK_REGION

func unblink() -> void:
    $Hip/Torso/Neck/Head.region_rect = HEAD_UNBLINK_REGION

func _play_animation(name: String, playback_rate: float = 1) -> bool:
    if ._play_animation(name, playback_rate):
        # In case we transition out mid-blink.
        unblink()
        
        # Most animations need the torso to be in front of the hip.
        move_torse_up()
        
        return true
    else:
        return false
