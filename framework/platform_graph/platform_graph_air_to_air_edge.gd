# Information for how to move through the air from a start position to an end position.
extends PlatformGraphEdge
class_name PlatformGraphAirToAirEdge

var start: Vector2
var end: Vector2

func _init(start: Vector2, end: Vector2) \
        .(_calculate_instructions(start, end)) -> void:
    self.start = start
    self.end = end

static func _calculate_instructions(start: Vector2, end: Vector2) -> PlayerInstructions:
    # FIXME: LEFT OFF HERE: ---A
    # - Re-use some of the helper functions from the JumpFromPlatformMovement class to calculate
    #   instructions for this (basically, implement the FallFromAirMovement class...).
    
    return null
