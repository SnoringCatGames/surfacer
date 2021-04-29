class_name WalkToAscendWallFromFloorCalculator
extends EdgeCalculator

const NAME := "WalkToAscendWallFromFloorCalculator"
const EDGE_TYPE := EdgeType.WALK_TO_ASCEND_WALL_FROM_FLOOR_EDGE
const IS_A_JUMP_CALCULATOR := false

const END_POINT_OFFSET := ClimbDownWallToFloorCalculator.END_POINT_OFFSET

func _init().(
        NAME,
        EDGE_TYPE,
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            surface.side == SurfaceSide.FLOOR and \
            (surface.counter_clockwise_concave_neighbor != null or \
            surface.clockwise_concave_neighbor != null)

func get_all_inter_surface_edges_from_surface(
        inter_surface_edges_results: Array,
        collision_params: CollisionCalcParams,
        origin_surface: Surface,
        surfaces_in_fall_range_set: Dictionary,
        surfaces_in_jump_range_set: Dictionary) -> void:
    var movement_params := collision_params.movement_params
    var end_point_horizontal_offset := Vector2(
            movement_params.collider_half_width_height.x + END_POINT_OFFSET,
            0.0)
    var end_point_vertical_offset := Vector2(
            0.0,
            movement_params.collider_half_width_height.y + END_POINT_OFFSET)
    
    for is_considering_clockwise_neighbor in [false, true]:
        var upper_neighbor_wall: Surface
        var wall_bottom_point: Vector2
        var floor_edge_point: Vector2
        
        if is_considering_clockwise_neighbor and \
                origin_surface.clockwise_concave_neighbor != null:
            # We're dealing with a right wall.
            upper_neighbor_wall = origin_surface.clockwise_concave_neighbor
            wall_bottom_point = \
                    upper_neighbor_wall.first_point - end_point_vertical_offset
            floor_edge_point = \
                    origin_surface.last_point - end_point_horizontal_offset
            
        elif !is_considering_clockwise_neighbor and \
                origin_surface.counter_clockwise_concave_neighbor != null:
            # We're dealing with a left wall.
            upper_neighbor_wall = \
                    origin_surface.counter_clockwise_concave_neighbor
            wall_bottom_point = \
                    upper_neighbor_wall.last_point - end_point_vertical_offset
            floor_edge_point = \
                    origin_surface.first_point + end_point_horizontal_offset
            
        else:
            continue
        
        var start_position := PositionAlongSurfaceFactory \
                .create_position_offset_from_target_point(
                        floor_edge_point,
                        origin_surface,
                        movement_params.collider_half_width_height)
        var end_position := PositionAlongSurfaceFactory \
                .create_position_offset_from_target_point(
                        wall_bottom_point,
                        upper_neighbor_wall,
                        movement_params.collider_half_width_height)
        
        #######################################################################
        # Allow for debug mode to limit the scope of what's calculated.
        if EdgeCalculator.should_skip_edge_calculation(
                collision_params.debug_params,
                start_position,
                end_position,
                null):
            continue
        #######################################################################
        
        var jump_land_positions := JumpLandPositions.new(
                start_position,
                end_position,
                Vector2.ZERO,
                false,
                false,
                false)
        var inter_surface_edges_result := InterSurfaceEdgesResult.new(
                origin_surface,
                upper_neighbor_wall,
                edge_type,
                [jump_land_positions])
        inter_surface_edges_results.push_back(inter_surface_edges_result)
        
        var edge := calculate_edge(
                null,
                collision_params,
                start_position,
                end_position,
                Vector2.ZERO,
                false,
                false)
        inter_surface_edges_result.valid_edges.push_back(edge)

func calculate_edge(
        edge_result_metadata: EdgeCalcResultMetadata,
        collision_params: CollisionCalcParams,
        position_start: PositionAlongSurface,
        position_end: PositionAlongSurface,
        velocity_start := Vector2.INF,
        needs_extra_jump_duration := false,
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    if edge_result_metadata != null:
        edge_result_metadata.edge_calc_result_type = \
                EdgeCalcResultType.EDGE_VALID_WITH_ONE_STEP
        edge_result_metadata.waypoint_validity = \
                WaypointValidity.WAYPOINT_VALID
    return WalkToAscendWallFromFloorEdge.new(
            self,
            position_start,
            position_end,
            velocity_start,
            collision_params.movement_params)
