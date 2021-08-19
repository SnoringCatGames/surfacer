class_name SurfaceNavigator
extends Reference
## Logic for navigating a character along a path of edges through a platform
## graph to a destination position.


signal navigation_started(is_retry)
signal destination_reached
signal navigation_interrupted(is_retrying)
signal navigation_canceled
signal navigation_ended(did_reach_destination)

const PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET := 1.0
const PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET := 1.0

var character: ScaffolderCharacter
var graph: PlatformGraph
var surface_state: CharacterSurfaceState
var movement_params: MovementParameters
var instructions_action_source: InstructionsActionSource
var from_air_calculator: FromAirCalculator
var surface_to_air_calculator: JumpFromSurfaceCalculator

var path: PlatformGraphPath
var previous_path: PlatformGraphPath

var path_start_time_scaled := INF
var previous_path_start_time_scaled := INF

var path_beats: Array
var previous_path_beats: Array

var edge: Edge
var edge_index := -1
var playback: InstructionsPlayback
var actions_might_be_dirty := false
var current_navigation_attempt_count := 0

var navigation_state := CharacterNavigationState.new()


func _init(
        character,
        graph: PlatformGraph) -> void:
    self.character = character
    self.graph = graph
    self.surface_state = character.surface_state
    self.movement_params = character.movement_params
    self.navigation_state.is_player_character = character.is_player_character
    self.instructions_action_source = \
            InstructionsActionSource.new(character, true)
    self.from_air_calculator = FromAirCalculator.new()
    self.surface_to_air_calculator = JumpFromSurfaceCalculator.new()


func navigate_path(
        path: PlatformGraphPath,
        is_retry := false) -> bool:
    Sc.profiler.start("navigator_navigate_path")
    
    var previous_navigation_attempt_count := current_navigation_attempt_count
    _reset()
    if is_retry:
        current_navigation_attempt_count = previous_navigation_attempt_count
    
    if path != null and \
            !Sc.geometry.are_points_equal_with_epsilon(
                    character.position,
                    path.origin.target_point,
                    4.0):
        # The selection and its path are stale, so update the path to match the
        # character's current position.
        path = find_path(
                path.destination,
                false,
                path.graph_destination_for_in_air_destination)
    
    if path == null:
        # Destination cannot be reached from origin.
        Sc.profiler.stop("navigator_navigate_path")
        _log("Cannot navigate null path: %s; from=%s" % [
                    character.character_name,
                    Sc.utils.get_vector_string(character.position),
                ],
                false)
        return false
    
    # Destination can be reached from origin.
    
    _interleave_intra_surface_edges(
            graph.collision_params,
            path)
    
    _optimize_edges_for_approach(
            graph.collision_params,
            path,
            character.velocity)
    
    _ensure_edges_have_trajectory_state(
            graph.collision_params,
            path)
    
    self.path = path
    self.path_start_time_scaled = Sc.time.get_scaled_play_time()
    self.path_beats = Sc.beats.calculate_path_beat_hashes_for_current_mode(
            path, path_start_time_scaled)
    navigation_state.is_currently_navigating = true
    navigation_state.has_reached_destination = false
    current_navigation_attempt_count += 1
    
    var duration_navigate_to_position: float = \
            Sc.profiler.stop("navigator_navigate_path")
    
    _log("Path start:          %8.3fs; %s; to=%s; from=%s; edges=%d" % [
                Sc.time.get_play_time(),
                character.character_name,
                Sc.utils.get_vector_string(
                        path.destination.target_point, 0),
                Sc.utils.get_vector_string(path.origin.target_point, 0),
                path.edges.size(),
            ],
            false)
    if character.logs_low_level_navigator_events:
        var format_string_template := (
                "{" +
                "\n\tdestination: %s," +
                "\n\tpath: %s," +
                "\n\ttimings: {" +
                "\n\t\tduration_navigate_to_position: %sms" +
                "\n\t}" +
                "\n}")
        var format_string_arguments := [
            path.destination.to_string(),
            path.to_string_with_newlines(1),
            duration_navigate_to_position,
        ]
        _log(format_string_template % format_string_arguments, true)
    
    _start_edge(
            0,
            is_retry)
    
    emit_signal("navigation_started", is_retry)
    
    return true


