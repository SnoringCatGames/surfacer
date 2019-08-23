# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name PlayerMovement

const MovementConstraint := preload("res://framework/player_movement/movement_constraint.gd")
const PlayerInstruction := preload("res://framework/player_movement/player_instruction.gd")
const MovementVertCalcStep := preload("res://framework/player_movement/movement_vertical_calculation_step.gd")

# FIXME: B 
# - Should I remove this and force a slightly higher offset to target jump position directly? What
#   about passing through constraints? Would the increased time to get to the position for a
#   wall-top constraint result in too much downward velocity into the ceiling?
# - Or what about the constraint offset margins? Shouldn't those actually address any needed
#   jump-height epsilon? Is this needlessly redundant with that mechanism?
# - Though I may need to always at least have _some_ small value here...
# FIXME: D Tweak this.
const JUMP_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 0.5
const MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON := Utils.PHYSICS_TIME_STEP * 0.5

# FIXME: D: Tweak this.
const MIN_MAX_VELOCITY_X_OFFSET := 0.01

var JUMP_RELEASE_INSTRUCTION = PlayerInstruction.new("jump", -1, false)

var name: String
var params: MovementParams
var surfaces: Array
var surface_parser: SurfaceParser

var can_traverse_edge := false
var can_traverse_to_air := false
var can_traverse_from_air := false

func _init(name: String, params: MovementParams) -> void:
    self.name = name
    self.params = params

func set_surfaces(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser
    self.surfaces = surface_parser.get_subset_of_surfaces( \
            params.can_grab_walls, params.can_grab_ceilings, params.can_grab_floors)

func get_all_edges_from_surface(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, possible_destination_surfaces: Array, \
        surface: Surface) -> Array:
    Utils.error( \
            "Abstract PlayerMovement.get_all_edges_from_surface is not implemented")
    return []

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, start: PositionAlongSurface, \
        end: Vector2) -> PlayerInstructions:
    Utils.error("Abstract PlayerMovement.get_instructions_to_air is not implemented")
    return null

func get_all_reachable_surface_instructions_from_air(space_state: Physics2DDirectSpaceState, \
        start: Vector2, end: PositionAlongSurface, velocity_start: Vector2) -> Array:
    Utils.error("Abstract PlayerMovement.get_all_reachable_surface_instructions_from_air is not implemented")
    return []

static func _calculate_constraints_around_surface(movement_params: MovementParams, \
        vertical_step: MovementVertCalcStep, previous_constraint: MovementConstraint, \
        origin_constraint: MovementConstraint, colliding_surface: Surface, \
        constraint_offset: Vector2) -> Array:
    var passing_vertically: bool
    var position_a: Vector2
    var position_b: Vector2
    
    # Calculate the positions of each constraint.
    match colliding_surface.side:
        SurfaceSide.FLOOR:
            passing_vertically = true
            # Left end
            position_a = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            # Right end
            position_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
        SurfaceSide.CEILING:
            passing_vertically = true
            # Left end
            position_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            # Right end
            position_b = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
        SurfaceSide.LEFT_WALL:
            passing_vertically = false
            # Top end
            position_a = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            # Bottom end
            position_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
        SurfaceSide.RIGHT_WALL:
            passing_vertically = false
            # Top end
            position_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            # Bottom end
            position_b = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
    
    var constraint_a := MovementConstraint.new( \
            colliding_surface, position_a, passing_vertically, true)
    var constraint_b := MovementConstraint.new( \
            colliding_surface, position_b, passing_vertically, false)
    
    var is_a_valid := update_constraint(constraint_a, previous_constraint, null, \
            origin_constraint, movement_params, vertical_step.velocity_step_start, \
            vertical_step.can_hold_jump_button, vertical_step, null)
    var is_b_valid := update_constraint(constraint_b, previous_constraint, null, \
            origin_constraint, movement_params, vertical_step.velocity_step_start, \
            vertical_step.can_hold_jump_button, vertical_step, null)
    
    var result := []
    if is_a_valid:
        result.push_back(constraint_a)
    if is_b_valid:
        result.push_back(constraint_b)
    return result

# Returns false if the constraint cannot satisfy the given parameters.
static func update_constraint(constraint: MovementConstraint, \
        previous_constraint: MovementConstraint, next_constraint: MovementConstraint, \
        origin_constraint: MovementConstraint, movement_params: MovementParams, \
        velocity_start_origin: Vector2, can_hold_jump_button_at_origin: bool, \
        vertical_step: MovementVertCalcStep, \
        additional_high_constraint: MovementConstraint) -> bool:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.

    # Previous and next constraints and vertical_step should be provided when updating intermediate constraints.
    assert(previous_constraint != null or constraint.is_origin)
    assert(next_constraint != null or constraint.is_destination)
    assert(vertical_step != null or constraint.is_destination or constraint.is_origin)

    # additional_high_constraint should only ever be provided for the destination, and then only
    # when we're doing backtracking for a new jump-height.
    assert(additional_high_constraint == null or constraint.is_destination)
    assert(vertical_step != null or additional_high_constraint == null)

    var horizontal_movement_sign := \
            _calculate_horizontal_movement_sign(constraint, previous_constraint, next_constraint)
    
    var time_passing_through: float
    var min_velocity_x: float
    var max_velocity_x: float
    var actual_velocity_x: float

    # Calculate the time that the movement would pass through the constraint.
    if constraint.is_origin:
        time_passing_through = 0.0
        min_velocity_x = velocity_start_origin.x
        max_velocity_x = velocity_start_origin.x
        actual_velocity_x = velocity_start_origin.x
    else:
        var position := constraint.position
        var previous_position := previous_constraint.position
        var displacement := position - previous_position
        
        # Check whether the vertical displacement is possible.
        if displacement.y < -movement_params.max_upward_jump_distance:
            return false
        
        if constraint.is_destination:
            # For the destination constraint, we need to calculate time_to_release_jump. All other
            # constraints can re-use this information from the vertical_step.

            var time_to_release_jump: float

            # We consider different parameters if we are starting a new movement calculation vs
            # backtracking to consider a new jump height.
            var constraint_to_calculate_jump_release_time_for: MovementConstraint
            if vertical_step == null:
                # We are starting a new movement calculation (not backtracking to consider a new
                # jump height).
                constraint_to_calculate_jump_release_time_for = constraint
            else:
                # We are backtracking to consider a new jump height.
                constraint_to_calculate_jump_release_time_for = additional_high_constraint
            
            # TODO: I should probably refactor these two calls, so we're doing fewer redundant
            #       calculations here.

            var origin_position := origin_constraint.position

            var time_to_pass_through_constraint_ignoring_others := \
                    calculate_time_to_jump_to_constraint(movement_params, origin_position, \
                            constraint_to_calculate_jump_release_time_for.position, \
                            velocity_start_origin, can_hold_jump_button_at_origin)
            if time_to_pass_through_constraint_ignoring_others == INF:
                return false
            assert(time_to_pass_through_constraint_ignoring_others > 0.0)

            var displacement_from_origin: Vector2 = \
                    constraint_to_calculate_jump_release_time_for.position - origin_position
            time_to_release_jump = calculate_time_to_release_jump_button( \
                    movement_params, time_to_pass_through_constraint_ignoring_others, \
                    displacement_from_origin)
            # If time_to_pass_through_constraint_ignoring_others was valid, then this should also
            # be valid.
            assert(time_to_release_jump != INF)

            if vertical_step != null:
                # We are backtracking to consider a new jump height.
                # The destination jump-release time should account for both:
                # - the time needed to reach any previous jump-heights before this current round of
                #   jump-height backtracking (vertical_step.time_instruction_end),
                # - and the time needed to reach this new previously-out-of-reach constraint
                #   (time_to_release_jump for the new constraint).
                time_to_release_jump = \
                        max(vertical_step.time_instruction_end, time_to_release_jump)
                
                time_passing_through = _calculate_time_for_passing_through_constraint( \
                        movement_params, vertical_step, constraint, vertical_step.time_step_end)
            else:
                # We are starting a new movement calculation (not backtracking to consider a new
                # jump height).
                time_passing_through = time_to_pass_through_constraint_ignoring_others

        else:
            # This is an intermediate constraint (not the origin or destination).
            time_passing_through = _calculate_time_for_passing_through_constraint( \
                    movement_params, vertical_step, constraint, \
                    previous_constraint.time_passing_through)
            
            var still_holding_jump_button := \
                    time_passing_through < vertical_step.time_instruction_end
            
            # We can quit early for a few types of constraints.
            if !constraint.passing_vertically and constraint.should_stay_on_min_side and \
                    still_holding_jump_button:
                # Quit early if we are trying to go above a wall, but we already released the jump
                # button.
                return false
            elif !constraint.passing_vertically and !constraint.should_stay_on_min_side and \
                    !still_holding_jump_button:
                # Quit early if we are trying to go below a wall, but we are still holding the jump
                # button.
                return false
            else:
                # We should never hit a floor while still holding the jump button.
                assert(!(constraint.surface.side == SurfaceSide.FLOOR and \
                        still_holding_jump_button))
        
        # Calculate the min and max velocity for movement through the constraint.
        var duration := time_passing_through - previous_constraint.time_passing_through
        var min_and_max_velocity_at_step_end := _calculate_min_and_max_velocity_at_end_of_interval( \
                previous_position.x, position.x, duration, \
                previous_constraint.min_velocity_x, previous_constraint.max_velocity_x, \
                movement_params.max_horizontal_speed_default, \
                movement_params.in_air_horizontal_acceleration, \
                horizontal_movement_sign)
        if min_and_max_velocity_at_step_end.empty():
            return false
        
        min_velocity_x = min_and_max_velocity_at_step_end[0]
        max_velocity_x = min_and_max_velocity_at_step_end[1]
        
        if constraint.is_destination:
            # Initialize the destination constraint's actual velocity to match whichever min/max
            # value yields the least overall movement.
            actual_velocity_x = \
                    constraint.min_velocity_x if horizontal_movement_sign > 0 else \
                    constraint.max_velocity_x
        else:
            # actual_velocity_x is calculated in a back-to-front pass when calculating the
            # horizontal steps.
            actual_velocity_x = INF
    
    constraint.horizontal_movement_sign = horizontal_movement_sign
    constraint.time_passing_through = time_passing_through
    constraint.min_velocity_x = min_velocity_x
    constraint.max_velocity_x = max_velocity_x
    constraint.actual_velocity_x = actual_velocity_x
    
    return true

