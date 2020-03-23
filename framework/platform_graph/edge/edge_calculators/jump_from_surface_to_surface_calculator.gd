extends EdgeMovementCalculator
class_name JumpFromSurfaceToSurfaceCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "JumpFromSurfaceToSurfaceCalculator"

# FIXME: LEFT OFF HERE: ---------------------------------------------------------A
# FIXME: -----------------------------
# 
# - Add a couple additional things to configure in MovementParams:
#   - Whether or not to ever check for intermediate collisions (and therefore whether to ever recurse during calculations).
#   - Whether to backtrack to consider higher jumps.
#   - Whether to return only the first valid edge between a pair of surfaces, or to return all valid edges.
#     - Rather, break this down:
#       - All jump/land pairs (get_all_jump_land_positions_for_surface)
#       - All start velocities
#   - How much extra jump boost to include beyond whatever is calculated as being needed for the jump.
#     - (This should be separate from any potential hardcoded boost that we include to help make run-time playback be closer to the calculated trajectories).
#   - How much radius to use for collision calculations.
#   - Whether to calculate dynamic departure edges (dynamic start velocity and positions).
# 
# - Analytics!
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
#   - Maybe add a new configuration for max number of collisions/intermediate-constraints to allow
#     in an edge calculation before giving up (or, recursion depth (with and without backtracking))?
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
#     - MovementConstraintUtils
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
# - Debug each EdgeMovementCalculators.
#   - Figure out what to do for FallFromFloorEdge.
#     - We need to on-the-fly detect when the player has left the floor and entered the air.
#     - We need to at-that-point start running the instructions for the fall trajectory.
#     - So FallFromFloorEdge might need to be replaced with two edges? WalkOffFloorEdge, and AirToSurfaceEdge?
# - Adjust cat_params to only allow subsets of EdgeMovementCalculators, in order to test the non-jump edges
# 
# - Test/debug FallMovementUtils.find_a_landing_trajectory (when clicking from an air position).
# 
# --- Expected cut-off for demo date ---
# 
# - Implement the bits of debug-menu UI to toggle annotations.
#   - Also support adjusting how many previous player positions to render.
#   - Also list controls in the debug menu.
#   - Collision calculation annotator bits.
#   - Add a top-level button to debug menu to hide all annotations.
#     - (grid, clicks, player position, player recent movement, platform graph, ...)
# 
# - Make screenshots and diagrams for README.
#   - Use global.DEBUG_STATE.extra_annotations
# 
# - In the README, list the types of MovementParams.
# 
# - Prepare a different, more interesting level for demo (some walls connecting to floors too).
# 
# - Make each background layer more faded. Only interactable foreground should pop so much.
# 
# - Put together some illustrative screenshots with special one-off annotations to explain the
#   graph parsing steps.
#   - A couple surfaces
#   - Show different tiles, to illustrate how surfaces get merged.
#   - All surfaces (different colors)
#   - A couple edges
#   - All edges
#   - 
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




func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null

func get_all_edges_from_surface( \
        collision_params: CollisionCalcParams, \
        edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var movement_params := collision_params.movement_params
    var debug_state := collision_params.debug_state
    
    var jump_positions: Array
    var land_positions: Array
    var velocity_starts: Array
    var edge: JumpFromSurfaceToSurfaceEdge
    
    for destination_surface in surfaces_in_jump_range_set:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other Movement type, so we don't handle those
        # cases here.
        
        if origin_surface == destination_surface:
            # We don't need to calculate edges for the degenerate case.
            continue
        
        jump_positions = EdgeMovementCalculator.get_all_jump_land_positions_for_surface( \
                movement_params, \
                origin_surface, \
                destination_surface.vertices, \
                destination_surface.bounding_box, \
                destination_surface.side, \
                movement_params.jump_boost, \
                true)
        land_positions = EdgeMovementCalculator.get_all_jump_land_positions_for_surface( \
                movement_params, \
                destination_surface, \
                origin_surface.vertices, \
                origin_surface.bounding_box, \
                origin_surface.side, \
                movement_params.jump_boost, \
                false)
        
        for jump_position in jump_positions:
            for land_position in land_positions:
                ###################################################################################
                # Allow for debug mode to limit the scope of what's calculated.
                if EdgeMovementCalculator.should_skip_edge_calculation( \
                        debug_state, \
                        jump_position, \
                        land_position):
                    continue
                
                # Record some extra debug state when we're limiting calculations to a single edge.
                var in_debug_mode: bool = debug_state.in_debug_mode and \
                        debug_state.has("limit_parsing") and \
                        debug_state.limit_parsing.has("edge") != null
                ###################################################################################
                
                velocity_starts = get_jump_velocity_starts( \
                        movement_params, \
                        origin_surface, \
                        jump_position)
                
                
                for velocity_start in velocity_starts:
                    edge = calculate_edge( \
                            collision_params, \
                            jump_position, \
                            land_position, \
                            true, \
                            velocity_start, \
                            false, \
                            in_debug_mode)
                    
                    if edge != null:
                        # Can reach land position from jump position.
                        edges_result.push_back(edge)
                        
                        # For efficiency, only compute one edge per surface pair.
                        break
                
                if edge != null:
                    # For efficiency, only compute one edge per surface pair.
                    break
            
            if edge != null:
                # For efficiency, only compute one edge per surface pair.
                edge = null
                break

# FIXME: LEFT OFF HERE: Move this somewhere else.
func get_edge_to_air( \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: Vector2) -> SurfaceToAirEdge:
    var velocity_start: Vector2 = get_jump_velocity_starts( \
            collision_params.movement_params, \
            position_start.surface, \
            position_start)[0]
    var position_end_wrapper := MovementUtils.create_position_without_surface(position_end)
    var overall_calc_params := EdgeMovementCalculator.create_movement_calc_overall_params( \
            collision_params, \
            position_start, \
            position_end_wrapper, \
            true, \
            velocity_start, \
            false, \
            false)
    if overall_calc_params == null:
        return null
    
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
                    SurfaceSide.NONE)
    var trajectory := MovementTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
            calc_results, \
            instructions)
    
    var velocity_end: Vector2 = calc_results.horizontal_steps.back().velocity_step_end
    
    var edge := SurfaceToAirEdge.new( \
            position_start, \
            position_end, \
            velocity_start, \
            velocity_end, \
            collision_params.movement_params, \
            instructions, \
            trajectory)
    
    return edge

