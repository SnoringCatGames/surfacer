# A PlatfromGraph is specific to a given player type. This is important since different players
# have different jump parameters and can reach different surfaces, so the edges in the graph will
# be different for each player.
extends Reference
class_name PlatformGraph

const AirToSurfaceEdge := preload("res://framework/platform_graph/edge/air_to_surface_edge.gd")
const IntraSurfaceEdge := preload("res://framework/platform_graph/edge/intra_surface_edge.gd")
const MovementCalcOverallParams := preload("res://framework/movement/models/movement_calculation_overall_params.gd")
const MovementCalcStepParams := preload("res://framework/movement/models/movement_calculation_step_params.gd")
const PriorityQueue := preload("res://framework/utils/priority_queue.gd")

# FIXME: LEFT OFF HERE: Master list:
#
# - Finish everything in JumpFromPlatformMovement (edge calculations, including movement constraints from interfering surfaces)
# - Finish/polish fallable surfaces calculations (and remove old obsolete functions)
#
# - Use FallFromAirMovement
# - Use max_horizontal_jump_distance and max_upward_jump_distance
# 
# - Fix some aggregate return types to be Array instead of Vector2.
#
# - Add annotations that draw the recent path that the player actually moved.
# - Add annotations for rendering some basic navigation mode info for the CP:
#   - Mode name
#   - Current "input" (UP, LEFT, etc.)?
#   - The entirety of the current instruction-set being run?
#
# - Add logic to consider a minimum movement distance, since jumping from floors or walls gives a
#   set minimum displacement.
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
# - Add integration tests:
#   - These should be much easier to write and maintain than the unit tests.
#   - These should start with:
#     - One player type (other types shouldn't be instantiated or considered by any logic at all)
#     - A level that could be either simple or complicated.
#     - We should be able to configure from the test the specific starting and ending surface and
#       position to check.
#       - This should then cause the PlatformGraph parsing and get_all_edges_from_surface parsing
#         to skip all other surfaces and jump/land positions.
#     - We should use the above configuration to target specific interesting edge use-cases.
#       - Skipping constraints
#       - Left/right/ceiling/floor intermediate surfaces
#         - And then passing on min/max side of those surfaces
#       - Zigzagging between a couple consecutive intermediate surfaces
#         - While moving upward, downward, leftward, rightward
#       - Jumping up around side of block to top
#       - Jumping down around top of block to side
#       - Jumping when a non-minimum step-end x velocity is needed
#       - Needing vertical backtracking
#       - Needing to press side-movement input in opposite direction of movement in order to slow
#         velocity along the step.
#       - Falling a long vertical distance, to test the fallable surfaces logic
#       - Jumping a long horizontal distance, to test the reachable surfaces logic
#       - Surface-to-surface
#       - Surface-to-air
#       - Air-to-surface
#       - wall to wall
#       - floor to wall
#       - wall to floor
#       - Starting on convex and concave corners between adjacent surfaces, so that the collision
#         margin considers the other surfaces as already colliding beforehand.
#
# - Refactor Movement classes, so that whether the start and end posiition is on a platform
#   or in the air is configuration that JumpFromPlatformMovement handles directly, rather than
#   relying on a separate FallFromAir class?
# - Add support for including walls in our navigation.
# - Add support for other Movement sub-classes:
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
# - Make get_surfaces_in_jump_and_fall_range more efficient? (force run it everyframe to ensure no lag)
#   - Scrap previous function; just use bounding box intersection (since I'm going to need to use
#     better logic for determining movement patterns anyway...)
#   - Actually, maybe don't worry too much, because this is actually only run at the start.
#
# - Add logic to Player when calculating touched edges to check that the collider is a stationary TileMap object
#
# - Figure out how to configure input names/mappings (or just add docs specifying that the
#   consumer must use these input names?)
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
# 
# - Update things to support falling from the center of fall-through surfaces (consider the whole
#   surface, rather than just the ends).
# 
# - Split apart Movement into smaller classes (after finalizing movement system architecture).
# 
# - Refactor the movement/navigation system to support more custom behaviors (e.g., some classic
#   video game movements, like walking to the edge and then turning around, circling the entire
#   circumference, bouncing forward, etc.).

const CLUSTER_CELL_SIZE := 0.5
const CLUSTER_CELL_HALF_SIZE := CLUSTER_CELL_SIZE * 0.5

