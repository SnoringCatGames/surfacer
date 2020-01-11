# Information for how to move along a surface from a start position to an end position.
# 
# The instructions for an intra-surface edge consist of a single directional-key press step, with
# no corresponding release.
extends Edge
class_name IntraSurfaceEdge

var start_position_along_surface: PositionAlongSurface
var end_position_along_surface: PositionAlongSurface

func _init(start: PositionAlongSurface, end: PositionAlongSurface) \
        .(_calculate_instructions(start.target_point, end)) -> void:
    self.start_position_along_surface = start
    self.end_position_along_surface = end

func _get_start() -> Vector2:
    return start_position_along_surface.target_point

func _get_end() -> Vector2:
    return end_position_along_surface.target_point

func update_for_player_state(player) -> void:
    instructions = _calculate_instructions(player.position, \
            end_position_along_surface)

static func _calculate_instructions(start: Vector2, \
        end: PositionAlongSurface) -> MovementInstructions:
    var is_wall_surface := \
            end.surface.side == SurfaceSide.LEFT_WALL || end.surface.side == SurfaceSide.RIGHT_WALL
    
    var input_key: String
    if is_wall_surface:
        if start.y < end.target_point.y:
            input_key = "move_down"
        else:
            input_key = "move_up"
    else:
        if start.x < end.target_point.x:
            input_key = "move_right"
        else:
            input_key = "move_left"
    
    var instruction := MovementInstruction.new(input_key, 0.0, true)
    var distance_squared := start.distance_squared_to(end.target_point)
    return MovementInstructions.new([instruction], INF, distance_squared)

func _get_class_name() -> String:
    return "IntraSurfaceEdge"

func _get_start_string() -> String:
    return start_position_along_surface.to_string()

func _get_end_string() -> String:
    return end_position_along_surface.to_string()
