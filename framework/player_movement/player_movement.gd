# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name PlayerMovement

const MovementConstraint := preload("res://framework/player_movement/movement_constraint.gd")
const PlayerInstruction := preload("res://framework/player_movement/player_instruction.gd")

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

static func _calculate_constraints( \
        colliding_surface: Surface, constraint_offset: Vector2) -> Array:
    var passing_point_a: Vector2
    var constraint_a: MovementConstraint
    var passing_point_b: Vector2
    var constraint_b: MovementConstraint
    
    match colliding_surface.side:
        SurfaceSide.FLOOR:
            # Left end
            passing_point_a = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, true, true)
            # Right end
            passing_point_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, true, false)
        SurfaceSide.CEILING:
            # Left end
            passing_point_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, true, true)
            # Right end
            passing_point_b = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, true, false)
        SurfaceSide.LEFT_WALL:
            # Top end
            passing_point_a = colliding_surface.vertices[0] + \
                    Vector2(constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, false, true)
            # Bottom end
            passing_point_b = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, false, false)
        SurfaceSide.RIGHT_WALL:
            # Top end
            passing_point_a = colliding_surface.vertices[colliding_surface.vertices.size() - 1] + \
                    Vector2(-constraint_offset.x, -constraint_offset.y)
            constraint_a = MovementConstraint.new(colliding_surface, passing_point_a, false, true)
            # Bottom end
            passing_point_b = colliding_surface.vertices[0] + \
                    Vector2(-constraint_offset.x, constraint_offset.y)
            constraint_b = MovementConstraint.new(colliding_surface, passing_point_b, false, false)
    
    return [constraint_a, constraint_b]

# Calculates the vertical component of position and velocity according to the given vertical
# movement state and the given time. These are then returned in a Vector2: x is position and y is
# velocity.
# FIXME: B: Fix unit tests to use the return value instead of output params.
static func calculate_vertical_end_state_for_time(movement_params: MovementParams, \
        vertical_step: MovementCalcStep, time: float) -> Vector2:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    var slow_ascent_end_time := min(time, vertical_step.time_instruction_end)
    
    # Basic equations of motion.
    var slow_ascent_end_position := vertical_step.position_start.y + \
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
    assert(time >= horizontal_step.time_start - Geometry.FLOAT_EPSILON)
    assert(time <= horizontal_step.time_step_end + Geometry.FLOAT_EPSILON)
    
    var position: float
    var velocity: float
    if time > horizontal_step.time_instruction_end:
        var delta_time := time - horizontal_step.time_instruction_end
        velocity = horizontal_step.velocity_instruction_end.x
        # From basic equation of motion:
        #     s = s_0 + v*t
        position = horizontal_step.position_instruction_end.x + velocity * delta_time
    else:
        var delta_time := time - horizontal_step.time_start
        var acceleration := movement_params.in_air_horizontal_acceleration * \
                horizontal_step.horizontal_movement_sign
        # From basic equation of motion:
        #     s = s_0 + v_0*t + 1/2*a*t^2
        position = horizontal_step.position_start.x + \
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
        vertical_step: MovementCalcStep, position: Vector2, min_end_time: float, \
        upcoming_constraint: MovementConstraint, destination_surface: Surface) -> float:
    var position_instruction_end := vertical_step.position_instruction_end
    var velocity_instruction_end := vertical_step.velocity_instruction_end
    
    var target_height := position.y
    var start_height := vertical_step.position_start.y
    
    var duration_of_slow_ascent: float
    var duration_of_fast_fall: float
    
    var surface := \
            upcoming_constraint.surface if upcoming_constraint != null else destination_surface
    
    var is_position_before_instruction_end: bool
    var is_position_before_peak: bool
    
    # We need to know whether the position corresponds to the rising or falling side of the jump
    # parabola, and whether the position correpsonds to before or after the jump button is
    # released.
    match surface.side:
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
            if upcoming_constraint != null:
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
        duration_of_slow_ascent = Geometry.solve_for_movement_duration(start_height, \
                target_height, movement_params.jump_boost, movement_params.gravity_slow_ascent, \
                true, min_end_time, false)
        if duration_of_slow_ascent == INF:
            return INF
        duration_of_fast_fall = 0.0
    else:
        duration_of_slow_ascent = vertical_step.time_instruction_end
        min_end_time = max(min_end_time - duration_of_slow_ascent, 0.0)
        duration_of_fast_fall = Geometry.solve_for_movement_duration( \
                position_instruction_end.y, target_height, velocity_instruction_end.y, \
                movement_params.gravity_fast_fall, is_position_before_peak, min_end_time, false)
        if duration_of_fast_fall == INF:
            return INF
    
    return duration_of_fast_fall + duration_of_slow_ascent

# Calculates the duration to accelerate over in order to reach the destination at the given time,
# given that velocity continues after acceleration stops and a new backward acceleration is
# applied.
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
    # FIXME: A: Check whether any of these asserts should be replaced with `return INF`.
    
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
            Geometry.solve_for_movement_duration(s_0, s, v_0, a, true, 0.0, true)
    
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
        position_start: Vector2, position_end: Vector2, \
        velocity_start: Vector2) -> MovementCalcLocalParams:
    # FIXME: B: Account for max y velocity when calculating any parabolic motion.
    
    var total_displacement: Vector2 = position_end - position_start
    var min_vertical_displacement := movement_params.max_upward_jump_distance
    
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
    
    var total_duration: float = Geometry.solve_for_movement_duration(position_start.y, \
            position_end.y, velocity_start.y, movement_params.gravity_fast_fall, false)
    if total_duration == INF:
        return null
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    var time_peak_height := -velocity_start.y / movement_params.gravity_fast_fall
    time_peak_height = max(time_peak_height, 0.0)
    
    var step := MovementCalcStep.new()
    step.time_start = 0.0
    step.time_instruction_end = 0.0
    step.time_step_end = total_duration
    step.time_peak_height = time_peak_height
    step.position_start = position_start
    step.velocity_start = velocity_start
    step.horizontal_movement_sign = horizontal_movement_sign
    
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
    
    return MovementCalcLocalParams.new(position_start, position_end, null, step, null)

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
        press = PlayerInstruction.new(input_key, step.time_start, true)
        release = PlayerInstruction.new(input_key, \
                step.time_instruction_end + MOVE_SIDEWAYS_DURATION_INCREASE_EPSILON, false)
        instructions[i * 2] = press
        instructions[i * 2 + 1] = release
        
        # Keep track of some info for edge annotation debugging.
        constraint_positions.push_back(step.position_step_end)
    
    # Record the jump instruction.
    if includes_jump:
        input_key = "jump"
        press = PlayerInstruction.new(input_key, vertical_step.time_start, true)
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