var movement_params: MovementParams
var surface_parser: SurfaceParser
var space_state: Physics2DDirectSpaceState
# Array<Surface>
var surfaces: Array
# Dictionary<Surface, Array<PositionAlongSurface>>
var surfaces_to_nodes: Dictionary
# Dictionary<PositionAlongSurface, Dictionary<Edge>>
var nodes_to_edges: Dictionary

var debug_state: Dictionary

func _init(surface_parser: SurfaceParser, space_state: Physics2DDirectSpaceState, \
        player_info: PlayerTypeConfiguration, debug_state: Dictionary) -> void:
    self.movement_params = player_info.movement_params
    self.surface_parser = surface_parser
    self.space_state = space_state
    self.debug_state = debug_state

    # Store the subset of surfaces that this player type can interact with.
    self.surfaces = surface_parser.get_subset_of_surfaces( \
            movement_params.can_grab_walls, \
            movement_params.can_grab_ceilings, \
            movement_params.can_grab_floors)

    self.surfaces_to_nodes = {}
    self.nodes_to_edges = {}
    
    _calculate_nodes_and_edges(surfaces, player_info, debug_state)

# Uses A* search.
func find_path(origin: PositionAlongSurface, \
        destination: PositionAlongSurface) -> PlatformGraphPath:
    # TODO: Add an early-cutoff mechanism for paths that deviate too far from straight-line.
    #       Otherwise, this will check every connecected surface before knowing that a destination
    #       cannot be reached.
    
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

# Finds a movement step that will result in landing on a surface, with an attempt to minimize the
# path the player would then have to travel between surfaces to reach the given target.
#
# Returns null if no possible landing exists.
func find_a_landing_trajectory(origin: Vector2, velocity_start: Vector2, \
        destination: PositionAlongSurface) -> AirToSurfaceEdge:
    var result_set := {}
    find_surfaces_in_fall_range(result_set, origin, velocity_start)
    var possible_landing_surfaces := result_set.keys()
    possible_landing_surfaces.sort_custom(self, "_compare_surfaces_by_max_y")

    var constraint_offset := MovementCalcOverallParams.calculate_constraint_offset(movement_params)
    
    var origin_vertices := [origin]
    var origin_bounding_box := Rect2(origin.x, origin.y, 0.0, 0.0)

    var possible_end_positions: Array
    var terminals: Array
    var vertical_step: MovementVertCalcStep
    var step_calc_params: MovementCalcStepParams
    var calc_results: MovementCalcResults
    var overall_calc_params: MovementCalcOverallParams

    # Find the first possible edge to a landing surface.
    for surface in possible_landing_surfaces:
        possible_end_positions = MovementUtils.get_all_jump_positions_from_surface( \
                movement_params, destination.surface, origin_vertices, origin_bounding_box)
        
        for position_end in possible_end_positions:
            terminals = MovementConstraintUtils.create_terminal_constraints(null, origin, \
                    surface, position_end.target_point, movement_params, constraint_offset, \
                    velocity_start, false)
            if terminals.empty():
                continue
            
            overall_calc_params = MovementCalcOverallParams.new(movement_params, space_state, \
                    surface_parser, velocity_start, terminals[0], terminals[1], false)
            
            vertical_step = VerticalMovementUtils.calculate_vertical_step(overall_calc_params)
            if vertical_step == null:
                continue
            
            step_calc_params = MovementCalcStepParams.new(overall_calc_params.origin_constraint, \
                    overall_calc_params.destination_constraint, vertical_step, \
                    overall_calc_params, overall_calc_params)
            
            calc_results = MovementStepUtils.calculate_steps_from_constraint( \
                    overall_calc_params, step_calc_params)
            if calc_results != null:
                return AirToSurfaceEdge.new(origin, position_end, calc_results)
    
    return null

