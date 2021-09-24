class_name JumpLandPositionsUtils
extends Reference
# A collection of utility functions for calculating state related to jump/land
# positions.


const EXTRA_JUMP_LAND_POSITION_MARGIN := 2.0
const CHARACTER_HEIGHT_VERTICAL_CLEARANCE_RATIO := 2.0
const JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_CHARACTER_WIDTH_HEIGHT_RATIO := 0.3
const EDGE_MOVEMENT_HORIZONTAL_DISTANCE_SUBTRACT_CHARACTER_WIDTH_RATIO := 0.1
const VERTICAL_OFFSET_TO_SUPPORT_EXTRA_MOVEMENT_AROUND_WALL_CHARACTER_HEIGHT_RATIO := 0.6
const MARGIN_FROM_CONCAVE_NEIGHBOR := 1.0

# This required min distance helps prevent the character from falling slightly
# short and missing the bottom corner of the land surface.
const MIN_LAND_DISTANCE_FROM_WALL_BOTTOM := 12.0


# Calculates "good" combinations of jump position, land position, and start
# velocity for movement between the given pair of surfaces.
# 
# -   Some interesting jump/land positions for a given surface include the
#     following:
#     -   Either end of the surface.
#     -   The closest position along the surface to either end of the other
#         surface.
#         -   This closest position, but with a slight offset to account for
#             the width of the character.
#         -   This closest position, but with an additional offset to account
#             for horizontal movement with minimum jump time and maximum
#             horizontal velocity.
#         -   The closest interior position along the surface to the closest
#             interior position along the other surface.
# -   Points are only included if they are distinct.
# -   We try to minimize the number of jump/land positions returned, since
#     having more of these greatly increases the overall time to parse the
#     platform graph.
# -   Results are returned sorted heuristically by what's more likely to
#     produce valid, efficient movement.
#     -   Surface-interior points are usually included before surface-end
#         points.
#     -   This usually puts shortest distance first.
# -   Start velocity is determined from the given EdgeCalculator.
# -   Start horizontal velocity from a floor could be either zero or max-speed.
# 
# For illustrations of the various jump/land position combinations for each
# surface arrangement, see:
# https://github.com/snoringcatgames/surfacer/tree/master/docs
static func calculate_jump_land_positions_for_surface_pair(
        movement_params: MovementParameters,
        jump_surface: Surface,
        land_surface: Surface) -> Array:
    var jump_surface_left_bound := jump_surface.bounding_box.position.x
    var jump_surface_right_bound := jump_surface.bounding_box.end.x
    var jump_surface_top_bound := jump_surface.bounding_box.position.y
    var jump_surface_bottom_bound := jump_surface.bounding_box.end.y
    var land_surface_left_bound := land_surface.bounding_box.position.x
    var land_surface_right_bound := land_surface.bounding_box.end.x
    var land_surface_top_bound := land_surface.bounding_box.position.y
    var land_surface_bottom_bound := land_surface.bounding_box.end.y
    
    var jump_connected_region_left_bound := \
            jump_surface.connected_region_bounding_box.position.x
    var jump_connected_region_right_bound := \
            jump_surface.connected_region_bounding_box.end.x
    var jump_connected_region_top_bound := \
            jump_surface.connected_region_bounding_box.position.y
    var jump_connected_region_bottom_bound := \
            jump_surface.connected_region_bounding_box.end.y
    var land_connected_region_left_bound := \
            land_surface.connected_region_bounding_box.position.x
    var land_connected_region_right_bound := \
            land_surface.connected_region_bounding_box.end.x
    var land_connected_region_top_bound := \
            land_surface.connected_region_bounding_box.position.y
    var land_connected_region_bottom_bound := \
            land_surface.connected_region_bounding_box.end.y
    
    var jump_surface_center := jump_surface.center
    var land_surface_center := land_surface.center
    
    var jump_surface_has_only_one_point := jump_surface.vertices.size() == 1
    var land_surface_has_only_one_point := land_surface.vertices.size() == 1
    
    var jump_surface_first_point := jump_surface.first_point
    var jump_surface_last_point := jump_surface.last_point
    var land_surface_first_point := land_surface.first_point
    var land_surface_last_point := land_surface.last_point
    
    # Create wrapper PositionAlongSurface ahead of time, so later calculations
    # can all reference the same instances.
    var jump_surface_first_point_wrapper: PositionAlongSurface = \
            PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            jump_surface_first_point,
                            jump_surface,
                            movement_params.collider)
    var jump_surface_last_point_wrapper: PositionAlongSurface = \
            PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            jump_surface_last_point,
                            jump_surface,
                            movement_params.collider)
    var land_surface_first_point_wrapper: PositionAlongSurface = \
            PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            land_surface_first_point,
                            land_surface,
                            movement_params.collider)
    var land_surface_last_point_wrapper: PositionAlongSurface = \
            PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            land_surface_last_point,
                            land_surface,
                            movement_params.collider)
    
    # Create some additional variables, so we can conveniently reference end
    # points according to near/far.
    # 
    # Use a bounding-box heuristic to determine which ends of the surfaces are
    # likely to be nearer and farther.
    var jump_surface_near_end := Vector2.INF
    var jump_surface_far_end := Vector2.INF
    var jump_surface_near_end_wrapper: PositionAlongSurface
    var jump_surface_far_end_wrapper: PositionAlongSurface
    if Sc.geometry.distance_squared_from_point_to_rect(
            jump_surface_first_point,
            land_surface.bounding_box) < \
            Sc.geometry.distance_squared_from_point_to_rect(
                    jump_surface_last_point,
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
    if Sc.geometry.distance_squared_from_point_to_rect(
            land_surface_first_point,
            jump_surface.bounding_box) < \
            Sc.geometry.distance_squared_from_point_to_rect(
                    land_surface_last_point,
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
    
    # Create some additional variables, so we can conveniently reference end
    # points according to left/right/top/bottom. This is just slightly easier
    # to read and think about, rather than having to remember which direction
    # the first/last points correspond to, depending on the given surface side.
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
            Sc.logger.error()
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
            Sc.logger.error()
    
    var are_surfaces_at_same_height: bool = \
            Sc.geometry.are_floats_equal_with_epsilon(
                    jump_surface_center.y,
                    land_surface_center.y,
                    1.0)
    var is_jump_surface_lower := \
            jump_surface_center.y > land_surface_center.y
    var is_jump_surface_higher := \
            jump_surface_center.y < land_surface_center.y
    var is_jump_surface_lower_or_level := \
            is_jump_surface_lower or \
            are_surfaces_at_same_height
    var is_jump_surface_more_to_the_left := \
            jump_surface_center.x < land_surface_center.x
    
    var is_a_jump_calculator := true
    var can_hold_jump_button_at_start := \
            is_a_jump_calculator and \
            jump_surface.side != SurfaceSide.CEILING
    
    var character_half_width_horizontal_offset := \
            movement_params.collider.half_width_height.x + \
            movement_params.collision_margin_for_waypoint_positions + \
            EXTRA_JUMP_LAND_POSITION_MARGIN
    var character_height_vertical_clearance := \
            movement_params.collider.half_width_height.y * 2.0 * \
            CHARACTER_HEIGHT_VERTICAL_CLEARANCE_RATIO + \
            movement_params.collision_margin_for_waypoint_positions * 2.0
    var interior_point_min_horizontal_distance_from_end := \
            movement_params.collider.half_width_height.x * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_CHARACTER_WIDTH_HEIGHT_RATIO
    var interior_point_min_vertical_distance_from_end := \
            movement_params.collider.half_width_height.y * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_CHARACTER_WIDTH_HEIGHT_RATIO
    var vertical_offset_to_support_extra_movement_around_wall := \
            movement_params.collider.half_width_height.y * \
            VERTICAL_OFFSET_TO_SUPPORT_EXTRA_MOVEMENT_AROUND_WALL_CHARACTER_HEIGHT_RATIO
            
    var all_jump_land_positions := []
    
    # Calculate intelligent jump/land position combinations for
    # surface-interior points, depending on the jump/land surface types and
    # spatial arrangement.
    match jump_surface.side:
        SurfaceSide.FLOOR:
            match land_surface.side:
                SurfaceSide.FLOOR:
                    # Jump from a floor, land on a floor.
                    # https://github.com/snoringcatgames/surfacer/tree/master/docs/
                    #         jump-land-positions-floor-to-floor.png
                    
                    var is_jump_surface_much_lower := \
                            jump_surface_center.y > \
                            land_surface_center.y + \
                            character_height_vertical_clearance
                    var is_land_surface_much_lower := \
                            land_surface_center.y > \
                            jump_surface_center.y + \
                            character_height_vertical_clearance
                    var are_surfaces_far_enough_to_move_between_vertically := \
                            is_jump_surface_much_lower or \
                            is_land_surface_much_lower
                    
                    var is_enough_left_side_distance_to_not_backtrack_horizontally := \
                            jump_surface_left_bound <= \
                            land_surface_left_bound - \
                                    character_half_width_horizontal_offset if \
                            is_jump_surface_lower else \
                            land_surface_left_bound <= \
                            jump_surface_left_bound - \
                                    character_half_width_horizontal_offset
                    var is_enough_right_side_distance_to_not_backtrack_horizontally := \
                            jump_surface_right_bound >= \
                            land_surface_right_bound + \
                                    character_half_width_horizontal_offset if \
                            is_jump_surface_lower else \
                            land_surface_right_bound >= \
                            jump_surface_right_bound + \
                                    character_half_width_horizontal_offset
                    
                    var needs_extra_jump_duration := \
                            land_surface_center.y - jump_surface_center.y < \
                            -movement_params.min_upward_jump_distance
                    
                    var is_considering_left_side_first := \
                            is_enough_left_side_distance_to_not_backtrack_horizontally or \
                            !is_enough_right_side_distance_to_not_backtrack_horizontally
                    var is_considering_left_side_order := \
                            [true, false] if \
                            is_considering_left_side_first else \
                            [false, true]
                    
                    for is_considering_left_side in \
                            is_considering_left_side_order:
                        if is_considering_left_side:
                            if is_enough_left_side_distance_to_not_backtrack_horizontally:
                                # Consider direct horizontal movement.
                                # Consider both v-zero and v-max.
                                
                                var does_velocity_start_moving_leftward := \
                                        jump_surface_left_bound > \
                                        land_surface_left_bound
                                var velocity_start_zero := get_velocity_start(
                                        movement_params,
                                        jump_surface,
                                        is_a_jump_calculator,
                                        does_velocity_start_moving_leftward,
                                        true)
                                var velocity_start_max_speed := \
                                        get_velocity_start(
                                                movement_params,
                                                jump_surface,
                                                is_a_jump_calculator,
                                                does_velocity_start_moving_leftward,
                                                false)
                                
                                if is_jump_surface_lower:
                                    # Consider max-speed horizontal start
                                    # velocity, with the corresponding
                                    # horizontal displacement from movement.
                                    var jump_basis: Vector2 = \
                                            Sc.geometry.project_shape_onto_surface(
                                                    land_surface_left_end,
                                                    movement_params.collider,
                                                    jump_surface)
                                    var land_basis := land_surface_left_end_wrapper.target_point
                                    var must_reach_destination_on_fall := true
                                    var must_reach_destination_on_rise := false
                                    var horizontal_movement_distance := \
                                            _calculate_horizontal_movement_distance(
                                                    movement_params,
                                                    jump_basis,
                                                    land_basis,
                                                    velocity_start_max_speed,
                                                    can_hold_jump_button_at_start,
                                                    must_reach_destination_on_fall,
                                                    must_reach_destination_on_rise)
                                    var jump_position: PositionAlongSurface
                                    var land_position: PositionAlongSurface
                                    if land_surface_left_bound - jump_surface_left_bound > \
                                            horizontal_movement_distance:
                                        # We can apply all of the horizontal movement displacement
                                        # onto the jump position.
                                        var jump_x := \
                                                land_surface_left_bound - \
                                                horizontal_movement_distance
                                        jump_position = _create_surface_interior_position(
                                                jump_x,
                                                jump_surface,
                                                movement_params.collider,
                                                jump_surface_left_end_wrapper,
                                                jump_surface_right_end_wrapper)
                                        land_position = land_surface_left_end_wrapper
                                    elif (land_surface_left_bound - jump_surface_left_bound) + \
                                            (land_surface_right_bound - \
                                            land_surface_left_bound) > \
                                            horizontal_movement_distance:
                                        # We can apply some of the horizontal movement displacement
                                        # onto the jump position, and the rest onto the land
                                        # position.
                                        jump_position = jump_surface_left_end_wrapper
                                        var land_x := \
                                                land_surface_left_bound + \
                                                horizontal_movement_distance - \
                                                (land_surface_left_bound - \
                                                jump_surface_left_bound)
                                        land_position = _create_surface_interior_position(
                                                land_x,
                                                land_surface,
                                                movement_params.collider,
                                                land_surface_left_end_wrapper,
                                                land_surface_right_end_wrapper)
                                    else:
                                        # There isn't enough room on either surface to account for
                                        # the entire horizontal movement displacement, so we'll
                                        # just use the far ends.
                                        jump_position = jump_surface_left_end_wrapper
                                        land_position = land_surface_right_end_wrapper
                                    var max_movement_jump_land_positions := \
                                            _create_jump_land_positions(
                                                    movement_params,
                                                    jump_position,
                                                    land_position,
                                                    velocity_start_max_speed,
                                                    all_jump_land_positions,
                                                    needs_extra_jump_duration)
                                    
                                    # Consider zero horizontal start velocity, with only
                                    # character-half-width horizontal displacement.
                                    var jump_x := \
                                            land_surface_left_bound - \
                                            character_half_width_horizontal_offset
                                    jump_position = _create_surface_interior_position(
                                            jump_x,
                                            jump_surface,
                                            movement_params.collider,
                                            jump_surface_left_end_wrapper,
                                            jump_surface_right_end_wrapper)
                                    land_position = land_surface_left_end_wrapper
                                    var min_movement_jump_land_positions := _record_if_distinct(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start_zero,
                                            interior_point_min_horizontal_distance_from_end,
                                            needs_extra_jump_duration,
                                            all_jump_land_positions,
                                            false,
                                            max_movement_jump_land_positions)
                                    
                                else: # Land surface is lower.
                                    # Consider max-speed horizontal start velocity, with the
                                    # corresponding horizontal displacement from movement.
                                    var jump_basis := jump_surface_left_end_wrapper.target_point
                                    var land_basis: Vector2 = \
                                            Sc.geometry.project_shape_onto_surface(
                                                    jump_surface_left_end,
                                                    movement_params.collider,
                                                    land_surface)
                                    var must_reach_destination_on_fall := true
                                    var must_reach_destination_on_rise := false
                                    var horizontal_movement_distance := \
                                            _calculate_horizontal_movement_distance(
                                                    movement_params,
                                                    jump_basis,
                                                    land_basis,
                                                    velocity_start_max_speed,
                                                    can_hold_jump_button_at_start,
                                                    must_reach_destination_on_fall,
                                                    must_reach_destination_on_rise)
                                    var jump_position: PositionAlongSurface
                                    var land_position: PositionAlongSurface
                                    if jump_surface_left_bound - land_surface_left_bound > \
                                            horizontal_movement_distance:
                                        # We can apply all of the horizontal movement displacement
                                        # onto the land position.
                                        jump_position = jump_surface_left_end_wrapper
                                        var land_x := \
                                                jump_surface_left_bound - \
                                                horizontal_movement_distance
                                        land_position = _create_surface_interior_position(
                                                land_x,
                                                land_surface,
                                                movement_params.collider,
                                                land_surface_left_end_wrapper,
                                                land_surface_right_end_wrapper)
                                    elif (jump_surface_left_bound - land_surface_left_bound) + \
                                            (jump_surface_right_bound - \
                                            jump_surface_left_bound) > \
                                            horizontal_movement_distance:
                                        # We can apply some of the horizontal movement displacement
                                        # onto the land position, and the rest onto the jump
                                        # position.
                                        var jump_x := \
                                                jump_surface_left_bound + \
                                                horizontal_movement_distance - \
                                                (jump_surface_left_bound - \
                                                land_surface_left_bound)
                                        jump_position = _create_surface_interior_position(
                                                jump_x,
                                                jump_surface,
                                                movement_params.collider,
                                                jump_surface_left_end_wrapper,
                                                jump_surface_right_end_wrapper)
                                        land_position = land_surface_left_end_wrapper
                                    else:
                                        # There isn't enough room on either surface to account for
                                        # the entire horizontal movement displacement, so we'll
                                        # just use the far ends.
                                        jump_position = jump_surface_right_end_wrapper
                                        land_position = land_surface_left_end_wrapper
                                    var max_movement_jump_land_positions := \
                                            _create_jump_land_positions(
                                                    movement_params,
                                                    jump_position,
                                                    land_position,
                                                    velocity_start_max_speed,
                                                    all_jump_land_positions,
                                                    needs_extra_jump_duration)
                                    
                                    # Consider zero horizontal start velocity, with only
                                    # character-half-width horizontal displacement.
                                    jump_position = jump_surface_left_end_wrapper
                                    var land_x := \
                                            jump_surface_left_bound - \
                                            character_half_width_horizontal_offset
                                    land_position = _create_surface_interior_position(
                                            land_x,
                                            land_surface,
                                            movement_params.collider,
                                            land_surface_left_end_wrapper,
                                            land_surface_right_end_wrapper)
                                    var min_movement_jump_land_positions := _record_if_distinct(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start_zero,
                                            interior_point_min_horizontal_distance_from_end,
                                            needs_extra_jump_duration,
                                            all_jump_land_positions,
                                            false,
                                            max_movement_jump_land_positions)
                                
                            elif are_surfaces_far_enough_to_move_between_vertically:
                                # Consider backtracking horizontal movement in order to move around
                                # underneath the upper surface (the far end of the upper surface
                                # and the near end of the lower surface).
                                var does_velocity_start_moving_leftward := true
                                var velocity_start_max_speed := get_velocity_start(
                                        movement_params,
                                        jump_surface,
                                        is_a_jump_calculator,
                                        does_velocity_start_moving_leftward,
                                        false)
                                var jump_position := jump_surface_left_end_wrapper
                                var land_position := land_surface_left_end_wrapper
                                var less_likely_to_be_valid := true
                                var move_around_under_jump_land_positions := \
                                        _create_jump_land_positions(
                                                movement_params,
                                                jump_position,
                                                land_position,
                                                velocity_start_max_speed,
                                                all_jump_land_positions,
                                                needs_extra_jump_duration,
                                                less_likely_to_be_valid)
                            
                        else: # Is considering right side.
                            if is_enough_right_side_distance_to_not_backtrack_horizontally:
                                # Consider direct horizontal movement.
                                # Consider both v-zero and v-max.
                                
                                var does_velocity_start_moving_leftward := \
                                        jump_surface_right_bound > land_surface_right_bound
                                var velocity_start_zero := get_velocity_start(
                                        movement_params,
                                        jump_surface,
                                        is_a_jump_calculator,
                                        does_velocity_start_moving_leftward,
                                        true)
                                var velocity_start_max_speed := get_velocity_start(
                                        movement_params,
                                        jump_surface,
                                        is_a_jump_calculator,
                                        does_velocity_start_moving_leftward,
                                        false)
                                
                                if is_jump_surface_lower:
                                    # Consider max-speed horizontal start velocity, with the
                                    # corresponding horizontal displacement from movement.
                                    var jump_basis: Vector2 = \
                                            Sc.geometry.project_shape_onto_surface(
                                                    land_surface_right_end,
                                                    movement_params.collider,
                                                    jump_surface)
                                    var land_basis := land_surface_right_end_wrapper.target_point
                                    var must_reach_destination_on_fall := true
                                    var must_reach_destination_on_rise := false
                                    var horizontal_movement_distance := \
                                            _calculate_horizontal_movement_distance(
                                                    movement_params,
                                                    jump_basis,
                                                    land_basis,
                                                    velocity_start_max_speed,
                                                    can_hold_jump_button_at_start,
                                                    must_reach_destination_on_fall,
                                                    must_reach_destination_on_rise)
                                    var jump_position: PositionAlongSurface
                                    var land_position: PositionAlongSurface
                                    if jump_surface_right_bound - land_surface_right_bound > \
                                            horizontal_movement_distance:
                                        # We can apply all of the horizontal movement displacement
                                        # onto the jump position.
                                        var jump_x := \
                                                land_surface_right_bound + \
                                                horizontal_movement_distance
                                        jump_position = _create_surface_interior_position(
                                                jump_x,
                                                jump_surface,
                                                movement_params.collider,
                                                jump_surface_left_end_wrapper,
                                                jump_surface_right_end_wrapper)
                                        land_position = land_surface_right_end_wrapper
                                    elif (jump_surface_right_bound - land_surface_right_bound) + \
                                            (land_surface_right_bound - \
                                            land_surface_left_bound) > \
                                            horizontal_movement_distance:
                                        # We can apply some of the horizontal movement displacement
                                        # onto the jump position, and the rest onto the land
                                        # position.
                                        jump_position = jump_surface_right_end_wrapper
                                        var land_x := \
                                                land_surface_right_bound - \
                                                horizontal_movement_distance + \
                                                (jump_surface_right_bound - \
                                                land_surface_right_bound)
                                        land_position = _create_surface_interior_position(
                                                land_x,
                                                land_surface,
                                                movement_params.collider,
                                                land_surface_left_end_wrapper,
                                                land_surface_right_end_wrapper)
                                    else:
                                        # There isn't enough room on either surface to account for
                                        # the entire horizontal movement displacement, so we'll
                                        # just use the far ends.
                                        jump_position = jump_surface_right_end_wrapper
                                        land_position = land_surface_left_end_wrapper
                                    var max_movement_jump_land_positions := \
                                            _create_jump_land_positions(
                                                    movement_params,
                                                    jump_position,
                                                    land_position,
                                                    velocity_start_max_speed,
                                                    all_jump_land_positions,
                                                    needs_extra_jump_duration)
                                    
                                    # Consider zero horizontal start velocity, with only
                                    # character-half-width horizontal displacement.
                                    var jump_x := \
                                            land_surface_right_bound + \
                                            character_half_width_horizontal_offset
                                    jump_position = _create_surface_interior_position(
                                            jump_x,
                                            jump_surface,
                                            movement_params.collider,
                                            jump_surface_left_end_wrapper,
                                            jump_surface_right_end_wrapper)
                                    land_position = land_surface_right_end_wrapper
                                    var min_movement_jump_land_positions := _record_if_distinct(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start_zero,
                                            interior_point_min_horizontal_distance_from_end,
                                            needs_extra_jump_duration,
                                            all_jump_land_positions,
                                            false,
                                            max_movement_jump_land_positions)
                                    
                                else: # Land surface is lower.
                                    # Consider max-speed horizontal start velocity, with the
                                    # corresponding horizontal displacement from movement.
                                    var jump_basis := jump_surface_right_end_wrapper.target_point
                                    var land_basis: Vector2 = \
                                            Sc.geometry.project_shape_onto_surface(
                                                    jump_surface_right_end,
                                                    movement_params.collider,
                                                    land_surface)
                                    var must_reach_destination_on_fall := true
                                    var must_reach_destination_on_rise := false
                                    var horizontal_movement_distance := \
                                            _calculate_horizontal_movement_distance(
                                                    movement_params,
                                                    jump_basis,
                                                    land_basis,
                                                    velocity_start_max_speed,
                                                    can_hold_jump_button_at_start,
                                                    must_reach_destination_on_fall,
                                                    must_reach_destination_on_rise)
                                    var jump_position: PositionAlongSurface
                                    var land_position: PositionAlongSurface
                                    if land_surface_right_bound - jump_surface_right_bound > \
                                            horizontal_movement_distance:
                                        # We can apply all of the horizontal movement displacement
                                        # onto the land position.
                                        jump_position = jump_surface_right_end_wrapper
                                        var land_x := \
                                                jump_surface_right_bound + \
                                                horizontal_movement_distance
                                        land_position = _create_surface_interior_position(
                                                land_x,
                                                land_surface,
                                                movement_params.collider,
                                                land_surface_left_end_wrapper,
                                                land_surface_right_end_wrapper)
                                    elif (land_surface_right_bound - jump_surface_right_bound) + \
                                            (jump_surface_right_bound - \
                                            jump_surface_left_bound) > \
                                            horizontal_movement_distance:
                                        # We can apply some of the horizontal movement displacement
                                        # onto the land position, and the rest onto the jump
                                        # position.
                                        var jump_x := \
                                                jump_surface_right_bound - \
                                                horizontal_movement_distance + \
                                                (land_surface_right_bound - \
                                                jump_surface_right_bound)
                                        jump_position = _create_surface_interior_position(
                                                jump_x,
                                                jump_surface,
                                                movement_params.collider,
                                                jump_surface_left_end_wrapper,
                                                jump_surface_right_end_wrapper)
                                        land_position = land_surface_right_end_wrapper
                                    else:
                                        # There isn't enough room on either surface to account for
                                        # the entire horizontal movement displacement, so we'll
                                        # just use the far ends.
                                        jump_position = jump_surface_left_end_wrapper
                                        land_position = land_surface_right_end_wrapper
                                    var max_movement_jump_land_positions := \
                                            _create_jump_land_positions(
                                                    movement_params,
                                                    jump_position,
                                                    land_position,
                                                    velocity_start_max_speed,
                                                    all_jump_land_positions,
                                                    needs_extra_jump_duration)
                                    
                                    # Consider zero horizontal start velocity, with only
                                    # character-half-width horizontal displacement.
                                    jump_position = jump_surface_right_end_wrapper
                                    var land_x := \
                                            jump_surface_right_bound + \
                                            character_half_width_horizontal_offset
                                    land_position = _create_surface_interior_position(
                                            land_x,
                                            land_surface,
                                            movement_params.collider,
                                            land_surface_left_end_wrapper,
                                            land_surface_right_end_wrapper)
                                    var min_movement_jump_land_positions := _record_if_distinct(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start_zero,
                                            interior_point_min_horizontal_distance_from_end,
                                            needs_extra_jump_duration,
                                            all_jump_land_positions,
                                            false,
                                            max_movement_jump_land_positions)
                                
                            elif are_surfaces_far_enough_to_move_between_vertically:
                                # Consider backtracking horizontal movement in order to move around
                                # underneath the upper surface (the far end of the upper surface
                                # and the near end of the lower surface).
                                var does_velocity_start_moving_leftward := false
                                var velocity_start_max_speed := get_velocity_start(
                                        movement_params,
                                        jump_surface,
                                        is_a_jump_calculator,
                                        does_velocity_start_moving_leftward,
                                        false)
                                var jump_position := jump_surface_right_end_wrapper
                                var land_position := land_surface_right_end_wrapper
                                var less_likely_to_be_valid := true
                                var move_around_under_jump_land_positions := \
                                        _create_jump_land_positions(
                                                movement_params,
                                                jump_position,
                                                land_position,
                                                velocity_start_max_speed,
                                                all_jump_land_positions,
                                                needs_extra_jump_duration,
                                                less_likely_to_be_valid)
                    
                SurfaceSide.LEFT_WALL, \
                SurfaceSide.RIGHT_WALL:
                    # Jump from a floor, land on a wall.
                    # https://github.com/snoringcatgames/surfacer/tree/master/docs/
                    #         jump-land-positions-floor-to-wall.png
                    
                    var is_landing_on_left_wall := \
                            land_surface.side == SurfaceSide.LEFT_WALL
                    var can_jump_in_front_of_wall := \
                            is_landing_on_left_wall and \
                            jump_surface_right_bound > \
                                    land_surface_center.x + character_half_width_horizontal_offset or \
                            !is_landing_on_left_wall and \
                            jump_surface_left_bound < \
                                    land_surface_center.x - character_half_width_horizontal_offset
                    
                    var does_velocity_start_moving_leftward: bool
                    var prefer_velocity_start_zero_horizontal_speed: bool
                    var velocity_start: Vector2
                    var jump_basis: Vector2
                    var land_basis: Vector2
                    var jump_position: PositionAlongSurface
                    var land_position: PositionAlongSurface
                    var jump_land_positions: JumpLandPositions
                    
                    if can_jump_in_front_of_wall:
                        # We can jump from the floor into the front side of the wall (we don't need
                        # to go around the backside of the wall).
                        
                        var do_surfaces_overlap_horizontally := \
                                is_landing_on_left_wall and \
                                land_surface_right_bound > jump_surface_left_bound or \
                                !is_landing_on_left_wall and \
                                land_surface_left_bound < jump_surface_right_bound
                        
                        if !do_surfaces_overlap_horizontally:
                            # We're jumping sideways across a horizontal gap to reach the frontside
                            # of the wall.
                            # 
                            # Primary jump/land pair: From close end of floor to close point on
                            # wall.
                            does_velocity_start_moving_leftward = is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = false
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            jump_basis = jump_surface_near_end_wrapper.target_point
                            land_basis = Sc.geometry.project_shape_onto_surface(
                                    jump_surface_near_end,
                                    movement_params.collider,
                                    land_surface)
                            var must_reach_destination_on_fall := false
                            var must_reach_destination_on_rise := false
                            var horizontal_movement_distance := \
                                    _calculate_horizontal_movement_distance(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start,
                                            must_reach_destination_on_fall,
                                            must_reach_destination_on_rise)
                            var goal_x := \
                                    land_basis.x + horizontal_movement_distance if \
                                    is_landing_on_left_wall else \
                                    land_basis.x - horizontal_movement_distance
                            jump_position = _create_surface_interior_position(
                                    goal_x,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_left_end_wrapper,
                                    jump_surface_right_end_wrapper)
                            jump_basis = jump_position.target_point
                            var vertical_movement_displacement := \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            var goal_y := \
                                    jump_basis.y + \
                                    vertical_movement_displacement
                            var fail_if_outside_of_bounds := true
                            land_position = _create_surface_interior_position(
                                    goal_y,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_top_end_wrapper,
                                    land_surface_bottom_end_wrapper,
                                    fail_if_outside_of_bounds)
                            if land_position != null:
                                jump_land_positions = _create_jump_land_positions(
                                        movement_params,
                                        jump_position,
                                        land_position,
                                        velocity_start,
                                        all_jump_land_positions)
                            
                            if land_surface_bottom_bound < jump_surface_center.y:
                                # Bottom of wall is higher than floor.
                                # 
                                # Using max-speed initial velocity could make it impossible to rise
                                # high enough before we've already passed undernead the wall, so we
                                # should also consider a zero-speed initial velocity.
                                # 
                                # Secondary jump/land pair: From close end of floor to close point
                                # on wall.
                                does_velocity_start_moving_leftward = is_landing_on_left_wall
                                prefer_velocity_start_zero_horizontal_speed = true
                                velocity_start = get_velocity_start(
                                        movement_params,
                                        jump_surface,
                                        is_a_jump_calculator,
                                        does_velocity_start_moving_leftward,
                                        prefer_velocity_start_zero_horizontal_speed)
                                jump_basis = jump_surface_near_end_wrapper.target_point
                                land_basis = Sc.geometry.project_shape_onto_surface(
                                        jump_surface_near_end,
                                        movement_params.collider,
                                        land_surface)
                                must_reach_destination_on_fall = false
                                must_reach_destination_on_rise = false
                                horizontal_movement_distance = \
                                        _calculate_horizontal_movement_distance(
                                                movement_params,
                                                jump_basis,
                                                land_basis,
                                                velocity_start,
                                                can_hold_jump_button_at_start,
                                                must_reach_destination_on_fall,
                                                must_reach_destination_on_rise)
                                goal_x = \
                                        land_basis.x + horizontal_movement_distance if \
                                        is_landing_on_left_wall else \
                                        land_basis.x - horizontal_movement_distance
                                jump_position = _create_surface_interior_position(
                                        goal_x,
                                        jump_surface,
                                        movement_params.collider,
                                        jump_surface_left_end_wrapper,
                                        jump_surface_right_end_wrapper)
                                jump_basis = jump_position.target_point
                                vertical_movement_displacement = \
                                        _calculate_vertical_movement_displacement(
                                                movement_params,
                                                jump_basis,
                                                land_basis,
                                                velocity_start,
                                                can_hold_jump_button_at_start)
                                goal_y = \
                                        jump_basis.y + \
                                        vertical_movement_displacement
                                fail_if_outside_of_bounds = true
                                land_position = _create_surface_interior_position(
                                        goal_y,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_top_end_wrapper,
                                        land_surface_bottom_end_wrapper,
                                        fail_if_outside_of_bounds)
                                if land_position != null:
                                    jump_land_positions = _create_jump_land_positions(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start,
                                            all_jump_land_positions)
                                
                            elif land_surface_bottom_bound > jump_surface_center.y:
                                # Bottom of wall is lower than floor.
                                # 
                                # We might be able to move out around the far side of the floor,
                                # then underneath the floor, to land on the wall.
                                # 
                                # Secondary jump/land pair: From far end of floor to lower point on
                                # wall.
                                does_velocity_start_moving_leftward = !is_landing_on_left_wall
                                prefer_velocity_start_zero_horizontal_speed = false
                                velocity_start = get_velocity_start(
                                        movement_params,
                                        jump_surface,
                                        is_a_jump_calculator,
                                        does_velocity_start_moving_leftward,
                                        prefer_velocity_start_zero_horizontal_speed)
                                jump_position = jump_surface_far_end_wrapper
                                jump_basis = jump_surface_far_end_wrapper.target_point
                                land_basis = Sc.geometry.project_shape_onto_surface(
                                        jump_surface_far_end,
                                        movement_params.collider,
                                        land_surface)
                                vertical_movement_displacement = \
                                        _calculate_vertical_movement_displacement(
                                                movement_params,
                                                jump_basis,
                                                land_basis,
                                                velocity_start,
                                                can_hold_jump_button_at_start)
                                goal_y = \
                                        jump_basis.y + \
                                        vertical_movement_displacement
                                fail_if_outside_of_bounds = true
                                land_position = _create_surface_interior_position(
                                        goal_y,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_top_end_wrapper,
                                        land_surface_bottom_end_wrapper,
                                        fail_if_outside_of_bounds)
                                if land_position != null:
                                    var needs_extra_jump_duration := false
                                    var less_likely_to_be_valid := true
                                    jump_land_positions = _create_jump_land_positions(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start,
                                            all_jump_land_positions,
                                            needs_extra_jump_duration,
                                            less_likely_to_be_valid)
                            
                        elif land_surface_top_bound < jump_surface_center.y:
                            # The wall is directly above the floor.
                            # 
                            # Primary jump/land pair: From the floor in front of the wall into the
                            # wall.
                            does_velocity_start_moving_leftward = is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = false
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            var goal_x := \
                                    land_surface_bottom_end.x + \
                                    character_half_width_horizontal_offset if \
                                    is_landing_on_left_wall else \
                                    land_surface_bottom_end.x - \
                                    character_half_width_horizontal_offset
                            jump_basis = Sc.geometry.project_shape_onto_surface(
                                    Vector2(goal_x, INF),
                                    movement_params.collider,
                                    jump_surface)
                            land_basis = land_surface_bottom_end_wrapper.target_point
                            var must_reach_destination_on_fall := false
                            var must_reach_destination_on_rise := false
                            var horizontal_movement_distance := \
                                    _calculate_horizontal_movement_distance(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start,
                                            must_reach_destination_on_fall,
                                            must_reach_destination_on_rise)
                            goal_x += \
                                    horizontal_movement_distance if \
                                    is_landing_on_left_wall else \
                                    -horizontal_movement_distance
                            jump_position = _create_surface_interior_position(
                                    goal_x,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_left_end_wrapper,
                                    jump_surface_right_end_wrapper)
                            jump_basis = jump_position.target_point
                            var vertical_movement_displacement := \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            var goal_y := \
                                    jump_basis.y + \
                                    vertical_movement_displacement
                            land_position = _create_surface_interior_position(
                                    goal_y,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_top_end_wrapper,
                                    land_surface_bottom_end_wrapper)
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
                            # Also consider a version of the primary jump/land pair with zero
                            # horizontal start velocity.
                            does_velocity_start_moving_leftward = is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = true
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            land_position = land_surface_bottom_end_wrapper
                            goal_x = \
                                    land_surface_bottom_end.x + \
                                    character_half_width_horizontal_offset if \
                                    is_landing_on_left_wall else \
                                    land_surface_bottom_end.x - \
                                    character_half_width_horizontal_offset
                            jump_position = _create_surface_interior_position(
                                    goal_x,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_left_end_wrapper,
                                    jump_surface_right_end_wrapper)
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
                            # Secondary jump/land pair: From the floor around the backside and top
                            # of the wall to the top end of the wall.
                            does_velocity_start_moving_leftward = is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = false
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            goal_x = \
                                    land_connected_region_left_bound - \
                                    character_half_width_horizontal_offset if \
                                    is_landing_on_left_wall else \
                                    land_connected_region_right_bound + \
                                    character_half_width_horizontal_offset
                            jump_position = _create_surface_interior_position(
                                    goal_x,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_left_end_wrapper,
                                    jump_surface_right_end_wrapper)
                            land_position = land_surface_top_end_wrapper
                            var less_likely_to_be_valid := true
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions,
                                    less_likely_to_be_valid,
                                    less_likely_to_be_valid)
                            
                        else:
                            # The wall is directly below the floor.
                            # 
                            # Primary jump/land pair: From the floor end in front of the wall into
                            # the wall.
                            does_velocity_start_moving_leftward = !is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = false
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            jump_position = \
                                    jump_surface_right_end_wrapper if \
                                    is_landing_on_left_wall else \
                                    jump_surface_left_end_wrapper
                            jump_basis = jump_position.target_point
                            land_basis = land_surface_bottom_end_wrapper.target_point
                            var vertical_movement_displacement := \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            var goal_y := \
                                    jump_basis.y + \
                                    vertical_movement_displacement
                            var fail_if_outside_of_bounds := true
                            land_position = _create_surface_interior_position(
                                    goal_y,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_top_end_wrapper,
                                    land_surface_bottom_end_wrapper,
                                    fail_if_outside_of_bounds)
                            if land_position != null:
                                jump_land_positions = _create_jump_land_positions(
                                        movement_params,
                                        jump_position,
                                        land_position,
                                        velocity_start,
                                        all_jump_land_positions)
                            
                            # Secondary jump/land pair: From the floor end behind the wall, around
                            # the underside of the floor, over the top end of the wall, and into
                            # the frontside of the wall.
                            does_velocity_start_moving_leftward = is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = false
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            jump_position = \
                                    jump_surface_left_end_wrapper if \
                                    is_landing_on_left_wall else \
                                    jump_surface_right_end_wrapper
                            land_position = land_surface_top_end_wrapper
                            var less_likely_to_be_valid := true
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions,
                                    less_likely_to_be_valid,
                                    less_likely_to_be_valid)
                        
                    else:
                        # We must jump around the backside of the wall (and of the entire connected
                        # region) before landing on the frontside of the wall.
                        # 
                        # - We consider up to two jump/land pairs:
                        #   - The primary pair corresponds to movement from the floor around the
                        #     top of the wall.
                        #   - The secondary pair corresponds to movement that would go between
                        #     surfaces:
                        #     - Either around the underside of the wall if the wall is higher,
                        #     - Or around the backside end of the floor around the top of the wall
                        #       if the wall is lower.
                        
                        var is_wall_below_floor := \
                                land_surface_top_bound >= jump_surface_center.y
                        does_velocity_start_moving_leftward = !is_landing_on_left_wall
                        prefer_velocity_start_zero_horizontal_speed = false
                        velocity_start = get_velocity_start(
                                movement_params,
                                jump_surface,
                                is_a_jump_calculator,
                                does_velocity_start_moving_leftward,
                                prefer_velocity_start_zero_horizontal_speed)
                        var needs_extra_jump_duration := true
                        var goal_y := \
                                land_surface_top_bound + \
                                vertical_offset_to_support_extra_movement_around_wall
                        land_position = _create_surface_interior_position(
                                goal_y,
                                land_surface,
                                movement_params.collider,
                                land_surface_top_end_wrapper,
                                land_surface_bottom_end_wrapper)
                        
                        if is_wall_below_floor:
                            # Since the wall is below the floor, we don't need to account for any
                            # offset due for horizontal movement as we're jumping downward past the
                            # edge of the floor.
                            jump_position = \
                                    jump_surface_right_end_wrapper if \
                                    is_landing_on_left_wall else \
                                    jump_surface_left_end_wrapper
                            var less_likely_to_be_valid := false
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions,
                                    needs_extra_jump_duration,
                                    less_likely_to_be_valid)
                            
                        else:
                            # Since the top of the wall is higher than the floor, we need to
                            # account for any horizontal displacement that would occur (when using
                            # max horizontal speed) while jumping upward to move around the top of
                            # the wall (and around the entire connected region, as well).
                            var goal_x := \
                                    land_connected_region_left_bound - \
                                    character_half_width_horizontal_offset if \
                                    is_landing_on_left_wall else \
                                    land_connected_region_right_bound + \
                                    character_half_width_horizontal_offset
                            land_basis = Vector2(
                                    goal_x,
                                    land_connected_region_top_bound)
                            jump_basis = Sc.geometry.project_shape_onto_surface(
                                    Vector2(goal_x, INF),
                                    movement_params.collider,
                                    jump_surface)
                            var must_reach_destination_on_fall := true
                            var must_reach_destination_on_rise := false
                            var horizontal_movement_distance := \
                                    _calculate_horizontal_movement_distance(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start,
                                            must_reach_destination_on_fall,
                                            must_reach_destination_on_rise)
                            goal_x = \
                                    jump_basis.x - horizontal_movement_distance if \
                                    is_landing_on_left_wall else \
                                    jump_basis.x + horizontal_movement_distance
                            jump_position = _create_surface_interior_position(
                                    goal_x,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_left_end_wrapper,
                                    jump_surface_right_end_wrapper)
                            var less_likely_to_be_valid := true
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions,
                                    needs_extra_jump_duration,
                                    less_likely_to_be_valid)
                            
                            # Also consider a version of this jump/land pair with zero horizontal
                            # start velocity.
                            does_velocity_start_moving_leftward = !is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = true
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            goal_x = \
                                    land_connected_region_left_bound - \
                                    character_half_width_horizontal_offset if \
                                    is_landing_on_left_wall else \
                                    land_connected_region_right_bound + \
                                    character_half_width_horizontal_offset
                            jump_position = _create_surface_interior_position(
                                    goal_x,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_left_end_wrapper,
                                    jump_surface_right_end_wrapper)
                            less_likely_to_be_valid = true
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions,
                                    needs_extra_jump_duration,
                                    less_likely_to_be_valid)
                        
                        if land_surface_top_bound > \
                                jump_surface_center.y + \
                                movement_params.collider.half_width_height.y * 2.5:
                            # The wall is far enough below the floor that the character might be able
                            # to jump around overtop it, so let's consider a secondary jump/land
                            # pair for that movement.
                            # 
                            # The more speed we have moving out over the floor end, the more we can
                            # have when we come back around underneath the floor end.
                            does_velocity_start_moving_leftward = is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = false
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            needs_extra_jump_duration = false
                            jump_position = \
                                    jump_surface_left_end_wrapper if \
                                    is_landing_on_left_wall else \
                                    jump_surface_right_end_wrapper
                            # Land position should be the same slightly-below-top-end point as used
                            # in the primary jump/land pair above.
                            land_position = land_position
                            var less_likely_to_be_valid := true
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions,
                                    needs_extra_jump_duration,
                                    less_likely_to_be_valid)
                            
                        elif land_surface_bottom_bound < \
                                jump_surface_center.y - \
                                movement_params.collider.half_width_height.y * 2.5:
                            # The wall is far enough above the floor that the character might be able
                            # to jump around underneath it, so let's consider a secondary jump/land
                            # pair for that movement.
                            does_velocity_start_moving_leftward = !is_landing_on_left_wall
                            prefer_velocity_start_zero_horizontal_speed = false
                            velocity_start = get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    prefer_velocity_start_zero_horizontal_speed)
                            needs_extra_jump_duration = false
                            jump_position = \
                                    jump_surface_right_end_wrapper if \
                                    is_landing_on_left_wall else \
                                    jump_surface_left_end_wrapper
                            goal_y = land_surface_bottom_bound
                            land_position = _create_surface_interior_position(
                                    goal_y,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_top_end_wrapper,
                                    land_surface_bottom_end_wrapper)
                            var less_likely_to_be_valid := true
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions,
                                    needs_extra_jump_duration,
                                    less_likely_to_be_valid)
                    
                SurfaceSide.CEILING:
                    # Jump from a floor, land on a ceiling.
                    # https://github.com/snoringcatgames/surfacer/tree/master/docs/jump-land-positions-floor-to-ceiling.png
                    
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
                            var velocity_start := get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    false)
                            
                            var min_movement_jump_land_positions := _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
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
                            #   character width or for edge movement) for any of the jump/land
                            #   positions.
                            # 
                            # TODO: We could also consider the same jump/land basis points, but
                            #       with max-speed start velocity (and then a horizontal offset for
                            #       the positions), but that's probably not useful for most cases.
                            
                            var left_end_displacement_x := \
                                    land_surface_left_bound - jump_surface_left_bound
                            var right_end_displacement_x := \
                                    land_surface_right_bound - jump_surface_right_bound
                            
                            var velocity_start := get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    false,
                                    true)
                            
                            var jump_position: PositionAlongSurface
                            var land_position: PositionAlongSurface
                            
                            # Consider the left ends.
                            if left_end_displacement_x > 0.0:
                                # J: floor-closest-point-to-ceiling-left-end
                                # L: ceiling-left-end
                                # V: zero
                                # O: none
                                jump_position = _create_surface_interior_position(
                                        land_surface_left_bound,
                                        jump_surface,
                                        movement_params.collider,
                                        jump_surface_left_end_wrapper,
                                        jump_surface_right_end_wrapper)
                                land_position = land_surface_left_end_wrapper
                            else:
                                # J: floor-left-end
                                # L: ceiling-closest-point-to-floor-left-end
                                # V: zero
                                # O: none
                                jump_position = jump_surface_left_end_wrapper
                                land_position = _create_surface_interior_position(
                                        jump_surface_left_bound,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_left_end_wrapper,
                                        land_surface_right_end_wrapper)
                            var left_end_jump_land_positions := _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
                            # Consider the right ends.
                            if right_end_displacement_x > 0.0:
                                # J: floor-right-end
                                # L: ceiling-closest-point-to-floor-right-end
                                # V: zero
                                # O: none
                                jump_position = jump_surface_right_end_wrapper
                                land_position = _create_surface_interior_position(
                                        jump_surface_right_bound,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_left_end_wrapper,
                                        land_surface_right_end_wrapper)
                            else:
                                # J: floor-closest-point-to-ceiling-right-end
                                # L: ceiling-right-end
                                # V: zero
                                # O: none
                                jump_position = _create_surface_interior_position(
                                        land_surface_right_bound,
                                        jump_surface,
                                        movement_params.collider,
                                        jump_surface_left_end_wrapper,
                                        jump_surface_right_end_wrapper)
                                land_position = land_surface_right_end_wrapper
                            var right_end_jump_land_positions := _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
                            # Consider the closest points.
                            var jump_surface_closest_point: Vector2 = \
                                    Sc.geometry.get_closest_point_on_polyline_to_polyline(
                                            jump_surface.vertices,
                                            land_surface.vertices)
                            var land_surface_closest_point: Vector2 = \
                                    Sc.geometry.get_closest_point_on_polyline_to_point(
                                            jump_surface_closest_point,
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
                                jump_position = PositionAlongSurfaceFactory \
                                        .create_position_offset_from_target_point(
                                                jump_surface_closest_point,
                                                jump_surface,
                                                movement_params.collider,
                                                true)
                                land_position = PositionAlongSurfaceFactory \
                                        .create_position_offset_from_target_point(
                                                land_surface_closest_point,
                                                land_surface,
                                                movement_params.collider,
                                                true)
                                var closest_point_jump_land_positions := \
                                        _create_jump_land_positions(
                                                movement_params,
                                                jump_position,
                                                land_position,
                                                velocity_start)
                                if closest_point_jump_land_positions != null:
                                    # This closest-points pair is actually probably the most
                                    # likely to produce the best edge, so insert it at the start
                                    # of the result collection.
                                    all_jump_land_positions.push_front(
                                            closest_point_jump_land_positions)
                        
                    else:
                        # Jumping from a higher floor to a lower ceiling.
                        
                        # Return no valid points, since we must move down, past
                        # the floor, and cannot then move back upward after
                        # starting the fall.
                        pass
                    
                _:
                    Sc.logger.error("Unknown land surface side (jump from floor)")
            
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_jumping_from_left_wall := \
                    jump_surface.side == SurfaceSide.LEFT_WALL
            
            var velocity_start := get_velocity_start(
                    movement_params,
                    jump_surface,
                    is_a_jump_calculator)
            
            match land_surface.side:
                SurfaceSide.FLOOR:
                    # Jump from a wall, land on a floor.
                    # https://github.com/snoringcatgames/surfacer/tree/master/docs/
                    #         jump-land-positions-wall-to-floor.png
                    
                    var is_wall_fully_higher_than_floor := \
                            jump_surface_bottom_bound < land_surface_center.y
                    var is_wall_fully_lower_than_floor := \
                            jump_surface_top_bound > land_surface_center.y
                    var is_floor_fully_in_front_of_wall := \
                            is_jumping_from_left_wall and \
                            jump_surface_center.x < land_surface_left_bound or \
                            !is_jumping_from_left_wall and \
                            jump_surface_center.x > land_surface_right_bound
                    
                    var jump_position: PositionAlongSurface
                    var land_position: PositionAlongSurface
                    var jump_land_positions: JumpLandPositions
                    
                    if is_wall_fully_higher_than_floor:
                        # The wall is fully higher than the floor.
                        # 
                        # Primary jump/land pair: From the bottom of the wall to the floor.
                        var is_there_room_to_land_in_front_of_wall := \
                                land_surface_right_bound > \
                                jump_surface_center.x + character_half_width_horizontal_offset if \
                                is_jumping_from_left_wall else \
                                land_surface_left_bound < \
                                jump_surface_center.x - character_half_width_horizontal_offset
                        if is_there_room_to_land_in_front_of_wall:
                            # There is room to land on the floor in front of the wall.
                            var jump_basis := jump_surface_bottom_end_wrapper.target_point
                            var goal_x := \
                                    jump_surface_bottom_end.x + \
                                    character_half_width_horizontal_offset if \
                                    is_jumping_from_left_wall else \
                                    jump_surface_bottom_end.x - \
                                    character_half_width_horizontal_offset
                            var land_basis: Vector2 = \
                                    Sc.geometry.project_shape_onto_surface(
                                            Vector2(goal_x, INF),
                                            movement_params.collider,
                                            land_surface)
                            var must_reach_destination_on_fall := true
                            var must_reach_destination_on_rise := false
                            var horizontal_movement_distance := \
                                    _calculate_horizontal_movement_distance(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start,
                                            must_reach_destination_on_fall,
                                            must_reach_destination_on_rise)
                            goal_x = \
                                    jump_basis.x + horizontal_movement_distance if \
                                    is_jumping_from_left_wall else \
                                    jump_basis.x - horizontal_movement_distance
                            land_position = _create_surface_interior_position(
                                    goal_x,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_left_end_wrapper,
                                    land_surface_right_end_wrapper)
                            land_basis = land_position.target_point
                            var vertical_movement_displacement := \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            var goal_y := \
                                    land_basis.y - \
                                    vertical_movement_displacement
                            var fail_if_outside_of_bounds := true
                            jump_position = _create_surface_interior_position(
                                    goal_y,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_top_end_wrapper,
                                    jump_surface_bottom_end_wrapper,
                                    fail_if_outside_of_bounds)
                            if jump_position != null:
                                jump_land_positions = _create_jump_land_positions(
                                        movement_params,
                                        jump_position,
                                        land_position,
                                        velocity_start,
                                        all_jump_land_positions)
                        else:
                            # There is not room to land on the floor in front of the wall.
                            # 
                            # That means that we need to move back around underneath the wall in
                            # order to land on the floor.
                            jump_position = jump_surface_bottom_end_wrapper
                            land_position = \
                                    land_surface_right_end_wrapper if \
                                    is_jumping_from_left_wall else \
                                    land_surface_left_end_wrapper
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                        
                        # Secondary jump/land pair: From the top of the wall, around behind the
                        # wall, to the floor.
                        var is_there_room_to_land_behind_wall := \
                                jump_connected_region_left_bound >= \
                                land_surface_left_bound if \
                                is_jumping_from_left_wall else \
                                jump_connected_region_right_bound <= \
                                land_surface_right_bound
                        if is_there_room_to_land_behind_wall:
                            jump_position = jump_surface_top_end_wrapper
                            var goal_x := \
                                    jump_connected_region_left_bound - \
                                    character_half_width_horizontal_offset if \
                                    is_jumping_from_left_wall else \
                                    jump_connected_region_right_bound + \
                                    character_half_width_horizontal_offset
                            land_position = _create_surface_interior_position(
                                    goal_x,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_left_end_wrapper,
                                    land_surface_right_end_wrapper)
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                        
                    elif is_wall_fully_lower_than_floor:
                        # The wall is fully lower than the floor.
                        var do_surfaces_overlap_horizontally := \
                                jump_surface_center.x >= land_surface_left_bound and \
                                jump_surface_center.x <= land_surface_right_bound
                        if do_surfaces_overlap_horizontally:
                            land_position = \
                                    land_surface_right_end_wrapper if \
                                    is_jumping_from_left_wall else \
                                    land_surface_left_end_wrapper
                            # Because we could hit the underside of the floor before getting around
                            # the end, we need to consider the vertical displacement that's needed
                            # in order to movement horizontally around the end.
                            var jump_basis := jump_surface_bottom_end_wrapper.target_point
                            var land_basis := land_position.target_point
                            var vertical_movement_displacement := \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            var goal_y := \
                                    land_basis.y - \
                                    vertical_movement_displacement + \
                                    vertical_offset_to_support_extra_movement_around_wall
                            jump_position = _create_surface_interior_position(
                                    goal_y,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_top_end_wrapper,
                                    jump_surface_bottom_end_wrapper,
                                    true)
                            if jump_position != null:
                                # There is enough length along the jump surface to support jumping
                                # from a low enough position to reach the vertical displacement.
                                jump_land_positions = _create_jump_land_positions(
                                        movement_params,
                                        jump_position,
                                        land_position,
                                        velocity_start,
                                        all_jump_land_positions)
                        else:
                            jump_position = jump_surface_top_end_wrapper
                            land_position = land_surface_near_end_wrapper
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                        
                    elif is_floor_fully_in_front_of_wall:
                        # The floor is fully in front of the wall.
                        var jump_basis: Vector2 = Sc.geometry.project_shape_onto_surface(
                                land_surface_near_end,
                                movement_params.collider,
                                jump_surface)
                        var land_basis := land_surface_near_end_wrapper.target_point
                        var must_reach_destination_on_fall := true
                        var must_reach_destination_on_rise := false
                        var horizontal_movement_distance := \
                                _calculate_horizontal_movement_distance(
                                        movement_params,
                                        jump_basis,
                                        land_basis,
                                        velocity_start,
                                        can_hold_jump_button_at_start,
                                        must_reach_destination_on_fall,
                                        must_reach_destination_on_rise)
                        var goal_x := \
                                jump_basis.x + horizontal_movement_distance if \
                                is_jumping_from_left_wall else \
                                jump_basis.x - horizontal_movement_distance
                        land_position = _create_surface_interior_position(
                                goal_x,
                                land_surface,
                                movement_params.collider,
                                land_surface_left_end_wrapper,
                                land_surface_right_end_wrapper)
                        land_basis = land_position.target_point
                        var vertical_movement_displacement := \
                                _calculate_vertical_movement_displacement(
                                        movement_params,
                                        jump_basis,
                                        land_basis,
                                        velocity_start,
                                        can_hold_jump_button_at_start)
                        var goal_y := \
                                land_basis.y - \
                                vertical_movement_displacement
                        var fail_if_outside_of_bounds := true
                        jump_position = _create_surface_interior_position(
                                goal_y,
                                jump_surface,
                                movement_params.collider,
                                jump_surface_top_end_wrapper,
                                jump_surface_bottom_end_wrapper,
                                fail_if_outside_of_bounds)
                        if jump_position != null:
                            jump_land_positions = _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                        
                    else:
                        # The floor is fully behind the wall.
                        jump_position = jump_surface_top_end_wrapper
                        land_position = land_surface_near_end_wrapper
                        jump_land_positions = _create_jump_land_positions(
                                movement_params,
                                jump_position,
                                land_position,
                                velocity_start,
                                all_jump_land_positions)
                    
                SurfaceSide.LEFT_WALL, \
                SurfaceSide.RIGHT_WALL:
                    # Jump from a wall, land on a wall.
                    # https://github.com/snoringcatgames/surfacer/tree/master/docs/
                    #         jump-land-positions-wall-to-same-wall.png
                    # https://github.com/snoringcatgames/surfacer/tree/master/docs/
                    #         jump-land-positions-wall-to-opposite-wall.png
                    
                    var top_end_displacement_y := \
                            land_surface_top_bound - jump_surface_top_bound
                    var bottom_end_displacement_y := \
                            land_surface_bottom_bound - jump_surface_bottom_bound
                    
                    var do_surfaces_overlap_vertically := \
                            jump_surface_top_bound < land_surface_bottom_bound and \
                            jump_surface_bottom_bound > land_surface_top_bound
                    
                    var are_walls_facing_each_other := \
                            is_jump_surface_more_to_the_left and is_jumping_from_left_wall or \
                            !is_jump_surface_more_to_the_left and !is_jumping_from_left_wall
                    
                    if jump_surface.side == land_surface.side:
                        # Jump between walls of the same side.
                        # https://github.com/snoringcatgames/surfacer/tree/master/
                        #        docs/jump-land-positions-wall-to-same-wall.png
                        # 
                        # This means that we must go around one end of one of the walls.
                        # - Which wall depends on which wall is in front.
                        # - Which end depends on which wall is higher.
                        
                        var is_jump_surface_in_front := \
                                is_jump_surface_more_to_the_left and \
                                        !is_jumping_from_left_wall or \
                                !is_jump_surface_more_to_the_left and \
                                        is_jumping_from_left_wall
                        
                        var jump_position: PositionAlongSurface
                        var land_position: PositionAlongSurface
                        var jump_land_positions: JumpLandPositions
                        var jump_basis: Vector2
                        var land_basis: Vector2
                        var vertical_movement_displacement: float
                        var goal_y: float
                        
                        if is_jump_surface_in_front:
                            # Jump surface is in front.
                            jump_position = jump_surface_top_end_wrapper
                            jump_basis = jump_position.target_point
                            land_basis = Sc.geometry.project_shape_onto_surface(
                                    jump_surface_top_end,
                                    movement_params.collider,
                                    land_surface)
                            vertical_movement_displacement = \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            goal_y = \
                                    jump_basis.y + \
                                    vertical_movement_displacement + \
                                    vertical_offset_to_support_extra_movement_around_wall
                            land_position = _create_surface_interior_position(
                                    goal_y,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_top_end_wrapper,
                                    land_surface_bottom_end_wrapper,
                                    true)
                            if land_position != null:
                                # There is enough length along the land surface to support landing
                                # on a low enough position to reach the vertical displacement.
                                jump_land_positions = _create_jump_land_positions(
                                        movement_params,
                                        jump_position,
                                        land_position,
                                        velocity_start,
                                        all_jump_land_positions)
                            
                            if bottom_end_displacement_y > 0.0:
                                # The bottom end of the jump surface is higher than the bottom end
                                # of the land surface. It might be possible for movement to go
                                # around the underside of the jump surface, so we consider that
                                # extra jump/land pair here.
                                jump_position = jump_surface_bottom_end_wrapper
                                jump_basis = jump_surface_bottom_end_wrapper.target_point
                                land_basis = Sc.geometry.project_shape_onto_surface(
                                        jump_surface_bottom_end,
                                        movement_params.collider,
                                        land_surface)
                                vertical_movement_displacement = \
                                        _calculate_vertical_movement_displacement(
                                                movement_params,
                                                jump_basis,
                                                land_basis,
                                                velocity_start,
                                                can_hold_jump_button_at_start)
                                goal_y = \
                                        jump_surface_bottom_bound + \
                                        vertical_movement_displacement + \
                                        vertical_offset_to_support_extra_movement_around_wall
                                land_position = _create_surface_interior_position(
                                        goal_y,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_top_end_wrapper,
                                        land_surface_bottom_end_wrapper,
                                        true)
                                if land_position != null:
                                    # There is enough length along the land surface to support
                                    # landing on a low enough position to reach the vertical
                                    # displacement.
                                    jump_land_positions = _create_jump_land_positions(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start,
                                            all_jump_land_positions)
                            
                        else:
                            # Jump surface is behind.
                            var needs_extra_jump_duration := true
                            goal_y = \
                                    land_surface_top_bound + \
                                    vertical_offset_to_support_extra_movement_around_wall
                            land_position = _create_surface_interior_position(
                                    goal_y,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_top_end_wrapper,
                                    land_surface_bottom_end_wrapper,
                                    false)
                            jump_basis = Sc.geometry.project_shape_onto_surface(
                                    land_surface_top_end,
                                    movement_params.collider,
                                    jump_surface)
                            land_basis = land_surface_top_end_wrapper.target_point
                            vertical_movement_displacement = \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            goal_y = \
                                    land_position.target_point.y - \
                                    vertical_movement_displacement
                            jump_position = _create_surface_interior_position(
                                    goal_y,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_top_end_wrapper,
                                    jump_surface_bottom_end_wrapper,
                                    true)
                            if jump_position != null:
                                # There is enough length along the jump surface to support jumping
                                # from a high enough position to reach the vertical displacement.
                                jump_land_positions = \
                                        _create_jump_land_positions(
                                                movement_params,
                                                jump_position,
                                                land_position,
                                                velocity_start,
                                                all_jump_land_positions,
                                                needs_extra_jump_duration)
                            
                            if bottom_end_displacement_y < 0.0:
                                # The bottom end of the jump surface is lower than the bottom end
                                # of the land surface. It might be possible for movement to go
                                # around the underside of the land surface, so we consider that
                                # extra jump/land pair here.
                                needs_extra_jump_duration = false
                                land_position = land_surface_bottom_end_wrapper
                                jump_basis = Sc.geometry.project_shape_onto_surface(
                                        land_surface_bottom_end,
                                        movement_params.collider,
                                        jump_surface)
                                land_basis = land_position.target_point
                                var displacement := land_basis - jump_basis
                                var acceleration_x := \
                                        movement_params.in_air_horizontal_acceleration if \
                                        displacement.x > 0.0 else \
                                        -movement_params.in_air_horizontal_acceleration
                                var duration: float = \
                                        MovementUtils.calculate_duration_for_displacement(
                                                displacement.x,
                                                velocity_start.x,
                                                acceleration_x,
                                                movement_params.max_horizontal_speed_default)
                                assert(!is_inf(duration))
                                if duration < movement_params.time_to_max_upward_jump_distance:
                                    # We can reach the land position on the rise of the jump.
                                    vertical_movement_displacement = VerticalMovementUtils \
                                            .calculate_vertical_displacement_from_duration_with_max_slow_rise_gravity(
                                                    movement_params,
                                                    duration,
                                                    velocity_start.y)
                                    goal_y = \
                                            land_surface_bottom_bound - \
                                            vertical_movement_displacement + \
                                            vertical_offset_to_support_extra_movement_around_wall
                                    jump_position = _create_surface_interior_position(
                                            goal_y,
                                            jump_surface,
                                            movement_params.collider,
                                            jump_surface_top_end_wrapper,
                                            jump_surface_bottom_end_wrapper,
                                            true)
                                    if jump_position != null:
                                        # There is enough length along the jump surface to support jumping
                                        # from a low enough position to reach the vertical displacement.
                                        jump_land_positions = \
                                                _create_jump_land_positions(
                                                        movement_params,
                                                        jump_position,
                                                        land_position,
                                                        velocity_start,
                                                        all_jump_land_positions,
                                                        needs_extra_jump_duration)
                        
                    elif are_walls_facing_each_other:
                        # Jump between two walls that are facing each other.
                        # https://github.com/snoringcatgames/surfacer/tree/master/
                        #    docs/jump-land-positions-wall-to-opposite-wall.png
                        
                        var jump_basis: Vector2
                        var land_basis: Vector2
                        
                        if top_end_displacement_y > 0.0:
                            # Jump-surface top-end is higher than land-surface top-end.
                            jump_basis = Sc.geometry.project_shape_onto_surface(
                                    land_surface_top_end,
                                    movement_params.collider,
                                    jump_surface)
                            land_basis = land_surface_top_end_wrapper.target_point
                        else:
                            # Jump-surface top-end is lower than land-surface top-end.
                            jump_basis = jump_surface_top_end_wrapper.target_point
                            land_basis = Sc.geometry.project_shape_onto_surface(
                                    jump_surface_top_end,
                                    movement_params.collider,
                                    land_surface)
                        var top_end_jump_land_positions := \
                                _calculate_jump_land_points_for_walls_facing_each_other(
                                        movement_params,
                                        all_jump_land_positions,
                                        false,
                                        jump_basis,
                                        land_basis,
                                        velocity_start,
                                        can_hold_jump_button_at_start,
                                        jump_surface,
                                        jump_surface_top_end_wrapper,
                                        jump_surface_bottom_end_wrapper,
                                        land_surface,
                                        land_surface_top_end_wrapper,
                                        land_surface_bottom_end_wrapper)
                        
                        # Considering bottom-end case.
                        if bottom_end_displacement_y > 0.0:
                            # Jump-surface bottom-end is higher than land-surface bottom-end.
                            jump_basis = jump_surface_bottom_end_wrapper.target_point
                            land_basis = Sc.geometry.project_shape_onto_surface(
                                    jump_surface_bottom_end,
                                    movement_params.collider,
                                    land_surface)
                        else:
                            # Jump-surface bottom-end is lower than land-surface bottom-end.
                            jump_basis = Sc.geometry.project_shape_onto_surface(
                                    land_surface_bottom_end,
                                    movement_params.collider,
                                    jump_surface)
                            land_basis = land_surface_bottom_end_wrapper.target_point
                        var bottom_end_jump_land_positions := \
                                _calculate_jump_land_points_for_walls_facing_each_other(
                                        movement_params,
                                        all_jump_land_positions,
                                        false,
                                        jump_basis,
                                        land_basis,
                                        velocity_start,
                                        can_hold_jump_button_at_start,
                                        jump_surface,
                                        jump_surface_top_end_wrapper,
                                        jump_surface_bottom_end_wrapper,
                                        land_surface,
                                        land_surface_top_end_wrapper,
                                        land_surface_bottom_end_wrapper,
                                        top_end_jump_land_positions)
                        
                        # Considering closest-points case.
                        jump_basis = Sc.geometry.get_closest_point_on_polyline_to_polyline(
                                jump_surface.vertices,
                                land_surface.vertices)
                        jump_basis = Sc.geometry.project_shape_onto_surface(
                                jump_basis,
                                movement_params.collider,
                                jump_surface)
                        land_basis = Sc.geometry.get_closest_point_on_polyline_to_point(
                                land_basis,
                                land_surface.vertices)
                        land_basis = Sc.geometry.project_shape_onto_surface(
                                land_basis,
                                movement_params.collider,
                                land_surface)
                        var closest_points_jump_land_positions := \
                                _calculate_jump_land_points_for_walls_facing_each_other(
                                        movement_params,
                                        all_jump_land_positions,
                                        true,
                                        jump_basis,
                                        land_basis,
                                        velocity_start,
                                        can_hold_jump_button_at_start,
                                        jump_surface,
                                        jump_surface_top_end_wrapper,
                                        jump_surface_bottom_end_wrapper,
                                        land_surface,
                                        land_surface_top_end_wrapper,
                                        land_surface_bottom_end_wrapper,
                                        top_end_jump_land_positions,
                                        bottom_end_jump_land_positions)
                        
                    else:
                        # Jump between two walls that are facing away from each other.
                        # https://github.com/snoringcatgames/surfacer/tree/master/docs/jump-land-positions-wall-to-opposite-wall.png
                        
                        # Consider one pair for the top ends.
                        var needs_extra_jump_duration := true
                        var jump_position := jump_surface_top_end_wrapper
                        var land_position := _create_surface_interior_position(
                                land_surface_top_end.y + \
                                        vertical_offset_to_support_extra_movement_around_wall,
                                land_surface,
                                movement_params.collider,
                                land_surface_top_end_wrapper,
                                land_surface_bottom_end_wrapper)
                        var top_ends_jump_land_positions := _create_jump_land_positions(
                                movement_params,
                                jump_position,
                                land_position,
                                velocity_start,
                                all_jump_land_positions,
                                needs_extra_jump_duration)
                        
                        if !do_surfaces_overlap_vertically:
                            # When the surfaces don't overlap vertically, it might be possible
                            # for movement to go horizontally between the two surfaces, so we
                            # consider that extra jump/land pair here.
                            needs_extra_jump_duration = false
                            if is_jump_surface_lower:
                                jump_position = jump_surface_top_end_wrapper
                                land_position = land_surface_bottom_end_wrapper
                            else:
                                jump_position = jump_surface_bottom_end_wrapper
                                land_position = _create_surface_interior_position(
                                        land_surface_top_end.y + \
                                                vertical_offset_to_support_extra_movement_around_wall,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_top_end_wrapper,
                                        land_surface_bottom_end_wrapper)
                            var between_surfaces_jump_land_positions := \
                                    _create_jump_land_positions(
                                            movement_params,
                                            jump_position,
                                            land_position,
                                            velocity_start,
                                            all_jump_land_positions,
                                            needs_extra_jump_duration)
                    
                SurfaceSide.CEILING:
                    # Jump from a wall, land on a ceiling.
                    
                    var is_wall_fully_higher_than_ceiling := \
                            jump_surface_bottom_bound < land_surface_center.y
                    var is_wall_fully_lower_than_ceiling := \
                            jump_surface_top_bound > land_surface_center.y
                    var is_ceiling_fully_in_front_of_wall := \
                            is_jumping_from_left_wall and \
                            jump_surface_center.x < land_surface_left_bound or \
                            !is_jumping_from_left_wall and \
                            jump_surface_center.x > land_surface_right_bound
                    
                    var is_there_room_to_land_in_front_of_wall := \
                            land_surface_right_bound > \
                            jump_surface_center.x + character_half_width_horizontal_offset if \
                            is_jumping_from_left_wall else \
                            land_surface_left_bound < \
                            jump_surface_center.x - character_half_width_horizontal_offset
                    
                    if !is_wall_fully_higher_than_ceiling:
                        if is_there_room_to_land_in_front_of_wall:
                            # There is room to land on the ceiling in front of the wall.
                            
                            var jump_basis: Vector2
                            if is_wall_fully_lower_than_ceiling:
                                jump_basis = jump_surface_top_end_wrapper.target_point
                            else:
                                jump_basis = Sc.geometry.project_shape_onto_surface(
                                        Vector2(INF, land_surface_near_end_wrapper.target_point.y),
                                        movement_params.collider,
                                        jump_surface)
                            
                            var goal_x := jump_basis.x
                            var land_basis: Vector2 = \
                                    Sc.geometry.project_shape_onto_surface(
                                            Vector2(goal_x, INF),
                                            movement_params.collider,
                                            land_surface)
                            var must_reach_destination_on_fall := false
                            var must_reach_destination_on_rise := true
                            var horizontal_movement_distance := \
                                    _calculate_horizontal_movement_distance(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start,
                                            must_reach_destination_on_fall,
                                            must_reach_destination_on_rise)
                            goal_x = \
                                    jump_basis.x + horizontal_movement_distance if \
                                    is_jumping_from_left_wall else \
                                    jump_basis.x - horizontal_movement_distance
                            var land_position := _create_surface_interior_position(
                                    goal_x,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_left_end_wrapper,
                                    land_surface_right_end_wrapper)
                            land_basis = land_position.target_point
                            var vertical_movement_displacement := \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            var goal_y := \
                                    land_basis.y - \
                                    vertical_movement_displacement
                            var fail_if_outside_of_bounds := true
                            var jump_position := _create_surface_interior_position(
                                    goal_y,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_top_end_wrapper,
                                    jump_surface_bottom_end_wrapper,
                                    fail_if_outside_of_bounds)
                            if jump_position != null:
                                var jump_land_positions := _create_jump_land_positions(
                                        movement_params,
                                        jump_position,
                                        land_position,
                                        velocity_start,
                                        all_jump_land_positions)
                            
                        elif is_wall_fully_lower_than_ceiling:
                            # There is not room to land on the ceiling in front of the wall.
                            # 
                            # That means that we need to move back around over the wall in
                            # order to land on the ceiling.
                            
                            var land_position := \
                                    land_surface_right_end_wrapper if \
                                    is_jumping_from_left_wall else \
                                    land_surface_left_end_wrapper
                            var jump_basis := jump_surface_top_end_wrapper.target_point
                            var land_basis := land_position.target_point
                            var vertical_movement_displacement := \
                                    _calculate_vertical_movement_displacement(
                                            movement_params,
                                            jump_basis,
                                            land_basis,
                                            velocity_start,
                                            can_hold_jump_button_at_start)
                            var goal_y := \
                                    land_basis.y - \
                                    vertical_movement_displacement
                            var fail_if_outside_of_bounds := true
                            var jump_position := _create_surface_interior_position(
                                    goal_y,
                                    jump_surface,
                                    movement_params.collider,
                                    jump_surface_top_end_wrapper,
                                    jump_surface_bottom_end_wrapper,
                                    fail_if_outside_of_bounds)
                            if jump_position != null:
                                var jump_land_positions := _create_jump_land_positions(
                                        movement_params,
                                        jump_position,
                                        land_position,
                                        velocity_start,
                                        all_jump_land_positions)
                            
                        else:
                            # The ceiling is behind and not above the wall.
                            
                            # Return no valid points, since we cannot reach it.
                            pass
                        
                    else:
                        # Jumping from a higher wall to a lower ceiling.
                        
                        # Return no valid points, since we cannot move upward
                        # after descending down to the ceiling.
                        pass
                    
                _:
                    Sc.logger.error("Unknown land surface side (jump from wall)")
            
        SurfaceSide.CEILING:
            match land_surface.side:
                SurfaceSide.FLOOR:
                    # Jump from a ceiling, land on a floor.
                    # Similar to:
                    # https://github.com/snoringcatgames/surfacer/tree/master/docs/jump-land-positions-floor-to-ceiling.png
                    
                    if is_jump_surface_higher:
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
                            var velocity_start := get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    does_velocity_start_moving_leftward,
                                    false)
                            
                            var min_movement_jump_land_positions := _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
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
                            #   character width or for edge movement) for any of the jump/land
                            #   positions.
                            # 
                            # TODO: We could also consider the same jump/land basis points, but
                            #       with max-speed start velocity (and then a horizontal offset for
                            #       the positions), but that's probably not useful for most cases.
                            
                            var left_end_displacement_x := \
                                    land_surface_left_bound - jump_surface_left_bound
                            var right_end_displacement_x := \
                                    land_surface_right_bound - jump_surface_right_bound
                            
                            var velocity_start := get_velocity_start(
                                    movement_params,
                                    jump_surface,
                                    is_a_jump_calculator,
                                    false,
                                    true)
                            
                            var jump_position: PositionAlongSurface
                            var land_position: PositionAlongSurface
                            
                            # Consider the left ends.
                            if left_end_displacement_x > 0.0:
                                # J: floor-closest-point-to-ceiling-left-end
                                # L: ceiling-left-end
                                # V: zero
                                # O: none
                                jump_position = _create_surface_interior_position(
                                        land_surface_left_bound,
                                        jump_surface,
                                        movement_params.collider,
                                        jump_surface_left_end_wrapper,
                                        jump_surface_right_end_wrapper)
                                land_position = land_surface_left_end_wrapper
                            else:
                                # J: floor-left-end
                                # L: ceiling-closest-point-to-floor-left-end
                                # V: zero
                                # O: none
                                jump_position = jump_surface_left_end_wrapper
                                land_position = _create_surface_interior_position(
                                        jump_surface_left_bound,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_left_end_wrapper,
                                        land_surface_right_end_wrapper)
                            var left_end_jump_land_positions := _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
                            # Consider the right ends.
                            if right_end_displacement_x > 0.0:
                                # J: floor-right-end
                                # L: ceiling-closest-point-to-floor-right-end
                                # V: zero
                                # O: none
                                jump_position = jump_surface_right_end_wrapper
                                land_position = _create_surface_interior_position(
                                        jump_surface_right_bound,
                                        land_surface,
                                        movement_params.collider,
                                        land_surface_left_end_wrapper,
                                        land_surface_right_end_wrapper)
                            else:
                                # J: floor-closest-point-to-ceiling-right-end
                                # L: ceiling-right-end
                                # V: zero
                                # O: none
                                jump_position = _create_surface_interior_position(
                                        land_surface_right_bound,
                                        jump_surface,
                                        movement_params.collider,
                                        jump_surface_left_end_wrapper,
                                        jump_surface_right_end_wrapper)
                                land_position = land_surface_right_end_wrapper
                            var right_end_jump_land_positions := _create_jump_land_positions(
                                    movement_params,
                                    jump_position,
                                    land_position,
                                    velocity_start,
                                    all_jump_land_positions)
                            
                            # Consider the closest points.
                            var jump_surface_closest_point: Vector2 = \
                                    Sc.geometry.get_closest_point_on_polyline_to_polyline(
                                            jump_surface.vertices,
                                            land_surface.vertices)
                            var land_surface_closest_point: Vector2 = \
                                    Sc.geometry.get_closest_point_on_polyline_to_point(
                                            jump_surface_closest_point,
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
                                jump_position = PositionAlongSurfaceFactory \
                                        .create_position_offset_from_target_point(
                                                jump_surface_closest_point,
                                                jump_surface,
                                                movement_params.collider,
                                                true)
                                land_position = PositionAlongSurfaceFactory \
                                        .create_position_offset_from_target_point(
                                                land_surface_closest_point,
                                                land_surface,
                                                movement_params.collider,
                                                true)
                                var closest_point_jump_land_positions := \
                                        _create_jump_land_positions(
                                                movement_params,
                                                jump_position,
                                                land_position,
                                                velocity_start)
                                if closest_point_jump_land_positions != null:
                                    # This closest-points pair is actually probably the most
                                    # likely to produce the best edge, so insert it at the start
                                    # of the result collection.
                                    all_jump_land_positions.push_front(
                                            closest_point_jump_land_positions)
                        
                    else:
                        # Jumping from a lower ceiling to a higher floor.
                        
                        # Return no valid points, since we cannot move upward.
                        pass
                    
                SurfaceSide.LEFT_WALL, \
                SurfaceSide.RIGHT_WALL:
                    # Jump from a ceiling, land on a wall.
                    
                    var is_landing_on_left_wall := \
                            land_surface.side == SurfaceSide.LEFT_WALL
                    var is_wall_fully_higher_than_ceiling := \
                            jump_surface_center.y > land_surface_bottom_bound
                    var is_wall_fully_lower_than_ceiling := \
                            jump_surface_center.y < land_surface_top_bound
                    var is_ceiling_fully_in_front_of_wall := \
                            is_landing_on_left_wall and \
                            jump_surface_left_bound > land_surface_center.x or \
                            !is_landing_on_left_wall and \
                            jump_surface_right_bound < land_surface_center.x
                    
                    if is_wall_fully_lower_than_ceiling or \
                            !is_wall_fully_higher_than_ceiling and \
                                    is_ceiling_fully_in_front_of_wall:
                        # The ceiling isn't either fully below of fully behind
                        # the wall.
                        
                        # - There is only one likely position pair we consider:
                        #   - The closest position along the ceiling, and the bottom of the
                        #     wall.
                        # - We only consider start velocity with zero horizontal speed.
                        # - Since we only consider start velocity of zero, we don't care about
                        #   whether velocity would need to start moving leftward or rightward.
                        # - We don't need to include any horizontal offsets (to account for
                        #   character width or for edge movement) for any of the jump/land
                        #   positions.
                        
                        var velocity_start := get_velocity_start(
                                movement_params,
                                jump_surface,
                                is_a_jump_calculator,
                                false,
                                true)
                        
                        # J: ceiling-closest-point-to-wall-bottom-end
                        # L: wall-bottom-end
                        # V: zero
                        # O: none
                        var jump_position := _create_surface_interior_position(
                                land_surface_bottom_end_wrapper.target_point.x,
                                jump_surface,
                                movement_params.collider,
                                jump_surface_left_end_wrapper,
                                jump_surface_right_end_wrapper)
                        var land_position := land_surface_bottom_end_wrapper
                        var jump_land_positions := _create_jump_land_positions(
                                movement_params,
                                jump_position,
                                land_position,
                                velocity_start,
                                all_jump_land_positions)
                        
                    else:
                        # Jumping from a lower ceiling to a higher wall.
                        
                        # Return no valid points, since we cannot move upward.
                        pass
                    
                SurfaceSide.CEILING:
                    # Jump from a ceiling, land on a ceiling.
                    
                    # Return no valid points, since we must move down, away
                    # from the first ceiling, and cannot then move back upward
                    # after starting the fall.
                    pass
                    
                _:
                    Sc.logger.error("Unknown land surface side (jump from ceiling)")
            
        _:
            Sc.logger.error("Unknown jump surface side")
    
    if movement_params.always_includes_jump_land_positions_at_surface_ends:
        # Record jump/land position combinations for the surface-end points.
        # 
        # The surface-end points aren't usually as efficient, or as likely to
        # produce valid edges, as the more intelligent surface-interior-point
        # calculations above. Also, one of the surface-interior point
        # calculations should almost always cover any surface-end-point edge
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
                        land_surface_end_position \
                                .target_projection_onto_surface.x - \
                        jump_surface_end_position \
                                .target_projection_onto_surface.x < 0.0
                var prefer_zero_horizontal_speed := true
                var velocity_start_zero := get_velocity_start(
                        movement_params,
                        jump_surface,
                        is_a_jump_calculator,
                        does_velocity_start_moving_leftward,
                        prefer_zero_horizontal_speed)
                var jump_land_positions := _create_jump_land_positions(
                        movement_params,
                        jump_surface_end_position,
                        land_surface_end_position,
                        velocity_start_zero,
                        all_jump_land_positions)
    
    # If either surface has only one point, then it might be possible that we
    # added a duplicate result.
    if jump_surface_has_only_one_point or \
            land_surface_has_only_one_point:
        var i := 0
        while i < all_jump_land_positions.size() - 1:
            var j := i + 1
            while j < all_jump_land_positions.size():
                var jump_land_positions1: JumpLandPositions = \
                        all_jump_land_positions[i]
                var jump_land_positions2: JumpLandPositions = \
                        all_jump_land_positions[j]
                if jump_land_positions1.jump_position == \
                        jump_land_positions2.jump_position and \
                        jump_land_positions1.land_position == \
                        jump_land_positions2.land_position and \
                        jump_land_positions1.velocity_start == \
                        jump_land_positions2.velocity_start:
                    all_jump_land_positions.remove(j)
                    j -= 1
                    # FIXME: LEFT OFF HERE: ------ If this never happens, maybe remove it?
#                    Sc.logger.error()
                j += 1
            i += 1
    
    return all_jump_land_positions


static func calculate_land_positions_on_surface(
        movement_params: MovementParameters,
        land_surface: Surface,
        origin_position: PositionAlongSurface,
        velocity_start: Vector2,
        can_hold_jump_button_at_start: bool) -> Array:
    var land_surface_first_point_wrapper: PositionAlongSurface = \
            PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            land_surface.first_point,
                            land_surface,
                            movement_params.collider)
    
    if land_surface.vertices.size() == 1:
        # The land surface consists of only a single point.
        var jump_land_positions := _create_jump_land_positions(
                movement_params,
                origin_position,
                land_surface_first_point_wrapper,
                velocity_start,
                null,
                false,
                false,
                true,
                false)
        return [jump_land_positions] if \
                jump_land_positions != null else \
                []
    
    var land_surface_last_point_wrapper: PositionAlongSurface = \
            PositionAlongSurfaceFactory \
                    .create_position_offset_from_target_point(
                            land_surface.last_point,
                            land_surface,
                            movement_params.collider)
    
    var land_surface_left_bound := land_surface.bounding_box.position.x
    var land_surface_right_bound := land_surface.bounding_box.end.x
    var land_surface_top_bound := land_surface.bounding_box.position.y
    var land_surface_bottom_bound := land_surface.bounding_box.end.y
    var land_surface_center := land_surface.center
    
    var origin_target_point := origin_position.target_point
    
    match land_surface.side:
        SurfaceSide.FLOOR:
            var land_surface_left_end_wrapper := \
                    land_surface_first_point_wrapper
            var land_surface_right_end_wrapper := \
                    land_surface_last_point_wrapper
            var is_below_floor := origin_target_point.y > land_surface_center.y
            
            if is_below_floor and velocity_start.y > 0.0:
                # We cannot reach the floor.
                return []
                
            else:
                # We may be able to reach the floor.
                var result := []
                var land_basis: Vector2 = \
                        Sc.geometry.project_shape_onto_surface(
                                origin_target_point,
                                movement_params.collider,
                                land_surface)
                var must_reach_destination_on_fall := true
                var must_reach_destination_on_rise := false
                
                var can_reach_vertical_displacement := VerticalMovementUtils \
                        .check_can_reach_vertical_displacement(
                                movement_params,
                                origin_target_point,
                                land_basis,
                                velocity_start,
                                can_hold_jump_button_at_start)
                if !can_reach_vertical_displacement:
                    return result
                
                var land_position_with_horizontal_movement_distance: \
                        PositionAlongSurface
                if velocity_start.x != 0.0:
                    var horizontal_movement_distance := \
                            _calculate_horizontal_movement_distance(
                                    movement_params,
                                    origin_target_point,
                                    land_basis,
                                    velocity_start,
                                    can_hold_jump_button_at_start,
                                    must_reach_destination_on_fall,
                                    must_reach_destination_on_rise)
                    var land_x := \
                            origin_target_point.x + \
                                    horizontal_movement_distance if \
                            velocity_start.x > 0.0 else \
                            origin_target_point.x - \
                                    horizontal_movement_distance
                    land_position_with_horizontal_movement_distance = \
                            _create_surface_interior_position(
                                    land_x,
                                    land_surface,
                                    movement_params.collider,
                                    land_surface_left_end_wrapper,
                                    land_surface_right_end_wrapper)
                    var jump_land_positions_with_horizontal_movement_distance := \
                            _create_jump_land_positions(
                                    movement_params,
                                    origin_position,
                                    land_position_with_horizontal_movement_distance,
                                    velocity_start,
                                    null,
                                    false,
                                    false,
                                    true,
                                    false)
                    if jump_land_positions_with_horizontal_movement_distance != null:
                        result.push_back( \
                                jump_land_positions_with_horizontal_movement_distance)
                
                var land_position_without_horizontal_movement_distance := \
                        _create_surface_interior_position(
                                origin_target_point.x,
                                land_surface,
                                movement_params.collider,
                                land_surface_left_end_wrapper,
                                land_surface_right_end_wrapper)
                if land_position_without_horizontal_movement_distance != \
                        land_position_with_horizontal_movement_distance:
                    var jump_land_positions_without_horizontal_movement_distance := \
                            _create_jump_land_positions(
                                    movement_params,
                                    origin_position,
                                    land_position_without_horizontal_movement_distance,
                                    velocity_start,
                                    null,
                                    false,
                                    false,
                                    true,
                                    false)
                    if jump_land_positions_without_horizontal_movement_distance != null:
                        result.push_back( \
                                jump_land_positions_without_horizontal_movement_distance)
                
                return result
            
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var is_left_wall := land_surface.side == SurfaceSide.LEFT_WALL
            var land_surface_top_end_wrapper := \
                    land_surface_first_point_wrapper if \
                    is_left_wall else \
                    land_surface_last_point_wrapper
            var land_surface_bottom_end_wrapper := \
                    land_surface_last_point_wrapper if \
                    is_left_wall else \
                    land_surface_first_point_wrapper
            var is_behind_wall := \
                    origin_target_point.x < land_surface_center.x if \
                    is_left_wall else \
                    origin_target_point.x > land_surface_center.x
            var is_below_top_of_wall := \
                    origin_target_point.y > \
                    land_surface_top_end_wrapper \
                            .target_projection_onto_surface.y
            var is_below_bottom_of_wall := \
                    origin_target_point.y < \
                    land_surface_bottom_end_wrapper \
                            .target_projection_onto_surface.y
            var vertical_offset_to_support_extra_movement_around_wall := \
                    movement_params.collider.half_width_height.y * \
                    VERTICAL_OFFSET_TO_SUPPORT_EXTRA_MOVEMENT_AROUND_WALL_CHARACTER_HEIGHT_RATIO
            
            if (is_below_bottom_of_wall or \
                    (is_behind_wall and \
                    is_below_top_of_wall)) and \
                    velocity_start.y > 0.0:
                # We cannot reach the front of the wall.
                return []
                
            elif is_behind_wall and \
                    is_below_bottom_of_wall and \
                    velocity_start.y < 0.0:
                var can_reach_vertical_displacement := VerticalMovementUtils \
                        .check_can_reach_vertical_displacement(
                                movement_params,
                                origin_target_point,
                                land_surface_bottom_end_wrapper.target_point,
                                velocity_start,
                                can_hold_jump_button_at_start)
                if !can_reach_vertical_displacement:
                    return []
                
                # We may be able to reach around to the bottom of the wall.
                var jump_land_positions := _create_jump_land_positions(
                        movement_params,
                        origin_position,
                        land_surface_bottom_end_wrapper,
                        velocity_start,
                        null,
                        false,
                        false,
                        true,
                        false)
                return [jump_land_positions] if \
                        jump_land_positions != null else \
                        []
                
            elif is_behind_wall:
                # We may be able to reach around the top of the wall.
                var land_y := \
                        land_surface_top_bound + \
                        vertical_offset_to_support_extra_movement_around_wall
                var land_position := _create_surface_interior_position(
                        land_y,
                        land_surface,
                        movement_params.collider,
                        land_surface_top_end_wrapper,
                        land_surface_bottom_end_wrapper)
                
                var can_reach_vertical_displacement := VerticalMovementUtils \
                        .check_can_reach_vertical_displacement(
                                movement_params,
                                origin_target_point,
                                land_position.target_point,
                                velocity_start,
                                can_hold_jump_button_at_start)
                if !can_reach_vertical_displacement:
                    return []
                
                var jump_land_positions := _create_jump_land_positions(
                        movement_params,
                        origin_position,
                        land_position,
                        velocity_start,
                        null,
                        false,
                        false,
                        true,
                        false)
                return [jump_land_positions] if \
                        jump_land_positions != null else \
                        []
                
            else:
                # We are in front of the wall and high enough, and we may be
                # able to move horizontally directly into the wall.
                var land_basis: Vector2 = \
                        Sc.geometry.project_shape_onto_surface(
                                origin_target_point,
                                movement_params.collider,
                                land_surface)
                
                var can_reach_vertical_displacement := VerticalMovementUtils \
                        .check_can_reach_vertical_displacement(
                                movement_params,
                                origin_target_point,
                                land_basis,
                                velocity_start,
                                can_hold_jump_button_at_start)
                if !can_reach_vertical_displacement:
                    return []
                
                var vertical_movement_displacement := \
                        _calculate_vertical_movement_displacement(
                                movement_params,
                                origin_target_point,
                                land_basis,
                                velocity_start,
                                can_hold_jump_button_at_start)
                var land_y := origin_target_point.y + \
                        vertical_movement_displacement
                var land_position := _create_surface_interior_position(
                        land_y,
                        land_surface,
                        movement_params.collider,
                        land_surface_top_end_wrapper,
                        land_surface_bottom_end_wrapper)
                var jump_land_positions := _create_jump_land_positions(
                        movement_params,
                        origin_position,
                        land_position,
                        velocity_start,
                        null,
                        false,
                        false,
                        true,
                        false)
                return [jump_land_positions] if \
                        jump_land_positions != null else \
                        []
            
        SurfaceSide.CEILING:
            if velocity_start.y > 0.0:
                # We cannot reach the ceiling.
                return []
            else:
                # We may be able to reach the ceiling.
                
                var land_basis: Vector2 = \
                        Sc.geometry.project_shape_onto_surface(
                                origin_target_point,
                                movement_params.collider,
                                land_surface)
                var must_reach_destination_on_fall := false
                var must_reach_destination_on_rise := true
                
                var can_reach_vertical_displacement := VerticalMovementUtils \
                        .check_can_reach_vertical_displacement(
                                movement_params,
                                origin_target_point,
                                land_basis,
                                velocity_start,
                                can_hold_jump_button_at_start)
                if !can_reach_vertical_displacement:
                    return []
                
                var horizontal_movement_distance := \
                        _calculate_horizontal_movement_distance(
                                movement_params,
                                origin_target_point,
                                land_basis,
                                velocity_start,
                                can_hold_jump_button_at_start,
                                must_reach_destination_on_fall,
                                must_reach_destination_on_rise)
                var land_x := \
                        origin_target_point.x + \
                                horizontal_movement_distance if \
                        velocity_start.x > 0.0 else \
                        origin_target_point.x - \
                                horizontal_movement_distance
                var land_position_with_horizontal_movement_distance := \
                        _create_surface_interior_position(
                                land_x,
                                land_surface,
                                movement_params.collider,
                                land_surface_first_point_wrapper,
                                land_surface_last_point_wrapper)
                var jump_land_positions_with_horizontal_movement_distance := \
                        _create_jump_land_positions(
                                movement_params,
                                origin_position,
                                land_position_with_horizontal_movement_distance,
                                velocity_start,
                                null,
                                false,
                                false,
                                true,
                                false)
                if jump_land_positions_with_horizontal_movement_distance != null:
                    return [jump_land_positions_with_horizontal_movement_distance]
                else:
                    return []
            
        _:
            Sc.logger.error("Unknown land surface side")
            return []


