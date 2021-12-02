class_name SurfaceNavigator
extends Reference
## Logic for navigating a character along a path of edges through a platform
## graph to a destination position.


signal navigation_started(is_retry)
signal destination_reached
signal navigation_interrupted(interruption_resolution_mode)
signal navigation_canceled
signal navigation_ended(did_reach_destination)

const PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET := 1.0
const PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET := 1.0

const BOUNCIFY_MAIN_JUMP_DISTANCE_RATIO_OF_MAX := 0.9
const BOUNCIFY_FALLBACK_JUMP_DISTANCE_RATIO_OF_MAX := 0.5
const BOUNCIFY_CLOSE_ENOUGH_TO_END_DISTANCE_RATIO_OF_JUMP := 0.2

const IGNORE_SHORT_EDGE_BEFORE_INITIAL_JUMP_DISTANCE_THRESHOLD := 4.0

const CANCEL_FROM_REPEAT_INTERRUPTIONS_DISTANCE_SQUARED_THRESHOLD := \
        12.0 * 12.0

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
var current_navigation_attempt_count := 0

var navigation_state := CharacterNavigationState.new()

var interruption_resolution_mode := NavigationInterruptionResolution.CANCEL_NAV


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
        _log("Null path",
                "",
                false)
        return false
    
    # Destination can be reached from origin.
    
    _interleave_intra_surface_edges(
            graph.collision_params,
            path)
    
    
    var start_velocity := \
            MovementUtils.clamp_horizontal_velocity_to_max_default(
                    movement_params,
                    character.velocity)
    _optimize_edges_for_approach(
            graph.collision_params,
            path,
            start_velocity)
    
    _ensure_edges_have_trajectory_state(
            graph.collision_params,
            path)
    
    self.path = path
    self.path_start_time_scaled = Sc.time.get_scaled_play_time()
    self.path_beats = Sc.beats.calculate_path_beat_hashes_for_current_mode(
            path, path_start_time_scaled)
    navigation_state.is_currently_navigating = true
    navigation_state.has_reached_destination = false
    navigation_state.path_start_time = Sc.time.get_scaled_play_time()
    navigation_state.last_interruption_position = Vector2.INF
    current_navigation_attempt_count += 1
    
    var duration_navigate_to_position: float = \
            Sc.profiler.stop("navigator_navigate_path")
    
    _log("Path start",
            "to=%s; from=%s; edges=%d" % [
                Sc.utils.get_vector_string(
                        path.destination.target_point, 0),
                Sc.utils.get_vector_string(path.origin.target_point, 0),
                path.edges.size(),
            ],
            false)
    if character.logs_verbose_navigator_events:
        var message := (
                    "{" +
                    "\n\tdestination: %s," +
                    "\n\tpath: %s," +
                    "\n\ttimings: {" +
                    "\n\t\tduration_navigate_to_position: %sms" +
                    "\n\t}" +
                    "\n}"
                ) % [
                    path.destination.to_string(),
                    path.to_string_with_newlines(1),
                    duration_navigate_to_position,
                ]
        character._log(
                message,
                "",
                CharacterLogType.NAVIGATION,
                true,
                false,
                false)
    
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
    if surface_state.is_grabbing_surface:
        # Find a path from a starting character-position along a surface.
        graph_origin = PositionAlongSurface.new(
                surface_state.center_position_along_surface)
    else:
        # Find a path from a starting character-position in the air.
        
        # Try to dynamically calculate a valid air-to-surface edge from the
        # current in-air position.
        var origin := PositionAlongSurfaceFactory \
                .create_position_without_surface(surface_state.center_position)
        # FIXME: --------------- Test/tweak/remove? this.
        var start_velocity_epsilon := Vector2(0.0, -5.0)
        var start_velocity := character.velocity + start_velocity_epsilon
        start_velocity = MovementUtils.clamp_horizontal_velocity_to_max_default(
                movement_params,
                start_velocity)
        var can_hold_jump_button_at_start: bool = \
                character.actions.pressed_jump
        var from_air_edge := from_air_calculator.find_a_landing_trajectory(
                null,
                graph.collision_params,
                graph.surfaces_set,
                origin,
                start_velocity,
                can_hold_jump_button_at_start,
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
            
            var elapsed_edge_time := playback.get_elapsed_time_scaled()
            from_air_edge = from_air_calculator \
                    .create_edge_from_part_of_other_edge(
                            edge,
                            elapsed_edge_time,
                            character)
            
            if from_air_edge == null:
                # Edge playback has already exceeded the expected duration.
                # -   The expected edge duration is recorded according to a
                #     single calculation up-front, whereas the edge trajectory
                #     and edge playback are calculated according to incremental
                #     frame-by-frame motion updates.
                # -   This means that the expected edge duration is often less
                #     than reality.
                # -   So, in this case, we can just force the character position
                #     to match the end of the edge.
                
                graph_origin = edge.end_position_along_surface
                
                var sync_position := \
                        movement_params \
                            .syncs_character_position_to_edge_trajectory or \
                        movement_params \
                            .forces_character_position_to_match_path_at_end or \
                        movement_params \
                            .forces_character_position_to_match_edge_at_start
                if sync_position:
                    character.position = edge.get_end()
                
                var sync_velocity := \
                        movement_params \
                            .syncs_character_velocity_to_edge_trajectory or \
                        movement_params \
                            .forces_character_velocity_to_zero_at_path_end or \
                        movement_params \
                            .forces_character_velocity_to_match_edge_at_start
                if sync_velocity:
                    character.velocity = edge.velocity_end
        
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
            # We were unable to calculate a valid surface-to-air edge.
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
        var start_velocity := \
                MovementUtils.clamp_horizontal_velocity_to_max_default(
                        movement_params,
                        character.velocity)
        if movement_params.also_optimizes_preselection_path:
            _optimize_edges_for_approach(
                    graph.collision_params,
                    path,
                    start_velocity)
        
        _ensure_edges_have_trajectory_state(
                graph.collision_params,
                path)
    
    return path


func bouncify_path(path: PlatformGraphPath) -> void:
    # -   Iterate through the edges in the path.
    # -   If the edge is an IntraSurfaceEdge, then replace it with a series of
    #     jumps.
    # -   Interleave the stardand in-between IntraSurfaceEdges between the
    #     jumps.
    
    var main_jump_distance: float = character.movement_params \
            .floor_jump_max_horizontal_jump_distance * \
            BOUNCIFY_MAIN_JUMP_DISTANCE_RATIO_OF_MAX
    var fallback_jump_distance: float = character.movement_params \
            .floor_jump_max_horizontal_jump_distance * \
            BOUNCIFY_FALLBACK_JUMP_DISTANCE_RATIO_OF_MAX
    var close_enough_to_end_distance: float = character.movement_params \
            .floor_jump_max_horizontal_jump_distance * \
            BOUNCIFY_CLOSE_ENOUGH_TO_END_DISTANCE_RATIO_OF_JUMP
    
    var i := 0
    while i < path.edges.size():
        var original_edge: Edge = path.edges[i]
        var surface := original_edge.get_start_surface()
        
        # We only add jumps for floor IntraSurfaceEdges.
        if !(original_edge is IntraSurfaceEdge) or \
                surface.side != SurfaceSide.FLOOR:
            i += 1
            continue
        
        var was_last_edge := i == path.edges.size() - 1
        
        var new_edges := []
        
        var end_point := original_edge.get_end()
        var current_start_point := original_edge.get_start()
        var displacement := end_point - current_start_point
        var remaining_distance := abs(displacement.x)
        
        var horizontal_movement_sign := \
                -1 if \
                displacement.x < 0 else \
                1
        var movement_direction := horizontal_movement_sign * Vector2(1, 0)
        
        var main_jump_displacement := \
                main_jump_distance * movement_direction
        var fallback_jump_displacement := \
                fallback_jump_distance * movement_direction
        
        var calculator: JumpFromSurfaceCalculator = \
                Su.movement.edge_calculators["JumpFromSurfaceCalculator"]
        var velocity_start := JumpLandPositionsUtils.get_velocity_start(
                character.movement_params,
                surface,
                true,
                displacement.x < 0,
                false)
        
        # Add an in-between IntraSurface edge.
        var previous_velocity_end_x: float = \
                path.edges[i - 1].velocity_end.x if \
                i > 0 else \
                0.0
        var intra_surface_edge: IntraSurfaceEdge = Su.movement \
                .intra_surface_calculator.create_correction_interstitial(
                        original_edge.start_position_along_surface,
                        Vector2(previous_velocity_end_x, 0.0),
                        character.movement_params)
        new_edges.push_back(intra_surface_edge)
        
        while remaining_distance > close_enough_to_end_distance:
            var jump_origin := PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            current_start_point,
                            surface,
                            character.collider,
                            true,
                            false)
            
            var possible_displacements := \
                    [main_jump_displacement, fallback_jump_displacement] if \
                    remaining_distance >= main_jump_distance else \
                    [fallback_jump_displacement] if \
                    remaining_distance >= fallback_jump_distance else \
                    [movement_direction * remaining_distance]
            
            var current_end_point: Vector2
            var jump_destination: PositionAlongSurface
            var jump_edge: JumpFromSurfaceEdge
            
            for jump_displacement in possible_displacements:
                current_end_point = current_start_point + jump_displacement
                jump_destination = PositionAlongSurfaceFactory \
                        .create_position_offset_from_target_point(
                                current_end_point,
                                surface,
                                character.collider,
                                true,
                                false)
                jump_edge = calculator.calculate_edge(
                        null,
                        graph.collision_params,
                        jump_origin,
                        jump_destination,
                        velocity_start)
                if jump_edge != null:
                    break
            
            if jump_edge != null:
                new_edges.push_back(jump_edge)
                
                # Add an in-between IntraSurface edge.
                previous_velocity_end_x = jump_edge.velocity_end.x
                intra_surface_edge = Su.movement.intra_surface_calculator \
                        .create_correction_interstitial(
                                jump_edge.end_position_along_surface,
                                Vector2(previous_velocity_end_x, 0.0),
                                character.movement_params)
                new_edges.push_back(intra_surface_edge)
            else:
                # We weren't able to calculate a jump edge for this span, so
                # just use an intra-surface edge.
                previous_velocity_end_x = intra_surface_edge.velocity_end.x
                intra_surface_edge = \
                        Su.movement.intra_surface_calculator.create(
                                jump_origin,
                                jump_destination,
                                Vector2(previous_velocity_end_x, 0.0),
                                character.movement_params)
                new_edges.push_back(intra_surface_edge)
            
            remaining_distance = abs(end_point.x - current_end_point.x)
            current_start_point = current_end_point
        
        if !was_last_edge:
            # If the path continues on after this, then replace the last
            # in-between intra-surface edge with one that will get us to the
            # original edge end point.
            intra_surface_edge = new_edges.back()
            intra_surface_edge = Su.movement.intra_surface_calculator.create(
                    intra_surface_edge.start_position_along_surface,
                    original_edge.end_position_along_surface,
                    intra_surface_edge.velocity_start,
                    character.movement_params)
            new_edges[new_edges.size() - 1] = intra_surface_edge
        
        # Merge any adjacent intra-surface edges.
        var j := 0
        while j < new_edges.size() - 1:
            var previous: Edge = new_edges[j]
            var next: Edge = new_edges[j + 1]
            if previous is IntraSurfaceEdge and \
                    next is IntraSurfaceEdge:
                new_edges[j] = Su.movement.intra_surface_calculator.create(
                        previous.start_position_along_surface,
                        next.end_position_along_surface,
                        previous.velocity_start,
                        character.movement_params)
                new_edges.remove(j + 1)
                j -= 1
            j += 1
        
        if new_edges.size() > 1:
            # We created some new jumps, so replace the old edge with them.
            Sc.utils.splice(
                    path.edges,
                    i,
                    1,
                    new_edges)
            i += new_edges.size()
        else:
            # We weren't able to create any new jumps, so keep the old edge.
            i += 1
    
    path.update_distance_and_duration()


