class_name FromAirEdge
extends Edge
# Information for how to move through the air to a platform.


const TYPE := EdgeType.FROM_AIR_EDGE
const IS_TIME_BASED := true
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := false
const INCLUDES_AIR_TRAJECTORY := true


func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        velocity_end := Vector2.INF,
        includes_extra_wall_land_horizontal_speed := false,
        movement_params: MovementParameters = null,
        instructions: EdgeInstructions = null,
        trajectory: EdgeTrajectory = null,
        edge_calc_result_type := EdgeCalcResultType.UNKNOWN,
        time_peak_height := INF) \
        .(TYPE,
        IS_TIME_BASED,
        SURFACE_TYPE,
        ENTERS_AIR,
        INCLUDES_AIR_TRAJECTORY,
        calculator,
        start,
        end,
        velocity_start,
        velocity_end,
        false,
        includes_extra_wall_land_horizontal_speed,
        movement_params,
        instructions,
        trajectory,
        edge_calc_result_type,
        time_peak_height) -> void:
    pass


func _calculate_distance(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        trajectory: EdgeTrajectory) -> float:
    return trajectory.distance_from_continuous_trajectory


func _calculate_duration(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        instructions: EdgeInstructions,
        distance: float) -> float:
    return instructions.duration


func get_animation_state_at_time(
        result: PlayerAnimationState,
        edge_time: float) -> void:
    result.player_position = get_position_at_time(edge_time)
    if edge_time < time_peak_height:
        result.animation_name = "JumpRise"
        result.animation_position = edge_time
    else:
        result.animation_name = "JumpFall"
        result.animation_position = edge_time - time_peak_height
    result.facing_left = instructions.get_is_facing_left_at_time(
            edge_time, velocity_start.x < 0.0)


func _check_did_just_reach_surface_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    return check_just_landed_on_expected_surface(
            surface_state,
            self.get_end_surface(),
            playback)
