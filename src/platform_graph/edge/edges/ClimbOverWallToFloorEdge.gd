# Information for how to climb up and over a wall to stand on the adjacent
# floor.
# 
# The instructions for this edge consist of two consecutive directional-key
# presses (into the wall, and upward), with no corresponding release.
class_name ClimbOverWallToFloorEdge
extends Edge

const TYPE := EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE
const IS_TIME_BASED := false
const SURFACE_TYPE := SurfaceType.WALL
const ENTERS_AIR := true
const INCLUDES_AIR_TRAJECTORY := true

func _init(
        calculator = null,
        start: PositionAlongSurface = null,
        end: PositionAlongSurface = null,
        movement_params: MovementParams = null,
        trajectory: EdgeTrajectory = null) \
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
        trajectory,
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP) -> void:
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
    var distance_y := end.target_point.y - start.target_point.y
    return MovementUtils.calculate_time_to_climb(
            distance_y,
            true,
            movement_params)

func _check_did_just_reach_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time() >= duration
    else:
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
    
    var sideways_input_key := \
            "ml" if \
            start.side == SurfaceSide.LEFT_WALL else \
            "mr"
    var inward_instruction := EdgeInstruction.new(
            sideways_input_key,
            0.0,
            true)
    
    var upward_instruction := EdgeInstruction.new(
            "mu",
            0.0,
            true)
    
    return EdgeInstructions.new(
            [inward_instruction, upward_instruction],
            INF)

# This edge needs to override this function, since Godot's collision engine
# generates many false-positive departures and collisions when rounding the
# corner between surfaces. So we need to be more permissible here for what we
# consider to be expected when leaving and entering the air.
func update_navigation_state(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback,
        just_started_new_edge: bool,
        is_starting_navigation_retry: bool) -> void:
    .update_navigation_state(
            navigation_state,
            surface_state,
            playback,
            just_started_new_edge,
            is_starting_navigation_retry)
    if is_starting_navigation_retry:
        # This should never happen.
        Gs.logger.error()
        return
    
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.get_start_surface() or \
            surface_state.grabbed_surface == self.get_end_surface()
    navigation_state.just_left_air_unexpectedly = \
            surface_state.just_left_air and \
            !is_grabbed_surface_expected and \
            surface_state.collision_count > 0
    
    navigation_state.just_entered_air_unexpectedly = false
    
    navigation_state.just_interrupted_navigation = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    navigation_state.just_reached_end_of_edge = \
            _check_did_just_reach_destination(
                    navigation_state,
                    surface_state,
                    playback)
