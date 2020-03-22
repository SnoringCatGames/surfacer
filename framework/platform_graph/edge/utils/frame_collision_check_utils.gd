class_name FrameCollisionCheckUtils

const MovementCalcCollisionDebugState = preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_collision_debug_state.gd")

# TODO: Adjust this.
const VERTEX_SIDE_NUDGE_OFFSET := 0.001

# Determines whether the given motion of the given shape would collide with a surface. If a
# collision would occur, this returns the surface; otherwise, this returns null.
static func check_frame_for_collision( \
        space_state: Physics2DDirectSpaceState, \
        shape_query_params: Physics2DShapeQueryParameters, \
        collider_half_width_height: Vector2, \
        collider_rotation: float, \
        surface_parser: SurfaceParser, \
        has_recursed := false, \
        collision_debug_state = null) -> SurfaceCollision:
    # TODO: collide_shape can sometimes produce intersection points with round-off error that exist
    #       outside the bounds of the tile. At least in one case, the round-off error was 0.003
    #       beyond the tile bounds in the direction of motion. 
    
    var direction := shape_query_params.motion.normalized()
    var position_start := shape_query_params.transform.origin
    var position_end := position_start + shape_query_params.motion
    
    # Check for collisions during this frame; these could be new or pre-existing.
    # 
    # In most cases, for rectangular boundaries, `collide_shape` returns four points. In these
    # cases, two points correspond to the vertices of shape A that lie within shape B, and the
    # other two points correspond to the points where A intersect the edge of B. The player's
    # collision boundary could be either A or B.
    # 
    # When `collide_shape` returns two points, that seems to mean that only one vertex of shape A
    # lies within shape B. In this case, one of the points corresponds to the vertex of A that lies
    # within B, and the other point corresponds to the projection of that point onto an edge of B
    # that A is intersecting.
    # 
    # Sometimes `collide_shape` can return more than 4 points. This seems to happen more often with
    # more exotic collision shapes like capsules.
    var intersection_points := space_state.collide_shape(shape_query_params, 32)
    assert(intersection_points.size() < 32)
    if intersection_points.empty():
        # No collision.
        return null
    
    # Find when the collision occured during this frame's motion.
    # 
    # -   An array of size 2 means that there was no pre-existing collision.
    # -   An empty array means that we were already colliding even before any motion.
    var collision_ratios := space_state.cast_motion(shape_query_params)
    assert(collision_ratios.size() != 1)
    var there_was_a_preexisting_collision: bool = collision_ratios.size() == 0 or \
            (collision_ratios[0] == 0 and collision_ratios[1] == 0)
    
    ###############################################################################################
    if collision_debug_state != null:
        _record_collision_debug_state( \
                collision_debug_state, \
                shape_query_params, \
                collider_half_width_height, \
                intersection_points, \
                collision_ratios)
    ###############################################################################################
    
    if !_check_whether_any_intersection_point_lies_within_bounding_box_of_frame( \
            intersection_points, \
            position_start, \
            position_end, \
            collider_half_width_height, \
            shape_query_params.margin):
        Utils.error("space_state.collide_shape returned invalid collision points", false)
        # There is no actual collision this frame.
        return null
    
    
    
    
    
    
    # FIXME: B: Update tests to provide bounding box; add new test for this "corner" case
    
    # FIXME: E:
    # - Problem: Single-point surfaces will fail here (empty collision Dictionary result).
    # - Solution:
    #   - Not sure.
    #   - Might be able to use another space_state method?
    #   - Or, might be able to estimate parameters from other sources:
    #     - Normal according to the direction of motion?
    #     - Position from edge_aligned_ray_trace_target
    #     - Collider from ...
    
    
    
    
    
    
    var edge_aligned_ray_trace_target := _find_closest_intersection_point( \
            intersection_points, \
            position_start, \
            direction, \
            collider_half_width_height, \
            there_was_a_preexisting_collision)
    if edge_aligned_ray_trace_target == Vector2.INF:
        # We are moving away from all of the intersection points, so we can assume that there are
        # no new collisions this frame.
        return null
    
    
    
    
    if there_was_a_preexisting_collision:
        # - This collision probably involves the margin colliding and not the actual shape
        #   (otherwise, it should have been handled previously as an actual collision).
        # - However, this collision could still correspond to a real collision with an actual
        #   shape, due to round-off error.
        # - In which case, all intersection_points should be nearly equal in either the x or y
        #   coordinate, and we can assume that the edge_aligned_ray_trace_target is a point along
        #   the outside of a non-occluded surface, and that this surface is the closest in the
        #   direction of travel.
        
        if !has_recursed:
            var original_margin := shape_query_params.margin
            var original_motion := shape_query_params.motion
            
            # Remove margin, so we can determine which side the shape would actually collide
            # against.
            shape_query_params.margin = 0.0
            # Increase the motion, since we can't be sure the shape would otherwise collide without
            # the margin.
            shape_query_params.motion = direction * original_margin * 4
            
            # When the Player's shape rests against another collidable, that can be interpreted as
            # a collision, so we add a slight offset here.
            # 
            # This updates the matrix translation in global space, rather than relative to the
            # local coordinates of the matrix (which `translated` would do). This is important,
            # since the matrix could have been rotated.
            # FIXME: LEFT OFF HERE: Is this needed?
            shape_query_params.transform[2] += direction * 0.01
            
            var result := check_frame_for_collision( \
                    space_state, \
                    shape_query_params, \
                    collider_half_width_height, \
                    collider_rotation, \
                    surface_parser, \
                    true, \
                    collision_debug_state)
            
            shape_query_params.margin = original_margin
            shape_query_params.motion = original_motion
            shape_query_params.transform = Transform2D(collider_rotation, position_start)
            
            return result
        else: # has_recursed
            # We are probably just dealing with round-off error, in which case all
            # intersection_points should be nearly equal in either the x or y coordinate, and
            # edge_aligned_ray_trace_target should be the correct point to use.
            
            var are_intersection_points_close_horizontally: bool = \
                    Geometry.are_floats_equal_with_epsilon( \
                            intersection_points[0].x, intersection_points[1].x, 1.0) and \
                    Geometry.are_floats_equal_with_epsilon( \
                            intersection_points[0].x, intersection_points[2].x, 1.0) and \
                    Geometry.are_floats_equal_with_epsilon( \
                            intersection_points[0].x, intersection_points[3].x, 1.0)
            var are_intersection_points_close_vertically: bool = \
                    Geometry.are_floats_equal_with_epsilon( \
                            intersection_points[0].y, intersection_points[1].y, 1.0) and \
                    Geometry.are_floats_equal_with_epsilon( \
                            intersection_points[0].y, intersection_points[2].y, 1.0) and \
                    Geometry.are_floats_equal_with_epsilon( \
                            intersection_points[0].y, intersection_points[3].y, 1.0)
            # FIXME: Remove? This seems to be usually true, but not always.
