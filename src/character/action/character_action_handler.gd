class_name CharacterActionHandler
extends Reference
## An ActionHandler updates a character's state each frame, in response to current
## events and the character's current state.
## For example, FloorJumpAction listens for jump events while the character is on
## the ground, and triggers character jump state accordingly.


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


func process(character) -> bool:
    Sc.logger.error("Abstract CharacterActionHandler.process is not implemented")
    return false
