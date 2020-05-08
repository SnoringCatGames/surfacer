# Parameters that are used for calculating edge-movement collisions.
extends Reference
class_name CollisionCalcParams

var debug_params: Dictionary
var space_state: Physics2DDirectSpaceState
var movement_params: MovementParams
var surface_parser: SurfaceParser

func _init( \
        debug_params: Dictionary, \
        space_state: Physics2DDirectSpaceState, \
        movement_params: MovementParams, \
        surface_parser: SurfaceParser) -> void:
    self.debug_params = debug_params
    self.space_state = space_state
    self.movement_params = movement_params
    self.surface_parser = surface_parser
