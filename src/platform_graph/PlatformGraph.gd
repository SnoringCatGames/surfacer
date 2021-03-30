# -   This graph is optimized for run-time path-finding.
# -   Graph parsing is slow and is done during app start.
# -   Graph parsing is multi-threaded.
# -   A PlatfromGraph is specific to a given player type. This is important
#     since different players have different jump parameters and can reach
#     different surfaces, so the edges in the graph will be different for each
#     player.
class_name PlatformGraph
extends Reference

const CLUSTER_CELL_SIZE := 0.5
const CLUSTER_CELL_HALF_SIZE := CLUSTER_CELL_SIZE * 0.5

var collision_params: CollisionCalcParams
var player_params: PlayerParams
var movement_params: MovementParams
var surface_parser: SurfaceParser

# Dictionary<Surface, Surface>
var surfaces_set := {}

# Dictionary<Surface, Array<PositionAlongSurface>>
var surfaces_to_outbound_nodes := {}

# Intra-surface edges are not calculated and stored ahead of time; they're only
# calculated at run time when navigating a specific path.
# 
# Dictionary<PositionAlongSurface, Dictionary<PositionAlongSurface,
#         Array<Edge>>>
var nodes_to_nodes_to_edges := {}

# Dictionary<Surface, Array<InterSurfaceEdgeResult>>
var surfaces_to_inter_surface_edges_results := {}

# Dictionary<String, int>
var counts := {}

var debug_params := {}

# Array<Thread>
var _threads := []

func _init( \
        player_params: PlayerParams, \
        collision_params: CollisionCalcParams) -> void:
    self.collision_params = collision_params
    self.player_params = player_params
    self.movement_params = player_params.movement_params
    self.surface_parser = collision_params.surface_parser
    self.debug_params = collision_params.debug_params
    
    # Store the subset of surfaces that this player type can interact with.
    var surfaces_array := surface_parser.get_subset_of_surfaces( \
            movement_params.can_grab_walls, \
            movement_params.can_grab_ceilings, \
            movement_params.can_grab_floors)
    self.surfaces_set = Gs.utils.array_to_set(surfaces_array)
    
    _calculate_nodes_and_edges()
    
    _update_counts()

# Uses A* search.
func find_path( \
        origin: PositionAlongSurface, \
        destination: PositionAlongSurface) -> PlatformGraphPath:
    # TODO: Add an early-cutoff mechanism for paths that deviate too far from
    #       straight-line. Otherwise, this will check every connecected surface
    #       before knowing that a destination cannot be reached.
    
    var origin_surface := origin.surface
    var destination_surface := destination.surface
    
    if origin_surface == destination_surface:
        # If the we are simply trying to get to a different position on the
        # same surface, then we don't need A*.
        var edges := [IntraSurfaceEdge.new( \
                origin, \
                destination, \
                Vector2.ZERO, \
                movement_params)]
        return PlatformGraphPath.new(edges)
    
    var explored_surfaces := {}
    var nodes_to_previous_nodes := {}
    nodes_to_previous_nodes[origin] = null
    var nodes_to_weights := {}
    nodes_to_weights[origin] = 0.0
    var frontier := PriorityQueue.new()
    frontier.insert(0.0, origin)
    
    var nodes_to_edges_for_current_node: Dictionary
    var current_node: PositionAlongSurface
    var current_weight: float
    var new_actual_weight: float
    
    # Determine the cheapest path.
    while !frontier.is_empty:
        current_node = frontier.remove_root()
        current_weight = nodes_to_weights[current_node]
        
        if current_node == destination:
            # We found the shortest path.
            break
        
        ### Record intra-surface edges.
        
        # If we reached the destination surface, record a temporary
        # intra-surface edge to the destination from this current_node.
        if current_node.surface == destination_surface:
            var next_node := destination
            new_actual_weight = \
                    current_weight + \
                    _calculate_intra_surface_edge_weight( \
                            movement_params, \
                            current_node, \
                            next_node)
            _record_frontier( \
                    current_node, \
                    next_node, \
                    destination, \
                    new_actual_weight, \
                    nodes_to_previous_nodes, \
                    nodes_to_weights, \
                    frontier)
            # We don't need to consider any additional edges from this node,
            # since they'd necessarily be less direct than this intra-surface
            # edge that we just recorded.
            continue
        
        # Only consider the out-bound nodes of the current surface if we
        # haven't already considered them (otherwise, we can end up with
        # multiple adjacent intra-surface edges in the same path).
        if !explored_surfaces.has(current_node.surface):
            explored_surfaces[current_node.surface] = true
            
            # Record temporary intra-surface edges from the current node to
            # each other node on the same surface.
            for next_node in surfaces_to_outbound_nodes[current_node.surface]:
                new_actual_weight = \
                        current_weight + \
                        _calculate_intra_surface_edge_weight( \
                                movement_params, \
                                current_node, \
                                next_node)
                _record_frontier( \
                        current_node, \
                        next_node, \
                        destination, \
                        new_actual_weight, \
                        nodes_to_previous_nodes, \
                        nodes_to_weights, \
                        frontier)
        
        ### Record inter-surface edges.
        
        if !nodes_to_nodes_to_edges.has(current_node):
            # There are no inter-surface edges from this node.
            continue
        
        # Iterate through each inter-surface neighbor node, and record their
        # weights, paths, and priorities.
        nodes_to_edges_for_current_node = nodes_to_nodes_to_edges[current_node]
        for next_node in nodes_to_edges_for_current_node:
            for next_edge in nodes_to_edges_for_current_node[next_node]:
                new_actual_weight = current_weight + next_edge.get_weight()
                _record_frontier( \
                        current_node, \
                        next_node, \
                        destination, \
                        new_actual_weight, \
                        nodes_to_previous_nodes, \
                        nodes_to_weights, \
                        frontier)
    
    # Collect the edges for the cheapest path.
    
    var edges := []
    current_node = destination
    var previous_node: PositionAlongSurface = \
            nodes_to_previous_nodes.get(current_node)
    
    if previous_node == null:
        # The destination cannot be reached form the origin.
        return null
    
    while previous_node != null:
        var next_edge: Edge
        if previous_node.surface == current_node.surface:
            # An intermediate intra-surface edge.
            # 
            # The previous node is on the same surface as the current node, so
            # we create an intra-surface edge.
            next_edge = IntraSurfaceEdge.new( \
                    previous_node, \
                    current_node, \
                    Vector2.ZERO, \
                    movement_params)
        else:
            next_edge = _get_cheapest_edge_between_nodes( \
                    previous_node, \
                    current_node)
        
        assert(next_edge != null)
        
        edges.push_front(next_edge)
        current_node = previous_node
        previous_node = nodes_to_previous_nodes.get(previous_node)
    
    assert(!edges.empty())
    
    return PlatformGraphPath.new(edges)