# Starts a new navigation to the given destination.
func navigate_to_position(
        destination: PositionAlongSurface,
        only_includes_bidirectional_edges := false,
        graph_destination_for_in_air_destination: PositionAlongSurface = null,
        is_retry := false) -> bool:
    var path := find_path(
            destination,
            only_includes_bidirectional_edges,
            graph_destination_for_in_air_destination)
    return navigate_path(path, is_retry)


func find_path(
        destination: PositionAlongSurface,
        only_includes_bidirectional_edges := false,
        graph_destination_for_in_air_destination: PositionAlongSurface = \
                null) -> PlatformGraphPath:
    Sc.profiler.start("navigator_find_path")
    
    # Nudge the destination away from any concave neighbor surfaces, if
    # necessary.
    destination = PositionAlongSurface.new(destination)
    JumpLandPositionsUtils \
            .ensure_position_is_not_too_close_to_concave_neighbor(
                    movement_params,
                    destination)
    
    if graph_destination_for_in_air_destination != null:    
        # Nudge the graph-destination away from any concave neighbor surfaces,
        # if necessary.
        graph_destination_for_in_air_destination = PositionAlongSurface.new(
                graph_destination_for_in_air_destination)
        JumpLandPositionsUtils \
                .ensure_position_is_not_too_close_to_concave_neighbor(
                        movement_params,
                        graph_destination_for_in_air_destination)
    
    var graph_origin: PositionAlongSurface
    var prefix_edge: FromAirEdge
    var suffix_edge: JumpFromSurfaceEdge
    
    # Handle the start of the path.
    if surface_state.is_grabbing_a_surface:
        # Find a path from a starting character-position along a surface.
        graph_origin = PositionAlongSurface.new(
                surface_state.center_position_along_surface)
    else:
        # Find a path from a starting character-position in the air.
        
        # Try to dynamically calculate a valid air-to-surface edge from the
        # current in-air position.
        var origin := PositionAlongSurfaceFactory \
                .create_position_without_surface(surface_state.center_position)
        var from_air_edge := \
                from_air_calculator.find_a_landing_trajectory(
                        null,
                        graph.collision_params,
                        graph.surfaces_set,
                        origin,
                        character.velocity,
                        destination,
                        null)
        
        if from_air_edge == null and \
                navigation_state.is_currently_navigating and \
                edge.get_end_surface() != null:
            # We weren't able to dynamically calculate a valid air-to-surface
            # edge from the current in-air position, but the character was
            # already navigating along a valid edge to a surface, so let's just
            # re-use the remainder of that edge.
            
            # TODO: This case shouldn't be needed; in theory, we should have
            #       been able to find a valid land trajectory above.
            Sc.logger.warning("Unable to calculate air-to-surface edge")
            
            var elapsed_edge_time := playback.get_elapsed_time_scaled()
            if elapsed_edge_time < edge.duration:
                from_air_edge = from_air_calculator \
                        .create_edge_from_part_of_other_edge(
                                edge,
                                elapsed_edge_time,
                                character)
            else:
                Sc.logger.warning(
                        "Unable to re-use current edge as air-to-surface " +
                        "edge: edge playback time exceeds edge duration")
        
        if from_air_edge != null:
            # We were able to calculate a valid air-to-surface edge.
            graph_origin = from_air_edge.end_position_along_surface
            prefix_edge = from_air_edge
        else:
            Sc.profiler.stop("navigator_find_path")
            return null
    
    # Handle the end of the path.
    if destination.surface != null:
        # Find a path to an ending character-position along a surface.
        graph_destination_for_in_air_destination = destination
    else:
        # Find a path to an ending character-position in the air.
        
        assert(graph_destination_for_in_air_destination != null)
        
        # Try to dynamically calculate a valid surface-to-air edge.
        var surface_to_air_edge := _calculate_surface_to_air_edge(
                graph_destination_for_in_air_destination,
                destination)
        
        if surface_to_air_edge != null:
            # We were able to calculate a valid surface-to-air edge.
            suffix_edge = surface_to_air_edge
        else:
            Sc.logger.warning("Unable to calculate surface-to-air edge")
            Sc.profiler.stop("navigator_find_path")
            return null
    
    var path := graph.find_path(
            graph_origin,
            graph_destination_for_in_air_destination,
            only_includes_bidirectional_edges)
    if path != null:
        path.graph_destination_for_in_air_destination = \
                graph_destination_for_in_air_destination
        if prefix_edge != null:
            path.push_front(prefix_edge)
        if suffix_edge != null:
            path.push_back(suffix_edge)
    
    Sc.profiler.stop("navigator_find_path")
    
    if path != null:
        if movement_params.also_optimizes_preselection_path:
            _optimize_edges_for_approach(
                    graph.collision_params,
                    path,
                    character.velocity)
        
        _ensure_edges_have_trajectory_state(
                graph.collision_params,
                path)
    
    return path


