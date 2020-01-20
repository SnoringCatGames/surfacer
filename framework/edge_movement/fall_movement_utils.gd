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
    find_surfaces_in_fall_range( \
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

static func find_surfaces_in_fall_range(movement_params: MovementParams, \
        possible_surfaces_set: Dictionary, result_set: Dictionary, origin: Vector2, \
        velocity_start: Vector2) -> void:
    # FIXME: E: Offset the start_position_offset to account for velocity_start.
    # TODO: Refactor this to use a more accurate bounding polygon.
    
    # This offset should account for the extra horizontal range before the player has reached
    # terminal velocity.
    var start_position_offset_x: float = \
            HorizontalMovementUtils.calculate_max_horizontal_displacement( \
                    velocity_start.x, velocity_start.y, \
                    movement_params.max_horizontal_speed_default, \
                    movement_params.gravity_slow_rise, movement_params.gravity_fast_fall)
    var start_position_offset := Vector2(start_position_offset_x, 0.0)
    var slope := movement_params.max_vertical_speed / movement_params.max_horizontal_speed_default
    var bottom_corner_offset_from_top_corner := Vector2(100000.0, 100000.0 * slope)
    
    var top_left := origin - start_position_offset
    var top_right := origin + start_position_offset
    var bottom_left := top_left + Vector2(-bottom_corner_offset_from_top_corner.x, \
            bottom_corner_offset_from_top_corner.y)
    var bottom_right := top_right + Vector2(bottom_corner_offset_from_top_corner.x, \
            bottom_corner_offset_from_top_corner.y)
    _get_surfaces_intersecting_polygon(result_set, \
            [top_left, top_right, bottom_right, bottom_left], possible_surfaces_set)

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
