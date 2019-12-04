extends Node2D
class_name EdgeCalculationSelectorAnnotator

var global
var edge_attempt: MovementCalcOverallDebugState
var selected_step: MovementCalcStepDebugState

# FIXME: LEFT OFF HERE: -------------------------------------A

func _init() -> void:
    pass

func _ready() -> void:
    self.global = null

func _process(delta: float) -> void:
    pass

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and \
            !event.pressed and (event.control or event.command):
        var position: Vector2 = global.current_level.get_global_mouse_position()

func _draw() -> void:
    if edge_attempt == null:
        return
    
    pass