func try_to_start_path_with_a_jump(
        path: PlatformGraphPath,
        jump_boost_multiplier := 1.0) -> bool:
    var first_edge: Edge = path.edges[0]

    if first_edge is FromAirEdge:
        # Don't bother trying to jump at the start, since the character is
        # already starting in the air.
        return false
    
    var was_almost_starting_with_a_jump: bool = \
            path.edges.size() > 1 and \
            first_edge is IntraSurfaceEdge and \
            path.edges[1] is JumpFromSurfaceEdge and \
            first_edge.distance < \
                    IGNORE_SHORT_EDGE_BEFORE_INITIAL_JUMP_DISTANCE_THRESHOLD
    
    # TODO: Possibly support paths starting with inter-surface edges.
    #       But then we'll need to also add a new intra-surface edge after our
    #       new jump edge.
    if first_edge is IntraSurfaceEdge and \
            first_edge.start_position_along_surface.side == \
                    SurfaceSide.FLOOR and \
            !was_almost_starting_with_a_jump:
        var calculator: JumpFromSurfaceCalculator = \
                Su.movement.edge_calculators["JumpFromSurfaceCalculator"]
        var velocity_start := JumpLandPositionsUtils.get_velocity_start(
                movement_params,
                path.origin.surface,
                true,
                false,
                true)
        velocity_start.y *= jump_boost_multiplier
        var jump_edge := calculator.calculate_edge(
                null,
                graph.collision_params,
                path.origin,
                path.origin,
                velocity_start)
        
        if jump_edge != null:
            path.push_front(jump_edge)
            calculator.optimize_edge_land_position_for_path(
                    graph.collision_params,
                    path,
                    0,
                    jump_edge,
                    path.edges[1])
            path.update_distance_and_duration()
            return true
    
    return false


