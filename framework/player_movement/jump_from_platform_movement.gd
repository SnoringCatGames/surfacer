extends PlayerMovement
class_name JumpFromPlatformMovement

const MovementCalcGlobalParams = preload("res://framework/player_movement/movement_calculation_global_params.gd")
const MovementCalcLocalParams = preload("res://framework/player_movement/movement_calculation_local_params.gd")
const MovementCalcStep = preload("res://framework/player_movement/movement_calculation_step.gd")

# FIXME: LEFT OFF HERE: B ******
# - Should I remove this and force a slightly higher offset to target jump position directly? What
#   about passing through constraints? Would the increased time to get to the position for a
#   wall-top constraint result in too much downward velocity into the ceiling?
# - Or what about the constraint offset margins? Shouldn't those actually address any needed
#   jump-height epsilon? Is this needlessly redundant with that mechanism?
# FIXME: LEFT OFF HERE: D ******** Tweak this
const JUMP_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP / 2.0

const VALID_END_POSITION_DISTANCE_SQUARED_THRESHOLD := 64.0

# FIXME: LEFT OFF HERE: -A ***************
# - Test anything else with our PlayerInstruction test?
# - 
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
# - 
# - Create a pause menu and a level switcher.
# - Create some sort of configuration for specifying a level as well as the set of annotations to use.
#   - Actually use this from the menu's level switcher.
#   - Or should the level itself specify which annotations to use?
# - Adapt one of the levels to just render a human player and then the annotations for all edges
#   that our algorithm thinks the human player can traverse.
#   - Try to render all of the interesting edge pairs that I think I should test for.
# - 
# - Will also want to record some other info for annotations/debugging:
#   - Store on PlayerInstructions (but on MovementCalcStep first, during calculation?).
#   - A polyline representation of the ultimate trajectory, including time-slice-testing and
#     considering constraints.
#   - The ultimate sequence of constraints that were used (these are actually just the start positions of each movementcalcstep).
# - 
# - Step through and double-check each return value parameter individually through the recursion, and each input parameter.
# - 
# - Optimize a bit for collisions with vertical surfaces:
#   - For the top constraint, change the constraint position to instead use the far side of the
#     adjacent top-side/floor surface.
#   - This probably means I should store adjacent Surfaces when originally parsing the Surfaces.
# - After completing all steps, re-visit each and think about whether the approach can be
#   simplified now that we have our current way of thinking with total_duration being the basis
#   for max_height and distance and ...
# - Convert between iterative and recursive?
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
# - 
# - Make some diagrams in InkScape with surfaces, trajectories, and constraints to demonstrate
#   algorithm traversal
#   - Label/color-code parts to demonstrate separate traversal steps
# - Make the 144-cell diagram in InkScape and add to docs.
# - Storing possibly 9 edges from A to B.

func _init(params: MovementParams).("jump_from_platform", params) -> void:
    self.can_traverse_edge = true
    self.can_traverse_to_air = true
    self.can_traverse_from_air = false

