extends Reference
class_name EdgeMovementCalculator

var name: String

func _init(name: String) -> void:
    self.name = name

func get_can_traverse_from_surface(surface: Surface) -> bool:
    Utils.error("abstract EdgeMovementCalculator.get_can_traverse_from_surface is not implemented")
    return false

func get_all_edges_from_surface(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser, \
        possible_surfaces_set: Dictionary, a: Surface) -> Array:
    Utils.error("abstract EdgeMovementCalculator.get_all_edges_from_surface is not implemented")
    return []
