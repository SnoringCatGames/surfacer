extends PlayerMovement
class_name JumpFromPlatformMovement

const MovementCalcGlobalParams := preload("res://framework/player_movement/movement_calculation_global_params.gd")
const MovementCalcLocalParams := preload("res://framework/player_movement/movement_calculation_local_params.gd")
const MovementCalcStep := preload("res://framework/player_movement/movement_calculation_step.gd")

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

const VALID_END_POSITION_DISTANCE_SQUARED_THRESHOLD := 64.0

# FIXME: B: use this to record slow/fast gravities on the movement_params when initializing and
#        update all usages to use the right one (rather than mutating the movement_params in the
#        middle of edge calculations below).
# FIXME: B: Update step calculation to increase durations by a slight amount (after calculating
#        them all), in order to not have the rendered/discrete trajectory stop short?
# FIXME: B: Update tests to use the new acceleration values.
const GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION := 1.00#1.08

func _init(params: MovementParams).("jump_from_platform", params) -> void:
    self.can_traverse_edge = true
    self.can_traverse_to_air = true
    self.can_traverse_from_air = false

func get_all_edges_from_surface(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, possible_surfaces: Array, a: Surface) -> Array:
    var jump_positions: Array
    var land_positions: Array
    var terminals: Array
    var instructions: PlayerInstructions
    var edges := []
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall *= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_ascent *= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var velocity_start := Vector2(0.0, params.jump_boost)
    var global_calc_params := \
            MovementCalcGlobalParams.new(params, space_state, surface_parser, velocity_start)
    
    for b in possible_surfaces:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other PlayerMovement type, so we don't handle those
        # cases here.
        
        if a == b:
            continue
        
        # FIXME: D:
        # - Do a cheap bounding-box distance check here, before calculating any possible jump/land
        #   points.
        # - Don't forget to also allow for fallable surfaces (more expensive).
        # - This is still cheaper than considering all 9 jump/land pair instructions, right?
        
        jump_positions = get_all_jump_positions_from_surface(params, a, b.vertices, b.bounding_box)
        land_positions = get_all_jump_positions_from_surface(params, b, a.vertices, a.bounding_box)

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
                
                terminals = PlayerMovement.create_terminal_constraints(a, \
                        jump_position.target_point, b, land_position.target_point, params, \
                        velocity_start)
                global_calc_params.origin_constraint = terminals[0]
                global_calc_params.destination_constraint = terminals[1]
                
                instructions = _calculate_jump_instructions(global_calc_params)
                if instructions != null:
                    # Can reach land position from jump position.
                    edges.push_back(InterSurfaceEdge.new( \
                            jump_position, land_position, instructions))
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall /= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_ascent /= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, position_start: PositionAlongSurface, \
        position_end: Vector2) -> PlayerInstructions:
    var velocity_start := Vector2(0.0, params.jump_boost)
    var global_calc_params := \
            MovementCalcGlobalParams.new(params, space_state, surface_parser, velocity_start)
    
    var terminals := PlayerMovement.create_terminal_constraints(position_start.surface, \
            position_start.target_point, null, position_end, params, velocity_start)
    global_calc_params.origin_constraint = terminals[0]
    global_calc_params.destination_constraint = terminals[1]
    
    return _calculate_jump_instructions(global_calc_params)

# Calculates instructions that would move the player from the given start position to the given end
# position.
# 
# This considers interference from intermediate surfaces, and will only return instructions that
# would produce valid movement without intermediate collisions.
static func _calculate_jump_instructions(global_calc_params: MovementCalcGlobalParams) -> PlayerInstructions:
    var calc_results := _calculate_steps_with_new_jump_height(global_calc_params, null)
    
    if calc_results == null:
        return null
    
    var instructions := convert_calculation_steps_to_player_instructions( \
            global_calc_params.origin_constraint.position, \
            global_calc_params.destination_constraint.position, calc_results)
    
    if Utils.IN_DEV_MODE:
        _test_instructions(instructions, global_calc_params, calc_results)
    
    return instructions

# Test that the given instructions were created correctly.
static func _test_instructions(instructions: PlayerInstructions, \
        global_calc_params: MovementCalcGlobalParams, calc_results: MovementCalcResults) -> bool:
    assert(instructions.instructions.size() > 0)
    assert(instructions.instructions.size() % 2 == 0)
    
    assert(instructions.instructions[0].time == 0.0)
    
    # FIXME: B: REMOVE
    global_calc_params.movement_params.gravity_fast_fall /= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    global_calc_params.movement_params.gravity_slow_ascent /= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var collision := CollisionChecks.check_instructions_for_collision(global_calc_params, \
            instructions, calc_results.vertical_step, calc_results.horizontal_steps)
    assert(collision == null or collision.surface == global_calc_params.destination_constraint.surface)
    var final_frame_position := \
            instructions.frame_discrete_positions[instructions.frame_discrete_positions.size() - 1]
    # FIXME: B: Add back in after fixing the use of GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION.
