# Information for how to move along a surface from a start position to an end position.
# 
# The instructions for an intra-surface edge consist of a single directional-key press step, with
# no corresponding release.
extends Edge
class_name IntraSurfaceEdge

const NAME := "IntraSurfaceEdge"
const IS_TIME_BASED := false

var start_position_along_surface: PositionAlongSurface
var end_position_along_surface: PositionAlongSurface

func _init(start: PositionAlongSurface, end: PositionAlongSurface) \
        .(NAME, IS_TIME_BASED, _calculate_instructions(start, end)) -> void:
    self.start_position_along_surface = start
    self.end_position_along_surface = end

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    # Check whether we were on the other side of the destination in the previous frame.
    var target_point: Vector2 = self.end
    var was_less_than_end: bool
    var is_less_than_end: bool
    if surface_state.is_grabbing_wall:
        was_less_than_end = surface_state.previous_center_position.y < target_point.y
        is_less_than_end = surface_state.center_position.y < target_point.y
    else:
        was_less_than_end = surface_state.previous_center_position.x < target_point.x
        is_less_than_end = surface_state.center_position.x < target_point.x
    return was_less_than_end != is_less_than_end

func _get_start() -> Vector2:
    return start_position_along_surface.target_point

func _get_end() -> Vector2:
    return end_position_along_surface.target_point

func _get_start_surface() -> Surface:
    return start_position_along_surface.surface

func _get_end_surface() -> Surface:
    return end_position_along_surface.surface

func update_for_surface_state(surface_state: PlayerSurfaceState) -> void:
    instructions = _calculate_instructions(surface_state.center_position_along_surface, \
            end_position_along_surface)

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
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
    
    var instruction := MovementInstruction.new(input_key, 0.0, true)
    var distance_squared := start.target_point.distance_squared_to(end.target_point)
    return MovementInstructions.new([instruction], INF, distance_squared)

func _get_start_string() -> String:
    return start_position_along_surface.to_string()

func _get_end_string() -> String:
    return end_position_along_surface.to_string()
