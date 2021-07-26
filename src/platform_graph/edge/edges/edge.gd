class_name Edge
extends EdgeAttempt
# Information for how to move from a start position to an end position.


# Whether the instructions for moving along this edge are updated according to
# traversal time (vs according to surface state).
var is_time_based: bool

var surface_type: int

# Whether the movement along this edge transitions from grabbing a surface to
# being airborne.
var enters_air: bool

var includes_air_trajectory: bool

var movement_params: MovementParams

# Whether this edge was created by the navigator for a specific path at
# run-time, rather than ahead of time when initially parsing the platform
# graph.
var is_optimized_for_path := false

var instructions: EdgeInstructions

var trajectory: EdgeTrajectory

var velocity_end := Vector2.INF

var time_peak_height := 0.0

# If true, then this edge starts and ends at the same position.
var is_degenerate: bool

# In pixels.
var distance: float
# In seconds.
var duration: float


func _init(
        edge_type: int,
        is_time_based: bool,
        surface_type: int,
        enters_air: bool,
        includes_air_trajectory: bool,
        calculator,
        start_position_along_surface: PositionAlongSurface,
        end_position_along_surface: PositionAlongSurface,
        velocity_start: Vector2,
        velocity_end: Vector2,
        includes_extra_jump_duration: bool,
        includes_extra_wall_land_horizontal_speed: bool,
        movement_params: MovementParams,
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
    self.includes_air_trajectory = includes_air_trajectory
    self.movement_params = movement_params
    self.velocity_end = velocity_end
    self.instructions = instructions
    self.trajectory = trajectory
    self.time_peak_height = time_peak_height
    
    assert(trajectory == null or \
            (!trajectory.frame_continuous_positions_from_steps.empty() or \
            !movement_params.includes_continuous_trajectory_positions))
    
    if start_position_along_surface != null:
        self.is_degenerate = Sc.geometry.are_points_equal_with_epsilon(
                start_position_along_surface.target_point,
                end_position_along_surface.target_point,
                0.00001)
        self.distance = _calculate_distance(
                start_position_along_surface,
                end_position_along_surface,
                trajectory)
        assert(!is_inf(distance))
        self.duration = _calculate_duration(
                start_position_along_surface,
                end_position_along_surface,
                instructions,
                distance)
        assert(!is_inf(duration))
        if self.instructions == null:
            self.instructions = _calculate_instructions(
                    start_position_along_surface,
                    end_position_along_surface,
                    duration)
        assert(!is_inf(self.instructions.duration))
    
    # -   Too few frames probably means that a collision was detected much
    #     earlier than expected.
    # -   Too many frames probably means ...
    var expected_frame_count_for_duration := \
            int(duration / Time.PHYSICS_TIME_STEP)
    var allowed_variance_from_expected_frame_count := 8
    assert(trajectory == null or \
            trajectory.frame_continuous_positions_from_steps.empty() or \
            (trajectory.frame_continuous_positions_from_steps.size() >= \
                    expected_frame_count_for_duration - 8 and \
            trajectory.frame_continuous_positions_from_steps.size() <= \
                    expected_frame_count_for_duration + 8))


func update_for_surface_state(
        surface_state: PlayerSurfaceState,
        is_final_edge: bool) -> void:
    # Do nothing unless the sub-class implements this.
    pass


func update_navigation_state(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback,
        just_started_new_edge: bool,
        is_starting_navigation_retry: bool) -> void:
    # When retrying navigation, we need to ignore whatever surface state in
    # the current frame led to the previous navigation being interrupted.
    if is_starting_navigation_retry:
        navigation_state.just_left_air_unexpectedly = false
        navigation_state.just_entered_air_unexpectedly = false
        navigation_state.just_interrupted_by_user_action = false
        navigation_state.just_interrupted_navigation = false
        navigation_state.just_reached_end_of_edge = false
        navigation_state.is_stalling_one_frame_before_reaching_end = false
        return
    
    var still_grabbing_start_surface_at_start := \
            just_started_new_edge and \
            surface_state.grabbed_surface == self.get_start_surface()
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == self.get_end_surface()
    navigation_state.just_left_air_unexpectedly = \
            surface_state.just_left_air and \
            !is_grabbed_surface_expected and \
            surface_state.collision_count > 0 and \
            !still_grabbing_start_surface_at_start
    
    navigation_state.just_entered_air_unexpectedly = \
            surface_state.just_entered_air and \
            !navigation_state.is_expecting_to_enter_air
    
    navigation_state.just_interrupted_by_user_action = \
            navigation_state.is_human_player and \
            UserActionSource.get_is_some_user_action_pressed()
    
    navigation_state.just_interrupted_navigation = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    if surface_state.just_entered_air:
        navigation_state.is_expecting_to_enter_air = false
    
    _update_navigation_state_expected_surface_air_helper(
            navigation_state,
            surface_state,
            is_starting_navigation_retry)
    
    navigation_state.just_interrupted_navigation = \
            navigation_state.just_left_air_unexpectedly or \
            navigation_state.just_entered_air_unexpectedly or \
            navigation_state.just_interrupted_by_user_action
    
    if movement_params.bypasses_runtime_physics:
        navigation_state.just_reached_end_of_edge = \
                navigation_state.is_stalling_one_frame_before_reaching_end
        navigation_state.is_stalling_one_frame_before_reaching_end = \
                !navigation_state.just_reached_end_of_edge and \
                _check_did_just_reach_destination(
                        navigation_state,
                        surface_state,
                        playback)
        _update_expected_position_along_surface(
                navigation_state,
                playback.get_elapsed_time_scaled())
    else:
        navigation_state.just_reached_end_of_edge = \
                _check_did_just_reach_destination(
                        navigation_state,
                        surface_state,
                        playback)


# This enables sub-classes to provide custom logic regarding how and when a
# surface collision may or may not be expected.
func _update_navigation_state_expected_surface_air_helper(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        is_starting_navigation_retry: bool) -> void:
    pass


func _calculate_distance(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        trajectory: EdgeTrajectory) -> float:
    Sc.logger.error("Abstract Edge._calculate_distance is not implemented")
    return INF


func _calculate_duration(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        instructions: EdgeInstructions,
        distance: float) -> float:
    Sc.logger.error("Abstract Edge._calculate_duration is not implemented")
    return INF


static func _calculate_instructions(
        start: PositionAlongSurface,
        end: PositionAlongSurface,
        duration: float) -> EdgeInstructions:
    Sc.logger.error("Abstract Edge._calculate_instructions is not implemented")
    return null


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
            includes_extra_wall_land_horizontal_speed)
    self.trajectory = edge_with_trajectory.trajectory


