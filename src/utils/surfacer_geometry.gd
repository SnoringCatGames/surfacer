tool
class_name SurfacerGeometry
extends ScaffolderGeometry


# TODO: We might want to instead replace this with a ratio (like 1.1) of the
#       KinematicBody2D.get_safe_margin value (defaults to 0.08, but we set it
#       higher during graph calculations).
const COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD := 0.5


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
            Sc.geometry.FLOOR_MAX_ANGLE:
        return SurfaceSide.FLOOR
    elif abs(normal.angle_to(Sc.geometry.DOWN)) <= \
            Sc.geometry.FLOOR_MAX_ANGLE:
        return SurfaceSide.CEILING
    elif normal.x > 0:
        return SurfaceSide.LEFT_WALL
    else:
        return SurfaceSide.RIGHT_WALL


static func get_floor_friction_multiplier(player) -> float:
    var collision := _get_collision_for_side(player, SurfaceSide.FLOOR)
    # Collision friction is a property of the TileMap node.
    if collision != null and \
            collision.collider.collision_friction != null:
        return collision.collider.collision_friction
    return 0.0


static func _get_collision_for_side(
        player,
        side: int) -> KinematicCollision2D:
    if player.surface_state.is_touching_floor:
        for i in player.get_slide_count():
            var collision: KinematicCollision2D = player.get_slide_collision(i)
            if get_surface_side_for_normal(collision.normal) == side:
                return collision
    return null


