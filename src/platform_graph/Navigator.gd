class_name Navigator
extends Reference

signal started_navigation
signal reached_destination

const PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET := 1.0
const PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET := 1.0

var player
var graph: PlatformGraph
var surface_state: PlayerSurfaceState
var instructions_action_source: InstructionsActionSource
var from_air_calculator: FromAirCalculator
var surface_to_air_calculator: JumpFromSurfaceCalculator

var is_currently_navigating := false
var has_reached_destination := false
var just_reached_destination := false
var previous_path: PlatformGraphPath
var path: PlatformGraphPath
var path_start_time_scaled := INF
var edge: Edge
var edge_index := -1
var playback: InstructionsPlayback
var actions_might_be_dirty := false
var current_navigation_attempt_count := 0

var navigation_state := PlayerNavigationState.new()

func _init(
        player,
        graph: PlatformGraph) -> void:
    self.player = player
    self.graph = graph
    self.surface_state = player.surface_state
    self.navigation_state.is_human_player = player.is_human_player
    self.instructions_action_source = \
            InstructionsActionSource.new(player, true)
    self.from_air_calculator = FromAirCalculator.new()
    self.surface_to_air_calculator = JumpFromSurfaceCalculator.new()

func navigate_path(
        path: PlatformGraphPath,
        is_retry := false) -> bool:
    Gs.profiler.start("navigator_navigate_path")
    
    var previous_navigation_attempt_count := current_navigation_attempt_count
    _reset()
    if is_retry:
        current_navigation_attempt_count = previous_navigation_attempt_count
    
    if path != null and \
            !Gs.geometry.are_points_equal_with_epsilon(
                    player.position,
                    path.origin.target_point,
                    4.0):
        # The selection and its path are stale, so update the path to match
        # the player's current position.
        path = find_path(
                path.destination,
                path.graph_destination_for_in_air_destination)
    
    if path == null:
        # Destination cannot be reached from origin.
        Gs.profiler.stop("navigator_navigate_path")
        print_msg("CANNOT NAVIGATE NULL PATH")
        return false
        
    else:
        # Destination can be reached from origin.
        
        _interleave_intra_surface_edges(
                graph.collision_params,
                path)
        
        Gs.profiler.start("navigator_optimize_edges_for_approach")
        _optimize_edges_for_approach(
                graph.collision_params,
                path,
                player.velocity)
        var duration_optimize_edges_for_approach: float = Gs.profiler.stop(
                "navigator_optimize_edges_for_approach")
        
        path.update_distance_and_duration()
        
        self.path = path
        self.path_start_time_scaled = Gs.time.get_scaled_play_time_sec()
        is_currently_navigating = true
        has_reached_destination = false
        just_reached_destination = false
        current_navigation_attempt_count += 1
        
        var duration_navigate_to_position: float = \
                Gs.profiler.stop("navigator_navigate_path")
        
        var format_string_template := (
                "STARTING PATH NAV:   %8.3fs; {" +
                "\n\tdestination: %s," +
                "\n\tpath: %s," +
                "\n\ttimings: {" +
                "\n\t\tduration_navigate_to_position: %sms" +
                "\n\t\tduration_optimize_edges_for_approach: %sms" +
                "\n\t}" +
                "\n}")
        var format_string_arguments := [
            Gs.time.get_play_time_sec(),
            path.destination.to_string(),
            path.to_string_with_newlines(1),
            duration_navigate_to_position,
            duration_optimize_edges_for_approach,
        ]
        print_msg(format_string_template, format_string_arguments)
        
        _start_edge(
                0,
                is_retry)
        
        emit_signal("started_navigation")
        
        return true

# Starts a new navigation to the given destination.
func navigate_to_position(
        destination: PositionAlongSurface,
        graph_destination_for_in_air_destination: PositionAlongSurface = null,
        is_retry := false) -> bool:
    # Nudge the destination away from any concave neighbor surfaces, if
    # necessary.
    destination = PositionAlongSurface.new(destination)
    JumpLandPositionsUtils \
            .ensure_position_is_not_too_close_to_concave_neighbor(
                    player.movement_params,
                    destination)
    
    if graph_destination_for_in_air_destination != null:    
        # Nudge the graph-destination away from any concave neighbor surfaces,
        # if necessary.
        graph_destination_for_in_air_destination = PositionAlongSurface.new(
                graph_destination_for_in_air_destination)
        JumpLandPositionsUtils \
                .ensure_position_is_not_too_close_to_concave_neighbor(
                        player.movement_params,
                        graph_destination_for_in_air_destination)
    
    var path := find_path(
            destination, graph_destination_for_in_air_destination)
    
    return navigate_path(path, is_retry)

