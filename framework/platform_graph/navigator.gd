extends Reference
class_name Navigator

const NEARBY_SURFACE_DISTANCE_THRESHOLD := 160.0

var player # TODO: Add type back
var graph: PlatformGraph
var global # TODO: Add type back
var surface_state: PlayerSurfaceState
var collision_params: CollisionCalcParams
var instructions_action_source: InstructionsActionSource

var is_currently_navigating := false
var reached_destination := false
var previous_path: PlatformGraphPath
var current_path: PlatformGraphPath
var current_edge: Edge
var current_edge_index := -1
var current_playback: InstructionsPlayback

var navigation_state := PlayerNavigationState.new()

func _init(player, graph: PlatformGraph, global) -> void:
    self.player = player
    self.graph = graph
    self.global = global
    self.surface_state = player.surface_state
    self.collision_params = CollisionCalcParams.new( \
            Global.DEBUG_STATE, global.space_state, player.movement_params, graph.surface_parser)
    self.instructions_action_source = InstructionsActionSource.new(player, true)

# Starts a new navigation to the given destination.
func navigate_to_nearby_surface(target: Vector2, \
        distance_threshold := NEARBY_SURFACE_DISTANCE_THRESHOLD) -> bool:
    reset()
    
    var destination := SurfaceParser.find_closest_position_on_a_surface(target, player)
    
    if destination.target_point.distance_squared_to(target) > \
            distance_threshold * distance_threshold:
        # Target is too far from any surface.
        print("TARGET IS TOO FAR FROM ANY SURFACE")
        return false
    
    var path: PlatformGraphPath
    if surface_state.is_grabbing_a_surface:
        var origin := PositionAlongSurface.new(surface_state.center_position_along_surface)
        path = graph.find_path(origin, destination)
    else:
        var origin := surface_state.center_position
        var air_to_surface_edge := FallMovementUtils.find_a_landing_trajectory( \
                collision_params, graph.surfaces_set, origin, player.velocity, destination)
        if air_to_surface_edge != null:
            path = graph.find_path(air_to_surface_edge.end_position_along_surface, destination)
            if path != null:
                path.push_front(air_to_surface_edge)
    
    if path == null:
        # Destination cannot be reached from origin.
        print("CANNOT NAVIGATE TO TARGET: %s" % target)
        return false
    else:
        # Destination can be reached from origin.
        
        _interleave_intra_surface_edges(collision_params, path)
        _optimize_edges_for_approach(collision_params, path, player.velocity)
        
        var format_string_template := "STARTING PATH NAV:   %8.3ft; {" + \
            "\n\tdestination: %s," + \
            "\n\tpath: %s," + \
            "\n}"
        var format_string_arguments := [ \
                global.elapsed_play_time_sec, \
                target, \
                path.to_string_with_newlines(1), \
            ]
        print(format_string_template % format_string_arguments)
        
        current_path = path
        is_currently_navigating = true
        reached_destination = false
        
        _start_edge(0)
        
        return true

func _set_reached_destination() -> void:
    # FIXME: Assert that we are close enough to the destination position.
#    assert()
    
    reset()
    reached_destination = true
    
    print("REACHED END OF PATH: %8.3ft" % [global.elapsed_play_time_sec])

func reset() -> void:
    if current_path != null:
        previous_path = current_path
    
    current_path = null
    current_edge = null
    current_edge_index = -1
    is_currently_navigating = false
    reached_destination = false
    current_playback = null
    instructions_action_source.cancel_all_playback()
    navigation_state.reset()

func _start_edge(index: int) -> void:
    current_edge_index = index
    current_edge = current_path.edges[index]
    
    var format_string_template := "STARTING EDGE NAV:   %8.3ft; %s"
    var format_string_arguments := [ \
            global.elapsed_play_time_sec, \
            current_edge.to_string_with_newlines(0), \
        ]
    print(format_string_template % format_string_arguments)
    
    if player.movement_params.forces_player_position_to_match_edge_at_start:
        player.position = current_edge.start
    if player.movement_params.forces_player_velocity_to_match_edge_at_start:
        player.velocity = current_edge.velocity_start
        surface_state.horizontal_acceleration_sign = 0
    
    current_edge.update_for_surface_state(surface_state)
    navigation_state.is_expecting_to_enter_air = current_edge.enters_air
    
    current_playback = instructions_action_source.start_instructions( \
            current_edge, global.elapsed_play_time_sec)
    
    # Some instructions could be immediately skipped, depending on runtime state, so this gives us
    # a change to move straight to the next edge.
    update()

