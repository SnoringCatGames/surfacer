class_name SurfaceFinder
extends Reference


# TODO: Map the TileMap into an RTree or QuadTree.

const SURFACES_TILE_MAPS_COLLISION_LAYER := 1

const _CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET := 0.02
const _CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET := 0.01

# TODO: We might want to instead replace this with a ratio (like 1.1) of the
#       KinematicBody2D.get_safe_margin value (defaults to 0.08, but we set it
#       higher during graph calculations).
const _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD := 0.5


static func find_closest_surface_in_direction(
        surface_store: SurfaceStore,
        target: Vector2,
        direction: Vector2,
        collision_surface_result: CollisionSurfaceResult = null,
        max_distance := 10000.0) -> Surface:
    collision_surface_result = \
            collision_surface_result if \
            collision_surface_result != null else \
            surface_store._collision_surface_result
    
    var collision: Dictionary = Su.space_state.intersect_ray(
            target,
            direction * max_distance,
            [],
            SURFACES_TILE_MAPS_COLLISION_LAYER,
            true,
            false)
    if collision.empty():
        return null
    assert(collision.collider is TileMap)
    
    calculate_collision_surface(
            collision_surface_result,
            surface_store,
            collision.position,
            collision.normal,
            collision.collider,
            true,
            false)
    
    return collision_surface_result.surface


static func find_closest_position_on_a_surface(
        target: Vector2,
        character,
        surface_reachability: int,
        max_distance_squared_threshold := INF,
        max_distance_basis_point := Vector2.INF) -> PositionAlongSurface:
    var surfaces
    match surface_reachability:
        SurfaceReachability.ANY:
            surfaces = character.possible_surfaces_set
        SurfaceReachability.REACHABLE:
            assert(Su.are_reachable_surfaces_per_player_tracked)
            surfaces = character.reachable_surfaces
        SurfaceReachability.REVERSIBLY_REACHABLE:
            assert(Su.are_reachable_surfaces_per_player_tracked)
            surfaces = character.reversibly_reachable_surfaces
        _:
            Sc.logger.error("SurfaceFinder.find_closest_position_on_a_surface")
    
    var positions := find_closest_positions_on_surfaces(
            target,
            character,
            7,
            max_distance_squared_threshold,
            max_distance_basis_point,
            surfaces)
    if positions.empty():
        return null
    else:
        return positions[0]


static func find_closest_positions_on_surfaces(
        target: Vector2,
        character,
        position_count: int,
        max_distance_squared_threshold := INF,
        max_distance_basis_point := Vector2.INF,
        surfaces = []) -> Array:
    surfaces = \
                surfaces if \
                !surfaces.empty() else \
                character.possible_surfaces_set
    var closest_surfaces := get_closest_surfaces(
            target,
            surfaces,
            position_count,
            max_distance_squared_threshold,
            max_distance_basis_point)
    
    var closest_positions := []
    closest_positions.resize(closest_surfaces.size())
    
    var valid_position_count := 0
    
    for i in closest_surfaces.size():
        var position := PositionAlongSurface.new()
        position.match_surface_target_and_collider(
                closest_surfaces[i],
                target,
                character.collider,
                true,
                true,
                true)
        if position.target_point != Vector2.INF:
            closest_positions[valid_position_count] = position
            valid_position_count += 1
    
    closest_positions.resize(valid_position_count)
    
    return closest_positions


