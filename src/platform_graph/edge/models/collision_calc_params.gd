class_name CollisionCalcParams
extends Reference
# Parameters that are used for calculating edge-movement collisions.


var debug_params: Dictionary
var movement_params: MovementParams
var surface_parser: SurfaceParser
var player: KinematicBody2D
var thread_id: String = Gs.profiler.DEFAULT_THREAD_ID


func _init(
        debug_params: Dictionary,
        movement_params: MovementParams,
        surface_parser: SurfaceParser,
        player: KinematicBody2D) -> void:
    self.debug_params = debug_params
    self.movement_params = movement_params
    self.surface_parser = surface_parser
    self.player = player


func copy(other) -> void:
    self.debug_params = other.debug_params
    self.movement_params = other.movement_params
    self.surface_parser = other.surface_parser
    self.player = other.player
