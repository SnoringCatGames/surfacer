# Information for how to move through the air to a platform.
extends Edge
class_name AirToSurfaceEdge

var start: Vector2
var end: PositionAlongSurface

func _init(start: Vector2, end: PositionAlongSurface) \
        .(_calculate_instructions(start, end)) -> void:
    self.start = start
    self.end = end

static func _calculate_instructions( \
        start: Vector2, end: PositionAlongSurface) -> PlayerInstructions:
    # FIXME: LEFT OFF HERE: ---A
    # - Re-use some of the helper functions from the JumpFromPlatformMovement class to calculate
    #   instructions for this (basically, implement the FallFromAirMovement class...).
    
    return null
