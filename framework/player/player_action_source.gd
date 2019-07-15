extends Reference
class_name PlayerActionSource

# Calculates actions for the current frame.
func update(actions: PlayerActionState, delta: float) -> void:
    Utils.error("Abstract PlayerActionSource.update is not implemented")
