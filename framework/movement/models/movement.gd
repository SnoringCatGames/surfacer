# A specific type of traversal movement, configured for a specific Player.
extends Reference
class_name Movement

var name: String
var params: MovementParams
var surfaces: Array
var surface_parser: SurfaceParser

var can_traverse_edge := false
var can_traverse_to_air := false
var can_traverse_from_air := false

func _init(name: String, params: MovementParams) -> void:
    self.name = name
    self.params = params

func set_surfaces(surface_parser: SurfaceParser) -> void:
    self.surface_parser = surface_parser
    self.surfaces = surface_parser.get_subset_of_surfaces( \
            params.can_grab_walls, params.can_grab_ceilings, params.can_grab_floors)

func get_all_edges_from_surface(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, possible_destination_surfaces: Array, \
        surface: Surface) -> Array:
    Utils.error("Abstract Movement.get_all_edges_from_surface is not implemented")
    return []

func get_instructions_to_air(space_state: Physics2DDirectSpaceState, \
        surface_parser: SurfaceParser, start: PositionAlongSurface, \
        end: Vector2) -> MovementInstructions:
    Utils.error("Abstract Movement.get_instructions_to_air is not implemented")
    return null

func get_all_reachable_surface_instructions_from_air(space_state: Physics2DDirectSpaceState, \
        start: Vector2, end: PositionAlongSurface, velocity_start: Vector2) -> Array:
    Utils.error( \
            "Abstract Movement.get_all_reachable_surface_instructions_from_air is not implemented")
    return []
