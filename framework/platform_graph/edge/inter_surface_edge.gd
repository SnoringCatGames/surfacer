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

func _get_class_name() -> String:
    return "InterSurfaceEdge"

func _get_start_string() -> String:
    return start.to_string()

func _get_end_string() -> String:
    return end.to_string()
