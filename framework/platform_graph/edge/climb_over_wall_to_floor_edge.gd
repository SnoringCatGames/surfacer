# Information for how to climb up and over a wall to stand on the adjacent floor.
# 
# The instructions for this edge consist of two consecutive directional-key presses (into the wall,
# and upward), with no corresponding release.
extends Edge
class_name ClimbOverWallToFloorEdge

const NAME := "ClimbOverWallToFloorEdge"
const IS_TIME_BASED := false

var start_position_along_surface: PositionAlongSurface
var end_position_along_surface: PositionAlongSurface

func _init(start: PositionAlongSurface, end: PositionAlongSurface) \
        .(NAME, IS_TIME_BASED, _calculate_instructions(start, end)) -> void:
    self.start_position_along_surface = start
    self.end_position_along_surface = end

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    assert(end.surface.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "move_left" if start.surface.side == SurfaceSide.LEFT_WALL else "move_right"
    var inward_instruction := MovementInstruction.new(sideways_input_key, 0.0, true)
    
    var upward_instruction := MovementInstruction.new("move_up", 0.0, true)
    
    var distance_squared := start.target_point.distance_squared_to(end.target_point)
    
    return MovementInstructions.new([inward_instruction, upward_instruction], INF, \
            distance_squared)

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return surface_state.just_grabbed_floor

func _get_start() -> Vector2:
    return start_position_along_surface.target_point

func _get_end() -> Vector2:
    return end_position_along_surface.target_point

func _get_start_surface() -> Surface:
    return start_position_along_surface.surface

func _get_end_surface() -> Surface:
    return end_position_along_surface.surface

func _get_start_string() -> String:
    return start_position_along_surface.to_string()

func _get_end_string() -> String:
    return end_position_along_surface.to_string()