#                assert(are_intersection_points_close_horizontally or \
#                        are_intersection_points_close_vertically)
            
            # Create some artificial values for the point of collision.
            position_start -= shape_query_params.motion * 0.1
            collision_ratios = [0, 0.1]
    
    # A value of 1 means that no collision was detected.
    assert(collision_ratios[0] < 1.0)
    
    var position_just_before_collision: Vector2 = \
            position_start + shape_query_params.motion * collision_ratios[0]
    var position_when_colliding: Vector2 = \
            position_start + shape_query_params.motion * collision_ratios[1]
    
    
    
    
    
    var side := SurfaceSide.NONE
    # For nudging the ray-tracing a little so that it hits the correct side of the collider vertex.
    var perpendicular_offset := Vector2.INF
    var should_try_without_perpendicular_nudge_first: bool
    
    if direction.x == 0 or direction.y == 0:
        # Moving straight sideways or up-down.
        
        if direction.x == 0:
            if direction.y > 0:
                side = SurfaceSide.FLOOR
            else: # direction.y < 0
                side = SurfaceSide.CEILING
        elif direction.y == 0:
            if direction.x > 0:
                side = SurfaceSide.RIGHT_WALL
            else: # direction.x < 0
                side = SurfaceSide.LEFT_WALL
        
        perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
        should_try_without_perpendicular_nudge_first = true
        
    else:
        # Moving at an angle.
        
        var x_min_just_before_collision := \
                position_just_before_collision.x - collider_half_width_height.x
        var x_max_just_before_collision := \
                position_just_before_collision.x + collider_half_width_height.x
        var y_min_just_before_collision := \
                position_just_before_collision.y - collider_half_width_height.y
        var y_max_just_before_collision := \
                position_just_before_collision.y + collider_half_width_height.y
        
        var intersects_along_x := \
                x_min_just_before_collision <= edge_aligned_ray_trace_target.x and \
                x_max_just_before_collision >= edge_aligned_ray_trace_target.x
        var intersects_along_y := \
                y_min_just_before_collision <= edge_aligned_ray_trace_target.y and \
                y_max_just_before_collision >= edge_aligned_ray_trace_target.y
        
        if !intersects_along_x and !intersects_along_y:
            # Neither dimension intersects just before collision. This usually just means that
            # `cast_motion` is using too large of a time step.
            # 
            # Here is our workaround:
            # -   Pick the closest corner of the non-margin shape. Project a line from it along
            #     the motion direction.
            # -   Determine which side of the line edge_aligned_ray_trace_target lies on.
            # -   Choose a target point that is nudged from edge_aligned_ray_trace_target slightly
            #     toward the line.
            # -   Use `intersect_ray` to cast a line into this nudged point and get the normal.
            
            var closest_corner_x := \
                    x_max_just_before_collision if direction.x > 0 else x_min_just_before_collision
            var closest_corner_y := \
                    y_max_just_before_collision if direction.y > 0 else y_min_just_before_collision
            var closest_corner := Vector2(closest_corner_x, closest_corner_y)
            var projected_corner := closest_corner + direction
            perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
            var perdendicular_point := closest_corner + perpendicular_offset
            
            var closest_point_side_of_ray := \
                    (projected_corner.x - closest_corner.x) * \
                    (edge_aligned_ray_trace_target.y - closest_corner.y) - \
                    (projected_corner.y - closest_corner.y) * \
                    (edge_aligned_ray_trace_target.x - closest_corner.x)
            var perpendicular_offset_side_of_ray := \
                    (projected_corner.x - closest_corner.x) * \
                    (perdendicular_point.y - closest_corner.y) - \
                    (projected_corner.y - closest_corner.y) * \
                    (perdendicular_point.x - closest_corner.x)
            
            perpendicular_offset = -perpendicular_offset if \
                    (closest_point_side_of_ray > 0) == \
                            (perpendicular_offset_side_of_ray > 0) else \
                    perpendicular_offset
            should_try_without_perpendicular_nudge_first = false
            
        elif !intersects_along_x or !intersects_along_y:
            # If only one dimension intersects just before collision, then we use that to determine
            # which side we're colliding with.
            
            if intersects_along_x:
                if direction.y > 0:
                    side = SurfaceSide.FLOOR
                else: # direction.y < 0
                    side = SurfaceSide.CEILING
                
                if direction.x > 0:
                    perpendicular_offset = Vector2(VERTEX_SIDE_NUDGE_OFFSET, 0.0)
                else: # direction.x < 0
                    perpendicular_offset = Vector2(-VERTEX_SIDE_NUDGE_OFFSET, 0.0)
            else: # intersects_along_y
                if direction.x > 0:
                    side = SurfaceSide.RIGHT_WALL
                else: # direction.x < 0
                    side = SurfaceSide.LEFT_WALL
                
                if direction.y > 0:
                    perpendicular_offset = Vector2(0.0, VERTEX_SIDE_NUDGE_OFFSET)
                else: # direction.y < 0
                    perpendicular_offset = Vector2(0.0, -VERTEX_SIDE_NUDGE_OFFSET)
            
            should_try_without_perpendicular_nudge_first = false
            
        else:
            # If both dimensions intersect just before collision, then we use the direction of
            # motion to determine which side we're colliding with.
            # This can happen with Player shapes that don't just consist of axially-aligned edges.
            
            if abs(direction.angle_to(Geometry.DOWN)) <= Geometry.FLOOR_MAX_ANGLE:
                side = SurfaceSide.FLOOR
            elif abs(direction.angle_to(Geometry.UP)) <= Geometry.FLOOR_MAX_ANGLE:
                side = SurfaceSide.CEILING
            elif direction.x < 0:
                side = SurfaceSide.LEFT_WALL
            else:
                side = SurfaceSide.RIGHT_WALL
            
            perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
            should_try_without_perpendicular_nudge_first = true    
    
    
    
    var surface_collision := SurfaceCollision.new()
    surface_collision.player_position = position_when_colliding # FIXME: ------- Not defined when only two intersection points.
    if collision_debug_state != null:
        collision_debug_state.collision = surface_collision
    
    _calculate_intersection_point_and_surface( \
            space_state, \
            shape_query_params, \
            surface_parser, \
            edge_aligned_ray_trace_target, \
            direction, \
            perpendicular_offset, \
            side, \
            should_try_without_perpendicular_nudge_first, \
            surface_collision, \
            collision_debug_state)
    
    if !surface_collision.is_valid_collision_state:
        var format_string_template := "An error occurred during collision detection." + \
                "\n\tintersection_points: %s" + \
                "\n\tcollision_ratios: %s" + \
                "\n\tposition_start: %s" + \
                "\n\tmotion: %s" + \
                "\n\tcollider_half_width_height: %s" + \
                "\n\tframe_start_min_coordinates: %s" + \
                "\n\tframe_start_max_coordinates: %s" + \
                "\n\tframe_end_min_coordinates: %s" + \
                "\n\tframe_end_max_coordinates: %s" + \
                "\n\tframe_previous_min_coordinates: %s" + \
                "\n\tframe_previous_max_coordinates: %s"
        var format_string_arguments := [ \
                String(intersection_points), \
                String(space_state.cast_motion(shape_query_params)), \
                String(position_start), \
                String(shape_query_params.motion), \
                String(collider_half_width_height), \
                String(shape_query_params.transform[2] - collider_half_width_height), \
                String(shape_query_params.transform[2] + collider_half_width_height), \
                String(shape_query_params.transform[2] + shape_query_params.motion - \
                        collider_half_width_height), \
                String(shape_query_params.transform[2] + shape_query_params.motion + \
                        collider_half_width_height), \
                String(collision_debug_state.frame_previous_min_coordinates) if \
                        collision_debug_state != null else "?", \
                String(collision_debug_state.frame_previous_max_coordinates) if \
                        collision_debug_state != null else "?", \
            ]
        var message := format_string_template % format_string_arguments
        Utils.error(message, false)
    
    return surface_collision

