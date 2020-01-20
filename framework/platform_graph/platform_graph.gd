# A PlatfromGraph is specific to a given player type. This is important since different players
# have different jump parameters and can reach different surfaces, so the edges in the graph will
# be different for each player.
extends Reference
class_name PlatformGraph

const AirToSurfaceEdge := preload("res://framework/platform_graph/edge/air_to_surface_edge.gd")
const IntraSurfaceEdge := preload("res://framework/platform_graph/edge/intra_surface_edge.gd")
const MovementCalcOverallParams := preload("res://framework/edge_movement/models/movement_calculation_overall_params.gd")
const MovementCalcStepParams := preload("res://framework/edge_movement/models/movement_calculation_step_params.gd")
const PriorityQueue := preload("res://framework/utils/priority_queue.gd")

# FIXME: LEFT OFF HERE: Master list:
#
# - Finish everything in JumpFromPlatformCalculator (edge calculations, including movement constraints from interfering surfaces)
# - Finish/polish fallable surfaces calculations (and remove old obsolete functions)
#
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
#   or in the air is configuration that JumpFromPlatformCalculator handles directly, rather than
#   relying on a separate FallFromAir class?
# - Add support for including walls in our navigation.
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
# - Refactor the movement/navigation system to support more custom behaviors (e.g., some classic
#   video game movements, like walking to the edge and then turning around, circling the entire
#   circumference, bouncing forward, etc.).


# FIXME: (old notes from jump_from_platform_movement) SUB-MASTER LIST ***************
# - Add support for specifying a required min/max end-x-velocity.
#   - More notes in the backtracking method.
# - Test support for specifying a required min/max end-x-velocity.
# 
# - LEFT OFF HERE: Resolve/debug all left-off commented-out places.
# - LEFT OFF HERE: Check for other obvious false negative edges.
# 
# - LEFT OFF HERE: Implement/test edge-traversal movement:
#   - Test the logic for moving along a path.
#   - Add support for sending the CPU to a click target (configured in the specific level).
#   - Add support for picking random surfaces or points-in-space to move the CPU to; resetting
#        to a new point after the CPU reaches the old point.
#     - Implement this as an alternative to ClickToNavigate (actually, support both running at the
#       same time).
#     - It will need to listen for when the navigator has reached the destination though (make sure
#       that signal is emitted).
# - LEFT OFF HERE: Create a demo level to showcase lots of interesting edges.
# - LEFT OFF HERE: Check for other obvious false negative edges.
# - LEFT OFF HERE: Debug why discrete movement trajectories are incorrect.
#   - Discrete trajectories are definitely peaking higher; should we cut the jump button sooner?
#   - Not considering continous max vertical velocity might contribute to discrete vertical
#     movement stopping short.
# - LEFT OFF HERE: Debug/stress-test intermediate collision scenarios.
#   - After fixing max vertical velocity, is there anything else I can boost?
# - LEFT OFF HERE: Debug why check_instructions_for_collision fails with collisions (render better annotations?).
# - LEFT OFF HERE: Add squirrel animation.
# 
# - Debugging:
#   - Would it help to add some quick and easy annotation helpers for temp debugging that I can access on global (or wherever) and just tell to render dots/lines/circles?
#   - Then I could use that to render all sorts of temp calculation stuff from this file.
#   - Add an annotation for tracing the players recent center positions.
#   - Try rendering a path for trajectory that's closer to the calculations for parabolic motion instead of the resulting instruction positions?
#     - Might help to see the significance of the difference.
#     - Might be able to do this with smaller step sizes?
# 
# - Problem: What if we hit a ceiling surface (still moving upwards)?
#   - We'll set a constraint to either side.
#   - Then we'll likely need to backtrack to use a bigger jump height.
#   - On the backtracking traversal, we'll hit the same surface again.
#     - Solution: We should always be allowed to hit ceiling surfaces again.
#       - Which surfaces _aren't_ we allowed to hit again?
#         - floor, left_wall, right_wall
#       - Important: Double-check that if collision clips a static-collidable corner, that the
#         correct surface is returned
# - Problem: If we allow hitting a ceiling surface repeatedly, what happens if a jump ascent cannot
#   get around it (cannot move horizontally far enough during the ascent)?
#   - Solution: Afer calculating constraints for a surface collision, if it's a ceiling surface,
#     check whether the time to move horizontally exceeds the time to move upward for either
#     constraint. If so, abandon that traversal (remove the constraint from the array before
#     calling the sub function).
# - Optimization: We should never consider increased-height backtracking from hitting a ceiling
#   surface.
# 
# - Create a pause menu and a level switcher.
# - Create some sort of configuration for specifying a level as well as the set of annotations to use.
#   - Actually use this from the menu's level switcher.
#   - Or should the level itself specify which annotations to use?
# - Adapt one of the levels to just render a human player and then the annotations for all edges
#   that our algorithm thinks the human player can traverse.
#   - Try to render all of the interesting edge pairs that I think I should test for.
# 
# - Step through and double-check each return value parameter individually through the recursion, and each input parameter.
# 
# - Optimize a bit for collisions with vertical surfaces:
#   - For the top constraint, change the constraint position to instead use the far side of the
#     adjacent top-side/floor surface.
#   - This probably means I should store adjacent Surfaces when originally parsing the Surfaces.
# - Step through all parts and re-check for correctness.
# - Account for half-width/height offset needed to clear the edge of B (if possible).
# - Also, account for the half-width/height offset needed to not fall onto A.
# - Include a margin around constraints and land position.
# - Allow for the player to bump into walls/ceiling if they could still reach the land point
#   afterward (will need to update logic to not include margin when accounting for these hits).
# - Update the instructions calculations to consider actual discrete timesteps rather than
#   using continuous algorithms.
# - Share per-frame state updates logic between the instruction calculations and actual Player
#   movements.
# - Problem: We need to make sure that we still have enough momementum left once we hit the target
#   position to actually cause us to grab on to the target surface.
#   - Solution: Add support for ensuring a minimum normal-direction speed at the end of the jump.
#     - Faster is probably always better, since efficient/quick movements are better.
# 
# - Problem: All of the edge calculations will allow the slow-ascent gravity to also be used for
#   the downward portion of the jump.
#   - Either update Player controllers to also allow that,
#   - or update all relevant edge calculation logic.
# 
# - Make some diagrams in InkScape with surfaces, trajectories, and constraints to demonstrate
#   algorithm traversal
#   - Label/color-code parts to demonstrate separate traversal steps
# - Make the 144-cell diagram in InkScape and add to docs.
# - Storing possibly 9 edges from A to B.
# 
# FIXME: C:
# - Set the destination_constraint min_velocity_x and max_velocity_x at the start, in order to
#   latch onto the target surface.
#   - Also add support for specifying min/max y velocities for this?
# 
# FIXME: B:
# - Should we more explicity re-use all horizontal steps from before the jump button was released?
#   - It might simplify the logic for checking for previously collided surfaces, and make things
#     more efficient.
# 
# FIXME: B: Check if we need to update following constraints when creating a new one:
# - Unfortunately, it is possible that the creation of a new intermediate constraint could
#   invalidate the actual_velocity_x for the following constraint(s). A fix for this would be
#   to first recalculate the min/max x velocities for all following constraints in forward
#   order, and then recalculate the actual x velocity for all following constraints in reverse
#   order.
# 
# FIXME: B: 
# - Make edge-calc annotations usable at run time, by clicking on the start and end positions to check.
# 