func _calculate_surface_to_air_edge(
        start: PositionAlongSurface,
        end: PositionAlongSurface) -> JumpFromSurfaceEdge:
    var velocity_start := JumpLandPositionsUtils.get_velocity_start(
            movement_params,
            start.surface,
            surface_to_air_calculator.is_a_jump_calculator,
            false,
            true)
    return surface_to_air_calculator.calculate_edge(
            null,
            graph.collision_params,
            start,
            end,
            velocity_start,
            false,
            false) as JumpFromSurfaceEdge


func stop() -> void:
    var was_navigating := navigation_state.is_currently_navigating
    var had_canceled := navigation_state.has_canceled
    var had_just_canceled := navigation_state.just_canceled
    var had_just_ended := navigation_state.just_ended
    
    _reset()
    
    if was_navigating:
        navigation_state.has_canceled = true
        navigation_state.just_canceled = true
        navigation_state.just_ended = true
        
        emit_signal("navigation_canceled")
        emit_signal("navigation_ended", false)
    else:
        # Preserve pre-existing state.
        navigation_state.has_canceled = had_canceled
        navigation_state.just_canceled = had_just_canceled
        navigation_state.just_ended = had_just_ended


func _set_reached_destination() -> void:
    if movement_params.forces_character_position_to_match_path_at_end:
        character.set_position(edge.get_end())
    if movement_params.forces_character_velocity_to_zero_at_path_end and \
            edge.get_end_surface() != null:
        match edge.get_end_surface().side:
            SurfaceSide.FLOOR, SurfaceSide.CEILING:
                character.velocity.x = 0.0
            SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                character.velocity.y = 0.0
            _:
                Sc.logger.error("Invalid SurfaceSide")
    
    _log("Path end:            %8.3fs; %s; to=%s; from=%s; edges=%d" % [
                Sc.time.get_play_time(),
                character.character_name,
                Sc.utils.get_vector_string(path.destination.target_point, 0),
                Sc.utils.get_vector_string(path.origin.target_point, 0),
                path.edges.size(),
            ],
            false)
    
    _reset()
    navigation_state.has_reached_destination = true
    navigation_state.just_reached_destination = true
    navigation_state.just_ended = true
    
    emit_signal("destination_reached")
    emit_signal("navigation_ended", true)


func _reset() -> void:
    if path != null:
        previous_path = path
        previous_path_start_time_scaled = path_start_time_scaled
        previous_path_beats = path_beats
    
    path = null
    path_start_time_scaled = INF
    path_beats = []
    edge = null
    edge_index = -1
    playback = null
    instructions_action_source.cancel_all_playback()
    actions_might_be_dirty = true
    current_navigation_attempt_count = 0
    navigation_state.reset()


func _start_edge(
        index: int,
        is_starting_navigation_retry := false) -> void:
    Sc.profiler.start("navigator_start_edge")
    
    edge_index = index
    edge = path.edges[index]
    
    if movement_params.forces_character_position_to_match_edge_at_start:
        character.set_position(edge.get_start())
    if movement_params.forces_character_velocity_to_match_edge_at_start:
        character.velocity = edge.velocity_start
        surface_state.horizontal_acceleration_sign = 0
    
    edge.update_for_surface_state(
            surface_state,
            edge == path.edges.back())
    navigation_state.is_expecting_to_enter_air = edge.enters_air
    
    playback = instructions_action_source.start_instructions(
            edge,
            Sc.time.get_scaled_play_time())
    
    var duration_start_edge: float = \
            Sc.profiler.stop("navigator_start_edge")
    
    if character.logs_low_level_navigator_events:
        var format_string_template := \
                "Starting edge nav:   %8.3fs; %s; %s; calc duration=%sms"
        var format_string_arguments := [
                Sc.time.get_play_time(),
                character.character_name,
                edge.to_string_with_newlines(0),
                str(duration_start_edge),
            ]
        _log(format_string_template % format_string_arguments, true)
    
    # Some instructions could be immediately skipped, depending on runtime
    # state, so this gives us a chance to move straight to the next edge.
    _update(
            true,
            is_starting_navigation_retry)


