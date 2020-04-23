extends EdgeMovementCalculator
class_name JumpInterSurfaceCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "JumpInterSurfaceCalculator"
const IS_A_JUMP_CALCULATOR := true

# FIXME: LEFT OFF HERE: ---------------------------------------------------------A
# FIXME: -----------------------------
# 
# - Fix a bug where jump falls way short; from right-end of short-low floor to bottom-end of short-high-right-side wall.
# 
# - Add some simple loading screen improvements:
#   - Add a message underneath the initial splash screen:
#     - "Waiting on Godot"
#     - Include the Godot logo.
#   - Create a second, custom version of the splash screen:
#     - "Calculating platform graph"
#     - As a Godot scene.
#     - Show it after downloading, during my PlatformGraph parsing.
# 
# - Will need to add an additional section in the debug menu for displaying analytics info.
#   - Can probably also integrate some info into the tree for debugged trajectories.
#   - Take this opportunity to also start adding the toggle support for annotations.
# 
# - Analytics!
#   - Figure out how/where to store this.
#     - Don't just keep all step debug state--too much.
#     - In particular, don't keep any PositionAlongSurface references--would break deduping in
#       PlatformGraph.
#   - Log a bit of metadata and duration info on every calculated edge attempt, such as:
#     - number of attempted steps,
#     - types of steps,
#     - number of collisions,
#     - number of backtracking attempts,
#   - Then put together some interesting aggregations, such as:
#     - time spent calculating each edge,
#     - Avg time spent calculating each different type of edge,
#     - how many collisions on avg for jump/fall,
#     - ...
#   - Try to use these analytics to inform decisions around which calculations are worth it.
#   - Maybe add a new configuration for max number of collisions/intermediate-waypoints to allow
#     in an edge calculation before giving up (or, recursion depth (with and without backtracking))?
#   - Tweak movement_params.exceptional_jump_instruction_duration_increase, and ensure
#     that it is actually cutting down on the number of times we have to backtrack.
# 
# - When "backtracking" for height, re-use all previous waypoints, but reset their times and
#   maybe velocities.
#   - This should actually mean that we no longer "backtrack"/recurse specially.
#   - Conditionally use this approach behind a movement_params flag. This should improve
#     efficiency and decrease accuracy.
#   - Then also add another flag for whether to run a final collision test over the combined
#     steps after calculating the result.
#     - This should be useful, since we'll want to ensure that such calculations don't produce
#       false positives.
# 
# - Debug performance with how many jump/land pairs get returned, and how costly the new extra
#   previous-jump/land-position-distance checks are.
# 
# - Debug all the new jump/land optimization logic.
# 
# - Finish logic to consume Waypoint.needs_extra_jump_duration.
#   - Started, but stopped partway through, with adding this usage in
#     _update_waypoint_velocity_and_time.
# 
# - Check on current behavior of MovementInstructionsUtils.JUMP_DURATION_INCREASE_EPSILON and 
#   MovementInstructionsUtils.MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON.
# 
# --- Debug ---
# 
# - Check whether the dynamic edge optimizations are too expensive.
# 
# - Things to debug:
#   - Jumping from floor of lower-small-block to floor of upper-small-black.
#     - Collision detection isn't correctly detecting the collision with the right-side of the upper block.
#   - Jumping from floor of lower-small-block to far right-wall of upper-small-black.
#   - Jumping from left-wall of upper-small-block to right-wall of upper-small-block.
# 
# >>- Fix how things work when minimizes_velocity_change_when_jumping is true.
#   - [no] Find and move all movement-offset constants to one central location?
#     - MovementInstructionsUtils
#     - WaypointUtils
#     - FrameCollisionCheckUtils
#     - MovementCalcOverallParams
#   >>>- Compare where instructions are pressed/released vs when I expect them.
#   - Step through movement along an edge?
#   >>- Should this be when I implement the logic to force the player's position to match the
#     expected edge positions (with a weighted avg)?
# 
# - Debug edges.
#   - Calculation: Check all edge-cases; look at all expected edge trajectories in each level.
#   - Execution: Check that navigation actually follows paths and executes trajectories as expected.
# 
# - Debug why this edge calculation generates 35 steps...
#   - test_level_long_rise
#   - from top-most floor to bottom-most (wide) floor, on the right side
# 
# - Fix frame collision detection...
#   - Seeing pre-existing collisions when jumping from walls.
#   - Fix collision-detection errors from logs.
#   - Go through levels and verify that all expected edges work.
# 
# - Fix issue where jumping around edge sometimes isn't going far enough; it's clipping the corner.
# 
# - Re-visit GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
# 
# - Fix performance.
#   - Should I almost never be actually storing things in Pool arrays? It seems like I mostly end
#     up passing them around as arguments to functions, to they get copied as values...
# 
# - Adjust cat_params to only allow subsets of EdgeMovementCalculators, in order to test the non-jump edges
# 
# - Test/debug FallMovementUtils.find_a_landing_trajectory (when clicking from an air position).
# 
# --- EASIER BITS ---
# 
# - Figure out how to fix scaling/aliasing in Godot when adjusting to different screen sizes and
#   camera zoom.
# 
# - Update level images:
#   - Make background layers more faded
#   - Make foreground images more wood-like
# 
# - Implement the bits of debug-menu UI to toggle annotations.
#   - Also support adjusting how many previous player positions to render.
#   - Also list controls in the debug menu.
#   - Collision calculation annotator bits.
#   - Add a top-level button to debug menu to hide all annotations.
#     - (grid, clicks, player position, player recent movement, platform graph, ...)
# 
# - Think up ways to make the debug annotations more dynamic/intelligent/useful...
#   - Make jump/land positions (along with start v, and which pairs connect) more discoverable when
#     ctrl+clicking.
#   - A mode to dynamically show next edge debug state while navigating a path?
#     - Maybe the goal here should be to make all the the complexity of the
#       graph/waypoints/alternative-or-failed-branches somehow visible or understandable to others
#       with a quick viewing.
#   - Have a mode that hides all the other background, foreground, and player images, so that we
#     can just show the annotations.
# 
# - In the README, list the types of MovementParams.
# 
# - Prepare a different, more interesting level for demo (some walls connecting to floors too).
# 
# - Put together some illustrative screenshots with special one-off annotations to explain the
#   graph parsing steps in the README.
#   - Use global.DEBUG_STATE.extra_annotations
#   - Screenshots:
#     - A couple surfaces
#     - Show different tiles, to illustrate how surfaces get merged.
#     - All surfaces (different colors)
#     - A couple edges
#     - All edges
#     - 
# 
# ---  ---
# 
# - Add squirrel assets and animation.
#   - Start by copying-over the Piskel squirrel animation art.
#   - Create squirrel parts art in Aseprite.
#   - Create squirrel animation key frames in Godot.
#     - Idle, standing
#     - Idle, climbing
#     - Crawl-walk-sniff
#     - Bounding walk
#     - Climbing up
#     - Climbing down (just run climbing-up in reverse? Probably want to bound down, facing down,
#       as opposed to cat. Will make transition weird, but whatever?)
#     - 
# 
# ---  ---
# 
# - Loading screen
#   - While downloading, and while parsing level graph
#   - Hand-animated pixel art
#   - Simple GIF file
#   - Host/load/show separately from the rest of the JavaScript and assets
#   - Squirrels digging-up/eating tulips
# 
# - Welcome screen
#   - Hand-animated pixel art
#   x- Gratuitous whooshy sliding shine and a sparkle at the end
#   x- With squirrels running and climbing over the letters?
#   >- Approach:
#     - Start simple. Pick font. Render in Inkscape. Create a hand-pixel-drawn copy in Aseprite.
#     - V1: Show "Squirrel Away" text. Animate squirrel running across, right to left, in front of letters.
#     - V2: Have squirrel pause to the left of the S, with its tail overlapping the S. Give a couple tail twitches. Then have squirrel leave.
#     
# ---  ---
# 
# - Update some edge calculators to offset the expected near-side, far-side, close-side, top-side,
#   bottom-side, etc. jump-off/land-on position calculations to account for neighbor surfaces that
#   would get in the way.
# 
# - Add better annotation selection.
#   - Add shortcuts for toggling debugging annotations
#     - Add support for triggering the calc-step annotations based on a shortcut.
#       - i
#       - also, require clicking on the start and end positions in order to select which edge to
#         debug
#         - Use this _in addition to_ the current top-level configuration for specifying which edge
#           to calculate?
#       - also, then only actually calculate the edge debug state when using this click-to-specify
#         debug mode
#     - also, add other shortcuts for toggling other annotations:
#       - whether all surfaces are highlighted
#       - whether the player's position+collision boundary are rendered
#       - whether the player's current surface is rendered
#       - whether all edges are rendered
#       - whether grid boundaries+indices are rendered
#       - whether the ruler is rendered
#       - whether the actual level tilemap is rendered
#       - whether the background is rendered
#       - whether the actual players are rendered
#     - create a collapsible dat.GUI-esque menu at the top-right that lists all the possible
#       annotation configuration options
#       - set up a nice API for creating these, setting values, listening for value changes, and
#         defining keyboard shortcuts.
#   - Use InputMap to programatically add keybindings.
#     - This should enable our framework to setup all the shortcuts it cares about, without
#       consumers needing to ever redeclare anything in their project settings.
#     - This should also enable better API design for configuring keybindings and menu items from
#       the same place.
#     - https://godot-es-docs.readthedocs.io/en/latest/classes/class_inputmap.html#class-inputmap
# 
# - Finish remaining surface-closest-point-jump-off calculation cases.
#   - Also, maybe still not quite far enough with the offset?
# 
# - Implement fall-through/walk-through movement-type utils.
# 
# - Cleanup frame_collison_check_utils:
#   - Clean-up/break-apart/simplify current logic.
#   - Maybe add some old ideas for extra improvements to check_frame_for_collision:
#     - [maybe?] Rather than just using closest_intersection_point, sort all intersection_points, and
#       try each of them in sequence when the first one fails	
#     - [easy to add, might be nice for future] If that also fails, use a completely separate new
#       cheap-and-dirty check-for-collision-in-frame method?	
#       - Check if intersection_points is not-empty.
#       - Sort them by closest in direction of motion (and ignoring behind points).
#       - Iterate through points, trying to get tile index by a slight nudge offset from each
#         intersection point in the direction of motion until one sticks.
#       - Choose surface side just from dominant motion component.
#     - Add a field on the collision class for the type of collision check used
#     - Add another field (or another option for the above field) to indicate that none of the
#       collision checks worked, and this collision is in an error state
#     - Use this error state to abort collision/step/edge calculations (rather than the current
#       approach of returning null, which is the same as with not detecting any collisions at all).
#     - It might be worth adding a check before ray-tracing to check whether the starting point
#       lies within a populated tile in the tilemap, and then trying the other perpendicular
#       offset direction if so. However, this would require configuring a single global tile
#       map that we expect collisions from, and plumbing that tile map through to here.
# 
# - Look into themes, and what default/global theme state I should set up.
# - Look into what sort of anti-aliasing and scaling to do with GUI vs level vs camera/window zoom...
# 
# - Fix the behavior that causes vertical movement along a wall to get sucked slightly toward the
#   wall after passing the end of the wall (assuming the motion was actually touching the wall).
#   - This is not caused by my logic; it's a property of the underlying Godot collision engine.
# 
# - Add a configurable method to the MovementParams API for defining arbitrary weight calculation
#   for each character type (it could do things like strongly prefer certain edge types). 
# 
# - Check FIXMEs in CollisionCheckUtils. We should check on their accuracy now.
# 
# - Add some sort of warning message when the player's run-time velocity is too far from what's
#   expected?
# 