#    assert(final_frame_position.distance_squared_to( \
#            global_calc_params.destination_constraint.position) < \
#            VALID_END_POSITION_DISTANCE_SQUARED_THRESHOLD)

    # FIXME: B: REMOVE
    global_calc_params.movement_params.gravity_fast_fall *= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    global_calc_params.movement_params.gravity_slow_ascent *= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    return true

# Calculates movement steps to reach the given destination.
# 
# This first calculates the one vertical step of the overall movement, using the minimum possible
# peak jump height. It then calculates the horizontal steps.
# 
# This can trigger recursive calls if horizontal movement cannot be satisfied without backtracking
# to consider a new higher jump height.
static func _calculate_steps_with_new_jump_height(global_calc_params: MovementCalcGlobalParams, \
        upcoming_constraint: MovementConstraint) -> MovementCalcResults:
    var local_calc_params := calculate_vertical_step(global_calc_params)
    
    if local_calc_params == null:
        # The destination is out of reach.
        return null
    
    # FIXME: LEFT OFF HERE: ----A: Move this to be inside calculate_vertical_step after working
    # out how to better calculate max height according to both destination constraint and upcoming
    # constraint?
    local_calc_params.end_constraint = upcoming_constraint if upcoming_constraint != null else \
            global_calc_params.destination_constraint
    
    return calculate_steps_from_constraint(global_calc_params, local_calc_params)

# Recursively calculates a list of movement steps to reach the given destination.
# 
# Normally, this function deals with horizontal movement steps. However, if we find that a
# constraint cannot be satisfied with just horizontal movement, we may backtrack and try a new
# recursive traversal using a higher jump height.
static func calculate_steps_from_constraint(global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams) -> MovementCalcResults:
    ### BASE CASES
    
    var next_horizontal_step := calculate_horizontal_step(local_calc_params, global_calc_params)
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE: -A:
    # - Debugging min step-end velocity.
    # - Get the up-left jump from floor to floor working on level long-rise.
    # - Set a breakpoint here.
#    print("yo")
    
    if next_horizontal_step == null:
        # The destination is out of reach.
        return null
    
    var vertical_step := local_calc_params.vertical_step
    
    # If this is the last horizontal step, then let's check whether whether we calculated
    # things correctly.
    if local_calc_params.end_constraint.is_destination:
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.time_step_end, vertical_step.time_step_end, 0.0001))
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.position_step_end.y, vertical_step.position_step_end.y, \
                0.001))
        assert(Geometry.are_points_equal_with_epsilon(next_horizontal_step.position_step_end, \
                global_calc_params.destination_constraint.position, 0.0001))
    
    var collision := CollisionChecks.check_continuous_horizontal_step_for_collision( \
            global_calc_params, local_calc_params, next_horizontal_step)
    
    if collision == null or collision.surface == global_calc_params.destination_constraint.surface:
        # There is no intermediate surface interfering with this movement, or we've reached the
        # destination surface.
        return MovementCalcResults.new([next_horizontal_step], vertical_step)
    
    if global_calc_params.collided_surfaces.has(collision.surface):
        # We've already considered a collision with this surface, so this movement won't work.
        # Without this check, we'd recurse through a traversal branch that is identical to one
        # we've already considered, and we'd loop infinitely.
        return null
    
    ### RECURSIVE CASES
    
    global_calc_params.collided_surfaces[collision.surface] = true
    
    # Calculate possible constraints to divert the movement around either side of the colliding
    # surface.
    var constraints := _calculate_constraints_around_surface(global_calc_params.movement_params, \
            vertical_step, local_calc_params.start_constraint, collision.surface, \
            global_calc_params.constraint_offset)
    
    # First, try to satisfy the constraints without backtracking to consider a new max jump height.
    var calc_results := _calculate_steps_from_constraint_without_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)
    if calc_results != null or !global_calc_params.can_backtrack_on_height:
        return calc_results
    
    # Then, try to satisfy the constraints with backtracking to consider a new max jump height.
    return _calculate_steps_from_constraint_with_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)