static func _calculate_intra_surface_edge_weight( \
        movement_params: MovementParams, \
        node_a: PositionAlongSurface, \
        node_b: PositionAlongSurface) -> float:
    var distance := node_a.target_point.distance_to(node_b.target_point)
    
    # Use either the distance or the duration as the weight for the edge.
    var weight: float
    if movement_params.uses_duration_instead_of_distance_for_edge_weight:
        weight = IntraSurfaceEdge.calculate_duration_to_move_along_surface( \
                movement_params, \
                node_a, \
                node_b, \
                distance)
    else:
        weight = distance
    
    # Apply a multiplier to the weight according to the type of edge.
    match node_a.side:
        SurfaceSide.FLOOR, \
        SurfaceSide.CEILING:
            weight *= movement_params.walking_edge_weight_multiplier
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            weight *= movement_params.climbing_edge_weight_multiplier
        _:
            Gs.utils.error()
    
    # Give a constant extra weight for each additional edge in a path.
    weight += movement_params.additional_edge_weight_offset
    
    return weight

# Helper function for find_path. This records new neighbor nodes for the given
# node.
static func _record_frontier( \
        current: PositionAlongSurface, \
        next: PositionAlongSurface, \
        destination: PositionAlongSurface, \
        new_actual_weight: float, \
        nodes_to_previous_nodes: Dictionary, \
        nodes_to_weights: Dictionary, \
        frontier: PriorityQueue) -> void:
    if !nodes_to_weights.has(next) or \
            new_actual_weight < nodes_to_weights[next]:
        # We found a new or cheaper path to this next node, so record it.
        
        # Record the path to this node.
        nodes_to_previous_nodes[next] = current
        
        # Record this node's weight.
        nodes_to_weights[next] = new_actual_weight
        
        var heuristic_weight = \
                next.target_point.distance_to(destination.target_point)
        
        # Add this node to the frontier with a priority.
        var priority = new_actual_weight + heuristic_weight
        frontier.insert(priority, next)

func _get_cheapest_edge_between_nodes( \
        origin: PositionAlongSurface, \
        destination: PositionAlongSurface) -> Edge:
    var cheapest_edge: Edge
    var cheapest_weight := INF
    var current_weight: float
    for current_edge in nodes_to_nodes_to_edges[origin][destination]:
        current_weight = current_edge.get_weight()
        if current_weight < cheapest_weight:
            cheapest_edge = current_edge
            cheapest_weight = current_weight
    return cheapest_edge

