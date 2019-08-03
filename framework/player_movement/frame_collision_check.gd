class_name FrameCollisionCheck

# TODO: Adjust this.
const VERTEX_SIDE_NUDGE_OFFSET := 0.001

# Determines whether the given motion of the given shape would collide with a surface. If a
# collision would occur, this returns the surface; otherwise, this returns null.
static func check_frame_for_collision(space_state: Physics2DDirectSpaceState, \
        shape_query_params: Physics2DShapeQueryParameters, collider_half_width_height: Vector2, \
        surface_parser: SurfaceParser, has_recursed := false) -> SurfaceCollision:
    # FIXME: B: Check whether all of the level setup must be called from within an early
    #   _physics_process callback (space might have a lock otherwise)?
    
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
    
    var intersection_points := space_state.collide_shape(shape_query_params, 32)
    assert(intersection_points.size() < 32)
    if intersection_points.empty():
        return null
    
    var direction := shape_query_params.motion.normalized()
    var position_start := shape_query_params.transform.origin
    var x_min_start := position_start.x - collider_half_width_height.x
    var x_max_start := position_start.x + collider_half_width_height.x
    var y_min_start := position_start.y - collider_half_width_height.y
    var y_max_start := position_start.y + collider_half_width_height.y
    
    var current_projection_onto_motion: float
    var closest_projection_onto_motion: float = INF
    var current_intersection_point: Vector2
    var closest_intersection_point := Vector2.INF
    var other_closest_intersection_point := Vector2.INF
    
    # Use Physics2DDirectSpaceState.intersect_ray to get a bit more info about the collision--
    # specifically, the normal and the collider.
    var collision := {}
    
    var side := SurfaceSide.NONE
    var is_touching_floor := false
    var is_touching_ceiling := false
    var is_touching_left_wall := false
    var is_touching_right_wall := false
    # For nudging the ray-tracing a little so that it hits the correct side of the collider vertex.
    var perpendicular_offset: Vector2
    var should_try_without_perpendicular_nudge_first: bool
    
    var ray_trace_target: Vector2
    
    # FIXME: B: Update tests to provide bounding box; add new test for this "corner" case
    
    # FIXME: E:
    # - Problem: Single-point surfaces will fail here (empty collision Dictionary result).
    # - Solution:
    #   - Not sure.
    #   - Might be able to use another space_state method?
    #   - Or, might be able to estimate parameters from other sources:
    #     - Normal according to the direction of motion?
    #     - Position from closest_intersection_point
    #     - Collider from ...
    
    # FIXME: LEFT OFF HERE: DEBUGGING: Remove
    if true:
#    if intersection_points.size() == 2:
#        # `collide_shape` _seems_ to only return two points when we are clipping a corner on our
#        # way past. And it _seems_ as though the two points in these cases are always the corners
#        # of the tile and the Player at this frame time. If those two assumptions are correct, then
#        # we can use the midpoint between these two positions as the target for ray-casting, and
#        # that should get us the correct surface and normal.
#
#        ray_trace_target = \
#                intersection_points[0].linear_interpolate(intersection_points[1], 0.5)
#
#        perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
#        should_try_without_perpendicular_nudge_first = true
#    else:
        # Choose whichever point comes first, along the direction of the motion. If two points are
        # equally close, then choose whichever point is closest to the starting position.
        
        for i in intersection_points.size():
            current_intersection_point = intersection_points[i]
            
            # Ignore any points that we aren't moving toward. Those indicate pre-existing collisions,
            # which should only exist from the collision margin intersecting nearby surfaces at the
            # start of the Player's movement.
            if direction.x <= 0 and current_intersection_point.x >= x_max_start or \
                    direction.x >= 0 and current_intersection_point.x <= x_min_start or \
                    direction.y <= 0 and current_intersection_point.y >= y_max_start or \
                    direction.y >= 0 and current_intersection_point.y <= y_min_start:
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
            # We are moving away from all of the intersection points, so we can assume that there are
            # no new collisions this frame.
            return null
        
        if other_closest_intersection_point != Vector2.INF:
            # Two points of intersection were equally close against the direction of motion, so choose
            # whichever point is closest to the starting position.
            var distance_a := closest_intersection_point.distance_squared_to(position_start)
            var distance_b := other_closest_intersection_point.distance_squared_to(position_start)
            closest_intersection_point = closest_intersection_point if distance_a < distance_b else \
                    other_closest_intersection_point
        
        ray_trace_target = closest_intersection_point
                    
        if direction.x == 0 or direction.y == 0:
            # Moving straight sideways or up-down.
    
            if direction.x == 0:
                if direction.y > 0:
                    side = SurfaceSide.FLOOR
                    is_touching_floor = true
                else: # direction.y < 0
                    side = SurfaceSide.CEILING
                    is_touching_ceiling = true
            elif direction.y == 0:
                if direction.x > 0:
                    side = SurfaceSide.RIGHT_WALL
                    is_touching_right_wall = true
                else: # direction.x < 0
                    side = SurfaceSide.LEFT_WALL
                    is_touching_left_wall = true
            
            perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
            should_try_without_perpendicular_nudge_first = true
        else:
            # Moving at an angle.
            
            var collision_ratios := space_state.cast_motion(shape_query_params)
            
            var position_just_before_collision: Vector2
            if collision_ratios.size() == 2:
                # An array of size 2 means that there was no pre-existing collision.
                
                # A value of 1 means that no collision was detected.
                assert(collision_ratios[0] < 1.0)
                
                position_just_before_collision = \
                        position_start + shape_query_params.motion * collision_ratios[0]
            else: # collision_ratios.size() == 0
                # An empty array means that we were already colliding even before any motion.
                # 
                # - We can assume that this collision actually involves the margin colliding and not
                #   the actual shape.
                # - We can assume that the closest_intersection_point is a point along the outside of a
                #   non-occluded surface, and that this surface is the closest in the direction of
                #   travel.
                
                assert(!has_recursed)
                
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
                shape_query_params.transform = \
                        shape_query_params.transform.translated(-direction * 0.01)
                
                var result := check_frame_for_collision(space_state, shape_query_params, \
                        collider_half_width_height, surface_parser, true)
                
                shape_query_params.margin = original_margin
                shape_query_params.motion = original_motion
                shape_query_params.transform = Transform2D(0.0, position_start)
                
                return result
                
            var x_min_just_before_collision := \
                    position_just_before_collision.x - collider_half_width_height.x
            var x_max_just_before_collision := \
                    position_just_before_collision.x + collider_half_width_height.x
            var y_min_just_before_collision := \
                    position_just_before_collision.y - collider_half_width_height.y
            var y_max_just_before_collision := \
                    position_just_before_collision.y + collider_half_width_height.y
            
            var intersects_along_x := x_min_just_before_collision <= closest_intersection_point.x and \
                    x_max_just_before_collision >= closest_intersection_point.x
            var intersects_along_y := y_min_just_before_collision <= closest_intersection_point.y and \
                    y_max_just_before_collision >= closest_intersection_point.y
            
            if !intersects_along_x and !intersects_along_y:
                # Neither dimension intersects just before collision. This usually just means that
                # `cast_motion` is using too large of a time step.
                # 
                # Here is our workaround:
                # - Pick the closest corner of the non-margin shape. Project a line from it along the 
                #   motion direction.
                # - Determine which side of the line closest_intersection_point lies on.
                # - Choose a target point that is nudged from closest_intersection_point slightly
                #   toward the line.
                # - Use `intersect_ray` to cast a line into this nudged point and get the normal.
                
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
                        (closest_intersection_point.y - closest_corner.y) - \
                        (projected_corner.y - closest_corner.y) * \
                        (closest_intersection_point.x - closest_corner.x)
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
                
            if !intersects_along_x or !intersects_along_y:
                # If only one dimension intersects just before collision, then we use that to determine
                # which side we're colliding with.
                
                if intersects_along_x:
                    if direction.y > 0:
                        side = SurfaceSide.FLOOR
                        is_touching_floor = true
                    else: # direction.y < 0
                        side = SurfaceSide.CEILING
                        is_touching_ceiling = true
                    
                    if direction.x > 0:
                        perpendicular_offset = Vector2(VERTEX_SIDE_NUDGE_OFFSET, 0.0)
                    else: # direction.x < 0
                        perpendicular_offset = Vector2(-VERTEX_SIDE_NUDGE_OFFSET, 0.0)
                else: # intersects_along_y
                    if direction.x > 0:
                        side = SurfaceSide.RIGHT_WALL
                        is_touching_right_wall = true
                    else: # direction.x < 0
                        side = SurfaceSide.LEFT_WALL
                        is_touching_left_wall = true
                    
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
                    is_touching_floor = true
                elif abs(direction.angle_to(Geometry.UP)) <= Geometry.FLOOR_MAX_ANGLE:
                    side = SurfaceSide.CEILING
                    is_touching_ceiling = true
                elif direction.x < 0:
                    side = SurfaceSide.LEFT_WALL
                    is_touching_left_wall = true
                else:
                    side = SurfaceSide.RIGHT_WALL
                    is_touching_right_wall = true
                
                perpendicular_offset = direction.tangent() * VERTEX_SIDE_NUDGE_OFFSET
                should_try_without_perpendicular_nudge_first = true
    
    var from := ray_trace_target - direction * 0.001
    var to := ray_trace_target + direction * 1000000
    
    if should_try_without_perpendicular_nudge_first:
        collision = space_state.intersect_ray(from, to, shape_query_params.exclude, \
                shape_query_params.collision_layer)
    
    # If the ray tracing didn't hit the collider, then try nudging it a little to either side.
    # This can happen when the point of intersection is a vertex of the collider.
    
    if collision.empty():
        collision = space_state.intersect_ray(from + perpendicular_offset, \
                to + perpendicular_offset, shape_query_params.exclude, \
                shape_query_params.collision_layer)
    
    if !should_try_without_perpendicular_nudge_first:
        collision = space_state.intersect_ray(from, to, shape_query_params.exclude, \
                shape_query_params.collision_layer)
        
    if collision.empty():
        collision = space_state.intersect_ray(from - perpendicular_offset, \
                to - perpendicular_offset, shape_query_params.exclude, \
                shape_query_params.collision_layer)
    
    assert(!collision.empty())
    
    # FIXME: Add back in?
