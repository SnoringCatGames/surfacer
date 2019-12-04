extends Node2D
class_name CollisionCalculationAnnotator

var edge_attempt: MovementCalcOverallDebugState
var selected_step: MovementCalcStepDebugState

func _init() -> void:
    pass

func _ready() -> void:
    pass

func _draw() -> void:
    if edge_attempt == null:
        return
    
    pass

func on_step_selected(selected_step_attempt: MovementCalcStepDebugState) -> void:
    self.selected_step = selected_step_attempt