static func _calculate_intersection_point_and_surface( \
        space_state: Physics2DDirectSpaceState, \
        shape_query_params: Physics2DShapeQueryParameters, \
        surface_parser: SurfaceParser, \
        edge_aligned_ray_trace_target: Vector2, \
        direction: Vector2, \
        perpendicular_offset: Vector2, \
        side: int, \
        should_try_without_perpendicular_nudge_first: bool, \
        surface_collision: SurfaceCollision, \
        collision_debug_state: MovementCalcCollisionDebugState) -> void:
    var tile_map_cell_size := surface_parser.max_tile_map_cell_size
    
    var intersection_point := Vector2.INF
    var surface: Surface
    
    var collision: Dictionary
    var tile_map: TileMap
    var is_touching_floor: bool
    var is_touching_ceiling: bool
    var is_touching_left_wall: bool
    var is_touching_right_wall: bool
    var tile_map_coord := Vector2.INF
    var tile_map_index: int
    
    # Round-off error can sometimes cause smaller offsets to fail, so we try again with larger
    # offsets for those cases.
    for offset_multiplier in [1.0, 4.0, 16.0]:
        # Our calculations can sometimes cause ray-tracing to start from the inside of the relevant
        # tile, which then causes the ray-trace to collide with the wrong side of the tile (from
        # the inside). This error case is caught when we try to get the corresponding surface for
        # the collision. We can correct for this error case by instead ray-casting from the same
        # point, but in the opposite direction.
        for direction_multiplier in [1, -1]:
            # Ray-trace to find the point of intersection and the collision normal.
            collision = _ray_trace_with_nudge( \
                    space_state, \
                    shape_query_params, \
                    tile_map_cell_size, \
                    edge_aligned_ray_trace_target, \
                    direction, \
                    perpendicular_offset, \
                    offset_multiplier, \
                    direction_multiplier, \
                    should_try_without_perpendicular_nudge_first)
            if collision.empty():
                continue
            
            # If we reversed the direction for ray-casting, then we found a collision with the
            # inner-side of the surface, and we need to flip the normal.
            collision.normal *= direction_multiplier
            
            # If we haven't yet defined the surface side, do that now, based off the collision
            # normal.
            if side == SurfaceSide.NONE:
                if abs(collision.normal.angle_to(Geometry.UP)) <= Geometry.FLOOR_MAX_ANGLE:
                    side = SurfaceSide.FLOOR
                elif abs(collision.normal.angle_to(Geometry.DOWN)) <= Geometry.FLOOR_MAX_ANGLE:
                    side = SurfaceSide.CEILING
                elif collision.normal.x > 0:
                    side = SurfaceSide.LEFT_WALL
                else:
                    side = SurfaceSide.RIGHT_WALL
            
            # FIXME: ----------- Should we assert that previously calculated side agrees with collision normal?
            
            intersection_point = collision.position
            tile_map = collision.collider
            
            is_touching_floor = side == SurfaceSide.FLOOR
            is_touching_ceiling = side == SurfaceSide.CEILING
            is_touching_left_wall = side == SurfaceSide.LEFT_WALL
            is_touching_right_wall = side == SurfaceSide.RIGHT_WALL
            tile_map_coord = Geometry.get_collision_tile_map_coord( \
                    intersection_point, tile_map, is_touching_floor, is_touching_ceiling, \
                    is_touching_left_wall, is_touching_right_wall, false)
            if tile_map_coord == Vector2.INF:
                continue
            
            tile_map_index = Geometry.get_tile_map_index_from_grid_coord(tile_map_coord, tile_map)
            
            if surface_parser.has_surface_for_tile( \
                    tile_map, \
                    tile_map_index, \
                    side):
                surface = surface_parser.get_surface_for_tile( \
                        tile_map, \
                        tile_map_index, \
                        side)
                break
        
        if surface != null:
            break
    
    
    # FIXME: Add back in?
