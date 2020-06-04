extends Reference
class_name Navigator

const NEARBY_SURFACE_DISTANCE_THRESHOLD := 160.0
const PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET := 1.0
const PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET := 1.0

var player
var graph: PlatformGraph
var surface_state: PlayerSurfaceState
var movement_params: MovementParams
var collision_params: CollisionCalcParams
var instructions_action_source: InstructionsActionSource
var air_to_surface_calculator: AirToSurfaceCalculator

var is_currently_navigating := false
var reached_destination := false
var current_destination: PositionAlongSurface
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var current_edge: Edge
var current_edge_index := -1
var current_playback: InstructionsPlayback
var actions_might_be_dirty := false

var navigation_state := PlayerNavigationState.new()

func _init( \
        player, \
        graph: PlatformGraph) -> void:
    self.player = player
    self.graph = graph
    self.surface_state = player.surface_state
    self.movement_params = player.movement_params
    self.collision_params = CollisionCalcParams.new( \
            Global.DEBUG_PARAMS, \
            Global.space_state, \
            movement_params, \
            graph.surface_parser)
    self.instructions_action_source = InstructionsActionSource.new(player, true)
    self.air_to_surface_calculator = AirToSurfaceCalculator.new()

# Starts a new navigation to the given destination.
func navigate_to_position(destination: PositionAlongSurface) -> bool:
    reset()
    
    var path: PlatformGraphPath
    if surface_state.is_grabbing_a_surface:
        var origin := PositionAlongSurface.new(surface_state.center_position_along_surface)
        path = graph.find_path( \
                origin, \
                destination)
    else:
        var origin := MovementUtils.create_position_without_surface(surface_state.center_position)
        var air_to_surface_edge := air_to_surface_calculator.find_a_landing_trajectory( \
                null, \
                collision_params, \
                graph.surfaces_set, \
                origin, \
                player.velocity, \
                destination, \
                null)
        if air_to_surface_edge != null:
            path = graph.find_path( \
                    air_to_surface_edge.end_position_along_surface, \
                    destination)
            if path != null:
                path.push_front(air_to_surface_edge)
    
    if path == null:
        # Destination cannot be reached from origin.
        print("CANNOT NAVIGATE TO TARGET: %s" % destination.to_string())
        return false
    else:
        # Destination can be reached from origin.
        
        _interleave_intra_surface_edges( \
                collision_params, \
                path)
        _optimize_edges_for_approach( \
                collision_params, \
                path, \
                player.velocity)
        
        var format_string_template := "STARTING PATH NAV:   %8.3ft; {" + \
            "\n\tdestination: %s," + \
            "\n\tpath: %s," + \
            "\n}"
        var format_string_arguments := [ \
                Global.elapsed_play_time_sec, \
                destination.to_string(), \
                path.to_string_with_newlines(1), \
            ]
        print(format_string_template % format_string_arguments)
        
        current_destination = destination
        current_path = path
        is_currently_navigating = true
        reached_destination = false
        
        _start_edge(0)
        
        return true

func _set_reached_destination() -> void:
    # FIXME: Assert that we are close enough to the destination position.
#    assert()
    
    if movement_params.forces_player_position_to_match_path_at_end:
        player.position = current_edge.end
    if movement_params.forces_player_velocity_to_zero_at_path_end and \
            current_edge.end_surface != null:
        match current_edge.end_surface.side:
            SurfaceSide.FLOOR, SurfaceSide.CEILING:
                player.velocity.x = 0.0
            SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                player.velocity.y = 0.0
            _:
                Utils.error("Invalid SurfaceSide")
    
    reset()
    reached_destination = true
    
    print("REACHED END OF PATH: %8.3ft" % [Global.elapsed_play_time_sec])

func reset() -> void:
    if current_path != null:
        previous_path = current_path
    
    current_destination = null
    current_path = null
    current_edge = null
    current_edge_index = -1
    is_currently_navigating = false
    reached_destination = false
    current_playback = null
    instructions_action_source.cancel_all_playback()
    actions_might_be_dirty = true
    navigation_state.reset()

