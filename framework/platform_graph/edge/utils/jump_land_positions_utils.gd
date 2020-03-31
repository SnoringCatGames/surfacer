# A collection of utility functions for calculating state related to jump/land positions.
class_name JumpLandPositionsUtils

const EXTRA_JUMP_LAND_POSITION_MARGIN := 2.0
const JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_RATIO := 0.3
const EDGE_MOVEMENT_HORIZONTAL_DISTANCE_SUBTRACT_PLAYER_WIDTH_RATIO := 0.6

# Calculates "good" combinations of jump position, land position, and start velocity for movement
# between the given pair of surfaces.
# 
# - Some interesting jump/land positions for a given surface include the following:
#   - Either end of the surface.
#   - The closest position along the surface to either end of the other surface.
#     - This closest position, but with a slight offset to account for the width of the player.
#     - This closest position, but with an additional offset to account for horizontal movement
#       with minimum jump time and maximum horizontal velocity.
#     - The closest interior position along the surface to the closest interior position along the
#       other surface.
# - Points are only included if they are distinct.
# - We try to minimize the number of jump/land positions returned, since having more of these
#   greatly increases the overall time to parse the platform graph.
# - Results are returned sorted heuristically by what's more likely to produce valid, efficient
#   movement.
#   - Surface-interior points are usually included before surface-end points.
#   - This usually puts shortest distance first.
# - Start velocity is determined from the given EdgeMovementCalculator.
# - Start horizontal velocity from a floor could be either zero or max-speed.
static func calculate_jump_land_positions_for_surface_pair( \
        movement_params: MovementParams, \
        jump_surface: Surface, \
        land_surface: Surface, \
        is_a_jump_calculator: bool) -> Array:
    var jump_surface_left_bound := jump_surface.bounding_box.position.x
    var jump_surface_right_bound := jump_surface.bounding_box.end.x
    var jump_surface_top_bound := jump_surface.bounding_box.position.y
    var jump_surface_bottom_bound := jump_surface.bounding_box.end.y
    var land_surface_left_bound := land_surface.bounding_box.position.x
    var land_surface_right_bound := land_surface.bounding_box.end.x
    var land_surface_top_bound := land_surface.bounding_box.position.y
    var land_surface_bottom_bound := land_surface.bounding_box.end.y
    
    var jump_surface_center := jump_surface.bounding_box.position + \
            (jump_surface.bounding_box.end - jump_surface.bounding_box.position) / 2.0
    var land_surface_center := land_surface.bounding_box.position + \
            (land_surface.bounding_box.end - land_surface.bounding_box.position) / 2.0
    
    var jump_surface_first_point := jump_surface.first_point
    var jump_surface_last_point := jump_surface.last_point
    var land_surface_first_point := land_surface.first_point
    var land_surface_last_point := land_surface.last_point
    
    # Create wrapper PositionAlongSurface ahead of time, so later calculations can all reference
    # the same instances.
    var jump_surface_first_point_wrapper: PositionAlongSurface
    var jump_surface_last_point_wrapper: PositionAlongSurface
    if jump_surface.vertices.size() == 1:
        jump_surface_first_point_wrapper = \
                MovementUtils.create_position_offset_from_target_point( \
                        jump_surface_first_point, \
                        jump_surface, \
                        movement_params.collider_half_width_height)
        jump_surface_last_point_wrapper = jump_surface_first_point_wrapper
    else:
        jump_surface_first_point_wrapper = \
                MovementUtils.create_position_offset_from_target_point( \
                        jump_surface_first_point, \
                        jump_surface, \
                        movement_params.collider_half_width_height)
        jump_surface_last_point_wrapper = \
                MovementUtils.create_position_offset_from_target_point( \
                        jump_surface_last_point, \
                        jump_surface, \
                        movement_params.collider_half_width_height)
    var land_surface_first_point_wrapper: PositionAlongSurface
    var land_surface_last_point_wrapper: PositionAlongSurface
    if land_surface.vertices.size() == 1:
        land_surface_first_point_wrapper = \
                MovementUtils.create_position_offset_from_target_point( \
                        land_surface_first_point, \
                        land_surface, \
                        movement_params.collider_half_width_height)
        land_surface_last_point_wrapper = land_surface_first_point_wrapper
    else:
        land_surface_first_point_wrapper = \
                MovementUtils.create_position_offset_from_target_point( \
                        land_surface_first_point, \
                        land_surface, \
                        movement_params.collider_half_width_height)
        land_surface_last_point_wrapper = \
                MovementUtils.create_position_offset_from_target_point( \
                        land_surface_last_point, \
                        land_surface, \
                        movement_params.collider_half_width_height)
    
    # Use a bounding-box heuristic to determine which ends of the surfaces are likely to be nearer
    # and farther.
    var jump_surface_near_end := Vector2.INF
    var jump_surface_far_end := Vector2.INF
    var jump_surface_near_end_wrapper: PositionAlongSurface
    var jump_surface_far_end_wrapper: PositionAlongSurface
    if Geometry.distance_squared_from_point_to_rect( \
            jump_surface_first_point, \
            land_surface.bounding_box) < \
            Geometry.distance_squared_from_point_to_rect( \
                    jump_surface_last_point, \
                    land_surface.bounding_box):
        jump_surface_near_end = jump_surface_first_point
        jump_surface_far_end = jump_surface_last_point
        jump_surface_near_end_wrapper = jump_surface_first_point_wrapper
        jump_surface_far_end_wrapper = jump_surface_last_point_wrapper
    else:
        jump_surface_near_end = jump_surface_last_point
        jump_surface_far_end = jump_surface_first_point
        jump_surface_near_end_wrapper = jump_surface_last_point_wrapper
        jump_surface_far_end_wrapper = jump_surface_first_point_wrapper
    var land_surface_near_end := Vector2.INF
    var land_surface_far_end := Vector2.INF
    var land_surface_near_end_wrapper: PositionAlongSurface
    var land_surface_far_end_wrapper: PositionAlongSurface
    if Geometry.distance_squared_from_point_to_rect( \
            land_surface_first_point, \
            jump_surface.bounding_box) < \
            Geometry.distance_squared_from_point_to_rect( \
                    land_surface_last_point, \
                    jump_surface.bounding_box):
        land_surface_near_end = land_surface_first_point
        land_surface_far_end = land_surface_last_point
        land_surface_near_end_wrapper = land_surface_first_point_wrapper
        land_surface_far_end_wrapper = land_surface_last_point_wrapper
    else:
        land_surface_near_end = land_surface_last_point
        land_surface_far_end = land_surface_first_point
        land_surface_near_end_wrapper = land_surface_last_point_wrapper
        land_surface_far_end_wrapper = land_surface_first_point_wrapper
    
    var player_width_horizontal_offset := \
            movement_params.collider_half_width_height.x + \
            MovementCalcOverallParams.EDGE_MOVEMENT_ACTUAL_MARGIN + \
            EXTRA_JUMP_LAND_POSITION_MARGIN
    var interior_point_min_distance_from_end := \
            movement_params.collider_half_width_height.x * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_RATIO
    
    var all_jump_land_positions := []
    
    # Calculate intelligent jump/land position combinations for surface-interior points, depending
    # on the jump/land surface types and spatial arrangement.
    match jump_surface.side:
        SurfaceSide.FLOOR:
            match land_surface.side:
                SurfaceSide.FLOOR:
                    # Jump from a floor, land on a floor.
                    
                    var is_jump_surface_lower := \
                            jump_surface_center.y > land_surface_center.y
                    var is_jump_surface_more_to_the_left := \
                            jump_surface_center.x < land_surface_center.x
                    
                    var left_end_displacement_x := \
                            land_surface_left_bound - jump_surface_left_bound
                    var right_end_displacement_x := \
                            land_surface_right_bound - jump_surface_right_bound
                    
                    # We want to first consider the end that will more likely give us better edge
                    # results.
                    var traversal_order_for_considering_left_end := \
                            [true, false] if \
                            is_jump_surface_lower and is_jump_surface_more_to_the_left or \
                            !is_jump_surface_lower and !is_jump_surface_more_to_the_left else \
                            [false, true]
                    
                    for is_considering_left_end in traversal_order_for_considering_left_end:
                        # - We assume start-velocity will be directed either from left-end to
                        #   left-end or from right-end to right-end, without passing across the
                        #   other end of the jump surface.
                        #   - If, for one end, movement would be better directed in the other
                        #     direction, that should eventually be covered by the other end case.
                        # - We consider the player width; otherwise, a jump point directly beneath
                        #   the land point would require some extra horizontal motion in order to
                        #   navigate around the end of the land platform.
                        var does_velocity_start_moving_leftward: bool = ( \
                                is_considering_left_end and \
                                (!is_jump_surface_lower or \
                                left_end_displacement_x > player_width_horizontal_offset)
                            ) or ( \
                                !is_considering_left_end and \
                                is_jump_surface_lower and \
                                right_end_displacement_x <= player_width_horizontal_offset
                            )
                        
                        # These are all the cases for which movement doesn't need to pass at all
                        # underneath either surface. Otherwise, efficient movement needs to hug one
                        # end of the higher surface as the player moves around it, and horizontal
                        # velocity direction is swapped while doing so. Since horizontal velocity
                        # direction would need to swap, we're instead concerned with minimizing
                        # motion rather than considering offsets that stretch it out.
                        var should_consider_surface_interior_positions: bool = ( \
                                is_jump_surface_lower and \
                                is_considering_left_end and \
                                left_end_displacement_x > player_width_horizontal_offset \
                            ) or ( \
                                is_jump_surface_lower and \
                                !is_considering_left_end and \
                                right_end_displacement_x < -player_width_horizontal_offset \
                            ) or ( \
                                !is_jump_surface_lower and \
                                is_considering_left_end and \
                                left_end_displacement_x < -player_width_horizontal_offset \
                            ) or ( \
                                !is_jump_surface_lower and \
                                !is_considering_left_end and \
                                right_end_displacement_x > player_width_horizontal_offset \
                            )
                        
                        if !should_consider_surface_interior_positions:
                            # Only consider the two surface-ends on the designated side (one
                            # jump-land pair).
                            
                            var prefer_velocity_start_zero_horizontal_speed := \
                                    !is_jump_surface_lower
                            var velocity_start := get_velocity_start( \
                                    movement_params, \
                                    jump_surface, \
                                    is_a_jump_calculator, \
                                    does_velocity_start_moving_leftward, \
                                    prefer_velocity_start_zero_horizontal_speed)
                            var jump_position: PositionAlongSurface
                            var land_position: PositionAlongSurface
                            if is_considering_left_end:
                                jump_position = jump_surface_first_point_wrapper
                                land_position = land_surface_first_point_wrapper
                            else:
                                jump_position = jump_surface_last_point_wrapper
                                land_position = land_surface_last_point_wrapper
                            var jump_land_positions := JumpLandPositions.new( \
                                        jump_position, \
                                        land_position, \
                                        velocity_start)
                            all_jump_land_positions.push_back(jump_land_positions)
                            
                        else:
                            # Consider a few different jump-land pairs:
                            # 
                            # - A jump-land pair for the points on each surface that should
                            #   correspond to the least horizontal movement possible.
                            #     J/L: lower-closest-with-width-offset
                            #     L/J: upper-near-end
                            #     V:   zero
                            # - A jump-land pair for the points on each surface that should
                            #   correspond to the most horizontal movement possible, and with as
                            #   much of the horizontal offset as possible applied to the jump/land
                            #   point on the lower surface.
                            #     J/L: lower-closest-with-horizontal-movement-offset
                            #     L/J: upper-near-end
                            #     V:   max
                            # - A jump-land pair for the points on each surface that should
                            #   correspond to the most horizontal movement possible, and with as
                            #   much of the horizontal offset as possible applied to the jump/land
                            #   point on the upper surface.
                            #     J/L: lower-closest (no width offset)
                            #     L/J: upper-near-end-with-horizontal-movement-offset
                            #     V:   max
                            
                            var velocity_start_zero := get_velocity_start( \
                                    movement_params, \
                                    jump_surface, \
                                    is_a_jump_calculator, \
                                    does_velocity_start_moving_leftward, \
                                    true)
                            var velocity_start_max_speed := get_velocity_start( \
                                    movement_params, \
                                    jump_surface, \
                                    is_a_jump_calculator, \
                                    does_velocity_start_moving_leftward, \
                                    false)
                            
                            var displacement_jump_basis_point: Vector2
                            var displacement_land_basis_point: Vector2
                            if is_considering_left_end:
                                if is_jump_surface_lower:
                                    displacement_jump_basis_point = \
                                            Geometry.project_point_onto_surface( \
                                                    Vector2(land_surface_left_bound, \
                                                            INF), \
                                                    jump_surface)
                                    displacement_land_basis_point = \
                                            land_surface_first_point_wrapper.target_point
                                else:
                                    displacement_jump_basis_point = \
                                            jump_surface_first_point_wrapper.target_point
                                    displacement_land_basis_point = \
                                            Geometry.project_point_onto_surface( \
                                                    Vector2(jump_surface_left_bound, \
                                                            INF), \
                                                    land_surface)
                            else:
                                if is_jump_surface_lower:
                                    displacement_jump_basis_point = \
                                            Geometry.project_point_onto_surface( \
                                                    Vector2(land_surface_right_bound, \
                                                            INF), \
                                                    jump_surface)
                                    displacement_land_basis_point = \
                                            land_surface_last_point_wrapper.target_point
                                else:
                                    displacement_jump_basis_point = \
                                            jump_surface_last_point_wrapper.target_point
                                    displacement_land_basis_point = \
                                            Geometry.project_point_onto_surface( \
                                                    Vector2(jump_surface_right_bound, \
                                                            INF), \
                                                    land_surface)
                            
                            var horizontal_movement_offset := \
                                    _calculate_horizontal_movement_offset( \
                                            movement_params, \
                                            displacement_jump_basis_point, \
                                            displacement_land_basis_point, \
                                            velocity_start_max_speed, \
                                            is_a_jump_calculator, \
                                            false)
                            
                            var goal_x: float
                            var jump_position: PositionAlongSurface
                            var land_position: PositionAlongSurface
                            
                            # Record a jump-land pair for the points on each surface that should
                            # correspond to the least horizontal movement possible.
                            # 
                            #   J/L: lower-closest-with-width-offset
                            #   L/J: upper-near-end
                            #   V:   zero
                            if is_jump_surface_lower:
                                if is_considering_left_end:
                                    goal_x = \
                                            land_surface_left_bound - \
                                            player_width_horizontal_offset
                                    jump_position = _create_surface_interior_position( \
                                            goal_x, \
                                            jump_surface, \
                                            movement_params.collider_half_width_height, \
                                            jump_surface_first_point_wrapper, \
                                            jump_surface_last_point_wrapper)
                                    land_position = land_surface_first_point_wrapper
                                else:
                                    goal_x = \
                                            land_surface_right_bound + \
                                            player_width_horizontal_offset
                                    jump_position = _create_surface_interior_position( \
                                            goal_x, \
                                            jump_surface, \
                                            movement_params.collider_half_width_height, \
                                            jump_surface_first_point_wrapper, \
                                            jump_surface_last_point_wrapper)
                                    land_position = land_surface_last_point_wrapper
                            else:
                                if is_considering_left_end:
                                    jump_position = jump_surface_first_point_wrapper
                                    goal_x = \
                                            jump_surface_left_bound - \
                                            player_width_horizontal_offset
                                    land_position = _create_surface_interior_position( \
                                            goal_x, \
                                            land_surface, \
                                            movement_params.collider_half_width_height, \
                                            land_surface_first_point_wrapper, \
                                            land_surface_last_point_wrapper)
                                else:
                                    jump_position = jump_surface_last_point_wrapper
                                    goal_x = \
                                            jump_surface_right_bound + \
                                            player_width_horizontal_offset
                                    land_position = _create_surface_interior_position( \
                                            goal_x, \
                                            land_surface, \
                                            movement_params.collider_half_width_height, \
                                            land_surface_first_point_wrapper, \
                                            land_surface_last_point_wrapper)
                            var min_movement_jump_land_positions := JumpLandPositions.new( \
                                    jump_position, \
                                    land_position, \
                                    velocity_start_zero)
                            all_jump_land_positions.push_back(min_movement_jump_land_positions)
                            
                            if horizontal_movement_offset != INF:
                                # Record a jump-land pair for the points on each surface that
                                # should correspond to the most horizontal movement possible, and
                                # with as much of the horizontal offset as possible applied to the
                                # jump/land point on the lower surface.
                                # 
                                #   J/L: lower-closest-with-horizontal-movement-offset
                                #   L/J: upper-near-end
                                #   V:   max
                                if is_jump_surface_lower:
                                    if is_considering_left_end:
                                        goal_x = \
                                                land_surface_left_bound - \
                                                horizontal_movement_offset
                                        jump_position = _create_surface_interior_position( \
                                                goal_x, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_first_point_wrapper, \
                                                jump_surface_last_point_wrapper)
                                        land_position = land_surface_first_point_wrapper
                                    else:
                                        goal_x = \
                                                land_surface_right_bound + \
                                                horizontal_movement_offset
                                        jump_position = _create_surface_interior_position( \
                                                goal_x, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_first_point_wrapper, \
                                                jump_surface_last_point_wrapper)
                                        land_position = land_surface_last_point_wrapper
                                else:
                                    if is_considering_left_end:
                                        jump_position = jump_surface_first_point_wrapper
                                        goal_x = \
                                                jump_surface_left_bound - \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_first_point_wrapper, \
                                                land_surface_last_point_wrapper)
                                    else:
                                        jump_position = jump_surface_last_point_wrapper
                                        goal_x = \
                                                jump_surface_right_bound + \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_first_point_wrapper, \
                                                land_surface_last_point_wrapper)
                                # Only record this separate jump-land pair if it is distinct.
                                var is_close_to_previous_positions := \
                                        abs(min_movement_jump_land_positions.jump_position.target_point.x - \
                                                jump_position.target_point.x) < \
                                        interior_point_min_distance_from_end and \
                                        abs(min_movement_jump_land_positions.land_position.target_point.x - \
                                                land_position.target_point.x) < \
                                        interior_point_min_distance_from_end
                                var max_movement_with_lower_surface_offset_jump_land_positions: \
                                        JumpLandPositions
                                if !is_close_to_previous_positions:
                                    max_movement_with_lower_surface_offset_jump_land_positions = \
                                            JumpLandPositions.new( \
                                                    jump_position, \
                                                    land_position, \
                                                    velocity_start_max_speed)
                                    all_jump_land_positions.push_back( \
                                            max_movement_with_lower_surface_offset_jump_land_positions)
                                else:
                                    max_movement_with_lower_surface_offset_jump_land_positions = \
                                            min_movement_jump_land_positions
                                
                                # Record a jump-land pair for the points on each surface that
                                # should correspond to the most horizontal movement possible, and
                                # with as much of the horizontal offset as possible applied to the
                                # jump/land point on the upper surface.
                                # 
                                #   J/L: lower-closest (no width offset)
                                #   L/J: upper-near-end-with-horizontal-movement-offset
                                #   V:   max
                                if is_jump_surface_lower:
                                    if is_considering_left_end:
                                        jump_position = _create_surface_interior_position( \
                                                land_surface_left_bound, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_first_point_wrapper, \
                                                jump_surface_last_point_wrapper)
                                        goal_x = \
                                                land_surface_left_bound + \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_first_point_wrapper, \
                                                land_surface_last_point_wrapper)
                                    else:
                                        jump_position = _create_surface_interior_position( \
                                                land_surface_right_bound, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_first_point_wrapper, \
                                                jump_surface_last_point_wrapper)
                                        goal_x = \
                                                land_surface_right_bound - \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_first_point_wrapper, \
                                                land_surface_last_point_wrapper)
                                else:
                                    if is_considering_left_end:
                                        goal_x = \
                                                jump_surface_left_bound + \
                                                horizontal_movement_offset
                                        jump_position = _create_surface_interior_position( \
                                                goal_x, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_first_point_wrapper, \
                                                jump_surface_last_point_wrapper)
                                        land_position = _create_surface_interior_position( \
                                                jump_surface_left_bound, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_first_point_wrapper, \
                                                land_surface_last_point_wrapper)
                                    else:
                                        goal_x = \
                                                jump_surface_right_bound - \
                                                horizontal_movement_offset
                                        jump_position = _create_surface_interior_position( \
                                                goal_x, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_first_point_wrapper, \
                                                jump_surface_last_point_wrapper)
                                        land_position = _create_surface_interior_position( \
                                                jump_surface_right_bound, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_first_point_wrapper, \
                                                land_surface_last_point_wrapper)
                                # Only record this separate jump-land pair if it is distinct.
                                var is_close_to_previous_min_movement_positions := \
                                        abs(min_movement_jump_land_positions.jump_position.target_point.x - \
                                                jump_position.target_point.x) < \
                                        interior_point_min_distance_from_end and \
                                        abs(min_movement_jump_land_positions.land_position.target_point.x - \
                                                land_position.target_point.x) < \
                                        interior_point_min_distance_from_end
                                var is_close_to_previous_max_movement_positions := \
                                        abs(max_movement_with_lower_surface_offset_jump_land_positions.jump_position.target_point.x - \
                                                jump_position.target_point.x) < \
                                        interior_point_min_distance_from_end and \
                                        abs(max_movement_with_lower_surface_offset_jump_land_positions.land_position.target_point.x - \
                                                land_position.target_point.x) < \
                                        interior_point_min_distance_from_end
                                var max_movement_with_upper_surface_offset_jump_land_positions: \
                                        JumpLandPositions
                                if !is_close_to_previous_min_movement_positions and \
                                        !is_close_to_previous_max_movement_positions:
                                    max_movement_with_upper_surface_offset_jump_land_positions = \
                                            JumpLandPositions.new( \
                                                    jump_position, \
                                                    land_position, \
                                                    velocity_start_max_speed)
                                    all_jump_land_positions.push_back( \
                                            max_movement_with_upper_surface_offset_jump_land_positions)
                                else:
                                    max_movement_with_upper_surface_offset_jump_land_positions = \
                                            min_movement_jump_land_positions
                    
                SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                    # Jump from a floor, land on a wall.
                    
                    # FIXME: LEFT OFF HERE: ------------------------------------A
                    # - Start by again looking for patterns in the arrangnement SVG, for clues on
                    #   how to break the use-cases apart.
                    #   - Probably need to create another set of diagrams after noticing whatever pattern...
                    # - 
                    pass
                    
                SurfaceSide.CEILING:
                    # Jump from a floor, land on a ceiling.
                    
                    # FIXME: ------------
                    pass
                    
                _:
                    Utils.error()
            
        SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
            # FIXME: ------------
            pass
            
        SurfaceSide.CEILING:
            # TODO: Handle jump-from-ceiling use-cases.
            pass
            
        _:
            Utils.error()
        
        
    
    
    
    
    
    