static func get_velocity_start(
        movement_params: MovementParameters,
        origin_surface: Surface,
        is_jumping: bool,
        is_moving_leftward := false,
        prefer_zero_horizontal_speed := false) -> Vector2:
    var velocity_start_x := get_horizontal_velocity_start(
            movement_params,
            origin_surface,
            is_moving_leftward,
            prefer_zero_horizontal_speed)
    
    var velocity_start_y: float
    if !is_jumping:
        velocity_start_y = 0.0
    else:
        match origin_surface.side:
            SurfaceSide.LEFT_WALL, \
            SurfaceSide.RIGHT_WALL:
                velocity_start_y = movement_params.jump_boost
                
            SurfaceSide.FLOOR:
                velocity_start_y = movement_params.jump_boost
                
            SurfaceSide.CEILING:
                # We always prefer "falling" rather than "jumping-down" from
                # ceilings, since starting with less vertical speed only gives
                # us more flexibility.
                velocity_start_y = 0.0
                
            _:
                Sc.logger.error()
                return Vector2.INF
    
    return Vector2(velocity_start_x, velocity_start_y)


static func get_horizontal_velocity_start(
        movement_params: MovementParameters,
        origin_surface: Surface,
        is_moving_leftward := false,
        prefer_zero_horizontal_speed := false) -> float:
    match origin_surface.side:
        SurfaceSide.FLOOR:
            if prefer_zero_horizontal_speed:
                return 0.0
            
            # This uses a simplifying assumption, since we can't know whether
            # there is actually enough ramp-up distance without knowing the
            # exact position within the bounds of the surface.
            var can_reach_half_max_speed := \
                    origin_surface.bounding_box.size.x > \
                    movement_params.distance_to_half_max_horizontal_speed
            
            if can_reach_half_max_speed:
                if is_moving_leftward:
                    return -movement_params.max_horizontal_speed_default
                else:
                    return movement_params.max_horizontal_speed_default
            else:
                return 0.0
            
        SurfaceSide.LEFT_WALL:
            return movement_params.wall_jump_horizontal_boost
            
        SurfaceSide.RIGHT_WALL:
            return -movement_params.wall_jump_horizontal_boost
            
        SurfaceSide.CEILING:
            if prefer_zero_horizontal_speed:
                return 0.0
            elif is_moving_leftward:
                return -movement_params.ceiling_crawl_speed
            else:
                return movement_params.ceiling_crawl_speed
            
        _:
            Sc.logger.error()
            return INF


