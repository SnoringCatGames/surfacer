extends PlayerMovement
class_name JumpFromPlatformMovement

const MovementCalcGlobalParams = preload("res://framework/player_movement/movement_calculation_global_params.gd")
const MovementCalcLocalParams = preload("res://framework/player_movement/movement_calculation_local_params.gd")
const MovementCalcStep = preload("res://framework/player_movement/movement_calculation_step.gd")

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
        
        for i in range(possible_jump_land_pairs.size() - 1):
            jump_point = possible_jump_land_pairs[i]
            land_point = possible_jump_land_pairs[i + 1]
            
            jump_position.match_surface_target_and_collider(a, jump_point, \
                    params.collider_half_width_height)
            land_position.match_surface_target_and_collider(b, land_point, \
                    params.collider_half_width_height)
            instructions = _calculate_jump_instructions( \
                    global_calc_params, jump_position.target_point, land_position.target_point)
            if instructions != null:
                edges.push_back(PlatformGraphEdge.new(jump_position, land_position, instructions))
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        position_start: PositionAlongSurface, position_end: Vector2) -> PlayerInstructions:
    var global_calc_params := MovementCalcGlobalParams.new(params, space_state)
    
    return _calculate_jump_instructions( \
            global_calc_params, position_start.target_point, position_end)

# FIXME: LEFT OFF HERE: --A ********* doc
func _calculate_jump_instructions(global_calc_params: MovementCalcGlobalParams, \
        position_start: Vector2, position_end: Vector2) -> PlayerInstructions:
    var calc_results := \
            _calculate_steps_with_new_jump_height(global_calc_params, position_start, position_end)
    
    if calc_results == null:
        return null
    
    return _convert_calculation_steps_to_player_instructions( \
            calc_results, position_start, position_end)

# FIXME: LEFT OFF HERE: --A ********* doc
func _calculate_steps_with_new_jump_height(global_calc_params: MovementCalcGlobalParams, \
        position_start: Vector2, position_end: Vector2) -> MovementCalcResults:
    var local_calc_params := _calculate_vertical_step(position_start, position_end)
    
    if local_calc_params == null:
        # The destination is out of reach.
        return null
    
    return _calculate_steps_from_constraint(global_calc_params, local_calc_params)
    
    # FIXME: LEFT OFF HERE: -------A *********
    # - Implement max-height backtracking:
    #   - Do create a new helper function for starting new recursive traversal that initializes
    #     vertical step and global_calc_params state.
    #   - Pass-in new parameters for initializing vertical step:
    #     - velocity_start
    #       - make sure we're still using this correctly for calculating the jump_button_end time
    #     - pass-in original start position as well as current start position.
    #     - Maintain set of already-collided surfaces.
    #   - Create a new data structure for returning results.
    #   - Decide how to split apart some parameters and distinguish between local traversal and global.
    #     - MovementCalcGlobalParams will represent global
    #       - Remove vertical_step, total_duration
    #     - Either create a new one for local, or use the new MovementCalcLocalParams

# FIXME: LEFT OFF HERE: -A ********
# - Will also want to record some other info for annotations/debugging:
#   - Store on PlayerInstructions (but on MovementCalcStep first, during calculation?).
#   - A polyline representation of the ultimate trajectory, including time-slice-testing and
#     considering constraints.
#   - The ultimate sequence of constraints that were used.

# FIXME: LEFT OFF HERE: A ***************
# - 
# - Optimize a bit for collisions with vertical surfaces:
#   - For the top constraint, change the constraint position to instead use the far side of the
#     adjacent top-side/floor Surface.
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
# - 
# - Make some diagrams in InkScape with surfaces, trajectories, and constraints to demonstrate
#   algorithm traversal
#   - Label/color-code parts to demonstrate separate traversal steps
# - Make the 144-cell diagram in InkScape and add to docs.
# - Storing possibly 9 edges from A to B.

# FIXME: LEFT OFF HERE: B: Add support for maintaining horizontal speed when falling, and
#        needing to push back the other way to slow it.

