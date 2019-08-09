# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name PlayerMovement

const MovementConstraint := preload("res://framework/player_movement/movement_constraint.gd")
const PlayerInstruction := preload("res://framework/player_movement/player_instruction.gd")
const MovementVertCalcStep := preload("res://framework/player_movement/movement_vertical_calculation_step.gd")

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
        start: Vector2, end: PositionAlongSurface, start_velocity: Vector2) -> Array:
    Utils.error("Abstract PlayerMovement.get_all_reachable_surface_instructions_from_air is not implemented")
    return []

static func _calculate_constraints(movement_params: MovementParams, \
        vertical_step: MovementVertCalcStep, colliding_surface: Surface, \
        constraint_offset: Vector2, previous_constraint: MovementConstraint) -> Array:
    # Calculate the positions of each constraint.
    var passing_vertically: bool
    var position_a: Vector2
    var position_b: Vector2
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
    
    # Calculate the time that the movement would pass through each constraint.
    var time_passing_through_a := calculate_time_to_reach_constraint( \
            movement_params, previous_constraint.position, position_a, \
            vertical_step.velocity_start, vertical_step.can_hold_jump_button)
    assert(time_passing_through_a != INF and time_passing_through_a != 0.0)
    var time_passing_through_b := calculate_time_to_reach_constraint( \
            movement_params, previous_constraint.position, position_b, \
            vertical_step.velocity_start, vertical_step.can_hold_jump_button)
    assert(time_passing_through_b != INF and time_passing_through_b != 0.0)
    
    # Calculate the min and max velocity for each constraint.
    var duration_a := time_passing_through_a - previous_constraint.time_passing_through
    var min_and_max_velocity_at_step_end_a := _calculate_min_or_max_velocity_at_end_of_interval( \
            previous_constraint.position.x, position_a.x, duration_a, \
            previous_constraint.min_x_velocity, previous_constraint.max_x_velocity, \
            movement_params.max_horizontal_speed_default, \
            movement_params.in_air_horizontal_acceleration)
    var duration_b := time_passing_through_b - previous_constraint.time_passing_through
    var min_and_max_velocity_at_step_end_b := _calculate_min_or_max_velocity_at_end_of_interval( \
            previous_constraint.position.x, position_b.x, duration_b, \
            previous_constraint.min_x_velocity, previous_constraint.max_x_velocity, \
            movement_params.max_horizontal_speed_default, \
            movement_params.in_air_horizontal_acceleration)
    
    var constraint_a := \
            MovementConstraint.new(colliding_surface, position_a, passing_vertically, true)
    constraint_a.time_passing_through = time_passing_through_a
    constraint_a.min_x_velocity = min_and_max_velocity_at_step_end_a.x
    constraint_a.max_x_velocity = min_and_max_velocity_at_step_end_a.y
    
    var constraint_b := \
            MovementConstraint.new(colliding_surface, position_b, passing_vertically, false)
    constraint_b.time_passing_through = time_passing_through_b
    constraint_b.min_x_velocity = min_and_max_velocity_at_step_end_b.x
    constraint_b.max_x_velocity = min_and_max_velocity_at_step_end_b.y
    
    return [constraint_a, constraint_b]