static func _calculate_horizontal_movement_sign(constraint: MovementConstraint, \
        previous_constraint: MovementConstraint, next_constraint: MovementConstraint) -> int:
    assert(constraint.surface != null or constraint.is_origin or constraint.is_destination)
    assert(previous_constraint != null or constraint.is_origin)
    assert(next_constraint != null or !constraint.is_origin)
    
    var surface := constraint.surface
    var displacement := constraint.position - previous_constraint.position if \
            previous_constraint != null else next_constraint.position - constraint.position
    var neighbor_horizontal_movement_sign := previous_constraint.horizontal_movement_sign if \
            previous_constraint != null else next_constraint.horizontal_movement_sign
    var is_origin := constraint.is_origin
    var is_destination := constraint.is_destination

    var displacement_sign := \
            0 if Geometry.are_floats_equal_with_epsilon( \
                    displacement_from_previous.x, 0.0, 0.1) else \
            (1 if displacement_from_previous.x > 0 else \
            -1)
    
    var horizontal_movement_sign_from_displacement := \
            -1 if displacement_sign == -1 else \
            (1 if displacement_sign == 1 else \
            # For straight-vertical steps, if there was any horizontal movement through the
            # previous, then we're going to need to backtrack in the opposition direction to reach
            # the destination.
            (neighbor_horizontal_movement_sign if neighbor_horizontal_movement_sign != INF else \
            # For straight vertical steps from the origin, we don't have much to go off of for
            # picking the horizontal movement direction, so just default to rightward for now.
            1))

    var horizontal_movement_sign_from_surface: int
    if is_origin:
        horizontal_movement_sign_from_surface = \
                1 if surface != null and surface.side == SurfaceSide.LEFT_WALL else \
                (-1 if surface != null and surface.side == SurfaceSide.RIGHT_WALL else \
                horizontal_movement_sign_from_displacement)
    elif is_destination:
        horizontal_movement_sign_from_surface = \
                -1 if surface != null and surface.side == SurfaceSide.LEFT_WALL else \
                (1 if surface != null and surface.side == SurfaceSide.RIGHT_WALL else \
                horizontal_movement_sign_from_displacement)
    else:
        horizontal_movement_sign_from_surface = \
                -1 if surface.side == SurfaceSide.LEFT_WALL else \
                (1 if surface.side == SurfaceSide.RIGHT_WALL else \
                (-1 if constraint.should_stay_on_min_side else 1))
    
    assert(horizontal_movement_sign_from_surface == horizontal_movement_sign_from_displacement or \
            (is_origin and displacement_sign == 0))

    return horizontal_movement_sign_from_surface

