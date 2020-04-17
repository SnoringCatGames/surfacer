# Information for how to walk across a floor to grab on to an adjacent upward wall.
# 
# The instructions for this edge consist of two consecutive directional-key presses (toward the
# wall, and upward), with no corresponding release.
extends Edge
class_name WalkToAscendWallFromFloorEdge

const NAME := "WalkToAscendWallFromFloorEdge"
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.FLOOR
const ENTERS_AIR := false

func _init( \
        calculator, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        velocity_start: Vector2, \
        movement_params: MovementParams) \
        .(NAME, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        calculator, \
        start, \
        end, \
        velocity_start, \
        Vector2.ZERO, \
        false, \
        false, \
        movement_params, \
        _calculate_instructions(start, end), \
        null) -> void:
    pass

func _calculate_distance( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        trajectory: MovementTrajectory) -> float:
    return Geometry.calculate_manhattan_distance(start.target_point, end.target_point)

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: MovementInstructions, \
        movement_params: MovementParams, \
        distance: float) -> float:
    return MovementUtils.calculate_time_to_walk( \
            distance, \
            0.0, \
            movement_params)

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    return surface_state.just_grabbed_left_wall or surface_state.just_grabbed_right_wall

static func _calculate_instructions( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface) -> MovementInstructions:
    assert(end.surface.side == SurfaceSide.LEFT_WALL || \
            end.surface.side == SurfaceSide.RIGHT_WALL)
    assert(start.surface.side == SurfaceSide.FLOOR)
    
    var sideways_input_key := \
            "move_left" if end.surface.side == SurfaceSide.LEFT_WALL else "move_right"
    var inward_instruction := MovementInstruction.new( \
            sideways_input_key, \
            0.0, \
            true)
    
    var upward_instruction := MovementInstruction.new( \
            "move_up", \
            0.0, \
            true)
    
    return MovementInstructions.new( \
            [inward_instruction, upward_instruction], \
            INF)