#    assert(Geometry.are_points_equal_with_epsilon( \
#            collision.position, ray_trace_target, perpendicular_offset.length + 0.0001))
    
    # If we haven't yet defined the surface side, do that now, based off the collision normal.
    if side == SurfaceSide.NONE:
        if abs(collision.normal.angle_to(Geometry.UP)) <= Geometry.FLOOR_MAX_ANGLE:
            side = SurfaceSide.FLOOR
            is_touching_floor = true
        elif abs(collision.normal.angle_to(Geometry.DOWN)) <= Geometry.FLOOR_MAX_ANGLE:
            side = SurfaceSide.CEILING
            is_touching_ceiling = true
        elif collision.normal.x > 0:
            side = SurfaceSide.LEFT_WALL
            is_touching_left_wall = true
        else:
            side = SurfaceSide.RIGHT_WALL
            is_touching_right_wall = true

    var intersection_point: Vector2 = collision.position
    var tile_map: TileMap = collision.collider
    var tile_map_coord: Vector2 = Geometry.get_collision_tile_map_coord( \
            intersection_point, tile_map, is_touching_floor, is_touching_ceiling, \
            is_touching_left_wall, is_touching_right_wall, false)
    
    # If get_collision_tile_map_coord returns an invalid result, then it's because the motion is
    # moving away from that tile and not into it. This happens when the starting position is within
    # EDGE_MOVEMENT_TEST_MARGIN from a surface.
    if tile_map_coord == Vector2.INF:
        return null
    
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord(tile_map_coord, tile_map)
    
    var surface := surface_parser.get_surface_for_tile(tile_map, tile_map_index, side)
    
    return SurfaceCollision.new(surface, intersection_point)