# The given parameters represent the horizontal motion of a single step.
# 
# A Vector2 is returned:
# - The x property represents the min velocity.
# - The y property represents the max velocity.
static func _calculate_min_and_max_velocity_at_end_of_interval(s_0: float, s: float, t: float, \
        v_0_min_from_prev_constraint: float, v_0_max_from_prev_constraint: float, \
        speed_max: float, a_magnitude: float, horizontal_movement_sign: int) -> Array:
    var displacement := s - s_0
    
    if horizontal_movement_sign < 0:
        # Swap some params, so that we can simplify the calculations to assume one direction.
        var swap := s_0
        s_0 = s
        s = swap
        swap = v_0_min_from_prev_constraint
        v_0_min_from_prev_constraint = -v_0_max_from_prev_constraint
        v_0_max_from_prev_constraint = -swap
        displacement = -displacement
    
    var d_squared: float
    var duration_to_hold_move_sideways: float
    var min_v_0_that_can_reach_target: float
    var max_v_0_that_can_reach_target: float
    var v_0_min: float
    var v_0_max: float
    
    # Calculate the max-possible end x velocity.
    # - First, try using a forward acceleration.
    # - Then, try a backward acceleration, if forward didn't work.
    var v_max: float
    for a in [a_magnitude, -a_magnitude]:
        # The minimum possible v_0 will yield the maximum possible v.
        # From a basic equation of motion:
        #    s = s_0 + v_0*t + 1/2*a*t^2
        #    Algebra...
        #    v_0 = (s - s_0)/t - 1/2*a*t
        min_v_0_that_can_reach_target = displacement / t - 0.5 * a * t
        # The mimimum possible v_0 is dependent on both the duration of the current step and the
        # minimum possible step-end v_0 from the previous step.
        v_0_min = max(min_v_0_that_can_reach_target, v_0_min_from_prev_constraint)
        
        # - There are two parts:
        #   - Part 1: Coast at v_0 until we need to start accelerating.
        #   - Part 2: Constant acceleration from v_0 to v_1.
        #   - The longer part 1 is, the more we can accelerate during part 2, and the bigger v_1 can
        #     be.
        # Derivation:
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_1
        # - s_2 = s_1 + v_0*t_2 + 1/2*a*t_2^2
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - t_2 = sqrt(2 * (s_2 - s_0 - v_0*t_total) / a)
        d_squared = 2 * (s - s_0 - v_0_min * t) / a
        if d_squared < 0:
            # We cannot reach the end with these parameters.
            continue
        duration_to_hold_move_sideways = sqrt(d_squared)
        
        # From a basic equation of motion:
        #    v = v_0 + a*t
        v_max = v_0_min + a * duration_to_hold_move_sideways
    
    # Calculate the min-possible end x velocity.
    # - First, try using a backward acceleration.
    # - Then, try a forward acceleration, if backward didn't work.
    var v_min: float
    for a in [-a_magnitude, a_magnitude]:
        # The maximum possible v_0 will yield the minimum possible v.
        # From a basic equation of motion:
        #    s = s_0 + v_0*t + 1/2*a*t^2
        #    Algebra...
        #    v_0 = (s - s_0)/t - 1/2*a*t
        max_v_0_that_can_reach_target = displacement / t - 0.5 * a * t
        # The maximum possible v_0 is dependent on both the duration of the current step and the
        # maximum possible step-end v_0 from the previous step.
        v_0_max = min(max_v_0_that_can_reach_target, v_0_max_from_prev_constraint)
        
        # - There are two parts:
        #   - Part 1: Coast at v_0 until we need to start decelerating.
        #   - Part 2: Constant deceleration from v_0 to v_1.
        #   - The longer part 1 is, the more we can decelerate during part 2, and the smaller v_1 can
        #     be.
        # Derivation:
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_1
        # - s_2 = s_1 + v_0*t_2 + 1/2*a*t_2^2
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - t_2 = sqrt(2 * (s_2 - s_0 - v_0*t_total) / a)
        d_squared = 2 * (s - s_0 - v_0_max * t) / a
        if d_squared < 0:
            # We cannot reach the end with these parameters.
            continue
        duration_to_hold_move_sideways = sqrt(d_squared)
        
        # From a basic equation of motion:
        #    v = v_0 + a*t
        v_min = v_0_max + a * duration_to_hold_move_sideways
    
    if v_min == INF or v_max == INF:
        # Expect that if one value is invalid, the other should be too.
        assert(v_min == INF and v_max == INF)
        # We cannot reach this constraint from the previous constraint.
        return []
    
    # Correct small floating-point errors around zero.
    if Geometry.are_floats_equal_with_epsilon(v_min, 0.0):
        v_min = 0.0
    if Geometry.are_floats_equal_with_epsilon(v_max, 0.0):
        v_max = 0.0
    
    assert(v_min >= 0.0)
    assert(v_max >= 0.0)
    
    # Limit max speed.
    v_min = min(v_min, speed_max) + MIN_MAX_VELOCITY_X_OFFSET
    v_max = min(v_max, speed_max) - MIN_MAX_VELOCITY_X_OFFSET
    
    if horizontal_movement_sign > 0:
        return [v_min, v_max]
    else:
        return [-v_max, -v_min]

# Calculates the vertical component of position and velocity according to the given vertical
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
# FIXME: B: Fix unit tests to use the return value instead of output params.
static func calculate_vertical_end_state_for_time(movement_params: MovementParams, \
        vertical_step: MovementVertCalcStep, time: float) -> Vector2:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    var slow_ascent_end_time := min(time, vertical_step.time_instruction_end)
    
    # Basic equations of motion.
    var slow_ascent_end_position := vertical_step.position_step_start.y + \
            vertical_step.velocity_step_start.y * slow_ascent_end_time + \
            0.5 * movement_params.gravity_slow_ascent * slow_ascent_end_time * slow_ascent_end_time
    var slow_ascent_end_velocity := vertical_step.velocity_step_start.y + \
            movement_params.gravity_slow_ascent * slow_ascent_end_time
    
    var position: float
    var velocity: float
    if vertical_step.time_instruction_end >= time:
        # We only need to consider the slow-ascent parabolic section.
        position = slow_ascent_end_position
        velocity = slow_ascent_end_velocity
    else:
        # We need to consider both the slow-ascent and fast-fall parabolic sections.
        
        var fast_fall_duration := time - slow_ascent_end_time
        
        # Basic equations of motion.
        position = slow_ascent_end_position + \
            slow_ascent_end_velocity * fast_fall_duration + \
            0.5 * movement_params.gravity_fast_fall * fast_fall_duration * fast_fall_duration
        velocity = slow_ascent_end_velocity + movement_params.gravity_fast_fall * fast_fall_duration
    
    return Vector2(position, velocity)

# Calculates the horizontal component of position and velocity according to the given horizontal
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
static func calculate_horizontal_end_state_for_time(movement_params: MovementParams, \
        horizontal_step: MovementCalcStep, time: float) -> Vector2:
    assert(time >= horizontal_step.time_step_start - Geometry.FLOAT_EPSILON)
    assert(time <= horizontal_step.time_step_end + Geometry.FLOAT_EPSILON)
    
    var position: float
    var velocity: float
    if time <= horizontal_step.time_instruction_start:
        var delta_time := time - horizontal_step.time_step_start
        velocity = horizontal_step.velocity_step_start.x
        # From a basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_step_start.x + velocity * delta_time
        
    elif time >= horizontal_step.time_instruction_end:
        var delta_time := time - horizontal_step.time_instruction_end
        velocity = horizontal_step.velocity_instruction_end.x
        # From a basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_instruction_end.x + velocity * delta_time
        
    else:
        var delta_time := time - horizontal_step.time_instruction_start
        var acceleration := movement_params.in_air_horizontal_acceleration * \
                horizontal_step.horizontal_acceleration_sign
        # From basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        position = horizontal_step.position_instruction_start.x + \
                horizontal_step.velocity_step_start.x * delta_time + \
                0.5 * acceleration * delta_time * delta_time
        # From basic equation of motion:
        #     v = v_0 + a*t
        velocity = horizontal_step.velocity_step_start.x + acceleration * delta_time
    
    assert(velocity <= movement_params.max_horizontal_speed_default + 0.001)
    
    return Vector2(position, velocity)

