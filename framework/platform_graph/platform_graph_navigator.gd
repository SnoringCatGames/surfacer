extends Reference
class_name PlatformGraphNavigator

# FIXME: LEFT OFF HERE
# - MAKE get_nearby_surfaces MORE EFFICIENT! (force run it everyframe to ensure no lag)
#   - Scrap previous function; just use bounding box intersection (since I'm going to need to use
#     better logic for determining movement patterns anyway...)
# - Use navigator to test (print) when state changes occur and calculating:
#   - the current PositionOnSurface,
#   - which other surfaces are nearby,
#     - Will need to add that function for getting nearby surfaces
#   - then a start for implemententing EdgeInstructions
# - Add annotations for graph edges and navigator:
#   - 

# TODO: Adjust this
const SURFACE_CLOSE_DISTANCE_THRESHOLD = 512

var current_position: PositionOnSurface
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

func traverse_edge(start: PositionOnSurface, end: PositionOnSurface) -> void:
    # TODO
    pass

# A reference to the actual surface node, and a specification for position along that node.
# 
# FIXME: ACTUALLY, should the following be true? Not extending past might be both slightly more realistic as well as better for handling the offset I wanted to add before jumping landing near the edge anyway...
# Note: A position along a surface could actually extend past the edges of the surface. This is
# because a player's bounding box has non-zero width and height.
# 
# The position always indicates the center of the player's bounding box.
class PositionOnSurface extends Reference:
    func _init():
        pass
    
    # TODO
    # - A reference to the actual surface/Node
    # - Specification for position along that node.
    # - Node type

# Information for how to move from a start position on one surface to an end position on another
# surface.
class EdgeInstructions extends Reference:
    func _init():
        pass
    
    # TODO
    # - start_node_start_pos: PositionOnSurface
    # - end_node_end_pos: PositionOnSurface
    # - end_node_start_pos: PositionOnSurface
    # - end_node_end_pos: PositionOnSurface
    # - instruction set to move from start to end node
    # - instruction set to move within start node
    # - instruction set to move within end node
