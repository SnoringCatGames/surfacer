extends EdgeMovementCalculator
class_name FallFromWallCalculator

const MovementCalcOverallParams := preload("res://framework/edge_movement/models/movement_calculation_overall_params.gd")

const NAME := 'FallFromWallCalculator'

func _init().(NAME) -> void:
    pass

func get_can_traverse_from_surface(surface: Surface) -> bool:
    return surface != null # FIXME: ----------

func get_all_edges_from_surface(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser, edges_result: Array, \
        surfaces_in_fall_range_set: Dictionary, surfaces_in_jump_range_set: Dictionary, \
        origin_surface: Surface) -> void:
    # FIXME: LEFT OFF HERE: ----------------------------------------A
#    var air_to_surface_edge := FallMovementUtils.find_a_landing_trajectory( \
#            space_state, movement_params, surface_parser, possible_surfaces_set, origin, \
#            player.velocity, destination)
    pass
