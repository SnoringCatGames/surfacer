extends Reference
class_name Navigator

const NEARBY_SURFACE_DISTANCE_THRESHOLD := 160.0

var player # TODO: Add type back
var graph: PlatformGraph
var global # TODO: Add type back
var surface_state: PlayerSurfaceState
var surface_parser: SurfaceParser
var instructions_action_source: InstructionsActionSource

var is_currently_navigating := false
var reached_destination := false
var current_path: PlatformGraphPath
var current_edge: Edge
var current_edge_index := -1
var current_edge_playback: InstructionsPlayback

var is_expecting_to_enter_air := false
var just_interrupted_navigation := false
var just_collided_unexpectedly := false
var just_entered_air_unexpectedly := false
var just_interrupted_by_user_action := false
var just_reached_end_of_edge := false
var just_reached_intra_surface_destination := false
var just_landed_on_expected_surface := false
var just_reached_in_air_destination := false

func _init(player, graph: PlatformGraph, global) -> void:
    self.player = player
    self.graph = graph
    self.global = global
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
                graph.find_a_landing_trajectory(origin, player.velocity, destination)
        if air_to_surface_edge != null:
            path = graph.find_path(air_to_surface_edge.end, destination)
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
        current_edge = current_path.edges[0]
        current_edge_index = 0
        is_currently_navigating = true
        reached_destination = false
        
        _start_edge(current_edge)
        
        return true

func _set_reached_destination() -> void:
    # FIXME: Assert that we are close enough to the destination position.
#    assert()
    
    reached_destination = true
    is_currently_navigating = false
    current_edge = null
    current_edge_index = -1
    current_edge_playback = null
    instructions_action_source.cancel_all_playback()

func reset() -> void:
    current_path = null
    current_edge = null
    current_edge_index = -1
    is_currently_navigating = false
    reached_destination = false
    current_edge_playback = null
    instructions_action_source.cancel_all_playback()
    is_expecting_to_enter_air = false
    just_interrupted_navigation = false
    just_collided_unexpectedly = false
    just_entered_air_unexpectedly = false
    just_interrupted_by_user_action = false
    just_reached_end_of_edge = false
    just_reached_intra_surface_destination = false
    just_landed_on_expected_surface = false
    just_reached_in_air_destination = false

func _start_edge(edge: Edge) -> void:
    var format_string_template := "STARTING EDGE NAVIGATION: %8.3f; %s"
    var format_string_arguments := [ \
            global.elapsed_play_time_sec, \
            edge.to_string_with_newlines(1), \
        ]
    print(format_string_template % format_string_arguments)

    # FIXME: LEFT OFF HERE: ------------------------A:
    # - Add and call a new edge.update_for_player_state(player) method.
    # - Implementation:
    #   - Use player position to determine whether to press left or right.
    #     - And change instructions object accordingly.
    #   - Set the player velocity to zero, if needed.
    
    current_edge_playback = instructions_action_source.start_instructions( \
            edge.instructions, global.elapsed_play_time_sec)
    is_expecting_to_enter_air = edge is InterSurfaceEdge or edge is SurfaceToAirEdge

# Updates player-graph state in response to the given new PlayerSurfaceState.
func update() -> void:
    if !is_currently_navigating:
        return
    
    _update_edge_navigation_state()
    
    # FIXME: A: Remove this, and instead update edge-calculations to support variable
    #           velocity_start_x values.
    if is_expecting_to_enter_air:
        player.velocity.x = 0.0
    
    if just_interrupted_navigation:
        var interruption_type_label: String
        if just_collided_unexpectedly:
            interruption_type_label = "just_collided_unexpectedly"
        elif just_entered_air_unexpectedly:
            interruption_type_label = "just_entered_air_unexpectedly"
        else: # just_interrupted_by_user_action
            interruption_type_label = "just_interrupted_by_user_action"
        
        print("Edge movement interrupted:%8.3f; %s" % \
                [global.elapsed_play_time_sec, interruption_type_label])
        # FIXME: Add back in at some point...
