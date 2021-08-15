class_name SurfacerCharacterRecentMovementAnnotator
extends ScaffolderCharacterRecentMovementAnnotator


const HORIZONTAL_INSTRUCTION_START_LENGTH := 9
const HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH := 1
const HORIZONTAL_INSTRUCTION_END_LENGTH := 9
const HORIZONTAL_INSTRUCTION_END_STROKE_WIDTH := 1
const VERTICAL_INSTRUCTION_START_END_LENGTH := 11
const VERTICAL_INSTRUCTION_START_END_STROKE_WIDTH := 1

# We use this as a circular buffer.
var recent_actions: PoolIntArray


func _init(character: SurfacerCharacter).(character) -> void:
    self.recent_actions = PoolIntArray()
    self.recent_actions.resize(RECENT_POSITIONS_BUFFER_SIZE)


func check_for_update() -> void:
    # Record the action as belonging to the previous frame.
    if character.actions.just_pressed_jump:
        recent_actions[current_position_index] = \
                CharacterActionType.PRESSED_JUMP
    elif character.actions.just_pressed_left:
        recent_actions[current_position_index] = \
                CharacterActionType.PRESSED_LEFT
    elif character.actions.just_pressed_right:
        recent_actions[current_position_index] = \
                CharacterActionType.PRESSED_RIGHT
    elif character.actions.just_pressed_grab_wall:
        recent_actions[current_position_index] = \
                CharacterActionType.PRESSED_GRAB_WALL
    elif character.actions.just_pressed_face_left:
        recent_actions[current_position_index] = \
                CharacterActionType.PRESSED_FACE_LEFT
    elif character.actions.just_pressed_face_right:
        recent_actions[current_position_index] = \
                CharacterActionType.PRESSED_FACE_RIGHT
    elif character.actions.just_released_jump:
        recent_actions[current_position_index] = \
                CharacterActionType.RELEASED_JUMP
    elif character.actions.just_released_left:
        recent_actions[current_position_index] = \
                CharacterActionType.RELEASED_LEFT
    elif character.actions.just_released_right:
        recent_actions[current_position_index] = \
                CharacterActionType.RELEASED_RIGHT
    elif character.actions.just_released_grab_wall:
        recent_actions[current_position_index] = \
                CharacterActionType.RELEASED_GRAB_WALL
    elif character.actions.just_released_face_left:
        recent_actions[current_position_index] = \
                CharacterActionType.RELEASED_FACE_LEFT
    elif character.actions.just_released_face_right:
        recent_actions[current_position_index] = \
                CharacterActionType.RELEASED_FACE_RIGHT
    elif character.did_move_last_frame:
        recent_actions[current_position_index] = \
                CharacterActionType.NONE
    else:
        # Ignore this frame, since there was no movement or action.
        return
    
    total_position_count += 1
    current_position_index = \
            (current_position_index + 1) % RECENT_POSITIONS_BUFFER_SIZE
    
    # Record the new position for the current frame.
    recent_positions[current_position_index] = character.position
    # Record an empty place-holder action value for the current frame.
    recent_actions[current_position_index] = CharacterActionType.NONE
    # Record an empty place-holder beat value for the current frame.
    recent_beats[current_position_index] = -1
    
    update()


func _draw_frame(
        index: int,
        previous_position: Vector2,
        color: Color,
        opacity: float) -> void:
    var next_position := recent_positions[index]
    
    draw_line(
            previous_position,
            next_position,
            color,
            MOVEMENT_STROKE_WIDTH)
    
    var action: int = recent_actions[index]
    if action != CharacterActionType.NONE:
        _draw_action_indicator(
                action,
                next_position,
                opacity)
    
    var beat_index: int = recent_beats[index]
    if beat_index >= 0:
        _draw_beat_hash(
                beat_index,
                previous_position,
                next_position,
                opacity)


# Draw an indicator for the action that happened at this point.
func _draw_action_indicator(
        action: int,
        position: Vector2,
        opacity: float) -> void:
    var color := Color.from_hsv(
            MOVEMENT_HUE,
            0.3,
            0.99,
            opacity)
    
    var input_key := ""
    var is_pressed: bool
    match action:
        CharacterActionType.PRESSED_JUMP:
            input_key = "j"
            is_pressed = true
        CharacterActionType.RELEASED_JUMP:
            input_key = "j"
            is_pressed = false
        CharacterActionType.PRESSED_LEFT:
            input_key = "ml"
            is_pressed = true
        CharacterActionType.RELEASED_LEFT:
            input_key = "ml"
            is_pressed = false
        CharacterActionType.PRESSED_RIGHT:
            input_key = "mr"
            is_pressed = true
        CharacterActionType.RELEASED_RIGHT:
            input_key = "mr"
            is_pressed = false
        CharacterActionType.PRESSED_GRAB_WALL, \
        CharacterActionType.RELEASED_GRAB_WALL, \
        CharacterActionType.PRESSED_FACE_LEFT, \
        CharacterActionType.RELEASED_FACE_LEFT, \
        CharacterActionType.PRESSED_FACE_RIGHT, \
        CharacterActionType.RELEASED_FACE_RIGHT:
            pass
        _:
            Sc.logger.error(
                    ("Unknown CharacterActionType passed to " +
                    "_draw_action_indicator: %s") % \
                    CharacterActionType.get_string(action))
    
    if input_key != "":
        Sc.draw.draw_instruction_indicator(
                self,
                input_key,
                is_pressed,
                position,
                SurfacerDrawUtils.EDGE_INSTRUCTION_INDICATOR_LENGTH,
                color)
