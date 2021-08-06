class_name SurfacerPlayerRecentMovementAnnotator
extends ScaffolderPlayerRecentMovementAnnotator


const HORIZONTAL_INSTRUCTION_START_LENGTH := 9
const HORIZONTAL_INSTRUCTION_START_STROKE_WIDTH := 1
const HORIZONTAL_INSTRUCTION_END_LENGTH := 9
const HORIZONTAL_INSTRUCTION_END_STROKE_WIDTH := 1
const VERTICAL_INSTRUCTION_START_END_LENGTH := 11
const VERTICAL_INSTRUCTION_START_END_STROKE_WIDTH := 1

# We use this as a circular buffer.
var recent_actions: PoolIntArray


func _init(player: SurfacerPlayer).(player) -> void:
    self.recent_actions = PoolIntArray()
    self.recent_actions.resize(RECENT_POSITIONS_BUFFER_SIZE)


func check_for_update() -> void:
    # Record the action as belonging to the previous frame.
    if player.actions.just_pressed_jump:
        recent_actions[current_position_index] = \
                PlayerActionType.PRESSED_JUMP
    elif player.actions.just_pressed_left:
        recent_actions[current_position_index] = \
                PlayerActionType.PRESSED_LEFT
    elif player.actions.just_pressed_right:
        recent_actions[current_position_index] = \
                PlayerActionType.PRESSED_RIGHT
    elif player.actions.just_pressed_grab_wall:
        recent_actions[current_position_index] = \
                PlayerActionType.PRESSED_GRAB_WALL
    elif player.actions.just_pressed_face_left:
        recent_actions[current_position_index] = \
                PlayerActionType.PRESSED_FACE_LEFT
    elif player.actions.just_pressed_face_right:
        recent_actions[current_position_index] = \
                PlayerActionType.PRESSED_FACE_RIGHT
    elif player.actions.just_released_jump:
        recent_actions[current_position_index] = \
                PlayerActionType.RELEASED_JUMP
    elif player.actions.just_released_left:
        recent_actions[current_position_index] = \
                PlayerActionType.RELEASED_LEFT
    elif player.actions.just_released_right:
        recent_actions[current_position_index] = \
                PlayerActionType.RELEASED_RIGHT
    elif player.actions.just_released_grab_wall:
        recent_actions[current_position_index] = \
                PlayerActionType.RELEASED_GRAB_WALL
    elif player.actions.just_released_face_left:
        recent_actions[current_position_index] = \
                PlayerActionType.RELEASED_FACE_LEFT
    elif player.actions.just_released_face_right:
        recent_actions[current_position_index] = \
                PlayerActionType.RELEASED_FACE_RIGHT
    elif player.did_move_last_frame:
        recent_actions[current_position_index] = \
                PlayerActionType.NONE
    else:
        # Ignore this frame, since there was no movement or action.
        return
    
    total_position_count += 1
    current_position_index = \
            (current_position_index + 1) % RECENT_POSITIONS_BUFFER_SIZE
    
    # Record the new position for the current frame.
    recent_positions[current_position_index] = player.position
    # Record an empty place-holder action value for the current frame.
    recent_actions[current_position_index] = PlayerActionType.NONE
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
    if action != PlayerActionType.NONE:
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
        PlayerActionType.PRESSED_JUMP:
            input_key = "j"
            is_pressed = true
        PlayerActionType.RELEASED_JUMP:
            input_key = "j"
            is_pressed = false
        PlayerActionType.PRESSED_LEFT:
            input_key = "ml"
            is_pressed = true
        PlayerActionType.RELEASED_LEFT:
            input_key = "ml"
            is_pressed = false
        PlayerActionType.PRESSED_RIGHT:
            input_key = "mr"
            is_pressed = true
        PlayerActionType.RELEASED_RIGHT:
            input_key = "mr"
            is_pressed = false
        PlayerActionType.PRESSED_GRAB_WALL, \
        PlayerActionType.RELEASED_GRAB_WALL, \
        PlayerActionType.PRESSED_FACE_LEFT, \
        PlayerActionType.RELEASED_FACE_LEFT, \
        PlayerActionType.PRESSED_FACE_RIGHT, \
        PlayerActionType.RELEASED_FACE_RIGHT:
            pass
        _:
            Sc.logger.error(
                    ("Unknown PlayerActionType passed to " +
                    "_draw_action_indicator: %s") % \
                    PlayerActionType.get_string(action))
    
    if input_key != "":
        Sc.draw.draw_instruction_indicator(
                self,
                input_key,
                is_pressed,
                position,
                SurfacerDrawUtils.EDGE_INSTRUCTION_INDICATOR_LENGTH,
                color)