static func get_collision_tile_map_coord(
        result: CollisionTileMapCoordResult,
        collision_position: Vector2,
        tile_map: TileMap,
        is_touching_floor: bool,
        is_touching_ceiling: bool,
        is_touching_left_wall: bool,
        is_touching_right_wall: bool,
        allows_errors := false) -> void:
    var half_cell_size := tile_map.cell_size / 2.0
    var used_rect := tile_map.get_used_rect()
    var tile_map_top_left_position_world_coord := \
            tile_map.position - used_rect.position * tile_map.cell_size
    var position_relative_to_tile_map := \
            collision_position - tile_map_top_left_position_world_coord
    
    var cell_width_mod := abs(fmod(
            position_relative_to_tile_map.x,
            tile_map.cell_size.x))
    var cell_height_mod := abs(fmod(
            position_relative_to_tile_map.y,
            tile_map.cell_size.y))
    
    var is_between_cells_horizontally := \
            cell_width_mod < COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD or \
            tile_map.cell_size.x - cell_width_mod < \
                    COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD
    var is_between_cells_vertically := \
            cell_height_mod < COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD or \
            tile_map.cell_size.y - cell_height_mod < \
                    COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD
    
    var surface_side := SurfaceSide.NONE
    var tile_coord := Vector2.INF
    var warning_message := ""
    var error_message := ""
    
    var top_left_cell_coord: Vector2
    var top_right_cell_coord: Vector2
    var bottom_left_cell_coord: Vector2
    var bottom_right_cell_coord: Vector2
    
    var left_cell_coord: Vector2
    var right_cell_coord: Vector2
    var top_cell_coord: Vector2
    var bottom_cell_coord: Vector2
    
    var is_there_a_tile_at_top_left: bool
    var is_there_a_tile_at_top_right: bool
    var is_there_a_tile_at_bottom_left: bool
    var is_there_a_tile_at_bottom_right: bool
    var is_there_a_tile_at_left: bool
    var is_there_a_tile_at_right: bool
    var is_there_a_tile_at_top: bool
    var is_there_a_tile_at_bottom: bool
    
    if is_between_cells_horizontally and is_between_cells_vertically:
        top_left_cell_coord = ScaffolderGeometry.world_to_tile_map(
                Vector2(collision_position.x - half_cell_size.x,
                        collision_position.y - half_cell_size.y),
                tile_map)
        top_right_cell_coord = Vector2(
                top_left_cell_coord.x + 1,
                top_left_cell_coord.y)
        bottom_left_cell_coord = Vector2(
                top_left_cell_coord.x,
                top_left_cell_coord.y + 1)
        bottom_right_cell_coord = Vector2(
                top_left_cell_coord.x + 1,
                top_left_cell_coord.y + 1)
        
        is_there_a_tile_at_top_left = tile_map.get_cellv(
                top_left_cell_coord) >= 0
        is_there_a_tile_at_top_right = tile_map.get_cellv(
                top_right_cell_coord) >= 0
        is_there_a_tile_at_bottom_left = tile_map.get_cellv(
                bottom_left_cell_coord) >= 0
        is_there_a_tile_at_bottom_right = tile_map.get_cellv(
                bottom_right_cell_coord) >= 0
        
        if is_touching_floor:
            if is_touching_left_wall:
                if is_there_a_tile_at_top_right:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells " +
                            "touching floor and left-wall, " +
                            "and a tile in top-right cell")
                
                if is_there_a_tile_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.FLOOR
                elif is_there_a_tile_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                elif is_there_a_tile_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.FLOOR
                else:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching floor and left-wall, " +
                            "and no tile in any surrounding cells")
                
            elif is_touching_right_wall:
                if is_there_a_tile_at_top_left:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching floor and right-wall, " +
                            "and a tile in top-left cell")
                
                if is_there_a_tile_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.FLOOR
                elif is_there_a_tile_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                elif is_there_a_tile_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.FLOOR
                else:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching floor and right-wall, " +
                            "and no tile in any surrounding cells")
                
            elif is_there_a_tile_at_bottom_left:
                tile_coord = bottom_left_cell_coord
                surface_side = SurfaceSide.FLOOR
            elif is_there_a_tile_at_bottom_right:
                tile_coord = bottom_right_cell_coord
                surface_side = SurfaceSide.FLOOR
            else:
                # This should never happen.
                error_message = (
                        "Horizontally/vertically between cells and no " +
                        "tiles in any surrounding cells")
            
        elif is_touching_ceiling:
            if is_touching_left_wall:
                if is_there_a_tile_at_bottom_right:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells " +
                            "touching ceiling and left-wall, " +
                            "and a tile in bottom-right cell")
                
                if is_there_a_tile_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                elif is_there_a_tile_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.CEILING
                elif is_there_a_tile_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                else:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching ceiling and left-wall, " +
                            "and no tile in any surrounding cells")
                
            elif is_touching_right_wall:
                if is_there_a_tile_at_bottom_left:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells " +
                            "touching ceiling and right-wall, " +
                            "and a tile in bottom-left cell")
                
                if is_there_a_tile_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                elif is_there_a_tile_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.CEILING
                elif is_there_a_tile_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                else:
                    # This should never happen.
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching ceiling and right-wall, " +
                            "and no tile in any surrounding cells")
                
            elif is_there_a_tile_at_top_left:
                tile_coord = top_left_cell_coord
                surface_side = SurfaceSide.CEILING
            elif is_there_a_tile_at_top_right:
                tile_coord = top_right_cell_coord
                surface_side = SurfaceSide.CEILING
            else:
                # This should never happen.
                error_message = (
                        "Horizontally/vertically between cells and no " +
                        "tiles in any surrounding cells")
            
        elif is_touching_left_wall:
            if is_there_a_tile_at_top_left:
                tile_coord = top_left_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            elif is_there_a_tile_at_bottom_left:
                tile_coord = bottom_left_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            else:
                # This should never happen.
                error_message = (
                        "Horizontally/vertically between cells, touching " +
                        "left-wall, and no tile in either left cell")
            
        elif is_touching_right_wall:
            if is_there_a_tile_at_top_right:
                tile_coord = top_right_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            elif is_there_a_tile_at_bottom_right:
                tile_coord = bottom_right_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            else:
                # This should never happen.
                error_message = (
                        "Horizontally/vertically between cells, touching " +
                        "left-wall, and no tile in either right cell")
            
        else:
            # This should never happen.
            error_message = (
                    "Somehow colliding, but not touching any floor/" +
                    "ceiling/wall (horizontally/vertically between cells)")
        
    elif is_between_cells_vertically:
        top_cell_coord = ScaffolderGeometry.world_to_tile_map(
                Vector2(collision_position.x,
                        collision_position.y - half_cell_size.y),
                tile_map)
        bottom_cell_coord = Vector2(
                top_cell_coord.x,
                top_cell_coord.y + 1)
        is_there_a_tile_at_top = tile_map.get_cellv(top_cell_coord) >= 0
        is_there_a_tile_at_bottom = tile_map.get_cellv(bottom_cell_coord) >= 0
        
        if is_touching_floor:
            if is_there_a_tile_at_bottom:
                tile_coord = bottom_cell_coord
                surface_side = SurfaceSide.FLOOR
            else:
                # This should never happen.
                error_message = (
                        "Vertically between cells, touching floor, and no " +
                        "tile in lower or upper cell")
        elif is_touching_ceiling:
            if is_there_a_tile_at_top:
                tile_coord = top_cell_coord
                surface_side = SurfaceSide.CEILING
            else:
                # This should never happen.
                error_message = (
                        "Vertically between cells, touching ceiling, and " +
                        "no tile in upper or lower cell")
        else:
            # This should never happen.
            error_message = (
                    "Somehow colliding, but not touching any floor/" +
                    "ceiling (vertically between cells)")
        
    elif is_between_cells_horizontally:
        left_cell_coord = ScaffolderGeometry.world_to_tile_map(
                Vector2(collision_position.x - half_cell_size.x,
                        collision_position.y),
                tile_map)
        right_cell_coord = Vector2(
                left_cell_coord.x + 1,
                left_cell_coord.y)
        is_there_a_tile_at_left = tile_map.get_cellv(left_cell_coord) >= 0
        is_there_a_tile_at_right = tile_map.get_cellv(right_cell_coord) >= 0
        
        if is_touching_left_wall:
            if is_there_a_tile_at_left:
                tile_coord = left_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            else:
                error_message = (
                        "Horizontally between cells, touching left-wall, " +
                        "and no tile in left cell")
        elif is_touching_right_wall:
            if is_there_a_tile_at_right:
                tile_coord = right_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            else:
                error_message = (
                        "Horizontally between cells, touching right-wall, " +
                        "and no tile in right cell")
        else:
            # This should never happen.
            error_message = (
                    "Somehow colliding, but not touching any wall " +
                    "(horizontally between cells)")
        
    else:
        tile_coord = ScaffolderGeometry.world_to_tile_map(
                collision_position,
                tile_map)
    
    result.tile_map_coord = tile_coord
    result.surface_side = surface_side
    result.error_message = error_message
    
    if !allows_errors and \
            (!error_message.empty() or \
            !warning_message.empty()):
        var first_statement: String
        var second_statement: String
        if !error_message.empty():
            first_statement = "ERROR: INVALID COLLISION TILEMAP STATE"
            second_statement = error_message
        elif !warning_message.empty():
            first_statement = "WARNING: UNUSUAL COLLISION TILEMAP STATE"
            second_statement = warning_message
        else:
            first_statement = "WARNING: UNUSUAL COLLISION TILEMAP STATE"
            second_statement = (
                    "Godot's underlying collision engine presumably " +
                    "calculated an incorrect result. This usually happens " +
                    "when the player is sliding along a corner.")
        var print_message := """%s: 
            %s; 
            collision_position=%s 
            is_touching_floor=%s 
            is_touching_ceiling=%s 
            is_touching_left_wall=%s 
            is_touching_right_wall=%s 
            is_between_cells_horizontally=%s 
            is_between_cells_vertically=%s 
            top_left_cell_coord=%s 
            left_cell_coord=%s 
            top_cell_coord=%s 
            is_there_a_tile_at_top_left=%s 
            is_there_a_tile_at_top_right=%s 
            is_there_a_tile_at_bottom_left=%s 
            is_there_a_tile_at_bottom_right=%s 
            is_there_a_tile_at_left=%s 
            is_there_a_tile_at_right=%s 
            is_there_a_tile_at_top=%s 
            is_there_a_tile_at_bottom=%s 
            tile_coord=%s 
            """ % [
                first_statement,
                second_statement,
                collision_position,
                is_touching_floor,
                is_touching_ceiling,
                is_touching_left_wall,
                is_touching_right_wall,
                is_between_cells_horizontally,
                is_between_cells_vertically,
                top_left_cell_coord,
                left_cell_coord,
                top_cell_coord,
                is_there_a_tile_at_top_left,
                is_there_a_tile_at_top_right,
                is_there_a_tile_at_bottom_left,
                is_there_a_tile_at_bottom_right,
                is_there_a_tile_at_left,
                is_there_a_tile_at_right,
                is_there_a_tile_at_top,
                is_there_a_tile_at_bottom,
                tile_coord,
            ]
        if !error_message.empty() and \
                !allows_errors:
            Sc.logger.error(print_message)
        else:
            Sc.logger.warning(print_message)
