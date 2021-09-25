tool
class_name SurfacerGeometry
extends ScaffolderGeometry


# Calculates where the axially-aligned surface-side-normal that goes through
# the given point would intersect with the surface.
static func project_point_onto_surface(
        point: Vector2,
        surface: Surface,
        side_override := SurfaceSide.NONE) -> Vector2:
    var surface_side := \
            surface.side if \
            side_override == SurfaceSide.NONE else \
            side_override
    var start_vertex = surface.first_point
    var end_vertex = surface.last_point
    
    # Check whether the point lies outside the surface boundaries.
    match surface_side:
        SurfaceSide.FLOOR:
            if point.x <= start_vertex.x:
                return start_vertex
            elif point.x >= end_vertex.x:
                return end_vertex
        SurfaceSide.CEILING:
            if point.x >= start_vertex.x:
                return start_vertex
            elif point.x <= end_vertex.x:
                return end_vertex
        SurfaceSide.LEFT_WALL:
            if point.y <= start_vertex.y:
                return start_vertex
            elif point.y >= end_vertex.y:
                return end_vertex
        SurfaceSide.RIGHT_WALL:
            if point.y >= start_vertex.y:
                return start_vertex
            elif point.y <= end_vertex.y:
                return end_vertex
        _:
            Sc.logger.error()
    
    # Target lies within the surface boundaries.
    
    # Calculate a segment that represents the axially-aligned
    # surface-side-normal.
    var segment_a: Vector2
    var segment_b: Vector2
    if surface_side == SurfaceSide.FLOOR or \
            surface_side == SurfaceSide.CEILING:
        segment_a = Vector2(point.x, surface.bounding_box.position.y)
        segment_b = Vector2(point.x, surface.bounding_box.end.y)
    else:
        segment_a = Vector2(surface.bounding_box.position.x, point.y)
        segment_b = Vector2(surface.bounding_box.end.x, point.y)
    
    var intersection: Vector2 = \
            Sc.geometry.get_intersection_of_segment_and_polyline(
                    segment_a,
                    segment_b,
                    surface.vertices)
    assert(intersection != Vector2.INF)
    return intersection


static func get_surface_normal_at_point(
        surface: Surface,
        point: Vector2) -> Vector2:
    if !is_instance_valid(surface):
        return Vector2.INF
    
    if surface.vertices.size() <= 1:
        return surface.normal
    
    var segment_points_result := []
    get_surface_segment_at_point(
            segment_points_result,
            surface,
            point,
            true)
    var segment_start: Vector2 = segment_points_result[0]
    var segment_end: Vector2 = segment_points_result[1]
    
    var displacement := segment_end - segment_start
    # Displacement is clockwise around convex surfaces, so the normal is the
    # counter-clockwise perpendicular direction from the displacement.
    var perpendicular := Vector2(displacement.y, -displacement.x)
    var normal := perpendicular.normalized()
    
    return normal


# -   Calculates where the center position of the given shape would be if it
#     were moved along the axially-aligned surface-side-normal until it just
#     rested against the given surface.
# -   This only considers a maximum of two segments along the surface polyline.
#     -   Most surfaces should be created with long enough segments, relative
#         to character sizes, that this shouldn't be a problem.
static func project_shape_onto_surface(
        shape_position: Vector2,
        shape: RotatedShape,
        surface: Surface,
        uses_end_segment_if_outside_bounds := true,
        side_override := SurfaceSide.NONE) -> Vector2:
    # TODO: Should this also account for the next segment on a neighbor surface?
    
    var surface_side := \
            surface.side if \
            side_override == SurfaceSide.NONE else \
            side_override
    
    if !is_instance_valid(surface):
        return Vector2.INF
    
    if !is_instance_valid(shape):
        return project_point_onto_surface(
                shape_position,
                surface,
                surface_side)
    
    var is_horizontal_surface := \
            surface_side == SurfaceSide.FLOOR or \
            surface_side == SurfaceSide.CEILING
    
    # Allow callers to provide an infinite coordinate for the axis that we're
    # projecting along.
    if is_inf(shape_position.y) and \
            is_horizontal_surface:
        shape_position.y = 0.0
    if is_inf(shape_position.x) and \
            !is_horizontal_surface:
        shape_position.x = 0.0
    
    var shape_min_x := shape_position.x - shape.half_width_height.x
    var shape_max_x := shape_position.x + shape.half_width_height.x
    var shape_min_y := shape_position.y - shape.half_width_height.y
    var shape_max_y := shape_position.y + shape.half_width_height.y
    
    var shape_min_side_point := Vector2.INF
    var shape_max_side_point := Vector2.INF
    if is_horizontal_surface:
        shape_min_side_point = Vector2(shape_min_x, 0.0)
        shape_max_side_point = Vector2(shape_max_x, 0.0)
    else:
        shape_min_side_point = Vector2(0.0, shape_min_y)
        shape_max_side_point = Vector2(0.0, shape_max_y)
    
    if uses_end_segment_if_outside_bounds:
        var nudged_shape_position := shape_position
        if is_horizontal_surface:
            if shape_max_x < surface.bounding_box.position.x + 0.0001:
                nudged_shape_position.x += \
                        surface.bounding_box.position.x + 0.001 - \
                        shape_max_x
            elif shape_min_x > surface.bounding_box.end.x - 0.0001:
                nudged_shape_position.x += \
                        surface.bounding_box.end.x - 0.001 - \
                        shape_min_x
        else:
            if shape_max_y < surface.bounding_box.position.y + 0.0001:
                nudged_shape_position.y += \
                        surface.bounding_box.position.y + 0.001 - \
                        shape_max_y
            elif shape_min_y > surface.bounding_box.end.y - 0.0001:
                nudged_shape_position.y += \
                        surface.bounding_box.end.y - 0.001 - \
                        shape_min_y
        
        if nudged_shape_position != shape_position:
            var nudged_projection := project_shape_onto_surface(
                    nudged_shape_position,
                    shape,
                    surface,
                    uses_end_segment_if_outside_bounds,
                    side_override)
            
            if is_horizontal_surface:
                nudged_projection.x = shape_position.x
            else:
                nudged_projection.y = shape_position.y
            
            return nudged_projection
    
    if surface.vertices.size() <= 1:
        return project_shape_onto_segment(
                shape_position,
                shape,
                surface_side,
                surface.vertices[0],
                surface.vertices[0])
    
    var vertices_to_check := get_vertices_around_range(
            surface,
            shape_min_x,
            shape_max_x,
            shape_min_y,
            shape_max_y)
    
    # Use whichever segment-projection places the shape further away from the
    # surface.
    var furthest_projection := Vector2.INF
    match surface_side:
        SurfaceSide.FLOOR:
            furthest_projection = Vector2.INF
            for i in vertices_to_check.size() - 1:
                var projection := project_shape_onto_segment(
                        shape_position,
                        shape,
                        surface_side,
                        vertices_to_check[i],
                        vertices_to_check[i + 1])
                if projection.y < furthest_projection.y:
                    furthest_projection = projection
        SurfaceSide.LEFT_WALL:
            furthest_projection = -Vector2.INF
            for i in vertices_to_check.size() - 1:
                var projection := project_shape_onto_segment(
                        shape_position,
                        shape,
                        surface_side,
                        vertices_to_check[i],
                        vertices_to_check[i + 1])
                if projection.x > furthest_projection.x:
                    furthest_projection = projection
        SurfaceSide.RIGHT_WALL:
            furthest_projection = Vector2.INF
            for i in vertices_to_check.size() - 1:
                var projection := project_shape_onto_segment(
                        shape_position,
                        shape,
                        surface_side,
                        vertices_to_check[i],
                        vertices_to_check[i + 1])
                if projection.x < furthest_projection.x:
                    furthest_projection = projection
        SurfaceSide.CEILING:
            furthest_projection = -Vector2.INF
            for i in vertices_to_check.size() - 1:
                var projection := project_shape_onto_segment(
                        shape_position,
                        shape,
                        surface_side,
                        vertices_to_check[i],
                        vertices_to_check[i + 1])
                if projection.y > furthest_projection.y:
                    furthest_projection = projection
        _:
            Sc.logger.error()
    
    return furthest_projection


