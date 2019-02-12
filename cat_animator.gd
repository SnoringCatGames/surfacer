extends Node2D

func walk_left():
    play_animation("walk")
    set_scale(Vector2(1,1))

func walk_right():
    play_animation("walk")
    set_scale(Vector2(-1,1))

func rest():
    play_animation("rest")

func play_animation(name):
    var isCurrentAnimation = $AnimationPlayer.current_animation == name
    var isPlaying = $AnimationPlayer.is_playing()
    
    if !isCurrentAnimation or !isPlaying:
        $AnimationPlayer.play(name)