# FIXME: LEFT OFF HERE: -------------------------------------------------A
# 
# #########
# 
# - Try adding other edges now:
#   - 
# 
# - Add some sort of heuristic to choose when to go with smaller or larger velocity end during
#   horizontal step calc.
#   - The alternative, is to once again flip the order we calculate steps, so that we base all
#     steps off of minimizing the x velocity at the destination.
#     - :/ We might want to do that anyway though, to give us more flexibility later when we want
#       to be able to specify a given non-zero target end velocity.
# 
# - Should I move some of the horizontal movement functions from constraint_utils to
#   horizontal_movement_utils?
# 
# - Can I render something in the annotations (or in the console output) like the constraint
#   position or the surface end positions, in order to make it easier to quickly set a breakpoint
#   to match the corresponding step?
# 
# - Debug, debug, debug...
# 
# - Additional_high_constraint_position breakpoint is happening three times??
#   - Should I move the fail-because-we've-been-here-before logic from looking at steps+surfaces+heights to here?
# 
# - Should we somehow ensure that jump height is always bumped up at least enough to cover the
#   extra distance of constraint offsets? 
#   - Since jumping up to a destination, around the other edge of the platform (which has the
#     constraint offset), seems like a common use-case, this would probably be a useful optimization.
#   - [This is important, since the first attempt at getting to the top-right constraint always fails, since it requires a _slightly_ higher jump, and we want it to instead succeed.]
# 
# - There is a problem with my approach for using time_to_get_to_destination_from_constraint.
#   time-to-get-to-intermediate-constraint-from-constraint could matter a lot too. But maybe this
#   is infrequent enough that I don't care? At least document this limitation (in code and README).
# 
# - Add logic to ignore a constraint when the horizontal steps leading up to it would have found
#   another collision.
#   - Because changing trajectory for the earlier collision is likely to invalidate the later
#     collision.
#   - In this case, the recursive call that found the additional, earlier collision will need to
#     also then calculate all steps from this collision to the end?
# 
# - Fix pixel-perfect scaling/aliasing when enlarging screen and doing camera zoom.
#   - Only support whole-number multiples somehow?
# 
# - When backtracking, re-use all steps that finish before releasing the jump button.
# 
# - Add a translation to the on-wall cat animations, so that they are all a bit lower; the cat's
#   head should be about the same position as the corresponding horizontal pose that collided, and
#   the bottom should fall from there.
# 
# - Add support for detecting invalid origin/destination positions (due to pre-existing collisions
#   with nearby surfaces).
#   - Shouldn't matter for convex neighbor surfaces though.
#   - And then add support for correcting the origin/destination position to avoid the collision.
#     - When a pre-existing collision is detected, look at the surface side direction.
#     - If parallel to the origin/destination surface, give up.
#     - If perpendicular, then offset the position to where the player would rest against the
#       surface, and check whether that position is still valid along the origin/destination
#       surface.
# 
# - Render a legend:
#   - x: point of collision
#   - outline: player boundary at point of collision
#   - open circles: start or end constraints
#   - plus: left/right button start
#   - minus: left/right button end
#   - asterisk: jump button end
#   - diamond: 
#   - BT: 
#   - RF: 
# 
# - Polish description of approach in the README.
#   - In general, a guiding heuristic in these calculations is to minimize movement. So, through
#     each constraint (step-end), we try to minimize the horizontal speed of the movement at that
#     point.
# 
# - Try to fix DrawUtils dashed polylines.
# 
# - Think through and maybe fix the function in constraint utils for accounting for max-speed vs
#   min/max for valid next step?
# 
# 
# - Collision calculation annotator:
#   - Would it be worth adding support to zoom and pan the camera to the current collision?
#     - Maybe this could be toggleable via clicking a button in the tree view?
#     - Would definitely want to animate the zoom.
#     - Probably also need to change the camera translation.
#       - Probably can just calculate the offset from the player to the collision, and use that to
#         manually assign an offset to the camera.
#       - Would also need to animate this translation.
# 


