extends Reference
class_name PlayerInstructions

# Array<PlayerInstruction>
var instructions: Array
var duration: int
var distance: float

# Instructions don't need to be pre-sorted.
func _init(instructions: Array, duration: int, distance: float) -> void:
    self.instructions = instructions
    self.duration = duration
    self.distance = distance
    
    self.instructions.sort_custom(self, "instruction_comparator")

static func instruction_comparator(a: PlayerInstruction, b: PlayerInstruction) -> bool:
    return a.time <= b.time
