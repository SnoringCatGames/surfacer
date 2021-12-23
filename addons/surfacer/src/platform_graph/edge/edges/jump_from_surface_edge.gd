class_name JumpFromSurfaceEdge
extends Edge
# Information for how to move through the air from a start (jump) position on
# one surface to an end (landing) position on another surface.


const TYPE := EdgeType.JUMP_FROM_SURFACE_EDGE
const IS_TIME_BASED := true
const SURFACE_TYPE := SurfaceType.AIR
const ENTERS_AIR := true


func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        velocity_end := Vector2.INF,
        distance := INF,
        duration := INF,
        includes_extra_jump_duration := false,
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
        calculator,
        start,
        end,
        velocity_start,
        velocity_end,
        distance,
        duration,
        includes_extra_jump_duration,
        includes_extra_wall_land_horizontal_speed,
        movement_params,
        instructions,
        trajectory,
        edge_calc_result_type,
        time_peak_height) -> void:
    pass


func get_animation_state_at_time(
        result: SurfacerCharacterAnimationState,
        edge_time: float) -> void:
    result.character_position = get_position_at_time(edge_time)
    result.grabbed_surface = null
    result.grab_position = Vector2.INF
    if edge_time < time_peak_height:
        result.animation_name = "JumpRise"
        result.animation_position = edge_time
    else:
        result.animation_name = "JumpFall"
        result.animation_position = edge_time - time_peak_height
    result.facing_left = instructions.get_is_facing_left_at_time(
            edge_time, velocity_start.x < 0.0)


func _check_did_just_reach_surface_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    var end_surface := get_end_surface()
    var just_landed_on_expected_surface := \
            check_just_landed_on_expected_surface(
                surface_state,
                end_surface,
                playback)
    return just_landed_on_expected_surface and \
            (!just_started_new_edge or \
            !_get_is_surface_start_or_collinear_neighbor(end_surface))