const CLUSTER_CELL_SIZE := 0.5
const CLUSTER_CELL_HALF_SIZE := CLUSTER_CELL_SIZE * 0.5

var movement_params: MovementParams
var surface_parser: SurfaceParser
var space_state: Physics2DDirectSpaceState
# Dictionary<Surface, Surface>
var surfaces_set: Dictionary
# Dictionary<Surface, Array<PositionAlongSurface>>
var surfaces_to_outbound_nodes: Dictionary
# Dictionary<PositionAlongSurface, Dictionary<PositionAlongSurface, Edge>>
var nodes_to_nodes_to_edges: Dictionary

var debug_state: Dictionary

func _init(surface_parser: SurfaceParser, space_state: Physics2DDirectSpaceState, \
        player_info: PlayerTypeConfiguration, debug_state: Dictionary) -> void:
    self.movement_params = player_info.movement_params
    self.surface_parser = surface_parser
    self.space_state = space_state
    self.debug_state = debug_state
    
    # Store the subset of surfaces that this player type can interact with.
    var surfaces_array := surface_parser.get_subset_of_surfaces( \
            movement_params.can_grab_walls, \
            movement_params.can_grab_ceilings, \
            movement_params.can_grab_floors)
    self.surfaces_set = Utils.array_to_set(surfaces_array)
    
    self.surfaces_to_outbound_nodes = {}
    self.nodes_to_nodes_to_edges = {}
    
    _calculate_nodes_and_edges(surfaces_set, player_info, debug_state)

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
    
    var nodes_to_previous_nodes := {}
    nodes_to_previous_nodes[origin] = null
    var nodes_to_weights := {}
    nodes_to_weights[origin] = 0.0
    var frontier := PriorityQueue.new()
    frontier.insert(0.0, origin)
    
    var nodes_to_edges_for_current_node: Dictionary
    var next_edge: Edge
    var current_node: PositionAlongSurface
    var current_weight: float
    var next_node: PositionAlongSurface
    var new_actual_weight: float
    
    # Determine the cheapest path.
    while !frontier.is_empty:
        current_node = frontier.remove_root()
        current_weight = nodes_to_weights[current_node]
        
        if current_node == destination:
            # We found the shortest path.
            break
        
        ### Record intra-surface edges.
        
        # If reached the destination surface, record a temporary intra-surface edge to the
        # destination from this current_node.
        if current_node.surface == destination_surface:
            next_node = destination
            new_actual_weight = current_weight + \
                    current_node.target_point.distance_to(next_node.target_point)
            _record_frontier(current_node, next_node, destination, new_actual_weight, \
                    nodes_to_previous_nodes, nodes_to_weights, frontier)
            # We don't need to consider any additional edges from this node, since they'd
            # necessarily be less direct than this intra-surface edge that we just recorded.
            continue
        
        # Record temporary intra-surface edges from the current node to each other node on the same
        # surface.
        for next_node in surfaces_to_outbound_nodes[current_node.surface]:
            new_actual_weight = current_weight + \
                    current_node.target_point.distance_to(next_node.target_point)
            _record_frontier(current_node, next_node, destination, new_actual_weight, \
                    nodes_to_previous_nodes, nodes_to_weights, frontier)
        
        ### Record inter-surface edges.
        
        if !nodes_to_nodes_to_edges.has(current_node):
            # There are no inter-surface edges from this node.
            continue
        
        # Iterate through each inter-surface neighbor node, and record their weights, paths, and
        # priorities.
        nodes_to_edges_for_current_node = nodes_to_nodes_to_edges[current_node]
        for next_node in nodes_to_edges_for_current_node:
            next_edge = nodes_to_edges_for_current_node[next_node]
            new_actual_weight = current_weight + next_edge.weight
            _record_frontier(current_node, next_node, destination, new_actual_weight, \
                    nodes_to_previous_nodes, nodes_to_weights, frontier)
    
    # Collect the edges for the cheapest path.
    
    var edges := []
    current_node = destination
    var previous_node: PositionAlongSurface = nodes_to_previous_nodes.get(current_node)
    
    if previous_node == null:
        # The destination cannot be reached form the origin.
        return null
    
    while previous_node != null:
        if nodes_to_previous_nodes[previous_node] == null or edges.empty():
            # The first and last edge are temporary and extend from/to the origin/destination,
            # which are not aligned with normal node positions.
            next_edge = IntraSurfaceEdge.new(previous_node, current_node)
        elif previous_node.surface == current_node.surface:
            # The previous node is on the same surface as the current node, so we create an
            # intra-surface edge.
            next_edge = IntraSurfaceEdge.new(previous_node, current_node)
        else:
            next_edge = nodes_to_nodes_to_edges[previous_node][current_node]
        
        assert(next_edge != null)
        
        edges.push_front(next_edge)
        current_node = previous_node
        previous_node = nodes_to_previous_nodes.get(previous_node)
    
    assert(!edges.empty())
    
    return PlatformGraphPath.new(edges)

