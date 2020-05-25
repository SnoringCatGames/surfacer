extends EdgeMovementCalculator
class_name WalkToAscendWallFromFloorCalculator

const NAME := "WalkToAscendWallFromFloorCalculator"
const EDGE_TYPE := EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE
const IS_A_JUMP_CALCULATOR := false

const END_POINT_OFFSET := ClimbDownWallToFloorCalculator.END_POINT_OFFSET

func _init().( \
        NAME, \
        EDGE_TYPE, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            surface.side == SurfaceSide.FLOOR and \
            (surface.counter_clockwise_concave_neighbor != null or \
            surface.clockwise_concave_neighbor != null)

func get_all_inter_surface_edges_from_surface( \
        edges_result: Array, \
        failed_edge_attempts_result: Array, \
        collision_params: CollisionCalcParams, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var movement_params := collision_params.movement_params
    var end_point_horizontal_offset := Vector2( \
            movement_params.collider_half_width_height.x + END_POINT_OFFSET, 0.0)
    var end_point_vertical_offset := Vector2(0.0, \
            movement_params.collider_half_width_height.y + END_POINT_OFFSET)
    
    if origin_surface.counter_clockwise_concave_neighbor != null:
        # We're dealing with a left wall.
        
        var upper_neighbor_wall := origin_surface.counter_clockwise_concave_neighbor
        var wall_bottom_point := upper_neighbor_wall.last_point - end_point_vertical_offset
        var floor_edge_point := origin_surface.first_point + end_point_horizontal_offset
        
        var start_position := MovementUtils.create_position_offset_from_target_point( \
                floor_edge_point, \
                origin_surface, \
                movement_params.collider_half_width_height)
        var end_position := MovementUtils.create_position_offset_from_target_point( \
                wall_bottom_point, \
                upper_neighbor_wall, \
                movement_params.collider_half_width_height)
        
        var edge := calculate_edge( \
                null, \
                collision_params, \
                start_position, \
                end_position, \
                Vector2.ZERO, \
                false, \
                false)
        edges_result.push_back(edge)
    
    if origin_surface.clockwise_concave_neighbor != null:
        # We're dealing with a right wall.
        
        var upper_neighbor_wall := origin_surface.clockwise_concave_neighbor
        var wall_bottom_point := upper_neighbor_wall.first_point - end_point_vertical_offset
        var floor_edge_point := origin_surface.last_point - end_point_horizontal_offset
        
        var start_position := MovementUtils.create_position_offset_from_target_point( \
                floor_edge_point, \
                origin_surface, \
                movement_params.collider_half_width_height)
        var end_position := MovementUtils.create_position_offset_from_target_point( \
                wall_bottom_point, \
                upper_neighbor_wall, \
                movement_params.collider_half_width_height)
        
        var edge := calculate_edge( \
                null, \
                collision_params, \
                start_position, \
                end_position, \
                Vector2.ZERO, \
                false, \
                false)
        edges_result.push_back(edge)

func calculate_edge( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        needs_extra_jump_duration := false, \
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    return WalkToAscendWallFromFloorEdge.new( \
            self, \
            position_start, \
            position_end, \
            velocity_start, \
            collision_params.movement_params)