# This returns a PositionAlongSurface instance for the given x/y coordinate
# along the given surface. If the coordinate isn't actually within the bounds
# of the surface, then a pre-existing PositionAlongSurface instance will be
# returned, rather than creating a redundant new instance.
static func _create_surface_interior_position(
        goal_coordinate: float,
        surface: Surface,
        collider: RotatedShape,
        lower_end_position: PositionAlongSurface,
        upper_end_position: PositionAlongSurface,
        fail_if_outside_of_bounds := false) -> PositionAlongSurface:
    var is_considering_x_axis := surface.normal.x == 0.0
    # TODO: Update this to use a more precise spacing according to collider
    #       shape and neighbor segment angle (using project_shape_onto_surface)?
    var interior_point_min_horizontal_distance_from_end := \
            collider.half_width_height.x * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_CHARACTER_WIDTH_HEIGHT_RATIO
    
    var lower_bound: float
    var upper_bound: float
    if is_considering_x_axis:
        lower_bound = surface.bounding_box.position.x
        upper_bound = surface.bounding_box.end.x
    else:
        lower_bound = surface.bounding_box.position.y
        upper_bound = surface.bounding_box.end.y
    
    var is_goal_outside_of_bounds := \
        goal_coordinate < lower_bound or \
        goal_coordinate > upper_bound
    
    if fail_if_outside_of_bounds and is_goal_outside_of_bounds:
        return null
    
    var is_goal_close_to_lower_end := \
            goal_coordinate <= lower_bound + \
                    interior_point_min_horizontal_distance_from_end
    var is_goal_close_to_upper_end := \
            goal_coordinate >= upper_bound - \
                    interior_point_min_horizontal_distance_from_end
    
    if is_goal_close_to_lower_end:
        return lower_end_position
    elif is_goal_close_to_upper_end:
        return upper_end_position
    else:
        # The goal coordinate isn't too close to either end, so we can create a
        # new surface-interior position for it.
        var target_point := \
                Vector2(goal_coordinate, INF) if \
                is_considering_x_axis else \
                Vector2(INF, goal_coordinate)
        return PositionAlongSurfaceFactory \
                .create_position_offset_from_target_point(
                        target_point,
                        surface,
                        collider,
                        true)


