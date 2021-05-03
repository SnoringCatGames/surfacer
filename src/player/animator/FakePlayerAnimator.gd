class_name FakePlayerAnimator
extends PlayerAnimator

func _create_params() -> PlayerAnimatorParams:
    return PlayerAnimatorParams.new()

func _ready() -> void:
    # Do nothing.
    pass

func _play_animation(
        name: String,
        playback_rate: float = 1) -> bool:
    # Do nothing.
    return false