# Calculates the time at which the movement would travel through the given position given the
# given vertical_step.
# FIXME: B: Update unit tests to include min_end_time.
static func _calculate_time_for_passing_through_constraint(movement_params: MovementParams, \
        vertical_step: MovementVertCalcStep, constraint: MovementConstraint, \
        min_end_time: float) -> float:
    var position := constraint.position

    var position_instruction_end := vertical_step.position_instruction_end
    var velocity_instruction_end := vertical_step.velocity_instruction_end
    
    var target_height := position.y
    var start_height := vertical_step.position_step_start.y
    
    var duration_of_slow_ascent: float
    var duration_of_fast_fall: float
    
    var is_position_before_instruction_end: bool
    var is_position_before_peak: bool
    
    # We need to know whether the position corresponds to the rising or falling side of the jump
    # parabola, and whether the position corresponds to before or after the jump button is
    # released.
    match constraint.surface.side:
        SurfaceSide.FLOOR:
            # Jump reaches the position after releasing the jump button (and after the peak).
            is_position_before_instruction_end = false
            is_position_before_peak = false
        SurfaceSide.CEILING:
            # Jump reaches the position before the peak.
            is_position_before_peak = true
            
            if target_height > start_height:
                return INF
            
            if target_height > position_instruction_end.y:
                # Jump reaches the position before releasing the jump button.
                is_position_before_instruction_end = true
            else:
                # Jump reaches the position after releasing the jump button (but before the
                # peak).
                is_position_before_instruction_end = false
        _: # A wall.
            if !constraint.is_destination:
                # We are considering an intermediate constraint.
                if constraint.should_stay_on_min_side:
                    # Passing over the top of the wall (jump reaches the position before the peak).
                    is_position_before_peak = true
                    
                    # FIXME: Double-check whether the vertical_step calculations will have actually
                    #        supported upward velocity at this point, or whether it will be forcing
                    #        downward?
                    
                    if target_height > position_instruction_end.y:
                        # We assume that we will always use upward velocity when passing over a
                        # wall.
                        # Jump reaches the position before releasing the jump button.
                        is_position_before_instruction_end = true
                    else:
                        # We assume that we will always use downward velocity when passing under a
                        # wall.
                        # Jump reaches the position after releasing the jump button.
                        is_position_before_instruction_end = false
                else:
                    # Passing under the bottom of the wall (jump reaches the position after
                    # releasing the jump button and after the peak).
                    is_position_before_instruction_end = false
                    is_position_before_peak = false
            else:
                # We are considering a destination surface.
                # We assume destination walls will always use downward velocity at the end.
                is_position_before_instruction_end = false
                is_position_before_peak = false
    
    if is_position_before_instruction_end:
        duration_of_slow_ascent = Geometry.calculate_movement_duration(start_height, \
                target_height, movement_params.jump_boost, movement_params.gravity_slow_ascent, \
                true, min_end_time, false)
        if duration_of_slow_ascent == INF:
            return INF
        duration_of_fast_fall = 0.0
    else:
        duration_of_slow_ascent = vertical_step.time_instruction_end
        min_end_time = max(min_end_time - duration_of_slow_ascent, 0.0)
        duration_of_fast_fall = Geometry.calculate_movement_duration( \
                position_instruction_end.y, target_height, velocity_instruction_end.y, \
                movement_params.gravity_fast_fall, is_position_before_peak, min_end_time, false)
        if duration_of_fast_fall == INF:
            return INF
    
    return duration_of_fast_fall + duration_of_slow_ascent

# Calculates the duration to accelerate over in order to reach the destination at the given time,
# given that velocity continues after acceleration stops and a new backward acceleration is
# applied.
# 
# Note: This could depend on a speed that exceeds the max-allowed speed.
# TODO: Remove if no-one is still using this.
static func _calculate_time_to_release_acceleration(time_start: float, time_step_end: float, \
        position_start: float, position_end: float, velocity_start: float, \
        acceleration_start: float, post_release_backward_acceleration: float, \
        returns_lower_result := true, expects_only_one_positive_result := false) -> float:
    var duration := time_step_end - time_start
    
    # Derivation:
    # - Start with basic equations of motion
    # - v_1 = v_0 + a_0*t_0
    # - s_2 = s_1 + v_1*t_1 + 1/2*a_1*t_1^2
    # - s_0 = s_0 + v_0*t_0 + 1/2*a_0*t_0^2
    # - t_2 = t_0 + t_1
    # - Do some algebra...
    # - 0 = (1/2*(a_0 - a_1)) * t_0^2 + (t_2 * (a_1 - a_0)) * t_0 + (s_2 - s_0 - t_2 * (v_0 + 1/2*a_1*t_2))
    # - Apply quadratic formula to solve for t_0.
    var a := 0.5 * (acceleration_start - post_release_backward_acceleration)
    var b := duration * (post_release_backward_acceleration - acceleration_start)
    var c := position_end - position_start - duration * \
            (velocity_start + 0.5 * post_release_backward_acceleration * duration)
    
    # This would produce a divide-by-zero.
    assert(a != 0)
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-b + discriminant_sqrt) / 2 / a
    var t2 := (-b - discriminant_sqrt) / 2 / a
    
    # Optionally ensure that only one result is positive.
    assert(!expects_only_one_positive_result or t1 < 0 or t2 < 0)
    # Ensure that there are not two negative results.
    assert(t1 >= 0 or t2 >= 0)
    
    # Use only non-negative results.
    if t1 < 0:
        return t2
    elif t2 < 0:
        return t1
    else:
        if returns_lower_result:
            return min(t1, t2)
        else:
            return max(t1, t2)

# Calculates the minimum required time to reach the destination, considering a maximum velocity.
static func _calculate_min_time_to_reach_position(s_0: float, s: float, \
        v_0: float, speed_max: float, a: float) -> float:
    if s_0 == s:
        # The start position is the destination.
        return 0.0
    elif a == 0:
        # Handle the degenerate case with no acceleration.
        if v_0 == 0:
            # We can't reach the destination, since we're not moving anywhere.
            return INF 
        elif (s - s_0 > 0) != (v_0 > 0):
            # We can't reach the destination, since we're moving in the wrong direction.
            return INF
        else:
            # s = s_0 + v_0*t
            return (s - s_0) / v_0
    
    var velocity_max := speed_max if a > 0 else -speed_max
    
    var duration_to_reach_position_with_no_velocity_cap: float = \
            Geometry.calculate_movement_duration(s_0, s, v_0, a, true, 0.0, true)
    
    if duration_to_reach_position_with_no_velocity_cap == INF:
        # We can't ever reach the destination.
        return INF
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_to_reach_max_velocity := (velocity_max - v_0) / a
    assert(duration_to_reach_max_velocity > 0)
    
    if duration_to_reach_max_velocity >= duration_to_reach_position_with_no_velocity_cap:
        # We won't have hit the max velocity before reaching the destination.
        return duration_to_reach_position_with_no_velocity_cap
    else:
        # We will have hit the max velocity before reaching the destination.
        
        # From a basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        var position_when_reaching_max_velocity := s_0 + v_0 * duration_to_reach_max_velocity + \
                0.5 * a * duration_to_reach_max_velocity * duration_to_reach_max_velocity
        
        # From a basic equation of motion:
        #     s = s_0 + v*t
        var duration_with_max_velocity := (s - position_when_reaching_max_velocity) / velocity_max
        assert(duration_with_max_velocity > 0)
        
        return duration_to_reach_max_velocity + duration_with_max_velocity

static func get_all_jump_positions_from_surface(movement_params: MovementParams, \
        surface: Surface, target_vertices: Array, target_bounding_box: Rect2) -> Array:
    var start: Vector2 = surface.vertices[0]
    var end: Vector2 = surface.vertices[surface.vertices.size() - 1]
    
    # Use a bounding-box heuristic to determine which end of the surfaces are likely to be
    # nearer and farther.
    var near_end: Vector2
    var far_end: Vector2
    if Geometry.distance_squared_from_point_to_rect(start, target_bounding_box) < \
            Geometry.distance_squared_from_point_to_rect(end, target_bounding_box):
        near_end = start
        far_end = end
    else:
        near_end = end
        far_end = start
    
    # Record the near-end poist.
    var jump_position := _create_position_from_target_point( \
            near_end, surface, movement_params.collider_half_width_height)
    var possible_jump_positions = [jump_position]

    # Only consider the far-end point if it is distinct.
    if surface.vertices.size() > 1:
        jump_position = _create_position_from_target_point( \
                far_end, surface, movement_params.collider_half_width_height)
        possible_jump_positions.push_back(jump_position)
        
        # The actual clostest point along the surface could be somewhere in the middle.
        # Only consider the closest point if it is distinct.
        var closest_point: Vector2 = \
                Geometry.get_closest_point_on_polyline_to_polyline(surface.vertices, target_vertices)
        if closest_point != near_end and closest_point != far_end:
            jump_position = _create_position_from_target_point( \
                    closest_point, surface, movement_params.collider_half_width_height)
            possible_jump_positions.push_back(jump_position)
    
    return possible_jump_positions