# Checks whether the given jump/land positions are far enough away from all
# other previous jump/land positions, and records it in the given results
# collection if they are.
static func _record_if_distinct(
        movement_params: MovementParameters,
        current_jump_position: PositionAlongSurface,
        current_land_position: PositionAlongSurface,
        velocity_start: Vector2,
        distance_threshold: float,
        needs_extra_jump_duration: bool,
        results: Array,
        inserts_at_front: bool,
        previous_jump_land_positions_1: JumpLandPositions,
        previous_jump_land_positions_2 = null,
        previous_jump_land_positions_3 = null) -> JumpLandPositions:
    var is_considering_x_coordinate_for_jump_position := \
            current_jump_position.surface.normal.x == 0.0
    var is_considering_x_coordinate_for_land_position:= \
            current_land_position.surface.normal.x == 0.0
    
    if !movement_params \
            .includes_redundant_j_l_positions_with_zero_start_velocity:
        for previous_jump_land_positions in [
                previous_jump_land_positions_1,
                previous_jump_land_positions_2,
                previous_jump_land_positions_3,
                ]:
            if previous_jump_land_positions != null:
                var current_jump_coordinate: float
                var current_land_coordinate: float
                var previous_jump_coordinate: float
                var previous_land_coordinate: float
                
                if is_considering_x_coordinate_for_jump_position:
                    current_jump_coordinate = current_jump_position \
                            .target_projection_onto_surface.x
                    previous_jump_coordinate = \
                            previous_jump_land_positions.jump_position\
                                    .target_projection_onto_surface.x
                else:
                    current_jump_coordinate = current_jump_position \
                            .target_projection_onto_surface.y
                    previous_jump_coordinate = \
                            previous_jump_land_positions.jump_position \
                                    .target_projection_onto_surface.y
                
                if is_considering_x_coordinate_for_land_position:
                    current_land_coordinate = current_land_position \
                            .target_projection_onto_surface.x
                    previous_land_coordinate = \
                            previous_jump_land_positions.land_position \
                                    .target_projection_onto_surface.x
                else:
                    current_land_coordinate = current_land_position\
                            .target_projection_onto_surface.y
                    previous_land_coordinate = \
                            previous_jump_land_positions.land_position \
                                    .target_projection_onto_surface.y
                
                var is_close := \
                        abs(previous_jump_coordinate - \
                                current_jump_coordinate) < \
                        distance_threshold and \
                        abs(previous_land_coordinate - \
                                current_land_coordinate) < \
                        distance_threshold
                if is_close:
                    return null
    
    var jump_land_positions := _create_jump_land_positions(
            movement_params,
            current_jump_position,
            current_land_position,
            velocity_start)
    if jump_land_positions != null:
        if inserts_at_front:
            results.push_front(jump_land_positions)
        else:
            results.push_back(jump_land_positions)
    return jump_land_positions