#    # Instead of choosing the exact closest point along the jump surface to the land
#    # surface, we may want to give the "closest" jump-off point an offset (corresponding to the
#    # player's width) that should reduce overall movement.
#    # 
#    # As an example of when this offset is important, consider the case when we jump from floor
#    # surface A to floor surface B, which lies exactly above A. In this case, the jump movement
#    # must go around one edge of B or the other in order to land on the top-side of B. Ideally,
#    # the jump position from A would already be outside the edge of B, so that we don't need to
#    # first move horizontally outward and then back in. However, the exact "closest" point on A
#    # to B will not be outside the edge of B.
#    var closest_point_with_width_offset_on_jump_surface := Vector2.INF
#    var mid_point_matching_edge_movement := Vector2.INF
#    match jump_surface.side:
#        SurfaceSide.FLOOR:
#            if surface_center.y < land_surface_center.y:
#                # Jump surface is above land surface.
#
#                # closest_point_with_width_offset_on_jump_surface must be one of the ends of the jump surface.
#                closest_point_with_width_offset_on_jump_surface = jump_surface_last_point if \
#                        surface_center.x < land_surface_center.x else \
#                        jump_surface_first_point
#
#                mid_point_matching_edge_movement = Vector2.INF
#            else:
#                # Jump surface is below land surface.
#
#                var closest_point_with_width_offset_on_land_surface := Vector2.INF
#                var goal_x_on_surface: float = INF
#                var should_try_to_move_around_left_side_of_target: bool
#
#                match land_surface.side:
#                    SurfaceSide.FLOOR:
#                        # Choose whichever land-surface end point is closer to the jump center, and
#                        # calculate a half-player-width offset from there.
#                        should_try_to_move_around_left_side_of_target = \
#                                abs(land_surface_left_bound - surface_center.x) < \
#                                abs(land_surface_right_bound - surface_center.x)
#
#                        # Calculate the "closest" point on the jump surface to our goal offset point.
#                        if should_try_to_move_around_left_side_of_target:
#                            closest_point_with_width_offset_on_land_surface = land_surface_first_point
#                            goal_x_on_surface = closest_point_with_width_offset_on_land_surface.x - \
#                                    player_width_horizontal_offset
#                        else:
#                            closest_point_with_width_offset_on_land_surface = land_surface_last_point
#                            goal_x_on_surface = closest_point_with_width_offset_on_land_surface.x + \
#                                    player_width_horizontal_offset
#                        closest_point_with_width_offset_on_jump_surface = Geometry.project_point_onto_surface( \
#                                Vector2(goal_x_on_surface, INF), \
#                                jump_surface)
#
#                    SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
#                        should_try_to_move_around_left_side_of_target = \
#                                land_surface.side == SurfaceSide.RIGHT_WALL
#                        # Find the point along the land surface that's closest to the jump surface,
#                        # and calculate a half-player-width offset from there.
#                        closest_point_with_width_offset_on_land_surface = \
#                                Geometry.get_closest_point_on_polyline_to_polyline( \
#                                        land_surface.vertices, \
#                                        jump_surface.vertices)
#                        goal_x_on_surface = closest_point_with_width_offset_on_land_surface.x + \
#                                (player_width_horizontal_offset if \
#                                land_surface.side == SurfaceSide.LEFT_WALL else \
#                                -player_width_horizontal_offset)
#                        # Calculate the "closest" point on the jump surface to our goal offset point.
#                        closest_point_with_width_offset_on_jump_surface = Geometry.project_point_onto_surface( \
#                                Vector2(goal_x_on_surface, INF), \
#                                jump_surface)
#
#                    SurfaceSide.CEILING:
#                        # We can use any point along the land surface.
#                        closest_point_with_width_offset_on_jump_surface = \
#                                Geometry.get_closest_point_on_polyline_to_polyline( \
#                                        jump_surface.vertices, \
#                                        land_surface.vertices)
#                        mid_point_matching_edge_movement = Vector2.INF
#
#                    _:
#                        Utils.error()
#
#                if land_surface.side != SurfaceSide.CEILING:
#                    # Calculate the point along the jump surface that would correspond to the
#                    # closest land position on the land surface, while maintaining a max-speed
#                    # horizontal velocity for the duration of the movement.
#                    # 
#                    # This makes a few simplifying assumptions:
#                    # - Assumes only fast-fall gravity for the edge.
#                    # - Assumes the edge starts with the max horizontal speed.
#                    # - Assumes that the center of the surface is at the same height as the
#                    #   resulting point along the surface that we are calculating.
#
#                    var displacement_y := closest_point_with_width_offset_on_land_surface.y - surface_center.y
#                    var fall_time_with_max_gravity := \
#                            MovementUtils.calculate_duration_for_displacement( \
#                                    displacement_y if is_jump_off_surface else -displacement_y, \
#                                    velocity_start_y, \
#                                    movement_params.gravity_fast_fall, \
#                                    movement_params.max_vertical_speed)
#                    # (s - s_0) = v*t
#                    var max_velocity_horizontal_offset := \
#                            movement_params.max_horizontal_speed_default * \
#                            fall_time_with_max_gravity
#                    # This max velocity range could overshoot what's actually reachable, so we
#                    # subtract a portion of the player's width to more likely end up with a usable
#                    # position.
#                    max_velocity_horizontal_offset -= \
#                            player_width_horizontal_offset * \
#                            EDGE_MOVEMENT_HORIZONTAL_DISTANCE_SUBTRACT_PLAYER_WIDTH_RATIO
#                    goal_x_on_surface += -max_velocity_horizontal_offset if \
#                            should_try_to_move_around_left_side_of_target else \
#                            max_velocity_horizontal_offset
#                    mid_point_matching_edge_movement = Geometry.project_point_onto_surface( \
#                            Vector2(goal_x_on_surface, INF), \
#                            jump_surface)
#
#        SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
#            var gravity_for_inter_edge_distance_calc: float = INF
#
#            match land_surface.side:
#                SurfaceSide.FLOOR:
#                    if jump_surface.side == SurfaceSide.LEFT_WALL and \
#                            land_surface.bounding_box.end.x <= surface_center.x:
#                        # The land surface is behind the jump surface, so we assume we'll
#                        # need to go around the top side of this jump surface wall.
#                        closest_point_with_width_offset_on_jump_surface = jump_surface_first_point
#                        mid_point_matching_edge_movement = Vector2.INF
#                        gravity_for_inter_edge_distance_calc = INF
#
#                    elif jump_surface.side == SurfaceSide.RIGHT_WALL and \
#                            land_surface.bounding_box.position.x >= surface_center.x:
#                        # The land surface is behind the jump surface, so we assume we'll
#                        # need to go around the top side of this jump surface wall.
#                        closest_point_with_width_offset_on_jump_surface = jump_surface_last_point
#                        mid_point_matching_edge_movement = Vector2.INF
#                        gravity_for_inter_edge_distance_calc = INF
#
#                    else:
#                        # The land surface, at least partially, is in front of the jump
#                        # surface wall.
#
#                        closest_point_with_width_offset_on_jump_surface = \
#                                Geometry.get_closest_point_on_polyline_to_polyline( \
#                                        jump_surface.vertices, \
#                                        land_surface.vertices)
#                        gravity_for_inter_edge_distance_calc = \
#                                movement_params.gravity_fast_fall
#
#                SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
#                    if (jump_surface.side == SurfaceSide.LEFT_WALL and \
#                            land_surface.side == SurfaceSide.RIGHT_WALL and \
#                            surface_center.x < land_surface_center.x) or \
#                            (jump_surface.side == SurfaceSide.RIGHT_WALL and \
#                                land_surface.side == SurfaceSide.LEFT_WALL and \
#                                surface_center.x > land_surface_center.x):
#                        # The surfaces are facing each other.
#                        closest_point_with_width_offset_on_jump_surface = \
#                                Geometry.get_closest_point_on_polyline_to_polyline( \
#                                        jump_surface.vertices, \
#                                        land_surface.vertices)
#                    else:
#                        # The surfaces aren't facing each other, so we assume we'll need to
#                        # go around the top of at least one of them.
#
#                        var surface_top: float
#                        if jump_surface.side != land_surface.side:
#                            # We need to go around the tops of both surfaces.
#                            surface_top = min(jump_surface.bounding_box.position.y, \
#                                    land_surface.bounding_box.position.y)
#
#                        elif (jump_surface.side == SurfaceSide.LEFT_WALL and \
#                                surface_center.x < land_surface_center.x) or \
#                                (jump_surface.side == SurfaceSide.RIGHT_WALL and \
#                                surface_center.x > land_surface_center.x):
#                            # We need to go around the top of the land surface.
#                            surface_top = land_surface.bounding_box.position.y
#
#                        else:
#                            # We need to go around the top of the jump surface.
#                            surface_top = jump_surface.bounding_box.position.y
#
#                        closest_point_with_width_offset_on_jump_surface = Geometry.project_point_onto_surface( \
#                                Vector2(INF, surface_top), \
#                                jump_surface)
#
#                    gravity_for_inter_edge_distance_calc = movement_params.gravity_fast_fall
#
#                SurfaceSide.CEILING:
#                    if jump_surface.side == SurfaceSide.LEFT_WALL and \
#                            land_surface.bounding_box.end.x <= surface_center.x:
#                        # The land surface is behind the jump surface, so we assume we'll
#                        # need to go around the top side of this jump surface wall.
#                        closest_point_with_width_offset_on_jump_surface = jump_surface_first_point
#                        mid_point_matching_edge_movement = Vector2.INF
#                        gravity_for_inter_edge_distance_calc = INF
#
#                    elif jump_surface.side == SurfaceSide.RIGHT_WALL and \
#                            land_surface.bounding_box.end.x >= surface_center.x:
#                        # The land surface is behind the jump surface, so we assume we'll
#                        # need to go around the top side of this jump surface wall.
#                        closest_point_with_width_offset_on_jump_surface = jump_surface_last_point
#                        mid_point_matching_edge_movement = Vector2.INF
#                        gravity_for_inter_edge_distance_calc = INF
#
#                    else:
#                        # The land surface, at least partially, is in front of the jump
#                        # surface wall.
#
#                        closest_point_with_width_offset_on_jump_surface = \
#                                Geometry.get_closest_point_on_polyline_to_polyline( \
#                                        jump_surface.vertices, \
#                                        land_surface.vertices)
#                        gravity_for_inter_edge_distance_calc = movement_params.gravity_slow_rise
#
#                _:
#                    Utils.error()
#
#            if gravity_for_inter_edge_distance_calc != INF:
#                # Calculate the point along the jump surface that would correspond to
#                # falling/jumping to the closest land position on the land surface.
#                # 
#                # This makes a few simplifying assumptions:
#                # - Assumes only fast-fall gravity for the edge.
#                # - Assumes the edge starts with zero horizontal speed.
#                # - Assumes that the center of the jump surface is at about the same
#                #   x-coordinate as the rest of the surface.
#
#                var closest_point_with_width_offset_on_land_surface: Vector2 = \
#                        Geometry.get_closest_point_on_polyline_to_polyline( \
#                                land_surface.vertices, \
#                                jump_surface.vertices)
#                var horizontal_movement_offset := \
#                        closest_point_with_width_offset_on_land_surface.x - surface_center.x
#                var acceleration := \
#                        movement_params.in_air_horizontal_acceleration if \
#                        horizontal_movement_offset >= 0.0 else \
#                        -movement_params.in_air_horizontal_acceleration
#                var time_to_travel_horizontal_movement_offset := \
#                        MovementUtils.calculate_duration_for_displacement( \
#                                horizontal_movement_offset, \
#                                0.0, \
#                                acceleration, \
#                                movement_params.max_horizontal_speed_default)
#                # From a basic equation of motion:
#                #     s = s_0 + v_0*t + 1/2*a*t^2
#                # Algebra...:
#                #     (s - s_0) = v_0*t + 1/2*a*t^2
#                var vertical_distance := \
#                        velocity_start_y * time_to_travel_horizontal_movement_offset + \
#                        0.5 * gravity_for_inter_edge_distance_calc * \
#                        time_to_travel_horizontal_movement_offset * \
#                        time_to_travel_horizontal_movement_offset
#
#                mid_point_matching_edge_movement = \
#                        Geometry.project_point_onto_surface( \
#                                Vector2(INF, closest_point_with_width_offset_on_land_surface.y - \
#                                        vertical_distance), \
#                                jump_surface)
#
#        SurfaceSide.CEILING:
#            # TODO: Implement this case.
#            closest_point_with_width_offset_on_jump_surface = \
#                    Geometry.get_closest_point_on_polyline_to_polyline( \
#                            jump_surface.vertices, \
#                            land_surface.vertices)
#
#        _:
#            Utils.error()
#
#    # Only consider the horizontal-movement point if it is distinct.
#    if movement_params.considers_mid_point_matching_edge_movement_for_jump_land_position and \
#            mid_point_matching_edge_movement != Vector2.INF and \
#            mid_point_matching_edge_movement != jump_surface_near_end and \
#            mid_point_matching_edge_movement != jump_surface_far_end and \
#            mid_point_matching_edge_movement != closest_point_with_width_offset_on_jump_surface:
#        jump_position = MovementUtils.create_position_offset_from_target_point( \
#                mid_point_matching_edge_movement, \
#                jump_surface, \
#                movement_params.collider_half_width_height)
#        possible_jump_positions.push_front(jump_position)
#
#    # Only consider the "closest" point if it is distinct.
#    if movement_params.considers_closest_mid_point_for_jump_land_position and \
#            closest_point_with_width_offset_on_jump_surface != Vector2.INF and \
#            closest_point_with_width_offset_on_jump_surface != jump_surface_near_end and \
#            closest_point_with_width_offset_on_jump_surface != jump_surface_far_end:
#        jump_position = MovementUtils.create_position_offset_from_target_point( \
#                closest_point_with_width_offset_on_jump_surface, \
#                jump_surface, \
#                movement_params.collider_half_width_height)
#        possible_jump_positions.push_front(jump_position)
    
    
    
    
    if movement_params.always_includes_jump_land_end_point_combinations:
        # Record jump/land position combinations for the surface-end points.
        
        # Collect the surface-end points to use.
        var jump_surface_end_positions := []
        jump_surface_end_positions.push_back(jump_surface_near_end_wrapper)
        if jump_surface_far_end_wrapper != jump_surface_near_end_wrapper:
            jump_surface_end_positions.push_back(jump_surface_far_end_wrapper)
        var land_surface_end_positions := []
        land_surface_end_positions.push_back(land_surface_near_end_wrapper)
        if land_surface_far_end_wrapper != land_surface_near_end_wrapper:
            land_surface_end_positions.push_back(land_surface_far_end_wrapper)
        
        # Instantiate the jump/land pairs.
        for jump_surface_end_position in jump_surface_end_positions:
            for land_surface_end_position in land_surface_end_positions:
                var does_velocity_start_moving_leftward: bool = \
                        land_surface_end_position.target_point.x - \
                        jump_surface_end_position.target_point.x < 0.0
                var prefer_zero_horizontal_speed := true
                var velocity_start_zero := get_velocity_start( \
                        movement_params, \
                        jump_surface, \
                        is_a_jump_calculator, \
                        does_velocity_start_moving_leftward, \
                        prefer_zero_horizontal_speed)
                var jump_land_positions := JumpLandPositions.new( \
                        jump_surface_end_position, \
                        land_surface_end_position, \
                        velocity_start_zero)
                all_jump_land_positions.push_back(jump_land_positions)    
    
    return all_jump_land_positions