# Gets the closest surface to the given point.
static func get_closest_surfaces(
        target: Vector2,
        surfaces,
        surface_count: int,
        max_distance_squared_threshold := INF,
        max_distance_basis_point := Vector2.INF) -> Array:
    assert(!surfaces.empty())
    
    max_distance_basis_point = \
            max_distance_basis_point if \
            max_distance_basis_point != Vector2.INF else \
            target
    var next_distance_squared_to_beat := max_distance_squared_threshold
    var closest_surfaces_and_distances := []
    
    for current_surface in surfaces:
        var current_target_distance_squared: float = \
                Sc.geometry.distance_squared_from_point_to_rect(
                        target,
                        current_surface.bounding_box)
        var current_max_distance_basis_distance_squared: float = \
                Sc.geometry.distance_squared_from_point_to_rect(
                        max_distance_basis_point,
                        current_surface.bounding_box)
        if current_target_distance_squared < \
                        next_distance_squared_to_beat and \
                current_max_distance_basis_distance_squared < \
                        max_distance_squared_threshold:
            var closest_point: Vector2 = \
                    Sc.geometry.get_closest_point_on_polyline_to_point(
                            target,
                            current_surface.vertices)
            current_target_distance_squared = \
                    target.distance_squared_to(closest_point)
            current_max_distance_basis_distance_squared = \
                    max_distance_basis_point.distance_squared_to(closest_point)
            if current_target_distance_squared < \
                            next_distance_squared_to_beat and \
                    current_max_distance_basis_distance_squared < \
                            max_distance_squared_threshold:
                var is_closest_to_first_point: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                                closest_point,
                                current_surface.first_point,
                                0.01)
                var is_closest_to_last_point: bool = \
                        Sc.geometry.are_points_equal_with_epsilon(
                                closest_point,
                                current_surface.last_point,
                                0.01)
                if is_closest_to_first_point or is_closest_to_last_point:
                    var first_point_diff: Vector2 = \
                            target - current_surface.first_point
                    var last_point_diff: Vector2 = \
                            target - current_surface.last_point
                    
                    var is_more_than_45_deg_from_normal_from_corner: bool
                    match current_surface.side:
                        SurfaceSide.FLOOR:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.x < 0.0 and \
                                        -first_point_diff.x > \
                                                -first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.x > 0.0 and \
                                        last_point_diff.x > -last_point_diff.y
                        SurfaceSide.LEFT_WALL:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.y < 0.0 and \
                                        first_point_diff.x < \
                                                -first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.y > 0.0 and \
                                        last_point_diff.x < last_point_diff.y
                        SurfaceSide.RIGHT_WALL:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.y > 0.0 and \
                                        -first_point_diff.x < \
                                                first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.y < 0.0 and \
                                        -last_point_diff.x < -last_point_diff.y
                        SurfaceSide.CEILING:
                            if is_closest_to_first_point:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        first_point_diff.x > 0.0 and \
                                        first_point_diff.x > first_point_diff.y
                            else:
                                is_more_than_45_deg_from_normal_from_corner = \
                                        last_point_diff.x < 0.0 and \
                                        -last_point_diff.x > last_point_diff.y
                        _:
                            Sc.logger.error("Invalid SurfaceSide")
                    
                    current_target_distance_squared += \
                            _CORNER_TARGET_LESS_PREFERRED_SURFACE_SIDE_OFFSET if \
                            is_more_than_45_deg_from_normal_from_corner else \
                            _CORNER_TARGET_MORE_PREFERRED_SURFACE_SIDE_OFFSET
                
                var was_added := maybe_add_surface_to_closest_n_collection(
                        closest_surfaces_and_distances,
                        [current_surface, current_target_distance_squared],
                        surface_count)
                if was_added:
                    next_distance_squared_to_beat = \
                            closest_surfaces_and_distances[ \
                                    surface_count - 1][1] if \
                            closest_surfaces_and_distances.size() == \
                                    surface_count else \
                            max_distance_squared_threshold
    
    var closest_surfaces := []
    closest_surfaces.resize(closest_surfaces_and_distances.size())
    for i in closest_surfaces_and_distances.size():
        closest_surfaces[i] = closest_surfaces_and_distances[i][0]
    
    return closest_surfaces


static func maybe_add_surface_to_closest_n_collection(
        collection: Array,
        surface_and_distance: Array,
        n: int) -> bool:
    if collection.size() < n:
        collection.push_back(surface_and_distance)
        collection.sort_custom(_SurfaceAndDistanceComparator, "sort_ascending")
        return true
    else:
        if surface_and_distance[1] < collection[n - 1][1]:
            collection[n - 1] = surface_and_distance
            collection.sort_custom(
                    _SurfaceAndDistanceComparator, "sort_ascending")
            return true
    return false


class _SurfaceAndDistanceComparator:
    static func sort_ascending(a: Array, b: Array):
        if a[1] < b[1]:
            return true
        return false