#    assert(Geometry.are_points_equal_with_epsilon(collision.position, \
#            edge_aligned_ray_trace_target, perpendicular_offset.length + 0.0001))
    # FIXME: Add back in?
#    assert(surface != null)
    
    # Record return values.
    surface_collision.is_valid_collision_state = \
            intersection_point != Vector2.INF and surface != null
    surface_collision.position = intersection_point
    surface_collision.surface = surface

# Ray-trace to get a bit more information about the collision--specifically, the normal and the
# collider.
# 
# This attempts ray tracing with and without a slight nudge to either side of the original
# calculated ray. This nudging can be important when the point of intersection is a vertex of the
# collider.
static func _ray_trace_with_nudge( \
        space_state: Physics2DDirectSpaceState, \
        shape_query_params: Physics2DShapeQueryParameters, \
        tile_map_cell_size: Vector2, \
        target: Vector2, \
        direction: Vector2, \
        perpendicular_offset: Vector2, \
        offset_multiplier: float, \
        direction_multiplier: int, \
        should_try_without_perpendicular_nudge_first: bool) -> Dictionary:
    var from_offset := direction * -0.001
    # This reduction in vector length can cause x or y components to be lost due to round off, but
    # it's important that we preserve some amount of these.
    if direction.x != 0.0 and from_offset.x < 0.00001 and from_offset.x > -0.00001:
        from_offset.x = 0.001 if from_offset.x > 0 else -0.001
    if direction.y != 0.0 and from_offset.y < 0.00001 and from_offset.y > -0.00001:
        from_offset.y = 0.001 if from_offset.y > 0 else -0.001
    
    var from := target + from_offset * direction_multiplier
    var to := target + \
            direction * (tile_map_cell_size.x + tile_map_cell_size.y) * direction_multiplier
    
    var offset := perpendicular_offset * offset_multiplier
    
    # TODO: It might be worth adding a check before ray-tracing to check whether the starting point
    #       lies within a populated tile in the tilemap, and then trying the other perpendicular
    #       offset direction if so. However, this would require configuring a single global tile
    #       map that we expect collisions from, and plumbing that tile map through to here.
    
    var collision: Dictionary
    
    if should_try_without_perpendicular_nudge_first:
        collision = space_state.intersect_ray( \
                from, \
                to, \
                shape_query_params.exclude, \
                shape_query_params.collision_layer)
        if !collision.empty():
            return collision
    
    collision = space_state.intersect_ray( \
            from + offset, \
            to + offset, \
            shape_query_params.exclude, \
            shape_query_params.collision_layer)
    if !collision.empty():
        return collision
    
    if !should_try_without_perpendicular_nudge_first:
        collision = space_state.intersect_ray( \
                from, \
                to, \
                shape_query_params.exclude, \
                shape_query_params.collision_layer)
        if !collision.empty():
            return collision
    
    collision = space_state.intersect_ray( \
            from - offset, \
            to - offset, \
            shape_query_params.exclude, \
            shape_query_params.collision_layer)
    if !collision.empty():
        return collision
    
    return {}

