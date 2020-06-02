# Information for how to climb down a wall to stand on the adjacent floor.
# 
# The instructions for this edge consist of a single downward key press, with no corresponding
# release. This will cause the player to climb down the wall, then grab the floor once they reach
# it.
extends Edge
class_name ClimbDownWallToFloorEdge

const TYPE := EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.WALL
const ENTERS_AIR := false
const INCLUDES_AIR_TRAJECTORY := false

func _init( \
        calculator, \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        movement_params: MovementParams) \
        .(TYPE, \
        IS_TIME_BASED, \
        SURFACE_TYPE, \
        ENTERS_AIR, \
        INCLUDES_AIR_TRAJECTORY, \
        calculator, \
        start, \
        end, \
        Vector2.ZERO, \
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
        trajectory: EdgeTrajectory) -> float:
    return Geometry.calculate_manhattan_distance( \
            start.target_point, \
            end.target_point)

func _calculate_duration( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface, \
        instructions: EdgeInstructions, \
        distance: float) -> float:
    return MovementUtils.calculate_time_to_climb( \
            distance, \
            false, \
            movement_params)

func _check_did_just_reach_destination( \
        navigation_state: PlayerNavigationState, \
        surface_state: PlayerSurfaceState, \
        playback) -> bool:
    return surface_state.just_grabbed_floor

static func _calculate_instructions( \
        start: PositionAlongSurface, \
        end: PositionAlongSurface) -> EdgeInstructions:
    assert(start.surface.side == SurfaceSide.LEFT_WALL || \
            start.surface.side == SurfaceSide.RIGHT_WALL)
    assert(end.surface.side == SurfaceSide.FLOOR)
    
    var instruction := EdgeInstruction.new( \
            "move_down", \
            0.0, \
            true)
    
    return EdgeInstructions.new( \
            [instruction], \
            INF)