# The given parameters represent the horizontal motion of a single step. If the movement is
# leftward, this calculates the maximum step-end x velocity. If the movement is rightward, this
# calculates the minimum step-end x velocity.
# 
# A Vector2 is returned:
# - The x property represents the min velocity.
# - The y property represents the max velocity.
# 
# Only one of the min/max values is actually calculated, depending on the direction of movement.
# This is because later calculations in _calculate_horizontal_step will calculate the other value
# directly.
static func _calculate_min_or_max_velocity_at_end_of_interval(s_0: float, s: float, t: float, \
        v_0_min: float, v_0_max: float, speed_max: float, a_magnitude: float) -> Vector2:
    # FIXME: C: Account for movement_sign == 0. And account for pressing sideways-move-input in
    #           opposite direction, in order to counter too-strong velocity_start.
    
    var displacement := s - s_0
    var movement_sign := \
            (1 if displacement > 0 else \
            (-1 if displacement < 0 else \
            0))
    var a := a_magnitude * movement_sign
    
    var v_min: float
    var v_max: float
    if movement_sign > 0:
        # - The minimum possible v_0 will yield the maximum possible v.
        # - The mimimum possible v_0 is dependent on both the duration of the current step and the
        #   minimum possible step-end v_0 from the previous step.
        # From a basic equation of motion:
        #    s = s_0 + v_0*t + 1/2*a*t^2
        #    Algebra...
        #    v_0 = (s - s_0)/t - 1/2*a*t
        var min_v_0_that_can_reach_target := displacement / t - 0.5 * a * t
        var v_0 := max(min_v_0_that_can_reach_target, v_0_min)
        
        # Derivation:
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_1
        # - s_2 = s_1 + v_0*t_2 + 1/2*a*t_2^2
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - t_2 = sqrt(2 * (s_2 - s_0 - v_0*t_total) / a)
        var duration_to_hold_move_sideways := sqrt(2 * (s - s_0 - v_0 * t) / a)
        
        # From a basic equation of motion:
        #    v = v_0 + a*t
        v_max = v_0 + a * duration_to_hold_move_sideways
        
        # Limit max speed.
        var speed := abs(v_max)
        speed = min(speed, speed_max)
        v_max = speed * movement_sign
        
        assert(v_max != INF)
        
        v_min = INF
        
    elif movement_sign < 0:
        # - The maximum possible v_0 will yield the minimum possible v.
        # - The maximum possible v_0 is dependent on both the duration of the current step and the
        #   maximum possible step-end v_0 from the previous step.
        # From a basic equation of motion:
        #    s = s_0 + v_0*t + 1/2*a*t^2
        #    Algebra...
        #    v_0 = (s - s_0)/t - 1/2*a*t
        var max_v_0_that_can_reach_target := displacement / t - 0.5 * a * t
        var v_0 := min(max_v_0_that_can_reach_target, v_0_max)
        
        # Derivation:
        # - Start with basic equations of motion
        # - s_1 = s_0 + v_0*t_1
        # - s_2 = s_1 + v_0*t_2 + 1/2*a*t_2^2
        # - t_total = t_1 + t_2
        # - Do some algebra...
        # - t_2 = sqrt(2 * (s_2 - s_0 - v_0*t_total) / a)
        var duration_to_hold_move_sideways := sqrt(2 * (s - s_0 - v_0 * t) / a)
        
        # From a basic equation of motion:
        #    v = v_0 + a*t
        v_min = v_0 + a * duration_to_hold_move_sideways
        
        # Limit max speed.
        var speed := abs(v_min)
        speed = min(speed, speed_max)
        v_min = speed * movement_sign
        
        assert(v_min != INF)
        
        v_max = INF
        
    else:
        v_min = 0.0
        v_max = 0.0
    
    return Vector2(v_min, v_max)

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
            vertical_step.velocity_start.y * slow_ascent_end_time + \
            0.5 * movement_params.gravity_slow_ascent * slow_ascent_end_time * slow_ascent_end_time
    var slow_ascent_end_velocity := vertical_step.velocity_start.y + \
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
        velocity = horizontal_step.velocity_start.x
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
                horizontal_step.horizontal_movement_sign
        # From basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        position = horizontal_step.position_instruction_start.x + \
                horizontal_step.velocity_start.x * delta_time + \
                0.5 * acceleration * delta_time * delta_time
        # From basic equation of motion:
        #     v = v_0 + a*t
        velocity = horizontal_step.velocity_start.x + acceleration * delta_time
    
    assert(velocity <= movement_params.max_horizontal_speed_default + 0.001)
    
    return Vector2(position, velocity)

# Calculates the time at which the movement would travel through the given position given the
# given vertical_step.
# FIXME: B: Update unit tests to include min_end_time.
static func _calculate_end_time_for_jumping_to_position(movement_params: MovementParams, \
        vertical_step: MovementVertCalcStep, position: Vector2, min_end_time: float, \
        upcoming_constraint: MovementConstraint) -> float:
    var position_instruction_end := vertical_step.position_instruction_end
    var velocity_instruction_end := vertical_step.velocity_instruction_end
    
    var target_height := position.y
    var start_height := vertical_step.position_step_start.y
    
    var duration_of_slow_ascent: float
    var duration_of_fast_fall: float
    
    var is_position_before_instruction_end: bool
    var is_position_before_peak: bool
    
    # We need to know whether the position corresponds to the rising or falling side of the jump
    # parabola, and whether the position correpsonds to before or after the jump button is
    # released.
    match upcoming_constraint.surface.side:
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
            if !upcoming_constraint.is_destination:
                # We are considering an intermediate constraint.
                if upcoming_constraint.should_stay_on_min_side:
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