# Check whether either constraint can be satisfied with our current max jump height.
static func _calculate_steps_from_constraint_without_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    
    # FIXME: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # Recurse: Calculate movement to the constraint.
        local_calc_params_to_constraint = MovementCalcLocalParams.new( \
                local_calc_params.start_constraint, constraint, \
                local_calc_params.vertical_step)
        calc_results_to_constraint = calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_to_constraint)
        
        if calc_results_to_constraint == null:
            # This constraint is out of reach with the current jump height.
            continue
        
        # Recurse: Calculate movement from the constraint to the original destination.
        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint, local_calc_params.end_constraint, \
                local_calc_params.vertical_step)
        calc_results_from_constraint = calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_from_constraint)
        
        if calc_results_from_constraint != null:
            # We found movement that satisfies the constraint.
            if !calc_results_from_constraint.backtracked_for_new_jump_height:
                # The movement calculations from after the constraint didn't have to backtrack and
                # use a higher jump height.
                Utils.concat(calc_results_to_constraint.horizontal_steps, \
                        calc_results_from_constraint.horizontal_steps)
                return calc_results_to_constraint
            else:
                # The movement calculations from after the constraint had to backtrack and use a
                # higher jump height. This means that these post-constraint results include new
                # steps leading up to the constraint, so we should abandon our previous
                # pre-constraint results.
                return calc_results_from_constraint
    
    # We weren't able to satisfy the constraints around the colliding surface.
    return null

