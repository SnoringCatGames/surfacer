# Information for how to walk across a floor to grab on to an adjacent upward wall.
# 
# The instructions for this edge consist of two consecutive directional-key presses (toward the
# wall, and upward), with no corresponding release.
extends Edge
class_name WalkToAscendWallFromFloor

const NAME := "WalkToAscendWallFromFloor"
const IS_TIME_BASED := false

func _init(start: PositionAlongSurface, end: PositionAlongSurface) \
        .(NAME, IS_TIME_BASED, start, end, _calculate_instructions(start, end)) -> void:
    pass

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return surface_state.just_grabbed_left_wall or surface_state.just_grabbed_right_wall

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
    assert(end.surface.side == SurfaceSide.LEFT_WALL || \
            end.surface.side == SurfaceSide.RIGHT_WALL)
    assert(start.surface.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "move_left" if end.surface.side == SurfaceSide.LEFT_WALL else "move_right"
    var inward_instruction := MovementInstruction.new(sideways_input_key, 0.0, true)
    
    var upward_instruction := MovementInstruction.new("move_up", 0.0, true)
    
    var distance := start.target_point.distance_to(end.target_point)
    
    return MovementInstructions.new([inward_instruction, upward_instruction], INF, distance)
