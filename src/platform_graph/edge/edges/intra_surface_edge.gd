class_name IntraSurfaceEdge
extends Edge
## -   Information for how to move along a surface from a start position to an
##     end position.[br]
## -   The instructions for an intra-surface edge consist of a single
##     directional-key press step, with no corresponding release.[br]


const TYPE := EdgeType.INTRA_SURFACE_EDGE
const IS_TIME_BASED := false
const ENTERS_AIR := false

const REACHED_DESTINATION_DISTANCE_THRESHOLD := 3.0

var is_moving_clockwise := false
var stopping_distance := INF
var is_backtracking_to_not_protrude_past_surface_end := false
# If true, then this edge starts and ends at the same position.
var is_degenerate: bool


func _init(
        calculator = null,
        start_position_along_surface: PositionAlongSurface = null,
        end_position_along_surface: PositionAlongSurface = null,
        velocity_start := Vector2.INF,
        velocity_end := Vector2.INF,
        distance := INF,
        duration := INF,
        is_moving_clockwise := false,
        stopping_distance := INF,
        is_degenerate := false,
        movement_params: MovementParameters = null,
        instructions: EdgeInstructions = null,
        trajectory: EdgeTrajectory = null) \
        .(TYPE,
        IS_TIME_BASED,
        SurfaceType.get_type_from_side(start_position_along_surface.side),
        ENTERS_AIR,
        calculator,
        start_position_along_surface,
        end_position_along_surface,
        velocity_start,
        velocity_end,
        distance,
        duration,
        false,
        false,
        movement_params,
        instructions,
        trajectory,
        EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP,
        0.0) -> void:
    # Intra-surface edges are never calculated and stored ahead of time;
    # they're only calculated at run time when navigating a specific path.
    self.is_optimized_for_path = true
    self.is_moving_clockwise = is_moving_clockwise
    self.stopping_distance = stopping_distance
    self.is_degenerate = is_degenerate


func get_position_at_time(edge_time: float) -> Vector2:
    if is_instance_valid(trajectory):
        return .get_position_at_time(edge_time)
    else:
        return _get_position_at_time_without_trajectory(edge_time)


func get_velocity_at_time(edge_time: float) -> Vector2:
    if is_instance_valid(trajectory):
        return .get_velocity_at_time(edge_time)
    else:
        return _get_velocity_at_time_without_trajectory(edge_time)


