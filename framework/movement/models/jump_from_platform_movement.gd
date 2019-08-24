extends Movement
class_name JumpFromPlatformMovement

const MovementCalcGlobalParams := preload("res://framework/movement/models/movement_calculation_global_params.gd")

# FIXME: SUB-MASTER LIST ***************
# - Add support for specifying a required min/max end-x-velocity.
#   - More notes in the backtracking method.
# - Test support for specifying a required min/max end-x-velocity.
# 
# - Add support for pressing away from the destination in order to slow down enough to not overshoot it.
#   - 
# - Test support for pressing away from the destination in order to slow down enough to not overshoot it.
# 
# - Fix false-negative for long-rise floor-to-floor jumping up-and-left.
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
# - Set the destination_constraint min_velocity_x and max_velocity_x at the start, in order to latch onto the target surface.
#   - Also add support for specifying min/max y velocities for this?
# 
# FIXME: B:
# - Should we more explicity re-use all vertical steps from before the jump button was released?
#   - It might simplify the logic for checking for previously collided surfaces, and make things more efficient.
# 
# FIXME: A: Check if we need to update following constraints when creating a new one:
# - Unfortunately, it is possible that the creation of a new intermediate constraint could
#   invalidate the actual_velocity_x for the following constraint(s). A fix for this would be
#   to first recalculate the min/max x velocities for all following constraints in forward
#   order, and then recalculate the actual x velocity for all following constraints in reverse
#   order.


# FIXME: LEFT OFF HERE: ---A
# - Implement support for skipping a constraint:
#   - Needs to be detected in the constraint-creation logic.
#   - Then needs to be handled in the recursion logic.
#   - When to skip:
#     - # If the direction of travel is the same as the side of the surface that the
#       # constraint lies on, then we'll keep the constraint. Otherwise, we'll skip the constraint.
#     - if (horizontal displacement sign from previous_constraint to new_constraint == -1) == should_stay_on_min_side:
#       - # Skip logic...
#       - FIXME: LEFT OFF HERE
#     - ADAPT FOR DOCS:
#       - PROBLEM: Sometimes we should be able to skip a constraint and go straight from the
#         earlier one to the later one.
#         - Example scenario:
#           - Origin is constraint #0, Destination is constraint #3
#           - Assume we are jumping from low-left platform to high-right platform, and there
#             is an intermediate block in the way.
#           - Our first step attempt hits the underside of the block, so we try constraints on
#             either side.
#           - After trying the left-hand constraint (#1), we then hit the left side of the
#             block. So we then try a top-side constraint (#2). (bottom-side fails the
#             surface-already-encountered check).
#           - After going through this new left-side (right-wall), top-side constraint, we can
#             successfully reach the destination.
#           - Problem 1: With the resulting path, we still have to go through both of the
#             constraints. We should should be able to skip the first constraint and go
#             straight from the origin to the second constraint.
#           - Problem 2: With the current plan-of-attack with this design, we would be forced
#             to be going leftward when we pass through the first constraint.
#       - SOLUTION:
#         - If horizontal _movement_ (displacement) direction from #0 to #1 is opposite from
#           what the normal surface-side-based constraint-pass-through-direction calculation
#           would yield, then ... [is this a constraint we should skip?]




# FIXME: LEFT OFF HERE: -------------------------------------------------A
# 
# - Fix the issue with min/max x-velocity calculations when updating constraints.
# 
# - Check that global_calc_params.collided_surfaces is handled correctly:
#   - QUESTION/PROBLEM: Regarding the current backtracking
#     logic and disallowal of hitting previous surfaces:
#     - What's to stop a new jump-height calculation from still running into the
#       same old wall constraint as before, when we hit the wall before letting
#       go of jump?
#     - I'm pretty sure nothing is.
#     **- SOLUTION: Move the global_calc_params.collided_surfaces assignment and
#       access to helper functions.
#       - In the assignment function, check whether the jump button would still
#         be pressed:
#         - If so, then record the surface on list A: on this list any future
#           encounter of the surface fails, regardless.
#         - Else, list B: recording on this list uses a string value for the key,
#           which is based on both the surface params and on the current
#           jump-release time.
#       - In the access function, the appropriate list is checked.
# 
# - Polish description of approach in the README.
#   - In general, a guiding heuristic in these calculations is to minimize movement. So, through each constraint (step-end), we try to minimize the horizontal speed of the movement at that point.
# 




