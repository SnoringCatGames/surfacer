extends PlayerMovement
class_name JumpFromPlatformMovement

const InstrCalcParams = preload("res://framework/player_movement/instructions_calculation_params.gd")
const InstrCalcStep = preload("res://framework/player_movement/instructions_calculation_step.gd")

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
    
    var instructions_params := InstrCalcParams.new(params, space_state)
    
    var possible_surfaces := _get_nearby_and_fallable_surfaces(a)
    
    for b in possible_surfaces:
        # This makes the assumption that traversing through any fall-through/walk-through surface
        # would be better handled by some other PlayerMovement type, so we don't handle those
        # cases here.
        
        instructions_params.destination_surface = b
        
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
                    instructions_params, jump_position.target_point, land_position.target_point)
            if instructions != null:
                edges.push_back(PlatformGraphEdge.new(jump_position, land_position, instructions))
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        position_start: PositionAlongSurface, position_end: Vector2) -> PlayerInstructions:
    var instructions_params := InstrCalcParams.new(params, space_state)
    
    return _calculate_jump_instructions( \
            instructions_params, position_start.target_point, position_end)

func _calculate_jump_instructions(instructions_params: InstrCalcParams, \
        position_start: Vector2, position_end: Vector2) -> PlayerInstructions:
    # FIXME: LEFT OFF HERE: --A ********
    # - Figure out how to actually handle vertical step calculations, after working out the
    #   backtracking for new max_heights from vertical constraints.
    _create_vertical_step(instructions_params, position_start, position_end)
    
    if instructions_params.vertical_step == null:
        # The destination is out of reach.
        return null
    
    var steps := _calculate_instruction_steps(instructions_params, null, position_end)
    
    # FIXME: Add an assert checking that the instructions will end at the correct point, and
    #        without colliding into anything else.
    
    # FIXME: Convert Array<InstrCalcStep> into PlayerInstructions
    return null
    
    # FIXME: LEFT OFF HERE: ----A ********
    # - Will also want to record some other info for annotations/debugging:
    #   - Store on PlayerInstructions (but on InstrCalcStep first, during calculation?).
    #   - A polyline representation of the ultimate trajectory, including time-slice-testing and
    #     considering constraints.
    #   - The ultimate sequence of constraints that were used.
    
    # FIXME: LEFT OFF HERE: A ***************
    # - 
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
    # - Make the 144-cell diagram in InkScape and add to docs.
    # - Storing possibly 9 edges from A to B.
    
    # FIXME: Add support for maintaining horizontal speed when falling, and needing to push back
    # the other way to slow it.