func find_surfaces_in_fall_range( \
        result_set: Dictionary, origin: Vector2, velocity_start: Vector2) -> void:
    # FIXME: E: Offset the start_position_offset to account for velocity_start.
    # TODO: Refactor this to use a more accurate bounding polygon.
    
    # This offset should account for the extra horizontal range before the player has reached
    # terminal velocity.
    var start_position_offset_x: float = \
            HorizontalMovementUtils.calculate_max_horizontal_displacement(movement_params, \
                    velocity_start.y)
    var start_position_offset := Vector2(start_position_offset_x, 0.0)
    var slope := movement_params.max_vertical_speed / movement_params.max_horizontal_speed_default
    var bottom_corner_offset_from_top_corner := Vector2(100000.0, 100000.0 * slope)
    
    var top_left := origin - start_position_offset
    var top_right := origin + start_position_offset
    var bottom_left := top_left + Vector2(-bottom_corner_offset_from_top_corner.x, bottom_corner_offset_from_top_corner.y)
    var bottom_right := top_right + Vector2(bottom_corner_offset_from_top_corner.x, bottom_corner_offset_from_top_corner.y)
    _get_surfaces_intersecting_polygon(result_set, \
            [top_left, top_right, bottom_right, bottom_left], surfaces)

func get_surfaces_in_jump_and_fall_range(origin_surface: Surface) -> Array:
    # TODO: Update this to support falling from the center of fall-through surfaces (consider the
    #       whole surface, rather than just the ends).
    
    var velocity_start := Vector2(0.0, movement_params.jump_boost)
    
    var result_set := {}
    
    # Get all surfaces that are within fall range from either end of the origin surface.
    find_surfaces_in_fall_range(result_set, origin_surface.vertices[0], velocity_start)
    var size := origin_surface.vertices.size()
    if size > 1:
        find_surfaces_in_fall_range(result_set, origin_surface.vertices[size - 1], velocity_start)
    
    _get_surfaces_in_jump_range(result_set, origin_surface, surfaces, \
            movement_params.max_horizontal_jump_distance, movement_params.max_upward_jump_distance)
    
    return result_set.keys()

# Calculates and stores the edges between surface nodes that this player type can traverse.
func _calculate_nodes_and_edges(surfaces: Array, player_info: PlayerTypeConfiguration, \
        debug_state: Dictionary) -> void:
    var possible_destination_surfaces: Array
    
    # Calculate all inter-surface edges.
    var surfaces_to_edges := {}
    for movement_type in player_info.movement_types:
        if movement_type.can_traverse_edge:
            for surface in surfaces:
                ###################################################################################
                # Allow for debug mode to limit the scope of what's calculated.
                if debug_state.in_debug_mode and \
                        player_info.name != debug_state.limit_parsing_to_single_edge.player_name:
                    continue
                
                # FIXME: Comment out when writing tests
#                pass
                ###################################################################################
                
                # Calculate the inter-surface edges.
                possible_destination_surfaces = get_surfaces_in_jump_and_fall_range(surface)
                surfaces_to_edges[surface] = movement_type.get_all_edges_from_surface( \
                        debug_state, space_state, surface_parser, \
                        possible_destination_surfaces, surface)
    
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

# This is only an approximation, since it only considers the end points of the surface rather than
# each segment of the surface polyline.
static func _get_surfaces_intersecting_triangle(triangle_a: Vector2, triangle_b: Vector2,
        triangle_c: Vector2, surfaces: Array) -> Array:
    var result := []
    for surface in surfaces:
        if Geometry.do_segment_and_triangle_intersect(surface.vertices.front(), \
                surface.vertices.back(), triangle_a, triangle_b, triangle_c):
            result.push_back(surface)
    return result

# This is only an approximation, since it only considers the end points of the surface rather than
# each segment of the surface polyline.
static func _get_surfaces_intersecting_polygon( \
        result_set: Dictionary, polygon: Array, surfaces: Array) -> void:
    for surface in surfaces:
        if Geometry.do_segment_and_polygon_intersect(surface.vertices[0], \
                surface.vertices[surface.vertices.size() - 1], polygon):
            result_set[surface] = surface

static func _compare_surfaces_by_max_y(a: Surface, b: Surface) -> bool:
    return a.bounding_box.position.y < b.bounding_box.position.y

static func _get_surfaces_in_jump_range(result_set: Dictionary, target_surface: Surface, \
        other_surfaces: Array, max_horizontal_jump_distance: float, \
        max_upward_jump_distance: float) -> void:
    var expanded_target_bounding_box := target_surface.bounding_box.grow_individual( \
            max_horizontal_jump_distance, max_upward_jump_distance, max_horizontal_jump_distance, \
            0.0)
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE
#    if target_surface.bounding_box.position == Vector2(128, 64):
#        print("yo")
    
    for other_surface in other_surfaces:
        if expanded_target_bounding_box.intersects(other_surface.bounding_box):
            result_set[other_surface] = other_surface