# FIXME: LEFT OFF HERE: ----------------------------------A:
# - Is there a better way I should be simplifying this construction pattern in general to make it
#   easier to reuse with other edge calculators?
static func calculate_edge(
        collision_params: CollisionCalcParams, \
        origin_position: PositionAlongSurface, \
        destination_position: PositionAlongSurface, \
        can_hold_jump_button: bool, \
        velocity_start: Vector2, \
        returns_invalid_constraints: bool, \
        in_debug_mode: bool) -> JumpFromSurfaceToSurfaceEdge:
    var overall_calc_params := EdgeMovementCalculator.create_movement_calc_overall_params( \
            collision_params, \
            origin_position, \
            destination_position, \
            can_hold_jump_button, \
            velocity_start, \
            returns_invalid_constraints, \
            in_debug_mode)
    if overall_calc_params == null:
        return null
    
    return create_edge_from_overall_params( \
            overall_calc_params, \
            origin_position, \
            destination_position)

static func create_edge_from_overall_params( \
        overall_calc_params: MovementCalcOverallParams, \
        origin_position: PositionAlongSurface, \
        destination_position: PositionAlongSurface) -> JumpFromSurfaceToSurfaceEdge:
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
                    destination_position.surface.side)
    var trajectory := MovementTrajectoryUtils.calculate_trajectory_from_calculation_steps( \
            calc_results, \
            instructions)
    
    var velocity_end: Vector2 = calc_results.horizontal_steps.back().velocity_step_end
    
    var edge := JumpFromSurfaceToSurfaceEdge.new( \
            origin_position, \
            destination_position, \
            overall_calc_params.velocity_start, \
            velocity_end, \
            overall_calc_params.movement_params, \
            instructions, \
            trajectory)
    
    return edge

static func get_jump_velocity_starts( \
        movement_params: MovementParams, \
        origin_surface: Surface, \
        jump_position: PositionAlongSurface) -> Array:
    var velocity_starts := []
    
    match origin_surface.side:
        SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
            # Initial velocity when jumping from a wall is slightly outward from the wall.
            var velocity_start_x := movement_params.wall_jump_horizontal_boost if \
                    origin_surface.side == SurfaceSide.LEFT_WALL else \
                    -movement_params.wall_jump_horizontal_boost
            velocity_starts.push_back(Vector2(velocity_start_x, movement_params.jump_boost))
            
        SurfaceSide.FLOOR, SurfaceSide.CEILING:
            var can_reach_half_max_speed := origin_surface.bounding_box.size.x > \
                    movement_params.distance_to_half_max_horizontal_speed
            var is_first_point: bool = Geometry.are_points_equal_with_epsilon( \
                    jump_position.target_projection_onto_surface, origin_surface.first_point)
            var is_last_point: bool = Geometry.are_points_equal_with_epsilon( \
                    jump_position.target_projection_onto_surface, origin_surface.last_point)
            var is_mid_point: bool = !is_first_point and !is_last_point
            
            # Determine whether to calculate jumping with max horizontal speed.
            if movement_params.calculates_edges_with_velocity_start_x_max_speed and \
                    can_reach_half_max_speed and !is_mid_point:
                if is_first_point:
                    velocity_starts.push_back(
                            Vector2(-movement_params.max_horizontal_speed_default if \
                                    origin_surface.side == SurfaceSide.FLOOR else \
                                    movement_params.max_horizontal_speed_default, \
                                    movement_params.jump_boost))
                elif is_last_point:
                    velocity_starts.push_back(
                            Vector2(movement_params.max_horizontal_speed_default if \
                            origin_surface.side == SurfaceSide.FLOOR else \
                            -movement_params.max_horizontal_speed_default, \
                            movement_params.jump_boost))
            
            # Determine whether to calculate jumping with zero horizontal speed.
            if movement_params.calculates_edges_from_surface_ends_with_velocity_start_x_zero or \
                    is_mid_point:
                velocity_starts.push_back(Vector2(0.0, movement_params.jump_boost))
            
        _:
            Utils.error()
    
    return velocity_starts

