extends PlayerMovement
class_name JumpFromPlatformMovement

const MovementCalcGlobalParams = preload("res://framework/player_movement/movement_calculation_global_params.gd")
const MovementCalcLocalParams = preload("res://framework/player_movement/movement_calculation_local_params.gd")
const MovementCalcStep = preload("res://framework/player_movement/movement_calculation_step.gd")

# FIXME: SUB-MASTER LIST ***************
# - LEFT OFF HERE: Fix the current issue in check_frame_for_collision when using level_4 with all
#                  surfaces.
# - LEFT OFF HERE: Some non-edge-calc, lighter work to do now:
#   --> B: Add path finding and update logic to PlatformGraphNavigator.
#   - C: Add support for executing movement WITHIN an edge.
#   - D: Add support for executing movement along an edge.
#     - Implement ComputerPlayer.
#     - Use the cat animator for now, since that will let me test/implement the animation triggers.
#   - F: Add support for not having a human or CPU in a level.
#   - G: Add support for sending the CPU to a click target (configured in the specific level).
#   - H: Add support for picking random surfaces or points-in-space to move the CPU to; resetting
#        to a new point after the CPU reaches the old point.
#     - Implement this as an alternative to ClickToNavigate (actually, support both running at the
#       same time).
#     - It will need to listen for when the navigator has reached the destination though (make sure
#       that signal is emitted).
#   - I: Fix surface annotator (doubles on part and wraps around edge wrong).
#   - J: Create a demo level to showcase lots of interesting edges.
# - LEFT OFF HERE: Add support for specifying a desired min end-x-velocity.
#   - We need to add support for specifying a desired min end-x-velocity from the previous
#     horizontal step (by default, all end velocities are as small as possible).
#   - We can then use this to determine when to start the horizontal movement for the previous
#     horizontal step (delaying movement start yields a greater end velocity).
#   - In order to determine whether the required min end-x-velocity from the previous step, we
#     should flip the order in which we calculate horizontal steps in the constraint recursion.
#   - We should be able to just calculate the latter step first, since we know what its start
#     position and time must be.
# - LEFT OFF HERE: Check for other obvious false negative edges.
# - LEFT OFF HERE: Debug why discrete movement trajectories are incorrect.
#   - Discrete trajectories are definitely peaking higher; should we cut the jump button sooner?
#   - Not considering continous max vertical velocity might contribute to discrete vertical
#     movement stopping short.
# - LEFT OFF HERE: Debug/stress-test intermediate collision scenarios.
#   - After fixing max vertical velocity, is there anything else I can boost?
# - LEFT OFF HERE: Debug why _check_instructions_for_collision fails with collisions (render better annotations?).
# - LEFT OFF HERE: Non-edge-calc, lighter work: Add squirrel animation.
# - 
# - Debugging:
#   - Would it help to add some quick and easy annotation helpers for temp debugging that I can access on global (or wherever) and just tell to render dots/lines/circles?
#   - Then I could use that to render all sorts of temp calculation stuff from this file.
#   - Add an annotation for tracing the players recent center positions.
#   - Try rendering a path for trajectory that's closen to the calculations for parabolic motion instead of the resulting instruction positions?
#     - Might help to see the significance of the difference.
#     - Might be able to do this with smaller step sizes?
# - 
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
# - Step through and double-check each return value parameter individually through the recursion, and each input parameter.
# - 
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
# - 
# - Problem: All of the edge calculations will allow the slow-ascent gravity to also be used for
#   the downward portion of the jump.
#   - Either update Player controllers to also allow that,
#   - or update all relevant edge calculation logic.
# - 
# - Fix _get_nearby_and_fallable_surfaces et al
# - 
# - Eventually, split each Test inner-class group out into its own file
# - 
# - Make some diagrams in InkScape with surfaces, trajectories, and constraints to demonstrate
#   algorithm traversal
#   - Label/color-code parts to demonstrate separate traversal steps
# - Make the 144-cell diagram in InkScape and add to docs.
# - Storing possibly 9 edges from A to B.