func try_to_end_path_with_a_jump(path: PlatformGraphPath) -> bool:
    var end_edge: Edge = path.edges[path.edges.size() - 1]
    
    if !(end_edge is IntraSurfaceEdge):
        # Don't bother trying to jump at the end, since the character is
        # already ending with an air-borne edge.
        return false
    
    var was_almost_ending_with_a_jump: bool = \
            path.edges.size() > 1 and \
            !(path.edges[path.edges.size() - 2] is JumpFromSurfaceEdge) and \
            end_edge.distance < \
                    IGNORE_SHORT_EDGE_BEFORE_INITIAL_JUMP_DISTANCE_THRESHOLD
    
    if !was_almost_ending_with_a_jump and \
            end_edge.end_position_along_surface.side == SurfaceSide.FLOOR:
        var is_end_edge_moving_leftward := \
                end_edge.get_end().x - end_edge.get_start().x < 0
        var calculator: JumpFromSurfaceCalculator = \
                Su.movement.edge_calculators["JumpFromSurfaceCalculator"]
        var velocity_start := JumpLandPositionsUtils.get_velocity_start(
                character.movement_params,
                path.destination.surface,
                true,
                is_end_edge_moving_leftward,
                false)
        var jump_edge := calculator.calculate_edge(
                null,
                graph.collision_params,
                path.destination,
                path.destination,
                velocity_start)
        
        if is_instance_valid(jump_edge):
            path.push_back(jump_edge)
            var previous_edge := end_edge
            var previous_velocity_end_x := previous_edge.velocity_end.x
            calculator.optimize_edge_jump_position_for_path(
                    graph.collision_params,
                    path,
                    path.edges.size() - 1,
                    previous_velocity_end_x,
                    previous_edge,
                    jump_edge)
            var intra_surface_edge: IntraSurfaceEdge = Su.movement \
                    .intra_surface_calculator.create_correction_interstitial(
                            jump_edge.end_position_along_surface,
                            Vector2(jump_edge.velocity_end.x, 0.0),
                            movement_params)
            path.edges.push_back(intra_surface_edge)
            path.update_distance_and_duration()
            return true
    
    return false


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