func _get_position_at_time_without_trajectory(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var start := get_start()
    var displacement := get_end() - start
    var surface := get_start_surface()
    match surface.side:
        SurfaceSide.FLOOR:
            var acceleration_x := \
                    movement_params.walk_acceleration if \
                    displacement.x > 0 else \
                    -movement_params.walk_acceleration
            var displacement_x := \
                    MovementUtils.calculate_displacement_for_duration(
                            edge_time,
                            velocity_start.x,
                            acceleration_x,
                            movement_params.max_horizontal_speed_default)
            var position_x := start.x + displacement_x
            return Sc.geometry.project_shape_onto_surface(
                    Vector2(position_x, 0.0),
                    movement_params.collider,
                    surface)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var velocity_y := \
                    movement_params.climb_up_speed if \
                    displacement.y < 0.0 else \
                    movement_params.climb_down_speed
            var position_y := start.y + velocity_y * edge_time
            return Sc.geometry.project_shape_onto_surface(
                    Vector2(0.0, position_y),
                    movement_params.collider,
                    surface)
        SurfaceSide.CEILING:
            var velocity_x := \
                    movement_params.ceiling_crawl_speed if \
                    displacement.x > 0.0 else \
                    -movement_params.ceiling_crawl_speed
            var position_x := start.x + velocity_x * edge_time
            return Sc.geometry.project_shape_onto_surface(
                    Vector2(position_x, 0.0),
                    movement_params.collider,
                    surface)
        _:
            Sc.logger.error()
            return Vector2.INF


func _get_velocity_at_time_without_trajectory(edge_time: float) -> Vector2:
    if edge_time > duration:
        return Vector2.INF
    var start := get_start()
    var displacement := get_end() - start
    var surface := get_start_surface()
    match surface.side:
        SurfaceSide.FLOOR:
            var acceleration_x := \
                    movement_params.walk_acceleration if \
                    displacement.x > 0 else \
                    -movement_params.walk_acceleration
            var velocity_x := velocity_start.x + acceleration_x * edge_time
            velocity_x = clamp(
                    velocity_x,
                    -movement_params.max_horizontal_speed_default,
                    movement_params.max_horizontal_speed_default)
            return Vector2(velocity_x, 0.0)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var velocity_y := \
                    movement_params.climb_up_speed if \
                    displacement.y < 0.0 else \
                    movement_params.climb_down_speed
            return Vector2(0.0, velocity_y)
        SurfaceSide.CEILING:
            var velocity_x := \
                    movement_params.ceiling_crawl_speed if \
                    displacement.x > 0.0 else \
                    -movement_params.ceiling_crawl_speed
            return Vector2(velocity_x, 0.0)
        _:
            Sc.logger.error()
            return Vector2.INF


func get_animation_state_at_time(
        result: CharacterAnimationState,
        edge_time: float) -> void:
    var displacement := get_end() - get_start()
    
    result.character_position = get_position_at_time(edge_time)
    result.animation_position = edge_time
    
    var side := get_start_surface().side
    match side:
        SurfaceSide.FLOOR:
            result.animation_name = "Walk"
            result.facing_left = displacement.x < 0.0
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            result.animation_name = \
                    "ClimbUp" if \
                    displacement.y < 0.0 else \
                    "ClimbDown"
            result.facing_left = side == SurfaceSide.LEFT_WALL
        SurfaceSide.CEILING:
            result.animation_name = "CrawlOnCeiling"
            result.facing_left = displacement.x < 0.0
        _:
            Sc.logger.error()


func _check_did_just_reach_surface_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    
    if surface_state.contact_count > 1:
        var surface := get_start_surface()
        var concave_neighbor_approaching := \
                surface.clockwise_concave_neighbor if \
                is_moving_clockwise else \
                surface.counter_clockwise_concave_neighbor
        for contact_surface in surface_state.surfaces_to_contacts:
            if contact_surface == concave_neighbor_approaching:
                # Colliding with the neighbor that we're approaching at the
                # end of the edge.
                return true
            else:
                continue
    
    # Check whether we were on the other side of the destination in the
    # previous frame.
    
    var end := end_position_along_surface.target_point
    
    var was_less_than_end: bool
    var is_less_than_end: bool
    var diff: float
    var is_moving_away_from_destination: bool
    
    if surface_state.is_grabbing_wall:
        var is_moving_upward: bool = \
                instructions.instructions[0].input_key == "mu"
        var position_y_instruction_end := \
                end.y + stopping_distance if \
                is_moving_upward else \
                end.y - stopping_distance
        was_less_than_end = surface_state.previous_center_position.y < \
                position_y_instruction_end
        is_less_than_end = surface_state.center_position.y < \
                position_y_instruction_end
        diff = position_y_instruction_end - surface_state.center_position.y
        is_moving_away_from_destination = (diff > 0) == is_moving_upward
        
    else:
        var is_moving_leftward: bool = \
                instructions.instructions[0].input_key == "ml"
        var position_x_instruction_end := \
                end.x + stopping_distance if \
                is_moving_leftward else \
                end.x - stopping_distance
        was_less_than_end = surface_state.previous_center_position.x < \
                position_x_instruction_end
        is_less_than_end = surface_state.center_position.x < \
                position_x_instruction_end
        diff = position_x_instruction_end - surface_state.center_position.x
        is_moving_away_from_destination = (diff > 0) == is_moving_leftward
    
    var moved_across_destination := was_less_than_end != is_less_than_end
    var is_close_to_destination := \
            abs(diff) < REACHED_DESTINATION_DISTANCE_THRESHOLD
    
    return moved_across_destination or \
            is_close_to_destination or \
            is_moving_away_from_destination


func _update_navigation_state_edge_specific_helper(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        is_starting_navigation_retry: bool) -> void:
    # -   We only need special navigation-state updates when colliding with
    #     multiple surfaces,
    # -   and we don't need special updates if we already know the edge is
    #     done.
    if surface_state.contact_count < 2 or \
            navigation_state.just_interrupted:
        return
    
    var surface := get_start_surface()
    
    for contact_surface in surface_state.surfaces_to_contacts:
        if contact_surface == surface or \
                contact_surface == surface.clockwise_concave_neighbor or \
                contact_surface == \
                        surface.counter_clockwise_concave_neighbor or \
                contact_surface == surface.clockwise_convex_neighbor or \
                contact_surface == surface.counter_clockwise_convex_neighbor:
            continue
        else:
            # Colliding with an unconnected surface.
            # Interrupted the edge.
            navigation_state.just_interrupted_by_unexpected_collision = true
            break
