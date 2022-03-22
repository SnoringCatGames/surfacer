class_name Edge
extends EdgeAttempt
## -   Information for how to move from a start position to an end position.[br]
## -   This is an "edge" in the PlatformGraph.[br]
## -   Each edge endpoint, or "node", is a PositionAlongSurface.[br]


# Whether the instructions for moving along this edge are updated according to
# traversal time (vs according to surface state).
var is_time_based: bool

var surface_type: int

# Whether the movement along this edge transitions from grabbing a surface to
# being airborne.
var enters_air: bool

var movement_params: MovementParameters

# Whether this edge was created by the navigator for a specific path at
# run-time, rather than ahead of time when initially parsing the platform
# graph.
var is_optimized_for_path := false

var instructions: EdgeInstructions

var trajectory: EdgeTrajectory

var velocity_end := Vector2.INF

var time_peak_height := 0.0

# In pixels.
var distance: float
# In seconds.
var duration: float


func _init(
        edge_type: int,
        is_time_based: bool,
        surface_type: int,
        enters_air: bool,
        calculator,
        start_position_along_surface: PositionAlongSurface,
        end_position_along_surface: PositionAlongSurface,
        velocity_start: Vector2,
        velocity_end: Vector2,
        distance: float,
        duration: float,
        includes_extra_jump_duration: bool,
        includes_extra_wall_land_horizontal_speed: bool,
        movement_params: MovementParameters,
        instructions: EdgeInstructions,
        trajectory: EdgeTrajectory,
        edge_calc_result_type: int,
        time_peak_height: float
        ).(
        edge_type,
        edge_calc_result_type,
        start_position_along_surface,
        end_position_along_surface,
        velocity_start,
        includes_extra_jump_duration,
        includes_extra_wall_land_horizontal_speed,
        calculator \
        ) -> void:
    self.is_time_based = is_time_based
    self.surface_type = surface_type
    self.enters_air = enters_air
    self.movement_params = movement_params
    self.velocity_end = velocity_end
    self.distance = distance
    self.duration = duration
    self.instructions = instructions
    self.trajectory = trajectory
    self.time_peak_height = time_peak_height
    
    assert(trajectory == null or \
            (!trajectory.frame_continuous_positions_from_steps.empty() or \
            !movement_params.includes_continuous_trajectory_positions))
    
    if start_position_along_surface != null:
        assert(!is_inf(distance))
        assert(!is_inf(duration))
        assert(!is_inf(self.instructions.duration))
    
    # -   Too few frames probably means that a collision was detected much
    #     earlier than expected.
    # -   Too many frames probably means a bug in our calculations.
    var expected_frame_count_for_duration := \
            int(duration / ScaffolderTime.PHYSICS_TIME_STEP)
    assert(trajectory == null or \
            trajectory.frame_continuous_positions_from_steps.empty() or \
            (trajectory.frame_continuous_positions_from_steps.size() >= \
                    expected_frame_count_for_duration - 10 and \
            trajectory.frame_continuous_positions_from_steps.size() <= \
                    expected_frame_count_for_duration + 4))


