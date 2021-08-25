class_name CharacterActionSource
extends Reference


const input_key_to_action_name := {
    "j": "jump",
    "mu": "up",
    "md": "down",
    "ml": "left",
    "mr": "right",
    "g": "grab",
    "fl": "face_left",
    "fr": "face_right",
}

var source_type_prefix: String
var character: ScaffolderCharacter
var is_additive: bool


func _init(
        source_type_prefix: String,
        character,
        is_additive: bool) -> void:
    self.source_type_prefix = source_type_prefix
    self.character = character
    self.is_additive = is_additive


# Calculates actions for the current frame.
func update(
        actions: CharacterActionState,
        previous_actions: CharacterActionState,
        time_scaled: float,
        delta_scaled: float,
        navigation_state: CharacterNavigationState) -> void:
    Sc.logger.error("Abstract CharacterActionSource.update is not implemented")


static func update_for_key_press(
        actions: CharacterActionState,
        previous_actions: CharacterActionState,
        input_key: String,
        is_pressed: bool,
        time_scaled: float,
        is_additive: bool) -> void:
    var action_name: String = input_key_to_action_name[input_key]
    var pressed_action_key := "pressed_" + action_name
    var just_pressed_action_key := "just_pressed_" + action_name
    var just_released_action_key := "just_released_" + action_name
    
    var was_pressed_in_previous_frame: bool = \
            previous_actions.get(pressed_action_key)
    var was_already_pressed_in_current_frame: bool = \
            actions.get(pressed_action_key)
    var is_pressed_in_current_frame := \
            is_pressed or \
            (is_additive and was_already_pressed_in_current_frame)
    var just_pressed := \
            !was_pressed_in_previous_frame and \
            is_pressed_in_current_frame
    var just_released := \
            was_pressed_in_previous_frame and \
            !is_pressed_in_current_frame
    
    actions.set(pressed_action_key, is_pressed_in_current_frame)
    actions.set(just_pressed_action_key, just_pressed)
    actions.set(just_released_action_key, just_released)