func get_all_edges_from_surface(space_state: Physics2DDirectSpaceState, a: Surface) -> Array:
    var player_half_width := params.collider_half_width_height.x
    var player_half_height := params.collider_half_width_height.y
    var a_start: Vector2 = a.vertices[0]
    var a_end: Vector2 = a.vertices[a.vertices.size() - 1]
    var b_start: Vector2
    var b_end: Vector2
    var a_near_end: Vector2
    var a_far_end: Vector2
    var a_closest_point: Vector2
    var b_near_end: Vector2
    var b_far_end: Vector2
    var b_closest_point: Vector2
    var possible_jump_points: Array
    var possible_land_points: Array
    var possible_jump_land_pairs := []
    var jump_point: Vector2
    var land_point: Vector2
    var jump_position := PositionAlongSurface.new()
    var land_position := PositionAlongSurface.new()
    var instructions: PlayerInstructions
    var weight: float
    var edges = []
    
    var global_calc_params := MovementCalcGlobalParams.new(params, space_state)
    
    var possible_surfaces := _get_nearby_and_fallable_surfaces(a)
    
    for b in possible_surfaces:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other PlayerMovement type, so we don't handle those
        # cases here.
        
        if a == b:
            continue
        
        global_calc_params.destination_surface = b
        
        b_start = b.vertices[0]
        b_end = b.vertices[b.vertices.size() - 1]
        
        # FIXME: D:
        # - Do a cheap bounding-box distance check here, before calculating any possible jump/land
        #   points.
        # - Don't forget to also allow for fallable surfaces (more expensive).
        # - This is still cheaper than considering all 9 jump/land pair instructions, right?
        
        # Use a bounding-box heuristic to determine which end of the surfaces are likely to be
        # nearer and farther.
        if Geometry.distance_squared_from_point_to_rect(a_start, b.bounding_box) < \
                Geometry.distance_squared_from_point_to_rect(a_end, b.bounding_box):
            a_near_end = a_start
            a_far_end = a_end
        else:
            a_near_end = a_end
            a_far_end = a_start
        if Geometry.distance_squared_from_point_to_rect(b_start, a.bounding_box) < \
                Geometry.distance_squared_from_point_to_rect(b_end, a.bounding_box):
            b_near_end = b_start
            b_far_end = b_end
        else:
            b_near_end = b_end
            b_far_end = b_start
        
        # The actual clostest points along each surface could be somewhere in the middle.
        a_closest_point = \
            Geometry.get_closest_point_on_polyline_to_polyline(a.vertices, b.vertices)
        b_closest_point = \
            Geometry.get_closest_point_on_polyline_to_polyline(b.vertices, a.vertices)
        
        # Only consider the far-end and closest points if they are distinct.
        possible_jump_points = [a_near_end]
        possible_land_points = [b_near_end]
        if a.vertices.size() > 1:
            possible_jump_points.push_back(a_far_end)
        if a_closest_point != a_near_end and a_closest_point != a_far_end:
            possible_jump_points.push_back(a_closest_point)
        if b.vertices.size() > 1:
            possible_land_points.push_back(b_far_end)
        if b_closest_point != b_near_end and b_closest_point != b_far_end:
            possible_land_points.push_back(b_closest_point)
        
        # Calculate the pairs of possible jump and land points to check.
        possible_jump_land_pairs.clear()
        for possible_jump_point in possible_jump_points:
            for possible_land_point in possible_land_points:
                possible_jump_land_pairs.push_back(possible_jump_point)
                possible_jump_land_pairs.push_back(possible_land_point)
        
        # FIXME: LEFT OFF HERE: D *********** Remove. This is for debugging.
        if a.side != SurfaceSide.FLOOR or b.side != SurfaceSide.FLOOR:
            continue
        else:
            possible_jump_land_pairs = [a_near_end, b_near_end]
        
        for i in range(possible_jump_land_pairs.size() - 1):
            jump_point = possible_jump_land_pairs[i]
            land_point = possible_jump_land_pairs[i + 1]
            
            jump_position.match_surface_target_and_collider(a, jump_point, \
                    params.collider_half_width_height)
            land_position.match_surface_target_and_collider(b, land_point, \
                    params.collider_half_width_height)
            global_calc_params.position_start = jump_position.target_point
            global_calc_params.position_end = land_position.target_point
            instructions = _calculate_jump_instructions(global_calc_params)
            if instructions != null:
                edges.push_back(PlatformGraphEdge.new(jump_position, land_position, instructions))
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        position_start: PositionAlongSurface, position_end: Vector2) -> PlayerInstructions:
    var global_calc_params := MovementCalcGlobalParams.new(params, space_state)
    global_calc_params.position_start = position_start.target_point
    global_calc_params.position_end = position_end
    
    return _calculate_jump_instructions(global_calc_params)

# Calculates instructions that would move the player from the given start position to the given end
# position.
# 
# This considers interference from intermediate surfaces, and will only return instructions that
# would produce valid movement without intermediate collisions.
func _calculate_jump_instructions( \
        global_calc_params: MovementCalcGlobalParams) -> PlayerInstructions:
    var calc_results := _calculate_steps_with_new_jump_height( \
            global_calc_params, global_calc_params.position_end, null)
    
    if calc_results == null:
        return null
    
    var instructions := \
            _convert_calculation_steps_to_player_instructions(global_calc_params, calc_results)
    
    if Utils.IN_DEV_MODE:
        _test_instructions(instructions, global_calc_params)
    
    return instructions

