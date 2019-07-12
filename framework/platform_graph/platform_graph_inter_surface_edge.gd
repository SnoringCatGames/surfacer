# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
extends PlatformGraphEdge
class_name PlatformGraphInterSurfaceEdge

var instructions: PlayerInstructions

func _init(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: PlayerInstructions).(start, end) -> void:
    self.start = start
    self.end = end
    self.instructions = instructions

func _get_weight() -> float:
    return instructions.distance_squared
