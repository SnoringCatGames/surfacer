# Information for how to move through the air from a start (jump) position on one surface to an
# end (landing) position on another surface.
extends Edge
class_name InterSurfaceEdge

var start: PositionAlongSurface
var end: PositionAlongSurface

func _init(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions).(instructions) -> void:
    self.start = start
    self.end = end