# Recursively calculates a list of movement steps to reach the given destination.
# 
# Normally, this function deals with horizontal movement steps. However, if we find that a
# constraint cannot be satisfied with just horizontal movement, we may backtrack and try a new
# recursive traversal using a higher jump height.
func _calculate_steps_from_constraint(global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams) -> MovementCalcResults:
    ### BASE CASES
    
    var next_horizontal_step := _create_horizontal_step(local_calc_params)
    
    # Check whether the destination is within reach of this PlayerMovement.
    if next_horizontal_step == null:
        return null
    
    var colliding_surface := _check_step_for_collision(global_calc_params, local_calc_params, next_horizontal_step)
    
    # Check whether there is no Surface interfering with this PlayerMovement, on whether we've
    # reached the destination Surface.
    if colliding_surface == null or colliding_surface == global_calc_params.destination_surface:
        return MovementCalcResults.new([next_horizontal_step], local_calc_params.vertical_step, \
                local_calc_params.total_duration)
    
    # Check whether we've already considered a collision with this Surface. If so, then this
    # movement won't work.
    if global_calc_params.collided_surfaces.has(colliding_surface):
        return null
    
    ### RECURSIVE CASES
    
    global_calc_params.collided_surfaces[colliding_surface] = true
    
    # Calculate possible constraints to divert the movement around either side of the colliding
    # Surface.
    var constraints := \
            _calculate_constraints(colliding_surface, global_calc_params.constraint_offset)
    
    # Try to satisfy the constraints without backtracking to consider a new max jump height.
    var calc_results := _calculate_steps_from_constraint_without_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)
    if calc_results != null:
        return calc_results
    
    # Try to satisfy the constraints with backtracking to consider a new max jump height.
    return _calculate_steps_from_constraint_with_backtracking_on_height( \
            global_calc_params, local_calc_params, constraints)

func _calculate_steps_from_constraint_without_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    
    # Check whether either constraint can be satisfied with our current jump height.
    # FIXME: LEFT OFF HERE: B: Add heuristics to pick the "better" constraint first.
    for constraint in constraints:
        # Recurse: Calculate movement to the constraint.
        local_calc_params_to_constraint = MovementCalcLocalParams.new( \
                local_calc_params.position_start, constraint.passing_point, \
                local_calc_params.previous_step, local_calc_params.vertical_step, \
                local_calc_params.total_duration)
        calc_results_to_constraint = _calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_to_constraint)
        
        if calc_results_to_constraint.horizontal_steps.empty():
            # This constraint is out of reach.
            continue
        
        # Recurse: Calculate movement from the constraint to the original destination.
        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint.passing_point, local_calc_params.position_end, \
                calc_results_to_constraint.horizontal_steps.back(), 
                local_calc_params.vertical_step, local_calc_params.total_duration)
        calc_results_from_constraint = _calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_from_constraint)
        
        if !calc_results_from_constraint.horizontal_steps.empty():
            # We found movement that satisfies the constraint.
            Utils.concat(calc_results_to_constraint.horizontal_steps, \
                    calc_results_from_constraint.horizontal_steps)
            return calc_results_to_constraint
    
    # We weren't able to satisfy the constraints around the colliding Surface.
    return null

func _calculate_steps_from_constraint_with_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    
    # Check whether re-calculating the initial vertical step (and total duration) to use a higher
    # jump would enable either constraint to be satisfied.
    # FIXME: LEFT OFF HERE: B: Add heuristics to pick the "better" constraint first.
    for constraint in constraints:
        # FIXME: LEFT OFF HERE: ---A *********
        # - Refactor vertical step stuff...:
        #   - For the backtracking recursion, I need to be able to initialize a new vertical step
        #     for both the section before and after the constraint.
        #     - I will need to somehow use the total_duration from both.
        #     - I will need to not use params.jump_boost as the initial velocity for the latter.
        #   - Think about what structure will be useful for re-use with the fall_from_air_movement.
        #   - Think about what structure will be useful for re-use with the jump_from_wall_movement.
        #     - Will I need to create a separate class for jump_from_wall_movement vs jump_from_floor_movement?
        #   - I will need to not mutate the shared global_calc_params state between recursive calls.
        # - If we are in a recursive branch that depends on an alternate start position, then that
        #   will need to have access to the original start position.
        #   - And it will still need to re-use the same set of already-collided surfaces.
        # - Make sure only the new steps get concatenated and used when doing backtracking.
        
        # Note: The new traversal can never collide with any of the Surfaces that this past
        # traversal collided with. If it did, it would end up on a traversal branch that's
        # identical to one we've already eliminated. So we re-use the same collided_surfaces
        # parameter.
        
        # Recurse: Backtrack and try a higher jump (to the constraint).
        # FIXME: LEFT OFF HERE: ----------------A What happens if this local position start is not the same as the global position start?
        calc_results_to_constraint = _calculate_steps_with_new_jump_height(global_calc_params, \
                local_calc_params.position_start, constraint.passing_point)
        
        if calc_results_to_constraint == null:
            # The constraint is out of reach.
            continue
        
        # Recurse: Calculate movement from the constraint to the original destination.
        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint.passing_point, local_calc_params.position_end, \
                calc_results_to_constraint.horizontal_steps.back(), \
                calc_results_to_constraint.vertical_step, \
                calc_results_to_constraint.total_duration)
        calc_results_from_constraint = _calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_from_constraint)
        
        if !calc_results_from_constraint.horizontal_steps.empty():
            # We found movement that satisfies the constraint.
            Utils.concat(calc_results_to_constraint.horizontal_steps, \
                    calc_results_from_constraint.horizontal_steps)
            # FIXME: LEFT OFF HERE: ----------------A calculate a new total_duration to use here that adds in the fall duration from the constraint
