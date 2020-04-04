# A collection of utility functions for calculating state related to jump/land positions.
class_name JumpLandPositionsUtils

const EXTRA_JUMP_LAND_POSITION_MARGIN := 2.0
const JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_HEIGHT_RATIO := 0.3
const EDGE_MOVEMENT_HORIZONTAL_DISTANCE_SUBTRACT_PLAYER_WIDTH_RATIO := 0.6
const VERTICAL_OFFSET_TO_SUPPORT_EXTRA_MOVEMENT_AROUND_WALL_PLAYER_HEIGHT_RATIO := 0.5

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
    
    var is_jump_surface_lower := \
            jump_surface_center.y > land_surface_center.y
    var is_jump_surface_more_to_the_left := \
            jump_surface_center.x < land_surface_center.x
    
    var jump_surface_has_only_one_point := jump_surface.vertices.size() == 1
    var land_surface_has_only_one_point := land_surface.vertices.size() == 1
    
    var jump_surface_first_point := jump_surface.first_point
    var jump_surface_last_point := jump_surface.last_point
    var land_surface_first_point := land_surface.first_point
    var land_surface_last_point := land_surface.last_point
    
    # Create wrapper PositionAlongSurface ahead of time, so later calculations can all reference
    # the same instances.
    var jump_surface_first_point_wrapper: PositionAlongSurface
    var jump_surface_last_point_wrapper: PositionAlongSurface
    if jump_surface_has_only_one_point:
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
    if land_surface_has_only_one_point:
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
    
    # Create some additional variables, so we can conveniently reference end points according to
    # near/far.
    # 
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
    
    # Create some additional variables, so we can conveniently reference end points according to
    # left/right/top/bottom. This is just slightly easier to read and think about, rather than
    # having to remember which direction the first/last points correspond to, depending on the
    # given surface side.
    var jump_surface_left_end := Vector2.INF
    var jump_surface_right_end := Vector2.INF
    var jump_surface_top_end := Vector2.INF
    var jump_surface_bottom_end := Vector2.INF
    var jump_surface_left_end_wrapper: PositionAlongSurface
    var jump_surface_right_end_wrapper: PositionAlongSurface
    var jump_surface_top_end_wrapper: PositionAlongSurface
    var jump_surface_bottom_end_wrapper: PositionAlongSurface
    match jump_surface.side:
        SurfaceSide.FLOOR:
            jump_surface_left_end = jump_surface_first_point
            jump_surface_right_end = jump_surface_last_point
            jump_surface_top_end = Vector2.INF
            jump_surface_bottom_end = Vector2.INF
            jump_surface_left_end_wrapper = jump_surface_first_point_wrapper
            jump_surface_right_end_wrapper = jump_surface_last_point_wrapper
            jump_surface_top_end_wrapper = null
            jump_surface_bottom_end_wrapper = null
        SurfaceSide.LEFT_WALL:
            jump_surface_left_end = Vector2.INF
            jump_surface_right_end = Vector2.INF
            jump_surface_top_end = jump_surface_first_point
            jump_surface_bottom_end = jump_surface_last_point
            jump_surface_left_end_wrapper = null
            jump_surface_right_end_wrapper = null
            jump_surface_top_end_wrapper = jump_surface_first_point_wrapper
            jump_surface_bottom_end_wrapper = jump_surface_last_point_wrapper
        SurfaceSide.RIGHT_WALL:
            jump_surface_left_end = Vector2.INF
            jump_surface_right_end = Vector2.INF
            jump_surface_top_end = jump_surface_last_point
            jump_surface_bottom_end = jump_surface_first_point
            jump_surface_left_end_wrapper = null
            jump_surface_right_end_wrapper = null
            jump_surface_top_end_wrapper = jump_surface_last_point_wrapper
            jump_surface_bottom_end_wrapper = jump_surface_first_point_wrapper
        SurfaceSide.CEILING:
            jump_surface_left_end = jump_surface_last_point
            jump_surface_right_end = jump_surface_first_point
            jump_surface_top_end = Vector2.INF
            jump_surface_bottom_end = Vector2.INF
            jump_surface_left_end_wrapper = jump_surface_last_point_wrapper
            jump_surface_right_end_wrapper = jump_surface_first_point_wrapper
            jump_surface_top_end_wrapper = null
            jump_surface_bottom_end_wrapper = null
        _:
            Utils.error()
    var land_surface_left_end := Vector2.INF
    var land_surface_right_end := Vector2.INF
    var land_surface_top_end := Vector2.INF
    var land_surface_bottom_end := Vector2.INF
    var land_surface_left_end_wrapper: PositionAlongSurface
    var land_surface_right_end_wrapper: PositionAlongSurface
    var land_surface_top_end_wrapper: PositionAlongSurface
    var land_surface_bottom_end_wrapper: PositionAlongSurface
    match land_surface.side:
        SurfaceSide.FLOOR:
            land_surface_left_end = land_surface_first_point
            land_surface_right_end = land_surface_last_point
            land_surface_top_end = Vector2.INF
            land_surface_bottom_end = Vector2.INF
            land_surface_left_end_wrapper = land_surface_first_point_wrapper
            land_surface_right_end_wrapper = land_surface_last_point_wrapper
            land_surface_top_end_wrapper = null
            land_surface_bottom_end_wrapper = null
        SurfaceSide.LEFT_WALL:
            land_surface_left_end = Vector2.INF
            land_surface_right_end = Vector2.INF
            land_surface_top_end = land_surface_first_point
            land_surface_bottom_end = land_surface_last_point
            land_surface_left_end_wrapper = null
            land_surface_right_end_wrapper = null
            land_surface_top_end_wrapper = land_surface_first_point_wrapper
            land_surface_bottom_end_wrapper = land_surface_last_point_wrapper
        SurfaceSide.RIGHT_WALL:
            land_surface_left_end = Vector2.INF
            land_surface_right_end = Vector2.INF
            land_surface_top_end = land_surface_last_point
            land_surface_bottom_end = land_surface_first_point
            land_surface_left_end_wrapper = null
            land_surface_right_end_wrapper = null
            land_surface_top_end_wrapper = land_surface_last_point_wrapper
            land_surface_bottom_end_wrapper = land_surface_first_point_wrapper
        SurfaceSide.CEILING:
            land_surface_left_end = land_surface_last_point
            land_surface_right_end = land_surface_first_point
            land_surface_top_end = Vector2.INF
            land_surface_bottom_end = Vector2.INF
            land_surface_left_end_wrapper = land_surface_last_point_wrapper
            land_surface_right_end_wrapper = land_surface_first_point_wrapper
            land_surface_top_end_wrapper = null
            land_surface_bottom_end_wrapper = null
        _:
            Utils.error()
    
    var player_width_horizontal_offset := \
            movement_params.collider_half_width_height.x + \
            MovementCalcOverallParams.EDGE_MOVEMENT_ACTUAL_MARGIN + \
            EXTRA_JUMP_LAND_POSITION_MARGIN
    var interior_point_min_horizontal_distance_from_end := \
            movement_params.collider_half_width_height.x * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_HEIGHT_RATIO
    var interior_point_min_vertical_distance_from_end := \
            movement_params.collider_half_width_height.y * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_HEIGHT_RATIO
    
    var all_jump_land_positions := []
    
    # Calculate intelligent jump/land position combinations for surface-interior points, depending
    # on the jump/land surface types and spatial arrangement.
    match jump_surface.side:
        SurfaceSide.FLOOR:
            match land_surface.side:
                SurfaceSide.FLOOR:
                    # Jump from a floor, land on a floor.
                    
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
                                jump_position = jump_surface_left_end_wrapper
                                land_position = land_surface_left_end_wrapper
                            else:
                                jump_position = jump_surface_right_end_wrapper
                                land_position = land_surface_right_end_wrapper
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
                                            land_surface_left_end_wrapper.target_point
                                else:
                                    displacement_jump_basis_point = \
                                            jump_surface_left_end_wrapper.target_point
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
                                            land_surface_right_end_wrapper.target_point
                                else:
                                    displacement_jump_basis_point = \
                                            jump_surface_right_end_wrapper.target_point
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
                                            jump_surface_left_end_wrapper, \
                                            jump_surface_right_end_wrapper)
                                    land_position = land_surface_left_end_wrapper
                                else:
                                    goal_x = \
                                            land_surface_right_bound + \
                                            player_width_horizontal_offset
                                    jump_position = _create_surface_interior_position( \
                                            goal_x, \
                                            jump_surface, \
                                            movement_params.collider_half_width_height, \
                                            jump_surface_left_end_wrapper, \
                                            jump_surface_right_end_wrapper)
                                    land_position = land_surface_right_end_wrapper
                            else:
                                if is_considering_left_end:
                                    jump_position = jump_surface_left_end_wrapper
                                    goal_x = \
                                            jump_surface_left_bound - \
                                            player_width_horizontal_offset
                                    land_position = _create_surface_interior_position( \
                                            goal_x, \
                                            land_surface, \
                                            movement_params.collider_half_width_height, \
                                            land_surface_left_end_wrapper, \
                                            land_surface_right_end_wrapper)
                                else:
                                    jump_position = jump_surface_right_end_wrapper
                                    goal_x = \
                                            jump_surface_right_bound + \
                                            player_width_horizontal_offset
                                    land_position = _create_surface_interior_position( \
                                            goal_x, \
                                            land_surface, \
                                            movement_params.collider_half_width_height, \
                                            land_surface_left_end_wrapper, \
                                            land_surface_right_end_wrapper)
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
                                                jump_surface_left_end_wrapper, \
                                                jump_surface_right_end_wrapper)
                                        land_position = land_surface_left_end_wrapper
                                    else:
                                        goal_x = \
                                                land_surface_right_bound + \
                                                horizontal_movement_offset
                                        jump_position = _create_surface_interior_position( \
                                                goal_x, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_left_end_wrapper, \
                                                jump_surface_right_end_wrapper)
                                        land_position = land_surface_right_end_wrapper
                                else:
                                    if is_considering_left_end:
                                        jump_position = jump_surface_left_end_wrapper
                                        goal_x = \
                                                jump_surface_left_bound - \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_left_end_wrapper, \
                                                land_surface_right_end_wrapper)
                                    else:
                                        jump_position = jump_surface_right_end_wrapper
                                        goal_x = \
                                                jump_surface_right_bound + \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_left_end_wrapper, \
                                                land_surface_right_end_wrapper)
                                var max_movement_with_lower_surface_offset_jump_land_positions := \
                                        _record_if_distinct( \
                                                jump_position, \
                                                land_position, \
                                                velocity_start_max_speed, \
                                                interior_point_min_horizontal_distance_from_end, \
                                                all_jump_land_positions, \
                                                false, \
                                                min_movement_jump_land_positions)
                                
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
                                                jump_surface_left_end_wrapper, \
                                                jump_surface_right_end_wrapper)
                                        goal_x = \
                                                land_surface_left_bound + \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_left_end_wrapper, \
                                                land_surface_right_end_wrapper)
                                    else:
                                        jump_position = _create_surface_interior_position( \
                                                land_surface_right_bound, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_left_end_wrapper, \
                                                jump_surface_right_end_wrapper)
                                        goal_x = \
                                                land_surface_right_bound - \
                                                horizontal_movement_offset
                                        land_position = _create_surface_interior_position( \
                                                goal_x, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_left_end_wrapper, \
                                                land_surface_right_end_wrapper)
                                else:
                                    if is_considering_left_end:
                                        goal_x = \
                                                jump_surface_left_bound + \
                                                horizontal_movement_offset
                                        jump_position = _create_surface_interior_position( \
                                                goal_x, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_left_end_wrapper, \
                                                jump_surface_right_end_wrapper)
                                        land_position = _create_surface_interior_position( \
                                                jump_surface_left_bound, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_left_end_wrapper, \
                                                land_surface_right_end_wrapper)
                                    else:
                                        goal_x = \
                                                jump_surface_right_bound - \
                                                horizontal_movement_offset
                                        jump_position = _create_surface_interior_position( \
                                                goal_x, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                jump_surface_left_end_wrapper, \
                                                jump_surface_right_end_wrapper)
                                        land_position = _create_surface_interior_position( \
                                                jump_surface_right_bound, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                land_surface_left_end_wrapper, \
                                                land_surface_right_end_wrapper)
                                # Only record this separate jump-land pair if it is distinct.
                                _record_if_distinct( \
                                        jump_position, \
                                        land_position, \
                                        velocity_start_max_speed, \
                                        interior_point_min_horizontal_distance_from_end, \
                                        all_jump_land_positions, \
                                        false, \
                                        min_movement_jump_land_positions, \
                                        max_movement_with_lower_surface_offset_jump_land_positions)
                    
                SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                    # Jump from a floor, land on a wall.
                    
                    # FIXME: LEFT OFF HERE: ------------------------------------A
                    # 
                    # IMPLEMENT FLOOR TO WALL APPROACH:
                    # 
                    # - Primary edge:
                    #   - if left-wall:
                    #     - if floor-r-bound > wall.x + half-width:
                    #       - land-basis-pt = wall-closest-pt
                    #       - land-offset = vertical-mvt-offset
                    #       - unless wall is below floor and between floor horizontal bounds:
                    #         - v-start-h-direction = left
                    #         - jump-basis-pt = floor-closest-pt
                    #         - jump-offset = rightward-h-mvt-offset
                    #       - else:
                    #         - v-start-h-direction = right
                    #         - jump-basis-pt = floor-r-end
                    #         - jump-offset = 0
                    #         - This is the one case to only do with v-max-speed (no v-zero).
                    #     - else:
                    #       - land-basis-pt = wall-top-end
                    #       - land-offset = 0
                    #       - v-start-h-direction = right
                    #       - jump-basis-pt = floor-closest-pt
                    #       - jump-offset = leftward-h-mvt-offset
                    #   - right wall is the same idea, but with opposite h-directions and floor ends
                    # 
                    # - Leftward horizontal movement offset should always include a bit of
                    #   a decrease, since it has to go around wall end and then backtrack
                    #   slightly to press into the wall.
                    # 
                    # - Handle secondary edges separately with stand-alone logic.
                    # 
                    # - All primary cases should be done twice, with v-zero and v-max-speed.
                    #   - Except with case "wall is below floor and between floor horizontal bounds".
                    #   - When using v-zero, horizontal offset should only be half the width of the player.
                    # 
                    # - When reversing the jump/land surfaces
                    #   (adapt any changes as needed, into a new set of instructions)
                    #   - v-offset happens in same cases, but might involve different calculation to get the right value
                    #   - other than that, I think the cases are essentially the same?
                    # 
                    # - Then implement the other cases:
                    #   - Floor to wall
                    #   - Wall to floor
                    #   - Wall to wall
                    #   - Floor to ceiling
                    # - Then go back to the SVG diagrams and polish, export, incorporote into README:
                    #   - Anything else to clean up diagrams, incorporate any other aspects
                    #     from notes, then incorporate notes into final diagram export.
                    #   - Then also update the floor-to-floor diagram.
                    #   - Then update diagrams and notes for wall to wall cases.
                    #     - These seem easier.
                    #   - Don't do any to/from ceiling cases yet.
                    #     - Except, floor to ceiling is _really_ easy.
                    #       - Just always use absolute closest point along either surface with
                    #         never any offsets.
                    #       - And never allow landing on a ceiling from a floor if the ceiling is lower.
                    # 
                    # Details to remember:
                    # - Use interior_point_min_vertical_distance_from_end
                    # - Use vertical_offset_to_support_extra_movement_around_wall
                    #   - Use this here, and in all other cases, when we need to change
                    #     horizontal velocity for the given surface arrangement (i.e.,
                    #     going around and reversing around the top or bottom of a jump or
                    #     land wall).
                    pass
                    
                SurfaceSide.CEILING:
                    # Jump from a floor, land on a ceiling.
                    
                    if is_jump_surface_lower:
                        var do_surfaces_overlap_horizontally := \
                                jump_surface_left_bound < land_surface_right_bound and \
                                jump_surface_right_bound > land_surface_left_bound
                        
                        if !do_surfaces_overlap_horizontally:
                            # The surfaces don't overlap horizontally.
                            # 
                            # There is then only one pair we consider:
                            # - The closest ends.
                            
                            var jump_position := jump_surface_near_end_wrapper
                            var land_position := land_surface_near_end_wrapper
                            
                            var does_velocity_start_moving_leftward := \
                                    !is_jump_surface_more_to_the_left
                            var velocity_start := get_velocity_start( \
                                    movement_params, \
                                    jump_surface, \
                                    is_a_jump_calculator, \
                                    does_velocity_start_moving_leftward, \
                                    false)
                            
                            var min_movement_jump_land_positions := JumpLandPositions.new( \
                                    jump_position, \
                                    land_position, \
                                    velocity_start)
                            all_jump_land_positions.push_back(min_movement_jump_land_positions)
                            
                        else:
                            # The surfaces overlap horizontally.
                            # 
                            # - There are then three likely position pairs we consider:
                            #   - Positions at the right-most x-coordinate of overlap.
                            #   - Positions at the left-most x-coordinate of overlap.
                            #   - The closest positions between the two surfaces (assuming they're
                            #     distinct from the above two pairs).
                            # - We only consider start velocity with zero horizontal speed.
                            # - Since we only consider start velocity of zero, we don't care about
                            #   whether velocity would need to start moving leftward or rightward.
                            # - We don't need to include any horizontal offsets (to account for
                            #   player width or for edge movement) for any of the jump/land
                            #   positions.
                            # 
                            # TODO: We could also consider the same jump/land basis points, but
                            #       with max-speed start velocity (and then a horizontal offset for
                            #       the positions), but that's probably not useful for most cases.
                            
                            var left_end_displacement_x := \
                                    land_surface_left_bound - jump_surface_left_bound
                            var right_end_displacement_x := \
                                    land_surface_right_bound - jump_surface_right_bound
                            
                            var velocity_start := get_velocity_start( \
                                    movement_params, \
                                    jump_surface, \
                                    is_a_jump_calculator, \
                                    false, \
                                    true)
                            
                            var jump_position: PositionAlongSurface
                            var land_position: PositionAlongSurface
                            
                            # Consider the left ends.
                            if left_end_displacement_x > 0.0:
                                # J: floor-closest-point-to-ceiling-left-end
                                # L: ceiling-left-end
                                # V: zero
                                # O: none
                                jump_position = _create_surface_interior_position( \
                                        land_surface_left_bound, \
                                        jump_surface, \
                                        movement_params.collider_half_width_height, \
                                        jump_surface_left_end_wrapper, \
                                        jump_surface_right_end_wrapper)
                                land_position = land_surface_left_end_wrapper
                            else:
                                # J: floor-left-end
                                # L: ceiling-closest-point-to-floor-left-end
                                # V: zero
                                # O: none
                                jump_position = jump_surface_left_end_wrapper
                                land_position = _create_surface_interior_position( \
                                        jump_surface_left_bound, \
                                        land_surface, \
                                        movement_params.collider_half_width_height, \
                                        land_surface_left_end_wrapper, \
                                        land_surface_right_end_wrapper)
                            var left_end_jump_land_positions := JumpLandPositions.new( \
                                    jump_position, \
                                    land_position, \
                                    velocity_start)
                            all_jump_land_positions.push_back(left_end_jump_land_positions)
                            
                            # FIXME: ---------------------- Move this check to the top, to handle the same for all arrangements?
                            if jump_surface_has_only_one_point or land_surface_has_only_one_point:
                                # If either surface has only a single point, then we only want to
                                # consider the one jump/land pair.
                                pass
                            
                            # Consider the right ends.
                            if right_end_displacement_x > 0.0:
                                # J: floor-right-end
                                # L: ceiling-closest-point-to-floor-right-end
                                # V: zero
                                # O: none
                                jump_position = jump_surface_right_end_wrapper
                                land_position = _create_surface_interior_position( \
                                        jump_surface_right_bound, \
                                        land_surface, \
                                        movement_params.collider_half_width_height, \
                                        land_surface_left_end_wrapper, \
                                        land_surface_right_end_wrapper)
                            else:
                                # J: floor-closest-point-to-ceiling-right-end
                                # L: ceiling-right-end
                                # V: zero
                                # O: none
                                jump_position = _create_surface_interior_position( \
                                        land_surface_right_bound, \
                                        jump_surface, \
                                        movement_params.collider_half_width_height, \
                                        jump_surface_left_end_wrapper, \
                                        jump_surface_right_end_wrapper)
                                land_position = land_surface_right_end_wrapper
                            var right_end_jump_land_positions := JumpLandPositions.new( \
                                    jump_position, \
                                    land_position, \
                                    velocity_start)
                            all_jump_land_positions.push_back(right_end_jump_land_positions)
                            
                            # Consider the closest points.
                            var jump_surface_closest_point: Vector2 = \
                                    Geometry.get_closest_point_on_polyline_to_polyline( \
                                            jump_surface.vertices, \
                                            land_surface.vertices)
                            var land_surface_closest_point: Vector2 = \
                                    Geometry.get_closest_point_on_polyline_to_point( \
                                            jump_surface_closest_point, \
                                            land_surface.vertices)
                            var is_jump_point_distinct := \
                                    jump_surface_closest_point.x > \
                                            jump_surface_left_bound + \
                                            interior_point_min_horizontal_distance_from_end and \
                                    jump_surface_closest_point.x < \
                                            jump_surface_right_bound - \
                                            interior_point_min_horizontal_distance_from_end
                            var is_land_point_distinct := \
                                    land_surface_closest_point.x > \
                                            land_surface_left_bound + \
                                            interior_point_min_horizontal_distance_from_end and \
                                    land_surface_closest_point.x < \
                                            land_surface_right_bound - \
                                            interior_point_min_horizontal_distance_from_end
                            if is_jump_point_distinct and is_land_point_distinct:
                                # The closest points aren't too close to the ends, so we can create
                                # new surface-interior positions for them.
                                jump_position = \
                                        MovementUtils.create_position_offset_from_target_point( \
                                                jump_surface_closest_point, \
                                                jump_surface, \
                                                movement_params.collider_half_width_height, \
                                                true)
                                land_position = \
                                        MovementUtils.create_position_offset_from_target_point( \
                                                land_surface_closest_point, \
                                                land_surface, \
                                                movement_params.collider_half_width_height, \
                                                true)
                                var closest_point_jump_land_positions := JumpLandPositions.new( \
                                        jump_position, \
                                        land_position, \
                                        velocity_start)
                                # This closest-points pair is actually probably the most likely to
                                # produce the best edge, so insert it at the start of the result
                                # collection.
                                all_jump_land_positions.push_front(closest_point_jump_land_positions)
                        
                    else:
                        # Jumping from a higher floor to a lower ceiling.
                        
                        # Return no valid points, since we must move down, past the floor, and
                        # cannot then move back upward after starting the fall.
                        pass
                    
                _:
                    Utils.error("Unknown land surface side (jump from floor)")
            
        SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
            match land_surface.side:
                SurfaceSide.FLOOR:
                    # Jump from a wall, land on a floor.
                    
                    # FIXME: ------------
                    # - ...
                    # 
                    # Details to remember:
                    # - Use interior_point_min_vertical_distance_from_end
                    # - Use vertical_offset_to_support_extra_movement_around_wall
                    #   - Use this here, and in all other cases, when we need to change
                    #     horizontal velocity for the given surface arrangement (i.e.,
                    #     going around and reversing around the top or bottom of a jump or
                    #     land wall).
                    pass
                    
                SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                    # Jump from a wall, land on a wall.
                    
                    var top_end_displacement_y := \
                            land_surface_top_bound - jump_surface_top_bound
                    var bottom_end_displacement_y := \
                            land_surface_bottom_bound - jump_surface_bottom_bound
                    
                    var do_surfaces_overlap_vertically := \
                            jump_surface_top_bound < land_surface_bottom_bound and \
                            jump_surface_bottom_bound > land_surface_top_bound
                    
                    var vertical_offset_to_support_extra_movement_around_wall := \
                            movement_params.collider_half_width_height.y * \
                            VERTICAL_OFFSET_TO_SUPPORT_EXTRA_MOVEMENT_AROUND_WALL_PLAYER_HEIGHT_RATIO
                    
                    var velocity_start := get_velocity_start( \
                            movement_params, \
                            jump_surface, \
                            is_a_jump_calculator)
                    
                    if jump_surface.side == land_surface.side:
                        # Jump between walls of the same side.
                        # 
                        # This means that we must go around one end of one of the walls.
                        # - Which wall depends on which wall is in front.
                        # - Which end depends on which wall is higher.
                        
                        # FIXME: ------------
                        # - Consider top ends:
                        #   - J-basis: jump-surface-top-end
                        #   - L-basis: land-surface-top-end
                        #   - is jump surface in front or
                        #     is jump top-end lower:
                        #     - J-offset: none
                        #   - else:
                        #     - J-offset: v-offset-from-movement
                        #   - is jump surface in front:
                        #     - L-offset: v-offset-from-movement
                        #   - else:
                        #     - L-offset: none
                        # - Consider bottom ends:
                        #   - J-basis: jump-surface-bottom-end
                        #   - L-basis: land-surface-bottom-end
                        #   - is jump surface in front:
                        #     - is jump bottom-end is lower:
                        #       - NO RESULT
                        #     - else:
                        #       - J-offset: none
                        #       - L-offset: v-offset-from-movement
                        #         - If this offset would exceed the bottom-end of
                        #           the land-surface, then abandon attempt
                        #   - else:
                        #     - is jump-bottom-end is higher:
                        #       - NO RESULT
                        #     - else:
                        #       - J-offset: v-offset-from-movemnent
                        #         - If this offset would exceed the bottom-end of
                        #           the jump-surface, then abandon attempt
                        #       - L-offset: none
                        # - Use interior_point_min_vertical_distance_from_end
                        # - Use vertical_offset_to_support_extra_movement_around_wall
                        #   - Use this here, and in all other cases, when we need to change
                        #     horizontal velocity for the given surface arrangement (i.e.,
                        #     going around and reversing around the top or bottom of a jump or
                        #     land wall).
                        pass
                        
                    else:
                        # Jump between walls of opposite sides.
                        
                        var are_walls_facing_each_other := \
                                is_jump_surface_more_to_the_left and \
                                jump_surface.side == SurfaceSide.LEFT_WALL or \
                                !is_jump_surface_more_to_the_left and \
                                jump_surface.side == SurfaceSide.RIGHT_WALL
                        
                        if are_walls_facing_each_other:
                            # Jump between two walls that are facing each other.
                            
                            var displacement_jump_basis_point: Vector2
                            var displacement_land_basis_point: Vector2
                            
                            if top_end_displacement_y > 0.0:
                                # Jump-surface top-end is higher than land-surface top-end.
                                displacement_jump_basis_point = \
                                        Geometry.project_point_onto_surface( \
                                                Vector2(land_surface_top_bound, INF), \
                                                jump_surface)
                                displacement_land_basis_point = \
                                        land_surface_top_end_wrapper.target_point
                            else:
                                # Jump-surface top-end is lower than land-surface top-end.
                                displacement_jump_basis_point = \
                                        jump_surface_top_end_wrapper.target_point
                                displacement_land_basis_point = \
                                        Geometry.project_point_onto_surface( \
                                                Vector2(jump_surface_top_bound, INF), \
                                                land_surface)
                            var top_end_jump_land_positions := \
                                    _calculate_jump_land_points_for_walls_facing_each_other( \
                                            movement_params, \
                                            all_jump_land_positions, \
                                            false, \
                                            displacement_jump_basis_point, \
                                            displacement_land_basis_point, \
                                            velocity_start, \
                                            is_a_jump_calculator, \
                                            jump_surface, \
                                            jump_surface_top_end_wrapper, \
                                            jump_surface_bottom_end_wrapper, \
                                            land_surface, \
                                            land_surface_top_end_wrapper, \
                                            land_surface_bottom_end_wrapper)
                            
                            # FIXME: ---------------------- Move this check to the top, to handle the same for all arrangements?
                            if jump_surface_has_only_one_point or land_surface_has_only_one_point:
                                # If either surface has only a single point, then we only want to
                                # consider the one jump/land pair.
                                pass
                            
                            # Considering bottom-end case.
                            if bottom_end_displacement_y > 0.0:
                                # Jump-surface bottom-end is higher than land-surface bottom-end.
                                displacement_jump_basis_point = \
                                        jump_surface_bottom_end_wrapper.target_point
                                displacement_land_basis_point = \
                                        Geometry.project_point_onto_surface( \
                                                Vector2(jump_surface_bottom_bound, INF), \
                                                land_surface)
                            else:
                                # Jump-surface bottom-end is lower than land-surface bottom-end.
                                displacement_jump_basis_point = \
                                        Geometry.project_point_onto_surface( \
                                                Vector2(land_surface_bottom_bound, INF), \
                                                jump_surface)
                                displacement_land_basis_point = \
                                        land_surface_bottom_end_wrapper.target_point
                            var bottom_end_jump_land_positions := \
                                    _calculate_jump_land_points_for_walls_facing_each_other( \
                                            movement_params, \
                                            all_jump_land_positions, \
                                            false, \
                                            displacement_jump_basis_point, \
                                            displacement_land_basis_point, \
                                            velocity_start, \
                                            is_a_jump_calculator, \
                                            jump_surface, \
                                            jump_surface_top_end_wrapper, \
                                            jump_surface_bottom_end_wrapper, \
                                            land_surface, \
                                            land_surface_top_end_wrapper, \
                                            land_surface_bottom_end_wrapper, \
                                            top_end_jump_land_positions)
                            
                            # Considering closest-points case.
                            displacement_jump_basis_point = \
                                    Geometry.get_closest_point_on_polyline_to_polyline( \
                                            jump_surface.vertices, \
                                            land_surface.vertices)
                            displacement_land_basis_point = \
                                    Geometry.get_closest_point_on_polyline_to_point( \
                                            displacement_land_basis_point, \
                                            land_surface.vertices)
                            var closest_points_jump_land_positions := \
                                    _calculate_jump_land_points_for_walls_facing_each_other( \
                                            movement_params, \
                                            all_jump_land_positions, \
                                            true, \
                                            displacement_jump_basis_point, \
                                            displacement_land_basis_point, \
                                            velocity_start, \
                                            is_a_jump_calculator, \
                                            jump_surface, \
                                            jump_surface_top_end_wrapper, \
                                            jump_surface_bottom_end_wrapper, \
                                            land_surface, \
                                            land_surface_top_end_wrapper, \
                                            land_surface_bottom_end_wrapper, \
                                            top_end_jump_land_positions, \
                                            bottom_end_jump_land_positions)
                            
                        else:
                            # Jump between two walls that are facing away from each other.
                            
                            # Consider one pair for the top ends.
                            var jump_position := jump_surface_top_end_wrapper
                            var land_position := _create_surface_interior_position( \
                                    land_surface_top_end_wrapper.target_point.y + \
                                            vertical_offset_to_support_extra_movement_around_wall, \
                                    land_surface, \
                                    movement_params.collider_half_width_height, \
                                    land_surface_top_end_wrapper, \
                                    land_surface_bottom_end_wrapper)
                            var top_ends_jump_land_positions := JumpLandPositions.new( \
                                    jump_position, \
                                    land_position, \
                                    velocity_start)
                            all_jump_land_positions.push_back(top_ends_jump_land_positions)
                            
                            if !do_surfaces_overlap_vertically:
                                # When the surfaces don't overlap vertically, it might be possible
                                # for movement to go horizontally between the two surfaces, so we
                                # consider that extra jump/land pair here.
                                if is_jump_surface_lower:
                                    jump_position = jump_surface_top_end_wrapper
                                    land_position = land_surface_bottom_end_wrapper
                                else:
                                    jump_position = jump_surface_bottom_end_wrapper
                                    land_position = _create_surface_interior_position( \
                                            land_surface_top_end_wrapper.target_point.y + \
                                                    vertical_offset_to_support_extra_movement_around_wall, \
                                            land_surface, \
                                            movement_params.collider_half_width_height, \
                                            land_surface_top_end_wrapper, \
                                            land_surface_bottom_end_wrapper)
                                var between_surfaces_jump_land_positions := \
                                        JumpLandPositions.new( \
                                                jump_position, \
                                                land_position, \
                                                velocity_start)
                                all_jump_land_positions.push_back(between_surfaces_jump_land_positions)
                    
                SurfaceSide.CEILING:
                    # Jump from a wall, land on a ceiling.
                    
                    # TODO: Implement ceiling use-cases.
                    Utils.error("calculate_jump_land_positions_for_surface_pair ceiling cases " + \
                            "not implemented yet")
                    
                _:
                    Utils.error("Unknown land surface side (jump from wall)")
            
        SurfaceSide.CEILING:
            match land_surface.side:
                SurfaceSide.FLOOR:
                    # Jump from a ceiling, land on a floor.
                    
                    # TODO: Implement ceiling use-cases.
                    Utils.error("calculate_jump_land_positions_for_surface_pair ceiling cases " + \
                            "not implemented yet")
                    
                SurfaceSide.LEFT_WALL, SurfaceSide.RIGHT_WALL:
                    # Jump from a ceiling, land on a wall.
                    
                    # TODO: Implement ceiling use-cases.
                    Utils.error("calculate_jump_land_positions_for_surface_pair ceiling cases " + \
                            "not implemented yet")
                    
                SurfaceSide.CEILING:
                    # Jump from a ceiling, land on a ceiling.
                    
                    # Return no valid points, since we must move down, away from the first ceiling,
                    # and cannot then move back upward after starting the fall.
                    pass
                    
                _:
                    Utils.error("Unknown land surface side (jump from ceiling)")
            
        _:
            Utils.error("Unknown jump surface side")
    
    if movement_params.always_includes_jump_land_end_point_combinations:
        # Record jump/land position combinations for the surface-end points.
        # 
        # The surface-end points aren't usually as efficient, or as likely to produce valid edges,
        # as the more intelligent surface-interior-point calculations above. Also, one of the
        # surface-interior point calculations should almost always cover any surface-end-point edge
        # use-case.
        
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
        var interior_point_min_horizontal_distance_from_end := \
                movement_params.collider_half_width_height.x * \
                JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_HEIGHT_RATIO
        var interior_point_min_horizontal_distance_squared_from_end := \
                interior_point_min_horizontal_distance_from_end * \
                interior_point_min_horizontal_distance_from_end
        if land_surface_closest_point.distance_squared_to(land_surface.first_point) < \
                interior_point_min_horizontal_distance_squared_from_end and \
                land_surface_closest_point.distance_squared_to(land_surface.last_point) < \
                interior_point_min_horizontal_distance_squared_from_end:
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
    var interior_point_min_horizontal_distance_from_end := \
            collider_half_width_height.x * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_HEIGHT_RATIO
    
    var lower_bound: float
    var upper_bound: float
    if is_considering_x_axis:
        lower_bound = surface.bounding_box.position.x
        upper_bound = surface.bounding_box.end.x
    else:
        lower_bound = surface.bounding_box.position.y
        upper_bound = surface.bounding_box.end.y
    
    var is_goal_close_to_lower_end := \
            goal_coordinate <= lower_bound + interior_point_min_horizontal_distance_from_end
    var is_goal_close_to_upper_end := \
            goal_coordinate >= upper_bound - interior_point_min_horizontal_distance_from_end
    
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