# -   Sometimes Godot's move_and_slide API can produce invalid
#     collisions or collisions with invalid normals.
# -   Invalid normals seem to happen mostly near corners and sloped surfaces.
#     -   Often, normals are just slightly off for sloped surfaces.
#     -   Sometimes, normals are reversed when moving around a corner.
# -   Pass-in tries_adjusted_collision_normal as true if we should correct for
#     slightly-off normals around sloped surfaces.
# -   Reversed normals around corners will be corrected automatically.
static func calculate_collision_surface(
        result: CollisionSurfaceResult,
        surface_store: SurfaceStore,
        collision_position: Vector2,
        collision_normal_or_side,
        tile_map: TileMap,
        tries_adjusted_collision_normal: bool,
        allows_errors: bool,
        is_nested_call := false) -> void:
    var half_cell_size := tile_map.cell_size / 2.0
    var used_rect := tile_map.get_used_rect()
    var tilemap_top_left_position_world_coord := \
            tile_map.position - used_rect.position * tile_map.cell_size
    var position_relative_to_tilemap := \
            collision_position - tilemap_top_left_position_world_coord
    
    var cell_width_mod := abs(fmod(
            position_relative_to_tilemap.x,
            tile_map.cell_size.x))
    var cell_height_mod := abs(fmod(
            position_relative_to_tilemap.y,
            tile_map.cell_size.y))
    
    var is_between_cells_horizontally := \
            cell_width_mod < _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD or \
            tile_map.cell_size.x - cell_width_mod < \
                    _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD
    var is_between_cells_vertically := \
            cell_height_mod < _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD or \
            tile_map.cell_size.y - cell_height_mod < \
                    _COLLISION_BETWEEN_CELLS_DISTANCE_THRESHOLD
    
    assert(!tries_adjusted_collision_normal or \
            collision_normal_or_side is Vector2)
    var collision_side: int = \
            collision_normal_or_side if \
            collision_normal_or_side is int else \
            Sc.geometry.get_surface_side_for_normal(collision_normal_or_side)
    var is_touching_floor := false
    var is_touching_ceiling := false
    var is_touching_left_wall := false
    var is_touching_right_wall := false
    match collision_side:
        SurfaceSide.FLOOR:
            is_touching_floor = true
        SurfaceSide.LEFT_WALL:
            is_touching_left_wall = true
        SurfaceSide.RIGHT_WALL:
            is_touching_right_wall = true
        SurfaceSide.CEILING:
            is_touching_ceiling = true
        _:
            Sc.logger.error("SurfaceFinder.calculate_collision_surface")
    
    var surface_side := SurfaceSide.NONE
    var tile_coord := Vector2.INF
    var error_message := ""
    
    if is_between_cells_horizontally and \
            is_between_cells_vertically:
        var top_left_cell_coord: Vector2 = Sc.geometry.world_to_tilemap(
                Vector2(collision_position.x - half_cell_size.x,
                        collision_position.y - half_cell_size.y),
                tile_map)
        var top_right_cell_coord := Vector2(
                top_left_cell_coord.x + 1,
                top_left_cell_coord.y)
        var bottom_left_cell_coord := Vector2(
                top_left_cell_coord.x,
                top_left_cell_coord.y + 1)
        var bottom_right_cell_coord := Vector2(
                top_left_cell_coord.x + 1,
                top_left_cell_coord.y + 1)
        
        var top_left_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        top_left_cell_coord, tile_map)
        var top_right_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        top_right_cell_coord, tile_map)
        var bottom_left_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        bottom_left_cell_coord, tile_map)
        var bottom_right_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        bottom_right_cell_coord, tile_map)
        
        var is_there_a_floor_at_top_left := surface_store.get_surface_for_tile(
                tile_map,
                top_left_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_top_left := surface_store.get_surface_for_tile(
                tile_map,
                top_left_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_top_left := surface_store.get_surface_for_tile(
                tile_map,
                top_left_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_top_left := surface_store.get_surface_for_tile(
                tile_map,
                top_left_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        var is_there_a_floor_at_top_right := surface_store.get_surface_for_tile(
                tile_map,
                top_right_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_top_right := surface_store.get_surface_for_tile(
                tile_map,
                top_right_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_top_right := surface_store.get_surface_for_tile(
                tile_map,
                top_right_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_top_right := surface_store.get_surface_for_tile(
                tile_map,
                top_right_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        var is_there_a_floor_at_bottom_left := surface_store.get_surface_for_tile(
                tile_map,
                bottom_left_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_bottom_left := surface_store.get_surface_for_tile(
                tile_map,
                bottom_left_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_bottom_left := surface_store.get_surface_for_tile(
                tile_map,
                bottom_left_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_bottom_left := surface_store.get_surface_for_tile(
                tile_map,
                bottom_left_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        var is_there_a_floor_at_bottom_right := surface_store.get_surface_for_tile(
                tile_map,
                bottom_right_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_bottom_right := surface_store.get_surface_for_tile(
                tile_map,
                bottom_right_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_bottom_right := surface_store.get_surface_for_tile(
                tile_map,
                bottom_right_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_bottom_right := surface_store.get_surface_for_tile(
                tile_map,
                bottom_right_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        if is_touching_floor:
            if is_touching_left_wall:
                if is_there_a_floor_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.FLOOR
                elif is_there_a_left_wall_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                elif is_there_a_floor_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.FLOOR
                elif is_there_a_left_wall_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                # Can happen with angled tile shapes.
                elif is_there_a_left_wall_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                # Can happen with angled tile shapes.
                elif is_there_a_floor_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.FLOOR
                else:
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching floor and left-wall, and " +
                            "no floor or left-wall in lower or left cells")
            elif is_touching_right_wall:
                if is_there_a_floor_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.FLOOR
                elif is_there_a_right_wall_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                elif is_there_a_floor_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.FLOOR
                elif is_there_a_right_wall_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                # Can happen with angled tile shapes.
                elif is_there_a_right_wall_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                # Can happen with angled tile shapes.
                elif is_there_a_floor_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.FLOOR
                else:
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching floor and right-wall, and " +
                            "no floor or right-wall in lower or right cells")
            elif is_there_a_floor_at_bottom_left:
                tile_coord = bottom_left_cell_coord
                surface_side = SurfaceSide.FLOOR
            elif is_there_a_floor_at_bottom_right:
                tile_coord = bottom_right_cell_coord
                surface_side = SurfaceSide.FLOOR
            # Can happen with angled tile shapes.
            elif is_there_a_floor_at_top_left:
                tile_coord = top_left_cell_coord
                surface_side = SurfaceSide.FLOOR
            # Can happen with angled tile shapes.
            elif is_there_a_floor_at_top_right:
                tile_coord = top_right_cell_coord
                surface_side = SurfaceSide.FLOOR
            else:
                error_message = (
                        "Horizontally/vertically between cells, " +
                        "touching floor, and " +
                        "no floor or wall in lower cells")
            
        elif is_touching_ceiling:
            if is_touching_left_wall:
                if is_there_a_left_wall_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                elif is_there_a_ceiling_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.CEILING
                elif is_there_a_left_wall_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                elif is_there_a_ceiling_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.CEILING
                # Can happen with angled tile shapes.
                elif is_there_a_ceiling_at_bottom_left:
                    tile_coord = bottom_left_cell_coord
                    surface_side = SurfaceSide.CEILING
                # Can happen with angled tile shapes.
                elif is_there_a_left_wall_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.LEFT_WALL
                else:
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching ceiling and left-wall, and " +
                            "no ceiling or left-wall in upper or left cells")
            elif is_touching_right_wall:
                if is_there_a_right_wall_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                elif is_there_a_ceiling_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.CEILING
                elif is_there_a_right_wall_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                elif is_there_a_ceiling_at_top_right:
                    tile_coord = top_right_cell_coord
                    surface_side = SurfaceSide.CEILING
                # Can happen with angled tile shapes.
                elif is_there_a_ceiling_at_bottom_right:
                    tile_coord = bottom_right_cell_coord
                    surface_side = SurfaceSide.CEILING
                # Can happen with angled tile shapes.
                elif is_there_a_right_wall_at_top_left:
                    tile_coord = top_left_cell_coord
                    surface_side = SurfaceSide.RIGHT_WALL
                else:
                    error_message = (
                            "Horizontally/vertically between cells, " +
                            "touching ceiling and right-wall, and " +
                            "no ceiling or right-wall in upper or right cells")
            elif is_there_a_ceiling_at_top_left:
                tile_coord = top_left_cell_coord
                surface_side = SurfaceSide.CEILING
            elif is_there_a_ceiling_at_top_right:
                tile_coord = top_right_cell_coord
                surface_side = SurfaceSide.CEILING
            # Can happen with angled tile shapes.
            elif is_there_a_ceiling_at_bottom_left:
                tile_coord = bottom_left_cell_coord
                surface_side = SurfaceSide.CEILING
            # Can happen with angled tile shapes.
            elif is_there_a_ceiling_at_bottom_right:
                tile_coord = bottom_right_cell_coord
                surface_side = SurfaceSide.CEILING
            else:
                error_message = (
                        "Horizontally/vertically between cells, " +
                        "touching ceiling, and " +
                        "no ceiling or wall in upper cells")
            
        elif is_touching_left_wall:
            if is_there_a_left_wall_at_top_left:
                tile_coord = top_left_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            elif is_there_a_left_wall_at_bottom_left:
                tile_coord = bottom_left_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            # Can happen with angled tile shapes.
            elif is_there_a_left_wall_at_top_right:
                tile_coord = top_right_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            # Can happen with angled tile shapes.
            elif is_there_a_left_wall_at_bottom_right:
                tile_coord = bottom_right_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            else:
                error_message = (
                        "Horizontally/vertically between cells, " +
                        "touching left-wall, and " +
                        "no left-wall in any neighbor cells")
            
        elif is_touching_right_wall:
            if is_there_a_right_wall_at_top_right:
                tile_coord = top_right_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            elif is_there_a_right_wall_at_bottom_right:
                tile_coord = bottom_right_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            # Can happen with angled tile shapes.
            elif is_there_a_right_wall_at_top_left:
                tile_coord = top_left_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            # Can happen with angled tile shapes.
            elif is_there_a_right_wall_at_bottom_left:
                tile_coord = bottom_left_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            else:
                error_message = (
                        "Horizontally/vertically between cells, " +
                        "touching right-wall, and " +
                        "no right-wall in any neighbor cells")
            
        else:
            error_message = (
                    "Somehow colliding, " +
                    "but not touching any floor/ceiling/wall " +
                    "(horizontally/vertically between cells)")
        
    elif is_between_cells_vertically:
        var top_cell_coord: Vector2 = Sc.geometry.world_to_tilemap(
                Vector2(collision_position.x,
                        collision_position.y - half_cell_size.y),
                tile_map)
        var bottom_cell_coord := Vector2(
                top_cell_coord.x,
                top_cell_coord.y + 1)
        
        var top_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        top_cell_coord, tile_map)
        var bottom_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        bottom_cell_coord, tile_map)
        
        var is_there_a_floor_at_top := surface_store.get_surface_for_tile(
                tile_map,
                top_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_top := surface_store.get_surface_for_tile(
                tile_map,
                top_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_top := surface_store.get_surface_for_tile(
                tile_map,
                top_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_top := surface_store.get_surface_for_tile(
                tile_map,
                top_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        var is_there_a_floor_at_bottom := surface_store.get_surface_for_tile(
                tile_map,
                bottom_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_bottom := surface_store.get_surface_for_tile(
                tile_map,
                bottom_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_bottom := surface_store.get_surface_for_tile(
                tile_map,
                bottom_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_bottom := surface_store.get_surface_for_tile(
                tile_map,
                bottom_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        if is_touching_floor:
            if is_there_a_floor_at_bottom:
                tile_coord = bottom_cell_coord
                surface_side = SurfaceSide.FLOOR
            # Can happen with angled tile shapes.
            elif is_there_a_floor_at_top:
                tile_coord = top_cell_coord
                surface_side = SurfaceSide.FLOOR
            else:
                error_message = (
                        "Vertically between cells, " +
                        "touching floor, and " +
                        "no floor in lower cell")
        elif is_touching_ceiling:
            if is_there_a_ceiling_at_top:
                tile_coord = top_cell_coord
                surface_side = SurfaceSide.CEILING
            # Can happen with angled tile shapes.
            elif is_there_a_ceiling_at_bottom:
                tile_coord = bottom_cell_coord
                surface_side = SurfaceSide.CEILING
            else:
                error_message = (
                        "Vertically between cells, " +
                        "touching ceiling, and " +
                        "no ceiling in upper cell")
        elif is_touching_left_wall:
            if is_there_a_left_wall_at_top:
                tile_coord = top_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            elif is_there_a_left_wall_at_bottom:
                tile_coord = bottom_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            else:
                error_message = (
                        "Vertically between cells, " +
                        "touching left-wall, and " +
                        "no left-wall in upper or lower cell")
        elif is_touching_right_wall:
            if is_there_a_right_wall_at_top:
                tile_coord = top_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            elif is_there_a_right_wall_at_bottom:
                tile_coord = bottom_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            else:
                error_message = (
                        "Vertically between cells, " +
                        "touching right-wall, and " +
                        "no right-wall in upper or lower cell")
        else:
            error_message = (
                    "Somehow colliding, " +
                    "but not touching any floor/ceiling/wall " +
                    "(vertically between cells)")
        
    elif is_between_cells_horizontally:
        var left_cell_coord: Vector2 = Sc.geometry.world_to_tilemap(
                Vector2(collision_position.x - half_cell_size.x,
                        collision_position.y),
                tile_map)
        var right_cell_coord := Vector2(
                left_cell_coord.x + 1,
                left_cell_coord.y)
        
        var left_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        left_cell_coord, tile_map)
        var right_cell_index: int = \
                Sc.geometry.get_tilemap_index_from_grid_coord(
                        right_cell_coord, tile_map)
        
        var is_there_a_floor_at_left := surface_store.get_surface_for_tile(
                tile_map,
                left_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_left := surface_store.get_surface_for_tile(
                tile_map,
                left_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_left := surface_store.get_surface_for_tile(
                tile_map,
                left_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_left := surface_store.get_surface_for_tile(
                tile_map,
                left_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        var is_there_a_floor_at_right := surface_store.get_surface_for_tile(
                tile_map,
                right_cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling_at_right := surface_store.get_surface_for_tile(
                tile_map,
                right_cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall_at_right := surface_store.get_surface_for_tile(
                tile_map,
                right_cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall_at_right := surface_store.get_surface_for_tile(
                tile_map,
                right_cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        if is_touching_left_wall:
            if is_there_a_left_wall_at_left:
                tile_coord = left_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            # Can happen with angled tile shapes.
            elif is_there_a_left_wall_at_right:
                tile_coord = right_cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            else:
                error_message = (
                        "Horizontally between cells, " +
                        "touching left-wall, and " +
                        "no floor in left cell")
        elif is_touching_right_wall:
            if is_there_a_right_wall_at_right:
                tile_coord = right_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            # Can happen with angled tile shapes.
            elif is_there_a_right_wall_at_left:
                tile_coord = left_cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            else:
                error_message = (
                        "Horizontally between cells, " +
                        "touching right-wall, and " +
                        "no floor in right cell")
        elif is_touching_floor:
            if is_there_a_floor_at_left:
                tile_coord = left_cell_coord
                surface_side = SurfaceSide.FLOOR
            elif is_there_a_floor_at_right:
                tile_coord = right_cell_coord
                surface_side = SurfaceSide.FLOOR
            else:
                error_message = (
                        "Horizontally between cells, " +
                        "touching floor, and " +
                        "no floor in left or right cell")
        elif is_touching_ceiling:
            if is_there_a_ceiling_at_left:
                tile_coord = left_cell_coord
                surface_side = SurfaceSide.CEILING
            elif is_there_a_ceiling_at_right:
                tile_coord = right_cell_coord
                surface_side = SurfaceSide.CEILING
            else:
                error_message = (
                        "Horizontally between cells, " +
                        "touching ceiling, and " +
                        "no ceiling in left or right cell")
        else:
            error_message = (
                    "Somehow colliding, " +
                    "but not touching any floor/ceiling/wall " +
                    "(horizontally between cells)")
        
    # In cell interior (not between cells).
    else:
        var cell_coord: Vector2 = Sc.geometry.world_to_tilemap(
                collision_position,
                tile_map)
        var cell_index: int = Sc.geometry.get_tilemap_index_from_grid_coord(
                cell_coord, tile_map)
        
        var is_there_a_floor := surface_store.get_surface_for_tile(
                tile_map,
                cell_index,
                SurfaceSide.FLOOR) != null
        var is_there_a_ceiling := surface_store.get_surface_for_tile(
                tile_map,
                cell_index,
                SurfaceSide.CEILING) != null
        var is_there_a_left_wall := surface_store.get_surface_for_tile(
                tile_map,
                cell_index,
                SurfaceSide.LEFT_WALL) != null
        var is_there_a_right_wall := surface_store.get_surface_for_tile(
                tile_map,
                cell_index,
                SurfaceSide.RIGHT_WALL) != null
        
        if is_touching_floor:
            if is_there_a_floor:
                tile_coord = cell_coord
                surface_side = SurfaceSide.FLOOR
            else:
                error_message = (
                        "In cell interior, " +
                        "touching floor, and " +
                        "no floor in cell")
        elif is_touching_ceiling:
            if is_there_a_ceiling:
                tile_coord = cell_coord
                surface_side = SurfaceSide.CEILING
            else:
                error_message = (
                        "In cell interior, " +
                        "touching ceiling, and " +
                        "no ceiling in cell")
        elif is_touching_left_wall:
            if is_there_a_left_wall:
                tile_coord = cell_coord
                surface_side = SurfaceSide.LEFT_WALL
            else:
                error_message = (
                        "In cell interior, " +
                        "touching left-wall, and " +
                        "no left-wall in cell")
        elif is_touching_right_wall:
            if is_there_a_right_wall:
                tile_coord = cell_coord
                surface_side = SurfaceSide.RIGHT_WALL
            else:
                error_message = (
                        "In cell interior, " +
                        "touching right-wall, and " +
                        "no right-wall in cell")
        else:
            error_message = (
                    "Somehow colliding, " +
                    "but not touching any floor/ceiling/wall " +
                    "(in cell interior)")
    
    var cell_index := -1
    var surface: Surface = null
    if tile_coord != Vector2.INF:
        cell_index = Sc.geometry.get_tilemap_index_from_grid_coord(
                tile_coord, tile_map)
        surface = surface_store.get_surface_for_tile(
                tile_map,
                cell_index,
                surface_side)
    
    result.surface = surface
    result.surface_side = surface_side
    result.tilemap_coord = tile_coord
    result.tilemap_index = cell_index
    result.flipped_sides_for_nested_call = is_nested_call
    result.error_message = error_message
    
    if !error_message.empty() and \
            !is_nested_call:
        var reversed_collision_normal_or_side
        if collision_normal_or_side is int:
            match collision_normal_or_side:
                SurfaceSide.FLOOR:
                    reversed_collision_normal_or_side = SurfaceSide.CEILING
                SurfaceSide.LEFT_WALL:
                    reversed_collision_normal_or_side = SurfaceSide.RIGHT_WALL
                SurfaceSide.RIGHT_WALL:
                    reversed_collision_normal_or_side = SurfaceSide.LEFT_WALL
                SurfaceSide.CEILING:
                    reversed_collision_normal_or_side = SurfaceSide.FLOOR
                _:
                    Sc.logger.error("SurfaceFinder.calculate_collision_surface")
        else:
            reversed_collision_normal_or_side = -collision_normal_or_side
        calculate_collision_surface(
                result,
                surface_store,
                collision_position,
                reversed_collision_normal_or_side,
                tile_map,
                false,
                allows_errors,
                true)
        if result.error_message.empty():
            return
        
        if tries_adjusted_collision_normal:
            # -   Flip the normal around the diagonal within the same
            #     quadrant.
            # -   For example:
            #     -   (1,4) => (4,1)
            #     -   (-1,4) => (-4,1)
            var adjusted_collision_normal: Vector2
            if (collision_normal_or_side.x < 0.0) == \
                    (collision_normal_or_side.y < 0.0):
                adjusted_collision_normal = Vector2(
                        collision_normal_or_side.y,
                        collision_normal_or_side.x)
            else:
                adjusted_collision_normal = Vector2(
                        -collision_normal_or_side.y,
                        -collision_normal_or_side.x)
            calculate_collision_surface(
                    result,
                    surface_store,
                    collision_position,
                    adjusted_collision_normal,
                    tile_map,
                    false,
                    allows_errors,
                    false)
            if result.error_message.empty():
                return
    
    if !allows_errors and \
            !error_message.empty() and \
            !is_nested_call:
        var collision_normal_or_side_str := \
                SurfaceSide.get_string(collision_normal_or_side) if \
                collision_normal_or_side is int else \
                Sc.utils.get_vector_string(collision_normal_or_side, 3)
        var print_message := """ERROR: INVALID COLLISION TILEMAP STATE: 
            %s; 
            collision_position=%s 
            collision_normal_or_side=%s 
            is_touching_floor=%s 
            is_touching_ceiling=%s 
            is_touching_left_wall=%s 
            is_touching_right_wall=%s 
            is_between_cells_horizontally=%s 
            is_between_cells_vertically=%s 
            tile_coord=%s 
            """ % [
                error_message,
                collision_position,
                collision_normal_or_side_str,
                is_touching_floor,
                is_touching_ceiling,
                is_touching_left_wall,
                is_touching_right_wall,
                is_between_cells_horizontally,
                is_between_cells_vertically,
                tile_coord,
            ]
        if !error_message.empty() and \
                !allows_errors:
            Sc.logger.error(print_message)
        else:
            Sc.logger.warning(print_message)
