# Information for how to move from a surface to a position in the air.
extends PlatformGraphEdge
class_name PlatformGraphSurfaceToAirEdge

var start: PositionAlongSurface
var end: Vector2

func _init(start: PositionAlongSurface, end: Vector2) \
        .(_calculate_instructions(start, end)) -> void:
    self.start = start
    self.end = end

static func _calculate_instructions( \
        start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    # FIXME: LEFT OFF HERE: ---A
    # - Re-use some of the helper functions from the JumpFromPlatformMovement class to calculate
    #   instructions for this.
    
    return null
