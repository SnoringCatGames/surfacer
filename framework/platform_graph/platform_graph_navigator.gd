extends Reference
class_name PlatformGraphNavigator

# FIXME:
# - MAKE get_nearby_surfaces MORE EFFICIENT? (force run it everyframe to ensure no lag)
#   - Scrap previous function; just use bounding box intersection (since I'm going to need to use
#     better logic for determining movement patterns anyway...)
#   - Actually, maybe don't worry too much, because this is actually only run at the start.

# TODO: Adjust this
const SURFACE_CLOSE_DISTANCE_THRESHOLD = 512

#var current_position: PositionAlongSurface
# Array<Surface>
var nearby_surfaces: Array

var player # FIXME: Add type back
var surface_state: PlayerSurfaceState
var nodes: PlatformGraphNodes
var edges: PlatformGraphEdges
var _stopwatch: Stopwatch

func _init(player, graph: PlatformGraph) -> void:
    self.player = player
    surface_state = player.surface_state
    nodes = graph.nodes
    edges = graph.edges[player.player_name]
    _stopwatch = Stopwatch.new()

# Updates player-graph state in response to the given new PlayerSurfaceState.
func update() -> void:
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

func calculate_grabbed_surface(surface_state: PlayerSurfaceState) -> Surface:
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord( \
            surface_state.grab_position_tile_map_coord, surface_state.grabbed_tile_map)
    return nodes.get_surface_for_tile(surface_state.grabbed_tile_map, tile_map_index, \
            surface_state.grabbed_side)

func find_path(start_node: PoolVector2Array, end_node: PoolVector2Array):
    # TODO
    pass

#func traverse_edge(start: PositionAlongSurface, end: PositionAlongSurface) -> void:
#    # TODO
#    pass
