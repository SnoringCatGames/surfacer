# Parameters that are used for calculating edge-movement collisions.
extends Reference
class_name CollisionCalcParams

var debug_state: Dictionary
var space_state: Physics2DDirectSpaceState
var movement_params: MovementParams
var surface_parser: SurfaceParser

func _init(debug_state: Dictionary, space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, surface_parser: SurfaceParser) -> void:
    self.debug_state = debug_state
    self.space_state = space_state
    self.movement_params = movement_params
    self.surface_parser = surface_parser