func find_path(
        destination: PositionAlongSurface,
        graph_destination_for_in_air_destination: PositionAlongSurface = \
                null) -> PlatformGraphPath:
    Gs.profiler.start("navigator_find_path")
    
    var graph_origin: PositionAlongSurface
    var prefix_edge: FromAirEdge
    var suffix_edge: JumpFromSurfaceEdge
    
    # Handle the start of the path.
    if surface_state.is_grabbing_a_surface:
        # Find a path from a starting player-position along a surface.
        graph_origin = PositionAlongSurface.new(
                surface_state.center_position_along_surface)
    else:
        # Find a path from a starting player-position in the air.
        
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
                        player.velocity,
                        destination,
                        null)
        
        if from_air_edge == null and \
                is_currently_navigating and \
                edge.get_end_surface() != null:
            # We weren't able to dynamically calculate a valid air-to-surface
            # edge from the current in-air position, but the player was already
            # navigating along a valid edge to a surface, so let's just re-use
            # the remainder of that edge.
            
            # TODO: This case shouldn't be needed; in theory, we should have
            #       been able to find a valid land trajectory above.
            Gs.logger.print("Unable to calculate air-to-surface edge")
            
            var elapsed_edge_time := playback.get_elapsed_time_scaled()
            if elapsed_edge_time < edge.duration:
                from_air_edge = from_air_calculator \
                        .create_edge_from_part_of_other_edge(
                                edge,
                                elapsed_edge_time,
                                player)
            else:
                Gs.logger.print(
                        "Unable to re-use current edge as air-to-surface " +
                        "edge: edge playback time exceeds edge duration")
        
        if from_air_edge != null:
            # We were able to calculate a valid air-to-surface edge.
            graph_origin = from_air_edge.end_position_along_surface
            prefix_edge = from_air_edge
        else:
            Gs.profiler.stop("navigator_find_path")
            return null
    
    # Handle the end of the path.
    if destination.surface != null:
        # Find a path to an ending player-position along a surface.
        graph_destination_for_in_air_destination = destination
    else:
        # Find a path to an ending player-position in the air.
        
        assert(graph_destination_for_in_air_destination != null)
        
        # Try to dynamically calculate a valid surface-to-air edge.
        var velocity_start := JumpLandPositionsUtils.get_velocity_start(
                player.movement_params,
                graph_destination_for_in_air_destination.surface,
                surface_to_air_calculator.is_a_jump_calculator,
                false,
                true)
        var surface_to_air_edge := surface_to_air_calculator.calculate_edge(
                null,
                graph.collision_params,
                graph_destination_for_in_air_destination,
                destination,
                velocity_start,
                false,
                false)
        
        if surface_to_air_edge != null:
            # We were able to calculate a valid surface-to-air edge.
            suffix_edge = surface_to_air_edge
        else:
            Gs.logger.print("Unable to calculate surface-to-air edge")
            Gs.profiler.stop("navigator_find_path")
            return null
    
    var path := graph.find_path(
            graph_origin,
            graph_destination_for_in_air_destination)
    if path != null:
        path.graph_destination_for_in_air_destination = \
                graph_destination_for_in_air_destination
        if prefix_edge != null:
            path.push_front(prefix_edge)
        if suffix_edge != null:
            path.push_back(suffix_edge)
    
    Gs.profiler.stop("navigator_find_path")
    
    return path

func stop() -> void:
    _reset()

func _set_reached_destination() -> void:
    if player.movement_params.forces_player_position_to_match_path_at_end:
        player.set_position(edge.get_end())
    if player.movement_params.forces_player_velocity_to_zero_at_path_end and \
            edge.get_end_surface() != null:
        match edge.get_end_surface().side:
            SurfaceSide.FLOOR, SurfaceSide.CEILING:
                player.velocity.x = 0.0
            SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                player.velocity.y = 0.0
            _:
                Gs.logger.error("Invalid SurfaceSide")
    
    _reset()
    has_reached_destination = true
    just_reached_destination = true
    
    print_msg("REACHED END OF PATH: %8.3fs", Gs.time.get_play_time_sec())
    
    emit_signal("reached_destination")

