# A PlatfromGraph is specific to a given player type. This is important since different players
# have different jump parameters and can reach different surfaces, so the edges in the graph will
# be different for each player.
extends Reference
class_name PlatformGraph

const PriorityQueue := preload("res://framework/utils/priority_queue.gd")
const IntraSurfaceEdge := preload("res://framework/platform_graph/edge/intra_surface_edge.gd")

# FIXME: LEFT OFF HERE: Master list:
# 
# - Finish everything in JumpFromPlatformMovement (edge calculations, including movement constraints from interfering surfaces)
# - Finish/polish fallable surfaces calculations (and remove old obsolete functions)
# 
# - Use FallFromAirMovement
# - Use PlayerMovement.get_max_upward_distance and PlayerMovement.get_max_horizontal_distance
# - Add logic to use path.start_instructions when we start a navigation while the player isn't on a surface.
# - Add logic to use path.end_instructions when the destination is far enough from the surface AND an optional
#     should_jump_to_reach_destination parameter is provided.
# 
# - Add support for creating Edge.
# - Add support for executing Edge.
# - Add annotations for the whole edge set.
# 
# - Implement get_all_edges_from_surface for jumping.
# - Add annotations for the actual trajectories that are defined by Edge.
#   - These will be stored on PlayerInstructions.
#   - Also render annotations for the constraints that were used (also stored on PlayerInstructions).
# - Add annotations that draw the recent path that the player actually moved.
# - Add annotations for rendering some basic navigation mode info for the CP:
#   - Mode name
#   - Current "input" (UP, LEFT, etc.)?
#   - The entirety of the current instruction-set being run?
# - A*-search: Add support for actually navigating end-to-end to a given target point.
#   - Will need to consider the "weight" for moving along a surface from a previous edge's land to
#     the potential next edge's jump.
# - Add annotations for just the path that the navigator is currently using.
# - Test out the accuracy of edge traversal actually matching up to our pre-calculated trajectories.
# 
# - Add logic to check for obvious surfaces that interfere with an edge trajectory (prefer false
#   negatives over false positives).
# 
# - Add logic to emulate/test/ray-trace a Player's movement across an edge. This should help with
#   annotations (both path and boundaries) and precise detection for interfering surfaces.
# 
# - Add logic to consider a minimum movement distance, since jumping from floors or walls gives a
#   set minimum displacement. 
# 
# - Add logic to start edge traversal from the earliest possible PositionAlongSurface (given the
#   previous/inital/landing PositionAlongSurface), rather than from whatever pre-calculated
#   PositionAlongSurface was used to determine whether the edge is possible.
# 
# - Add logic to test execution of TestPlayer movement over _every_ edge in a complex, hand-made
#   test level.
#   - Make sure that the player hits the correct destination surface without hitting any other
#     surface on-route.
#   - Also test that the player lands on the destination within a threshold of the expected
#     position.
#   - Will need to figure out how to emulate/manipulate time deltas for the test environment...
# 
# - Add logic to automatically self-correct to the expected position/movement/state sometimes...
#   - When? Each frame? Only when we're further away than our tolerance allows?
# 
# - Add support for actually considering the discrete physics time steps rather than assuming
#   continuous integration?
#   - OR, add support for fudging it?
#     - I could calculate and emulate all of this as previously planned to be realistic and use
#       the same rules as a HumanPlayer; BUT, then actually adjust the movement to matchup with
#       the expected pre-calculated result (so, actually, not really run the instructions set at
#       all?)
#     - It's probably at least worth adding an optional mode that does this and comparing the
#       performance.
#     - Or would something like a GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION (~0.9985?)
#       param fix things enough?
# 
# - Refactor PlayerMovement classes, so that whether the start and end posiition is on a platform
#   or in the air is configuration that JumpFromPlatformMovement handles directly, rather than
#   relying on a separate FallFromAir class?
# - Add support for including walls in our navigation.
# - Add support for other PlayerMovement sub-classes:
#   - JumpFromWallMovement
#   - FallFromPlatformMovement
#   - FallFromWallMovement
# - Add support for other jump aspects:
#   - Fast fall
#   - Variable jump height
#   - Double jump
#   - Horizontal acceleration?
# 
# - Update the pre-configured Input Map in Project Settings to use more semantic keys instead of just up/down/etc.
# - Document in a separate markdown file exactly which Input Map keys this framework depends on.
# 
# - MAKE get_nearby_surfaces MORE EFFICIENT? (force run it everyframe to ensure no lag)
#   - Scrap previous function; just use bounding box intersection (since I'm going to need to use
#     better logic for determining movement patterns anyway...)
#   - Actually, maybe don't worry too much, because this is actually only run at the start.
# 
# - Add logic to Player when calculating touched edges to check that the collider is a stationary TileMap object
# 
# - Figure out how to configure input names/mappings (or just add docs specifying that the
#   consumer must use these input names?)
# - Test exporting to HTML5.
# - Start adding networking support.
# - Finish adding tests.
# 
# - Add an early-cutoff mechanism to A* for paths that deviate too far from straight-line.
#   Otherwise, it will check every connecected surface before knowing that a destination cannot be
#   reached.
#   - Or look at number of surfaces visited instead of straight-line deviation?
#   - Cons:
#     - Can miss valid paths if they deviate too far.
# - OR, use djikstra's algorithm, and always store every path to/from every other surface?
#   - Cons:
#     - Takes more space (maybe ok?).
#     - Too expensive if the map ever changes dynamically.
#       - Unless I have a way of localizing changes.