# Calculates a representative horizontal distance between jump and land
#  positions.
# 
# - For simplicity, this assumes that the closest point of the surface is at
#   the same height as the resulting point along the surface that we are
#   calculating.
# - Returns INF if we cannot reach the land position from the start position.
static func _calculate_horizontal_movement_distance(
        movement_params: MovementParameters,
        jump_basis: Vector2,
        land_basis: Vector2,
        velocity_start: Vector2,
        can_hold_jump_button_at_start: bool,
        must_reach_destination_on_fall: bool,
        must_reach_destination_on_rise: bool) -> float:
    var displacement: Vector2 = land_basis - jump_basis
    
    var duration: float = \
            VerticalMovementUtils.calculate_time_to_jump_to_waypoint(
                    movement_params,
                    displacement,
                    velocity_start,
                    can_hold_jump_button_at_start,
                    must_reach_destination_on_fall,
                    must_reach_destination_on_rise)
    if is_inf(duration):
        # We cannot reach the land position from the start position.
        return INF
    
    var horizontal_movement_distance: float = \
            MovementUtils.calculate_displacement_for_duration(
                    duration,
                    abs(velocity_start.x),
                    movement_params.in_air_horizontal_acceleration,
                    movement_params.max_horizontal_speed_default)
    
    var character_half_width_horizontal_offset := \
            movement_params.collider.half_width_height.x + \
            movement_params.collision_margin_for_waypoint_positions + \
            EXTRA_JUMP_LAND_POSITION_MARGIN
    
    # This max movement range could slightly overshoot what's actually
    # reachable, so we subtract a portion of the character's width to more
    # likely end up with a usable position.
    var horizontal_movement_distance_partial_decrease := \
            character_half_width_horizontal_offset * \
            EDGE_MOVEMENT_HORIZONTAL_DISTANCE_SUBTRACT_CHARACTER_WIDTH_RATIO
    if horizontal_movement_distance > \
            horizontal_movement_distance_partial_decrease:
        horizontal_movement_distance -= \
                horizontal_movement_distance_partial_decrease
    
    return horizontal_movement_distance