static func _create_position_from_target_point(target_point: Vector2, surface: Surface, \
        collider_half_width_height: Vector2) -> PositionAlongSurface:
    var position := PositionAlongSurface.new()
    position.match_surface_target_and_collider(surface, target_point, collider_half_width_height)
    return position

# Translates movement data from a form that is more useful when calculating the movement to a form
# that is more useful when executing the movement.
static func convert_calculation_steps_to_player_instructions( \
        position_start: Vector2, position_end: Vector2, \
        calc_results: MovementCalcResults, includes_jump := true) -> PlayerInstructions:
    var steps := calc_results.horizontal_steps
    var vertical_step := calc_results.vertical_step
    
    var distance_squared := position_start.distance_squared_to(position_end)
    
    var constraint_positions := []
    
    var instructions := []
    instructions.resize(steps.size() * 2)
    
    var step: MovementCalcStep
    var input_key: String
    var press: PlayerInstruction
    var release: PlayerInstruction

    # Record the various sideways movement instructions.
    for i in range(steps.size()):
        step = steps[i]
        input_key = "move_left" if step.horizontal_acceleration_sign < 0 else "move_right"
        press = PlayerInstruction.new(input_key, step.time_instruction_start, true)
        release = PlayerInstruction.new(input_key, \
                step.time_instruction_end + MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON, false)
        instructions[i * 2] = press
        instructions[i * 2 + 1] = release
        
        # Keep track of some info for edge annotation debugging.
        constraint_positions.push_back(step.position_step_end)
    
    # Record the jump instruction.
    if includes_jump:
        input_key = "jump"
        press = PlayerInstruction.new(input_key, vertical_step.time_instruction_start, true)
        release = PlayerInstruction.new(input_key, \
                vertical_step.time_instruction_end + JUMP_DURATION_INCREASE_EPSILON, false)
        instructions.push_front(release)
        instructions.push_front(press)
    
    return PlayerInstructions.new(instructions, vertical_step.time_step_end, distance_squared, \
            constraint_positions)

static func update_velocity_in_air( \
        velocity: Vector2, delta: float, is_pressing_jump: bool, is_first_jump: bool, \
        horizontal_acceleration_sign: int, movement_params: MovementParams) -> Vector2:
    var is_ascending_from_jump := velocity.y < 0 and is_pressing_jump
    
    # Make gravity stronger when falling. This creates a more satisfying jump.
    # Similarly, make gravity stronger for double jumps.
    var gravity_multiplier := 1.0 if !is_ascending_from_jump else \
            (movement_params.slow_ascent_gravity_multiplier if is_first_jump \
                    else movement_params.ascent_double_jump_gravity_multiplier)
    
    # Vertical movement.
    velocity.y += delta * movement_params.gravity_fast_fall * gravity_multiplier
    
    # Horizontal movement.
    velocity.x += delta * movement_params.in_air_horizontal_acceleration * horizontal_acceleration_sign
    
    return velocity

static func cap_velocity(velocity: Vector2, movement_params: MovementParams) -> Vector2:
    # Cap horizontal speed at a max value.
    velocity.x = clamp(velocity.x, -movement_params.current_max_horizontal_speed, \
            movement_params.current_max_horizontal_speed)
    
    # Kill horizontal speed below a min value.
    if velocity.x > -movement_params.min_horizontal_speed and \
            velocity.x < movement_params.min_horizontal_speed:
        velocity.x = 0
    
    # Cap vertical speed at a max value.
    velocity.y = clamp(velocity.y, -movement_params.max_vertical_speed, \
            movement_params.max_vertical_speed)
    
    # Kill vertical speed below a min value.
    if velocity.y > -movement_params.min_vertical_speed and \
            velocity.y < movement_params.min_vertical_speed:
        velocity.y = 0
    
    return velocity

# Returns a positive value.
static func calculate_max_upward_movement(movement_params: MovementParams) -> float:
    # FIXME: F: Add support for double jumps, dash, etc.
    
    # From a basic equation of motion:
    # - v^2 = v_0^2 + 2*a*(s - s_0)
    # - s_0 = 0
    # - v = 0
    # - Algebra...
    # - s = -v_0^2 / 2 / a
    return (movement_params.jump_boost * movement_params.jump_boost) / 2 / \
            movement_params.gravity_slow_ascent

static func calculate_max_horizontal_movement( \
        movement_params: MovementParams, velocity_start_y: float) -> float:
    # FIXME: F: Add support for double jumps, dash, etc.
    # FIXME: A: Add horizontal acceleration
    
    # v = v_0 + a*t
    var max_time_to_peak := -velocity_start_y / movement_params.gravity_slow_ascent
    # s = s_0 + v_0*t + 0.5*a*t*t
    var max_peak_height := velocity_start_y * max_time_to_peak + \
            0.5 * movement_params.gravity_slow_ascent * max_time_to_peak * max_time_to_peak
    # v^2 = v_0^2 + 2*a*(s - s_0)
    var max_velocity_when_returning_to_starting_height := \
            sqrt(2 * movement_params.gravity_fast_fall * -max_peak_height)
    # v = v_0 + a*t
    var max_time_for_descent_from_peak_to_starting_height := \
            max_velocity_when_returning_to_starting_height / movement_params.gravity_fast_fall
    # Ascent time plus descent time.
    var max_time_to_starting_height := \
            max_time_to_peak + max_time_for_descent_from_peak_to_starting_height
    # s = s_0 + v * t
    return max_time_to_starting_height * movement_params.max_horizontal_speed_default

