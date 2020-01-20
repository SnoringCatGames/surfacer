extends EdgeMovementCalculator
class_name FallFromWallMovement

const MovementCalcOverallParams := preload("res://framework/edge_movement/models/movement_calculation_overall_params.gd")

const NAME := 'FallFromWallMovement'

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null # FIXME: ----------

func get_all_edges_from_surface(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser, \
        possible_surfaces_set: Dictionary, a: Surface) -> Array:
    # FIXME: LEFT OFF HERE: ----------------------------------------A
#    var air_to_surface_edge := FallMovementUtils.find_a_landing_trajectory( \
#            space_state, movement_params, surface_parser, possible_surfaces_set, origin, \
#            player.velocity, destination)
    return []