const CLUSTER_CELL_SIZE := 0.5
const CLUSTER_CELL_HALF_SIZE := CLUSTER_CELL_SIZE * 0.5

var surface_parser: SurfaceParser
# Array<Surface>
var surfaces: Array
# Dictionary<Surface, Array<PositionAlongSurface>>
var surfaces_to_nodes: Dictionary
# Dictionary<PositionAlongSurface, Dictionary<Edge>>
var nodes_to_edges: Dictionary

func _init(surface_parser: SurfaceParser, space_state: Physics2DDirectSpaceState, \
        player_info: PlayerTypeConfiguration) -> void:
    self.surface_parser = surface_parser
    
    # Store the subset of surfaces that this player type can interact with.
    self.surfaces = surface_parser.get_subset_of_surfaces( \
            player_info.movement_params.can_grab_walls, \
            player_info.movement_params.can_grab_ceilings, \
            player_info.movement_params.can_grab_floors)
    
    self.surfaces_to_nodes = {}
    self.nodes_to_edges = {}
    
    _calculate_nodes_and_edges(space_state, surface_parser, surfaces, player_info)

# Uses A* search.
# TODO: Add an early-cutoff mechanism for paths that deviate too far from straight-line. Otherwise, this will check every connecected surface before knowing that a destination cannot be reached.
func find_path(origin: PositionAlongSurface, \
        destination: PositionAlongSurface) -> PlatformGraphPath:
    var origin_surface := origin.surface
    var destination_surface := destination.surface
    
    if origin_surface == destination_surface:
        # If the we are simply trying to get to a different position on the same surface, then we
        # don't need A*.
        var edges := [IntraSurfaceEdge.new(origin, destination)]
        return PlatformGraphPath.new(edges)
    
    var frontier := PriorityQueue.new()
    var node_to_previous_node := {}
    node_to_previous_node[origin] = null
    var nodes_to_weights := {}
    nodes_to_weights[origin] = 0.0
    
    var nodes_to_edges_for_current_node: Dictionary
    var next_edge: Edge
    var current_node: PositionAlongSurface
    var current_weight: float
    var next_node: PositionAlongSurface
    var new_weight: float
    var heuristic_weight: float
    var priority: float
    
    # Record temporary edges from the origin to each node on the origin's surface.
    for next_node in surfaces_to_nodes[origin_surface]:
        # Record the path to this node.
        node_to_previous_node[next_node] = origin
        
        # Record this node's weight.
        new_weight = origin.target_point.distance_squared_to(next_node.target_point)
        nodes_to_weights[next_node] = new_weight
        
        # Add this node to the frontier with a priority.
        priority = new_weight
        frontier.insert(priority, next_node)
    
    # Determine the cheapest path.
    while !frontier.is_empty:
        current_node = frontier.remove_root()
        current_weight = nodes_to_weights[current_node]
        
        if current_node == destination:
            break
        
        if current_node.surface == destination_surface:
            # Record a temporary edge to the destination from this current_node.
            
            next_node = destination
            new_weight = current_weight + \
                    current_node.target_point.distance_squared_to(destination.target_point)
            
            if !nodes_to_weights.has(next_node) or new_weight < nodes_to_weights[next_node]:
                # We found a new or cheaper path to this next node, so record it.
                
                # Record the path to this node.
                node_to_previous_node[next_node] = current_node
                
                # Record this node's weight.
                nodes_to_weights[next_node] = new_weight
                
                # Add this node to the frontier with a priority.
                priority = new_weight
                frontier.insert(priority, next_node)
        
            continue
        
        # Iterate through each current neighbor node, and add record their weights, paths, and
        # priorities.
        nodes_to_edges_for_current_node = nodes_to_edges[current_node]
        for next_node in nodes_to_edges_for_current_node:
            next_edge = nodes_to_edges_for_current_node[next_node]
            new_weight = current_weight + next_edge.weight
            
            if !nodes_to_weights.has(next_node) or new_weight < nodes_to_weights[next_node]:
                # We found a new or cheaper path to this next node, so record it.
                
                # Record the path to this node.
                node_to_previous_node[next_node] = current_node
                
                # Record this node's weight.
                nodes_to_weights[next_node] = new_weight
                heuristic_weight = next_node.target_point.distance_squared_to(destination.target_point)
                
                # Add this node to the frontier with a priority.
                priority = new_weight + heuristic_weight
                frontier.insert(priority, next_node)
    
    # Collect the edges for the cheapest path.
    
    var edges := []
    current_node = destination
    var previous_node: PositionAlongSurface = node_to_previous_node.get(current_node)
    
    if previous_node == null:
        # The destination cannot be reached form the origin.
        return null
    
    while previous_node != null:
        if node_to_previous_node[previous_node] == null or edges.empty():
            # The first and last edge are temporary and extend from/to the origin/destination,
            # which are not aligned with normal node positions.
            next_edge = IntraSurfaceEdge.new(previous_node, current_node)
        else:
            next_edge = nodes_to_edges[previous_node][current_node]
        
        assert(next_edge != null)
        
        edges.push_front(next_edge)
        current_node = previous_node
        previous_node = node_to_previous_node.get(previous_node)
    
    assert(!edges.empty())
    
    return PlatformGraphPath.new(edges)