# Test that the given instructions were created correctly.
func _test_instructions(instructions: PlayerInstructions, \
        global_calc_params: MovementCalcGlobalParams) -> bool:
    assert(instructions.instructions.size() > 0)
    assert(instructions.instructions.size() % 2 == 0)
    
    assert(instructions.instructions[0].time == 0.0)
    
    var collision := _check_instructions_for_collision(global_calc_params, instructions)
    assert(collision == null or collision.surface == global_calc_params.destination_surface)
    var final_frame_position := instructions.frame_positions[instructions.frame_positions.size() - 1]
    # FIXME: LEFT OFF HERE: ---------------A
#    assert(final_frame_position.distance_squared_to(global_calc_params.position_end) < \
#            VALID_END_POSITION_DISTANCE_SQUARED_THRESHOLD)
    
    return true

# Calculates movement steps to reach the given destination.
# 
# This first calculates the one vertical step of the overall movement, using the minimum possible
# peak jump height. It then calculates the horizontal steps.
# 
# This can trigger recursive calls if horizontal movement cannot be satisfied without backtracking
# to consider a new higher jump height.
func _calculate_steps_with_new_jump_height(global_calc_params: MovementCalcGlobalParams, \
        local_position_end: Vector2, \
        upcoming_constraint: MovementConstraint) -> MovementCalcResults:
    var local_calc_params := \
            _calculate_vertical_step(global_calc_params.position_start, local_position_end)
    
    if local_calc_params == null:
        # The destination is out of reach.
        return null
        
    local_calc_params.upcoming_constraint = upcoming_constraint
    
    return _calculate_steps_from_constraint(global_calc_params, local_calc_params)

# Recursively calculates a list of movement steps to reach the given destination.
# 
# Normally, this function deals with horizontal movement steps. However, if we find that a
# constraint cannot be satisfied with just horizontal movement, we may backtrack and try a new
# recursive traversal using a higher jump height.
func _calculate_steps_from_constraint(global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams) -> MovementCalcResults:
    ### BASE CASES
    
    var next_horizontal_step := _create_horizontal_step(local_calc_params, global_calc_params)
    
    if next_horizontal_step == null:
        # The destination is out of reach.
        return null
    
    var collision := _check_horizontal_step_for_collision(global_calc_params, local_calc_params, \
            next_horizontal_step)
    
    if collision == null or collision.surface == global_calc_params.destination_surface:
        # There is no intermediate surface interfering with this movement, or we've reached the
        # destination surface.
        return MovementCalcResults.new([next_horizontal_step], local_calc_params.vertical_step)
    
    if global_calc_params.collided_surfaces.has(collision.surface):
        # We've already considered a collision with this surface, so this movement won't work.
        # Without this check, we'd recurse through a traversal branch that is identical to one
        # we've already considered, and we'd loop infinitely.
        return null
    
    ### RECURSIVE CASES
    
    global_calc_params.collided_surfaces[collision.surface] = true
    
    # Calculate possible constraints to divert the movement around either side of the colliding
    # surface.
    var constraints := \
            _calculate_constraints(collision.surface, global_calc_params.constraint_offset)
    
    # First, try to satisfy the constraints without backtracking to consider a new max jump height.
    var calc_results := _calculate_steps_from_constraint_without_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)
    if calc_results != null:
        return calc_results
    
    # Then, try to satisfy the constraints with backtracking to consider a new max jump height.
    return _calculate_steps_from_constraint_with_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)

