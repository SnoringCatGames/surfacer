extends Reference
class_name PlayerActionHandler

var name: String
# PlayerActionSurfaceType
var type: int
var priority: int

func _init(name: String, type: int, priority: int) -> void:
    self.name = name
    self.type = type
    self.priority = priority

# TODO: Add type back in.
func process(player) -> bool:
    Utils.error("abstract PlayerActionHandler.process is not implemented")
    return false