# FIXME: B ******
# - Should I remove this and force a slightly higher offset to target jump position directly? What
#   about passing through constraints? Would the increased time to get to the position for a
#   wall-top constraint result in too much downward velocity into the ceiling?
# - Or what about the constraint offset margins? Shouldn't those actually address any needed
#   jump-height epsilon? Is this needlessly redundant with that mechanism?
# - Though I may need to always at least have _some_ small value here...
# FIXME: D ******** Tweak this
const JUMP_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 0.5
const MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 0.5

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
        surface_parser: SurfaceParser, a: Surface) -> Array:
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
    var possible_jump_points := []
    var possible_land_points := []
    var possible_jump_land_pairs := []
    var jump_point: Vector2
    var land_point: Vector2
    var jump_position: PositionAlongSurface
    var land_position: PositionAlongSurface
    var instructions: PlayerInstructions
    var edges := {}
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall *= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_ascent *= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    var global_calc_params := MovementCalcGlobalParams.new(params, space_state, surface_parser)
    
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
        possible_jump_points.clear()
        possible_land_points.clear()
        possible_jump_points.push_back(a_near_end)
        possible_land_points.push_back(b_near_end)
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
        
        # FIXME: D *********** Remove. This is for debugging.
#        if a.side != SurfaceSide.FLOOR or b.side != SurfaceSide.FLOOR:
#            continue
#        else:
#            possible_jump_land_pairs = [a_far_end, b_far_end]
        # FIXME: D: Remove
        if a.side == SurfaceSide.CEILING or b.side == SurfaceSide.CEILING:
            continue
        
        for i in range(possible_jump_land_pairs.size() - 1):
            jump_point = possible_jump_land_pairs[i]
            land_point = possible_jump_land_pairs[i + 1]
            
            jump_position = PositionAlongSurface.new()
            jump_position.match_surface_target_and_collider(a, jump_point, \
                    params.collider_half_width_height)
            land_position = PositionAlongSurface.new()
            land_position.match_surface_target_and_collider(b, land_point, \
                    params.collider_half_width_height)
            global_calc_params.position_start = jump_position.target_point
            global_calc_params.position_end = land_position.target_point
            instructions = _calculate_jump_instructions(global_calc_params)
            if instructions != null:
                # Can reach land position from jump position.
                edges.push_back(PlatformGraphInterSurfaceEdge.new( \
                        jump_position, land_position, instructions))
    
    # FIXME: B: REMOVE
    params.gravity_fast_fall /= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    params.gravity_slow_ascent /= GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION
    
    return edges

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, position_start: PositionAlongSurface, \
        position_end: Vector2) -> PlayerInstructions:
    var global_calc_params := MovementCalcGlobalParams.new(params, space_state, surface_parser)
    global_calc_params.position_start = position_start.target_point
    global_calc_params.position_end = position_end
    
    return _calculate_jump_instructions(global_calc_params)

# Calculates instructions that would move the player from the given start position to the given end
# position.
# 
# This considers interference from intermediate surfaces, and will only return instructions that
# would produce valid movement without intermediate collisions.
static func _calculate_jump_instructions( \
        global_calc_params: MovementCalcGlobalParams) -> PlayerInstructions:
    var calc_results := _calculate_steps_with_new_jump_height( \
            global_calc_params, global_calc_params.position_end, null)
    
    if calc_results == null:
        return null
    
    var instructions := \
            _convert_calculation_steps_to_player_instructions(global_calc_params, calc_results)
    
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
    
    var collision := _check_instructions_for_collision(global_calc_params, instructions, \
            calc_results.vertical_step, calc_results.horizontal_steps)
    assert(collision == null or collision.surface == global_calc_params.destination_surface)
    var final_frame_position := \
            instructions.frame_discrete_positions[instructions.frame_discrete_positions.size() - 1]
    # FIXME: B: Add back in after fixing the use of GRAVITY_MULTIPLIER_TO_ADJUST_FOR_FRAME_DISCRETIZATION.