func _start_edge(index: int) -> void:
    current_edge_index = index
    current_edge = current_path.edges[index]
    
    var format_string_template := "STARTING EDGE NAV:   %8.3ft; %s"
    var format_string_arguments := [ \
            Global.elapsed_play_time_sec, \
            current_edge.to_string_with_newlines(0), \
        ]
    print(format_string_template % format_string_arguments)
    
    if movement_params.forces_player_position_to_match_edge_at_start:
        player.position = current_edge.start
    if movement_params.forces_player_velocity_to_match_edge_at_start:
        player.velocity = current_edge.velocity_start
        surface_state.horizontal_acceleration_sign = 0
    
    current_edge.update_for_surface_state( \
            surface_state, \
            current_edge == current_path.edges.back())
    navigation_state.is_expecting_to_enter_air = current_edge.enters_air
    
    current_playback = instructions_action_source.start_instructions( \
            current_edge, \
            Global.elapsed_play_time_sec)
    
    # Some instructions could be immediately skipped, depending on runtime state, so this gives us
    # a change to move straight to the next edge.
    update(true)

# Updates navigation state in response to the current surface state.
func update(just_started_new_edge = false) -> void:
    actions_might_be_dirty = just_started_new_edge
    
    if !is_currently_navigating:
        return
    
    current_edge.update_navigation_state( \
            navigation_state, \
            surface_state, \
            current_playback, \
            just_started_new_edge)
    
    if navigation_state.just_interrupted_navigation:
        var interruption_type_label: String
        if navigation_state.just_left_air_unexpectedly:
            interruption_type_label = "navigation_state.just_left_air_unexpectedly"
        elif navigation_state.just_entered_air_unexpectedly:
            interruption_type_label = "navigation_state.just_entered_air_unexpectedly"
        else: # navigation_state.just_interrupted_by_user_action
            interruption_type_label = "navigation_state.just_interrupted_by_user_action"
        
        print("EDGE MVT INTERRUPTED:%8.3ft; %s" % \
                [Global.elapsed_play_time_sec, interruption_type_label])
        # FIXME: Add back in at some point...
#        navigate_to_nearest_surface(current_path.destination)
        reset()
    elif navigation_state.just_reached_end_of_edge:
        print("REACHED END OF EDGE: %8.3ft; %s" % \
                [Global.elapsed_play_time_sec, current_edge.name])
    else:
        # Continuing along an edge.
        if surface_state.is_grabbing_a_surface:
            # print("Moving along a surface along edge")
            pass
        else:
            # print("Moving through the air along an edge")
            # FIXME: Detect when position is too far from expected. Then maybe auto-correct it?
            pass
    
    if navigation_state.just_reached_end_of_edge:
        # FIXME: Assert that we are close enough to the destination position.
        # assert()
        
        # Cancel the current intra-surface instructions (in case it didn't clear itself).
        instructions_action_source.cancel_playback( \
                current_playback, \
                Global.elapsed_play_time_sec)
        
        # Check for the next edge to navigate.
        var next_edge_index := current_edge_index + 1
        var was_last_edge := current_path.edges.size() == next_edge_index
        if was_last_edge:
            var backtracking_edge := _possibly_backtrack_to_not_protrude_past_surface_end( \
                    movement_params, \
                    current_edge, \
                    player.position, \
                    player.velocity)
            if backtracking_edge == null:
                _set_reached_destination()
            else:
                var format_string_template := "INSRT CTR-PROTR EDGE:%8.3ft; %s"
                var format_string_arguments := [ \
                        Global.elapsed_play_time_sec, \
                        backtracking_edge.to_string_with_newlines(0), \
                    ]
                print(format_string_template % format_string_arguments)
                
                current_path.edges.push_back(backtracking_edge)
                _start_edge(next_edge_index)
        else:
            _start_edge(next_edge_index)