func _update(
        just_started_new_edge := false,
        is_starting_navigation_retry := false) -> void:
    if !navigation_state.is_currently_navigating:
        navigation_state.just_ended = false
        navigation_state.just_reached_destination = false
        navigation_state.just_canceled = false
        navigation_state.just_interrupted = false
        navigation_state.just_left_air_unexpectedly = false
        navigation_state.just_entered_air_unexpectedly = false
        navigation_state.just_interrupted_by_unexpected_collision = false
        navigation_state.just_interrupted_by_player_action = false
        navigation_state.just_reached_end_of_edge = false
        return
    
    actions_might_be_dirty = just_started_new_edge
    
    # FIXME: ------ This can result in character's getting stuck in mid-air in a
    #        continuous, new-nav-every-frame loop.
#    if !character.surface_state.did_move_last_frame and \
#            !just_started_navigating:
#        # FIXME: ------------
#        # - This work-around shouldn't be needed. What's the underlying
#        #   problem?
#        Sc.logger.warning(
#                "SurfaceNavigator.is_currently_navigating and " +
#                "!CharacterSurfaceState.did_move_last_frame")
#        var destination := path.destination
#        var graph_destination_for_in_air_destination := \
#                path.graph_destination_for_in_air_destination
#        stop()
#        navigate_to_position(
#                destination,
#                graph_destination_for_in_air_destination)
#        return
    
    edge.update_navigation_state(
            navigation_state,
            surface_state,
            playback,
            just_started_new_edge,
            is_starting_navigation_retry)
    
    if navigation_state.just_interrupted:
        navigation_state.has_interrupted = true
        
        var interruption_type_label: String
        if navigation_state.just_left_air_unexpectedly:
            interruption_type_label = "just_left_air_unexpectedly"
        elif navigation_state.just_entered_air_unexpectedly:
            interruption_type_label = "just_entered_air_unexpectedly"
        elif navigation_state.just_interrupted_by_unexpected_collision:
            interruption_type_label = \
                    "just_interrupted_by_unexpected_collision"
        else: # navigation_state.just_interrupted_by_player_action
            interruption_type_label = "just_interrupted_by_player_action"
        
        _log("Edge interrupted:    %8.3fs; %s; %s; to=%s; from=%s" % [
                    Sc.time.get_play_time(),
                    character.character_name,
                    interruption_type_label,
                    Sc.utils.get_vector_string(path.destination.target_point),
                    Sc.utils.get_vector_string(path.origin.target_point),
                ],
                false)
        
        # FIXME: ---- Think of how to handle interruptions differently...
        
        var is_retrying := movement_params.retries_navigation_when_interrupted
        
        if is_retrying:
            navigate_to_position(
                    path.destination,
                    false,
                    path.graph_destination_for_in_air_destination,
                    true)
        
        emit_signal("navigation_interrupted", is_retrying)
        if !is_retrying:
            _reset()
            navigation_state.has_interrupted = true
            navigation_state.just_interrupted = true
            navigation_state.just_ended = true
            emit_signal("navigation_ended", false)
        
        return
        
    elif navigation_state.just_reached_end_of_edge:
        if character.logs_low_level_navigator_events:
            _log("Edge end:            %8.3fs; %s; %s" % [
                Sc.time.get_play_time(),
                character.character_name,
                edge.get_name(),
            ], true)
    else:
        # Continuing along an edge.
        if surface_state.is_grabbing_a_surface:
            pass
        else:
            # TODO: Detect when position is too far from expected. Then maybe
            #       auto-correct it?
            pass
    
    if navigation_state.just_reached_end_of_edge:
        # Cancel the current intra-surface instructions (in case it didn't
        # clear itself).
        instructions_action_source.cancel_playback(
                playback,
                Sc.time.get_scaled_play_time())
        playback = null
        
        # Check for the next edge to navigate.
        var next_edge_index := edge_index + 1
        var was_last_edge := path.edges.size() == next_edge_index
        if was_last_edge:
            var backtracking_edge := \
                    _possibly_backtrack_to_not_protrude_past_surface_end(
                            movement_params,
                            edge,
                            character.position,
                            character.velocity)
            if backtracking_edge == null:
                _set_reached_destination()
            else:
                if character.logs_low_level_navigator_events:
                    var format_string_template := \
                            "Insrt ctr-potr edge:%8.3fs; %s; %s"
                    var format_string_arguments := [
                            Sc.time.get_play_time(),
                            character.character_name,
                            backtracking_edge.to_string_with_newlines(0),
                        ]
                    _log(format_string_template % format_string_arguments,
                            true)
                
                path.edges.push_back(backtracking_edge)
                
                _start_edge(next_edge_index)
        else:
            _start_edge(next_edge_index)


