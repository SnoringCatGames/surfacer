extends Reference
class_name FrameCollisionCheckUtils

# Determines whether the given motion of the given shape would collide with a
# surface. If a collision would occur, this returns information about the
# collision.
static func check_frame_for_collision( \
        collision_params: CollisionCalcParams, \
        shape_query_params: Physics2DShapeQueryParameters, \
        collision_result_metadata = null) -> SurfaceCollision:
    var displacement := shape_query_params.motion
    var position_start := shape_query_params.transform.origin
    
    collision_params.player.position = position_start
    var kinematic_collision := collision_params.player.move_and_collide( \
            displacement, \
            true, \
            true, \
            true)
    
    if kinematic_collision == null:
        # No collision found for this frame.
        return null
    
    var surface_collision := SurfaceCollision.new()
    surface_collision.position = kinematic_collision.position
    surface_collision.player_position = \
            position_start + kinematic_collision.travel
    
    ###########################################################################
    if collision_result_metadata != null:
        # FIXME: -------------------------- REFACTOR or REMOVE
        _record_collision_result_metadata( \
                collision_result_metadata, \
                collision_params, \
                shape_query_params, \
                kinematic_collision, \
                surface_collision)
    ###########################################################################
    
    var surface_side := \
            Utils.get_which_surface_side_collided(kinematic_collision)
    var is_touching_floor := surface_side == SurfaceSide.FLOOR
    var is_touching_ceiling := surface_side == SurfaceSide.CEILING
    var is_touching_left_wall := surface_side == SurfaceSide.LEFT_WALL
    var is_touching_right_wall := surface_side == SurfaceSide.RIGHT_WALL
    var tile_map: TileMap = kinematic_collision.collider
    var tile_map_result := CollisionTileMapCoordResult.new()
    Geometry.get_collision_tile_map_coord( \
            tile_map_result, \
            kinematic_collision.position, \
            tile_map, \
            is_touching_floor, \
            is_touching_ceiling, \
            is_touching_left_wall, \
            is_touching_right_wall)
    if !tile_map_result.is_godot_floor_ceiling_detection_correct:
        is_touching_floor = !is_touching_floor
        is_touching_ceiling = !is_touching_ceiling
        surface_side = tile_map_result.surface_side
    
    if tile_map_result.tile_map_coord == Vector2.INF:
        # Invalid collision state.
        if collision_params.movement_params \
                .asserts_no_preexisting_collisions_during_edge_calculations:
            Utils.error()
        surface_collision.is_valid_collision_state = false
        return null
    
    var tile_map_index: int = Geometry.get_tile_map_index_from_grid_coord( \
            tile_map_result.tile_map_coord, \
            tile_map)
    if !collision_params.surface_parser.has_surface_for_tile( \
            tile_map, \
            tile_map_index, \
            surface_side):
        # Invalid collision state.
        if collision_params.movement_params \
                .asserts_no_preexisting_collisions_during_edge_calculations:
            Utils.error()
        surface_collision.is_valid_collision_state = false
        return null
    
    var surface := collision_params.surface_parser.get_surface_for_tile( \
            tile_map, \
            tile_map_index, \
            surface_side)
    
    surface_collision.surface = surface
    surface_collision.is_valid_collision_state = true
    
    return surface_collision

static func _record_collision_result_metadata( \
        collision_result_metadata: CollisionCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        shape_query_params: Physics2DShapeQueryParameters, \
        kinematic_collision: KinematicCollision2D, \
        surface_collision: SurfaceCollision) -> void:
    collision_result_metadata.frame_motion = shape_query_params.motion
    collision_result_metadata.frame_previous_position = \
            collision_result_metadata.frame_start_position
    collision_result_metadata.frame_start_position = \
            shape_query_params.transform[2]
    collision_result_metadata.frame_end_position = \
            collision_result_metadata.frame_start_position + \
            collision_result_metadata.frame_motion
    collision_result_metadata.frame_previous_min_coordinates = \
            collision_result_metadata.frame_start_min_coordinates
    collision_result_metadata.frame_previous_max_coordinates = \
            collision_result_metadata.frame_start_max_coordinates
    collision_result_metadata.frame_start_min_coordinates = \
            collision_result_metadata.frame_start_position - \
            collision_params.movement_params.collider_half_width_height
    collision_result_metadata.frame_start_max_coordinates = \
            collision_result_metadata.frame_start_position + \
            collision_params.movement_params.collider_half_width_height
    collision_result_metadata.frame_end_min_coordinates = \
            collision_result_metadata.frame_end_position - \
            collision_params.movement_params.collider_half_width_height
    collision_result_metadata.frame_end_max_coordinates = \
            collision_result_metadata.frame_end_position + \
            collision_params.movement_params.collider_half_width_height
    collision_result_metadata.intersection_points = [ \
        kinematic_collision.position, \
    ]
    collision_result_metadata.collision_ratios = [ \
        kinematic_collision.travel.length() / \
                shape_query_params.motion.length(), \
        kinematic_collision.travel.length() / \
                shape_query_params.motion.length(), \
    ]
    collision_result_metadata.collision = surface_collision