static func _record_collision_debug_state( \
        collision_debug_state: MovementCalcCollisionDebugState, \
        shape_query_params: Physics2DShapeQueryParameters, \
        collider_half_width_height: Vector2, \
        intersection_points: Array, \
        collision_ratios: Array) -> void:
    collision_debug_state.frame_motion = shape_query_params.motion
    collision_debug_state.frame_previous_position = collision_debug_state.frame_start_position
    collision_debug_state.frame_start_position = shape_query_params.transform[2]
    collision_debug_state.frame_end_position = \
            collision_debug_state.frame_start_position + collision_debug_state.frame_motion
    collision_debug_state.frame_previous_min_coordinates = \
            collision_debug_state.frame_start_min_coordinates
    collision_debug_state.frame_previous_max_coordinates = \
            collision_debug_state.frame_start_max_coordinates
    collision_debug_state.frame_start_min_coordinates = \
            collision_debug_state.frame_start_position - collider_half_width_height
    collision_debug_state.frame_start_max_coordinates = \
            collision_debug_state.frame_start_position + collider_half_width_height
    collision_debug_state.frame_end_min_coordinates = \
            collision_debug_state.frame_end_position - collider_half_width_height
    collision_debug_state.frame_end_max_coordinates = \
            collision_debug_state.frame_end_position + collider_half_width_height
    collision_debug_state.intersection_points = intersection_points
    collision_debug_state.collision_ratios = collision_ratios
    
