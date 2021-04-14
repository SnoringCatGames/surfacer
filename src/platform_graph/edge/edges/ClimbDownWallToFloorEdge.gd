# Information for how to climb down a wall to stand on the adjacent floor.
# 
# The instructions for this edge consist of a single downward key press, with no corresponding
# release. This will cause the player to climb down the wall, then grab the floor once they reach
# it.
class_name ClimbDownWallToFloorEdge
extends Edge

const TYPE := EdgeType.CLIMB_DOWN_WALL_TO_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.WALL
const ENTERS_AIR := false
const INCLUDES_AIR_TRAJECTORY := false

func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        movement_params: MovementParams = null) \
        .(TYPE,
        IS_TIME_BASED,
        SURFACE_TYPE,
        ENTERS_AIR,
        INCLUDES_AIR_TRAJECTORY,
        calculator,
        start,
        end,
        Vector2.ZERO,
        Vector2.ZERO,
        false,
        false,
        movement_params,
        _calculate_instructions(start, end),
        null,
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP) -> void:
    pass

func _calculate_distance(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        trajectory: EdgeTrajectory) -> float:
    return Gs.geometry.calculate_manhattan_distance(
            start.target_point,
            end.target_point)

func _calculate_duration(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        instructions: EdgeInstructions,
        distance: float) -> float:
    return MovementUtils.calculate_time_to_climb(
            distance,
            false,
            movement_params)

func _check_did_just_reach_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    return surface_state.just_grabbed_floor

func _get_weight_multiplier() -> float:
    return movement_params.walking_edge_weight_multiplier

static func _calculate_instructions(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> EdgeInstructions:
    if start == null or end == null:
        return null
    
    assert(start.side == SurfaceSide.LEFT_WALL || \
            start.side == SurfaceSide.RIGHT_WALL)
    assert(end.side == SurfaceSide.FLOOR)
    
    var instruction := EdgeInstruction.new(
            "md",
            0.0,
            true)
    
    return EdgeInstructions.new(
            [instruction],
            INF)