static func optimize_edge_for_approach( \
        collision_params: CollisionCalcParams, \
        path: PlatformGraphPath, \
        edge_index: int, \
        previous_velocity_end_x: float, \
        previous_edge: IntraSurfaceEdge, \
        edge: JumpFromSurfaceToSurfaceEdge, \
        in_debug_mode: bool) -> void:
    # TODO: Refactor this to use a true binary search. Right now it is similar, but we never
    #       move backward once we find a working jump.
    var jump_ratios := [0.0, 0.5, 0.75, 0.875]
    
    var movement_params := collision_params.movement_params
    
    var previous_edge_displacement := previous_edge.end - previous_edge.start
    
    var is_horizontal_surface := \
            previous_edge.start_surface != null and \
            (previous_edge.start_surface.side == SurfaceSide.FLOOR or \
            previous_edge.start_surface.side == SurfaceSide.CEILING)
    
    if is_horizontal_surface:
        # Jumping from a floor or ceiling.
        
        var is_already_exceeding_max_speed_toward_displacement := \
                (previous_edge_displacement.x >= 0.0 and previous_velocity_end_x > \
                        movement_params.max_horizontal_speed_default) or \
                (previous_edge_displacement.x <= 0.0 and previous_velocity_end_x < \
                        -movement_params.max_horizontal_speed_default)
        
        var acceleration_x := movement_params.walk_acceleration if \
                previous_edge_displacement.x >= 0.0 else \
                -movement_params.walk_acceleration
        
        var jump_position: PositionAlongSurface
        var optimized_edge: JumpFromSurfaceToSurfaceEdge
        
        for i in range(jump_ratios.size()):
            if jump_ratios[i] == 0.0:
                jump_position = previous_edge.start_position_along_surface
            else:
                jump_position = MovementUtils.create_position_offset_from_target_point( \
                        Vector2(previous_edge.start.x + \
                                previous_edge_displacement.x * jump_ratios[i], 0.0), \
                        previous_edge.start_surface, \
                        movement_params.collider_half_width_height)
            
            # Calculate the start velocity to use according to the available ramp-up
            # distance and max speed.
            var velocity_start_x: float = MovementUtils.calculate_velocity_end_for_displacement( \
                    jump_position.target_point.x - previous_edge.start.x, \
                    previous_velocity_end_x, \
                    acceleration_x, \
                    movement_params.max_horizontal_speed_default)
            var velocity_start_y := movement_params.jump_boost
            var velocity_start = Vector2(velocity_start_x, velocity_start_y)
            
            optimized_edge = calculate_edge( \
                    collision_params, \
                    jump_position, \
                    edge.end_position_along_surface, \
                    true, \
                    velocity_start, \
                    false, \
                    in_debug_mode)
            
            if optimized_edge != null:
                optimized_edge.is_bespoke_for_path = true
                
                previous_edge = IntraSurfaceEdge.new( \
                        previous_edge.start_position_along_surface, \
                        jump_position, \
                        Vector2(previous_velocity_end_x, 0.0), \
                        movement_params)
                
                path.edges[edge_index - 1] = previous_edge
                path.edges[edge_index] = optimized_edge
                
                return
        
    else:
        # Jumping from a wall.
        
        var jump_position: PositionAlongSurface
        var velocity_start: Vector2
        var optimized_edge: JumpFromSurfaceToSurfaceEdge
        
        for i in range(jump_ratios.size()):
            if jump_ratios[i] == 0.0:
                jump_position = previous_edge.start_position_along_surface
            else:
                jump_position = MovementUtils.create_position_offset_from_target_point( \
                        Vector2(0.0, previous_edge.start.y + \
                                previous_edge_displacement.y * jump_ratios[i]), \
                        previous_edge.start_surface, \
                        movement_params.collider_half_width_height)
            
            velocity_start = get_jump_velocity_starts( \
                    movement_params, \
                    jump_position.surface, \
                    jump_position)[0]
            
            optimized_edge = calculate_edge( \
                    collision_params, \
                    jump_position, \
                    edge.end_position_along_surface, \
                    true, \
                    velocity_start, \
                    false, \
                    in_debug_mode)
            
            if optimized_edge != null:
                optimized_edge.is_bespoke_for_path = true
                
                previous_edge = IntraSurfaceEdge.new( \
                        previous_edge.start_position_along_surface, \
                        jump_position, \
                        Vector2.ZERO, \
                        movement_params)
                
                path.edges[edge_index - 1] = previous_edge
                path.edges[edge_index] = optimized_edge
                
                return
