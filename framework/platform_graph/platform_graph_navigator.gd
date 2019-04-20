extends Reference
class_name PlatformGraphNavigator

# TODO: Adjust this
const SURFACE_CLOSE_DISTANCE_THRESHOLD = 512

var player # TODO: Add type back
var surface_state: PlayerSurfaceState
var nodes: PlatformGraphNodes
var edges: PlatformGraphEdges

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
var just_reached_start_of_edge := false

# FIXME: Remove
# Array<Surface>
var nearby_surfaces: Array

func _init(player, graph: PlatformGraph) -> void:
    self.player = player
    surface_state = player.surface_state
    nodes = graph.nodes
    edges = graph.edges[player.player_name]
    _stopwatch = Stopwatch.new()

# Starts a new navigation to the given destination.
func start_new_navigation(target: Vector2) -> void:
    assert(surface_state.is_grabbing_a_surface) # FIXME: Remove
    
    var origin := surface_state.player_center_position_along_surface
    var destination := _find_closest_position_in_graph(target)
    var path := _calculate_path(origin, destination)
    
    current_path = path
    current_edge_index = 0
    current_edge = current_path.edges[current_edge_index]
    is_currently_navigating = true
    reached_destination = false

func reset() -> void:
    current_path = null
    current_edge_index = -1
    current_edge = null
    is_currently_navigating = false

# Updates player-graph state in response to the given new PlayerSurfaceState.
func update() -> void:
    if !is_currently_navigating:
        return
    
    var is_grabbed_surface_expected := \
            surface_state.grabbed_surface == current_edge.end.surface
    just_collided_unexpectedly = \
            !is_grabbed_surface_expected and player.get_slide_count() > 0
    just_entered_air_unexpectedly = \
            surface_state.just_entered_air and !just_reached_start_of_edge
    just_landed_on_expected_surface = surface_state.just_left_air and \
            surface_state.grabbed_surface == current_edge.end.surface
    just_interrupted_navigation = just_collided_unexpectedly or just_entered_air_unexpectedly
    # FIXME: Add logic to detect when we've reached the target PositionAlongSurface when moving within node.
    just_reached_start_of_edge = false
    
    if just_interrupted_navigation:
        print("PlatformGraphNavigator: just_interrupted_navigation")
        
        # Re-calculate navigation to the same destination.
        var destination = current_path.end_instructions_destination if \
                current_path.has_end_instructions else \
                current_path.surface_destination.target_point
#        start_new_navigation(destination) # FIXME: Add back in after implementing edge calculations and executions
    
    elif just_reached_start_of_edge:
        print("PlatformGraphNavigator: just_reached_start_of_edge")
        
        reached_destination = current_path.edges.size() == current_edge_index + 1
        if reached_destination:
            reset()
        else:
            current_edge_index += 1
            current_edge = current_path.edges[current_edge_index]
            
            # FIXME: Trigger next instruction set
    
    elif just_landed_on_expected_surface:
        print("PlatformGraphNavigator: just_landed_on_expected_surface")
        
        # FIXME: Detect when position is too far from expected.
        # FIXME: Start moving within the surface to the next edge start position.
        pass
    
    elif surface_state.is_grabbing_a_surface:
        print("PlatformGraphNavigator: Moving along a surface")
        
        # FIXME: Continue moving toward next edge.
        pass
    
    else: # Moving through the air.
        print("PlatformGraphNavigator: Moving through the air")
        
        # FIXME: Detect when position is too far from expected.
        # FIXME: Continue executing movement instruction set.
        pass
    
    # FIXME: Remove
    if surface_state.is_grabbing_a_surface:
        if surface_state.just_changed_surface:
            _stopwatch.start()
            print("get_nearby_surfaces...")
            nearby_surfaces = nodes.get_nearby_surfaces(surface_state.grabbed_surface, \
                    SURFACE_CLOSE_DISTANCE_THRESHOLD)
            print("get_nearby_surfaces duration: %sms" % _stopwatch.stop())
    else:
        nearby_surfaces = []

# Finds the Surface the corresponds to the given PlayerSurfaceState.
func calculate_grabbed_surface(surface_state: PlayerSurfaceState) -> Surface:
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord( \
            surface_state.grab_position_tile_map_coord, surface_state.grabbed_tile_map)
    return nodes.get_surface_for_tile(surface_state.grabbed_tile_map, tile_map_index, \
            surface_state.grabbed_side)

func _calculate_path(origin: PositionAlongSurface, \
        destination: PositionAlongSurface) -> PlatformGraphPath:
    var edges := []
    # FIXME: Remove
    var edge := PlatformGraphEdge.new(origin, destination, [])
    edges.push_back(edge)
    # FIXME: Use a A* to find the edges.
    return PlatformGraphPath.new(origin, destination, edges)

# Finds the closest PositionAlongSurface to the given target point.
func _find_closest_position_in_graph(target: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    var surface := nodes.get_closest_surface(target)
    position.match_surface_target_and_collider(surface, target, player.collider)
    return position