func predict_animation_state(
        result: CharacterAnimationState,
        elapsed_time_from_now: float) -> bool:
    if !navigation_state.is_currently_navigating:
        character.get_current_animation_state(result)
        
        var confidence_progress := min(
                elapsed_time_from_now / \
                CharacterAnimationState.POST_PATH_DURATION_TO_MIN_CONFIDENCE,
                1.0)
        result.confidence_multiplier = lerp(
                1.0,
                0.0,
                confidence_progress)
        
        return false
    
    var current_path_elapsed_time: float = \
            Sc.time.get_scaled_play_time() - \
            path_start_time_scaled
    var prediction_path_time := \
            current_path_elapsed_time + elapsed_time_from_now
    
    return path.predict_animation_state(result, prediction_path_time)


func get_destination() -> PositionAlongSurface:
    return path.destination if \
            path != null else \
            null


func get_previous_destination() -> PositionAlongSurface:
    return previous_path.destination if \
            previous_path != null else \
            null


# Conditionally prints the given message, depending on the SurfacerCharacter's
# configuration.
func _log(
        message: String,
        is_low_level_framework_event = false) -> void:
    character._log(
            message,
            CharacterLogType.NAVIGATOR,
            is_low_level_framework_event)


static func _possibly_backtrack_to_not_protrude_past_surface_end(
        movement_params: MovementParameters,
        edge: Edge,
        position: Vector2,
        velocity: Vector2) -> IntraSurfaceEdge:
    var surface := edge.get_end_surface()
    
    if surface == null or \
            !movement_params \
            .prevents_path_ends_from_exceeding_surface_ends_with_offsets or \
            edge.is_backtracking_to_not_protrude_past_surface_end:
        return null
    
    var position_after_coming_to_a_stop: Vector2
    if surface.side == SurfaceSide.FLOOR:
        var stopping_distance := \
                MovementUtils.calculate_distance_to_stop_from_friction(
                        movement_params,
                        abs(velocity.x),
                        movement_params.gravity_fast_fall,
                        movement_params.friction_coefficient)
        var stopping_displacement := \
                stopping_distance if \
                velocity.x > 0.0 else \
                -stopping_distance
        position_after_coming_to_a_stop = Vector2(
                position.x + stopping_displacement,
                position.y)
    else:
        # TODO: Add support for acceleration and friction along wall and
        #       ceiling surfaces.
        position_after_coming_to_a_stop = position
    
    var would_protrude_past_surface_end_after_coming_to_a_stop := false
    var end_target_point := Vector2.INF
    
    match surface.side:
        SurfaceSide.FLOOR:
            if position_after_coming_to_a_stop.x < \
                    surface.first_point.x + \
                    PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.first_point.x + \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.first_point.y)
            elif position_after_coming_to_a_stop.x > \
                    surface.last_point.x - \
                    PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.last_point.x - \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.last_point.y)
        SurfaceSide.LEFT_WALL:
            if position_after_coming_to_a_stop.y < \
                    surface.first_point.y + \
                    PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.first_point.x,
                                surface.first_point.y + \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
            elif position_after_coming_to_a_stop.y > \
                    surface.last_point.y - \
                    PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.last_point.x,
                                surface.last_point.y - \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
        SurfaceSide.RIGHT_WALL:
            if position_after_coming_to_a_stop.y > \
                    surface.first_point.y - \
                    PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.first_point.x,
                                surface.first_point.y - \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
            elif position_after_coming_to_a_stop.y < \
                    surface.last_point.y + \
                    PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.last_point.x,
                                surface.last_point.y + \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
        SurfaceSide.CEILING:
            if position_after_coming_to_a_stop.x > \
                    surface.first_point.x - \
                    PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.first_point.x - \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.first_point.y)
            elif position_after_coming_to_a_stop.x < \
                    surface.last_point.x + \
                    PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                would_protrude_past_surface_end_after_coming_to_a_stop = \
                        true
                end_target_point = \
                        Vector2(surface.last_point.x + \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.last_point.y)
        _:
            Sc.logger.error("Invalid SurfaceSide")
    
    if !would_protrude_past_surface_end_after_coming_to_a_stop:
        return null
    
    var start_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    position,
                    surface,
                    movement_params.collider_half_width_height,
                    true)
    var end_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    end_target_point,
                    surface,
                    movement_params.collider_half_width_height,
                    true)
    var backtracking_edge := IntraSurfaceEdge.new(
            start_position,
            end_position,
            velocity,
            movement_params)
    backtracking_edge.is_backtracking_to_not_protrude_past_surface_end = true
    return backtracking_edge


