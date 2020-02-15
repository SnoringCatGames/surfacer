# Information for how to walk across a floor to grab on to an adjacent upward wall.
# 
# The instructions for this edge consist of two consecutive directional-key presses (toward the
# wall, and upward), with no corresponding release.
extends Edge
class_name WalkToAscendWallFromFloorEdge

const NAME := "WalkToAscendWallFromFloorEdge"
const IS_TIME_BASED := false
const ENTERS_AIR := false

func _init(start: PositionAlongSurface, end: PositionAlongSurface) \
        .(NAME, IS_TIME_BASED, ENTERS_AIR, start, end, null) -> void:
    pass

func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface, calc_results: MovementCalcResults) -> MovementInstructions:
    assert(end.surface.side == SurfaceSide.LEFT_WALL || \
            end.surface.side == SurfaceSide.RIGHT_WALL)
    assert(start.surface.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "move_left" if end.surface.side == SurfaceSide.LEFT_WALL else "move_right"
    var inward_instruction := MovementInstruction.new(sideways_input_key, 0.0, true)
    
    var upward_instruction := MovementInstruction.new("move_up", 0.0, true)
    
    return MovementInstructions.new([inward_instruction, upward_instruction], INF)

func _calculate_distance(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) -> float:
    return start.target_point.distance_to(end.target_point)

func _calculate_duration(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, distance: float) -> float:
    # FIXME: ----------
    return INF

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return surface_state.just_grabbed_left_wall or surface_state.just_grabbed_right_wall
