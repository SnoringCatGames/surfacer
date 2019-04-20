# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
extends Reference
class_name PlatformGraphEdge

var start: PositionAlongSurface
var end: PositionAlongSurface
# Array<PlayerInstruction>
var instructions: Array

func _init(start: PositionAlongSurface, end: PositionAlongSurface, instructions: Array) -> void:
    self.start = start
    self.end = end
    self.instructions = instructions
