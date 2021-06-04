class_name PlayerActionHandler
extends Reference


const MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION := 15.0
const MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION := 60.0

var name: String
# SurfaceType
var type: int
var uses_runtime_physics: bool
var priority: int


func _init(
        name: String,
        type: int,
        uses_runtime_physics: bool,
        priority: int) -> void:
    self.name = name
    self.type = type
    self.uses_runtime_physics = uses_runtime_physics
    self.priority = priority


func process(player) -> bool:
    Gs.logger.error("abstract PlayerActionHandler.process is not implemented")
    return false