# Calculates and stores the edges between surface nodes that this player type
# can traverse.
# 
# Intra-surface edges are not calculated and stored ahead of time; they're only
# calculated at run time when navigating a specific path.
# 
# This calculation is multi-threaded.
func _calculate_nodes_and_edges() -> void:
    ###########################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if debug_params.has("limit_parsing") and \
            debug_params.limit_parsing.has("player_name") and \
            player_params.name != debug_params.limit_parsing.player_name:
        return
    ###########################################################################
    
    _calculate_inter_surface_edges_total()
    
    # Dedup all edge-end positions (aka, nodes).
    var grid_cell_to_node := {}
    for surface in surfaces_to_inter_surface_edges_results:
        for inter_surface_edges_result in \
                surfaces_to_inter_surface_edges_results[surface]:
            for jump_land_positions in \
                    inter_surface_edges_result.all_jump_land_positions:
                jump_land_positions.jump_position = _dedup_node( \
                        jump_land_positions.jump_position, \
                        grid_cell_to_node)
                jump_land_positions.land_position = _dedup_node( \
                        jump_land_positions.land_position, \
                        grid_cell_to_node)
            
            for edge in inter_surface_edges_result.valid_edges:
                edge.start_position_along_surface = _dedup_node( \
                        edge.start_position_along_surface, \
                        grid_cell_to_node)
                edge.end_position_along_surface = _dedup_node( \
                        edge.end_position_along_surface, \
                        grid_cell_to_node)
            
            # InterSurfaceEdgesResult.failed_edge_attempts only indirectly
            # references PositionAlongSurface objects through the
            # JumpLandPositions object, which has already been deduped.
    
    # Record mappings from surfaces to nodes.
    var nodes_set := {}
    var cell_id: String
    for surface in surfaces_to_inter_surface_edges_results:
        nodes_set.clear()
        
        # Get a deduped set of all nodes on this surface.
        for inter_surface_edges_results in \
                surfaces_to_inter_surface_edges_results[surface]:
            for edge in inter_surface_edges_results.valid_edges:
                cell_id = _node_to_cell_id(edge.start_position_along_surface)
                nodes_set[cell_id] = edge.start_position_along_surface
        
        surfaces_to_outbound_nodes[surface] = nodes_set.values()
    
    # Set up edge mappings.
    for surface in surfaces_to_outbound_nodes:
        for node in surfaces_to_outbound_nodes[surface]:
            nodes_to_nodes_to_edges[node] = {}
    
    # Record inter-surface edges.
    for surface in surfaces_to_inter_surface_edges_results:
        for inter_surface_edges_results in \
                surfaces_to_inter_surface_edges_results[surface]:
            for edge in inter_surface_edges_results.valid_edges:
                if !nodes_to_nodes_to_edges \
                        [edge.start_position_along_surface] \
                        .has(edge.end_position_along_surface):
                    nodes_to_nodes_to_edges \
                        [edge.start_position_along_surface] \
                        [edge.end_position_along_surface] = []
                nodes_to_nodes_to_edges \
                        [edge.start_position_along_surface] \
                        [edge.end_position_along_surface].push_back(edge)
    
    if !Surfacer.is_inspector_enabled:
        # Free-up this memory if we don't need to display the graph state in
        # the inspector.
        surfaces_to_inter_surface_edges_results.clear()

func _calculate_inter_surface_edges_total() -> void:
    # Pre-allocate space in the Dictionary for thread-safe recording of the
    # results.
    for origin_surface in surfaces_set:
        surfaces_to_inter_surface_edges_results[origin_surface] = []
    
    if Gs.uses_threads:
        var threads := []
        threads.resize(Gs.thread_count)
        
        # Use child threads to parallelize graph parsing.
        for i in Gs.thread_count:
            var thread := Thread.new()
            Gs.profiler.init_thread("parse_edges:" + str(i))
            threads[i] = thread
            thread.start( \
                    self, \
                    "_calculate_inter_surface_edges_subset", \
                    i)
        
        for thread in threads:
            thread.wait_to_finish()
    else:
        _calculate_inter_surface_edges_subset(-1)