# Calculate and store the edges between surface nodes that this player type can traverse.
func _calculate_nodes_and_edges(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, surfaces: Array, \
        player_info: PlayerTypeConfiguration) -> void:
    # Calculate all inter-surface edges.
    var surfaces_to_edges := {}
    for movement_type in player_info.movement_types:
        if movement_type.can_traverse_edge:
            for surface in surfaces:
                # FIXME: Comment out when writing tests
#                pass
                # FIXME: LEFT OFF HERE: DEBUGGING: Remove
                if player_info.name == "cat":
                    # Calculate the inter-surface edges.
                    surfaces_to_edges[surface] = movement_type.get_all_edges_from_surface(space_state, surface_parser, surface)
    
    # Dedup all edge-end positions (aka, nodes).
    var grid_cell_to_node := {}
    for surface in surfaces_to_edges:
        for edge in surfaces_to_edges[surface]:
            edge.start = _dedup_node(edge.start, grid_cell_to_node)
            edge.end = _dedup_node(edge.end, grid_cell_to_node)
    
    # Record mappings from surfaces to nodes.
    var nodes_set := {}
    var cell_id: String
    for surface in surfaces_to_edges:
        nodes_set.clear()
        
        # Get a deduped set of all nodes on this surface.
        for edge in surfaces_to_edges[surface]:
            cell_id = _node_to_cell_id(edge.start)
            nodes_set[cell_id] = edge.start
        
        surfaces_to_nodes[surface] = nodes_set.values()
    
    # Set up edge mappings.
    for surface in surfaces_to_nodes:
        for node in surfaces_to_nodes[surface]:
            nodes_to_edges[node] = {}
    
    # Calculate and record all intra-surface edges.
    var intra_surface_edge: IntraSurfaceEdge
    for surface in surfaces_to_nodes:
        for node_a in surfaces_to_nodes[surface]:
            for node_b in surfaces_to_nodes[surface]:
                if node_a == node_b:
                    # Don't create intra-surface edges that start and end at the same node.
                    continue
                
                # Record uni-directional edges in both directions.
                intra_surface_edge = IntraSurfaceEdge.new(node_a, node_b)
                nodes_to_edges[node_a][node_b] = intra_surface_edge
                intra_surface_edge = IntraSurfaceEdge.new(node_b, node_a)
                nodes_to_edges[node_b][node_a] = intra_surface_edge
    
    # Record inter-surface edges.
    for surface in surfaces_to_edges:
        for edge in surfaces_to_edges[surface]:
            nodes_to_edges[edge.start][edge.end] = edge

# Checks whether a previous node with the same position has already been seen.
# 
# - If there is a match, then the previous instance is returned.
# - Otherwise, the new new instance is recorded and returned.
static func _dedup_node(node: PositionAlongSurface, grid_cell_to_node: Dictionary) -> PositionAlongSurface:
    var cell_id := _node_to_cell_id(node)
    
    if grid_cell_to_node.has(cell_id):
        # If we already have a node in this position, then replace the reference for this
        # edge to instead use this other node instance.
        node = grid_cell_to_node[cell_id]
    else:
        # If we don't yet have a node in this position, then record this node.
        grid_cell_to_node[cell_id] = node
    
    return node

# Get a string representation for the grid cell that the given node corresponds to.
# 
# - Before considering each position, subtract x and y by CLUSTER_CELL_HALF_SIZE, since positions
#   are likely to be aligned with cell boundaries, which would make cell assignment less
#   predictable.
# - False negatives for node deduplication should be unlikely, but it should also be ok when it
#   does happen. It'll just result in a little more storage.
static func _node_to_cell_id(node: PositionAlongSurface) -> String:
    return "%s,%s,%s" % [node.surface.side, \
            floor((node.target_point.x - CLUSTER_CELL_HALF_SIZE) / CLUSTER_CELL_SIZE) as int, \
            floor((node.target_point.y - CLUSTER_CELL_HALF_SIZE) / CLUSTER_CELL_SIZE) as int]