# Helper function for find_path. This records new neighbor nodes for the given node.
static func _record_frontier(current: PositionAlongSurface, next: PositionAlongSurface, \
        destination: PositionAlongSurface, new_actual_weight: float, \
        nodes_to_previous_nodes: Dictionary, nodes_to_weights: Dictionary, \
        frontier: PriorityQueue) -> void:
    if !nodes_to_weights.has(next) or new_actual_weight < nodes_to_weights[next]:
        # We found a new or cheaper path to this next node, so record it.
        
        # Record the path to this node.
        nodes_to_previous_nodes[next] = current
        
        # Record this node's weight.
        nodes_to_weights[next] = new_actual_weight
        
        var heuristic_weight = next.target_point.distance_to(destination.target_point)
        
        # Add this node to the frontier with a priority.
        var priority = new_actual_weight + heuristic_weight
        frontier.insert(priority, next)

func get_surfaces_in_jump_and_fall_range(origin_surface: Surface) -> Dictionary:
    # TODO: Update this to support falling from the center of fall-through surfaces (consider the
    #       whole surface, rather than just the ends).
    
    var velocity_start := movement_params.get_jump_initial_velocity(origin_surface.side)
    
    var result_set := {}
    
    # Get all surfaces that are within fall range from either end of the origin surface.
    FallMovementUtils.find_surfaces_in_fall_range(movement_params, surfaces_set, \
            result_set, origin_surface.first_point, velocity_start)
    if origin_surface.vertices.size() > 1:
        FallMovementUtils.find_surfaces_in_fall_range(movement_params, surfaces_set, \
                result_set, origin_surface.last_point, velocity_start)
    
    var max_horizontal_jump_distance := \
            movement_params.get_max_horizontal_jump_distance(origin_surface.side)
    _get_surfaces_in_jump_range(result_set, origin_surface, surfaces_set, \
            max_horizontal_jump_distance, movement_params.max_upward_jump_distance)
    
    return result_set