#    assert(final_frame_position.distance_squared_to(global_calc_params.position_end) < \
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
        local_position_end: Vector2, \
        upcoming_constraint: MovementConstraint) -> MovementCalcResults:
    var local_calc_params := _calculate_vertical_step(global_calc_params.movement_params, \
            global_calc_params.position_start, local_position_end)
    
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
static func _calculate_steps_from_constraint(global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams) -> MovementCalcResults:
    ### BASE CASES
    
    var next_horizontal_step := _calculate_horizontal_step(local_calc_params, global_calc_params)
    
    if next_horizontal_step == null:
        # The destination is out of reach.
        return null
    
    var vertical_step := local_calc_params.vertical_step
    
    # If this is the last horizontal step, then let's check whether whether we calculated
    # things correctly.
    if local_calc_params.upcoming_constraint == null:
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.time_step_end, vertical_step.time_step_end, 0.0001))
        assert(Geometry.are_floats_equal_with_epsilon( \
                next_horizontal_step.position_step_end.y, vertical_step.position_step_end.y, \
                0.001))
        assert(Geometry.are_points_equal_with_epsilon( \
                next_horizontal_step.position_step_end, global_calc_params.position_end, 0.0001))
    
    var collision := _check_continuous_horizontal_step_for_collision( \
            global_calc_params, local_calc_params, next_horizontal_step)
    
    if collision == null or collision.surface == global_calc_params.destination_surface:
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
                local_calc_params.position_start, constraint.passing_point, \
                local_calc_params.previous_step, local_calc_params.vertical_step, constraint)
        calc_results_to_constraint = _calculate_steps_from_constraint(global_calc_params, \
                local_calc_params_to_constraint)
        
        if calc_results_to_constraint == null:
            # This constraint is out of reach with the current jump height.
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
static func _calculate_steps_from_constraint_with_backtracking_on_height( \
        global_calc_params: MovementCalcGlobalParams, \
        local_calc_params: MovementCalcLocalParams, constraints: Array) -> MovementCalcResults:
    var local_calc_params_to_constraint: MovementCalcLocalParams
    var local_calc_params_from_constraint: MovementCalcLocalParams
    var calc_results_to_constraint: MovementCalcResults
    var calc_results_from_constraint: MovementCalcResults
    var vertical_step_to_constraint: MovementCalcStep
    var end_state: Vector2
    
    # FIXME: B: Add heuristics to pick the "better" constraint first.
    
    for constraint in constraints:
        # Recurse: Backtrack and try a higher jump (to the constraint).
        calc_results_to_constraint = _calculate_steps_with_new_jump_height( \
                global_calc_params, constraint.passing_point, constraint)
        
        if calc_results_to_constraint == null:
            # The constraint is out of reach.
            continue
        
        vertical_step_to_constraint = calc_results_to_constraint.vertical_step
        
        # Update the total duration to include the fall duration after the constraint.
        vertical_step_to_constraint.time_step_end = _calculate_end_time_for_jumping_to_position( \
                global_calc_params.movement_params, vertical_step_to_constraint, \
                local_calc_params.position_end, vertical_step_to_constraint.time_step_end, \
                local_calc_params.upcoming_constraint, global_calc_params.destination_surface)
        if vertical_step_to_constraint.time_step_end == INF:
            # The destination is out of reach from the constraint.
            continue
        end_state = _update_vertical_end_state_for_time(global_calc_params.movement_params, \
                vertical_step_to_constraint, vertical_step_to_constraint.time_step_end)
        vertical_step_to_constraint.position_step_end.y = end_state.x
        vertical_step_to_constraint.velocity_step_end.y = end_state.y
        
        # Recurse: Calculate movement from the constraint to the original destination.
        local_calc_params_from_constraint = MovementCalcLocalParams.new( \
                constraint.passing_point, local_calc_params.position_end, \
                calc_results_to_constraint.horizontal_steps.back(), \
                vertical_step_to_constraint, null)
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
static func _calculate_vertical_step(movement_params: MovementParams, \
        position_start: Vector2, position_end: Vector2) -> MovementCalcLocalParams:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    
    var total_displacement: Vector2 = position_end - position_start
    var min_vertical_displacement := movement_params.max_upward_distance
    
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
    
    var time_to_release_jump_button: float
    var velocity_at_jump_button_release: float
    
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
                (0.5 * movement_params.jump_boost * movement_params.jump_boost + \
                movement_params.gravity_fast_fall * total_displacement.y) / \
                (movement_params.gravity_fast_fall - movement_params.gravity_slow_ascent)
        
        if distance_to_release_button_for_shorter_jump < 0:
            # We need more motion than just the initial jump boost to reach the destination.
            time_to_release_jump_button = \
                    Geometry.solve_for_movement_duration(0.0, \
                    distance_to_release_button_for_shorter_jump, movement_params.jump_boost, \
                    movement_params.gravity_slow_ascent, true, 0.0, false)
            assert(time_to_release_jump_button != INF)
        
            # From a basic equation of motion:
            #     v = v_0 + a*t
            velocity_at_jump_button_release = movement_params.jump_boost + \
                    movement_params.gravity_slow_ascent * time_to_release_jump_button
    
            # From a basic equation of motion:
            #     v = v_0 + a*t
            var duration_to_reach_peak_after_release := \
                    -velocity_at_jump_button_release / movement_params.gravity_fast_fall
            assert(duration_to_reach_peak_after_release >= 0)
    
            duration_to_reach_upward_displacement = time_to_release_jump_button + \
                    duration_to_reach_peak_after_release
        else:
            # The initial jump boost is already more motion than we need to reach the destination.
            # 
            # In this case, we set up the vertical step to hit the end position while still
            # travelling upward.
            time_to_release_jump_button = 0
            velocity_at_jump_button_release = movement_params.jump_boost
            duration_to_reach_upward_displacement = Geometry.solve_for_movement_duration(0.0, \
                    total_displacement.y, movement_params.jump_boost, \
                    movement_params.gravity_fast_fall, true, 0.0, false)
    else:
        # We're jumping downward, so we don't need to reach any minimum peak height.
        duration_to_reach_upward_displacement = 0.0
    
    # Calculate how long it will take for the jump to reach some lower destination.
    var duration_to_reach_downward_displacement: float
    if total_displacement.y > 0:
        duration_to_reach_downward_displacement = Geometry.solve_for_movement_duration( \
                position_start.y, position_end.y, movement_params.jump_boost, \
                movement_params.gravity_fast_fall, true, 0.0, true)
        assert(duration_to_reach_downward_displacement != INF)
    else:
        duration_to_reach_downward_displacement = 0.0
    
    var duration_to_reach_horizontal_displacement := _calculate_min_time_to_reach_position( \
            position_start.x, position_end.x, 0.0, \
            movement_params.max_horizontal_speed_default, \
            movement_params.in_air_horizontal_acceleration * horizontal_movement_sign)
    assert(duration_to_reach_horizontal_displacement >= 0 and \
            duration_to_reach_horizontal_displacement != INF)
    
    var duration_to_reach_upward_displacement_on_descent := 0.0
    if duration_to_reach_downward_displacement == 0.0:
        # The total duration still isn't enough if we cannot reach the horizontal displacement
        # before we've already past the destination vertically on the upward side of the
        # trajectory. In that case, we need to consider the minimum time for the upward and
        # downward motion of the jump.
        
        var duration_to_reach_upward_displacement_with_only_fast_fall = \
                Geometry.solve_for_movement_duration(position_start.y, position_end.y, \
                        movement_params.jump_boost, movement_params.gravity_fast_fall, true, 0.0, \
                        false)
        
        if duration_to_reach_upward_displacement_with_only_fast_fall != INF and \
                duration_to_reach_upward_displacement_with_only_fast_fall < \
                duration_to_reach_horizontal_displacement:
            duration_to_reach_upward_displacement_on_descent = \
                    Geometry.solve_for_movement_duration(position_start.y, position_end.y, \
                            movement_params.jump_boost, movement_params.gravity_fast_fall, \
                            false, 0.0, false)
            assert(duration_to_reach_upward_displacement_on_descent != INF)
    
    # How high we need to jump is determined by the total duration of the jump.
    # 
    # The total duration of the jump is at least the greatest of three durations:
    # - The duration to reach the minimum peak height (i.e., how high upward we must jump to reach
    #   a higher destination).
    # - The duration to reach a lower destination.
    # - The duration to cover the horizontal displacement.
    # 
    # However, that total duration still isn't enough if we cannot reach the horizontal
    # displacement before we've already past the destination vertically on the upward side of the
    # trajectory. In that case, we need to consider the minimum time for the upward and downward
    # motion of the jump.
    var total_duration := max(max(max(duration_to_reach_upward_displacement, \
            duration_to_reach_downward_displacement), \
            duration_to_reach_horizontal_displacement), \
            duration_to_reach_upward_displacement_on_descent)
    
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
    var a := 0.5 * (movement_params.gravity_fast_fall - movement_params.gravity_slow_ascent)
    var b := total_duration * \
            (movement_params.gravity_slow_ascent - movement_params.gravity_fast_fall)
    var c := position_start.y - position_end.y + movement_params.jump_boost * total_duration + \
            0.5 * movement_params.gravity_fast_fall * total_duration * total_duration
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position in the given time.
        return null
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-b - discriminant_sqrt) / 2 / a
    var t2 := (-b + discriminant_sqrt) / 2 / a
    if t1 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t2
    elif t2 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t1
    else:
        time_to_release_jump_button = min(t1, t2)
    assert(time_to_release_jump_button >= -Geometry.FLOAT_EPSILON)
    time_to_release_jump_button = max(time_to_release_jump_button, 0.0)
    assert(time_to_release_jump_button <= total_duration)
    
    # Given the time to release the jump button, calculate the time to reach the peak.
    # From a basic equation of motion:
    #     v = v_0 + a*t
    velocity_at_jump_button_release = movement_params.jump_boost + \
            movement_params.gravity_slow_ascent * time_to_release_jump_button
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_to_reach_peak_after_release := \
            -velocity_at_jump_button_release / movement_params.gravity_fast_fall
    var time_peak_height := time_to_release_jump_button + duration_to_reach_peak_after_release
    
    var step := MovementCalcStep.new()
    step.time_start = 0.0
    step.time_instruction_end = time_to_release_jump_button
    step.time_step_end = total_duration
    step.time_peak_height = time_peak_height
    step.position_start = position_start
    step.velocity_start = Vector2(0.0, movement_params.jump_boost)
    step.horizontal_movement_sign = horizontal_movement_sign
    
    var instruction_end_state := \
            _update_vertical_end_state_for_time(movement_params, step, step.time_instruction_end)
    var step_end_state := \
            _update_vertical_end_state_for_time(movement_params, step, step.time_step_end)
    var peak_height_end_state := \
            _update_vertical_end_state_for_time(movement_params, step, step.time_peak_height)
    
    step.position_instruction_end = Vector2(INF, instruction_end_state.x)
    step.position_step_end = Vector2(INF, step_end_state.x)
    step.position_peak_height = Vector2(INF, peak_height_end_state.x)
    step.velocity_instruction_end = Vector2(INF, instruction_end_state.y)
    step.velocity_step_end = Vector2(INF, step_end_state.y)
    
    assert(Geometry.are_floats_equal_with_epsilon( \
            step.position_step_end.y, position_end.y, 0.001))
    
    return MovementCalcLocalParams.new(position_start, position_end, null, step, null)