# Choosees whichever point comes first, along the direction of the motion. If two points are
# equally close, then this chooses whichever point is closest to the starting position.
static func _find_closest_intersection_point( \
        intersection_points: Array, \
        position_start: Vector2, \
        direction: Vector2, \
        collider_half_width_height: Vector2, \
        there_was_a_preexisting_collision: bool) -> Vector2:
    var x_min_start := position_start.x - collider_half_width_height.x
    var x_max_start := position_start.x + collider_half_width_height.x
    var y_min_start := position_start.y - collider_half_width_height.y
    var y_max_start := position_start.y + collider_half_width_height.y
    
    var closest_intersection_point := Vector2.INF
    var other_closest_intersection_point := Vector2.INF
    var current_intersection_point := Vector2.INF
    var closest_projection_onto_motion: float
    var current_projection_onto_motion: float
    
    for i in intersection_points.size():
        current_intersection_point = intersection_points[i]
        
        # Ignore points from pre-existing collisions.
        # 
        # Points that we aren't moving toward can indicate one of two things:
        # 1.  Pre-existing collisions, which exist from the collision margin intersecting
        #     nearby surfaces at the start of the Player's movement.
        # 2.  Clipping a corner of a tile with the Player's collision boundary.
        if there_was_a_preexisting_collision and \
                (direction.x <= 0 and Geometry.is_float_gte_with_epsilon( \
                        current_intersection_point.x, x_max_start, 0.001) or \
                direction.x >= 0 and Geometry.is_float_lte_with_epsilon( \
                        current_intersection_point.x, x_min_start, 0.001) or \
                direction.y <= 0 and Geometry.is_float_gte_with_epsilon( \
                        current_intersection_point.y, y_max_start, 0.001) or \
                direction.y >= 0 and Geometry.is_float_lte_with_epsilon( \
                        current_intersection_point.y, y_min_start, 0.001)):
            continue
        
        current_projection_onto_motion = direction.dot(current_intersection_point)
        
        if Geometry.are_floats_equal_with_epsilon(current_projection_onto_motion, \
                closest_projection_onto_motion):
            # Two points are equally close, so record this so we can compare them afterward.
            other_closest_intersection_point = current_intersection_point
        elif current_projection_onto_motion < closest_projection_onto_motion:
            # We have a new closest point.
            closest_intersection_point = current_intersection_point
            closest_projection_onto_motion = current_projection_onto_motion
            other_closest_intersection_point = Vector2.INF
    
    if closest_intersection_point == Vector2.INF:
        # We are moving away from all of the intersection points.
        return Vector2.INF
    
    if other_closest_intersection_point != Vector2.INF:
        # Two points of intersection were equally close against the direction of motion, so choose
        # whichever point is closest to the starting position.
        var distance_a := closest_intersection_point.distance_squared_to(position_start)
        var distance_b := other_closest_intersection_point.distance_squared_to(position_start)
        closest_intersection_point = closest_intersection_point if distance_a < distance_b else \
                other_closest_intersection_point
    
    return closest_intersection_point