func _calculate_inter_surface_edges_subset(thread_index: int) -> void:
    var collision_params_for_thread := CollisionCalcParams.new( \
            {}, \
            null, \
            null, \
            null)
    collision_params_for_thread.copy(collision_params)
    collision_params_for_thread.thread_id = \
            "parse_edges:" + str(thread_index) if \
            thread_index >= 0 else \
            Gs.profiler.DEFAULT_THREAD_ID
    
    var surfaces_in_fall_range_set := {}
    var surfaces_in_jump_range_set := {}
    
    # Array<InterSurfaceEdgeResult>
    var inter_surface_edges_results: Array
    
    var i := -1
    
    # Calculate all inter-surface edges.
    for origin_surface in surfaces_set:
        i += 1
        
        # Divide the origin surfaces across threads.
        if thread_index >= 0 and \
                i % Surfacer.THREAD_COUNT != thread_index:
            continue
        
        inter_surface_edges_results = \
                surfaces_to_inter_surface_edges_results[origin_surface]
        surfaces_in_fall_range_set.clear()
        surfaces_in_jump_range_set.clear()
        
        get_surfaces_in_jump_and_fall_range( \
                collision_params_for_thread, \
                surfaces_in_fall_range_set, \
                surfaces_in_jump_range_set, \
                origin_surface)
        
        for edge_calculator in player_params.edge_calculators:
            ###################################################################
            # Allow for debug mode to limit the scope of what's calculated.
            if debug_params.has("limit_parsing") and \
                    debug_params.limit_parsing.has("edge_type") and \
                    edge_calculator.edge_type != \
                            debug_params.limit_parsing.edge_type:
                continue
            ###################################################################
            
            if edge_calculator.get_can_traverse_from_surface(origin_surface):
                # Calculate the inter-surface edges.
                edge_calculator.get_all_inter_surface_edges_from_surface( \
                        inter_surface_edges_results, \
                        collision_params_for_thread, \
                        origin_surface, \
                        surfaces_in_fall_range_set, \
                        surfaces_in_jump_range_set)

# Checks whether a previous node with the same position has already been seen.
#
# - If there is a match, then the previous instance is returned.
# - Otherwise, the new new instance is recorded and returned.
static func _dedup_node( \
        node: PositionAlongSurface, \
        grid_cell_to_node: Dictionary) -> PositionAlongSurface:
    var cell_id := _node_to_cell_id(node)
    
    if grid_cell_to_node.has(cell_id):
        # If we already have a node in this position, then replace the
        # reference for this edge to instead use this other node instance.
        node = grid_cell_to_node[cell_id]
    else:
        # If we don't yet have a node in this position, then record this node.
        grid_cell_to_node[cell_id] = node
    
    return node

# Get a string representation for the grid cell that the given node corresponds
# to.
#
# - Before considering each position, subtract x and y by
#   CLUSTER_CELL_HALF_SIZE, since positions are likely to be aligned with cell
#   boundaries, which would make cell assignment less predictable.
# - False negatives for node deduplication should be unlikely, but it should
#   also be ok when it does happen. It'll just result in a little more storage.
static func _node_to_cell_id(node: PositionAlongSurface) -> String:
    return "%s,%s,%s" % [node.side, \
            floor((node.target_point.x - CLUSTER_CELL_HALF_SIZE) / \
                    CLUSTER_CELL_SIZE) as int, \
            floor((node.target_point.y - CLUSTER_CELL_HALF_SIZE) / \
                    CLUSTER_CELL_SIZE) as int]

func get_surfaces_in_jump_and_fall_range( \
        collision_params: CollisionCalcParams, \
        surfaces_in_fall_range_result_set: Dictionary, \
        surfaces_in_jump_range_result_set: Dictionary, \
        origin_surface: Surface) -> void:
    # TODO: Update this to support falling from the center of fall-through
    #       surfaces (consider the whole surface, rather than just the ends).
    
    # Get all surfaces that are within fall range from either end of the origin
    # surface.
    Gs.profiler.start( \
            SurfacerProfilerMetric.FIND_SURFACES_IN_JUMP_FALL_RANGE_FROM_SURFACE, \
            collision_params.thread_id)
    FallMovementUtils.find_surfaces_in_fall_range_from_surface( \
            movement_params, \
            surfaces_set, \
            surfaces_in_fall_range_result_set, \
            surfaces_in_jump_range_result_set, \
            origin_surface)
    Gs.profiler.stop( \
            SurfacerProfilerMetric.FIND_SURFACES_IN_JUMP_FALL_RANGE_FROM_SURFACE, \
            collision_params.thread_id)

func _update_counts() -> void:
    counts.clear()
    
    counts.total_surfaces = 0
    counts.total_edges = 0
    
    # Initialize surface and edge type counts.
    for side in SurfaceSide.keys():
        if side == "NONE":
            continue
        counts[side] = 0
    for type in EdgeType.keys():
        if type == "UNKNOWN":
            continue
        counts[type] = 0
    
    var surface_side_string: String
    
    for surface in surfaces_set:
        # Increment the surface counts.
        surface_side_string = SurfaceSide.get_side_string(surface.side)
        counts[surface_side_string] += 1
        counts.total_surfaces += 1
        
        for origin_node in surfaces_to_outbound_nodes[surface]:
            for destination_node in nodes_to_nodes_to_edges[origin_node]:
                for edge in \
                        nodes_to_nodes_to_edges[origin_node][destination_node]:
                    # Increment the edge counts.
                    counts[edge.name] += 1
                    counts.total_edges += 1

func to_string() -> String:
    return "PlatformGraph{ player: %s, surfaces: %s, edges: %s }" % [ \
            movement_params.name, \
            counts.total_surfaces, \
            counts.total_edges, \
            ]
