# Information for how to move along a surface from a start position to an end position.
# 
# The instructions for an intra-surface edge consist of a single directional-key press step, with
# no corresponding release.
extends PlatformGraphEdge
class_name PlatformGraphIntraSurfaceEdge

var start: PositionAlongSurface
var end: PositionAlongSurface

func _init(start: PositionAlongSurface, end: PositionAlongSurface) \
        .(_calculate_instructions(start, end)) -> void:
    self.start = start
    self.end = end

static func _calculate_instructions( \
        start: PositionAlongSurface, end: PositionAlongSurface) -> PlayerInstructions:
    var is_wall_surface := \
            end.surface.side == SurfaceSide.LEFT_WALL || end.surface.side == SurfaceSide.RIGHT_WALL
    
    var input_key: String
    if is_wall_surface:
        if start.target_point.y < end.target_point.y:
            input_key = "move_down"
        else:
            input_key = "move_up"
    else:
        if start.target_point.x < end.target_point.x:
            input_key = "move_right"
        else:
            input_key = "move_left"
    
    var instruction := PlayerInstruction.new(input_key, 0.0, true)
    var distance_squared := start.target_point.distance_squared_to(end.target_point)
    return PlayerInstructions.new([instruction], INF, distance_squared)
