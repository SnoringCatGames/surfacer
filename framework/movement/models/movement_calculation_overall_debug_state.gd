# State that captures internal calculation information for a single edge in order to help with
# debugging.
extends Reference
class_name MovementCalcOverallDebugState

# FIXME: LEFT OFF HERE: ------------------------------------A
# - Exactly what info would be useful to see rendered?
#   - reason for failing for each non-collision failure (can't reach, but from which return block?); this would probably be rendered as an error-code number
#   - something special for backtracking...; maybe just render the first trajectory with a new backtracking traversal with some special annotation? or maybe not, since these will just stack on top of each other?
#   - maybe I should have a toggleable mode (configured at start with the edge-selector info) that renders each successive trajectory at a delay and loops the whole sequence?
# - Make this annotation also work for valid edges.
# - Later, make this annotation usable at run time, by clicking on the start and end positions to check.
# 
# - Add support for manually stepping through the calc step annotations, instead of it being on an automatic timer.
# - Add support for rendering the movement steps in a tree view; the linear view is confusing.
#   - Will need to change how the ste debug state is stored...
#     - 
#   - Will need to create a vertical panel for rendering lists of text lines.
#     - 

var origin_constraint: MovementConstraint setget ,_get_origin
var destination_constraint: MovementConstraint setget ,_get_destination
var movement_params: MovementParams setget ,_get_movement_params

# Array<StepAttemptDebugState>
var step_attempts := []

var _overall_calc_params

func _init(overall_calc_params) -> void:
    self._overall_calc_params = overall_calc_params
    
func _get_origin() -> MovementConstraint:
    return _overall_calc_params.origin_constraint as MovementConstraint

func _get_destination() -> MovementConstraint:
    return _overall_calc_params.destination_constraint as MovementConstraint

func _get_movement_params() -> MovementParams:
    return _overall_calc_params.movement_params as MovementParams