static func calculate_jump_positions_on_surface( \
        movement_params: MovementParams, \
        jump_surface: Surface, \
        land_position: PositionAlongSurface, \
        is_a_jump_calculator: bool) -> Array:
    # TODO: Implement this.
    Utils.error("JumpLandPositionsUtils.calculate_jump_positions_for_surface not yet implemented")
    return []

static func calculate_land_positions_on_surface( \
        movement_params: MovementParams, \
        land_surface: Surface, \
        origin_position: PositionAlongSurface, \
        velocity_start: Vector2) -> Array:
    var land_surface_first_point_wrapper: PositionAlongSurface = \
            MovementUtils.create_position_offset_from_target_point( \
                    land_surface.first_point, \
                    land_surface, \
                    movement_params.collider_half_width_height)
    
    if land_surface.vertices.size() > 1:
        var land_surface_last_point_wrapper: PositionAlongSurface = \
                MovementUtils.create_position_offset_from_target_point( \
                        land_surface.last_point, \
                        land_surface, \
                        movement_params.collider_half_width_height)
        
        # Determine which end is closer and which is farther.
        var land_surface_near_end_wrapper: PositionAlongSurface
        var land_surface_far_end_wrapper: PositionAlongSurface
        if land_surface.first_point.distance_squared_to(origin_position.target_point) < \
                land_surface.last_point.distance_squared_to(origin_position.target_point):
            land_surface_near_end_wrapper = land_surface_first_point_wrapper
            land_surface_far_end_wrapper = land_surface_last_point_wrapper
        else:
            land_surface_near_end_wrapper = land_surface_last_point_wrapper
            land_surface_far_end_wrapper = land_surface_first_point_wrapper
        
        var all_jump_land_positions := []
        var jump_land_positions: JumpLandPositions
        
        # FIXME: Consider the distance that would be travelled (either vertically or horizontally,
        #        depending on land_surface.side), and offset the closest point by that.
        
        # Include the closest point iff it is far enough from either end.
        var land_surface_closest_point: Vector2 = \
                Geometry.get_closest_point_on_polyline_to_point( \
                        origin_position.target_point, \
                        land_surface.vertices)
        var interior_point_min_distance_from_end := \
                movement_params.collider_half_width_height.x * \
                JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_RATIO
        var interior_point_min_distance_squared_from_end := \
                interior_point_min_distance_from_end * interior_point_min_distance_from_end
        if land_surface_closest_point.distance_squared_to(land_surface.first_point) < \
                interior_point_min_distance_squared_from_end and \
                land_surface_closest_point.distance_squared_to(land_surface.last_point) < \
                interior_point_min_distance_squared_from_end:
            var land_surface_closest_point_wrapper := \
                    MovementUtils.create_position_offset_from_target_point( \
                            land_surface_closest_point, \
                            land_surface, \
                            movement_params.collider_half_width_height)
            jump_land_positions = JumpLandPositions.new( \
                    origin_position, \
                    land_surface_closest_point_wrapper, \
                    velocity_start)
            all_jump_land_positions.push_back(jump_land_positions)
        
        # Include the near end.
        jump_land_positions = JumpLandPositions.new( \
                origin_position, \
                land_surface_near_end_wrapper, \
                velocity_start)
        all_jump_land_positions.push_back(jump_land_positions)
        
        # Include the far end.
        jump_land_positions = JumpLandPositions.new( \
                origin_position, \
                land_surface_far_end_wrapper, \
                velocity_start)
        all_jump_land_positions.push_back(jump_land_positions)
        
        return all_jump_land_positions
        
    else:
        # The land surface consists of only a single point.
        var jump_land_positions := JumpLandPositions.new( \
                origin_position, \
                land_surface_first_point_wrapper, \
                velocity_start)
        return [jump_land_positions]