# FIXME: doc
func _calculate_instruction_steps(instructions_params: InstrCalcParams, \
        previous_step: InstrCalcStep, position_end: Vector2) -> Array:
    var next_step := _create_horizontal_step(previous_step, position_end, instructions_params)
    
    # Check whether the destination is within reach of this PlayerMovement.
    if next_step == null:
        return []
    
    var colliding_surface := _check_step_for_collision(instructions_params, next_step)
    
    # Check whether there is no Surface interfering with this PlayerMovement, on whether we've
    # reached the destination Surface.
    if colliding_surface == null or colliding_surface == instructions_params.destination_surface:
        return [next_step]
    
    # Check whether we've already considered a collision with this Surface. If so, then this
    # movement won't work.
    if instructions_params.collided_surfaces.has(colliding_surface):
        return []
    
    instructions_params.collided_surfaces[colliding_surface] = true
    
    # Calculate possible constraints to divert the movement around either side of the colliding
    # Surface.
    var constraints := \
            _calculate_constraints(colliding_surface, instructions_params.constraint_offset)
    
    # Check whether either constraint can be satisfied with our current max_height.
    # FIXME: Add heuristics to pick the "better" constraint first.
    var steps1: Array
    var steps2: Array
    for constraint in constraints:
        # Recurse: Calculate movement to the constraint.
        steps1 = _calculate_instruction_steps( \
                instructions_params, previous_step, constraint.passing_point)
        
        if steps1.empty():
            # This constraint is out of reach.
            continue
        
        # FIXME: LEFT OFF HERE: ------------A ***************
        # - Fix PlayerMovement.check_step_for_collision
        # - Can I change velocity fields from Vector2 to float, and only consider the x or y
        #   coordinate, depending on whether it's a horizontal or vertical step?
        # - Consider initial velocity when calculating _TmpMovement horizontal and vertical
        #   instructions.
        # - Refactor _TmpMovement and how it stores sequences of instructions to make recursive
        #   calculations and backtracking easier:
        #   - Store horizontal instructions in their own separate array
        #   - Store the single vertical instruction as its own field; no array needed, since there
        #     will be only one
        #   - Store start and end time, position, velocity, active inputs, etc. for each
        #     InstrCalcStep
        #   - Only need to store one element for each InstrCalcStep; it accounts for its start
        #     and end
        #   - Store index of the first horizontal instruction that overlaps with the jump button
        #     not being pressed (the first horizontal instruction that we will need to change when\
        #     we backtrack to change the max_height)
        # - Then add logic to convert the temporary helper structure into the final
        #   PlayerInstructions form that we'll actually save on final Edges
        # - Fix start/end position/velocity assignments and updates between steps
        # - Update these _TmpMovement values when recursing (and with results):
        #   - horizontal_step_index
        #   - active_inputs
        #   - time
        #   - position
        #   - velocity
        # - Account for max vertical velocity when calculating parabolic motion for vertical
        #   InstrCalcSteps.
        
#                    var is_pressing_jump: bool = next_movement.active_inputs.has("jump")
#                    if is_pressing_jump and next_movement.instructions.is_instruction_in_range( \
#                            JUMP_RELEASE_INSTRUCTION, previous_time, current_time):
#                        is_pressing_jump = false
#                        next_movement.active_inputs.erase("jump")
        
        # Recurse: Calculate movement from the constraint to the original destination.
        steps2 = _calculate_instruction_steps(instructions_params, steps1.back(), position_end)
        
        if steps2 != null:
            # We found movement that satisfies the constraint.
            Utils.concat(steps1, steps2)
            return steps1
    
    # Check whether increasing the max_height would enable either constraint to be satisfied.
    for constraint in constraints:
        pass
        # FIXME: LEFT OFF HERE: -A *********
        # - Add "backtracking" for extra height when needed:
        # - 
        #       - Handle vertical surface constraints:
        #         - For the "above" constraint branch:
        #           - If we cannot reach this height with our max range, then abort.
        #           - If we are not currently still pressing up, then we need to backtrack
        #             and re-calculate all constraints from the moment we had released up.
        #         - For the "below" constraint branch:
        # - 
        # - Both vertical and horizontal surface constraints could pass with extra height.
        # - For backtracking with new max height, recalculate new full instruction set to
        #   the given constraint, then set a flag to not consider previous parents? Or can
        #   I just return the new child, and parents aren't considered (via concatenation
        #   or something) anyway?
        # - Definitely maintain that list of previously collided surfaces; use the same
        #   list whenakong new calls for whole new instruction sets based off new max
        #   heights constraint end positions.
        # - I'm never actually explicitly changing max height values for vertical
        #   constraints.
        # 
        # 
        # # The new traversal can never collide with any of the Surfaces that this past traversal
        # # collided with. If it did, it would end up on a traversal branch that we've already
        # # eliminated.
    
    # We weren't able to satisfy the constraints around the colliding Surface.
    return []