func _init(params: MovementParams).("jump_from_platform", params) -> void:
    self.can_traverse_edge = true
    self.can_traverse_to_air = true
    self.can_traverse_from_air = false

func get_all_edges_from_surface(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, possible_surfaces: Array, a: Surface) -> Array:
    var jump_positions: Array
    var land_positions: Array
    var terminals: Array
    var instructions: MovementInstructions
    var edges := []
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall *= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_ascent *= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var velocity_start := Vector2(0.0, params.jump_boost)
    var global_calc_params := \
            MovementCalcGlobalParams.new(params, space_state, surface_parser, velocity_start)
    
    for b in possible_surfaces:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other Movement type, so we don't handle those
        # cases here.
        
        if a == b:
            continue
        
        # FIXME: D:
        # - Do a cheap bounding-box distance check here, before calculating any possible jump/land
        #   points.
        # - Don't forget to also allow for fallable surfaces (more expensive).
        # - This is still cheaper than considering all 9 jump/land pair instructions, right?
        
        jump_positions = MovementUtils.get_all_jump_positions_from_surface( \
                params, a, b.vertices, b.bounding_box)
        land_positions = MovementUtils.get_all_jump_positions_from_surface( \
                params, b, a.vertices, a.bounding_box)

        for jump_position in jump_positions:
            for land_position in land_positions:
                # FIXME: E: DEBUGGING: Remove.
                if a.side != SurfaceSide.FLOOR or b.side != SurfaceSide.FLOOR:
                    # Ignore non-floor surfaces.
                    continue
                elif jump_position != jump_positions.back() or \
                        land_position != land_positions.back():
                    # Ignore non-far-ends.
                    continue
                elif a.vertices[0] != Vector2(128, 64):
                    # Ignore anything but the one origin surface we are debugging.
                    continue
                elif b.vertices[0] != Vector2(-128, -448):
                    # Ignore anything but the one destination surface we are debugging.
                    continue
                
                terminals = MovementConstraintUtils.create_terminal_constraints(a, \
                        jump_position.target_point, b, land_position.target_point, params, \
                        velocity_start, true)
                if terminals.empty():
                    continue
                
                global_calc_params.origin_constraint = terminals[0]
                global_calc_params.destination_constraint = terminals[1]
                
                instructions = _calculate_jump_instructions(global_calc_params)
                if instructions != null:
                    # Can reach land position from jump position.
                    edges.push_back(InterSurfaceEdge.new( \
                            jump_position, land_position, instructions))
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall /= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_ascent /= \
            MovementInstructionsUtils.GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, position_start: PositionAlongSurface, \
        position_end: Vector2) -> MovementInstructions:
    var velocity_start := Vector2(0.0, params.jump_boost)
    var global_calc_params := \
            MovementCalcGlobalParams.new(params, space_state, surface_parser, velocity_start)
    
    var terminals := MovementConstraintUtils.create_terminal_constraints(position_start.surface, \
            position_start.target_point, null, position_end, params, velocity_start, true)
    if terminals.empty():
        null
    
    global_calc_params.origin_constraint = terminals[0]
    global_calc_params.destination_constraint = terminals[1]
    
    return _calculate_jump_instructions(global_calc_params)

# Calculates instructions that would move the player from the given start position to the given end
# position.
# 
# This considers interference from intermediate surfaces, and will only return instructions that
# would produce valid movement without intermediate collisions.
static func _calculate_jump_instructions( \
        global_calc_params: MovementCalcGlobalParams) -> MovementInstructions:
    var calc_results := MovementStepUtils.calculate_steps_with_new_jump_height(global_calc_params)
    
    if calc_results == null:
        return null
    
    var instructions: MovementInstructions = \
            MovementUtils.convert_calculation_steps_to_movement_instructions( \
                    global_calc_params.origin_constraint.position, \
                    global_calc_params.destination_constraint.position, calc_results)
    
    if Utils.IN_DEV_MODE:
        MovementInstructionsUtils.test_instructions(instructions, global_calc_params, calc_results)
    
    return instructions
