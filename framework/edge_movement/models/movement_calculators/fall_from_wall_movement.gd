extends EdgeMovementCalculator
class_name FallFromWallMovement

const MovementCalcOverallParams := preload("res://framework/edge_movement/models/movement_calculation_overall_params.gd")

const NAME := 'FallFromWallMovement'

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null # FIXME: ----------

func get_all_edges_from_surface(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser, possible_surfaces: Array, \
        a: Surface) -> Array:
    # FIXME: LEFT OFF HERE: ----------------------------------------A
    return []