func _init().( \
        NAME, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null

func get_all_inter_surface_edges_from_surface( \
        collision_params: CollisionCalcParams, \
        edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var movement_params := collision_params.movement_params
    var debug_state := collision_params.debug_state
    
    var jump_land_position_results_for_destination_surface := []
    var jump_land_positions_to_consider: Array
    var edge: JumpInterSurfaceEdge
    
    for destination_surface in surfaces_in_jump_range_set:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other Movement type, so we don't handle those
        # cases here.
        
        ###########################################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeMovementCalculator.should_skip_edge_calculation( \
                debug_state, \
                origin_surface, \
                destination_surface):
            continue
        ###########################################################################################
        
        if origin_surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        jump_land_position_results_for_destination_surface.clear()
        
        jump_land_positions_to_consider = \
                JumpLandPositionsUtils.calculate_jump_land_positions_for_surface_pair( \
                        movement_params, \
                        origin_surface, \
                        destination_surface, \
                        self.is_a_jump_calculator)
        
        for jump_land_positions in jump_land_positions_to_consider:
            #######################################################################################
            # Allow for debug mode to limit the scope of what's calculated.
            if EdgeMovementCalculator.should_skip_edge_calculation( \
                    debug_state, \
                    jump_land_positions.jump_position, \
                    jump_land_positions.land_position):
                continue
            
            # Record some extra debug state when we're limiting calculations to a single edge.
            var in_debug_mode: bool = debug_state.in_debug_mode and \
                    debug_state.has("limit_parsing") and \
                    debug_state.limit_parsing.has("edge") != null
            #######################################################################################
            
            if jump_land_positions.less_likely_to_be_valid and \
                    movement_params.skips_jump_land_positions_that_are_less_likely_to_be_valid:
                continue
            
            if !jump_land_positions.is_far_enough_from_other_jump_land_positions( \
                    movement_params, \
                    jump_land_position_results_for_destination_surface, \
                    true, \
                    true):
                # We've already found a valid edge with a land position that's close enough to this
                # land position.
                continue
            
            edge = calculate_edge( \
                    collision_params, \
                    jump_land_positions.jump_position, \
                    jump_land_positions.land_position, \
                    jump_land_positions.velocity_start, \
                    jump_land_positions.needs_extra_jump_duration, \
                    jump_land_positions.needs_extra_wall_land_horizontal_speed, \
                    in_debug_mode)
            
            if edge != null:
                # Can reach land position from jump position.
                edges_result.push_back(edge)
                edge = null
                jump_land_position_results_for_destination_surface.push_back(jump_land_positions)

func calculate_edge( \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        needs_extra_jump_duration := false, \
        needs_extra_wall_land_horizontal_speed := false, \
        in_debug_mode := false) -> Edge:
    var overall_calc_params := EdgeMovementCalculator.create_movement_calc_overall_params( \
            collision_params, \
            position_start, \
            position_end, \
            true, \
            velocity_start, \
            needs_extra_jump_duration, \
            needs_extra_wall_land_horizontal_speed, \
            false, \
            in_debug_mode)
    if overall_calc_params == null:
        return null
    
    return create_edge_from_overall_params(overall_calc_params)

func optimize_edge_jump_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: Edge, \
        in_debug_mode: bool) -> void:
    assert(edge is JumpInterSurfaceEdge)
    
    EdgeMovementCalculator.optimize_edge_jump_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            previous_velocity_end_x, \
            previous_edge, \
            edge, \
            in_debug_mode, \
            self)