static func get_velocity_start( \
        movement_params: MovementParams, \
        origin_surface: Surface, \
        is_jumping: bool, \
        is_moving_leftward := false, \
        prefer_zero_horizontal_speed := false) -> Vector2:
    var velocity_start_x := get_horizontal_velocity_start( \
            movement_params, \
            origin_surface, \
            is_moving_leftward, \
            prefer_zero_horizontal_speed)
    
    var velocity_start_y: float
    if !is_jumping:
        velocity_start_y = 0.0
    else:
        match origin_surface.side:
            SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                velocity_start_y = movement_params.jump_boost
                
            SurfaceSide.FLOOR:
                velocity_start_y = movement_params.jump_boost
                
            SurfaceSide.CEILING:
                velocity_start_y = 0.0
                
            _:
                Utils.error()
                return Vector2.INF
    
    return Vector2(velocity_start_x, velocity_start_y)

static func get_horizontal_velocity_start( \
        movement_params: MovementParams, \
        origin_surface: Surface, \
        is_moving_leftward := false, \
        prefer_zero_horizontal_speed := false) -> float:
    match origin_surface.side:
        SurfaceSide.LEFT_WALL:
            return movement_params.wall_jump_horizontal_boost
            
        SurfaceSide.RIGHT_WALL:
            return -movement_params.wall_jump_horizontal_boost
            
        SurfaceSide.FLOOR, SurfaceSide.CEILING:
            if prefer_zero_horizontal_speed:
                return 0.0
            
            # This uses a simplifying assumption, since we can't know whether there is actually 
            # enough ramp-up distance without knowing the exact position within the bounds of the
            # surface.
            var can_reach_half_max_speed := origin_surface.bounding_box.size.x > \
                    movement_params.distance_to_half_max_horizontal_speed
            
            if can_reach_half_max_speed:
                if is_moving_leftward:
                    return -movement_params.max_horizontal_speed_default
                else:
                    return movement_params.max_horizontal_speed_default
            else:
                return 0.0
            
        _:
            Utils.error()
            return INF