#        navigate_to_nearest_surface(current_path.destination)
        reset()
    elif just_reached_end_of_edge:
        var edge_type_label: String
        if just_reached_intra_surface_destination:
            assert(current_edge is IntraSurfaceEdge)
            edge_type_label = "intra-surface"
        elif just_landed_on_expected_surface:
            assert(current_edge is InterSurfaceEdge or current_edge is AirToSurfaceEdge)
            edge_type_label = \
                    "inter-surface" if current_edge is InterSurfaceEdge else "air-to-surface"
        elif just_reached_in_air_destination:
            assert(current_edge is SurfaceToAirEdge or current_edge is AirToAirEdge)
            edge_type_label = \
                    "surface-to-air" if current_edge is SurfaceToAirEdge else "air-to-air"
        
        print("Reached end of edge:      %8.3f; %s" % [global.elapsed_play_time_sec, edge_type_label])
    else:
        # Continuing along an edge.
        if surface_state.is_grabbing_a_surface:
            # print("Moving along a surface along edge")
            pass
        else:
            # print("Moving through the air along an edge")
            # FIXME: Detect when position is too far from expected. Then maybe auto-correct it?
            pass
    
    if just_reached_end_of_edge:
        # FIXME: Assert that we are close enough to the destination position.
        # assert()
        
        # Cancel the current intra-surface instructions (in case it didn't clear itself).
        instructions_action_source.cancel_playback(current_edge_playback)
        
        # Check for the next edge to navigate.
        var was_last_edge := current_path.edges.size() == current_edge_index + 1
        if was_last_edge:
            _set_reached_destination()
        else:
            current_edge_index += 1
            current_edge = current_path.edges[current_edge_index]
            _start_edge(current_edge)

func _update_edge_navigation_state() -> void:
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == current_edge.end.surface
    var is_moving_along_intra_surface_edge := \
            surface_state.is_grabbing_a_surface and is_grabbed_surface_expected
    # FIXME: E: Add support for walking into a wall and climbing up it.
    just_collided_unexpectedly = surface_state.just_left_air and \
            !is_grabbed_surface_expected and player.surface_state.collision_count > 0
    just_entered_air_unexpectedly = \
            surface_state.just_entered_air and !is_expecting_to_enter_air
    just_landed_on_expected_surface = surface_state.just_left_air and \
            surface_state.grabbed_surface == current_edge.end.surface
    just_interrupted_by_user_action = UserActionSource.get_is_some_user_action_pressed()
    just_interrupted_navigation = just_collided_unexpectedly or just_entered_air_unexpectedly or \
            just_interrupted_by_user_action
    
    if surface_state.just_entered_air:
        is_expecting_to_enter_air = false
    
    if is_moving_along_intra_surface_edge:
        var target_point: Vector2 = current_edge.end.target_point
        var was_less_than_end: bool
        var is_less_than_end: bool
        if surface_state.is_grabbing_wall:
            was_less_than_end = surface_state.previous_center_position.y < target_point.y
            is_less_than_end = surface_state.center_position.y < target_point.y
        else:
            was_less_than_end = surface_state.previous_center_position.x < target_point.x
            is_less_than_end = surface_state.center_position.x < target_point.x
        
        just_reached_intra_surface_destination = was_less_than_end != is_less_than_end
    else:
        just_reached_intra_surface_destination = false
    
    var is_moving_to_expected_in_air_destination: bool = \
            !surface_state.is_touching_a_surface and \
            (current_edge is SurfaceToAirEdge or \
            current_edge is AirToAirEdge)
    
    if is_moving_to_expected_in_air_destination:
        just_reached_in_air_destination = current_edge_playback.is_finished
    else:
        just_reached_in_air_destination = false
    
    just_reached_end_of_edge = \
            just_reached_intra_surface_destination or \
            just_landed_on_expected_surface or \
            just_reached_in_air_destination
