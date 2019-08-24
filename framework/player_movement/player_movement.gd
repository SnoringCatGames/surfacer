# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name PlayerMovement

const PlayerInstruction := preload("res://framework/player_movement/player_instruction.gd")

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