#            calc_results_to_constraint.total_duration = 
            return calc_results_to_constraint
    
    # We weren't able to satisfy the constraints around the colliding Surface.
    return null

# Initializes a new MovementCalcStep for the vertical part of the movement, and saves it, and the
# total_duration, on the given MovementCalcGlobalParams.
func _calculate_vertical_step( \
        position_start: Vector2, position_end: Vector2) -> MovementCalcLocalParams:
    # FIXME: LEFT OFF HERE: B: Account for max y velocity when calculating any parabolic motion.
    
    var total_displacement: Vector2 = position_end - position_start
    var max_vertical_displacement := get_max_upward_distance()
    var duration_to_peak := -params.jump_boost / params.gravity
    
    assert(duration_to_peak > 0)
    
    # Check whether the vertical displacement is possible.
    if max_vertical_displacement < total_displacement.y:
        return null
    
    var slow_ascent_gravity := params.gravity * params.ascent_gravity_multiplier
    
    # Calculate how long it will take for the jump to reach some minimum peak height.
    # 
    # This takes into consideration the fast-fall mechanics (i.e., that a slower gravity is applied
    # until either the jump button is released or we hit the peak of the jump)
    var duration_to_reach_upward_displacement: float
    if total_displacement.y < 0:
        # Derivation:
        # - Start with basic equations of motion
        # - v_1^2 = v_0^2 + 2*a_0 * (s_1 - s_0)
        # - v_2^2 = v_1^2 + 2*a_1 * (s_2 - s_1)
        # - v_2 = 0
        # - s_0 = 0
        # - Do some algebra...
        # - s_1 = (1/2*v_0^2 + a_1*s_2) / (a_1 - a_0)
        var distance_to_release_button_for_shorter_jump := \
                (0.5 * params.jump_boost * params.jump_boost + \
                        params.gravity * total_displacement.y) / \
                (params.gravity - slow_ascent_gravity)
        assert(distance_to_release_button_for_shorter_jump < 0)
        
        # From basic equations of motion.
        var duration_to_release_button_for_shorter_jump := \
                (sqrt(params.jump_boost * params.jump_boost + \
                2 * slow_ascent_gravity * distance_to_release_button_for_shorter_jump) - \
                params.jump_boost) / slow_ascent_gravity
        
        # From basic equations of motion.
        var duration_to_reach_peak_after_release := \
                -params.jump_boost - \
                        slow_ascent_gravity * duration_to_release_button_for_shorter_jump / \
                params.gravity
        duration_to_reach_upward_displacement = duration_to_release_button_for_shorter_jump + \
                duration_to_reach_peak_after_release
    else:
        # We're jumping downward, so we don't need to reach any minimum peak height.
        duration_to_reach_upward_displacement = 0.0
    
    # Calculate how long it will take for the jump to reach some lower destination.
    var duration_to_reach_downward_displacement: float
    if total_displacement.y >= 0:
        duration_to_reach_downward_displacement = 0.0
    else:
        # From a basic equation of motion.
        var discriminant := \
                params.jump_boost * params.jump_boost + 2 * params.gravity * total_displacement.y
        if discriminant < 0:
            # We can't reach the end position from our start position.
            return null
        var discriminant_sqrt := sqrt(discriminant)
        duration_to_reach_downward_displacement = \
                (-params.jump_boost + discriminant_sqrt) / params.gravity
        if duration_to_reach_downward_displacement < 0:
            duration_to_reach_downward_displacement = \
                    (-params.jump_boost - discriminant_sqrt) / params.gravity
    
    # FIXME: LEFT OFF HERE: B: Account for horizontal acceleration.
    var duration_to_reach_horizontal_displacement := \
            abs(total_displacement.x / params.max_horizontal_speed_default)
    
    # How high we need to jump is determined by the greatest of three durations:
    # - The duration to reach the minimum peak height (i.e., how high upward we must jump to reach
    #   a higher destination).
    # - The duration to reach a lower destination.
    # - The duration to cover the horizontal displacement.
    var total_duration := max(max(duration_to_reach_upward_displacement, \
            duration_to_reach_downward_displacement), duration_to_reach_horizontal_displacement)
    
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
    var time_to_release_jump_button := (-b + discriminant_sqrt) / 2 * a
    if time_to_release_jump_button < 0:
        time_to_release_jump_button = (-b - discriminant_sqrt) / 2 * a
    
    var step := MovementCalcStep.new()
    step.time_start = 0.0
    step.time_end = time_to_release_jump_button
    step.position_start = position_start
    step.position_end = Vector2.INF
    step.velocity_start = Vector2(0, params.jump_boost)
    step.velocity_end = Vector2.INF
    step.horizontal_movement_sign = 0
    _update_vertical_state_for_time(step, step, step.time_end)
    
    return MovementCalcLocalParams.new(position_start, position_end, null, step, total_duration)