func optimize_edge_land_position_for_path( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        edge: Edge, \
        next_edge: IntraSurfaceEdge, \
        in_debug_mode: bool) -> void:
    assert(edge is JumpInterSurfaceEdge)
    
    EdgeMovementCalculator.optimize_edge_land_position_for_path_helper( \
            collision_params, \
            path, \
            edge_index, \
            edge, \
            next_edge, \
            in_debug_mode, \
            self)

func create_edge_from_overall_params( \
        overall_calc_params: MovementCalcOverallParams) -> JumpInterSurfaceEdge:
    var calc_results := MovementStepUtils.calculate_steps_with_new_jump_height( \
            overall_calc_params, \
            null, \
            null)
    if calc_results == null:
        return null
    
    var instructions := \
            MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                    calc_results, \
                    true, \
                    overall_calc_params.destination_position.surface.side)
    var trajectory := MovementTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
            calc_results, \
            instructions)
    
    var velocity_end: Vector2 = calc_results.horizontal_steps.back().velocity_step_end
    
    var edge := JumpInterSurfaceEdge.new( \
            self, \
            overall_calc_params.origin_position, \
            overall_calc_params.destination_position, \
            overall_calc_params.velocity_start, \
            velocity_end, \
            overall_calc_params.needs_extra_jump_duration, \
            overall_calc_params.needs_extra_wall_land_horizontal_speed, \
            overall_calc_params.movement_params, \
            instructions, \
            trajectory)
    
    return edge