# Updates navigation state in response to the current surface state.
func update() -> void:
    if !is_currently_navigating:
        return
    
    current_edge.update_navigation_state( \
            navigation_state, surface_state, current_playback)
    
    if navigation_state.just_interrupted_navigation:
        var interruption_type_label: String
        if navigation_state.just_left_air_unexpectedly:
            interruption_type_label = "navigation_state.just_left_air_unexpectedly"
        elif navigation_state.just_entered_air_unexpectedly:
            interruption_type_label = "navigation_state.just_entered_air_unexpectedly"
        else: # navigation_state.just_interrupted_by_user_action
            interruption_type_label = "navigation_state.just_interrupted_by_user_action"
        
        print("EDGE MVT INTERRUPTED:%8.3ft; %s" % \
                [global.elapsed_play_time_sec, interruption_type_label])
        # FIXME: Add back in at some point...
#        navigate_to_nearest_surface(current_path.destination)
        reset()
    elif navigation_state.just_reached_end_of_edge:
        print("REACHED END OF EDGE: %8.3ft; %s" % \
                [global.elapsed_play_time_sec, current_edge.name])
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
        instructions_action_source.cancel_playback(current_playback, global.elapsed_play_time_sec)
        
        # Check for the next edge to navigate.
        var next_edge_index := current_edge_index + 1
        var was_last_edge := current_path.edges.size() == next_edge_index
        if was_last_edge:
            _set_reached_destination()
        else:
            _start_edge(next_edge_index)

# Tries to update each jump edge to jump from the earliest point possible along the surface
# rather than from the safe end/closest point that was used at build-time when calculating
# possible edges.
# - This also updates start velocity when updating start position.
static func _optimize_edges_for_approach(collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, velocity_start: Vector2) -> void:
    var movement_params := collision_params.movement_params
    
    ###############################################################################################
    # Record some extra debug state when we're limiting calculations to a single edge.
    var in_debug_mode: bool = collision_params.debug_state.in_debug_mode and \
            collision_params.debug_state.has("limit_parsing") and \
            collision_params.debug_state.limit_parsing.has("edge") != null
    ###############################################################################################
    
    if movement_params.optimizes_edge_jump_offs_at_run_time:
        # At runtime, after finding a path through build-time-calculated edges, try to optimize the
        # jump-off points of the edges to better account for the direction that the player will be
        # approaching the edge from. This produces more efficient and natural movement. The
        # build-time-calculated edge state would only use surface end-points or closest points. We
        # also take this opportunity to update start velocities to exactly match what is allowed
        # from the ramp-up distance along the edge, rather than either the fixed zero or max-speed
        # value used for the build-time-calculated edge state.
        
        var current_edge: Edge
        var next_edge: Edge
        var is_moving_from_intra_surface_to_jump: bool
        var is_moving_from_intra_surface_to_fall_off_wall: bool
        var is_edge_long_enough_to_be_worth_optimizing: bool
        var previous_velocity_end_x := velocity_start.x
        
        for i in range(path.edges.size() - 1):
            current_edge = path.edges[i]
            next_edge = path.edges[i + 1]
            
            is_edge_long_enough_to_be_worth_optimizing = current_edge.distance >= \
                    movement_params.min_intra_surface_distance_to_optimize_jump_for
            
            if is_edge_long_enough_to_be_worth_optimizing:
                is_moving_from_intra_surface_to_jump = \
                        current_edge is IntraSurfaceEdge and \
                        next_edge is JumpFromSurfaceToSurfaceEdge
                is_moving_from_intra_surface_to_fall_off_wall = \
                        current_edge is IntraSurfaceEdge and \
                        next_edge is FallFromWallEdge
                
                if is_moving_from_intra_surface_to_jump:
                    JumpFromSurfaceToSurfaceCalculator.optimize_edge_for_approach( \
                            collision_params, path, i + 1, previous_velocity_end_x, current_edge, \
                            next_edge, in_debug_mode)
                elif is_moving_from_intra_surface_to_fall_off_wall:
                    FallFromWallCalculator.optimize_edge_for_approach(collision_params, path, \
                            i + 1, previous_velocity_end_x, current_edge, next_edge, in_debug_mode)
            
            previous_velocity_end_x = current_edge.velocity_end.x

# Inserts extra intra-surface between any edges that land and then immediately jump from the same
# position, since the land position could be off due to movement error at runtime.
static func _interleave_intra_surface_edges(collision_params: CollisionCalcParams, \
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