# This returns a PositionAlongSurface instance for the given x/y coordinate along the given
# surface. If the coordinate isn't actually within the bounds of the surface, then a pre-existing
# PositionAlongSurface instance will be returned, rather than creating a redundant new instance.
static func _create_surface_interior_position( \
        goal_coordinate: float, \
        surface: Surface, \
        collider_half_width_height: Vector2, \
        lower_end_position: PositionAlongSurface, \
        upper_end_position: PositionAlongSurface) -> PositionAlongSurface:
    var is_considering_x_axis := surface.normal.x == 0.0
    var interior_point_min_distance_from_end := \
            collider_half_width_height.x * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_RATIO
    
    var lower_bound: float
    var upper_bound: float
    if is_considering_x_axis:
        lower_bound = surface.bounding_box.position.x
        upper_bound = surface.bounding_box.end.x
    else:
        lower_bound = surface.bounding_box.position.y
        upper_bound = surface.bounding_box.end.y
    
    var is_goal_close_to_lower_end := \
            goal_coordinate <= lower_bound + interior_point_min_distance_from_end
    var is_goal_close_to_upper_end := \
            goal_coordinate >= upper_bound - interior_point_min_distance_from_end
    
    if is_goal_close_to_lower_end:
        return lower_end_position
    elif is_goal_close_to_upper_end:
        return upper_end_position
    else:
        # The goal coordinate isn't too close to either end, so we can create a new
        # surface-interior position for it.
        var target_point := \
                Vector2(goal_coordinate, INF) if \
                is_considering_x_axis else \
                Vector2(INF, goal_coordinate)
        return MovementUtils.create_position_offset_from_target_point( \
                target_point, \
                surface, \
                collider_half_width_height, \
                true)