# Calculates a representative vertical distance between the given jump and land
# positions.
# 
# -   If this is for a jump calculator, then both vertical displacements
#     corresponding to max-jump-button-press and min-jump-button-press are
#     considered, and a value within this range is returned. This value will be
#     as close as possible to the actual displacement between the given
#     jump/land basis points.
# -   For simplicity, this assumes that the basis point is at the same
#     x-coordinate as the resulting point along the surface that we are
#     calculating.
# -   This doesn't account for any required velocity-end values for landing on
#     wall surfaces. Instead, we rely on a constant vertical offset being
#     applied (elsewhere) whenever we detect movement is moving around an end
#     of a wall.
static func _calculate_vertical_movement_displacement(
        movement_params: MovementParameters,
        jump_basis: Vector2,
        land_basis: Vector2,
        velocity_start: Vector2,
        can_hold_jump_button_at_start: bool) -> float:
    var displacement: Vector2 = land_basis - jump_basis
    var acceleration_x := \
            movement_params.in_air_horizontal_acceleration if \
            displacement.x > 0.0 else \
            -movement_params.in_air_horizontal_acceleration
    
    var duration: float = MovementUtils.calculate_duration_for_displacement(
            displacement.x,
            velocity_start.x,
            acceleration_x,
            movement_params.max_horizontal_speed_default)
    assert(!is_inf(duration))
    
    var vertical_displacement_with_fast_fall_gravity: float = \
            MovementUtils.calculate_displacement_for_duration(
                    duration,
                    abs(velocity_start.y),
                    movement_params.gravity_fast_fall,
                    movement_params.max_vertical_speed)
    
    if vertical_displacement_with_fast_fall_gravity < displacement.y:
        # Even with max fast-fall gravity, we can reach a point above the
        # target displacement. So let's assume we can delay some of the
        # horizontal offset, and fall as far as we want.
        return displacement.y
        
    elif !can_hold_jump_button_at_start:
        # Since we can't use any slow-rise gravity, this displacement with max
        # fast-fall gravity is the best we can do.
        return vertical_displacement_with_fast_fall_gravity
        
    else:
        # Take into consideration the offset with slow-rise gravity.
        duration = max(duration, movement_params.time_to_max_upward_jump_distance)
        var vertical_displacement_with_slow_rise_gravity: float = \
                VerticalMovementUtils \
                        .calculate_vertical_displacement_from_duration_with_max_slow_rise_gravity(
                                movement_params,
                                duration,
                                velocity_start.y)
        
        if vertical_displacement_with_slow_rise_gravity > displacement.y:
            # Since we descend further than we'd like, even with min gravity,
            # this displacement is our best option.
            return vertical_displacement_with_slow_rise_gravity
        
        # The ideal displacement would exactly match the displacement between
        # the basis jump/land points, and since that displacemnt is within the
        # possible range, we can use it.
        return displacement.y


