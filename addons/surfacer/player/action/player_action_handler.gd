extends Reference
class_name PlayerActionHandler

const MIN_SPEED_TO_MAINTAIN_VERTICAL_COLLISION := 15.0
const MIN_SPEED_TO_MAINTAIN_HORIZONTAL_COLLISION := 60.0

var name: String
# SurfaceType
var type: int
var priority: int

func _init( \
        name: String, \
        type: int, \
        priority: int) -> void:
    self.name = name
    self.type = type
    self.priority = priority

func process(player) -> bool:
    ScaffoldUtils.error("abstract PlayerActionHandler.process is not implemented")
    return false
