class_name ClimbOverWallToFloorEdge
extends Edge
# Information for how to climb up and over a wall to stand on the adjacent
# floor.
# 
# The instructions for this edge consist of two consecutive directional-key
# presses (into the wall, and upward), with no corresponding release.


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
        null,
        trajectory,
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP,
        0.0) -> void:
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
    var distance_y := end.target_point.y - start.target_point.y
    return MovementUtils.calculate_time_to_climb(
            distance_y,
            true,
            movement_params)


func get_animation_state_at_time(
        result: PlayerAnimationState,
        edge_time: float) -> void:
    result.player_position = get_position_at_time(edge_time)
    result.animation_type = PlayerAnimationType.CLIMB_UP
    result.animation_position = edge_time
    result.facing_left = get_start_surface().side == SurfaceSide.LEFT_WALL


func _update_expected_position_along_surface(
        navigation_state: PlayerNavigationState,
        edge_time: float) -> void:
    var position := navigation_state.expected_position_along_surface
    position.surface = \
            get_end_surface() if \
            navigation_state.is_stalling_one_frame_before_reaching_end else \
            get_start_surface()
    position.target_point = get_position_at_time(edge_time)
    if position.surface != null:
        position.update_target_projection_onto_surface()
    else:
        position.target_projection_onto_surface = Vector2.INF


func _check_did_just_reach_surface_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    else:
        return surface_state.just_grabbed_floor


func _get_weight_multiplier() -> float:
    return movement_params.walking_edge_weight_multiplier


static func _calculate_instructions(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        duration: float) -> EdgeInstructions:
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
            duration)


# This edge needs to override this function, since Godot's collision engine
# generates many false-positive departures and collisions when rounding the
# corner between surfaces. So we need to be more permissible here for what we
# consider to be expected when leaving and entering the air.
func _update_navigation_state_expected_surface_air_helper(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        is_starting_navigation_retry: bool) -> void:
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
