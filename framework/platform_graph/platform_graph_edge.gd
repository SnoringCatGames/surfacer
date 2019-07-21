# Information for how to move from a start position to an end position.
extends Reference
class_name PlatformGraphEdge

var instructions: PlayerInstructions

var weight: float setget ,_get_weight

func _init(instructions: PlayerInstructions) -> void:
    self.instructions = instructions

func _get_weight() -> float:
    return instructions.distance_squared