# Calculates a new step for the vertical part of the fall movement and the corresponding total fall
# duration.
static func calculate_fall_vertical_step(movement_params: MovementParams, \
        origin_constraint: MovementConstraint, destination_constraint: MovementConstraint, \
        velocity_start: Vector2) -> MovementCalcLocalParams:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    
    var position_start := origin_constraint.position
    var position_end := destination_constraint.position
    
    var total_displacement: Vector2 = position_end - position_start
    var min_vertical_displacement := -movement_params.max_upward_jump_distance
    
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
    
    var can_hold_jump_button := false
    
    var total_duration := calculate_time_to_reach_constraint(movement_params, position_start, \
            position_end, velocity_start, can_hold_jump_button)
    if total_duration == INF:
        return null
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var time_peak_height := -velocity_start.y / movement_params.gravity_fast_fall
    time_peak_height = max(time_peak_height, 0.0)
    
    var step := MovementVertCalcStep.new()
    step.time_step_start = 0.0
    step.time_instruction_start = 0.0
    step.time_step_end = total_duration
    step.time_instruction_end = 0.0
    step.time_peak_height = time_peak_height
    step.position_step_start = position_start
    step.position_instruction_start = position_start
    step.velocity_start = velocity_start
    step.horizontal_movement_sign = horizontal_movement_sign
    step.can_hold_jump_button = can_hold_jump_button
    
    var step_end_state := \
            calculate_vertical_end_state_for_time(movement_params, step, step.time_step_end)
    var peak_height_end_state := \
            calculate_vertical_end_state_for_time(movement_params, step, step.time_peak_height)
    
    step.position_instruction_end = position_start
    step.position_step_end = Vector2(INF, step_end_state.x)
    step.position_peak_height = Vector2(INF, peak_height_end_state.x)
    step.velocity_instruction_end = velocity_start
    step.velocity_step_end = Vector2(INF, step_end_state.y)
    
    assert(Geometry.are_floats_equal_with_epsilon( \
            step.position_step_end.y, position_end.y, 0.001))
    
    return MovementCalcLocalParams.new(origin_constraint, destination_constraint, null, step)

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
        input_key = "move_left" if step.horizontal_movement_sign < 0 else "move_right"
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
        horizontal_movement_sign: int, movement_params: MovementParams) -> Vector2:
    var is_ascending_from_jump := velocity.y < 0 and is_pressing_jump
    
    # Make gravity stronger when falling. This creates a more satisfying jump.
    # Similarly, make gravity stronger for double jumps.
    var gravity_multiplier := 1.0 if !is_ascending_from_jump else \
            (movement_params.slow_ascent_gravity_multiplier if is_first_jump \
                    else movement_params.ascent_double_jump_gravity_multiplier)
    
    # Vertical movement.
    velocity.y += delta * movement_params.gravity_fast_fall * gravity_multiplier
    
    # Horizontal movement.
    velocity.x += delta * movement_params.in_air_horizontal_acceleration * horizontal_movement_sign
    
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
static func calculate_time_to_reach_constraint(movement_params: MovementParams, \
        position_start: Vector2, position_end: Vector2, velocity_start: Vector2, \
        can_hold_jump_button: bool) -> float:
    if can_hold_jump_button:
        # If we can currently hold the jump button, then there is slow-ascent and
        # variable-jump-height to consider.
        
        var displacement: Vector2 = position_end - position_start
        
        var horizontal_movement_sign: int
        if displacement.x < 0:
            horizontal_movement_sign = -1
        elif displacement.x > 0:
            horizontal_movement_sign = 1
        else:
            horizontal_movement_sign = 0
        
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

static func create_origin_constraint(surface: Surface, position: Vector2, \
        velocity_start: Vector2, passing_vertically: bool) -> MovementConstraint:
    var constraint := MovementConstraint.new(surface, position, passing_vertically, false)
    constraint.is_origin = true
    constraint.time_passing_through = 0.0
    constraint.min_x_velocity = velocity_start.x
    constraint.max_x_velocity = velocity_start.x
    return constraint

static func create_destination_constraint(surface: Surface, position: Vector2, \
        passing_vertically: bool) -> MovementConstraint:
    var constraint := MovementConstraint.new(surface, position, passing_vertically, false)
    constraint.is_destination = true
    return constraint