# Calculates the minimum possible time it would take to jump between the given positions.
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
static func calculate_time_to_jump_to_constraint(movement_params: MovementParams, \
        position_start: Vector2, position_end: Vector2, velocity_start: Vector2, \
        can_hold_jump_button_at_start: bool) -> float:
    if can_hold_jump_button_at_start:
        # If we can currently hold the jump button, then there is slow-ascent and
        # variable-jump-height to consider.
        
        var displacement: Vector2 = position_end - position_start
        
        # Calculate how long it will take for the jump to reach some minimum peak height.
        # 
        # This takes into consideration the fast-fall mechanics (i.e., that a slower gravity is applied
        # until either the jump button is released or we hit the peak of the jump)
        var duration_to_reach_upward_displacement: float
        if displacement.y < 0:
            # Derivation:
            # - Start with basic equations of motion
            # - v_1^2 = v_0^2 + 2*a_0*(s_1 - s_0)
            # - v_2^2 = v_1^2 + 2*a_1*(s_2 - s_1)
            # - v_2 = 0
            # - s_0 = 0
            # - Do some algebra...
            # - s_1 = (1/2*v_0^2 + a_1*s_2) / (a_1 - a_0)
            var distance_to_release_button_for_shorter_jump := \
                    (0.5 * velocity_start.y * velocity_start.y + \
                    movement_params.gravity_fast_fall * displacement.y) / \
                    (movement_params.gravity_fast_fall - movement_params.gravity_slow_ascent)
            
            if distance_to_release_button_for_shorter_jump < 0:
                # We need more motion than just the initial jump boost to reach the destination.
                var time_to_release_jump_button: float = \
                        Geometry.calculate_movement_duration(0.0, \
                        distance_to_release_button_for_shorter_jump, velocity_start.y, \
                        movement_params.gravity_slow_ascent, true, 0.0, false)
                assert(time_to_release_jump_button != INF)
            
                # From a basic equation of motion:
                #     v = v_0 + a*t
                var velocity_at_jump_button_release := velocity_start.y + \
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
                duration_to_reach_upward_displacement = Geometry.calculate_movement_duration(0.0, \
                        displacement.y, velocity_start.y, \
                        movement_params.gravity_fast_fall, true, 0.0, false)
        else:
            # We're jumping downward, so we don't need to reach any minimum peak height.
            duration_to_reach_upward_displacement = 0.0
        
        # Calculate how long it will take for the jump to reach some lower destination.
        var duration_to_reach_downward_displacement: float
        if displacement.y > 0:
            duration_to_reach_downward_displacement = Geometry.calculate_movement_duration( \
                    position_start.y, position_end.y, velocity_start.y, \
                    movement_params.gravity_fast_fall, true, 0.0, true)
            assert(duration_to_reach_downward_displacement != INF)
        else:
            duration_to_reach_downward_displacement = 0.0
        
        var horizontal_acceleration_sign: int
        if displacement.x < 0:
            horizontal_acceleration_sign = -1
        elif displacement.x > 0:
            horizontal_acceleration_sign = 1
        else:
            horizontal_acceleration_sign = 0
        
        var duration_to_reach_horizontal_displacement := _calculate_min_time_to_reach_position( \
                position_start.x, position_end.x, velocity_start.x, \
                movement_params.max_horizontal_speed_default, \
                movement_params.in_air_horizontal_acceleration * horizontal_acceleration_sign)
        if duration_to_reach_horizontal_displacement == INF:
            # If we can't reach the destination with that acceleration direction, try the other
            # direction.
            horizontal_acceleration_sign = -horizontal_acceleration_sign
            duration_to_reach_horizontal_displacement = _calculate_min_time_to_reach_position( \
                    position_start.x, position_end.x, velocity_start.x, \
                    movement_params.max_horizontal_speed_default, \
                    movement_params.in_air_horizontal_acceleration * horizontal_acceleration_sign)
        assert(duration_to_reach_horizontal_displacement >= 0 and \
                duration_to_reach_horizontal_displacement != INF)
        
        var duration_to_reach_upward_displacement_on_descent := 0.0
        if duration_to_reach_downward_displacement == 0.0:
            # The total duration still isn't enough if we cannot reach the horizontal displacement
            # before we've already past the destination vertically on the upward side of the
            # trajectory. In that case, we need to consider the minimum time for the upward and
            # downward motion of the jump.
            
            var duration_to_reach_upward_displacement_with_only_fast_fall = \
                    Geometry.calculate_movement_duration(position_start.y, position_end.y, \
                            velocity_start.y, movement_params.gravity_fast_fall, true, 0.0, \
                            false)
            
            if duration_to_reach_upward_displacement_with_only_fast_fall != INF and \
                    duration_to_reach_upward_displacement_with_only_fast_fall < \
                    duration_to_reach_horizontal_displacement:
                duration_to_reach_upward_displacement_on_descent = \
                        Geometry.calculate_movement_duration(position_start.y, position_end.y, \
                                velocity_start.y, movement_params.gravity_fast_fall, \
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
        return max(max(max(duration_to_reach_upward_displacement, \
                duration_to_reach_downward_displacement), \
                duration_to_reach_horizontal_displacement), \
                duration_to_reach_upward_displacement_on_descent)
    else:
        # If we can't currently hold the jump button, then there is no slow-ascent and variable
        # jump height to consider. So our movement duration is a lot simpler to calculate.
        return Geometry.calculate_movement_duration(position_start.y, \
                position_end.y, velocity_start.y, movement_params.gravity_fast_fall, false)

# Given the total duration, calculate the time to release the jump button.
static func calculate_time_to_release_jump_button(movement_params: MovementParams, \
        duration: float, displacement: Vector2) -> float:
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
    var b := duration * (movement_params.gravity_slow_ascent - movement_params.gravity_fast_fall)
    var c := -displacement.y + movement_params.jump_boost * duration + \
            0.5 * movement_params.gravity_fast_fall * duration * duration
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # We can't reach the end position from our start position in the given time.
        return INF
    var discriminant_sqrt := sqrt(discriminant)
    var t1 := (-b - discriminant_sqrt) / 2 / a
    var t2 := (-b + discriminant_sqrt) / 2 / a
    
    var time_to_release_jump_button: float
    if t1 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t2
    elif t2 < -Geometry.FLOAT_EPSILON:
        time_to_release_jump_button = t1
    else:
        time_to_release_jump_button = min(t1, t2)
    assert(time_to_release_jump_button >= -Geometry.FLOAT_EPSILON)
    
    time_to_release_jump_button = max(time_to_release_jump_button, 0.0)
    assert(time_to_release_jump_button <= duration)
    
    return time_to_release_jump_button

static func create_terminal_constraints(origin_surface: Surface, origin_position: Vector2, \
        destination_surface: Surface, destination_position: Vector2, \
        movement_params: MovementParams, velocity_start: Vector2) -> Array:
    var origin_passing_vertically := \
            origin_surface.normal.x == 0 if origin_surface != null else true
    var destination_passing_vertically := \
            destination_surface.normal.x == 0 if destination_surface != null else true
    
    var origin := MovementConstraint.new( \
            origin_surface, origin_position, origin_passing_vertically, false)
    var destination := MovementConstraint.new( \
            destination_surface, destination_position, destination_passing_vertically, false)

    origin.is_origin = true
    destination.is_destination = true
    
    var is_origin_valid := update_constraint(origin, null, destination, origin, movement_params, \
            velocity_start, false, null, null)
    var is_destination_valid := update_constraint(destination, origin, null, origin, \
            movement_params, velocity_start, false, null, null)
    
    if is_origin_valid and is_destination_valid:
        return [origin, destination]
    else:
        return []

# Calculates a new step for the vertical part of the movement and the corresponding total jump
# duration.
static func calculate_vertical_step( \
        global_calc_params: MovementCalcGlobalParams) -> MovementVertCalcStep:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    
    var movement_params := global_calc_params.movement_params
    var origin_constraint := global_calc_params.origin_constraint
    var destination_constraint := global_calc_params.destination_constraint
    var velocity_start := global_calc_params.velocity_start
    var can_hold_jump_button := global_calc_params.can_backtrack_on_height
    
    var position_start := origin_constraint.position
    var position_end := destination_constraint.position
    var time_step_end := destination_constraint.time_passing_through
    
    var time_instruction_end: float
    var position_instruction_end: Vector2
    var velocity_instruction_end: Vector2
    
    # Calculate instruction-end and peak-height state. These depend on whether or not we can hold
    # the jump button to manipulate the jump height. 
    if can_hold_jump_button:
        var displacement: Vector2 = position_end - position_start
        time_instruction_end = \
                calculate_time_to_release_jump_button(movement_params, time_step_end, displacement)
        if time_instruction_end == INF:
            return null
        
        # Need to calculate these after the step is instantiated.
        position_instruction_end = Vector2.INF
        velocity_instruction_end = Vector2.INF
    else:
        time_instruction_end = 0.0
        position_instruction_end = position_start
        velocity_instruction_end = velocity_start
    
    # Given the time to release the jump button, calculate the time to reach the peak.
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var velocity_at_jump_button_release := movement_params.jump_boost + \
            movement_params.gravity_slow_ascent * time_instruction_end
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_to_reach_peak_after_release := \
            -velocity_at_jump_button_release / movement_params.gravity_fast_fall
    var time_peak_height := time_instruction_end + duration_to_reach_peak_after_release
    time_peak_height = max(time_peak_height, 0.0)
    
    var step := MovementVertCalcStep.new()
    
    step.horizontal_acceleration_sign = destination_constraint.horizontal_movement_sign
    step.can_hold_jump_button = can_hold_jump_button
    
    step.time_step_start = 0.0
    step.time_instruction_start = 0.0
    step.time_instruction_end = time_instruction_end
    step.time_step_end = time_step_end
    step.time_peak_height = time_peak_height
    
    step.position_step_start = position_start
    step.position_instruction_start = position_start
    step.position_step_end = position_end
    
    step.velocity_step_start = velocity_start
    step.velocity_instruction_start = velocity_start
    
    var step_end_state := \
            calculate_vertical_end_state_for_time(movement_params, step, time_step_end)
    var peak_height_end_state := \
            calculate_vertical_end_state_for_time(movement_params, step, time_peak_height)
    
    assert(Geometry.are_floats_equal_with_epsilon(step_end_state.x, position_end.y, 0.001))
    
    step.position_peak_height = Vector2(INF, peak_height_end_state.x)
    step.velocity_step_end = Vector2(INF, step_end_state.y)
    
    if position_instruction_end == Vector2.INF:
        var instruction_end_state := \
                calculate_vertical_end_state_for_time(movement_params, step, time_instruction_end)
        position_instruction_end = Vector2(INF, instruction_end_state.x)
        velocity_instruction_end = Vector2(INF, instruction_end_state.y)
    
    step.position_instruction_end = position_instruction_end
    step.velocity_instruction_end = velocity_instruction_end

    return step

# Calculates a new step for the horizontal part of the movement.
static func calculate_horizontal_step(local_calc_params: MovementCalcLocalParams, \
        global_calc_params: MovementCalcGlobalParams) -> MovementCalcStep:
    var movement_params := global_calc_params.movement_params
    var vertical_step := local_calc_params.vertical_step
    
    var start_constraint := local_calc_params.start_constraint
    var position_step_start := start_constraint.position
    var time_step_start := start_constraint.time_passing_through
    
    var end_constraint := local_calc_params.end_constraint
    var position_end := end_constraint.position
    var time_step_end := end_constraint.time_passing_through
    var velocity_end_x := end_constraint.actual_velocity_x
    
    var step_duration := time_step_end - time_step_start
    var displacement := position_end - position_step_start
    
    # FIXME: LEFT OFF HERE: DEBUGGING: REMOVE: -A
#    if position_step_start == Vector2(-2, -483) and position_end == Vector2(-128, -478):
#        print("yo")
    
    var horizontal_acceleration_sign: int
    var acceleration: float
    var velocity_start_x: float
    var should_accelerate_at_start: bool
    
    # Calculate the velocity_start_x, the direction of acceleration, and whether we should
    # accelerate at the start of the step or at the end of the step.
    if end_constraint.horizontal_movement_sign != start_constraint.horizontal_movement_sign:
        # If the start and end velocities are in opposition horizontal directions, then there is
        # only one possible acceleration direction.
        
        horizontal_acceleration_sign = end_constraint.horizontal_movement_sign
        acceleration = \
                movement_params.in_air_horizontal_acceleration * horizontal_acceleration_sign
            
        # First, try accelerating at the start of the step, then at the end.
        for try_accelerate_at_start in [true, false]:
            velocity_start_x = _calculate_min_speed_velocity_start_x( \
                    start_constraint.horizontal_movement_sign, displacement.x, \
                    start_constraint.min_velocity_x, start_constraint.max_velocity_x, \
                    velocity_end_x, acceleration, step_duration, try_accelerate_at_start)
            
            if velocity_start_x != INF:
                # We found a valid start velocity.
                should_accelerate_at_start = try_accelerate_at_start
                break
        
    else:
        # If the start and end velocities are in the same horizontal direction, then it's possible
        # for the acceleration to be in either direction.
        
        # Since we generally want to try to minimize movement (and minimize the speed at the start
        # of the step), we first attempt the acceleration direction that corresponds to that min
        # speed.
        var min_speed_x_v_0 := start_constraint.min_velocity_x if \
                start_constraint.horizontal_movement_sign > 0 else \
                start_constraint.max_velocity_x
        
        # Determine acceleration direction.
        var velocity_x_change := velocity_end_x - min_speed_x_v_0
        if velocity_x_change > 0:
            horizontal_acceleration_sign = 1
        elif velocity_x_change < 0:
            horizontal_acceleration_sign = -1
        else:
            horizontal_acceleration_sign = 0
        
        # First, try with the acceleration in one direction, then try the other.
        for sign_multiplier in [horizontal_acceleration_sign, -horizontal_acceleration_sign]:
            acceleration = movement_params.in_air_horizontal_acceleration * sign_multiplier
            
            # First, try accelerating at the start of the step, then at the end.
            for try_accelerate_at_start in [true, false]:
                velocity_start_x = _calculate_min_speed_velocity_start_x( \
                        start_constraint.horizontal_movement_sign, displacement.x, \
                        start_constraint.min_velocity_x, start_constraint.max_velocity_x, \
                        velocity_end_x, acceleration, step_duration, should_accelerate_at_start)
                
                if velocity_start_x != INF:
                    # We found a valid start velocity.
                    should_accelerate_at_start = try_accelerate_at_start
                    break
            
            if velocity_start_x != INF:
                # We found a valid start velocity with acceleration in this direction.
                horizontal_acceleration_sign = sign_multiplier
                break
    
    if velocity_start_x == INF:
        # There is no start velocity that can reach the target end position/velocity/time.
        return null
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var duration_for_horizontal_acceleration := (velocity_end_x - velocity_start_x) / acceleration
    if step_duration < duration_for_horizontal_acceleration:
        # The horizontal displacement is out of reach.
        return null
    var duration_for_horizontal_coasting := step_duration - duration_for_horizontal_acceleration
    
    var time_instruction_start: float
    var time_instruction_end: float
    var position_instruction_start_x: float
    var position_instruction_end_x: float
    
    if should_accelerate_at_start:
        time_instruction_start = time_step_start
        time_instruction_end = time_step_start + duration_for_horizontal_acceleration
        
        position_instruction_start_x = position_step_start.x
        # From a basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        position_instruction_end_x = position_step_start.x + \
                velocity_start_x * duration_for_horizontal_acceleration + \
                0.5 * acceleration * \
                duration_for_horizontal_acceleration * duration_for_horizontal_acceleration
    else:
        time_instruction_start = time_step_end - duration_for_horizontal_acceleration
        time_instruction_end = time_step_end
        
        # From a basic equation of motion:
        #     s = s_0 + v_0*t
        position_instruction_start_x = \
                position_step_start.x + velocity_start_x * duration_for_horizontal_coasting
        position_instruction_end_x = position_step_end.x
    
    var step_start_state := calculate_vertical_end_state_for_time( \
            movement_params, vertical_step, time_step_start)
    var instruction_start_state := calculate_vertical_end_state_for_time( \
            movement_params, vertical_step, time_instruction_start)
    var instruction_end_state := calculate_vertical_end_state_for_time( \
            movement_params, vertical_step, time_instruction_end)
    var step_end_state := calculate_vertical_end_state_for_time( \
            movement_params, vertical_step, time_step_end)
    
    assert(Geometry.are_floats_equal_with_epsilon(step_end_state.x, position_end.y, 0.0001))
    assert(Geometry.are_floats_equal_with_epsilon(step_start_state.x, position_start.y, 0.0001))
    
    var step := MovementCalcStep.new()
    
    step.horizontal_acceleration_sign = horizontal_acceleration_sign
    
    step.time_step_start = time_step_start
    step.time_instruction_start = time_instruction_start
    step.time_instruction_end = time_instruction_end
    step.time_step_end = time_step_end
    
    step.position_step_start = position_step_start
    step.position_instruction_start = Vector2(position_instruction_start_x, instruction_start_state.x)
    step.position_instruction_end = Vector2(position_instruction_end_x, instruction_end_state.x)
    step.position_step_end = position_end
    
    step.velocity_step_start = Vector2(velocity_start_x, step_start_state.y)
    step.velocity_instruction_start = Vector2(velocity_start_x, instruction_start_state.y)
    step.velocity_instruction_end = Vector2(velocity_end_x, instruction_end_state.y)
    step.velocity_step_end = Vector2(velocity_end_x, step_end_state.y)
    
    previous_constraint.actual_velocity_x = step.velocity_start.x
    
    return step

# Calculate the minimum possible start velocity to reach the given end position,
# velocity, and time. This min start velocity corresponds to accelerating the most.
static func _calculate_min_speed_velocity_start_x(horizontal_movement_sign_start: int, \
        displacement: float, v_start_min: float, v_start_max: float, v_end: float, \
        acceleration: float, duration: float, should_accelerate_at_start: bool) -> float:
    var min_speed_x_v_0 := v_start_min if horizontal_movement_sign_start > 0 else v_start_max
    
    if displacement == 0:
        # If we don't need to move horizontally at all, then let's just use the start velocity with
        # the minimum possible speed.
        return min_speed_x_v_0
    
    var a: float
    var b: float
    var c: float
    
    # - Accelerating at the start, and coasting at the end, yields a smaller starting velocity.
    # - Accelerating at the end, and coasting at the start, yields a larger starting velocity.
    if should_accelerate_at_start:
        # Try accelerating at the start of the step.
        # Derivation:
        # - There are two parts:
        #   - Part 1: Constant acceleration from v_0 to v_1.
        #   - Part 2: Coast at v_1 until we reach the destination.
        #   - The shorter part 1 is, the sooner we reach v_1 and the further we travel during
        #     part 2. This then means that we will need to have a lower v_0 and travel less far
        #     during part 1, which is good, since we want to choose a v_0 with the
        #     minimum-possible speed.
        # - Start with basic equations of motion
        # - v_1 = v_0 + a*t_1
        # - s_2 = s_1 + v_1*t_2
        # - v_1^2 = v_0^2 + 2*a*(s_1 - s_0)
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - 0 = 2*a*(s_2 - s_0 - v_1*t_total) + v_1^2 - 2*v_1*v_0 + v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = 1
        b = -2 * v_end
        c = 2 * acceleration * (displacement - v_end * duration) + v_end * v_end
    else:
        # Try accelerating at the end of the step.
        # Derivation:
        # - There are two parts:
        #   - Part 1: Coast at v_0 until we need to start accelerating.
        #   - Part 2: Constant acceleration from v_0 to v_1; we reach the destination when we reach v_1.
        #   - The longer part 1 is, the more we can accelerate during part 2, and the bigger v_1 can
        #     be.
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_0
        # - v_1 = v_0 + a*t_1
        # - v_1^2 = v_0^2 + 2*a*(s_2 - s_1)
        # - t_total = t_0 + t_1
        # - Do some algebra...
        # - 0 = 2*a*(s_2 - s_0) - v_1^2 + 2*(v_1 - a*t_total)*v_0 - v_0^2
        # - Apply quadratic formula to solve for v_0.
        a = -1
        b = 2 * (v_end - acceleration * duration)
        c = 2 * acceleration * displacement - v_end * v_end
    
    var discriminant := b * b - 4 * a * c
    if discriminant < 0:
        # There is no start velocity that can satisfy these parameters.
        return INF
    
    var discriminant_sqrt := sqrt(discriminant)
    var result_1 := (-b + discriminant_sqrt) / 2 / a
    var result_2 := (-b - discriminant_sqrt) / 2 / a
    
    var min_speed_v_0_to_reach_target: float
    if horizontal_movement_sign_start > 0:
        if result_1 < 0:
            min_speed_v_0_to_reach_target = result_2
        elif result_2 < 0:
            min_speed_v_0_to_reach_target = result_1
        else:
            min_speed_v_0_to_reach_target = min(result_1, result_2)
        
        if min_speed_v_0_to_reach_target < 0:
            # Movement must be in the expected direction, so this isn't a valid start velocity.
            return INF
        
        # FIXME: LEFT OFF HERE: --------A:
        # - I'm not sure how to choose between these two possible results right now.
        # - Set a break point and look at them.
        # - Probably add some assertions.
        
        if min_speed_v_0_to_reach_target > v_start_max:
            # We cannot start this step with enough velocity to reach the end position.
            return INF
        elif min_speed_v_0_to_reach_target < v_start_min:
            # The calculated min-speed start velocity is less than the min possible for this step,
            # so let's try using the min possible for this step.
            return v_start_min
        else:
            # The calculated velocity is somewhere within the acceptable min/max range.
            return min_speed_v_0_to_reach_target
    else: 
        # horizontal_movement_sign_start < 0
        
        if result_1 > 0:
            min_speed_v_0_to_reach_target = result_2
        elif result_2 > 0:
            min_speed_v_0_to_reach_target = result_1
        else:
            min_speed_v_0_to_reach_target = max(result_1, result_2)
        
        if min_speed_v_0_to_reach_target > 0:
            # Movement must be in the expected direction, so this isn't a valid start velocity.
            return INF
        
        # FIXME: LEFT OFF HERE: --------A:
        # - I'm not sure how to choose between these two possible results right now.
        # - Set a break point and look at them.
        # - Probably add some assertions.
        
        if min_speed_v_0_to_reach_target < v_start_min:
            # We cannot start this step with enough velocity to reach the end position.
            return INF
        elif min_speed_v_0_to_reach_target > v_start_max:
            # The calculated min-speed start velocity is greater than the max possible for this
            # step, so let's try using the max possible for this step.
            return v_start_max
        else:
            # The calculated velocity is somewhere within the acceptable min/max range.
            return min_speed_v_0_to_reach_target
    
    return INF

static func copy_constraint(original: MovementConstraint) -> MovementConstraint:
    var copy := MovementConstraint.new(original.surface, original.position, \
            original.passing_vertically, original.should_stay_on_min_side)
    copy.horizontal_movement_sign = original.horizontal_movement_sign
    copy.time_passing_through = original.time_passing_through
    copy.min_velocity_x = original.min_velocity_x
    copy.max_velocity_x = original.max_velocity_x
    copy.actual_velocity_x = original.actual_velocity_x
    copy.is_origin = original.is_origin
    copy.is_destination = original.is_destination
    return copy