# Calculates a jump/land pair between two walls that face each other.
# 
# -   Calculates vertical offset for jumping between the given basis points,
#     and applies this offset to the resulting jump/land pair.
# -   Re-uses any end-point wrapper position instances, instead of creating new
#     ones.
# -   Checks previous jump/land pairs to ensure the new one would be distinct.
# -   Returns null if there is not enough length along either surface to
#     account for the needed vertical offset for the movement.
static func _calculate_jump_land_points_for_walls_facing_each_other(
        movement_params: MovementParameters,
        all_jump_land_positions: Array,
        inserts_at_front: bool,
        jump_basis_point: Vector2,
        land_basis_point: Vector2,
        velocity_start: Vector2,
        can_hold_jump_button_at_start: bool,
        jump_surface: Surface,
        jump_surface_top_end_wrapper: PositionAlongSurface,
        jump_surface_bottom_end_wrapper: PositionAlongSurface,
        land_surface: Surface,
        land_surface_top_end_wrapper: PositionAlongSurface,
        land_surface_bottom_end_wrapper: PositionAlongSurface,
        other_jump_land_positions_1 = null,
        other_jump_land_positions_2 = null) -> JumpLandPositions:
    var jump_surface_top_bound := jump_surface.bounding_box.position.y
    var land_surface_bottom_bound := land_surface.bounding_box.end.y
    
    var vertical_movement_displacement := \
            _calculate_vertical_movement_displacement(
                    movement_params,
                    jump_basis_point,
                    land_basis_point,
                    velocity_start,
                    can_hold_jump_button_at_start)
    
    var jump_goal_y := jump_basis_point.y
    var land_goal_y := jump_basis_point.y + vertical_movement_displacement
    
    if land_goal_y > land_surface_bottom_bound:
        # There is not enough length on the land surface to account for this
        # vertical offset, so we need to account for some of it on the jump
        # surface.
        var remaining_offset := land_goal_y - land_surface_bottom_bound
        if jump_goal_y - remaining_offset >= jump_surface_top_bound:
            # There is enough length on the jump surface to account for this
            # vertical offset.
            jump_goal_y -= remaining_offset
            land_goal_y = land_surface_bottom_bound
        else:
            # There is not enough length on the jump surface to account for
            # this vertical offset either, so we should abandon this jump/land
            # pair as infeasible.
            return null
    
    var jump_position := _create_surface_interior_position(
            jump_goal_y,
            jump_surface,
            movement_params.collider,
            jump_surface_top_end_wrapper,
            jump_surface_bottom_end_wrapper)
    var land_position := _create_surface_interior_position(
            land_goal_y,
            land_surface,
            movement_params.collider,
            land_surface_top_end_wrapper,
            land_surface_bottom_end_wrapper)
    
    var interior_point_min_vertical_distance_from_end := \
            movement_params.collider.half_width_height.y * \
            JUMP_LAND_SURFACE_INTERIOR_POINT_MIN_DISTANCE_FROM_END_CHARACTER_WIDTH_HEIGHT_RATIO
    
    return _record_if_distinct(
            movement_params,
            jump_position,
            land_position,
            velocity_start,
            interior_point_min_vertical_distance_from_end,
            false,
            all_jump_land_positions,
            inserts_at_front,
            other_jump_land_positions_1,
            other_jump_land_positions_2)