# Checks whether collide_shape returned valid collision points.
# 
# Sometimes, it's possible for collide_shape to return points that could not intersect with the
# player at any point during the motion in this frame. No idea why Godot's collision detection
# is failing here.
# FIXME: Remove?
static func _check_whether_any_intersection_point_lies_within_bounding_box_of_frame( \
        intersection_points: Array, \
        position_start: Vector2, \
        position_end: Vector2, \
        collider_half_width_height: Vector2, \
        collision_margin: float) -> bool:
    var min_x_of_frame := min(position_start.x, position_end.x)
    var max_x_of_frame := max(position_start.x, position_end.x)
    var min_y_of_frame := min(position_start.y, position_end.y)
    var max_y_of_frame := max(position_start.y, position_end.y)
    
    var top_left_point_of_frame := \
            Vector2(min_x_of_frame, min_y_of_frame) - collider_half_width_height
    var bottom_right_point_of_frame := \
            Vector2(max_x_of_frame, max_y_of_frame) + collider_half_width_height
    
    var bounding_box_of_frame := \
            Rect2(top_left_point_of_frame, bottom_right_point_of_frame - top_left_point_of_frame)
    bounding_box_of_frame = bounding_box_of_frame.grow(collision_margin + 0.1)
    
    var do_any_intersection_points_like_within_bounding_box_of_frame := false
    for intersection_point in intersection_points:
        if bounding_box_of_frame.has_point(intersection_point):
            do_any_intersection_points_like_within_bounding_box_of_frame = true
    
    return do_any_intersection_points_like_within_bounding_box_of_frame