# Check whether either constraint can be satisfied if we backtrack to re-calculate the initial
# vertical step with a higher max jump height.
static func _calculate_steps_from_constraint_with_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    var vertical_step_to_constraint: MovementVertCalcStep
    var end_state: Vector2
    
    # FIXME: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # FIXME: LEFT OFF HERE: -----A
        # - Add support for specifying a required min/max end-x-velocity.
        #   - We need to add support for specifying a desired min end-x-velocity from the previous
        #     horizontal step (by default, all end velocities are as small as possible).
        #   - We can then use this to determine when to start the horizontal movement for the previous
        #     horizontal step (delaying movement start yields a greater end velocity).
        #   - In order to determine the required min end-x-velocity from the previous step, we
        #     must flip the order in which we calculate horizontal steps in the constraint recursion.
        #   - We should be able to just calculate the latter step first, since we know what its start
        #     position and time must be.
        #   - ADDITIONAL CHANGE: We will need to calculate the jump height according to
        #     whether the needed min/max end-x-velocity exceeds the speed cap.
        #     - The current backtracking logic doesn't support this.
        #       - It only addresses the need to increase height according to intermediate
        #         conflicting surfaces.
        #       - So we need to update calculate_vertical_step to support this.
        #         **- Include a new param: post_constraint_destination
        #           - Or maybe just use the global_param destination?
        #         - PROBLEM: Will need to know what the greatest-possible step-end horizontal
        #           velocity will be for the current constraint.
        #           - This will depend on whether we'll have had enough time to hold the sideways
        #             button (since the last constraint position and velocity) in order to reach
        #             the horizontal speed cap.
        #             - I think this means that we will need to record min/max velocity on all
        #               previous constraints and check through them when determining the next?
        #             - Plan exactly what this constraint min/max velocity assignment and access look like.
        #               - [Sketched out more below]
        # 
        #             - FOLLOW-UP CONCERN/QUESTION/PROBLEM: Regarding the current backtracking
        #               logic and disallowal of hitting previous surfaces:
        #               - What's to stop a new jump-height calculation from still running into the
        #                 same old wall constraint as before, when we hit the wall before letting
        #                 go of jump?
        #               - I'm pretty sure nothing is.
        #               **- SOLUTION: Move the global_calc_params.collided_surfaces assignment and
        #                 access to helper functions.
        #                 - In the assignment function, check whether the jump button would still
        #                   be pressed:
        #                   - If so, then record the surface on list A: on this list any future
        #                     encounter of the surface fails, regardless.
        #                   - Else, list B: recording on this list uses a string value for the key,
        #                     which is based on both the surface params and on the current
        #                     jump-release time.
        #                 - In the access function, the appropriate list is checked.
        # 
        #         - We can then use this greatest-possible step-end horizontal velocity to
        #           determine how much longer we'd need to hold the jump button for.
        #   - Whether to use min or max will be dependent on the horizontal_movement_sign.
        #   - Make this part of the MovementConstraint object.
        #   **- Will definitely need to set an offset for this.
        #     - Probably just a constant offset; not too big; will need some tweaking.
        #   - This required min/max end-x-velocity will need to be added to both recursing with and
        #     without backtracking on height.
        #     - Which means that the order inversion (calculate last step first) will happen for
        #       both.
        #   **- Update README with a description of this feature.
        # 
        # Thoughts...
        # **- Need to change jump-height-calculation to choose max of previous-height and height-for-new-constraint.
        # - By default, we are always first considering the min height and the min step-end-x-speed.
        #   - This is affected by jump height.
        #   - But the min jump height produces the min possible step-end-x-speed, so this min is accurate.
        #   - It's possible that the min becomes smaller than we can actually use if we need to increase the jump height.
        #   - However, I don't think that's a problem?
        # - We can then also save with the constraint the max step-end-x-speed.
        #   - 
        # - The min-possible step-end-x-speed is dependent on the jump height.
        #   - Because to get the min speed, we need horizontal movement to be steady over the entire step.
        #   - 
        # - The max-possible step-end-x-speed is dependent on the jump height.
        #   - Because when the jump-button is released changes the amount of time we may have to move horizontally in a step.
        #   -
        # - The jump height is dependent on the max-possible step-end-x-speed.
        #   - Because if we can't move far enough with the given starting x velocity and max
        #     height, then we could move further with a greater max height.
        #   - 
        # - POSSIBLE LIMITING HEURISTIC A:
        #   - Just use the original default jump-release time.
        #   - This could possibly result in "max" speed values that aren't actually as high as they
        #     could be, since an earlier jump-release could give us not enough time to accelerate
        #     to max step-end-speed.
        #     - But this is probably OK, since our first priority is in limiting the jump height to
        #       only what is necessary.
        #   - REVISIT, all this thinking in terms of which steps are actually affected after getting the initial implementation figured out.
        #   - We can calculate the max-possible step-end-x-speed beforehand according to:
        #     - The min-possible and max-possible (directional) step-end-x-velocities of the step-start (the previous step-end).
        #       - This will then depend on us having already calculated the min and max for all previous steps.
        #     - The horizontal displacement of the step.
        #     - The horizontal acceleration.
        #     - The horizontal speed cap.
        # - POSSIBLE LIMITING HEURISTIC B:
        #   - Assume optimal jump-release time for generating the max-possible step-end-x-speed.
        #     - What is this time: Later jump releases in general.
        #       - Since early jump-release can decrease the max-possible step-end-x-speed, since it
        #         could give us not enough time to accelerate to max speed.
        #   - Not a good solution, since this would inflate jump heights.
        #
        # - So, here's a possible ultimate order of events:
        #   - From front to back:
        #     - [stored on vertical step] Calculate minimum possible overall jump-release time.
        #     - [stored on (previous) constraints] Calculate the one and only time for passing through the
        #         constraint.
        #         - There is no separate min and max for this, since this is dependent on where we
        #           are in the vertical movement.
        #         - PROBLEM: How to know whether we are on the ascent or the descent of the jump?
        #           - Is it possible to know the x position of the jump peak?
        #             - Or at least between which constraints the peak occurs?
        #           - Answer: I can compute the durations between constraints using the same step
        #             duration logic I used in the original vertical-step calculations.
        #     - [stored on (previous) constraints] Calculate min and max possible (directional)
        #         step-end-x-velocity for each step.
        #   - From back to front:
        #     - For both traversal versions:
        #       **- [stored on horizontal steps] Calculate steps in reverse order in order to 
        #           require that a given step ends with a certain x velocity.
        #     - For traversal with backtracking only:
        #       **- Use a new post_constraint_destination param passed to the vertical step calc to
        #         support increasing the jump height as needed in order to reach the destination
        #         after the latest constraint.
        #     - [no?] Calculate jump height for each step.
        #       - [no?] This will depend on whether the jump button can still be pressed at the start of the current step.
        #       - [no?] This will probably involve keeping track of the relative jump height needed for just the displacement of the current step.
        #         - [no?] We will probably then need to add some heights together at the end.
        #       - FIXME: LEFT OFF HERE: Should I use any special conditional logic here for considering the different constraint-surface-type cases?
        #         - E.g.:
        #           - Going above a wall:
        #             - Is what I've been basing this approach off of.
        #             - Auto-fail if jump button is already released.
        #           - Going below a wall:
        #             - Auto-fail is jump button is still held.
        #             - Otherwise, min/max step-end-x-velocities should be easy enough to compute.
        #           - Around floor:
        #             - Assert jump button isn't held.
        #             - Should involve same height and min/max step-end-x-speed requirement calculations as walls.
        #             - Would it help at all to refactor destination representation to use a normal Constraint object?
        #               - Then we could treat it the same in terms of surface-type considerations, and needing to reach far enough in a given direction.
        #           - Around ceiling:
        #             - Should involve same height and min/max step-end-x-speed requirement calculations as walls.
        #     - Keep track of the max required value.
        # - Do I need to refactor how the with and without backtracking recursive calls are split apart?
        #   - Either going into the constraint or out of the constraint could require backtracking to get a higher jump height.
        #   - Maybe just start out by creating a new version of the without function, and then add whatever I need from there.
        #   - I _THINK_ that I actually do want to keep them separate now?
        #     - In the version without backtracking, it will only consider the max horizontal speed, and if that's insufficient, fail.
        #     - In the version with backtracking, it will then also consider whether the height
        #       can/should be increased.
        #     - Although, these could still be combined.
        #     - But, I guess the reason for originally splitting, was to not do the expensive
        #       backtracking calculations if a non-backtracking approach with the other constraint
        #       would work.
        #     **- At the very least, document that original motivation!
        # 
        
        # - FIXME: LEFT OFF HERE: C: (after getting current refactor to work with floor-to-floor edges):
        #   - Need to add support for pressing sideways-move-input in opposite direction, in order
        #     to counter too-strong velocity_start.
        
        # FIXME: LEFT OFF HERE: ACTION ITEMS: ---------A
        # **- Update calculate_horizontal_step to use calculate_horizontal_step when needed.
        #   - If needed, we can maybe also calculate this in the initial constraint calc
        #     function with the other min/max value.
        # **- Update both recursive functions to calculate steps from back to front, considering
        #   min/max horizontal velocity.
        # - Update vertical step calc function to use greater of the height from both previous and new constraints.
        # **- [um, is this the wrong place?] Update vertical step calc function to consider max step-end-x-speed.
        #   - Is this all that's needed to support the backtracking version?
        # - Set the destination_constraint min_x_velocity and max_x_velocity at the start, in order to latch onto the target surface.
        #   - Also add support for specifying min/max y velocities for this?
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
        # - Step through and double-check that the correct min/max step state will be calculated at the right places in recursive traversals.
        # - Add logic to quit early for invalid surface collisions?
        # - Move the global_calc_params.collided_surfaces assignment and access to helper functions?
        # - Cleanup/refactor/consolidate the with-and-without-backtracking recursive functions?
        # - Go through above notes/thoughts and make sure all bits are acounted for.
        # - Either support or add a doc+TODO for the other failing backtracking case that I scribbled.
        # - Document approach in the README.
        
        # Recurse: Backtrack and try a higher jump (to the constraint).
        calc_results_to_constraint = \
                _calculate_steps_with_new_jump_height(global_calc_params, constraint)
        
        if calc_results_to_constraint == null:
            # The constraint is out of reach.
            continue
        
        vertical_step_to_constraint = calc_results_to_constraint.vertical_step
        
        # Update the total duration to include the fall duration after the constraint.
        vertical_step_to_constraint.time_step_end = _calculate_end_time_for_jumping_to_position( \
                global_calc_params.movement_params, vertical_step_to_constraint, \
                local_calc_params.end_constraint.position, vertical_step_to_constraint.time_step_end, \
                local_calc_params.end_constraint)
        if vertical_step_to_constraint.time_step_end == INF:
            # The destination is out of reach from the constraint.
            continue
        end_state = calculate_vertical_end_state_for_time(global_calc_params.movement_params, \
                vertical_step_to_constraint, vertical_step_to_constraint.time_step_end)
        vertical_step_to_constraint.position_step_end.y = end_state.x
        vertical_step_to_constraint.velocity_step_end.y = end_state.y
        
        # Recurse: Calculate movement from the constraint to the original destination.
        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint, local_calc_params.end_constraint, \
                vertical_step_to_constraint)
        calc_results_from_constraint = calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_from_constraint)
        
        if calc_results_from_constraint != null:
            # We found movement that satisfies the constraint.
            if !calc_results_from_constraint.backtracked_for_new_jump_height:
                # The movement calculations from after the constraint didn't have to backtrack and
                # use a higher jump height.
            
                # Combine the steps from before and after the constraint.
                Utils.concat(calc_results_to_constraint.horizontal_steps, \
                        calc_results_from_constraint.horizontal_steps)
                
                # Mark this result as having backtracked to re-calculate the previous steps.
                calc_results_to_constraint.backtracked_for_new_jump_height = true
                
                return calc_results_to_constraint
            else:
                # The movement calculations from after the constraint had to backtrack and use a
                # higher jump height. This means that these post-constraint results include new
                # steps leading up to the constraint, so we should abandon our previous
                # pre-constraint results.
                return calc_results_from_constraint
    
    # We weren't able to satisfy the constraints around the colliding surface.
    return null
