class_name CharacterAnimationState
extends Reference


const POST_PATH_DURATION_TO_MIN_CONFIDENCE := 1.0
const MIN_POST_PATH_CONFIDENCE_OPACITY := 0.3
const LOW_CONFIDENCE_MODULATE_MASK := Color("cccc22")

var character_position := Vector2.INF
var animation_name := "Rest"
var animation_position := 0.0
var facing_left := false
var confidence_multiplier := 0.0


func reset() -> void:
    self.character_position = Vector2.INF
    self.animation_name = "Rest"
    self.animation_position = 0.0
    self.facing_left = false
    self.confidence_multiplier = 0.0


func copy(other: CharacterAnimationState) -> void:
    self.character_position = other.character_position
    self.animation_name = other.animation_name
    self.animation_position = other.animation_position
    self.facing_left = other.facing_left
    self.confidence_multiplier = other.confidence_multiplier