static func _create_jump_land_positions(
        movement_params: MovementParameters,
        jump_position: PositionAlongSurface,
        land_position: PositionAlongSurface,
        velocity_start: Vector2,
        results_collection = null,
        needs_extra_jump_duration := false,
        less_likely_to_be_valid := false,
        preserves_jump_position := false,
        preserves_land_position := false) -> JumpLandPositions:
    # TODO: Go through callsites, and update them if this offset might possibly
    #       make the other jump/land position be too far away.
    if !preserves_jump_position and \
            !ensure_position_is_not_too_close_to_concave_neighbor(
                    movement_params,
                    jump_position):
        return null
    if !preserves_land_position and \
            !ensure_position_is_not_too_close_to_concave_neighbor(
                    movement_params,
                    land_position):
        return null
    
    var is_close_to_wall_bottom := \
            is_land_position_close_to_wall_bottom(land_position) if \
            preserves_land_position else \
            _possibly_offset_wall_bottom_land_position(
                    movement_params,
                    land_position)
    
    var result := JumpLandPositions.new(
            jump_position,
            land_position,
            velocity_start,
            needs_extra_jump_duration,
            is_close_to_wall_bottom,
            less_likely_to_be_valid)
    if results_collection != null:
        results_collection.push_back(result)
    return result


# Returns false if there is not enough room for the character on the surface.
static func ensure_position_is_not_too_close_to_concave_neighbor(
        movement_params: MovementParameters,
        position: PositionAlongSurface) -> bool:
    var surface := position.surface
    
    if surface == null or \
            surface.clockwise_concave_neighbor == null and \
            surface.counter_clockwise_concave_neighbor == null:
        # If the surface has no concave neighbors, then don't adjust the
        # position.
        return true
    
    var x_offset := \
            movement_params.collider.half_width_height.x + \
            MARGIN_FROM_CONCAVE_NEIGHBOR
    var y_offset := \
            movement_params.collider.half_width_height.y + \
            MARGIN_FROM_CONCAVE_NEIGHBOR
    
    # Ensure there is enough room for the character to fit on the surface.
    match position.side:
        SurfaceSide.FLOOR, \
        SurfaceSide.CEILING:
            if surface.clockwise_concave_neighbor != null and \
                    surface.counter_clockwise_concave_neighbor != null and \
                    surface.bounding_box.size.x < x_offset * 2:
                # There is not enough room for the character to fit on this
                # surface.
                return false
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            if surface.clockwise_concave_neighbor != null and \
                    surface.counter_clockwise_concave_neighbor != null and \
                    surface.bounding_box.size.y < y_offset * 2:
                # There is not enough room for the character to fit on this
                # surface.
                return false
        SurfaceSide.NONE:
            pass
        _:
            Sc.logger.error()
            return false
    
    # Offset position if it's too close to either end.
    match position.side:
        SurfaceSide.FLOOR:
            var new_coordinate := position.target_projection_onto_surface.x
            if surface.clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.end.x - x_offset
                if new_coordinate > boundary_coordinate:
                    new_coordinate = boundary_coordinate
            if surface.counter_clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.position.x + x_offset
                if new_coordinate < boundary_coordinate:
                    new_coordinate = boundary_coordinate
            position.target_point.x = new_coordinate
            
        SurfaceSide.LEFT_WALL:
            var new_coordinate := position.target_projection_onto_surface.y
            if surface.clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.end.y - y_offset
                if new_coordinate > boundary_coordinate:
                    new_coordinate = boundary_coordinate
            if surface.counter_clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.position.y + y_offset
                if new_coordinate < boundary_coordinate:
                    new_coordinate = boundary_coordinate
            position.target_point.y = new_coordinate
            
        SurfaceSide.RIGHT_WALL:
            var new_coordinate := position.target_projection_onto_surface.y
            if surface.counter_clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.end.y - y_offset
                if new_coordinate > boundary_coordinate:
                    new_coordinate = boundary_coordinate
            if surface.clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.position.y + y_offset
                if new_coordinate < boundary_coordinate:
                    new_coordinate = boundary_coordinate
            position.target_point.y = new_coordinate
            
        SurfaceSide.CEILING:
            var new_coordinate := position.target_projection_onto_surface.x
            if surface.counter_clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.end.x - x_offset
                if new_coordinate > boundary_coordinate:
                    new_coordinate = boundary_coordinate
            if surface.clockwise_concave_neighbor != null:
                var boundary_coordinate := \
                        surface.bounding_box.position.x + x_offset
                if new_coordinate < boundary_coordinate:
                    new_coordinate = boundary_coordinate
            position.target_point.x = new_coordinate
            
        SurfaceSide.NONE:
            pass
            
        _:
            Sc.logger.error()
            return false
    
    # Make sure the target point is still the right distance out from the
    # surface, according to the surface and character shape.
    var target_point: Vector2 = Sc.geometry.project_shape_onto_surface(
            position.target_point,
            movement_params.collider,
            position.surface)
    position.match_surface_target_and_collider(
            position.surface,
            target_point,
            movement_params.collider,
            true,
            true)
    
    return true


# Ensure a min distance up from wall bottom ends to prevent the character from
# falling slightly short and missing the bottom corner of the land surface.
static func _possibly_offset_wall_bottom_land_position(
        movement_params: MovementParameters,
        land_position: PositionAlongSurface) -> bool:
    if is_land_position_close_to_wall_bottom(land_position):
        var bottom_bound := \
                land_position.surface.bounding_box.end.y - \
                MIN_LAND_DISTANCE_FROM_WALL_BOTTOM
        var target_point := Vector2(land_position.target_point.x, bottom_bound)
        target_point = Sc.geometry.project_shape_onto_surface(
                target_point,
                movement_params.collider,
                land_position.surface)
        land_position.match_surface_target_and_collider(
                land_position.surface,
                target_point,
                movement_params.collider,
                true,
                true)
        return true
    return false


static func is_land_position_close_to_wall_bottom(
        land_position: PositionAlongSurface) -> bool:
    var surface := land_position.surface
    return (surface.side == SurfaceSide.LEFT_WALL or \
            surface.side == SurfaceSide.RIGHT_WALL) and \
            land_position.target_point.y > \
            surface.bounding_box.end.y - MIN_LAND_DISTANCE_FROM_WALL_BOTTOM
