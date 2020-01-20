extends Reference
class_name Navigator

const NEARBY_SURFACE_DISTANCE_THRESHOLD := 160.0

var player # TODO: Add type back
var graph: PlatformGraph
var global # TODO: Add type back
var space_state: Physics2DDirectSpaceState
var movement_params: MovementParams
var surface_state: PlayerSurfaceState
var surface_parser: SurfaceParser
var instructions_action_source: InstructionsActionSource

var is_currently_navigating := false
var reached_destination := false
var current_path: PlatformGraphPath
var current_edge: Edge
var current_edge_index := -1
var current_playback: InstructionsPlayback

var navigation_state := PlayerNavigationState.new()

func _init(player, graph: PlatformGraph, global) -> void:
    self.player = player
    self.graph = graph
    self.global = global
    self.space_state = global.space_state
    self.movement_params = player.movement_params
    self.surface_state = player.surface_state
    self.surface_parser = graph.surface_parser
    self.instructions_action_source = InstructionsActionSource.new(player, true)

# Starts a new navigation to the given destination.
func navigate_to_nearby_surface(target: Vector2, \
        distance_threshold := NEARBY_SURFACE_DISTANCE_THRESHOLD) -> bool:
    reset()
    
    var destination := SurfaceParser.find_closest_position_on_a_surface(target, player)
    
    if destination.target_point.distance_squared_to(target) > \
            distance_threshold * distance_threshold:
        # Target is too far from any surface.
        print("Target is too far from any surface")
        return false
    
    var path: PlatformGraphPath
    if surface_state.is_grabbing_a_surface:
        var origin := surface_state.center_position_along_surface
        path = graph.find_path(origin, destination)
    else:
        var origin := surface_state.center_position
        var air_to_surface_edge := \
                FallMovementUtils.find_a_landing_trajectory(space_state, movement_params, \
                        surface_parser, graph.surfaces_set, origin, player.velocity, \
                        destination)
        if air_to_surface_edge != null:
            path = graph.find_path(air_to_surface_edge.end_position_along_surface, destination)
            if path != null:
                path.push_front(air_to_surface_edge)
    
    if path == null:
        # Destination cannot be reached from origin.
        print("Cannot navigate to target: %s" % target)
        return false
    else:
        # Destination can be reached from origin.
        
        var format_string_template := "STARTING PATH NAVIGATION: %8.3f; {" + \
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
    
    reached_destination = true
    is_currently_navigating = false
    current_edge = null
    current_edge_index = -1
    current_playback = null
    instructions_action_source.cancel_all_playback()
    
    print("Reached end of path:      %8.3f" % [global.elapsed_play_time_sec])

func reset() -> void:
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
    
    var format_string_template := "STARTING EDGE NAVIGATION: %8.3f; %s"
    var format_string_arguments := [ \
            global.elapsed_play_time_sec, \
            current_edge.to_string_with_newlines(1), \
        ]
    print(format_string_template % format_string_arguments)
    
    if global.NAVIGATOR_STATE.forces_player_position_to_match_edge_at_start:
        player.position = current_edge.start
    if global.NAVIGATOR_STATE.forces_player_velocity_to_match_edge_at_start:
        player.velocity = Vector2.ZERO
    
    current_edge.update_for_surface_state(surface_state)
    
    current_playback = instructions_action_source.start_instructions( \
            current_edge, global.elapsed_play_time_sec)
    navigation_state.is_expecting_to_enter_air = \
            current_edge is InterSurfaceEdge or current_edge is SurfaceToAirEdge

# Updates navigation state in response to the current surface state.
func update() -> void:
    if !is_currently_navigating:
        return
    
    current_edge.update_navigation_state( \
            navigation_state, surface_state, current_playback)
    
    # FIXME: A: Remove this, and instead update edge-calculations to support variable
    #           velocity_start_x values.
    if navigation_state.is_expecting_to_enter_air:
        player.velocity.x = 0.0
    
    if navigation_state.just_interrupted_navigation:
        var interruption_type_label: String
        if navigation_state.just_left_air_unexpectedly:
            interruption_type_label = "navigation_state.just_left_air_unexpectedly"
        elif navigation_state.just_entered_air_unexpectedly:
            interruption_type_label = "navigation_state.just_entered_air_unexpectedly"
        else: # navigation_state.just_interrupted_by_user_action
            interruption_type_label = "navigation_state.just_interrupted_by_user_action"
        
        print("Edge movement interrupted:%8.3f; %s" % \
                [global.elapsed_play_time_sec, interruption_type_label])
        # FIXME: Add back in at some point...
#        navigate_to_nearest_surface(current_path.destination)
        reset()
    elif navigation_state.just_reached_end_of_edge:
        print("Reached end of edge:      %8.3f; %s" % \
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
        instructions_action_source.cancel_playback(current_playback)
        
        # Check for the next edge to navigate.
        var next_edge_index := current_edge_index + 1
        var was_last_edge := current_path.edges.size() == next_edge_index
        if was_last_edge:
            _set_reached_destination()
        else:
            _start_edge(next_edge_index)