func _reset() -> void:
    if path != null:
        previous_path = path
    
    path = null
    path_start_time_scaled = INF
    edge = null
    edge_index = -1
    is_currently_navigating = false
    has_reached_destination = false
    just_reached_destination = false
    playback = null
    instructions_action_source.cancel_all_playback()
    actions_might_be_dirty = true
    current_navigation_attempt_count = 0
    navigation_state.reset()

func _start_edge(
        index: int,
        is_starting_navigation_retry := false) -> void:
    Gs.profiler.start("navigator_start_edge")
    
    edge_index = index
    edge = path.edges[index]
    
    if player.movement_params.forces_player_position_to_match_edge_at_start:
        player.set_position(edge.get_start())
    if player.movement_params.forces_player_velocity_to_match_edge_at_start:
        player.velocity = edge.velocity_start
        surface_state.horizontal_acceleration_sign = 0
    
    edge.update_for_surface_state(
            surface_state,
            edge == path.edges.back())
    navigation_state.is_expecting_to_enter_air = edge.enters_air
    
    playback = instructions_action_source.start_instructions(
            edge,
            Gs.time.get_scaled_play_time_sec())
    
    var duration_start_edge: float = \
            Gs.profiler.stop("navigator_start_edge")
    
    var format_string_template := \
            "STARTING EDGE NAV:   %8.3fs; %s; calc duration=%sms"
    var format_string_arguments := [
            Gs.time.get_play_time_sec(),
            edge.to_string_with_newlines(0),
            str(duration_start_edge),
        ]
    print_msg(format_string_template, format_string_arguments)
    
    # Some instructions could be immediately skipped, depending on runtime
    # state, so this gives us a change to move straight to the next edge.
    update(
            true,
            is_starting_navigation_retry)

func update(
        just_started_new_edge := false,
        is_starting_navigation_retry := false) -> void:
    just_reached_destination = false
    
    actions_might_be_dirty = just_started_new_edge
    
    if !is_currently_navigating:
        return
    
    edge.update_navigation_state(
            navigation_state,
            surface_state,
            playback,
            just_started_new_edge,
            is_starting_navigation_retry)
    
    if navigation_state.just_interrupted_navigation:
        var interruption_type_label: String
        if navigation_state.just_left_air_unexpectedly:
            interruption_type_label = \
                    "navigation_state.just_left_air_unexpectedly"
        elif navigation_state.just_entered_air_unexpectedly:
            interruption_type_label = \
                    "navigation_state.just_entered_air_unexpectedly"
        else: # navigation_state.just_interrupted_by_user_action
            interruption_type_label = \
                    "navigation_state.just_interrupted_by_user_action"
        print_msg("EDGE MVT INTERRUPTED:%8.3fs; %s",
                [Gs.time.get_play_time_sec(), interruption_type_label])
        
        if player.movement_params.retries_navigation_when_interrupted:
            navigate_to_position(
                    path.destination,
                    path.graph_destination_for_in_air_destination,
                    true)
        else:
            _reset()
        return
        
    elif navigation_state.just_reached_end_of_edge:
        print_msg("REACHED END OF EDGE: %8.3fs; %s", [
            Gs.time.get_play_time_sec(),
            edge.get_name(),
        ])
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
                Gs.time.get_scaled_play_time_sec())
        playback = null
        
        # Check for the next edge to navigate.
        var next_edge_index := edge_index + 1
        var was_last_edge := path.edges.size() == next_edge_index
        if was_last_edge:
            var backtracking_edge := \
                    _possibly_backtrack_to_not_protrude_past_surface_end(
                            player.movement_params,
                            edge,
                            player.position,
                            player.velocity)
            if backtracking_edge == null:
                _set_reached_destination()
            else:
                var format_string_template := "INSRT CTR-PROTR EDGE:%8.3fs; %s"
                var format_string_arguments := [
                        Gs.time.get_play_time_sec(),
                        backtracking_edge.to_string_with_newlines(0),
                    ]
                print_msg(format_string_template, format_string_arguments)
                
                path.edges.push_back(backtracking_edge)
                
                _start_edge(next_edge_index)
        else:
            _start_edge(next_edge_index)