static func _possibly_backtrack_to_not_protrude_past_surface_end(
        movement_params: MovementParams, \
        current_edge: Edge, \
        current_position: Vector2, \
        current_velocity: Vector2) -> IntraSurfaceEdge:
    if movement_params.prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets and \
            !current_edge.is_backtracking_to_not_protrude_past_surface_end:
        var surface := current_edge.end_surface
        
        var position_after_coming_to_a_stop: Vector2
        if surface.side == SurfaceSide.FLOOR:
            var stopping_distance := MovementUtils.calculate_distance_to_stop_from_friction( \
                    movement_params, \
                    abs(current_velocity.x), \
                    movement_params.gravity_fast_fall, \
                    movement_params.friction_coefficient)
            var stopping_displacement := \
                    stopping_distance if \
                    current_velocity.x > 0.0 else \
                    -stopping_distance
            position_after_coming_to_a_stop = Vector2( \
                    current_position.x + stopping_displacement, \
                    current_position.y)
        else:
            # TODO: Add support for acceleration and friction along wall and ceiling surfaces.
            position_after_coming_to_a_stop = current_position
        
        var would_protrude_past_surface_end_after_coming_to_a_stop := false
        var end_target_point := Vector2.INF
        
        match surface.side:
            SurfaceSide.FLOOR:
                if position_after_coming_to_a_stop.x < surface.first_point.x + \
                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.first_point.x + \
                                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                    surface.first_point.y)
                elif position_after_coming_to_a_stop.x > surface.last_point.x - \
                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.last_point.x - \
                                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                    surface.last_point.y)
            SurfaceSide.LEFT_WALL:
                if position_after_coming_to_a_stop.y < surface.first_point.y + \
                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.first_point.x, \
                                    surface.first_point.y + \
                                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                elif position_after_coming_to_a_stop.y > surface.last_point.y - \
                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.last_point.x, \
                                    surface.last_point.y - \
                                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
            SurfaceSide.RIGHT_WALL:
                if position_after_coming_to_a_stop.y > surface.first_point.y - \
                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.first_point.x, \
                                    surface.first_point.y - \
                                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                elif position_after_coming_to_a_stop.y < surface.last_point.y + \
                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.last_point.x, \
                                    surface.last_point.y + \
                                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
            SurfaceSide.CEILING:
                if position_after_coming_to_a_stop.x > surface.first_point.x - \
                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.first_point.x - \
                                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                    surface.first_point.y)
                elif position_after_coming_to_a_stop.x < surface.last_point.x + \
                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                    would_protrude_past_surface_end_after_coming_to_a_stop = true
                    end_target_point = \
                            Vector2(surface.last_point.x + \
                                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                    surface.last_point.y)
            _:
                Utils.error("Invalid SurfaceSide")
        
        if would_protrude_past_surface_end_after_coming_to_a_stop:
            var start_position := MovementUtils.create_position_offset_from_target_point( \
                    current_position, \
                    surface, \
                    movement_params.collider_half_width_height, \
                    true)
            var end_position := MovementUtils.create_position_offset_from_target_point( \
                    end_target_point, \
                    surface, \
                    movement_params.collider_half_width_height, \
                    true)
            var backtracking_edge := IntraSurfaceEdge.new( \
                    start_position, \
                    end_position, \
                    current_velocity, \
                    movement_params)
            backtracking_edge.is_backtracking_to_not_protrude_past_surface_end = true
            return backtracking_edge
    
    return null