# Initializes a new InstrCalcStep for the vertical part of the movement, and saves it, and the
# total_duration, on the given InstrCalcParams.
func _create_vertical_step(instructions_params: InstrCalcParams, start: Vector2, \
        end: Vector2) -> void:
    # FIXME: Account for max y velocity when calculating any parabolic motion
    
    var total_displacement: Vector2 = end - start
    var max_vertical_displacement := get_max_upward_distance()
    var duration_to_peak := -params.jump_boost / params.gravity
    
    assert(duration_to_peak > 0)
    
    # Check whether the vertical displacement is possible.
    if max_vertical_displacement < total_displacement.y:
        return
    
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
            return
        var discriminant_sqrt := sqrt(discriminant)
        duration_to_reach_downward_displacement = \
                (-params.jump_boost + discriminant_sqrt) / params.gravity
        if duration_to_reach_downward_displacement < 0:
            duration_to_reach_downward_displacement = \
                    (-params.jump_boost - discriminant_sqrt) / params.gravity
    
    # FIXME: Account for horizontal acceleration.
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
    var c := start.y - end.y + params.jump_boost * total_duration + \
            0.5 * params.gravity * total_duration * total_duration
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position.
        return
    var discriminant_sqrt := sqrt(discriminant)
    var time_to_release_jump_button := (-b + discriminant_sqrt) / 2 * a
    if time_to_release_jump_button < 0:
        time_to_release_jump_button = (-b - discriminant_sqrt) / 2 * a
    
    var step := InstrCalcStep.new()
    step.input_key = "jump"
    step.time_start = 0.0
    step.time_end = time_to_release_jump_button
    step.position_start = start
    step.position_end = Vector2.INF
    step.velocity_start = Vector2(0, params.jump_boost)
    step.velocity_end = Vector2.INF
    step.horizontal_movement_sign = 0
    _update_vertical_state_for_time(step, step, step.time_end)
    
    instructions_params.vertical_step = step
    instructions_params.total_duration = total_duration

# Initializes a new InstrCalcStep for the horizontal part of the movement.
func _create_horizontal_step(previous_step: InstrCalcStep, position_end: Vector2, \
        instructions_params: InstrCalcParams) -> InstrCalcStep:
    var vertical_step := instructions_params.vertical_step
    
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
    
    var time_remaining := instructions_params.total_duration - time_start
    var displacement: Vector2 = position_end - position_start
    
    # FIXME: Account for horizontal acceleration.
    var duration_for_horizontal_displacement := \
            abs(displacement.x / params.max_horizontal_speed_default)
    
    # Check whether the horizontal displacement is possible.
    if time_remaining < duration_for_horizontal_displacement:
        return null
    
    var horizontal_movement_input_name: String
    var horizontal_movement_sign: int
    if displacement.x < 0:
        horizontal_movement_input_name = "move_left"
        horizontal_movement_sign = -1
    elif displacement.x > 0:
        horizontal_movement_input_name = "move_right"
        horizontal_movement_sign = 1
    else:
        horizontal_movement_input_name = "move_right"
        horizontal_movement_sign = 0
    
    var time_end := time_start + duration_for_horizontal_displacement
    
    var step := InstrCalcStep.new()
    step.input_key = horizontal_movement_input_name
    step.time_start = time_start
    step.time_end = time_end
    step.position_start = position_start
    step.position_end = position_end
    step.velocity_start = Vector2(0.0, velocity_start.y)
    step.velocity_end = Vector2(0.0, INF)
    step.horizontal_movement_sign = horizontal_movement_sign
    _update_vertical_state_for_time(step, vertical_step, step.time_end)
    
    return step

func get_max_upward_distance() -> float:
    return -(params.jump_boost * params.jump_boost) / 2 / \
            (params.gravity * params.ascent_gravity_multiplier)

func get_max_horizontal_distance() -> float:
    # Take into account the slow gravity of ascent and the fast gravity of descent.
    # FIXME: Re-calculate this; add a multiplier (x2) to allow for additional distance when the
    #        destination is below.
    return (-params.jump_boost / params.gravity * params.max_horizontal_speed_default) / \
            (1 + params.ascent_gravity_multiplier)
