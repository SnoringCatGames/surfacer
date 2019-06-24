extends ComputerPlayer
class_name SquirrelPlayer

func _init().("squirrel") -> void:
    pass

# Updates physics and player states in response to the current actions.
func _process_actions() -> void:
    velocity.x = 0
    velocity.y += actions.delta * movement_params.gravity_fast_fall