func update_navigation_state(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        is_starting_navigation_retry: bool) -> void:
    # When retrying navigation, we need to ignore whatever surface state in
    # the current frame led to the previous navigation being interrupted.
    if is_starting_navigation_retry:
        navigation_state.just_left_air_unexpectedly = false
        navigation_state.just_entered_air_unexpectedly = false
        navigation_state.just_interrupted_by_unexpected_collision = false
        navigation_state.just_interrupted_by_player_action = false
        navigation_state.just_interrupted_by_being_stuck = false
        navigation_state.just_interrupted = false
        navigation_state.just_reached_end_of_edge = false
        navigation_state.is_stalling_one_frame_before_reaching_end = false
        return
    
    var just_started_new_edge := \
            navigation_state.edge_frame_count == 0
    
    var still_grabbing_start_surface_at_start := \
            just_started_new_edge and \
            _get_is_surface_start_or_collinear_neighbor(
                    surface_state.grabbed_surface)
    var is_grabbed_surface_expected: bool = \
            _get_is_surface_end_or_collinear_neighbor(
                    surface_state.grabbed_surface)
    navigation_state.just_left_air_unexpectedly = \
            surface_state.just_left_air and \
            !is_grabbed_surface_expected and \
            surface_state.contact_count > 0 and \
            !still_grabbing_start_surface_at_start
    
    navigation_state.just_entered_air_unexpectedly = \
            surface_state.just_entered_air and \
            !navigation_state.is_expecting_to_enter_air
    
    navigation_state.just_interrupted_by_player_action = \
            navigation_state.is_player_character and \
            PlayerActionSource.get_is_some_player_action_pressed()
    
    navigation_state.just_interrupted = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_unexpected_collision or \
            navigation_state.just_interrupted_by_player_action or \
            navigation_state.just_interrupted_by_being_stuck
    
    if surface_state.just_entered_air:
        navigation_state.is_expecting_to_enter_air = false
    
    _check_for_unexpected_collision(
            navigation_state,
            surface_state,
            is_starting_navigation_retry)
    
    _update_navigation_state_edge_specific_helper(
            navigation_state,
            surface_state,
            is_starting_navigation_retry)
    
    navigation_state.just_interrupted = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_unexpected_collision or \
            navigation_state.just_interrupted_by_player_action or \
            navigation_state.just_interrupted_by_being_stuck
    
    if movement_params.bypasses_runtime_physics:
        navigation_state.just_reached_end_of_edge = \
                navigation_state.is_stalling_one_frame_before_reaching_end
        navigation_state.is_stalling_one_frame_before_reaching_end = \
                !navigation_state.just_reached_end_of_edge and \
                _check_did_just_reach_destination(
                        navigation_state,
                        surface_state,
                        playback,
                        just_started_new_edge)
        _update_expected_position_along_surface(
                navigation_state,
                playback.get_elapsed_time_scaled())
    else:
        navigation_state.just_reached_end_of_edge = \
                _check_did_just_reach_destination(
                        navigation_state,
                        surface_state,
                        playback,
                        just_started_new_edge)


# This enables sub-classes to provide custom logic regarding how and when a
# surface collision may or may not be expected.
func _update_navigation_state_edge_specific_helper(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        is_starting_navigation_retry: bool) -> void:
    pass