func predict_animation_state(
        result: PlayerAnimationState,
        elapsed_time_from_now: float) -> bool:
    if !is_currently_navigating:
        player.get_current_animation_state(result)
        return false
    
    var current_path_elapsed_time := \
            Gs.time.get_scaled_play_time_sec() - \
            path_start_time_scaled
    var prediction_path_time := \
            current_path_elapsed_time + elapsed_time_from_now
    
    return path.predict_animation_state(result, prediction_path_time)

func get_destination() -> PositionAlongSurface:
    return path.destination if path != null else null

func get_previous_destination() -> PositionAlongSurface:
    return previous_path.destination if previous_path != null else null

# Conditionally prints the given message, depending on the Player's
# configuration.
func print_msg(
        message_template: String,
        message_args = null) -> void:
    if Surfacer.is_surfacer_logging and \
            player.movement_params.logs_navigator_events and \
            (player.is_human_player or \
                    player.movement_params.logs_computer_player_events):
        if message_args != null:
            Gs.logger.print(message_template % message_args)
        else:
            Gs.logger.print(message_template)

static func _possibly_backtrack_to_not_protrude_past_surface_end(
        movement_params: MovementParams,
        edge: Edge,
        position: Vector2,
        velocity: Vector2) -> IntraSurfaceEdge:
    var surface := edge.get_end_surface()
    
    if surface == null or \
            !movement_params \
            .prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets or \
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
            Gs.logger.error("Invalid SurfaceSide")
    
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
# - This also updates start velocity when updating start position.
static func _optimize_edges_for_approach(
        collision_params: CollisionCalcParams,
        path: PlatformGraphPath,
        velocity_start: Vector2) -> void:
    var movement_params := collision_params.movement_params
    
    # At runtime, after finding a path through build-time-calculated edges, try
    # to optimize the jump-off or land points of the edges to better account
    # for the direction that the player will be approaching the edge from. This
    # produces more efficient and natural movement. The build-time-calculated
    # edge state would only use surface end-points or closest points. We also
    # take this opportunity to update start velocities to exactly match what is
    # allowed from the ramp-up distance along the edge, rather than either the
    # fixed zero or max-speed value used for the build-time-calculated edge
    # state.
    
    if movement_params.optimizes_edge_jump_positions_at_run_time:
        # Optimize jump positions.
        
        var previous_edge: Edge
        var current_edge: Edge
        var is_previous_edge_long_enough_to_be_worth_optimizing_jump_position: bool
        var previous_velocity_end_x := velocity_start.x
        
        for i in range(1, path.edges.size()):
            previous_edge = path.edges[i - 1]
            current_edge = path.edges[i]
            
            # We shouldn't have two intra-surface edges in a row.
            assert(!(previous_edge is IntraSurfaceEdge) or \
                    !(current_edge is IntraSurfaceEdge))
            
            is_previous_edge_long_enough_to_be_worth_optimizing_jump_position = \
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
                Gs.geometry.are_points_equal_with_epsilon(
                        path.edges[0].get_start(),
                        path.edges[1].get_start(),
                        1.0):
            path.edges.remove(0)
    
    if movement_params.optimizes_edge_land_positions_at_run_time:
        # Optimize land positions.
        
        var previous_edge: Edge
        var current_edge: Edge
        var is_current_edge_long_enough_to_be_worth_optimizing_land_position: bool
        
        for i in range(1, path.edges.size()):
            previous_edge = path.edges[i - 1]
            current_edge = path.edges[i]
            
            # We shouldn't have two intra-surface edges in a row.
            assert(!(previous_edge is IntraSurfaceEdge) or \
                    !(current_edge is IntraSurfaceEdge))
            
            is_current_edge_long_enough_to_be_worth_optimizing_land_position = \
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
            .prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets:
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
                    Gs.logger.error("Invalid SurfaceSide")
            
            if target_point != Vector2.INF:
                last_edge.update_terminal(
                        false,
                        target_point)

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
    var edge: Edge
    while i < count:
        edge = path.edges[i]
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