# Initializes a new MovementCalcStep for the horizontal part of the movement.
func _create_horizontal_step(local_calc_params: MovementCalcLocalParams) -> MovementCalcStep:
    var previous_step := local_calc_params.previous_step
    var vertical_step := local_calc_params.vertical_step
    var position_end := local_calc_params.position_end
    
    # Get some start state from the previous step.
    var time_start: float
    var position_start: Vector2
    var velocity_start: Vector2
    if previous_step != null:
        # The next step starts off where the previous step ended.
        time_start = previous_step.time_end
        position_start = previous_step.position_end
        velocity_start = previous_step.velocity_end
    else:
        # If there is no previous step, then get the initial state from the vertical step.
        time_start = vertical_step.time_start
        position_start = vertical_step.position_start
        velocity_start = vertical_step.velocity_start
    
    var time_remaining := local_calc_params.total_duration - time_start
    var displacement: Vector2 = position_end - position_start
    
    # FIXME: LEFT OFF HERE: B: Account for horizontal acceleration (and velocity_start).
    var duration_for_horizontal_displacement := \
            abs(displacement.x / params.max_horizontal_speed_default)
    
    # Check whether the horizontal displacement is possible.
    if time_remaining < duration_for_horizontal_displacement:
        return null
    
    var horizontal_movement_sign: int
    if displacement.x < 0:
        horizontal_movement_sign = -1
    elif displacement.x > 0:
        horizontal_movement_sign = 1
    else:
        horizontal_movement_sign = 0
    
    var time_end := time_start + duration_for_horizontal_displacement
    
    var step := MovementCalcStep.new()
    step.time_start = time_start
    step.time_end = time_end
    step.position_start = position_start
    step.position_end = position_end
    step.velocity_start = Vector2(0.0, velocity_start.y)
    step.velocity_end = Vector2(0.0, INF)
    step.horizontal_movement_sign = horizontal_movement_sign
    _update_vertical_state_for_time(step, vertical_step, step.time_end)
    
    return step

func _convert_calculation_steps_to_player_instructions(calc_results: MovementCalcResults, \
        position_start: Vector2, position_end: Vector2) -> PlayerInstructions:
    var steps := calc_results.horizontal_steps
    var vertical_step := calc_results.vertical_step
    
    var distance := position_start.distance_to(position_end)
    
    var instructions := []
    instructions.resize((steps.size() + 1) * 2)
    
    var input_key := "jump"
    var press := PlayerInstruction.new(input_key, vertical_step.time_start, true)
    var release := PlayerInstruction.new(input_key, vertical_step.time_end, false)
    
    instructions[0] = press
    instructions[1] = release
    
    var i := 0
    var step: MovementCalcStep
    for i in range(steps.size()):
        step = steps[i]
        input_key = "move_left" if step.horizontal_movement_sign < 0 else "move_right"
        press = PlayerInstruction.new(input_key, step.time_start, true)
        release = PlayerInstruction.new(input_key, step.time_end, false)
        instructions[i * 2 + 2] = press
        instructions[i * 2 + 3] = release
        i += 1
    
    return PlayerInstructions.new(instructions, calc_results.total_duration, distance)

func get_max_upward_distance() -> float:
    return -(params.jump_boost * params.jump_boost) / 2 / \
            (params.gravity * params.ascent_gravity_multiplier)

func get_max_horizontal_distance() -> float:
    # Take into account the slow gravity of ascent and the fast gravity of descent.
    # FIXME: LEFT OFF HERE: B: Re-calculate this; add a multiplier (x2) to allow for additional
    #        distance when the destination is below.
    return (-params.jump_boost / params.gravity * params.max_horizontal_speed_default) / \
            (1 + params.ascent_gravity_multiplier)