# Calculate a representative horizontal distance between jump and land positions.
# 
# For simplicity, this assumes that the closest point of the surface is at the same height as the
# resulting point along the surface that we are calculating.
static func _calculate_horizontal_movement_offset( \
        movement_params: MovementParams, \
        displacement_jump_basis_point: Vector2, \
        displacement_land_basis_point: Vector2, \
        velocity_start: Vector2, \
        is_a_jump_calculator: bool, \
        must_reach_destination_on_descent: bool) -> float:
    var displacement: Vector2 = \
            displacement_land_basis_point - displacement_jump_basis_point
    
    var duration: float = \
            VerticalMovementUtils.calculate_time_to_jump_to_constraint( \
                    movement_params, \
                    displacement, \
                    velocity_start, \
                    is_a_jump_calculator, \
                    true)
    if duration == INF:
        # We cannot reach the land position from the start position.
        return INF
    
    var horizontal_movement_offset: float = \
            MovementUtils.calculate_displacement_for_duration( \
                    duration, \
                    abs(velocity_start.x), \
                    movement_params.in_air_horizontal_acceleration, \
                    movement_params.max_horizontal_speed_default)
    
    var player_width_horizontal_offset := \
            movement_params.collider_half_width_height.x + \
            MovementCalcOverallParams.EDGE_MOVEMENT_ACTUAL_MARGIN + \
            EXTRA_JUMP_LAND_POSITION_MARGIN
    
    # This max movement range could slightly overshoot what's actually
    # reachable, so we subtract a portion of the player's width to more
    # likely end up with a usable position (but we leave a minimum of at
    # least half the player's width).
    var horizontal_movement_offset_partial_decrease := \
            player_width_horizontal_offset * \
            EDGE_MOVEMENT_HORIZONTAL_DISTANCE_SUBTRACT_PLAYER_WIDTH_RATIO
    if horizontal_movement_offset > player_width_horizontal_offset + \
            horizontal_movement_offset_partial_decrease:
        horizontal_movement_offset -= \
                horizontal_movement_offset_partial_decrease
    elif horizontal_movement_offset > player_width_horizontal_offset:
        horizontal_movement_offset = player_width_horizontal_offset
    
    return horizontal_movement_offset
