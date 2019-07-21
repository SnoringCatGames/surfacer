extends Reference
class_name PlatformGraphNavigator

var player # TODO: Add type back
var graph: PlatformGraph
var surface_state: PlayerSurfaceState
var surface_parser: SurfaceParser
var instructions_action_source: InstructionsActionSource

var _stopwatch: Stopwatch

var is_currently_navigating := false
var reached_destination := false
var current_path: PlatformGraphPath
var current_edge: PlatformGraphEdge
var current_edge_index := -1

var just_collided_unexpectedly := false
var just_entered_air_unexpectedly := false
var just_landed_on_expected_surface := false
var just_interrupted_navigation := false
var just_reached_end_of_intra_surface_edge := false

func _init(player, graph: PlatformGraph) -> void:
    self.player = player
    self.graph = graph
    self.surface_state = player.surface_state
    self.surface_parser = graph.surface_parser
    self.instructions_action_source = InstructionsActionSource.new(player)
    _stopwatch = Stopwatch.new()

# Starts a new navigation to the given destination.
func start_new_navigation(target: Vector2) -> bool:
    # FIXME: B: Remove
    assert(surface_state.is_grabbing_a_surface)
    
    var origin := surface_state.player_center_position_along_surface
    var destination := find_closest_position_on_a_surface(target, player)
    # FIXME: LEFT OFF HERE: -----------A
    # - Add support for an in-air origin and destination.
    # - Implement two new Edge sub-classes for these.
    var path := graph.find_path(origin, destination)
    
    if path == null:
        # Destination cannot be reached from origin.
        current_path = null
        current_edge = null
        current_edge_index = -1
        is_currently_navigating = false
        reached_destination = false
        return false
    else:
        # Destination can be reached from origin.
        current_path = path
        current_edge = current_path.edges[0]
        current_edge_index = 0
        is_currently_navigating = true
        reached_destination = false
        instructions_action_source.start_instructions(current_edge.instructions)
        return true

func reset() -> void:
    current_path = null
    current_edge_index = -1
    current_edge = null
    is_currently_navigating = false

# Updates player-graph state in response to the given new PlayerSurfaceState.
func update() -> void:
    if !is_currently_navigating:
        return
    
    var is_grabbed_surface_expected: bool = \
            surface_state.grabbed_surface == current_edge.end.surface
    var moving_along_intra_surface_edge := \
            surface_state.is_grabbing_a_surface and is_grabbed_surface_expected
    just_collided_unexpectedly = surface_state.just_left_air and \
            !is_grabbed_surface_expected and player.surface_state.collision_count > 0
    just_entered_air_unexpectedly = \
            surface_state.just_entered_air and !just_reached_end_of_intra_surface_edge
    just_landed_on_expected_surface = surface_state.just_left_air and \
            surface_state.grabbed_surface == current_edge.end.surface
    just_interrupted_navigation = just_collided_unexpectedly or just_entered_air_unexpectedly
    
    if moving_along_intra_surface_edge:
        var target_point: Vector2 = current_edge.end.target_point
        var was_less_than_end: bool
        var is_less_than_end: bool
        if surface_state.is_grabbing_wall:
            was_less_than_end = surface_state.previous_center_position.y < target_point.y
            is_less_than_end = surface_state.center_position.y < target_point.y
        else:
            was_less_than_end = surface_state.previous_center_position.x < target_point.x
            is_less_than_end = surface_state.center_position.x < target_point.x
        
        just_reached_end_of_intra_surface_edge = was_less_than_end != is_less_than_end
    else:
        just_reached_end_of_intra_surface_edge = false
    
    # FIXME: LEFT OFF HERE: ---------------------A
    # - Add support for cancelling a current instruction on InstructionsActionSource (for when
    #   we've reached the end of the intra-surface edge).
    # - Make sure current instructions and state are cancelled correctly in start_new_navigation,
    #   reset, and various cases below.
    # - Simplify some of the case-type calculations in this function to consider the sub-type of
    #   the current edge.
    # - Address the other edge-type cases in start_new_navigation above (don't just require start
    #   and end on surfaces).
    # - Implement the instruction-calculations for the other three edge sub-classes.
    
    if just_interrupted_navigation:
        print("Edge movement interrupted")
        
        # FIXME: Add back in at some point...
#        start_new_navigation(current_path.destination)
    
    elif just_reached_end_of_intra_surface_edge:
        print("Reached end of intra-surface edge")
        
        reached_destination = current_path.edges.size() == current_edge_index + 1
        if reached_destination:
            reset()
        else:
            current_edge_index += 1
            current_edge = current_path.edges[current_edge_index]
            
            # FIXME: Trigger next instruction set
    
    elif just_landed_on_expected_surface:
        print("Reached end of inter-surface edge")
        
        # FIXME: Detect when position is too far from expected.
        # FIXME: Start moving within the surface to the next edge start position.
        pass
    
    elif surface_state.is_grabbing_a_surface:
#        print("Moving along an intra-surface edge")
        
        # FIXME: Continue moving toward next edge.
        pass
    
    else: # Moving through the air.
#        print("Moving along an inter-surface edge")
        
        # FIXME: Detect when position is too far from expected.
        
        # The inter-surface-edge movement instruction set should continue executing.
        pass

# Finds the closest PositionAlongSurface to the given target point.
static func find_closest_position_on_a_surface(target: Vector2, player) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    var surface := get_closest_surface(target, player.possible_surfaces)
    position.match_surface_target_and_collider(surface, target, player.collider_half_width_height)
    return position

# Gets the closest surface to the given point.
static func get_closest_surface(target: Vector2, surfaces: Array) -> Surface:
    var closest_surface: Surface
    var closest_distance_squared: float
    var current_distance_squared: float
    
    closest_surface = surfaces[0]
    closest_distance_squared = \
            Geometry.get_distance_squared_from_point_to_polyline(target, closest_surface.vertices)
    
    for current_surface in surfaces:
        current_distance_squared = Geometry.distance_squared_from_point_to_rect(target, \
                current_surface.bounding_box)
        if current_distance_squared < closest_distance_squared:
            current_distance_squared = Geometry.get_distance_squared_from_point_to_polyline( \
                    target, current_surface.vertices)
            if current_distance_squared < closest_distance_squared:
                closest_distance_squared = current_distance_squared
                closest_surface = current_surface
    
    return closest_surface
