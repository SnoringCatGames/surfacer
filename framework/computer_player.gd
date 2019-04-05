extends Player
class_name ComputerPlayer

# Gets low-level input for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
func _get_current_input(delta: float) -> Dictionary:
    # TODO
    return {}
