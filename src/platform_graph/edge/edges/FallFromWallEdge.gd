# Information for how to let go of a wall in order to fall.
# 
# The instructions for this edge consist of a single sideways key press, with
# no corresponding release.
class_name FallFromWallEdge
extends Edge

const TYPE := EdgeType.FALL_FROM_WALL_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := true
const INCLUDES_AIR_TRAJECTORY := true

func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        velocity_end := Vector2.INF,
        includes_extra_wall_land_horizontal_speed := false,
        movement_params: MovementParams = null,
        instructions: EdgeInstructions = null,
        trajectory: EdgeTrajectory = null,
        edge_calc_result_type := EdgeCalcResultType.UNKNOWN) \
        .(TYPE,
        IS_TIME_BASED,
        SURFACE_TYPE,
        ENTERS_AIR,
        INCLUDES_AIR_TRAJECTORY,
        calculator,
        start,
        end,
        _get_velocity_start(movement_params, start),
        velocity_end,
        false,
        includes_extra_wall_land_horizontal_speed,
        movement_params,
        instructions,
        trajectory,
        edge_calc_result_type) -> void:
    pass

func _calculate_distance(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        trajectory: EdgeTrajectory) -> float:
    return trajectory.distance_from_continuous_frames

func _calculate_duration(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        instructions: EdgeInstructions,
        distance: float) -> float:
    return instructions.duration

func _check_did_just_reach_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    return Edge.check_just_landed_on_expected_surface(
            surface_state,
            self.get_end_surface())

static func _get_velocity_start(
        movement_params: MovementParams,
        start: PositionAlongSurface) -> Vector2:
    return Vector2(movement_params.wall_fall_horizontal_boost * \
                        start.surface.normal.x,
                0.0) if \
            movement_params != null and start != null else \
            Vector2.INF