# Checks whether the given jump/land positions are far enough away from all other previous
# jump/land positions, and records it in the given results collection if they are.
static func _record_if_distinct( \
        current_jump_position: PositionAlongSurface, \
        current_land_position: PositionAlongSurface, \
        velocity_start: Vector2, \
        distance_threshold: float, \
        results: Array, \
        inserts_at_front: bool, \
        previous_jump_land_positions_1: JumpLandPositions, \
        previous_jump_land_positions_2 = null, \
        previous_jump_land_positions_3 = null) -> JumpLandPositions:
    var is_considering_x_coordinate_for_jump_position := \
            current_jump_position.surface.normal.x == 0.0
    var is_considering_x_coordinate_for_land_position:= \
            current_land_position.surface.normal.x == 0.0
    
    var current_jump_coordinate: float
    var current_land_coordinate: float
    var previous_jump_coordinate: float
    var previous_land_coordinate: float
    var is_close: bool
    
    for previous_jump_land_positions in [ \
            previous_jump_land_positions_1, \
            previous_jump_land_positions_2, \
            previous_jump_land_positions_3, \
            ]:
        if previous_jump_land_positions != null:
            if is_considering_x_coordinate_for_jump_position:
                current_jump_coordinate = current_jump_position.target_point.x
                previous_jump_coordinate = \
                        previous_jump_land_positions.jump_position.target_point.x
            else:
                current_jump_coordinate = current_jump_position.target_point.y
                previous_jump_coordinate = \
                        previous_jump_land_positions.jump_position.target_point.y
            
            if is_considering_x_coordinate_for_land_position:
                current_land_coordinate = current_land_position.target_point.x
                previous_land_coordinate = \
                        previous_jump_land_positions.land_position.target_point.x
            else:
                current_land_coordinate = current_land_position.target_point.y
                previous_land_coordinate = \
                        previous_jump_land_positions.land_position.target_point.y
            
            is_close = \
                    abs(previous_jump_coordinate - current_jump_coordinate) < \
                    distance_threshold and \
                    abs(previous_land_coordinate - current_land_coordinate) < \
                    distance_threshold
            if is_close:
                return null
    
    var jump_land_positions := \
            JumpLandPositions.new( \
                    current_jump_position, \
                    current_land_position, \
                    velocity_start)
    if inserts_at_front:
        results.push_front(jump_land_positions)
    else:
        results.push_back(jump_land_positions)
    return jump_land_positions