# Calculates a new step for the horizontal part of the movement.
static func _calculate_horizontal_step(local_calc_params: MovementCalcLocalParams, \
        global_calc_params: MovementCalcGlobalParams) -> MovementCalcStep:
    var movement_params := global_calc_params.movement_params
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
    
    var time_step_end := _calculate_end_time_for_jumping_to_position( \
            movement_params, vertical_step, position_end, time_start, \
            local_calc_params.upcoming_constraint, global_calc_params.destination_surface)
    if time_step_end == INF:
        # The vertical displacement is out of reach.
        return null
    
    var time_remaining := vertical_step.time_step_end - time_start
    var displacement: Vector2 = position_end - position_start
    
    var horizontal_movement_sign: int
    if displacement.x < 0:
        horizontal_movement_sign = -1
    elif displacement.x > 0:
        horizontal_movement_sign = 1
    else:
        horizontal_movement_sign = 0
    var acceleration := movement_params.in_air_horizontal_acceleration * horizontal_movement_sign
    
    # FIXME: Problem: Sometimes, the following step may require a minimum or maiximum starting
    #        velocity in order to reach it's constraint. Right now, this isn't paying much
    #        attention to the end velocity; if time_instruction_end < time_step_end, then we could
    #        manipulate things to increase or decrease the end velocity.
    
    # TODO: Pass-in a post-release backward acceleration?
    # - It might make motion feel snappier/more-efficient.
    # - It would require updating each horizontal MovementCalcSteps to result in a second
    #   PlayerInstruction pair for pressing the opposition direction for the remaining time between
    #   time_instruction_end and time_step_end.
    # - Would need to also update _update_horizontal_end_state_for_time.
    
    var duration_for_horizontal_acceleration := _calculate_time_to_release_acceleration( \
            time_start, time_step_end, position_start.x, position_end.x, velocity_start.x, \
            acceleration, 0.0, true, false)
    
    if time_remaining < duration_for_horizontal_acceleration:
        # The horizontal displacement is out of reach.
        return null
    
    var time_instruction_end := time_start + duration_for_horizontal_acceleration
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2
    var position_instruction_end_x := position_start.x + \
            velocity_start.x * duration_for_horizontal_acceleration + \
            0.5 * acceleration * \
            duration_for_horizontal_acceleration * duration_for_horizontal_acceleration
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var velocity_instruction_end_x := velocity_start.x + \
            acceleration * duration_for_horizontal_acceleration
    var velocity_step_end_x := velocity_instruction_end_x
    
    if velocity_instruction_end_x > movement_params.max_horizontal_speed_default + 1:
        # The horizontal displacement is out of reach.
        return null
    
    var step := MovementCalcStep.new()
    step.time_start = time_start
    step.time_instruction_end = time_instruction_end
    step.time_step_end = time_step_end
    step.position_start = position_start
    step.velocity_start = velocity_start
    step.horizontal_movement_sign = horizontal_movement_sign
    
    var instruction_end_state := _update_vertical_end_state_for_time( \
            movement_params, vertical_step, step.time_instruction_end)
    var step_end_state := _update_vertical_end_state_for_time( \
            movement_params, vertical_step, step.time_step_end)
    
    step.position_instruction_end = Vector2(position_instruction_end_x, instruction_end_state.x)
    step.position_step_end = position_end
    step.velocity_instruction_end = Vector2(velocity_instruction_end_x, instruction_end_state.y)
    step.velocity_step_end = Vector2(velocity_step_end_x, step_end_state.y)
    
    assert(Geometry.are_floats_equal_with_epsilon(position_end.y, step_end_state.x, 0.0001))
    
    return step