# Tries to update each jump edge to jump from the earliest point possible along
# the surface rather than from the safe end/closest point that was used at
# build-time when calculating possible edges.
# -   This also updates start velocity when updating start position.
func _optimize_edges_for_approach(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        velocity_start: Vector2) -> void:
    if path.is_optimized:
        # Already optimized.
        return
    
    Sc.profiler.start("navigator_optimize_edges_for_approach")
    
    var movement_params := collision_params.movement_params
    
    # -   At runtime, after finding a path through build-time-calculated edges,
    #     try to optimize the jump-off or land points of the edges to better
    #     account for the direction that the character will be approaching the
    #     edge from.
    # -   This produces more efficient and natural movement.
    # -   The build-time-calculated edge state would only use surface
    #     end-points or closest points.
    # -   We also take this opportunity to update start velocities to exactly
    #     match what is allowed from the ramp-up distance along the edge,
    #     rather than either the fixed zero or max-speed value used for the
    #     build-time-calculated edge state.
    
    if movement_params.optimizes_edge_jump_positions_at_run_time and \
            path.destination.surface == null:
        # Optimize jump-off point to reach in-air destination.
        
        var index_of_earliest_possible_edge_to_replace := max(0,
                path.edges.size() - 1 - movement_params \
                        .max_edges_to_remove_from_path_for_opt_to_in_air_dest)
        for i in range(
                index_of_earliest_possible_edge_to_replace, path.edges.size()):
            var edge: Edge = path.edges[i]
            
            # We can only alter the end position of IntraSurfaceEdges.
            if !(edge is IntraSurfaceEdge):
                continue
            
            var jump_off_surface: Surface = edge.get_start_surface()
            var closest_jump_off_point := PositionAlongSurface.new()
            closest_jump_off_point.match_surface_target_and_collider(
                    jump_off_surface,
                    path.destination.target_point,
                    movement_params.collider_half_width_height,
                    true,
                    true)
            
            var surface_to_air_edge := _calculate_surface_to_air_edge(
                    closest_jump_off_point, path.destination)
            if surface_to_air_edge == null:
                continue
            
            # We found an earlier position along an IntraSurfaceEdge that we
            # can jump from.
            # -   Update the end position of the IntraSurfaceEdge.
            # -   Record the new surface-to-air edge.
            # -   Remove the old following edges.
            edge.update_terminal(
                    false,
                    closest_jump_off_point.target_point)
            path.edges.resize(i + 2)
            path.edges[i + 1] = surface_to_air_edge
            path.graph_destination_for_in_air_destination = \
                    closest_jump_off_point
            break
    
    if movement_params.optimizes_edge_jump_positions_at_run_time:
        # Optimize jump positions.
        
        var previous_velocity_end_x := velocity_start.x
        
        for i in range(1, path.edges.size()):
            var previous_edge: Edge = path.edges[i - 1]
            var current_edge: Edge = path.edges[i]
            
            # We shouldn't have two intra-surface edges in a row.
            assert(!(previous_edge is IntraSurfaceEdge) or \
                    !(current_edge is IntraSurfaceEdge))
            
            var is_previous_edge_long_enough_to_be_worth_optimizing_jump_position := \
                    previous_edge.distance >= \
                    movement_params \
                            .min_intra_surface_distance_to_optimize_jump_for
            
            if is_previous_edge_long_enough_to_be_worth_optimizing_jump_position and \
                    previous_edge is IntraSurfaceEdge:
                current_edge.calculator.optimize_edge_jump_position_for_path(
                        collision_params,
                        path,
                        i,
                        previous_velocity_end_x,
                        previous_edge,
                        current_edge)
            
            previous_velocity_end_x = previous_edge.velocity_end.x
        
        # If we optimized the second edge, so that it can start from the same
        # position that the first, intra-surface, edge starts, then we can just
        # remove the first, intra-surface, edge.
        if path.edges.size() > 1 and \
                path.edges[0] is IntraSurfaceEdge and \
                Sc.geometry.are_points_equal_with_epsilon(
                        path.edges[0].get_start(),
                        path.edges[1].get_start(),
                        1.0):
            path.edges.remove(0)
    
    if movement_params.optimizes_edge_land_positions_at_run_time:
        # Optimize land positions.
        
        for i in range(1, path.edges.size()):
            var previous_edge: Edge = path.edges[i - 1]
            var current_edge: Edge = path.edges[i]
            
            # We shouldn't have two intra-surface edges in a row.
            assert(!(previous_edge is IntraSurfaceEdge) or \
                    !(current_edge is IntraSurfaceEdge))
            
            var is_current_edge_long_enough_to_be_worth_optimizing_land_position := \
                    current_edge.distance >= \
                    movement_params \
                            .min_intra_surface_distance_to_optimize_jump_for
            
            if is_current_edge_long_enough_to_be_worth_optimizing_land_position and \
                    current_edge is IntraSurfaceEdge:
                previous_edge.calculator \
                        .optimize_edge_land_position_for_path(
                                collision_params,
                                path,
                                i - 1,
                                previous_edge,
                                current_edge)
    
    if movement_params \
            .prevents_path_ends_from_exceeding_surface_ends_with_offsets:
        var last_edge: Edge = path.edges.back()
        if last_edge is IntraSurfaceEdge:
            var surface := last_edge.get_end_surface()
            var end_position := last_edge.end_position_along_surface
            var target_point := Vector2.INF
            match surface.side:
                SurfaceSide.FLOOR:
                    if end_position.target_point.x < surface.first_point.x + \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2(
                                surface.first_point.x + \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.first_point.y)
                    elif end_position.target_point.x > surface.last_point.x - \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2(
                                surface.last_point.x - \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.last_point.y)
                SurfaceSide.LEFT_WALL:
                    if end_position.target_point.y < surface.first_point.y + \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2(
                                surface.first_point.x,
                                surface.first_point.y + \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                    elif end_position.target_point.y > surface.last_point.y - \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2(
                                surface.last_point.x,
                                surface.last_point.y - \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                SurfaceSide.RIGHT_WALL:
                    if end_position.target_point.y > surface.first_point.y - \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2(
                                surface.first_point.x,
                                surface.first_point.y - \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                    elif end_position.target_point.y < surface.last_point.y + \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2(
                                surface.last_point.x,
                                surface.last_point.y + \
                                PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                SurfaceSide.CEILING:
                    if end_position.target_point.x > surface.first_point.x - \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2(
                                surface.first_point.x - \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.first_point.y)
                    elif end_position.target_point.x < surface.last_point.x + \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2(
                                surface.last_point.x + \
                                PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET,
                                surface.last_point.y)
                _:
                    Sc.logger.error("Invalid SurfaceSide")
            
            if target_point != Vector2.INF:
                last_edge.update_terminal(
                        false,
                        target_point)
    
    if movement_params.optimizes_edge_jump_positions_at_run_time or \
            movement_params.optimizes_edge_land_positions_at_run_time or \
            movement_params \
            .prevents_path_ends_from_exceeding_surface_ends_with_offsets:
        path.update_distance_and_duration()
    
    path.is_optimized = true
    
    Sc.profiler.stop("navigator_optimize_edges_for_approach")


func _ensure_edges_have_trajectory_state(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath) -> void:
    if collision_params.movement_params \
            .is_trajectory_state_stored_at_build_time:
        # Edges in the path should already contain trajectory state.
        return
    
    Sc.profiler.start("navigator_ensure_edges_have_trajectory_state")
    
    for i in path.edges.size():
        var edge: Edge = path.edges[i]
        
        if edge.trajectory != null or \
                edge.calculator == null:
            continue
        
        var edge_with_trajectory: Edge = edge.calculator.calculate_edge(
                null,
                collision_params,
                edge.start_position_along_surface,
                edge.end_position_along_surface,
                edge.velocity_start,
                edge.includes_extra_jump_duration,
                edge.includes_extra_wall_land_horizontal_speed)
        if edge_with_trajectory == null:
            # TODO: I may be able to remove this, and may have only hit this
            #       bug because I was using stale platform graph files after
            #       updating movement_params?
            Sc.logger.warning(
                    "Unable to calculate trajectory for edge: %s" % 
                    edge.to_string())
            var placeholder_trajectory_hack := EdgeTrajectoryUtils \
                    .create_trajectory_placeholder_hack(edge)
            path.edges[i].trajectory = placeholder_trajectory_hack
        else:
            var do_edges_match: bool = \
                    edge_with_trajectory != null and \
                    Sc.geometry.are_floats_equal_with_epsilon(
                            edge_with_trajectory.duration,
                            edge.duration,
                            0.001) and \
                    Sc.geometry.are_floats_equal_with_epsilon(
                            edge_with_trajectory.distance,
                            edge.distance,
                            1.0)
            # FIXME:
            # - Remove.
            # - Another reason this has happened in the past is that
            #   CollisionCheckUtils.check_frame_for_collision >
            #   crash_test_dummy.move_and_collide inconsistently detects a
            #   collision during the last frame of an edge.
            #   - It detects the collision at build time, but not at run time.
            #   - So the run-time trajectory has one extra frame, and a bit
            #     more distance for that frame.
#            if !do_edges_match:
#                edge_with_trajectory = edge.calculator.calculate_edge(
#                        null,
#                        collision_params,
#                        edge.start_position_along_surface,
#                        edge.end_position_along_surface,
#                        edge.velocity_start,
#                        edge.includes_extra_jump_duration,
#                        edge.includes_extra_wall_land_horizontal_speed)
            # **Did you change the tile map or movement params and forget to
            #   update the platform graph??**
            assert(do_edges_match)
            path.edges[i] = edge_with_trajectory
    
    Sc.profiler.stop("navigator_ensure_edges_have_trajectory_state")


# Inserts extra intra-surface between any edges that land and then immediately
# jump from the same position, since the land position could be off due to
# movement error at runtime.
static func _interleave_intra_surface_edges(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath) -> void:
    # Insert extra intra-surface between any edges that land and then
    # immediately jump from the same position, since the land position could be
    # off due to movement error at runtime.
    var i := 0
    var count := path.edges.size()
    while i < count:
        var edge: Edge = path.edges[i]
        # Check whether this edge lands on a surface from the air.
        if edge.surface_type == SurfaceType.AIR and \
                edge.get_end_surface() != null:
            # Since the surface lands on the surface from the air, there could
            # be enough movement error that we should move along the surface to
            # the intended land position before executing the next originally
            # calculated edge (but don't worry about IntraSurfaceEdges, since
            # they'll end up moving to the correct spot anyway).
            if i + 1 < count and \
                    !(path.edges[i + 1] is IntraSurfaceEdge):
                path.edges.insert(i + 1,
                        IntraSurfaceEdge.new(
                                edge.end_position_along_surface,
                                edge.end_position_along_surface,
                                # TODO: Calculate a more accurate
                                #       surface-aligned value.
                                edge.velocity_end,
                                collision_params.movement_params))
                i += 1
                count += 1
        i += 1
