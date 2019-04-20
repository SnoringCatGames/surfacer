extends Reference
class_name PlayerMovement

var name: String
var params: MovementParams

func _init(name: String, params: MovementParams) -> void:
    self.name = name
    self.params = params

func get_instructions_for_edge(start: PositionAlongSurface, end: PositionAlongSurface) -> Array:
    Utils.error("Abstract PlayerMovement.get_instructions_for_edge is not implemented")
    return []

func get_instructions_from_air(start: Vector2, end: PositionAlongSurface) -> Array:
    Utils.error("Abstract PlayerMovement.get_movement_instructions_from_air is not implemented")
    return []

func get_instructions_to_air(start: PositionAlongSurface, end: Vector2) -> Array:
    Utils.error("Abstract PlayerMovement.get_movement_instructions_to_air is not implemented")
    return []

func get_max_upward_range() -> float:
    Utils.error("Abstract PlayerMovement.get_max_upward_movement is not implemented")
    return 0.0

func get_max_horizontal_range() -> float:
    Utils.error("Abstract PlayerMovement.get_max_horizontal_movement is not implemented")
    return 0.0
