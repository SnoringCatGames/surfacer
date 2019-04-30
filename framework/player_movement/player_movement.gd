# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name PlayerMovement

var name: String
var params: MovementParams
var surfaces: Array

var can_traverse_edge := false
var can_traverse_to_air := false
var can_traverse_from_air := false

func _init(name: String, params: MovementParams) -> void:
    self.name = name
    self.params = params

func set_surfaces(surface_parser: SurfaceParser) -> void:
    self.surfaces = surface_parser.get_subset_of_surfaces( \
            params.can_grab_walls, params.can_grab_ceilings, params.can_grab_floors)

func get_all_edges_from_surface(surface: Surface) -> Array:
    Utils.error( \
            "Abstract PlayerMovement.get_all_edges_from_surface is not implemented")
    return []

func get_possible_instructions_to_air(start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    Utils.error("Abstract PlayerMovement.get_possible_instructions_to_air is not implemented")
    return null

func get_all_reachable_surface_instructions_from_air(start: Vector2, end: PositionAlongSurface, \
        start_velocity: Vector2) -> Array:
    Utils.error("Abstract PlayerMovement.get_all_reachable_surface_instructions_from_air is not implemented")
    return []

func get_max_upward_distance() -> float:
    Utils.error("Abstract PlayerMovement.get_max_upward_distance is not implemented")
    return 0.0

func get_max_horizontal_distance() -> float:
    Utils.error("Abstract PlayerMovement.get_max_horizontal_distance is not implemented")
    return 0.0