func get_position_at_time(edge_time: float) -> Vector2:
    var index := int(edge_time / Time.PHYSICS_TIME_STEP)
    if index >= trajectory.frame_continuous_positions_from_steps.size():
        return Vector2.INF
    return trajectory.frame_continuous_positions_from_steps[index]


func get_velocity_at_time(edge_time: float) -> Vector2:
    var index := int(edge_time / Time.PHYSICS_TIME_STEP)
    if index >= trajectory.frame_continuous_velocities_from_steps.size():
        return Vector2.INF
    return trajectory.frame_continuous_velocities_from_steps[index]


func get_animation_state_at_time(
        result: PlayerAnimationState,
        edge_time: float) -> void:
    Sc.logger.error(
            "Abstract Edge.get_animation_state_at_time is not implemented")


func _update_expected_position_along_surface(
        navigation_state: PlayerNavigationState,
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
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    if end_position_along_surface.surface == null:
        return _check_did_just_reach_in_air_destination(
                navigation_state,
                surface_state,
                playback)
    else:
        return _check_did_just_reach_surface_destination(
                navigation_state,
                surface_state,
                playback)


func _check_did_just_reach_surface_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    Sc.logger.error(
            "Abstract Edge._check_did_just_reach_surface_destination is not " +
            "implemented")
    return false


func _check_did_just_reach_in_air_destination(
        navigation_state: PlayerNavigationState,
        surface_state: PlayerSurfaceState,
        playback) -> bool:
    return surface_state.center_position.distance_squared_to(
            end_position_along_surface.target_point) < \
            movement_params \
                    .reached_in_air_destination_distance_squared_threshold


func get_weight() -> float:
    # Use either the distance or the duration as the weight for the edge.
    var weight := duration if \
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
        SurfaceType.AIR:
            return movement_params.air_edge_weight_multiplier
        _:
            Sc.logger.error()
            return INF


func _get_start_string() -> String:
    return start_position_along_surface.to_string()
func _get_end_string() -> String:
    return end_position_along_surface.to_string()


func get_name() -> String:
    return EdgeType.get_string(edge_type)


func get_should_end_by_colliding_with_surface() -> bool:
    return end_position_along_surface.surface != \
            start_position_along_surface.surface and \
            end_position_along_surface.surface != null


func to_string() -> String:
    var format_string_template := (
            "%s{ " +
            "start: %s, " +
            "end: %s, " +
            "velocity_start: %s, " +
            "velocity_end: %s, " +
            "distance: %s, " +
            "duration: %s, " +
            "is_optimized_for_path: %s, " +
            "instructions: %s " +
            "}")
    var format_string_arguments := [
            get_name(),
            _get_start_string(),
            _get_end_string(),
            str(velocity_start),
            str(velocity_end),
            distance,
            duration,
            is_optimized_for_path,
            instructions.to_string(),
        ]
    return format_string_template % format_string_arguments


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
        surface_state: PlayerSurfaceState,
        end_surface: Surface,
        playback) -> bool:
    if movement_params.bypasses_runtime_physics:
        return playback.get_elapsed_time_scaled() >= duration
    else:
        return surface_state.just_left_air and \
                surface_state.grabbed_surface == end_surface


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
    movement_params = Su.player_movement_params[json_object.pn]
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
    json_object.pn = movement_params.name
    json_object.io = is_optimized_for_path
    json_object.in = instructions.to_json_object()
    if trajectory != null and \
            movement_params.is_trajectory_state_stored_at_build_time and \
            !Su.ignores_platform_graph_save_file_trajectory_state:
        json_object.tr = trajectory.to_json_object()
    json_object.ve = Sc.json.encode_vector2(velocity_end)
    json_object.di = distance
    json_object.du = duration