func _set_reached_destination() -> void:
    _log("Path end",
            "to=%s; from=%s; edges=%d" % [
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
    current_navigation_attempt_count = 0
    navigation_state.reset()


func _start_edge(
        index: int,
        is_starting_navigation_retry := false) -> void:
    Sc.profiler.start("navigator_start_edge")
    
    edge_index = index
    edge = path.edges[index]
    
    _sync_surface_state_for_start_of_edge(edge)
    
    if edge is IntraSurfaceEdge:
        edge.calculator.update_for_surface_state(
                edge,
                surface_state,
                edge == path.edges.back())
    
    navigation_state.is_expecting_to_enter_air = edge.enters_air
    
    playback = instructions_action_source.start_instructions(
            edge,
            Sc.time.get_scaled_play_time())
    
    var duration_start_edge: float = \
            Sc.profiler.stop("navigator_start_edge")
    
    _log("Edge start",
            edge.to_string(false),
            false)
    if character.logs_verbose_navigator_events:
        var message := "%s; calc duration=%sms" % [
                    edge.to_string_with_newlines(0),
                    str(duration_start_edge),
                ]
        character._log(
                message,
                "",
                CharacterLogType.NAVIGATION,
                true,
                false,
                false)
    
    # Some instructions could be immediately skipped, depending on runtime
    # state, so this gives us a chance to move straight to the next edge.
    _update(true,
            is_starting_navigation_retry)


func _sync_surface_state_for_start_of_edge(edge: Edge) -> void:
    if surface_state.grabbed_surface == edge.get_start_surface():
        return
    
    # -   This can sometimes happen when the edge was detected as
    #     successfully completing because the character was grabbing the
    #     next-neighbor surface.
    # -   In that case, we update the surface state to match what is
    #     expected for the start of the next edge.
    var actual_str := \
            surface_state.grabbed_surface.to_string(false) if \
            is_instance_valid(surface_state.grabbed_surface) else \
            "-"
    var expected_str := \
            edge.get_start_surface().to_string(false) if \
            is_instance_valid(edge.get_start_surface()) else \
            "-"
    var details := (
            "actual=%s; " +
            "expected=%s; " +
            "_start_edge: Grabbed surface was not expected"
        ) % [
            actual_str,
            expected_str,
        ]
    _log("Sync edge st",
            details)
    
    character._match_expected_navigation_surface_state(edge, 0.0)


func _update(
        just_started_new_edge := false,
        is_starting_navigation_retry := false) -> void:
    if just_started_new_edge:
        navigation_state.just_started_edge = true
        navigation_state.edge_start_time = Sc.time.get_scaled_play_time()
        navigation_state.edge_start_frame = \
                Sc.time.get_play_physics_frame_count()
    else:
        navigation_state.just_started_edge = false
    
    navigation_state.edge_frame_count = \
            Sc.time.get_play_physics_frame_count() - \
            navigation_state.edge_start_frame
    
    if !navigation_state.is_currently_navigating:
        navigation_state.just_ended = false
        navigation_state.just_reached_destination = false
        navigation_state.just_canceled = false
        navigation_state.just_interrupted = false
        navigation_state.just_left_air_unexpectedly = false
        navigation_state.just_entered_air_unexpectedly = false
        navigation_state.just_interrupted_by_unexpected_collision = false
        navigation_state.just_interrupted_by_player_action = false
        navigation_state.just_interrupted_by_being_stuck = false
        navigation_state.just_started_edge = false
        navigation_state.just_reached_end_of_edge = false
        return
    
    if _check_if_character_is_stuck():
        # FIXME: ----------------
        # - This probably should never happen.
        # - What is the underlying problem?
#        Sc.logger.error()
        navigation_state.just_interrupted_by_being_stuck = true
        navigation_state.has_interrupted = true
        navigation_state.just_interrupted = true
    else:
        edge.update_navigation_state(
                navigation_state,
                surface_state,
                playback,
                just_started_new_edge,
                is_starting_navigation_retry)
    
    if navigation_state.just_interrupted:
        if is_starting_navigation_retry:
            # FIXME: -----------------
            # - This probably should never happen.
            # - What's the underlying problem?
#            Sc.logger.error()
            Sc.logger.warning(
                    "Unable to fix navigation interruption by forcing " +
                    "state to match what's expected.")
            var resolution_override := \
                    NavigationInterruptionResolution.SKIP_NAV if \
                    interruption_resolution_mode == \
                        NavigationInterruptionResolution \
                            .FORCE_EXPECTED_STATE else \
                    NavigationInterruptionResolution.CANCEL_NAV
            _handle_interruption(
                    just_started_new_edge,
                    resolution_override)
        else:
            _handle_interruption(just_started_new_edge)
        return
    
    if navigation_state.just_reached_end_of_edge:
        _handle_reached_end_of_edge(true)


func _check_if_character_is_stuck() -> bool:
    return !character.surface_state.did_move_last_frame and \
            !character.surface_state.did_move_frame_before_last and \
            navigation_state.edge_start_time <= \
                    Sc.time.get_scaled_play_time() - \
                    Sc.time.PHYSICS_TIME_STEP * 2.0


func _handle_interruption(
        just_started_new_edge := false,
        interruption_resolution_mode := \
                NavigationInterruptionResolution.UNKNOWN) -> void:
    if interruption_resolution_mode == \
            NavigationInterruptionResolution.UNKNOWN:
        interruption_resolution_mode = self.interruption_resolution_mode
    
    navigation_state.has_interrupted = true
    var previous_interruption_position := \
            navigation_state.last_interruption_position
    navigation_state.last_interruption_position = character.position
    
    # If the character is interrupted repeatedly in the same spot, then skip
    # this edge.
    if interruption_resolution_mode == \
                NavigationInterruptionResolution.FORCE_EXPECTED_STATE and \
            previous_interruption_position != Vector2.INF and \
            previous_interruption_position \
                .distance_squared_to(character.position) <= \
                CANCEL_FROM_REPEAT_INTERRUPTIONS_DISTANCE_SQUARED_THRESHOLD:
        interruption_resolution_mode = \
                NavigationInterruptionResolution.SKIP_NAV
    
    var interruption_type_label: String
    if navigation_state.just_left_air_unexpectedly:
        interruption_type_label = "just_left_air_unexpectedly"
    elif navigation_state.just_entered_air_unexpectedly:
        interruption_type_label = "just_entered_air_unexpectedly"
    elif navigation_state.just_interrupted_by_unexpected_collision:
        interruption_type_label = \
                "just_interrupted_by_unexpected_collision"
    elif navigation_state.just_interrupted_by_player_action:
        interruption_type_label = "just_interrupted_by_player_action"
    elif navigation_state.just_interrupted_by_being_stuck:
        interruption_type_label = "just_interrupted_by_being_stuck"
    else:
        interruption_type_label = "UNKNOWN_INTERRUPTION_TYPE"
    _log("Edge interru",
            "%s; %s; to=%s; from=%s" % [
                interruption_type_label,
                NavigationInterruptionResolution.get_string(
                        interruption_resolution_mode),
                Sc.utils.get_vector_string(edge.get_end()),
                Sc.utils.get_vector_string(edge.get_start()),
            ],
            false)
    
    if navigation_state.just_interrupted_by_being_stuck:
        Sc.logger.warning("The character navigation is stuck!")
    
    match interruption_resolution_mode:
        NavigationInterruptionResolution.CANCEL_NAV:
            _reset()
            navigation_state.has_interrupted = true
            navigation_state.just_interrupted = true
            navigation_state.just_ended = true
            emit_signal("navigation_ended", false)
            
        NavigationInterruptionResolution.RETRY_NAV:
            navigate_to_position(
                    path.destination,
                    false,
                    path.graph_destination_for_in_air_destination,
                    true)
            
        NavigationInterruptionResolution.SKIP_NAV:
            navigation_state.has_interrupted = false
            navigation_state.just_interrupted = false
            navigation_state.just_left_air_unexpectedly = false
            navigation_state.just_entered_air_unexpectedly = false
            navigation_state.just_interrupted_by_unexpected_collision = false
            navigation_state.just_interrupted_by_player_action = false
            navigation_state.just_interrupted_by_being_stuck = false
            navigation_state.just_reached_end_of_edge = true
            
            character._match_expected_navigation_surface_state(
                    edge,
                    edge.duration)
            _handle_reached_end_of_edge(true)
            
        NavigationInterruptionResolution.FORCE_EXPECTED_STATE:
            navigation_state.has_interrupted = false
            navigation_state.just_interrupted = false
            navigation_state.just_left_air_unexpectedly = false
            navigation_state.just_entered_air_unexpectedly = false
            navigation_state.just_interrupted_by_unexpected_collision = false
            navigation_state.just_interrupted_by_player_action = false
            navigation_state.just_interrupted_by_being_stuck = false
            character._match_expected_navigation_surface_state()
            _update(just_started_new_edge, true)
            
        _:
            Sc.logger.error()
    
    emit_signal("navigation_interrupted", interruption_resolution_mode)


func _handle_reached_end_of_edge(starts_next_edge: bool) -> void:
    _log("Edge end",
            edge.get_name(),
            false)
    
    # Cancel the current intra-surface instructions (in case it didn't
    # clear itself).
    instructions_action_source.cancel_playback(
            playback,
            Sc.time.get_scaled_play_time())
    playback = null
    
    if !starts_next_edge:
        return
    
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
            if character.logs_verbose_navigator_events:
                _log("Bcktrck edge",
                        backtracking_edge.to_string(true),
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
        details: String,
        is_verbose := false) -> void:
    character._log(
            message,
            details,
            CharacterLogType.NAVIGATOR,
            is_verbose)


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
                    movement_params.friction_coeff_without_sideways_input,
                    surface.properties.friction_multiplier)
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
                    movement_params.collider,
                    true,
                    false)
    var end_position := PositionAlongSurfaceFactory \
            .create_position_offset_from_target_point(
                    end_target_point,
                    surface,
                    movement_params.collider,
                    true,
                    false)
    var backtracking_edge: IntraSurfaceEdge = \
            Su.movement.intra_surface_calculator.create(
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
                    movement_params.collider,
                    true,
                    true,
                    true)
            if !closest_jump_off_point.is_valid:
                continue
            
            var surface_to_air_edge := _calculate_surface_to_air_edge(
                    closest_jump_off_point, path.destination)
            if surface_to_air_edge == null:
                continue
            
            # We found an earlier position along an IntraSurfaceEdge that we
            # can jump from.
            # -   Update the end position of the IntraSurfaceEdge.
            # -   Record the new surface-to-air edge.
            # -   Remove the old following edges.
            edge.calculator.update_terminal(
                    edge,
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
                last_edge.calculator.update_terminal(
                        last_edge,
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
                edge.includes_extra_wall_land_horizontal_speed,
                edge)
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
                            0.004) and \
                    Sc.geometry.are_floats_equal_with_epsilon(
                            edge_with_trajectory.distance,
                            edge.distance,
                            1.2)
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
                        Su.movement.intra_surface_calculator \
                            .create_correction_interstitial(
                                edge.end_position_along_surface,
                                # TODO: Calculate a more accurate
                                #       surface-aligned value.
                                edge.velocity_end,
                                collision_params.movement_params))
                i += 1
                count += 1
        i += 1