# Calculates and stores the edges between surface nodes that this player type can traverse.
func _calculate_nodes_and_edges(surfaces_set: Dictionary, player_info: PlayerTypeConfiguration, \
        debug_state: Dictionary) -> void:
    ###################################################################################
    # Allow for debug mode to limit the scope of what's calculated.
    if debug_state.in_debug_mode and \
            debug_state.has('limit_parsing') and \
            player_info.name != debug_state.limit_parsing.player_name:
        return
    ###################################################################################
    
    var possible_destination_surfaces_set: Dictionary
    
    # Calculate all inter-surface edges.
    # Dictionary<Surface, Array<Edge>>
    var surfaces_to_edges := {}
    var edges: Array
    for surface in surfaces_set:
        surfaces_to_edges[surface] = []
        possible_destination_surfaces_set = get_surfaces_in_jump_and_fall_range(surface)
        
        for movement_calculator in player_info.movement_calculators:
            if movement_calculator.get_can_traverse_from_surface(surface):
                # Calculate the inter-surface edges.
                edges = movement_calculator.get_all_edges_from_surface( \
                        debug_state, space_state, movement_params, surface_parser, \
                        possible_destination_surfaces_set, surface)
                
                # Remove any used surfaces from consideration.
                for edge in edges:
                    possible_destination_surfaces_set.erase(edge.end_surface)
                
                Utils.concat(surfaces_to_edges[surface], edges)
    
    # Dedup all edge-end positions (aka, nodes).
    var grid_cell_to_node := {}
    for surface in surfaces_to_edges:
        for edge in surfaces_to_edges[surface]:
            edge.start_position_along_surface = \
                    _dedup_node(edge.start_position_along_surface, grid_cell_to_node)
            edge.end_position_along_surface = \
                    _dedup_node(edge.end_position_along_surface, grid_cell_to_node)
    
    # Record mappings from surfaces to nodes.
    var nodes_set := {}
    var cell_id: String
    for surface in surfaces_to_edges:
        nodes_set.clear()
        
        # Get a deduped set of all nodes on this surface.
        for edge in surfaces_to_edges[surface]:
            cell_id = _node_to_cell_id(edge.start_position_along_surface)
            nodes_set[cell_id] = edge.start_position_along_surface
        
        surfaces_to_outbound_nodes[surface] = nodes_set.values()
    
    # Set up edge mappings.
    for surface in surfaces_to_outbound_nodes:
        for node in surfaces_to_outbound_nodes[surface]:
            nodes_to_nodes_to_edges[node] = {}
    
    # Calculate and record all intra-surface edges.
    var intra_surface_edge: IntraSurfaceEdge
    for surface in surfaces_to_outbound_nodes:
        for node_a in surfaces_to_outbound_nodes[surface]:
            for node_b in surfaces_to_outbound_nodes[surface]:
                if node_a == node_b:
                    # Don't create intra-surface edges that start and end at the same node.
                    continue
                
                # Record uni-directional edges in both directions.
                intra_surface_edge = IntraSurfaceEdge.new(node_a, node_b)
                nodes_to_nodes_to_edges[node_a][node_b] = intra_surface_edge
                intra_surface_edge = IntraSurfaceEdge.new(node_b, node_a)
                nodes_to_nodes_to_edges[node_b][node_a] = intra_surface_edge
    
    # Record inter-surface edges.
    for surface in surfaces_to_edges:
        for edge in surfaces_to_edges[surface]:
            nodes_to_nodes_to_edges[edge.start_position_along_surface][edge.end_position_along_surface] = \
                    edge

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

static func _get_surfaces_in_jump_range(result_set: Dictionary, target_surface: Surface, \
        other_surfaces_set: Dictionary, max_horizontal_jump_distance: float, \
        max_upward_jump_distance: float) -> void:
    var expanded_target_bounding_box := target_surface.bounding_box.grow_individual( \
            max_horizontal_jump_distance, max_upward_jump_distance, max_horizontal_jump_distance, \
            0.0)
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE
#    if target_surface.bounding_box.position == Vector2(128, 64):
#        print("yo")
    
    for other_surface in other_surfaces_set:
        if expanded_target_bounding_box.intersects(other_surface.bounding_box):
            result_set[other_surface] = other_surface