# Translates movement data from a form that is more useful when calculating the movement to a form
# that is more useful when executing the movement.
static func _convert_calculation_steps_to_player_instructions( \
        global_calc_params: MovementCalcGlobalParams, \
        calc_results: MovementCalcResults) -> PlayerInstructions:
    var steps := calc_results.horizontal_steps
    var vertical_step := calc_results.vertical_step
    
    var distance_squared := \
            global_calc_params.position_start.distance_squared_to(global_calc_params.position_end)
    
    var constraint_positions := []
    
    var instructions := []
    instructions.resize((steps.size() + 1) * 2)
    
    var input_key := "jump"
    var press := PlayerInstruction.new(input_key, vertical_step.time_start, true)
    var release := PlayerInstruction.new(input_key, \
            vertical_step.time_instruction_end + JUMP_DURATION_INCREASE_EPSILON, false)
    
    instructions[0] = press
    instructions[1] = release
    
    var i := 0
    var step: MovementCalcStep
    for i in range(steps.size()):
        step = steps[i]
        input_key = "move_left" if step.horizontal_movement_sign < 0 else "move_right"
        press = PlayerInstruction.new(input_key, step.time_start, true)
        release = PlayerInstruction.new(input_key, \
                step.time_instruction_end + MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON, false)
        instructions[i * 2 + 2] = press
        instructions[i * 2 + 3] = release
        i += 1
        
        # Keep track of some info for edge annotation debugging.
        constraint_positions.push_back(step.position_step_end)
    
    return PlayerInstructions.new(instructions, vertical_step.time_step_end, distance_squared, \
            constraint_positions)