# Calculates a representative horizontal distance between jump and land positions.
# 
# For simplicity, this assumes that the closest point of the surface is at the same height as the
# resulting point along the surface that we are calculating.
static func _calculate_horizontal_movement_offset( \
        movement_params: MovementParams, \
        displacement_jump_basis_point: Vector2, \
        displacement_land_basis_point: Vector2, \
        velocity_start: Vector2, \
        is_a_jump_calculator: bool, \
        must_reach_destination_on_fall: bool) -> float:
    var displacement: Vector2 = \
            displacement_land_basis_point - displacement_jump_basis_point
    
    var duration: float = \
            VerticalMovementUtils.calculate_time_to_jump_to_waypoint( \
                    movement_params, \
                    displacement, \
                    velocity_start, \
                    is_a_jump_calculator, \
                    must_reach_destination_on_fall)
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

# Calculates a representative vertical distance between the given jump and land positions.
# 
# - If this is for a jump calculator, then both vertical displacements corresponding to
#   max-jump-button-press and min-jump-button-press are considered, and a value within this range
#   is returned. This value will be as close as possible to the actual displacement between the
#   given jump/land basis points.
# - For simplicity, this assumes that the basis point is at the same x-coordinate as the resulting
#   point along the surface that we are calculating.
# - This doesn't account for any required velocity-end values for landing on wall surfaces.
#   Instead, we rely on a constant vertical offset being applied (elsewhere) whenever we detect
#    movement is moving around an end of a wall.
static func _calculate_vertical_movement_offset( \
        movement_params: MovementParams, \
        displacement_jump_basis_point: Vector2, \
        displacement_land_basis_point: Vector2, \
        velocity_start: Vector2, \
        is_a_jump_calculator: bool) -> float:
    var displacement: Vector2 = \
            displacement_land_basis_point - displacement_jump_basis_point
    var acceleration_x := \
            movement_params.in_air_horizontal_acceleration if \
            displacement.x > 0.0 else \
            -movement_params.in_air_horizontal_acceleration
    
    var duration: float = MovementUtils.calculate_duration_for_displacement( \
            displacement.x, \
            velocity_start.x, \
            acceleration_x, \
            movement_params.max_horizontal_speed_default)
    assert(duration != INF)
    
    var vertical_offset_with_fast_fall_gravity: float = \
            MovementUtils.calculate_displacement_for_duration( \
                    duration, \
                    abs(velocity_start.y), \
                    movement_params.gravity_fast_fall, \
                    movement_params.max_vertical_speed)
    
    if !is_a_jump_calculator or vertical_offset_with_fast_fall_gravity < displacement.y:
        # Since we already can't descend as far as we'd like with max gravity, we don't need to
        # bother calculating the option with min gravity.
        return vertical_offset_with_fast_fall_gravity
    
    else:
        # Take into consideration the offset with slow-rise gravity.
        var vertical_offset_with_slow_rise_gravity: float = VerticalMovementUtils \
                .calculate_vertical_displacement_from_duration_with_max_slow_rise_gravity( \
                        movement_params, \
                        duration, \
                        velocity_start.y)
        
        if vertical_offset_with_slow_rise_gravity > displacement.y:
            # Since we descend further than we'd like, even with min gravity, this displacement is
            # our best option.
            return vertical_offset_with_slow_rise_gravity
        
        # The ideal displacement would exactly match the displacemnt between the basis jump/land
        # points, and since that displacemnt is within the possible range, we can use it.
        return displacement.y

