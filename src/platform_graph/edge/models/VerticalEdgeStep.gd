class_name VerticalEdgeStep
extends EdgeStep
# Some vertical start and stop state for a movement.
# 
# - Each overall (edge) movement consists of a single vertical step and a series of horizontal
#   steps.
# - A vertical step could represent the pressing of the jump button (for jump movements).
# - Or a vertical step could just be a placeholder for storing some of the vertical movement state
#   (for fall movements).

# The time at which movement for this step should reach the maximum height.
var time_peak_height: float

# The maximum height position for this step.
var position_peak_height := Vector2.INF

# Whether the jump button can be held in order to apply slow-rise and variable-jump-height.
var can_hold_jump_button: bool
