tool
class_name SurfacerGeometry
extends ScaffolderGeometry


# Calculates where the alially-aligned surface-side-normal that goes through
# the given point would intersect with the surface.
static func project_point_onto_surface(
        point: Vector2,
        surface: Surface) -> Vector2:
    # Check whether the point lies outside the surface boundaries.
    var start_vertex = surface.first_point
    var end_vertex = surface.last_point
    if surface.side == SurfaceSide.FLOOR and point.x <= start_vertex.x:
        return start_vertex
    elif surface.side == SurfaceSide.FLOOR and point.x >= end_vertex.x:
        return end_vertex
    elif surface.side == SurfaceSide.CEILING and point.x >= start_vertex.x:
        return start_vertex
    elif surface.side == SurfaceSide.CEILING and point.x <= end_vertex.x:
        return end_vertex
    elif surface.side == SurfaceSide.LEFT_WALL and point.y <= start_vertex.y:
        return start_vertex
    elif surface.side == SurfaceSide.LEFT_WALL and point.y >= end_vertex.y:
        return end_vertex
    elif surface.side == SurfaceSide.RIGHT_WALL and point.y >= start_vertex.y:
        return start_vertex
    elif surface.side == SurfaceSide.RIGHT_WALL and point.y <= end_vertex.y:
        return end_vertex
    else:
        # Target lies within the surface boundaries.
        
        # Calculate a segment that represents the alially-aligned
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


# Projects the given point onto the given surface, then offsets the point away
# from the surface (in the direction of the surface normal) to a distance
# corresponding to either the x or y coordinate of the given offset magnitude
# vector.
static func project_point_onto_surface_with_offset(
        point: Vector2,
        surface: Surface,
        offset_magnitude: Vector2) -> Vector2:
    var projection: Vector2 = project_point_onto_surface(
            point,
            surface)
    projection += offset_magnitude * surface.normal
    return projection


# Offsets the point away from the surface (in the direction of the surface
# normal) to a distance corresponding to either the x or y coordinate of the
# given offset magnitude vector.
static func offset_point_from_surface(
        point: Vector2,
        surface: Surface,
        offset_magnitude: Vector2) -> Vector2:
    return point + offset_magnitude * surface.normal


static func get_surface_normal_at_point(
        surface: Surface,
        point: Vector2) -> Vector2:
    if !is_instance_valid(surface):
        return Vector2.INF
    
    var epsilon := 0.01
    
    var vertices := surface.vertices
    var count := vertices.size()
    
    if count <= 1:
        return surface.normal
    
    var segment_start := Vector2.INF
    var segment_end := Vector2.INF
    
    match surface.side:
        SurfaceSide.FLOOR:
            if point.x < vertices[0].x + epsilon:
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.x > vertices[count - 1].x - epsilon:
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                for i in range(1, count):
                    if point.x < vertices[i].x:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        SurfaceSide.LEFT_WALL:
            if point.y < vertices[0].y + epsilon:
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.y > vertices[count - 1].y - epsilon:
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                for i in range(1, count):
                    if point.y < vertices[i].y:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        SurfaceSide.RIGHT_WALL:
            if point.y > vertices[0].y - epsilon:
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.y < vertices[count - 1].y + epsilon:
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                for i in range(1, count):
                    if point.y > vertices[i].y:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        SurfaceSide.CEILING:
            if point.x > vertices[0].x - epsilon:
                segment_start = vertices[0]
                segment_end = vertices[1]
            elif point.x < vertices[count - 1].x + epsilon:
                segment_start = vertices[count - 2]
                segment_end = vertices[count - 1]
            else:
                for i in range(1, count):
                    if point.x > vertices[i].x:
                        segment_start = vertices[i - 1]
                        segment_end = vertices[i]
                        break
        _:
            Sc.logger.error()
    
    var displacement := segment_end - segment_start
    # Displacement is clockwise around convex surfaces, so the normal is the
    # counter-clockwise perpendicular direction from the displacement.
    var perpendicular := Vector2(displacement.y, -displacement.x)
    var normal := perpendicular.normalized()
    
    return normal


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
        side: int) -> KinematicCollision2D:
    if character.surface_state.is_touching_floor:
        for i in character.get_slide_count():
            var collision: KinematicCollision2D = \
                    character.get_slide_collision(i)
            if get_surface_side_for_normal(collision.normal) == side:
                return collision
    return null


