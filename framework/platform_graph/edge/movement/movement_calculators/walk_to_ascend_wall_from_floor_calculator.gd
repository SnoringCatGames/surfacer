extends EdgeMovementCalculator
class_name WalkToAscendWallFromFloorCalculator

const MovementCalcOverallParams := preload("res://framework/platform_graph/edge/movement/models/movement_calculation_overall_params.gd")

const NAME := 'WalkToAscendWallFromFloorCalculator'

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null # FIXME: ----------

func get_all_edges_from_surface(collision_params: CollisionCalcParams, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    # FIXME: LEFT OFF HERE: ----------------------------------------A
    pass