# Tries to update each jump edge to jump from the earliest point possible along the surface
# rather than from the safe end/closest point that was used at build-time when calculating
# possible edges.
# - This also updates start velocity when updating start position.
static func _optimize_edges_for_approach( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        velocity_start: Vector2) -> void:
    var movement_params := collision_params.movement_params
    
    # At runtime, after finding a path through build-time-calculated edges, try to optimize the
    # jump-off or land points of the edges to better account for the direction that the player will
    # be approaching the edge from. This produces more efficient and natural movement. The
    # build-time-calculated edge state would only use surface end-points or closest points. We also
    # take this opportunity to update start velocities to exactly match what is allowed from the
    # ramp-up distance along the edge, rather than either the fixed zero or max-speed value used
    # for the build-time-calculated edge state.
    
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
            assert(!(previous_edge is IntraSurfaceEdge) or !(current_edge is IntraSurfaceEdge))
            
            is_previous_edge_long_enough_to_be_worth_optimizing_jump_position = \
                    previous_edge.distance >= \
                    movement_params.min_intra_surface_distance_to_optimize_jump_for
            
            if is_previous_edge_long_enough_to_be_worth_optimizing_jump_position and \
                    previous_edge is IntraSurfaceEdge:
                current_edge.calculator.optimize_edge_jump_position_for_path( \
                        collision_params, \
                        path, \
                        i, \
                        previous_velocity_end_x, \
                        previous_edge, \
                        current_edge)
            
            previous_velocity_end_x = previous_edge.velocity_end.x
        
        # If we optimized the second edge, so that it can start from the same position that the
        # first, intra-surface, edge starts, then we can just remove the first, intra-surface,
        # edge.
        if path.edges.size() > 1 and \
                path.edges[0] is IntraSurfaceEdge and \
                Geometry.are_points_equal_with_epsilon( \
                        path.edges[0].start, \
                        path.edges[1].start, \
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
            assert(!(previous_edge is IntraSurfaceEdge) or !(current_edge is IntraSurfaceEdge))
            
            is_current_edge_long_enough_to_be_worth_optimizing_land_position = \
                    current_edge.distance >= \
                    movement_params.min_intra_surface_distance_to_optimize_jump_for
            
            if is_current_edge_long_enough_to_be_worth_optimizing_land_position and \
                    current_edge is IntraSurfaceEdge:
                previous_edge.calculator.optimize_edge_land_position_for_path( \
                        collision_params, \
                        path, \
                        i - 1, \
                        previous_edge, \
                        current_edge)
    
    if movement_params.prevents_path_end_points_from_protruding_past_surface_ends_with_extra_offsets:
        var last_edge: Edge = path.edges.back()
        if last_edge is IntraSurfaceEdge:
            var surface := last_edge.end_surface
            var end_position := last_edge.end_position_along_surface
            var target_point := Vector2.INF
            match surface.side:
                SurfaceSide.FLOOR:
                    if end_position.target_point.x < surface.first_point.x + \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2( \
                                surface.first_point.x + \
                                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                surface.first_point.y)
                    elif end_position.target_point.x > surface.last_point.x - \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2( \
                                surface.last_point.x - \
                                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                surface.last_point.y)
                SurfaceSide.LEFT_WALL:
                    if end_position.target_point.y < surface.first_point.y + \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2( \
                                surface.first_point.x, \
                                surface.first_point.y + \
                                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                    elif end_position.target_point.y > surface.last_point.y - \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2( \
                                surface.last_point.x, \
                                surface.last_point.y - \
                                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                SurfaceSide.RIGHT_WALL:
                    if end_position.target_point.y > surface.first_point.y - \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2( \
                                surface.first_point.x, \
                                surface.first_point.y - \
                                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                    elif end_position.target_point.y < surface.last_point.y + \
                            PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET:
                        target_point = Vector2( \
                                surface.last_point.x, \
                                surface.last_point.y + \
                                        PROTRUSION_PREVENTION_SURFACE_END_WALL_OFFSET)
                SurfaceSide.CEILING:
                    if end_position.target_point.x > surface.first_point.x - \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2( \
                                surface.first_point.x - \
                                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                surface.first_point.y)
                    elif end_position.target_point.x < surface.last_point.x + \
                            PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET:
                        target_point = Vector2( \
                                surface.last_point.x + \
                                        PROTRUSION_PREVENTION_SURFACE_END_FLOOR_OFFSET, \
                                surface.last_point.y)
                _:
                    Utils.error("Invalid SurfaceSide")
            
            if target_point != Vector2.INF:
                last_edge.update_terminal( \
                        false, \
                        target_point)

# Inserts extra intra-surface between any edges that land and then immediately jump from the same
# position, since the land position could be off due to movement error at runtime.
static func _interleave_intra_surface_edges( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath) -> void:
    # Insert extra intra-surface between any edges that land and then immediately jump from the
    # same position, since the land position could be off due to movement error at runtime.
    var i := 0
    var count := path.edges.size()
    var edge: Edge
    while i < count:
        edge = path.edges[i]
        # Check whether this edge lands on a surface from the air.
        if edge.surface_type == SurfaceType.AIR and edge.end_surface != null:
            # Since the surface lands on the surface from the air, there could be enough
            # movement error that we should move along the surface to the intended land position
            # before executing the next originally calculated edge (but don't worry about
            # IntraSurfaceEdges, since they'll end up moving to the correct spot anyway).
            if i + 1 < count and !(path.edges[i + 1] is IntraSurfaceEdge):
                path.edges.insert(i + 1, \
                        IntraSurfaceEdge.new( \
                                edge.end_position_along_surface, \
                                edge.end_position_along_surface, \
                                # TODO: Calculate a more accurate surface-aligned value.
                                edge.velocity_end, \
                                collision_params.movement_params))
                i += 1
                count += 1
        i += 1
