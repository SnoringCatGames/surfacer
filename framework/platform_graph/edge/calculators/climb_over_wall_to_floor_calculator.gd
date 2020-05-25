extends EdgeMovementCalculator
class_name ClimbOverWallToFloorCalculator

const NAME := "ClimbOverWallToFloorCalculator"
const EDGE_TYPE := EdgeType.CLIMB_OVER_WALL_TO_FLOOR_EDGE
const IS_A_JUMP_CALCULATOR := false

func _init().( \
        NAME, \
        EDGE_TYPE, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            ((surface.side == SurfaceSide.LEFT_WALL and \
                    surface.counter_clockwise_convex_neighbor != null) or \
            (surface.side == SurfaceSide.RIGHT_WALL and \
                    surface.clockwise_convex_neighbor != null))

func get_all_inter_surface_edges_from_surface( \
        edges_result: Array, \
        failed_edge_attempts_result: Array, \
        collision_params: CollisionCalcParams, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var movement_params := collision_params.movement_params
    
    var upper_neighbor_floor: Surface
    var wall_top_point: Vector2
    var floor_edge_point: Vector2
    
    if origin_surface.side == SurfaceSide.LEFT_WALL:
        upper_neighbor_floor = origin_surface.counter_clockwise_convex_neighbor
        wall_top_point = origin_surface.first_point
        floor_edge_point = upper_neighbor_floor.last_point
        
    elif origin_surface.side == SurfaceSide.RIGHT_WALL:
        upper_neighbor_floor = origin_surface.clockwise_convex_neighbor
        wall_top_point = origin_surface.last_point
        floor_edge_point = upper_neighbor_floor.first_point
    
    if upper_neighbor_floor == null:
        # There is no floor surface to climb up to.
        return
    
    var start_position := MovementUtils.create_position_offset_from_target_point( \
            wall_top_point, \
            origin_surface, \
            movement_params.collider_half_width_height)
    var end_position := MovementUtils.create_position_offset_from_target_point( \
            floor_edge_point, \
            upper_neighbor_floor, \
            movement_params.collider_half_width_height)
    
    var edge := calculate_edge( \
            null, \
            collision_params, \
            start_position, \
            end_position)
    edges_result.push_back(edge)

func calculate_edge( \
        edge_result_metadata: EdgeCalcResultMetadata, \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        needs_extra_jump_duration := false, \
        needs_extra_wall_land_horizontal_speed := false) -> Edge:
    return ClimbOverWallToFloorEdge.new( \
            self, \
            position_start, \
            position_end, \
            collision_params.movement_params)