# Check whether either constraint can be satisfied with our current max jump height.
func _calculate_steps_from_constraint_without_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    
    # FIXME: LEFT OFF HERE: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # Recurse: Calculate movement to the constraint.
        local_calc_params_to_constraint = MovementCalcLocalParams.new( \
                local_calc_params.position_start, constraint.passing_point, \
                local_calc_params.previous_step, local_calc_params.vertical_step, constraint)
        calc_results_to_constraint = _calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_to_constraint)
        
        if calc_results_to_constraint == null:
            # This constraint is out of reach.
            continue
        
        # Recurse: Calculate movement from the constraint to the original destination.
        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint.passing_point, local_calc_params.position_end, \
                calc_results_to_constraint.horizontal_steps.back(), 
                local_calc_params.vertical_step, null)
        calc_results_from_constraint = _calculate_steps_from_constraint(global_calc_params, \
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
func _calculate_steps_from_constraint_with_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    var duration_from_constraint: float
    
    # FIXME: LEFT OFF HERE: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # Recurse: Backtrack and try a higher jump (to the constraint).
        calc_results_to_constraint = _calculate_steps_with_new_jump_height( \
                global_calc_params, constraint.passing_point, constraint)
        
        if calc_results_to_constraint == null:
            # The constraint is out of reach.
            continue
        
        # Update the total duration to include the fall duration after the constraint.
        duration_from_constraint = _calculate_end_time_for_jumping_to_position( \
                calc_results_to_constraint.vertical_step, local_calc_params.position_end, \
                local_calc_params.upcoming_constraint, global_calc_params.destination_surface)
        calc_results_to_constraint.vertical_step.time_step_end += duration_from_constraint
        _update_vertical_end_state_for_time(calc_results_to_constraint.vertical_step, \
                calc_results_to_constraint.vertical_step, 
                calc_results_to_constraint.vertical_step.time_step_end, true)
        
        # Recurse: Calculate movement from the constraint to the original destination.
        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint.passing_point, local_calc_params.position_end, \
                calc_results_to_constraint.horizontal_steps.back(), \
                calc_results_to_constraint.vertical_step, null)
        calc_results_from_constraint = _calculate_steps_from_constraint(global_calc_params, \
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

# Calculates a new step for the vertical part of the movement and the corresponding total jump
# duration.
func _calculate_vertical_step( \
        position_start: Vector2, position_end: Vector2) -> MovementCalcLocalParams:
    # FIXME: LEFT OFF HERE: B: Account for max y velocity when calculating any parabolic motion.
    
    var total_displacement: Vector2 = position_end - position_start
    var min_vertical_displacement := get_max_upward_distance()
    var duration_to_peak := -params.jump_boost / params.gravity
    
    assert(duration_to_peak > 0)
    
    # Check whether the vertical displacement is possible.
    if min_vertical_displacement > total_displacement.y:
        return null
    
    var horizontal_movement_sign: int
    if total_displacement.x < 0:
        horizontal_movement_sign = -1
    elif total_displacement.x > 0:
        horizontal_movement_sign = 1
    else:
        horizontal_movement_sign = 0
    
    var slow_ascent_gravity := params.gravity * params.ascent_gravity_multiplier
    
    # Calculate how long it will take for the jump to reach some minimum peak height.
    # 
    # This takes into consideration the fast-fall mechanics (i.e., that a slower gravity is applied
    # until either the jump button is released or we hit the peak of the jump)
    var duration_to_reach_upward_displacement: float
    if total_displacement.y < 0:
        # Derivation:
        # - Start with basic equations of motion
        # - v_1^2 = v_0^2 + 2*a_0*(s_1 - s_0)
        # - v_2^2 = v_1^2 + 2*a_1*(s_2 - s_1)
        # - v_2 = 0
        # - s_0 = 0
        # - Do some algebra...
        # - s_1 = (1/2*v_0^2 + a_1*s_2) / (a_1 - a_0)
        var distance_to_release_button_for_shorter_jump := \
                (0.5 * params.jump_boost * params.jump_boost + \
                        params.gravity * total_displacement.y) / \
                (params.gravity - slow_ascent_gravity)
#        assert(distance_to_release_button_for_shorter_jump < 0)# FIXME: Should this be here?
        
        var duration_to_release_button_for_shorter_jump: float = \
                Geometry.solve_for_movement_duration(0, \
                distance_to_release_button_for_shorter_jump, params.jump_boost, \
                slow_ascent_gravity, true, false)
        assert(duration_to_release_button_for_shorter_jump > 0)
        
        # From a basic equation of motion:
        #     v = v_0 + a*t
        var duration_to_reach_peak_after_release := \
                -params.jump_boost - \
                        slow_ascent_gravity * duration_to_release_button_for_shorter_jump / \
                params.gravity
        assert(duration_to_reach_peak_after_release > 0)
        duration_to_reach_upward_displacement = duration_to_release_button_for_shorter_jump + \
                duration_to_reach_peak_after_release
        
    else:
        # We're jumping downward, so we don't need to reach any minimum peak height.
        duration_to_reach_upward_displacement = 0.0
    
    # Calculate how long it will take for the jump to reach some lower destination.
    var duration_to_reach_downward_displacement: float
    if total_displacement.y > 0:
        duration_to_reach_downward_displacement = Geometry.solve_for_movement_duration( \
                position_start.y, position_end.y, params.jump_boost, params.gravity, true, true)
    else:
        duration_to_reach_downward_displacement = 0.0
    
    # FIXME: LEFT OFF HERE: B: Account for max x velocity.
    var duration_to_reach_horizontal_displacement: float = Geometry.solve_for_movement_duration( \
            position_start.x, position_end.x, 0.0, \
            params.in_air_horizontal_acceleration * horizontal_movement_sign, true, true)
    
    # How high we need to jump is determined by the greatest of three durations:
    # - The duration to reach the minimum peak height (i.e., how high upward we must jump to reach
    #   a higher destination).
    # - The duration to reach a lower destination.
    # - The duration to cover the horizontal displacement.
    var total_duration := max(max(duration_to_reach_upward_displacement, \
            duration_to_reach_downward_displacement), \
            duration_to_reach_horizontal_displacement) + JUMP_DURATION_INCREASE_EPSILON
    
    # Given the total duration, calculate the time to release the jump button.
    # 
    # Derivation:
    # - Start with basic equations of motion
    # - s_1 = s_0 + v_0*t_0 + 1/2*a_0*t_0^2
    # - s_2 = s_1 + v_1*t_1 + 1/2*a_1*t_1^2
    # - t_2 = t_0 + t_1
    # - v_1 = v_0 + a_0*t_0
    # - Do some algebra...
    # - 0 = (1/2*(a_1 - a_0))*t_0^2 + (t_2*(a_0 - a_1))*t_0 + (s_0 - s_2 + v_0*t_2 + 1/2*a_1*t_2^2)
    # - Apply quadratic formula to solve for t_0.
    var a := 0.5 * (params.gravity - slow_ascent_gravity)
    var b := total_duration * (slow_ascent_gravity - params.gravity)
    var c := position_start.y - position_end.y + params.jump_boost * total_duration + \
            0.5 * params.gravity * total_duration * total_duration
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position.
        return null
    var discriminant_sqrt := sqrt(discriminant)
    # FIXME: LEFT OFF HERE: Why was I seeing this as 1.xxx when I flipped the +/- discriminant_sqrt
    #        and jump shouldn't have been held at all?
    var t1 := (-b - discriminant_sqrt) / 2 / a
    var t2 := (-b + discriminant_sqrt) / 2 / a
    var time_to_release_jump_button: float
    if t1 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t2
    if t2 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t1
    else:
        time_to_release_jump_button = min(t1, t2)
    
    # Given the time to release the jump button, calculate the time to reach the peak.
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var velocity_at_jump_button_release := \
            params.jump_boost + slow_ascent_gravity * time_to_release_jump_button
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var time_of_peak_height := -velocity_at_jump_button_release / params.gravity
    
    var step := MovementCalcStep.new()
    step.time_start = 0.0
    step.time_instruction_end = time_to_release_jump_button
    step.time_step_end = total_duration
    step.time_of_peak_height = time_of_peak_height
    step.position_start = position_start
    step.position_step_end = Vector2.INF
    step.velocity_start = Vector2(0, params.jump_boost)
    step.velocity_step_end = Vector2.INF
    step.horizontal_movement_sign = horizontal_movement_sign
    _update_vertical_end_state_for_time(step, step, step.time_step_end, true)
    _update_vertical_end_state_for_time(step, step, step.time_instruction_end, false)
    
    return MovementCalcLocalParams.new(position_start, position_end, null, step, null)

# Calculates a new step for the horizontal part of the movement.
func _create_horizontal_step(local_calc_params: MovementCalcLocalParams, \
        global_calc_params: MovementCalcGlobalParams) -> MovementCalcStep:
    var previous_step := local_calc_params.previous_step
    var vertical_step := local_calc_params.vertical_step
    var position_end := local_calc_params.position_end
    
    # Get some start state from the previous step.
    var time_start: float
    var position_start: Vector2
    var velocity_start: Vector2
    if previous_step != null:
        # The next step starts off where the previous step ended.
        time_start = previous_step.time_step_end
        position_start = previous_step.position_step_end
        velocity_start = previous_step.velocity_step_end
    else:
        # If there is no previous step, then get the initial state from the vertical step.
        time_start = vertical_step.time_start
        position_start = vertical_step.position_start
        velocity_start = vertical_step.velocity_start
    
    var time_remaining := vertical_step.time_step_end - time_start
    var displacement: Vector2 = position_end - position_start
    
    var horizontal_movement_sign: int
    if displacement.x < 0:
        horizontal_movement_sign = -1
    elif displacement.x > 0:
        horizontal_movement_sign = 1
    else:
        horizontal_movement_sign = 0
    
    # FIXME: LEFT OFF HERE: B: Account for max x velocity.
    var duration_for_horizontal_displacement: float = Geometry.solve_for_movement_duration( \
            position_start.x, position_end.x, 0.0, \
            params.in_air_horizontal_acceleration * horizontal_movement_sign, true, true)
    
    # Check whether the horizontal displacement is possible.
    if time_remaining < duration_for_horizontal_displacement:
        return null
    
    var time_end := time_start + duration_for_horizontal_displacement
    
    var step := MovementCalcStep.new()
    step.time_start = time_start
    step.time_instruction_end = time_end
    step.position_start = position_start
    step.position_step_end = position_end
    step.velocity_start = Vector2(0.0, velocity_start.y)
    step.velocity_step_end = Vector2(0.0, INF)
    step.horizontal_movement_sign = horizontal_movement_sign
    _update_vertical_end_state_for_time(step, vertical_step, step.time_step_end, true)
    step.time_step_end = _calculate_end_time_for_jumping_to_position( \
            vertical_step, position_end, local_calc_params.upcoming_constraint, \
            global_calc_params.destination_surface)
    
    return step

# Translates movement data from a form that is more useful when calculating the movement to a form
# that is more useful when executing the movement.
func _convert_calculation_steps_to_player_instructions( \
        global_calc_params: MovementCalcGlobalParams, \
        calc_results: MovementCalcResults) -> PlayerInstructions:
    var steps := calc_results.horizontal_steps
    var vertical_step := calc_results.vertical_step
    
    var distance := global_calc_params.position_start.distance_to(global_calc_params.position_end)
    
    var constraint_positions := []
    
    var instructions := []
    instructions.resize((steps.size() + 1) * 2)
    
    var input_key := "jump"
    var press := PlayerInstruction.new(input_key, vertical_step.time_start, true)
    var release := PlayerInstruction.new(input_key, vertical_step.time_instruction_end, false)
    
    instructions[0] = press
    instructions[1] = release
    
    var i := 0
    var step: MovementCalcStep
    for i in range(steps.size()):
        step = steps[i]
        input_key = "move_left" if step.horizontal_movement_sign < 0 else "move_right"
        press = PlayerInstruction.new(input_key, step.time_start, true)
        release = PlayerInstruction.new(input_key, step.time_instruction_end, false)
        instructions[i * 2 + 2] = press
        instructions[i * 2 + 3] = release
        i += 1
        
        # Keep track of some info for edge annotation debugging.
        constraint_positions.push_back(step.position_start)
    
    return PlayerInstructions.new(instructions, vertical_step.time_step_end, distance, \
            constraint_positions)

func get_max_upward_distance() -> float:
    return -(params.jump_boost * params.jump_boost) / 2 / \
            (params.gravity * params.ascent_gravity_multiplier)

func get_max_horizontal_distance() -> float:
    # Take into account the slow gravity of ascent and the fast gravity of descent.
    # FIXME: LEFT OFF HERE: B: Re-calculate this; add a multiplier (x2) to allow for additional
    #        distance when the destination is below.
    return (-params.jump_boost / params.gravity * params.max_horizontal_speed_default) / \
            (1 + params.ascent_gravity_multiplier)
