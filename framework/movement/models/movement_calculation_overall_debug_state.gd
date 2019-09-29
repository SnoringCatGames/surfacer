# State that captures internal calculation information for a single edge in order to help with
# debugging.
extends Reference
class_name MovementCalcOverallDebugState

# FIXME: LEFT OFF HERE: ------------------------------------A
# - Create a better way to debug edge calculations.
# - render annotations?
# - I could save arbitrary debug state on overall_calc_params
# - I would need to keep it in sync with different overall_calc_params instances between traversals
# - Probably need to record a full tree of stuff...; or maybe not, since I could just record things in order of occurrence
# - But before doing anything, need to list out exactly what info would be useful to see rendered?
#   - failed trajectories to collisions
#   - points of collisions
#   - attempted constraints for the collisions
#   - color-code each of the above three with the same color for a given collision
#   - reason for failing for each non-collision failure (can't reach, but from which return block?); this would probably be rendered as an error-code number
#   - some sort of sequencing info, so we can tell the order of traversal annotations; maybe always render first with orange and last with blue, and just show a gradient for all steps in the middle?
#   - something special for backtracking...; maybe just render the first trajectory with a new backtracking traversal with some special annotation? or maybe not, since these will just stack on top of each other?
#   - maybe I should have a toggleable mode (configured at start with the edge-selector info) that renders each successive trajectory at a delay and loops the whole sequence?
# - Make this annotation also work for valid edges.
# - Later, make this annotation usable at run time, by clicking on the start and end positions to check.

var origin_constraint: MovementConstraint setget ,_get_origin
var destination_constraint: MovementConstraint setget ,_get_destination

# Array<StepAttemptDebugState>
var step_attempts := []

var _overall_calc_params

func _init(overall_calc_params) -> void:
    self._overall_calc_params = overall_calc_params
    
func _get_origin() -> MovementConstraint:
    return _overall_calc_params.origin_constraint as MovementConstraint

func _get_destination() -> MovementConstraint:
    return _overall_calc_params.destination_constraint as MovementConstraint
