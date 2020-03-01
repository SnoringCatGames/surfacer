extends EdgeMovementCalculator
class_name FallFromFloorCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "FallFromFloorCalculator"

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            surface.side == SurfaceSide.FLOOR and \
            (surface.concave_counter_clockwise_neighbor == null or \
            surface.concave_clockwise_neighbor == null)

func get_all_edges_from_surface(collision_params: CollisionCalcParams, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    if origin_surface.concave_counter_clockwise_neighbor == null:
        # Calculating the fall-off state for the left edge of the floor.
        _get_all_edges_from_one_side( \
                collision_params, edges_result, surfaces_in_fall_range_set, origin_surface, true)
    
    if origin_surface.concave_clockwise_neighbor == null:
        # Calculating the fall-off state for the right edge of the floor.
        _get_all_edges_from_one_side( \
                collision_params, edges_result, surfaces_in_fall_range_set, origin_surface, false)

static func _get_all_edges_from_one_side(collision_params: CollisionCalcParams, \
        edges_result: Array, surfaces_in_fall_range_set: Dictionary, origin_surface: Surface, \
        falls_on_left_side: bool) -> void:
    var debug_state := collision_params.debug_state
    var movement_params := collision_params.movement_params
    var velocity_x_start := 0.0
    var edge_point := \
            origin_surface.first_point if falls_on_left_side else origin_surface.last_point
    
    var position_start := PositionAlongSurface.new()
    position_start.match_surface_target_and_collider(origin_surface, edge_point, \
            movement_params.collider_half_width_height, true, false)
    
    var position_fall_off := _calculate_player_center_at_fall_off_point(edge_point, \
            falls_on_left_side, movement_params.collider_shape, movement_params.collider_rotation)
    
    var displacement_from_start_to_fall_off := position_fall_off - position_start.target_point
    
    var acceleration := movement_params.walk_acceleration if \
            displacement_from_start_to_fall_off.x > 0 else \
            -movement_params.walk_acceleration
    var velocity_x_at_max_speed := movement_params.max_horizontal_speed_default if \
            displacement_from_start_to_fall_off.x > 0 else \
            -movement_params.max_horizontal_speed_default
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # Algebra...
    #     t = (v - v_0) / a
    var time_to_reach_max_horizontal_speed := \
            (velocity_x_at_max_speed - velocity_x_start) / acceleration
    
    # From a basic equation of motion:
    #     s = s_0 + v_0*t + 1/2*a*t^2
    # Algebra...
    #     (s - s_0) = v_0*t + 1/2*a*t^2
    var displacement_x_to_reach_max_horizontal_speed := \
            velocity_x_start * time_to_reach_max_horizontal_speed + \
            0.5 * acceleration * time_to_reach_max_horizontal_speed * \
            time_to_reach_max_horizontal_speed
    
    var velocity_x_fall_off: float
    var time_fall_off: float
    if abs(displacement_x_to_reach_max_horizontal_speed) > \
            abs(displacement_from_start_to_fall_off.x):
        # We do not hit max speed before we hit the fall-off point.
        
        # From a basic equation of motion:
        #     v^2 = v_0^2 + 2*a*(s - s_0)
        # Algebra...
        #     v = sqrt(v_0^2 + 2*a*(s - s_0))
        velocity_x_fall_off = sqrt(velocity_x_start * velocity_x_start + \
                2 * acceleration * displacement_from_start_to_fall_off.x)
        # From a basic equation of motion:
        #     v = v_0 + a*t
        # Algebra...
        #     t = (v - v_0) / a
        time_fall_off = (velocity_x_fall_off - velocity_x_start) / acceleration
    else:
        # We hit max speed before we hit the fall-off point.
        
        var remaining_displacement_at_max_speed := displacement_from_start_to_fall_off.x - \
                displacement_x_to_reach_max_horizontal_speed
        # From a basic equation of motion:
        #     s = s_0 + v*t
        # Algebra...
        #     t = (s - s_0) / v
        var remaining_time_at_max_speed := \
                remaining_displacement_at_max_speed / velocity_x_at_max_speed
        time_fall_off = time_to_reach_max_horizontal_speed + remaining_time_at_max_speed
        velocity_x_fall_off = velocity_x_at_max_speed
    
    var position_fall_off_wrapper := MovementUtils.create_position_from_target_point( \
            position_fall_off, origin_surface, movement_params.collider_half_width_height)
    var velocity_start := Vector2(velocity_x_fall_off, 0.0)
    
    var landing_trajectories := FallMovementUtils.find_landing_trajectories(collision_params, \
            surfaces_in_fall_range_set, position_fall_off_wrapper, velocity_start)
    
    var position_end: PositionAlongSurface
    var instructions: MovementInstructions
    var edge: FallFromFloorEdge
    
    for calc_results in landing_trajectories:
        position_end = calc_results.overall_calc_params.destination_position
        instructions = _calculate_instructions(position_start, position_end, calc_results, \
                time_fall_off, falls_on_left_side)
        edge = FallFromFloorEdge.new( \
                position_start, position_end, movement_params, instructions, falls_on_left_side)
        edges_result.push_back(edge)

static func _calculate_player_center_at_fall_off_point(edge_point: Vector2, \
        falls_on_left_side: bool, collider_shape: Shape2D, collider_rotation: float) -> Vector2:
    var is_rotated_90_degrees = \
            abs(fmod(collider_rotation + PI * 2, PI) - PI / 2) < Geometry.FLOAT_EPSILON
    # Ensure that collision boundaries are only ever axially aligned.
    assert(is_rotated_90_degrees or abs(collider_rotation) < Geometry.FLOAT_EPSILON)
    
    var right_side_fall_off_displacement_x: float
    var fall_off_displacement_y: float
    
    if collider_shape is CircleShape2D:
        right_side_fall_off_displacement_x = collider_shape.radius
        fall_off_displacement_y = 0.0
        
    elif collider_shape is CapsuleShape2D:
        if is_rotated_90_degrees:
            right_side_fall_off_displacement_x = \
                    collider_shape.radius + collider_shape.height * 0.5
            fall_off_displacement_y = 0.0
        else:
            right_side_fall_off_displacement_x = collider_shape.radius
            fall_off_displacement_y = -collider_shape.height * 0.5
        
    elif collider_shape is RectangleShape2D:
        if is_rotated_90_degrees:
            right_side_fall_off_displacement_x = collider_shape.extents.y
            fall_off_displacement_y = collider_shape.extents.x
        else:
            right_side_fall_off_displacement_x = collider_shape.extents.x
            fall_off_displacement_y = collider_shape.extents.y
        
    else:
        Utils.error("Invalid Shape2D provided for " + \
                "_calculate_player_center_at_fall_off_point: %s. " + \
                "The supported shapes are: CircleShape2D, CapsuleShape2D, RectangleShape2D." % \
                collider_shape)
    
    return edge_point + \
            Vector2(-right_side_fall_off_displacement_x if falls_on_left_side else \
                    right_side_fall_off_displacement_x, \
                    fall_off_displacement_y)

static func _increment_calc_results_start_times(calc_results: MovementCalcResults, \
        time_fall_off: float) -> void:
    calc_results.vertical_step.time_peak_height += time_fall_off
    calc_results.vertical_step.time_step_start += time_fall_off
    calc_results.vertical_step.time_instruction_start += time_fall_off
    calc_results.vertical_step.time_instruction_end += time_fall_off
    calc_results.vertical_step.time_step_end += time_fall_off
    
    calc_results.overall_calc_params.origin_constraint.time_passing_through += time_fall_off
    calc_results.overall_calc_params.destination_constraint.time_passing_through += time_fall_off
    
    for horizontal_step in calc_results.horizontal_steps:
        horizontal_step.time_step_start += time_fall_off
        horizontal_step.time_instruction_start += time_fall_off
        horizontal_step.time_instruction_end += time_fall_off
        horizontal_step.time_step_end += time_fall_off

static func _calculate_instructions(start: PositionAlongSurface, \
        end: PositionAlongSurface, calc_results: MovementCalcResults, time_fall_off: float, \
        falls_on_left_side: bool) -> MovementInstructions:
    # FIXME: REMOVE: Only update actual instructions?
    _increment_calc_results_start_times(calc_results, time_fall_off)
    
    # Calculate the fall-trajectory instructions.
    var instructions := \
            MovementInstructionsUtils.convert_calculation_steps_to_movement_instructions( \
                    calc_results, false, end.surface.side)
    
    # Calculate the walk-off instructions.
    var sideways_input_key := "move_left" if falls_on_left_side else "move_right"
    var outward_press := MovementInstruction.new(sideways_input_key, 0.0, true)
    var outward_release := \
            MovementInstruction.new(sideways_input_key, time_fall_off - 0.0001, false)
    instructions.instructions.push_front(outward_release)
    instructions.instructions.push_front(outward_press)
    
    instructions.duration += time_fall_off
    
    return instructions
