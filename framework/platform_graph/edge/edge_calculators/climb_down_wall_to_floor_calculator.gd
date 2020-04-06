extends EdgeMovementCalculator
class_name ClimbDownWallToFloorCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "ClimbDownWallToFloorCalculator"
const IS_A_JUMP_CALCULATOR := false

const END_POINT_OFFSET := 1.0

func _init().( \
        NAME, \
        IS_A_JUMP_CALCULATOR) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            ((surface.side == SurfaceSide.LEFT_WALL and \
                    surface.clockwise_concave_neighbor != null) or \
            (surface.side == SurfaceSide.RIGHT_WALL and \
                    surface.counter_clockwise_concave_neighbor != null))

func get_all_inter_surface_edges_from_surface( \
        collision_params: CollisionCalcParams, \
        edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, \
        surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    var movement_params := collision_params.movement_params
    var end_point_horizontal_offset := Vector2( \
            movement_params.collider_half_width_height.x + END_POINT_OFFSET, 0.0)
    var end_point_vertical_offset := Vector2(0.0, \
            movement_params.collider_half_width_height.y + END_POINT_OFFSET)
    
    var lower_neighbor_floor: Surface
    var wall_bottom_point: Vector2
    var floor_edge_point: Vector2
    
    if origin_surface.side == SurfaceSide.LEFT_WALL:
        lower_neighbor_floor = origin_surface.clockwise_concave_neighbor
        wall_bottom_point = origin_surface.last_point - end_point_vertical_offset
        floor_edge_point = lower_neighbor_floor.first_point + end_point_horizontal_offset
        
    elif origin_surface.side == SurfaceSide.RIGHT_WALL:
        lower_neighbor_floor = origin_surface.counter_clockwise_concave_neighbor
        wall_bottom_point = origin_surface.first_point - end_point_vertical_offset
        floor_edge_point = lower_neighbor_floor.last_point - end_point_horizontal_offset
    
    if lower_neighbor_floor == null:
        # There is no floor surface to climb up to.
        return
    
    var start_position := MovementUtils.create_position_offset_from_target_point( \
            wall_bottom_point, \
            origin_surface, \
            movement_params.collider_half_width_height)
    var end_position := MovementUtils.create_position_offset_from_target_point( \
            floor_edge_point, \
            lower_neighbor_floor, \
            movement_params.collider_half_width_height)
    
    var edge := calculate_edge( \
            collision_params, \
            start_position, \
            end_position)
    edges_result.push_back(edge)

func calculate_edge( \
        collision_params: CollisionCalcParams, \
        position_start: PositionAlongSurface, \
        position_end: PositionAlongSurface, \
        velocity_start := Vector2.INF, \
        in_debug_mode := false) -> Edge:
    return ClimbDownWallToFloorEdge.new( \
            self, \
            position_start, \
            position_end, \
            collision_params.movement_params)
