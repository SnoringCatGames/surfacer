# State that captures internal calculation information for a single (attempted) step within an edge
# in order to help with debugging.
extends Reference
class_name MovementCalcStepDebugState

var start_constraint: MovementConstraint setget ,_get_start
var end_constraint: MovementConstraint setget ,_get_end

var frame_positions: PoolVector2Array

var collision: SurfaceCollision

var _step_calc_params

func _init(step_calc_params) -> void:
    self._step_calc_params = step_calc_params

func _get_start() -> MovementConstraint:
    return _step_calc_params.start_constraint as MovementConstraint

func _get_end() -> MovementConstraint:
    return _step_calc_params.end_constraint as MovementConstraint
