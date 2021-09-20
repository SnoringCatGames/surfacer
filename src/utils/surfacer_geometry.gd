tool
class_name SurfacerGeometry
extends ScaffolderGeometry


# Calculates where the axially-aligned surface-side-normal that goes through
# the given point would intersect with the surface.
static func project_point_onto_surface(
        point: Vector2,
        surface: Surface) -> Vector2:
    var start_vertex = surface.first_point
    var end_vertex = surface.last_point
    
    # Check whether the point lies outside the surface boundaries.
    match surface.side:
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
    if surface.side == SurfaceSide.FLOOR or \
            surface.side == SurfaceSide.CEILING:
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
        uses_end_segment_if_outside_bounds := true) -> Vector2:
    # TODO: Should this also account for the next segment on a neighbor surface?
    
    if !is_instance_valid(surface):
        return Vector2.INF
    
    if surface.vertices.size() <= 1:
        return project_shape_onto_segment(
                shape_position,
                shape,
                surface.side,
                surface.vertices[0],
                surface.vertices[0])
    
    var shape_min_x := shape_position.x - shape.half_width_height.x
    var shape_max_x := shape_position.x + shape.half_width_height.x
    var shape_min_y := shape_position.y - shape.half_width_height.y
    var shape_max_y := shape_position.y + shape.half_width_height.y
    
    var shape_min_side_point := Vector2.INF
    var shape_max_side_point := Vector2.INF
    match surface.side:
        SurfaceSide.FLOOR, \
        SurfaceSide.CEILING:
            shape_min_side_point = Vector2(shape_min_x, 0.0)
            shape_max_side_point = Vector2(shape_max_x, 0.0)
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            shape_min_side_point = Vector2(0.0, shape_min_y)
            shape_max_side_point = Vector2(0.0, shape_max_y)
        _:
            Sc.logger.error()
    
    if uses_end_segment_if_outside_bounds:
        var is_horizontal_surface := \
                surface.side == SurfaceSide.FLOOR or \
                surface.side == SurfaceSide.CEILING
        
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
                    uses_end_segment_if_outside_bounds)
            
            if is_horizontal_surface:
                nudged_projection.x = shape_position.x
            else:
                nudged_projection.y = shape_position.y
            
            return nudged_projection
    
    var segment_points_result := []
    
    get_surface_segment_at_point(
            segment_points_result,
            surface,
            shape_min_side_point,
            uses_end_segment_if_outside_bounds)
    var min_side_segment_start := Vector2.INF
    var min_side_segment_end := Vector2.INF
    if !segment_points_result.empty():
        min_side_segment_start = segment_points_result[0]
        min_side_segment_end = segment_points_result[1]
    
    get_surface_segment_at_point(
            segment_points_result,
            surface,
            shape_max_side_point,
            uses_end_segment_if_outside_bounds)
    var max_side_segment_start := Vector2.INF
    var max_side_segment_end := Vector2.INF
    if !segment_points_result.empty():
        max_side_segment_start = segment_points_result[0]
        max_side_segment_end = segment_points_result[1]
    
    # Both ends of the shape project onto the same segment, so ignore one copy.
    if min_side_segment_start == max_side_segment_start:
        assert(min_side_segment_start != Vector2.INF)
        max_side_segment_start = Vector2.INF
        max_side_segment_end = Vector2.INF
    
    # Only one of the two possible segments is valid, so ignore the other.
    if min_side_segment_start == Vector2.INF or \
            max_side_segment_start == Vector2.INF:
        var segment_start: Vector2
        var segment_end: Vector2
        if min_side_segment_start == Vector2.INF:
            segment_start = max_side_segment_start
            segment_end = max_side_segment_end
        else:
            segment_start = min_side_segment_start
            segment_end = min_side_segment_end
        
        return project_shape_onto_segment(
                shape_position,
                shape,
                surface.side,
                segment_start,
                segment_end)
    
    # Both possible segments are valid, so use whichever projects the shape
    # further away.
    var min_side_segment_projection := project_shape_onto_segment(
            shape_position,
            shape,
            surface.side,
            min_side_segment_start,
            min_side_segment_end)
    var max_side_segment_projection := project_shape_onto_segment(
            shape_position,
            shape,
            surface.side,
            max_side_segment_start,
            max_side_segment_end)
    match surface.side:
        SurfaceSide.FLOOR:
            if min_side_segment_projection.y < max_side_segment_projection.y:
                return min_side_segment_projection
            else:
                return max_side_segment_projection
        SurfaceSide.LEFT_WALL:
            if min_side_segment_projection.x < max_side_segment_projection.x:
                return max_side_segment_projection
            else:
                return min_side_segment_projection
        SurfaceSide.RIGHT_WALL:
            if min_side_segment_projection.x < max_side_segment_projection.x:
                return min_side_segment_projection
            else:
                return max_side_segment_projection
        SurfaceSide.CEILING:
            if min_side_segment_projection.y < max_side_segment_projection.y:
                return max_side_segment_projection
            else:
                return min_side_segment_projection
        _:
            Sc.logger.error()
            return Vector2.INF


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
    
    var segment_displacement := segment_end - segment_start
    # Segment displacement is clockwise around convex surfaces, so the normal
    # is the counter-clockwise perpendicular direction from the displacement.
    var segment_perpendicular := \
            Vector2(segment_displacement.y, -segment_displacement.x)
    var segment_normal := segment_perpendicular.normalized()
    
    var shape_min_x := shape_position.x - shape.half_width_height.x
    var shape_max_x := shape_position.x + shape.half_width_height.x
    var shape_min_y := shape_position.y - shape.half_width_height.y
    var shape_max_y := shape_position.y + shape.half_width_height.y
    
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
    
    var segment_slope: float
    match surface_side:
        SurfaceSide.FLOOR, \
        SurfaceSide.CEILING:
            var numerator := \
                    rightward_segment_point.y - leftward_segment_point.y
            var denominator := \
                    rightward_segment_point.x - leftward_segment_point.x
            segment_slope = \
                    numerator / denominator if \
                    denominator != 0.0 else \
                    INF
        SurfaceSide.LEFT_WALL, \
        SurfaceSide.RIGHT_WALL:
            var numerator := upper_segment_point.y - lower_segment_point.y
            var denominator := upper_segment_point.x - lower_segment_point.x
            segment_slope = \
                    numerator / denominator if \
                    denominator != 0.0 else \
                    INF
        _:
            Sc.logger.error()
    
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
            shape.half_width_height = circle_half_width_height
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
                        if rightward_segment_point.x < \
                                leftward_capsule_end_center.x:
                            # We can treat this as a circle-projection with the
                            # left-end of the capsule.
                            is_shape_circle = true
                            shape_position = leftward_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                        elif rightward_segment_point.x < \
                                rightward_capsule_end_center.x:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            shape.half_width_height = \
                                    rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # right-end of the capsule.
                            is_shape_circle = true
                            shape_position = rightward_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                    else:
                        # -   Either is floor, and slopes up to the left.
                        # -   Or is ceiling, and slopes up to the right.
                        if leftward_segment_point.x > \
                                rightward_capsule_end_center.x:
                            # We can treat this as a circle-projection with the
                            # right-end of the capsule.
                            is_shape_circle = true
                            shape_position = rightward_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                        elif leftward_segment_point.x > \
                                leftward_capsule_end_center.x:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            shape.half_width_height = \
                                    rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # left-end of the capsule.
                            is_shape_circle = true
                            shape_position = leftward_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                    
                SurfaceSide.LEFT_WALL, \
                SurfaceSide.RIGHT_WALL:
                    if segment_normal.y <= 0:
                        # -   Either is left-wall, and is level or slopes up to
                        #     the left.
                        # -   Or is right-wall, and is level or slopes up to
                        #     the right.
                        if lower_segment_point.y < \
                                upper_capsule_end_center.y:
                            # We can treat this as a circle-projection with the
                            # upper-end of the capsule.
                            is_shape_circle = true
                            shape_position = upper_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                        elif lower_segment_point.y < \
                                lower_capsule_end_center.y:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            shape.half_width_height = \
                                    rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # lower-end of the capsule.
                            is_shape_circle = true
                            shape_position = lower_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                    else:
                        # -   Either is left-wall, and slopes up to the right.
                        # -   Or is right-wall, and slopes up to the left.
                        if upper_segment_point.y > \
                                lower_capsule_end_center.y:
                            # We can treat this as a circle-projection with the
                            # lower-end of the capsule.
                            is_shape_circle = true
                            shape_position = lower_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                        elif upper_segment_point.y > \
                                upper_capsule_end_center.y:
                            # We can treat this as a rectangle-projection with
                            # the center of the capsule.
                            is_shape_rectangle = true
                            shape_position = capsule_center
                            shape.half_width_height = \
                                    rectangle_half_width_height
                        else:
                            # We can treat this as a circle-projection with the
                            # upper-end of the capsule.
                            is_shape_circle = true
                            shape_position = upper_capsule_end_center
                            shape.half_width_height = circle_half_width_height
                    
                _:
                    Sc.logger.error()
    
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
                projection_displacement_y = INF
                
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
                    projection_displacement_y = min(
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
                    projection_displacement_y = min(
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
                    projection_displacement_y = min(
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
                
                projection_displacement_x = INF
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
                projection_displacement_y = INF
                
                if shape_min_x < leftward_segment_point.x:
                    # The shape overlaps with the segment left side.
                    var possible_contact_point_displacement_y := \
                            leftward_segment_point.y - shape_close_end_y
                    projection_displacement_y = min(
                            projection_displacement_y,
                            possible_contact_point_displacement_y)
                
                if shape_max_x > rightward_segment_point.x:
                    # The shape overlaps with the segment right side.
                    var possible_contact_point_displacement_y := \
                            rightward_segment_point.y - shape_close_end_y
                    projection_displacement_y = min(
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
                    projection_displacement_y = min(
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
                    projection_displacement_y = min(
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
                
                projection_displacement_x = INF
                projection_displacement_y = 0.0
                
                if shape_min_y < upper_segment_point.y:
                    # The shape overlaps with the segment top side.
                    var possible_contact_point_displacement_x := \
                            upper_segment_point.x - shape_close_end_x
                    projection_displacement_x = min(
                            projection_displacement_x,
                            possible_contact_point_displacement_x)
                
                if shape_max_y > lower_segment_point.y:
                    # The shape overlaps with the segment bottom side.
                    var possible_contact_point_displacement_x := \
                            lower_segment_point.x - shape_close_end_x
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
                    projection_displacement_x = min(
                            projection_displacement_x,
                            possible_contact_point_displacement_x)
                
            _:
                Sc.logger.error()
    
    return shape_position + \
            Vector2(projection_displacement_x, projection_displacement_y)


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