func _check_for_unexpected_collision(
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
    
    var is_still_colliding_with_start_surface := \
            _get_is_surface_start_or_collinear_neighbor(
                surface_state.grabbed_surface)
    
    if is_still_colliding_with_start_surface:
        for contact_surface in surface_state.surfaces_to_contacts:
            if !_get_is_surface_expected_for_touch_contact(
                    contact_surface,
                    navigation_state):
                # Colliding with an unconnected surface.
                # Interrupted the edge.
                navigation_state \
                        .just_interrupted_by_unexpected_collision = true
                return
    
    if !_get_is_surface_expected_for_grab(
            surface_state.grabbed_surface,
            navigation_state):
        navigation_state.just_interrupted_by_unexpected_collision = true


func _get_is_surface_expected_for_touch_contact(
        contact_surface: Surface,
        navigation_state: CharacterNavigationState) -> bool:
    return _get_is_surface_start_end_or_collinear_neighbor(contact_surface) or \
            (navigation_state.edge_frame_count <= 1 and \
            (contact_surface == start_position_along_surface.surface \
                .clockwise_neighbor or \
            contact_surface == start_position_along_surface.surface \
                .counter_clockwise_neighbor))


func _get_is_surface_expected_for_grab(
        grabbed_surface: Surface,
        navigation_state: CharacterNavigationState) -> bool:
    return _get_is_surface_start_end_or_collinear_neighbor(grabbed_surface)


func _get_is_surface_start_or_collinear_neighbor(surface: Surface) -> bool:
    return surface == start_position_along_surface.surface or \
            (surface != null and \
            start_position_along_surface.surface != null and \
            (surface == start_position_along_surface.surface \
                .clockwise_collinear_neighbor or \
            surface == start_position_along_surface.surface \
                .counter_clockwise_collinear_neighbor))


func _get_is_surface_end_or_collinear_neighbor(surface: Surface) -> bool:
    return surface == end_position_along_surface.surface or \
            (surface != null and \
            end_position_along_surface.surface != null and \
            (surface == end_position_along_surface.surface \
                .clockwise_collinear_neighbor or \
            surface == end_position_along_surface.surface \
                .counter_clockwise_collinear_neighbor))


func _get_is_surface_start_end_or_collinear_neighbor(surface: Surface) -> bool:
    return surface == start_position_along_surface.surface or \
            surface == end_position_along_surface.surface or \
            (surface != null and \
            start_position_along_surface.surface != null and \
            end_position_along_surface.surface != null and \
            (surface == start_position_along_surface.surface \
                .clockwise_collinear_neighbor or \
            surface == start_position_along_surface.surface \
                .counter_clockwise_collinear_neighbor or \
            surface == end_position_along_surface.surface \
                .clockwise_collinear_neighbor or \
            surface == end_position_along_surface.surface \
                .counter_clockwise_collinear_neighbor))


# This should probably only be used during debugging. Otherwise, local memory
# usage could potentially grow quite large.
func populate_trajectory(collision_params: CollisionCalcParams) -> void:
    if trajectory != null or \
            calculator == null:
        return
    
    var edge_with_trajectory: Edge = calculator.calculate_edge(
            null,
            collision_params,
            start_position_along_surface,
            end_position_along_surface,
            velocity_start,
            includes_extra_jump_duration,
            includes_extra_wall_land_horizontal_speed,
            self)
    # FIXME: Remove this when it's no longer useful for debugging: ------------
#    if !is_instance_valid(edge_with_trajectory):
#        edge_with_trajectory = calculator.calculate_edge(
#                null,
#                collision_params,
#                start_position_along_surface,
#                end_position_along_surface,
#                velocity_start,
#                includes_extra_jump_duration,
#                includes_extra_wall_land_horizontal_speed,
#                self)
    self.trajectory = edge_with_trajectory.trajectory


func get_position_at_time(edge_time: float) -> Vector2:
    if is_instance_valid(trajectory):
        var index := int(edge_time / ScaffolderTime.PHYSICS_TIME_STEP)
        if index >= trajectory.frame_continuous_positions_from_steps.size():
            return end_position_along_surface.target_point
        return trajectory.frame_continuous_positions_from_steps[index]
    else:
        return start_position_along_surface.target_point


func get_velocity_at_time(edge_time: float) -> Vector2:
    if is_instance_valid(trajectory):
        var index := int(edge_time / ScaffolderTime.PHYSICS_TIME_STEP)
        if index >= trajectory.frame_continuous_velocities_from_steps.size():
            return _get_post_trajectory_velocity_for_triggering_grab()
        return trajectory.frame_continuous_velocities_from_steps[index]
    else:
        return velocity_start


func _get_post_trajectory_velocity_for_triggering_grab() -> Vector2:
    var velocity := velocity_end
    match end_position_along_surface.side:
        SurfaceSide.FLOOR:
            velocity.y = MovementParameters.STRONG_SPEED_TO_MAINTAIN_COLLISION
        SurfaceSide.LEFT_WALL:
            velocity.x = -MovementParameters.STRONG_SPEED_TO_MAINTAIN_COLLISION
        SurfaceSide.RIGHT_WALL:
            velocity.x = MovementParameters.STRONG_SPEED_TO_MAINTAIN_COLLISION
        SurfaceSide.CEILING:
            velocity.y = -MovementParameters.STRONG_SPEED_TO_MAINTAIN_COLLISION
        _:
            # Do nothing. Just use velocity_end.
            pass
    return velocity


func get_animation_state_at_time(
        result: SurfacerCharacterAnimationState,
        edge_time: float) -> void:
    Sc.logger.error(
            "Abstract Edge.get_animation_state_at_time is not implemented")


func sync_expected_surface_state(
        surface_state: CharacterSurfaceState,
        edge_time: float) -> void:
    var edge_frame_index := int(edge_time / ScaffolderTime.PHYSICS_TIME_STEP)
    var is_at_start_of_edge := edge_frame_index == 0
    var is_at_end_of_edge := \
            !is_instance_valid(trajectory) or \
            edge_frame_index >= \
                trajectory.frame_continuous_positions_from_steps.size() - 1
    
    if is_at_end_of_edge:
        _sync_expected_end_surface_state(surface_state)
    elif is_at_start_of_edge:
        _sync_expected_start_surface_state(surface_state)
    else:
        _sync_expected_middle_surface_state(surface_state, edge_time)


func _sync_expected_start_surface_state(
        surface_state: CharacterSurfaceState) -> void:
    var position := start_position_along_surface.target_point
    var velocity := velocity_start
    var surface := get_start_surface()
    var facing_left := \
            trajectory.frame_continuous_velocities_from_steps[0].x < 0.0 if \
            !trajectory.frame_continuous_velocities_from_steps.empty() else \
            (get_end() - get_start()).x < 0.0
    
    if is_instance_valid(surface):
        surface_state.sync_state_for_surface_grab(
                surface,
                position,
                false,
                facing_left)
    surface_state.center_position = position
    surface_state.velocity = velocity


func _sync_expected_end_surface_state(
        surface_state: CharacterSurfaceState) -> void:
    var position := end_position_along_surface.target_point
    var velocity := velocity_end
    var surface := get_end_surface()
    var facing_left := \
            trajectory.frame_continuous_velocities_from_steps[
                trajectory.frame_continuous_velocities_from_steps \
                    .size() - 1].x < 0.0 if \
            !trajectory.frame_continuous_velocities_from_steps.empty() else \
            (get_end() - get_start()).x < 0.0
    
    if is_instance_valid(surface):
        surface_state.sync_state_for_surface_grab(
                surface,
                position,
                enters_air,
                facing_left)
    surface_state.center_position = position
    surface_state.velocity = velocity


func _sync_expected_middle_surface_state(
        surface_state: CharacterSurfaceState,
        edge_time: float) -> void:
    assert(enters_air or \
            surface_type == SurfaceType.AIR,
            "Surface-bound edges must override " +
            "_sync_expected_middle_surface_state")
    
    var edge_frame_index := int(edge_time / ScaffolderTime.PHYSICS_TIME_STEP)
    var did_just_release := edge_frame_index == 1
    var position := get_position_at_time(edge_time)
    var velocity := get_velocity_at_time(edge_time)
    
    surface_state.clear_current_state()
    surface_state.center_position = position
    surface_state.velocity = velocity
    
    if did_just_release:
        var start_surface := get_start_surface()
        if is_instance_valid(start_surface):
            surface_state.sync_state_for_surface_release(
                    start_surface,
                    position)


func _update_expected_position_along_surface(
        navigation_state: CharacterNavigationState,
        edge_time: float) -> void:
    var position := navigation_state.expected_position_along_surface
    position.surface = \
            get_end_surface() if \
            navigation_state.is_stalling_one_frame_before_reaching_end or \
                    !enters_air else \
            null
    position.target_point = get_position_at_time(edge_time)
    if position.surface != null:
        position.update_target_projection_onto_surface()
    else:
        position.target_projection_onto_surface = Vector2.INF


func _check_did_just_reach_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    if end_position_along_surface.surface == null:
        return _check_did_just_reach_in_air_destination(
                navigation_state,
                surface_state,
                playback,
                just_started_new_edge)
    else:
        return _check_did_just_reach_surface_destination(
                navigation_state,
                surface_state,
                playback,
                just_started_new_edge)


func _check_did_just_reach_surface_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    Sc.logger.error(
            "Abstract Edge._check_did_just_reach_surface_destination is not " +
            "implemented")
    return false


func _check_did_just_reach_in_air_destination(
        navigation_state: CharacterNavigationState,
        surface_state: CharacterSurfaceState,
        playback,
        just_started_new_edge: bool) -> bool:
    return surface_state.center_position.distance_squared_to(
            end_position_along_surface.target_point) < \
            movement_params \
                    .reached_in_air_destination_distance_squared_threshold


func get_weight() -> float:
    # Use either the distance or the duration as the weight for the edge.
    var weight := \
            duration if \
            movement_params \
                    .uses_duration_instead_of_distance_for_edge_weight else \
            distance
    
    # Apply a multiplier to the weight according to the type of edge.
    weight *= _get_weight_multiplier()
    
    # Give a constant extra weight for each additional edge in a path.
    weight += movement_params.additional_edge_weight_offset
    
    return weight


func _get_weight_multiplier() -> float:
    match surface_type:
        SurfaceType.FLOOR:
            return movement_params.walking_edge_weight_multiplier
        SurfaceType.WALL:
            return movement_params.climbing_edge_weight_multiplier
        SurfaceType.CEILING:
            return movement_params.ceiling_crawling_edge_weight_multiplier
        SurfaceType.AIR:
            return movement_params.air_edge_weight_multiplier
        _:
            Sc.logger.error("Edge._get_weight_multiplier")
            return INF


func _get_start_string(verbose := true) -> String:
    return start_position_along_surface.to_string(verbose)
func _get_end_string(verbose := true) -> String:
    return end_position_along_surface.to_string(verbose)


func get_name(verbose := true) -> String:
    return EdgeType.get_string(edge_type) if \
            verbose else \
            EdgeType.get_prefix(edge_type)


func get_should_end_by_colliding_with_surface() -> bool:
    return end_position_along_surface.surface != \
            start_position_along_surface.surface and \
            end_position_along_surface.surface != null


func to_string(verbose := true) -> String:
    if verbose:
        return (
            "%s{ " +
            "start: %s, " +
            "end: %s, " +
            "velocity_start: %s, " +
            "velocity_end: %s, " +
            "distance: %s, " +
            "duration: %s, " +
            "is_optimized_for_path: %s, " +
            "instructions: %s " +
            "}"
        ) % [
            get_name(verbose),
            _get_start_string(verbose),
            _get_end_string(verbose),
            str(velocity_start),
            str(velocity_end),
            distance,
            duration,
            is_optimized_for_path,
            instructions.to_string(),
        ]
    else:
        return (
            "%s{ p0: %s, p1: %s }"
        ) % [
            get_name(verbose),
            _get_start_string(verbose),
            _get_end_string(verbose),
        ]


func to_string_with_newlines(indent_level: int) -> String:
    var indent_level_str := ""
    for i in indent_level:
        indent_level_str += "\t"
    
    var format_string_template := ("%s{" +
            "\n\t%sstart: %s," +
            "\n\t%send: %s," +
            "\n\t%svelocity_start: %s," +
            "\n\t%svelocity_end: %s," +
            "\n\t%sdistance: %s," +
            "\n\t%sduration: %s," +
            "\n\t%sis_optimized_for_path: %s," +
            "\n\t%sinstructions: %s," +
        "\n%s}")
    var format_string_arguments := [
            get_name(),
            indent_level_str,
            _get_start_string(),
            indent_level_str,
            _get_end_string(),
            indent_level_str,
            str(velocity_start),
            indent_level_str,
            str(velocity_end),
            indent_level_str,
            distance,
            indent_level_str,
            duration,
            indent_level_str,
            is_optimized_for_path,
            indent_level_str,
            instructions.to_string_with_newlines(indent_level + 1),
            indent_level_str,
        ]
    
    return format_string_template % format_string_arguments


# This creates a PositionAlongSurface object with the given target point and a
# null Surface.
static func vector2_to_position_along_surface(target_point: Vector2) -> \
        PositionAlongSurface:
    var position_along_surface := PositionAlongSurface.new()
    position_along_surface.target_point = target_point
    return position_along_surface


func check_just_landed_on_expected_surface(
        surface_state: CharacterSurfaceState,
        end_surface: Surface,
        playback) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    else:
        return surface_state.just_left_air and \
                (surface_state.grabbed_surface == end_surface or \
                surface_state.grabbed_surface == \
                    end_surface.clockwise_collinear_neighbor or \
                surface_state.grabbed_surface == \
                    end_surface.counter_clockwise_collinear_neighbor)


func load_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    _load_edge_state_from_json_object(json_object, context)


func to_json_object() -> Dictionary:
    var json_object := {}
    _edge_state_to_json_object(json_object)
    return json_object


func _load_edge_state_from_json_object(
        json_object: Dictionary,
        context: Dictionary) -> void:
    _load_edge_attempt_state_from_json_object(json_object, context)
    movement_params = Su.movement.character_movement_params[json_object.pn]
    is_optimized_for_path = json_object.io
    instructions = EdgeInstructions.new()
    instructions.load_from_json_object(json_object.in, context)
    if json_object.has("tr") and \
            !Su.ignores_platform_graph_save_file_trajectory_state:
        trajectory = EdgeTrajectory.new()
        trajectory.load_from_json_object(json_object.tr, context)
    velocity_end = Sc.json.decode_vector2(json_object.ve)
    distance = json_object.di
    duration = json_object.du


func _edge_state_to_json_object(json_object: Dictionary) -> void:
    _edge_attempt_state_to_json_object(json_object)
    json_object.pn = movement_params.character_category_name
    json_object.io = is_optimized_for_path
    json_object.in = instructions.to_json_object()
    if trajectory != null and \
            movement_params.is_trajectory_state_stored_at_build_time and \
            !Su.ignores_platform_graph_save_file_trajectory_state:
        json_object.tr = trajectory.to_json_object()
    json_object.ve = Sc.json.encode_vector2(velocity_end)
    json_object.di = distance
    json_object.du = duration
