class_name PlayerParams
extends Reference

var name: String
# PlayerType
var type: int
var movement_params: MovementParams
# Array<EdgeCalculator>
var edge_calculators: Array
# Array<PlayerActionHandler>
var action_handlers: Array

func _init(
        name: String,
        movement_params: MovementParams,
        edge_calculators: Array,
        action_handlers: Array) -> void:
    self.name = name
    self.movement_params = movement_params
    self.edge_calculators = edge_calculators
    self.action_handlers = action_handlers

func get_edge_calculator(edge_type: int) -> EdgeCalculator:
    for calculator in edge_calculators:
        if calculator.edge_type == edge_type:
            return calculator
    return null
