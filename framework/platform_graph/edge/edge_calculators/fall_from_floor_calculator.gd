extends EdgeMovementCalculator
class_name FallFromFloorCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/calculation_models/movement_calculation_overall_params.gd")

const NAME := "FallFromFloorCalculator"

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null and \
            surface.side == SurfaceSide.FLOOR and \
            (surface.convex_counter_clockwise_neighbor == null or \
            surface.convex_clockwise_neighbor == null)

func get_all_edges_from_surface(collision_params: CollisionCalcParams, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    # FIXME: LEFT OFF HERE: ----------------------------------------A
    #   - Calculate fall-off position according to collider shape (capsule and circle will be at the
    #     left-most center point (unless capsule in vertical)).
    #   - Can calculate start x speed according to horizontal distance from floor to the actual
    #     fall-off position.
    #   - Can calculate walk part ends and fall part begins just according to horizontal displacement
    #     and acceleration.
    pass
    
    var movement_params := collision_params.movement_params
    var velocity_start := Vector2.ZERO
#    var time_to_reach_fall_off_position := movement_params.walk_acceleration
    
    if origin_surface.convex_counter_clockwise_neighbor == null:
        pass
    
    if origin_surface.convex_clockwise_neighbor == null:
        pass
