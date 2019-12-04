extends Node2D
class_name CollisionCalculationAnnotator

var edge_attempt: MovementCalcOverallDebugState
var selected_step: MovementCalcStepDebugState

# FIXME: LEFT OFF HERE: -------------------------------------A
#   - Should show all the details for the state of a collision calculation.
#   - Should work for both valid collisions and error-state collisions.
#   - Things to render:
#     - Bounding box of frame start, end, and previous frame start.
#     - Bounding box with and without margin (thin lines and dotted lines).
#     - intersection_points
#     - motion arrow
#   - Should integrate into the edge calculation annotation selection?
#     - Hopefully shouldn't be too noisy...
#   - Probably need to support zooming-in the camera?
#     - Maybe this could be toggleable via clicking a button in the tree view?
#     - Would definitely want to animate the zoom.
#     - Probably also need to change the camera translation.
#       - Probably can just calculate the offset from the player to the collision, and use that to
#         manually assign an offset to the camera.
#       - Would also need to animate this translation.

func _init() -> void:
    pass

func _ready() -> void:
    pass

func _draw() -> void:
    if edge_attempt == null:
        return
    
    pass
