# A collection of utility functions for calculating state related to fall movement.
class_name FallMovementUtils

# Finds a movement step that will result in landing on a surface, with an attempt to minimize the
# path the player would then have to travel between surfaces to reach the given target.
#
# Returns null if no possible landing exists.
static func find_a_landing_trajectory(space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser, \
        possible_surfaces_set: Dictionary, origin: Vector2, velocity_start: Vector2, \
        destination: PositionAlongSurface) -> AirToSurfaceEdge:
    var result_set := {}
    find_surfaces_in_fall_range_from_point( \
            movement_params, possible_surfaces_set, result_set, origin, velocity_start)
    var possible_landing_surfaces := result_set.keys()
    possible_landing_surfaces.sort_custom(SurfaceMaxYComparator, "sort")
    
    var constraint_offset := MovementCalcOverallParams.calculate_constraint_offset(movement_params)
    
    var origin_vertices := [origin]
    var origin_bounding_box := Rect2(origin.x, origin.y, 0.0, 0.0)
    
    var possible_end_positions: Array
    var terminals: Array
    var vertical_step: MovementVertCalcStep
    var step_calc_params: MovementCalcStepParams
    var calc_results: MovementCalcResults
    var overall_calc_params: MovementCalcOverallParams
    
    # Find the first possible edge to a landing surface.
    for surface in possible_landing_surfaces:
        possible_end_positions = MovementUtils.get_all_jump_positions_from_surface( \
                movement_params, destination.surface, origin_vertices, origin_bounding_box, \
                SurfaceSide.CEILING)
        
        for position_end in possible_end_positions:
            terminals = MovementConstraintUtils.create_terminal_constraints(null, origin, \
                    surface, position_end.target_point, movement_params, false, velocity_start)
            if terminals.empty():
                continue
            
            overall_calc_params = MovementCalcOverallParams.new(movement_params, space_state, \
                    surface_parser, terminals[0], terminals[1], velocity_start, false)
            
            vertical_step = VerticalMovementUtils.calculate_vertical_step(overall_calc_params)
            if vertical_step == null:
                continue
            
            step_calc_params = MovementCalcStepParams.new(overall_calc_params.origin_constraint, \
                    overall_calc_params.destination_constraint, vertical_step, \
                    overall_calc_params, null, null)
            
            calc_results = MovementStepUtils.calculate_steps_from_constraint( \
                    overall_calc_params, step_calc_params)
            if calc_results != null:
                return AirToSurfaceEdge.new(origin, position_end, calc_results)
    
    return null

