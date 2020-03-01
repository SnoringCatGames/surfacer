# Information for how to climb up and over a wall to stand on the adjacent floor.
# 
# The instructions for this edge consist of two consecutive directional-key presses (into the wall,
# and upward), with no corresponding release.
extends Edge
class_name ClimbOverWallToFloorEdge

const NAME := "ClimbOverWallToFloorEdge"
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.WALL
const ENTERS_AIR := true

func _init(start: PositionAlongSurface, end: PositionAlongSurface, \
        movement_params: MovementParams) \
        .(NAME, IS_TIME_BASED, SURFACE_TYPE, ENTERS_AIR, start, end, movement_params, \
        _calculate_instructions(start, end)) -> void:
    pass

func _calculate_distance(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions) -> float:
    return Geometry.calculate_manhattan_distance(start.target_point, end.target_point)

func _calculate_duration(start: PositionAlongSurface, end: PositionAlongSurface, \
        instructions: MovementInstructions, movement_params: MovementParams, \
        distance: float) -> float:
    return MovementUtils.calculate_time_to_climb(distance, true, movement_params)

func _check_did_just_reach_destination(navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, playback) -> bool:
    return surface_state.just_grabbed_floor

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    assert(end.surface.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "move_left" if start.surface.side == SurfaceSide.LEFT_WALL else "move_right"
    var inward_instruction := MovementInstruction.new(sideways_input_key, 0.0, true)
    
    var upward_instruction := MovementInstruction.new("move_up", 0.0, true)
    
    return MovementInstructions.new([inward_instruction, upward_instruction], INF)
