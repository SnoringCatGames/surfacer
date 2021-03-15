extends PlayerAnimator
class_name SquirrelAnimator

func _create_params() -> PlayerAnimatorParams:
    var animator_params := PlayerAnimatorParams.new()
    
    animator_params.faces_right_by_default = true
    
    animator_params.rest_name = "Stand"
    animator_params.rest_on_wall_name = "HoldWall"
    animator_params.jump_rise_name = "JumpRise"
    animator_params.jump_fall_name = "JumpFall"
    animator_params.walk_name = "Run"
    animator_params.climb_up_name = "ClimbUp"
    animator_params.climb_down_name = "ClimbDown"
    
    animator_params.rest_playback_rate = 1.0
    animator_params.rest_on_wall_playback_rate = 1.0
    animator_params.jump_rise_playback_rate = 1.0
    animator_params.jump_fall_playback_rate = 1.0
    animator_params.walk_playback_rate = 2.3
    animator_params.climb_up_playback_rate = 2.3
    animator_params.climb_down_playback_rate = 2.3
    
    return animator_params

func _play_animation( \
        name: String, \
        playback_rate: float = 1) -> bool:
    _show_sprite(name)
    return ._play_animation(name, playback_rate)

func _show_sprite(animation_name: String) -> void:
    # Hide the other sprites.
    var sprites := [
        $Run,
        $ClimbUp,
        $ClimbDown,
        $Stand,
        $HoldWall,
        $JumpFall,
        $JumpRise,
    ]
    for sprite in sprites:
        sprite.visible = false
    
    # Show the current sprite.
    match animation_name:
        "Run":
            $Run.visible = true
        "ClimbUp":
            $ClimbUp.visible = true
        "ClimbDown":
            $ClimbDown.visible = true
        "Stand":
            $Stand.visible = true
        "HoldWall":
            $HoldWall.visible = true
        "JumpFall":
            $JumpFall.visible = true
        "JumpRise":
            $JumpRise.visible = true
        _:
            Utils.static_error()
