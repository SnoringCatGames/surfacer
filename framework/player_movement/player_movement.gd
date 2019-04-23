extends Reference
class_name PlayerMovement

var name: String
var params: MovementParams

func _init(name: String, params: MovementParams) -> void:
    self.name = name
    self.params = params

func get_instructions_for_edge(start: PositionAlongSurface, \
        end: PositionAlongSurface) -> PlayerInstructions:
    Utils.error("Abstract PlayerMovement.get_instructions_for_edge is not implemented")
    return null

func get_instructions_to_air(start: PositionAlongSurface, end: Vector2) -> PlayerInstructions:
    Utils.error("Abstract PlayerMovement.get_instructions_to_air is not implemented")
    return null

func get_instructions_from_air(start: Vector2, end: PositionAlongSurface, \
        start_velocity: Vector2) -> PlayerInstructions:
    Utils.error("Abstract PlayerMovement.get_instructions_from_air is not implemented")
    return null

func get_max_upward_distance() -> float:
    Utils.error("Abstract PlayerMovement.get_max_upward_distance is not implemented")
    return 0.0

func get_max_horizontal_distance() -> float:
    Utils.error("Abstract PlayerMovement.get_max_horizontal_distance is not implemented")
    return 0.0
