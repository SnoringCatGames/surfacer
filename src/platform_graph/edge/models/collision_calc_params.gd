class_name CollisionCalcParams
extends Reference
# Parameters that are used for calculating edge-movement collisions.


var debug_params: Dictionary
var movement_params: MovementParameters
var surface_parser: SurfaceParser
var crash_test_dummy: KinematicBody2D
var thread_id: String = Sc.profiler.DEFAULT_THREAD_ID


func _init(
        debug_params: Dictionary,
        movement_params: MovementParameters,
        surface_parser: SurfaceParser,
        crash_test_dummy: KinematicBody2D) -> void:
    self.debug_params = debug_params
    self.movement_params = movement_params
    self.surface_parser = surface_parser
    self.crash_test_dummy = crash_test_dummy


func copy(other) -> void:
    self.debug_params = other.debug_params
    self.movement_params = other.movement_params
    self.surface_parser = other.surface_parser
    self.crash_test_dummy = other.crash_test_dummy