static func calculate_displacement_x_for_vertical_distance_past_edge( \
        distance_past_edge: float,
        is_left_wall: bool,
        collider_shape: Shape2D,
        collider_rotation: float) -> float:
    var is_rotated_90_degrees = \
            abs(fmod(collider_rotation + PI * 2, PI) - PI / 2) < \
            Sc.geometry.FLOAT_EPSILON
    
    if collider_shape is CircleShape2D:
        if distance_past_edge >= collider_shape.radius:
            return 0.0
        else:
            return calculate_circular_displacement_x_for_vertical_distance_past_edge(
                    distance_past_edge,
                    collider_shape.radius,
                    is_left_wall)
        
    elif collider_shape is CapsuleShape2D:
        if is_rotated_90_degrees:
            var half_height_offset: float = \
                    collider_shape.height / 2.0 if \
                    is_left_wall else \
                    -collider_shape.height / 2.0
            return calculate_circular_displacement_x_for_vertical_distance_past_edge(
                    distance_past_edge,
                    collider_shape.radius,
                    is_left_wall) + half_height_offset
        else:
            distance_past_edge -= collider_shape.height / 2.0
            if distance_past_edge <= 0:
                # Treat the same as a rectangle.
                return collider_shape.radius if \
                        is_left_wall else \
                        -collider_shape.radius
            else:
                # Treat the same as an offset circle.
                return calculate_circular_displacement_x_for_vertical_distance_past_edge(
                        distance_past_edge,
                        collider_shape.radius,
                        is_left_wall)
        
    elif collider_shape is RectangleShape2D:
        if is_rotated_90_degrees:
            return collider_shape.extents.y if \
                    is_left_wall else \
                    -collider_shape.extents.y
        else:
            return collider_shape.extents.x if \
                    is_left_wall else \
                    -collider_shape.extents.x
        
    else:
        Sc.logger.error((
                "Invalid Shape2D provided for " +
                "calculate_displacement_x_for_vertical_distance_past_edge: %s. " +
                "The supported shapes are: CircleShape2D, CapsuleShape2D, " +
                "RectangleShape2D.") % \
                collider_shape)
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
        collider_shape: Shape2D,
        collider_rotation: float) -> float:
    var is_rotated_90_degrees = \
            abs(fmod(collider_rotation + PI * 2, PI) - PI / 2) < \
            Sc.geometry.FLOAT_EPSILON
    
    if collider_shape is CircleShape2D:
        if distance_past_edge >= collider_shape.radius:
            return 0.0
        else:
            return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
                    distance_past_edge,
                    collider_shape.radius,
                    is_floor)
        
    elif collider_shape is CapsuleShape2D:
        if is_rotated_90_degrees:
            distance_past_edge -= collider_shape.height * 0.5
            if distance_past_edge <= 0:
                # Treat the same as a rectangle.
                return -collider_shape.radius if \
                        is_floor else \
                        collider_shape.radius
            else:
                # Treat the same as an offset circle.
                return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
                        distance_past_edge,
                        collider_shape.radius,
                        is_floor)
        else:
            var half_height_offset: float = \
                    collider_shape.height / 2.0 if \
                    is_floor else \
                    -collider_shape.height / 2.0
            return calculate_circular_displacement_y_for_horizontal_distance_past_edge(
                    distance_past_edge,
                    collider_shape.radius,
                    is_floor) + half_height_offset
        
    elif collider_shape is RectangleShape2D:
        if is_rotated_90_degrees:
            return -collider_shape.extents.x if \
                    is_floor else \
                    collider_shape.extents.x
        else:
            return -collider_shape.extents.y if \
                    is_floor else \
                    collider_shape.extents.y
        
    else:
        Sc.logger.error((
                "Invalid Shape2D provided for " +
                "calculate_displacement_y_for_horizontal_distance_past_edge: %s. " +
                "The supported shapes are: CircleShape2D, CapsuleShape2D, " +
                "RectangleShape2D.") % \
                collider_shape)
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
