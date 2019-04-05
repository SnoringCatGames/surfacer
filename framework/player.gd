extends KinematicBody2D
class_name Player

var horizontal_facing_sign := -1

# Gets low-level input for the current frame.
#
# This can be overridden separately for the human and computer players:
# - The computer player will use instruction sets.
# - The human player will use system IO.
func _get_current_input(delta: float) -> Dictionary:
    Global.error("abstract Player._get_current_input is not implemented")
    return {}

# Calculates high-level actions from low-level inputs for the current frame.
#
# Stores these high-level actions on the given action map.
func _calculate_actions(actions: Dictionary) -> void:
    Global.error("abstract Player._get_current_actions is not implemented")

# Updates physics and player states in response to the current actions.
func _process_actions(actions: Dictionary) -> void:
    Global.error("abstract Player._process_actions is not implemented")

func _physics_process(delta: float) -> void:
    var actions := _get_current_input(delta)
    _calculate_actions(actions)
    _process_actions(actions)
