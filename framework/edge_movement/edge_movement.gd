extends Reference
class_name EdgeMovement

var name: String
var params: MovementParams

func _init(name: String, params: MovementParams) -> void:
    self.name = name
    self.params = params

func get_movement_instructions(start_position: PositionAlongSurface, \
        end_position: PositionAlongSurface) -> PlatformGraphEdge:
    Utils.error("Abstract EdgeMovement.get_movement_instructions is not implemented")
    return null

func get_max_upward_range() -> float:
    Utils.error("Abstract EdgeMovement.get_max_upward_movement is not implemented")
    return 0.0

func get_max_horizontal_range() -> float:
    Utils.error("Abstract EdgeMovement.get_max_horizontal_movement is not implemented")
    return 0.0