# -   Calculates where the center position of the given shape would be if it
#     were moved along the given axially-aligned surface normal until it just
#     rested against the given segment.
# -   This works for whichever side of the segment the shape starts on.
static func project_shape_onto_segment(
        shape_position: Vector2,
        shape: RotatedShape,
        surface_side: int,
        segment_start: Vector2,
        segment_end: Vector2) -> Vector2:
    var surface_normal: Vector2 = SurfaceSide.get_normal(surface_side)
    
    if !is_instance_valid(shape):
        return Sc.geometry.get_intersection_of_segments(
                    shape_position - surface_normal * 100000.0,
                    shape_position + surface_normal * 100000.0,
                    segment_start,
                    segment_end)
    
    var original_shape_position := shape_position
    var half_width_height := shape.half_width_height
    
    var segment_normal: Vector2
    if segment_end == segment_start:
        segment_normal = surface_normal
    else:
        var segment_displacement := segment_end - segment_start
        # Segment displacement is clockwise around convex surfaces, so the
        # normal is the counter-clockwise perpendicular direction from the
        # displacement.
        var segment_perpendicular := \
                Vector2(segment_displacement.y, -segment_displacement.x)
        segment_normal = segment_perpendicular.normalized()
    
    var leftward_segment_point := Vector2.INF
    var rightward_segment_point := Vector2.INF
    var upper_segment_point := Vector2.INF
    var lower_segment_point := Vector2.INF
    match surface_side:
        SurfaceSide.FLOOR:
            leftward_segment_point = segment_start
            rightward_segment_point = segment_end
        SurfaceSide.LEFT_WALL:
            upper_segment_point = segment_start
            lower_segment_point = segment_end
        SurfaceSide.RIGHT_WALL:
            upper_segment_point = segment_end
            lower_segment_point = segment_start
        SurfaceSide.CEILING:
            leftward_segment_point = segment_end
            rightward_segment_point = segment_start
        _:
            Sc.logger.error()
    
    var segment_tangent := segment_normal.tangent()
    var segment_slope := \
            segment_tangent.y / segment_tangent.x if \
            segment_tangent.x != 0.0 else \
            INF
    
    var is_shape_circle := shape.shape is CircleShape2D
    var is_shape_capsule := shape.shape is CapsuleShape2D
    var is_shape_rectangle := shape.shape is RectangleShape2D
    
    assert(is_shape_circle or \
            is_shape_capsule or \
            is_shape_rectangle)
    
    var projection_displacement_x := INF
    var projection_displacement_y := INF
    
    if is_shape_capsule:
        # All of our capsule-projection cases involve modifying parameters and
        # redirecting to either the circle-handling branch or the
        # rectangle-handling branch.
        
        var radius: float = shape.shape.radius
        var height: float = shape.shape.height
        var half_height := height * 0.5
        
        var is_horizontal_surface := \
                surface_side == SurfaceSide.FLOOR or \
                surface_side == SurfaceSide.CEILING
        
        var capsule_center := shape_position
        
        var leftward_capsule_end_center := Vector2.INF
        var rightward_capsule_end_center := Vector2.INF
        var upper_capsule_end_center := Vector2.INF
        var lower_capsule_end_center := Vector2.INF
        if shape.is_rotated_90_degrees:
            leftward_capsule_end_center = \
                    capsule_center - Vector2(half_height, 0.0)
            rightward_capsule_end_center = \
                    capsule_center + Vector2(half_height, 0.0)
        else:
            upper_capsule_end_center = \
                    capsule_center - Vector2(0.0, half_height)
            lower_capsule_end_center = \
                    capsule_center + Vector2(0.0, half_height)
        
        var circle_half_width_height := Vector2(radius, radius)
        var rectangle_half_width_height := \
                Vector2(half_height, radius) if \
                shape.is_rotated_90_degrees else \
                Vector2(radius, half_height)
        
        if shape.is_rotated_90_degrees != is_horizontal_surface or \
                height == 0.0:
            # If the round-end of the capsule is facing the surface, then we
            # can treat it the same as a circle.
            is_shape_circle = true
            half_width_height = circle_half_width_height
            match surface_side:
                SurfaceSide.FLOOR:
                    shape_position = lower_capsule_end_center
                SurfaceSide.LEFT_WALL:
                    shape_position = leftward_capsule_end_center
                SurfaceSide.RIGHT_WALL:
                    shape_position = rightward_capsule_end_center
                SurfaceSide.CEILING:
                    shape_position = upper_capsule_end_center
                _:
                    Sc.logger.error()
            
        else:
            # The flat-side of the capsule is facing the surface.
            # -   In this case, we can assume that the segment will only ever
            #     contact either round end, unless the segment ends between the
            #     capsule-end centers.
            # -   We can handle the former case by modifying our parameters and
            #     redirecting to our circle-handling branch.
            # -   We can handle the latter case by modifying our parameters and
            #     redirecting to our rectangle-handling branch.
            
            match surface_side:
                SurfaceSide.FLOOR, \
                SurfaceSide.CEILING:
                    if segment_normal.x <= 0:
                        # -   Either is floor, and is level or slopes up to the
                        #     right.
                        # -   Or is ceiling, and is level or slopes up to the
                        #     left.
                        if rightward_segment_point.x <= \
                                leftward_capsule_end_center.x:
                            # We can treat this as a circle-projection with the
                            # left-end of the capsule.
                            is_shape_circle = true
                            shape_position = leftward_capsule_end_center
                            half_width_height = circle_half_width_height
                        elif rightward_segment_point.x < \
                                rightward_capsule_end_center.x:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            half_width_height = rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # right-end of the capsule.
                            is_shape_circle = true
                            shape_position = rightward_capsule_end_center
                            half_width_height = circle_half_width_height
                    else:
                        # -   Either is floor, and slopes up to the left.
                        # -   Or is ceiling, and slopes up to the right.
                        if leftward_segment_point.x >= \
                                rightward_capsule_end_center.x:
                            # We can treat this as a circle-projection with the
                            # right-end of the capsule.
                            is_shape_circle = true
                            shape_position = rightward_capsule_end_center
                            half_width_height = circle_half_width_height
                        elif leftward_segment_point.x > \
                                leftward_capsule_end_center.x:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            half_width_height = rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # left-end of the capsule.
                            is_shape_circle = true
                            shape_position = leftward_capsule_end_center
                            half_width_height = circle_half_width_height
                    
                SurfaceSide.LEFT_WALL, \
                SurfaceSide.RIGHT_WALL:
                    if segment_normal.y <= 0:
                        # -   Either is left-wall, and is level or slopes up to
                        #     the left.
                        # -   Or is right-wall, and is level or slopes up to
                        #     the right.
                        if lower_segment_point.y <= \
                                upper_capsule_end_center.y:
                            # We can treat this as a circle-projection with the
                            # upper-end of the capsule.
                            is_shape_circle = true
                            shape_position = upper_capsule_end_center
                            half_width_height = circle_half_width_height
                        elif lower_segment_point.y < \
                                lower_capsule_end_center.y:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            half_width_height = rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # lower-end of the capsule.
                            is_shape_circle = true
                            shape_position = lower_capsule_end_center
                            half_width_height = circle_half_width_height
                    else:
                        # -   Either is left-wall, and slopes up to the right.
                        # -   Or is right-wall, and slopes up to the left.
                        if upper_segment_point.y >= \
                                lower_capsule_end_center.y:
                            # We can treat this as a circle-projection with the
                            # lower-end of the capsule.
                            is_shape_circle = true
                            shape_position = lower_capsule_end_center
                            half_width_height = circle_half_width_height
                        elif upper_segment_point.y > \
                                upper_capsule_end_center.y:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            half_width_height = rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # upper-end of the capsule.
                            is_shape_circle = true
                            shape_position = upper_capsule_end_center
                            half_width_height = circle_half_width_height
                    
                _:
                    Sc.logger.error()
    
    var shape_min_x := shape_position.x - half_width_height.x
    var shape_max_x := shape_position.x + half_width_height.x
    var shape_min_y := shape_position.y - half_width_height.y
    var shape_max_y := shape_position.y + half_width_height.y
    
    if is_shape_circle:
        # -   There are three possible contact points to consider:
        #     -   Either end of the segment, but only if the circle extends
        #         beyond that end.
        #     -   The point along the circumference of the circle in the
        #         direction of the segment-normal from the circle center.
        # -   We use the closest valid contact point.
        
        var radius: float = shape.shape.radius
        
        match surface_side:
            SurfaceSide.FLOOR, \
            SurfaceSide.CEILING:
                if shape_max_x < leftward_segment_point.x or \
                        shape_min_x > rightward_segment_point.x:
                    # The shape is outside the bounds of the segment.
                    return Vector2.INF
                
                var segment_cast_start := \
                        shape_position - segment_normal * radius * 1.1
                var segment_cast_end := shape_position
                var shape_point_along_normal := \
                        Sc.geometry.get_intersection_of_segment_and_circle(
                                segment_cast_start,
                                segment_cast_end,
                                shape_position,
                                radius,
                                true)
                
                projection_displacement_x = 0.0
                projection_displacement_y = \
                        INF if \
                        surface_side == SurfaceSide.FLOOR else \
                        -INF
                
                if shape_min_x < leftward_segment_point.x:
                    # The shape overlaps with the segment left side.
                    segment_cast_start = \
                            shape_position - surface_normal * radius * 1.1
                    segment_cast_start.x = leftward_segment_point.x
                    segment_cast_end = shape_position
                    segment_cast_end.x = leftward_segment_point.x
                    var possible_contact_point := \
                            Sc.geometry.get_intersection_of_segment_and_circle(
                                    segment_cast_start,
                                    segment_cast_end,
                                    shape_position,
                                    radius,
                                    true)
                    var possible_contact_point_displacement_y := \
                            leftward_segment_point.y - possible_contact_point.y
                    if surface_side == SurfaceSide.FLOOR:
                        projection_displacement_y = min(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                    else:
                        projection_displacement_y = max(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                
                if shape_max_x > rightward_segment_point.x:
                    # The shape overlaps with the segment right side.
                    segment_cast_start = \
                            shape_position - surface_normal * radius * 1.1
                    segment_cast_start.x = rightward_segment_point.x
                    segment_cast_end = shape_position
                    segment_cast_end.x = rightward_segment_point.x
                    var possible_contact_point := \
                            Sc.geometry.get_intersection_of_segment_and_circle(
                                    segment_cast_start,
                                    segment_cast_end,
                                    shape_position,
                                    radius,
                                    true)
                    var possible_contact_point_displacement_y := \
                            rightward_segment_point.y - \
                            possible_contact_point.y
                    if surface_side == SurfaceSide.FLOOR:
                        projection_displacement_y = min(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                    else:
                        projection_displacement_y = max(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                
                if shape_point_along_normal.x > leftward_segment_point.x and \
                        shape_point_along_normal.x < rightward_segment_point.x:
                    # The point along the shape that would contact the line
                    # through the segment, lies within the bounds of the
                    # segment.
                    
                    # Slope formula:
                    #   m = (y2-y1)/(x2-x1)
                    #   y2 = m(x2-x1) + y1
                    var segment_y_at_shape_point_along_normal := \
                            segment_slope * \
                            (shape_point_along_normal.x - \
                                    leftward_segment_point.x) + \
                            leftward_segment_point.y
                    var possible_contact_point_displacement_y := \
                            segment_y_at_shape_point_along_normal - \
                            shape_point_along_normal.y
                    if surface_side == SurfaceSide.FLOOR:
                        projection_displacement_y = min(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                    else:
                        projection_displacement_y = max(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                
            SurfaceSide.LEFT_WALL, \
            SurfaceSide.RIGHT_WALL:
                if shape_max_y < upper_segment_point.y or \
                        shape_min_y > lower_segment_point.y:
                    # The shape is outside the bounds of the segment.
                    return Vector2.INF
                
                var segment_cast_start := \
                        shape_position - segment_normal * radius * 1.1
                var segment_cast_end := shape_position
                var shape_point_along_normal := \
                        Sc.geometry.get_intersection_of_segment_and_circle(
                                segment_cast_start,
                                segment_cast_end,
                                shape_position,
                                radius,
                                true)
                
                projection_displacement_x = \
                        -INF if \
                        surface_side == SurfaceSide.LEFT_WALL else \
                        INF
                projection_displacement_y = 0.0
                
                if shape_min_y < upper_segment_point.y:
                    # The shape overlaps with the segment top side.
                    segment_cast_start = \
                            shape_position - surface_normal * radius * 1.1
                    segment_cast_start.y = upper_segment_point.y
                    segment_cast_end = shape_position
                    segment_cast_end.y = upper_segment_point.y
                    var possible_contact_point := \
                            Sc.geometry.get_intersection_of_segment_and_circle(
                                    segment_cast_start,
                                    segment_cast_end,
                                    shape_position,
                                    radius,
                                    true)
                    var possible_contact_point_displacement_x := \
                            upper_segment_point.x - possible_contact_point.x
                    if surface_side == SurfaceSide.LEFT_WALL:
                        projection_displacement_x = max(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                    else:
                        projection_displacement_x = min(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                
                if shape_max_y > lower_segment_point.y:
                    # The shape overlaps with the segment bottom side.
                    segment_cast_start = \
                            shape_position - surface_normal * radius * 1.1
                    segment_cast_start.y = lower_segment_point.y
                    segment_cast_end = shape_position
                    segment_cast_end.y = lower_segment_point.y
                    var possible_contact_point := \
                            Sc.geometry.get_intersection_of_segment_and_circle(
                                    segment_cast_start,
                                    segment_cast_end,
                                    shape_position,
                                    radius,
                                    true)
                    var possible_contact_point_displacement_x := \
                            lower_segment_point.x - \
                            possible_contact_point.x
                    if surface_side == SurfaceSide.LEFT_WALL:
                        projection_displacement_x = max(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                    else:
                        projection_displacement_x = min(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                
                if shape_point_along_normal.y > upper_segment_point.y and \
                        shape_point_along_normal.y < lower_segment_point.y:
                    # The point along the shape that would contact the line
                    # through the segment, lies within the bounds of the
                    # segment.
                    
                    # Slope formula:
                    #   m = (y2-y1)/(x2-x1)
                    #   x2 = (y2-y1)/m + x1
                    var segment_x_at_shape_point_along_normal := \
                            (shape_point_along_normal.y - \
                                    lower_segment_point.y) / \
                            segment_slope + \
                            lower_segment_point.x
                    var possible_contact_point_displacement_x := \
                            segment_x_at_shape_point_along_normal - \
                            shape_point_along_normal.x
                    if surface_side == SurfaceSide.LEFT_WALL:
                        projection_displacement_x = max(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                    else:
                        projection_displacement_x = min(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                
            _:
                Sc.logger.error()
    
    if is_shape_rectangle:
        # -   There are four possible contact points to consider:
        #     -   Either end of the segment, but only if the rectangle extends
        #         beyond that end.
        #     -   Either of the corners of the rectangle that face the surface,
        #         but only if the segment extends beyond that corner.
        # -   We use the closest valid contact point.
        
        match surface_side:
            SurfaceSide.FLOOR, \
            SurfaceSide.CEILING:
                if shape_max_x < leftward_segment_point.x or \
                        shape_min_x > rightward_segment_point.x:
                    # The shape is outside the bounds of the segment.
                    return Vector2.INF
                
                var shape_close_end_y := \
                        shape_max_y if \
                        surface_side == SurfaceSide.FLOOR else \
                        shape_min_y
                
                projection_displacement_x = 0.0
                projection_displacement_y = \
                        INF if \
                        surface_side == SurfaceSide.FLOOR else \
                        -INF
                
                if shape_min_x < leftward_segment_point.x:
                    # The shape overlaps with the segment left side.
                    var possible_contact_point_displacement_y := \
                            leftward_segment_point.y - shape_close_end_y
                    if surface_side == SurfaceSide.FLOOR:
                        projection_displacement_y = min(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                    else:
                        projection_displacement_y = max(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                
                if shape_max_x > rightward_segment_point.x:
                    # The shape overlaps with the segment right side.
                    var possible_contact_point_displacement_y := \
                            rightward_segment_point.y - shape_close_end_y
                    if surface_side == SurfaceSide.FLOOR:
                        projection_displacement_y = min(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                    else:
                        projection_displacement_y = max(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                
                if shape_min_x > leftward_segment_point.x:
                    # The segment overlaps with the shape left side.
                    
                    # Slope formula:
                    #   m = (y2-y1)/(x2-x1)
                    #   y2 = m(x2-x1) + y1
                    var segment_y_at_shape_left_side := \
                            segment_slope * \
                            (shape_min_x - leftward_segment_point.x) + \
                            leftward_segment_point.y
                    var possible_contact_point_displacement_y := \
                            segment_y_at_shape_left_side - \
                            shape_close_end_y
                    if surface_side == SurfaceSide.FLOOR:
                        projection_displacement_y = min(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                    else:
                        projection_displacement_y = max(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                
                if shape_max_x < rightward_segment_point.x:
                    # The segment overlaps with the shape right side.
                    
                    # Slope formula:
                    #   m = (y2-y1)/(x2-x1)
                    #   y2 = m(x2-x1) + y1
                    var segment_y_at_shape_right_side := \
                            segment_slope * \
                            (shape_max_x - leftward_segment_point.x) + \
                            leftward_segment_point.y
                    var possible_contact_point_displacement_y := \
                            segment_y_at_shape_right_side - \
                            shape_close_end_y
                    if surface_side == SurfaceSide.FLOOR:
                        projection_displacement_y = min(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                    else:
                        projection_displacement_y = max(
                                projection_displacement_y,
                                possible_contact_point_displacement_y)
                
            SurfaceSide.LEFT_WALL, \
            SurfaceSide.RIGHT_WALL:
                if shape_max_y < upper_segment_point.y or \
                        shape_min_y > lower_segment_point.y:
                    # The shape is outside the bounds of the segment.
                    return Vector2.INF
                
                var shape_close_end_x := \
                        shape_max_x if \
                        surface_side == SurfaceSide.RIGHT_WALL else \
                        shape_min_x
                
                projection_displacement_x = \
                        -INF if \
                        surface_side == SurfaceSide.LEFT_WALL else \
                        INF
                projection_displacement_y = 0.0
                
                if shape_min_y < upper_segment_point.y:
                    # The shape overlaps with the segment top side.
                    var possible_contact_point_displacement_x := \
                            upper_segment_point.x - shape_close_end_x
                    if surface_side == SurfaceSide.LEFT_WALL:
                        projection_displacement_x = max(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                    else:
                        projection_displacement_x = min(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                
                if shape_max_y > lower_segment_point.y:
                    # The shape overlaps with the segment bottom side.
                    var possible_contact_point_displacement_x := \
                            lower_segment_point.x - shape_close_end_x
                    if surface_side == SurfaceSide.LEFT_WALL:
                        projection_displacement_x = max(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                    else:
                        projection_displacement_x = min(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                
                if shape_min_y > upper_segment_point.y:
                    # The segment overlaps with the shape top side.
                    
                    # Slope formula:
                    #   m = (y2-y1)/(x2-x1)
                    #   x2 = (y2-y1)/m + x1
                    var segment_x_at_shape_upper_side := \
                            (shape_min_y - lower_segment_point.y) / \
                            segment_slope + \
                            lower_segment_point.x
                    var possible_contact_point_displacement_x := \
                            segment_x_at_shape_upper_side - \
                            shape_close_end_x
                    if surface_side == SurfaceSide.LEFT_WALL:
                        projection_displacement_x = max(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                    else:
                        projection_displacement_x = min(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                
                if shape_max_y < lower_segment_point.y:
                    # The segment overlaps with the shape bottom side.
                    
                    # Slope formula:
                    #   m = (y2-y1)/(x2-x1)
                    #   x2 = (y2-y1)/m + x1
                    var segment_x_at_shape_lower_side := \
                            (shape_max_y - lower_segment_point.y) / \
                            segment_slope + \
                            lower_segment_point.x
                    var possible_contact_point_displacement_x := \
                            segment_x_at_shape_lower_side - \
                            shape_close_end_x
                    if surface_side == SurfaceSide.LEFT_WALL:
                        projection_displacement_x = max(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                    else:
                        projection_displacement_x = min(
                                projection_displacement_x,
                                possible_contact_point_displacement_x)
                
            _:
                Sc.logger.error()
    
    return original_shape_position + \
            Vector2(projection_displacement_x, projection_displacement_y)


static func project_shape_onto_segment_and_away_from_concave_neighbors(
        shape_position: Vector2,
        shape: RotatedShape,
        surface: Surface,
        uses_end_segment_if_outside_bounds := true,
        side_override := SurfaceSide.NONE) -> Vector2:
    var projection := project_shape_onto_surface(
            shape_position,
            shape,
            surface,
            uses_end_segment_if_outside_bounds,
            side_override)
    
    var cw_neighbor := surface.clockwise_neighbor
    var is_cw_neighbor_concave := \
            cw_neighbor == surface.clockwise_concave_neighbor
    if is_cw_neighbor_concave:
        var cw_neighbor_normal_side_override := \
                get_concave_neighbor_projection_side_override(surface, true)
        projection = project_away_from_concave_neighbor(
                projection,
                cw_neighbor,
                cw_neighbor_normal_side_override,
                shape)
    
    var ccw_neighbor := surface.clockwise_neighbor
    var is_ccw_neighbor_concave := \
            ccw_neighbor == surface.clockwise_concave_neighbor
    if is_ccw_neighbor_concave:
        var ccw_neighbor_normal_side_override := \
                get_concave_neighbor_projection_side_override(surface, false)
        projection = project_away_from_concave_neighbor(
                projection,
                ccw_neighbor,
                ccw_neighbor_normal_side_override,
                shape)
    
    return projection


static func get_concave_neighbor_projection_side_override(
        surface: Surface,
        is_clockwise: bool) -> int:
    match surface.side:
        SurfaceSide.FLOOR:
            return SurfaceSide.RIGHT_WALL if \
                    is_clockwise else \
                    SurfaceSide.LEFT_WALL
        SurfaceSide.LEFT_WALL:
            return SurfaceSide.FLOOR if \
                    is_clockwise else \
                    SurfaceSide.CEILING
        SurfaceSide.RIGHT_WALL:
            return SurfaceSide.CEILING if \
                    is_clockwise else \
                    SurfaceSide.FLOOR
        SurfaceSide.CEILING:
            return SurfaceSide.LEFT_WALL if \
                    is_clockwise else \
                    SurfaceSide.RIGHT_WALL
        _:
            Sc.logger.error()
            return SurfaceSide.NONE


static func project_away_from_concave_neighbor(
        position: Vector2,
        neighbor: Surface,
        neighbor_normal_side_override: int,
        shape: RotatedShape) -> Vector2:
    # Broad-phase check: Can these be intersecting?
    if !check_for_shape_to_rect_intersection(
            position,
            shape,
            neighbor.bounding_box):
        return Vector2.INF
    
    var concave_neighbor_projection := project_shape_onto_surface(
            position,
            shape,
            neighbor,
            true,
            neighbor_normal_side_override)
    
    match neighbor_normal_side_override:
        SurfaceSide.FLOOR:
            if concave_neighbor_projection.y < position.y:
                position.y = concave_neighbor_projection.y
                return position
        SurfaceSide.LEFT_WALL:
            if concave_neighbor_projection.x > position.x:
                position.x = concave_neighbor_projection.x
                return position
        SurfaceSide.RIGHT_WALL:
            if concave_neighbor_projection.x < position.x:
                position.x = concave_neighbor_projection.x
                return position
        SurfaceSide.CEILING:
            if concave_neighbor_projection.y > position.y:
                position.y = concave_neighbor_projection.y
                return position
        _:
            Sc.logger.error()
    
    return Vector2.INF


static func check_for_shape_to_rect_intersection(
        shape_position: Vector2,
        shape: RotatedShape,
        rect: Rect2) -> bool:
    return rect.position.x < shape_position.x + shape.half_width_height.x and \
            rect.end.x > shape_position.x - shape.half_width_height.x and \
            rect.position.y < shape_position.y + shape.half_width_height.y and \
            rect.end.y > shape_position.y - shape.half_width_height.y


# -   Finds the end points of the segment along the given surface that the
#     axially-aligned projection of the given point onto the surface would
#     intersect.
static func get_surface_segment_at_point(
        segment_points_result: Array,
        surface: Surface,
        point: Vector2,
        uses_end_segment_if_outside_bounds := true) -> void:
    if !is_instance_valid(surface):
        segment_points_result.resize(0)
        return
    
    var epsilon := 0.01
    
    var vertices := surface.vertices
    var count := vertices.size()
    
    if count <= 1:
        segment_points_result.resize(0)
        return
    
    var inside_bounds := false
    var segment_start := Vector2.INF
    var segment_end := Vector2.INF
    
    match surface.side:
        SurfaceSide.FLOOR:
            if point.x < vertices[0].x + epsilon:
                inside_bounds = false
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.x > vertices[count - 1].x - epsilon:
                inside_bounds = false
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                inside_bounds = true
                for i in range(1, count):
                    if point.x < vertices[i].x:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        SurfaceSide.LEFT_WALL:
            if point.y < vertices[0].y + epsilon:
                inside_bounds = false
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.y > vertices[count - 1].y - epsilon:
                inside_bounds = false
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                inside_bounds = true
                for i in range(1, count):
                    if point.y < vertices[i].y:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        SurfaceSide.RIGHT_WALL:
            if point.y > vertices[0].y - epsilon:
                inside_bounds = false
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.y < vertices[count - 1].y + epsilon:
                inside_bounds = false
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                inside_bounds = true
                for i in range(1, count):
                    if point.y > vertices[i].y:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        SurfaceSide.CEILING:
            if point.x > vertices[0].x - epsilon:
                inside_bounds = false
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.x < vertices[count - 1].x + epsilon:
                inside_bounds = false
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                inside_bounds = true
                for i in range(1, count):
                    if point.x > vertices[i].x:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        _:
            Sc.logger.error()
    
    if inside_bounds or \
            uses_end_segment_if_outside_bounds:
        segment_points_result.resize(2)
        segment_points_result[0] = segment_start
        segment_points_result[1] = segment_end
    else:
        segment_points_result.resize(0)


static func get_vertices_around_range(
        surface: Surface,
        range_min_x: float,
        range_max_x: float,
        range_min_y: float,
        range_max_y: float) -> Array:
    if !is_instance_valid(surface):
        return []
    
    var epsilon := 0.01
    
    var vertices := surface.vertices
    var count := vertices.size()
    
    if count <= 1:
        return [surface.vertices[0]]
    
    var start_index: int
    var end_index: int
    
    match surface.side:
        SurfaceSide.FLOOR:
            start_index = 0
            for i in count:
                if vertices[i].x > range_min_x:
                    start_index = i - 1
                    break
            start_index = max(start_index, 0)
            
            end_index = start_index + 1
            for i in range(end_index, count):
                end_index = i
                if vertices[i].x > range_max_x:
                    break
        SurfaceSide.LEFT_WALL:
            start_index = 0
            for i in count:
                if vertices[i].y > range_min_y:
                    start_index = i - 1
                    break
            start_index = max(start_index, 0)
            
            end_index = start_index + 1
            for i in range(end_index, count):
                end_index = i
                if vertices[i].y > range_max_y:
                    break
        SurfaceSide.RIGHT_WALL:
            start_index = 0
            for i in count:
                if vertices[i].y < range_max_y:
                    start_index = i - 1
                    break
            start_index = max(start_index, 0)
            
            end_index = start_index + 1
            for i in range(end_index, count):
                end_index = i
                if vertices[i].y < range_min_y:
                    break
        SurfaceSide.CEILING:
            start_index = 0
            for i in count:
                if vertices[i].x < range_max_x:
                    start_index = i - 1
                    break
            start_index = max(start_index, 0)
            
            end_index = start_index + 1
            for i in range(end_index, count):
                end_index = i
                if vertices[i].x < range_min_x:
                    break
        _:
            Sc.logger.error()
    
    var result_size := end_index - start_index + 1
    var result := []
    result.resize(result_size)
    for i in result_size:
        result[i] = vertices[start_index + i]
    
    return result


static func are_position_wrappers_equal_with_epsilon(
        a: PositionAlongSurface,
        b: PositionAlongSurface,
        epsilon := ScaffolderGeometry.FLOAT_EPSILON) -> bool:
    if a == null and b == null:
        return true
    elif a == null or b == null:
        return false
    elif a.surface != b.surface:
        return false
    var x_diff = b.target_point.x - a.target_point.x
    var y_diff = b.target_point.y - a.target_point.y
    return -epsilon < x_diff and x_diff < epsilon and \
            -epsilon < y_diff and y_diff < epsilon


static func get_surface_side_for_normal(normal: Vector2) -> int:
    if abs(normal.angle_to(Sc.geometry.UP)) <= \
            Sc.geometry.FLOOR_MAX_ANGLE + Sc.geometry.WALL_ANGLE_EPSILON:
        return SurfaceSide.FLOOR
    elif abs(normal.angle_to(Sc.geometry.DOWN)) <= \
            Sc.geometry.FLOOR_MAX_ANGLE + Sc.geometry.WALL_ANGLE_EPSILON:
        return SurfaceSide.CEILING
    elif normal.x > 0:
        return SurfaceSide.LEFT_WALL
    else:
        return SurfaceSide.RIGHT_WALL


static func get_floor_friction_multiplier(character) -> float:
    var collision := _get_collision_for_side(character, SurfaceSide.FLOOR)
    # Collision friction is a property of the TileMap node.
    if collision != null and \
            collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0.0


static func _get_collision_for_side(
        character,
        side: int) -> KinematicCollision2DCopy:
    if character.surface_state.is_touching_floor:
        for collision in character.collisions:
            if get_surface_side_for_normal(collision.normal) == side:
                return collision
    return null


static func project_shape_onto_convex_corner_preserving_tangent_position( \
        shape_position: Vector2,
        shape: RotatedShape,
        origin_surface: Surface,
        destination_surface: Surface) -> Vector2:
    var projection := Vector2.INF
    
    if Su.are_oddly_shaped_surfaces_used and \
            (is_instance_valid(origin_surface) or \
            is_instance_valid(destination_surface)):
        
        var destination_projection := Vector2.INF
        if is_instance_valid(destination_surface):
            destination_projection = project_shape_onto_surface(
                    shape_position,
                    shape,
                    destination_surface,
                    true,
                    origin_surface.side)
        
        var origin_projection := Vector2.INF
        if is_instance_valid(origin_surface):
            origin_projection = project_shape_onto_surface(
                    shape_position,
                    shape,
                    origin_surface,
                    true,
                    origin_surface.side)
        
        var is_destination_projection_valid := \
                !is_inf(destination_projection.x) and \
                !is_inf(destination_projection.y)
        
        match origin_surface.side:
            SurfaceSide.FLOOR:
                if is_destination_projection_valid and \
                        destination_projection.y < origin_projection.y:
                    return destination_projection
                else:
                    return origin_projection
            SurfaceSide.LEFT_WALL:
                if is_destination_projection_valid and \
                        destination_projection.x > origin_projection.x:
                    return destination_projection
                else:
                    return origin_projection
            SurfaceSide.RIGHT_WALL:
                if is_destination_projection_valid and \
                        destination_projection.x < origin_projection.x:
                    return destination_projection
                else:
                    return origin_projection
            SurfaceSide.CEILING:
                if is_destination_projection_valid and \
                        destination_projection.y > origin_projection.y:
                    return destination_projection
                else:
                    return origin_projection
            _:
                Sc.logger.error()
        
    else:
        # TODO: Implement this case. Redirect to
        #       calculate_displacement_x_for_vertical_distance_past_edge and
        #       calculate_displacement_y_for_horizontal_distance_past_edge.
        Sc.logger.error("Not implemented yet.")
    
    return projection


static func calculate_displacement_x_for_vertical_distance_past_edge( \
        distance_past_edge: float,
        is_left_wall: bool,
        collider: RotatedShape) -> float:
    if collider.shape is CircleShape2D:
        if distance_past_edge >= collider.shape.radius:
            return 0.0
        else:
            return calculate_circular_displacement_x_for_vertical_distance_past_edge(
                    distance_past_edge,
                    collider.shape.radius,
                    is_left_wall)
        
    elif collider.shape is CapsuleShape2D:
        if collider.is_rotated_90_degrees:
            var half_height_offset: float = \
                    collider.shape.height / 2.0 if \
                    is_left_wall else \
                    -collider.shape.height / 2.0
            return calculate_circular_displacement_x_for_vertical_distance_past_edge(
                    distance_past_edge,
                    collider.shape.radius,
                    is_left_wall) + half_height_offset
        else:
            distance_past_edge -= collider.shape.height / 2.0
            if distance_past_edge <= 0:
                # Treat the same as a rectangle.
                return collider.shape.radius if \
                        is_left_wall else \
                        -collider.shape.radius
            else:
                # Treat the same as an offset circle.
                return calculate_circular_displacement_x_for_vertical_distance_past_edge(
                        distance_past_edge,
                        collider.shape.radius,
                        is_left_wall)
        
    elif collider.shape is RectangleShape2D:
        if collider.is_rotated_90_degrees:
            return collider.shape.extents.y if \
                    is_left_wall else \
                    -collider.shape.extents.y
        else:
            return collider.shape.extents.x if \
                    is_left_wall else \
                    -collider.shape.extents.x
        
    else:
        Sc.logger.error((
                "Invalid Shape2D provided for " +
                "calculate_displacement_x_for_vertical_distance_past_edge: %s. " +
                "The supported shapes are: CircleShape2D, CapsuleShape2D, " +
                "RectangleShape2D.") % \
                collider.shape)
        return INF


static func calculate_circular_displacement_x_for_vertical_distance_past_edge(
        distance_past_edge: float,
        radius: float,
        is_left_wall: bool) -> float:
    var distance_x := \
            0.0 if \
            distance_past_edge >= radius else \
            sqrt(radius * radius - distance_past_edge * distance_past_edge)
    return distance_x if \
            is_left_wall else \
            -distance_x


static func calculate_displacement_y_for_horizontal_distance_past_edge( \
        distance_past_edge: float,
        is_floor: bool,
        collider: RotatedShape) -> float:
    if collider.shape is CircleShape2D:
        if distance_past_edge >= collider.shape.radius:
            return 0.0
        else:
            return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
                    distance_past_edge,
                    collider.shape.radius,
                    is_floor)
        
    elif collider.shape is CapsuleShape2D:
        if collider.is_rotated_90_degrees:
            distance_past_edge -= collider.shape.height * 0.5
            if distance_past_edge <= 0:
                # Treat the same as a rectangle.
                return -collider.shape.radius if \
                        is_floor else \
                        collider.shape.radius
            else:
                # Treat the same as an offset circle.
                return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
                        distance_past_edge,
                        collider.shape.radius,
                        is_floor)
        else:
            var half_height_offset: float = \
                    collider.shape.height / 2.0 if \
                    is_floor else \
                    -collider.shape.height / 2.0
            return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
                    distance_past_edge,
                    collider.shape.radius,
                    is_floor) + half_height_offset
        
    elif collider.shape is RectangleShape2D:
        if collider.is_rotated_90_degrees:
            return -collider.shape.extents.x if \
                    is_floor else \
                    collider.shape.extents.x
        else:
            return -collider.shape.extents.y if \
                    is_floor else \
                    collider.shape.extents.y
        
    else:
        Sc.logger.error((
                "Invalid Shape2D provided for " +
                "calculate_displacement_y_for_horizontal_distance_past_edge: %s. " +
                "The supported shapes are: CircleShape2D, CapsuleShape2D, " +
                "RectangleShape2D.") % \
                collider.shape)
        return INF


static func calculate_circular_displacement_y_for_horizontal_distance_past_edge(
        distance_past_edge: float,
        radius: float,
        is_floor: bool) -> float:
    var distance_y := \
            0.0 if \
            distance_past_edge >= radius else \
            sqrt(radius * radius - distance_past_edge * distance_past_edge)
    return -distance_y if \
            is_floor else \
            distance_y
