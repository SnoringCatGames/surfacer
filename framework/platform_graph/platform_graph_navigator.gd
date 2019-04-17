extends Reference
class_name PlatformGraphNavigator

# TODO: Adjust this
const SURFACE_CLOSE_DISTANCE_THRESHOLD = 512

var player # FIXME: Add type back
var surface_state: PlayerSurfaceState
var nodes: PlatformGraphNodes
var edges: PlatformGraphEdges

var _stopwatch: Stopwatch

var is_currently_navigating := false
var current_path: PlatformGraphPath
var current_edge_index: int

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
func start_new_navigation(destination: PositionAlongSurface) -> void:
    # FIXME
    pass

# Finds the closest PositionAlongSurface to the given target point.
func find_closest_position(target: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    # FIXME
    return position

# Updates player-graph state in response to the given new PlayerSurfaceState.
func update() -> void:
    # FIXME: LEFT OFF HERE:
    # - Finish match_surface_target_and_collider
    # - Add logic to initiate next walk/climb on surface once we've landed on the desired surface.
    # - Add logic to initiate next jump when we've reached the target PositionAlongSurface when moving within node.
    # - Add logic to walk/climb to target PositionAlongSurface.
    # - Add logic to detect when we've reached the target PositionAlongSurface when moving within node.
    # - Add logic to inform the player when we've reached the final goal position.
    # - Add logic to the Player to detect unexpected interruptions:
    #   - Hit a surface (inform the navigator; navigator returns false if unexpected; player starts a new navigation)
    #   - Hit by anything else (figure out response depending on collider; at least cancel previous navigation)
    #   - Want to start a new navigation for whatever reason.
    # - Add a check when current position/movement/state is further than our tolerance away from the expected state for the current path.
    #   - Throw an error.
    # - Add logic to automatically self-correct to the expected position/movement/state sometimes...
    #   - When? Each frame? Only when we're further away than our tolerance allows?
    
    
    
    
    # FIXME
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

func _calculate_path(origin: PositionAlongSurface, destination: PositionAlongSurface) -> PlatformGraphPath:
    var edges := []
    # FIXME
    return PlatformGraphPath.new(origin, destination, edges)