# FIXME: F:
# - Move these diagrams out of ASCII and into InkScape.
# - Include in markdown explanation docs.
# - Reference markdown from relevant points in this function.
# - Go through other interesting functions/edge-cases and create diagrams for them too.

# ## How Physics2DDirectSpaceState.collide_shape works
# 
# If we have the two shapes below colliding, then the `o` characters below are the positions
# that collide_shape will return:
# 
#                  +-------------------+
#                  |                   |
#                  |              o----o----+
#                  |              |    |    | <-----
#                  |              |    |    |
#                  |              |    |    | <-----
#                  |              o----o----+
#                  |                   |
#                  +-------------------+
# 
#                  +-------------------+
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |              o----o----+
#                  |              |    |    | <-----
#                  +--------------o----o    |
#                                 |         | <-----
#                                 +---------+
# 
# However, collide_shapes returns incorrect results with tunnelling:
# 
#              o-------------------o
#              |                   |
# +---------+  |                   |
# |         | <----------------------------------
# |         |  |                   |
# |         | <----------------------------------
# +---------+  o                   o <== Best option
#              |                   |
#              +-------------------+
#
# Our collision calculations still work even with the incorrect results from collide_shapes.
# We always choose the one point of intersection that is valid.

# ## Handing pre-existing collisions.
# 
# - These _should_ only happen due to increased margins around the actual Player shape, and at
#   the start of the movement; otherwise, they should have been handled in a previous frame.
# - We can ignore surfaces that we are moving away from, since we can assume that these aren't
#   valid collisions.
# - The valid collision points that we need to consider are any points that are in both the
#   same x and y direction as movement from any corner of the Player's _actual_ shape (not
#   considering the margin). The diagrams below illustrate this:
# 
# (Only the top three points are valid)
#                                          `
#                                  ..............
#                                  .       `    .
#                                  .    +--+    .
#                  +-----------o---o---o|  |    .
#            `   ` | `   `   `   ` . ` |+--+    .
#                  |               .   |        .  __
#                  |               o...o......... |\
#                  |                   |   __       \
#                  |                   |  |\         \
#                  |                   |    \
#                  |                   |     \
#                  +-------------------+
# 
# (None of the points are valid)
#                                       `
#                  +-----------------o-o`
#                  |               o...o.........
#                  |           __  .   |`       .
#                  |            /| .   |+--+    .
#                  |           /   .   ||  |    .
#                  |          /    .   |+--+  ` . `   `   `   `
#                  |               .   |        .
#                  |               o...o.........
#                  +-------------------+  __
#                                          /|
#                                         /
#                                        /

# ## Choose the right side when colliding with a corner.
# 
# `space_state.intersect_ray` could return a normal from either side of an intersected corner.
# However, only one side is correct. The correct side is determined by which dimension
# intersected first. The following diagram helps illustrate this.
#
# Before collision: 
#                  +-------------------+
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  +-------------------+
#                                          +---------+
#                                          |         |
#                                          |         |
#                                          |         |  __
#                                          +---------+ |\
#                                              __        \
#                                             |\          \
#                                               \
#                                                \
# 
# After the shapes intersect along one dimension, but before they intersect along the other:
#     (In this example, the shapes intersect along the y axis, and the correct side for the
#     collision is the right side of the larger shape.)
#                  +-------------------+
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |+---------+
#                  +-------------------+|         |
#                                       |         |
#                                       |         |  __
#                                       +---------+ |\
#                                           __        \
#                                          |\          \
#                                            \
#                                             \
# 
# After the shapes intersect along both dimensions.
#                  +-------------------+
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                   |
#                  |                 o-o-------+
#                  |                 | |       |
#                  |                 | |       |
#                  +-----------------o-o       |  __
#                                    +---------+ |\
#                                        __        \
#                                       |\          \
#                                         \
#                                          \