static func find_surfaces_in_fall_range_from_point(movement_params: MovementParams, \
        possible_surfaces_set: Dictionary, result_set: Dictionary, origin: Vector2, \
        velocity_start: Vector2) -> void:
    # FIXME: E: Offset the start_position_offset to account for velocity_start.
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    # NOTE: This makes the simplifying assumption that the player cannot still be pressing the jump
    #       button, and we only need to consider fast-fall gravity.
    var time_to_terminal_velocity_y := (movement_params.max_vertical_speed - velocity_start.y) / \
            movement_params.gravity_fast_fall
    
    # This offset should account for the extra horizontal range before the player has reached
    # terminal velocity.
    # From a basic equation of motion:
    #     s = s_0 + v*t
    var offset_x_for_acceleration_to_terminal_velocity := \
            movement_params.max_horizontal_speed_default * time_to_terminal_velocity_y
    
    var offset_for_acceleration_to_terminal_velocity := \
            Vector2(offset_x_for_acceleration_to_terminal_velocity, 0.0)
    var slope := movement_params.max_vertical_speed / movement_params.max_horizontal_speed_default
    var offset_x_from_top_corner_to_bottom_corner := 10000.0
    var offset_y_from_top_corner_to_bottom_corner := 10000.0 * slope
    
    var top_left := origin - offset_for_acceleration_to_terminal_velocity
    var top_right := origin + offset_for_acceleration_to_terminal_velocity
    var bottom_left := top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
            offset_y_from_top_corner_to_bottom_corner)
    var bottom_right := top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
            offset_y_from_top_corner_to_bottom_corner)
    
    _get_surfaces_intersecting_polygon(result_set, \
            [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)

static func find_surfaces_in_fall_range_from_surface(movement_params: MovementParams, \
        possible_surfaces_set: Dictionary, \
        surfaces_in_fall_range_without_jump_distance_result_set: Dictionary, \
        surfaces_in_fall_range_with_jump_distance_result_set: Dictionary, \
        origin_surface: Surface) -> void:
    # FIXME: E: Offset the start_position_offset to account for velocity_start.
    # FIXME: E: There may be cases when it's worth considering both
    #           offset_for_acceleration_to_terminal_velocity and offset_for_jump_distance together.
    
    # From a basic equation of motion:
    #     v = v_0 + a*t
    #     v_0 = 0.0
    # NOTE: This makes the simplifying assumption that the player cannot still be pressing the jump
    #       button, and we only need to consider fast-fall gravity.
    var time_to_terminal_velocity_y := \
            movement_params.max_vertical_speed / movement_params.gravity_fast_fall
    
    # This offset should account for the extra horizontal range before the player has reached
    # terminal velocity.
    # From a basic equation of motion:
    #     s = s_0 + v*t
    var offset_x_for_acceleration_to_terminal_velocity := \
            movement_params.max_horizontal_speed_default * time_to_terminal_velocity_y
    
    var offset_for_acceleration_to_terminal_velocity := \
            Vector2(offset_x_for_acceleration_to_terminal_velocity, 0.0)
    var slope := movement_params.max_vertical_speed / movement_params.max_horizontal_speed_default
    var offset_x_from_top_corner_to_bottom_corner := 100000.0
    var offset_y_from_top_corner_to_bottom_corner := 100000.0 * slope
    
    # FIXME: LEFT OFF HERE: ----------------------------------A
    # - Decide whether to adapt this function or create another for the find_a_landing_trajectory
    #   case, where we only start with a single point, rather than a surface.
    
    # Only expand the intersection polygon to consider the jump distance, if the
    # corresponding result set is given.
    var max_horizontal_jump_distance := \
            movement_params.get_max_horizontal_jump_distance(origin_surface.side) if \
            surfaces_in_fall_range_with_jump_distance_result_set != null else \
            0.0
    var offset_for_jump_distance := Vector2(max_horizontal_jump_distance, 0.0)
    
    var top_left: Vector2
    var top_right: Vector2
    var bottom_left: Vector2
    var bottom_right: Vector2
    
    match origin_surface.side:
        SurfaceSide.LEFT_WALL:
            # Only expand calculate the jump-distance results, if the corresponding result set is
            # given.
            if surfaces_in_fall_range_with_jump_distance_result_set != null:
                top_left = origin_surface.first_point - offset_for_jump_distance
                top_right = origin_surface.first_point + offset_for_jump_distance
                bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                _get_surfaces_intersecting_polygon( \
                        surfaces_in_fall_range_with_jump_distance_result_set, \
                        [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)
                
                # Limit the possible surfaces for the following without-jump-distance calculation
                # to be a subset of the with-jump-distance result.
                possible_surfaces_set = surfaces_in_fall_range_with_jump_distance_result_set
            
            # For falling from a left-side wall, we can only fall leftward from bottom point, and
            # we can fall the furthest rightward from the top point. So we call the bottom point
            # the "top-left" and we call the top point the "top-right".
            top_left = origin_surface.last_point - \
                    offset_for_acceleration_to_terminal_velocity
            top_right = origin_surface.first_point + \
                    offset_for_acceleration_to_terminal_velocity
            bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            _get_surfaces_intersecting_polygon( \
                    surfaces_in_fall_range_without_jump_distance_result_set, \
                    [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)
            
        SurfaceSide.RIGHT_WALL:
            # Only expand calculate the jump-distance results, if the corresponding result set is
            # given.
            if surfaces_in_fall_range_with_jump_distance_result_set != null:
                top_left = origin_surface.last_point - offset_for_jump_distance
                top_right = origin_surface.last_point + offset_for_jump_distance
                bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                _get_surfaces_intersecting_polygon( \
                        surfaces_in_fall_range_with_jump_distance_result_set, \
                        [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)
                
                # Limit the possible surfaces for the following without-jump-distance calculation
                # to be a subset of the with-jump-distance result.
                possible_surfaces_set = surfaces_in_fall_range_with_jump_distance_result_set
            
            # For falling from a right-side wall, we can only fall rightward from bottom point, and
            # we can fall the furthest leftward from the top point. So we call the top point
            # the "top-left" and we call the bottom point the "top-right".
            top_left = origin_surface.last_point - \
                    offset_for_acceleration_to_terminal_velocity
            top_right = origin_surface.first_point + \
                    offset_for_acceleration_to_terminal_velocity
            bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            _get_surfaces_intersecting_polygon( \
                    surfaces_in_fall_range_without_jump_distance_result_set, \
                    [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)
            
        SurfaceSide.FLOOR:
            # Only expand calculate the jump-distance results, if the corresponding result set is
            # given.
            if surfaces_in_fall_range_with_jump_distance_result_set != null:
                top_left = origin_surface.first_point - offset_for_jump_distance
                top_right = origin_surface.last_point + offset_for_jump_distance
                bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                        offset_y_from_top_corner_to_bottom_corner)
                _get_surfaces_intersecting_polygon( \
                        surfaces_in_fall_range_with_jump_distance_result_set, \
                        [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)
                
                # Limit the possible surfaces for the following without-jump-distance calculation
                # to be a subset of the with-jump-distance result.
                possible_surfaces_set = surfaces_in_fall_range_with_jump_distance_result_set
            
            top_left = origin_surface.first_point - \
                    offset_for_acceleration_to_terminal_velocity
            top_right = origin_surface.last_point + \
                    offset_for_acceleration_to_terminal_velocity
            bottom_left = top_left + Vector2(-offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            bottom_right = top_right + Vector2(offset_x_from_top_corner_to_bottom_corner, \
                    offset_y_from_top_corner_to_bottom_corner)
            _get_surfaces_intersecting_polygon( \
                    surfaces_in_fall_range_without_jump_distance_result_set, \
                    [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)
            
        _:
            Utils.error()

# This is only an approximation, since it only considers the end points of the surface rather than
# each segment of the surface polyline.
static func _get_surfaces_intersecting_triangle(triangle_a: Vector2, triangle_b: Vector2,
        triangle_c: Vector2, surfaces: Array) -> Array:
    var result := []
    for surface in surfaces:
        if Geometry.do_segment_and_triangle_intersect(surface.vertices.front(), \
                surface.vertices.back(), triangle_a, triangle_b, triangle_c):
            result.push_back(surface)
    return result

# This is only an approximation, since it only considers the end points of the surface rather than
# each segment of the surface polyline.
static func _get_surfaces_intersecting_polygon( \
        result_set: Dictionary, polygon: Array, surfaces_set: Dictionary) -> void:
    for surface in surfaces_set:
        if Geometry.do_segment_and_polygon_intersect( \
                surface.first_point, surface.last_point, polygon):
            result_set[surface] = surface

class SurfaceMaxYComparator:
    static func sort(a: Surface, b: Surface) -> bool:
        return a.bounding_box.position.y < b.bounding_box.position.y