# Calculates a jump/land pair between two walls that face each other.
# 
# - Calculates vertical offset for jumping between the given basis points, and applies this offset
#   to the resulting jump/land pair.
# - Re-uses any end-point wrapper position instances, instead of creating new ones.
# - Checks previous jump/land pairs to ensure the new one would be distinct.
static func _calculate_jump_land_points_for_walls_facing_each_other( \
        movement_params: MovementParams, \
        all_jump_land_positions: Array, \
        inserts_at_front: bool, \
        jump_basis_point: Vector2, \
        land_basis_point: Vector2, \
        velocity_start: Vector2, \
        is_a_jump_calculator: bool, \
        jump_surface: Surface, \
        jump_surface_top_end_wrapper: PositionAlongSurface, \
        jump_surface_bottom_end_wrapper: PositionAlongSurface, \
        land_surface: Surface, \
        land_surface_top_end_wrapper: PositionAlongSurface, \
        land_surface_bottom_end_wrapper: PositionAlongSurface, \
        other_jump_land_positions_1 = null, \
        other_jump_land_positions_2 = null) -> JumpLandPositions:
    var jump_surface_top_bound := jump_surface.bounding_box.position.y
    var land_surface_bottom_bound := land_surface.bounding_box.end.y
    
    var vertical_movement_offset := _calculate_vertical_movement_offset( \
            movement_params, \
            jump_basis_point, \
            land_basis_point, \
            velocity_start, \
            is_a_jump_calculator)
    
    var jump_goal_y := jump_basis_point.y
    var land_goal_y := jump_basis_point.y + vertical_movement_offset
    
    if land_goal_y > land_surface_bottom_bound:
        # There is not enough length on the land surface to account for this vertical offset, so we
        # need to account for some of it on the jump surface.
        var remaining_offset := land_goal_y - land_surface_bottom_bound
        if jump_goal_y - remaining_offset >= jump_surface_top_bound:
            # There is enough length on the jump surface to account for this vertical offset.
            jump_goal_y -= remaining_offset
            land_goal_y = land_surface_bottom_bound
        else:
            # There is not enough length on the jump surface to account for this vertical offset
            # either, so we should abandon this jump/land pair as infeasible.
            return null
    
    var jump_position := _create_surface_interior_position( \
            jump_goal_y, \
            jump_surface, \
            movement_params.collider_half_width_height, \
            jump_surface_top_end_wrapper, \
            jump_surface_bottom_end_wrapper)
    var land_position := _create_surface_interior_position( \
            land_goal_y, \
            land_surface, \
            movement_params.collider_half_width_height, \
            land_surface_top_end_wrapper, \
            land_surface_bottom_end_wrapper)
    
    var interior_point_min_vertical_distance_from_end := \
            movement_params.collider_half_width_height.y * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_PLAYER_WIDTH_HEIGHT_RATIO
    
    return _record_if_distinct( \
            jump_position, \
            land_position, \
            velocity_start, \
            interior_point_min_vertical_distance_from_end, \
            all_jump_land_positions, \
            inserts_at_front, \
            other_jump_land_positions_1, \
            other_jump_land_positions_2)
