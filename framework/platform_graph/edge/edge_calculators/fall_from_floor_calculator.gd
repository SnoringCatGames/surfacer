extends EdgeMovementCalculator
class_name FallFromFloorCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "FallFromFloorCalculator"

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            surface.side == SurfaceSide.FLOOR and \
            (surface.convex_counter_clockwise_neighbor == null or \
            surface.convex_clockwise_neighbor == null)

func get_all_edges_from_surface(collision_params: CollisionCalcParams, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    pass
#    # FIXME: LEFT OFF HERE: -------------------------------------------A
#
#    var debug_state := collision_params.debug_state
#    var movement_params := collision_params.movement_params
#    var velocity_x_start := 0.0
#
#
#
#
#
#    if origin_surface.concave_counter_clockwise_neighbor == null:
#        # Calculating the fall-off state for the left edge of the floor.
#
#        var position_start := PositionAlongSurface.new()
#        position_start.match_surface_target_and_collider(origin_surface, \
#                origin_surface.first_point, movement_params.collider_half_width_height)
#
#        var position_fall_off := calculate_player_center_at_fall_off_point( \
#                origin_surface.first_point, true, movement_params.collider_shape, \
#                movement_params.collider_rotation)
#
#        var displacement_from_start_to_fall_off := position_fall_off - position_start.target_point
#
#        var acceleration := movement_params.walk_acceleration if \
#                displacement_from_start_to_fall_off.x > 0 else \
#                -movement_params.walk_acceleration
#        var velocity_x_at_max_speed := movement_params.max_horizontal_speed_default if \
#                displacement_from_start_to_fall_off.x > 0 else \
#                -movement_params.max_horizontal_speed_default
#
#        # From a basic equation of motion:
#        #     v = v_0 + a*t
#        # Algebra...
#        #     t = (v - v_0) / a
#        var time_to_reach_max_horizontal_speed := \
#                (velocity_x_at_max_speed - velocity_x_start) / acceleration
#
#        # From a basic equation of motion:
#        #     s = s_0 + v_0*t + 1/2*a*t^2
#        # Algebra...
#        #     (s - s_0) = v_0*t + 1/2*a*t^2
#        var displacement_x_to_reach_max_horizontal_speed := \
#                velocity_x_start * time_to_reach_max_horizontal_speed + \
#                0.5 * acceleration * time_to_reach_max_horizontal_speed * \
#                time_to_reach_max_horizontal_speed
#
#        var velocity_x_fall_off: float
#        var time_fall_off: float
#        if abs(displacement_x_to_reach_max_horizontal_speed) > \
#                abs(displacement_from_start_to_fall_off.x):
#            # We do not hit max speed before we hit the fall-off point.
#
#            # From a basic equation of motion:
#            #     v^2 = v_0^2 + 2*a*(s - s_0)
#            # Algebra...
#            #     v = sqrt(v_0^2 + 2*a*(s - s_0))
#            velocity_x_fall_off = sqrt(velocity_x_start * velocity_x_start + \
#                    2 * acceleration * displacement_from_start_to_fall_off.x)
#            # From a basic equation of motion:
#            #     v = v_0 + a*t
#            # Algebra...
#            #     t = (v - v_0) / a
#            time_fall_off = (velocity_x_fall_off - velocity_x_start) / acceleration
#        else:
#            # We hit max speed before we hit the fall-off point.
#
#            var remaining_displacement_at_max_speed := displacement_from_start_to_fall_off.x - \
#                    displacement_x_to_reach_max_horizontal_speed
#            # From a basic equation of motion:
#            #     s = s_0 + v*t
#            # Algebra...
#            #     t = (s - s_0) / v
#            var remaining_time_at_max_speed := \
#                    remaining_displacement_at_max_speed / velocity_x_at_max_speed
#            time_fall_off = time_to_reach_max_horizontal_speed + remaining_time_at_max_speed
#            velocity_x_fall_off = velocity_x_at_max_speed
#
#    # FIXME: --------------
#    # - Calculate and loop over all possible landing surfaces and landing positions.
#    # - Call helper function from fall-from-air calculator to get an air-to-air edge.
#    # - Steal the instructions from that air edge, and prepend a walk instruction for the initial displacement.
#    # - Modify all the other instructions start and end times.
#    #   - And debug state?
#    # - Create a new fall-from-floor edge.
#    # - 
#
#
#    ###################################################################################
#    # Allow for debug mode to limit the scope of what's calculated.
#    if EdgeMovementCalculator.should_skip_edge_calculation(debug_state, \
#            jump_position, land_position):
#        continue
#    ###################################################################################
#
#    overall_calc_params = EdgeMovementCalculator.create_movement_calc_overall_params( \
#            collision_params, jump_position.surface, jump_position.target_point, \
#            land_position.surface, land_position.target_point, false, velocity_start, \
#            false, false)
#    if overall_calc_params == null:
#        continue
#
#    ###################################################################################
#    # Record some extra debug state when we're limiting calculations to a single edge.
#    if debug_state.in_debug_mode and debug_state.has("limit_parsing") and \
#            debug_state.limit_parsing.has("edge") != null:
#        overall_calc_params.in_debug_mode = true
#    ###################################################################################
#
#    var vertical_step := \
#            VerticalMovementUtils.calculate_vertical_step(overall_calc_params)
#    if vertical_step == null:
#        continue
#
#    var step_calc_params := MovementCalcStepParams.new( \
#            overall_calc_params.origin_constraint, \
#            overall_calc_params.destination_constraint, vertical_step, \
#            overall_calc_params, null, null)
#
#    var calc_results := MovementStepUtils.calculate_steps_from_constraint( \
#            overall_calc_params, step_calc_params)
#    if calc_results == null:
#        continue
#
#    edge = FallFromWallEdge.new(jump_position, land_position, calc_results)
#
#    # FIXME: ---------- Remove?
#    if Utils.IN_DEV_MODE:
#        MovementInstructionsUtils.test_instructions( \
#                edge.instructions, overall_calc_params, calc_results)
#
#    if edge != null:
#        # Can reach land position from jump position.
#        edges_result.push_back(edge)
#        # For efficiency, only compute one edge per surface pair.
#        break
#
#
#
#
#
#
#
#
#
#
#
#
#    if origin_surface.concave_clockwise_neighbor == null:
#        # Calculating the fall-off state for the right edge of the floor.
#
#        pass

static func calculate_player_center_at_fall_off_point(edge_point: Vector2, \
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
            right_side_fall_off_displacement_x = collider_shape.radius + collider_shape.height
            fall_off_displacement_y = 0.0
        else:
            right_side_fall_off_displacement_x = collider_shape.radius
            fall_off_displacement_y = -collider_shape.height
        
    elif collider_shape is RectangleShape2D:
        if is_rotated_90_degrees:
            right_side_fall_off_displacement_x = collider_shape.extents.y
            fall_off_displacement_y = collider_shape.extents.x
        else:
            right_side_fall_off_displacement_x = collider_shape.extents.x
            fall_off_displacement_y = collider_shape.extents.y
        
    else:
        Utils.error("Invalid Shape2D provided for " + \
                "calculate_player_center_at_fall_off_point: %s. " + \
                "The supported shapes are: CircleShape2D, CapsuleShape2D, RectangleShape2D." % \
                collider_shape)
    
    return edge_point + \
            Vector2(-right_side_fall_off_displacement_x if falls_on_left_side else \
                    right_side_fall_off_displacement_x, \
                    fall_off_displacement_y)
